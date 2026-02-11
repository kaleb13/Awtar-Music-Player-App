import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/library_provider.dart';
import '../widgets/app_widgets.dart';
import '../providers/performance_provider.dart';
import 'hidden_assets_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

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
            const SizedBox(height: 16),
            if (libraryState.errorMessage != null &&
                libraryState.errorMessage!.contains("restart"))
              Container(
                color: Colors.red.withOpacity(0.2),
                padding: const EdgeInsets.all(8),
                width: double.infinity,
                child: Text(
                  libraryState.errorMessage!,
                  style: const TextStyle(color: Colors.redAccent),
                  textAlign: TextAlign.center,
                ),
              ),
            if (libraryState.completionMessage != null)
              Container(
                color: Colors.green.withOpacity(0.2),
                padding: const EdgeInsets.all(8),
                width: double.infinity,
                child: Text(
                  libraryState.completionMessage!,
                  style: const TextStyle(color: Colors.greenAccent),
                  textAlign: TextAlign.center,
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  AppIconButton(
                    icon: Icons.arrow_back,
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 16),
                  Text("Settings", style: AppTextStyles.titleMedium),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                children: [
                  _buildSettingsSection(
                    title: "Performance",
                    children: [
                      SwitchListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 8,
                        ),
                        secondary: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.speed, color: Colors.white),
                        ),
                        title: const Text(
                          "Low Performance Mode",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: const Text(
                          "Reduce visual effects for better performance",
                          style: TextStyle(color: Colors.white54, fontSize: 14),
                        ),
                        value: ref.watch(lowPerformanceModeProvider),
                        activeColor: AppColors.accentYellow,
                        onChanged: (value) {
                          ref
                              .read(lowPerformanceModeProvider.notifier)
                              .toggle();
                        },
                      ),
                    ],
                  ),
                  _buildSettingsSection(
                    title: "Library",
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 8,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.search, color: Colors.white),
                        ),
                        title: const Text(
                          "Rescan Library",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: libraryState.isLoading
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  LinearProgressIndicator(
                                    value: libraryState.scanProgress,
                                    backgroundColor: Colors.white10,
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          AppColors.primaryGreen,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${(libraryState.scanProgress * 100).toInt()}%",
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              )
                            : const Text(
                                "Search for new audio files",
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 14,
                                ),
                              ),
                        trailing: libraryState.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primaryGreen,
                                ),
                              )
                            : const Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.white54,
                              ),
                        onTap: libraryState.isLoading
                            ? null
                            : () => ref
                                  .read(libraryProvider.notifier)
                                  .scanLibrary(force: true),
                      ),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 8,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.refresh, color: Colors.white),
                        ),
                        title: const Text(
                          "Reload Metadata",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: isReloading
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: Colors.white10,
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          AppColors.accentYellow,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${(progress * 100).toInt()}%",
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              )
                            : const Text(
                                "Refresh all songs and lyrics",
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 14,
                                ),
                              ),
                        onTap: isReloading
                            ? null
                            : () {
                                ref
                                    .read(libraryProvider.notifier)
                                    .reloadMetadata();
                              },
                        trailing: isReloading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.accentYellow,
                                ),
                              )
                            : const Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.white54,
                              ),
                      ),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 8,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.visibility_off,
                            color: Colors.white,
                          ),
                        ),
                        title: const Text(
                          "Hidden Content",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: const Text(
                          "Manage hidden artists and albums",
                          style: TextStyle(color: Colors.white54, fontSize: 14),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.white54,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HiddenAssetsScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.accentYellow,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
        ...children,
        const Divider(color: Colors.white10, height: 32),
      ],
    );
  }
}
