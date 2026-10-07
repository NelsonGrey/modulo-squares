import 'package:modulo_squares/gamecenter/game_center_connection.dart';
import 'package:modulo_squares/gamecenter/game_center_progress_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Forwards to [inner] only while the player is connected to Game Center.
///
/// Achievements earned while disconnected aren't lost: their IDs are kept
/// locally and granted by [flushEarned] the next time the player connects.
/// Scores need no such queue — the game re-submits the best score on connect.
class ConnectionGatedProgressService implements GameCenterProgressService {
  ConnectionGatedProgressService(this.inner, this.connection);

  final GameCenterProgressService inner;
  final GameCenterConnection connection;

  static const _earnedKey = 'gamecenter.earnedWhileDisconnected';

  @override
  Future<void> unlockAchievement(String id) async {
    if (connection.isConnected) return inner.unlockAchievement(id);
    if (!connection.supported) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final earned = (prefs.getStringList(_earnedKey) ?? []).toSet()..add(id);
      await prefs.setStringList(_earnedKey, earned.toList());
    } catch (_) {
      // Best-effort, like every Game Center call.
    }
  }

  /// Grants every achievement remembered from while disconnected.
  Future<void> flushEarned() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final earned = prefs.getStringList(_earnedKey) ?? const [];
      await prefs.remove(_earnedKey);
      for (final id in earned) {
        await inner.unlockAchievement(id);
      }
    } catch (_) {
      // Best-effort.
    }
  }

  @override
  Future<void> submitScore(int score) async {
    if (connection.isConnected) await inner.submitScore(score);
  }

  @override
  Future<void> showLeaderboard() async {
    if (connection.isConnected) await inner.showLeaderboard();
  }

  @override
  Future<void> showAchievements() async {
    if (connection.isConnected) await inner.showAchievements();
  }
}
