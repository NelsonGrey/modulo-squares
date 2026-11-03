import 'package:modulo_squares/gamecenter/game_center_progress_service.dart';

/// In-memory [GameCenterProgressService] for tests and non-iOS platforms.
class FakeGameCenterProgressService implements GameCenterProgressService {
  final unlocked = <String>{};
  final scores = <int>[];
  int leaderboardShown = 0;
  int achievementsShown = 0;

  @override
  Future<void> unlockAchievement(String id) async => unlocked.add(id);

  @override
  Future<void> submitScore(int score) async => scores.add(score);

  @override
  Future<void> showLeaderboard() async => leaderboardShown++;

  @override
  Future<void> showAchievements() async => achievementsShown++;
}
