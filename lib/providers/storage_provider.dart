import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storage_space/storage_space.dart';
import 'dart:io';

class StorageInfo {
  final String name;
  final double usedSize; // in GB
  final double totalSize; // in GB
  final bool isAvailable;

  StorageInfo({
    required this.name,
    required this.usedSize,
    required this.totalSize,
    required this.isAvailable,
  });

  double get percent => totalSize > 0 ? usedSize / totalSize : 0;
}

class StorageState {
  final List<StorageInfo> storages;
  final bool isLoading;

  StorageState({this.storages = const [], this.isLoading = false});
}

class StorageNotifier extends StateNotifier<StorageState> {
  StorageNotifier() : super(StorageState()) {
    refresh();
  }

  Future<void> refresh() async {
    state = StorageState(isLoading: true);

    List<StorageInfo> results = [];

    // 1. Internal Storage
    try {
      final space = await getStorageSpace(
        lowOnSpaceThreshold: 0,
        fractionDigits: 2,
      );
      results.add(
        StorageInfo(
          name: "Internal Storage",
          usedSize: (space.total - space.free) / (1024 * 1024 * 1024),
          totalSize: space.total / (1024 * 1024 * 1024),
          isAvailable: true,
        ),
      );
    } catch (e) {
      debugPrint("Error getting internal storage: $e");
    }

    // 2. SD Card (Simplified detection for now)
    // In a real app, we'd use platform channels or search /storage/
    bool sdFound = false;
    try {
      if (Platform.isAndroid) {
        final dir = Directory('/storage');
        if (dir.existsSync()) {
          final list = dir.listSync();
          for (final entity in list) {
            final path = entity.path;
            if (path != '/storage/emulated' && path != '/storage/self') {
              // Likely an SD card or USB
              try {
                // Approximate size check if possible or just show as available
                // storage_space doesn't easily support arbitrary paths in the free version of getStorageSpace
                // but let's assume we can't easily get it without more complex logic
                sdFound = true;
                break;
              } catch (_) {}
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Error detecting SD card: $e");
    }

    results.add(
      StorageInfo(
        name: "SD Card",
        usedSize: sdFound ? 12 : 0, // Mock for now if found
        totalSize: sdFound ? 128 : 0,
        isAvailable: sdFound,
      ),
    );

    results.add(
      StorageInfo(
        name: "USB Drive",
        usedSize: 0,
        totalSize: 0,
        isAvailable: false,
      ),
    );

    state = StorageState(storages: results, isLoading: false);
  }
}

final storageProvider = StateNotifierProvider<StorageNotifier, StorageState>((
  ref,
) {
  return StorageNotifier();
});
