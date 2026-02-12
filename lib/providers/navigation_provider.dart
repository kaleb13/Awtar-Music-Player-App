import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final GlobalKey<NavigatorState> innerNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldState> rootScaffoldKey = GlobalKey<ScaffoldState>();

final scrollProgressProvider = StateProvider<double>((ref) => 0.0);

final pageControllerProvider = Provider<PageController>((ref) {
  final controller = PageController();
  controller.addListener(() {
    if (controller.hasClients) {
      ref.read(scrollProgressProvider.notifier).state = controller.page ?? 0.0;
    }
  });
  ref.onDispose(() => controller.dispose());
  return controller;
});

enum AppScreen { home, player, lyrics }

final screenProvider = StateProvider<AppScreen>((ref) => AppScreen.home);

enum HomeTab { home, folders, artists, albums }

final homeTabProvider = StateProvider<HomeTab>((ref) => HomeTab.home);

enum MainTab { home, discover, collection }

final mainTabProvider = StateProvider<MainTab>((ref) => MainTab.home);

final bottomNavVisibleProvider = StateProvider<bool>((ref) => true);
