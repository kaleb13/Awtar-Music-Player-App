import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/backup_provider.dart';
import '../widgets/app_widgets.dart';

class BackupRestoreScreen extends ConsumerWidget {
  const BackupRestoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backupState = ref.watch(backupProvider);

    return Scaffold(
      backgroundColor: AppColors.mainDark,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  AppIconButton(
                    icon: Icons.arrow_back,
                    onTap: () {
                      ref.read(backupProvider.notifier).reset();
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(width: 16),
                  Text("Backup & Restore", style: AppTextStyles.titleMedium),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Data Portability",
                      style: AppTextStyles.titleLarge.copyWith(
                        color: AppColors.accentBlue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Export your music library data to a portable file or restore from a previous backup.",
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white54,
                      ),
                    ),
                    const SizedBox(height: 48),
                    if (backupState.status == BackupStatus.idle ||
                        backupState.status == BackupStatus.success ||
                        backupState.status == BackupStatus.error)
                      _buildActionButtons(context, ref, backupState),

                    if (backupState.status == BackupStatus.backingUp ||
                        backupState.status == BackupStatus.restoring)
                      _buildProgressSection(backupState),

                    if (backupState.errorMessage != null)
                      _buildErrorDisplay(backupState.errorMessage!),

                    if (backupState.status == BackupStatus.success)
                      _buildSuccessDisplay(
                        backupState.message ?? "Operation completed!",
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    BackupState state,
  ) {
    return Column(
      children: [
        _buildOptionCard(
          title: "Back Up Data",
          subtitle:
              "Create a portable JSON file with your play stats, favorites, and playlists.",
          icon: Icons.cloud_upload_outlined,
          onTap: () => ref.read(backupProvider.notifier).exportBackup(),
        ),
        const SizedBox(height: 16),
        _buildOptionCard(
          title: "Restore Data",
          subtitle: "Import your data from an Awtar Music Player backup file.",
          icon: Icons.settings_backup_restore,
          onTap: () async {
            final proceed = await _showRestoreConfirmation(context);
            if (proceed == true) {
              ref.read(backupProvider.notifier).importBackup();
            }
          },
        ),
      ],
    );
  }

  Widget _buildOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accentBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.accentBlue),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.white24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSection(BackupState state) {
    return Column(
      children: [
        const SizedBox(height: 24),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: state.progress,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            valueColor: const AlwaysStoppedAnimation(AppColors.accentBlue),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          state.message ?? "Processing...",
          style: AppTextStyles.bodyMain,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          "${(state.progress * 100).toInt()}%",
          style: AppTextStyles.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.accentBlue,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorDisplay(String error) {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessDisplay(String message) {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.greenAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.greenAccent, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showRestoreConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161618),
        title: const Text("Restore Backup?"),
        content: const Text(
          "This will overwrite your current play stats and playlists. App settings will also be updated. Continue?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Restore",
              style: TextStyle(color: AppColors.accentBlue),
            ),
          ),
        ],
      ),
    );
  }
}

