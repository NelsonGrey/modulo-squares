import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:modulo_squares/core/services/error_handler.dart';
import 'package:modulo_squares/core/services/cache_service.dart';

class LeaderboardService {
  static const List<({int maxRank, String badge})> _weeklyBadgeTiers = [
    (maxRank: 1, badge: 'Legend'),
    (maxRank: 3, badge: 'Diamond'),
    (maxRank: 10, badge: 'Gold'),
    (maxRank: 25, badge: 'Silver'),
    (maxRank: 50, badge: 'Bronze'),
  ];

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;
  static final CollectionReference _scoresCollection = _firestore.collection(
    'modulo_leaderboard',
  );
  static final CollectionReference _dailyLeaderboardCollection = _firestore
      .collection('modulo_daily_leaderboard');
  static final CollectionReference _weeklyLeaderboardCollection = _firestore
      .collection('modulo_weekly_leaderboard');

  static CollectionReference<Map<String, dynamic>> _dailyScoresCollection(
    int challengeId,
  ) {
    return _dailyLeaderboardCollection
        .doc(challengeId.toString())
        .collection('scores');
  }

  static CollectionReference<Map<String, dynamic>> _weeklyScoresCollection(
    int weekId,
  ) {
    return _weeklyLeaderboardCollection
        .doc(weekId.toString())
        .collection('scores');
  }

  static int currentWeekId({DateTime? now}) {
    final d = now ?? DateTime.now();
    final startOfYear = DateTime(d.year, 1, 1);
    final dayOfYear = d.difference(startOfYear).inDays + 1;
    final week = ((dayOfYear - 1) ~/ 7) + 1;
    return (d.year * 100) + week;
  }

  static List<int> recentWeekIds({int count = 8, DateTime? now}) {
    final result = <int>[];
    final anchor = now ?? DateTime.now();
    for (int i = 0; i < count; i++) {
      final date = anchor.subtract(Duration(days: i * 7));
      final weekId = currentWeekId(now: date);
      if (!result.contains(weekId)) {
        result.add(weekId);
      }
    }
    return result;
  }

  static String weeklyBadgeForRank(int rank) {
    for (final tier in _weeklyBadgeTiers) {
      if (rank <= tier.maxRank) {
        return tier.badge;
      }
    }
    return 'Contender';
  }

  static bool get _isFirebaseReady {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Returns true only when Firebase is ready AND the user is signed in.
  static bool get _isUserAuthenticated {
    return _isFirebaseReady && FirebaseAuth.instance.currentUser != null;
  }

  /// Submit a score for a player. Overwrites if player already exists.
  static Future<void> submitScore(
    BuildContext context,
    String playerName,
    int score,
  ) async {
    if (!_isUserAuthenticated) return;
    try {
      // Client-side validation
      if (playerName.isEmpty || playerName.length > 50) {
        throw ArgumentError('Invalid player name: must be 1-50 characters');
      }
      if (score < 0 || score > 999999) {
        throw ArgumentError('Invalid score: must be between 0-999999');
      }

      await _functions.httpsCallable('submitScore').call({
        'playerName': playerName,
        'score': score,
        'level': 1,
        'clientTime': DateTime.now().millisecondsSinceEpoch,
      });

      // Clear cache since data has changed
      await CacheService().clearLeaderboardCache();
    } catch (e) {
      ErrorHandler().logError('Submit score', e);
      if (context.mounted) {
        ErrorHandler().showErrorSnackBar(
          context,
          ErrorHandler().getFirestoreErrorMessage(e, context),
          onRetry: () => submitScore(context, playerName, score),
        );
      }
    }
  }

  /// Get top scores as a stream from Firestore
  static Stream<List<Map<String, dynamic>>> getTopScores(int limit) {
    if (!_isFirebaseReady) {
      return Stream<List<Map<String, dynamic>>>.value(<Map<String, dynamic>>[]);
    }

    return _scoresCollection
        .orderBy('score', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          final data =
              snapshot.docs.map((doc) {
                final row =
                    (doc.data() as Map<String, dynamic>?) ??
                    <String, dynamic>{};
                final name = (row['playerName'] as String?)?.trim();
                return {
                  'name': (name == null || name.isEmpty) ? doc.id : name,
                  'score': row['score'] ?? 0,
                };
              }).toList();

          CacheService().cacheLeaderboardData(data);
          return data;
        })
        .handleError((error) {
          ErrorHandler().logError('Get top scores stream', error);
        })
        .asBroadcastStream();
  }

  /// Get cached leaderboard data if available, otherwise empty list
  static List<Map<String, dynamic>> getCachedTopScores({
    Duration maxAge = const Duration(minutes: 5),
  }) {
    return CacheService().getCachedLeaderboardData(maxAge: maxAge) ?? [];
  }

  /// Get leaderboard data with cache-first strategy
  static Stream<List<Map<String, dynamic>>> getTopScoresWithCache(
    int limit, {
    Duration cacheMaxAge = const Duration(minutes: 5),
  }) async* {
    // Return cached data immediately if available and fresh
    final cachedData = getCachedTopScores(maxAge: cacheMaxAge);
    if (cachedData.isNotEmpty) {
      yield cachedData;
    }

    // Then yield from the live stream
    await for (final data in getTopScores(limit)) {
      yield data;
    }
  }

  /// Force refresh leaderboard cache
  static Future<void> refreshLeaderboardCache() async {
    await CacheService().clearLeaderboardCache();
  }

  /// Submit a score to a daily challenge leaderboard bucket.
  static Future<bool> submitDailyScore(
    BuildContext context,
    int challengeId,
    String playerName,
    int score,
  ) async {
    if (!_isUserAuthenticated) return false;
    try {
      if (challengeId <= 0) {
        throw ArgumentError('Invalid challenge id');
      }
      if (playerName.isEmpty || playerName.length > 50) {
        throw ArgumentError('Invalid player name: must be 1-50 characters');
      }
      if (score < 0 || score > 999999) {
        throw ArgumentError('Invalid score: must be between 0-999999');
      }

      await _functions.httpsCallable('submitDailyScore').call({
        'challengeId': challengeId,
        'playerName': playerName,
        'score': score,
        'level': 1,
        'clientTime': DateTime.now().millisecondsSinceEpoch,
      });
      return true;
    } catch (e) {
      ErrorHandler().logError('Submit daily score', e);
      if (context.mounted) {
        ErrorHandler().showErrorSnackBar(
          context,
          ErrorHandler().getFirestoreErrorMessage(e, context),
          onRetry:
              () => submitDailyScore(context, challengeId, playerName, score),
        );
      }
      return false;
    }
  }

  /// Submit a score to a weekly leaderboard bucket.
  /// Keeps the best score for the week per player.
  static Future<bool> submitWeeklyScore(
    BuildContext context,
    int weekId,
    String playerName,
    int score,
  ) async {
    if (!_isUserAuthenticated) return false;
    try {
      if (weekId <= 0) {
        throw ArgumentError('Invalid week id');
      }
      if (playerName.isEmpty || playerName.length > 50) {
        throw ArgumentError('Invalid player name: must be 1-50 characters');
      }
      if (score < 0 || score > 999999) {
        throw ArgumentError('Invalid score: must be between 0-999999');
      }

      await _functions.httpsCallable('submitWeeklyScore').call({
        'weekId': weekId,
        'playerName': playerName,
        'score': score,
        'level': 1,
        'clientTime': DateTime.now().millisecondsSinceEpoch,
      });
      return true;
    } catch (e) {
      ErrorHandler().logError('Submit weekly score', e);
      if (context.mounted) {
        ErrorHandler().showErrorSnackBar(
          context,
          ErrorHandler().getFirestoreErrorMessage(e, context),
          onRetry: () => submitWeeklyScore(context, weekId, playerName, score),
        );
      }
      return false;
    }
  }

  /// Get top scores for a specific daily challenge.
  static Stream<List<Map<String, dynamic>>> getTopDailyScores(
    int challengeId,
    int limit,
  ) {
    if (!_isFirebaseReady) {
      return Stream<List<Map<String, dynamic>>>.value(<Map<String, dynamic>>[]);
    }

    return _dailyScoresCollection(challengeId)
        .orderBy('score', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final row = doc.data();
            final name = (row['playerName'] as String?)?.trim();
            return {
              'name': (name == null || name.isEmpty) ? doc.id : name,
              'score': row['score'] ?? 0,
            };
          }).toList();
        })
        .handleError((error) {
          ErrorHandler().logError('Get top daily scores stream', error);
        })
        .asBroadcastStream();
  }

  /// Get top scores for a specific weekly ladder bucket.
  static Stream<List<Map<String, dynamic>>> getTopWeeklyScores(
    int weekId,
    int limit,
  ) {
    if (!_isFirebaseReady) {
      return Stream<List<Map<String, dynamic>>>.value(<Map<String, dynamic>>[]);
    }

    return _weeklyScoresCollection(weekId)
        .orderBy('score', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final row = doc.data();
            final name = (row['playerName'] as String?)?.trim();
            return {
              'name': (name == null || name.isEmpty) ? doc.id : name,
              'score': row['score'] ?? 0,
            };
          }).toList();
        })
        .handleError((error) {
          ErrorHandler().logError('Get top weekly scores stream', error);
        })
        .asBroadcastStream();
  }

  /// Best-effort rank lookup for a player in a daily challenge.
  /// Returns 1-based rank or null if rank cannot be determined.
  static Future<int?> getDailyRank(int challengeId, String playerName) async {
    if (!_isFirebaseReady) return null;
    try {
      if (challengeId <= 0 || playerName.isEmpty) return null;

      final snapshot =
          await _dailyScoresCollection(
            challengeId,
          ).orderBy('score', descending: true).limit(1000).get();

      final docs = snapshot.docs;
      for (int i = 0; i < docs.length; i++) {
        final row = docs[i].data();
        if (docs[i].id == playerName || row['playerName'] == playerName) {
          return i + 1;
        }
      }
      return null;
    } catch (error) {
      ErrorHandler().logError('Get daily rank', error);
      return null;
    }
  }

  /// Best-effort rank lookup for a player in a weekly ladder.
  /// Returns 1-based rank or null if rank cannot be determined.
  static Future<int?> getWeeklyRank(int weekId, String playerName) async {
    if (!_isFirebaseReady) return null;
    try {
      if (weekId <= 0 || playerName.isEmpty) return null;

      final snapshot =
          await _weeklyScoresCollection(
            weekId,
          ).orderBy('score', descending: true).limit(1000).get();

      final docs = snapshot.docs;
      for (int i = 0; i < docs.length; i++) {
        final row = docs[i].data();
        if (docs[i].id == playerName || row['playerName'] == playerName) {
          return i + 1;
        }
      }
      return null;
    } catch (error) {
      ErrorHandler().logError('Get weekly rank', error);
      return null;
    }
  }

  /// Best rank snapshot across a set of recent weekly ladders.
  /// Returns null when no rank is found in any provided week.
  static Future<({int weekId, int rank, String badge})?>
  getBestWeeklySeasonSnapshot({
    required String playerName,
    required List<int> weekIds,
  }) async {
    if (!_isFirebaseReady) return null;
    if (playerName.isEmpty || weekIds.isEmpty) return null;

    ({int weekId, int rank, String badge})? best;
    for (final weekId in weekIds) {
      final rank = await getWeeklyRank(weekId, playerName);
      if (rank == null) continue;

      if (best == null || rank < best.rank) {
        best = (weekId: weekId, rank: rank, badge: weeklyBadgeForRank(rank));
      }
    }

    return best;
  }

  /// Per-week progression snapshot for a list of weekly ladders.
  /// Includes weeks with no rank so UI can show complete trend context.
  static Future<List<({int weekId, int? rank, String? badge})>>
  getWeeklySeasonProgress({
    required String playerName,
    required List<int> weekIds,
  }) async {
    if (playerName.isEmpty || weekIds.isEmpty) return const [];

    final progress = <({int weekId, int? rank, String? badge})>[];
    for (final weekId in weekIds) {
      final rank = await getWeeklyRank(weekId, playerName);
      progress.add((
        weekId: weekId,
        rank: rank,
        badge: rank == null ? null : weeklyBadgeForRank(rank),
      ));
    }
    return progress;
  }

  /// Per-week progression including trend direction compared to the prior week.
  /// Trend values: improving, stable, declining, none.
  static Future<
    List<({int weekId, int? rank, String? badge, String trend, int? delta})>
  >
  getWeeklySeasonProgressWithTrend({
    required String playerName,
    required List<int> weekIds,
  }) async {
    if (playerName.isEmpty || weekIds.isEmpty) return const [];

    // Use oldest->newest for intuitive trend progression.
    final orderedWeeks = List<int>.from(weekIds.reversed);
    final base = await getWeeklySeasonProgress(
      playerName: playerName,
      weekIds: orderedWeeks,
    );

    int? previousRank;
    final result =
        <({int weekId, int? rank, String? badge, String trend, int? delta})>[];
    for (final item in base) {
      final currentRank = item.rank;
      String trend = 'none';
      int? delta;

      if (currentRank != null && previousRank != null) {
        delta = previousRank - currentRank;
        if (currentRank < previousRank) {
          trend = 'improving';
        } else if (currentRank == previousRank) {
          trend = 'stable';
        } else {
          trend = 'declining';
        }
      }

      result.add((
        weekId: item.weekId,
        rank: item.rank,
        badge: item.badge,
        delta: delta,
        trend: trend,
      ));

      if (currentRank != null) {
        previousRank = currentRank;
      }
    }

    return result;
  }
}
