import 'package:flutter/foundation.dart';
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

  // debugDefaultTargetPlatformOverride must be reset as the last step inside
  // the test body itself -- Flutter's test binding verifies debug vars are
  // unset immediately after the test callback returns, before any tearDown()
  // or addTearDown() callback gets a chance to run.
  Future<void> withPlatform(
    TargetPlatform platform,
    Future<void> Function() body,
  ) async {
    debugDefaultTargetPlatformOverride = platform;
    try {
      await body();
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  }

  testWidgets('does not show guest sign-in option', (
    WidgetTester tester,
  ) async {
    await pumpLogin(tester);
    await tester.pumpAndSettle();

    expect(find.text('Play as Guest'), findsNothing);
  });

  testWidgets('Android shows Google sign-in but not Apple', (
    WidgetTester tester,
  ) async {
    await withPlatform(TargetPlatform.android, () async {
      await pumpLogin(tester);
      await tester.pumpAndSettle();

      expect(find.textContaining('Sign in to save progress'), findsOneWidget);
      expect(find.text('Sign in with Google'), findsOneWidget);
      expect(find.text('Sign in with Email'), findsOneWidget);
      expect(find.text('Sign in with Apple'), findsNothing);
    });
  });

  testWidgets('iOS shows Apple sign-in but not Google', (
    WidgetTester tester,
  ) async {
    await withPlatform(TargetPlatform.iOS, () async {
      await pumpLogin(tester);
      await tester.pumpAndSettle();

      expect(find.textContaining('Sign in to save progress'), findsOneWidget);
      expect(find.text('Sign in with Apple'), findsOneWidget);
      expect(find.text('Sign in with Email'), findsOneWidget);
      expect(find.text('Sign in with Google'), findsNothing);
    });
  });
}
