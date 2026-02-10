import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../widgets/color_aware_album_card.dart';
import '../../providers/library_provider.dart';
import '../../providers/player_provider.dart';
import '../../providers/stats_provider.dart';
import '../../widgets/app_artwork.dart';
import '../../services/palette_service.dart';
import 'album_details_screen.dart';
import '../../models/song.dart';

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
  Color _dominantColor = AppColors.surfaceDark;
  late ScrollController _scrollController;
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()
      ..addListener(() {
        if (mounted) {
          setState(() {
            _scrollOffset = _scrollController.offset;
          });
        }
      });
    _updatePalette();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _updatePalette() async {
    final libraryState = ref.read(libraryProvider);
    final artistSongs = libraryState.songs
        .where((s) => s.artist == widget.name)
        .toList();

    if (artistSongs.isNotEmpty) {
      final color = await PaletteService.generateAccentColor(
        artistSongs.first.albumArt ?? "",
        songId: artistSongs.first.id,
      );
      if (mounted) {
        setState(() => _dominantColor = color);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final libraryState = ref.watch(libraryProvider);
    final stats = ref.watch(statsProvider);

    final artistSongs = libraryState.songs
        .where((s) => s.artist == widget.name)
        .toList();
    final artistAlbums = libraryState.albums
        .where((a) => a.artist == widget.name)
        .toList();

    // Top Tracks logic
    final topTracks =
        artistSongs.where((s) => (stats.songPlayCounts[s.id] ?? 0) > 0).toList()
          ..sort(
            (a, b) => (stats.songPlayCounts[b.id] ?? 0).compareTo(
              stats.songPlayCounts[a.id] ?? 0,
            ),
          );
    final limitedTopTracks = topTracks.take(5).toList();

    final backgroundColor = _dominantColor;
    final double expandedHeight = MediaQuery.of(context).size.width * 0.66;
    final double threshold = expandedHeight - kToolbarHeight;
    final double opacity = (threshold > 0)
        ? (_scrollOffset / threshold).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          if (artistSongs.isNotEmpty)
            Positioned(
              top: -_scrollOffset * 0.4,
              left: 0,
              right: 0,
              height: MediaQuery.of(context).size.width,
              child: ShaderMask(
                shaderCallback: (rect) {
                  return LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [backgroundColor.withOpacity(0.6), backgroundColor],
                    stops: const [0.0, 1.0],
                  ).createShader(rect);
                },
                blendMode: BlendMode.srcOver,
                child: AppArtwork(
                  songId: artistSongs.first.id,
                  size: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),

          CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverAppBar(
                backgroundColor: backgroundColor.withOpacity(opacity),
                title: Opacity(
                  opacity: opacity,
                  child: Text(
                    widget.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                pinned: true,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              SliverToBoxAdapter(
                child: SizedBox(height: expandedHeight - kToolbarHeight),
              ),

              SliverToBoxAdapter(
                child: Container(
                  color: backgroundColor,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      Text(
                        widget.name,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.titleLarge.copyWith(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "${artistAlbums.length} albums • ${artistSongs.length} tracks",
                        style: AppTextStyles.bodyMain.copyWith(
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 20),
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
                          backgroundColor: Color.lerp(
                            backgroundColor,
                            Colors.black,
                            0.4,
                          ),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 48,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text("SHUFFLE PLAY"),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              if (artistAlbums.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Container(
                    color: backgroundColor,
                    padding: const EdgeInsets.only(left: 16, bottom: 8),
                    child: const Text(
                      "ALBUMS",
                      style: TextStyle(
                        color: Colors.white54,
                        letterSpacing: 2,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    color: backgroundColor,
                    height: 180,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: artistAlbums.length,
                      itemBuilder: (context, index) {
                        final album = artistAlbums[index];
                        final albumSong = artistSongs.firstWhere(
                          (s) => s.album == album.album,
                          orElse: () => artistSongs.first,
                        );
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: ColorAwareAlbumCard(
                            title: album.album,
                            artist: album.artist,
                            songId: albumSong.id,
                            size: 110,
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
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],

              if (limitedTopTracks.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Container(
                    color: backgroundColor,
                    padding: const EdgeInsets.only(top: 24, bottom: 8),
                    child: const Center(
                      child: Text(
                        "TOP TRACKS",
                        style: TextStyle(
                          color: Colors.white54,
                          letterSpacing: 2,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final song = limitedTopTracks[index];
                    final playCount = stats.songPlayCounts[song.id] ?? 0;
                    return Container(
                      color: backgroundColor,
                      child: ListTile(
                        leading: Text(
                          "${index + 1}",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        title: Text(
                          song.title,
                          style: const TextStyle(color: Colors.white),
                        ),
                        trailing: Text(
                          "$playCount",
                          style: const TextStyle(color: Colors.white54),
                        ),
                        onTap: () => ref
                            .read(playerProvider.notifier)
                            .playPlaylist(limitedTopTracks, index),
                      ),
                    );
                  }, childCount: limitedTopTracks.length),
                ),
              ],

              SliverToBoxAdapter(
                child: Container(
                  color: backgroundColor,
                  padding: const EdgeInsets.only(top: 24, bottom: 8),
                  child: const Center(
                    child: Text(
                      "TRACKS",
                      style: TextStyle(
                        color: Colors.white54,
                        letterSpacing: 2,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final song = artistSongs[index];
                  return Container(
                    color: backgroundColor,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      leading: AppArtwork(
                        songId: song.id,
                        size: 40,
                        borderRadius: 4,
                      ),
                      title: Text(
                        song.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        song.album ?? "Single",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                      onTap: () => ref
                          .read(playerProvider.notifier)
                          .playPlaylist(artistSongs, index),
                    ),
                  );
                }, childCount: artistSongs.length),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 150)),
            ],
          ),
        ],
      ),
    );
  }
}
