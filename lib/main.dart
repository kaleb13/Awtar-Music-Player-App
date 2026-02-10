import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:awtart_music_player/providers/navigation_provider.dart';
import 'package:awtart_music_player/providers/library_provider.dart';
import 'package:awtart_music_player/providers/player_provider.dart';
import 'package:awtart_music_player/theme/app_theme.dart';
import 'screens/main_sections.dart';
import 'screens/home_screen.dart';
import 'screens/main_player_screen.dart';
import 'screens/permission_onboarding_screen.dart';
import 'widgets/app_artwork.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'providers/stats_provider.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

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
        splashColor: Colors.white.withOpacity(0.05),
        highlightColor: Colors.transparent,
        indicatorColor: AppColors.accentYellow,
        tabBarTheme: TabBarThemeData(
          indicatorColor: AppColors.accentYellow,
          overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.pressed)) {
              return Colors.white.withOpacity(0.05);
            }
            if (states.contains(WidgetState.hovered)) {
              return Colors.white.withOpacity(0.03);
            }
            return null;
          }),
        ),
      ),
      home: onboardingCompleted
          ? const RootLayout()
          : const PermissionOnboardingScreen(),
    );
  }
}

class RootLayout extends ConsumerWidget {
  const RootLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryState = ref.watch(libraryProvider);
    final currentTab = ref.watch(mainTabProvider);
    final playerState = ref.watch(playerProvider); // Added
    final currentSong = playerState.currentSong; // Added

    // Set status bar color for dark backgrounds (main app)
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    // Auto-request permission silently if in initial state
    // (onboarding has already shown permission UI)
    if (libraryState.permissionStatus == LibraryPermissionStatus.initial) {
      // Request permission silently without showing UI
      Future.microtask(() {
        ref.read(libraryProvider.notifier).requestPermission();
      });
      return const LibraryLoadingScreen();
    }

    // Show loading screen while scanning
    if (libraryState.isLoading) {
      return const LibraryLoadingScreen();
    }

    // Show error if scanning failed
    if (libraryState.errorMessage != null) {
      return ErrorScreen(message: libraryState.errorMessage!);
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
        // 1. Dynamic Blurred Background
        if (currentSong != null)
          Positioned.fill(
            child: AppArtwork(songId: currentSong.id, fit: BoxFit.cover),
          ),

        // 2. Blur Filter
        if (currentSong != null)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(color: Colors.transparent),
            ),
          ),

        // 3. Current background color with 25% opacity (Overground)
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.mainDarkLight.withOpacity(0.9),
                  AppColors.mainDark.withOpacity(0.9),
                ],
              ),
            ),
          ),
        ),

        // 4. Main App Scaffold (must be transparent to see the background)
        Scaffold(backgroundColor: Colors.transparent, body: content),

        const MainMusicPlayer(),
      ],
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
                color: AppColors.primaryGreen.withOpacity(0.1),
              ),
              child: const Icon(
                Icons.music_note,
                color: AppColors.primaryGreen,
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
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 200,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: const LinearProgressIndicator(
                  color: AppColors.primaryGreen,
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
                color: AppColors.primaryGreen,
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
                  color: Colors.white.withOpacity(0.7),
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
                  backgroundColor: AppColors.primaryGreen,
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
                  color: Colors.white.withOpacity(0.7),
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
                  backgroundColor: AppColors.primaryGreen,
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
                  color: Colors.white.withOpacity(0.7),
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
                  backgroundColor: AppColors.primaryGreen,
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
