import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:modulo/screens/game_screen.dart';
// Login screen intentionally not used for launch; auto guest auth.
import 'package:modulo/l10n/app_localizations.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:modulo/utils/analytics_service.dart';
import 'package:modulo/utils/ad_service.dart';
import 'package:modulo/utils/consent_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // Configure consent and ad request settings before initializing ads
  await ConsentService.instance.configure();
  await AdService.instance.initialize();
  AdService.instance.loadInterstitial();
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

  @override
  Widget build(BuildContext context) {
    // Log app open on first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsService.instance.logAppOpen();
    });

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final user = snapshot.data;
        if (user == null) {
          // Auto sign-in anonymously and show a loading indicator until ready.
          FirebaseAuth.instance.signInAnonymously();
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        // Set analytics user id once we have a user
        AnalyticsService.instance.setUserIdFromAuth(user);
        return const GameScreen();
      },
    );
  }
}
