import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';

enum PerformanceMode { normal, low, ultraLow }

final performanceModeProvider =
    StateNotifierProvider<PerformanceNotifier, PerformanceMode>((ref) {
      final prefs = ref.watch(sharedPreferencesProvider);
      return PerformanceNotifier(prefs);
    });

// Backward compatibility (don't break existing code yet)
final lowPerformanceModeProvider = Provider<bool>((ref) {
  final mode = ref.watch(performanceModeProvider);
  return mode == PerformanceMode.low || mode == PerformanceMode.ultraLow;
});

final ultraLowPerformanceModeProvider = Provider<bool>((ref) {
  final mode = ref.watch(performanceModeProvider);
  return mode == PerformanceMode.ultraLow;
});

class PerformanceNotifier extends StateNotifier<PerformanceMode> {
  final SharedPreferences _prefs;

  PerformanceNotifier(this._prefs) : super(_getInitialMode(_prefs));

  static PerformanceMode _getInitialMode(SharedPreferences prefs) {
    // Migrate old bool setting if it exists
    if (prefs.containsKey('low_performance_mode')) {
      final isLow = prefs.getBool('low_performance_mode') ?? false;
      prefs.remove('low_performance_mode'); // Clean up old key
      final mode = isLow ? PerformanceMode.low : PerformanceMode.normal;
      prefs.setString('performance_mode_v2', mode.name);
      return mode;
    }

    final saved = prefs.getString('performance_mode_v2');
    if (saved == null) return PerformanceMode.normal;
    return PerformanceMode.values.firstWhere(
      (e) => e.name == saved,
      orElse: () => PerformanceMode.normal,
    );
  }

  void setMode(PerformanceMode mode) {
    state = mode;
    _prefs.setString('performance_mode_v2', mode.name);
  }

  void toggle() {
    if (state == PerformanceMode.normal) {
      setMode(PerformanceMode.low);
    } else if (state == PerformanceMode.low) {
      setMode(PerformanceMode.ultraLow);
    } else {
      setMode(PerformanceMode.normal);
    }
  }
}
