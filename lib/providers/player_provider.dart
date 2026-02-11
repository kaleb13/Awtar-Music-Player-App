import 'package:audiotags/audiotags.dart';
import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/song.dart';
import 'stats_provider.dart';
import '../services/audio_handler.dart';

class MusicPlayerState {
  final Song? currentSong;
  final List<Song> queue;
  final int currentIndex;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final bool isShuffling;
  final RepeatMode repeatMode;

  MusicPlayerState({
    this.currentSong,
    this.queue = const [],
    this.currentIndex = -1,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.isShuffling = false,
    this.repeatMode = RepeatMode.off,
  });

  MusicPlayerState copyWith({
    Song? currentSong,
    List<Song>? queue,
    int? currentIndex,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    bool? isShuffling,
    RepeatMode? repeatMode,
  }) {
    return MusicPlayerState(
      currentSong: currentSong ?? this.currentSong,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      isShuffling: isShuffling ?? this.isShuffling,
      repeatMode: repeatMode ?? this.repeatMode,
    );
  }
}

enum RepeatMode { off, all, one }

class PlayerNotifier extends StateNotifier<MusicPlayerState> {
  final ap.AudioPlayer _audioPlayer = ap.AudioPlayer();
  final Ref _ref;
  DateTime? _lastTrackingPoint;
  AudioPlayerHandler? _audioHandler;
  bool _isInitializingHandler = false;

  PlayerNotifier(this._ref, {bool skipInit = false})
    : super(MusicPlayerState()) {
    if (skipInit) return;

    _loadLastPlayedSong();
    _initAudioHandler();

    _audioPlayer.onPositionChanged.listen((pos) {
      state = state.copyWith(position: pos);
      _checkTracking(pos);

      // Update notification position
      _audioHandler?.updatePlaybackState(
        playing: state.isPlaying,
        position: pos,
      );
    });

    _audioPlayer.onDurationChanged.listen((dur) {
      state = state.copyWith(duration: dur);
    });

    _audioPlayer.onPlayerStateChanged.listen((s) {
      final isPlaying = s == ap.PlayerState.playing;
      state = state.copyWith(isPlaying: isPlaying);

      // Update notification state
      _audioHandler?.updatePlaybackState(
        playing: isPlaying,
        position: state.position,
      );
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      if (state.repeatMode == RepeatMode.one) {
        _audioPlayer.seek(Duration.zero);
        _audioPlayer.resume();
      } else {
        next();
      }
    });
  }

  Future<void> _loadLastPlayedSong() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSongJson = prefs.getString('last_played_song');

      if (lastSongJson != null) {
        final songMap = jsonDecode(lastSongJson) as Map<String, dynamic>;
        final lastSong = Song.fromMap(songMap);

        // Set the last played song without playing it
        state = state.copyWith(currentSong: lastSong);

        debugPrint('✅ Loaded last played song: ${lastSong.title}');
      }
    } catch (e) {
      debugPrint('Error loading last played song: $e');
    }
  }

  Future<void> _saveLastPlayedSong(Song song) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final songJson = jsonEncode(song.toMap());
      await prefs.setString('last_played_song', songJson);
      debugPrint('💾 Saved last played song: ${song.title}');
    } catch (e) {
      debugPrint('Error saving last played song: $e');
    }
  }

  Future<void> _initAudioHandler() async {
    if (_isInitializingHandler || _audioHandler != null) return;
    _isInitializingHandler = true;

    try {
      debugPrint('🎵 Starting audio handler initialization...');

      // Request notification permission on Android 13+ (API 33+)
      // This is required for media notifications to appear
      final notificationPermission = await Permission.notification.request();
      debugPrint('Notification permission status: $notificationPermission');

      if (!notificationPermission.isGranted) {
        debugPrint(
          '⚠️ Notification permission not granted. Media notifications may not appear.',
        );
      }

      _audioHandler = await AudioService.init(
        builder: () => AudioPlayerHandler(),
        config: AudioServiceConfig(
          androidNotificationChannelId: 'com.awtart.music.playback.v1',
          androidNotificationChannelName: 'Music Playback',
          androidNotificationOngoing: true,
          androidShowNotificationBadge: true,
          androidNotificationIcon: 'mipmap/ic_launcher',
          androidStopForegroundOnPause: false,
          notificationColor: const Color(
            0xFF1DB954,
          ), // Spotify green or similar
        ),
      );

      // Connect handler callbacks to player actions
      _audioHandler?.onPlayPressed = () async {
        if (state.currentSong != null) {
          await _audioPlayer.resume();
        }
      };

      _audioHandler?.onPausePressed = () async {
        await pause();
      };

      _audioHandler?.onNext = () => next();
      _audioHandler?.onPrevious = () => previous();
      _audioHandler?.onSeekPressed = (position) => seek(position);

      debugPrint('✅ Audio handler initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing audio handler: $e');
      _audioHandler = null;
    } finally {
      _isInitializingHandler = false;
    }
  }

  void _checkTracking(Duration pos) {
    if (state.currentSong == null) return;
    final now = DateTime.now();
    if (_lastTrackingPoint == null ||
        now.difference(_lastTrackingPoint!).inSeconds >= 60) {
      _lastTrackingPoint = now;
      _ref
          .read(statsProvider.notifier)
          .recordDuration(
            state.currentSong!.id,
            state.currentSong!.artist,
            state.currentSong!.album ?? "Unknown",
            60,
          );
    }
  }

  Future<void> play(Song song, {List<Song>? queue, int? index}) async {
    // Ensure audio handler is initialized before proceeding
    if (_audioHandler == null) {
      await _initAudioHandler();
    }

    final newQueue = queue ?? [song];
    // If no index provided, find the song in the queue (or use 0 for single-song queue)
    final newIndex =
        index ?? newQueue.indexOf(song).clamp(0, newQueue.length - 1);

    state = state.copyWith(
      currentSong: song,
      queue: newQueue,
      currentIndex: newIndex,
    );

    // Save this song as the last played song
    await _saveLastPlayedSong(song);

    _ref
        .read(statsProvider.notifier)
        .recordPlay(song.id, song.artist, song.album ?? "Unknown");

    await _audioPlayer.play(ap.DeviceFileSource(song.url));

    // Update notification with current song info
    debugPrint('Updating notification: ${song.title} by ${song.artist}');

    Uri? artUri;
    if (song.albumArt != null && song.albumArt!.isNotEmpty) {
      try {
        artUri = Uri.parse(song.albumArt!);
      } catch (e) {
        debugPrint('Error parsing albumArt URI: $e');
      }
    }

    await _audioHandler?.setMediaItem(
      id: song.id.toString(),
      title: song.title,
      artist: song.artist,
      album: song.album,
      artUri: artUri,
      duration: Duration(seconds: song.duration),
    );

    // Force call updatePlaybackState to ensure notification triggers
    _audioHandler?.updatePlaybackState(playing: true, position: Duration.zero);

    debugPrint('Notification updated successfully');

    // Fetch real lyrics
    _fetchLyrics(song);
  }

  Future<void> _fetchLyrics(Song song) async {
    try {
      final tag = await AudioTags.read(song.url);
      final String? lyricsText = tag?.lyrics;

      List<LyricLine> newLyrics = [];

      if (lyricsText != null && lyricsText.isNotEmpty) {
        // Naive splitting by newline for unsynchronized lyrics
        final lines = lyricsText.split('\n');
        newLyrics = lines
            .map((line) => LyricLine(time: Duration.zero, text: line.trim()))
            .where((l) => l.text.isNotEmpty)
            .toList();
      }

      // If we found lyrics, update the song in the state
      // We only update if the current song is still the same one we fetched for
      if (state.currentSong?.id == song.id) {
        final updatedSong = song.copyWith(lyrics: newLyrics);
        state = state.copyWith(currentSong: updatedSong);
      }
    } catch (e) {
      debugPrint("Failed to fetch lyrics: $e");
    }
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> togglePlayPause(Song? song) async {
    if (state.isPlaying) {
      await pause();
    } else {
      if (song != null) {
        await play(song);
      } else if (state.currentSong != null) {
        await _audioPlayer.resume();
      }
    }
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  void next() {
    if (state.queue.isEmpty) return;
    int nextIndex = state.currentIndex + 1;
    if (nextIndex >= state.queue.length) {
      if (state.repeatMode == RepeatMode.all) {
        nextIndex = 0;
      } else {
        return;
      }
    }
    play(state.queue[nextIndex], index: nextIndex);
  }

  void previous() {
    if (state.queue.isEmpty) return;
    int prevIndex = state.currentIndex - 1;
    if (prevIndex < 0) {
      if (state.repeatMode == RepeatMode.all) {
        prevIndex = state.queue.length - 1;
      } else {
        return;
      }
    }
    play(state.queue[prevIndex], index: prevIndex);
  }

  void toggleShuffle() {
    final newValue = !state.isShuffling;
    List<Song> newQueue = List.from(state.queue);
    if (newValue) {
      newQueue.shuffle();
    } else {
      // Restore original order if we cared, but for now just shuffle
    }
    state = state.copyWith(isShuffling: newValue, queue: newQueue);
  }

  Future<void> playPlaylist(List<Song> playlist, int index) async {
    if (playlist.isEmpty) return;
    await play(playlist[index], queue: playlist, index: index);
  }

  void updateFavoriteStatus(int songId, bool isFavorite) {
    if (state.currentSong?.id == songId) {
      state = state.copyWith(
        currentSong: state.currentSong!.copyWith(isFavorite: isFavorite),
      );
    }

    // Also update in the current queue to keep it consistent
    if (state.queue.any((s) => s.id == songId)) {
      state = state.copyWith(
        queue: state.queue.map((s) {
          if (s.id == songId) {
            return s.copyWith(isFavorite: isFavorite);
          }
          return s;
        }).toList(),
      );
    }
  }

  void toggleRepeat() {
    final nextMode = RepeatMode
        .values[(state.repeatMode.index + 1) % RepeatMode.values.length];
    state = state.copyWith(repeatMode: nextMode);
  }

  void addToQueue(List<Song> songs) {
    if (songs.isEmpty) return;
    // Remove duplicates if needed? standard players allow duplicates.
    final newQueue = List<Song>.from(state.queue)..addAll(songs);
    state = state.copyWith(queue: newQueue);
  }

  void addNext(List<Song> songs) {
    if (songs.isEmpty) return;
    if (state.queue.isEmpty) {
      playPlaylist(songs, 0);
      return;
    }
    final newQueue = List<Song>.from(state.queue);
    // Insert after current index
    newQueue.insertAll(state.currentIndex + 1, songs);
    state = state.copyWith(queue: newQueue);
  }
}

final playerProvider = StateNotifierProvider<PlayerNotifier, MusicPlayerState>((
  ref,
) {
  return PlayerNotifier(ref);
});
