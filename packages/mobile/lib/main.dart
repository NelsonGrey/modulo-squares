import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:modulo_squares/features/auth/login_screen.dart';
import 'package:modulo_squares/features/game/game_screen.dart';
import 'package:modulo_squares/features/website/website_screen.dart';
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
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      getIt<AnalyticsService>().logAppOpen();
    });
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildAuthWaitingScaffold(message: 'Checking account...');
        }

        if (snapshot.hasError) {
          ErrorHandler().logError('Auth stream', snapshot.error);
          return _buildAuthWaitingScaffold(
            message: 'Authentication is temporarily unavailable.',
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return const LoginScreen();
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
