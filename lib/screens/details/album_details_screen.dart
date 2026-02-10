import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/library_provider.dart';
import '../../providers/player_provider.dart';
import '../../widgets/app_artwork.dart';
import '../../services/palette_service.dart';

class AlbumDetailsScreen extends ConsumerStatefulWidget {
  final String title;
  final String artist;
  final String imageUrl;

  const AlbumDetailsScreen({
    super.key,
    required this.title,
    required this.artist,
    required this.imageUrl,
  });

  @override
  ConsumerState<AlbumDetailsScreen> createState() => _AlbumDetailsScreenState();
}

class _AlbumDetailsScreenState extends ConsumerState<AlbumDetailsScreen> {
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
    final albumSongs = libraryState.songs
        .where((s) => s.album == widget.title)
        .toList();

    if (albumSongs.isNotEmpty) {
      final color = await PaletteService.generateAccentColor(
        albumSongs.first.albumArt ?? "",
        songId: albumSongs.first.id,
      );
      if (mounted) {
        setState(() => _dominantColor = color);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final libraryState = ref.watch(libraryProvider);
    final albumSongs = libraryState.songs
        .where((s) => s.album == widget.title)
        .toList();

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
          if (albumSongs.isNotEmpty)
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
                  songId: albumSongs.first.id,
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
                    widget.title,
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
                        widget.title,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.titleLarge.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "${albumSongs.length} tracks • ${widget.artist}",
                        style: AppTextStyles.bodyMain.copyWith(
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final song = albumSongs[index];
                  return Container(
                    color: backgroundColor,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 4,
                      ),
                      leading: Text(
                        "${index + 1}",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 14,
                        ),
                      ),
                      title: Text(
                        song.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        song.artist,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                      onTap: () => ref
                          .read(playerProvider.notifier)
                          .playPlaylist(albumSongs, index),
                    ),
                  );
                }, childCount: albumSongs.length),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
            ],
          ),

          Positioned(
            top: (expandedHeight - kToolbarHeight + 60 - _scrollOffset).clamp(
              kToolbarHeight - 28,
              double.infinity,
            ),
            right: 30,
            child: Opacity(
              opacity: (_scrollOffset > (expandedHeight + 20)) ? 0.0 : 1.0,
              child: FloatingActionButton(
                onPressed: () {
                  if (albumSongs.isNotEmpty) {
                    ref
                        .read(playerProvider.notifier)
                        .playPlaylist(albumSongs, 0);
                  }
                },
                backgroundColor: Color.lerp(backgroundColor, Colors.black, 0.4),
                shape: const CircleBorder(),
                child: SvgPicture.asset(
                  "assets/icons/play_icon.svg",
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                  width: 24,
                  height: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
