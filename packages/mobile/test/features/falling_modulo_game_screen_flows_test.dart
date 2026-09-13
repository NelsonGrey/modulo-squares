// Full-user-flow widget tests for FallingModuloGameScreen.
//
// This file is a behavior-preservation safety net ahead of a planned
// refactor that will split falling_modulo_game_screen.dart's HUD,
// settings dialog, purchase flow, and pause overlay into separate
// widgets. Every test here asserts *observable behavior* (displayed
// text, widget state) resulting from real user interaction, not just
// "does it build" — so a behavior change during the refactor should
// make one of these fail.
//
// falling_modulo_game_screen_test.dart and
// integration/game_screen_integration_test.dart already cover dialog
// structure, section visibility, and toggle persistence-via-reopen.
// This file intentionally does not duplicate those; it covers scoring
// paths (success/miss/dead-bucket/level-up), HUD updates driven by real
// drops, pause/resume state preservation, a live in-game effect of a
// settings change (not just reopening the dialog), and the purchase
// flow's success/cancelled/error branches.
//
// Movement (`_moveLeft`/`_moveRight`) is throttled by a wall-clock
// cooldown (`DateTime.now()`, not the fake test clock — see the
// pre-existing "expert demo" test in game_screen_integration_test.dart),
// but the very first move after a fresh widget is never throttled. Every
// scenario below that needs a specific lane uses at most one move, so
// none of this file depends on real time passing.
//
// Determinism is achieved via a `FallingModuloGameEngine` subclass that
// overrides the (public) `createInitialState` to return a fully
// scripted `FallingModuloGameState` — bucket layout, falling value, and
// fill balance are all controlled by each test. Every method used to
// resolve a drop after that (`resolveCurrentTile`, `moveLeft`,
// `moveRight`, `divisibleBucketIndexes`) is the real, un-mocked engine
// implementation.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:modulo_squares/core/di/service_locator.dart';
import 'package:modulo_squares/core/services/purchase_service.dart';
import 'package:modulo_squares/features/game/falling_modulo_game_screen.dart';
import 'package:modulo_squares/features/game/models/falling_modulo_game_engine.dart';
import 'package:modulo_squares/features/game/models/game_theme.dart';

import '../services/purchase_service_test.mocks.dart';

// ── Scripted engine ──────────────────────────────────────────────────────
//
// Returns a fixed, fully-known initial state instead of the production
// random one, so a test can assert exact scoring/HUD outcomes. Every
// other engine method (resolveCurrentTile, moveLeft/Right,
// divisibleBucketIndexes) is inherited unchanged from the real engine.

class _ScriptedEngine extends FallingModuloGameEngine {
  _ScriptedEngine(this._initial);

  final FallingModuloGameState _initial;

  @override
  FallingModuloGameState createInitialState({
    int startingLevel = 1,
    GameDifficulty difficulty = GameDifficulty.normal,
  }) => _initial;
}

FallingModuloGameState _scriptedState({
  required List<int> bucketValues,
  required int fallingValue,
  int currentLane = 5,
  int level = 1,
  int score = 0,
  int combo = 0,
  int fillBalance = 0,
}) {
  final range = FallingModuloGameEngine.numberRangeForLevel(level);
  return FallingModuloGameState(
    level: level,
    score: score,
    combo: combo,
    bucketValues: bucketValues,
    currentFallingValue: fallingValue,
    currentLane: currentLane,
    tilesResolvedInLevel: 0,
    targetTilesPerLevel: FallingModuloGameEngine.targetTilesForLevel(level),
    numberRangeMin: range.min,
    numberRangeMax: range.max,
    dropIntervalMs: FallingModuloGameEngine.dropIntervalForLevel(level),
    fillBalance: fillBalance,
    progressGridCellCount: 100,
  );
}

// ── Helpers ──────────────────────────────────────────────────────────────

const Size _phoneSize = Size(1080, 1920);

Future<void> _pumpScripted(
  WidgetTester tester,
  FallingModuloGameState initialState,
) async {
  tester.view.physicalSize = _phoneSize;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: FallingModuloGameScreen(engine: _ScriptedEngine(initialState)),
    ),
  );
  await tester.pump();
}

Future<void> _pumpApp(WidgetTester tester) async {
  tester.view.physicalSize = _phoneSize;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(const MaterialApp(home: FallingModuloGameScreen()));
  await tester.pump();
}

/// Starts the run and waits out the ~500ms per-tile spawn delay so the
/// Drop button becomes enabled, without ever crossing the (much longer)
/// drop-interval auto-resolve threshold.
Future<void> _startAndClearSpawnDelay(WidgetTester tester) async {
  await tester.tap(find.text('Start Game'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 550));
}

Future<void> _drop(WidgetTester tester) async {
  await tester.tap(find.text('Drop'));
  await tester.pump();
}

/// Flushes the score-burst label's own 700ms auto-clear timer so it can't
/// still be pending when the test ends (mirrors the same fix already used
/// by the pre-existing "expert demo" test in
/// game_screen_integration_test.dart).
Future<void> _settleBurstTimer(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 700));
}

Future<void> _openSettings(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Settings'));
  await tester.pumpAndSettle();
}

Future<void> _expandSection(WidgetTester tester, String header) async {
  await tester.tap(find.text(header));
  await tester.pumpAndSettle();
}

/// Reads the text of a keyed HUD value (see game_hud.dart's `Key`s) --
/// the HUD renders bare values inside icon chips/labels rather than
/// "Label: value" pills, so plain `find.text` would collide with other
/// on-screen numbers.
String _hudValue(WidgetTester tester, String key) {
  return tester.widget<Text>(find.byKey(Key(key))).data!;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    await getIt.reset();
  });

  // ── HUD updates from real drops ─────────────────────────────────────────

  group('HUD updates during a real play round', () {
    testWidgets(
      'a successful drop updates Score, Best, Fill and clears the spawn-delay '
      'state, and shows a positive score burst',
      (tester) async {
        // Lane 5 (center, the default) holds bucket value 9; falling value 18
        // is evenly divisible by it -> success, base scoreDelta = 18 * 9 =
        // 162. Bucket 9 is also 18's highest divisor, so the highest-bucket
        // bonus doubles it to 324 and fill progress is +2 instead of +1.
        final state = _scriptedState(
          bucketValues: const [2, 5, 0, 8, 3, 9, 1, 4, 6, 7],
          fallingValue: 18,
        );
        await _pumpScripted(tester, state);

        expect(_hudValue(tester, 'hud-score-value'), '0');
        expect(_hudValue(tester, 'hud-fall-value'), 'Paused');

        await _startAndClearSpawnDelay(tester);

        // Spawn delay has cleared: the configured drop interval for level 1
        // (6000ms) is now shown instead of "Ready..." or "Paused".
        expect(_hudValue(tester, 'hud-fall-value'), '6.00s');

        await _drop(tester);

        expect(_hudValue(tester, 'hud-score-value'), '324');
        expect(_hudValue(tester, 'hud-best-value'), '324');
        expect(_hudValue(tester, 'hud-combo-value'), '1');
        expect(_hudValue(tester, 'hud-fill-value'), '2 / 100');
        expect(find.text('★ +324 BONUS!'), findsOneWidget);

        await _settleBurstTimer(tester);
      },
    );

    testWidgets(
      'chaining 3 successful drops builds combo and raises the Move Speed '
      'multiplier shown in the HUD',
      (tester) async {
        // Lane 5 holds bucket value 1, which divides every falling value, so
        // every drop succeeds regardless of the (uncontrolled) random falling
        // value chosen for drops after the first.
        final state = _scriptedState(
          bucketValues: const [2, 3, 4, 5, 6, 1, 7, 8, 9, 0],
          fallingValue: 10,
        );
        await _pumpScripted(tester, state);
        await _startAndClearSpawnDelay(tester);

        expect(_hudValue(tester, 'hud-move-speed-value'), '1.00x');

        for (var i = 0; i < 3; i++) {
          await _drop(tester);
          if (i < 2) {
            // Wait out the next tile's spawn delay before the following drop.
            await tester.pump(const Duration(milliseconds: 550));
          }
        }

        expect(_hudValue(tester, 'hud-combo-value'), '3');
        expect(_hudValue(tester, 'hud-move-speed-value'), '1.10x');

        await _settleBurstTimer(tester);
      },
    );
  });

  // ── Distinct scoring paths ───────────────────────────────────────────────

  group('Miss and dead-bucket scoring paths', () {
    testWidgets(
      'a miss (wrong bucket, non-zero remainder) deducts points, resets '
      'combo, and creates a fill deficit',
      (tester) async {
        // Lane 5 holds bucket value 9; falling value 10 leaves remainder 1 ->
        // miss. scoreDelta = -(10 * 9 * 1) = -90, clamped to 0 since score
        // starts at 0.
        final state = _scriptedState(
          bucketValues: const [2, 5, 0, 8, 3, 9, 1, 4, 6, 7],
          fallingValue: 10,
          combo: 4,
        );
        await _pumpScripted(tester, state);
        await _startAndClearSpawnDelay(tester);

        expect(_hudValue(tester, 'hud-combo-value'), '4');

        await _drop(tester);

        expect(_hudValue(tester, 'hud-score-value'), '0');
        expect(_hudValue(tester, 'hud-best-value'), '0');
        expect(_hudValue(tester, 'hud-combo-value'), '0');
        expect(_hudValue(tester, 'hud-deficit-value'), '-1');
        expect(find.text('-90'), findsOneWidget);

        await _settleBurstTimer(tester);
      },
    );

    testWidgets(
      'landing in the Dead bucket deducts the full falling value outright '
      'and creates a fill deficit',
      (tester) async {
        // Lane 5 holds the dead bucket (value 0).
        final state = _scriptedState(
          bucketValues: const [1, 2, 3, 4, 5, 0, 6, 7, 8, 9],
          fallingValue: 15,
        );
        await _pumpScripted(tester, state);
        await _startAndClearSpawnDelay(tester);

        await _drop(tester);

        expect(_hudValue(tester, 'hud-score-value'), '0');
        expect(_hudValue(tester, 'hud-combo-value'), '0');
        expect(_hudValue(tester, 'hud-deficit-value'), '-1');
        // Dead-bucket burst text is the raw negative delta, distinct from a
        // wrong-bucket miss's remainder-scaled penalty.
        expect(find.text('-15'), findsOneWidget);

        await _settleBurstTimer(tester);
      },
    );
  });

  // ── Level-up transition ─────────────────────────────────────────────────

  group('Level-up transition', () {
    testWidgets(
      'filling the last square completes the level: HUD shows the new '
      'level, a completion snackbar appears, and the run auto-pauses',
      (tester) async {
        // Same success setup as the HUD test (lane 5 = bucket 9, falling
        // value 18) but starting one square short of completing the level.
        final state = _scriptedState(
          bucketValues: const [2, 5, 0, 8, 3, 9, 1, 4, 6, 7],
          fallingValue: 18,
          fillBalance: 99,
        );
        await _pumpScripted(tester, state);
        await _startAndClearSpawnDelay(tester);

        expect(_hudValue(tester, 'hud-level-value'), 'Level 1');
        expect(find.byTooltip('Pause'), findsOneWidget);

        await _drop(tester);

        expect(_hudValue(tester, 'hud-level-value'), 'Level 2');
        expect(find.text('Level 1 complete!'), findsOneWidget);
        // Levelling up auto-pauses the run: the Pause button is replaced by
        // the paused overlay, and the fill balance reset for the new level.
        expect(find.byTooltip('Pause'), findsNothing);
        // "Resume" only appears on the pause overlay itself -- disambiguates
        // from the HUD's own Fall chip, which also reads "Paused" once the
        // run stops.
        expect(find.text('Resume'), findsOneWidget);
        expect(_hudValue(tester, 'hud-fall-value'), 'Paused');
        expect(_hudValue(tester, 'hud-fill-value'), '0 / 100');

        await _settleBurstTimer(tester);
      },
    );
  });

  // ── Pause / resume state preservation ───────────────────────────────────

  group('Pause and resume preserve game state', () {
    testWidgets(
      'pausing freezes score, lane, and drop progress; resuming restores '
      'the run without losing any of it',
      (tester) async {
        // Lane 4 (one moveLeft from the default center lane 5) holds bucket
        // value 3; falling value 9 divides evenly -> success, scoreDelta =
        // 9 * 3 = 27.
        final state = _scriptedState(
          bucketValues: const [1, 2, 4, 5, 3, 6, 7, 8, 9, 0],
          fallingValue: 9,
        );
        await _pumpScripted(tester, state);

        await _startAndClearSpawnDelay(tester);
        // First move of a fresh widget is never cooldown-throttled.
        await tester.tap(find.text('Left'));
        await tester.pump();
        await _drop(tester);

        expect(_hudValue(tester, 'hud-score-value'), '27');

        // The lane-index label was removed from _buildBucket, so lane
        // selection is fingerprinted here by the selected bucket's value
        // label instead -- fine since bucketValues is fixed for this test
        // (no level-up occurs) and its values are unique, so a value
        // uniquely identifies which lane is selected. Lane 4 holds value 3.
        String selectedBucketValueLabel() {
          // Default theme is Deep Ocean (no fallingMode.theme pref set in
          // this test) -- its selected, non-dead bucket fill color.
          final selectedBucketColor =
              gameThemePalettes[GameThemeId.deepOcean]!.bucketSelectedBg;
          final selected = find.byWidgetPredicate(
            (w) =>
                w is Container &&
                w.decoration is BoxDecoration &&
                (w.decoration as BoxDecoration).color == selectedBucketColor,
          );
          expect(selected, findsOneWidget);
          final labels =
              tester
                  .widgetList<Text>(
                    find.descendant(of: selected, matching: find.byType(Text)),
                  )
                  .map((t) => t.data)
                  .whereType<String>()
                  .toList();
          return labels.single;
        }

        expect(selectedBucketValueLabel(), '3');

        final progressBefore =
            tester
                .widget<LinearProgressIndicator>(
                  find.byKey(const Key('drop-progress-indicator')),
                )
                .value;

        await tester.tap(find.byTooltip('Pause'));
        await tester.pump();

        // "Resume" only appears on the pause overlay -- disambiguates from
        // the HUD's own Fall chip, which also reads "Paused" once stopped.
        expect(find.text('Resume'), findsOneWidget);
        expect(_hudValue(tester, 'hud-fall-value'), 'Paused');
        expect(find.text('Level 1  ·  Score 27'), findsOneWidget);
        // HUD score stays visible and unchanged behind the pause overlay.
        expect(_hudValue(tester, 'hud-score-value'), '27');

        expect(
          tester
              .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Left'),
              )
              .onPressed,
          isNull,
        );
        expect(
          tester
              .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Right'),
              )
              .onPressed,
          isNull,
        );
        expect(
          tester
              .widget<FilledButton>(find.widgetWithText(FilledButton, 'Drop'))
              .onPressed,
          isNull,
        );

        // Advancing fake time while paused must not move the drop clock —
        // the periodic ticker bails out early whenever `_isRunning` is false.
        await tester.pump(const Duration(seconds: 5));
        final progressWhilePaused =
            tester
                .widget<LinearProgressIndicator>(
                  find.byKey(const Key('drop-progress-indicator')),
                )
                .value;
        expect(progressWhilePaused, progressBefore);

        await tester.tap(find.text('Resume'));
        await tester.pump();

        expect(find.text('Resume'), findsNothing);
        expect(_hudValue(tester, 'hud-score-value'), '27');
        expect(selectedBucketValueLabel(), '3');
        expect(
          tester
              .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Left'),
              )
              .onPressed,
          isNotNull,
        );
      },
    );
  });

  // ── Movement cooldown across drop cycles ────────────────────────────────

  group('Movement cooldown resets with each new tile', () {
    testWidgets(
      'a move right after a tile resolves succeeds immediately, not just '
      'the very first move of the whole run',
      (tester) async {
        // Regression test: _resetDropClock() zeroed _elapsed on every
        // resolve (success, miss, or manual Drop) but never cleared
        // _lastInputAtElapsed, so _canMoveNow()'s `_elapsed - last` went
        // negative the moment a new tile spawned -- silently blocking
        // movement until _elapsed climbed back past whatever (now stale)
        // value _lastInputAtElapsed held from the previous tile's cycle.
        // In practice this made Left/Right feel like they worked "only
        // sometimes".
        final state = _scriptedState(
          bucketValues: const [1, 2, 4, 5, 3, 6, 7, 8, 9, 0],
          fallingValue: 9,
        );
        await _pumpScripted(tester, state);
        await _startAndClearSpawnDelay(tester);

        String selectedBucketValueLabel() {
          final selectedBucketColor =
              gameThemePalettes[GameThemeId.deepOcean]!.bucketSelectedBg;
          final selected = find.byWidgetPredicate(
            (w) =>
                w is Container &&
                w.decoration is BoxDecoration &&
                (w.decoration as BoxDecoration).color == selectedBucketColor,
          );
          expect(selected, findsOneWidget);
          return tester
              .widgetList<Text>(
                find.descendant(of: selected, matching: find.byType(Text)),
              )
              .map((t) => t.data)
              .whereType<String>()
              .single;
        }

        // First move of a fresh widget is never cooldown-throttled: lane 5
        // (value 6) -> lane 6 (value 7).
        await tester.tap(find.text('Right'));
        await tester.pump();
        expect(selectedBucketValueLabel(), '7');

        // Resolving the current tile starts a brand-new drop cycle
        // (_resetDropClock). bucketValues don't reshuffle mid-level, so
        // lane 6 still reads '7' right after.
        await _drop(tester);
        expect(selectedBucketValueLabel(), '7');

        // The bug: this move landed well within the *old* cooldown window
        // relative to the stale _lastInputAtElapsed from the move above,
        // so it used to be silently dropped. Lane 6 (value 7) -> lane 7
        // (value 8).
        await tester.tap(find.text('Right'));
        await tester.pump();
        expect(selectedBucketValueLabel(), '8');

        await _settleBurstTimer(tester);
      },
    );
  });

  // ── Opening Settings/Leaderboard pauses the game ────────────────────────

  group('Opening Settings or Leaderboard pauses the game', () {
    // Regression: neither icon flipped _isRunning, so the drop timer,
    // deficit, and score kept advancing behind either screen while it was
    // open -- unlike the dedicated Pause button.
    testWidgets('opening Settings pauses a running game', (tester) async {
      final state = _scriptedState(
        bucketValues: const [1, 2, 4, 5, 3, 6, 7, 8, 9, 0],
        fallingValue: 9,
      );
      await _pumpScripted(tester, state);
      await _startAndClearSpawnDelay(tester);

      expect(_hudValue(tester, 'hud-fall-value'), isNot('Paused'));

      await _openSettings(tester);

      expect(_hudValue(tester, 'hud-fall-value'), 'Paused');
    });

    testWidgets('opening Leaderboard pauses a running game', (tester) async {
      tester.view.physicalSize = _phoneSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final state = _scriptedState(
        bucketValues: const [1, 2, 4, 5, 3, 6, 7, 8, 9, 0],
        fallingValue: 9,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: FallingModuloGameScreen(
            engine: _ScriptedEngine(state),
            // Stubbed out: the real LeaderboardScreen reaches Firestore in
            // a static field initializer with no guard, which is fine in
            // the real app (main.dart always initializes Firebase first)
            // but not in this Firebase-less widget test.
            leaderboardBuilder: (_) => const SizedBox.shrink(),
          ),
        ),
      );
      await tester.pump();
      await _startAndClearSpawnDelay(tester);

      expect(_hudValue(tester, 'hud-fall-value'), isNot('Paused'));

      // A single pump, not pumpAndSettle: _pauseForOverlay() runs
      // synchronously before the push's own transition even starts, but
      // once MaterialPageRoute's push transition fully settles the covered
      // game screen is no longer reachable by key -- check right after the
      // tap while it still is.
      await tester.tap(find.byTooltip('Leaderboard'));
      await tester.pump();

      expect(_hudValue(tester, 'hud-fall-value'), 'Paused');
    });
  });

  // ── Buckets never pre-hint the answer ────────────────────────────────────

  group('Buckets carry no pre-drop hint', () {
    testWidgets(
      'no bucket is highlighted for divisibility before a drop, even when '
      'only one bucket evenly divides the falling value',
      (tester) async {
        // Falling value 17 is prime and greater than every 1-9 bucket value,
        // so bucket value 1 (which divides everything) is the only bucket
        // that would divide it evenly -- the case most likely to leak a hint
        // if one existed. There must be no color or icon revealing that.
        final state = _scriptedState(
          bucketValues: const [2, 5, 0, 8, 3, 9, 1, 4, 6, 7],
          fallingValue: 17,
        );
        await _pumpScripted(tester, state);

        final greenBuckets = find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).color == Colors.green.shade100,
        );
        expect(greenBuckets, findsNothing);
      },
    );
  });

  // ── Purchase flow — remove ads ───────────────────────────────────────────

  group('Purchase flow — remove ads (product available)', () {
    late MockInAppPurchase mockInAppPurchase;
    late PurchaseService purchaseService;
    late StreamController<List<PurchaseDetails>> purchaseStreamController;

    setUp(() async {
      mockInAppPurchase = MockInAppPurchase();
      when(mockInAppPurchase.isAvailable()).thenAnswer((_) async => true);

      final mockProduct = MockProductDetails();
      when(mockProduct.id).thenReturn('remove_ads');
      when(mockProduct.title).thenReturn('Remove Ads');
      when(mockProduct.description).thenReturn('Remove ads from the game');
      when(mockProduct.price).thenReturn('\$2.99');
      when(mockInAppPurchase.queryProductDetails({'remove_ads'})).thenAnswer(
        (_) async => ProductDetailsResponse(
          productDetails: [mockProduct],
          notFoundIDs: [],
          error: null,
        ),
      );

      purchaseStreamController = StreamController<List<PurchaseDetails>>();
      when(
        mockInAppPurchase.purchaseStream,
      ).thenAnswer((_) => purchaseStreamController.stream);
      when(
        mockInAppPurchase.buyNonConsumable(
          purchaseParam: anyNamed('purchaseParam'),
        ),
      ).thenAnswer((_) async => true);

      purchaseService = PurchaseService(mockInAppPurchase);
      await purchaseService.initialize();
      getIt.registerSingleton<PurchaseService>(purchaseService);
    });

    tearDown(() async {
      await purchaseStreamController.close();
      purchaseService.dispose();
    });

    Future<void> tapUnlockPremium(WidgetTester tester) async {
      await _openSettings(tester);
      await _expandSection(tester, 'PURCHASES');
      await tester.tap(find.textContaining('Unlock Premium'));
      await tester.pump();
      await tester.pump();
    }

    testWidgets(
      'a completed purchase persists ad-removal and shows Ad-Free the next '
      'time Settings is opened',
      (tester) async {
        await _pumpApp(tester);
        await tapUnlockPremium(tester);

        // The store confirms the purchase asynchronously via the stream —
        // this is how a real successful StoreKit/Play Billing purchase
        // reaches the app.
        final mockPurchase = MockPurchaseDetails();
        when(mockPurchase.productID).thenReturn('remove_ads');
        when(mockPurchase.status).thenReturn(PurchaseStatus.purchased);
        when(mockPurchase.pendingCompletePurchase).thenReturn(true);
        when(mockPurchase.error).thenReturn(null);
        purchaseStreamController.add([mockPurchase]);
        await tester.pump();
        await tester.pump();

        // The dialog captured `adsRemoved` once, at open time -- close and
        // reopen it to prove the purchase actually persisted rather than
        // just checking the service's in-memory flag directly.
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        await _openSettings(tester);
        await _expandSection(tester, 'PURCHASES');

        expect(find.text('Ad-Free'), findsOneWidget);
        expect(find.textContaining('Unlock Premium'), findsNothing);
        expect(purchaseService.adsRemoved, isTrue);
      },
    );

    testWidgets(
      'a cancelled purchase leaves ad-removal entitlement unchanged',
      (tester) async {
        await _pumpApp(tester);
        await tapUnlockPremium(tester);

        final mockPurchase = MockPurchaseDetails();
        when(mockPurchase.productID).thenReturn('remove_ads');
        when(mockPurchase.status).thenReturn(PurchaseStatus.canceled);
        when(mockPurchase.pendingCompletePurchase).thenReturn(false);
        when(mockPurchase.error).thenReturn(null);
        purchaseStreamController.add([mockPurchase]);
        await tester.pump();
        await tester.pump();

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        await _openSettings(tester);
        await _expandSection(tester, 'PURCHASES');

        expect(find.text('Ads Enabled'), findsOneWidget);
        expect(find.textContaining('Unlock Premium'), findsOneWidget);
        expect(purchaseService.adsRemoved, isFalse);
      },
    );
  });

  group('Purchase flow — remove ads (product unavailable)', () {
    late MockInAppPurchase mockInAppPurchase;
    late PurchaseService purchaseService;
    late StreamController<List<PurchaseDetails>> purchaseStreamController;

    setUp(() async {
      mockInAppPurchase = MockInAppPurchase();
      when(mockInAppPurchase.isAvailable()).thenAnswer((_) async => true);
      when(mockInAppPurchase.queryProductDetails({'remove_ads'})).thenAnswer(
        (_) async => ProductDetailsResponse(
          productDetails: [],
          notFoundIDs: ['remove_ads'],
          error: null,
        ),
      );

      purchaseStreamController = StreamController<List<PurchaseDetails>>();
      when(
        mockInAppPurchase.purchaseStream,
      ).thenAnswer((_) => purchaseStreamController.stream);

      purchaseService = PurchaseService(mockInAppPurchase);
      await purchaseService.initialize();
      getIt.registerSingleton<PurchaseService>(purchaseService);
    });

    tearDown(() async {
      await purchaseStreamController.close();
      purchaseService.dispose();
    });

    testWidgets(
      'tapping Unlock Premium shows an error message when the store has no '
      'matching product, and leaves entitlement unchanged',
      (tester) async {
        await _pumpApp(tester);
        await _openSettings(tester);
        await _expandSection(tester, 'PURCHASES');

        await tester.tap(find.textContaining('Unlock Premium'));
        await tester.pump();
        await tester.pump();

        expect(
          find.text(
            'Unable to connect to the App Store. Please check your connection and try again.',
          ),
          findsOneWidget,
        );
        expect(purchaseService.adsRemoved, isFalse);
      },
    );
  });
}
