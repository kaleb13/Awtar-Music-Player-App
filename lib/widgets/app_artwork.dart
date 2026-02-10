import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

/// Widget to display album artwork from local device using on_audio_query
class AppArtwork extends StatelessWidget {
  final int? songId;
  final int? albumId;
  final double size;
  final double borderRadius;
  final BoxFit fit;
  final Widget? placeholder;

  const AppArtwork({
    super.key,
    this.songId,
    this.albumId,
    this.size = 100,
    this.borderRadius = 0,
    this.fit = BoxFit.cover,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    // Priority: albumId > songId
    final id = albumId ?? songId;

    if (id == null) {
      return _buildPlaceholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: QueryArtworkWidget(
        id: id,
        type: albumId != null ? ArtworkType.ALBUM : ArtworkType.AUDIO,
        artworkFit: fit,
        artworkWidth: size,
        artworkHeight: size,
        artworkBorder: BorderRadius.zero,
        nullArtworkWidget: _buildPlaceholder(),
        keepOldArtwork: true,
        artworkQuality: FilterQuality.medium,
      ),
    );
  }

  Widget _buildPlaceholder() {
    return placeholder ??
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: Icon(
            Icons.music_note,
            color: Colors.grey[600],
            size: size * 0.4,
          ),
        );
  }
}
