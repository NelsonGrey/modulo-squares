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

  static CollectionReference<Map<String, dynamic>> _dailyScoresCollection(
    int challengeId,
  ) {
    return _dailyLeaderboardCollection
        .doc(challengeId.toString())
        .collection('scores');
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
  static Stream<List<Map<String, dynamic>>> getTopScores(int limit) async* {
    if (!_isFirebaseReady) {
      yield <Map<String, dynamic>>[];
      return;
    }
    try {
      await for (final snapshot
          in FirebaseFirestore.instance
              .collection('modulo_leaderboard')
              .orderBy('score', descending: true)
              .limit(limit)
              .snapshots()) {
        final data =
            snapshot.docs.map((doc) {
              final data = doc.data();
              return {'name': doc.id, 'score': data['score'] ?? 0};
            }).toList();

        // Cache the fresh data
        CacheService().cacheLeaderboardData(data);

        yield data;
      }
    } catch (error) {
      ErrorHandler().logError('Get top scores stream', error);
      // Yield empty list on error to prevent stream from breaking
      yield <Map<String, dynamic>>[];
    }
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

  /// Get top scores for a specific daily challenge.
  static Stream<List<Map<String, dynamic>>> getTopDailyScores(
    int challengeId,
    int limit,
  ) async* {
    if (!_isFirebaseReady) {
      yield <Map<String, dynamic>>[];
      return;
    }
    try {
      await for (final snapshot
          in _dailyScoresCollection(
            challengeId,
          ).orderBy('score', descending: true).limit(limit).snapshots()) {
        final data =
            snapshot.docs.map((doc) {
              final d = doc.data();
              return {'name': doc.id, 'score': d['score'] ?? 0};
            }).toList();

        yield data;
      }
    } catch (error) {
      ErrorHandler().logError('Get top daily scores stream', error);
      yield <Map<String, dynamic>>[];
    }
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
}
