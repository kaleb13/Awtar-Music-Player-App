import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/color_aware_album_card.dart';
import '../details/album_details_screen.dart';
import '../../providers/navigation_provider.dart';

class AlbumsTab extends ConsumerWidget {
  const AlbumsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ... (rest of the list definition is fine)
    final albums = [
      {
        "title": "After Hours",
        "artist": "The Weekend",
        "img":
            "https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?q=80&w=300",
      },
      {
        "title": "Scorpion",
        "artist": "Drake",
        "img":
            "https://images.unsplash.com/photo-1493225255756-d9584f8606e9?q=80&w=300",
      },
      {
        "title": "Hollywood's Bleeding",
        "artist": "Post Malone",
        "img":
            "https://images.unsplash.com/photo-1459749411177-042180ce673c?q=80&w=300",
      },
      {
        "title": "Anti",
        "artist": "Rihanna",
        "img":
            "https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?q=80&w=300",
      },
      {
        "title": "Astroworld",
        "artist": "Travis Scott",
        "img":
            "https://images.unsplash.com/photo-1470225620780-dba8ba36b745?q=80&w=300",
      },
      {
        "title": "Sweetener",
        "artist": "Ariana Grande",
        "img":
            "https://images.unsplash.com/photo-1621112904887-413379ce6824?q=80&w=300",
      },
    ];

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.7, // Matching artist tab ratio
      ),
      itemCount: albums.length,
      itemBuilder: (context, index) {
        final album = albums[index];
        return ColorAwareAlbumCard(
          // Replaced AppAlbumCard
          title: album["title"]!,
          artist: album["artist"]!,
          imageUrl: album["img"]!,
          flexible: true,
          showThreeDotsMenu: true,
          onTap: () {
            ref.read(bottomNavVisibleProvider.notifier).state = false;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AlbumDetailsScreen(
                  title: album["title"]!,
                  artist: album["artist"]!,
                  imageUrl: album["img"]!,
                ),
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
