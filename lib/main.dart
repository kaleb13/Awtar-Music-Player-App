import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:awtar_music_player/providers/navigation_provider.dart';
import 'package:awtar_music_player/providers/library_provider.dart';
import 'package:awtar_music_player/providers/player_provider.dart';
import 'package:awtar_music_player/theme/app_theme.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'screens/main_sections.dart';
import 'screens/home_screen.dart';
import 'screens/main_player_screen.dart';
import 'screens/permission_onboarding_screen.dart';
import 'widgets/app_artwork.dart';
import 'widgets/app_drawer.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'providers/stats_provider.dart';
import 'providers/performance_provider.dart';
import 'services/database_service.dart';
import 'services/palette_service.dart';

// Keys moved to navigation_provider.dart

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Fire audio background init WITHOUT awaiting — it can finish later.
  //    This shaves ~300-800ms off cold start.
  final audioInitFuture =
      JustAudioBackground.init(
        androidNotificationChannelId:
            'com.example.awtart_music_player.channel.audio',
        androidNotificationChannelName: 'Music Playback',
        androidNotificationOngoing: true,
        androidNotificationIcon: 'drawable/ic_notification',
      ).catchError((e) {
        debugPrint("❌ Critical Error: JustAudioBackground.init failed: $e");
      });

  // 2. Pre-warm SharedPreferences, Database, and Palette cache IN PARALLEL.
  //    This means by the time LibraryProvider._init() runs, all three are
  //    already hot — no cold-open penalty.
  final prefs = await SharedPreferences.getInstance();
  await Future.wait([
    DatabaseService.warmUp(),
    PaletteService.loadFromDisk(prefs: prefs),
  ]);

  // 3. Ensure audio init completes before the player is used
  //    (the player screen won't render until the user taps a song,
  //    so this is effectively invisible).
  audioInitFuture.ignore();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        statsProvider.overrideWith((ref) => StatsNotifier(prefs)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(sharedPreferencesProvider);
    final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

    return MaterialApp(
      title: 'Awtar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.black,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        splashFactory: InkRipple.splashFactory,
        splashColor: Colors.white.withValues(alpha: 0.08),
        highlightColor: Colors.white.withValues(alpha: 0.04),
        tabBarTheme: TabBarThemeData(
          indicatorColor: AppColors.accentBlue,
          splashFactory: InkRipple.splashFactory,
          overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.pressed)) {
              return Colors.white.withValues(alpha: 0.05);
            }
            if (states.contains(WidgetState.hovered)) {
              return Colors.white.withValues(alpha: 0.03);
            }
            return null;
          }),
        ),
        popupMenuTheme: PopupMenuThemeData(
          color: AppColors.surfacePopover,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1.2,
            ),
          ),
          elevation: 12,
          textStyle: AppTextStyles.bodySmall.copyWith(color: Colors.white),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: AppColors.surfacePopover,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          titleTextStyle: AppTextStyles.titleMedium,
        ),
        drawerTheme: const DrawerThemeData(
          backgroundColor: AppColors.surfacePlayer,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppColors.surfacePopover,
          modalBackgroundColor: AppColors.surfacePopover,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
        ),
      ),
      home: onboardingCompleted
          ? const AppShell()
          : const PermissionOnboardingScreen(),
    );
  }
}

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final NavigatorState? navigator = innerNavigatorKey.currentState;
        if (navigator != null && navigator.canPop()) {
          navigator.pop();
          return;
        }

        final currentScreen = ref.read(screenProvider);
        if (currentScreen == AppScreen.lyrics) {
          ref.read(screenProvider.notifier).state = AppScreen.player;
        } else if (currentScreen == AppScreen.player) {
          ref.read(screenProvider.notifier).state = AppScreen.home;
        } else {
          // If we are at the root of the inner navigator, we can close the app or go back to android home
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        key: rootScaffoldKey,
        backgroundColor: Colors.transparent,
        drawer: const AppDrawer(),
        drawerEnableOpenDragGesture: false,
        body: Stack(
          children: [
            Positioned.fill(
              child: Navigator(
                key: innerNavigatorKey,
                onGenerateRoute: (settings) {
                  return MaterialPageRoute(
                    builder: (context) => const RootLayout(),
                    settings: settings,
                  );
                },
              ),
            ),
            const Positioned.fill(child: MainMusicPlayer()),
          ],
        ),
      ),
    );
  }
}

class RootLayout extends ConsumerWidget {
  const RootLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Optimize rebuilds by watching ONLY the properties needed for routing
    final permissionStatus = ref.watch(
      libraryProvider.select((s) => s.permissionStatus),
    );
    final isLoading = ref.watch(libraryProvider.select((s) => s.isLoading));
    final hasSongs = ref.watch(
      libraryProvider.select((s) => s.songs.isNotEmpty),
    );
    final errorMessage = ref.watch(
      libraryProvider.select((s) => s.errorMessage),
    );

    final currentTab = ref.watch(mainTabProvider);

    // Set status bar color for dark backgrounds (main app)
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    // Auto-request permission silently if in initial state
    if (permissionStatus == LibraryPermissionStatus.initial) {
      Future.microtask(() {
        ref.read(libraryProvider.notifier).requestPermission();
      });
      return const LibraryLoadingScreen();
    }

    // Show loading screen ONLY if we have NO cached songs yet.
    if (isLoading && !hasSongs) {
      return const LibraryLoadingScreen();
    }

    // Show error if scanning failed
    if (errorMessage != null) {
      return ErrorScreen(message: errorMessage);
    }

    // Normal app flow
    Widget content;
    switch (currentTab) {
      case MainTab.discover:
        content = const DiscoverScreen();
      case MainTab.collection:
        content = const CollectionScreen();
      case MainTab.home:
        content = const HomeScreen();
    }

    return Stack(
      children: [
        // 1. Dynamic Blurred Background (Extracted & Wrapped in RepaintBoundary)
        const BlurredBackground(),

        // 2. Main App content
        Material(color: Colors.transparent, child: content),
      ],
    );
  }
}

/// Extracted background to isolate blur calculations and repaints.
/// Uses [RepaintBoundary] to ensure scrolling content doesn't force a re-blur.
class BlurredBackground extends ConsumerWidget {
  const BlurredBackground({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSong = ref.watch(playerProvider.select((s) => s.currentSong));
    final performanceMode = ref.watch(performanceModeProvider);

    return RepaintBoundary(
      child: Stack(
        children: [
          // Background Color / Gradient (Always present)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.mainDarkLight.withValues(alpha: 0.85),
                      AppColors.mainDark.withValues(alpha: 0.85),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Artwork & Blur (Conditional)
          if (currentSong != null &&
              performanceMode != PerformanceMode.ultraLow) ...[
            Positioned.fill(
              child: IgnorePointer(
                child: AppArtwork(
                  songId: currentSong.id,
                  fit: BoxFit.cover,
                  size: 300, // Downsampled for performance
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: performanceMode == PerformanceMode.low ? 15 : 30,
                    sigmaY: performanceMode == PerformanceMode.low ? 15 : 30,
                  ),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
            // Re-apply overlay for depth and readability
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.mainDarkLight.withValues(alpha: 0.7),
                        AppColors.mainDark.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class LibraryLoadingScreen extends StatelessWidget {
  const LibraryLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentBlue.withValues(alpha: 0.1),
              ),
              child: const Icon(
                Icons.music_note,
                color: AppColors.accentBlue,
                size: 50,
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              "Awtar",
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Organizing your musical world...",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 200,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: const LinearProgressIndicator(
                  color: AppColors.accentBlue,
                  backgroundColor: AppColors.surfaceDark,
                  minHeight: 6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PermissionRequestScreen extends ConsumerWidget {
  const PermissionRequestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.folder_open,
                color: AppColors.accentBlue,
                size: 80,
              ),
              const SizedBox(height: 40),
              const Text(
                "Access Your Music",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                "Awtar needs permission to access your music library to play your favorite songs.",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () {
                  ref.read(libraryProvider.notifier).requestPermission();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentBlue,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  "Grant Permission",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PermissionDeniedScreen extends ConsumerWidget {
  final bool isPermanent;
  const PermissionDeniedScreen({super.key, required this.isPermanent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isPermanent ? Icons.block : Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 80,
              ),
              const SizedBox(height: 40),
              Text(
                isPermanent ? "Permission Denied" : "Access Required",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                isPermanent
                    ? "Storage permission was permanently denied. Please enable it in your device settings to use Awtar."
                    : "Awtar cannot function without storage permission. Please grant access to continue.",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () {
                  if (isPermanent) {
                    ref.read(libraryProvider.notifier).openSettings();
                  } else {
                    ref.read(libraryProvider.notifier).requestPermission();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentBlue,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  isPermanent ? "Open Settings" : "Try Again",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ErrorScreen extends ConsumerWidget {
  final String message;
  const ErrorScreen({super.key, required this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 80),
              const SizedBox(height: 40),
              const Text(
                "Something Went Wrong",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () {
                  ref.read(libraryProvider.notifier).requestPermission();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentBlue,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  "Retry",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
