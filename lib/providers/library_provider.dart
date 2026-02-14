import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:audiotags/audiotags.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/song.dart';
import '../models/artist.dart';
import '../models/album.dart';
import '../models/playlist.dart';
import 'dart:math';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../main.dart';
import 'player_provider.dart';
import '../services/lyrics_service.dart';
import '../services/database_service.dart';
import '../services/palette_service.dart';

enum LibraryPermissionStatus {
  initial,
  requesting,
  granted,
  denied,
  permanentlyDenied,
}

enum AlbumNameSource { metadata, folder }

enum TitleSource { metadata, filename }

class LibraryState {
  final List<Song> songs;
  final List<Artist> artists;
  final List<Album> albums;
  final List<Playlist> playlists;
  final List<String> folders;
  final List<String> discoveredFolders;
  final Map<String, List<String>> storageMap;
  final Set<String> excludedFolders;
  final Set<String> hiddenArtists;
  final Set<String> hiddenAlbums;
  final Map<String, int> folderSongCounts;
  final Map<String, int> representativeArtistSongs;
  final Map<String, int> representativeAlbumSongs;
  final Map<String, Color> artistColors;
  final Map<String, Color> albumColors;
  final int lastScanTimestamp;
  final Song? bannerSong;
  final bool isLoading;
  final bool isRefiningLibrary;
  final double refineProgress;
  final LibraryPermissionStatus permissionStatus;
  final String? errorMessage;
  final String? completionMessage;
  final double metadataLoadProgress;
  final bool isReloadingMetadata;
  final double scanProgress; // 0.0 to 1.0
  final AlbumNameSource albumNameSource;
  final TitleSource titleSource;
  final bool hideSmallAlbums;
  final bool hideSmallArtists;
  final bool hideUnknownArtist;

  LibraryState({
    this.songs = const [],
    this.artists = const [],
    this.albums = const [],
    this.playlists = const [],
    this.folders = const [],
    this.discoveredFolders = const [],
    this.storageMap = const {},
    this.excludedFolders = const {},
    this.hiddenArtists = const {},
    this.hiddenAlbums = const {},
    this.folderSongCounts = const {},
    this.representativeArtistSongs = const {},
    this.representativeAlbumSongs = const {},
    this.artistColors = const {},
    this.albumColors = const {},
    this.lastScanTimestamp = 0,
    this.bannerSong,
    this.isLoading = false,
    this.isRefiningLibrary = false,
    this.refineProgress = 0.0,
    this.permissionStatus = LibraryPermissionStatus.initial,
    this.errorMessage,
    this.completionMessage,
    this.metadataLoadProgress = 0.0,
    this.isReloadingMetadata = false,
    this.scanProgress = 0.0,
    this.albumNameSource = AlbumNameSource.metadata,
    this.titleSource = TitleSource.metadata,
    this.hideSmallAlbums = false,
    this.hideSmallArtists = false,
    this.hideUnknownArtist = false,
  });

  LibraryState copyWith({
    List<Song>? songs,
    List<Artist>? artists,
    List<Album>? albums,
    List<Playlist>? playlists,
    List<String>? folders,
    List<String>? discoveredFolders,
    bool? isRefiningLibrary,
    double? refineProgress,
    Map<String, List<String>>? storageMap,
    Set<String>? excludedFolders,
    Set<String>? hiddenArtists,
    Set<String>? hiddenAlbums,
    Map<String, int>? folderSongCounts,
    Map<String, int>? representativeArtistSongs,
    Map<String, int>? representativeAlbumSongs,
    Map<String, Color>? artistColors,
    Map<String, Color>? albumColors,
    int? lastScanTimestamp,
    Song? bannerSong,
    bool? isLoading,
    LibraryPermissionStatus? permissionStatus,
    String? errorMessage,
    String? completionMessage,
    double? metadataLoadProgress,
    bool? isReloadingMetadata,
    double? scanProgress,
    AlbumNameSource? albumNameSource,
    TitleSource? titleSource,
    bool? hideSmallAlbums,
    bool? hideSmallArtists,
    bool? hideUnknownArtist,
  }) {
    return LibraryState(
      songs: songs ?? this.songs,
      artists: artists ?? this.artists,
      albums: albums ?? this.albums,
      playlists: playlists ?? this.playlists,
      folders: folders ?? this.folders,
      discoveredFolders: discoveredFolders ?? this.discoveredFolders,
      isRefiningLibrary: isRefiningLibrary ?? this.isRefiningLibrary,
      refineProgress: refineProgress ?? this.refineProgress,
      storageMap: storageMap ?? this.storageMap,
      excludedFolders: excludedFolders ?? this.excludedFolders,
      hiddenArtists: hiddenArtists ?? this.hiddenArtists,
      hiddenAlbums: hiddenAlbums ?? this.hiddenAlbums,
      folderSongCounts: folderSongCounts ?? this.folderSongCounts,
      representativeArtistSongs:
          representativeArtistSongs ?? this.representativeArtistSongs,
      representativeAlbumSongs:
          representativeAlbumSongs ?? this.representativeAlbumSongs,
      artistColors: artistColors ?? this.artistColors,
      albumColors: albumColors ?? this.albumColors,
      lastScanTimestamp: lastScanTimestamp ?? this.lastScanTimestamp,
      bannerSong: bannerSong ?? this.bannerSong,
      isLoading: isLoading ?? this.isLoading,
      permissionStatus: permissionStatus ?? this.permissionStatus,
      errorMessage: errorMessage,
      completionMessage: completionMessage,
      metadataLoadProgress: metadataLoadProgress ?? this.metadataLoadProgress,
      isReloadingMetadata: isReloadingMetadata ?? this.isReloadingMetadata,
      scanProgress: scanProgress ?? this.scanProgress,
      albumNameSource: albumNameSource ?? this.albumNameSource,
      titleSource: titleSource ?? this.titleSource,
      hideSmallAlbums: hideSmallAlbums ?? this.hideSmallAlbums,
      hideSmallArtists: hideSmallArtists ?? this.hideSmallArtists,
      hideUnknownArtist: hideUnknownArtist ?? this.hideUnknownArtist,
    );
  }
}

class LibraryNotifier extends StateNotifier<LibraryState> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final Ref _ref;

  LibraryNotifier(this._ref, {bool skipInit = false}) : super(LibraryState()) {
    if (!skipInit) {
      _init();
    }
  }

  Future<void> _init() async {
    // 1. Try to load from cache immediately for fast startup
    await _loadFromCache();
    // 2. Check permissions and scan in background
    await _checkPermission();
    _scanForLyrics();
  }

  Future<void> _loadFromCache() async {
    try {
      final prefs = _ref.read(sharedPreferencesProvider);

      // 1. Load structured data from SQLite
      final List<Song> songs = await DatabaseService.getAllSongs();
      final List<Playlist> playlists = await DatabaseService.getAllPlaylists();
      final Map<String, String> artistImages =
          await DatabaseService.getAllArtistImages();

      // 2. Load small settings/metadata from SharedPreferences
      final cacheData = prefs.getString('library_metadata_v1');

      Set<String> excludedFolders = {};
      Set<String> hiddenArtists = {};
      Set<String> hiddenAlbums = {};
      Map<String, List<String>> storageMap = {};
      Map<String, int> repArtists = {};
      Map<String, int> repAlbums = {};
      int lastScan = 0;

      if (cacheData != null) {
        final Map<String, dynamic> decoded = jsonDecode(cacheData);
        excludedFolders = Set<String>.from(decoded['excludedFolders'] ?? []);
        hiddenArtists = Set<String>.from(decoded['hiddenArtists'] ?? []);
        hiddenAlbums = Set<String>.from(decoded['hiddenAlbums'] ?? []);
        final discoveredFolders = List<String>.from(
          decoded['discoveredFolders'] ?? [],
        );

        if (decoded['storageMap'] != null) {
          (decoded['storageMap'] as Map).forEach((k, v) {
            storageMap[k.toString()] = List<String>.from(v);
          });
        }
        repArtists = Map<String, int>.from(decoded['repArtists'] ?? {});
        repAlbums = Map<String, int>.from(decoded['repAlbums'] ?? {});
        lastScan = decoded['lastScan'] ?? 0;

        final albumSource = AlbumNameSource.values.firstWhere(
          (e) => e.name == (decoded['albumNameSource'] ?? 'metadata'),
        );
        final songSource = TitleSource.values.firstWhere(
          (e) => e.name == (decoded['titleSource'] ?? 'metadata'),
        );

        final hideSmallAlbums = decoded['hideSmallAlbums'] ?? false;
        final hideSmallArtists = decoded['hideSmallArtists'] ?? false;
        final hideUnknownArtist = decoded['hideUnknownArtist'] ?? false;

        state = state.copyWith(
          discoveredFolders: discoveredFolders,
          albumNameSource: albumSource,
          titleSource: songSource,
          hideSmallAlbums: hideSmallAlbums,
          hideSmallArtists: hideSmallArtists,
          hideUnknownArtist: hideUnknownArtist,
        );
      }

      // Rebuild Artist objects with the loaded images
      final Map<String, List<Song>> artistSongsGroup = {};
      for (final song in songs) {
        artistSongsGroup.putIfAbsent(song.artist, () => []).add(song);
      }

      final List<Artist> artists = artistSongsGroup.entries.map((entry) {
        final artistAlbums = entry.value
            .map((s) => s.album)
            .where((a) => a != null)
            .toSet()
            .length;
        return Artist(
          id: repArtists[entry.key] ?? entry.value.first.id,
          artist: entry.key,
          numberOfTracks: entry.value.length,
          numberOfAlbums: artistAlbums,
          imagePath: artistImages[entry.key],
        );
      }).toList();

      // Rebuild Album objects
      final Map<String, List<Song>> albumSongsGroup = {};
      for (final song in songs) {
        if (song.album != null) {
          final key = '${song.album}_${song.artist}';
          albumSongsGroup.putIfAbsent(key, () => []).add(song);
        }
      }

      final List<Album> albums = albumSongsGroup.entries.map((entry) {
        return Album(
          id: repAlbums[entry.key] ?? entry.value.first.id,
          album: entry.value.first.album!,
          artist: entry.value.first.artist,
          numberOfSongs: entry.value.length,
        );
      }).toList();

      // NEW: Rebuild Folders and Folder Song Counts immediately from cached songs
      final Set<String> folderSet = {};
      final Map<String, int> folderCounts = {};
      for (final s in songs) {
        final path = s.url;
        final index = path.lastIndexOf('/');
        if (index != -1) {
          final dirPath = path.substring(0, index);
          // Check if folder is excluded
          if (!excludedFolders.contains(dirPath)) {
            folderSet.add(dirPath);
            folderCounts[dirPath] = (folderCounts[dirPath] ?? 0) + 1;
          }
        }
      }
      final List<String> folders = folderSet.toList()..sort();

      state = state.copyWith(
        songs: songs,
        artists: artists,
        albums: albums,
        playlists: playlists,
        folders: folders,
        folderSongCounts: folderCounts,
        storageMap: storageMap,
        excludedFolders: excludedFolders,
        hiddenArtists: hiddenArtists,
        hiddenAlbums: hiddenAlbums,
        representativeArtistSongs: repArtists,
        representativeAlbumSongs: repAlbums,
        lastScanTimestamp: lastScan,
      );

      // Trigger background color calculation
      _calculateArtistColors(artists, songs);
      _calculateAlbumColors(albums, songs);

      if (songs.isNotEmpty) {
        _updateBannerSong(songs);
      }
    } catch (e) {
      debugPrint("Error loading from DB/Cache: $e");
    }
  }

  Future<void> _saveToCache() async {
    try {
      final prefs = _ref.read(sharedPreferencesProvider);

      // 1. Save core data to SQLite
      await DatabaseService.saveSongs(state.songs);
      await DatabaseService.savePlaylists(state.playlists);

      // 2. Save UI metadata to SharedPreferences
      final metadata = jsonEncode({
        'excludedFolders': state.excludedFolders.toList(),
        'hiddenArtists': state.hiddenArtists.toList(),
        'hiddenAlbums': state.hiddenAlbums.toList(),
        'discoveredFolders': state.discoveredFolders,
        'storageMap': state.storageMap,
        'repArtists': state.representativeArtistSongs,
        'repAlbums': state.representativeAlbumSongs,
        'lastScan': state.lastScanTimestamp,
        'albumNameSource': state.albumNameSource.name,
        'titleSource': state.titleSource.name,
        'hideSmallAlbums': state.hideSmallAlbums,
        'hideSmallArtists': state.hideSmallArtists,
        'hideUnknownArtist': state.hideUnknownArtist,
      });
      await prefs.setString('library_metadata_v1', metadata);
    } catch (e) {
      debugPrint("Error saving to DB/Cache: $e");
    }
  }

  Future<void> updateNamingConfiguration({
    required AlbumNameSource albumSource,
    required TitleSource titleSource,
  }) async {
    // Only proceed if something actually changed
    if (state.albumNameSource == albumSource &&
        state.titleSource == titleSource) {
      return;
    }

    state = state.copyWith(
      isLoading: true,
      scanProgress: 0.0,
      albumNameSource: albumSource,
      titleSource: titleSource,
    );

    // Give UI a moment to show the loader
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      // Re-scan is the safest way to "reset" the naming correctly
      // as it pulls fresh metadata from the system and applies our folder/filename overrides
      await scanLibrary(force: true);

      state = state.copyWith(
        isLoading: false,
        completionMessage: "Configuration updated successfully!",
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: "Failed to update configuration: $e",
      );
    }

    _saveToCache();
    // Auto-clear message
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) state = state.copyWith(completionMessage: null);
    });
  }

  void toggleArtistVisibility(String artistName) {
    final hidden = Set<String>.from(state.hiddenArtists);
    if (hidden.contains(artistName)) {
      hidden.remove(artistName);
    } else {
      hidden.add(artistName);
    }
    state = state.copyWith(hiddenArtists: hidden);
    _saveToCache();
  }

  void toggleHideSmallAlbums(bool value) {
    state = state.copyWith(hideSmallAlbums: value);
    _saveToCache();
  }

  void toggleHideSmallArtists(bool value) {
    state = state.copyWith(hideSmallArtists: value);
    _saveToCache();
  }

  void toggleHideUnknownArtist(bool value) {
    state = state.copyWith(hideUnknownArtist: value);
    _saveToCache();
  }

  Future<void> deleteSongs(List<Song> songs) async {
    try {
      state = state.copyWith(isLoading: true);

      // Separate songs into successful deletions and failures
      final List<int> deletedIds = [];

      for (final song in songs) {
        final file = File(song.url);
        if (await file.exists()) {
          try {
            await file.delete();
            deletedIds.add(song.id);
          } catch (e) {
            debugPrint("Failed to delete file: ${song.url}, error: $e");
          }
        } else {
          // File doesn't exist, remove from DB anyway
          deletedIds.add(song.id);
        }
      }

      if (deletedIds.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: "No songs were deleted.",
        );
        return;
      }

      // Update state by removing deleted songs
      final newSongs = state.songs
          .where((s) => !deletedIds.contains(s.id))
          .toList();

      // Re-process albums/artists/folders
      final newArtists = _extractArtists(newSongs);
      final newAlbums = _extractAlbums(newSongs);
      final newFolders = _extractFolders(newSongs);

      state = state.copyWith(
        songs: newSongs,
        artists: newArtists,
        albums: newAlbums,
        folders: newFolders,
        isLoading: false,
        completionMessage: "Deleted ${deletedIds.length} songs.",
      );

      // Persist changes if necessary (usually handled by re-scan or just cache)
      _saveToCache();

      // Auto-clear message
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) state = state.copyWith(completionMessage: null);
      });
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: "Failed to delete songs: $e",
      );
    }
  }

  void toggleAlbumVisibility(String albumKey) {
    final hidden = Set<String>.from(state.hiddenAlbums);
    if (hidden.contains(albumKey)) {
      hidden.remove(albumKey);
    } else {
      hidden.add(albumKey);
    }
    state = state.copyWith(hiddenAlbums: hidden);
    _saveToCache();
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

  Future<void> scanLibrary({bool force = false}) async {
    if (state.songs.isEmpty) {
      state = state.copyWith(isLoading: true, errorMessage: null);
    }

    try {
      // 1. Fast check: query only song count or ids to see if we need a full scan
      final songModels = await _audioQuery.querySongs(
        sortType: null,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );

      // Compute a lightweight signature to detect changes reliably
      final int currentCount = songModels.length;
      int currentIdSum = 0;
      int currentDurationSum = 0;
      for (var s in songModels) {
        currentIdSum += s.id;
        currentDurationSum += (s.duration ?? 0);
      }

      // Compare with current state signature
      int stateIdSum = 0;
      int stateDurationSum = 0;
      for (var s in state.songs) {
        stateIdSum += s.id;
        stateDurationSum += s.duration;
      }

      // If signature matches and it's not a forced scan, and we have data, skip the heavy scan
      if (!force &&
          state.songs.isNotEmpty &&
          currentCount == state.songs.length &&
          currentIdSum == stateIdSum &&
          currentDurationSum == stateDurationSum) {
        debugPrint("Library scan skipped: item signature identical.");
        state = state.copyWith(isLoading: false);
        return;
      }

      state = state.copyWith(scanProgress: 0.1);

      final int totalSongs = songModels.length;
      final List<Song> songs = [];

      for (int i = 0; i < totalSongs; i++) {
        final s = songModels[i];
        String? artworkUri;
        if (s.id != 0) {
          artworkUri = 'content://media/external/audio/albumart/${s.albumId}';
        }

        final folderName = s.data.split('/').reversed.elementAt(1);
        final fileName = s.data.split('/').last.split('.').first;

        final String finalTitle = state.titleSource == TitleSource.metadata
            ? s.title
            : fileName;
        final String? finalAlbum =
            state.albumNameSource == AlbumNameSource.metadata
            ? s.album
            : folderName;

        songs.add(
          Song(
            id: s.id,
            title: finalTitle,
            artist: s.artist ?? "Unknown Artist",
            album: finalAlbum,
            albumArt: artworkUri,
            url: s.data,
            duration: s.duration ?? 0,
            lyrics: [],
            trackNumber: (s.track != null && s.track! >= 1000)
                ? s.track! % 1000
                : s.track,
            genre: s.genre,
          ),
        );

        if (i % 50 == 0) {
          state = state.copyWith(scanProgress: 0.1 + (i / totalSongs) * 0.7);
        }
      }

      state = state.copyWith(scanProgress: 0.85);

      // Get favorites from DB to preserve them
      final dbSongs = await DatabaseService.getAllSongs();
      final favoritedIds = dbSongs
          .where((s) => s.isFavorite)
          .map((s) => s.id)
          .toSet();

      final updatedSongs = songs.map((s) {
        if (favoritedIds.contains(s.id)) return s.copyWith(isFavorite: true);
        return s;
      }).toList();

      final Map<String, Set<String>> storageParentFolders = {};
      final Set<String> filteredFolderSet = {};
      final Set<String> allDiscoveredFolders = {};

      final Map<String, int> repArtists = {};
      final Map<String, int> repAlbums = {};

      for (final s in updatedSongs) {
        final path = s.url;
        final index = path.lastIndexOf('/');
        if (index != -1) {
          final dirPath = path.substring(0, index);
          allDiscoveredFolders.add(dirPath);

          repArtists.putIfAbsent(s.artist, () => s.id);
          if (s.album != null) {
            repAlbums.putIfAbsent("${s.album}_${s.artist}", () => s.id);
          }

          // Determine storage root for this folder
          String storageRoot = "";
          if (dirPath.startsWith("/storage/emulated/0")) {
            storageRoot = "/storage/emulated/0";
          } else {
            final parts = dirPath.split('/');
            if (parts.length >= 3 && parts[1] == 'storage') {
              storageRoot = "/storage/${parts[2]}";
            }
          }

          if (storageRoot.isNotEmpty) {
            final relativePath = dirPath.substring(storageRoot.length);
            final relParts = relativePath
                .split('/')
                .where((p) => p.isNotEmpty)
                .toList();
            if (relParts.isNotEmpty) {
              final topLevelFolderName = relParts.first;
              storageParentFolders
                  .putIfAbsent(storageRoot, () => {})
                  .add("$storageRoot/$topLevelFolderName");
            }
          }
        }
      }

      final filteredSongs = _filterSongsByFolders(
        updatedSongs,
        state.excludedFolders,
      );
      final artists = _rebuildArtists(filteredSongs);
      final albums = _rebuildAlbums(filteredSongs);

      for (final s in filteredSongs) {
        final path = s.url;
        final index = path.lastIndexOf('/');
        if (index != -1) {
          filteredFolderSet.add(path.substring(0, index));
        }
      }

      final storageMap = storageParentFolders.map(
        (key, value) => MapEntry(key, value.toList()),
      );

      // Precompute folder song counts
      final Map<String, int> folderCounts = {};
      for (final s in filteredSongs) {
        final path = s.url;
        final index = path.lastIndexOf('/');
        if (index != -1) {
          final dirPath = path.substring(0, index);
          folderCounts[dirPath] = (folderCounts[dirPath] ?? 0) + 1;
        }
      }

      state = state.copyWith(
        songs: filteredSongs,
        artists: artists,
        albums: albums,
        folders: filteredFolderSet.toList(),
        discoveredFolders: allDiscoveredFolders.toList(),
        storageMap: storageMap,
        folderSongCounts: folderCounts,
        representativeArtistSongs: repArtists,
        representativeAlbumSongs: repAlbums,
        lastScanTimestamp: DateTime.now().millisecondsSinceEpoch,
        isLoading: false,
        scanProgress: 1.0,
      );

      if (filteredSongs.isNotEmpty) {
        _updateBannerSong(filteredSongs);
      }

      // Trigger background color calculation
      _calculateArtistColors(artists, filteredSongs);
      _calculateAlbumColors(albums, filteredSongs);

      await _saveToCache();
      _scanForLyrics();
    } catch (e) {
      debugPrint("Error scanning library: $e");
      state = state.copyWith(
        isLoading: false,
        errorMessage: state.songs.isEmpty ? "Failed to scan library: $e" : null,
      );
    }
  }

  void toggleFavorite(Song song) {
    // Get the most up-to-date song from our list to avoid stale state
    final currentSongInLib = state.songs.firstWhere(
      (s) => s.id == song.id,
      orElse: () => song,
    );
    bool newStatus = !currentSongInLib.isFavorite;

    // 1. Update library state
    state = state.copyWith(
      songs: state.songs.map((s) {
        if (s.id == song.id) {
          return s.copyWith(isFavorite: newStatus);
        }
        return s;
      }).toList(),
    );

    // 2. Update player state via its notifier
    _ref.read(playerProvider.notifier).updateFavoriteStatus(song.id, newStatus);

    // 3. Update banner song if it matches
    if (state.bannerSong?.id == song.id) {
      state = state.copyWith(
        bannerSong: state.bannerSong!.copyWith(isFavorite: newStatus),
      );
    }

    _saveToCache();
  }

  // Playlist Management
  void createPlaylist(String name) {
    final newPlaylist = Playlist(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      songIds: [],
      createdAt: DateTime.now(),
    );
    state = state.copyWith(playlists: [...state.playlists, newPlaylist]);
    _saveToCache();
  }

  void deletePlaylist(Playlist playlist) {
    state = state.copyWith(
      playlists: state.playlists.where((p) => p.id != playlist.id).toList(),
    );
    _saveToCache();
  }

  void addToPlaylist(String playlistId, int songId) {
    state = state.copyWith(
      playlists: state.playlists.map((p) {
        if (p.id == playlistId) {
          if (!p.songIds.contains(songId)) {
            return p.copyWith(songIds: [...p.songIds, songId]);
          }
        }
        return p;
      }).toList(),
    );
    _saveToCache();
  }

  void removeFromPlaylist(String playlistId, int songId) {
    state = state.copyWith(
      playlists: state.playlists.map((p) {
        if (p.id == playlistId) {
          return p.copyWith(
            songIds: p.songIds.where((id) => id != songId).toList(),
          );
        }
        return p;
      }).toList(),
    );
    _saveToCache();
  }

  Future<void> updatePlaylistImage(String playlistId, String imagePath) async {
    // Save image permanently to app documents if it's from a temp location
    String finalPath = imagePath;
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        final docDir = await getApplicationDocumentsDirectory();
        final fileName =
            'playlist_${playlistId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedImage = await file.copy('${docDir.path}/$fileName');
        finalPath = savedImage.path;
      }
    } catch (e) {
      debugPrint("Error saving playlist image: $e");
    }

    state = state.copyWith(
      playlists: state.playlists.map((p) {
        if (p.id == playlistId) {
          return p.copyWith(imagePath: finalPath);
        }
        return p;
      }).toList(),
    );
    _saveToCache();
  }

  Future<void> updateArtistImage(String artistName, String imagePath) async {
    // Save image permanently to app documents if it's from a temp location
    String finalPath = imagePath;
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        final docDir = await getApplicationDocumentsDirectory();
        final fileName =
            'artist_${artistName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedImage = await file.copy('${docDir.path}/$fileName');
        finalPath = savedImage.path;
      }
    } catch (e) {
      debugPrint("Error saving artist image: $e");
    }

    // 1. Update image path immediately in state for instant UI feedback
    state = state.copyWith(
      artists: state.artists.map((a) {
        if (a.artist == artistName) {
          return a.copyWith(imagePath: finalPath);
        }
        return a;
      }).toList(),
    );

    // 2. Calculate new color asynchronously and update state when ready
    _getArtistColor(artistName, finalPath, null).then((newColor) {
      if (mounted) {
        state = state.copyWith(
          artistColors: {...state.artistColors, artistName: newColor},
        );
      }
    });

    // Save to DB
    DatabaseService.saveArtistImage(artistName, finalPath);
    _saveToCache();
  }

  Future<void> _calculateArtistColors(
    List<Artist> artists,
    List<Song> songs,
  ) async {
    final Map<String, Color> colors = {...state.artistColors};
    bool changed = false;

    for (final artist in artists) {
      if (!colors.containsKey(artist.artist)) {
        final songId = state.representativeArtistSongs[artist.artist];
        final song = songs.firstWhere(
          (s) => s.id == songId,
          orElse: () => songs.first,
        );

        final color = await _getArtistColor(
          artist.artist,
          artist.imagePath,
          song,
        );
        colors[artist.artist] = color;
        changed = true;
      }
    }

    if (changed && mounted) {
      state = state.copyWith(artistColors: colors);
    }
  }

  Future<void> _calculateAlbumColors(
    List<Album> albums,
    List<Song> songs,
  ) async {
    final Map<String, Color> colors = {...state.albumColors};
    bool changed = false;

    for (final album in albums) {
      final String albumKey = '${album.album}_${album.artist}';
      if (!colors.containsKey(albumKey)) {
        final songId = state.representativeAlbumSongs[albumKey];
        final song = songs.firstWhere(
          (s) => s.id == songId,
          orElse: () => songs.first,
        );

        final color = await PaletteService.getColor(
          song.albumArt ?? "",
          songId: song.id,
          songPath: song.url,
        );
        colors[albumKey] = color;
        changed = true;
      }
    }

    if (changed && mounted) {
      state = state.copyWith(albumColors: colors);
    }
  }

  Future<Color> _getArtistColor(
    String name,
    String? path,
    Song? fallbackSong,
  ) async {
    if (path != null && path.isNotEmpty) {
      return await PaletteService.getColor(path);
    } else if (fallbackSong != null) {
      return await PaletteService.getColor(
        fallbackSong.albumArt ?? "",
        songId: fallbackSong.id,
        songPath: fallbackSong.url,
      );
    }
    return const Color(0xFF4A90E2); // Fallback blue
  }

  // Folder Exclusion Management
  Future<void> toggleFolderExclusion(String folderPath) async {
    state = state.copyWith(
      isRefiningLibrary: true,
      refineProgress: 0.0,
      completionMessage: null,
    );

    final excludedFolders = Set<String>.from(state.excludedFolders);

    if (excludedFolders.contains(folderPath)) {
      excludedFolders.remove(folderPath);
    } else {
      excludedFolders.add(folderPath);
    }

    state = state.copyWith(
      excludedFolders: excludedFolders,
      refineProgress: 0.2,
    );
    await Future.delayed(const Duration(milliseconds: 300)); // Visual feedback

    // We need 'all' songs to refilter.
    // Instead of keeping a master list, we rescan (which is fast due to signature)
    // but we'll force it to apply the new filters.
    await scanLibrary(force: true);

    state = state.copyWith(
      refineProgress: 1.0,
      isRefiningLibrary: false,
      completionMessage: excludedFolders.contains(folderPath)
          ? "Folder excluded successfully"
          : "Folder included successfully",
    );

    // Auto-clear message after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) state = state.copyWith(completionMessage: null);
    });
  }

  List<Song> _filterSongsByFolders(
    List<Song> allSongs,
    Set<String> excludedFolders,
  ) {
    if (excludedFolders.isEmpty) return allSongs;

    return allSongs.where((song) {
      // Check if song's path starts with any excluded folder
      for (final excludedPath in excludedFolders) {
        if (song.url.startsWith(excludedPath)) {
          return false; // Exclude this song
        }
      }
      return true; // Include this song
    }).toList();
  }

  List<Artist> _rebuildArtists(List<Song> songs) {
    final Map<String, List<Song>> artistSongs = {};
    for (final song in songs) {
      artistSongs.putIfAbsent(song.artist, () => []).add(song);
    }

    // Preserve custom artist images
    final Map<String, String> artistImageMap = {
      for (var a in state.artists)
        if (a.imagePath != null) a.artist: a.imagePath!,
    };

    return artistSongs.entries.map((entry) {
      final artistAlbums = entry.value
          .map((s) => s.album)
          .where((a) => a != null)
          .toSet()
          .length;
      return Artist(
        id: state.representativeArtistSongs[entry.key] ?? entry.value.first.id,
        artist: entry.key,
        numberOfTracks: entry.value.length,
        numberOfAlbums: artistAlbums,
        imagePath: artistImageMap[entry.key],
      );
    }).toList();
  }

  List<Album> _rebuildAlbums(List<Song> songs) {
    final Map<String, List<Song>> albumSongs = {};
    for (final song in songs) {
      if (song.album != null) {
        final key = '${song.album}_${song.artist}';
        albumSongs.putIfAbsent(key, () => []).add(song);
      }
    }

    return albumSongs.entries.map((entry) {
      final songs = entry.value;
      return Album(
        id: state.representativeAlbumSongs[entry.key] ?? songs.first.id,
        album: songs.first.album!,
        artist: songs.first.artist,
        numberOfSongs: songs.length,
      );
    }).toList();
  }

  bool isFolderExcluded(String folderPath) {
    for (final excluded in state.excludedFolders) {
      if (folderPath == excluded || folderPath.startsWith("$excluded/")) {
        return true;
      }
    }
    return false;
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
    state = state.copyWith(
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
                albumArtist: tag.albumArtist,
                lyrics: lyrics,
                trackNumber:
                    (tag.trackNumber != null && tag.trackNumber! >= 1000)
                    ? tag.trackNumber! % 1000
                    : tag.trackNumber,
                genre: tag.genre,
                year: tag.year,
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

  Future<void> updateSongMetadata(
    Song song, {
    String? title,
    String? artist,
    String? album,
    int? trackNumber,
    String? genre,
    int? year,
    String? albumArtist,
  }) async {
    try {
      // 1. Update File Metadata if it's a local file
      if (!song.url.startsWith("http") && !song.url.startsWith("content://")) {
        final currentTag = await AudioTags.read(song.url);
        final tag = Tag(
          title: title ?? song.title,
          trackArtist: artist ?? song.artist,
          album: album ?? song.album,
          trackNumber: trackNumber ?? song.trackNumber,
          genre: genre ?? song.genre,
          year: year ?? song.year,
          albumArtist: albumArtist ?? song.albumArtist,
          pictures: currentTag?.pictures ?? [],
        );
        await AudioTags.write(song.url, tag);
      }

      // 2. Update Database & State
      final updatedSong = song.copyWith(
        title: title,
        artist: artist,
        album: album,
        trackNumber: trackNumber,
        genre: genre,
        year: year,
        albumArtist: albumArtist,
      );

      state = state.copyWith(
        songs: state.songs
            .map((s) => s.id == song.id ? updatedSong : s)
            .toList(),
      );

      // 3. Rebuild structures
      state = state.copyWith(
        artists: _rebuildArtists(state.songs),
        albums: _rebuildAlbums(state.songs),
      );

      await _saveToCache();
    } catch (e) {
      debugPrint("Error updating song metadata: $e");
      rethrow;
    }
  }

  Future<void> updateSongLyrics(Song song, String lyricsText) async {
    try {
      List<LyricLine> lyrics = [];
      if (lyricsText.contains('[') && lyricsText.contains(']')) {
        lyrics = LyricsService.parseLrc(lyricsText);
      }

      if (lyrics.isEmpty) {
        lyrics = lyricsText
            .split('\n')
            .where((line) => line.trim().isNotEmpty)
            .map((line) => LyricLine(time: Duration.zero, text: line.trim()))
            .toList();
      }

      // 1. Update file metadata
      if (!song.url.startsWith("http") && !song.url.startsWith("content://")) {
        final currentTag = await AudioTags.read(song.url);
        final tag = Tag(
          title: currentTag?.title,
          trackArtist: currentTag?.trackArtist,
          album: currentTag?.album,
          lyrics: lyricsText,
          pictures: currentTag?.pictures ?? [],
        );
        await AudioTags.write(song.url, tag);
      }

      // 2. Update DB & State
      final updatedSong = song.copyWith(lyrics: lyrics);
      state = state.copyWith(
        songs: state.songs
            .map((s) => s.id == song.id ? updatedSong : s)
            .toList(),
      );

      await DatabaseService.saveLyrics(song.id, lyrics);

      // 3. Update Player Provider if this is the current song
      _ref
          .read(playerProvider.notifier)
          .updateLyricsInState(song.id, lyrics, false);

      await _saveToCache();
    } catch (e) {
      debugPrint("Error updating lyrics: $e");
      rethrow;
    }
  }

  Future<void> updateAlbumMetadata(
    String oldAlbumName,
    String oldArtistName, {
    String? newTitle,
    String? newArtist,
    int? year,
  }) async {
    try {
      final songsInAlbum = state.songs
          .where((s) => s.album == oldAlbumName && s.artist == oldArtistName)
          .toList();

      for (var song in songsInAlbum) {
        await updateSongMetadata(
          song,
          album: newTitle,
          artist: newArtist,
          year: year,
        );
      }
    } catch (e) {
      debugPrint("Error updating album metadata: $e");
      rethrow;
    }
  }

  Future<void> updateAlbumCover(
    String albumName,
    String artistName,
    String imagePath,
  ) async {
    try {
      final songsInAlbum = state.songs
          .where((s) => s.album == albumName && s.artist == artistName)
          .toList();
      final bytes = await File(imagePath).readAsBytes();

      for (var song in songsInAlbum) {
        if (!song.url.startsWith("http") &&
            !song.url.startsWith("content://")) {
          final currentTag = await AudioTags.read(song.url);
          final tag = Tag(
            title: currentTag?.title,
            trackArtist: currentTag?.trackArtist,
            album: currentTag?.album,
            pictures: [
              Picture(
                bytes: bytes,
                mimeType: MimeType.values.first,
                pictureType: PictureType.values.first,
              ),
            ],
          );
          await AudioTags.write(song.url, tag);
        }
      }

      // Force a full scan to refresh everything from the files we just modified
      await scanLibrary(force: true);
    } catch (e) {
      debugPrint("Error updating album cover: $e");
      rethrow;
    }
  }

  Future<void> updateArtistMetadata(String oldName, String newName) async {
    try {
      final songsByArtist = state.songs
          .where((s) => s.artist == oldName)
          .toList();

      for (var song in songsByArtist) {
        await updateSongMetadata(song, artist: newName);
      }
    } catch (e) {
      debugPrint("Error updating artist metadata: $e");
      rethrow;
    }
  }

  // --- Helpers ---

  List<Artist> _extractArtists(List<Song> songs) {
    final Map<String, List<Song>> artistSongsGroup = {};
    for (final song in songs) {
      artistSongsGroup.putIfAbsent(song.artist, () => []).add(song);
    }

    return artistSongsGroup.entries.map((entry) {
      final artistAlbums = entry.value
          .map((s) => s.album)
          .where((a) => a != null)
          .toSet()
          .length;

      // Attempt to preserve image path if possible or fallback
      final existingArtist = state.artists.firstWhere(
        (a) => a.artist == entry.key,
        orElse: () => Artist(
          id: entry.value.first.id,
          artist: entry.key,
          numberOfTracks: entry.value.length,
          numberOfAlbums: artistAlbums,
          imagePath: null,
        ),
      );

      return Artist(
        id: existingArtist.id,
        artist: entry.key,
        numberOfTracks: entry.value.length,
        numberOfAlbums: artistAlbums,
        imagePath: existingArtist.imagePath,
      );
    }).toList();
  }

  List<Album> _extractAlbums(List<Song> songs) {
    final Map<String, List<Song>> albumSongsGroup = {};
    for (final song in songs) {
      if (song.album != null) {
        final key = '${song.album}_${song.artist}';
        albumSongsGroup.putIfAbsent(key, () => []).add(song);
      }
    }

    return albumSongsGroup.entries.map((entry) {
      final firstSong = entry.value.first;
      return Album(
        id: firstSong.id,
        album: firstSong.album!,
        artist: firstSong.artist,
        numberOfSongs: entry.value.length,
      );
    }).toList();
  }

  List<String> _extractFolders(List<Song> songs) {
    final folders = <String>{};
    for (final song in songs) {
      final folder = File(song.url).parent.path;
      folders.add(folder);
    }
    return folders.toList();
  }

  Future<void> _scanForLyrics() async {
    final songs = state.songs;
    if (songs.isEmpty) return;

    debugPrint(
      "🚀 Starting background lyrics scan for ${songs.length} songs...",
    );

    int processed = 0;
    for (final song in songs) {
      if (!mounted) break;

      if (LyricsService.peekCache(song.id) == null) {
        await _fetchLyricsInBackground(song);
        processed++;

        if (processed % 50 == 0) {
          await Future.delayed(const Duration(seconds: 2));
        }
      }
    }
    debugPrint(
      "✅ Background lyrics scan complete. Processed $processed new songs.",
    );
  }

  Future<void> _fetchLyricsInBackground(Song song) async {
    try {
      final dbLyrics = await DatabaseService.getLyricsForSong(song.id);
      if (dbLyrics.isNotEmpty) return;

      final lrcLyrics = await LyricsService.getLyricsForSong(song);
      if (lrcLyrics.isNotEmpty) return;

      final tag = await AudioTags.read(song.url);
      final lyricsText = tag?.lyrics;
      if (lyricsText != null && lyricsText.isNotEmpty) {
        List<LyricLine> parsedLyrics = [];
        if (lyricsText.contains('[') && lyricsText.contains(']')) {
          parsedLyrics = LyricsService.parseLrc(lyricsText);
        }

        if (parsedLyrics.isEmpty) {
          parsedLyrics = lyricsText
              .split('\n')
              .map((line) => LyricLine(time: Duration.zero, text: line.trim()))
              .where((l) => l.text.isNotEmpty)
              .toList();
        }

        if (parsedLyrics.isNotEmpty) {
          await DatabaseService.saveLyrics(song.id, parsedLyrics);
        }
      }
    } catch (e) {
      // Ignore background errors
    }
  }
}

final libraryProvider = StateNotifierProvider<LibraryNotifier, LibraryState>((
  ref,
) {
  return LibraryNotifier(ref);
});
