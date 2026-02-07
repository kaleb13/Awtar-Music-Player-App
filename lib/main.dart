import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:awtart_music_player/providers/navigation_provider.dart';
import 'screens/main_sections.dart';
import 'screens/home_screen.dart';
import 'screens/main_player_screen.dart';

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
    final currentTab = ref.watch(mainTabProvider);

    Widget content;
    switch (currentTab) {
      case MainTab.discover:
        content = const DiscoverScreen();
        break;
      case MainTab.collection:
        content = const CollectionScreen();
        break;
      case MainTab.home:
      default:
        content = const HomeScreen();
        break;
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. CONTENT LAYER
          content,
          // 2. THE DYNAMIC PLAYER SECTION (Handles all 3 states: Mini, Expanded, Lyrics)
          const Positioned.fill(child: MainMusicPlayer()),
        ],
      ),
    );
  }
}
