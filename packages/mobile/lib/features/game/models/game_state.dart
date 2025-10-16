import 'package:modulo/shared/models/game_board.dart';
import 'package:modulo/shared/models/cell_position.dart';

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

  GameState copyWith({
    GameBoard? gameBoard,
    int? level,
    int? highScore,
    int? remainingMoves,
    CellPosition? selectedCell,
    bool? isGameOver,
    bool? isLevelComplete,
  }) {
    return GameState(
      gameBoard: gameBoard ?? this.gameBoard,
      level: level ?? this.level,
      highScore: highScore ?? this.highScore,
      remainingMoves: remainingMoves ?? this.remainingMoves,
      selectedCell: selectedCell ?? this.selectedCell,
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
