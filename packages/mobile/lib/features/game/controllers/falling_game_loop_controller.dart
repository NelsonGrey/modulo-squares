import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:modulo_squares/features/game/models/falling_modulo_game_engine.dart';

/// Describes what happened when a tile resolved, for a caller (the screen)
/// to react to -- leaderboard submission, a level-complete snackbar/ad, high
/// score persistence. Those are all context-dependent side effects that
/// don't belong on a plain-Dart controller, so [FallingGameLoopController]
/// reports the outcome instead of performing them itself.
class TileResolutionOutcome {
  const TileResolutionOutcome({
    required this.result,
    required this.isNewHighScore,
  });

  final FallingModuloResolveResult result;
  final bool isNewHighScore;
}

/// Owns the falling-mode game loop: the drop timer, spawn delay, elapsed
/// clock, movement cooldown, and tile resolution. Pure Dart plus
/// [ChangeNotifier] -- no BuildContext, no widgets, no navigation, no
/// persistence, no ad/leaderboard calls. That split is what makes the class
/// of bug this controller was extracted to fix (see [_resetDropClock])
/// directly unit-testable: a plain `test()` can drive the fake-friendly
/// [Timer] callbacks and assert on state without pumping a widget tree.
///
/// [FallingModuloGameScreen] owns everything this deliberately doesn't:
/// theme, player identity, navigation, and the context-dependent side
/// effects of a resolved tile (via [onTileResolved]).
class FallingGameLoopController extends ChangeNotifier {
  FallingGameLoopController({
    required FallingModuloGameEngine engine,
    GameDifficulty initialDifficulty = GameDifficulty.normal,
    int initialHighScore = 0,
    this.onTileResolved,
  }) : _engine = engine,
       highScore = initialHighScore,
       state = engine.createInitialState(difficulty: initialDifficulty) {
    _startTicker();
  }

  static const Duration _tick = Duration(milliseconds: 16);
  static const Duration _spawnDelay = Duration(milliseconds: 500);
  static const Duration _burstDuration = Duration(milliseconds: 700);

  final FallingModuloGameEngine _engine;
  FallingModuloGameEngine get engine => _engine;

  /// Called every time a tile resolves (manual Drop or the timer's own
  /// auto-resolve) with the full outcome, so the screen can trigger
  /// leaderboard submission, a level-complete transition, and high-score
  /// persistence. Set once by the screen after construction.
  void Function(TileResolutionOutcome outcome)? onTileResolved;

  Timer? _timer;
  Duration? _lastInputAtElapsed;
  Duration _elapsed = Duration.zero;
  Duration _spawnDelayRemaining = _spawnDelay;
  Timer? _burstClearTimer;

  FallingModuloGameState state;
  int highScore;
  bool isRunning = false;
  bool hasStarted = false;
  String? resultBurstText;
  bool resultBurstPositive = true;
  bool resultBurstBonus = false;

  int get effectiveDropIntervalMs => state.dropIntervalMs;

  bool get isSpawnDelayActive => _spawnDelayRemaining > Duration.zero;

  double get dropProgress {
    if (isSpawnDelayActive) return 0.0;

    final totalMs = effectiveDropIntervalMs;
    if (totalMs <= 0) return 1.0;
    final p = _elapsed.inMilliseconds / totalMs;
    return p.clamp(0.0, 1.0);
  }

  void _startTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(_tick, (_) {
      if (!isRunning) return;

      if (_spawnDelayRemaining > Duration.zero) {
        _spawnDelayRemaining -= _tick;
        if (_spawnDelayRemaining < Duration.zero) {
          _spawnDelayRemaining = Duration.zero;
        }
      } else {
        _elapsed += _tick;
      }
      notifyListeners();

      if (_spawnDelayRemaining == Duration.zero &&
          _elapsed >= Duration(milliseconds: effectiveDropIntervalMs)) {
        resolveCurrentTile();
      }
    });
  }

  void _resetDropClock() {
    _elapsed = Duration.zero;
    // _canMoveNow() gates movement on _elapsed - _lastInputAtElapsed, so
    // without also clearing this here, a move late in one drop cycle (e.g.
    // _lastInputAtElapsed = 3000ms) leaves it stale once _elapsed resets to
    // zero for the next tile: the difference goes negative, permanently
    // failing the cooldown check until _elapsed climbs back past that old
    // value -- which can take most or all of the next drop, making Left/Right
    // feel like they only work "sometimes". Clearing it re-arms the same
    // last==null fast path _canMoveNow() already uses for a fresh run.
    //
    // This exact bug shipped once already: a prior refactor switched the
    // cooldown from wall-clock DateTime.now() (which only ever increases, so
    // this could never go negative) to this simulated per-drop clock, to
    // make cooldown tests deterministic under flutter_test's fake timers --
    // without also auditing every place _elapsed resets.
    _lastInputAtElapsed = null;
  }

  /// Resolves the currently-falling tile -- called either by the drop timer
  /// itself (auto-resolve once the drop interval elapses) or by the screen's
  /// Drop button. Both paths go through this one method so [onTileResolved]
  /// fires exactly once per resolution regardless of trigger.
  void resolveCurrentTile() {
    final result = _engine.resolveCurrentTile(state);
    final success = result.resolution.success;
    final isBonus = result.resolution.isHighestBucket;
    final scoreDelta = result.resolution.scoreDelta;
    final burstText =
        success
            ? (isBonus ? '★ +$scoreDelta BONUS!' : '+$scoreDelta')
            : '$scoreDelta';
    final isNewHighScore = result.state.score > highScore;

    state = result.state;
    if (state.score > highScore) highScore = state.score;
    resultBurstText = burstText;
    resultBurstPositive = success;
    resultBurstBonus = isBonus;
    _spawnDelayRemaining = _spawnDelay;
    _resetDropClock();
    if (result.resolution.leveledUp) isRunning = false;
    notifyListeners();

    _burstClearTimer?.cancel();
    _burstClearTimer = Timer(_burstDuration, () {
      if (resultBurstText != burstText) return;
      resultBurstText = null;
      notifyListeners();
    });

    onTileResolved?.call(
      TileResolutionOutcome(result: result, isNewHighScore: isNewHighScore),
    );
  }

  Duration _moveCooldown() {
    final baseMs = 180;
    final adjusted = (baseMs / state.horizontalMoveSpeedMultiplier).round();
    return Duration(milliseconds: adjusted.clamp(80, 180));
  }

  bool _canMoveNow() {
    // Gated on the simulated game clock (_elapsed) rather than wall-clock
    // DateTime.now() so this is deterministic under flutter_test's fake
    // clock: Timer.periodic callbacks (and thus _elapsed) are faked by
    // tester.pump(), but DateTime.now() is not. As a side effect, the
    // cooldown now only counts down while the game is actually running --
    // _elapsed is frozen while paused (see _startTicker's `!isRunning`
    // guard) -- which is the more correct behavior anyway: input the player
    // makes is already blocked while paused (the move buttons are disabled),
    // and a resumed game shouldn't have its very first input suppressed by a
    // cooldown that silently kept ticking in the background.
    final last = _lastInputAtElapsed;
    if (last == null) {
      _lastInputAtElapsed = _elapsed;
      return true;
    }

    if (_elapsed - last >= _moveCooldown()) {
      _lastInputAtElapsed = _elapsed;
      return true;
    }
    return false;
  }

  void moveLeft() {
    if (!_canMoveNow()) return;
    state = _engine.moveLeft(state);
    notifyListeners();
  }

  void moveRight() {
    if (!_canMoveNow()) return;
    state = _engine.moveRight(state);
    notifyListeners();
  }

  void toggleRunning() {
    isRunning = !isRunning;
    if (isRunning) hasStarted = true;
    notifyListeners();
  }

  /// Stops the loop if it's running; a no-op otherwise. Used before pushing
  /// Settings or the Leaderboard on top of the game, so neither silently
  /// keeps the drop timer (and thus score/deficit) advancing behind them --
  /// unlike the dedicated Pause button, they don't otherwise touch
  /// [isRunning] at all.
  void pause() {
    if (!isRunning) return;
    isRunning = false;
    notifyListeners();
  }

  void startNewRun() {
    state = _engine.createInitialState(difficulty: state.difficulty);
    isRunning = false;
    hasStarted = false;
    _elapsed = Duration.zero;
    _spawnDelayRemaining = _spawnDelay;
    _lastInputAtElapsed = null;
    resultBurstText = null;
    notifyListeners();
  }

  /// Applies preferences loaded asynchronously after construction (the
  /// constructor's own [initialHighScore]/[initialDifficulty] only cover the
  /// synchronous case, e.g. tests). Screen-only concern; SharedPreferences
  /// itself stays out of this controller.
  void loadPersisted({required int highScore, required GameDifficulty difficulty}) {
    this.highScore = highScore;
    setDifficulty(difficulty);
  }

  void setDifficulty(GameDifficulty difficulty) {
    state = state.copyWith(
      difficulty: difficulty,
      dropIntervalMs: FallingModuloGameEngine.dropIntervalForLevel(
        state.level,
        difficulty: difficulty,
      ),
    );
    notifyListeners();
  }

  void resetHighScore() {
    highScore = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _burstClearTimer?.cancel();
    super.dispose();
  }
}
