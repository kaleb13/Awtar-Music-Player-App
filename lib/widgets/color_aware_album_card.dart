import 'package:flutter/material.dart';
import 'app_widgets.dart'; // Import this to use AppPremiumCard

class ColorAwareAlbumCard extends StatelessWidget {
  final String title;
  final String artist;
  final String imageUrl;
  final double size;
  final bool isMini;
  final bool flexible;
  final bool showThreeDotsMenu;
  final VoidCallback? onTap;

  const ColorAwareAlbumCard({
    super.key,
    required this.title,
    required this.artist,
    required this.imageUrl,
    this.size = 140,
    this.isMini = false,
    this.flexible = false,
    this.showThreeDotsMenu = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // If flexible is true, we might want to use a LayoutBuilder or just a fixed large size
    // and let the parent handle layout.
    return AppPremiumCard(
      title: title,
      subtitle: artist,
      imageUrl: imageUrl,
      size:
          size, // AppPremiumCard now handles flexible inside using LayoutBuilder
      flexible: flexible,
      showMenu: showThreeDotsMenu,
      onTap: onTap,
    );
  }
}
