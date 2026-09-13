import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:modulo_squares/features/game/falling_modulo_game_screen.dart';
import 'package:modulo_squares/features/game/game_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'fallingMode.highScore': 77});
  });

  testWidgets('GameScreen launches falling gameplay by default', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const MaterialApp(home: GameScreen()));
    await tester.pump();

    expect(find.byType(FallingModuloGameScreen), findsOneWidget);
    expect(find.text('Modulo Squares'), findsWidgets);
  });

  testWidgets('GameScreen surfaces falling controls and HUD', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const MaterialApp(home: GameScreen()));
    await tester.pump();

    expect(find.text('Left'), findsOneWidget);
    expect(find.text('Drop'), findsOneWidget);
    expect(find.text('Right'), findsOneWidget);
    expect(find.text('Start Game'), findsOneWidget);
    expect(find.byKey(const Key('hud-level-value')), findsOneWidget);
    expect(find.byKey(const Key('hud-score-value')), findsOneWidget);
    expect(find.byKey(const Key('hud-best-value')), findsOneWidget);
  });
}
