import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:modulo_squares/core/services/leaderboard_service.dart';
import 'package:modulo_squares/core/services/cache_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CacheService cacheService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    cacheService = CacheService();
    await cacheService.initialize();
  });

  tearDown(() async {
    await cacheService.clearAllCaches();
  });

  group('LeaderboardService Integration', () {
    test('cache integration works end-to-end', () async {
      // Test data
      final testData = [
        {'name': 'Alice', 'score': 150},
        {'name': 'Bob', 'score': 120},
        {'name': 'Charlie', 'score': 100},
      ];

      // Cache the leaderboard data
      await cacheService.cacheLeaderboardData(testData);

      // Retrieve cached data through LeaderboardService
      final cachedData = LeaderboardService.getCachedTopScores();

      // Verify the data is correctly retrieved
      expect(cachedData, isNotEmpty);
      expect(cachedData.length, 3);
      expect(cachedData[0]['name'], 'Alice');
      expect(cachedData[0]['score'], 150);
      expect(cachedData[1]['name'], 'Bob');
      expect(cachedData[1]['score'], 120);
      expect(cachedData[2]['name'], 'Charlie');
      expect(cachedData[2]['score'], 100);
    });

    test('cache refresh clears data', () async {
      // Setup initial data
      final testData = [
        {'name': 'Player1', 'score': 200},
      ];

      await cacheService.cacheLeaderboardData(testData);
      expect(LeaderboardService.getCachedTopScores(), isNotEmpty);

      // Refresh cache
      await LeaderboardService.refreshLeaderboardCache();

      // Verify cache is cleared
      expect(LeaderboardService.getCachedTopScores(), isEmpty);
    });

    test('expired cache returns empty data', () async {
      final testData = [
        {'name': 'TestPlayer', 'score': 50},
      ];

      await cacheService.cacheLeaderboardData(testData);

      // Get cached data with zero max age (should be expired)
      final result = LeaderboardService.getCachedTopScores(maxAge: Duration.zero);

      expect(result, isEmpty);
    });

    test('cache handles empty data gracefully', () async {
      // Cache empty data
      await cacheService.cacheLeaderboardData([]);

      final result = LeaderboardService.getCachedTopScores();
      expect(result, isEmpty);
    });

    test('cache handles large datasets', () async {
      // Create a large dataset
      final largeData = List.generate(
        100,
        (index) => {'name': 'Player$index', 'score': 1000 - index},
      );

      await cacheService.cacheLeaderboardData(largeData);

      final result = LeaderboardService.getCachedTopScores();
      expect(result.length, 100);
      expect(result[0]['name'], 'Player0');
      expect(result[0]['score'], 1000);
      expect(result[99]['name'], 'Player99');
      expect(result[99]['score'], 901);
    });

    test('cache data persistence across service calls', () async {
      final testData = [
        {'name': 'Persistent', 'score': 300},
      ];

      // Cache data
      await cacheService.cacheLeaderboardData(testData);

      // Multiple retrievals should return same data
      final result1 = LeaderboardService.getCachedTopScores();
      final result2 = LeaderboardService.getCachedTopScores();

      expect(result1, equals(result2));
      expect(result1[0]['name'], 'Persistent');
      expect(result1[0]['score'], 300);
    });

    test('cache handles malformed data gracefully', () async {
      // Test with incomplete data
      final malformedData = [
        {'name': 'Good', 'score': 50},
        {'name': 'Incomplete'}, // Missing score
        {'score': 25}, // Missing name
      ];

      await cacheService.cacheLeaderboardData(malformedData);

      final result = LeaderboardService.getCachedTopScores();
      // Should handle gracefully (exact behavior depends on cache implementation)
      expect(result, isNotNull);
    });
  });
}
