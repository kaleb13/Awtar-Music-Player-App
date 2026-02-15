import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/library_provider.dart';
import '../widgets/app_widgets.dart';

class RescanLibraryScreen extends ConsumerWidget {
  const RescanLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryState = ref.watch(libraryProvider);
    final isLoading = libraryState.isLoading;
    final progress = libraryState.scanProgress;

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
                  Text("Storage Scanner", style: AppTextStyles.titleMedium),
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
                        color: AppColors.accentBlue.withOpacity(0.05),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.accentBlue.withOpacity(0.1),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.radar_rounded,
                        size: 80,
                        color: isLoading
                            ? AppColors.accentBlue
                            : Colors.white24,
                      ),
                    ),
                    const SizedBox(height: 48),
                    Text(
                      isLoading ? "Discovering Tracks..." : "Library Scan",
                      style: AppTextStyles.titleLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Scan your device for new audio files. This will update your collection with any recently added music across all your storage drives.",
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white54,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 64),
                    if (isLoading) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: Colors.white10,
                          valueColor: const AlwaysStoppedAnimation(
                            AppColors.accentBlue,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "${(progress * 100).toInt()}% Searched",
                        style: const TextStyle(
                          color: AppColors.accentBlue,
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
                            ref
                                .read(libraryProvider.notifier)
                                .scanLibrary(force: true);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            "RUN SCAN",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    if (!isLoading)
                      Text(
                        "Last scan complete",
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
