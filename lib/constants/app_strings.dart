
class AppStrings {
  static const String gameTitle = 'Modulo Game';
  static const String newGameTooltip = 'New Game';
  static const String congratulationsTitle = 'Congratulations!';
  static const String boardClearedMessage = 'You cleared the board!';
  static const String playAgainButton = 'Play Again';
  static const String tapToSelectInstruction = 'Tap a cell to select it.';

  static String selectedInstruction(int value) {
    return 'Selected cell with value: $value';
  }

  static String movesCount(int moves) {
    return 'Moves: $moves';
  }
}
