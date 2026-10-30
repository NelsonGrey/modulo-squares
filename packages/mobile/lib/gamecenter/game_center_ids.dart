/// Leaderboard and achievement IDs. These have to match the records created
/// in App Store Connect's Game Center configuration exactly — the code
/// references them by ID and nothing is auto-created. See
/// docs/GAME_CENTER_SETUP.md for the manual setup (names, descriptions and
/// point values) this list drives.
class GameCenterIds {
  const GameCenterIds._();

  /// Classic leaderboard, higher score is better.
  static const leaderboardHighScore = 'modulo_squares_high_score';

  // First steps
  static const achievementFirstClean = 'modulo_squares_first_clean';
  static const achievementFirstBonus = 'modulo_squares_first_bonus';
  static const achievementLuckySeven = 'modulo_squares_lucky_seven';

  // Levels
  static const achievementFirstLevel = 'modulo_squares_first_level';
  static const achievementLevel5 = 'modulo_squares_level_5';
  static const achievementLevel10 = 'modulo_squares_level_10';
  static const achievementLevel20 = 'modulo_squares_level_20';

  // Score in a single run
  static const achievementScore1000 = 'modulo_squares_score_1000';
  static const achievementScore5000 = 'modulo_squares_score_5000';
  static const achievementScore25000 = 'modulo_squares_score_25000';

  // Combos
  static const achievementCombo5 = 'modulo_squares_combo_5';
  static const achievementCombo10 = 'modulo_squares_combo_10';
  static const achievementCombo25 = 'modulo_squares_combo_25';

  // Skill
  static const achievementPerfectLevel = 'modulo_squares_perfect_level';
  static const achievementHardLevel5 = 'modulo_squares_hard_level_5';

  static const all = <String>[
    achievementFirstClean,
    achievementFirstBonus,
    achievementLuckySeven,
    achievementFirstLevel,
    achievementLevel5,
    achievementLevel10,
    achievementLevel20,
    achievementScore1000,
    achievementScore5000,
    achievementScore25000,
    achievementCombo5,
    achievementCombo10,
    achievementCombo25,
    achievementPerfectLevel,
    achievementHardLevel5,
  ];
}
