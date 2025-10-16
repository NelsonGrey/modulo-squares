class GameUtils {
  static int calculateMaxValue(int difficultyLevel) =>
      (difficultyLevel * 1000).clamp(1, 100000);
}