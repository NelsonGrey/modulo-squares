import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modulo_squares/features/auth/login_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpLogin(
    WidgetTester tester, {
    required Future<void> Function() anonymousSignIn,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          anonymousSignIn: anonymousSignIn,
          initializeGoogleSignIn: false,
        ),
      ),
    );
  }

  testWidgets('hides Retry for non-retryable guest sign-in errors', (
    WidgetTester tester,
  ) async {
    await pumpLogin(
      tester,
      anonymousSignIn:
          () async => throw FirebaseAuthException(code: 'too-many-requests'),
    );

    await tester.tap(find.text('Play as Guest'));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.textContaining('temporarily throttled'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
  });

  testWidgets('shows Retry for retryable guest sign-in errors', (
    WidgetTester tester,
  ) async {
    await pumpLogin(
      tester,
      anonymousSignIn:
          () async =>
              throw FirebaseAuthException(code: 'network-request-failed'),
    );

    await tester.tap(find.text('Play as Guest'));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(
      find.textContaining('Unable to sign in automatically'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
  });
}
