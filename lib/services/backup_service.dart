import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/stats_provider.dart';
import '../providers/library_provider.dart';
import '../services/database_service.dart';
import '../main.dart';
import '../models/song.dart';

class BackupService {
  static const int _currentVersion = 1;

  static Future<String> exportBackup(Ref ref) async {
    try {
      if (Platform.isAndroid) {
        // Request permissions
        if (await Permission.storage.request().isGranted ||
            await Permission.manageExternalStorage.request().isGranted) {
          debugPrint("Storage permissions granted");
        }
      }

      final stats = ref.read(statsProvider);
      final prefs = ref.read(sharedPreferencesProvider);
      final songs = await DatabaseService.getAllSongs();
      final playlists = await DatabaseService.getAllPlaylists();

      final String? libraryMetadata = prefs.getString('library_metadata_v1');

      final List<Map<String, String>> favoriteIdentities = songs
          .where((s) => s.isFavorite)
          .map(
            (s) => {
              'title': s.title,
              'artist': s.artist,
              'album': s.album ?? '',
            },
          )
          .toList();

      final List<Map<String, dynamic>> playlistData = playlists.map((p) {
        final List<Map<String, String>> songIdentities = [];
        for (final songId in p.songIds) {
          final song = songs.cast<Song?>().firstWhere(
            (s) => s?.id == songId,
            orElse: () => null,
          );
          if (song != null) {
            songIdentities.add({
              'title': song.title,
              'artist': song.artist,
              'album': song.album ?? '',
            });
          }
        }

        return {
          'id': p.id,
          'name': p.name,
          'imagePath': p.imagePath,
          'createdAt': p.createdAt.millisecondsSinceEpoch,
          'songs': songIdentities,
        };
      }).toList();

      final Map<String, dynamic> backup = {
        'version': _currentVersion,
        'appName': 'Awtar Music Player',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'stats': stats.toMapPortable(songs),
        'library_metadata': libraryMetadata != null
            ? jsonDecode(libraryMetadata)
            : null,
        'favorites': favoriteIdentities,
        'playlists': playlistData,
      };

      final String jsonString = jsonEncode(backup);
      final String fileName =
          "awtar_backup_${DateTime.now().toString().split(' ')[0].replaceAll('-', '')}_${DateTime.now().millisecondsSinceEpoch}.json";

      File? finalFile;

      if (Platform.isAndroid) {
        // Try multiple paths on Android, starting with Download folder which is often more accessible
        final List<String> potentialPaths = [
          '/storage/emulated/0/Download/AwtarPlayer/Backups',
          '/storage/emulated/0/AwtarPlayer/Backups',
          '/storage/emulated/0/Documents/AwtarPlayer/Backups',
        ];

        for (final path in potentialPaths) {
          try {
            final directory = Directory(path);
            if (!await directory.exists()) {
              await directory.create(recursive: true);
            }
            finalFile = File('${directory.path}/$fileName');
            await finalFile.writeAsString(jsonString);
            break; // Success!
          } catch (e) {
            debugPrint("Failed to save to $path: $e");
          }
        }
      }

      // If Android failed or we are on another platform, use tempDir as final fallback
      if (finalFile == null) {
        final Directory tempDir = await getTemporaryDirectory();
        finalFile = File('${tempDir.path}/$fileName');
        await finalFile.writeAsString(jsonString);
      }

      await Share.shareXFiles([
        XFile(finalFile.path),
      ], text: 'Awtar Music Player Backup saved to ${finalFile.path}');

      return finalFile.path;
    } catch (e) {
      debugPrint("Error during export: $e");
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> pickBackupFile() async {
    String? initialDir;
    if (Platform.isAndroid) {
      initialDir = '/storage/emulated/0/AwtarPlayer/Backups';
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      initialDirectory: initialDir,
    );

    if (result == null || result.files.single.path == null) return null;

    try {
      final file = File(result.files.single.path!);
      final String content = await file.readAsString();
      final Map<String, dynamic> backup = jsonDecode(content);

      if (backup['version'] == null ||
          backup['appName'] != 'Awtar Music Player') {
        throw Exception("Invalid backup file format");
      }

      return backup;
    } catch (e) {
      debugPrint("Error picking backup: $e");
      rethrow;
    }
  }

  static Future<void> restoreBackupWithProgress(
    Ref ref,
    Map<String, dynamic> backup,
    Function(double progress, String message) onProgress,
  ) async {
    try {
      final songs = ref.read(libraryProvider).songs;
      final prefs = ref.read(sharedPreferencesProvider);

      // 1. Restore Stats
      onProgress(0.2, "Restoring play statistics...");
      final stats = PlayStats.fromMapPortable(backup['stats'], songs);
      ref.read(statsProvider.notifier).updateState(stats);

      // 2. Restore Library Config
      onProgress(0.4, "Restoring library configuration...");
      if (backup['library_metadata'] != null) {
        await prefs.setString(
          'library_metadata_v1',
          jsonEncode(backup['library_metadata']),
        );
      }

      // 3. Apply Favorites and Playlists
      onProgress(0.6, "Re-mapping favorites and playlists...");
      await ref
          .read(libraryProvider.notifier)
          .applyBackupRestoration(
            favorites: List<Map<String, dynamic>>.from(backup['favorites']),
            playlists: List<Map<String, dynamic>>.from(backup['playlists']),
            onProgress: (p, m) => onProgress(0.6 + (p * 0.4), m),
          );
    } catch (e) {
      debugPrint("Error during restoration: $e");
      rethrow;
    }
  }
}

