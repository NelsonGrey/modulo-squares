import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:modulo_squares/core/services/cache_service.dart';
import 'package:modulo_squares/core/services/error_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

@GenerateMocks([FirebaseFirestore, CollectionReference, DocumentReference, QuerySnapshot, QueryDocumentSnapshot, Query, CacheService, ErrorHandler])
import 'leaderboard_service_test.mocks.dart';

// Test version of LeaderboardService with injectable dependencies
class TestableLeaderboardService {
  final FirebaseFirestore firestore;
  final CacheService cacheService;
  final ErrorHandler errorHandler;

  TestableLeaderboardService({required this.firestore, required this.cacheService, required this.errorHandler});

  CollectionReference get _scoresCollection => firestore.collection('modulo_leaderboard');

  Future<void> submitScore(BuildContext context, String playerName, int score) async {
    try {
      await _scoresCollection.doc(playerName).set({'score': score, 'timestamp': FieldValue.serverTimestamp()}, SetOptions(merge: true));

      await cacheService.clearLeaderboardCache();
    } catch (e) {
      errorHandler.logError('Submit score', e);
      errorHandler.showErrorSnackBar(context, errorHandler.getFirestoreErrorMessage(e), onRetry: () => submitScore(context, playerName, score));
    }
  }

  Stream<List<Map<String, dynamic>>> getTopScores(int limit) async* {
    try {
      await for (final snapshot in _scoresCollection.orderBy('score', descending: true).limit(limit).snapshots()) {
        final data =
            snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return {'name': doc.id, 'score': data['score'] ?? 0};
            }).toList();

        cacheService.cacheLeaderboardData(data);

        yield data;
      }
    } catch (error) {
      errorHandler.logError('Get top scores stream', error);
      yield <Map<String, dynamic>>[];
    }
  }

  List<Map<String, dynamic>> getCachedTopScores({Duration maxAge = const Duration(minutes: 5)}) {
    return cacheService.getCachedLeaderboardData(maxAge: maxAge) ?? [];
  }

  Stream<List<Map<String, dynamic>>> getTopScoresWithCache(int limit, {Duration cacheMaxAge = const Duration(minutes: 5)}) async* {
    final cachedData = getCachedTopScores(maxAge: cacheMaxAge);
    if (cachedData.isNotEmpty) {
      yield cachedData;
    }

    await for (final data in getTopScores(limit)) {
      yield data;
    }
  }

  Future<void> refreshLeaderboardCache() async {
    await cacheService.clearLeaderboardCache();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFirebaseFirestore mockFirestore;
  late MockCollectionReference<Map<String, dynamic>> mockCollection;
  late MockDocumentReference<Map<String, dynamic>> mockDoc;
  late MockQuerySnapshot<Map<String, dynamic>> mockQuerySnapshot;
  late MockQueryDocumentSnapshot<Map<String, dynamic>> mockDocSnapshot;
  late MockQuery<Map<String, dynamic>> mockQuery;
  late MockCacheService mockCacheService;
  late MockErrorHandler mockErrorHandler;
  late TestableLeaderboardService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});

    mockFirestore = MockFirebaseFirestore();
    mockCollection = MockCollectionReference();
    mockDoc = MockDocumentReference();
    mockQuerySnapshot = MockQuerySnapshot();
    mockDocSnapshot = MockQueryDocumentSnapshot();
    mockQuery = MockQuery();
    mockCacheService = MockCacheService();
    mockErrorHandler = MockErrorHandler();

    service = TestableLeaderboardService(firestore: mockFirestore, cacheService: mockCacheService, errorHandler: mockErrorHandler);
  });

  group('LeaderboardService - Cache Operations', () {
    test('getCachedTopScores returns cached data when available', () {
      when(mockCacheService.getCachedLeaderboardData(maxAge: anyNamed('maxAge'))).thenReturn([
        {'name': 'Player1', 'score': 100},
        {'name': 'Player2', 'score': 80},
      ]);

      final result = service.getCachedTopScores();

      expect(result, [
        {'name': 'Player1', 'score': 100},
        {'name': 'Player2', 'score': 80},
      ]);
      verify(mockCacheService.getCachedLeaderboardData(maxAge: Duration(minutes: 5))).called(1);
    });

    test('getCachedTopScores returns empty list when no cache', () {
      when(mockCacheService.getCachedLeaderboardData(maxAge: anyNamed('maxAge'))).thenReturn(null);

      final result = service.getCachedTopScores();

      expect(result, []);
      verify(mockCacheService.getCachedLeaderboardData(maxAge: Duration(minutes: 5))).called(1);
    });

    test('refreshLeaderboardCache calls clear cache', () async {
      when(mockCacheService.clearLeaderboardCache()).thenAnswer((_) async {});

      await service.refreshLeaderboardCache();

      verify(mockCacheService.clearLeaderboardCache()).called(1);
    });
  });

  group('LeaderboardService - Score Submission', () {
    test('submitScore succeeds with valid data', () async {
      final context = _MockBuildContext();

      when(mockFirestore.collection('modulo_leaderboard')).thenReturn(mockCollection as CollectionReference<Map<String, dynamic>>);
      when(mockCollection.doc('TestPlayer')).thenReturn(mockDoc as DocumentReference<Map<String, dynamic>>);
      when(mockDoc.set(any, any)).thenAnswer((_) async {});
      when(mockCacheService.clearLeaderboardCache()).thenAnswer((_) async {});

      await service.submitScore(context, 'TestPlayer', 150);

      verify(
        mockDoc.set(
          argThat(
            predicate((Map<String, dynamic> data) {
              return data['score'] == 150 && data['timestamp'] is FieldValue;
            }),
          ),
          any,
        ),
      ).called(1);
      verify(mockCacheService.clearLeaderboardCache()).called(1);
    });

    test('submitScore handles Firestore errors gracefully', () async {
      final context = _MockBuildContext();

      when(mockFirestore.collection('modulo_leaderboard')).thenReturn(mockCollection as CollectionReference<Map<String, dynamic>>);
      when(mockCollection.doc('TestPlayer')).thenReturn(mockDoc as DocumentReference<Map<String, dynamic>>);
      when(mockDoc.set(any, any)).thenThrow(FirebaseException(plugin: 'firestore', message: 'Network error'));
      when(mockErrorHandler.logError(any, any)).thenReturn(null);
      when(mockErrorHandler.getFirestoreErrorMessage(any)).thenReturn('Connection failed');
      when(mockErrorHandler.showErrorSnackBar(any, any, onRetry: anyNamed('onRetry'))).thenReturn(null);

      await service.submitScore(context, 'TestPlayer', 150);

      verify(mockErrorHandler.logError('Submit score', any)).called(1);
      verify(mockErrorHandler.showErrorSnackBar(context, 'Connection failed', onRetry: anyNamed('onRetry'))).called(1);
    });
  });

  group('LeaderboardService - Score Streaming', () {
    test('getTopScores returns properly formatted data', () async {
      when(mockFirestore.collection('modulo_leaderboard')).thenReturn(mockCollection as CollectionReference<Map<String, dynamic>>);
      when(mockCollection.orderBy('score', descending: true)).thenReturn(mockQuery as Query<Map<String, dynamic>>);
      when(mockQuery.limit(10)).thenReturn(mockQuery);
      when(mockQuery.snapshots()).thenAnswer((_) => Stream.value(mockQuerySnapshot));

      final mockDocs = [mockDocSnapshot];
      when(mockQuerySnapshot.docs).thenReturn(mockDocs);
      when(mockDocSnapshot.id).thenReturn('Player1');
      when(mockDocSnapshot.data()).thenReturn({'score': 100, 'timestamp': Timestamp.now()});
      when(mockCacheService.cacheLeaderboardData(any)).thenAnswer((_) async {});

      final stream = service.getTopScores(10);
      final result = await stream.first;

      expect(result, [
        {'name': 'Player1', 'score': 100},
      ]);
      verify(
        mockCacheService.cacheLeaderboardData([
          {'name': 'Player1', 'score': 100},
        ]),
      ).called(1);
    });

    test('getTopScores handles empty snapshots', () async {
      when(mockFirestore.collection('modulo_leaderboard')).thenReturn(mockCollection as CollectionReference<Map<String, dynamic>>);
      when(mockCollection.orderBy('score', descending: true)).thenReturn(mockQuery as Query<Map<String, dynamic>>);
      when(mockQuery.limit(10)).thenReturn(mockQuery);
      when(mockQuery.snapshots()).thenAnswer((_) => Stream.value(mockQuerySnapshot));

      when(mockQuerySnapshot.docs).thenReturn([]);
      when(mockCacheService.cacheLeaderboardData([])).thenAnswer((_) async {});

      final stream = service.getTopScores(10);
      final result = await stream.first;

      expect(result, []);
      verify(mockCacheService.cacheLeaderboardData([])).called(1);
    });

    test('getTopScores handles stream errors gracefully', () async {
      when(mockFirestore.collection('modulo_leaderboard')).thenReturn(mockCollection as CollectionReference<Map<String, dynamic>>);
      when(mockCollection.orderBy('score', descending: true)).thenReturn(mockQuery as Query<Map<String, dynamic>>);
      when(mockQuery.limit(10)).thenReturn(mockQuery);
      when(mockQuery.snapshots()).thenAnswer((_) => Stream.error(FirebaseException(plugin: 'firestore', message: 'Stream error')));
      when(mockErrorHandler.logError('Get top scores stream', any)).thenReturn(null);

      final stream = service.getTopScores(10);
      final result = await stream.first;

      expect(result, []);
      verify(mockErrorHandler.logError('Get top scores stream', any)).called(1);
    });
  });

  group('LeaderboardService - Cache-First Strategy', () {
    test('getTopScoresWithCache yields cached data first when available', () async {
      final cachedData = [
        {'name': 'Player1', 'score': 100},
      ];

      when(mockCacheService.getCachedLeaderboardData(maxAge: anyNamed('maxAge'))).thenReturn(cachedData);

      when(mockFirestore.collection('modulo_leaderboard')).thenReturn(mockCollection as CollectionReference<Map<String, dynamic>>);
      when(mockCollection.orderBy('score', descending: true)).thenReturn(mockQuery as Query<Map<String, dynamic>>);
      when(mockQuery.limit(10)).thenReturn(mockQuery);
      when(mockQuery.snapshots()).thenAnswer((_) => Stream.value(mockQuerySnapshot));

      final mockDocs = [mockDocSnapshot];
      when(mockQuerySnapshot.docs).thenReturn(mockDocs);
      when(mockDocSnapshot.id).thenReturn('Player1');
      when(mockDocSnapshot.data()).thenReturn({'score': 100, 'timestamp': Timestamp.now()});
      when(mockCacheService.cacheLeaderboardData(any)).thenAnswer((_) async {});

      final stream = service.getTopScoresWithCache(10);
      final results = await stream.toList();

      expect(results.length, 2);
      expect(results[0], cachedData); // Cached data first
    });

    test('getTopScoresWithCache yields only live data when no cache', () async {
      when(mockCacheService.getCachedLeaderboardData(maxAge: anyNamed('maxAge'))).thenReturn(null);

      when(mockFirestore.collection('modulo_leaderboard')).thenReturn(mockCollection as CollectionReference<Map<String, dynamic>>);
      when(mockCollection.orderBy('score', descending: true)).thenReturn(mockQuery as Query<Map<String, dynamic>>);
      when(mockQuery.limit(10)).thenReturn(mockQuery);
      when(mockQuery.snapshots()).thenAnswer((_) => Stream.value(mockQuerySnapshot));

      final mockDocs = [mockDocSnapshot];
      when(mockQuerySnapshot.docs).thenReturn(mockDocs);
      when(mockDocSnapshot.id).thenReturn('Player1');
      when(mockDocSnapshot.data()).thenReturn({'score': 100, 'timestamp': Timestamp.now()});
      when(mockCacheService.cacheLeaderboardData(any)).thenAnswer((_) async {});

      final stream = service.getTopScoresWithCache(10);
      final results = await stream.toList();

      expect(results.length, 1);
      expect(results[0], [
        {'name': 'Player1', 'score': 100},
      ]);
    });
  });

  group('LeaderboardService - Data Transformation', () {
    test('correctly transforms Firestore documents to leaderboard format', () async {
      when(mockFirestore.collection('modulo_leaderboard')).thenReturn(mockCollection as CollectionReference<Map<String, dynamic>>);
      when(mockCollection.orderBy('score', descending: true)).thenReturn(mockQuery as Query<Map<String, dynamic>>);
      when(mockQuery.limit(10)).thenReturn(mockQuery);
      when(mockQuery.snapshots()).thenAnswer((_) => Stream.value(mockQuerySnapshot));

      final mockDocs = [mockDocSnapshot];
      when(mockQuerySnapshot.docs).thenReturn(mockDocs);
      when(mockDocSnapshot.id).thenReturn('TestPlayer');
      when(mockDocSnapshot.data()).thenReturn({'score': 150, 'timestamp': Timestamp.now()});
      when(mockCacheService.cacheLeaderboardData(any)).thenAnswer((_) async {});

      final stream = service.getTopScores(10);
      final result = await stream.first;

      expect(result[0]['name'], 'TestPlayer');
      expect(result[0]['score'], 150);
    });

    test('handles missing score field gracefully', () async {
      when(mockFirestore.collection('modulo_leaderboard')).thenReturn(mockCollection as CollectionReference<Map<String, dynamic>>);
      when(mockCollection.orderBy('score', descending: true)).thenReturn(mockQuery as Query<Map<String, dynamic>>);
      when(mockQuery.limit(10)).thenReturn(mockQuery);
      when(mockQuery.snapshots()).thenAnswer((_) => Stream.value(mockQuerySnapshot));

      final mockDocs = [mockDocSnapshot];
      when(mockQuerySnapshot.docs).thenReturn(mockDocs);
      when(mockDocSnapshot.id).thenReturn('TestPlayer');
      when(mockDocSnapshot.data()).thenReturn({
        'timestamp': Timestamp.now(),
        // Missing score field
      });
      when(mockCacheService.cacheLeaderboardData(any)).thenAnswer((_) async {});

      final stream = service.getTopScores(10);
      final result = await stream.first;

      expect(result[0]['name'], 'TestPlayer');
      expect(result[0]['score'], 0); // Defaults to 0
    });
  });

  group('LeaderboardService - Edge Cases', () {
    test('handles very large score values', () async {
      when(mockFirestore.collection('modulo_leaderboard')).thenReturn(mockCollection as CollectionReference<Map<String, dynamic>>);
      when(mockCollection.orderBy('score', descending: true)).thenReturn(mockQuery as Query<Map<String, dynamic>>);
      when(mockQuery.limit(10)).thenReturn(mockQuery);
      when(mockQuery.snapshots()).thenAnswer((_) => Stream.value(mockQuerySnapshot));

      final mockDocs = [mockDocSnapshot];
      when(mockQuerySnapshot.docs).thenReturn(mockDocs);
      when(mockDocSnapshot.id).thenReturn('TestPlayer');
      when(mockDocSnapshot.data()).thenReturn({'score': 999999, 'timestamp': Timestamp.now()});
      when(mockCacheService.cacheLeaderboardData(any)).thenAnswer((_) async {});

      final stream = service.getTopScores(10);
      final result = await stream.first;

      expect(result[0]['score'], 999999);
    });

    test('handles zero scores', () async {
      when(mockFirestore.collection('modulo_leaderboard')).thenReturn(mockCollection as CollectionReference<Map<String, dynamic>>);
      when(mockCollection.orderBy('score', descending: true)).thenReturn(mockQuery as Query<Map<String, dynamic>>);
      when(mockQuery.limit(10)).thenReturn(mockQuery);
      when(mockQuery.snapshots()).thenAnswer((_) => Stream.value(mockQuerySnapshot));

      final mockDocs = [mockDocSnapshot];
      when(mockQuerySnapshot.docs).thenReturn(mockDocs);
      when(mockDocSnapshot.id).thenReturn('TestPlayer');
      when(mockDocSnapshot.data()).thenReturn({'score': 0, 'timestamp': Timestamp.now()});
      when(mockCacheService.cacheLeaderboardData(any)).thenAnswer((_) async {});

      final stream = service.getTopScores(10);
      final result = await stream.first;

      expect(result[0]['score'], 0);
    });

    test('handles negative scores', () async {
      when(mockFirestore.collection('modulo_leaderboard')).thenReturn(mockCollection as CollectionReference<Map<String, dynamic>>);
      when(mockCollection.orderBy('score', descending: true)).thenReturn(mockQuery as Query<Map<String, dynamic>>);
      when(mockQuery.limit(10)).thenReturn(mockQuery);
      when(mockQuery.snapshots()).thenAnswer((_) => Stream.value(mockQuerySnapshot));

      final mockDocs = [mockDocSnapshot];
      when(mockQuerySnapshot.docs).thenReturn(mockDocs);
      when(mockDocSnapshot.id).thenReturn('TestPlayer');
      when(mockDocSnapshot.data()).thenReturn({'score': -50, 'timestamp': Timestamp.now()});
      when(mockCacheService.cacheLeaderboardData(any)).thenAnswer((_) async {});

      final stream = service.getTopScores(10);
      final result = await stream.first;

      expect(result[0]['score'], -50);
    });
  });
}

// Mock BuildContext for testing
class _MockBuildContext extends Mock implements BuildContext {}
