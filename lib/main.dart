import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/main_player_screen.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Awtar',
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
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. HOME PAGE (Static Base)
          HomeScreen(),

          // 2. THE DYNAMIC PLAYER SECTION (Handles all 3 states: Mini, Expanded, Lyrics)
          Positioned.fill(child: MainMusicPlayer()),
        ],
      ),
    );
  }
}
