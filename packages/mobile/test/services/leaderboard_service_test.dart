import 'package:flutter_test/flutter_test.dart';
import 'package:modulo/core/services/leaderboard_service.dart';
import 'package:modulo/core/services/cache_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LeaderboardService', () {
    late CacheService cacheService;

    setUp(() async {
      // Clear any existing SharedPreferences instance for cache testing
      SharedPreferences.setMockInitialValues({});
      cacheService = CacheService();
      await cacheService.initialize();
    });

    tearDown(() async {
      // Clear cache after each test
      await cacheService.clearAllCaches();
    });

    test('getCachedTopScores returns cached data', () async {
      final testData = [
        {'name': 'Player1', 'score': 100},
        {'name': 'Player2', 'score': 80},
      ];

      // Cache the data using CacheService
      await cacheService.cacheLeaderboardData(testData);

      final result = LeaderboardService.getCachedTopScores();

      expect(result, isNotEmpty);
      expect(result.length, 2);
      expect(result[0]['name'], 'Player1');
      expect(result[0]['score'], 100);
    });

    test('getCachedTopScores returns empty list when no cache', () {
      final result = LeaderboardService.getCachedTopScores();

      expect(result, isEmpty);
    });

    test('getCachedTopScores returns empty list for expired cache', () async {
      final testData = [
        {'name': 'Player1', 'score': 100},
      ];

      // Cache the data
      await cacheService.cacheLeaderboardData(testData);

      // Get cached data with very short max age (should be expired)
      final result = LeaderboardService.getCachedTopScores(maxAge: Duration.zero);

      expect(result, isEmpty);
    });

    test('refreshLeaderboardCache clears cache', () async {
      final testData = [
        {'name': 'Player1', 'score': 100},
      ];

      // Cache the data
      await cacheService.cacheLeaderboardData(testData);

      // Verify cache exists
      expect(LeaderboardService.getCachedTopScores(), isNotEmpty);

      // Refresh cache
      await LeaderboardService.refreshLeaderboardCache();

      // Verify cache is cleared
      expect(LeaderboardService.getCachedTopScores(), isEmpty);
    });

    // Note: Firebase-dependent methods (submitScore, getTopScores, getTopScoresWithCache)
    // would require mocking Firebase dependencies. For now, we test the cache-related
    // functionality which is the testable part of the service.
  });
}
