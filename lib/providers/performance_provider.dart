import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';

final lowPerformanceModeProvider =
    StateNotifierProvider<PerformanceNotifier, bool>((ref) {
      final prefs = ref.watch(sharedPreferencesProvider);
      return PerformanceNotifier(prefs);
    });

class PerformanceNotifier extends StateNotifier<bool> {
  final SharedPreferences _prefs;

  PerformanceNotifier(this._prefs)
    : super(_prefs.getBool('low_performance_mode') ?? false);

  void toggle() {
    state = !state;
    _prefs.setBool('low_performance_mode', state);
  }
}
