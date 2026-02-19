import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/library_provider.dart';
import '../../models/song.dart';
import '../details/artist_details_screen.dart';
import '../../widgets/app_widgets.dart';
import '../../providers/navigation_provider.dart';
import '../../services/media_menu_service.dart';

class ArtistsTab extends ConsumerWidget {
  const ArtistsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artists = ref.watch(
      libraryProvider.select(
        (s) => s.artists.where((a) {
          if (s.hiddenArtists.contains(a.artist)) return false;
          if (s.hideSmallArtists && a.numberOfTracks < 3) return false;
          if (s.hideUnknownArtist &&
              (a.artist.toLowerCase() == "<unknown>" ||
                  a.artist.toLowerCase() == "unknown")) {
            return false;
          }
          return true;
        }).toList(),
      ),
    );

    final permissionStatus = ref.watch(
      libraryProvider.select((s) => s.permissionStatus),
    );
    final isLoading = ref.watch(libraryProvider.select((s) => s.isLoading));
    final representativeArtistSongs = ref.watch(
      libraryProvider.select((s) => s.representativeArtistSongs),
    );
    final artistColors = ref.watch(
      libraryProvider.select((s) => s.artistColors),
    );
    final songMap = ref.watch(libraryProvider.select((s) => s.songMap));
    final defaultSong =
        ref.watch(libraryProvider.select((s) => s.songs.firstOrNull)) ??
        Song(id: 0, title: "", url: "", artist: "", duration: 0, lyrics: []);

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
              "To see your artists, please grant storage permission",
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

    if (artists.isEmpty && !isLoading) {
      return const Center(
        child: Text(
          "No artists found on your device",
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
        childAspectRatio: 0.52, // Portrait ratio (taller cards)
      ),
      itemCount: artists.length,
      itemBuilder: (context, index) {
        final artist = artists[index];
        final representativeSongId = representativeArtistSongs[artist.artist];
        final artistSong = songMap[representativeSongId] ?? defaultSong;

        return AppPremiumCard(
          title: artist.artist,
          subtitle: "${artist.numberOfTracks} Tracks",
          songId: artistSong.id,
          flexible: true,
          isPortrait: true,
          borderColor: artistColors[artist.artist],
          artwork: artist.imagePath != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.file(
                    File(artist.imagePath!),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                )
              : null,
          onTap: () {
            ref.read(bottomNavVisibleProvider.notifier).state = false;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ArtistDetailsScreen(name: artist.artist, imageUrl: ""),
              ),
            ).then((_) {
              ref.read(bottomNavVisibleProvider.notifier).state = true;
            });
          },
          onLongPress: () {
            AppCenteredModal.show(
              context,
              title: artist.artist,
              items: [
                ...MediaMenuService.buildArtistActions(
                  context: context,
                  ref: ref,
                  artist: artist,
                ),
                AppModalItem(
                  icon: Icons.visibility_off_outlined,
                  label: "Hide Artist",
                  onTap: () {
                    ref
                        .read(libraryProvider.notifier)
                        .toggleArtistVisibility(artist.artist);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Hidden ${artist.artist}"),
                        action: SnackBarAction(
                          label: "Undo",
                          onPressed: () {
                            ref
                                .read(libraryProvider.notifier)
                                .toggleArtistVisibility(artist.artist);
                          },
                        ),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
