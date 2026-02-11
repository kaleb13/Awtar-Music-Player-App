import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/library_provider.dart';
import '../../providers/player_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_artwork.dart';
import '../../models/song.dart';

class FolderDetailsScreen extends ConsumerWidget {
  final String folderPath;
  final String folderName;

  const FolderDetailsScreen({
    super.key,
    required this.folderPath,
    required this.folderName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(libraryProvider);
    final playerState = ref.watch(playerProvider);
    final currentSong = playerState.currentSong;

    // Filter songs that are contained within this folder (at any depth)
    final allSongsInFolder = library.songs
        .where((s) => s.url.startsWith(folderPath))
        .toList();

    // Identify immediate songs vs immediate subfolders
    final List<Song> immediateSongs = [];
    final Set<String> directSubfolders = {};

    for (final song in allSongsInFolder) {
      final songUrl = song.url;
      final relativePath = songUrl.substring(folderPath.length);
      final parts = relativePath.split('/').where((p) => p.isNotEmpty).toList();

      if (parts.length == 1) {
        // This song is directly in folderPath
        immediateSongs.add(song);
      } else if (parts.length > 1) {
        // This song is in a subfolder. The first part is the immediate subfolder.
        directSubfolders.add(parts.first);
      }
    }

    final sortedSubfolders = directSubfolders.toList()..sort();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 1. Dynamic Blurred Background
          if (currentSong != null)
            Positioned.fill(
              child: AppArtwork(
                songId: currentSong.id,
                songPath: currentSong.url,
                fit: BoxFit.cover,
              ),
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
                _buildHeader(context, allSongsInFolder.length),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    children: [
                      if (sortedSubfolders.isNotEmpty) ...[
                        Text(
                          "FOLDERS",
                          style: AppTextStyles.caption.copyWith(
                            letterSpacing: 2,
                            color: Colors.white24,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...sortedSubfolders.map((subName) {
                          final subPath = "$folderPath/$subName";
                          // Count songs in this subfolder for subtext
                          final subCount = allSongsInFolder
                              .where((s) => s.url.startsWith(subPath))
                              .length;

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.folder,
                                color: AppColors.accentYellow,
                                size: 18,
                              ),
                            ),
                            title: Text(
                              subName,
                              style: AppTextStyles.bodyMain.copyWith(
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              "$subCount Tracks",
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 10,
                              ),
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
                                    folderPath: subPath,
                                    folderName: subName,
                                  ),
                                ),
                              );
                            },
                          );
                        }),
                        const SizedBox(height: 32),
                      ],
                      if (immediateSongs.isNotEmpty) ...[
                        Text(
                          "TRACKS",
                          style: AppTextStyles.caption.copyWith(
                            letterSpacing: 2,
                            color: Colors.white24,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...immediateSongs.map(
                          (song) => _buildSongItem(ref, song),
                        ),
                      ],
                      if (sortedSubfolders.isEmpty && immediateSongs.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 100),
                            child: Text(
                              "Empty Folder",
                              style: AppTextStyles.bodyMain.copyWith(
                                color: Colors.white24,
                              ),
                            ),
                          ),
                        ),
                    ],
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
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accentYellow.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.folder,
                  color: AppColors.accentYellow,
                  size: 40,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      folderName,
                      style: AppTextStyles.titleLarge,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$count Songs in total",
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            folderPath,
            style: AppTextStyles.caption.copyWith(
              color: Colors.white24,
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSongItem(WidgetRef ref, Song song) {
    return ListTile(
      onTap: () => ref.read(playerProvider.notifier).play(song),
      contentPadding: const EdgeInsets.only(bottom: 16),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AppArtwork(songId: song.id, songPath: song.url, size: 50),
      ),
      title: Text(
        song.title,
        style: AppTextStyles.bodyMain.copyWith(fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        song.artist,
        style: AppTextStyles.bodySmall.copyWith(color: Colors.white38),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.more_vert, color: Colors.white24, size: 20),
    );
  }
}
