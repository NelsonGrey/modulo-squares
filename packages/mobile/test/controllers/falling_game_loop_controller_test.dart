// Plain-Dart unit tests for FallingGameLoopController -- no widget pumping,
// no BuildContext, no button-finding. This is the whole point of pulling the
// game loop out of FallingModuloGameScreen's State: the movement-cooldown
// regression below used to require driving a full widget tree through
// fake-cleared spawn delays and tapping buttons by text to reproduce; here
// it's a dozen lines that call controller methods directly and assert on
// state.

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modulo_squares/features/game/controllers/falling_game_loop_controller.dart';
import 'package:modulo_squares/features/game/models/falling_modulo_game_engine.dart';

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
  GameDifficulty difficulty = GameDifficulty.normal,
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
    dropIntervalMs: FallingModuloGameEngine.dropIntervalForLevel(
      level,
      difficulty: difficulty,
    ),
    fillBalance: fillBalance,
    progressGridCellCount: 100,
    difficulty: difficulty,
  );
}

void main() {
  group('construction', () {
    test('starts stopped, with the engine\'s initial state', () {
      final state = _scriptedState(
        bucketValues: const [1, 2, 4, 5, 3, 6, 7, 8, 9, 0],
        fallingValue: 9,
      );
      final controller = FallingGameLoopController(
        engine: _ScriptedEngine(state),
      );
      addTearDown(controller.dispose);

      expect(controller.isRunning, isFalse);
      expect(controller.hasStarted, isFalse);
      expect(controller.state, same(state));
      expect(controller.highScore, 0);
    });

    test('takes an initial high score and difficulty', () {
      final state = _scriptedState(
        bucketValues: const [1, 2, 4, 5, 3, 6, 7, 8, 9, 0],
        fallingValue: 9,
        difficulty: GameDifficulty.hard,
      );
      final controller = FallingGameLoopController(
        engine: _ScriptedEngine(state),
        initialHighScore: 401,
        initialDifficulty: GameDifficulty.hard,
      );
      addTearDown(controller.dispose);

      expect(controller.highScore, 401);
      expect(controller.state.difficulty, GameDifficulty.hard);
    });
  });

  group('toggleRunning / pause', () {
    test('toggleRunning flips isRunning and latches hasStarted on', () {
      final state = _scriptedState(
        bucketValues: const [1, 2, 4, 5, 3, 6, 7, 8, 9, 0],
        fallingValue: 9,
      );
      final controller = FallingGameLoopController(
        engine: _ScriptedEngine(state),
      );
      addTearDown(controller.dispose);

      controller.toggleRunning();
      expect(controller.isRunning, isTrue);
      expect(controller.hasStarted, isTrue);

      controller.toggleRunning();
      expect(controller.isRunning, isFalse);
      // hasStarted never un-latches -- that's what distinguishes the
      // pre-game overlay from the paused overlay.
      expect(controller.hasStarted, isTrue);
    });

    test('pause() is a no-op when not running', () {
      final state = _scriptedState(
        bucketValues: const [1, 2, 4, 5, 3, 6, 7, 8, 9, 0],
        fallingValue: 9,
      );
      final controller = FallingGameLoopController(
        engine: _ScriptedEngine(state),
      );
      addTearDown(controller.dispose);

      var notified = false;
      controller.addListener(() => notified = true);
      controller.pause();

      expect(controller.isRunning, isFalse);
      expect(notified, isFalse);
    });

    test('pause() stops a running game and freezes the drop clock', () {
      fakeAsync((async) {
        final state = _scriptedState(
          bucketValues: const [1, 2, 4, 5, 3, 6, 7, 8, 9, 0],
          fallingValue: 9,
        );
        final controller = FallingGameLoopController(
          engine: _ScriptedEngine(state),
        );
        addTearDown(controller.dispose);

        controller.toggleRunning();
        async.elapse(const Duration(milliseconds: 600));
        final progressBeforePause = controller.dropProgress;

        controller.pause();
        async.elapse(const Duration(seconds: 5));

        expect(controller.isRunning, isFalse);
        expect(controller.dropProgress, progressBeforePause);
      });
    });
  });

  group('movement cooldown resets with each new drop cycle', () {
    test(
      'a move right after a tile resolves succeeds immediately, not just '
      'the very first move of the whole run',
      () {
        // Regression test: _resetDropClock() zeroed the elapsed drop clock
        // on every resolve but didn't clear the last-accepted-move snapshot
        // alongside it, so the cooldown check went negative the moment a new
        // tile spawned -- silently blocking movement until the elapsed clock
        // climbed back past a now-stale value from the *previous* tile's
        // cycle. In practice this made Left/Right feel like they only
        // worked "sometimes". Unlike the widget-level version of this test,
        // there's no button-finding or color-matching here -- just the
        // controller's own state.
        fakeAsync((async) {
          final state = _scriptedState(
            bucketValues: const [1, 2, 4, 5, 3, 6, 7, 8, 9, 0],
            fallingValue: 9,
          );
          final controller = FallingGameLoopController(
            engine: _ScriptedEngine(state),
          );
          addTearDown(controller.dispose);

          controller.toggleRunning();
          // Clear the 500ms spawn delay so the elapsed drop clock starts
          // advancing, matching a real player's first input timing.
          async.elapse(const Duration(milliseconds: 550));

          // First move of a fresh controller is never cooldown-throttled:
          // lane 5 -> lane 6.
          controller.moveRight();
          expect(controller.state.currentLane, 6);

          // Resolving starts a brand-new drop cycle (elapsed resets to
          // zero). bucketValues don't reshuffle mid-level, so the lane
          // itself doesn't move from this alone.
          controller.resolveCurrentTile();
          expect(controller.state.currentLane, 6);

          // The bug: this landed well within the *old* cooldown window
          // relative to the stale last-move snapshot from the move above,
          // so it used to be silently dropped. Lane 6 -> lane 7.
          controller.moveRight();
          expect(controller.state.currentLane, 7);
        });
      },
    );

    test(
      'moving twice within the cooldown window inside the same drop cycle '
      'is still throttled -- the fix only resets the reference point, it '
      "doesn't remove the cooldown",
      () {
        fakeAsync((async) {
          final state = _scriptedState(
            bucketValues: const [1, 2, 4, 5, 3, 6, 7, 8, 9, 0],
            fallingValue: 9,
          );
          final controller = FallingGameLoopController(
            engine: _ScriptedEngine(state),
          );
          addTearDown(controller.dispose);

          controller.toggleRunning();
          async.elapse(const Duration(milliseconds: 550));

          controller.moveRight();
          expect(controller.state.currentLane, 6);

          // Immediately again, no time elapsed: still within the ~150-180ms
          // cooldown for the default (1.0x) move speed.
          controller.moveRight();
          expect(controller.state.currentLane, 6);

          // Past the cooldown, same drop cycle: now it goes through.
          async.elapse(const Duration(milliseconds: 200));
          controller.moveRight();
          expect(controller.state.currentLane, 7);
        });
      },
    );
  });

  group('resolveCurrentTile', () {
    test('updates score/combo and reports the outcome via onTileResolved', () {
      // Lane 5 (default) holds bucket value 6; falling value 18 is evenly
      // divisible by it (18 % 6 == 0) -> success, scoreDelta = 18 * 6 = 108.
      final state = _scriptedState(
        bucketValues: const [1, 2, 4, 5, 3, 6, 7, 8, 9, 0],
        fallingValue: 18,
      );
      TileResolutionOutcome? seen;
      final controller = FallingGameLoopController(
        engine: _ScriptedEngine(state),
        onTileResolved: (outcome) => seen = outcome,
      );
      addTearDown(controller.dispose);

      controller.resolveCurrentTile();

      expect(controller.state.score, 108);
      expect(controller.state.combo, 1);
      expect(controller.highScore, 108);
      expect(seen, isNotNull);
      expect(seen!.isNewHighScore, isTrue);
      expect(seen!.result.resolution.success, isTrue);
    });

    test('does not report a new high score when the run is below it', () {
      final state = _scriptedState(
        bucketValues: const [1, 2, 4, 5, 3, 6, 7, 8, 9, 0],
        fallingValue: 18,
      );
      TileResolutionOutcome? seen;
      final controller = FallingGameLoopController(
        engine: _ScriptedEngine(state),
        initialHighScore: 5000,
        onTileResolved: (outcome) => seen = outcome,
      );
      addTearDown(controller.dispose);

      controller.resolveCurrentTile();

      expect(controller.highScore, 5000);
      expect(seen!.isNewHighScore, isFalse);
    });

    test('sets a burst label that clears itself after ~700ms', () {
      fakeAsync((async) {
        final state = _scriptedState(
          bucketValues: const [1, 2, 4, 5, 3, 6, 7, 8, 9, 0],
          fallingValue: 18,
        );
        final controller = FallingGameLoopController(
          engine: _ScriptedEngine(state),
        );
        addTearDown(controller.dispose);

        controller.resolveCurrentTile();
        expect(controller.resultBurstText, isNotNull);

        async.elapse(const Duration(milliseconds: 750));
        expect(controller.resultBurstText, isNull);
      });
    });

    test('leveling up stops the run', () {
      // fillBalance one short of the 100-cell target; falling value 18 into
      // bucket value 6 (lane 5) succeeds for +1 fill (not the highest
      // divisor, so no bonus double), completing the level.
      final state = _scriptedState(
        bucketValues: const [1, 2, 4, 5, 3, 6, 7, 8, 9, 0],
        fallingValue: 18,
        fillBalance: 99,
      );
      final controller = FallingGameLoopController(
        engine: _ScriptedEngine(state),
      );
      addTearDown(controller.dispose);
      controller.toggleRunning();

      controller.resolveCurrentTile();

      expect(controller.state.level, 2);
      expect(controller.isRunning, isFalse);
    });
  });

  group('startNewRun', () {
    test('resets state, run flags, and the drop clock', () {
      fakeAsync((async) {
        final state = _scriptedState(
          bucketValues: const [1, 2, 4, 5, 3, 6, 7, 8, 9, 0],
          fallingValue: 18,
        );
        final controller = FallingGameLoopController(
          engine: _ScriptedEngine(state),
        );
        addTearDown(controller.dispose);

        controller.toggleRunning();
        async.elapse(const Duration(milliseconds: 600));
        controller.resolveCurrentTile();

        controller.startNewRun();

        expect(controller.isRunning, isFalse);
        expect(controller.hasStarted, isFalse);
        expect(controller.resultBurstText, isNull);
        expect(controller.dropProgress, 0.0);
        // A fresh run's first move should never be cooldown-throttled --
        // confirms _lastInputAtElapsed was cleared too.
        controller.moveRight();
        expect(controller.state.currentLane, 6);
      });
    });
  });

  group('setDifficulty', () {
    test('updates both difficulty and the drop interval it drives', () {
      final state = _scriptedState(
        bucketValues: const [1, 2, 4, 5, 3, 6, 7, 8, 9, 0],
        fallingValue: 9,
      );
      final controller = FallingGameLoopController(
        engine: _ScriptedEngine(state),
      );
      addTearDown(controller.dispose);

      controller.setDifficulty(GameDifficulty.hard);

      expect(controller.state.difficulty, GameDifficulty.hard);
      expect(
        controller.state.dropIntervalMs,
        FallingModuloGameEngine.dropIntervalForLevel(
          controller.state.level,
          difficulty: GameDifficulty.hard,
        ),
      );
    });
  });

  group('resetHighScore', () {
    test('zeroes the high score', () {
      final state = _scriptedState(
        bucketValues: const [1, 2, 4, 5, 3, 6, 7, 8, 9, 0],
        fallingValue: 9,
      );
      final controller = FallingGameLoopController(
        engine: _ScriptedEngine(state),
        initialHighScore: 401,
      );
      addTearDown(controller.dispose);

      controller.resetHighScore();

      expect(controller.highScore, 0);
    });
  });
}
