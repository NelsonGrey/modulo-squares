import 'package:firebase_auth/firebase_auth.dart';

class AuthFallbackDecision {
  const AuthFallbackDecision({required this.message, required this.allowRetry});

  final String message;
  final bool allowRetry;
}

AuthFallbackDecision evaluateAnonymousSignInError(Object error) {
  var message =
      'Unable to sign in automatically. You can retry or continue offline.';
  var allowRetry = true;

  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'admin-restricted-operation':
      case 'operation-not-allowed':
        message =
            'Guest sign-in is disabled for this Firebase project. Continue offline to play.';
        allowRetry = false;
        break;
      case 'too-many-requests':
        message =
            'Sign-in is temporarily throttled. Please wait and try again later, or continue offline.';
        allowRetry = false;
        break;
    }
  }

  return AuthFallbackDecision(message: message, allowRetry: allowRetry);
}
