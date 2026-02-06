import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/main_player_screen.dart';
import 'screens/home_screen.dart';
import 'providers/navigation_provider.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Awtart Music Player',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
        useMaterial3: true,
      ),
      home: const RootLayout(),
    );
  }
}

class RootLayout extends ConsumerWidget {
  const RootLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentScreen = ref.watch(screenProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // HOME PAGE ALWAYS AT THE BOTTOM
          const HomeScreen(),

          // PLAYER OVERLAY (Slides up/down)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutQuart,
            top: currentScreen == AppScreen.player
                ? 0
                : MediaQuery.of(context).size.height,
            left: 0,
            right: 0,
            bottom: currentScreen == AppScreen.player
                ? 0
                : -MediaQuery.of(context).size.height,
            child: const MainMusicPlayer(),
          ),
        ],
      ),
    );
  }
}
