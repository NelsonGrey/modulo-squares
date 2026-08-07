import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modulo_squares/features/auth/forgot_password_screen.dart';

// Firebase is not initialized in the test environment (see login_screen_test.dart
// and falling_modulo_game_screen_test.dart, which follow the same convention),
// so any test that actually submits the form exercises the screen's error path
// rather than a real send.

void main() {
  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ForgotPasswordScreen()),
    );
  }

  testWidgets('renders an email field and a send button', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Reset Password'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Email'), findsOneWidget);
    expect(find.text('Send Reset Link'), findsOneWidget);
  });

  testWidgets('shows a validation error when submitted with an empty email', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Send Reset Link'));
    await tester.pumpAndSettle();

    expect(find.text('Enter your email address.'), findsOneWidget);
    // The empty-email guard never reaches FirebaseAuth, so there's no
    // success message either.
    expect(find.text('Send Reset Link'), findsOneWidget);
  });

  testWidgets(
    'settles into a failure (not success) state when Firebase is unavailable, '
    'rather than crashing or hanging',
    (tester) async {
      await pumpScreen(tester);

      await tester.enterText(
        find.widgetWithText(TextField, 'Email'),
        'player@example.com',
      );
      await tester.tap(find.text('Send Reset Link'));
      await tester.pumpAndSettle();

      // Firebase isn't initialized in the test environment, so
      // sendPasswordResetEmail throws; the exact message differs between
      // debug (raw exception text) and release (a friendly generic
      // message) builds, so just assert the failure path was taken: no
      // success banner, and the button returned to its normal label rather
      // than being stuck on "Sending...".
      expect(
        find.textContaining('If an account exists for that email'),
        findsNothing,
      );
      expect(find.text('Send Reset Link'), findsOneWidget);
      expect(find.text('Sending...'), findsNothing);
    },
  );
}
