import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:modulo/features/game/models/game_state.dart';
import 'package:modulo/shared/models/game_board.dart';
import 'package:modulo/shared/models/cell_position.dart';
import 'package:modulo/core/services/analytics_service.dart';
import 'package:modulo/core/services/ad_service.dart';

/// Provider for managing game state using ChangeNotifier
class GameProvider extends ChangeNotifier {
  GameState _gameState;
  final AnalyticsService _analyticsService;
  final AdService _adService;

  GameProvider({
    required GameState initialState,
    required AnalyticsService analyticsService,
    required AdService adService,
  })  : _gameState = initialState,
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

  /// Initialize the game provider with saved high score
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedHighScore = prefs.getInt('highScore') ?? 0;

    _gameState = _gameState.copyWith(highScore: savedHighScore);
    notifyListeners();
  }

  /// Save high score to persistent storage
  Future<void> _saveHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('highScore', _gameState.highScore);
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
    notifyListeners();
    _analyticsService.logLevelStart(
      level: _gameState.level,
      rows: _gameState.gameBoard.rows,
      cols: _gameState.gameBoard.cols,
    );
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
        _move(_gameState.selectedCell!.row, _gameState.selectedCell!.col, dRow, dCol);
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
      if (_gameState.gameBoard.nonEmptyTileCount() == 1 && _gameState.remainingMoves > 0) {
        final mercyBoard = _gameState.gameBoard.mercySpawnHelperTile(scorePenalty: 5);
        if (mercyBoard != null) {
          _gameState = _gameState.copyWith(
            gameBoard: mercyBoard,
            remainingMoves: _gameState.remainingMoves - 1,
          );
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
      if (_gameState.gameBoard.nonEmptyTileCount() == 1 && _gameState.remainingMoves > 0) {
        final mercyBoard = _gameState.gameBoard.mercySpawnHelperTile(scorePenalty: 5);
        if (mercyBoard != null) {
          _gameState = _gameState.copyWith(
            gameBoard: mercyBoard,
            remainingMoves: _gameState.remainingMoves - 1,
          );
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
      _gameState = _gameState.copyWith(isLevelComplete: true);
      _analyticsService.logLevelComplete(level: _gameState.level, score: _gameState.gameBoard.score);
      return;
    }

    if (_gameState.remainingMoves <= 0) {
      _gameState = _gameState.copyWith(isGameOver: true);
      _analyticsService.logOutOfMoves(level: _gameState.level, score: _gameState.gameBoard.score);
      return;
    }

    if (!_gameState.gameBoard.hasMoves()) {
      _gameState = _gameState.copyWith(isGameOver: true);
      _analyticsService.logGameOverNoMoves(score: _gameState.gameBoard.score);
    }
  }

  /// Advance to next level
  void nextLevel() {
    _gameState = _gameState.copyWith(
      level: _gameState.level + 1,
      isLevelComplete: false,
    );
    initializeGameBoard();
  }

  /// Restart current level
  void restartLevel() {
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
