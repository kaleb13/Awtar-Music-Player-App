import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../details/artist_details_screen.dart';

class ArtistsTab extends StatelessWidget {
  const ArtistsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final artists = [
      {
        "name": "The Weekend",
        "songs": "12 Songs",
        "img":
            "https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?q=80&w=300",
      },
      {
        "name": "Drake",
        "songs": "24 Songs",
        "img":
            "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=300",
      },
      {
        "name": "Post Malone",
        "songs": "8 Songs",
        "img":
            "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?q=80&w=300",
      },
      {
        "name": "Rihanna",
        "songs": "18 Songs",
        "img":
            "https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=300",
      },
      {
        "name": "Travis Scott",
        "songs": "15 Songs",
        "img":
            "https://images.unsplash.com/photo-1527980965255-d3b416303d12?q=80&w=300",
      },
      {
        "name": "Ariana Grande",
        "songs": "22 Songs",
        "img":
            "https://images.unsplash.com/photo-1517841905240-472988babdf9?q=80&w=300",
      },
    ];

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: artists.length,
      itemBuilder: (context, index) {
        final artist = artists[index];
        return GestureDetector(
          onTap: () {
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
          child: AppArtistCard(
            name: artist["name"]!,
            songs: artist["songs"]!,
            imageUrl: artist["img"]!,
          ),
        );
      },
    );
  }
}

class AppArtistCard extends StatelessWidget {
  final String name;
  final String songs;
  final String imageUrl;

  const AppArtistCard({
    super.key,
    required this.name,
    required this.songs,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
          opacity: 0.7,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: AppTextStyles.titleMedium.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              songs,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.accentYellow,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
