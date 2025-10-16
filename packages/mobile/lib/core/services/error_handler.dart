import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Centralized error handling service for Firebase and network operations
class ErrorHandler {
  ErrorHandler._();
  static final ErrorHandler instance = ErrorHandler._();

  factory ErrorHandler() => instance;

  /// Handle Firebase initialization errors
  void handleFirebaseInitError(dynamic error, StackTrace stackTrace) {
    debugPrint('Firebase initialization failed: $error');
    debugPrint('Stack trace: $stackTrace');
    // In a production app, you might want to send this to a crash reporting service
  }

  /// Handle Firebase Auth errors
  String getAuthErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'user-not-found':
          return 'No account found with this email.';
        case 'wrong-password':
          return 'Incorrect password.';
        case 'email-already-in-use':
          return 'An account with this email already exists.';
        case 'weak-password':
          return 'Password is too weak.';
        case 'invalid-email':
          return 'Invalid email address.';
        case 'operation-not-allowed':
          return 'This sign-in method is not enabled.';
        case 'too-many-requests':
          return 'Too many failed attempts. Please try again later.';
        case 'network-request-failed':
          return 'Network error. Please check your connection.';
        default:
          return 'Authentication failed: ${error.message ?? error.code}';
      }
    }
    return 'An unexpected authentication error occurred.';
  }

  /// Handle Firestore errors
  String getFirestoreErrorMessage(dynamic error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'You don\'t have permission to perform this action.';
        case 'not-found':
          return 'The requested data was not found.';
        case 'already-exists':
          return 'This data already exists.';
        case 'resource-exhausted':
          return 'Too many requests. Please try again later.';
        case 'failed-precondition':
          return 'Operation failed due to current state.';
        case 'aborted':
          return 'Operation was aborted.';
        case 'out-of-range':
          return 'Requested data is out of range.';
        case 'unimplemented':
          return 'This feature is not implemented yet.';
        case 'internal':
          return 'An internal error occurred.';
        case 'unavailable':
          return 'Service is currently unavailable.';
        case 'data-loss':
          return 'Data loss occurred.';
        case 'unauthenticated':
          return 'You must be signed in to perform this action.';
        case 'deadline-exceeded':
          return 'Request timed out. Please try again.';
        default:
          return 'Database error: ${error.message ?? error.code}';
      }
    }
    return 'An unexpected database error occurred.';
  }

  /// Handle AdMob errors
  String getAdErrorMessage(AdError error) {
    // AdMob error codes are typically integers, handle common ones
    switch (error.code) {
      case 0: // Internal error
        return 'Ad service internal error.';
      case 1: // Invalid request
        return 'Invalid ad request.';
      case 2: // Network error
        return 'Network error while loading ad.';
      case 3: // No fill
        return 'No ad available at this time.';
      default:
        return 'Ad error: ${error.message}';
    }
  }

  /// Handle In-App Purchase errors
  String getPurchaseErrorMessage(dynamic error) {
    if (error is IAPError) {
      // IAP error codes are strings
      switch (error.code) {
        case 'purchase_cancelled':
          return 'Purchase was cancelled.';
        case 'payment_invalid':
          return 'Payment information is invalid.';
        case 'client_invalid':
          return 'Client is not allowed to make purchases.';
        case 'payment_not_allowed':
          return 'Device is not allowed to make payments.';
        case 'product_not_available':
          return 'Product is not available for purchase.';
        case 'product_invalid':
          return 'Product ID is invalid.';
        case 'store_product_not_available':
          return 'Product is not available in the store.';
        default:
          return 'Purchase error: ${error.message}';
      }
    }
    return 'An unexpected purchase error occurred.';
  }

  /// Handle network connectivity errors
  String getNetworkErrorMessage() {
    return 'Network connection error. Please check your internet connection and try again.';
  }

  /// Show error snackbar with retry option
  void showErrorSnackBar(
    BuildContext context,
    String message, {
    VoidCallback? onRetry,
    Duration duration = const Duration(seconds: 4),
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        action: onRetry != null
            ? SnackBarAction(
                label: 'Retry',
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }

  /// Show error dialog for critical errors
  void showErrorDialog(
    BuildContext context,
    String title,
    String message, {
    VoidCallback? onRetry,
    String retryText = 'Retry',
    String dismissText = 'OK',
  }) {
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(dismissText),
          ),
          if (onRetry != null)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: Text(retryText),
            ),
        ],
      ),
    );
  }

  /// Log error for debugging/monitoring
  void logError(String operation, dynamic error, [StackTrace? stackTrace]) {
    debugPrint('[$operation] Error: $error');
    if (stackTrace != null) {
      debugPrint('[$operation] Stack trace: $stackTrace');
    }
    // In production, you might want to send this to a logging service
  }
}
