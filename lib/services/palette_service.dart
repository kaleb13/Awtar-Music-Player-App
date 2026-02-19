import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import '../theme/app_theme.dart';

import 'package:on_audio_query/on_audio_query.dart';
import 'package:audiotags/audiotags.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

class PaletteService {
  static const int _maxCacheSize = 200;
  static const String _prefsKey = 'palette_color_cache_v1';

  /// In-memory LRU cache — pre-populated from disk on first use.
  static final Map<String, Color> _cache = {};
  static bool _diskLoaded = false;

  /// Pending async extractions — deduplicates concurrent requests.
  static final Map<String, Future<Color>> _tasks = {};

  static final OnAudioQuery _audioQuery = OnAudioQuery();

  // ── Disk persistence ────────────────────────────────────────────────────

  /// Call once at startup (before first frame) to pre-populate the in-memory
  /// cache from SharedPreferences. This is synchronous-ish — it awaits prefs
  /// but returns immediately once the cache is filled.
  static Future<void> loadFromDisk({SharedPreferences? prefs}) async {
    if (_diskLoaded) return;
    _diskLoaded = true;
    try {
      final p = prefs ?? await SharedPreferences.getInstance();
      final raw = p.getString(_prefsKey);
      if (raw == null) return;
      final Map<String, dynamic> decoded = jsonDecode(raw);
      decoded.forEach((key, value) {
        if (value is int) {
          _cache[key] = Color(value);
        }
      });
      debugPrint('🎨 PaletteService: loaded ${_cache.length} colors from disk');
    } catch (e) {
      debugPrint('PaletteService loadFromDisk error: $e');
    }
  }

  /// Persist the current in-memory cache to SharedPreferences.
  /// Called after every new color is extracted.
  static Future<void> _saveToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, int> serializable = {};
      for (final entry in _cache.entries) {
        serializable[entry.key] = entry.value.toARGB32();
      }
      await prefs.setString(_prefsKey, jsonEncode(serializable));
    } catch (e) {
      debugPrint('PaletteService saveToDisk error: $e');
    }
  }

  // ── Public API ──────────────────────────────────────────────────────────

  static Future<Color> getColor(
    String imageUrl, {
    int? songId,
    String? songPath,
  }) async {
    return generateAccentColor(imageUrl, songId: songId, songPath: songPath);
  }

  static Future<Color> generateAccentColor(
    String imageUrl, {
    int? songId,
    String? songPath,
  }) async {
    final cacheKey = songId?.toString() ?? songPath ?? imageUrl;

    // 1. In-memory hit (includes pre-loaded disk cache)
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    // 2. Deduplicate concurrent requests for the same key
    if (_tasks.containsKey(cacheKey)) {
      return await _tasks[cacheKey]!;
    }

    // 3. Extract color — this is the expensive path
    final task = _processPalette(cacheKey, imageUrl, songId, songPath);
    _tasks[cacheKey] = task;

    try {
      return await task;
    } finally {
      _tasks.remove(cacheKey);
    }
  }

  static Future<Color> _processPalette(
    String cacheKey,
    String imageUrl,
    int? songId,
    String? songName,
  ) async {
    try {
      Uint8List? bytes;
      String? songPath = songName;

      // 1. Try on_audio_query (System Media Store)
      if (songId != null) {
        bytes = await _audioQuery.queryArtwork(
          songId,
          ArtworkType.AUDIO,
          format: ArtworkFormat.JPEG,
          size: 40,
        );
      }

      // 2. Fallback to manual tag reading from file
      if (bytes == null &&
          songPath != null &&
          !songPath.startsWith('content://')) {
        final file = File(songPath);
        if (await file.exists()) {
          try {
            final tag = await AudioTags.read(songPath);
            if (tag != null && tag.pictures.isNotEmpty) {
              bytes = tag.pictures.first.bytes;
            }
          } catch (e) {
            debugPrint("Palette AudioTags fallback error: $e");
          }
        }
      }

      ImageProvider provider;
      if (bytes != null && bytes.isNotEmpty) {
        provider = MemoryImage(bytes);
      } else if (imageUrl.startsWith('http')) {
        provider = NetworkImage(imageUrl);
      } else if (imageUrl.isNotEmpty && File(imageUrl).existsSync()) {
        provider = FileImage(File(imageUrl));
      } else {
        return _finalize(cacheKey, AppColors.accentBlue);
      }

      final PaletteGenerator generator =
          await PaletteGenerator.fromImageProvider(
            provider,
            size: const Size(64, 64),
            maximumColorCount: 5,
          );

      final color =
          generator.vibrantColor?.color ??
          generator.lightVibrantColor?.color ??
          generator.dominantColor?.color ??
          AppColors.accentBlue;

      return _finalize(cacheKey, color);
    } catch (e) {
      return _finalize(cacheKey, AppColors.accentBlue);
    }
  }

  static Color _finalize(String key, Color color) {
    _cache.remove(key); // Re-insert at end for LRU ordering
    _cache[key] = color;
    // Evict oldest entry if over limit
    if (_cache.length > _maxCacheSize) {
      _cache.remove(_cache.keys.first);
    }
    // Persist asynchronously — fire and forget, never blocks UI
    _saveToDisk();
    return color;
  }

  /// Expose the full cache so LibraryNotifier can bulk-load it at startup.
  static Map<String, Color> get cachedColors => Map.unmodifiable(_cache);

  /// Invalidate a single key (e.g. after artwork changes).
  static void invalidate(String key) {
    _cache.remove(key);
    _saveToDisk();
  }
}
