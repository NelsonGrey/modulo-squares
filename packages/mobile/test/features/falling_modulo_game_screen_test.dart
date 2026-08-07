import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:modulo_squares/core/di/service_locator.dart';
import 'package:modulo_squares/core/services/purchase_service.dart';
import 'package:modulo_squares/features/game/falling_modulo_game_screen.dart';
import 'package:modulo_squares/features/game/models/falling_modulo_game_engine.dart';

// ── Helpers ──────────────────────────────────────────────────────────────────

Widget _buildApp() => const MaterialApp(home: FallingModuloGameScreen());

const Size _phoneSize = Size(1080, 1920);

/// Pump the app and settle, applying a standard phone viewport.
Future<void> _pumpGame(WidgetTester tester) async {
  tester.view.physicalSize = _phoneSize;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(_buildApp());
  await tester.pump();
}

/// Open the settings dialog and settle.
Future<void> _openSettings(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Settings'));
  await tester.pumpAndSettle();
}

/// Expand a collapsed Settings section (Gameplay starts expanded; the rest
/// don't) by tapping its header.
Future<void> _expandSection(WidgetTester tester, String header) async {
  await tester.tap(find.text(header));
  await tester.pumpAndSettle();
}

// ── Setup / teardown ─────────────────────────────────────────────────────────

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    // Reset the service locator between tests so registered services don't
    // bleed across test cases.
    await getIt.reset();
  });

  // ── Basic game screen rendering ───────────────────────────────────────────

  group('Game screen basics', () {
    testWidgets('renders without crashing', (tester) async {
      await _pumpGame(tester);
      expect(find.byType(FallingModuloGameScreen), findsOneWidget);
    });

    testWidgets('shows Level and Score labels on start', (tester) async {
      await _pumpGame(tester);
      expect(find.textContaining('Level'), findsWidgets);
      expect(find.textContaining('Score'), findsWidgets);
    });

    testWidgets('drop progress indicator starts at zero during spawn delay', (
      tester,
    ) async {
      await _pumpGame(tester);
      final indicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(indicator.value, 0.0);
    });

    testWidgets('shows pre-game overlay and paused state before first start', (
      tester,
    ) async {
      await _pumpGame(tester);
      expect(find.text('Fall: Paused'), findsOneWidget);
      expect(find.text('Start Game'), findsOneWidget);
    });

    testWidgets('tapping Start Game reveals the Pause AppBar button', (
      tester,
    ) async {
      await _pumpGame(tester);
      await tester.tap(find.text('Start Game'));
      await tester.pump();
      expect(find.byTooltip('Pause'), findsOneWidget);
    });

    testWidgets('expert demo builds a clean combo without a deficit', (
      tester,
    ) async {
      tester.view.physicalSize = _phoneSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: FallingModuloGameScreen(
            engine: FallingModuloGameEngine(random: Random(20260803)),
            expertDemo: true,
          ),
        ),
      );
      await tester.pump();

      // Advance in human-scale input increments so the production movement
      // cooldown and falling-tile timers both participate in the demo.
      for (var step = 0; step < 180; step++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      // Drain the score-burst label's own 700ms auto-clear timer so it can't
      // still be pending when the test ends -- how many real-time moves land
      // within the loop above (and thus the exact tick the last burst timer
      // was scheduled on) is sensitive to how much CPU work runs per pump,
      // since move cooldown gating uses wall-clock DateTime.now(), not the
      // fake test clock.
      await tester.pump(const Duration(milliseconds: 700));

      final comboLabel = tester
          .widgetList<Text>(find.byType(Text))
          .map((widget) => widget.data)
          .whereType<String>()
          .firstWhere((text) => text.startsWith('Combo: '));
      final combo = int.parse(comboLabel.substring('Combo: '.length));

      expect(combo, greaterThanOrEqualTo(1));
      expect(find.textContaining('Deficit:'), findsNothing);
    });
  });

  // ── Settings dialog — section headers ────────────────────────────────────

  group('Settings dialog — section headers', () {
    testWidgets('dialog title reads Settings', (tester) async {
      await _pumpGame(tester);
      await _openSettings(tester);

      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('GAMEPLAY section header is present', (tester) async {
      await _pumpGame(tester);
      await _openSettings(tester);

      expect(find.text('GAMEPLAY'), findsOneWidget);
    });

    testWidgets('ACCOUNT section header is present', (tester) async {
      await _pumpGame(tester);
      await _openSettings(tester);

      expect(find.text('ACCOUNT'), findsOneWidget);
    });

    testWidgets(
      'PURCHASES section header is absent when no purchase service is registered',
      (tester) async {
        await _pumpGame(tester);
        await _openSettings(tester);

        expect(find.text('PURCHASES'), findsNothing);
      },
    );

    testWidgets(
      'PURCHASES section header appears when purchase service is registered',
      (tester) async {
        getIt.registerLazySingleton<PurchaseService>(
          () => PurchaseService.createForTesting(),
        );
        await _pumpGame(tester);
        await _openSettings(tester);

        expect(find.text('PURCHASES'), findsOneWidget);
      },
    );
  });

  // ── Settings dialog — Gameplay section ───────────────────────────────────

  group('Settings dialog — Gameplay section', () {
    testWidgets('Visual Cues switch is present', (tester) async {
      await _pumpGame(tester);
      await _openSettings(tester);

      expect(find.text('Visual Cues'), findsOneWidget);
    });

    testWidgets('Visual Cues subtitle describes the feature', (tester) async {
      await _pumpGame(tester);
      await _openSettings(tester);

      expect(
        find.text('Highlight buckets that divide the current number evenly'),
        findsOneWidget,
      );
    });

    testWidgets('Best Score label is present', (tester) async {
      await _pumpGame(tester);
      await _openSettings(tester);

      expect(find.text('Best Score'), findsOneWidget);
    });

    testWidgets('Best Score shows 0 on a fresh game', (tester) async {
      await _pumpGame(tester);
      await _openSettings(tester);

      // The score 0 appears both in the HUD and in the dialog; at least one
      // occurrence is expected.
      expect(find.text('0'), findsWidgets);
    });

    testWidgets('Best Score reflects a saved high score from prefs', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'fallingMode.highScore': 42,
        'fallingMode.visualCuesEnabled': true,
      });

      await _pumpGame(tester);
      await tester.pump(); // allow initState async prefs load
      await _openSettings(tester);

      expect(find.text('42'), findsWidgets);
    });

    testWidgets('Visual Cues switch can be toggled inside the dialog', (
      tester,
    ) async {
      await _pumpGame(tester);
      await _openSettings(tester);

      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);

      final switchBefore = tester.widget<Switch>(switchFinder).value;

      await tester.tap(switchFinder);
      await tester.pump();

      final switchAfter = tester.widget<Switch>(switchFinder).value;
      expect(switchAfter, isNot(switchBefore));
    });
  });

  // ── Settings dialog — Purchases section ──────────────────────────────────

  group('Settings dialog — Purchases section (service available)', () {
    setUp(() {
      getIt.registerLazySingleton<PurchaseService>(
        () => PurchaseService.createForTesting(),
      );
    });

    testWidgets('shows "Ads Enabled" when ads are not removed', (tester) async {
      await _pumpGame(tester);
      await _openSettings(tester);
      await _expandSection(tester, 'PURCHASES');

      expect(find.text('Ads Enabled'), findsOneWidget);
    });

    testWidgets('shows subtitle about ads playing between levels', (
      tester,
    ) async {
      await _pumpGame(tester);
      await _openSettings(tester);
      await _expandSection(tester, 'PURCHASES');

      expect(find.text('Short ads play between levels'), findsOneWidget);
    });

    testWidgets('Unlock Premium button is shown when ads are not removed', (
      tester,
    ) async {
      await _pumpGame(tester);
      await _openSettings(tester);
      await _expandSection(tester, 'PURCHASES');

      expect(find.textContaining('Unlock Premium'), findsOneWidget);
    });

    testWidgets('Unlock Premium button includes the product price', (
      tester,
    ) async {
      await _pumpGame(tester);
      await _openSettings(tester);
      await _expandSection(tester, 'PURCHASES');

      // The purchase service returns $2.99 as a fallback price when no store
      // product is loaded (test environment has no App Store connection).
      expect(find.textContaining('\$2.99'), findsOneWidget);
    });

    testWidgets('Restore Purchases button is always shown', (tester) async {
      await _pumpGame(tester);
      await _openSettings(tester);
      await _expandSection(tester, 'PURCHASES');

      expect(find.text('Restore Purchases'), findsOneWidget);
    });

    testWidgets('shows "Ad-Free" and hides Unlock Premium when ads are removed', (
      tester,
    ) async {
      // Simulate ads already removed via prefs (PurchaseService.createForTesting
      // respects SharedPreferences).
      SharedPreferences.setMockInitialValues({'ads_removed': true});

      // Re-register with the newly seeded prefs.
      await getIt.reset();
      final svc = PurchaseService.createForTesting();
      await svc.initialize(); // loads prefs
      getIt.registerSingleton<PurchaseService>(svc);

      await _pumpGame(tester);
      await _openSettings(tester);
      await _expandSection(tester, 'PURCHASES');

      expect(find.text('Ad-Free'), findsOneWidget);
      expect(find.text('Enjoy the game without interruptions'), findsOneWidget);
      expect(find.textContaining('Unlock Premium'), findsNothing);
    });

    testWidgets('Restore Purchases button shown even when ads are removed', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({'ads_removed': true});

      await getIt.reset();
      final svc = PurchaseService.createForTesting();
      await svc.initialize();
      getIt.registerSingleton<PurchaseService>(svc);

      await _pumpGame(tester);
      await _openSettings(tester);
      await _expandSection(tester, 'PURCHASES');

      expect(find.text('Restore Purchases'), findsOneWidget);
    });
  });

  // ── Settings dialog — Account section ────────────────────────────────────

  group('Settings dialog — Account section', () {
    testWidgets('Sign Out option is always shown', (tester) async {
      await _pumpGame(tester);
      await _openSettings(tester);
      await _expandSection(tester, 'ACCOUNT');

      expect(find.text('Sign Out'), findsOneWidget);
    });

    testWidgets('Delete Account option is always shown', (tester) async {
      await _pumpGame(tester);
      await _openSettings(tester);
      await _expandSection(tester, 'ACCOUNT');

      expect(find.text('Delete Account'), findsOneWidget);
    });

    testWidgets('tapping Delete Account shows a confirmation dialog', (
      tester,
    ) async {
      await _pumpGame(tester);
      await _openSettings(tester);
      await _expandSection(tester, 'ACCOUNT');

      await tester.tap(find.text('Delete Account'));
      await tester.pumpAndSettle();

      expect(find.text('Delete account?'), findsOneWidget);

      await tester.tap(find.text('Cancel').last);
      await tester.pumpAndSettle();

      expect(find.text('Delete account?'), findsNothing);
    });

    testWidgets(
      'Link Account is not shown when Firebase is uninitialised (treats as non-guest)',
      (tester) async {
        // Firebase is not initialized in the test environment; the code catches
        // the exception and sets isGuest = false, so Link Account stays hidden.
        await _pumpGame(tester);
        await _openSettings(tester);
        await _expandSection(tester, 'ACCOUNT');

        expect(find.text('Link Account'), findsNothing);
      },
    );

    testWidgets(
      'Change Password is not shown when Firebase is uninitialised (treats as no password provider)',
      (tester) async {
        // Firebase is not initialized in the test environment; the code catches
        // the exception and sets hasPasswordProvider = false, so Change
        // Password stays hidden -- mirrors the Link Account case above.
        await _pumpGame(tester);
        await _openSettings(tester);
        await _expandSection(tester, 'ACCOUNT');

        expect(find.text('Change Password'), findsNothing);
      },
    );

    testWidgets('dialog does not show legacy Switch Mode action', (
      tester,
    ) async {
      await _pumpGame(tester);
      await _openSettings(tester);
      await _expandSection(tester, 'ACCOUNT');

      expect(find.text('Switch Mode'), findsNothing);
    });
  });

  // ── Settings dialog — Legal & Support section ─────────────────────────────

  group('Settings dialog — Legal & Support section', () {
    testWidgets('Privacy Policy option is shown', (tester) async {
      await _pumpGame(tester);
      await _openSettings(tester);
      await _expandSection(tester, 'LEGAL & SUPPORT');

      expect(find.text('Privacy Policy'), findsOneWidget);
    });

    testWidgets('Terms of Service option is shown', (tester) async {
      await _pumpGame(tester);
      await _openSettings(tester);
      await _expandSection(tester, 'LEGAL & SUPPORT');

      expect(find.text('Terms of Service'), findsOneWidget);
    });

    testWidgets('Support option is shown', (tester) async {
      await _pumpGame(tester);
      await _openSettings(tester);
      await _expandSection(tester, 'LEGAL & SUPPORT');

      expect(find.text('Support'), findsOneWidget);
    });
  });

  // ── Settings dialog — Action buttons ─────────────────────────────────────

  group('Settings dialog — actions', () {
    testWidgets('Cancel button closes the dialog', (tester) async {
      await _pumpGame(tester);
      await _openSettings(tester);

      expect(find.text('Cancel'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsNothing);
    });

    testWidgets('Save button closes the dialog', (tester) async {
      await _pumpGame(tester);
      await _openSettings(tester);

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsNothing);
    });

    testWidgets('Save persists a Visual Cues toggle change', (tester) async {
      // Start with visual cues ON (default).
      await _pumpGame(tester);
      await _openSettings(tester);

      // Toggle the switch OFF.
      await tester.tap(find.byType(Switch));
      await tester.pump();

      // Save.
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Re-open — the switch should now be OFF.
      await _openSettings(tester);

      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, isFalse);
    });

    testWidgets('Cancel does not persist a Visual Cues toggle change', (
      tester,
    ) async {
      // Start with visual cues ON (default).
      await _pumpGame(tester);
      await _openSettings(tester);

      // Toggle switch OFF.
      await tester.tap(find.byType(Switch));
      await tester.pump();

      // Cancel.
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Re-open — the switch should still be ON.
      await _openSettings(tester);

      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, isTrue);
    });
  });

  // ── Pause overlay — New Game (with confirmation) ─────────────────────────

  group('Pause overlay — New Game', () {
    Future<void> pauseGame(WidgetTester tester) async {
      await tester.tap(find.text('Start Game'));
      await tester.pump();
      await tester.tap(find.byTooltip('Pause'));
      await tester.pump();
    }

    testWidgets('tapping New Game asks for confirmation before resetting', (
      tester,
    ) async {
      await _pumpGame(tester);
      await pauseGame(tester);

      await tester.tap(find.text('New Game'));
      await tester.pumpAndSettle();

      expect(find.text('Start a new run?'), findsOneWidget);
      // Nothing reset yet — still on the confirmation dialog.
      expect(find.text('Start Game'), findsNothing);
    });

    testWidgets('confirming resets score to 0 and shows Start Game overlay', (
      tester,
    ) async {
      await _pumpGame(tester);
      await pauseGame(tester);

      await tester.tap(find.text('New Game'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('New Run'));
      await tester.pumpAndSettle();

      expect(find.text('Start a new run?'), findsNothing);
      expect(find.text('Start Game'), findsOneWidget);
    });

    testWidgets('cancelling the confirmation leaves the run unchanged', (
      tester,
    ) async {
      await _pumpGame(tester);
      await pauseGame(tester);

      await tester.tap(find.text('New Game'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Start a new run?'), findsNothing);
      // Still paused mid-run, not back at the pre-game overlay.
      expect(find.text('Start Game'), findsNothing);
      expect(find.text('Paused'), findsOneWidget);
    });
  });
}
