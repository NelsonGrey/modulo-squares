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
    bool visualCuesEnabled = true,
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
    visualCuesEnabled: true,
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
        // is evenly divisible by it -> success, scoreDelta = 18 * 9 = 162.
        final state = _scriptedState(
          bucketValues: const [2, 5, 0, 8, 3, 9, 1, 4, 6, 7],
          fallingValue: 18,
        );
        await _pumpScripted(tester, state);

        expect(find.text('Score: 0'), findsOneWidget);
        expect(find.text('Fall: Paused'), findsOneWidget);

        await _startAndClearSpawnDelay(tester);

        // Spawn delay has cleared: the configured drop interval for level 1
        // (6000ms) is now shown instead of "Ready..." or "Paused".
        expect(find.text('Fall: 6.00s'), findsOneWidget);

        await _drop(tester);

        expect(find.text('Score: 162'), findsOneWidget);
        expect(find.text('Best: 162'), findsOneWidget);
        expect(find.text('Combo: 1'), findsOneWidget);
        expect(find.text('Fill: 1/100'), findsOneWidget);
        expect(find.text('+162'), findsOneWidget);

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

        expect(find.text('Move Speed: 1.00x'), findsOneWidget);

        for (var i = 0; i < 3; i++) {
          await _drop(tester);
          if (i < 2) {
            // Wait out the next tile's spawn delay before the following drop.
            await tester.pump(const Duration(milliseconds: 550));
          }
        }

        expect(find.text('Combo: 3'), findsOneWidget);
        expect(find.text('Move Speed: 1.10x'), findsOneWidget);

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

        expect(find.text('Combo: 4'), findsOneWidget);

        await _drop(tester);

        expect(find.text('Score: 0'), findsOneWidget);
        expect(find.text('Best: 0'), findsOneWidget);
        expect(find.text('Combo: 0'), findsOneWidget);
        expect(find.text('Deficit: -1'), findsOneWidget);
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

        expect(find.text('Score: 0'), findsOneWidget);
        expect(find.text('Combo: 0'), findsOneWidget);
        expect(find.text('Deficit: -1'), findsOneWidget);
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

        expect(find.text('Level: 1'), findsOneWidget);
        expect(find.byTooltip('Pause'), findsOneWidget);

        await _drop(tester);

        expect(find.text('Level: 2'), findsOneWidget);
        expect(find.text('Level 1 complete!'), findsOneWidget);
        // Levelling up auto-pauses the run: the Pause button is replaced by
        // the paused overlay, and the fill balance reset for the new level.
        expect(find.byTooltip('Pause'), findsNothing);
        expect(find.text('Paused'), findsOneWidget);
        expect(find.text('Fill: 0/100'), findsOneWidget);

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
        // Visual cues off so a bucket's "selected" highlight color is
        // unambiguous (with cues on, a divisible-hint match could also turn
        // the selected bucket green, depending on the next random falling
        // value once one exists).
        SharedPreferences.setMockInitialValues({
          'fallingMode.visualCuesEnabled': false,
        });

        // Lane 4 (one moveLeft from the default center lane 5) holds bucket
        // value 3; falling value 9 divides evenly -> success, scoreDelta =
        // 9 * 3 = 27.
        final state = _scriptedState(
          bucketValues: const [1, 2, 4, 5, 3, 6, 7, 8, 9, 0],
          fallingValue: 9,
        );
        await _pumpScripted(tester, state);
        await tester.pump(); // let the visualCuesEnabled=false prefs load land

        await _startAndClearSpawnDelay(tester);
        // First move of a fresh widget is never cooldown-throttled.
        await tester.tap(find.text('Left'));
        await tester.pump();
        await _drop(tester);

        expect(find.text('Score: 27'), findsOneWidget);

        String selectedLaneLabel() {
          final selected = find.byWidgetPredicate(
            (w) =>
                w is Container &&
                w.decoration is BoxDecoration &&
                (w.decoration as BoxDecoration).color == Colors.orange.shade200,
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
          // _buildBucket renders the value label then the index label.
          return labels.last;
        }

        expect(selectedLaneLabel(), '4');

        final progressBefore =
            tester
                .widget<LinearProgressIndicator>(
                  find.byType(LinearProgressIndicator),
                )
                .value;

        await tester.tap(find.byTooltip('Pause'));
        await tester.pump();

        expect(find.text('Paused'), findsOneWidget);
        expect(find.text('Level 1  ·  Score 27'), findsOneWidget);
        // HUD score stays visible and unchanged behind the pause overlay.
        expect(find.text('Score: 27'), findsOneWidget);

        expect(
          tester
              .widget<ElevatedButton>(
                find.widgetWithText(ElevatedButton, 'Left'),
              )
              .onPressed,
          isNull,
        );
        expect(
          tester
              .widget<ElevatedButton>(
                find.widgetWithText(ElevatedButton, 'Right'),
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
                  find.byType(LinearProgressIndicator),
                )
                .value;
        expect(progressWhilePaused, progressBefore);

        await tester.tap(find.text('Resume'));
        await tester.pump();

        expect(find.text('Paused'), findsNothing);
        expect(find.text('Score: 27'), findsOneWidget);
        expect(selectedLaneLabel(), '4');
        expect(
          tester
              .widget<ElevatedButton>(
                find.widgetWithText(ElevatedButton, 'Left'),
              )
              .onPressed,
          isNotNull,
        );
      },
    );
  });

  // ── Settings — a change taking live effect on the board ─────────────────

  group('Settings dialog changes the live board, not just the dialog', () {
    testWidgets(
      'turning off Visual Cues in Settings removes the divisible-bucket '
      'highlight from the game board itself',
      (tester) async {
        // Falling value 17 is prime and greater than every 1-9 bucket value,
        // so bucket value 1 (which divides everything) is the *only*
        // divisible-hint lane -- exactly one green-highlighted bucket.
        final state = _scriptedState(
          bucketValues: const [2, 5, 0, 8, 3, 9, 1, 4, 6, 7],
          fallingValue: 17,
        );
        await _pumpScripted(tester, state);

        Finder greenBuckets() => find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).color == Colors.green.shade100,
        );

        expect(greenBuckets(), findsOneWidget);

        await _openSettings(tester);
        await tester.tap(find.byType(Switch)); // Visual Cues switch, ON -> OFF
        await tester.pump();
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(greenBuckets(), findsNothing);
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
