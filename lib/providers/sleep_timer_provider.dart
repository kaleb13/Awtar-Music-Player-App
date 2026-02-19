import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'player_provider.dart';

class SleepTimerState {
  final Duration? remainingTime;
  final bool finishLastTrack;
  final bool isActive;

  SleepTimerState({
    this.remainingTime,
    this.finishLastTrack = false,
    this.isActive = false,
  });

  SleepTimerState copyWith({
    Duration? remainingTime,
    bool? finishLastTrack,
    bool? isActive,
  }) {
    return SleepTimerState(
      remainingTime: remainingTime ?? this.remainingTime,
      finishLastTrack: finishLastTrack ?? this.finishLastTrack,
      isActive: isActive ?? this.isActive,
    );
  }

  String get remainingTimeString {
    if (remainingTime == null) return "00:00";
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(remainingTime!.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(remainingTime!.inSeconds.remainder(60));
    if (remainingTime!.inHours > 0) {
      return "${twoDigits(remainingTime!.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    }
    return "$twoDigitMinutes:$twoDigitSeconds";
  }
}

class SleepTimerNotifier extends StateNotifier<SleepTimerState> {
  final Ref _ref;
  Timer? _timer;

  SleepTimerNotifier(this._ref) : super(SleepTimerState()) {
    // Listen to song changes to handle "Finish last track"
    _ref.listen(playerProvider.select((s) => s.currentSong?.id), (prev, next) {
      if (state.isActive &&
          state.remainingTime == Duration.zero &&
          state.finishLastTrack) {
        if (prev != null && next != prev) {
          _stopPlayback();
        }
      }
    });
  }

  void setTimer(Duration duration, bool finishLastTrack) {
    _timer?.cancel();
    state = SleepTimerState(
      remainingTime: duration,
      finishLastTrack: finishLastTrack,
      isActive: true,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingTime == null || state.remainingTime!.inSeconds <= 0) {
        _onTimerExpired();
      } else {
        state = state.copyWith(
          remainingTime: state.remainingTime! - const Duration(seconds: 1),
        );
      }
    });
  }

  void cancelTimer() {
    _timer?.cancel();
    state = SleepTimerState();
  }

  void _onTimerExpired() {
    _timer?.cancel();

    if (state.finishLastTrack) {
      state = state.copyWith(remainingTime: Duration.zero);
      // Wait for song change listener to trigger stop
    } else {
      _stopPlayback();
    }
  }

  void _stopPlayback() {
    _ref.read(playerProvider.notifier).pause();
    state = SleepTimerState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final sleepTimerProvider =
    StateNotifierProvider<SleepTimerNotifier, SleepTimerState>((ref) {
      return SleepTimerNotifier(ref);
    });

