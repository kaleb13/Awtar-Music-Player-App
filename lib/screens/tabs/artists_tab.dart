import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../details/artist_details_screen.dart';
import '../../providers/navigation_provider.dart';

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
      // Added more for grid visualization
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
        crossAxisCount: 3, // Changed to 3 columns
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.7, // Taller aspect ratio for narrower cards
      ),
      itemCount: artists.length,
      itemBuilder: (context, index) {
        final artist = artists[index];
        return GestureDetector(
          onTap: () {
            ref.read(bottomNavVisibleProvider.notifier).state = false;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ArtistDetailsScreen(
                  name: artist["name"]!,
                  imageUrl: artist["img"]!,
                ),
              ),
            ).then((_) {
              ref.read(bottomNavVisibleProvider.notifier).state = true;
            });
          },
          child: AppArtistCard(
            name: artist["name"]!,
            tracks: artist["tracks"]!,
            albums: artist["albums"]!,
            imageUrl: artist["img"]!,
          ),
        );
      },
    );
  }
}

class AppArtistCard extends StatelessWidget {
  final String name;
  final String tracks;
  final String albums;
  final String imageUrl;

  const AppArtistCard({
    super.key,
    required this.name,
    required this.tracks,
    required this.albums,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        // No color here, we want it transparent-ish or let children handle
      ),
      clipBehavior:
          Clip.antiAlias, // Ensures internal children respect rounded corners
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Square Image Top
          AspectRatio(
            aspectRatio: 1.0,
            child: Image.network(imageUrl, fit: BoxFit.cover),
          ),

          // 2. Info Section (Silver Dark Transparent)
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                // "Silver Dark" + Transparent
                color: const Color(0xFF2A2C30).withOpacity(0.9),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontFamily: "Inter", // Or whatever default font
                        color: Colors.white,
                        fontSize: 12, // Reduced font size to fit 3 columns
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Flexible(
                    child: Text(
                      "$tracks tracks $albums albums",
                      style: TextStyle(color: Colors.grey[400], fontSize: 9),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
