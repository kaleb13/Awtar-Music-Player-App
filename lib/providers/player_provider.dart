import 'package:audiotags/audiotags.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:flutter/material.dart' hide RepeatMode;
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

    _loadPlaybackState();
    _listenToStreams();
  }

  void _listenToStreams() {
    Duration lastThrottledPos = Duration.zero;
    _audioPlayer.positionStream.listen((pos) {
      if (mounted) {
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

    _audioPlayer.sequenceStateStream.listen((sequenceState) {
      if (sequenceState == null || !mounted) return;

      final index = sequenceState.currentIndex;
      if (index < state.queue.length) {
        final song = state.queue[index];
        if (state.currentSong?.id != song.id) {
          // Try to get lyrics synchronously from cache first
          final cachedLyrics = LyricsService.peekCache(song.id);
          final songWithLyrics = cachedLyrics != null
              ? song.copyWith(lyrics: cachedLyrics)
              : song;

          state = state.copyWith(
            currentSong: songWithLyrics,
            currentIndex: index,
          );

          _savePlaybackState();
          _ref
              .read(statsProvider.notifier)
              .recordPlay(song.id, song.artist, song.album ?? "Unknown");

          if (cachedLyrics == null) {
            _fetchLyrics(song);
          }
          _warmUpQueue();
        }
      }
    });

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

  AudioSource _createAudioSource(Song song) {
    Uri? artUri;
    if (song.albumArt != null && song.albumArt!.isNotEmpty) {
      try {
        if (song.albumArt!.startsWith('/')) {
          artUri = Uri.file(song.albumArt!);
        } else {
          artUri = Uri.parse(song.albumArt!);
        }
      } catch (e) {
        debugPrint('   ⚠️ Error parsing albumArt URI: $e');
      }
    }

    final audioUri = (song.url.startsWith('/') || song.url.contains(':\\'))
        ? Uri.file(song.url)
        : Uri.parse(song.url);

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
    try {
      if (state.errorMessage != null) {
        state = state.copyWith(errorMessage: null);
      }

      final newQueue = queue ?? [song];
      final targetIndex =
          index ?? newQueue.indexOf(song).clamp(0, newQueue.length - 1);

      // Use peekCache to get lyrics instantly if they were preloaded
      final cachedLyrics = LyricsService.peekCache(song.id);
      final songWithLyrics = cachedLyrics != null
          ? song.copyWith(lyrics: cachedLyrics)
          : song;

      if (cachedLyrics == null) {
        _fetchLyrics(song);
      }

      if (state.queue != newQueue) {
        state = state.copyWith(
          queue: newQueue,
          currentSong: songWithLyrics,
          currentIndex: targetIndex,
        );

        final sources = newQueue.map((s) => _createAudioSource(s)).toList();
        _playlist = ConcatenatingAudioSource(children: sources);

        // Preload lyrics for the entire queue in background
        LyricsService.preloadLyrics(newQueue).then((_) {
          if (mounted) {
            // Re-peek current song lyrics if they weren't ready
            final current = state.currentSong;
            if (current != null && current.lyrics.isEmpty) {
              final newLyrics = LyricsService.peekCache(current.id);
              if (newLyrics != null) {
                updateLyricsInState(current.id, newLyrics, false);
              }
            }
          }
        });

        await _audioPlayer.setAudioSource(
          _playlist,
          initialIndex: targetIndex,
          initialPosition: Duration.zero,
        );
        _savePlaybackState();
      } else {
        if (_audioPlayer.currentIndex != targetIndex) {
          state = state.copyWith(
            currentSong: songWithLyrics,
            currentIndex: targetIndex,
          );
          await _audioPlayer.seek(Duration.zero, index: targetIndex);
        }
        _savePlaybackState();
      }

      await _audioPlayer.play();
    } catch (e) {
      debugPrint('❌ Playback failed: $e');
      if (mounted) {
        state = state.copyWith(errorMessage: "Playback failed: $e");
      }
    }
  }

  Future<void> _loadPlaybackState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSongJson = prefs.getString('last_played_song');
      final queueJson = prefs.getString('last_played_queue');
      final lastIndex = prefs.getInt('last_played_index') ?? -1;

      if (lastSongJson != null) {
        final songMap = jsonDecode(lastSongJson) as Map<String, dynamic>;
        final lastSong = Song.fromMap(songMap);

        if (queueJson != null) {
          final List<dynamic> queueList = jsonDecode(queueJson);
          final queue = queueList.map((m) => Song.fromMap(m)).toList();

          if (queue.isNotEmpty) {
            state = state.copyWith(
              currentSong: lastSong,
              queue: queue,
              currentIndex: lastIndex != -1 ? lastIndex : 0,
            );

            // Progressive: Defer heavy audio source initialization
            Future.delayed(const Duration(milliseconds: 500), () async {
              if (mounted && _playlist.length == 0) {
                final sources = queue
                    .map((s) => _createAudioSource(s))
                    .toList();
                _playlist = ConcatenatingAudioSource(children: sources);
                await _audioPlayer.setAudioSource(
                  _playlist,
                  initialIndex: state.currentIndex,
                  initialPosition: Duration.zero,
                );
              }
            });
          } else {
            state = state.copyWith(currentSong: lastSong);
          }
        } else {
          state = state.copyWith(currentSong: lastSong);
        }
      }
    } catch (e) {
      debugPrint('Error loading playback state: $e');
    }
  }

  Future<void> _savePlaybackState() async {
    try {
      final prefs = _ref.read(sharedPreferencesProvider);
      if (state.currentSong != null) {
        await prefs.setString(
          'last_played_song',
          jsonEncode(state.currentSong!.toMap()),
        );
      }
      if (state.queue.isNotEmpty) {
        await prefs.setString(
          'last_played_queue',
          jsonEncode(state.queue.map((s) => s.toMap()).toList()),
        );
        await prefs.setInt('last_played_index', state.currentIndex);
      }
    } catch (e) {
      debugPrint('Error saving playback state: $e');
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
      ArtworkCacheService.warmUp(song.url, song.id);
      if (song.lyrics.isEmpty) {
        _fetchLyrics(song, isWarmUp: true);
      }
    }
  }

  Future<void> _fetchLyrics(Song song, {bool isWarmUp = false}) async {
    try {
      final List<LyricLine> cachedLyrics = await LyricsService.getLyricsForSong(
        song,
      );
      if (cachedLyrics.isNotEmpty) {
        updateLyricsInState(song.id, cachedLyrics, isWarmUp);
        return;
      }

      final tag = await AudioTags.read(song.url);
      final String? lyricsText = tag?.lyrics;

      if (lyricsText != null && lyricsText.isNotEmpty) {
        final List<LyricLine> parsedLyrics = LyricsService.parse(lyricsText);

        if (parsedLyrics.isNotEmpty) {
          DatabaseService.saveLyrics(song.id, parsedLyrics);
          updateLyricsInState(song.id, parsedLyrics, isWarmUp);
        }
      }
    } catch (e) {
      if (!isWarmUp) debugPrint("Failed to fetch lyrics: $e");
    }
  }

  void updateLyricsInState(int songId, List<LyricLine> lyrics, bool isWarmUp) {
    if (!mounted) return;

    Song? updatedCurrentSong = state.currentSong;
    List<Song> updatedQueue = state.queue;
    bool changed = false;

    if (state.currentSong?.id == songId && state.currentSong!.lyrics.isEmpty) {
      updatedCurrentSong = state.currentSong!.copyWith(lyrics: lyrics);
      changed = true;
    }

    if (state.queue.any((s) => s.id == songId)) {
      bool queueChanged = false;
      final newQueue = state.queue.map((s) {
        if (s.id == songId && s.lyrics.isEmpty) {
          queueChanged = true;
          return s.copyWith(lyrics: lyrics);
        }
        return s;
      }).toList();

      if (queueChanged) {
        updatedQueue = newQueue;
        changed = true;
      }
    }

    if (changed) {
      state = state.copyWith(
        currentSong: updatedCurrentSong,
        queue: updatedQueue,
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
      final targetSong = song ?? state.currentSong;
      if (targetSong == null) return;

      // If no audio source is set (common after startup), we must call play() to load it
      if (_audioPlayer.audioSource == null ||
          (song != null && state.currentSong?.id != song.id)) {
        await play(targetSong);
      } else {
        await _audioPlayer.play();
      }
    }
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  Future<void> seekRelative(Duration offset) async {
    final newPosition = _audioPlayer.position + offset;
    final duration = _audioPlayer.duration ?? Duration.zero;
    if (newPosition < Duration.zero) {
      await _audioPlayer.seek(Duration.zero);
    } else if (newPosition > duration) {
      next();
    } else {
      await _audioPlayer.seek(newPosition);
    }
  }

  void next() {
    if (_audioPlayer.hasNext) {
      _audioPlayer.seekToNext();
    } else {
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
    _savePlaybackState();
  }

  Future<void> playPlaylist(List<Song> playlist, int index) async {
    await play(playlist[index], queue: playlist, index: index);
  }

  void updateFavoriteStatus(int songId, bool isFavorite) {
    Song? updatedCurrentSong = state.currentSong;
    if (state.currentSong?.id == songId) {
      updatedCurrentSong = state.currentSong!.copyWith(isFavorite: isFavorite);
    }

    final updatedQueue = state.queue.map((s) {
      if (s.id == songId) {
        return s.copyWith(isFavorite: isFavorite);
      }
      return s;
    }).toList();

    state = state.copyWith(
      currentSong: updatedCurrentSong,
      queue: updatedQueue,
    );
  }

  void updateSongMetadataInState(Song updatedSong) {
    if (!mounted) return;

    Song? updatedCurrentSong = state.currentSong;
    if (state.currentSong?.id == updatedSong.id) {
      updatedCurrentSong = updatedSong;
    }

    final updatedQueue = state.queue.map((s) {
      if (s.id == updatedSong.id) {
        return updatedSong;
      }
      return s;
    }).toList();

    state = state.copyWith(
      currentSong: updatedCurrentSong,
      queue: updatedQueue,
    );
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
    _savePlaybackState();
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
    _savePlaybackState();
  }

  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;
  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;

  void reorderQueue(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final newQueue = List<Song>.from(state.queue);
    final item = newQueue.removeAt(oldIndex);
    newQueue.insert(newIndex, item);

    int newCurrentIndex = state.currentIndex;
    if (oldIndex == state.currentIndex) {
      newCurrentIndex = newIndex;
    } else if (oldIndex < state.currentIndex &&
        newIndex >= state.currentIndex) {
      newCurrentIndex -= 1;
    } else if (oldIndex > state.currentIndex &&
        newIndex <= state.currentIndex) {
      newCurrentIndex += 1;
    }

    state = state.copyWith(queue: newQueue, currentIndex: newCurrentIndex);

    // Update the audio player's concatenating source
    try {
      await _playlist.move(oldIndex, newIndex);
      _savePlaybackState();
    } catch (e) {
      debugPrint('Error reordering playlist: $e');
    }
  }

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
