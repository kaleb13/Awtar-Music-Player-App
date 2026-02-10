import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/library_provider.dart';
import '../details/folder_details_screen.dart';

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

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.mainGradient),
        child: Column(
          children: [
            _buildHeader(context, folders.length),
            Expanded(
              child: folders.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 20,
                      ),
                      itemCount: folders.length,
                      itemBuilder: (context, index) {
                        final folderPath = folders[index];
                        final folderName = folderPath.split('/').last;

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.folder,
                              color: AppColors.accentYellow,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            folderName,
                            style: AppTextStyles.bodyMain.copyWith(
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            folderPath,
                            style: AppTextStyles.caption.copyWith(fontSize: 10),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: Colors.white24,
                            size: 16,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FolderDetailsScreen(
                                  folderPath: folderPath,
                                  folderName: folderName,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int count) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
      color: Colors.white.withOpacity(0.03),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            padding: EdgeInsets.zero,
            alignment: Alignment.centerLeft,
          ),
          const SizedBox(height: 20),
          Text(storageName, style: AppTextStyles.titleLarge),
          const SizedBox(height: 4),
          Text(
            "$count Music Folders Found",
            style: AppTextStyles.bodySmall.copyWith(color: Colors.white60),
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
