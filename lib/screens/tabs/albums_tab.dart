import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';

class AlbumsTab extends StatelessWidget {
  const AlbumsTab({super.key});

  @override
  Widget build(BuildContext context) {
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
            "https://images.unsplash.com/photo-1621112904887-419379ce6824?q=80&w=300",
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 24, right: 24, top: 20),
              child: AppTopBar(),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 24,
                  childAspectRatio: 0.75,
                ),
                itemCount: albums.length,
                itemBuilder: (context, index) {
                  final album = albums[index];
                  return AppAlbumCard(
                    title: album["title"]!,
                    artist: album["artist"]!,
                    imageUrl: album["img"]!,
                    size: 160,
                    flexible: true,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
