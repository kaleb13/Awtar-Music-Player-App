import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:audiotags/audiotags.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/song.dart';
import '../models/artist.dart';
import '../models/album.dart';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../main.dart';

enum LibraryPermissionStatus {
  initial,
  requesting,
  granted,
  denied,
  permanentlyDenied,
}

class LibraryState {
  final List<Song> songs;
  final List<Artist> artists;
  final List<Album> albums;
  final List<String> folders;
  final Map<String, List<String>> storageMap;
  final Song? bannerSong;
  final bool isLoading;
  final LibraryPermissionStatus permissionStatus;
  final String? errorMessage;
  final String? completionMessage;
  final double metadataLoadProgress;
  final bool isReloadingMetadata;

  LibraryState({
    this.songs = const [],
    this.artists = const [],
    this.albums = const [],
    this.folders = const [],
    this.storageMap = const {},
    this.bannerSong,
    this.isLoading = false,
    this.permissionStatus = LibraryPermissionStatus.initial,
    this.errorMessage,
    this.completionMessage,
    this.metadataLoadProgress = 0.0,
    this.isReloadingMetadata = false,
  });

  LibraryState copyWith({
    List<Song>? songs,
    List<Artist>? artists,
    List<Album>? albums,
    List<String>? folders,
    Map<String, List<String>>? storageMap,
    Song? bannerSong,
    bool? isLoading,
    LibraryPermissionStatus? permissionStatus,
    String? errorMessage,
    String? completionMessage,
    double? metadataLoadProgress,
    bool? isReloadingMetadata,
  }) {
    return LibraryState(
      songs: songs ?? this.songs,
      artists: artists ?? this.artists,
      albums: albums ?? this.albums,
      folders: folders ?? this.folders,
      storageMap: storageMap ?? this.storageMap,
      bannerSong: bannerSong ?? this.bannerSong,
      isLoading: isLoading ?? this.isLoading,
      permissionStatus: permissionStatus ?? this.permissionStatus,
      errorMessage:
          errorMessage, // Allow clearing by passing null? No, copyWith semantics usually preserve. We will explicitly pass null if needed.
      completionMessage: completionMessage,
      metadataLoadProgress: metadataLoadProgress ?? this.metadataLoadProgress,
      isReloadingMetadata: isReloadingMetadata ?? this.isReloadingMetadata,
    );
  }
}

class LibraryNotifier extends StateNotifier<LibraryState> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final Ref _ref;

  LibraryNotifier(this._ref) : super(LibraryState()) {
    _init();
  }

  Future<void> _init() async {
    // 1. Try to load from cache immediately for fast startup
    await _loadFromCache();
    // 2. Check permissions and scan in background
    await _checkPermission();
  }

  Future<void> _loadFromCache() async {
    try {
      final prefs = _ref.read(sharedPreferencesProvider);
      final cacheData = prefs.getString('library_cache_v2');
      if (cacheData != null) {
        final Map<String, dynamic> decoded = jsonDecode(cacheData);

        final songs = (decoded['songs'] as List)
            .map((s) => Song.fromMap(s))
            .toList();
        final artists = (decoded['artists'] as List)
            .map((a) => Artist.fromMap(a))
            .toList();
        final albums = (decoded['albums'] as List)
            .map((a) => Album.fromMap(a))
            .toList();
        final folders = List<String>.from(decoded['folders'] ?? []);
        final Map<String, List<String>> storageMap = {};
        if (decoded['storageMap'] != null) {
          (decoded['storageMap'] as Map).forEach((k, v) {
            storageMap[k.toString()] = List<String>.from(v);
          });
        }

        state = state.copyWith(
          songs: songs,
          artists: artists,
          albums: albums,
          folders: folders,
          storageMap: storageMap,
        );

        if (songs.isNotEmpty) {
          _updateBannerSong(songs);
        }
      }
    } catch (e) {
      debugPrint("Error loading library cache: $e");
    }
  }

  Future<void> _saveToCache() async {
    try {
      final prefs = _ref.read(sharedPreferencesProvider);
      final cacheData = jsonEncode({
        'songs': state.songs.map((s) => s.toMap()).toList(),
        'artists': state.artists.map((a) => a.toMap()).toList(),
        'albums': state.albums.map((a) => a.toMap()).toList(),
        'folders': state.folders,
        'storageMap': state.storageMap,
      });
      await prefs.setString('library_cache_v2', cacheData);
    } catch (e) {
      debugPrint("Error saving library cache: $e");
    }
  }

  Future<void> _checkPermission() async {
    try {
      PermissionStatus status;
      status = await Permission.audio.status;

      if (!status.isGranted) {
        final storageStatus = await Permission.storage.status;
        if (storageStatus.isGranted) {
          status = storageStatus;
        }
      }

      if (status.isGranted) {
        state = state.copyWith(
          permissionStatus: LibraryPermissionStatus.granted,
        );
        await scanLibrary();
      } else if (status.isPermanentlyDenied) {
        state = state.copyWith(
          permissionStatus: LibraryPermissionStatus.permanentlyDenied,
        );
      } else {
        state = state.copyWith(
          permissionStatus: LibraryPermissionStatus.initial,
        );
      }
    } catch (e) {
      debugPrint("Error checking permission: $e");
      state = state.copyWith(
        permissionStatus: LibraryPermissionStatus.initial,
        errorMessage: "Failed to check permissions",
      );
    }
  }

  Future<void> requestPermission() async {
    try {
      state = state.copyWith(
        permissionStatus: LibraryPermissionStatus.requesting,
      );

      Map<Permission, PermissionStatus> statuses = await [
        Permission.audio,
        Permission.storage,
      ].request();

      final audioGranted = statuses[Permission.audio]?.isGranted ?? false;
      final storageGranted = statuses[Permission.storage]?.isGranted ?? false;

      if (audioGranted || storageGranted) {
        state = state.copyWith(
          permissionStatus: LibraryPermissionStatus.granted,
        );
        await scanLibrary();
      } else {
        final audioDenied =
            statuses[Permission.audio]?.isPermanentlyDenied ?? false;
        final storageDenied =
            statuses[Permission.storage]?.isPermanentlyDenied ?? false;

        if (audioDenied || storageDenied) {
          state = state.copyWith(
            permissionStatus: LibraryPermissionStatus.permanentlyDenied,
            errorMessage: "Storage permission permanently denied",
          );
        } else {
          state = state.copyWith(
            permissionStatus: LibraryPermissionStatus.denied,
            errorMessage: "Storage permission denied",
          );
        }
      }
    } catch (e) {
      debugPrint("Error requesting permission: $e");
      state = state.copyWith(
        permissionStatus: LibraryPermissionStatus.denied,
        errorMessage: "Failed to request permissions: $e",
      );
    }
  }

  Future<void> openSettings() async {
    await openAppSettings();
  }

  Future<void> scanLibrary() async {
    if (state.songs.isEmpty) {
      state = state.copyWith(isLoading: true, errorMessage: null);
    }

    try {
      final results = await Future.wait([
        _audioQuery.querySongs(
          sortType: null,
          orderType: OrderType.ASC_OR_SMALLER,
          uriType: UriType.EXTERNAL,
          ignoreCase: true,
        ),
        _audioQuery.queryArtists(),
        _audioQuery.queryAlbums(),
      ]);

      final songModels = results[0] as List<SongModel>;
      final artistModels = results[1] as List<ArtistModel>;
      final albumModels = results[2] as List<AlbumModel>;

      final songs = songModels.map((s) {
        String? artworkUri;
        if (s.id != 0) {
          artworkUri = 'content://media/external/audio/albumart/${s.albumId}';
        }

        return Song(
          id: s.id,
          title: s.title,
          artist: s.artist ?? "Unknown Artist",
          album: s.album,
          albumArt: artworkUri,
          url: s.data,
          duration: s.duration ?? 0,
          lyrics: [],
        );
      }).toList();

      final artists = artistModels
          .map(
            (a) => Artist(
              id: a.id,
              artist: a.artist,
              numberOfTracks: a.numberOfTracks ?? 0,
              numberOfAlbums: a.numberOfAlbums ?? 0,
            ),
          )
          .toList();

      final albums = albumModels
          .map(
            (a) => Album(
              id: a.id,
              album: a.album,
              artist: a.artist ?? "Unknown Artist",
              numberOfSongs: a.numOfSongs ?? 0,
            ),
          )
          .toList();

      final Set<String> folderSet = {};
      final Map<String, Set<String>> storageParentFolders = {};

      for (final s in songs) {
        final path = s.url;
        final index = path.lastIndexOf('/');
        if (index != -1) {
          final dirPath = path.substring(0, index);
          folderSet.add(dirPath);

          // Storage logic
          String storageRoot = "";
          if (path.startsWith("/storage/emulated/0")) {
            storageRoot = "/storage/emulated/0";
          } else {
            // Check for /storage/XXXX-XXXX
            final parts = path.split('/');
            if (parts.length >= 3 && parts[1] == 'storage') {
              storageRoot = "/storage/${parts[2]}";
            }
          }

          if (storageRoot.isNotEmpty) {
            final relativePath = path.substring(storageRoot.length);
            final relParts = relativePath
                .split('/')
                .where((p) => p.isNotEmpty)
                .toList();
            if (relParts.length > 1) {
              // It's in a subfolder. The first part is the "Parent Folder" the user wants.
              final parentName = relParts.first;
              storageParentFolders
                  .putIfAbsent(storageRoot, () => {})
                  .add("$storageRoot/$parentName");
            } else {
              // Direct file in root? Or just one level.
              // If it's just /storage/emulated/0/Song.mp3, keep it in root?
              // User said: "only the parent folders will be displayed"
            }
          }
        }
      }

      final storageMap = storageParentFolders.map((key, value) {
        return MapEntry(key, value.toList());
      });

      state = state.copyWith(
        songs: songs,
        artists: artists,
        albums: albums,
        folders: folderSet.toList(),
        storageMap: storageMap,
        isLoading: false,
      );

      if (songs.isNotEmpty) {
        _updateBannerSong(songs);
      }

      _saveToCache();
    } catch (e) {
      debugPrint("Error scanning library: $e");
      state = state.copyWith(
        isLoading: false,
        errorMessage: state.songs.isEmpty ? "Failed to scan library: $e" : null,
      );
    }
  }

  void _updateBannerSong(List<Song> songs) {
    if (songs.isEmpty) return;

    // Filter by criteria: has art AND not unknown artist
    final validSongs = songs.where((s) {
      final hasArt = s.albumArt != null && s.albumArt!.isNotEmpty;
      final artistName = s.artist.toLowerCase();
      final isKnown =
          !artistName.contains("unknown") && !artistName.contains("<unknown>");
      return hasArt && isKnown;
    }).toList();

    if (validSongs.isEmpty) {
      // Fallback: any song with art if no "known" artists have art
      final songsWithArt = songs.where((s) => s.albumArt != null).toList();
      if (songsWithArt.isNotEmpty) {
        state = state.copyWith(
          bannerSong: songsWithArt[Random().nextInt(songsWithArt.length)],
        );
      } else {
        // Absolute fallback
        state = state.copyWith(
          bannerSong: songs[Random().nextInt(songs.length)],
        );
      }
      return;
    }

    final randomSong = validSongs[Random().nextInt(validSongs.length)];
    state = state.copyWith(bannerSong: randomSong);
  }

  Future<void> reloadMetadata() async {
    if (state.songs.isEmpty) return;

    // Clear error/completion messages at start
    state = LibraryState(
      songs: state.songs,
      artists: state.artists,
      albums: state.albums,
      folders: state.folders,
      storageMap: state.storageMap,
      bannerSong: state.bannerSong,
      isLoading: state.isLoading,
      permissionStatus: state.permissionStatus,
      // explicit reset
      errorMessage: null,
      completionMessage: null,
      isReloadingMetadata: true,
      metadataLoadProgress: 0.0,
    );

    List<Song> updatedSongs = [];
    int total = state.songs.length;
    int updatedCount = 0;

    for (int i = 0; i < total; i++) {
      // Check if cancelled or error occurred
      if (state.errorMessage != null &&
          state.errorMessage!.contains("restart")) {
        break;
      }

      Song song = state.songs[i];
      try {
        // Skip if not a valid file path
        if (!song.url.startsWith("http") &&
            !song.url.startsWith("content://")) {
          final file = File(song.url);
          if (await file.exists()) {
            final tag = await AudioTags.read(song.url);
            if (tag != null) {
              List<LyricLine> lyrics = [];
              if (tag.lyrics != null && tag.lyrics!.isNotEmpty) {
                final lines = tag.lyrics!.split('\n');
                lyrics = lines
                    .map(
                      (line) =>
                          LyricLine(time: Duration.zero, text: line.trim()),
                    )
                    .where((l) => l.text.isNotEmpty)
                    .toList();
              }

              song = song.copyWith(
                title: tag.title,
                artist: tag.trackArtist,
                album: tag.album,
                lyrics: lyrics,
              );
              updatedCount++;
            }
          }
        }
      } catch (e) {
        debugPrint("Error reloading metadata: $e");
        if (e.toString().contains("MissingPluginException")) {
          state = state.copyWith(
            errorMessage:
                "Please restart the app to enable metadata reloading (Native plugin missing).",
            isReloadingMetadata: false,
          );
          return;
        }
      }
      updatedSongs.add(song);
      state = state.copyWith(metadataLoadProgress: (i + 1) / total);
    }

    if (state.errorMessage == null) {
      state = state.copyWith(
        songs: updatedSongs,
        isReloadingMetadata: false,
        metadataLoadProgress: 1.0,
        completionMessage: "Done! Processed $updatedCount files.",
      );
      _saveToCache();
    }
  }
}

final libraryProvider = StateNotifierProvider<LibraryNotifier, LibraryState>((
  ref,
) {
  return LibraryNotifier(ref);
});
