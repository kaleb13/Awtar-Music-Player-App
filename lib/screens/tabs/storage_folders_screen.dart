import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/library_provider.dart';
import '../../widgets/app_widgets.dart';

class StorageFoldersScreen extends ConsumerWidget {
  final String storageName;
  final String storageRoot;

  const StorageFoldersScreen({
    super.key,
    required this.storageName,
    required this.storageRoot,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryState = ref.watch(libraryProvider);
    final folders = libraryState.storageMap[storageRoot] ?? [];
    final isRefining = libraryState.isRefiningLibrary;

    // Auto-pop if this root is no longer in storageMap (meaning it was excluded)
    // We check libraryState.folders too as a secondary check
    final isStillVisible = libraryState.storageMap.containsKey(storageRoot);

    if (!isStillVisible && !isRefining && libraryState.folders.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) Navigator.of(context).pop();
      });
    }

    return Scaffold(
      backgroundColor: AppColors.mainDark,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context, folders.length),
                Expanded(
                  child: folders.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(24, 20, 24, 180),
                          itemCount: folders.length,
                          itemBuilder: (context, index) {
                            final folderPath = folders[index];
                            final folderName = folderPath.split('/').last;
                            final isExcluded = ref
                                .read(libraryProvider.notifier)
                                .isFolderExcluded(folderPath);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.03),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isExcluded
                                      ? Colors.white.withOpacity(0.05)
                                      : AppColors.primaryGreen.withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isExcluded
                                        ? Colors.white.withOpacity(0.05)
                                        : AppColors.primaryGreen.withOpacity(
                                            0.1,
                                          ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.folder,
                                    color: isExcluded
                                        ? Colors.white24
                                        : AppColors.primaryGreen,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  folderName,
                                  style: AppTextStyles.bodyMain.copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isExcluded
                                        ? Colors.white38
                                        : Colors.white,
                                  ),
                                ),
                                subtitle: Text(
                                  folderPath,
                                  style: AppTextStyles.caption.copyWith(
                                    fontSize: 10,
                                    color: isExcluded
                                        ? Colors.white24
                                        : Colors.white54,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Transform.scale(
                                  scale: 0.8,
                                  child: Switch(
                                    value: !isExcluded,
                                    activeThumbColor: AppColors.primaryGreen,
                                    inactiveThumbColor: Colors.white24,
                                    inactiveTrackColor: Colors.white
                                        .withOpacity(0.1),
                                    onChanged: (value) async {
                                      await ref
                                          .read(libraryProvider.notifier)
                                          .toggleFolderExclusion(folderPath);
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          if (isRefining) _buildRefiningOverlay(libraryState.refineProgress),
        ],
      ),
    );
  }

  Widget _buildRefiningOverlay(double progress) {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.primaryGreen),
            const SizedBox(height: 16),
            Text("Refining Library...", style: AppTextStyles.titleMedium),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white10,
                valueColor: const AlwaysStoppedAnimation(
                  AppColors.primaryGreen,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          AppIconButton(
            icon: Icons.arrow_back,
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(storageName, style: AppTextStyles.titleMedium),
              Text(
                "$count Music Folders Found",
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primaryGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.music_off, size: 64, color: Colors.white12),
          const SizedBox(height: 16),
          Text(
            "No music detected in this source",
            style: AppTextStyles.bodyMain.copyWith(color: Colors.white54),
          ),
        ],
      ),
    );
  }
}
