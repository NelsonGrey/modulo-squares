import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:modulo_squares/core/di/service_locator.dart';
import 'package:modulo_squares/core/services/ad_service.dart';
import 'package:modulo_squares/core/services/asset_service.dart';
import 'package:modulo_squares/core/services/cache_service.dart';
import 'package:modulo_squares/core/services/consent_service.dart';
import 'package:modulo_squares/core/services/error_handler.dart';
import 'package:modulo_squares/core/services/purchase_service.dart';
import 'package:modulo_squares/features/game/game_screen.dart';
import 'package:modulo_squares/gamecenter/game_center_services.dart';
import 'package:modulo_squares/gamecenter/game_center_ui.dart';
import 'package:modulo_squares/l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
    // Only reconnects a player who already opted in; a failed sign-in (no
    // Game Center account on the device) lands in GameCenterStatus.unavailable
    // and never blocks the app from starting.
    await runInitStep(
      'game center',
      () => getIt<GameCenterServices>().connection.load(),
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
    return MaterialApp(
      title: 'Modulo Squares',
      debugShowCheckedModeBanner: false,
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
      home: const _Home(),
    );
  }
}

/// The game screen, plus the one-time Game Center invitation on first launch.
class _Home extends StatefulWidget {
  const _Home();

  @override
  State<_Home> createState() => _HomeState();
}

class _HomeState extends State<_Home> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _maybePromptGameCenter(),
    );
  }

  Future<void> _maybePromptGameCenter() async {
    if (!mounted || !getIt.isRegistered<GameCenterServices>()) return;
    final connection = getIt<GameCenterServices>().connection;
    if (connection.shouldPrompt) {
      await showGameCenterPrompt(context, connection);
    }
  }

  @override
  Widget build(BuildContext context) => const GameScreen();
}
