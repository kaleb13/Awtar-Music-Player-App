import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../details/artist_details_screen.dart';
import '../../widgets/app_widgets.dart'; // Import this to use AppPremiumCard

class ArtistsTab extends ConsumerWidget {
  const ArtistsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Enhanced mock data with track and album counts
    final artists = [
      {
        "name": "Belete Ermias",
        "tracks": "3",
        "albums": "3",
        "img":
            "https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?q=80&w=400",
      },
      {
        "name": "Bereket Tesfaye",
        "tracks": "60",
        "albums": "5",
        "img":
            "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=400",
      },
      {
        "name": "Biruk Gebretsadik",
        "tracks": "17",
        "albums": "2",
        "img":
            "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?q=80&w=400",
      },
      {
        "name": "Dagi Tilahun",
        "tracks": "38",
        "albums": "3",
        "img":
            "https://images.unsplash.com/photo-1527980965255-d3b416303d12?q=80&w=400",
      },
      {
        "name": "Dawit Getachew",
        "tracks": "39",
        "albums": "5",
        "img":
            "https://images.unsplash.com/photo-1517841905240-472988babdf9?q=80&w=400",
      },
      {
        "name": "Ephrem Alemu",
        "tracks": "37",
        "albums": "3",
        "img":
            "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?q=80&w=400",
      },
      {
        "name": "Fenan Befkadu",
        "tracks": "12",
        "albums": "1",
        "img":
            "https://images.unsplash.com/photo-1531123414780-f74242c2b052?q=80&w=400",
      },
      {
        "name": "Kaleb B",
        "tracks": "10",
        "albums": "1",
        "img":
            "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=400",
      },
    ];

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.65, // Increased vertical space to fix overflow
      ),
      itemCount: artists.length,
      itemBuilder: (context, index) {
        final artist = artists[index];
        return AppPremiumCard(
          title: artist["name"]!,
          subtitle: "${artist["tracks"]} Tracks ${artist["albums"]} Albums",
          imageUrl: artist["img"]!,
          isCircular:
              false, // User requested the square-rounded look like popular artists
          onTap: () {
            // ref.read(bottomNavVisibleProvider.notifier).state = false;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ArtistDetailsScreen(
                  name: artist["name"]!,
                  imageUrl: artist["img"]!,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
