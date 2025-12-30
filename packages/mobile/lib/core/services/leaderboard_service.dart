import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:modulo_squares/core/services/error_handler.dart';
import 'package:modulo_squares/core/services/cache_service.dart';

class LeaderboardService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final CollectionReference _scoresCollection = _firestore.collection('modulo_leaderboard');

  /// Submit a score for a player. Overwrites if player already exists.
  static Future<void> submitScore(BuildContext context, String playerName, int score) async {
    try {
      await _scoresCollection.doc(playerName).set({'score': score, 'timestamp': FieldValue.serverTimestamp()}, SetOptions(merge: true));

      // Clear cache since data has changed
      await CacheService().clearLeaderboardCache();
    } catch (e) {
      ErrorHandler().logError('Submit score', e);
      ErrorHandler().showErrorSnackBar(context, ErrorHandler().getFirestoreErrorMessage(e), onRetry: () => submitScore(context, playerName, score));
    }
  }

  /// Get top scores as a stream from Firestore
  static Stream<List<Map<String, dynamic>>> getTopScores(int limit) async* {
    try {
      await for (final snapshot in FirebaseFirestore.instance.collection('modulo_leaderboard').orderBy('score', descending: true).limit(limit).snapshots()) {
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
  static List<Map<String, dynamic>> getCachedTopScores({Duration maxAge = const Duration(minutes: 5)}) {
    return CacheService().getCachedLeaderboardData(maxAge: maxAge) ?? [];
  }

  /// Get leaderboard data with cache-first strategy
  static Stream<List<Map<String, dynamic>>> getTopScoresWithCache(int limit, {Duration cacheMaxAge = const Duration(minutes: 5)}) async* {
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
}
