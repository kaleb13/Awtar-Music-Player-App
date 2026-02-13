import 'package:audiotags/audiotags.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/song.dart';
import 'stats_provider.dart';
import '../services/artwork_cache_service.dart';
import '../services/lyrics_service.dart';
import '../services/database_service.dart';
import '../main.dart';

class MusicPlayerState {
  final Song? currentSong;
  final List<Song> queue;
  final int currentIndex;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final bool isShuffling;
  final RepeatMode repeatMode;
  final String? errorMessage;

  MusicPlayerState({
    this.currentSong,
    this.queue = const [],
    this.currentIndex = -1,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.isShuffling = false,
    this.repeatMode = RepeatMode.off,
    this.errorMessage,
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
    String? errorMessage,
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
      errorMessage: errorMessage,
    );
  }
}

enum RepeatMode { off, all, one }

class PlayerNotifier extends StateNotifier<MusicPlayerState> {
  late final AudioPlayer _audioPlayer;
  final Ref _ref;
  DateTime? _lastTrackingPoint;
  late ConcatenatingAudioSource _playlist;

  PlayerNotifier(this._ref, {bool skipInit = false})
    : super(MusicPlayerState()) {
    if (skipInit) return;

    _audioPlayer = AudioPlayer();
    _playlist = ConcatenatingAudioSource(children: []);

    // Set up the player with our playlist structure for later use
    // Initial setup might be empty until we play something
    // We defer setting source until play() or load()
    // However, just_audio recommends setting source early if possible, but empty source is fine.

    _loadLastPlayedSong();
    _listenToStreams();
  }

  void _listenToStreams() {
    // Only update position if it has changed significantly (e.g. 200ms) or use a separate stream
    // for progress to avoid excessive StateNotifier notifications.
    // For now, let's keep it but ensure it's not blocking.
    // Throttle MusicPlayerState position updates to once per 1000ms
    Duration lastThrottledPos = Duration.zero;
    _audioPlayer.positionStream.listen((pos) {
      if (mounted) {
        // Only update global state occasionally to avoid broad rebuilds
        if ((pos - lastThrottledPos).inMilliseconds.abs() >= 1000) {
          lastThrottledPos = pos;
          state = state.copyWith(position: pos);
        }
        _checkTracking(pos);
      }
    });

    _audioPlayer.durationStream.listen((dur) {
      if (dur != null && mounted) {
        state = state.copyWith(duration: dur);
      }
    });

    _audioPlayer.playerStateStream.listen((s) {
      if (mounted) {
        debugPrint(
          '🎧 PlayerState Changed: playing=${s.playing}, processingState=${s.processingState}',
        );
        state = state.copyWith(isPlaying: s.playing);
      }
    });

    // sequenceStateStream is the most reliable way to stay in sync with what's actually playing
    _audioPlayer.sequenceStateStream.listen((sequenceState) {
      if (sequenceState == null || !mounted) return;

      final index = sequenceState.currentIndex;
      if (index < state.queue.length) {
        final song = state.queue[index];
        if (state.currentSong?.id != song.id) {
          debugPrint('🎵 Song sync update: "${song.title}" (index: $index)');

          // Update state IMMEDIATELY
          state = state.copyWith(currentSong: song, currentIndex: index);

          // Background tasks
          _saveLastPlayedSong(song);
          _ref
              .read(statsProvider.notifier)
              .recordPlay(song.id, song.artist, song.album ?? "Unknown");
          _fetchLyrics(song);
          _warmUpQueue();
        }
      }
    });

    // Listen for detailed errors and events
    _audioPlayer.playbackEventStream.listen(
      (event) {
        debugPrint(
          '🔊 Playback Event: processingState=${event.processingState}',
        );
      },
      onError: (Object e, StackTrace st) {
        debugPrint('❌ Playback Event Stream Error: $e');
        if (mounted) {
          state = state.copyWith(errorMessage: e.toString());
        }
      },
    );
  }

  // Helper method to create AudioSource with MediaItem metadata
  // This is the implementation of the user's request
  AudioSource _createAudioSource(Song song) {
    debugPrint('💿 _createAudioSource: "${song.title}"');
    debugPrint('   📍 URI: ${song.url}');
    Uri? artUri;
    if (song.albumArt != null && song.albumArt!.isNotEmpty) {
      try {
        // Handle local file vs network URL for artwork
        if (song.albumArt!.startsWith('/')) {
          artUri = Uri.file(song.albumArt!);
        } else {
          artUri = Uri.parse(song.albumArt!);
        }
      } catch (e) {
        debugPrint('   ⚠️ Error parsing albumArt URI: $e');
      }
    }

    // Determine if audio URL is local or network
    final audioUri = (song.url.startsWith('/') || song.url.contains(':\\'))
        ? Uri.file(song.url)
        : Uri.parse(song.url);

    debugPrint('   🔗 Audio URI: $audioUri');

    return AudioSource.uri(
      audioUri,
      tag: MediaItem(
        id: song.id.toString(),
        album: song.album ?? "Unknown Album",
        title: song.title,
        artist: song.artist,
        artUri: artUri,
        duration: Duration(seconds: song.duration),
      ),
    );
  }

  Future<void> play(Song song, {List<Song>? queue, int? index}) async {
    debugPrint('▶️ Play called for: "${song.title}"');
    try {
      // Clear previous error
      if (state.errorMessage != null) {
        state = state.copyWith(errorMessage: null);
      }

      final newQueue = queue ?? [song];
      final targetIndex =
          index ?? newQueue.indexOf(song).clamp(0, newQueue.length - 1);

      // If the queue has changed, rebuild the playlist
      if (state.queue != newQueue) {
        debugPrint('   📋 Rebuilding playlist with ${newQueue.length} songs');

        // Optimistically update state first to reflect queue changes UI side immediately
        state = state.copyWith(
          queue: newQueue,
          currentSong: newQueue[targetIndex],
          currentIndex: targetIndex,
        );

        // Build new audio sources
        final sources = newQueue.map((s) => _createAudioSource(s)).toList();

        // Create a new playlist
        _playlist = ConcatenatingAudioSource(children: sources);

        // Set the new source to the player
        debugPrint('   ⏳ Setting audio source...');
        await _audioPlayer.setAudioSource(
          _playlist,
          initialIndex: targetIndex,
          initialPosition: Duration.zero,
        );
      } else {
        // Queue hasn't changed, just seek to the song
        if (_audioPlayer.currentIndex != targetIndex) {
          debugPrint('   ⏩ Seeking to index $targetIndex');
          // Update state optimistically
          state = state.copyWith(
            currentSong: state.queue[targetIndex],
            currentIndex: targetIndex,
          );
          await _audioPlayer.seek(Duration.zero, index: targetIndex);
        }
      }

      debugPrint('   🚀 Calling _audioPlayer.play()');
      await _audioPlayer.play();
      debugPrint('   ✅ Playback command sent');
    } catch (e, stack) {
      debugPrint('❌ Playback failed: $e');
      debugPrint('   Stack: $stack');
      if (mounted) {
        state = state.copyWith(errorMessage: "Playback failed: $e");
      }
    }
  }

  Future<void> _loadLastPlayedSong() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSongJson = prefs.getString('last_played_song');

      if (lastSongJson != null) {
        final songMap = jsonDecode(lastSongJson) as Map<String, dynamic>;
        final lastSong = Song.fromMap(songMap);
        state = state.copyWith(currentSong: lastSong);
      }
    } catch (e) {
      debugPrint('Error loading last played song: $e');
    }
  }

  Future<void> _saveLastPlayedSong(Song song) async {
    try {
      final prefs = _ref.read(sharedPreferencesProvider);
      final songJson = jsonEncode(song.toMap());
      await prefs.setString('last_played_song', songJson);
    } catch (e) {
      debugPrint('Error saving last played song: $e');
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

  void _warmUpQueue() {
    if (state.queue.isEmpty) return;
    final startIndex = (state.currentIndex + 1) % state.queue.length;
    for (int i = 0; i < 5; i++) {
      final index = (startIndex + i) % state.queue.length;
      final song = state.queue[index];

      // Warm up artwork
      ArtworkCacheService.warmUp(song.url, song.id);

      // Warm up lyrics (Pre-fetch in background)
      if (song.lyrics.isEmpty) {
        _fetchLyrics(song, isWarmUp: true);
      }
    }
  }

  Future<void> _fetchLyrics(Song song, {bool isWarmUp = false}) async {
    try {
      // 1. Try Service (Memory Cache -> DB -> LRC File)
      final List<LyricLine> cachedLyrics = await LyricsService.getLyricsForSong(
        song,
      );

      if (cachedLyrics.isNotEmpty) {
        _updateLyricsInState(song.id, cachedLyrics, isWarmUp);
        return;
      }

      // 2. Try Embedded Tags (Slowest fallback)
      final tag = await AudioTags.read(song.url);
      final String? lyricsText = tag?.lyrics;

      if (lyricsText != null && lyricsText.isNotEmpty) {
        List<LyricLine> parsedLyrics = [];
        if (lyricsText.contains('[') && lyricsText.contains(']')) {
          parsedLyrics = LyricsService.parseLrc(lyricsText);
        }

        if (parsedLyrics.isEmpty) {
          final lines = lyricsText.split('\n');
          parsedLyrics = lines
              .map((line) => LyricLine(time: Duration.zero, text: line.trim()))
              .where((l) => l.text.isNotEmpty)
              .toList();
        }

        if (parsedLyrics.isNotEmpty) {
          // Save to DB persistently so next session is instant
          DatabaseService.saveLyrics(song.id, parsedLyrics);
          _updateLyricsInState(song.id, parsedLyrics, isWarmUp);
        }
      }
    } catch (e) {
      if (!isWarmUp) debugPrint("Failed to fetch lyrics: $e");
    }
  }

  void _updateLyricsInState(int songId, List<LyricLine> lyrics, bool isWarmUp) {
    if (!mounted) return;

    // Update current song if it matches
    if (state.currentSong?.id == songId) {
      state = state.copyWith(
        currentSong: state.currentSong!.copyWith(lyrics: lyrics),
      );
    }

    // Also update in queue to ensure it's ready when user navigates
    if (state.queue.any((s) => s.id == songId)) {
      state = state.copyWith(
        queue: state.queue.map((s) {
          if (s.id == songId && s.lyrics.isEmpty) {
            return s.copyWith(lyrics: lyrics);
          }
          return s;
        }).toList(),
      );
    }
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> togglePlayPause(Song? song) async {
    if (state.isPlaying) {
      await pause();
    } else {
      if (song != null && state.currentSong?.id != song.id) {
        await play(song);
      } else {
        await _audioPlayer.play();
      }
    }
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  void next() {
    if (_audioPlayer.hasNext) {
      _audioPlayer.seekToNext();
    } else {
      // Loop if needed? ConcatenatingAudioSource handles loop if loop mode is set on player
      if (state.repeatMode == RepeatMode.all && state.queue.isNotEmpty) {
        _audioPlayer.seek(Duration.zero, index: 0);
      }
    }
  }

  void previous() {
    if (_audioPlayer.hasPrevious) {
      _audioPlayer.seekToPrevious();
    } else {
      if (state.repeatMode == RepeatMode.all && state.queue.isNotEmpty) {
        _audioPlayer.seek(Duration.zero, index: state.queue.length - 1);
      }
    }
  }

  void toggleShuffle() {
    final newValue = !state.isShuffling;
    _audioPlayer.setShuffleModeEnabled(newValue);
    state = state.copyWith(isShuffling: newValue);
  }

  Future<void> playPlaylist(List<Song> playlist, int index) async {
    await play(playlist[index], queue: playlist, index: index);
  }

  void updateFavoriteStatus(int songId, bool isFavorite) {
    if (state.currentSong?.id == songId) {
      state = state.copyWith(
        currentSong: state.currentSong!.copyWith(isFavorite: isFavorite),
      );
    }
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

    switch (nextMode) {
      case RepeatMode.off:
        _audioPlayer.setLoopMode(LoopMode.off);
        break;
      case RepeatMode.all:
        _audioPlayer.setLoopMode(LoopMode.all);
        break;
      case RepeatMode.one:
        _audioPlayer.setLoopMode(LoopMode.one);
        break;
    }
  }

  Future<void> addToQueue(List<Song> songs) async {
    final newQueue = List<Song>.from(state.queue)..addAll(songs);
    state = state.copyWith(queue: newQueue);
    await _playlist.addAll(songs.map((s) => _createAudioSource(s)).toList());
  }

  Future<void> addNext(List<Song> songs) async {
    if (songs.isEmpty) return;
    if (state.queue.isEmpty) {
      await playPlaylist(songs, 0);
      return;
    }
    final newQueue = List<Song>.from(state.queue);
    final insertIndex = state.currentIndex + 1;
    newQueue.insertAll(insertIndex, songs);
    state = state.copyWith(queue: newQueue);

    await _playlist.insertAll(
      insertIndex,
      songs.map((s) => _createAudioSource(s)).toList(),
    );
  }

  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;
  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}

final playerProvider = StateNotifierProvider<PlayerNotifier, MusicPlayerState>((
  ref,
) {
  return PlayerNotifier(ref);
});

final playerPositionStreamProvider = StreamProvider<Duration>((ref) {
  return ref.watch(playerProvider.notifier).positionStream;
});

final playerDurationStreamProvider = StreamProvider<Duration?>((ref) {
  return ref.watch(playerProvider.notifier).durationStream;
});

final playerStateStreamProvider = StreamProvider<PlayerState>((ref) {
  return ref.watch(playerProvider.notifier).playerStateStream;
});
