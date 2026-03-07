import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:modulo_squares/features/game/models/game_state.dart';
import 'package:modulo_squares/shared/models/game_board.dart';
import 'package:modulo_squares/shared/models/cell_position.dart';
import 'package:modulo_squares/core/services/analytics_service.dart';
import 'package:modulo_squares/core/services/ad_service.dart';

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
  int _mercySpawnsThisLevel = 0;
  bool _isDailyChallengeMode = false;
  int? _activeDailyChallengeId;

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

  int _startingMovesForLevel(int level) => 20 + (level - 1) * 2;

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

    _lastCompletedStars = stars;
    _lastCompletionImprovedBest = false;

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
    _gameState = _gameState.copyWith(
      gameBoard: GameBoard(level: _gameState.level),
      selectedCell: null,
      remainingMoves: 20 + (_gameState.level - 1) * 2,
      isGameOver: false,
      isLevelComplete: false,
    );
    _isDailyChallengeMode = false;
    _activeDailyChallengeId = null;
    _mercySpawnsThisLevel = 0;
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

    _gameState = _gameState.copyWith(
      gameBoard: GameBoard.dailyChallenge(seed: seed, difficulty: 7),
      selectedCell: null,
      remainingMoves: 18,
      isGameOver: false,
      isLevelComplete: false,
    );
    _isDailyChallengeMode = true;
    _activeDailyChallengeId = challengeId;
    _mercySpawnsThisLevel = 0;
    _lastCompletedStars = null;
    _lastCompletionImprovedBest = false;
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
    _lastCompletedStars = null;
    _lastCompletionImprovedBest = false;
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
          _gameState.remainingMoves > 0) {
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
          _gameState.remainingMoves > 0) {
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
      _analyticsService.logLevelComplete(
        level: _gameState.level,
        score: _gameState.gameBoard.score,
      );
      return;
    }

    if (_gameState.remainingMoves <= 0) {
      _gameState = _gameState.copyWith(isGameOver: true);
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

  /// Show interstitial ad and handle level completion
  void completeLevel(VoidCallback onAdClosed) {
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
    _adService.showInterstitial(
      trigger: 'restart',
      levelNum: _gameState.level,
      onClosed: onAdClosed,
    );
  }
}
