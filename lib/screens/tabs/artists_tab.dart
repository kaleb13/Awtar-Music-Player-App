import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/library_provider.dart';
import '../../models/song.dart';
import '../details/artist_details_screen.dart';
import '../../widgets/app_widgets.dart';
import '../../providers/navigation_provider.dart';

class ArtistsTab extends ConsumerWidget {
  const ArtistsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryState = ref.watch(libraryProvider);
    final artists = libraryState.artists;

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
              "To see your artists, please grant storage permission",
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

    if (artists.isEmpty && !libraryState.isLoading) {
      return const Center(
        child: Text(
          "No artists found on your device",
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.65,
      ),
      itemCount: artists.length,
      itemBuilder: (context, index) {
        final artist = artists[index];
        final artistSong = libraryState.songs.firstWhere(
          (s) => s.artist == artist.artist,
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

        return AppPremiumCard(
          title: artist.artist,
          subtitle: "${artist.numberOfTracks} Tracks",
          songId: artistSong.id,
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
        );
      },
    );
  }
}
