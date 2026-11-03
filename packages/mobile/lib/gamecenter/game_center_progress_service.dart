/// Game Center integration beyond sign-in: the leaderboard and achievements.
///
/// Every method is best-effort: a failure (not signed in, offline, simulator
/// without a Game Center account, a non-iOS platform) is swallowed inside the
/// implementation and never thrown, so callers never need to guard these
/// calls.
abstract class GameCenterProgressService {
  Future<void> unlockAchievement(String id);
  Future<void> submitScore(int score);
  Future<void> showLeaderboard();
  Future<void> showAchievements();
}
