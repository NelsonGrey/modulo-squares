import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modulo_squares/features/game/falling_modulo_game_screen.dart';
import 'package:modulo_squares/features/game/models/falling_modulo_game_engine.dart';
import 'package:modulo_squares/gamecenter/fake_game_center_progress_service.dart';
import 'package:modulo_squares/gamecenter/fake_platform_game_auth_service.dart';
import 'package:modulo_squares/gamecenter/game_center_connection.dart';
import 'package:modulo_squares/gamecenter/game_center_services.dart';
import 'package:modulo_squares/review/app_review_prompt.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeReviewRequester implements AppReviewRequester {
  int requests = 0;

  @override
  Future<void> requestReview() async => requests++;
}

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
  required int fillBalance,
  int score = 0,
}) {
  const level = 1;
  final range = FallingModuloGameEngine.numberRangeForLevel(level);
  return FallingModuloGameState(
    level: level,
    score: score,
    combo: 0,
    // Lane 5 is bucket 9, the highest divisor of 18, so Drop is a bonus catch.
    bucketValues: const [2, 5, 0, 8, 3, 9, 1, 4, 6, 7],
    currentFallingValue: 18,
    currentLane: 5,
    tilesResolvedInLevel: 0,
    targetTilesPerLevel: FallingModuloGameEngine.targetTilesForLevel(level),
    numberRangeMin: range.min,
    numberRangeMax: range.max,
    dropIntervalMs: FallingModuloGameEngine.dropIntervalForLevel(level),
    fillBalance: fillBalance,
    progressGridCellCount: 100,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const phone = Size(1080, 1920);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<
    ({_FakeReviewRequester requester, FakeGameCenterProgressService progress})
  >
  pumpGame(
    WidgetTester tester, {
    required FallingModuloGameState state,
    required bool gameCenterSupported,
    Map<String, Object> preferences = const <String, Object>{},
  }) async {
    SharedPreferences.setMockInitialValues(preferences);
    final prefs = await SharedPreferences.getInstance();
    final requester = _FakeReviewRequester();
    final progress = FakeGameCenterProgressService();
    tester.view.physicalSize = phone;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: FallingModuloGameScreen(
          engine: _ScriptedEngine(state),
          gameCenter: GameCenterServices(
            auth: FakePlatformGameAuthService(),
            backend: progress,
            connection:
                gameCenterSupported
                    ? GameCenterConnection.connectedFake()
                    : GameCenterConnection.unsupportedFake(),
          ),
          reviewPrompt: AppReviewPrompt(
            requester: requester,
            preferences: prefs,
          ),
        ),
      ),
    );
    await tester.pump();
    return (requester: requester, progress: progress);
  }

  Future<void> startAndDrop(WidgetTester tester) async {
    await tester.tap(find.text('Start Game'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 550));
    await tester.tap(find.text('Drop'));
    await tester.pump();
  }

  testWidgets('time passing on the title screen does not ask for a review', (
    tester,
  ) async {
    final harness = await pumpGame(
      tester,
      state: _scriptedState(fillBalance: 0),
      gameCenterSupported: false,
      preferences: const <String, Object>{'fallingMode.highScore': 900},
    );

    await tester.pump(const Duration(seconds: 3));

    expect(harness.requester.requests, 0);
  });

  testWidgets('a new best mid-level does not ask until the level breaks', (
    tester,
  ) async {
    final harness = await pumpGame(
      tester,
      state: _scriptedState(fillBalance: 0),
      gameCenterSupported: true,
      preferences: const <String, Object>{'fallingMode.highScore': 10},
    );

    await startAndDrop(tester);

    expect(harness.requester.requests, 0);
    expect(find.text('Level 1 complete!'), findsNothing);
  });

  testWidgets('level complete asks even when Game Center is unavailable', (
    tester,
  ) async {
    final harness = await pumpGame(
      tester,
      state: _scriptedState(fillBalance: 99),
      gameCenterSupported: false,
    );

    await startAndDrop(tester);

    expect(find.text('Level 1 complete!'), findsOneWidget);
    expect(harness.requester.requests, 1);
    expect(harness.progress.unlocked, isEmpty);
    expect(harness.progress.scores, isEmpty);
  });

  testWidgets('a recent request suppresses the next level complete', (
    tester,
  ) async {
    final harness = await pumpGame(
      tester,
      state: _scriptedState(fillBalance: 99),
      gameCenterSupported: false,
      preferences: <String, Object>{
        AppReviewPrompt.lastRequestMillisKey:
            DateTime.now().millisecondsSinceEpoch,
      },
    );

    await startAndDrop(tester);

    expect(find.text('Level 1 complete!'), findsOneWidget);
    expect(harness.requester.requests, 0);
  });
}
