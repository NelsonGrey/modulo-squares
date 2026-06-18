import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:modulo_squares/features/game/models/game_state.dart';
import 'package:modulo_squares/shared/models/game_board.dart';
import 'package:modulo_squares/shared/models/cell_position.dart';
import 'package:modulo_squares/core/services/analytics_service.dart';
import 'package:modulo_squares/core/services/ad_service.dart';

enum DailyModifier { noMercy, obstacleSurge, bonusRush, lowMoves }

/// Provider for managing game state using ChangeNotifier
class GameProvider extends ChangeNotifier {
  static const String _highScoreKey = 'highScore';
  static const String _bestStarsByLevelKey = 'bestStarsByLevel';
  static const String _bestScoreByLevelKey = 'bestScoreByLevel';
  static const String _dailyBestStarsKey = 'dailyBestStarsByChallenge';
  static const String _dailyBestScoreKey = 'dailyBestScoreByChallenge';

  GameState _gameState;
  final AnalyticsService _analyticsService;
  final AdService _adService;

  Map<int, int> _bestStarsByLevel = {};
  Map<int, int> _bestScoreByLevel = {};
  Map<int, int> _dailyBestStarsByChallenge = {};
  Map<int, int> _dailyBestScoreByChallenge = {};
  int? _lastCompletedStars;
  bool _lastCompletionImprovedBest = false;
  bool _lastCompletionHitPar = false;
  bool _lastCompletionHitElite = false;
  int _mercySpawnsThisLevel = 0;
  bool _isDailyChallengeMode = false;
  int? _activeDailyChallengeId;
  DailyModifier? _dailyModifier;
  int _consecutiveFailures = 0;
  int _levelsCompletedSinceAd = 0;

  GameProvider({
    required GameState initialState,
    required AnalyticsService analyticsService,
    required AdService adService,
  }) : _gameState = initialState,
       _analyticsService = analyticsService,
       _adService = adService;

  // Getters for state
  GameState get gameState => _gameState;
  GameBoard get gameBoard => _gameState.gameBoard;
  int get level => _gameState.level;
  int get highScore => _gameState.highScore;
  int get remainingMoves => _gameState.remainingMoves;
  CellPosition? get selectedCell => _gameState.selectedCell;
  bool get isGameOver => _gameState.isGameOver;
  bool get isLevelComplete => _gameState.isLevelComplete;
  bool get isDailyChallengeMode => _isDailyChallengeMode;
  int? get activeDailyChallengeId => _activeDailyChallengeId;
  int? get lastCompletedStars => _lastCompletedStars;
  bool get lastCompletionImprovedBest => _lastCompletionImprovedBest;
  bool get lastCompletionHitPar => _lastCompletionHitPar;
  bool get lastCompletionHitElite => _lastCompletionHitElite;
  DailyModifier? get dailyModifier => _dailyModifier;

  int? bestStarsForLevel(int level) => _bestStarsByLevel[level];
  int? bestScoreForLevel(int level) => _bestScoreByLevel[level];

  int? dailyBestStarsForChallenge(int challengeId) =>
      _dailyBestStarsByChallenge[challengeId];
  int? dailyBestScoreForChallenge(int challengeId) =>
      _dailyBestScoreByChallenge[challengeId];

  int get todayChallengeId {
    final now = DateTime.now();
    return (now.year * 10000) + (now.month * 100) + now.day;
  }

  int _baseMovesForLevel(int level) {
    final base = 22 - ((level - 1) ~/ 2);
    return base.clamp(11, 22);
  }

  int _assistMovesForLevel(int level) {
    if (level <= 1) return 0;
    if (_consecutiveFailures >= 5) return 4;
    if (_consecutiveFailures >= 3) return 2;
    return 0;
  }

  int _startingMovesForLevel(int level) =>
      _baseMovesForLevel(level) + _assistMovesForLevel(level);

  int _parMovesForLevel(int level) {
    final target = _startingMovesForLevel(level) - (5 + ((level - 1) ~/ 3));
    return target.clamp(5, _startingMovesForLevel(level));
  }

  int _eliteMovesForLevel(int level) {
    final elite = _parMovesForLevel(level) - 2;
    return elite.clamp(3, _parMovesForLevel(level));
  }

  ({int emptyChance, int obstacleChance, int bonusChance, int solveDepth})
  _boardTuningForLevel(int level) {
    final int failAssist = (_consecutiveFailures >= 3) ? 1 : 0;
    final emptyChance = (24 - (level * 2) + (failAssist * 3)).clamp(10, 36);
    final obstacleChance = (level >= 4 ? 3 + (level ~/ 6) - failAssist : 0)
        .clamp(0, 10);
    final bonusChance = (2 + (level ~/ 8) + failAssist).clamp(1, 8);
    final solveDepth = (8 + (level ~/ 4) + failAssist).clamp(8, 14);
    return (
      emptyChance: emptyChance,
      obstacleChance: obstacleChance,
      bonusChance: bonusChance,
      solveDepth: solveDepth,
    );
  }

  DailyModifier _dailyModifierForChallenge(int challengeId) {
    switch (challengeId % 4) {
      case 0:
        return DailyModifier.noMercy;
      case 1:
        return DailyModifier.obstacleSurge;
      case 2:
        return DailyModifier.bonusRush;
      default:
        return DailyModifier.lowMoves;
    }
  }

  String get dailyModifierLabel {
    switch (_dailyModifier) {
      case DailyModifier.noMercy:
        return 'No Mercy';
      case DailyModifier.obstacleSurge:
        return 'Obstacle Surge';
      case DailyModifier.bonusRush:
        return 'Bonus Rush';
      case DailyModifier.lowMoves:
        return 'Low Moves';
      case null:
        return '';
    }
  }

  int get currentParMoves => _parMovesForLevel(_gameState.level);
  int get currentEliteMoves => _eliteMovesForLevel(_gameState.level);

  int _calculateStarsForCompletion() {
    final int startingMoves = _startingMovesForLevel(_gameState.level);
    final int usedMoves = (startingMoves - _gameState.remainingMoves).clamp(
      0,
      startingMoves,
    );

    int stars;
    if (usedMoves <= (startingMoves * 0.4).round()) {
      stars = 3;
    } else if (usedMoves <= (startingMoves * 0.7).round()) {
      stars = 2;
    } else {
      stars = 1;
    }

    if (_mercySpawnsThisLevel > 0) {
      stars = (stars - 1).clamp(1, 3);
    }

    return stars;
  }

  Map<int, int> _decodeIntMap(String? raw) {
    if (raw == null || raw.isEmpty) return {};

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return {};

    final result = <int, int>{};
    for (final entry in decoded.entries) {
      final key = int.tryParse(entry.key);
      if (key == null) continue;

      final value = entry.value;
      if (value is int) {
        result[key] = value;
      } else if (value is num) {
        result[key] = value.toInt();
      }
    }
    return result;
  }

  Future<void> _saveLevelResults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _bestStarsByLevelKey,
      jsonEncode(_bestStarsByLevel.map((k, v) => MapEntry(k.toString(), v))),
    );
    await prefs.setString(
      _bestScoreByLevelKey,
      jsonEncode(_bestScoreByLevel.map((k, v) => MapEntry(k.toString(), v))),
    );
    await prefs.setString(
      _dailyBestStarsKey,
      jsonEncode(
        _dailyBestStarsByChallenge.map((k, v) => MapEntry(k.toString(), v)),
      ),
    );
    await prefs.setString(
      _dailyBestScoreKey,
      jsonEncode(
        _dailyBestScoreByChallenge.map((k, v) => MapEntry(k.toString(), v)),
      ),
    );
  }

  /// Initialize the game provider with saved high score
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedHighScore = prefs.getInt(_highScoreKey) ?? 0;

    _bestStarsByLevel = _decodeIntMap(prefs.getString(_bestStarsByLevelKey));
    _bestScoreByLevel = _decodeIntMap(prefs.getString(_bestScoreByLevelKey));
    _dailyBestStarsByChallenge = _decodeIntMap(
      prefs.getString(_dailyBestStarsKey),
    );
    _dailyBestScoreByChallenge = _decodeIntMap(
      prefs.getString(_dailyBestScoreKey),
    );
    _gameState = _gameState.copyWith(highScore: savedHighScore);
    notifyListeners();
  }

  /// Save high score to persistent storage
  Future<void> _saveHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_highScoreKey, _gameState.highScore);
  }

  Future<void> _recordLevelCompletionResult() async {
    final int levelNum = _gameState.level;
    final int score = _gameState.gameBoard.score;
    final int stars = _calculateStarsForCompletion();
    final int usedMoves = (_startingMovesForLevel(_gameState.level) -
            _gameState.remainingMoves)
        .clamp(0, _startingMovesForLevel(_gameState.level));

    _lastCompletedStars = stars;
    _lastCompletionImprovedBest = false;
    _lastCompletionHitPar = usedMoves <= _parMovesForLevel(_gameState.level);
    _lastCompletionHitElite =
        usedMoves <= _eliteMovesForLevel(_gameState.level);

    _analyticsService.logLevelStarResult(
      level: _gameState.level,
      stars: stars,
      score: score,
      mercySpawns: _mercySpawnsThisLevel,
      isDaily: _isDailyChallengeMode,
    );

    if (_isDailyChallengeMode && _activeDailyChallengeId != null) {
      final int challengeId = _activeDailyChallengeId!;
      final int prevBestStars = _dailyBestStarsByChallenge[challengeId] ?? 0;
      final int prevBestScore = _dailyBestScoreByChallenge[challengeId] ?? 0;

      if (stars > prevBestStars) {
        _dailyBestStarsByChallenge[challengeId] = stars;
        _lastCompletionImprovedBest = true;
      }

      if (score > prevBestScore) {
        _dailyBestScoreByChallenge[challengeId] = score;
        _lastCompletionImprovedBest = true;
      }
    } else {
      final int prevBestStars = _bestStarsByLevel[levelNum] ?? 0;
      final int prevBestScore = _bestScoreByLevel[levelNum] ?? 0;

      if (stars > prevBestStars) {
        _bestStarsByLevel[levelNum] = stars;
        _lastCompletionImprovedBest = true;
      }

      if (score > prevBestScore) {
        _bestScoreByLevel[levelNum] = score;
        _lastCompletionImprovedBest = true;
      }
    }

    await _saveLevelResults();
  }

  /// Initialize a new game board for the current level
  void initializeGameBoard() {
    final tuning = _boardTuningForLevel(_gameState.level);
    _gameState = _gameState.copyWith(
      gameBoard: GameBoard(
        level: _gameState.level,
        emptyChanceOverride: tuning.emptyChance,
        obstacleChanceOverride: tuning.obstacleChance,
        bonusChanceOverride: tuning.bonusChance,
        solveDepth: tuning.solveDepth,
      ),
      selectedCell: null,
      remainingMoves: _startingMovesForLevel(_gameState.level),
      isGameOver: false,
      isLevelComplete: false,
    );
    _isDailyChallengeMode = false;
    _activeDailyChallengeId = null;
    _dailyModifier = null;
    _mercySpawnsThisLevel = 0;
    _lastCompletionHitPar = false;
    _lastCompletionHitElite = false;
    notifyListeners();
    _analyticsService.logLevelStart(
      level: _gameState.level,
      rows: _gameState.gameBoard.rows,
      cols: _gameState.gameBoard.cols,
    );
  }

  void startDailyChallenge({DateTime? date}) {
    final d = date ?? DateTime.now();
    final int challengeId = (d.year * 10000) + (d.month * 100) + d.day;
    final int seed = challengeId;
    final modifier = _dailyModifierForChallenge(challengeId);

    int emptyChance = 16;
    int obstacleChance = 6;
    int bonusChance = 3;
    int solveDepth = 12;
    int dailyMoves = 17;

    switch (modifier) {
      case DailyModifier.noMercy:
        dailyMoves = 17;
        obstacleChance = 7;
        break;
      case DailyModifier.obstacleSurge:
        dailyMoves = 18;
        obstacleChance = 10;
        emptyChance = 18;
        break;
      case DailyModifier.bonusRush:
        dailyMoves = 17;
        bonusChance = 8;
        obstacleChance = 5;
        break;
      case DailyModifier.lowMoves:
        dailyMoves = 14;
        obstacleChance = 6;
        bonusChance = 4;
        solveDepth = 13;
        break;
    }

    _gameState = _gameState.copyWith(
      gameBoard: GameBoard.dailyChallenge(
        seed: seed,
        difficulty: 7,
        emptyChanceOverride: emptyChance,
        obstacleChanceOverride: obstacleChance,
        bonusChanceOverride: bonusChance,
        solveDepth: solveDepth,
      ),
      selectedCell: null,
      remainingMoves: dailyMoves,
      isGameOver: false,
      isLevelComplete: false,
    );
    _isDailyChallengeMode = true;
    _activeDailyChallengeId = challengeId;
    _dailyModifier = modifier;
    _mercySpawnsThisLevel = 0;
    _lastCompletedStars = null;
    _lastCompletionImprovedBest = false;
    _lastCompletionHitPar = false;
    _lastCompletionHitElite = false;
    notifyListeners();

    _analyticsService.logLevelStart(
      level: challengeId,
      rows: _gameState.gameBoard.rows,
      cols: _gameState.gameBoard.cols,
    );
    _analyticsService.logDailyStart(challengeId: challengeId);
  }

  void exitDailyChallengeMode() {
    _isDailyChallengeMode = false;
    _activeDailyChallengeId = null;
    _dailyModifier = null;
    _lastCompletedStars = null;
    _lastCompletionImprovedBest = false;
    _lastCompletionHitPar = false;
    _lastCompletionHitElite = false;
    initializeGameBoard();
  }

  /// Handle cell tap for selection/movement
  void handleTap(int row, int col) {
    if (_gameState.selectedCell == null) {
      // Select cell
      _gameState = _gameState.copyWith(selectedCell: CellPosition(row, col));
    } else {
      // Attempt move
      final int dRow = row - _gameState.selectedCell!.row;
      final int dCol = col - _gameState.selectedCell!.col;
      if ((dRow.abs() == 1 && dCol == 0) || (dRow == 0 && dCol.abs() == 1)) {
        _move(
          _gameState.selectedCell!.row,
          _gameState.selectedCell!.col,
          dRow,
          dCol,
        );
      }
      _gameState = _gameState.copyWith(selectedCell: null);
    }
    notifyListeners();
  }

  /// Perform a move operation
  void _move(int row, int col, int dRow, int dCol) {
    if (_gameState.remainingMoves <= 0) return;

    final newBoard = _gameState.gameBoard.move(row, col, dRow, dCol);
    if (newBoard != null) {
      _gameState = _gameState.copyWith(
        gameBoard: newBoard,
        remainingMoves: _gameState.remainingMoves - 1,
      );

      _analyticsService.logMove(type: 'tap');

      // Check for mercy spawn
      if (_gameState.gameBoard.nonEmptyTileCount() == 1 &&
          _gameState.remainingMoves > 0 &&
          _dailyModifier != DailyModifier.noMercy) {
        final mercyBoard = _gameState.gameBoard.mercySpawnHelperTile(
          scorePenalty: 5,
        );
        if (mercyBoard != null) {
          _gameState = _gameState.copyWith(
            gameBoard: mercyBoard,
            remainingMoves: _gameState.remainingMoves - 1,
          );
          _mercySpawnsThisLevel += 1;
          _analyticsService.logMercySpawn(penalty: 5);
        }
      }

      // Update high score if needed
      if (_gameState.gameBoard.score > _gameState.highScore) {
        _gameState = _gameState.copyWith(highScore: _gameState.gameBoard.score);
        _saveHighScore();
      }

      _checkWinLose();
      notifyListeners();
    }
  }

  /// Handle slide gesture
  void handleSlide(int row, int col, int dRow, int dCol) {
    if (_gameState.remainingMoves <= 0) return;

    final newBoard = _gameState.gameBoard.slide(row, col, dRow, dCol);
    if (newBoard != null) {
      _gameState = _gameState.copyWith(
        gameBoard: newBoard,
        remainingMoves: _gameState.remainingMoves - 1,
      );

      _analyticsService.logMove(type: 'swipe');

      // Check for mercy spawn
      if (_gameState.gameBoard.nonEmptyTileCount() == 1 &&
          _gameState.remainingMoves > 0 &&
          _dailyModifier != DailyModifier.noMercy) {
        final mercyBoard = _gameState.gameBoard.mercySpawnHelperTile(
          scorePenalty: 5,
        );
        if (mercyBoard != null) {
          _gameState = _gameState.copyWith(
            gameBoard: mercyBoard,
            remainingMoves: _gameState.remainingMoves - 1,
          );
          _mercySpawnsThisLevel += 1;
          _analyticsService.logMercySpawn(penalty: 5);
        }
      }

      // Update high score if needed
      if (_gameState.gameBoard.score > _gameState.highScore) {
        _gameState = _gameState.copyWith(highScore: _gameState.gameBoard.score);
        _saveHighScore();
      }

      _checkWinLose();
      notifyListeners();
    }
  }

  /// Check win/lose conditions
  void _checkWinLose() {
    if (_gameState.gameBoard.isBoardClear()) {
      _recordLevelCompletionResult();
      _gameState = _gameState.copyWith(isLevelComplete: true);
      _consecutiveFailures = 0;
      _analyticsService.logLevelComplete(
        level: _gameState.level,
        score: _gameState.gameBoard.score,
      );
      return;
    }

    if (_gameState.remainingMoves <= 0) {
      _gameState = _gameState.copyWith(isGameOver: true);
      _consecutiveFailures += 1;
      _analyticsService.logOutOfMoves(
        level: _gameState.level,
        score: _gameState.gameBoard.score,
      );
      _analyticsService.logLevelFailReason(
        level: _gameState.level,
        reason: 'out_of_moves',
        score: _gameState.gameBoard.score,
        isDaily: _isDailyChallengeMode,
      );
      return;
    }

    if (!_gameState.gameBoard.hasMoves()) {
      _gameState = _gameState.copyWith(isGameOver: true);
      _consecutiveFailures += 1;
      _analyticsService.logGameOverNoMoves(score: _gameState.gameBoard.score);
      _analyticsService.logLevelFailReason(
        level: _gameState.level,
        reason: 'no_valid_moves',
        score: _gameState.gameBoard.score,
        isDaily: _isDailyChallengeMode,
      );
    }
  }

  /// Advance to next level
  void nextLevel() {
    if (_isDailyChallengeMode && _activeDailyChallengeId != null) {
      final challengeDate = DateTime(
        _activeDailyChallengeId! ~/ 10000,
        (_activeDailyChallengeId! % 10000) ~/ 100,
        _activeDailyChallengeId! % 100,
      );
      startDailyChallenge(date: challengeDate);
      return;
    }

    _gameState = _gameState.copyWith(
      level: _gameState.level + 1,
      isLevelComplete: false,
    );
    _lastCompletedStars = null;
    _lastCompletionImprovedBest = false;
    _lastCompletionHitPar = false;
    _lastCompletionHitElite = false;
    initializeGameBoard();
  }

  /// Restart current level
  void restartLevel() {
    _analyticsService.logLevelRetry(
      level: _gameState.level,
      isDaily: _isDailyChallengeMode,
    );
    initializeGameBoard();
  }

  bool _shouldShowInterstitial({required String trigger}) {
    if (trigger == 'level_complete') {
      return _levelsCompletedSinceAd >= 2;
    }
    if (trigger == 'restart') {
      return _consecutiveFailures >= 2;
    }
    return true;
  }

  /// Show interstitial ad and handle level completion
  void completeLevel(VoidCallback onAdClosed) {
    _levelsCompletedSinceAd += 1;

    if (!_shouldShowInterstitial(trigger: 'level_complete')) {
      nextLevel();
      onAdClosed();
      return;
    }

    _levelsCompletedSinceAd = 0;
    _adService.showInterstitial(
      trigger: 'level_complete',
      levelNum: _gameState.level,
      onClosed: () {
        nextLevel();
        onAdClosed();
      },
    );
  }

  /// Show restart ad
  void restartWithAd(VoidCallback onAdClosed) {
    if (!_shouldShowInterstitial(trigger: 'restart')) {
      onAdClosed();
      return;
    }

    _consecutiveFailures = 0;
    _adService.showInterstitial(
      trigger: 'restart',
      levelNum: _gameState.level,
      onClosed: onAdClosed,
    );
  }
}
