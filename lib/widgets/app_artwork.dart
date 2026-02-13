import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:audiotags/audiotags.dart';
import 'dart:typed_data';
import 'dart:io';
import '../services/artwork_cache_service.dart';

/// Widget to display album artwork from local device using on_audio_query
class AppArtwork extends StatefulWidget {
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

  @override
  State<AppArtwork> createState() => _AppArtworkState();
}

class _AppArtworkState extends State<AppArtwork> {
  static final OnAudioQuery _audioQuery = OnAudioQuery();
  static final Map<String, Uint8List> _cache = {};

  Future<Uint8List?>? _artworkFuture;

  @override
  void initState() {
    super.initState();
    _loadArtwork();
  }

  @override
  void didUpdateWidget(AppArtwork oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.songId != oldWidget.songId ||
        widget.albumId != oldWidget.albumId ||
        widget.songPath != oldWidget.songPath) {
      _loadArtwork();
    }
  }

  void _loadArtwork() {
    // Determine fetch size - if widget size is default/small, optimize query
    // Otherwise used bounded max
    int? querySize;
    if (widget.size != double.infinity && widget.size < 200) {
      querySize = 200;
    }

    final key = _generateKey(querySize);

    // Check cache first
    if (_cache.containsKey(key)) {
      _artworkFuture = Future.value(_cache[key]);
      return;
    }

    _artworkFuture = _fetchArtwork(key, querySize);
  }

  String _generateKey(int? sizeVariant) {
    return "${widget.albumId}_${widget.songId}_${widget.songPath}_${sizeVariant ?? 'full'}";
  }

  Future<Uint8List?> _fetchArtwork(String key, int? querySize) async {
    try {
      // 0. Check Persistent Disk Cache first
      final diskCached = await ArtworkCacheService.get(
        widget.songPath,
        widget.songId ?? widget.albumId,
      );
      if (diskCached != null) {
        _cache[key] = diskCached;
        return diskCached;
      }

      Uint8List? bytes;

      // 1. Try on_audio_query (System Media Store)
      final id = widget.albumId ?? widget.songId;
      if (id != null) {
        bytes = await _audioQuery.queryArtwork(
          id,
          widget.albumId != null ? ArtworkType.ALBUM : ArtworkType.AUDIO,
          format: ArtworkFormat.JPEG,
          size: querySize,
          quality: 100,
        );
      }

      // 2. Fallback to manual tag reading from file
      if (bytes == null &&
          widget.songPath != null &&
          !widget.songPath!.startsWith('content://')) {
        final file = File(widget.songPath!);
        if (await file.exists()) {
          try {
            final tag = await AudioTags.read(widget.songPath!);
            if (tag != null && tag.pictures.isNotEmpty) {
              bytes = tag.pictures.first.bytes;
            }
          } catch (e) {
            debugPrint("AudioTags fallback error: $e");
          }
        }
      }

      if (bytes != null && bytes.isNotEmpty) {
        _cache[key] = bytes;
        // Save to Persistent Disk Cache
        await ArtworkCacheService.save(
          widget.songPath,
          widget.songId ?? widget.albumId,
          bytes,
        );
        return bytes;
      }
    } catch (e) {
      debugPrint("Error fetching artwork: $e");
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // If no identifiers, show placeholder immediately
    if (widget.albumId == null &&
        widget.songId == null &&
        widget.songPath == null) {
      return _buildPlaceholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: FutureBuilder<Uint8List?>(
        future: _artworkFuture,
        builder: (context, snapshot) {
          final bytes = snapshot.data;
          final isDone = snapshot.connectionState == ConnectionState.done;

          // Optimization: If we have new bytes, use them.
          // If we are still loading, try to show the previous cache if available
          // (which is handled by GaplessPlayback if we were using the same Image widget)
          // But since we use different keys/futures, we should try to be smart.

          if (bytes != null && bytes.isNotEmpty) {
            // Calculate optimal cache size for decoding
            final int cacheSize = widget.size == double.infinity
                ? (MediaQuery.of(context).size.width *
                          MediaQuery.of(context).devicePixelRatio)
                      .toInt()
                : (widget.size * MediaQuery.of(context).devicePixelRatio)
                      .toInt();

            return Image.memory(
              bytes,
              width: widget.size == double.infinity ? null : widget.size,
              height: widget.size == double.infinity ? null : widget.size,
              fit: widget.fit,
              filterQuality: FilterQuality.low, // Optimization for animations
              gaplessPlayback: true, // Prevent flickering when updating
              cacheWidth: cacheSize,
            );
          }

          // If we are loading and don't have data yet, we might want to transparently
          // show nothing OR keep the old one if we were doing a cross-fade.
          // For now, only show placeholder if we truly have nothing or it's been a while.
          if (!isDone) {
            // Return an empty container or a very subtle placeholder to avoid "flash"
            return Container(
              width: widget.size == double.infinity ? 100 : widget.size,
              height: widget.size == double.infinity ? 100 : widget.size,
              color: Colors.black12,
            );
          }

          return _buildPlaceholder();
        },
      ),
    );
  }

  Widget _buildPlaceholder() {
    return widget.placeholder ??
        Container(
          width: widget.size == double.infinity ? 100 : widget.size,
          height: widget.size == double.infinity ? 100 : widget.size,
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
          child: Icon(
            Icons.music_note,
            color: Colors.grey[700],
            size: (widget.size == double.infinity ? 100 : widget.size) * 0.4,
          ),
        );
  }
}
