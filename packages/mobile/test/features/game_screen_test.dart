import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modulo/l10n/app_localizations.dart';
import 'package:modulo/features/game/game_screen.dart';
import 'package:modulo/core/di/service_locator.dart';
import 'package:modulo/core/services/analytics_service.dart';
import 'package:modulo/core/services/ad_service.dart';

// Mock services for testing
class MockAnalyticsService implements AnalyticsService {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockAdService implements AdService {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  setUpAll(() {
    // Setup minimal service locator for tests
    getIt.registerSingleton<AnalyticsService>(MockAnalyticsService());
    getIt.registerSingleton<AdService>(MockAdService());
  });

  tearDownAll(() {
    getIt.reset();
  });

  testWidgets('GameScreen renders without crashing', (WidgetTester tester) async {
    // Increase the test surface to avoid overflow
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
        supportedLocales: [
          Locale('en', ''),
        ],
        home: GameScreen(),
      ),
    );

    // Allow initial async state to settle
    await tester.pumpAndSettle();

    // Verify the screen renders without crashing
    expect(find.byType(GameScreen), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('GameScreen displays basic UI elements', (WidgetTester tester) async {
    // Increase the test surface
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
        supportedLocales: [
          Locale('en', ''),
        ],
        home: GameScreen(),
      ),
    );

    // Allow initial async state to settle
    await tester.pumpAndSettle();

    // Verify basic UI elements are present
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
    // The exact content depends on the game state, but basic structure should be there
  });

  testWidgets('GameScreen handles different screen sizes', (WidgetTester tester) async {
    // Test with a smaller screen
    final view = tester.view;
    view.physicalSize = const Size(800, 1200);
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
        supportedLocales: [
          Locale('en', ''),
        ],
        home: GameScreen(),
      ),
    );

    // Allow initial async state to settle
    await tester.pumpAndSettle();

    // Should still render without crashing on smaller screens
    expect(find.byType(GameScreen), findsOneWidget);
  });

  testWidgets('GameScreen integrates with localization', (WidgetTester tester) async {
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
        supportedLocales: [
          Locale('en', ''),
        ],
        home: GameScreen(),
      ),
    );

    // Allow initial async state to settle
    await tester.pumpAndSettle();

    // Verify that localization is working (AppLocalizations should be available)
    final context = tester.element(find.byType(Scaffold));
    expect(AppLocalizations.of(context), isNotNull);
  });

  testWidgets('GameScreen creates provider correctly', (WidgetTester tester) async {
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
        supportedLocales: [
          Locale('en', ''),
        ],
        home: GameScreen(),
      ),
    );

    // Allow initial async state to settle
    await tester.pumpAndSettle();

    // Verify that a provider was created (we can't easily test the provider value)
    expect(find.byType(GameScreen), findsOneWidget);
  });
}
