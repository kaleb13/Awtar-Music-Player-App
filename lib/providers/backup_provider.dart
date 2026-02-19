import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/backup_service.dart';

enum BackupStatus { idle, backingUp, restoring, success, error }

class BackupState {
  final BackupStatus status;
  final double progress;
  final String? message;
  final String? errorMessage;

  BackupState({
    this.status = BackupStatus.idle,
    this.progress = 0.0,
    this.message,
    this.errorMessage,
  });

  BackupState copyWith({
    BackupStatus? status,
    double? progress,
    String? message,
    String? errorMessage,
  }) {
    return BackupState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      message: message,
      errorMessage: errorMessage,
    );
  }
}

class BackupNotifier extends StateNotifier<BackupState> {
  final Ref _ref;

  BackupNotifier(this._ref) : super(BackupState());

  Future<void> exportBackup() async {
    state = state.copyWith(
      status: BackupStatus.backingUp,
      progress: 0.1,
      message: "Preparing data...",
    );

    try {
      // We can add intermediate progress steps here if needed
      final path = await BackupService.exportBackup(_ref);

      state = state.copyWith(
        status: BackupStatus.success,
        progress: 1.0,
        message: "Backup exported successfully!\nSaved to: $path",
      );
    } catch (e) {
      state = state.copyWith(
        status: BackupStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> importBackup() async {
    try {
      final backup = await BackupService.pickBackupFile();
      if (backup == null) return;

      state = state.copyWith(
        status: BackupStatus.restoring,
        progress: 0.1,
        message: "Reading backup file...",
      );

      // We'll perform restoration in steps to show progress
      await BackupService.restoreBackupWithProgress(_ref, backup, (
        progress,
        message,
      ) {
        state = state.copyWith(progress: progress, message: message);
      });

      state = state.copyWith(
        status: BackupStatus.success,
        progress: 1.0,
        message: "Data restored successfully!",
      );
    } catch (e) {
      state = state.copyWith(
        status: BackupStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void reset() {
    state = BackupState();
  }
}

final backupProvider = StateNotifierProvider<BackupNotifier, BackupState>((
  ref,
) {
  return BackupNotifier(ref);
});

