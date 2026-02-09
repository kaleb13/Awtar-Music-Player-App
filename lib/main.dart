import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:awtart_music_player/providers/navigation_provider.dart';
import 'package:device_preview/device_preview.dart';
import 'screens/main_sections.dart';
import 'screens/home_screen.dart';
import 'screens/main_player_screen.dart';

void main() {
  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => const ProviderScope(child: MyApp()),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      title: 'Awtar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
        useMaterial3: true,
      ),
      home: const RootLayout(),
      builder: (context, child) {
        final childWithOverlay = Stack(
          children: [
            child ?? const SizedBox(),
            Overlay(
              initialEntries: [
                OverlayEntry(builder: (context) => const MainMusicPlayer()),
              ],
            ),
          ],
        );
        return DevicePreview.appBuilder(context, childWithOverlay);
      },
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

    return Scaffold(backgroundColor: Colors.black, body: content);
  }
}
