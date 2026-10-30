import 'package:modulo_squares/features/game/models/falling_modulo_game_engine.dart';
import 'package:modulo_squares/gamecenter/game_center_ids.dart';

/// Decides which Game Center achievements a resolved tile has earned.
///
/// Pure logic with no Game Center calls, so the rules are unit-testable. It
/// remembers what it has already reported this session so each ID is returned
/// once; Game Center itself ignores repeats across sessions.
class AchievementTracker {
  final Set<String> _reported = {};
  int _missesThisLevel = 0;

  /// Clears per-run state when a new run starts. Already-reported IDs stay
  /// reported: an achievement earned earlier is still earned.
  void startNewRun() => _missesThisLevel = 0;

  /// The achievement IDs newly earned by [resolution], which left the game in
  /// [state].
  List<String> onTileResolved(
    FallingModuloResolution resolution,
    FallingModuloGameState state,
  ) {
    final earned = <String>[];
    void earn(String id) {
      if (_reported.add(id)) earned.add(id);
    }

    if (resolution.success) {
      earn(GameCenterIds.achievementFirstClean);
      if (resolution.isHighestBucket) {
        earn(GameCenterIds.achievementFirstBonus);
      }
      if (resolution.bucketValue == 7) {
        earn(GameCenterIds.achievementLuckySeven);
      }
    } else {
      _missesThisLevel++;
    }

    final combo = resolution.comboAfter;
    if (combo >= 5) earn(GameCenterIds.achievementCombo5);
    if (combo >= 10) earn(GameCenterIds.achievementCombo10);
    if (combo >= 25) earn(GameCenterIds.achievementCombo25);

    final score = state.score;
    if (score >= 1000) earn(GameCenterIds.achievementScore1000);
    if (score >= 5000) earn(GameCenterIds.achievementScore5000);
    if (score >= 25000) earn(GameCenterIds.achievementScore25000);

    final level = state.level;
    if (level >= 2) earn(GameCenterIds.achievementFirstLevel);
    if (level >= 5) earn(GameCenterIds.achievementLevel5);
    if (level >= 10) earn(GameCenterIds.achievementLevel10);
    if (level >= 20) earn(GameCenterIds.achievementLevel20);
    if (level >= 5 && state.difficulty == GameDifficulty.hard) {
      earn(GameCenterIds.achievementHardLevel5);
    }

    if (resolution.leveledUp) {
      if (_missesThisLevel == 0) earn(GameCenterIds.achievementPerfectLevel);
      _missesThisLevel = 0;
    }

    return earned;
  }
}
