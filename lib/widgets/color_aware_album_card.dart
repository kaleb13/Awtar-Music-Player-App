import 'package:flutter/material.dart';
import 'app_widgets.dart'; // Import this to use AppPremiumCard

class ColorAwareAlbumCard extends StatelessWidget {
  final String title;
  final String artist;
  final String imageUrl;
  final double size;
  final bool isMini;
  final bool flexible;
  final bool isPortrait;
  final bool showThreeDotsMenu;
  final VoidCallback? onTap;
  final VoidCallback? onMenuTap;
  final Widget? artwork;
  final int? songId;
  final String? songPath;
  final PopupMenuItemBuilder<String>? menuBuilder;
  final void Function(String)? onMenuSelected;

  final VoidCallback? onLongPress;

  const ColorAwareAlbumCard({
    super.key,
    required this.title,
    required this.artist,
    this.imageUrl = "",
    this.size = 140,
    this.isMini = false,
    this.flexible = false,
    this.isPortrait = false,
    this.showThreeDotsMenu = false,
    this.onTap,
    this.onMenuTap,
    this.onLongPress,
    this.artwork,
    this.songId,
    this.songPath,
    this.menuBuilder,
    this.onMenuSelected,
  });

  @override
  Widget build(BuildContext context) {
    // If flexible is true, we might want to use a LayoutBuilder or just a fixed large size
    // and let the parent handle layout.
    return AppPremiumCard(
      title: title,
      subtitle: artist,
      imageUrl: imageUrl,
      size: size,
      flexible: flexible,
      isPortrait: isPortrait,
      showMenu: showThreeDotsMenu,
      onTap: onTap,
      onMenuTap: onMenuTap,
      onLongPress: onLongPress,
      artwork: artwork,
      songId: songId,
      songPath: songPath,
      menuBuilder: menuBuilder,
      onMenuSelected: onMenuSelected,
    );
  }
}

