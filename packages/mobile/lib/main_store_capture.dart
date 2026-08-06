import 'dart:math';

import 'package:flutter/material.dart';
import 'package:modulo_squares/core/di/service_locator.dart';
import 'package:modulo_squares/core/services/purchase_service.dart';
import 'package:modulo_squares/features/game/falling_modulo_game_screen.dart';
import 'package:modulo_squares/features/game/models/falling_modulo_game_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A local-only entry point for deterministic App Store and Play Store media.
///
/// It bypasses authentication, analytics, ads, and network initialization while
/// rendering the same production gameplay widget. The normal app entry point
/// remains `main.dart`; release builds do not reference this file.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final preferences = await SharedPreferences.getInstance();
  await preferences.setInt('fallingMode.highScore', 401);
  await preferences.setBool('fallingMode.visualCuesEnabled', true);

  if (!getIt.isRegistered<PurchaseService>()) {
    getIt.registerLazySingleton<PurchaseService>(
      PurchaseService.createForTesting,
    );
  }

  runApp(const StoreCaptureApp());
}

class StoreCaptureApp extends StatelessWidget {
  const StoreCaptureApp({super.key});

  @override
  Widget build(BuildContext context) {
    const expertDemo = bool.fromEnvironment('STORE_CAPTURE_EXPERT_DEMO');

    return MaterialApp(
      title: 'Modulo Squares',
      debugShowCheckedModeBanner: false,
      home: FallingModuloGameScreen(
        engine: StoreCaptureGameEngine(),
        expertDemo: expertDemo,
      ),
    );
  }
}

/// Supplies a repeatable sequence of valid in-range numbers for store media.
/// Movement, timing, divisor selection, scoring, combos, and progress continue
/// to use the production game engine unchanged.
class StoreCaptureGameEngine extends FallingModuloGameEngine {
  StoreCaptureGameEngine() : super(random: Random(20260803));

  static const _promoValues = <int>[
    18,
    16,
    15,
    14,
    12,
    9,
    8,
    18,
    10,
    16,
    15,
    12,
    14,
    9,
    18,
    8,
  ];

  var _promoValueIndex = 0;

  int _nextPromoValue() {
    final value = _promoValues[_promoValueIndex % _promoValues.length];
    _promoValueIndex++;
    return value;
  }

  @override
  FallingModuloGameState createInitialState({
    int startingLevel = 1,
    bool visualCuesEnabled = true,
  }) {
    _promoValueIndex = 0;
    return super
        .createInitialState(
          startingLevel: startingLevel,
          visualCuesEnabled: visualCuesEnabled,
        )
        .copyWith(currentFallingValue: _nextPromoValue());
  }

  @override
  FallingModuloResolveResult resolveCurrentTile(FallingModuloGameState state) {
    final result = super.resolveCurrentTile(state);
    return FallingModuloResolveResult(
      state: result.state.copyWith(currentFallingValue: _nextPromoValue()),
      resolution: result.resolution,
    );
  }
}
