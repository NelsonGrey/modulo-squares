import 'package:flutter_test/flutter_test.dart';
import 'package:modulo_squares/core/services/cache_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CacheService', () {
    late CacheService cacheService;

    setUp(() async {
      // Clear any existing SharedPreferences instance
      SharedPreferences.setMockInitialValues({});
      cacheService = CacheService();
      await cacheService.initialize();
    });

    tearDown(() async {
      // Clear cache after each test
      await cacheService.clearAllCaches();
    });

    test('initializes successfully', () async {
      expect(cacheService, isNotNull);
    });

    test('caches and retrieves leaderboard data', () async {
      final testData = [
        {'name': 'Player1', 'score': 100},
        {'name': 'Player2', 'score': 80},
      ];

      await cacheService.cacheLeaderboardData(testData);
      final cachedData = cacheService.getCachedLeaderboardData();

      expect(cachedData, isNotNull);
      expect(cachedData!.length, 2);
      expect(cachedData[0]['name'], 'Player1');
      expect(cachedData[0]['score'], 100);
    });

    test('returns null for expired cache', () async {
      final testData = [
        {'name': 'Player1', 'score': 100}
      ];

      await cacheService.cacheLeaderboardData(testData);

      // Wait for cache to expire (using very short max age)
      final cachedData = cacheService.getCachedLeaderboardData(maxAge: Duration.zero);

      expect(cachedData, isNull);
    });

    test('caches and retrieves game assets', () async {
      final testAssets = {
        'sound_enabled': true,
        'theme': 'dark',
        'volume': 0.8,
      };

      await cacheService.cacheGameAssets(testAssets);
      final cachedAssets = cacheService.getCachedGameAssets();

      expect(cachedAssets, isNotNull);
      expect(cachedAssets!['sound_enabled'], true);
      expect(cachedAssets['theme'], 'dark');
      expect(cachedAssets['volume'], 0.8);
    });

    test('clears leaderboard cache', () async {
      final testData = [
        {'name': 'Player1', 'score': 100}
      ];

      await cacheService.cacheLeaderboardData(testData);
      expect(cacheService.getCachedLeaderboardData(), isNotNull);

      await cacheService.clearLeaderboardCache();
      expect(cacheService.getCachedLeaderboardData(), isNull);
    });

    test('clears all caches', () async {
      final leaderboardData = [
        {'name': 'Player1', 'score': 100}
      ];
      final gameAssets = {'theme': 'dark'};

      await cacheService.cacheLeaderboardData(leaderboardData);
      await cacheService.cacheGameAssets(gameAssets);

      expect(cacheService.getCachedLeaderboardData(), isNotNull);
      expect(cacheService.getCachedGameAssets(), isNotNull);

      await cacheService.clearAllCaches();

      expect(cacheService.getCachedLeaderboardData(), isNull);
      expect(cacheService.getCachedGameAssets(), isNull);
    });

    test('provides cache statistics', () {
      final stats = cacheService.getCacheStats();
      expect(stats, isNotNull);
      expect(stats.containsKey('leaderboard_cached'), true);
      expect(stats.containsKey('game_assets_cached'), true);
      expect(stats.containsKey('cache_size_bytes'), true);
    });
  });
}
