import 'package:modulo_squares/shared/models/game_board.dart';
import 'package:modulo_squares/shared/models/cell_position.dart';

/// Represents the complete state of a game session
class GameState {
  final GameBoard gameBoard;
  final int level;
  final int highScore;
  final int remainingMoves;
  final CellPosition? selectedCell;
  final bool isGameOver;
  final bool isLevelComplete;

  const GameState({
    required this.gameBoard,
    required this.level,
    required this.highScore,
    required this.remainingMoves,
    this.selectedCell,
    this.isGameOver = false,
    this.isLevelComplete = false,
  });

  static const Object _unset = Object();

  GameState copyWith({
    GameBoard? gameBoard,
    int? level,
    int? highScore,
    int? remainingMoves,
    Object? selectedCell = _unset,
    bool? isGameOver,
    bool? isLevelComplete,
  }) {
    return GameState(
      gameBoard: gameBoard ?? this.gameBoard,
      level: level ?? this.level,
      highScore: highScore ?? this.highScore,
      remainingMoves: remainingMoves ?? this.remainingMoves,
      selectedCell:
          identical(selectedCell, _unset)
              ? this.selectedCell
              : selectedCell as CellPosition?,
      isGameOver: isGameOver ?? this.isGameOver,
      isLevelComplete: isLevelComplete ?? this.isLevelComplete,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GameState &&
        other.gameBoard == gameBoard &&
        other.level == level &&
        other.highScore == highScore &&
        other.remainingMoves == remainingMoves &&
        other.selectedCell == selectedCell &&
        other.isGameOver == isGameOver &&
        other.isLevelComplete == isLevelComplete;
  }

  @override
  int get hashCode {
    return Object.hash(
      gameBoard,
      level,
      highScore,
      remainingMoves,
      selectedCell,
      isGameOver,
      isLevelComplete,
    );
  }
}
