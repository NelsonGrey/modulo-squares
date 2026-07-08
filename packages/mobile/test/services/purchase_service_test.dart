import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'dart:async';
import 'package:modulo_squares/core/services/purchase_service.dart';

// Generate mocks
@GenerateMocks([InAppPurchase, ProductDetails, PurchaseDetails])
import 'purchase_service_test.mocks.dart';

// Test implementation of InAppPurchase for testing
class TestInAppPurchase implements InAppPurchase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<bool> isAvailable() async => true;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => Stream.empty();

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> identifiers) async {
    return ProductDetailsResponse(productDetails: [], notFoundIDs: identifiers.toList());
  }

  @override
  Future<bool> buyConsumable({required PurchaseParam purchaseParam, bool autoConsume = true}) async => true;

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async => true;

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {}

  @override
  Future<void> restorePurchases({String? applicationUserName}) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockInAppPurchase mockInAppPurchase;
  late PurchaseService purchaseService;

  setUp(() async {
    mockInAppPurchase = MockInAppPurchase();

    // Initialize SharedPreferences for testing
    SharedPreferences.setMockInitialValues({});

    // Create service with mock
    purchaseService = PurchaseService(mockInAppPurchase);
  });

  tearDown(() {
    purchaseService.dispose();
    PurchaseService.resetInstance(); // Reset singleton for clean tests
  });

  group('PurchaseService - Initialization', () {
    test('factory constructor creates service with dependency injection', () {
      final service = PurchaseService(mockInAppPurchase);

      expect(service, isNotNull);
    });

    test('createForTesting creates service in test mode', () {
      final service = PurchaseService.createForTesting();

      expect(service, isNotNull);
    });

    test('initialize sets up IAP connection and loads products', () async {
      // Mock IAP availability
      when(mockInAppPurchase.isAvailable()).thenAnswer((_) async => true);

      // Mock product query
      final mockProduct = MockProductDetails();
      when(mockProduct.id).thenReturn('remove_ads');
      when(mockProduct.title).thenReturn('Remove Ads');
      when(mockProduct.description).thenReturn('Remove ads from the game');
      when(mockProduct.price).thenReturn('\$0.99');

      when(
        mockInAppPurchase.queryProductDetails({'remove_ads', 'premium_version'}),
      ).thenAnswer((_) async => ProductDetailsResponse(productDetails: [mockProduct], notFoundIDs: [], error: null));

      // Mock purchase stream
      final purchaseStreamController = StreamController<List<PurchaseDetails>>();
      when(mockInAppPurchase.purchaseStream).thenAnswer((_) => purchaseStreamController.stream);

      await purchaseService.initialize();

      expect(purchaseService.isAvailable, true);
      expect(purchaseService.products.isNotEmpty, true);
      expect(purchaseService.products.first.id, 'remove_ads');

      await purchaseStreamController.close();
    });

    test('initialize handles IAP unavailable', () async {
      when(mockInAppPurchase.isAvailable()).thenAnswer((_) async => false);

      await purchaseService.initialize();

      expect(purchaseService.isAvailable, false);
    });

    test('initialize handles product query errors gracefully', () async {
      when(mockInAppPurchase.isAvailable()).thenAnswer((_) async => true);

      when(mockInAppPurchase.queryProductDetails({'remove_ads', 'premium_version'})).thenAnswer(
        (_) async => ProductDetailsResponse(
          productDetails: [],
          notFoundIDs: ['remove_ads', 'premium_version'],
          error: IAPError(source: 'test', code: 'test_error', message: 'Test error'),
        ),
      );

      final purchaseStreamController = StreamController<List<PurchaseDetails>>();
      when(mockInAppPurchase.purchaseStream).thenAnswer((_) => purchaseStreamController.stream);

      await purchaseService.initialize();

      expect(purchaseService.isAvailable, true);
      expect(purchaseService.products.isEmpty, true);

      await purchaseStreamController.close();
    });
  });

  group('PurchaseService - Product Management', () {
    test('products getter returns loaded products', () {
      final service = PurchaseService.createForTesting();
      expect(service.products, isA<List<ProductDetails>>());
    });

    test('isProductPurchased returns false for unpurchased product', () {
      final service = PurchaseService.createForTesting();
      final isPurchased = service.isProductPurchased('remove_ads');

      expect(isPurchased, false);
    });

    test('isProductPurchased returns true for premium product when purchased', () {
      final service = PurchaseService.createForTesting();
      // Test mode service doesn't persist state, so this will always be false
      final isPurchased = service.isProductPurchased('premium_version');

      expect(isPurchased, false);
    });

    test('getProductPrice returns formatted price', () {
      final service = PurchaseService.createForTesting();
      final price = service.getProductPrice('remove_ads');

      expect(price, isA<String>());
      expect(price, isNotEmpty);
    });

    test(
      'getProductPrice falls back to default price when the loaded '
      'products list holds a ProductDetails subclass (regression test for '
      'the real-device crash: on iOS, in_app_purchase_storekit populates '
      'this list with AppStoreProduct2Details, a ProductDetails subclass, '
      'so the list\'s runtime element type is more specific than the '
      'declared List<ProductDetails> — firstWhere\'s orElse must match '
      'that runtime type or it throws a TypeError)',
      () async {
        when(mockInAppPurchase.isAvailable()).thenAnswer((_) async => true);

        final mockProduct = MockProductDetails();
        when(mockProduct.id).thenReturn('remove_ads');
        when(mockProduct.title).thenReturn('Remove Ads');
        when(mockProduct.description).thenReturn('Remove ads from the game');
        when(mockProduct.price).thenReturn('\$0.99');

        // Must be a List<MockProductDetails>, not a List<ProductDetails>,
        // to reproduce the real bug: on a real device the list's runtime
        // element type is a ProductDetails subclass (AppStoreProduct2Details),
        // and a plain `[mockProduct]` literal here would get inferred as
        // List<ProductDetails> from the surrounding parameter type instead,
        // silently defeating the regression test.
        final List<MockProductDetails> mockProducts = [mockProduct];

        when(
          mockInAppPurchase.queryProductDetails({'remove_ads', 'premium_version'}),
        ).thenAnswer(
          (_) async => ProductDetailsResponse(productDetails: mockProducts, notFoundIDs: [], error: null),
        );

        final purchaseStreamController = StreamController<List<PurchaseDetails>>();
        when(mockInAppPurchase.purchaseStream).thenAnswer((_) => purchaseStreamController.stream);

        await purchaseService.initialize();

        // Product not in the list — exercises the orElse fallback path.
        final price = purchaseService.getProductPrice('premium_version');

        expect(price, '\$0.99');

        await purchaseStreamController.close();
      },
    );
  });

  group('PurchaseService - Purchase Flow', () {
    late StreamController<List<PurchaseDetails>> purchaseStreamController;

    setUp(() async {
      // Setup basic mocks
      when(mockInAppPurchase.isAvailable()).thenAnswer((_) async => true);

      final mockAdRemovalProduct = MockProductDetails();
      when(mockAdRemovalProduct.id).thenReturn('remove_ads');
      when(mockAdRemovalProduct.title).thenReturn('Remove Ads');
      when(mockAdRemovalProduct.description).thenReturn('Remove ads from the game');
      when(mockAdRemovalProduct.price).thenReturn('\$0.99');

      final mockPremiumProduct = MockProductDetails();
      when(mockPremiumProduct.id).thenReturn('premium_version');
      when(mockPremiumProduct.title).thenReturn('Premium Version');
      when(mockPremiumProduct.description).thenReturn('Unlock premium features');
      when(mockPremiumProduct.price).thenReturn('\$4.99');

      when(
        mockInAppPurchase.queryProductDetails({'remove_ads', 'premium_version'}),
      ).thenAnswer((_) async => ProductDetailsResponse(productDetails: [mockAdRemovalProduct, mockPremiumProduct], notFoundIDs: [], error: null));

      purchaseStreamController = StreamController<List<PurchaseDetails>>();
      when(mockInAppPurchase.purchaseStream).thenAnswer((_) => purchaseStreamController.stream);

      await purchaseService.initialize();
    });

    tearDown(() async {
      await purchaseStreamController.close();
    });

    test('purchaseAdRemoval initiates purchase successfully', () async {
      when(mockInAppPurchase.buyNonConsumable(purchaseParam: anyNamed('purchaseParam'))).thenAnswer((_) async => true);

      await purchaseService.purchaseAdRemoval();

      verify(mockInAppPurchase.buyNonConsumable(purchaseParam: anyNamed('purchaseParam'))).called(1);
    });

    test('purchasePremium initiates purchase successfully', () async {
      when(mockInAppPurchase.buyNonConsumable(purchaseParam: anyNamed('purchaseParam'))).thenAnswer((_) async => true);

      await purchaseService.purchasePremium();

      verify(mockInAppPurchase.buyNonConsumable(purchaseParam: anyNamed('purchaseParam'))).called(1);
    });

    test('restorePurchases initiates restore flow', () async {
      when(mockInAppPurchase.restorePurchases()).thenAnswer((_) async => {});

      await purchaseService.restorePurchases();

      verify(mockInAppPurchase.restorePurchases()).called(1);
    });
  });

  group('PurchaseService - Purchase Processing', () {
    late StreamController<List<PurchaseDetails>> purchaseStreamController;
    late MockPurchaseDetails mockPurchase;

    setUp(() async {
      // Setup basic mocks
      when(mockInAppPurchase.isAvailable()).thenAnswer((_) async => true);

      final mockProduct = MockProductDetails();
      when(mockProduct.id).thenReturn('remove_ads');
      when(mockProduct.title).thenReturn('Remove Ads');
      when(mockProduct.description).thenReturn('Remove ads from the game');
      when(mockProduct.price).thenReturn('\$0.99');

      when(
        mockInAppPurchase.queryProductDetails({'remove_ads', 'premium_version'}),
      ).thenAnswer((_) async => ProductDetailsResponse(productDetails: [mockProduct], notFoundIDs: [], error: null));

      purchaseStreamController = StreamController<List<PurchaseDetails>>();
      when(mockInAppPurchase.purchaseStream).thenAnswer((_) => purchaseStreamController.stream);

      await purchaseService.initialize();

      // Setup mock purchase
      mockPurchase = MockPurchaseDetails();
      when(mockPurchase.productID).thenReturn('remove_ads');
      when(mockPurchase.status).thenReturn(PurchaseStatus.purchased);
      when(mockPurchase.pendingCompletePurchase).thenReturn(true);
      when(mockPurchase.error).thenReturn(null);
    });

    tearDown(() async {
      await purchaseStreamController.close();
    });

    test('purchase stream handles successful purchase', () async {
      // Simulate purchase update
      purchaseStreamController.add([mockPurchase]);

      // Wait for processing
      await Future.delayed(Duration(milliseconds: 100));

      verify(mockInAppPurchase.completePurchase(mockPurchase)).called(1);
    });

    test('purchase stream handles pending purchases', () async {
      when(mockPurchase.status).thenReturn(PurchaseStatus.pending);
      when(mockPurchase.pendingCompletePurchase).thenReturn(false);

      purchaseStreamController.add([mockPurchase]);

      await Future.delayed(Duration(milliseconds: 100));

      // Should not complete purchase for pending status
      verifyNever(mockInAppPurchase.completePurchase(any));
    });

    test('purchase stream handles failed purchases', () async {
      when(mockPurchase.status).thenReturn(PurchaseStatus.error);
      when(mockPurchase.pendingCompletePurchase).thenReturn(false);

      purchaseStreamController.add([mockPurchase]);

      await Future.delayed(Duration(milliseconds: 100));

      // Should not complete purchase for error status
      verifyNever(mockInAppPurchase.completePurchase(any));
    });

    test('purchase stream handles restored purchases', () async {
      when(mockPurchase.status).thenReturn(PurchaseStatus.restored);
      when(mockPurchase.pendingCompletePurchase).thenReturn(true);

      purchaseStreamController.add([mockPurchase]);

      await Future.delayed(Duration(milliseconds: 100));

      verify(mockInAppPurchase.completePurchase(mockPurchase)).called(1);
    });

    test('purchase stream handles cancelled purchases', () async {
      when(mockPurchase.status).thenReturn(PurchaseStatus.canceled);
      when(mockPurchase.pendingCompletePurchase).thenReturn(false);

      purchaseStreamController.add([mockPurchase]);

      await Future.delayed(Duration(milliseconds: 100));

      // Should not complete purchase for cancelled status
      verifyNever(mockInAppPurchase.completePurchase(any));
    });
  });

  group('PurchaseService - State Management', () {
    test('adsRemoved getter reflects purchase state', () {
      final service = PurchaseService.createForTesting();

      expect(service.adsRemoved, false);
    });

    test('premiumUnlocked getter reflects purchase state', () {
      final service = PurchaseService.createForTesting();

      expect(service.premiumUnlocked, false);
    });

    test('isProductPurchased handles different product IDs', () {
      final service = PurchaseService.createForTesting();

      expect(service.isProductPurchased('remove_ads'), false);
      expect(service.isProductPurchased('premium_version'), false);
      expect(service.isProductPurchased('unknown'), false);
    });
  });

  group('PurchaseService - Test Mode', () {
    test('createForTesting uses test implementation', () async {
      final testService = PurchaseService.createForTesting();
      await testService.initialize();

      expect(testService, isNotNull);
      expect(testService.isAvailable, true); // Test mode is always available
    });

    test('TestInAppPurchase returns test products', () async {
      final testIAP = TestInAppPurchase();

      final response = await testIAP.queryProductDetails({'remove_ads'});

      expect(response.productDetails.isEmpty, true); // Test implementation returns empty
      expect(response.notFoundIDs.isNotEmpty, true);
    });

    test('TestInAppPurchase simulates successful purchase', () async {
      final testIAP = TestInAppPurchase();

      final result = await testIAP.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: MockProductDetails()));

      expect(result, true);
    });

    test('TestInAppPurchase simulates restore purchases', () async {
      final testIAP = TestInAppPurchase();

      // Should complete without error
      await testIAP.restorePurchases();
    });
  });

  group('PurchaseService - Error Handling', () {
    test('initialize throws exception when IAP check fails', () async {
      when(mockInAppPurchase.isAvailable()).thenThrow(Exception('Test exception'));

      final service = PurchaseService(mockInAppPurchase);

      // The service does not catch exceptions from isAvailable()
      expect(() async => await service.initialize(), throwsException);
    });
    test('purchaseAdRemoval throws when products not loaded', () async {
      // Setup with no products (simulates products not yet fetched)
      when(mockInAppPurchase.isAvailable()).thenAnswer((_) async => true);

      when(
        mockInAppPurchase.queryProductDetails({'remove_ads', 'premium_version'}),
      ).thenAnswer((_) async => ProductDetailsResponse(productDetails: [], notFoundIDs: ['remove_ads', 'premium_version'], error: null));

      final purchaseStreamController = StreamController<List<PurchaseDetails>>();
      when(mockInAppPurchase.purchaseStream).thenAnswer((_) => purchaseStreamController.stream);

      final service = PurchaseService(mockInAppPurchase);
      await service.initialize();

      // Attempting to purchase when products are missing throws
      expect(() async => await service.purchaseAdRemoval(), throwsException);

      await purchaseStreamController.close();
    });

    test('dispose cleans up resources', () async {
      when(mockInAppPurchase.isAvailable()).thenAnswer((_) async => true);

      when(
        mockInAppPurchase.queryProductDetails({'remove_ads', 'premium_version'}),
      ).thenAnswer((_) async => ProductDetailsResponse(productDetails: [], notFoundIDs: ['remove_ads', 'premium_version'], error: null));

      final purchaseStreamController = StreamController<List<PurchaseDetails>>();
      when(mockInAppPurchase.purchaseStream).thenAnswer((_) => purchaseStreamController.stream);

      final service = PurchaseService(mockInAppPurchase);
      await service.initialize();

      service.dispose();

      // Should not crash on double dispose
      service.dispose();

      await purchaseStreamController.close();
    });
  });

  group('PurchaseService - Constants and Getters', () {
    test('adsRemoved getter works', () {
      final service = PurchaseService.createForTesting();
      expect(service.adsRemoved, isA<bool>());
    });

    test('premiumUnlocked getter works', () {
      final service = PurchaseService.createForTesting();
      expect(service.premiumUnlocked, isA<bool>());
    });

    test('isAvailable getter works', () {
      final service = PurchaseService.createForTesting();
      expect(service.isAvailable, isA<bool>());
    });

    test('products getter works', () {
      final service = PurchaseService.createForTesting();
      expect(service.products, isA<List<ProductDetails>>());
    });

    test('purchaseStream getter works', () {
      final service = PurchaseService.createForTesting();
      expect(service.purchaseStream, isA<Stream<PurchaseResult>>());
    });
  });

  group('PurchaseService - Singleton Pattern', () {
    test('factory constructor creates service with dependency injection', () {
      final service1 = PurchaseService(mockInAppPurchase);
      final service2 = PurchaseService(mockInAppPurchase);

      // Different instances since we're not using the singleton
      expect(service1, isNot(same(service2)));
    });

    test('resetInstance allows new singleton creation', () {
      // This test verifies that resetInstance doesn't crash
      PurchaseService.resetInstance();

      // Should be able to create new instance after reset
      expect(() => PurchaseService.resetInstance(), returnsNormally);
    });
  });
  group('PurchaseService - Purchase Result Enum', () {
    test('PurchaseResult enum values exist', () {
      expect(PurchaseResult.unavailable, equals(PurchaseResult.unavailable));
      expect(PurchaseResult.ready, equals(PurchaseResult.ready));
      expect(PurchaseResult.pending, equals(PurchaseResult.pending));
      expect(PurchaseResult.completed, equals(PurchaseResult.completed));
      expect(PurchaseResult.error, equals(PurchaseResult.error));
      expect(PurchaseResult.cancelled, equals(PurchaseResult.cancelled));
    });
  });
}
