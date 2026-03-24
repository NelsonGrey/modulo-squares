import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:modulo_squares/features/game/game_screen.dart';
import 'package:modulo_squares/features/website/website_screen.dart';
// Login screen intentionally not used for launch; auto guest auth.
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
import 'package:modulo_squares/core/auth/auth_fallback_policy.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error, stackTrace) {
    ErrorHandler().handleFirebaseInitError(error, stackTrace);
    // Continue with limited functionality - some features may not work
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

  runApp(const ModuloApp());
}

class ModuloApp extends StatelessWidget {
  const ModuloApp({super.key});

  @override
  Widget build(BuildContext context) {
    final FirebaseAnalyticsObserver observer = FirebaseAnalyticsObserver(
      analytics: FirebaseAnalytics.instance,
    );
    return MaterialApp(
      title: 'Modulo Squares',
      debugShowCheckedModeBanner: false,
      navigatorObservers: [observer],
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
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  static const Duration _authWaitTimeout = Duration(seconds: 12);
  static const Duration _signInTimeout = Duration(seconds: 10);

  Timer? _authTimer;
  bool _authTimedOut = false;
  bool _allowOffline = false;
  bool _isSigningIn = false;
  String? _authMessage;
  bool _autoSignInAttempted = false;
  bool _retryAuthAllowed = true;

  @override
  void initState() {
    super.initState();
    _startAuthTimer();
    unawaited(_attemptAnonymousSignIn());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      getIt<AnalyticsService>().logAppOpen();
    });
  }

  @override
  void dispose() {
    _authTimer?.cancel();
    super.dispose();
  }

  void _startAuthTimer() {
    _authTimer?.cancel();
    _authTimedOut = false;
    _authTimer = Timer(_authWaitTimeout, () {
      if (!mounted) return;
      setState(() {
        _authTimedOut = true;
        _authMessage ??= 'Authentication is taking longer than expected.';
      });
    });
  }

  Future<void> _attemptAnonymousSignIn({bool userInitiated = false}) async {
    if (_isSigningIn || _allowOffline) return;
    if (!userInitiated && _autoSignInAttempted) return;

    _autoSignInAttempted = true;

    setState(() {
      _isSigningIn = true;
      _authMessage = null;
      _retryAuthAllowed = true;
    });

    try {
      await FirebaseAuth.instance.signInAnonymously().timeout(_signInTimeout);
      if (!mounted) return;
      setState(() {
        _authTimedOut = false;
      });
      _startAuthTimer();
    } catch (error) {
      ErrorHandler().logError('Anonymous sign-in', error);
      if (!mounted) return;
      final decision = evaluateAnonymousSignInError(error);

      // In non-release builds, skip auth wall for hard backend policy blocks.
      if (!decision.allowRetry && !kReleaseMode) {
        _continueOffline();
        return;
      }

      setState(() {
        _authTimedOut = true;
        _authMessage = decision.message;
        _retryAuthAllowed = decision.allowRetry;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSigningIn = false;
        });
      }
    }
  }

  void _continueOffline() {
    _authTimer?.cancel();
    setState(() {
      _allowOffline = true;
    });
  }

  void _retryAuth() {
    if (!_retryAuthAllowed) return;
    _startAuthTimer();
    _autoSignInAttempted = false;
    _attemptAnonymousSignIn(userInitiated: true);
  }

  Widget _buildAuthWaitingScaffold({String? message}) {
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

  Widget _buildAuthFallbackScaffold(String message) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.wifi_off_outlined,
                size: 52,
                color: Colors.orange,
              ),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              if (_retryAuthAllowed)
                ElevatedButton(
                  onPressed: _retryAuth,
                  child: const Text('Retry'),
                ),
              if (_retryAuthAllowed) const SizedBox(height: 8),
              TextButton(
                onPressed: _continueOffline,
                child: const Text('Continue Offline'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_allowOffline) {
      return kIsWeb ? const WebsiteScreen() : const GameScreen();
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          if (_authTimedOut) {
            return _buildAuthFallbackScaffold(
              _authMessage ?? 'Authentication is taking longer than expected.',
            );
          }
          return _buildAuthWaitingScaffold(
            message: _isSigningIn ? 'Signing in...' : null,
          );
        }

        if (snapshot.hasError) {
          // Handle authentication stream errors
          ErrorHandler().logError('Auth stream', snapshot.error);
          return _buildAuthFallbackScaffold(
            'Authentication error. Retry or continue offline.',
          );
        }

        final user = snapshot.data;
        if (user == null) {
          if (_isSigningIn) {
            return _buildAuthWaitingScaffold(
              message: 'Signing in anonymously...',
            );
          }

          return _buildAuthFallbackScaffold(
            _authMessage ??
                'Sign-in is unavailable right now. Retry or continue offline.',
          );
        }

        // Set analytics user id once we have a user
        getIt<AnalyticsService>().setUserIdFromAuth(user);

        // Show promotional website on web, game on mobile
        if (kIsWeb) {
          return const WebsiteScreen();
        } else {
          return const GameScreen();
        }
      },
    );
  }
}
