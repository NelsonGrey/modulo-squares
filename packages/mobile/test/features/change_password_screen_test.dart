import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modulo_squares/features/auth/change_password_screen.dart';

// Firebase is not initialized in the test environment (see login_screen_test.dart
// and falling_modulo_game_screen_test.dart, which follow the same convention),
// so tests here stick to paths that don't require a successful round-trip to
// FirebaseAuth: client-side validation (empty fields, the quick password-policy
// check) and confirming the Firebase-unavailable path fails safely rather than
// crashing or hanging.

void main() {
  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ChangePasswordScreen()),
    );
    // Let the initState policy-load future (which fails fast -- no Firebase
    // app in the test environment) settle before interacting.
    await tester.pumpAndSettle();
  }

  testWidgets('renders current/new password fields and a submit button', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.text('Change Password'), findsWidgets);
    expect(find.widgetWithText(TextField, 'Current Password'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'New Password'), findsOneWidget);
  });

  testWidgets('shows a validation error when submitted with empty fields', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Change Password'));
    await tester.pumpAndSettle();

    expect(
      find.text('Current and new password are required.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'shows the quick password-policy error for a new password that is too weak, '
    'without touching FirebaseAuth',
    (tester) async {
      await pumpScreen(tester);

      await tester.enterText(
        find.widgetWithText(TextField, 'Current Password'),
        'currentPassw0rd!',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'New Password'),
        'short',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Change Password'));
      await tester.pumpAndSettle();

      // Default PasswordPolicyState requires 8+ characters.
      expect(
        find.text('Password must be at least 8 characters.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'settles into a failure (not success) state when Firebase is unavailable, '
    'rather than crashing or hanging',
    (tester) async {
      await pumpScreen(tester);

      await tester.enterText(
        find.widgetWithText(TextField, 'Current Password'),
        'currentPassw0rd!',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'New Password'),
        'NewPassw0rd!',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Change Password'));
      await tester.pumpAndSettle();

      expect(find.text('Password changed successfully.'), findsNothing);
      expect(find.text('Changing...'), findsNothing);
      expect(find.widgetWithText(ElevatedButton, 'Change Password'), findsOneWidget);
    },
  );
}
