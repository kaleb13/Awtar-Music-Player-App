import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
        if (value < 1.0) {
          target = 1.0;
        } else {
          target = 2.0;
        }
      } else {
        // Swipe DOWN
        if (value > 1.0) {
          target = 1.0;
        } else {
          target = 0.0;
        }
      }
    } else {
      // 2. Slow Drag / Insufficient Fling Logic

      if (currentScreen == AppScreen.home) {
        // Origin: 0.0. Trigger > 0.2 (20%)
        target = value > 0.2 ? 1.0 : 0.0;
      } else if (currentScreen == AppScreen.lyrics) {
        // Origin: 2.0.
        // Logic: "Long drag but not too long" -> Require 20% movement (value < 1.8)
        target = value < 1.8 ? 1.0 : 2.0;
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
    final currentMainTab = ref.watch(mainTabProvider);

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
          // New Mini Player: Height ~60, Bottom Nav visible
          currentHeight = Tween<double>(
            begin: 60,
            end: screenHeight * 0.85,
          ).transform(val);
          currentTop = Tween<double>(
            begin: screenHeight - 160, // Above Nav Bar
            end: 0,
          ).transform(val);
          currentRadius = Tween<double>(
            begin: 30, // Pill Shape
            end: AppRadius.large,
          ).transform(val);
          currentMargin = Tween<double>(begin: 16, end: 0).transform(val);
          currentColor = Color.lerp(
            Colors.transparent, // Transparent for blurring bg
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
                Positioned(
                  key: const ValueKey('lyrics'),
                  top: ((2.0 - val) * screenHeight).clamp(0.0, screenHeight),
                  left: 0,
                  right: 0,
                  height: screenHeight,
                  child: LyricsScreenContent(
                    onDragUpdate: (delta) {
                      double screenHeight = MediaQuery.of(context).size.height;
                      double relativeDelta = delta / screenHeight;
                      // Dragging DOWN (positive delta) should DECREASE controller value (2.0 -> 1.0)
                      _controller.value = (_controller.value - relativeDelta)
                          .clamp(1.0, 2.0);
                    },
                    onDragEnd: (velocity) {
                      // Delegate to the main unified drag end handler
                      _onVerticalDragEnd(
                        DragEndDetails(
                          primaryVelocity: velocity,
                          velocity: Velocity(
                            pixelsPerSecond: Offset(0, velocity),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              // Bottom Navigation Bar (New)
              if (val < 0.2)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 140,
                  child: Opacity(
                    opacity: (1 - val * 5).clamp(0.0, 1.0),
                    child: Container(
                      alignment: Alignment.bottomCenter,
                      padding: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.background.withOpacity(0.0),
                            AppColors.background,
                          ],
                          stops: const [0.0, 0.6],
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildBottomNavItem(
                            ref,
                            MainTab.home,
                            "Home",
                            currentMainTab == MainTab.home,
                            svgPath: "assets/icons/home_icon.svg",
                          ),
                          _buildBottomNavItem(
                            ref,
                            MainTab.discover,
                            "Discovery",
                            currentMainTab == MainTab.discover,
                            svgPath: "assets/icons/search_icon.svg",
                          ),
                          _buildBottomNavItem(
                            ref,
                            MainTab.collection,
                            "Collection",
                            currentMainTab == MainTab.collection,
                            svgPath: "assets/icons/collection_icon.svg",
                          ),
                        ],
                      ),
                    ),
                  ),
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
                      // Remove shadow for mini player to look clean
                      boxShadow: val < 0.1
                          ? []
                          : [
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
                        filter: ImageFilter.blur(
                          sigmaX: val < 0.5 ? 10 : 20,
                          sigmaY: val < 0.5 ? 10 : 20,
                        ),
                        child: Container(
                          // Container Background Logic
                          // Mini: Transparent (shows blurred album art)
                          // Expanded: White (with slight opacity)
                          color: val < 0.1
                              ? Colors.black.withOpacity(0.3)
                              : currentColor.withOpacity(0.95),
                          child: SafeArea(
                            bottom: false,
                            top: false,
                            child: Padding(
                              padding: EdgeInsets.only(
                                top: Tween<double>(
                                  begin: 0,
                                  end: MediaQuery.of(context).padding.top,
                                ).transform(val.clamp(0.0, 1.0)),
                                left: Tween<double>(
                                  begin: 0, // Fill width at start
                                  end: 24,
                                ).transform(val.clamp(0.0, 1.0)),
                                right: Tween<double>(
                                  begin: 0, // Fill width at start
                                  end: 24,
                                ).transform(val.clamp(0.0, 1.0)),
                              ),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  // 1. Album Art (Background for mini, Foreground for Large)
                                  _buildMorphingAlbumArt(
                                    context,
                                    val,
                                    song.albumArt,
                                  ),
                                  // 2. Mini Player Content (Text on top of Art)
                                  if (val < 0.5)
                                    Positioned.fill(
                                      child: Opacity(
                                        opacity: (1 - val * 2).clamp(0.0, 1.0),
                                        child: _buildMiniPlayerUI(song, ref),
                                      ),
                                    ),
                                  // 3. Main Player Content (Text below/above Art)
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

  Widget _buildMiniPlayerUI(dynamic song, WidgetRef ref) {
    final isPlaying = ref.watch(playerProvider).isPlaying;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // Left: Play/Pause Button
          GestureDetector(
            onTap: () {
              ref.read(playerProvider.notifier).togglePlayPause(song);
            },
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 50, // Larger touch width
              height: 50, // Larger touch height
              alignment: const Alignment(-0.4, 0.0),
              child: isPlaying
                  ? SvgPicture.asset(
                      "assets/icons/pause_icon.svg",
                      width: 24, // Original requested size equivalent
                      height: 24,
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                    )
                  : SvgPicture.asset(
                      "assets/icons/play_icon.svg",
                      width: 24,
                      height: 24,
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                    ),
            ),
          ),
          // Center: Title and Artist
          Expanded(
            child: GestureDetector(
              onTap: () {
                ref.read(screenProvider.notifier).state = AppScreen.player;
              },
              behavior: HitTestBehavior.opaque,
              child: Container(
                color: Colors.transparent, // Ensure hits are captured
                height: 50, // Match height of side buttons
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      song.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      song.artist,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Right: Next Icon
          GestureDetector(
            onTap: () {
              ref.read(playerProvider.notifier).next();
            },
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 50,
              height: 50,
              alignment: const Alignment(0.4, 0.0),
              child: const Icon(Icons.skip_next, color: Colors.white, size: 30),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem(
    WidgetRef ref,
    MainTab tab,
    String label,
    bool isActive, {
    IconData? icon,
    String? svgPath,
  }) {
    return GestureDetector(
      onTap: () => ref.read(mainTabProvider.notifier).state = tab,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (svgPath != null)
            SvgPicture.asset(
              svgPath,
              colorFilter: ColorFilter.mode(
                isActive ? Colors.white : Colors.grey,
                BlendMode.srcIn,
              ),
              width: 26,
              height: 26,
            )
          else
            Icon(
              icon ?? Icons.error,
              color: isActive ? Colors.white : Colors.grey,
              size: 26,
            ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.grey,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMorphingAlbumArt(BuildContext context, double val, String url) {
    final screenWidth = MediaQuery.of(context).size.width;

    double top;
    double left;
    double width;
    double height;
    double radius;
    double blur;

    if (val <= 1.0) {
      width = Tween<double>(
        begin: screenWidth - 32,
        end: screenWidth - 48,
      ).transform(val);
      height = Tween<double>(begin: 60, end: screenWidth - 48).transform(val);
      top = Tween<double>(begin: 0, end: 75).transform(val);
      left = Tween<double>(begin: 0, end: 0).transform(val);
      radius = Tween<double>(begin: 0, end: AppRadius.large).transform(val);
      blur = Tween<double>(begin: 20, end: 0).transform(val);
    } else {
      double t = val - 1.0;
      width = Tween<double>(begin: screenWidth - 48, end: 50).transform(t);
      height = width;
      top = Tween<double>(begin: 75, end: 32).transform(t);
      left = 0;
      radius = Tween<double>(
        begin: AppRadius.large,
        end: AppRadius.small,
      ).transform(t);
      blur = 0;
    }

    return Positioned(
      top: top,
      left: left,
      width: width,
      height: height,
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
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: Image.network(
                url,
                fit: BoxFit.cover,
                width: width,
                height: height,
              ),
            ),
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
