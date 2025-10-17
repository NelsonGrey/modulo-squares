import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:modulo/core/services/analytics_service.dart';

void main() {
  late AnalyticsService analyticsService;

  setUp(() {
    analyticsService = AnalyticsService();
  });

  group('AnalyticsService', () {
    test('singleton pattern works correctly', () {
      final instance1 = AnalyticsService();
      final instance2 = AnalyticsService();
      expect(instance1, same(instance2));
    });

    test('AnalyticsService can be instantiated', () {
      expect(analyticsService, isNotNull);
      expect(analyticsService, isA<AnalyticsService>());
    });

    test('setUserIdFromAuth handles null user gracefully', () async {
      await expectLater(
        () => analyticsService.setUserIdFromAuth(null),
        returnsNormally,
      );
    });

    test('setUserIdFromAuth with anonymous user works', () async {
      final mockUser = _MockUser(isAnonymous: true, uid: 'test-uid');
      await expectLater(
        () => analyticsService.setUserIdFromAuth(mockUser),
        returnsNormally,
      );
    });

    test('setUserIdFromAuth with authenticated user works', () async {
      final mockUser = _MockUser(isAnonymous: false, uid: 'auth-uid');
      await expectLater(
        () => analyticsService.setUserIdFromAuth(mockUser),
        returnsNormally,
      );
    });

    test('logAppOpen works without throwing', () async {
      await expectLater(
        () => analyticsService.logAppOpen(),
        returnsNormally,
      );
    });

    test('logViewInstructions works without throwing', () async {
      await expectLater(
        () => analyticsService.logViewInstructions(),
        returnsNormally,
      );
    });

    test('logViewLeaderboard works without throwing', () async {
      await expectLater(
        () => analyticsService.logViewLeaderboard(),
        returnsNormally,
      );
    });

    test('logRestart with different levels works', () async {
      const levels = [1, 5, 10, 100];

      for (final level in levels) {
        await expectLater(
          () => analyticsService.logRestart(level: level),
          returnsNormally,
        );
      }
    });

    test('logLevelStart with various parameters works', () async {
      await expectLater(
        () => analyticsService.logLevelStart(level: 1, rows: 4, cols: 4),
        returnsNormally,
      );

      await expectLater(
        () => analyticsService.logLevelStart(level: 10, rows: 13, cols: 13),
        returnsNormally,
      );
    });

    test('logLevelComplete with various scores works', () async {
      const scores = [0, 10, 100, 1000];

      for (final score in scores) {
        await expectLater(
          () => analyticsService.logLevelComplete(level: 5, score: score),
          returnsNormally,
        );
      }
    });

    test('logOutOfMoves works with various parameters', () async {
      await expectLater(
        () => analyticsService.logOutOfMoves(level: 3, score: 50),
        returnsNormally,
      );
    });

    test('logGameOverNoMoves works with various scores', () async {
      const scores = [0, 25, 100, 500];

      for (final score in scores) {
        await expectLater(
          () => analyticsService.logGameOverNoMoves(score: score),
          returnsNormally,
        );
      }
    });

    test('logMove works with different move types', () async {
      const moveTypes = ['slide', 'merge', 'collision', 'spawn'];

      for (final type in moveTypes) {
        await expectLater(
          () => analyticsService.logMove(type: type),
          returnsNormally,
        );
      }
    });

    test('logSpecialTilesInfo works without throwing', () async {
      await expectLater(
        () => analyticsService.logSpecialTilesInfo(),
        returnsNormally,
      );
    });

    test('logMercySpawn works with different penalties', () async {
      const penalties = [1, 5, 10, 25];

      for (final penalty in penalties) {
        await expectLater(
          () => analyticsService.logMercySpawn(penalty: penalty),
          returnsNormally,
        );
      }
    });

    test('logAdImpression works with default parameters', () async {
      await expectLater(
        () => analyticsService.logAdImpression(),
        returnsNormally,
      );
    });

    test('logAdImpression works with all parameters', () async {
      await expectLater(
        () => analyticsService.logAdImpression(
          format: 'banner',
          trigger: 'level_complete',
          levelNum: 5,
        ),
        returnsNormally,
      );
    });

    test('logAdImpression handles null trigger gracefully', () async {
      await expectLater(
        () => analyticsService.logAdImpression(trigger: null),
        returnsNormally,
      );
    });

    test('logAdImpression handles null levelNum gracefully', () async {
      await expectLater(
        () => analyticsService.logAdImpression(levelNum: null),
        returnsNormally,
      );
    });

    test('logAdDismissed works with default parameters', () async {
      await expectLater(
        () => analyticsService.logAdDismissed(),
        returnsNormally,
      );
    });

    test('logAdDismissed works with all parameters', () async {
      await expectLater(
        () => analyticsService.logAdDismissed(
          format: 'rewarded',
          trigger: 'game_over',
          levelNum: 10,
        ),
        returnsNormally,
      );
    });

    test('logAdDismissed handles null parameters gracefully', () async {
      await expectLater(
        () => analyticsService.logAdDismissed(trigger: null, levelNum: null),
        returnsNormally,
      );
    });

    test('all methods handle Firebase not initialized gracefully', () async {
      // Since Firebase isn't initialized in tests, all methods should return normally
      // without throwing exceptions
      await expectLater(() => analyticsService.logAppOpen(), returnsNormally);
      await expectLater(() => analyticsService.logLevelStart(level: 1, rows: 4, cols: 4), returnsNormally);
      await expectLater(() => analyticsService.logAdImpression(), returnsNormally);
    });

    test('multiple AnalyticsService instances are the same', () {
      final service1 = AnalyticsService();
      final service2 = AnalyticsService.instance;
      final service3 = AnalyticsService();

      expect(service1, same(service2));
      expect(service2, same(service3));
    });
  });
}

// Mock User class for testing
class _MockUser implements User {
  @override
  final bool isAnonymous;
  @override
  final String uid;

  _MockUser({required this.isAnonymous, required this.uid});

  // Implement other required methods with minimal implementations
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
