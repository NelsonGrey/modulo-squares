import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  Future<void> setUserIdFromAuth(User? user) async {
    if (user == null) return;
    await analytics.setUserId(id: user.uid);
    await analytics.setUserProperty(name: 'is_anonymous', value: user.isAnonymous.toString());
  }

  Future<void> logAppOpen() => analytics.logAppOpen();

  Future<void> logViewInstructions() => analytics.logEvent(name: 'view_instructions');
  Future<void> logViewLeaderboard() => analytics.logEvent(name: 'view_leaderboard');
  Future<void> logRestart({required int level}) => analytics.logEvent(name: 'restart', parameters: {'level': level});

  Future<void> logLevelStart({required int level, required int rows, required int cols}) => analytics.logEvent(name: 'level_start', parameters: {
        'level_num': level,
        'rows': rows,
        'cols': cols,
      });
  Future<void> logLevelComplete({required int level, required int score}) => analytics.logEvent(name: 'level_complete', parameters: {
        'level_num': level,
        'score': score,
      });
  Future<void> logOutOfMoves({required int level, required int score}) => analytics.logEvent(name: 'out_of_moves', parameters: {
        'level_num': level,
        'score': score,
      });
  Future<void> logGameOverNoMoves({required int score}) => analytics.logEvent(name: 'game_over_no_moves', parameters: {
        'score': score,
      });
  Future<void> logMove({required String type}) => analytics.logEvent(name: 'move', parameters: {'type': type});
  Future<void> logSpecialTilesInfo() => analytics.logEvent(name: 'view_special_tiles');
  Future<void> logMercySpawn({required int penalty}) => analytics.logEvent(name: 'mercy_spawn', parameters: {'penalty': penalty});

  // Ads
  Future<void> logAdImpression({String format = 'interstitial', String? trigger, int? levelNum}) {
    final params = <String, Object>{'format': format};
    if (trigger != null && trigger.isNotEmpty) params['trigger'] = trigger;
    if (levelNum != null) params['level_num'] = levelNum;
    return analytics.logEvent(name: 'ad_impression', parameters: params);
  }

  Future<void> logAdDismissed({String format = 'interstitial', String? trigger, int? levelNum}) {
    final params = <String, Object>{'format': format};
    if (trigger != null && trigger.isNotEmpty) params['trigger'] = trigger;
    if (levelNum != null) params['level_num'] = levelNum;
    return analytics.logEvent(name: 'ad_dismissed', parameters: params);
  }
}
