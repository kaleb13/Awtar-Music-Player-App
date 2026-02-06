import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
