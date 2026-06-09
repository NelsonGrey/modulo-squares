# Modulo Squares - Backend Services Integration Guide

## Overview

Modulo Squares integrates multiple Firebase services and third-party APIs to provide a complete backend platform. This guide covers architecture, configuration, and implementation details.

---

## Firebase Services

### 1. Firebase Authentication

**Purpose**: User identity and authentication

#### Configuration

```dart
// lib/core/config/firebase_options.dart
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return iOS;
      case TargetPlatform.android:
        return android;
      case TargetPlatform.web:
        return web;
      default:
        throw UnsupportedError('Unsupported platform');
    }
  }

  static const FirebaseOptions iOS = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_API_KEY_IOS'),
    appId: String.fromEnvironment('FIREBASE_APP_ID_IOS'),
    messagingSenderId: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'),
    projectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
    storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET'),
    iosBundleId: String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID'),
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_API_KEY_ANDROID'),
    appId: String.fromEnvironment('FIREBASE_APP_ID_ANDROID'),
    messagingSenderId: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'),
    projectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
    storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET'),
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_API_KEY_WEB'),
    appId: String.fromEnvironment('FIREBASE_APP_ID_WEB'),
    messagingSenderId: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'),
    projectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
    storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET'),
  );
}
```

#### Initialization

```dart
// lib/main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error, stackTrace) {
    ErrorHandler().handleFirebaseInitError(error, stackTrace);
  }

  runApp(const ModuloApp());
}
```

#### Anonymous Authentication

```dart
// lib/features/auth/auth_service.dart
class AuthService {
  static AuthService get instance => _instance;
  static const _instance = AuthService._();

  Future<UserCredential> signInAnonymously() async {
    try {
      final userCredential = 
        await FirebaseAuth.instance.signInAnonymously();
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        code: e.code,
        message: e.message ?? 'Anonymous sign-in failed',
      );
    }
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  User? get currentUser => FirebaseAuth.instance.currentUser;

  Stream<User?> get authStateChanges => 
    FirebaseAuth.instance.authStateChanges();
}
```

**Flow**:
```
App Launch
    ↓
Check auth state
    ↓
If not authenticated: signInAnonymously()
    ↓
Receive UserCredential
    ↓
Access UID for Firestore operations
```

---

### 2. Cloud Firestore

**Purpose**: Real-time NoSQL database for all persistent data

#### Connection & Configuration

```dart
// lib/core/services/firestore_service.dart
class FirestoreService {
  static final _instance = FirestoreService._();

  factory FirestoreService() => _instance;

  FirestoreService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Configure for offline support
  Future<void> configure() async {
    await _firestore.settings = Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      host: kIsWeb ? 'firestore.googleapis.com' : null,
      sslEnabled: !kIsWeb,
    );
  }

  // Collection access
  CollectionReference<Map<String, dynamic>> get leaderboard =>
    _firestore.collection('modulo_leaderboard');

  DocumentReference<Map<String, dynamic>> userPurchases(String uid) =>
    _firestore.collection('purchases').doc(uid);

  DocumentReference<Map<String, dynamic>> userProfile(String uid) =>
    _firestore.collection('user_profiles').doc(uid);

  DocumentReference<Map<String, dynamic>> userStats(String uid) =>
    _firestore.collection('game_stats').doc(uid);
}
```

#### Leaderboard Service

```dart
// lib/core/services/leaderboard_service.dart
class LeaderboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AnalyticsService _analytics;

  LeaderboardService({required AnalyticsService analytics})
    : _analytics = analytics;

  // Submit score to leaderboard
  Future<DocumentReference> submitScore({
    required int score,
    required int level,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');

    try {
      return await _firestore
        .collection('modulo_leaderboard')
        .add({
          'userId': uid,
          'userEmail': FirebaseAuth.instance.currentUser?.email ?? 'anonymous',
          'score': score,
          'level': level,
          'timestamp': FieldValue.serverTimestamp(),
        })
        .catchError((error) {
          _analytics.logError(
            'score_submission_failed',
            error.toString(),
          );
          throw Exception('Failed to submit score: $error');
        });
    } catch (error) {
      print('Error submitting score: $error');
      rethrow;
    }
  }

  // Fetch global leaderboard
  Future<List<Map<String, dynamic>>> getGlobalLeaderboard({
    int limit = 100,
  }) async {
    try {
      final snapshot = await _firestore
        .collection('modulo_leaderboard')
        .orderBy('score', descending: true)
        .limit(limit)
        .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (error) {
      print('Error fetching leaderboard: $error');
      return [];
    }
  }

  // Fetch user's personal high scores
  Future<List<Map<String, dynamic>>> getUserHighScores({
    required String uid,
    int limit = 10,
  }) async {
    try {
      final snapshot = await _firestore
        .collection('modulo_leaderboard')
        .where('userId', isEqualTo: uid)
        .orderBy('score', descending: true)
        .limit(limit)
        .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (error) {
      print('Error fetching user scores: $error');
      return [];
    }
  }

  // Listen to top players in real-time
  Stream<List<Map<String, dynamic>>> getTopPlayersStream({
    int limit = 10,
  }) {
    return _firestore
      .collection('modulo_leaderboard')
      .orderBy('score', descending: true)
      .limit(limit)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }
}
```

#### Offline Support

```dart
// Firestore automatically enables offline caching
// Reads from cache when offline, writes queued until online

// Check connection status
final connectivity = await Connectivity().checkConnectivity();
final isOnline = connectivity != ConnectivityResult.none;

// Set persistence on Android/iOS
await FirebaseFirestore.instance.settings = Settings(
  persistenceEnabled: true,
  cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
);
```

---

### 3. Cloud Functions

**Purpose**: Serverless backend API for validation and data operations

#### Function Definition

```javascript
// packages/functions/index.js
import functions from 'firebase-functions';
import admin from 'firebase-admin';
import express from 'express';

const app = express();
admin.initializeApp();

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    service: 'modulo-squares-api'
  });
});

// Score submission function
exports.submitScore = functions.https.onCall(
  async (data, context) => {
    // Verify authentication
    const user = FunctionsAuthHelpers.verifyAuthenticated(context);
    const { uid, email } = user;

    // Validate input
    const { score, level } = data;
    if (typeof score !== 'number' || score < 0) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Invalid score'
      );
    }

    try {
      // Store in Firestore
      const docRef = await admin.firestore()
        .collection('modulo_leaderboard')
        .add({
          userId: uid,
          userEmail: email || 'anonymous',
          score,
          level,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });

      return {
        success: true,
        scoreId: docRef.id,
        data: { userId: uid, score, level }
      };
    } catch (error) {
      console.error('Score submission error:', error);
      throw new functions.https.HttpsError(
        'internal',
        'Failed to submit score',
        error.message
      );
    }
  }
);

// Export Express app for Docker
export default app;
```

#### CloudFunctions Helper Class

```dart
// lib/core/services/cloud_functions_service.dart
class CloudFunctionsService {
  static final _instance = CloudFunctionsService._();

  factory CloudFunctionsService() => _instance;

  CloudFunctionsService._();

  final HttpsCallable _submitScore = 
    FirebaseFunctions.instance.httpsCallable(
      'submitScore',
      options: HttpsCallableOptions(
        timeout: const Duration(seconds: 30),
      ),
    );

  Future<Map<String, dynamic>> submitScore({
    required int score,
    required int level,
  }) async {
    try {
      final result = await _submitScore.call({
        'score': score,
        'level': level,
      });
      
      return result.data as Map<String, dynamic>;
    } on FirebaseFunctionsException catch (error) {
      print('Function error: ${error.code} - ${error.message}');
      rethrow;
    }
  }
}
```

---

### 4. Firebase Analytics

**Purpose**: Event tracking and user behavior analysis

#### Service Implementation

```dart
// lib/core/services/analytics_service.dart
class AnalyticsService {
  static const _instance = AnalyticsService._();

  factory AnalyticsService() => _instance;

  AnalyticsService._();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Set user ID from Firebase Auth
  Future<void> setUserIdFromAuth(User? user) async {
    if (user != null) {
      await _analytics.setUserId(id: user.uid);
    }
  }

  // App lifecycle events
  Future<void> logAppOpen() async {
    await _analytics.logAppOpen();
  }

  // Game events
  Future<void> logLevelStart({
    required int level,
    required int rows,
    required int cols,
  }) async {
    await _analytics.logEvent(
      name: 'level_start',
      parameters: {
        'level': level,
        'rows': rows,
        'cols': cols,
      },
    );
  }

  Future<void> logLevelComplete({
    required int level,
    required int score,
  }) async {
    await _analytics.logEvent(
      name: 'level_complete',
      parameters: {
        'level': level,
        'score': score,
      },
    );
  }

  Future<void> logMove({required String type}) async {
    await _analytics.logEvent(
      name: 'move',
      parameters: {'type': type}, // 'tap' or 'swipe'
    );
  }

  Future<void> logGameOver({required int score}) async {
    await _analytics.logEvent(
      name: 'game_over',
      parameters: {'score': score},
    );
  }

  // Feature events
  Future<void> logViewInstructions() async {
    await _analytics.logEvent(name: 'view_instructions');
  }

  Future<void> logViewLeaderboard() async {
    await _analytics.logEvent(name: 'view_leaderboard');
  }

  // Ad events
  Future<void> logAdImpression({required String adType}) async {
    await _analytics.logAdImpression(
      adPlatform: 'admob',
      adFormat: adType, // 'banner', 'interstitial', etc
      value: 0.0,
      currency: 'USD',
    );
  }

  // IAP events
  Future<void> logInAppPurchase({
    required String productId,
    required double price,
    required String currency,
  }) async {
    await _analytics.logEvent(
      name: 'in_app_purchase',
      parameters: {
        'product_id': productId,
        'price': price,
        'currency': currency,
      },
    );
  }

  // Error events
  Future<void> logError(String error, String? stackTrace) async {
    await _analytics.logEvent(
      name: 'error_event',
      parameters: {
        'error': error,
        'stack_trace': stackTrace,
      },
    );
  }
}
```

#### Event Management

```dart
// Typical game session events:
// 1. app_open - User launches app
// 2. level_start - Player starts level
// 3. move - Player makes move (logged frequently)
// 4. level_complete - Level won
// 5. game_over - Level lost
// 6. view_leaderboard - User checks scores
// 7. in_app_purchase - User buys something
// 8. ad_impression - Ad shown

// These create heatmaps in Analytics Dashboard
```

---

### 5. Firebase Hosting

**Purpose**: Static website and web app hosting

#### Deployment

```bash
# Deploy web app
firebase deploy --only hosting

# Deploy specific target
firebase deploy --only hosting:web

# Staging deployment
firebase deploy --only hosting:staging
```

#### Configuration

```json
// firebase.json
{
  "hosting": {
    "public": "packages/web/dist",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ],
    "headers": [
      {
        "source": "**/*.@(js|css|ico|ttf|woff|woff2)",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "max-age=31536000"
          }
        ]
      }
    ]
  }
}
```

---

## Third-Party Services

### 1. Google AdMob

**Purpose**: In-app advertising and monetization

#### Configuration

```dart
// lib/core/services/ad_service.dart
class AdService {
  static const _instance = AdService._();

  factory AdService() => _instance;

  AdService._();

  final MobileAds _mobileAds = MobileAds.instance;

  // Initialize AdMob
  Future<void> initialize() async {
    if (kIsWeb) return; // Not available on web

    try {
      await _mobileAds.initialize();
      _loadInterstitialAd();
    } catch (error) {
      print('AdMob initialization failed: $error');
    }
  }

  // Banner Ad
  BannerAd createBannerAd() {
    return BannerAd(
      adUnitId: _getBannerAdUnitId(),
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => print('Banner ad loaded'),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          print('Banner ad failed: $error');
        },
      ),
    );
  }

  // Interstitial Ad (between levels)
  InterstitialAd? _interstitialAd;

  Future<void> _loadInterstitialAd() async {
    try {
      await InterstitialAd.load(
        adUnitId: _getInterstitialAdUnitId(),
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAd = ad;
          },
          onAdFailedToLoad: (error) {
            print('Interstitial ad failed: $error');
          },
        ),
      );
    } catch (error) {
      print('Failed to load interstitial: $error');
    }
  }

  void showInterstitial({
    required String trigger,
    required int levelNum,
    required VoidCallback onClosed,
  }) {
    if (_interstitialAd == null) {
      onClosed();
      return;
    }

    _interstitialAd?.fullScreenContentCallback = 
      FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _loadInterstitialAd(); // Reload for next time
          onClosed();
        },
      );

    _interstitialAd?.show();
  }

  String _getBannerAdUnitId() => 
    Platform.isAndroid 
      ? 'ca-app-pub-3940256099942544/6300978111' // Test ID
      : 'ca-app-pub-3940256099942544/2934735716'; // Test ID

  String _getInterstitialAdUnitId() =>
    Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/1033173712' // Test ID
      : 'ca-app-pub-3940256099942544/4411468910'; // Test ID
}
```

#### Ad Placement Strategy

```dart
// Show banner ad during gameplay
@override
Widget build(BuildContext context) {
  return Stack(
    children: [
      GameScreen(),
      Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: BannerAdWidget(
          bannerAd: _bannerAd,
        ),
      ),
    ],
  );
}

// Show interstitial ad on level completion
void completeLevel(VoidCallback onAdClosed) {
  gameProvider.completeLevel(() {
    _adService.showInterstitial(
      trigger: 'level_complete',
      levelNum: gameProvider.level,
      onClosed: onAdClosed,
    );
  });
}
```

---

### 2. In-App Purchases (RevenueCat)

**Purpose**: Monetization through premium features

#### Service Implementation

```dart
// lib/core/services/purchase_service.dart
class PurchaseService {
  static const _instance = PurchaseService._();

  factory PurchaseService() => _instance;

  PurchaseService._();

  final Purchases _purchases = Purchases.instance;

  Future<void> initialize() async {
    if (kIsWeb) return;

    try {
      await _purchases.configure(
        PurchasesConfiguration(
          'goog_<YOUR_PUBLIC_API_KEY>', // Google Play
        )
        ..appUserID = FirebaseAuth.instance.currentUser?.uid,
      );
    } catch (error) {
      print('RevenueCat initialization failed: $error');
    }
  }

  // Get available offerings
  Future<Offerings?> getOfferings() async {
    try {
      return await _purchases.getOfferings();
    } catch (error) {
      print('Error loading offerings: $error');
      return null;
    }
  }

  // Perform purchase
  Future<CustomerInfo> purchasePackage(Package package) async {
    try {
      final customerInfo = await _purchases.purchasePackage(package);
      
      // Log purchase
      FirebaseAnalytics.instance.logEvent(
        name: 'in_app_purchase',
        parameters: {
          'product_id': package.identifier,
          'price': package.storeProduct.price,
        },
      );

      return customerInfo;
    } catch (error) {
      print('Purchase failed: $error');
      rethrow;
    }
  }

  // Check if user has "remove ads" entitlement
  Future<bool> hasRemoveAdsEntitlement() async {
    try {
      final customerInfo = await _purchases.getCustomerInfo();
      return customerInfo.entitlements.active.containsKey('remove_ads');
    } catch (error) {
      print('Error checking entitlements: $error');
      return false;
    }
  }

  // Restore purchases
  Future<CustomerInfo> restorePurchases() async {
    try {
      return await _purchases.restorePurchases();
    } catch (error) {
      print('Restore failed: $error');
      rethrow;
    }
  }
}
```

---

## Service Locator & DI Setup

### Complete Setup

```dart
// lib/core/di/service_locator.dart
void setupServiceLocator() {
  // Core services
  getIt.registerSingleton<AnalyticsService>(AnalyticsService());
  getIt.registerSingleton<AdService>(AdService());
  getIt.registerSingleton<PurchaseService>(PurchaseService());
  getIt.registerSingleton<ConsentService>(ConsentService());
  getIt.registerSingleton<CacheService>(CacheService());
  getIt.registerSingleton<AssetService>(AssetService());
  getIt.registerSingleton<LeaderboardService>(
    LeaderboardService(analytics: getIt<AnalyticsService>()),
  );
  getIt.registerSingleton<CloudFunctionsService>(CloudFunctionsService());
  getIt.registerSingleton<ErrorHandler>(ErrorHandler());

  // Firebase services
  getIt.registerSingleton<FirebaseFirestore>(FirebaseFirestore.instance);
  getIt.registerSingleton<FirebaseAuth>(FirebaseAuth.instance);
}

// Usage in features
final analytics = getIt<AnalyticsService>();
final ads = getIt<AdService>();
final purchases = getIt<PurchaseService>();
```

---

## Monitoring & Observability

### Error Tracking

```dart
// lib/core/services/error_handler.dart
class ErrorHandler {
  static const _instance = ErrorHandler._();

  factory ErrorHandler() => _instance;

  ErrorHandler._();

  void logError(String context, dynamic error, StackTrace? stackTrace) {
    print('Error [$context]: $error');
    if (stackTrace != null) {
      print(stackTrace);
    }

    // Log to Firebase Analytics
    FirebaseAnalytics.instance.logEvent(
      name: 'error_event',
      parameters: {
        'error_context': context,
        'error_message': error.toString(),
        'stack_trace': stackTrace?.toString() ?? '',
      },
    );

    // Optionally send to Crashlytics
    FirebaseCrashlytics.instance.recordError(error, stackTrace);
  }

  String getAuthErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      return switch(error.code) {
        'user-not-found' => 'User not found',
        'wrong-password' => 'Incorrect password',
        'invalid-email' => 'Invalid email',
        'weak-password' => 'Password too weak',
        'email-already-in-use' => 'Email already registered',
        _ => 'Authentication failed: ${error.message}',
      };
    }
    return 'Unknown authentication error';
  }

  void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
```

---

## Performance Best Practices

### Database Queries

```dart
// ✅ Good: Efficient query
db.collection('modulo_leaderboard')
  .where('userId', isEqualTo: uid)
  .orderBy('score', descending: true)
  .limit(10)
  .get()

// ❌ Bad: Inefficient (loads all docs)
db.collection('modulo_leaderboard')
  .get()
  .then((snapshot) => snapshot.docs
    .where((doc) => doc['userId'] == uid)
    .toList())
```

### Caching Strategy

```dart
// Cache frequently accessed data
class LeaderboardService {
  List<ScoreEntry>? _cachedTopScores;
  DateTime? _cacheTime;

  Future<List<ScoreEntry>> getTopScores() async {
    final now = DateTime.now();
    final cacheValid = _cacheTime != null &&
        now.difference(_cacheTime!).inMinutes < 5;

    if (cacheValid && _cachedTopScores != null) {
      return _cachedTopScores!;
    }

    final scores = await _fetchTopScoresFromFirestore();
    _cachedTopScores = scores;
    _cacheTime = now;
    return scores;
  }
}
```

---

## Related Documentation

- [System Architecture](SYSTEM_ARCHITECTURE.md)
- [Database Schema](DATABASE_SCHEMA.md)
- [API Documentation](API_DOCUMENTATION.md)
- [Security Guidelines](SECURITY.md)
