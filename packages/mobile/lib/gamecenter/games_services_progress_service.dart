import 'dart:io';

import 'package:games_services/games_services.dart';
import 'package:modulo_squares/gamecenter/game_center_ids.dart';
import 'package:modulo_squares/gamecenter/game_center_progress_service.dart';

/// Real [GameCenterProgressService], backed by Game Center via the
/// `games_services` plugin's static Leaderboards/Achievements APIs.
/// iOS/macOS only.
class GamesServicesProgressService implements GameCenterProgressService {
  GamesServicesProgressService() {
    if (!(Platform.isIOS || Platform.isMacOS)) {
      throw UnsupportedError(
        'GamesServicesProgressService is only supported on iOS/macOS.',
      );
    }
  }

  @override
  Future<void> unlockAchievement(String id) async {
    try {
      await Achievements.unlock(
        achievement: Achievement(androidID: id, iOSID: id),
      );
    } catch (_) {
      // Best-effort: not signed in, offline, etc. Never blocks gameplay.
    }
  }

  @override
  Future<void> submitScore(int score) async {
    try {
      await Leaderboards.submitScore(
        score: Score(
          androidLeaderboardID: GameCenterIds.leaderboardHighScore,
          iOSLeaderboardID: GameCenterIds.leaderboardHighScore,
          value: score,
        ),
      );
    } catch (_) {
      // Best-effort.
    }
  }

  @override
  Future<void> showLeaderboard() async {
    try {
      await Leaderboards.showLeaderboards(
        iOSLeaderboardID: GameCenterIds.leaderboardHighScore,
        androidLeaderboardID: GameCenterIds.leaderboardHighScore,
      );
    } catch (_) {
      // Best-effort.
    }
  }

  @override
  Future<void> showAchievements() async {
    try {
      await Achievements.showAchievements();
    } catch (_) {
      // Best-effort.
    }
  }
}
