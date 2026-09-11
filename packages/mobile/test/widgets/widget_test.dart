import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:modulo_squares/l10n/app_localizations.dart';
import 'package:modulo_squares/features/game/game_screen.dart';
import 'package:modulo_squares/core/di/service_locator.dart';

void main() {
  setUpAll(() {
    // Setup service locator for tests
    setupServiceLocator();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('GameScreen displays HUD and controls', (
    WidgetTester tester,
  ) async {
    // Increase the test surface to avoid overflow with the square grid + controls
    final view = tester.view;
    view.physicalSize = const Size(1200, 2200);
    view.devicePixelRatio = 1.0;
    addTearDown(() {
      view.resetPhysicalSize();
      view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('en', '')],
        home: GameScreen(),
      ),
    );
    // GameScreen's FallingModuloGameScreen has a periodic timer; pumpAndSettle
    // would hang waiting for it. One pump is enough for the initial state.
    await tester.pump();

    final ctx = tester.element(find.byType(Scaffold));
    final l10n = AppLocalizations.of(ctx);
    expect(l10n, isNotNull);

    expect(find.text('Modulo Squares'), findsWidgets);
    expect(find.textContaining('Score:'), findsWidgets);
    expect(find.text('Left'), findsOneWidget);
    expect(find.text('Drop'), findsOneWidget);
    expect(find.text('Right'), findsOneWidget);
  });
}
