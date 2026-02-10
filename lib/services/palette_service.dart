import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import '../theme/app_theme.dart';

import 'package:on_audio_query/on_audio_query.dart';
import 'dart:typed_data';

class PaletteService {
  static final Map<String, Color> _cache = {};
  static final List<String> _pending = [];
  static final OnAudioQuery _audioQuery = OnAudioQuery();

  static Future<Color> getColor(String imageUrl, {int? songId}) async {
    return generateAccentColor(imageUrl, songId: songId);
  }

  static Future<Color> generateAccentColor(
    String imageUrl, {
    int? songId,
  }) async {
    final cacheKey = songId?.toString() ?? imageUrl;

    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    if (_pending.contains(cacheKey)) {
      return AppColors.accentYellow;
    }

    _pending.add(cacheKey);

    try {
      ImageProvider provider;
      if (songId != null) {
        final Uint8List? bytes = await _audioQuery.queryArtwork(
          songId,
          ArtworkType.AUDIO,
          format: ArtworkFormat.JPEG,
          size: 40,
        );
        if (bytes != null && bytes.isNotEmpty) {
          provider = MemoryImage(bytes);
        } else {
          return _finalize(cacheKey, AppColors.accentYellow);
        }
      } else if (imageUrl.startsWith('http')) {
        provider = NetworkImage(imageUrl);
      } else {
        return _finalize(cacheKey, AppColors.accentYellow);
      }

      final PaletteGenerator generator =
          await PaletteGenerator.fromImageProvider(
            provider,
            size: const Size(40, 40),
            maximumColorCount: 3,
          );

      final color =
          generator.vibrantColor?.color ??
          generator.dominantColor?.color ??
          AppColors.accentYellow;

      return _finalize(cacheKey, color);
    } catch (e) {
      return _finalize(cacheKey, AppColors.accentYellow);
    }
  }

  static Color _finalize(String key, Color color) {
    _cache[key] = color;
    _pending.remove(key);
    return color;
  }
}
