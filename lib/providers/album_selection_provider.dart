import 'package:flutter_riverpod/flutter_riverpod.dart';

// State provider to toggle selection mode for albums
final isAlbumSelectionModeProvider = StateProvider<bool>((ref) => false);

// State provider to track selected album identifiers (e.g., "${album.album}_${album.artist}")
final selectedAlbumIdsProvider = StateProvider<Set<String>>((ref) => {});
