import 'package:audiotags/audiotags.dart';
import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/song.dart';
import 'stats_provider.dart';

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

  PlayerNotifier(this._ref) : super(MusicPlayerState()) {
    _audioPlayer.onPositionChanged.listen((pos) {
      state = state.copyWith(position: pos);
      _checkTracking(pos);
    });

    _audioPlayer.onDurationChanged.listen((dur) {
      state = state.copyWith(duration: dur);
    });

    _audioPlayer.onPlayerStateChanged.listen((s) {
      state = state.copyWith(isPlaying: s == ap.PlayerState.playing);
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
    final newQueue = queue ?? state.queue;
    final newIndex =
        index ?? (queue != null ? queue.indexOf(song) : state.currentIndex);

    state = state.copyWith(
      currentSong: song,
      queue: newQueue,
      currentIndex: newIndex,
    );

    _ref
        .read(statsProvider.notifier)
        .recordPlay(song.id, song.artist, song.album ?? "Unknown");

    await _audioPlayer.play(ap.DeviceFileSource(song.url));

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

  void toggleRepeat() {
    final nextMode = RepeatMode
        .values[(state.repeatMode.index + 1) % RepeatMode.values.length];
    state = state.copyWith(repeatMode: nextMode);
  }
}

final playerProvider = StateNotifierProvider<PlayerNotifier, MusicPlayerState>((
  ref,
) {
  return PlayerNotifier(ref);
});
