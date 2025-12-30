import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:modulo_squares/core/services/error_handler.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ErrorHandler errorHandler;

  setUp(() {
    errorHandler = ErrorHandler();
  });

  group('ErrorHandler', () {
    test('singleton pattern works correctly', () {
      final instance1 = ErrorHandler();
      final instance2 = ErrorHandler();
      expect(instance1, same(instance2));
    });

    test('ErrorHandler can be instantiated', () {
      expect(errorHandler, isNotNull);
      expect(errorHandler, isA<ErrorHandler>());
    });

    test('provides auth error messages', () {
      // Test various Firebase Auth error codes
      final testCases = {
        'user-disabled': 'This account has been disabled.',
        'user-not-found': 'No account found with this email.',
        'wrong-password': 'Incorrect password.',
        'email-already-in-use': 'An account with this email already exists.',
        'weak-password': 'Password is too weak.',
        'invalid-email': 'Invalid email address.',
        'operation-not-allowed': 'This sign-in method is not enabled.',
        'too-many-requests': 'Too many failed attempts. Please try again later.',
        'network-request-failed': 'Network error. Please check your connection.',
        'unknown-error': 'Authentication failed: unknown-error',
      };

      for (final entry in testCases.entries) {
        expect(
          errorHandler.getAuthErrorMessage(FirebaseAuthException(code: entry.key)),
          entry.value,
        );
      }
    });

    test('provides firestore error messages', () {
      // Test various Firestore error codes
      final testCases = {
        'permission-denied': 'You don\'t have permission to perform this action.',
        'not-found': 'The requested data was not found.',
        'already-exists': 'This data already exists.',
        'resource-exhausted': 'Too many requests. Please try again later.',
        'failed-precondition': 'Operation failed due to current state.',
        'aborted': 'Operation was aborted.',
        'out-of-range': 'Requested data is out of range.',
        'unimplemented': 'This feature is not implemented yet.',
        'internal': 'An internal error occurred.',
        'unavailable': 'Service is currently unavailable.',
        'data-loss': 'Data loss occurred.',
        'unauthenticated': 'You must be signed in to perform this action.',
        'deadline-exceeded': 'Request timed out. Please try again.',
        'unknown-error': 'Database error: unknown-error',
      };

      for (final entry in testCases.entries) {
        expect(
          errorHandler.getFirestoreErrorMessage(FirebaseException(plugin: 'cloud_firestore', code: entry.key)),
          entry.value,
        );
      }
    });

    test('provides AdMob error messages', () {
      final testCases = {
        0: 'Ad service internal error.',
        1: 'Invalid ad request.',
        2: 'Network error while loading ad.',
        3: 'No ad available at this time.',
        999: 'Ad error: Test message',
      };

      for (final entry in testCases.entries) {
        final error = AdError(entry.key, 'Test message', 'domain');
        expect(errorHandler.getAdErrorMessage(error), entry.value);
      }
    });

    test('provides purchase error messages', () {
      final testCases = {
        'purchase_cancelled': 'Purchase was cancelled.',
        'payment_invalid': 'Payment information is invalid.',
        'client_invalid': 'Client is not allowed to make purchases.',
        'payment_not_allowed': 'Device is not allowed to make payments.',
        'product_not_available': 'Product is not available for purchase.',
        'product_invalid': 'Product ID is invalid.',
        'store_product_not_available': 'Product is not available in the store.',
        'unknown-code': 'Purchase error: unknown message',
      };

      for (final entry in testCases.entries) {
        final error = IAPError(code: entry.key, source: 'test_source', message: 'unknown message');
        expect(errorHandler.getPurchaseErrorMessage(error), entry.value);
      }
    });

    test('provides network error message', () {
      expect(
        errorHandler.getNetworkErrorMessage(),
        'Network connection error. Please check your internet connection and try again.',
      );
    });

    test('handleFirebaseInitError method exists and is callable', () {
      expect(() => errorHandler.handleFirebaseInitError('test error', StackTrace.current), returnsNormally);
    });

    test('logError method exists and is callable', () {
      expect(() => errorHandler.logError('test operation', 'test error'), returnsNormally);
      expect(() => errorHandler.logError('test operation', 'test error', StackTrace.current), returnsNormally);
    });

    test('error messages handle non-specific exceptions gracefully', () {
      final genericError = Exception('Some unexpected error');

      expect(errorHandler.getAuthErrorMessage(genericError), contains('unexpected'));
      expect(errorHandler.getFirestoreErrorMessage(genericError), contains('unexpected'));
      expect(errorHandler.getPurchaseErrorMessage(genericError), contains('unexpected'));
    });

    test('error messages are user-friendly', () {
      final authError = FirebaseAuthException(code: 'user-not-found');
      final message = errorHandler.getAuthErrorMessage(authError);

      expect(message, isNotEmpty);
      expect(message, isNot(contains('FirebaseAuthException')));
      expect(message, isNot(contains('code')));
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
