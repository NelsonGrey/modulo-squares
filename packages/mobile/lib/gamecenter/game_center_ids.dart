/// Leaderboard and achievement IDs. These have to match the records created
/// in App Store Connect's Game Center configuration exactly — the code
/// references them by ID and nothing is auto-created. See
/// docs/GAME_CENTER_SETUP.md for the manual setup this list drives.
class GameCenterIds {
  const GameCenterIds._();

  /// Classic leaderboard, higher score is better.
  static const leaderboardHighScore = 'modulo_squares_high_score';

  static const achievementFirstLevel = 'modulo_squares_first_level';
  static const achievementLevel5 = 'modulo_squares_level_5';
  static const achievementLevel10 = 'modulo_squares_level_10';
  static const achievementScore1000 = 'modulo_squares_score_1000';
  static const achievementScore5000 = 'modulo_squares_score_5000';
}
