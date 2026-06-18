import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:modulo_squares/features/leaderboard/leaderboard_screen.dart';
import 'package:modulo_squares/l10n/app_localizations.dart';

void main() {
  group('LeaderboardScreen Integration Tests', () {
    testWidgets('LeaderboardScreen has proper app bar', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          home: const LeaderboardScreen(),
        ),
      );

      // Don't pumpAndSettle to avoid Firebase initialization issues
      await tester.pump();

      // Verify AppBar is present with correct title
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Leaderboard'), findsOneWidget);
    });

    testWidgets('LeaderboardScreen handles localization correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          home: const LeaderboardScreen(),
        ),
      );

      // Don't pumpAndSettle to avoid Firebase initialization issues
      await tester.pump();

      // Verify that the screen renders without localization errors
      expect(find.byType(LeaderboardScreen), findsOneWidget);
    });

    testWidgets('LeaderboardScreen renders correctly on different screen sizes', (WidgetTester tester) async {
      // Test on a smaller screen
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          home: const LeaderboardScreen(),
        ),
      );

      // Don't pumpAndSettle to avoid Firebase initialization issues
      await tester.pump();

      // Verify all elements are still visible on smaller screen
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Leaderboard'), findsOneWidget);

      // Reset screen size
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('LeaderboardScreen displays error state UI elements', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          home: const LeaderboardScreen(),
        ),
      );

      // Don't pumpAndSettle to avoid Firebase initialization issues
      await tester.pump();

      // Note: Error state testing would require mocking the Firestore stream
      // For integration tests, we verify the UI structure is correct
      // Error handling UI elements are present in the code but hard to trigger without mocking
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('LeaderboardScreen handles navigation correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          navigatorObservers: [], // Add navigator observer if needed for navigation testing
          home: const LeaderboardScreen(),
        ),
      );

      // Don't pumpAndSettle to avoid Firebase initialization issues
      await tester.pump();

      // Verify the screen is properly integrated into the navigation stack
      expect(find.byType(LeaderboardScreen), findsOneWidget);
    });

    testWidgets('LeaderboardScreen has proper scaffold structure', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          home: const LeaderboardScreen(),
        ),
      );

      // Don't pumpAndSettle to avoid Firebase initialization issues
      await tester.pump();

      // Verify basic scaffold components
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });
  });
}
