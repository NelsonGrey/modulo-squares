import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:modulo_squares/core/di/service_locator.dart';
import 'package:modulo_squares/core/services/purchase_service.dart';
import 'package:modulo_squares/features/game/falling_modulo_game_screen.dart';
import 'package:modulo_squares/features/game/models/falling_modulo_game_engine.dart';
import 'package:modulo_squares/gamecenter/fake_game_center_progress_service.dart';
import 'package:modulo_squares/gamecenter/fake_platform_game_auth_service.dart';
import 'package:modulo_squares/gamecenter/game_center_connection.dart';
import 'package:modulo_squares/gamecenter/game_center_services.dart';
import 'package:modulo_squares/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local-only entry point for repeatable YouTube tutorial recording.
///
/// It renders production screens and game controls, but injected callbacks
/// keep Game Center, ads, and network access off. The release application continues to build from `main.dart`.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // The app is iOS-only (Game Center), so capture renders iOS styling.
  debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

  final preferences = await SharedPreferences.getInstance();
  await preferences.setInt('fallingMode.highScore', 401);

  if (!getIt.isRegistered<PurchaseService>()) {
    getIt.registerLazySingleton<PurchaseService>(
      PurchaseService.createForTesting,
    );
  }

  runApp(const YouTubeCaptureApp());
}

class YouTubeCaptureApp extends StatelessWidget {
  const YouTubeCaptureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Modulo Squares Tutorial Capture',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [Locale('en')],
      home: _CaptureRoot(),
    );
  }
}

enum _CaptureScene { menu, navigation, gameplay }

class _CaptureRoot extends StatefulWidget {
  const _CaptureRoot();

  @override
  State<_CaptureRoot> createState() => _CaptureRootState();
}

class _CaptureRootState extends State<_CaptureRoot> {
  _CaptureScene _scene = _CaptureScene.menu;

  void _show(_CaptureScene scene) => setState(() => _scene = scene);

  Widget _buildGame({required bool expertDemo}) {
    return FallingModuloGameScreen(
      engine: YouTubeCaptureGameEngine(),
      expertDemo: expertDemo,
      gameCenter: GameCenterServices(
        auth: FakePlatformGameAuthService(),
        backend: FakeGameCenterProgressService(),
        connection: GameCenterConnection.connectedFake(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const requestedScene = String.fromEnvironment('YOUTUBE_CAPTURE_SCENE');
    if (_scene == _CaptureScene.menu && requestedScene.isNotEmpty) {
      _scene = switch (requestedScene) {
        'navigation' => _CaptureScene.navigation,
        'gameplay' => _CaptureScene.gameplay,
        _ => _CaptureScene.menu,
      };
    }

    return switch (_scene) {
      _CaptureScene.menu => _CaptureMenu(onSelected: _show),
      _CaptureScene.navigation => _buildGame(expertDemo: false),
      _CaptureScene.gameplay => _buildGame(expertDemo: true),
    };
  }
}

class _CaptureMenu extends StatelessWidget {
  const _CaptureMenu({required this.onSelected});

  final ValueChanged<_CaptureScene> onSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          child: Column(
            children: [
              Image.asset('assets/icons/icon.png', width: 88, height: 88),
              const SizedBox(height: 16),
              const Text(
                'Tutorial Capture',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Local-only recording scenes',
                style: TextStyle(color: Colors.white54),
              ),
              const SizedBox(height: 44),
              _CaptureButton(
                label: 'Navigate the App',
                icon: Icons.explore_outlined,
                onPressed: () => onSelected(_CaptureScene.navigation),
              ),
              const SizedBox(height: 14),
              _CaptureButton(
                label: 'Gameplay',
                icon: Icons.sports_esports,
                onPressed: () => onSelected(_CaptureScene.gameplay),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CaptureButton extends StatelessWidget {
  const _CaptureButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF4CAF50),
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}

/// A stable input sequence used by both the gameplay tutorial and app tour.
class YouTubeCaptureGameEngine extends FallingModuloGameEngine {
  YouTubeCaptureGameEngine() : super(random: Random(20260813));

  // Every value stays >= 10 to match the real game's floor on the falling
  // number's range (FallingModuloGameEngine.numberRangeForLevel) -- captured
  // media should never show a value gameplay itself can no longer produce.
  static const _values = <int>[18, 16, 15, 14, 12, 19, 28, 10];
  var _index = 0;

  int _nextValue() => _values[_index++ % _values.length];

  @override
  FallingModuloGameState createInitialState({
    int startingLevel = 1,
    GameDifficulty difficulty = GameDifficulty.normal,
  }) {
    _index = 0;
    return super
        .createInitialState(
          startingLevel: startingLevel,
          difficulty: difficulty,
        )
        .copyWith(currentFallingValue: _nextValue());
  }

  @override
  FallingModuloResolveResult resolveCurrentTile(FallingModuloGameState state) {
    final result = super.resolveCurrentTile(state);
    return FallingModuloResolveResult(
      state: result.state.copyWith(currentFallingValue: _nextValue()),
      resolution: result.resolution,
    );
  }
}
