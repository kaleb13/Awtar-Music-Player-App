import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// PaletteGenerator removed
import 'package:awtar_music_player/services/palette_service.dart';
import 'package:awtar_music_player/providers/player_provider.dart';
import 'package:awtar_music_player/providers/library_provider.dart';
import 'package:awtar_music_player/providers/navigation_provider.dart';
import 'package:awtar_music_player/theme/app_theme.dart';
import 'package:awtar_music_player/widgets/app_artwork.dart';
import 'package:awtar_music_player/widgets/app_widgets.dart';
import 'package:awtar_music_player/widgets/playlist_dialogs.dart';
import 'package:awtar_music_player/models/song.dart';
import 'player_screen.dart';
import '../providers/sleep_timer_provider.dart';
import '../widgets/sleep_timer_dialog.dart';

import 'package:awtar_music_player/providers/performance_provider.dart';
import 'dart:async';

class MainMusicPlayer extends ConsumerStatefulWidget {
  const MainMusicPlayer({super.key});

  @override
  ConsumerState<MainMusicPlayer> createState() => _MainMusicPlayerState();
}

class _MainMusicPlayerState extends ConsumerState<MainMusicPlayer>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _breathingController;
  Color? _dominantColor;

  // Subscriptions to keep them out of build
  ProviderSubscription? _playingSub;
  ProviderSubscription? _songSub;
  ProviderSubscription? _screenSub;
  ProviderSubscription? _navSub;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      lowerBound: 0.0,
      upperBound: 2.0,
    );

    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    // Sync current visual state
    final initialScreen = ref.read(screenProvider);
    _controller.value = initialScreen == AppScreen.home ? 0.0 : 1.0;

    // Initial breathing state
    final performanceMode = ref.read(performanceModeProvider);
    if (ref.read(playerProvider).isPlaying &&
        performanceMode != PerformanceMode.ultraLow) {
      _breathingController.repeat(reverse: true);
    }

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

    _updatePalette();
    _setupListeners();
  }

  void _setupListeners() {
    // Register listeners once
    _playingSub = ref.listenManual<bool>(
      playerProvider.select((s) => s.isPlaying),
      (prev, isPlaying) {
        final performanceMode = ref.read(performanceModeProvider);
        if (isPlaying && performanceMode != PerformanceMode.ultraLow) {
          _breathingController.repeat(reverse: true);
        } else {
          _breathingController.stop();
        }
      },
    );

    ref.listenManual(performanceModeProvider, (prev, mode) {
      if (mode == PerformanceMode.ultraLow) {
        _breathingController.stop();
      } else if (ref.read(playerProvider).isPlaying) {
        _breathingController.repeat(reverse: true);
      }
    });

    _songSub = ref.listenManual(
      playerProvider.select((s) => s.currentSong?.id),
      (prev, next) {
        if (next != null) {
          _updatePalette();
        }
      },
    );

    _screenSub = ref.listenManual(screenProvider, (prev, next) {
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

    _navSub = ref.listenManual<bool>(bottomNavVisibleProvider, (prev, next) {
      if (prev == true && next == false) {
        if (_controller.value > 0.0 && _controller.value < 1.0) {
          _controller.animateTo(
            0.0,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
          );
        }
      }
    });
  }

  Future<void> _updatePalette() async {
    // ... existing _updatePalette content (will be preserved by replace_file_content if I'm careful or I just include it)
    final playerState = ref.read(playerProvider);
    final library = ref.read(libraryProvider);

    // Use current song or first from library as fallback
    final Song? song =
        playerState.currentSong ??
        (library.songs.isNotEmpty ? library.songs.first : null);

    if (song == null) return;

    // Use a default path if albumArt is null
    final String artPath = song.albumArt ?? "";
    if (artPath.isEmpty) {
      if (mounted) setState(() => _dominantColor = AppColors.accentYellow);
      return;
    }

    try {
      final color = await PaletteService.getColor(
        artPath,
        songId: song.id,
        songPath: song.url,
      );
      if (mounted) {
        setState(() {
          _dominantColor = color;
        });
      }
    } catch (e) {
      debugPrint("Error updating palette: $e");
    }
  }

  @override
  void dispose() {
    _playingSub?.close();
    _songSub?.close();
    _screenSub?.close();
    _navSub?.close();
    _controller.dispose();
    _breathingController.dispose();
    super.dispose();
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    // ... existing drag logic
    double delta = details.delta.dy / MediaQuery.of(context).size.height;
    _controller.value = (_controller.value - delta).clamp(0.0, 2.0);
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    // ... existing drag logic
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
    final currentSong = ref.watch(playerProvider.select((s) => s.currentSong));
    final Song? song = currentSong;

    final screenHeight = MediaQuery.of(context).size.height;
    final currentMainTab = ref.watch(mainTabProvider);

    // Performance optimization: Adaptive blur
    final performanceMode = ref.watch(performanceModeProvider);

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        final val = _controller.value;
        final hasSong = song != null;

        // 1. DIMENSIONS LOGIC
        final isNavVisible = ref.watch(bottomNavVisibleProvider);
        final double miniPlayerBaseTopTarget = isNavVisible
            ? screenHeight - 150
            : screenHeight - 75;

        return TweenAnimationBuilder<double>(
          tween: Tween<double>(
            begin: miniPlayerBaseTopTarget,
            end: miniPlayerBaseTopTarget,
          ),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          builder: (context, miniPlayerBaseTop, _) {
            double currentHeight;
            double currentTop;
            double currentRadius;
            double currentMargin;
            Color currentColor = AppColors.surfaceWhite;

            if (val <= 1.0) {
              currentHeight = Tween<double>(
                begin: 60,
                end: screenHeight * 0.85,
              ).transform(val);
              currentTop = Tween<double>(
                begin: miniPlayerBaseTop,
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

              // Update status bar based on player state
              if (val > 0.3) {
                SystemChrome.setSystemUIOverlayStyle(
                  const SystemUiOverlayStyle(
                    statusBarColor: Colors.transparent,
                    statusBarIconBrightness: Brightness.dark,
                    statusBarBrightness: Brightness.light,
                  ),
                );
              } else {
                SystemChrome.setSystemUIOverlayStyle(
                  const SystemUiOverlayStyle(
                    statusBarColor: Colors.transparent,
                    statusBarIconBrightness: Brightness.light,
                    statusBarBrightness: Brightness.dark,
                  ),
                );
              }
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
                children: [
                  if (val > 0.1 && hasSong)
                    Positioned.fill(
                      key: const ValueKey('bg'),
                      child: Opacity(
                        opacity: ((val - 0.1) * 1.25).clamp(0.0, 1.0),
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: AppColors.mainGradient,
                          ),
                        ),
                      ),
                    ),
                  if (val > 1.0 && hasSong)
                    Positioned(
                      key: const ValueKey('lyrics'),
                      top: ((2.0 - val) * screenHeight).clamp(
                        0.0,
                        screenHeight,
                      ),
                      left: 0,
                      right: 0,
                      height: screenHeight,
                      child: LyricsScreenContent(
                        onDragUpdate: (delta) {
                          double screenHeight = MediaQuery.of(
                            context,
                          ).size.height;
                          double relativeDelta = delta / screenHeight;
                          _controller.value =
                              (_controller.value - relativeDelta).clamp(
                                1.0,
                                2.0,
                              );
                        },
                        onDragEnd: (velocity) {
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
                  // Bottom Navigation Bar - Always show if visible
                  if (val < 0.2 && ref.watch(bottomNavVisibleProvider))
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 160,
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
                                Colors.transparent,
                                AppColors.background,
                                AppColors.background,
                              ],
                              stops: const [0.0, 0.4, 1.0],
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildBottomNavItem(
                                  ref,
                                  MainTab.home,
                                  "Home",
                                  currentMainTab == MainTab.home,
                                  svgPath: AppAssets.home,
                                ),
                              ),
                              Expanded(
                                child: _buildBottomNavItem(
                                  ref,
                                  MainTab.discover,
                                  "Discovery",
                                  currentMainTab == MainTab.discover,
                                  svgPath: AppAssets.search,
                                ),
                              ),
                              Expanded(
                                child: _buildBottomNavItem(
                                  ref,
                                  MainTab.collection,
                                  "Collection",
                                  currentMainTab == MainTab.collection,
                                  svgPath: AppAssets.collection,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (hasSong)
                    Positioned(
                      key: const ValueKey('card'),
                      top: currentTop,
                      left: currentMargin,
                      right: currentMargin,
                      height: currentHeight,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onVerticalDragUpdate: _onVerticalDragUpdate,
                        onVerticalDragEnd: _onVerticalDragEnd,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: val > 1.0
                                ? const BorderRadius.only(
                                    bottomLeft: Radius.circular(
                                      AppRadius.large,
                                    ),
                                    bottomRight: Radius.circular(
                                      AppRadius.large,
                                    ),
                                  )
                                : BorderRadius.vertical(
                                    top: Radius.circular(
                                      Tween<double>(
                                        begin: 30,
                                        end: 0,
                                      ).transform(val),
                                    ),
                                    bottom: Radius.circular(currentRadius),
                                  ),
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
                                    bottomLeft: Radius.circular(
                                      AppRadius.large,
                                    ),
                                    bottomRight: Radius.circular(
                                      AppRadius.large,
                                    ),
                                  )
                                : BorderRadius.vertical(
                                    top: Radius.circular(
                                      Tween<double>(
                                        begin: 30,
                                        end: 0,
                                      ).transform(val),
                                    ),
                                    bottom: Radius.circular(currentRadius),
                                  ),
                            child:
                                (performanceMode == PerformanceMode.ultraLow &&
                                    val < 0.1)
                                ? Container(
                                    color: val < 0.1
                                        ? Colors.black.withOpacity(0.3)
                                        : currentColor.withOpacity(0.95),
                                    child: _buildMainContent(
                                      context,
                                      val,
                                      song,
                                      performanceMode,
                                      ref,
                                    ),
                                  )
                                : BackdropFilter(
                                    filter: ImageFilter.blur(
                                      sigmaX:
                                          performanceMode ==
                                              PerformanceMode.ultraLow
                                          ? 0
                                          : (val < 0.5 ? 10 : 20),
                                      sigmaY:
                                          performanceMode ==
                                              PerformanceMode.ultraLow
                                          ? 0
                                          : (val < 0.5 ? 10 : 20),
                                    ),
                                    child: Container(
                                      color: val < 0.1
                                          ? Colors.black.withOpacity(0.3)
                                          : currentColor.withOpacity(0.95),
                                      child: _buildMainContent(
                                        context,
                                        val,
                                        song,
                                        performanceMode,
                                        ref,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  if (val > 1.5 && hasSong)
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
                  if (val > 0.5 && hasSong)
                    Positioned(
                      top: (currentTop + currentHeight).clamp(
                        0.0,
                        screenHeight,
                      ),
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Opacity(
                        opacity:
                            (val <= 1.0 ? (val - 0.5) * 2 : (2.0 - val) * 2)
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
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMainContent(
    BuildContext context,
    double val,
    Song song,
    PerformanceMode performanceMode,
    WidgetRef ref,
  ) {
    return SafeArea(
      bottom: false,
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          top: Tween<double>(
            begin: 0,
            end: MediaQuery.of(context).padding.top,
          ).transform(val.clamp(0.0, 1.0)),
          left: Tween<double>(begin: 0, end: 24).transform(val.clamp(0.0, 1.0)),
          right: Tween<double>(
            begin: 0,
            end: 24,
          ).transform(val.clamp(0.0, 1.0)),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            _buildMorphingAlbumArt(
              context,
              val,
              song.albumArt ?? "https://placeholder.com",
              performanceMode: performanceMode,
              songId: song.id,
              songPath: song.url,
            ),
            if (val < 0.5)
              Positioned.fill(
                child: Opacity(
                  opacity: (1 - val * 2).clamp(0.0, 1.0),
                  child: _buildMiniPlayerUI(song, ref),
                ),
              ),
            if (val > 0.2 && val < 1.3)
              Positioned.fill(
                child: Opacity(
                  opacity: val <= 1.0
                      ? (val * 2 - 0.4).clamp(0.0, 1.0)
                      : (1.0 - (val - 1.0) * 3).clamp(0.0, 1.0),
                  child: const RepaintBoundary(child: PlayerScreenContent()),
                ),
              ),
            if (val > 1.2)
              Positioned.fill(
                child: Opacity(
                  opacity: ((val - 1.5) * 2).clamp(0.0, 1.0),
                  child: const RepaintBoundary(child: LyricsHeaderContent()),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniPlayerUI(Song song, WidgetRef ref) {
    final isPlaying = ref.watch(playerProvider.select((s) => s.isPlaying));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              ref.read(playerProvider.notifier).togglePlayPause(song);
            },
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 50,
              height: 50,
              alignment: const Alignment(0.0, 0.0),
              child: isPlaying
                  ? SvgPicture.asset(
                      AppAssets.pause,
                      width: 24,
                      height: 24,
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                    )
                  : SvgPicture.asset(
                      AppAssets.play,
                      width: 24,
                      height: 24,
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                    ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                ref.read(screenProvider.notifier).state = AppScreen.player;
              },
              behavior: HitTestBehavior.opaque,
              child: Container(
                color: Colors.transparent,
                height: 50,
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
                      "${song.artist}${song.year != null ? ' • ${song.year}' : ''}",
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

  Widget _buildMorphingAlbumArt(
    BuildContext context,
    double val,
    String url, {
    required PerformanceMode performanceMode,
    int? songId,
    String? songPath,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final borderColor = _dominantColor ?? AppColors.accentYellow;

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
      top = Tween<double>(begin: 0, end: 70).transform(val);
      left = Tween<double>(begin: 0, end: 0).transform(val);
      radius = Tween<double>(begin: 0, end: AppRadius.large).transform(val);
      double maxBlur = 20.0;
      if (performanceMode == PerformanceMode.low) maxBlur = 8.0;
      if (performanceMode == PerformanceMode.ultraLow) maxBlur = 0.0;
      blur = Tween<double>(begin: maxBlur, end: 0).transform(val);
    } else {
      double t = val - 1.0;
      width = Tween<double>(begin: screenWidth - 48, end: 50).transform(t);
      height = width;
      // fixed: Ensure top aligns correctly. When expanded (t=0, val=1), top should result in
      // the art being placed correctly.
      // Previous logic might have been slightly off.
      // Transition to top: 32 when fully morphed to lyrics (val=2.0, t=1.0)
      top = Tween<double>(begin: 70, end: 32).transform(t);
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
        child: AnimatedBuilder(
          animation: _breathingController,
          builder: (context, child) {
            final scale = val < 0.1
                ? (1.0 + _breathingController.value * 0.3)
                : 1.0;
            return Transform.scale(
              scale: scale,
              alignment: Alignment.center,
              child: child,
            );
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              border: val > 0.2
                  ? Border.all(color: borderColor.withOpacity(0.9), width: 2.5)
                  : null,
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
            padding: val > 0.2 ? const EdgeInsets.all(5) : EdgeInsets.zero,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                val > 0.1 ? (radius > 4 ? radius - 4 : 0) : radius,
              ),
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                child: songId != null
                    ? AppArtwork(
                        songId: songId,
                        songPath: songPath,
                        size:
                            screenWidth, // Stable size (max needed) to avoid re-decoding
                        fit: BoxFit.cover,
                      )
                    : Image.network(
                        url,
                        fit: BoxFit.cover,
                        width: width,
                        height: height,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: AppColors.mainDarkLight,
                          child: const Icon(
                            Icons.music_note,
                            color: Colors.white24,
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LyricsPreview extends ConsumerWidget {
  const _LyricsPreview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final song =
        playerState.currentSong ??
        (ref.read(libraryProvider).songs.isNotEmpty
            ? ref.read(libraryProvider).songs.first
            : null);
    final position =
        ref.watch(playerPositionStreamProvider).value ?? Duration.zero;

    String? currentLyricText;

    if (song != null && song.lyrics.isNotEmpty) {
      for (int i = 0; i < song.lyrics.length; i++) {
        final lyric = song.lyrics[i];
        final nextTime = (i + 1 < song.lyrics.length)
            ? song.lyrics[i + 1].time
            : const Duration(hours: 99);

        // Find the strictly current line
        if (position >= lyric.time && position < nextTime) {
          currentLyricText = lyric.text;
          break;
        }
      }
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 0.5),
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: currentLyricText != null && currentLyricText.isNotEmpty
          ? Container(
              key: ValueKey<String>(currentLyricText),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                currentLyricText,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.titleMedium.copyWith(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              key: const ValueKey('static_lyrics'),
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Lyrics by",
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "AWTAR",
                  style: AppTextStyles.titleMedium.copyWith(
                    letterSpacing: 1.5,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
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
    return SizedBox(
      // Outer height for the bar
      height: 100,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. DRAG LAYER (Background)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onVerticalDragUpdate: onVerticalDragUpdate,
              onVerticalDragEnd: onVerticalDragEnd,
            ),
          ),
          // 2. INTERACTION LAYER (Foreground)
          Positioned.fill(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // SECTION 1: Sleep Timer (Far Left)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => SleepTimerDialog.show(context),
                  child: Container(
                    padding: const EdgeInsets.only(left: 30, right: 10),
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: ref.watch(sleepTimerProvider).isActive
                            ? AppColors.primaryGreen
                            : AppColors.accentYellow,
                        shape: BoxShape.circle,
                        boxShadow: [
                          if (ref.watch(sleepTimerProvider).isActive)
                            BoxShadow(
                              color: AppColors.primaryGreen.withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                        ],
                      ),
                      child: Icon(
                        ref.watch(sleepTimerProvider).isActive
                            ? Icons.timer
                            : Icons.timer_outlined,
                        color: ref.watch(sleepTimerProvider).isActive
                            ? Colors.white
                            : Colors.black,
                        size: 24,
                      ),
                    ),
                  ),
                ),
                // SECTION 2: Lyrics (Center)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => ref.read(screenProvider.notifier).state =
                        AppScreen.lyrics,
                    child: Container(
                      alignment: Alignment.center,
                      child: const _LyricsPreview(),
                    ),
                  ),
                ),
                // SECTION 3: Playlist (Far Right)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    final song = ref.read(playerProvider).currentSong;
                    if (song != null) {
                      PlaylistDialogs.showAddSongToPlaylist(
                        context,
                        ref,
                        song,
                        useRootNavigator: true,
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.only(right: 30, left: 10),
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.playlist_add,
                        color: Colors.white70,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
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
    final library = ref.watch(libraryProvider);
    final Song? song =
        playerState.currentSong ??
        (library.songs.isNotEmpty ? library.songs.first : null);

    if (song == null) return const SizedBox.shrink();
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
            GestureDetector(
              onTap: () {
                // Fixed: The song is guaranteed non-null here due to the check at line 888
                PlaylistDialogs.showAddSongToPlaylist(
                  context,
                  ref,
                  song,
                  useRootNavigator: true,
                );
              },
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.playlist_add,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
