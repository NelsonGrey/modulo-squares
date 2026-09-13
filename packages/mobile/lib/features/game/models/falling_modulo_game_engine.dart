import 'dart:math';

/// Controls the falling tile's speed curve. All three share the same decay
/// shape (`base * 0.96^(level-1)`, floored) and differ only in `base`/floor —
/// see [FallingModuloGameEngine.dropIntervalForLevel]. Normal is numerically
/// identical to the original single-curve design; Easy and Hard are
/// sub-ranges carved out of that same already-tuned envelope, deliberately
/// overlapping Normal rather than introducing new untested extremes.
enum GameDifficulty { easy, normal, hard }

class FallingModuloResolution {
  final bool success;
  final int fallingValue;
  final int bucketValue;
  final int remainder;
  final int scoreDelta;
  final int scoreAfter;
  final int comboAfter;
  final bool leveledUp;
  final bool isHighestBucket;
  final int bonusScoreDelta;

  const FallingModuloResolution({
    required this.success,
    required this.fallingValue,
    required this.bucketValue,
    required this.remainder,
    required this.scoreDelta,
    required this.scoreAfter,
    required this.comboAfter,
    required this.leveledUp,
    this.isHighestBucket = false,
    this.bonusScoreDelta = 0,
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
  final int fillBalance;
  final int progressGridCellCount;
  final GameDifficulty difficulty;

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
    this.fillBalance = 0,
    this.progressGridCellCount = 100,
    this.difficulty = GameDifficulty.normal,
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
    GameDifficulty? difficulty,
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
      difficulty: difficulty ?? this.difficulty,
    );
  }
}

class FallingModuloGameEngine {
  FallingModuloGameEngine({Random? random}) : _random = random ?? Random();

  static const int laneCount = 10;

  final Random _random;

  FallingModuloGameState createInitialState({
    int startingLevel = 1,
    GameDifficulty difficulty = GameDifficulty.normal,
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
      dropIntervalMs: dropIntervalForLevel(level, difficulty: difficulty),
      fillBalance: 0,
      progressGridCellCount: 100,
      difficulty: difficulty,
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

  /// The largest bucket value (1-9) that evenly divides [fallingValue].
  /// Always returns at least `1`, since bucket 1 divides every value.
  int highestDivisorFor(int fallingValue) {
    for (var b = laneCount - 1; b >= 1; b--) {
      if (fallingValue % b == 0) return b;
    }
    return 1; // unreachable — 1 always divides.
  }

  /// The lane index currently holding the highest-divisor bucket for
  /// [state]'s falling value. Used only by the expert auto-demo (store-capture
  /// media) to target the best lane — real gameplay never surfaces this in
  /// advance, so the player has to work it out themselves.
  int? highestDivisorBucketIndex(FallingModuloGameState state) {
    final highest = highestDivisorFor(state.currentFallingValue);
    final lane = state.bucketValues.indexOf(highest);
    return lane < 0 ? null : lane;
  }

  FallingModuloResolveResult resolveCurrentTile(FallingModuloGameState state) {
    final lane = state.currentLane.clamp(0, laneCount - 1);
    final bucketValue = state.bucketValues[lane];
    final bool isDead = bucketValue == 0;

    final int remainder;
    final bool success;
    final int baseScoreDelta;
    var bonusScoreDelta = 0;
    var isHighestBucket = false;

    if (isDead) {
      // Dead bucket: deduct the tile value from score, no divisibility applies.
      remainder = 0;
      success = false;
      baseScoreDelta = -state.currentFallingValue;
    } else {
      remainder = state.currentFallingValue % bucketValue;
      success = remainder == 0;
      if (success) {
        baseScoreDelta =
            bucketValue == 1 ? 0 : state.currentFallingValue * bucketValue;
        final highestDivisor = highestDivisorFor(state.currentFallingValue);
        isHighestBucket = bucketValue == highestDivisor;
        if (isHighestBucket) {
          // Doubling the base delta rewards the skill of finding the best
          // bucket. The one exception is when 1 is itself the highest
          // divisor (the falling value is coprime to every other bucket) --
          // its base delta is always 0, so doubling it would pay nothing for
          // correctly identifying the only valid move in the round.
          bonusScoreDelta =
              bucketValue == 1 ? state.currentFallingValue : baseScoreDelta;
        }
      } else {
        baseScoreDelta = -(state.currentFallingValue * bucketValue * remainder);
      }
    }

    final scoreDelta = baseScoreDelta + bonusScoreDelta;
    final scoreAfter = max(0, state.score + scoreDelta);
    final comboAfter = success ? state.combo + 1 : 0;
    var nextFillBalance = isDead
        ? state.fillBalance - 1
        : (success
            ? state.fillBalance + (isHighestBucket ? 2 : 1)
            : state.fillBalance - remainder);

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
      nextDropInterval = dropIntervalForLevel(
        nextLevel,
        difficulty: state.difficulty,
      );
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
      isHighestBucket: isHighestBucket,
      bonusScoreDelta: bonusScoreDelta,
    );

    return FallingModuloResolveResult(state: nextState, resolution: resolution);
  }

  static int targetTilesForLevel(int level) {
    final safeLevel = level < 1 ? 1 : level;
    return 12 + (2 * (safeLevel - 1));
  }

  static ({int min, int max}) numberRangeForLevel(int level) {
    final safeLevel = level < 1 ? 1 : level;
    // Floored at 10: the falling number must always read as a genuine
    // multi-step division problem, not a single digit a player can solve by
    // memorized multiplication tables alone. The unfloored `5 + safeLevel`
    // dips as low as 6 at level 1 -- this only raises the floor for early
    // levels (it's already >=10 from level 5 on); `max` is untouched.
    final min = max(10, 5 + safeLevel);
    return (min: min, max: 15 + (3 * safeLevel));
  }

  /// Every tier shares the same `0.96` per-level decay — the shape that was
  /// already validated through painful manual tuning — and differs only in
  /// its starting speed (`base`) and floor, both chosen from inside that same
  /// proven [1200, 6000] envelope. Normal reproduces the original single
  /// curve exactly; Easy and Hard are overlapping sub-ranges of it.
  static int dropIntervalForLevel(
    int level, {
    GameDifficulty difficulty = GameDifficulty.normal,
  }) {
    final safeLevel = level < 1 ? 1 : level;
    final int base;
    final int floor;
    switch (difficulty) {
      case GameDifficulty.easy:
        base = 6000;
        floor = 2600;
      case GameDifficulty.normal:
        base = 6000;
        floor = 1200;
      case GameDifficulty.hard:
        base = 4200;
        floor = 1200;
    }
    final scaled = base * pow(0.96, safeLevel - 1);
    return max(floor, scaled.floor());
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
