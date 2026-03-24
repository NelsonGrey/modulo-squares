import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modulo_squares/core/services/leaderboard_service.dart';
import 'package:modulo_squares/features/game/leaderboard_screen.dart';
import 'package:modulo_squares/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Game leaderboard screen shows global daily and weekly tabs', (
    WidgetTester tester,
  ) async {
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
        supportedLocales: [Locale('en')],
        home: LeaderboardScreen(playerName: 'Tester'),
      ),
    );

    await tester.pump();

    expect(find.text('Global'), findsOneWidget);
    expect(find.text('Daily'), findsOneWidget);
    expect(find.text('Weekly'), findsOneWidget);

    await tester.tap(find.text('Weekly'));
    await tester.pumpAndSettle();

    expect(find.text('Weekly Ladder'), findsOneWidget);
    expect(find.textContaining('Season Summary'), findsOneWidget);
    expect(find.text('Recent Weeks Trend'), findsOneWidget);
    expect(find.text('Improving'), findsOneWidget);
    expect(find.text('Stable'), findsOneWidget);
    expect(find.text('Declining'), findsOneWidget);
    expect(find.text('Leaderboard Depth'), findsOneWidget);
    expect(find.text('Top 10'), findsOneWidget);
    expect(find.text('Top 25'), findsOneWidget);
    expect(find.text('Top 50'), findsOneWidget);
    expect(find.byType(DropdownButton<int>), findsOneWidget);
  });

  testWidgets('Weekly leaderboard restores saved top-limit selection', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({'weeklyLeaderboardTopLimit': 50});

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
        supportedLocales: [Locale('en')],
        home: LeaderboardScreen(playerName: 'Tester'),
      ),
    );

    await tester.pump();
    await tester.tap(find.text('Weekly'));
    await tester.pumpAndSettle();

    final top50Chip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'Top 50'),
    );
    expect(top50Chip.selected, isTrue);
  });

  testWidgets('Weekly leaderboard restores saved selected week', (
    WidgetTester tester,
  ) async {
    final savedWeekId = LeaderboardService.currentWeekId();
    SharedPreferences.setMockInitialValues({
      'weeklyLeaderboardSelectedWeek': savedWeekId,
    });

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
        supportedLocales: [Locale('en')],
        home: LeaderboardScreen(playerName: 'Tester'),
      ),
    );

    await tester.pump();
    await tester.tap(find.text('Weekly'));
    await tester.pumpAndSettle();

    final weekDropdown = tester.widget<DropdownButton<int>>(
      find.byType(DropdownButton<int>),
    );
    expect(weekDropdown.value, savedWeekId);
  });
}
