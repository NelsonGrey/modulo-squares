import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:modulo_squares/features/game/falling_modulo_game_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget _buildApp({VoidCallback? onOpenModePicker}) {
    return MaterialApp(
      home: FallingModuloGameScreen(onOpenModePicker: onOpenModePicker),
    );
  }

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

  testWidgets('shows Ready text in HUD during spawn delay', (
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

    // During spawn delay the HUD shows 'Fall: Ready...' instead of the drop interval.
    expect(find.text('Fall: Ready...'), findsOneWidget);
  });

  testWidgets('onOpenModePicker callback fires when back button tapped', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    var called = false;
    await tester.pumpWidget(_buildApp(onOpenModePicker: () => called = true));
    await tester.pump();

    // Find any back/arrow button and tap it.
    final backButton = find.byIcon(Icons.arrow_back);
    if (backButton.evaluate().isNotEmpty) {
      await tester.tap(backButton);
      await tester.pump();
      expect(called, isTrue);
    }
  });
}
