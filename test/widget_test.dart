// Test file for Awtar Music Player
// Tests the main app flows: onboarding, tabs/navigation, and player state

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:awtar_music_player/main.dart';
import 'package:awtar_music_player/screens/permission_onboarding_screen.dart';
import 'package:awtar_music_player/screens/home_screen.dart';
import 'package:awtar_music_player/providers/library_provider.dart';
import 'package:awtar_music_player/providers/player_provider.dart';
import 'package:awtar_music_player/providers/navigation_provider.dart';
import 'package:awtar_music_player/providers/stats_provider.dart';

void main() {
  group('App Flow Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('Shows Onboarding when first run', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({'onboarding_completed': false});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            // Override stats provider even for onboarding since app might init it
            statsProvider.overrideWith((ref) => StatsNotifier(prefs)),
          ],
          child: const MyApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PermissionOnboardingScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
    });

    testWidgets('Shows Home Screen (Tabs) when onboarding completed', (
      WidgetTester tester,
    ) async {
      // Simulate completed onboarding
      SharedPreferences.setMockInitialValues({'onboarding_completed': true});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            libraryProvider.overrideWith((ref) => TestLibraryNotifier(ref)),
            playerProvider.overrideWith(
              (ref) => PlayerNotifier(ref, skipInit: true),
            ),
            statsProvider.overrideWith((ref) => StatsNotifier(prefs)),
          ],
          child: const MyApp(),
        ),
      );

      // Allow initial build
      await tester.pump();
      // LibraryLoadingScreen might show first if state is loading, let's settle
      await tester.pump(const Duration(seconds: 2));

      // We expect to see the AppShell which contains the main navigation
      expect(find.byType(AppShell), findsOneWidget);
    });
  });

  group('State Management Tests', () {
    test('Initial Player State is empty/stopped', () {
      final container = ProviderContainer(
        overrides: [
          playerProvider.overrideWith(
            (ref) => PlayerNotifier(ref, skipInit: true),
          ),
        ],
      );
      addTearDown(container.dispose);

      final playerState = container.read(playerProvider);

      expect(playerState.isPlaying, false);
      expect(playerState.currentSong, null);
      expect(playerState.queue, isEmpty);
    });

    test('Navigation defaults to Home tab', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final currentTab = container.read(mainTabProvider);
      expect(currentTab, MainTab.home);
    });
  });
}

// Simulator for testing that sets permission to granted
class TestLibraryNotifier extends LibraryNotifier {
  TestLibraryNotifier(Ref ref) : super(ref, skipInit: true) {
    state = state.copyWith(
      isLoading: false,
      permissionStatus: LibraryPermissionStatus.granted,
    );
  }
}
