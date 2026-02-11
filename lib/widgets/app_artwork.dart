import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:audiotags/audiotags.dart';
import 'dart:typed_data';
import 'dart:io';

/// Widget to display album artwork from local device using on_audio_query
class AppArtwork extends StatelessWidget {
  final int? songId;
  final int? albumId;
  final String? songPath;
  final double size;
  final double borderRadius;
  final BoxFit fit;
  final Widget? placeholder;

  const AppArtwork({
    super.key,
    this.songId,
    this.albumId,
    this.songPath,
    this.size = 100,
    this.borderRadius = 0,
    this.fit = BoxFit.cover,
    this.placeholder,
  });

  static final OnAudioQuery _audioQuery = OnAudioQuery();

  @override
  Widget build(BuildContext context) {
    // Priority: albumId > songId
    final id = albumId ?? songId;

    if (id == null && songPath == null) {
      return _buildPlaceholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: FutureBuilder<Uint8List?>(
        future: _fetchArtwork(id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.data != null &&
              snapshot.data!.isNotEmpty) {
            return Image.memory(
              snapshot.data!,
              width: size == double.infinity ? null : size,
              height: size == double.infinity ? null : size,
              fit: fit,
              filterQuality: FilterQuality.high,
              cacheWidth: size == double.infinity ? null : (size * 2).toInt(),
              cacheHeight: size == double.infinity ? null : (size * 2).toInt(),
            );
          }

          // Show placeholder while loading or if no artwork
          return _buildPlaceholder();
        },
      ),
    );
  }

  Future<Uint8List?> _fetchArtwork(int? id) async {
    try {
      // 1. Try fetching directly from file if path is available (Highest Quality)
      if (songPath != null && !songPath!.startsWith('content://')) {
        final file = File(songPath!);
        if (await file.exists()) {
          final tag = await AudioTags.read(songPath!);
          if (tag != null && tag.pictures.isNotEmpty) {
            return tag.pictures.first.bytes;
          }
        }
      }

      // 2. Fallback to on_audio_query with maximal settings
      if (id != null) {
        return await _audioQuery.queryArtwork(
          id,
          albumId != null ? ArtworkType.ALBUM : ArtworkType.AUDIO,
          format: ArtworkFormat.JPEG,
          size: null, // Full resolution
          quality: 100,
        );
      }
    } catch (e) {
      debugPrint("Error fetching artwork: $e");
    }
    return null;
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
