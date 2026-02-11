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
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../main.dart';
import 'player_provider.dart';

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
  final List<Playlist> playlists;
  final List<String> folders;
  final Map<String, List<String>> storageMap;
  final Set<String> excludedFolders; // Folders that are excluded from library
  final Set<String> hiddenArtists; // Artists hidden from list
  final Set<String> hiddenAlbums; // Albums hidden from list
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
    this.playlists = const [],
    this.folders = const [],
    this.storageMap = const {},
    this.excludedFolders = const {},
    this.hiddenArtists = const {},
    this.hiddenAlbums = const {},
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
    List<Playlist>? playlists,
    List<String>? folders,
    Map<String, List<String>>? storageMap,
    Set<String>? excludedFolders,
    Set<String>? hiddenArtists,
    Set<String>? hiddenAlbums,
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
      playlists: playlists ?? this.playlists,
      folders: folders ?? this.folders,
      storageMap: storageMap ?? this.storageMap,
      excludedFolders: excludedFolders ?? this.excludedFolders,
      hiddenArtists: hiddenArtists ?? this.hiddenArtists,
      hiddenAlbums: hiddenAlbums ?? this.hiddenAlbums,
      bannerSong: bannerSong ?? this.bannerSong,
      isLoading: isLoading ?? this.isLoading,
      permissionStatus: permissionStatus ?? this.permissionStatus,
      errorMessage: errorMessage,
      completionMessage: completionMessage,
      metadataLoadProgress: metadataLoadProgress ?? this.metadataLoadProgress,
      isReloadingMetadata: isReloadingMetadata ?? this.isReloadingMetadata,
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
  }

  Future<void> _loadFromCache() async {
    try {
      final prefs = _ref.read(sharedPreferencesProvider);
      final cacheData = prefs.getString('library_cache_v3'); // Updated version
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
        final playlists = (decoded['playlists'] as List? ?? [])
            .map((p) => Playlist.fromMap(p))
            .toList();
        final folders = List<String>.from(decoded['folders'] ?? []);
        final Set<String> excludedFolders = Set<String>.from(
          decoded['excludedFolders'] ?? [],
        );
        final Set<String> hiddenArtists = Set<String>.from(
          decoded['hiddenArtists'] ?? [],
        );
        final Set<String> hiddenAlbums = Set<String>.from(
          decoded['hiddenAlbums'] ?? [],
        );
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
          playlists: playlists,
          folders: folders,
          storageMap: storageMap,
          excludedFolders: excludedFolders,
          hiddenArtists: hiddenArtists,
          hiddenAlbums: hiddenAlbums,
        );

        if (songs.isNotEmpty) {
          _updateBannerSong(songs);
        }
      } else {
        // Migration from v2 if exists
        final oldData = prefs.getString('library_cache_v2');
        if (oldData != null) {
          // We could migrate, but simple scan is fine too.
          // For now just scan if v3 is not found.
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
        'playlists': state.playlists.map((p) => p.toMap()).toList(),
        'folders': state.folders,
        'storageMap': state.storageMap,
        'excludedFolders': state.excludedFolders.toList(),
        'hiddenArtists': state.hiddenArtists.toList(),
        'hiddenAlbums': state.hiddenAlbums.toList(),
      });
      await prefs.setString('library_cache_v3', cacheData);
    } catch (e) {
      debugPrint("Error saving library cache: $e");
    }
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

      // artists and albums will be rebuilt from filtered songs later

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

      // Preserve favorite status from existing library
      final favoritedIds = state.songs
          .where((s) => s.isFavorite)
          .map((s) => s.id)
          .toSet();

      final updatedSongs = songs.map((s) {
        if (favoritedIds.contains(s.id)) {
          return s.copyWith(isFavorite: true);
        }
        return s;
      }).toList();

      // IMPORTANT: Respect folder exclusions during scan
      final filteredSongs = _filterSongsByFolders(
        updatedSongs,
        state.excludedFolders,
      );

      // Rebuild artists and albums from the filtered song list
      // instead of using raw results which ignore folder exclusions.
      final artists = _rebuildArtists(filteredSongs);
      final albums = _rebuildAlbums(filteredSongs);

      state = state.copyWith(
        songs: filteredSongs,
        artists: artists,
        albums: albums,
        folders: folderSet.toList(),
        storageMap: storageMap,
        isLoading: false,
      );

      // Trigger banner update with filtered songs
      if (filteredSongs.isNotEmpty) {
        _updateBannerSong(filteredSongs);
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

    state = state.copyWith(
      artists: state.artists.map((a) {
        if (a.artist == artistName) {
          return a.copyWith(imagePath: finalPath);
        }
        return a;
      }).toList(),
    );
    _saveToCache();
  }

  // Folder Exclusion Management
  void toggleFolderExclusion(String folderPath) {
    final excludedFolders = Set<String>.from(state.excludedFolders);

    if (excludedFolders.contains(folderPath)) {
      // Include the folder (remove from excluded)
      excludedFolders.remove(folderPath);
    } else {
      // Exclude the folder (add to excluded)
      excludedFolders.add(folderPath);
    }

    // Filter songs, artists, and albums based on excluded folders
    final filteredSongs = _filterSongsByFolders(state.songs, excludedFolders);
    final filteredArtists = _rebuildArtists(filteredSongs);
    final filteredAlbums = _rebuildAlbums(filteredSongs);

    state = state.copyWith(
      excludedFolders: excludedFolders,
      songs: filteredSongs,
      artists: filteredArtists,
      albums: filteredAlbums,
    );

    _saveToCache();
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
        id: entry.value.first.id, // Use first song's ID as artist ID
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
        id: songs.first.id, // Use first song's ID as album ID
        album: songs.first.album!,
        artist: songs.first.artist,
        numberOfSongs: songs.length,
      );
    }).toList();
  }

  bool isFolderExcluded(String folderPath) {
    return state.excludedFolders.contains(folderPath);
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
