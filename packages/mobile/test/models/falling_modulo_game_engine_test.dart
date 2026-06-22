import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:modulo_squares/features/game/models/falling_modulo_game_engine.dart';

void main() {
  group('FallingModuloGameEngine', () {
    test(
      'initial state uses harder level 1 number range and randomized buckets',
      () {
        final engine = FallingModuloGameEngine(random: Random(1));
        final state = engine.createInitialState();

        expect(state.level, 1);
        expect(state.numberRangeMin, 6);
        expect(state.numberRangeMax, 18);
        expect(state.currentFallingValue, inInclusiveRange(6, 18));
        expect(
          state.bucketValues,
          unorderedEquals([0, 1, 2, 3, 4, 5, 6, 7, 8, 9]),
        );
        expect(state.progressGridCellCount, 100);
      },
    );

    test('success adds falling x bucket score', () {
      final engine = FallingModuloGameEngine(random: Random(2));
      final state = FallingModuloGameState(
        level: 1,
        score: 10,
        combo: 0,
        bucketValues: const [2, 3, 4, 5, 6, 7, 8, 9, 1],
        currentFallingValue: 12,
        currentLane: 0,
        tilesResolvedInLevel: 0,
        targetTilesPerLevel: FallingModuloGameEngine.targetTilesForLevel(1),
        numberRangeMin: 6,
        numberRangeMax: 18,
        dropIntervalMs: FallingModuloGameEngine.dropIntervalForLevel(1),
        visualCuesEnabled: true,
      );

      final result = engine.resolveCurrentTile(state);
      expect(result.resolution.success, true);
      expect(result.resolution.scoreDelta, 24);
      expect(result.state.score, 34);
      expect(result.state.combo, 1);
      expect(result.state.fillBalance, 1);
      expect(result.state.filledSquares, 1);
    });

    test('bucket value 1 adds zero score on success', () {
      final engine = FallingModuloGameEngine(random: Random(3));
      final state = FallingModuloGameState(
        level: 1,
        score: 50,
        combo: 2,
        bucketValues: const [1, 2, 3, 4, 5, 6, 7, 8, 9],
        currentFallingValue: 14,
        currentLane: 0,
        tilesResolvedInLevel: 0,
        targetTilesPerLevel: FallingModuloGameEngine.targetTilesForLevel(1),
        numberRangeMin: 6,
        numberRangeMax: 18,
        dropIntervalMs: FallingModuloGameEngine.dropIntervalForLevel(1),
        visualCuesEnabled: true,
      );

      final result = engine.resolveCurrentTile(state);
      expect(result.resolution.success, true);
      expect(result.resolution.scoreDelta, 0);
      expect(result.state.score, 50);
      expect(result.state.combo, 3);
    });

    test(
      'failure subtracts falling x bucket x remainder and clamps score to zero',
      () {
        final engine = FallingModuloGameEngine(random: Random(4));
        final state = FallingModuloGameState(
          level: 1,
          score: 15,
          combo: 4,
          bucketValues: const [8, 2, 3, 4, 5, 6, 7, 1, 9],
          currentFallingValue: 10,
          currentLane: 0,
          tilesResolvedInLevel: 0,
          targetTilesPerLevel: FallingModuloGameEngine.targetTilesForLevel(1),
          numberRangeMin: 6,
          numberRangeMax: 18,
          dropIntervalMs: FallingModuloGameEngine.dropIntervalForLevel(1),
          visualCuesEnabled: true,
        );

        // remainder = 10 % 8 = 2, penalty = 10 * 8 * 2 = 160
        final result = engine.resolveCurrentTile(state);
        expect(result.resolution.success, false);
        expect(result.resolution.remainder, 2);
        expect(result.resolution.scoreDelta, -160);
        expect(result.state.score, 0);
        expect(result.state.combo, 0);
        expect(result.state.fillBalance, -2);
        expect(result.state.deficitSquares, 2);
      },
    );

    test('combo maps to acceleration tiers', () {
      final baseState = FallingModuloGameState(
        level: 1,
        score: 0,
        combo: 0,
        bucketValues: const [1, 2, 3, 4, 5, 6, 7, 8, 9],
        currentFallingValue: 12,
        currentLane: 4,
        tilesResolvedInLevel: 0,
        targetTilesPerLevel: FallingModuloGameEngine.targetTilesForLevel(1),
        numberRangeMin: 6,
        numberRangeMax: 18,
        dropIntervalMs: FallingModuloGameEngine.dropIntervalForLevel(1),
        visualCuesEnabled: true,
      );

      expect(baseState.horizontalMoveSpeedMultiplier, 1.0);
      expect(baseState.copyWith(combo: 3).horizontalMoveSpeedMultiplier, 1.10);
      expect(baseState.copyWith(combo: 5).horizontalMoveSpeedMultiplier, 1.20);
      expect(baseState.copyWith(combo: 8).horizontalMoveSpeedMultiplier, 1.30);
    });

    test('visual cues can be toggled off', () {
      final engine = FallingModuloGameEngine(random: Random(5));
      final state = FallingModuloGameState(
        level: 1,
        score: 0,
        combo: 0,
        bucketValues: const [2, 3, 4, 5, 6, 7, 8, 9, 1],
        currentFallingValue: 12,
        currentLane: 4,
        tilesResolvedInLevel: 0,
        targetTilesPerLevel: FallingModuloGameEngine.targetTilesForLevel(1),
        numberRangeMin: 6,
        numberRangeMax: 18,
        dropIntervalMs: FallingModuloGameEngine.dropIntervalForLevel(1),
        visualCuesEnabled: true,
      );

      expect(engine.divisibleBucketIndexes(state), isNotEmpty);
      expect(
        engine.divisibleBucketIndexes(state.copyWith(visualCuesEnabled: false)),
        isEmpty,
      );
    });

    test(
      'level up rerolls buckets and increases range while reducing drop interval',
      () {
        final engine = FallingModuloGameEngine(random: Random(6));
        final initial = engine.createInitialState();

        final forcedPreLevelUp = initial.copyWith(
          fillBalance: initial.progressGridCellCount - 1,
          currentFallingValue: 12,
          currentLane: 0,
        );

        final result = engine.resolveCurrentTile(forcedPreLevelUp);

        expect(result.resolution.leveledUp, true);
        expect(result.state.level, 2);
        expect(result.state.fillBalance, 0);
        expect(result.state.filledSquares, 0);
        expect(result.state.numberRangeMin, 7);
        expect(result.state.numberRangeMax, 21);
        expect(
          result.state.dropIntervalMs,
          lessThan(FallingModuloGameEngine.dropIntervalForLevel(1)),
        );
        expect(
          result.state.bucketValues,
          unorderedEquals([0, 1, 2, 3, 4, 5, 6, 7, 8, 9]),
        );
        expect(result.state.bucketValues, isNot(equals(initial.bucketValues)));
      },
    );

    test('failure removes remainder worth of filled squares into deficit', () {
      final engine = FallingModuloGameEngine(random: Random(13));
      final state = FallingModuloGameState(
        level: 1,
        score: 100,
        combo: 2,
        bucketValues: const [6, 2, 3, 4, 5, 7, 8, 9, 1],
        currentFallingValue: 10, // remainder 4 against bucket 6
        currentLane: 0,
        tilesResolvedInLevel: 0,
        targetTilesPerLevel: FallingModuloGameEngine.targetTilesForLevel(1),
        numberRangeMin: 6,
        numberRangeMax: 18,
        dropIntervalMs: FallingModuloGameEngine.dropIntervalForLevel(1),
        visualCuesEnabled: true,
        fillBalance: 2,
      );

      final result = engine.resolveCurrentTile(state);
      expect(result.resolution.success, isFalse);
      expect(result.resolution.remainder, 4);
      expect(result.state.fillBalance, -2);
      expect(result.state.filledSquares, 0);
      expect(result.state.deficitSquares, 2);
    });

    group('dropIntervalForLevel', () {
      test('level 1 returns 6000ms baseline', () {
        expect(FallingModuloGameEngine.dropIntervalForLevel(1), 6000);
      });

      test('level 2 returns 5760ms (6000 * 0.96)', () {
        expect(FallingModuloGameEngine.dropIntervalForLevel(2), 5760);
      });

      test('level 10 returns 4155ms', () {
        expect(FallingModuloGameEngine.dropIntervalForLevel(10), 4155);
      });

      test('interval strictly decreases from level 1 to level 20', () {
        for (var level = 2; level <= 20; level++) {
          expect(
            FallingModuloGameEngine.dropIntervalForLevel(level),
            lessThan(FallingModuloGameEngine.dropIntervalForLevel(level - 1)),
            reason: 'Level $level should be faster than level ${level - 1}',
          );
        }
      });

      test('interval floors at 1200ms once scaling reaches the minimum', () {
        expect(FallingModuloGameEngine.dropIntervalForLevel(40), 1221);
        expect(FallingModuloGameEngine.dropIntervalForLevel(41), 1200);
        expect(FallingModuloGameEngine.dropIntervalForLevel(80), 1200);
      });

      test('clamped level < 1 treated as level 1', () {
        expect(
          FallingModuloGameEngine.dropIntervalForLevel(0),
          equals(FallingModuloGameEngine.dropIntervalForLevel(1)),
        );
        expect(
          FallingModuloGameEngine.dropIntervalForLevel(-5),
          equals(FallingModuloGameEngine.dropIntervalForLevel(1)),
        );
      });
    });

    group('score burst text format', () {
      test('success score delta is prefixed with +', () {
        // Verify the engine produces a positive scoreDelta on success so the
        // screen's '+$scoreDelta' format always shows a + prefix.
        final engine = FallingModuloGameEngine(random: Random(10));
        final state = FallingModuloGameState(
          level: 1,
          score: 0,
          combo: 0,
          bucketValues: const [3, 2, 4, 5, 6, 7, 8, 9, 1],
          currentFallingValue: 12,
          currentLane: 0, // bucket value 3, 12 % 3 == 0
          tilesResolvedInLevel: 0,
          targetTilesPerLevel: FallingModuloGameEngine.targetTilesForLevel(1),
          numberRangeMin: 6,
          numberRangeMax: 18,
          dropIntervalMs: FallingModuloGameEngine.dropIntervalForLevel(1),
          visualCuesEnabled: true,
        );
        final result = engine.resolveCurrentTile(state);
        expect(result.resolution.success, isTrue);
        expect(result.resolution.scoreDelta, greaterThan(0));
        final burstText = '+${result.resolution.scoreDelta}';
        expect(burstText, startsWith('+'));
      });

      test('failure score delta is negative, displayed without prefix', () {
        final engine = FallingModuloGameEngine(random: Random(11));
        final state = FallingModuloGameState(
          level: 1,
          score: 500,
          combo: 0,
          bucketValues: const [7, 2, 3, 4, 5, 6, 8, 9, 1],
          currentFallingValue: 11, // 11 % 7 = 4, failure
          currentLane: 0,
          tilesResolvedInLevel: 0,
          targetTilesPerLevel: FallingModuloGameEngine.targetTilesForLevel(1),
          numberRangeMin: 6,
          numberRangeMax: 18,
          dropIntervalMs: FallingModuloGameEngine.dropIntervalForLevel(1),
          visualCuesEnabled: true,
        );
        final result = engine.resolveCurrentTile(state);
        expect(result.resolution.success, isFalse);
        expect(result.resolution.scoreDelta, lessThan(0));
        final burstText = '${result.resolution.scoreDelta}';
        expect(burstText, startsWith('-'));
      });

      test('bucket value 1 success yields zero scoreDelta', () {
        final engine = FallingModuloGameEngine(random: Random(12));
        final state = FallingModuloGameState(
          level: 1,
          score: 100,
          combo: 0,
          bucketValues: const [1, 2, 3, 4, 5, 6, 7, 8, 9],
          currentFallingValue: 15,
          currentLane: 0, // bucket 1, always success with delta 0
          tilesResolvedInLevel: 0,
          targetTilesPerLevel: FallingModuloGameEngine.targetTilesForLevel(1),
          numberRangeMin: 6,
          numberRangeMax: 18,
          dropIntervalMs: FallingModuloGameEngine.dropIntervalForLevel(1),
          visualCuesEnabled: true,
        );
        final result = engine.resolveCurrentTile(state);
        expect(result.resolution.success, isTrue);
        expect(result.resolution.scoreDelta, 0);
        expect('+${result.resolution.scoreDelta}', '+0');
      });
    });

    group('targetTilesForLevel', () {
      test('level 1 requires 12 tiles', () {
        expect(FallingModuloGameEngine.targetTilesForLevel(1), 12);
      });

      test('increases by 2 each level', () {
        expect(FallingModuloGameEngine.targetTilesForLevel(2), 14);
        expect(FallingModuloGameEngine.targetTilesForLevel(3), 16);
        expect(FallingModuloGameEngine.targetTilesForLevel(5), 20);
      });
    });
  });
}
