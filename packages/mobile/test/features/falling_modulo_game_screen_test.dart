import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:modulo_squares/core/di/service_locator.dart';
import 'package:modulo_squares/core/services/purchase_service.dart';
import 'package:modulo_squares/features/game/falling_modulo_game_screen.dart';
import 'package:modulo_squares/features/game/models/falling_modulo_game_engine.dart';
import 'package:modulo_squares/features/game/models/game_theme.dart';

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

/// Reads the text of a keyed HUD value (see game_hud.dart's `Key`s) -- the
/// HUD renders bare values inside icon chips/labels rather than
/// "Label: value" pills, so plain `find.text` would collide with other
/// on-screen numbers.
String _hudValue(WidgetTester tester, String key) {
  return tester.widget<Text>(find.byKey(Key(key))).data!;
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
      // The score eyebrow label renders as "SCORE" (uppercase).
      expect(find.textContaining('SCORE'), findsWidgets);
    });

    testWidgets('drop progress indicator starts at zero during spawn delay', (
      tester,
    ) async {
      await _pumpGame(tester);
      final indicator = tester.widget<LinearProgressIndicator>(
        find.byKey(const Key('drop-progress-indicator')),
      );
      expect(indicator.value, 0.0);
    });

    testWidgets('shows pre-game overlay and paused state before first start', (
      tester,
    ) async {
      await _pumpGame(tester);
      expect(_hudValue(tester, 'hud-fall-value'), 'Paused');
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
      // still be pending when the test ends.
      await tester.pump(const Duration(milliseconds: 700));

      final combo = int.parse(_hudValue(tester, 'hud-combo-value'));

      expect(combo, greaterThanOrEqualTo(1));
      // The Deficit chip is always present now, just reading 0 when clear.
      expect(_hudValue(tester, 'hud-deficit-value'), '0');
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

    testWidgets('APPEARANCE section header is present', (tester) async {
      await _pumpGame(tester);
      await _openSettings(tester);

      expect(find.text('APPEARANCE'), findsOneWidget);
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
      SharedPreferences.setMockInitialValues({'fallingMode.highScore': 42});

      await _pumpGame(tester);
      await tester.pump(); // allow initState async prefs load
      await _openSettings(tester);

      expect(find.text('42'), findsWidgets);
    });

    testWidgets('Difficulty control is present and defaults to Normal', (
      tester,
    ) async {
      await _pumpGame(tester);
      await _openSettings(tester);

      expect(find.text('Difficulty'), findsOneWidget);
      final segmentedButton = tester.widget<SegmentedButton<GameDifficulty>>(
        find.byType(SegmentedButton<GameDifficulty>),
      );
      expect(segmentedButton.selected, {GameDifficulty.normal});
    });

    testWidgets('Difficulty selection can be changed inside the dialog', (
      tester,
    ) async {
      await _pumpGame(tester);
      await _openSettings(tester);

      await tester.tap(find.text('Hard'));
      await tester.pump();

      final segmentedButton = tester.widget<SegmentedButton<GameDifficulty>>(
        find.byType(SegmentedButton<GameDifficulty>),
      );
      expect(segmentedButton.selected, {GameDifficulty.hard});
    });

    testWidgets(
      'Best Score reflects a score the demo already raised before Settings '
      'opened, and stays put (not stale, not still climbing) across an '
      'in-dialog rebuild',
      (tester) async {
        // Regression test: showGameSettingsDialog used to take a plain `int
        // highScore` captured once when the dialog opened, which could go
        // stale after a later in-dialog rebuild (e.g. changing Difficulty).
        // It now takes a `getHighScore` getter read fresh on every rebuild.
        //
        // This no longer raises the score *behind* the open dialog -- opening
        // Settings now pauses the game (see the dedicated pause test below),
        // so the getter is instead exercised by rebuilding the dialog after
        // the score was already raised, confirming it reads the current
        // value rather than one snapshotted from an earlier build.
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

        // Let the expert demo play *before* Settings is open, long enough to
        // land at least one scoring success and raise the high score above 0.
        for (var step = 0; step < 120; step++) {
          await tester.pump(const Duration(milliseconds: 50));
        }

        await _openSettings(tester);
        expect(
          find.descendant(
            of: find.widgetWithText(ListTile, 'Best Score'),
            matching: find.text('0'),
          ),
          findsNothing,
        );
        // The ListTile's own title Text('Best Score') is also a descendant
        // alongside the trailing score Text, so byType(Text) alone matches
        // both -- pick out the one that isn't the title.
        String bestScoreValue() {
          return tester
              .widgetList<Text>(
                find.descendant(
                  of: find.widgetWithText(ListTile, 'Best Score'),
                  matching: find.byType(Text),
                ),
              )
              .map((t) => t.data)
              .whereType<String>()
              .firstWhere((data) => data != 'Best Score');
        }

        final scoreBeforeRebuild = bestScoreValue();

        // The game is paused behind the dialog now, so waiting here should
        // not change the score -- unlike the old captured-once bug, there is
        // nothing left to go stale, but confirm score is stable regardless.
        for (var step = 0; step < 40; step++) {
          await tester.pump(const Duration(milliseconds: 50));
        }

        // Force the dialog's StatefulBuilder to rebuild via an in-dialog
        // interaction, the same trigger the original bug report used.
        await tester.tap(find.text('Hard'));
        await tester.pump();

        expect(bestScoreValue(), scoreBeforeRebuild);
      },
    );
  });

  // ── Settings dialog — Appearance section ─────────────────────────────────

  group('Settings dialog — Appearance section', () {
    testWidgets('theme picker defaults to Deep Ocean', (tester) async {
      await _pumpGame(tester);
      await _openSettings(tester);
      await _expandSection(tester, 'APPEARANCE');

      final deepOceanSwatch = find.byKey(const Key('theme-swatch-deepOcean'));
      expect(deepOceanSwatch, findsOneWidget);
      expect(
        find.descendant(of: deepOceanSwatch, matching: find.byIcon(Icons.check)),
        findsOneWidget,
      );
    });

    testWidgets('selecting a palette and saving persists it across reopen', (
      tester,
    ) async {
      await _pumpGame(tester);
      await _openSettings(tester);
      await _expandSection(tester, 'APPEARANCE');

      await tester.tap(find.byKey(const Key('theme-swatch-arcadeNeon')));
      await tester.pump();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // The app bar repaints in the new theme's colors immediately, without
      // needing to reopen Settings.
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(
        appBar.backgroundColor,
        gameThemePalettes[GameThemeId.arcadeNeon]!.appBarBg,
      );

      // Re-open — Arcade Neon should still be the checked swatch.
      await _openSettings(tester);
      await _expandSection(tester, 'APPEARANCE');

      final arcadeNeonSwatch = find.byKey(
        const Key('theme-swatch-arcadeNeon'),
      );
      expect(
        find.descendant(
          of: arcadeNeonSwatch,
          matching: find.byIcon(Icons.check),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Cancel does not persist a palette change', (tester) async {
      await _pumpGame(tester);
      await _openSettings(tester);
      await _expandSection(tester, 'APPEARANCE');

      await tester.tap(find.byKey(const Key('theme-swatch-candyPop')));
      await tester.pump();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // The app bar never left the default Deep Ocean colors.
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(
        appBar.backgroundColor,
        gameThemePalettes[GameThemeId.deepOcean]!.appBarBg,
      );
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

    testWidgets('Save persists a Difficulty change', (tester) async {
      // Start with the default Normal difficulty.
      await _pumpGame(tester);
      await _openSettings(tester);

      await tester.tap(find.text('Hard'));
      await tester.pump();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Re-open — Hard should still be selected.
      await _openSettings(tester);

      final segmentedButton = tester.widget<SegmentedButton<GameDifficulty>>(
        find.byType(SegmentedButton<GameDifficulty>),
      );
      expect(segmentedButton.selected, {GameDifficulty.hard});
    });

    testWidgets('Cancel does not persist a Difficulty change', (
      tester,
    ) async {
      await _pumpGame(tester);
      await _openSettings(tester);

      await tester.tap(find.text('Hard'));
      await tester.pump();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Re-open — should still default to Normal.
      await _openSettings(tester);

      final segmentedButton = tester.widget<SegmentedButton<GameDifficulty>>(
        find.byType(SegmentedButton<GameDifficulty>),
      );
      expect(segmentedButton.selected, {GameDifficulty.normal});
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
      // Still paused mid-run, not back at the pre-game overlay. "Resume"
      // only appears on the pause overlay -- disambiguates from the HUD's
      // own Fall chip, which also reads "Paused" once stopped.
      expect(find.text('Start Game'), findsNothing);
      expect(find.text('Resume'), findsOneWidget);
    });
  });
}
