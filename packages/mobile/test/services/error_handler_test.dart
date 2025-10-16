import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:modulo/core/services/error_handler.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ErrorHandler', () {
    test('provides auth error messages', () {
      // Test various Firebase Auth error codes
      expect(
        ErrorHandler().getAuthErrorMessage(FirebaseAuthException(code: 'user-disabled')),
        'This account has been disabled.',
      );

      expect(
        ErrorHandler().getAuthErrorMessage(FirebaseAuthException(code: 'wrong-password')),
        'Incorrect password.',
      );

      expect(
        ErrorHandler().getAuthErrorMessage(FirebaseAuthException(code: 'user-not-found')),
        'No account found with this email.',
      );

      expect(
        ErrorHandler().getAuthErrorMessage(FirebaseAuthException(code: 'weak-password')),
        'Password is too weak.',
      );

      expect(
        ErrorHandler().getAuthErrorMessage(FirebaseAuthException(code: 'network-request-failed')),
        'Network error. Please check your connection.',
      );

      // Test unknown error
      expect(
        ErrorHandler().getAuthErrorMessage(FirebaseAuthException(code: 'unknown-error')),
        'Authentication failed: unknown-error',
      );
    });

    test('provides firestore error messages', () {
      // Test various Firestore error codes
      expect(
        ErrorHandler().getFirestoreErrorMessage(FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied')),
        'You don\'t have permission to perform this action.',
      );

      expect(
        ErrorHandler().getFirestoreErrorMessage(FirebaseException(plugin: 'cloud_firestore', code: 'not-found')),
        'The requested data was not found.',
      );

      expect(
        ErrorHandler().getFirestoreErrorMessage(FirebaseException(plugin: 'cloud_firestore', code: 'already-exists')),
        'This data already exists.',
      );

      expect(
        ErrorHandler().getFirestoreErrorMessage(FirebaseException(plugin: 'cloud_firestore', code: 'unavailable')),
        'Service is currently unavailable.',
      );

      expect(
        ErrorHandler().getFirestoreErrorMessage(FirebaseException(plugin: 'cloud_firestore', code: 'deadline-exceeded')),
        'Request timed out. Please try again.',
      );

      // Test unknown error
      expect(
        ErrorHandler().getFirestoreErrorMessage(FirebaseException(plugin: 'cloud_firestore', code: 'unknown-error')),
        'Database error: unknown-error',
      );
    });

    test('provides network error message', () {
      expect(
        ErrorHandler().getNetworkErrorMessage(),
        'Network connection error. Please check your internet connection and try again.',
      );
    });

    testWidgets('shows error snackbar', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    ErrorHandler().showErrorSnackBar(
                      context,
                      'Test error message',
                    );
                  },
                  child: const Text('Show Error'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Test error message'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('shows error snackbar with retry action', (WidgetTester tester) async {
      bool retryCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    ErrorHandler().showErrorSnackBar(
                      context,
                      'Test error message',
                      onRetry: () => retryCalled = true,
                    );
                  },
                  child: const Text('Show Error'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Test error message'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      expect(retryCalled, true);
    });

    testWidgets('shows error dialog', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    ErrorHandler().showErrorDialog(
                      context,
                      'Error Title',
                      'Error message content',
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Error Title'), findsOneWidget);
      expect(find.text('Error message content'), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('shows error dialog with retry action', (WidgetTester tester) async {
      bool retryCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    ErrorHandler().showErrorDialog(
                      context,
                      'Error Title',
                      'Error message content',
                      onRetry: () => retryCalled = true,
                      retryText: 'Try Again',
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Try Again'), findsOneWidget);

      await tester.tap(find.text('Try Again'));
      expect(retryCalled, true);
    });
  });
}
