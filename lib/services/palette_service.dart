import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import '../theme/app_theme.dart';

import 'package:on_audio_query/on_audio_query.dart';
import 'package:audiotags/audiotags.dart';
import 'dart:typed_data';
import 'dart:io';

class PaletteService {
  static final Map<String, Color> _cache = {};
  static final Map<String, Future<Color>> _tasks =
      {}; // Task queue for pending requests
  static final OnAudioQuery _audioQuery = OnAudioQuery();

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

    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    // If a task for this key is already in progress, wait for it
    if (_tasks.containsKey(cacheKey)) {
      return await _tasks[cacheKey]!;
    }

    // Start a new task
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
        return _finalize(cacheKey, AppColors.accentYellow);
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
          AppColors.accentYellow;

      return _finalize(cacheKey, color);
    } catch (e) {
      return _finalize(cacheKey, AppColors.accentYellow);
    }
  }

  static Color _finalize(String key, Color color) {
    _cache[key] = color;
    return color;
  }
}
