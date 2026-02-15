import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/library_provider.dart';
import '../../models/song.dart';
import '../../widgets/color_aware_album_card.dart';
import '../details/album_details_screen.dart';
import '../../widgets/app_widgets.dart';
import '../../providers/navigation_provider.dart';
import '../../services/media_menu_service.dart';
import '../../providers/album_selection_provider.dart';

class AlbumsTab extends ConsumerWidget {
  const AlbumsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelectionMode = ref.watch(isAlbumSelectionModeProvider);
    final selectedIds = ref.watch(selectedAlbumIdsProvider);

    final albums = ref.watch(
      libraryProvider.select(
        (s) => s.albums.where((a) {
          final key = "${a.album}_${a.artist}";
          if (s.hiddenAlbums.contains(key)) return false;
          if (s.hideSmallAlbums && a.numberOfSongs < 3) return false;
          return true;
        }).toList(),
      ),
    );

    final permissionStatus = ref.watch(
      libraryProvider.select((s) => s.permissionStatus),
    );
    final isLoading = ref.watch(libraryProvider.select((s) => s.isLoading));

    if (permissionStatus != LibraryPermissionStatus.granted) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            const Text(
              "Storage access required",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              "To see your albums, please grant storage permission",
              style: TextStyle(color: Colors.white54, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () =>
                  ref.read(libraryProvider.notifier).requestPermission(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentBlue,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text("Grant Permission"),
            ),
          ],
        ),
      );
    }

    if (albums.isEmpty && !isLoading) {
      return const Center(
        child: Text(
          "No albums found on your device",
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    final representativeAlbumSongs = ref.watch(
      libraryProvider.select((s) => s.representativeAlbumSongs),
    );
    final songs = ref.watch(libraryProvider.select((s) => s.songs));

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 180),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.65, // Comfortable ratio for compact style
      ),
      itemCount: albums.length,
      itemBuilder: (context, index) {
        final album = albums[index];
        final albumKey = "${album.album}_${album.artist}";
        final isSelected = selectedIds.contains(albumKey);

        final representativeSongId = representativeAlbumSongs[albumKey];
        final albumSong = songs.firstWhere(
          (s) => s.id == representativeSongId,
          orElse: () => songs.isNotEmpty
              ? songs.first
              : Song(
                  id: 0,
                  title: "",
                  url: "",
                  artist: "",
                  duration: 0,
                  lyrics: [],
                ),
        );

        return Stack(
          children: [
            ColorAwareAlbumCard(
              title: album.album,
              artist: album.artist,
              songId: albumSong.id,
              songPath: albumSong.url,
              size: 100, // Reduced from 140 to fix overflow
              flexible: true, // Use flexible scaling
              isPortrait: false, // Ensure square 'compact' shape
              showThreeDotsMenu: true,
              onTap: () {
                if (isSelectionMode) {
                  final newSet = Set<String>.from(selectedIds);
                  if (isSelected) {
                    newSet.remove(albumKey);
                  } else {
                    newSet.add(albumKey);
                  }
                  ref.read(selectedAlbumIdsProvider.notifier).state = newSet;
                } else {
                  ref.read(bottomNavVisibleProvider.notifier).state = false;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AlbumDetailsScreen(
                        title: album.album,
                        artist: album.artist,
                        imageUrl: "",
                      ),
                    ),
                  ).then((_) {
                    ref.read(bottomNavVisibleProvider.notifier).state = true;
                  });
                }
              },
              onLongPress: () {
                AppCenteredModal.show(
                  context,
                  title: album.album,
                  items: [
                    ...MediaMenuService.buildAlbumActions(
                      context: context,
                      ref: ref,
                      album: album,
                    ),
                    AppModalItem(
                      icon: Icons.visibility_off_outlined,
                      label: "Hide Album",
                      onTap: () {
                        final key = "${album.album}_${album.artist}";
                        ref
                            .read(libraryProvider.notifier)
                            .toggleAlbumVisibility(key);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Hidden ${album.album}"),
                            action: SnackBarAction(
                              label: "Undo",
                              onPressed: () {
                                ref
                                    .read(libraryProvider.notifier)
                                    .toggleAlbumVisibility(key);
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
              menuBuilder: (context) => MediaMenuService.buildAlbumMenuItems(
                context: context,
                ref: ref,
                album: album,
              ),
            ),
            if (isSelectionMode)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.accentBlue
                        : Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Icon(
                      Icons.check,
                      size: 16,
                      color: isSelected ? Colors.black : Colors.transparent,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
