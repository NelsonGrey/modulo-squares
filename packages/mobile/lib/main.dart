import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:modulo_squares/features/auth/login_screen.dart';
import 'package:modulo_squares/features/auth/gamertag_screen.dart';
import 'package:modulo_squares/features/game/game_screen.dart';
import 'package:modulo_squares/features/website/website_screen.dart';
import 'package:modulo_squares/core/services/gamertag_service.dart';
import 'package:modulo_squares/l10n/app_localizations.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:modulo_squares/core/services/analytics_service.dart';
import 'package:modulo_squares/core/services/ad_service.dart';
import 'package:modulo_squares/core/services/consent_service.dart';
import 'package:modulo_squares/core/services/purchase_service.dart';
import 'package:modulo_squares/core/config/firebase_options.dart';
import 'package:modulo_squares/core/services/error_handler.dart';
import 'package:modulo_squares/core/services/cache_service.dart';
import 'package:modulo_squares/core/services/asset_service.dart';
import 'package:modulo_squares/core/di/service_locator.dart';

Future<bool> initializeFirebaseApp() async {
  if (Firebase.apps.isNotEmpty) {
    return true;
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    return true;
  } on FirebaseException catch (error, stackTrace) {
    // Treat duplicate-app as healthy if a default app already exists.
    if (error.code == 'duplicate-app' && Firebase.apps.isNotEmpty) {
      return true;
    }

    ErrorHandler().handleFirebaseInitError(error, stackTrace);
    return Firebase.apps.isNotEmpty;
  } catch (error, stackTrace) {
    ErrorHandler().handleFirebaseInitError(error, stackTrace);
    return Firebase.apps.isNotEmpty;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final firebaseReady = await initializeFirebaseApp();

  // Wire Crashlytics fatal error handlers as early as possible.
  if (!kIsWeb && firebaseReady) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  // Activate App Check before any Firebase service calls.
  //
  // Pass --dart-define=APP_CHECK_DEBUG=true when building a dev-signed build
  // for device testing. The debug provider generates a UUID on first launch
  // (visible in the device log) — register it in Firebase Console →
  // App Check → your iOS app → Manage debug tokens.
  //
  // App Store / TestFlight builds omit the flag and use App Attest with
  // DeviceCheck as the fallback for older devices.
  const bool appCheckDebug =
      bool.fromEnvironment('APP_CHECK_DEBUG', defaultValue: false);
  const String appCheckDebugToken =
      String.fromEnvironment('APP_CHECK_DEBUG_TOKEN', defaultValue: '');

  if (firebaseReady && !kIsWeb) {
    try {
      await FirebaseAppCheck.instance.activate(
        providerApple: appCheckDebug
            ? AppleDebugProvider(
                debugToken: appCheckDebugToken.isNotEmpty
                    ? appCheckDebugToken
                    : null,
              )
            : const AppleAppAttestWithDeviceCheckFallbackProvider(),
      );

      if (appCheckDebug) {
        // Immediately verify the debug token is accepted by Firebase.
        // If this throws, the UUID is not registered in Firebase Console
        // under App Check → your iOS app → Manage debug tokens.
        try {
          await FirebaseAppCheck.instance.getToken(true);
          debugPrint('[AppCheck] Debug token accepted by Firebase ✓');
        } catch (e) {
          debugPrint('[AppCheck] Debug token REJECTED: $e');
          debugPrint('[AppCheck] Register UUID in Firebase Console → '
              'App Check → iOS app → Manage debug tokens');
          if (appCheckDebugToken.isNotEmpty) {
            debugPrint('[AppCheck] Token to register: $appCheckDebugToken');
          }
        }
      }
    } catch (e) {
      ErrorHandler().logError('App Check activation', e);
    }
  }

  // Setup dependency injection
  setupServiceLocator();

  Future<void> runInitStep(String label, Future<void> Function() step) async {
    try {
      await step();
    } catch (error, stackTrace) {
      ErrorHandler().logError(
        'Service initialization: $label',
        error,
        stackTrace,
      );
    }
  }

  // Configure services independently so one timeout does not block the rest.
  if (!kIsWeb) {
    await runInitStep(
      'consent',
      () => getIt<ConsentService>().configure().timeout(
        const Duration(seconds: 8),
      ),
    );
    await runInitStep(
      'ads',
      () => getIt<AdService>().initialize().timeout(const Duration(seconds: 8)),
    );
    await runInitStep(
      'purchases',
      () => getIt<PurchaseService>().initialize().timeout(
        const Duration(seconds: 8),
      ),
    );
  }

  await runInitStep(
    'cache',
    () => CacheService().initialize().timeout(const Duration(seconds: 8)),
  );
  await runInitStep(
    'assets',
    () => AssetService().preloadAssets().timeout(const Duration(seconds: 8)),
  );

  if (!kIsWeb) {
    await runInitStep('preload interstitial', () async {
      getIt<AdService>().loadInterstitial();
    });
  }

  runApp(ModuloApp(firebaseReady: firebaseReady));
}

class ModuloApp extends StatefulWidget {
  const ModuloApp({super.key, required this.firebaseReady});

  final bool firebaseReady;

  @override
  State<ModuloApp> createState() => _ModuloAppState();
}

class _ModuloAppState extends State<ModuloApp> {
  late bool _firebaseReady = widget.firebaseReady;
  bool _retryingFirebase = false;

  Future<void> _retryFirebaseInitialization() async {
    if (_retryingFirebase) {
      return;
    }

    setState(() {
      _retryingFirebase = true;
    });

    final firebaseReady = await initializeFirebaseApp();
    if (!mounted) {
      return;
    }

    setState(() {
      _firebaseReady = firebaseReady;
      _retryingFirebase = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final navigatorObservers = <NavigatorObserver>[];
    if (_firebaseReady && Firebase.apps.isNotEmpty) {
      navigatorObservers.add(
        FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
      );
    }

    return MaterialApp(
      title: 'Modulo Squares',
      debugShowCheckedModeBanner: false,
      navigatorObservers: navigatorObservers,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        // Add other supported locales here
      ],
      home:
          _firebaseReady
              ? const AuthGate()
              : FirebaseRecoveryScreen(
                isRetrying: _retryingFirebase,
                onRetry: _retryFirebaseInitialization,
              ),
    );
  }
}

class FirebaseRecoveryScreen extends StatelessWidget {
  const FirebaseRecoveryScreen({
    super.key,
    required this.isRetrying,
    required this.onRetry,
  });

  final bool isRetrying;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 56),
              const SizedBox(height: 16),
              const Text(
                'Unable to start app services',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              const Text(
                'The app could not reconnect to required services during launch. Retry initialization to continue.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isRetrying ? null : () => onRetry(),
                child: Text(isRetrying ? 'Retrying...' : 'Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _checkedUid;
  bool _hasGamertag = false;
  bool _loadingGamertag = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getIt<AnalyticsService>().logAppOpen();
    });
  }

  void _checkGamertagForUser(String uid) {
    if (_checkedUid == uid) return;
    _checkedUid = uid;
    setState(() => _loadingGamertag = true);
    // Pre-load the interstitial now so it has maximum time to arrive before
    // the user finishes creating their gamertag.
    if (!kIsWeb && getIt.isRegistered<AdService>()) {
      getIt<AdService>().loadInterstitial();
    }
    GamertagService.getGamertag(uid).then((tag) {
      if (mounted) {
        setState(() {
          _hasGamertag = tag != null && tag.isNotEmpty;
          _loadingGamertag = false;
        });
      }
    });
  }

  void _onGamertagSet() {
    if (!kIsWeb && getIt.isRegistered<AdService>()) {
      getIt<AdService>().showInterstitial(
        trigger: 'gamertag_complete',
        onClosed: () {
          if (mounted) setState(() => _hasGamertag = true);
        },
      );
    } else {
      setState(() => _hasGamertag = true);
    }
  }

  Widget _buildWaiting({String? message}) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (message != null) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(message, textAlign: TextAlign.center),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildWaiting(message: 'Checking account...');
        }

        if (snapshot.hasError) {
          ErrorHandler().logError('Auth stream', snapshot.error);
          return _buildWaiting(message: 'Authentication is temporarily unavailable.');
        }

        final user = snapshot.data;
        if (user == null) {
          _checkedUid = null;
          return const LoginScreen();
        }

        getIt<AnalyticsService>().setUserIdFromAuth(user);

        _checkGamertagForUser(user.uid);

        if (_loadingGamertag) {
          return _buildWaiting(message: 'Loading profile...');
        }

        if (!_hasGamertag) {
          return GamertagScreen(onGamertagSet: _onGamertagSet);
        }

        return kIsWeb ? const WebsiteScreen() : const GameScreen();
      },
    );
  }
}
