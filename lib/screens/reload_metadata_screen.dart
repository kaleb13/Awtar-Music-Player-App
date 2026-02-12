import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/library_provider.dart';
import '../widgets/app_widgets.dart';

class ReloadMetadataScreen extends ConsumerWidget {
  const ReloadMetadataScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryState = ref.watch(libraryProvider);
    final isReloading = libraryState.isReloadingMetadata;
    final progress = libraryState.metadataLoadProgress;

    return Scaffold(
      backgroundColor: AppColors.mainDark,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  AppIconButton(
                    icon: Icons.arrow_back,
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 16),
                  Text("Metadata Recovery", style: AppTextStyles.titleMedium),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withOpacity(0.05),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primaryGreen.withOpacity(0.1),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.settings_backup_restore_rounded,
                        size: 80,
                        color: isReloading
                            ? AppColors.primaryGreen
                            : Colors.white24,
                      ),
                    ),
                    const SizedBox(height: 48),
                    Text(
                      isReloading
                          ? "Reloading Collection..."
                          : "System Refresh",
                      style: AppTextStyles.titleLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Update song tags, album art, and lyrics from your local storage. This will rebuild your music library metadata.",
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white54,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 64),
                    if (isReloading) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: Colors.white10,
                          valueColor: const AlwaysStoppedAnimation(
                            AppColors.primaryGreen,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "${(progress * 100).toInt()}% Complete",
                        style: const TextStyle(
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ] else
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: () {
                            ref.read(libraryProvider.notifier).reloadMetadata();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            "START RELOAD",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    if (!isReloading)
                      Text(
                        "Last sync: ${DateTime.now().hour}:${DateTime.now().minute}",
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white12,
                        ),
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
}
