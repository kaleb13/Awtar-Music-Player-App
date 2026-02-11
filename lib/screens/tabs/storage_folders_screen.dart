import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/library_provider.dart';
import '../../providers/player_provider.dart';
import '../../widgets/app_artwork.dart';
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
    final playerState = ref.watch(playerProvider);
    final currentSong = playerState.currentSong;
    final folders = libraryState.storageMap[storageRoot] ?? [];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 1. Dynamic Blurred Background
          if (currentSong != null)
            Positioned.fill(
              child: AppArtwork(songId: currentSong.id, fit: BoxFit.cover),
            ),

          if (currentSong != null)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(color: Colors.transparent),
              ),
            ),

          // 2. Gradient Overlay (90% opacity)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.mainDarkLight.withOpacity(0.9),
                    AppColors.mainDark.withOpacity(0.9),
                  ],
                ),
              ),
            ),
          ),

          // 3. Main Content
          SafeArea(
            top: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                            final isExcluded = ref
                                .read(libraryProvider.notifier)
                                .isFolderExcluded(folderPath);

                            return ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.04),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isExcluded
                                          ? Colors.white.withOpacity(0.05)
                                          : AppColors.primaryGreen.withOpacity(
                                              0.1,
                                            ),
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
                                            : AppColors.accentYellow
                                                  .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.folder,
                                        color: isExcluded
                                            ? Colors.white24
                                            : AppColors.accentYellow,
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
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Transform.scale(
                                          scale: 0.8,
                                          child: Switch(
                                            value: !isExcluded,
                                            activeThumbColor: AppColors.primaryGreen,
                                            inactiveThumbColor: Colors.white24,
                                            inactiveTrackColor: Colors.white
                                                .withOpacity(0.1),
                                            onChanged: (value) {
                                              ref
                                                  .read(
                                                    libraryProvider.notifier,
                                                  )
                                                  .toggleFolderExclusion(
                                                    folderPath,
                                                  );
                                            },
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.chevron_right,
                                            color: Colors.white24,
                                            size: 20,
                                          ),
                                          onPressed: isExcluded
                                              ? null
                                              : () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          FolderDetailsScreen(
                                                            folderPath:
                                                                folderPath,
                                                            folderName:
                                                                folderName,
                                                          ),
                                                    ),
                                                  );
                                                },
                                        ),
                                      ],
                                    ),
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
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int count) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            border: Border(
              bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
            ),
          ),
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
        ),
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
