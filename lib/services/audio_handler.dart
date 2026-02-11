import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';

/// Audio handler that manages the background audio playback
/// and media notification controls
/// This handler doesn't play audio itself - it delegates to the main player
class AudioPlayerHandler extends BaseAudioHandler with SeekHandler {
  // Callback functions to communicate with the main player
  Function()? onPlayPressed;
  Function()? onPausePressed;
  Function()? onNext;
  Function()? onPrevious;
  Function(Duration)? onSeekPressed;

  AudioPlayerHandler() {
    // Set initial playback state
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: AudioProcessingState.idle,
        playing: false,
      ),
    );
  }

  /// Update the media item displayed in the notification
  Future<void> setMediaItem({
    required String id,
    required String title,
    required String artist,
    String? album,
    Uri? artUri,
    Duration? duration,
  }) async {
    final newMediaItem = MediaItem(
      id: id,
      title: title,
      artist: artist,
      album: album,
      artUri: artUri,
      duration: duration,
    );

    mediaItem.add(newMediaItem);

    // Also update playback state to ready when we have a media item
    playbackState.add(
      playbackState.value.copyWith(processingState: AudioProcessingState.ready),
    );
  }

  /// Update playback state and position
  void updatePlaybackState({
    required bool playing,
    Duration? position,
    Duration? bufferedPosition,
  }) {
    final controls = playing
        ? [
            MediaControl.skipToPrevious,
            MediaControl.pause,
            MediaControl.skipToNext,
          ]
        : [
            MediaControl.skipToPrevious,
            MediaControl.play,
            MediaControl.skipToNext,
          ];

    playbackState.add(
      playbackState.value.copyWith(
        controls: controls,
        androidCompactActionIndices: const [0, 1, 2],
        playing: playing,
        updatePosition: position ?? playbackState.value.position,
        bufferedPosition:
            bufferedPosition ?? playbackState.value.bufferedPosition,
        processingState: AudioProcessingState.ready,
      ),
    );
  }

  @override
  Future<void> play() async {
    try {
      debugPrint('AudioHandler: play() called');
      // Update state immediately for UI responsiveness
      updatePlaybackState(playing: true);
      onPlayPressed?.call();
    } catch (e) {
      debugPrint('Error in play: $e');
    }
  }

  @override
  Future<void> pause() async {
    try {
      debugPrint('AudioHandler: pause() called');
      // Update state immediately for UI responsiveness
      updatePlaybackState(playing: false);
      onPausePressed?.call();
    } catch (e) {
      debugPrint('Error in pause: $e');
    }
  }

  @override
  Future<void> seek(Duration position) async {
    try {
      debugPrint('AudioHandler: seek($position) called');
      onSeekPressed?.call(position);
    } catch (e) {
      debugPrint('Error in seek: $e');
    }
  }

  @override
  Future<void> skipToNext() async {
    try {
      debugPrint('AudioHandler: skipToNext() called');
      onNext?.call();
    } catch (e) {
      debugPrint('Error in skipToNext: $e');
    }
  }

  @override
  Future<void> skipToPrevious() async {
    try {
      debugPrint('AudioHandler: skipToPrevious() called');
      onPrevious?.call();
    } catch (e) {
      debugPrint('Error in skipToPrevious: $e');
    }
  }

  @override
  Future<void> stop() async {
    try {
      debugPrint('AudioHandler: stop() called');
      await super.stop();
    } catch (e) {
      debugPrint('Error in stop: $e');
    }
  }
}
