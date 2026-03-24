import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modulo_squares/features/game/leaderboard_screen.dart';
import 'package:modulo_squares/l10n/app_localizations.dart';

void main() {
  testWidgets('Game leaderboard screen shows global daily and weekly tabs', (
    WidgetTester tester,
  ) async {
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
    expect(find.byType(DropdownButton<int>), findsOneWidget);
  });
}
