import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:awtart_music_player/providers/player_provider.dart';
import 'package:awtart_music_player/providers/navigation_provider.dart';
import 'player_screen.dart';

class MainMusicPlayer extends ConsumerStatefulWidget {
  const MainMusicPlayer({super.key});

  @override
  ConsumerState<MainMusicPlayer> createState() => _MainMusicPlayerState();
}

class _MainMusicPlayerState extends ConsumerState<MainMusicPlayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _controller.addListener(() {
      ref.read(scrollProgressProvider.notifier).state = _controller.value;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    // We want swipe up to increase _controller.value
    // details.delta.dy is negative when swiping up
    _controller.value -= details.delta.dy / MediaQuery.of(context).size.height;
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (_controller.value > 0.5 || details.primaryVelocity! < -500) {
      _controller.animateTo(1.0, curve: Curves.easeOutQuart);
    } else {
      _controller.animateTo(0.0, curve: Curves.easeOutQuart);
    }
  }

  @override
  Widget build(BuildContext context) {
    final song = ref.watch(sampleSongProvider);
    final progress = ref.watch(scrollProgressProvider);
    final screenHeight = MediaQuery.of(context).size.height;

    // Constants for the white layer
    const expandedHeightFactor = 0.85;
    const collapsedHeightFactor = 0.18;

    final currentHeightFactor =
        expandedHeightFactor * (1 - progress) +
        collapsedHeightFactor * progress;
    final currentHeight = screenHeight * currentHeightFactor;
    const sameRoundness = 40.0; // Decreased and unified as requested

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. LYRICS LAYER (FIXED IN BACKGROUND)
          // Always there, revealed as the curtain lifts
          const Positioned.fill(child: LyricsScreenContent()),

          // 2. THE SLIDING WHITE LAYER (THE CURTAIN)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: currentHeight,
            child: GestureDetector(
              onVerticalDragUpdate: _onVerticalDragUpdate,
              onVerticalDragEnd: _onVerticalDragEnd,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(sameRoundness),
                    bottomRight: Radius.circular(sameRoundness),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Stack(
                      children: [
                        // HOME CONTENT (Fading out)
                        Opacity(
                          opacity: (1 - progress * 2).clamp(0.0, 1.0),
                          child: const PlayerScreenContent(),
                        ),

                        // MINI DOCKED HEADER (Fading in)
                        Opacity(
                          opacity: (progress * 2 - 1).clamp(0.0, 1.0),
                          child: const LyricsHeaderContent(),
                        ),

                        // THE SMART SHRINKING ALBUM ART
                        _buildSmartAlbumArt(context, progress, song.albumArt),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 3. HOME BOTTOM BAR (Slides out)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Transform.translate(
              offset: Offset(0, 120 * progress),
              child: Opacity(
                opacity: (1 - progress * 3).clamp(0.0, 1.0),
                child: PlayerBottomBar(),
              ),
            ),
          ),

          // 4. LYRICS BOTTOM PLAYER (Slides in)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Transform.translate(
              offset: Offset(0, 120 * (1 - progress)),
              child: Opacity(
                opacity: (progress * 3 - 2).clamp(0.0, 1.0),
                child: LyricsBottomBarContent(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartAlbumArt(
    BuildContext context,
    double progress,
    String url,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final homeSize = screenWidth - 48;
    final lyricsSize = 50.0;

    final currentSize = homeSize * (1 - progress) + lyricsSize * progress;
    final currentTop = 60.0 * (1 - progress);

    return Positioned(
      top: currentTop,
      left: 0,
      width: currentSize,
      height: currentSize,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(progress > 0.8 ? 8 : 40),
            image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08 * (1 - progress)),
                blurRadius: 40,
                spreadRadius: 10,
                offset: const Offset(0, 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PlayerBottomBar extends ConsumerWidget {
  const PlayerBottomBar({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 120,
      color: const Color(0xFF191919),
      padding: const EdgeInsets.only(left: 30, right: 30, bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFFEEE544),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mic_none, color: Colors.black, size: 28),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Lyrics by",
                style: GoogleFonts.outfit(color: Colors.grey, fontSize: 10),
              ),
              Text(
                "GENIUS",
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const Icon(Icons.queue_music, color: Colors.white, size: 24),
        ],
      ),
    );
  }
}

class LyricsBottomBarContent extends ConsumerWidget {
  const LyricsBottomBarContent({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final song = ref.watch(sampleSongProvider);
    return Container(
      height: 120,
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                if (playerState.isPlaying) {
                  ref.read(playerProvider.notifier).pause();
                } else {
                  ref.read(playerProvider.notifier).play(song);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  playerState.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.black,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 2,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 4,
                  ),
                  activeTrackColor: Colors.white,
                  inactiveTrackColor: Colors.grey.withOpacity(0.3),
                  thumbColor: Colors.white,
                ),
                child: Slider(
                  value: playerState.position.inSeconds.toDouble(),
                  max: playerState.duration.inSeconds.toDouble().clamp(
                    0.001,
                    10000,
                  ),
                  onChanged: (v) {
                    ref
                        .read(playerProvider.notifier)
                        .seek(Duration(seconds: v.toInt()));
                  },
                ),
              ),
            ),
            const SizedBox(width: 15),
            const Icon(Icons.queue_music, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}
