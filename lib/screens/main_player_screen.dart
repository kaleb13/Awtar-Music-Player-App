import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:awtart_music_player/providers/player_provider.dart';
import 'package:awtart_music_player/providers/navigation_provider.dart';
import 'package:awtart_music_player/theme/app_theme.dart';
import 'package:awtart_music_player/widgets/app_widgets.dart';
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
    if (_controller.value <= 0.01 && details.delta.dy > 12) {
      ref.read(screenProvider.notifier).state = AppScreen.home;
      return;
    }
    double newValue =
        _controller.value -
        (details.delta.dy / MediaQuery.of(context).size.height);
    _controller.value = newValue.clamp(0.0, 1.0);
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;

    if (velocity < -500) {
      _controller.animateTo(1.0, curve: Curves.easeOutQuart);
      return;
    }

    if (velocity > 500) {
      _controller.animateTo(0.0, curve: Curves.easeOutQuart);
      if (_controller.value < 0.2) {
        ref.read(screenProvider.notifier).state = AppScreen.home;
      }
      return;
    }

    if (_controller.value > 0.3) {
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

    const expandedHeightFactor = 0.85;
    const collapsedHeightFactor = 0.18;

    final currentHeightFactor =
        expandedHeightFactor * (1 - progress) +
        collapsedHeightFactor * progress;
    final currentHeight = screenHeight * currentHeightFactor;

    return Scaffold(
      backgroundColor: Colors.transparent, // Allow underlying lyrics to show
      body: Stack(
        children: [
          // 1. LYRICS LAYER (Fixed in background)
          const Positioned.fill(child: LyricsScreenContent()),

          // 2. THE SLIDING WHITE LAYER (The Curtain)
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
                  color: AppColors.surfaceWhite,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(AppRadius.large),
                    bottomRight: Radius.circular(AppRadius.large),
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
              offset: Offset(0, 160 * progress),
              child: Opacity(
                opacity: (1 - progress * 3).clamp(0.0, 1.0),
                child: const PlayerBottomBar(),
              ),
            ),
          ),

          // 4. LYRICS BOTTOM PLAYER (Slides in)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Transform.translate(
              offset: Offset(0, 160 * (1 - progress)),
              child: Opacity(
                opacity: (progress * 3 - 2).clamp(0.0, 1.0),
                child: const LyricsBottomBarContent(),
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
    final homeSize = screenWidth - 48; // Padding 24 on each side
    final lyricsSize = 50.0;

    final currentSize = homeSize * (1 - progress) + lyricsSize * progress;

    // Interpolate Top Position
    // High Position: ~75px from top (Home View)
    // Low Position: ~32px from top (Center of Mini Header)
    final currentTop = (75.0 * (1 - progress)) + (32.0 * progress);

    // Interpolate Left Position to keep it centered in Home view
    final homeLeft = 0.0;
    final lyricsLeft =
        0.0; // In mini header, it's at the start of the row padding
    // Actually, in the Stack, let's keep it simple:

    return Positioned(
      top: currentTop,
      left:
          0, // It's horizontal 0 because it fills the horizontal space in Home view
      width: currentSize,
      height: currentSize,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              progress > 0.8 ? AppRadius.small : AppRadius.large,
            ),
            boxShadow: [
              if (progress < 0.5)
                BoxShadow(
                  color: Colors.black.withOpacity(0.08 * (1 - progress)),
                  blurRadius: 40,
                  spreadRadius: 10,
                  offset: const Offset(0, 20),
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              progress > 0.8 ? AppRadius.small : AppRadius.large,
            ),
            child: Image.network(
              url,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey.shade300,
                child: const Icon(Icons.music_note, size: 40),
              ),
            ),
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
      height: 160,
      color: Colors.transparent,
      padding: const EdgeInsets.only(left: 30, right: 30, bottom: 20),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: AppColors.accentYellow,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mic_none,
                  color: Colors.black,
                  size: 24,
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Lyrics by", style: AppTextStyles.caption),
                Text(
                  "GENIUS",
                  style: AppTextStyles.titleMedium.copyWith(
                    letterSpacing: 2,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            width: 60,
            child: Align(
              alignment: Alignment.centerRight,
              child: Icon(Icons.queue_music, color: Colors.white, size: 24),
            ),
          ),
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
      height: 160,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.background.withOpacity(0.0),
            AppColors.background.withOpacity(0.8),
            AppColors.background,
            AppColors.background,
          ],
          stops: const [0.0, 0.3, 0.6, 1.0],
        ),
      ),
      padding: const EdgeInsets.only(left: 30, right: 30, bottom: 30, top: 40),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            AppPlayButton(
              size: 56,
              color: Colors.white,
              iconColor: Colors.black,
              isPlaying: playerState.isPlaying,
              onTap: () {
                if (playerState.isPlaying) {
                  ref.read(playerProvider.notifier).pause();
                } else {
                  ref.read(playerProvider.notifier).play(song);
                }
              },
            ),
            const SizedBox(width: 15),
            Expanded(
              child: AppProgressBar(
                activeColor: Colors.white,
                value: playerState.position.inSeconds.toDouble(),
                max: playerState.duration.inSeconds.toDouble(),
                onChanged: (v) => ref
                    .read(playerProvider.notifier)
                    .seek(Duration(seconds: v.toInt())),
              ),
            ),
            const SizedBox(width: 15),
            const AppIconButton(
              icon: Icons.queue_music,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
