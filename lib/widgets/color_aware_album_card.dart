import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import '../theme/app_theme.dart';

class ColorAwareAlbumCard extends StatefulWidget {
  final String title;
  final String artist;
  final String imageUrl;
  final double size; // Used for width/height when flexible is false
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
  State<ColorAwareAlbumCard> createState() => _ColorAwareAlbumCardState();
}

class _ColorAwareAlbumCardState extends State<ColorAwareAlbumCard> {
  Color? _dominantColor;
  bool _isLoadingColor = true;

  @override
  void initState() {
    super.initState();
    _updatePalette();
  }

  @override
  void didUpdateWidget(covariant ColorAwareAlbumCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _updatePalette();
    }
  }

  Future<void> _updatePalette() async {
    if (!mounted) return;

    try {
      final PaletteGenerator generator =
          await PaletteGenerator.fromImageProvider(
            NetworkImage(widget.imageUrl),
            size: const Size(100, 100), // Optimizing for speed
            maximumColorCount: 5,
          );
      if (mounted) {
        setState(() {
          _dominantColor =
              generator.dominantColor?.color ??
              generator.vibrantColor?.color ??
              generator.mutedColor?.color ??
              AppColors.surfaceDark;
          _isLoadingColor = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _dominantColor = AppColors.surfaceDark;
          _isLoadingColor = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // If color is not ready or failed, fallback to dark surface
    final backgroundColor = _dominantColor ?? AppColors.surfaceDark;

    // Determine image widget
    Widget imageWidget;
    if (widget.flexible) {
      // If flexible, use AspectRatio to keep square-ish top part relative to width
      imageWidget = AspectRatio(
        aspectRatio: 1.0,
        child: Image.network(
          widget.imageUrl,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    } else {
      // If fixed size, use explicit dimensions
      imageWidget = SizedBox(
        width: widget.size,
        height: widget.size,
        child: Image.network(widget.imageUrl, fit: BoxFit.cover),
      );
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: widget.flexible ? double.infinity : widget.size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            imageWidget,
            Container(
              color: backgroundColor,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                // Changed to Row to accomdate menu
                children: [
                  Expanded(
                    // Text takes available space
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.title.isNotEmpty) ...[
                          Text(
                            widget.title,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize:
                                  11, // Reduced slightly to avoid overflow
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 1), // Reduced from 2
                        ],
                        if (widget.artist.isNotEmpty)
                          Text(
                            widget.artist,
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 9, // Reduced from 10
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  if (widget.showThreeDotsMenu) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.more_vert,
                      color: Colors.white.withOpacity(0.7),
                      size: 18,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
