import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:awtart_music_player/providers/player_provider.dart';
import 'package:awtart_music_player/providers/navigation_provider.dart';
import 'package:awtart_music_player/theme/app_theme.dart';
import 'package:awtart_music_player/widgets/app_widgets.dart';
import 'package:awtart_music_player/widgets/music_visualizer.dart';
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
      lowerBound: 0.0,
      upperBound: 2.0,
    );

    // Sync current visual state
    final initialScreen = ref.read(screenProvider);
    _controller.value = initialScreen == AppScreen.home ? 0.0 : 1.0;

    _controller.addListener(() {
      final val = _controller.value;
      if (val >= 1.0) {
        final progress = val - 1.0;
        if (ref.read(scrollProgressProvider) != progress) {
          ref.read(scrollProgressProvider.notifier).state = progress;
        }
      } else if (ref.read(scrollProgressProvider) != 0.0) {
        ref.read(scrollProgressProvider.notifier).state = 0.0;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    double delta = details.delta.dy / MediaQuery.of(context).size.height;
    _controller.value = (_controller.value - delta).clamp(0.0, 2.0);
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    final double velocity = details.primaryVelocity ?? 0;
    final double value = _controller.value;
    final currentScreen = ref.read(screenProvider);

    double target;

    // Standardized Sensitivity: Any fling > 50 triggers instant transition
    double flingThreshold = 50.0;

    // 1. Fling Logic
    if (velocity.abs() > flingThreshold) {
      if (velocity < 0) {
        // Swipe UP
        if (value < 1.0)
          target = 1.0;
        else
          target = 2.0;
      } else {
        // Swipe DOWN
        if (value > 1.0)
          target = 1.0;
        else
          target = 0.0;
      }
    } else {
      // 2. Slow Drag / Insufficient Fling Logic

      if (currentScreen == AppScreen.home) {
        // Origin: 0.0. Trigger > 0.2 (20%)
        target = value > 0.2 ? 1.0 : 0.0;
      } else if (currentScreen == AppScreen.lyrics) {
        // Origin: 2.0.
        // Logic: "Long drag but not too long" -> Require 25% movement (value < 1.75)
        target = value < 1.75 ? 1.0 : 2.0;
      } else {
        // Origin: 1.0 (Player). Keep 20% sensitive rule.
        if (value < 0.8) {
          target = 0.0;
        } else if (value > 1.2) {
          target = 2.0;
        } else {
          target = 1.0;
        }
      }
    }

    // Ultra-fast animation for flings
    final int durationMs = velocity.abs() > 50 ? 200 : 350;

    _controller
        .animateTo(
          target,
          duration: Duration(milliseconds: durationMs),
          curve: Curves.easeOutCubic,
        )
        .then((_) {
          // Sync the provider state after animation completes
          final newState = target == 0.0
              ? AppScreen.home
              : (target == 1.0 ? AppScreen.player : AppScreen.lyrics);
          if (ref.read(screenProvider) != newState) {
            ref.read(screenProvider.notifier).state = newState;
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    final song = ref.watch(sampleSongProvider);
    final screenHeight = MediaQuery.of(context).size.height;

    // Fixed: ref.listen must be in build, not in a builder callback
    ref.listen(screenProvider, (prev, next) {
      const fastDuration = Duration(milliseconds: 350);
      const fastCurve = Curves.easeOutCubic;

      if (next == AppScreen.home && _controller.value > 0.5) {
        _controller.animateTo(0.0, duration: fastDuration, curve: fastCurve);
      } else if (next == AppScreen.player) {
        if (_controller.value < 0.5 || _controller.value > 1.5) {
          _controller.animateTo(1.0, duration: fastDuration, curve: fastCurve);
        }
      } else if (next == AppScreen.lyrics && _controller.value < 1.5) {
        _controller.animateTo(2.0, duration: fastDuration, curve: fastCurve);
      }
    });

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        final val = _controller.value;

        // 1. DIMENSIONS LOGIC
        double currentHeight;
        double currentTop;
        double currentRadius;
        double currentMargin;
        Color currentColor = AppColors.surfaceWhite;
        if (val <= 1.0) {
          currentHeight = Tween<double>(
            begin: 70,
            end: screenHeight * 0.85,
          ).transform(val);
          currentTop = Tween<double>(
            begin: screenHeight - 96,
            end: 0,
          ).transform(val);
          currentRadius = Tween<double>(
            begin: 35,
            end: AppRadius.large,
          ).transform(val);
          currentMargin = Tween<double>(begin: 16, end: 0).transform(val);
          currentColor = Color.lerp(
            const Color(0xFFE0E4E7),
            AppColors.surfaceWhite,
            val.clamp(0.0, 1.0),
          )!;
        } else {
          double t = val - 1.0;
          currentHeight = Tween<double>(
            begin: screenHeight * 0.85,
            end: screenHeight * 0.18,
          ).transform(t);
          currentTop = 0;
          currentRadius = AppRadius.large;
          currentMargin = 0;
        }

        return Material(
          type: MaterialType.transparency,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (val > 0.1)
                Positioned.fill(
                  key: const ValueKey('bg'),
                  child: Opacity(
                    opacity: ((val - 0.1) * 1.25).clamp(0.0, 1.0),
                    child: Container(color: AppColors.mainDark),
                  ),
                ),
              if (val > 0.5)
                Positioned(
                  key: const ValueKey('bottomBar'),
                  top: (currentTop + currentHeight).clamp(0.0, screenHeight),
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Opacity(
                    opacity: (val <= 1.0 ? (val - 0.5) * 2 : (2.0 - val) * 2)
                        .clamp(0.0, 1.0),
                    child: IgnorePointer(
                      ignoring: val > 1.2,
                      child: PlayerBottomBar(
                        onVerticalDragUpdate: _onVerticalDragUpdate,
                        onVerticalDragEnd: _onVerticalDragEnd,
                      ),
                    ),
                  ),
                ),
              if (val > 1.0)
                const Positioned.fill(
                  key: ValueKey('lyrics'),
                  child:
                      LyricsScreenContent(), // Removed RepaintBoundary here as it's added inside the widget or can be added back if needed, but keeping text match simpler
                ),
              Positioned(
                key: const ValueKey('card'),
                top: currentTop,
                left: currentMargin,
                right: currentMargin,
                height: currentHeight,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    // If docked in Lyrics mode (white section at top), tap to go to Player
                    if (_controller.value > 1.5) {
                      ref.read(screenProvider.notifier).state =
                          AppScreen.player;
                    }
                  },
                  onVerticalDragUpdate: _onVerticalDragUpdate,
                  onVerticalDragEnd: _onVerticalDragEnd,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: val > 1.0
                          ? const BorderRadius.only(
                              bottomLeft: Radius.circular(AppRadius.large),
                              bottomRight: Radius.circular(AppRadius.large),
                            )
                          : BorderRadius.circular(currentRadius),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: val > 1.0
                          ? const BorderRadius.only(
                              bottomLeft: Radius.circular(AppRadius.large),
                              bottomRight: Radius.circular(AppRadius.large),
                            )
                          : BorderRadius.circular(currentRadius),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          color: currentColor.withOpacity(0.85),
                          child: SafeArea(
                            bottom: false,
                            top: false, // Manual safe area to prevent jolt
                            child: Padding(
                              padding: EdgeInsets.only(
                                top: Tween<double>(
                                  begin: 0,
                                  end: MediaQuery.of(context).padding.top,
                                ).transform(val.clamp(0.0, 1.0)),
                                left: Tween<double>(
                                  begin: 12,
                                  end: 24,
                                ).transform(val.clamp(0.0, 1.0)),
                                right: Tween<double>(
                                  begin: 12,
                                  end: 24,
                                ).transform(val.clamp(0.0, 1.0)),
                              ),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  if (val < 0.5)
                                    Positioned.fill(
                                      child: Opacity(
                                        opacity: (1 - val * 2).clamp(0.0, 1.0),
                                        child: _buildMiniPlayerUI(song),
                                      ),
                                    ),
                                  if (val > 0.2 && val < 1.8)
                                    Positioned.fill(
                                      child: Opacity(
                                        opacity: val <= 1.0
                                            ? (val * 2 - 0.4).clamp(0.0, 1.0)
                                            : (2 - val * 2 + 1).clamp(0.0, 1.0),
                                        child: const RepaintBoundary(
                                          child: PlayerScreenContent(),
                                        ),
                                      ),
                                    ),
                                  if (val > 1.2)
                                    Positioned.fill(
                                      child: Opacity(
                                        opacity: ((val - 1.5) * 2).clamp(
                                          0.0,
                                          1.0,
                                        ),
                                        child: const RepaintBoundary(
                                          child: LyricsHeaderContent(),
                                        ),
                                      ),
                                    ),
                                  _buildMorphingAlbumArt(
                                    context,
                                    val,
                                    song.albumArt,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (val > 1.5)
                Positioned(
                  key: const ValueKey('lyricsBar'),
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Opacity(
                    opacity: ((val - 1.7) * 3).clamp(0.0, 1.0),
                    child: const RepaintBoundary(
                      child: LyricsBottomBarContent(),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMiniPlayerUI(dynamic song) {
    final currentTab = ref.watch(homeTabProvider);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildNavIcon(
          HomeTab.home,
          Icons.home,
          Icons.home_outlined,
          currentTab == HomeTab.home,
        ),
        _buildNavIcon(
          HomeTab.folders,
          Icons.folder,
          Icons.folder_outlined,
          currentTab == HomeTab.folders,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () =>
                  ref.read(screenProvider.notifier).state = AppScreen.player,
              child: Container(
                height: 54,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D0D0D),
                  borderRadius: BorderRadius.circular(27),
                ),
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 5),
                        child: const SizedBox(width: 40, height: 40),
                      ),
                    ),
                    const Align(
                      alignment: Alignment.center,
                      child: MusicVisualizer(),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Consumer(
                          builder: (context, ref, child) {
                            final pos = ref.watch(
                              playerProvider.select((s) => s.position),
                            );
                            return Text(
                              _formatDuration(pos),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'monospace',
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        _buildNavIcon(
          HomeTab.artists,
          Icons.person,
          Icons.person_outline,
          currentTab == HomeTab.artists,
        ),
        _buildNavIcon(
          HomeTab.albums,
          Icons.library_music,
          Icons.library_music_outlined,
          currentTab == HomeTab.albums,
        ),
      ],
    );
  }

  Widget _buildNavIcon(
    HomeTab tab,
    IconData filled,
    IconData outlined,
    bool isActive,
  ) {
    return GestureDetector(
      onTap: () => ref.read(homeTabProvider.notifier).state = tab,
      child: SizedBox(
        width: 40,
        child: Icon(
          isActive ? filled : outlined,
          color: Colors.black,
          size: 26,
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    String minutes = d.inMinutes.toString();
    String seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  Widget _buildMorphingAlbumArt(BuildContext context, double val, String url) {
    final screenWidth = MediaQuery.of(context).size.width;
    double size;
    double top;
    double left;
    double radius;
    if (val <= 1.0) {
      size = Tween<double>(begin: 40, end: screenWidth - 48).transform(val);
      top = Tween<double>(begin: 15, end: 75).transform(val);
      left = Tween<double>(begin: 93, end: 0).transform(val);
      radius = Tween<double>(begin: 20, end: AppRadius.large).transform(val);
    } else {
      double t = val - 1.0;
      size = Tween<double>(begin: screenWidth - 48, end: 50).transform(t);
      top = Tween<double>(begin: 75, end: 32).transform(t);
      left = 0;
      radius = Tween<double>(
        begin: AppRadius.large,
        end: AppRadius.small,
      ).transform(t);
    }
    return Positioned(
      top: top,
      left: left,
      width: size,
      height: size,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            boxShadow: [
              if (val > 0.2 && val < 1.8)
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 5,
                  offset: const Offset(0, 10),
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Image.network(url, fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }
}

class PlayerBottomBar extends ConsumerWidget {
  final void Function(DragUpdateDetails)? onVerticalDragUpdate;
  final void Function(DragEndDetails)? onVerticalDragEnd;

  const PlayerBottomBar({
    super.key,
    this.onVerticalDragUpdate,
    this.onVerticalDragEnd,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => ref.read(screenProvider.notifier).state = AppScreen.lyrics,
      onVerticalDragUpdate: onVerticalDragUpdate,
      onVerticalDragEnd: onVerticalDragEnd,
      child: Container(
        decoration: const BoxDecoration(color: Colors.transparent),
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
                  Text(
                    "Lyrics by",
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  Text(
                    "GENIUS",
                    style: AppTextStyles.titleMedium.copyWith(
                      letterSpacing: 2,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 60,
              child: Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.queue_music,
                    color: Colors.white70,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
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
            AppColors.mainDark.withOpacity(0.0),
            AppColors.mainDark.withOpacity(0.8),
            AppColors.mainDark,
            AppColors.mainDark,
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
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.queue_music,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
