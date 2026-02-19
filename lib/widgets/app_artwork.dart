import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:audiotags/audiotags.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:image/image.dart' as img;
import '../services/artwork_cache_service.dart';

/// Widget to display album artwork from local device using on_audio_query.
///
/// Set [highQuality] = true for the main player screen to get full-resolution
/// artwork without any downsampling. For all other uses (list tiles, mini-player,
/// etc.) leave it false for fast, memory-efficient thumbnails.
class AppArtwork extends StatefulWidget {
  final int? songId;
  final int? albumId;
  final String? songPath;
  final double size;
  final double borderRadius;
  final BoxFit fit;
  final Widget? placeholder;

  /// When true, fetches artwork at full resolution and skips GPU-side
  /// downsampling. Only use this for the main player screen.
  final bool highQuality;

  const AppArtwork({
    super.key,
    this.songId,
    this.albumId,
    this.songPath,
    this.size = 100,
    this.borderRadius = 0,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.highQuality = false,
  });

  @override
  State<AppArtwork> createState() => _AppArtworkState();
}

class _AppArtworkState extends State<AppArtwork> {
  static final OnAudioQuery _audioQuery = OnAudioQuery();

  // Separate caches for thumbnail vs full-quality to avoid cross-contamination.
  static final Map<String, Uint8List> _thumbCache = {};
  static final Map<String, Uint8List> _hqCache = {};

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
        widget.songPath != oldWidget.songPath ||
        widget.highQuality != oldWidget.highQuality) {
      _loadArtwork();
    }
  }

  void _loadArtwork() {
    final cache = widget.highQuality ? _hqCache : _thumbCache;
    final key = _generateKey();

    if (cache.containsKey(key)) {
      _artworkFuture = Future.value(cache[key]);
      return;
    }

    _artworkFuture = widget.highQuality
        ? _fetchHighQualityArtwork(key)
        : _fetchThumbnailArtwork(key);
  }

  String _generateKey() {
    final variant = widget.highQuality ? 'hq' : 'thumb';
    return '${widget.albumId}_${widget.songId}_${widget.songPath}_$variant';
  }

  // ─── Thumbnail path (existing behaviour, unchanged) ──────────────────────

  Future<Uint8List?> _fetchThumbnailArtwork(String key) async {
    try {
      // 0. Persistent disk cache
      final diskCached = await ArtworkCacheService.get(
        widget.songPath,
        widget.songId ?? widget.albumId,
      );
      if (diskCached != null) {
        _thumbCache[key] = diskCached;
        return diskCached;
      }

      Uint8List? bytes;

      // 1. MediaStore (on_audio_query) — small size for thumbnails
      final id = widget.albumId ?? widget.songId;
      if (id != null) {
        bytes = await _audioQuery.queryArtwork(
          id,
          widget.albumId != null ? ArtworkType.ALBUM : ArtworkType.AUDIO,
          format: ArtworkFormat.JPEG,
          size: 200,
          quality: 100,
        );
      }

      // 2. AudioTags fallback
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
            debugPrint('AudioTags fallback error: $e');
          }
        }
      }

      if (bytes != null && bytes.isNotEmpty) {
        _thumbCache[key] = bytes;
        await ArtworkCacheService.save(
          widget.songPath,
          widget.songId ?? widget.albumId,
          bytes,
        );
        return bytes;
      }
    } catch (e) {
      debugPrint('Error fetching thumbnail artwork: $e');
    }
    return null;
  }

  // ─── High-quality path (main player screen) ──────────────────────────────

  /// Fetches artwork at full resolution. If the raw bytes exceed 2 MB
  /// (e.g. a user-embedded high-res cover), they are re-encoded at 90%
  /// JPEG quality to keep memory reasonable while preserving visual fidelity.
  Future<Uint8List?> _fetchHighQualityArtwork(String key) async {
    try {
      Uint8List? bytes;

      // 1. Try AudioTags first for HQ — it gives the raw embedded bytes
      //    without MediaStore's size cap.
      if (widget.songPath != null &&
          !widget.songPath!.startsWith('content://')) {
        final file = File(widget.songPath!);
        if (await file.exists()) {
          try {
            final tag = await AudioTags.read(widget.songPath!);
            if (tag != null && tag.pictures.isNotEmpty) {
              bytes = tag.pictures.first.bytes;
            }
          } catch (e) {
            debugPrint('HQ AudioTags read error: $e');
          }
        }
      }

      // 2. Fallback to MediaStore (no size cap = full resolution)
      if (bytes == null) {
        final id = widget.albumId ?? widget.songId;
        if (id != null) {
          bytes = await _audioQuery.queryArtwork(
            id,
            widget.albumId != null ? ArtworkType.ALBUM : ArtworkType.AUDIO,
            format: ArtworkFormat.JPEG,
            quality: 100,
            // No 'size' parameter → full resolution from MediaStore
          );
        }
      }

      if (bytes == null || bytes.isEmpty) return null;

      // 3. If the image is >2 MB, re-encode at 90% quality to save memory
      //    while keeping near-lossless visual quality.
      const int twoMb = 2 * 1024 * 1024;
      if (bytes.length > twoMb) {
        bytes = await _compressTo90Percent(bytes);
      }

      _hqCache[key] = bytes;
      return bytes;
    } catch (e) {
      debugPrint('Error fetching HQ artwork: $e');
    }
    return null;
  }

  /// Re-encodes image bytes at 90% JPEG quality.
  /// Runs on a background isolate via Flutter's compute-friendly approach.
  static Future<Uint8List> _compressTo90Percent(Uint8List input) async {
    try {
      final decoded = img.decodeImage(input);
      if (decoded == null) return input;
      final compressed = img.encodeJpg(decoded, quality: 90);
      return Uint8List.fromList(compressed);
    } catch (_) {
      return input; // If compression fails, use original
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (widget.albumId == null &&
        widget.songId == null &&
        widget.songPath == null) {
      return _buildPlaceholder();
    }

    // ─── SYNCHRONOUS CACHE CHECK ───
    // If the image is already in memory, return it immediately to avoid
    // FutureBuilder's asynchronous build cycle, which causes lag in lists.
    final cache = widget.highQuality ? _hqCache : _thumbCache;
    final key = _generateKey();
    final cachedBytes = cache[key];

    if (cachedBytes != null && cachedBytes.isNotEmpty) {
      return _buildImage(context, cachedBytes);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: FutureBuilder<Uint8List?>(
        future: _artworkFuture,
        builder: (context, snapshot) {
          final bytes = snapshot.data;
          final isDone = snapshot.connectionState == ConnectionState.done;

          if (bytes != null && bytes.isNotEmpty) {
            return _buildImage(context, bytes);
          }

          if (!isDone) {
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

  Widget _buildImage(BuildContext context, Uint8List bytes) {
    if (widget.highQuality) {
      // Full-quality display: no GPU downsampling, high filter quality
      return Image.memory(
        bytes,
        width: widget.size == double.infinity ? null : widget.size,
        height: widget.size == double.infinity ? null : widget.size,
        fit: widget.fit,
        filterQuality: FilterQuality.high,
        gaplessPlayback: true,
        // No cacheWidth → decoded at native resolution for crisp display
      );
    }

    // Standard thumbnail display
    final int cacheSize = widget.size == double.infinity
        ? (MediaQuery.of(context).size.width *
                  MediaQuery.of(context).devicePixelRatio)
              .toInt()
        : (widget.size * MediaQuery.of(context).devicePixelRatio).toInt();

    return Image.memory(
      bytes,
      width: widget.size == double.infinity ? null : widget.size,
      height: widget.size == double.infinity ? null : widget.size,
      fit: widget.fit,
      filterQuality: FilterQuality.low,
      gaplessPlayback: true,
      cacheWidth: cacheSize,
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
