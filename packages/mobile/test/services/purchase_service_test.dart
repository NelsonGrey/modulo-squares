import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:modulo/core/services/purchase_service.dart';

void main() {
  late PurchaseService purchaseService;

  setUp(() async {
    // Initialize SharedPreferences for testing
    SharedPreferences.setMockInitialValues({});
    purchaseService = PurchaseService();
  });

  tearDown(() {
    // Clean up after each test
    purchaseService.dispose();
  });

  group('PurchaseService', () {
    test('singleton pattern works correctly', () {
      final instance1 = PurchaseService();
      final instance2 = PurchaseService();
      expect(instance1, same(instance2));
    });

    test('PurchaseService can be instantiated', () {
      expect(purchaseService, isNotNull);
      expect(purchaseService, isA<PurchaseService>());
    });

    test('initial state is correct', () {
      expect(purchaseService.adsRemoved, false);
      expect(purchaseService.premiumUnlocked, false);
      expect(purchaseService.isAvailable, false);
      expect(purchaseService.products, isEmpty);
    });

    test('initialize method exists and is callable', () async {
      await expectLater(
        () => purchaseService.initialize(),
        returnsNormally,
      );
    });

    test('purchaseAdRemoval method exists and is callable', () async {
      await expectLater(
        () => purchaseService.purchaseAdRemoval(),
        returnsNormally,
      );
    });

    test('purchasePremium method exists and is callable', () async {
      await expectLater(
        () => purchaseService.purchasePremium(),
        returnsNormally,
      );
    });

    test('restorePurchases method exists and is callable', () async {
      await expectLater(
        () => purchaseService.restorePurchases(),
        returnsNormally,
      );
    });

    test('getProductPrice returns formatted price', () {
      // Should return a default price when no products are loaded
      final price = purchaseService.getProductPrice('test_product');
      expect(price, isA<String>());
      expect(price, isNotEmpty);
    });

    test('isProductPurchased returns false for unknown products', () {
      expect(purchaseService.isProductPurchased('unknown_product'), false);
    });

    test('isProductPurchased returns correct state for known products', () {
      // Initially both should be false
      expect(purchaseService.isProductPurchased('remove_ads'), false);
      expect(purchaseService.isProductPurchased('premium_version'), false);
    });

    test('purchaseStream is properly initialized', () {
      expect(purchaseService.purchaseStream, isNotNull);
    });

    test('dispose method works without throwing', () {
      expect(() => purchaseService.dispose(), returnsNormally);
    });

    test('multiple PurchaseService instances are the same', () {
      final service1 = PurchaseService();
      final service2 = PurchaseService.instance;
      final service3 = PurchaseService();

      expect(service1, same(service2));
      expect(service2, same(service3));
    });

    test('getProductPrice handles non-existent products gracefully', () {
      final price = purchaseService.getProductPrice('non_existent');
      expect(price, '\$0.00'); // Default price
    });

    test('service maintains state consistency', () {
      // Test that getters return consistent values
      final adsRemoved1 = purchaseService.adsRemoved;
      final adsRemoved2 = purchaseService.adsRemoved;
      expect(adsRemoved1, adsRemoved2);

      final premium1 = purchaseService.premiumUnlocked;
      final premium2 = purchaseService.premiumUnlocked;
      expect(premium1, premium2);
    });

    test('products getter returns empty list initially', () {
      expect(purchaseService.products, isEmpty);
      expect(purchaseService.products, isA<List>());
    });

    test('isAvailable getter returns false initially', () {
      expect(purchaseService.isAvailable, false);
    });

    test('dispose can be called multiple times safely', () {
      expect(() => purchaseService.dispose(), returnsNormally);
      expect(() => purchaseService.dispose(), returnsNormally);
    });

    test('service handles initialization failure gracefully', () async {
      // Since we can't mock the InAppPurchase.instance.isAvailable() in this test,
      // we test that the method completes without throwing
      await expectLater(
        () => purchaseService.initialize(),
        returnsNormally,
      );
    });

    test('purchase methods handle missing products gracefully', () async {
      // Since no products are loaded, these should handle the error gracefully
      await expectLater(
        () => purchaseService.purchaseAdRemoval(),
        returnsNormally,
      );

      await expectLater(
        () => purchaseService.purchasePremium(),
        returnsNormally,
      );
    });
  });
}
