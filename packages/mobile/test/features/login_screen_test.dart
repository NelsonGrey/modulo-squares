import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modulo_squares/features/auth/login_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpLogin(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(home: LoginScreen(initializeGoogleSignIn: false)),
    );
  }

  testWidgets('does not show guest sign-in option', (
    WidgetTester tester,
  ) async {
    await pumpLogin(tester);
    await tester.pumpAndSettle();

    expect(find.text('Play as Guest'), findsNothing);
  });

  testWidgets('shows account-required sign-in options', (
    WidgetTester tester,
  ) async {
    await pumpLogin(tester);
    await tester.pumpAndSettle();

    expect(find.textContaining('account is required'), findsOneWidget);
    expect(find.text('Sign in with Google'), findsOneWidget);
    expect(find.text('Sign in with Apple'), findsOneWidget);
  });
}
