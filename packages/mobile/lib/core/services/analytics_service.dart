import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  // Public constructor for dependency injection
  factory AnalyticsService() => instance;

  FirebaseAnalytics? get _analyticsSafe {
    // If Firebase isn't initialized (e.g., in widget tests), return null to no-op.
    try {
      if (Firebase.apps.isEmpty) return null;
      return FirebaseAnalytics.instance;
    } catch (_) {
      return null;
    }
  }

  Future<void> setUserIdFromAuth(User? user) async {
    final a = _analyticsSafe;
    if (a == null || user == null) return;
    await a.setUserId(id: user.uid);
    await a.setUserProperty(
      name: 'is_anonymous',
      value: user.isAnonymous.toString(),
    );
  }

  Future<void> logAppOpen() async {
    final a = _analyticsSafe;
    if (a == null) return;
    await a.logAppOpen();
  }

  Future<void> logViewInstructions() async {
    final a = _analyticsSafe;
    if (a == null) return;
    await a.logEvent(name: 'view_instructions');
  }

  Future<void> logViewLeaderboard() async {
    final a = _analyticsSafe;
    if (a == null) return;
    await a.logEvent(name: 'view_leaderboard');
  }

  Future<void> logRestart({required int level}) async {
    final a = _analyticsSafe;
    if (a == null) return;
    await a.logEvent(name: 'restart', parameters: {'level': level});
  }

  Future<void> logLevelStart({
    required int level,
    required int rows,
    required int cols,
  }) async {
    final a = _analyticsSafe;
    if (a == null) return;
    await a.logEvent(
      name: 'level_start',
      parameters: {'level_num': level, 'rows': rows, 'cols': cols},
    );
  }

  Future<void> logLevelComplete({
    required int level,
    required int score,
  }) async {
    final a = _analyticsSafe;
    if (a == null) return;
    await a.logEvent(
      name: 'level_complete',
      parameters: {'level_num': level, 'score': score},
    );
  }

  Future<void> logOutOfMoves({required int level, required int score}) async {
    final a = _analyticsSafe;
    if (a == null) return;
    await a.logEvent(
      name: 'out_of_moves',
      parameters: {'level_num': level, 'score': score},
    );
  }

  Future<void> logGameOverNoMoves({required int score}) async {
    final a = _analyticsSafe;
    if (a == null) return;
    await a.logEvent(name: 'game_over_no_moves', parameters: {'score': score});
  }

  Future<void> logMove({required String type}) async {
    final a = _analyticsSafe;
    if (a == null) return;
    await a.logEvent(name: 'move', parameters: {'type': type});
  }

  Future<void> logSpecialTilesInfo() async {
    final a = _analyticsSafe;
    if (a == null) return;
    await a.logEvent(name: 'view_special_tiles');
  }

  Future<void> logMercySpawn({required int penalty}) async {
    final a = _analyticsSafe;
    if (a == null) return;
    await a.logEvent(name: 'mercy_spawn', parameters: {'penalty': penalty});
  }

  // Ads
  Future<void> logAdImpression({
    String format = 'interstitial',
    String? trigger,
    int? levelNum,
  }) async {
    final a = _analyticsSafe;
    if (a == null) return;
    final params = <String, Object>{'format': format};
    if (trigger != null && trigger.isNotEmpty) params['trigger'] = trigger;
    if (levelNum != null) params['level_num'] = levelNum;
    await a.logEvent(name: 'ad_impression', parameters: params);
  }

  Future<void> logAdDismissed({
    String format = 'interstitial',
    String? trigger,
    int? levelNum,
  }) async {
    final a = _analyticsSafe;
    if (a == null) return;
    final params = <String, Object>{'format': format};
    if (trigger != null && trigger.isNotEmpty) params['trigger'] = trigger;
    if (levelNum != null) params['level_num'] = levelNum;
    await a.logEvent(name: 'ad_dismissed', parameters: params);
  }

  Future<void> logDailyStart({required int challengeId}) async {
    final a = _analyticsSafe;
    if (a == null) return;
    await a.logEvent(
      name: 'daily_start',
      parameters: {'challenge_id': challengeId},
    );
  }

  Future<void> logDailySubmit({
    required int challengeId,
    required int score,
    required bool submitted,
  }) async {
    final a = _analyticsSafe;
    if (a == null) return;
    await a.logEvent(
      name: 'daily_submit',
      parameters: {
        'challenge_id': challengeId,
        'score': score,
        'submitted': submitted ? 1 : 0,
      },
    );
  }

  Future<void> logDailyRankAvailable({
    required int challengeId,
    required bool rankAvailable,
    int? rank,
  }) async {
    final a = _analyticsSafe;
    if (a == null) return;
    final params = <String, Object>{
      'challenge_id': challengeId,
      'rank_available': rankAvailable ? 1 : 0,
    };
    if (rank != null) {
      params['rank'] = rank;
    }
    await a.logEvent(name: 'daily_rank_available', parameters: params);
  }

  Future<void> logWeeklySubmit({
    required int weekId,
    required int score,
    required bool submitted,
  }) async {
    final a = _analyticsSafe;
    if (a == null) return;
    await a.logEvent(
      name: 'weekly_submit',
      parameters: {
        'week_id': weekId,
        'score': score,
        'submitted': submitted ? 1 : 0,
      },
    );
  }

  Future<void> logWeeklyRankAvailable({
    required int weekId,
    required bool rankAvailable,
    int? rank,
  }) async {
    final a = _analyticsSafe;
    if (a == null) return;
    final params = <String, Object>{
      'week_id': weekId,
      'rank_available': rankAvailable ? 1 : 0,
    };
    if (rank != null) {
      params['rank'] = rank;
    }
    await a.logEvent(name: 'weekly_rank_available', parameters: params);
  }

  Future<void> logWeeklyBadgeEarned({
    required int weekId,
    required String badge,
    required int rank,
  }) async {
    final a = _analyticsSafe;
    if (a == null) return;
    await a.logEvent(
      name: 'weekly_badge_earned',
      parameters: {'week_id': weekId, 'badge': badge, 'rank': rank},
    );
  }

  Future<void> logLevelRetry({
    required int level,
    required bool isDaily,
  }) async {
    final a = _analyticsSafe;
    if (a == null) return;
    await a.logEvent(
      name: 'level_retry',
      parameters: {'level_num': level, 'is_daily': isDaily ? 1 : 0},
    );
  }

  Future<void> logLevelFailReason({
    required int level,
    required String reason,
    required int score,
    required bool isDaily,
  }) async {
    final a = _analyticsSafe;
    if (a == null) return;
    await a.logEvent(
      name: 'level_fail_reason',
      parameters: {
        'level_num': level,
        'reason': reason,
        'score': score,
        'is_daily': isDaily ? 1 : 0,
      },
    );
  }

  Future<void> logLevelStarResult({
    required int level,
    required int stars,
    required int score,
    required int mercySpawns,
    required bool isDaily,
  }) async {
    final a = _analyticsSafe;
    if (a == null) return;
    await a.logEvent(
      name: 'level_star_result',
      parameters: {
        'level_num': level,
        'stars': stars,
        'score': score,
        'mercy_spawns': mercySpawns,
        'is_daily': isDaily ? 1 : 0,
      },
    );
  }
}
