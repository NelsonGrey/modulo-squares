import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (error, stackTrace) {
    ErrorHandler().handleFirebaseInitError(error, stackTrace);
    // Continue with limited functionality - some features may not work
  }

  // Setup dependency injection
  setupServiceLocator();

  try {
    // Configure consent and ad request settings before initializing ads (mobile only)
    if (!kIsWeb) {
      await getIt<ConsentService>().configure();
      await getIt<AdService>().initialize();
      await getIt<PurchaseService>().initialize();
    }
    await CacheService().initialize();
    await AssetService().preloadAssets();
    if (!kIsWeb) {
      getIt<AdService>().loadInterstitial();
    }
  } catch (error, stackTrace) {
    ErrorHandler().logError('Service initialization', error, stackTrace);
    // Continue - services will handle their own errors gracefully
  }

  runApp(const ModuloApp());
}

class ModuloApp extends StatelessWidget {
  const ModuloApp({super.key});

  @override
  Widget build(BuildContext context) {
    final FirebaseAnalyticsObserver observer = FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance);
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

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<void> _attemptAnonymousSignIn(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signInAnonymously();
    } catch (error) {
      if (context.mounted) {
        ErrorHandler().showErrorSnackBar(context, ErrorHandler().getAuthErrorMessage(error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Log app open on first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getIt<AnalyticsService>().logAppOpen();
    });

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasError) {
          // Handle authentication stream errors
          ErrorHandler().logError('Auth stream', snapshot.error);
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Authentication Error'),
                  const SizedBox(height: 8),
                  const Text('Please restart the app or check your connection.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        await FirebaseAuth.instance.signInAnonymously();
                      } catch (error) {
                        if (context.mounted) {
                          ErrorHandler().showErrorSnackBar(context, ErrorHandler().getAuthErrorMessage(error));
                        }
                      }
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          // Auto sign-in anonymously and show a loading indicator until ready.
          _attemptAnonymousSignIn(context);
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
