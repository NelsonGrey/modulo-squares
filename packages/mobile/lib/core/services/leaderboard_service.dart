import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:modulo_squares/core/services/error_handler.dart';
import 'package:modulo_squares/core/services/cache_service.dart';

class LeaderboardService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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

  static String weeklyBadgeForRank(int rank) {
    if (rank <= 1) return 'Legend';
    if (rank <= 3) return 'Diamond';
    if (rank <= 10) return 'Gold';
    if (rank <= 25) return 'Silver';
    if (rank <= 50) return 'Bronze';
    return 'Contender';
  }

  static bool get _isFirebaseReady {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Submit a score for a player. Overwrites if player already exists.
  static Future<void> submitScore(
    BuildContext context,
    String playerName,
    int score,
  ) async {
    if (!_isFirebaseReady) return;
    try {
      // Client-side validation
      if (playerName.isEmpty || playerName.length > 50) {
        throw ArgumentError('Invalid player name: must be 1-50 characters');
      }
      if (score < 0 || score > 999999) {
        throw ArgumentError('Invalid score: must be between 0-999999');
      }

      await _scoresCollection.doc(playerName).set({
        'score': score,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

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

    return FirebaseFirestore.instance
        .collection('modulo_leaderboard')
        .orderBy('score', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          final data =
              snapshot.docs.map((doc) {
                final row = doc.data();
                return {'name': doc.id, 'score': row['score'] ?? 0};
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
    if (!_isFirebaseReady) return false;
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

      await _dailyScoresCollection(challengeId).doc(playerName).set({
        'score': score,
        'challengeId': challengeId,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
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
    if (!_isFirebaseReady) return false;
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

      final ref = _weeklyScoresCollection(weekId).doc(playerName);
      final existing = await ref.get();
      final existingScore = (existing.data()?['score'] as num?)?.toInt() ?? 0;
      final bestScore = score > existingScore ? score : existingScore;

      await ref.set({
        'score': bestScore,
        'weekId': weekId,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
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
            return {'name': doc.id, 'score': row['score'] ?? 0};
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
            return {'name': doc.id, 'score': row['score'] ?? 0};
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
        if (docs[i].id == playerName) {
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
        if (docs[i].id == playerName) {
          return i + 1;
        }
      }
      return null;
    } catch (error) {
      ErrorHandler().logError('Get weekly rank', error);
      return null;
    }
  }
}
