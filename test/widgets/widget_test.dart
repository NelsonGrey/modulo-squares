import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modulo/l10n/app_localizations.dart';
import 'package:modulo/screens/game_screen.dart';

void main() {
  testWidgets('GameScreen displays score and restart button', (WidgetTester tester) async {
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
    expect(find.textContaining('Score:'), findsOneWidget);
    expect(find.text('Restart'), findsOneWidget);
  });
}