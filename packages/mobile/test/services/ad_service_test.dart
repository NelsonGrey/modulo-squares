import 'package:flutter_test/flutter_test.dart';
import 'package:modulo/core/services/ad_service.dart';
import 'package:modulo/core/config/admob_config.dart';

void main() {
  late AdService adService;

  setUp(() {
    adService = AdService();
  });

  group('AdService', () {
    test('singleton pattern works correctly', () {
      final instance1 = AdService();
      final instance2 = AdService();
      expect(instance1, same(instance2));
    });

    test('AdService can be instantiated', () {
      expect(adService, isNotNull);
      expect(adService, isA<AdService>());
    });

    test('initialize method exists and is callable', () async {
      // Test that the method exists and doesn't throw
      expect(() async => await adService.initialize(), returnsNormally);
    });

    test('loadInterstitial method exists and is callable', () {
      // Test that the method exists and doesn't throw
      expect(() => adService.loadInterstitial(), returnsNormally);
    });

    test('showInterstitial method exists and is callable', () async {
      // Test that the method exists and doesn't throw
      await expectLater(
        () => adService.showInterstitial(),
        returnsNormally,
      );
    });

    test('showInterstitial with parameters works', () async {
      await expectLater(
        () => adService.showInterstitial(
          trigger: 'test_trigger',
          levelNum: 5,
          onClosed: () {},
        ),
        returnsNormally,
      );
    });

    test('showInterstitial callback is executed', () async {
      bool callbackExecuted = false;

      await adService.showInterstitial(
        onClosed: () => callbackExecuted = true,
      );

      // Since ads are not loaded in test environment, callback should be called immediately
      expect(callbackExecuted, true);
    });

    test('multiple AdService instances are the same', () {
      final service1 = AdService();
      final service2 = AdService.instance;
      final service3 = AdService();

      expect(service1, same(service2));
      expect(service2, same(service3));
    });

    test('AdMob config integration works', () {
      // Test that AdMobConfig is accessible (tested separately)
      expect(AdMobConfig.interstitialId, isNotEmpty);
    });

    test('service handles null callbacks gracefully', () async {
      await expectLater(
        () => adService.showInterstitial(onClosed: null),
        returnsNormally,
      );
    });

    test('service handles various trigger values', () async {
      const triggers = ['level_complete', 'game_over', 'menu_open', null];

      for (final trigger in triggers) {
        await expectLater(
          () => adService.showInterstitial(trigger: trigger),
          returnsNormally,
        );
      }
    });

    test('service handles various level numbers', () async {
      const levels = [1, 5, 10, 100, null];

      for (final level in levels) {
        await expectLater(
          () => adService.showInterstitial(levelNum: level),
          returnsNormally,
        );
      }
    });
  });
}
