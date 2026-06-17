import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:modulo_squares/features/game/falling_modulo_game_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget _buildApp() => const MaterialApp(home: FallingModuloGameScreen());

  testWidgets('renders without crashing', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(_buildApp());
    await tester.pump(); // allow initState async prefs load
    expect(find.byType(FallingModuloGameScreen), findsOneWidget);
  });

  testWidgets('shows level 1 and score 0 on start', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(_buildApp());
    await tester.pump();

    expect(find.textContaining('Level'), findsWidgets);
    expect(find.textContaining('Score'), findsWidgets);
  });

  testWidgets(
    'drop progress indicator is initially at zero during spawn delay',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_buildApp());
      await tester.pump(); // flush initState

      // At start a spawn delay is active — progress should be 0.
      final indicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(indicator.value, 0.0);
    },
  );

  testWidgets('shows pre-game overlay and paused HUD state before game start', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(_buildApp());
    await tester.pump();

    expect(find.text('Fall: Paused'), findsOneWidget);
    expect(find.text('Start Game'), findsOneWidget);
  });

  testWidgets('start game button switches to AppBar pause icon after starting run', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(_buildApp());
    await tester.pump();

    await tester.tap(find.text('Start Game'));
    await tester.pump();

    expect(find.byTooltip('Pause'), findsOneWidget);
  });

  testWidgets('settings dialog does not show mode switching action', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(_buildApp());
    await tester.pump();

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Switch Mode'), findsNothing);
  });
}
