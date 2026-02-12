import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/library_provider.dart';
import '../../models/song.dart';
import '../../widgets/color_aware_album_card.dart';
import '../details/album_details_screen.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/player_provider.dart';
import '../details/artist_details_screen.dart';

class AlbumsTab extends ConsumerWidget {
  const AlbumsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryState = ref.watch(libraryProvider);
    // Filter hidden albums
    final albums = libraryState.albums
        .where(
          (a) => !libraryState.hiddenAlbums.contains("${a.album}_${a.artist}"),
        )
        .toList();

    if (libraryState.permissionStatus != LibraryPermissionStatus.granted) {
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
                backgroundColor: AppColors.accentYellow,
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

    if (albums.isEmpty && !libraryState.isLoading) {
      return const Center(
        child: Text(
          "No albums found on your device",
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

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
        final albumSong = libraryState.songs.firstWhere(
          (s) => s.album == album.album,
          orElse: () => libraryState.songs.isNotEmpty
              ? libraryState.songs.first
              : Song(
                  id: 0,
                  title: "",
                  url: "",
                  artist: "",
                  duration: 0,
                  lyrics: [],
                ),
        );

        return ColorAwareAlbumCard(
          title: album.album,
          artist: album.artist,
          songId: albumSong.id,
          songPath: albumSong.url,
          size: 100, // Reduced from 140 to fix overflow
          flexible: true, // Use flexible scaling
          isPortrait: false, // Ensure square 'compact' shape
          showThreeDotsMenu: true,
          onTap: () {
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
          },
          menuBuilder: (context) => [
            const PopupMenuItem(
              value: 'play',
              child: Row(
                children: [
                  Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 12),
                  Text("Play Album", style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'play_next',
              child: Row(
                children: [
                  Icon(
                    Icons.playlist_play_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Text("Play Next", style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'queue',
              child: Row(
                children: [
                  Icon(
                    Icons.queue_music_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Text("Add to Queue", style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'artist',
              child: Row(
                children: [
                  Icon(Icons.person_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 12),
                  Text("Artist Details", style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'hide',
              child: Row(
                children: [
                  Icon(
                    Icons.visibility_off_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Text("Hide Album", style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ],
          onMenuSelected: (value) async {
            final albumSongs = libraryState.songs
                .where((s) => s.album == album.album)
                .toList();

            if (value == 'play') {
              ref.read(playerProvider.notifier).playPlaylist(albumSongs, 0);
            } else if (value == 'play_next') {
              ref.read(playerProvider.notifier).addNext(albumSongs);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Playing ${album.album} next"),
                  backgroundColor: AppColors.primaryGreen,
                ),
              );
            } else if (value == 'queue') {
              ref.read(playerProvider.notifier).addToQueue(albumSongs);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Added ${album.album} to queue"),
                  backgroundColor: AppColors.primaryGreen,
                ),
              );
            } else if (value == 'artist') {
              ref.read(bottomNavVisibleProvider.notifier).state = false;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ArtistDetailsScreen(name: album.artist, imageUrl: ""),
                ),
              ).then((_) {
                ref.read(bottomNavVisibleProvider.notifier).state = true;
              });
            } else if (value == 'hide') {
              _showHideDialog(context, ref, album.album, album.artist);
            }
          },
        );
      },
    );
  }

  void _showHideDialog(
    BuildContext context,
    WidgetRef ref,
    String albumName,
    String artistName,
  ) {
    final key = "${albumName}_${artistName}";
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (sheetC) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility_off, color: Colors.white),
              title: Text(
                "Hide $albumName",
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                "You can unhide it later from Settings",
                style: TextStyle(color: Colors.white54),
              ),
              onTap: () {
                ref.read(libraryProvider.notifier).toggleAlbumVisibility(key);
                Navigator.pop(sheetC);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Hidden $albumName"),
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
        ),
      ),
    );
  }
}
