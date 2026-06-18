import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:modulo_squares/features/game/falling_modulo_game_screen.dart';
import 'package:modulo_squares/features/game/game_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('GameScreen renders FallingModuloGameScreen', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const MaterialApp(home: GameScreen()));
    await tester.pumpAndSettle();

    expect(find.byType(GameScreen), findsOneWidget);
    expect(find.byType(FallingModuloGameScreen), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('GameScreen shows app title', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const MaterialApp(home: GameScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Modulo Squares'), findsWidgets);
  });
}
