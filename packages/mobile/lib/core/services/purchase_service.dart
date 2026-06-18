import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:modulo_squares/core/services/error_handler.dart';

/// Test implementation of InAppPurchase for testing
class _TestInAppPurchase implements InAppPurchase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<bool> isAvailable() async => true;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => Stream.empty();

  @override
  Future<ProductDetailsResponse> queryProductDetails(
    Set<String> identifiers,
  ) async {
    return ProductDetailsResponse(
      productDetails: [],
      notFoundIDs: identifiers.toList(),
    );
  }

  @override
  Future<bool> buyConsumable({
    required PurchaseParam purchaseParam,
    bool autoConsume = true,
  }) async => true;

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async =>
      true;

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {}

  @override
  Future<void> restorePurchases({String? applicationUserName}) async {}

  @override
  Future<String> countryCode() async => '';
}

/// Service for handling in-app purchases, specifically ad removal
class PurchaseService {
  PurchaseService._([InAppPurchase? inAppPurchase, bool testMode = false])
    : _inAppPurchase =
          testMode
              ? _TestInAppPurchase()
              : (inAppPurchase ?? InAppPurchase.instance),
      _testMode = testMode;

  static PurchaseService? _instance;

  static PurchaseService get instance {
    _instance ??= PurchaseService._();
    return _instance!;
  }

  // Public constructor for dependency injection and testing
  factory PurchaseService([InAppPurchase? inAppPurchase]) {
    if (inAppPurchase != null) {
      // For testing, create a new instance with the mock
      return PurchaseService._(inAppPurchase);
    }
    return instance;
  }

  // Factory method for testing that creates a testable instance
  factory PurchaseService.createForTesting() {
    return PurchaseService._(null, true);
  }

  static const String _adRemovalProductId = 'remove_ads';
  static const String _premiumProductId = 'premium_version';
  static const String _adRemovalPrefKey = 'ads_removed';
  static const String _premiumPrefKey = 'premium_unlocked';

  final InAppPurchase _inAppPurchase;
  final bool _testMode;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // Method for testing to reset the singleton instance
  static void resetInstance() {
    _instance = null;
  }

  StreamSubscription<List<PurchaseDetails>>? _subscription;

  final StreamController<PurchaseResult> _purchaseController =
      StreamController<PurchaseResult>.broadcast();
  Stream<PurchaseResult> get purchaseStream => _purchaseController.stream;

  List<ProductDetails> _products = [];
  List<ProductDetails> get products => _products;

  bool _adsRemoved = false;
  bool get adsRemoved => _adsRemoved;

  bool _premiumUnlocked = false;
  bool get premiumUnlocked => _premiumUnlocked;

  bool _isAvailable = false;
  bool get isAvailable => _isAvailable;

  /// Initialize the purchase service
  Future<void> initialize() async {
    if (_testMode) {
      // In test mode, skip platform initialization
      _isAvailable = true;
      await _loadPurchaseStates();
      return;
    }

    _isAvailable = await _inAppPurchase.isAvailable();

    if (!_isAvailable) {
      _purchaseController.add(PurchaseResult.unavailable);
      return;
    }

    // Load saved purchase states
    await _loadPurchaseStates();
    await _refreshEntitlementsFromServer();

    // Listen to purchase updates
    _subscription = _inAppPurchase.purchaseStream.listen(
      _handlePurchaseUpdate,
      onDone: () => _subscription?.cancel(),
      onError: (error) => _purchaseController.addError(error),
    );

    // Query product details
    await _queryProductDetails();

    _purchaseController.add(PurchaseResult.ready);
  }

  /// Query available products from the store
  Future<void> _queryProductDetails() async {
    final Set<String> productIds = {_adRemovalProductId, _premiumProductId};
    final ProductDetailsResponse response = await _inAppPurchase
        .queryProductDetails(productIds);

    if (response.error != null) {
      ErrorHandler().logError('Query product details', response.error);
      _purchaseController.addError(response.error!);
      return;
    }

    _products = response.productDetails;
  }

  /// Handle purchase updates from the store
  void _handlePurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          _purchaseController.add(PurchaseResult.pending);
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          unawaited(_completePurchase(purchaseDetails));
          break;
        case PurchaseStatus.error:
          ErrorHandler().logError('Purchase error', purchaseDetails.error);
          _purchaseController.add(PurchaseResult.error);
          break;
        case PurchaseStatus.canceled:
          _purchaseController.add(PurchaseResult.cancelled);
          break;
      }

      // Mark purchase as consumed/delivered
      if (purchaseDetails.pendingCompletePurchase) {
        _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  /// Complete a successful purchase
  Future<void> _completePurchase(PurchaseDetails purchaseDetails) async {
    final String productId = purchaseDetails.productID;

    try {
      if (_testMode) {
        // Keep tests deterministic without network dependencies.
        switch (productId) {
          case _adRemovalProductId:
            _adsRemoved = true;
            await _savePurchaseState(_adRemovalPrefKey, true);
            break;
          case _premiumProductId:
            _premiumUnlocked = true;
            _adsRemoved = true;
            await _savePurchaseState(_premiumPrefKey, true);
            await _savePurchaseState(_adRemovalPrefKey, true);
            break;
        }
        _purchaseController.add(PurchaseResult.completed);
        return;
      }

      final receipt = purchaseDetails.verificationData.serverVerificationData;
      final transactionId = purchaseDetails.purchaseID ?? '';
      final platform = _resolvePlatform();

      final result = await _functions.httpsCallable('validatePurchase').call({
        'productId': productId,
        'purchaseToken': receipt,
        'transactionId': transactionId,
        'platform': platform,
      });

      final data = Map<String, dynamic>.from(
        (result.data as Map?) ?? <String, dynamic>{},
      );
      final entitlements = Map<String, dynamic>.from(
        (data['entitlements'] as Map?) ?? <String, dynamic>{},
      );

      _adsRemoved = entitlements['adsRemoved'] == true;
      _premiumUnlocked = entitlements['premiumUnlocked'] == true;
      await _savePurchaseState(_adRemovalPrefKey, _adsRemoved);
      await _savePurchaseState(_premiumPrefKey, _premiumUnlocked);

      _purchaseController.add(PurchaseResult.completed);
    } catch (error) {
      ErrorHandler().logError('Complete purchase validation', error);
      _purchaseController.add(PurchaseResult.error);
    }
  }

  /// Initiate purchase for ad removal
  Future<void> purchaseAdRemoval() async {
    await _purchaseProduct(_adRemovalProductId);
  }

  /// Initiate purchase for premium version
  Future<void> purchasePremium() async {
    await _purchaseProduct(_premiumProductId);
  }

  /// Purchase a specific product
  Future<void> _purchaseProduct(String productId) async {
    final ProductDetails? product = _products
        .cast<ProductDetails?>()
        .firstWhere((element) => element?.id == productId, orElse: () => null);

    if (product == null) {
      final error = 'Product not found: $productId';
      ErrorHandler().logError('Purchase product', error);
      _purchaseController.addError(error);
      return;
    }

    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
  }

  /// Restore previous purchases
  Future<void> restorePurchases() async {
    await _inAppPurchase.restorePurchases();
    await _refreshEntitlementsFromServer();
  }

  /// Load saved purchase states from SharedPreferences
  Future<void> _loadPurchaseStates() async {
    final prefs = await SharedPreferences.getInstance();
    _adsRemoved = prefs.getBool(_adRemovalPrefKey) ?? false;
    _premiumUnlocked = prefs.getBool(_premiumPrefKey) ?? false;
  }

  Future<void> _refreshEntitlementsFromServer() async {
    if (_testMode) return;
    try {
      final result = await _functions.httpsCallable('getEntitlements').call();
      final data = Map<String, dynamic>.from(
        (result.data as Map?) ?? <String, dynamic>{},
      );

      _adsRemoved = data['adsRemoved'] == true;
      _premiumUnlocked = data['premiumUnlocked'] == true;

      await _savePurchaseState(_adRemovalPrefKey, _adsRemoved);
      await _savePurchaseState(_premiumPrefKey, _premiumUnlocked);
    } catch (error) {
      ErrorHandler().logError('Refresh entitlements', error);
    }
  }

  String _resolvePlatform() {
    final source = _inAppPurchase.toString().toLowerCase();
    if (source.contains('storekit') ||
        source.contains('ios') ||
        source.contains('apple')) {
      return 'ios';
    }
    return 'android';
  }

  /// Save purchase state to SharedPreferences
  Future<void> _savePurchaseState(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  /// Get formatted price for a product
  String getProductPrice(String productId) {
    final product = _products.firstWhere(
      (element) => element.id == productId,
      orElse:
          () => ProductDetails(
            id: productId,
            title: 'Unknown Product',
            description: '',
            price: '\$0.00',
            rawPrice: 0.0,
            currencyCode: 'USD',
          ),
    );
    return product.price;
  }

  /// Check if a product is already purchased
  bool isProductPurchased(String productId) {
    switch (productId) {
      case _adRemovalProductId:
        return _adsRemoved;
      case _premiumProductId:
        return _premiumUnlocked;
      default:
        return false;
    }
  }

  /// Dispose of resources
  void dispose() {
    _subscription?.cancel();
    _purchaseController.close();
  }
}

/// Purchase result enum for our service
enum PurchaseResult { unavailable, ready, pending, completed, error, cancelled }
