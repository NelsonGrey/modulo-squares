import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modulo_squares/core/auth/auth_fallback_policy.dart';

void main() {
  group('evaluateAnonymousSignInError', () {
    test('marks admin restricted as non-retryable', () {
      final decision = evaluateAnonymousSignInError(
        FirebaseAuthException(code: 'admin-restricted-operation'),
      );

      expect(decision.allowRetry, isFalse);
      expect(
        decision.message,
        contains('Guest sign-in is disabled for this Firebase project'),
      );
    });

    test('marks operation-not-allowed as non-retryable', () {
      final decision = evaluateAnonymousSignInError(
        FirebaseAuthException(code: 'operation-not-allowed'),
      );

      expect(decision.allowRetry, isFalse);
      expect(
        decision.message,
        contains('Guest sign-in is disabled for this Firebase project'),
      );
    });

    test('marks too-many-requests as non-retryable', () {
      final decision = evaluateAnonymousSignInError(
        FirebaseAuthException(code: 'too-many-requests'),
      );

      expect(decision.allowRetry, isFalse);
      expect(decision.message, contains('temporarily throttled'));
    });

    test('keeps unknown auth errors retryable', () {
      final decision = evaluateAnonymousSignInError(
        FirebaseAuthException(code: 'network-request-failed'),
      );

      expect(decision.allowRetry, isTrue);
      expect(decision.message, contains('Unable to sign in automatically'));
    });

    test('keeps non-auth errors retryable', () {
      final decision = evaluateAnonymousSignInError(Exception('boom'));

      expect(decision.allowRetry, isTrue);
      expect(decision.message, contains('Unable to sign in automatically'));
    });
  });
}
