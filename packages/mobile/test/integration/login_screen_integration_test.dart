import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:modulo_squares/features/auth/login_screen.dart';
import 'package:modulo_squares/l10n/app_localizations.dart';

void main() {
  Widget _buildLoginTestApp() {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      home: LoginScreen(initializeGoogleSignIn: false),
    );
  }

  group('LoginScreen Integration Tests', () {
    testWidgets(
      'LoginScreen displays account-required authentication options',
      (WidgetTester tester) async {
        await tester.pumpWidget(_buildLoginTestApp());

        await tester.pumpAndSettle();

        // Verify UI elements are present
        expect(find.textContaining('account is required'), findsOneWidget);
        expect(find.text('Sign in with Google'), findsOneWidget);
        expect(find.text('Sign in with Email'), findsOneWidget);
        expect(find.text('Sign in with Apple'), findsOneWidget);
        expect(find.text('Play as Guest'), findsNothing);
      },
    );

    testWidgets('LoginScreen Email sign-in button opens email auth dialog', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_buildLoginTestApp());

      await tester.pumpAndSettle();

      final emailButton = find.text('Sign in with Email');
      expect(emailButton, findsOneWidget);

      await tester.tap(emailButton);
      await tester.pumpAndSettle();

      expect(find.text('Sign in with email'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('LoginScreen Google sign-in button is displayed and tappable', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_buildLoginTestApp());

      await tester.pumpAndSettle();

      // Find and tap Google sign-in button
      final googleButton = find.text('Sign in with Google');
      expect(googleButton, findsOneWidget);
      await tester.tap(googleButton);
      await tester.pumpAndSettle();

      // Verify the button is tappable (Google Sign-In would handle the actual authentication)
      // This test ensures the UI interaction works correctly
    });

    testWidgets('LoginScreen Apple sign-in button is displayed and tappable', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_buildLoginTestApp());

      await tester.pumpAndSettle();

      // Find and tap Apple sign-in button
      final appleButton = find.text('Sign in with Apple');
      expect(appleButton, findsOneWidget);
      await tester.tap(appleButton);
      await tester.pumpAndSettle();

      // Verify the button is tappable (Apple Sign-In would handle the actual authentication)
      // This test ensures the UI interaction works correctly
    });

    testWidgets('LoginScreen handles localization correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_buildLoginTestApp());

      await tester.pumpAndSettle();

      // Verify that the screen renders without localization errors
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(Column), findsOneWidget);
    });

    testWidgets('LoginScreen has proper layout structure', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_buildLoginTestApp());

      await tester.pumpAndSettle();

      // Verify layout structure
      expect(
        find.byType(ElevatedButton),
        findsNWidgets(3),
      ); // Google, Email, and Apple buttons
      expect(find.byType(OutlinedButton), findsNothing);
      expect(find.byType(SizedBox), findsNWidgets(4)); // Spacing widgets
    });

    testWidgets('LoginScreen buttons are properly styled', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_buildLoginTestApp());

      await tester.pumpAndSettle();

      // Verify button styling (basic checks)
      final googleButton = find.text('Sign in with Google');
      final emailButton = find.text('Sign in with Email');
      final appleButton = find.text('Sign in with Apple');

      expect(
        tester.widget<ElevatedButton>(
          find.ancestor(
            of: googleButton,
            matching: find.byType(ElevatedButton),
          ),
        ),
        isNotNull,
      );
      expect(
        tester.widget<ElevatedButton>(
          find.ancestor(of: emailButton, matching: find.byType(ElevatedButton)),
        ),
        isNotNull,
      );
      expect(
        tester.widget<ElevatedButton>(
          find.ancestor(of: appleButton, matching: find.byType(ElevatedButton)),
        ),
        isNotNull,
      );
    });

    testWidgets('LoginScreen renders correctly on different screen sizes', (
      WidgetTester tester,
    ) async {
      // Test on a smaller screen
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(_buildLoginTestApp());

      await tester.pumpAndSettle();

      // Verify all elements are still visible on smaller screen
      expect(find.text('Sign in with Google'), findsOneWidget);
      expect(find.text('Sign in with Email'), findsOneWidget);
      expect(find.text('Sign in with Apple'), findsOneWidget);
      expect(find.text('Play as Guest'), findsNothing);

      // Reset screen size
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
