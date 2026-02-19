import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/library_provider.dart';
import '../../providers/player_provider.dart';
import '../../widgets/app_artwork.dart';
import 'album_details_screen.dart';
import '../../models/song.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../providers/stats_provider.dart';
import '../../providers/performance_provider.dart';
import '../../widgets/app_widgets.dart';
import '../../services/image_processing_service.dart';
import '../../services/media_menu_service.dart';

class ArtistDetailsScreen extends ConsumerStatefulWidget {
  final String name;
  final String imageUrl;

  const ArtistDetailsScreen({
    super.key,
    required this.name,
    required this.imageUrl,
  });

  @override
  ConsumerState<ArtistDetailsScreen> createState() =>
      _ArtistDetailsScreenState();
}

class _ArtistDetailsScreenState extends ConsumerState<ArtistDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final libraryState = ref.watch(libraryProvider);
    final playerState = ref.watch(playerProvider);
    final currentSong = playerState.currentSong;

    final artist = libraryState.artists.firstWhere(
      (a) => a.artist == widget.name,
      orElse: () => libraryState.artists.first,
    );

    final artistAlbums =
        libraryState.albums.where((a) => a.artist == widget.name).toList()
          ..sort((a, b) {
            if (a.firstYear != null && b.firstYear != null) {
              int cmp = a.firstYear!.compareTo(b.firstYear!);
              if (cmp != 0) return cmp;
            } else if (a.firstYear != null) {
              return -1;
            } else if (b.firstYear != null) {
              return 1;
            }
            return a.album.toLowerCase().compareTo(b.album.toLowerCase());
          });

    // Group songs by album in the same order as artistAlbums
    final List<Song> artistSongs = [];
    final Map<String, List<Song>> songsByAlbum = {};
    for (final s in libraryState.songs.where((s) => s.artist == widget.name)) {
      songsByAlbum.putIfAbsent(s.album ?? "Single", () => []).add(s);
    }

    for (final album in artistAlbums) {
      final songs = songsByAlbum[album.album] ?? [];
      songs.sort((a, b) {
        if (a.trackNumber != null && b.trackNumber != null) {
          int cmp = a.trackNumber!.compareTo(b.trackNumber!);
          if (cmp != 0) return cmp;
        } else if (a.trackNumber != null) {
          return -1;
        } else if (b.trackNumber != null) {
          return 1;
        }
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      });
      artistSongs.addAll(songs);
    }

    // Add any remaining songs not captured by the identifies albums
    final capturedIds = artistSongs.map((s) => s.id).toSet();
    final remaining =
        libraryState.songs
            .where(
              (s) => s.artist == widget.name && !capturedIds.contains(s.id),
            )
            .toList()
          ..sort(
            (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
          );
    artistSongs.addAll(remaining);

    final stats = ref.watch(statsProvider);

    // Filter top tracks (only those with at least 1 play)
    final topTracks =
        artistSongs.where((s) => (stats.songPlayCounts[s.id] ?? 0) > 0).toList()
          ..sort(
            (a, b) => (stats.songPlayCounts[b.id] ?? 0).compareTo(
              stats.songPlayCounts[a.id] ?? 0,
            ),
          );

    final displayTopTracks = topTracks.take(5).toList();

    final dominantColor =
        libraryState.artistColors[widget.name] ?? const Color(0xFF4A90E2);

    Future<void> pickArtistImage() async {
      final picker = ImagePicker();
      final options = ImageProcessingService.getPickOptions();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: options['maxWidth'],
        maxHeight: options['maxHeight'],
        imageQuality: options['imageQuality'],
      );
      if (image != null) {
        final processed = await ImageProcessingService.processImage(image.path);
        if (processed != null) {
          await ref
              .read(libraryProvider.notifier)
              .updateArtistImage(widget.name, processed.path);
        }
      }
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 1. Dynamic Blurred Background (Matching Home)
          if (currentSong != null)
            Positioned.fill(
              child: AppArtwork(
                songId: currentSong.id,
                songPath: currentSong.url,
                fit: BoxFit.cover,
                size: 300, // Optimization for blur
              ),
            ),

          if (currentSong != null &&
              ref.watch(performanceModeProvider) != PerformanceMode.ultraLow)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX:
                      ref.watch(performanceModeProvider) == PerformanceMode.low
                      ? 15
                      : 30,
                  sigmaY:
                      ref.watch(performanceModeProvider) == PerformanceMode.low
                      ? 15
                      : 30,
                ),
                child: Container(color: Colors.transparent),
              ),
            ),

          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.mainDarkLight.withValues(alpha: 0.9),
                    AppColors.mainDark.withValues(alpha: 0.9),
                  ],
                ),
              ),
            ),
          ),

          // 2. Content
          SafeArea(
            child: CustomScrollView(
              slivers: [
                // Custom App Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                ),

                // Artist Header
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      // Large Squircle Image
                      GestureDetector(
                        onTap:
                            pickArtistImage, // Single tap to change if desired, or keep long-press
                        onLongPress: () {
                          showModalBottomSheet(
                            context: context,
                            useRootNavigator: true,
                            backgroundColor: AppColors.mainDark,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                            ),
                            builder: (context) => SafeArea(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(height: 10),
                                  Container(
                                    width: 40,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.all(20),
                                    child: Text(
                                      "Update Artist Image",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  ListTile(
                                    leading: const Icon(
                                      Icons.image,
                                      color: Colors.white,
                                    ),
                                    title: const Text(
                                      "Select from Gallery",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    onTap: () {
                                      Navigator.pop(context);
                                      pickArtistImage();
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                ],
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.7,
                          height: MediaQuery.of(context).size.width * 0.7,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(80),
                            border: Border.all(
                              color: dominantColor.withValues(alpha: 0.8),
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: dominantColor.withValues(alpha: 0.2),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(77),
                            child: artist.imagePath != null
                                ? Image.file(
                                    File(artist.imagePath!),
                                    fit: BoxFit.cover,
                                  )
                                : (artistSongs.isNotEmpty
                                      ? AppArtwork(
                                          songId: artistSongs.first.id,
                                          songPath: artistSongs.first.url,
                                          size: 400,
                                        )
                                      : Container(
                                          color: Colors.grey[900],
                                          child: const Icon(
                                            Icons.person_add_alt_1,
                                            color: Colors.white24,
                                            size: 60,
                                          ),
                                        )),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        widget.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${artistSongs.length} Tracks ${artistAlbums.length} Albums",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Shuffle Button
                      ElevatedButton(
                        onPressed: () {
                          if (artistSongs.isNotEmpty) {
                            final shuffled = List<Song>.from(artistSongs)
                              ..shuffle();
                            ref
                                .read(playerProvider.notifier)
                                .playPlaylist(shuffled, 0);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: dominantColor,
                          foregroundColor:
                              dominantColor.computeLuminance() > 0.5
                              ? Colors.black
                              : Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          "SHUFFLE PLAY",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),

                // Albums Section
                if (artistAlbums.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 140,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        scrollDirection: Axis.horizontal,
                        itemCount: artistAlbums.length,
                        itemBuilder: (context, index) {
                          final album = artistAlbums[index];
                          final albumKey = '${album.album}_${album.artist}';
                          final albumSongId =
                              libraryState.representativeAlbumSongs[albumKey];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AlbumDetailsScreen(
                                    title: album.album,
                                    artist: album.artist,
                                    imageUrl: "",
                                  ),
                                ),
                              );
                            },
                            onLongPress: () {
                              AppCenteredModal.show(
                                context,
                                title: album.album,
                                items: MediaMenuService.buildAlbumActions(
                                  context: context,
                                  ref: ref,
                                  album: album,
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(right: 16),
                              child: Column(
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color:
                                            (libraryState
                                                        .albumColors[albumKey] ??
                                                    dominantColor)
                                                .withValues(alpha: 0.5),
                                        width: 2,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(22),
                                      child: AppArtwork(
                                        songId: albumSongId,
                                        size: 80,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: 80,
                                    child: Text(
                                      album.album,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    widget.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.4),
                                      fontSize: 8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],

                // Top Tracks Section
                if (displayTopTracks.isNotEmpty) ...[
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          "TOP TRACKS",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final song = displayTopTracks[index];
                      final playCount = stats.songPlayCounts[song.id] ?? 0;
                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.05),
                            width: 1,
                          ),
                        ),
                        child: ListTile(
                          leading: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                "#${index + 1}",
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            song.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          subtitle: Text(
                            "$playCount plays • ${song.album ?? 'Single'}",
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 10,
                            ),
                          ),
                          trailing: AppMenuButton(
                            menuBuilder: (context) =>
                                MediaMenuService.buildSongMenuItems(
                                  context: context,
                                  ref: ref,
                                  song: song,
                                ),
                          ),
                          onTap: () => ref
                              .read(playerProvider.notifier)
                              .playPlaylist(displayTopTracks, index),
                          onLongPress: () => AppCenteredModal.show(
                            context,
                            title: song.title,
                            items: MediaMenuService.buildSongActions(
                              context: context,
                              ref: ref,
                              song: song,
                            ),
                          ),
                        ),
                      );
                    }, childCount: displayTopTracks.length),
                  ),
                ],

                // Tracks Header
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        "TRACKS",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ),

                // Tracks List
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final song = artistSongs[index];
                    return AppSongTile(
                      song: song,
                      index: index,
                      playlist: artistSongs,
                      showArtwork: false, // Keep it clean in artist view
                    );
                  }, childCount: artistSongs.length),
                ),
                const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

