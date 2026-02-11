import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/library_provider.dart';
import '../../providers/player_provider.dart';
import '../../widgets/app_artwork.dart';
import '../../services/palette_service.dart';
import '../../providers/performance_provider.dart';

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
  Color _dominantColor = AppColors.accentYellow;

  @override
  void initState() {
    super.initState();
    _updatePalette();
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
    final playerState = ref.watch(playerProvider);
    final currentSong = playerState.currentSong;

    final albumSongs = libraryState.songs
        .where((s) => s.album == widget.title)
        .toList();

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
              ),
            ),

          if (currentSong != null)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: ref.watch(lowPerformanceModeProvider) ? 20 : 80,
                  sigmaY: ref.watch(lowPerformanceModeProvider) ? 20 : 80,
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
                    AppColors.mainDarkLight.withOpacity(0.92),
                    AppColors.mainDark.withOpacity(0.92),
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

                // Album Header Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Album Art with Perforated Play Button
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(50),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(48),
                                child: albumSongs.isNotEmpty
                                    ? AppArtwork(
                                        songId: albumSongs.first.id,
                                        songPath: albumSongs.first.url,
                                        size: 180,
                                      )
                                    : Container(color: Colors.grey[900]),
                              ),
                            ),
                            // Perforated Play Button
                            Positioned(
                              bottom: -15,
                              right: -15,
                              child: Container(
                                padding: const EdgeInsets.all(
                                  4,
                                ), // Perforation Gap
                                decoration: BoxDecoration(
                                  color: AppColors.mainDark.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: Container(
                                  width: 54,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    color: _dominantColor,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: _dominantColor.withOpacity(0.4),
                                        blurRadius: 15,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        if (albumSongs.isNotEmpty) {
                                          ref
                                              .read(playerProvider.notifier)
                                              .playPlaylist(albumSongs, 0);
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(27),
                                      child: Center(
                                        child: SvgPicture.asset(
                                          "assets/icons/play_icon.svg",
                                          colorFilter: ColorFilter.mode(
                                            _dominantColor.computeLuminance() >
                                                    0.5
                                                ? Colors.black
                                                : Colors.white,
                                            BlendMode.srcIn,
                                          ),
                                          width: 22,
                                          height: 22,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 28),
                        // Album Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                widget.artist,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "${albumSongs.length} Tracks",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.4),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 10), // Alignment adjust
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 40)),

                // Tracks List
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final song = albumSongs[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.02),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 4,
                        ),
                        leading: Text(
                          (index + 1).toString().padLeft(2, '0'),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.2),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        title: Text(
                          song.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          "Track ${index + 1}", // Or duration if available
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 11,
                          ),
                        ),
                        trailing: Icon(
                          Icons.more_vert,
                          color: Colors.white.withOpacity(0.3),
                          size: 20,
                        ),
                        onTap: () => ref
                            .read(playerProvider.notifier)
                            .playPlaylist(albumSongs, index),
                      ),
                    );
                  }, childCount: albumSongs.length),
                ),
                const SliverPadding(padding: EdgeInsets.only(bottom: 150)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
