import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class ArtworkCacheService {
  static String? _cacheDirPath;

  static Future<void> init() async {
    final cacheDir = await getTemporaryDirectory();
    _cacheDirPath = '${cacheDir.path}/artwork_cache';
    final dir = Directory(_cacheDirPath!);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  static String _generateKey(String? path, int? id) {
    if (path != null && path.isNotEmpty) {
      return md5.convert(utf8.encode(path)).toString();
    }
    return 'id_$id';
  }

  static Future<Uint8List?> get(String? path, int? id) async {
    if (_cacheDirPath == null) await init();
    final key = _generateKey(path, id);
    final file = File('$_cacheDirPath/$key');
    if (await file.exists()) {
      return await file.readAsBytes();
    }
    return null;
  }

  static Future<void> save(String? path, int? id, Uint8List bytes) async {
    if (_cacheDirPath == null) await init();
    final key = _generateKey(path, id);
    final file = File('$_cacheDirPath/$key');
    await file.writeAsBytes(bytes);
  }

  static Future<void> clear() async {
    if (_cacheDirPath == null) return;
    final dir = Directory(_cacheDirPath!);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    await init();
  }

  static Future<void> warmUp(String? path, int? id) async {
    if (_cacheDirPath == null) await init();
    final key = _generateKey(path, id);
    final file = File('$_cacheDirPath/$key');
    if (await file.exists()) return;
    // Note: Manual warming would require an instance of OnAudioQuery or similar.
    // Real pre-fetching will happen when the UI requests these items via AppArtwork.
  }
}
