import 'dart:math';

class FallingModuloResolution {
  final bool success;
  final int fallingValue;
  final int bucketValue;
  final int remainder;
  final int scoreDelta;
  final int scoreAfter;
  final int comboAfter;
  final bool leveledUp;

  const FallingModuloResolution({
    required this.success,
    required this.fallingValue,
    required this.bucketValue,
    required this.remainder,
    required this.scoreDelta,
    required this.scoreAfter,
    required this.comboAfter,
    required this.leveledUp,
  });
}

class FallingModuloResolveResult {
  final FallingModuloGameState state;
  final FallingModuloResolution resolution;

  const FallingModuloResolveResult({
    required this.state,
    required this.resolution,
  });
}

class FallingModuloGameState {
  final int level;
  final int score;
  final int combo;
  final List<int> bucketValues;
  final int currentFallingValue;
  final int currentLane;
  final int tilesResolvedInLevel;
  final int targetTilesPerLevel;
  final int numberRangeMin;
  final int numberRangeMax;
  final int dropIntervalMs;
  final bool visualCuesEnabled;
  final int fillBalance;
  final int progressGridCellCount;

  const FallingModuloGameState({
    required this.level,
    required this.score,
    required this.combo,
    required this.bucketValues,
    required this.currentFallingValue,
    required this.currentLane,
    required this.tilesResolvedInLevel,
    required this.targetTilesPerLevel,
    required this.numberRangeMin,
    required this.numberRangeMax,
    required this.dropIntervalMs,
    required this.visualCuesEnabled,
    this.fillBalance = 0,
    this.progressGridCellCount = 100,
  });

  int get filledSquares {
    if (fillBalance <= 0) return 0;
    if (fillBalance >= progressGridCellCount) return progressGridCellCount;
    return fillBalance;
  }

  int get deficitSquares => fillBalance < 0 ? -fillBalance : 0;

  double get horizontalMoveSpeedMultiplier {
    if (combo >= 8) return 1.30;
    if (combo >= 5) return 1.20;
    if (combo >= 3) return 1.10;
    return 1.0;
  }

  static const Object _unset = Object();

  FallingModuloGameState copyWith({
    int? level,
    int? score,
    int? combo,
    List<int>? bucketValues,
    int? currentFallingValue,
    int? currentLane,
    int? tilesResolvedInLevel,
    int? targetTilesPerLevel,
    int? numberRangeMin,
    int? numberRangeMax,
    int? dropIntervalMs,
    int? fillBalance,
    int? progressGridCellCount,
    Object? visualCuesEnabled = _unset,
  }) {
    return FallingModuloGameState(
      level: level ?? this.level,
      score: score ?? this.score,
      combo: combo ?? this.combo,
      bucketValues: bucketValues ?? this.bucketValues,
      currentFallingValue: currentFallingValue ?? this.currentFallingValue,
      currentLane: currentLane ?? this.currentLane,
      tilesResolvedInLevel: tilesResolvedInLevel ?? this.tilesResolvedInLevel,
      targetTilesPerLevel: targetTilesPerLevel ?? this.targetTilesPerLevel,
      numberRangeMin: numberRangeMin ?? this.numberRangeMin,
      numberRangeMax: numberRangeMax ?? this.numberRangeMax,
      dropIntervalMs: dropIntervalMs ?? this.dropIntervalMs,
      fillBalance: fillBalance ?? this.fillBalance,
      progressGridCellCount:
          progressGridCellCount ?? this.progressGridCellCount,
      visualCuesEnabled:
          identical(visualCuesEnabled, _unset)
              ? this.visualCuesEnabled
              : visualCuesEnabled as bool,
    );
  }
}

class FallingModuloGameEngine {
  FallingModuloGameEngine({Random? random}) : _random = random ?? Random();

  static const int laneCount = 10;

  final Random _random;

  FallingModuloGameState createInitialState({
    int startingLevel = 1,
    bool visualCuesEnabled = true,
  }) {
    final level = startingLevel < 1 ? 1 : startingLevel;
    final range = numberRangeForLevel(level);

    return FallingModuloGameState(
      level: level,
      score: 0,
      combo: 0,
      bucketValues: _randomizedBuckets(),
      currentFallingValue: _nextFallingValue(range.min, range.max),
      currentLane: laneCount ~/ 2,
      tilesResolvedInLevel: 0,
      targetTilesPerLevel: targetTilesForLevel(level),
      numberRangeMin: range.min,
      numberRangeMax: range.max,
      dropIntervalMs: dropIntervalForLevel(level),
      visualCuesEnabled: visualCuesEnabled,
      fillBalance: 0,
      progressGridCellCount: 100,
    );
  }

  FallingModuloGameState moveLeft(FallingModuloGameState state) {
    if (state.currentLane <= 0) return state;
    return state.copyWith(currentLane: state.currentLane - 1);
  }

  FallingModuloGameState moveRight(FallingModuloGameState state) {
    if (state.currentLane >= laneCount - 1) return state;
    return state.copyWith(currentLane: state.currentLane + 1);
  }

  List<int> divisibleBucketIndexes(FallingModuloGameState state) {
    if (!state.visualCuesEnabled) {
      return const <int>[];
    }

    final result = <int>[];
    for (var i = 0; i < state.bucketValues.length; i++) {
      final bucketValue = state.bucketValues[i];
      // Skip dead bucket (value 0) — no divisibility hint applies.
      if (bucketValue > 0 && state.currentFallingValue % bucketValue == 0) {
        result.add(i);
      }
    }
    return result;
  }

  FallingModuloResolveResult resolveCurrentTile(FallingModuloGameState state) {
    final lane = state.currentLane.clamp(0, laneCount - 1);
    final bucketValue = state.bucketValues[lane];
    final bool isDead = bucketValue == 0;

    final int remainder;
    final bool success;
    final int scoreDelta;

    if (isDead) {
      // Dead bucket: deduct the tile value from score, no divisibility applies.
      remainder = 0;
      success = false;
      scoreDelta = -state.currentFallingValue;
    } else {
      remainder = state.currentFallingValue % bucketValue;
      success = remainder == 0;
      if (success) {
        scoreDelta =
            bucketValue == 1 ? 0 : state.currentFallingValue * bucketValue;
      } else {
        scoreDelta = -(state.currentFallingValue * bucketValue * remainder);
      }
    }

    final scoreAfter = max(0, state.score + scoreDelta);
    final comboAfter = success ? state.combo + 1 : 0;
    var nextFillBalance = isDead
        ? state.fillBalance - 1
        : (success ? state.fillBalance + 1 : state.fillBalance - remainder);

    var nextLevel = state.level;
    var nextResolvedCount = state.tilesResolvedInLevel + 1;
    var nextTargetTiles = state.targetTilesPerLevel;
    var nextDropInterval = state.dropIntervalMs;
    var nextRangeMin = state.numberRangeMin;
    var nextRangeMax = state.numberRangeMax;
    var nextBuckets = state.bucketValues;
    var leveledUp = false;

    if (nextFillBalance >= state.progressGridCellCount) {
      nextLevel += 1;
      nextResolvedCount = 0;
      nextFillBalance = 0;
      nextTargetTiles = targetTilesForLevel(nextLevel);
      nextDropInterval = dropIntervalForLevel(nextLevel);
      final range = numberRangeForLevel(nextLevel);
      nextRangeMin = range.min;
      nextRangeMax = range.max;
      nextBuckets = _randomizedBuckets();
      leveledUp = true;
    }

    final nextState = state.copyWith(
      level: nextLevel,
      score: scoreAfter,
      combo: comboAfter,
      bucketValues: nextBuckets,
      currentFallingValue: _nextFallingValue(nextRangeMin, nextRangeMax),
      tilesResolvedInLevel: nextResolvedCount,
      targetTilesPerLevel: nextTargetTiles,
      numberRangeMin: nextRangeMin,
      numberRangeMax: nextRangeMax,
      dropIntervalMs: nextDropInterval,
      fillBalance: nextFillBalance,
    );

    final resolution = FallingModuloResolution(
      success: success,
      fallingValue: state.currentFallingValue,
      bucketValue: bucketValue,
      remainder: remainder,
      scoreDelta: scoreDelta,
      scoreAfter: scoreAfter,
      comboAfter: comboAfter,
      leveledUp: leveledUp,
    );

    return FallingModuloResolveResult(state: nextState, resolution: resolution);
  }

  static int targetTilesForLevel(int level) {
    final safeLevel = level < 1 ? 1 : level;
    return 12 + (2 * (safeLevel - 1));
  }

  static ({int min, int max}) numberRangeForLevel(int level) {
    final safeLevel = level < 1 ? 1 : level;
    return (min: 5 + safeLevel, max: 15 + (3 * safeLevel));
  }

  static int dropIntervalForLevel(int level) {
    final safeLevel = level < 1 ? 1 : level;
    final scaled = 6000 * pow(0.96, safeLevel - 1);
    return max(1200, scaled.floor());
  }

  List<int> _randomizedBuckets() {
    // Nine scoring buckets (1–9) plus one dead bucket (0), shuffled randomly.
    final values = List<int>.generate(laneCount - 1, (index) => index + 1);
    values.add(0);
    values.shuffle(_random);
    return values;
  }

  int _nextFallingValue(int minValue, int maxValue) {
    return minValue + _random.nextInt((maxValue - minValue) + 1);
  }
}
