import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/song.dart';

class MusicPlayerState {
  final Song? currentSong;
  final bool isPlaying;
  final Duration position;
  final Duration duration;

  MusicPlayerState({
    this.currentSong,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
  });

  MusicPlayerState copyWith({
    Song? currentSong,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
  }) {
    return MusicPlayerState(
      currentSong: currentSong ?? this.currentSong,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
    );
  }
}

class PlayerNotifier extends StateNotifier<MusicPlayerState> {
  final ap.AudioPlayer _audioPlayer = ap.AudioPlayer();

  PlayerNotifier() : super(MusicPlayerState()) {
    _audioPlayer.onPositionChanged.listen((pos) {
      state = state.copyWith(position: pos);
    });

    _audioPlayer.onDurationChanged.listen((dur) {
      state = state.copyWith(duration: dur);
    });

    _audioPlayer.onPlayerStateChanged.listen((s) {
      state = state.copyWith(isPlaying: s == ap.PlayerState.playing);
    });
  }

  Future<void> play(Song song) async {
    if (state.currentSong?.url == song.url) {
      await _audioPlayer.resume();
    } else {
      state = state.copyWith(currentSong: song);
      await _audioPlayer.play(ap.UrlSource(song.url));
    }
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }
}

final playerProvider = StateNotifierProvider<PlayerNotifier, MusicPlayerState>((
  ref,
) {
  return PlayerNotifier();
});

final sampleSongProvider = Provider<Song>((ref) {
  return Song(
    title: "God's Plan",
    artist: "Drake",
    albumArt:
        "https://images.genius.com/f9c8d5d4a13f683495441315664556a3.1000x1000x1.jpg",
    url:
        "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3", // Sample MP3
    lyrics: [
      LyricLine(time: Duration(seconds: 0), text: "[intro]"),
      LyricLine(
        time: Duration(seconds: 5),
        text: "And they wishin' and wishin'",
      ),
      LyricLine(time: Duration(seconds: 10), text: "And wishin' and wishin'"),
      LyricLine(time: Duration(seconds: 15), text: "They wishin' on me, yuh"),
      LyricLine(time: Duration(seconds: 20), text: "[verse 1]"),
      LyricLine(
        time: Duration(seconds: 25),
        text: "I been movin' calm, don't start",
      ),
      LyricLine(time: Duration(seconds: 30), text: "No trouble with me"),
      LyricLine(
        time: Duration(seconds: 35),
        text: "Tryna keep it peaceful is a struggle for me",
      ),
      LyricLine(
        time: Duration(seconds: 40),
        text: "Don't pull up at 6 AM to cuddle with me",
      ),
      LyricLine(
        time: Duration(seconds: 45),
        text: "You know how I like it when you lovin'",
      ),
      LyricLine(
        time: Duration(seconds: 50),
        text: "I don't wanna die for them to miss me",
      ),
    ],
  );
});
