// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Modulo Squares';

  @override
  String get profile => 'Profile';

  @override
  String get signOut => 'Sign Out';

  @override
  String get name => 'Name';

  @override
  String get email => 'Email';

  @override
  String get uid => 'UID';

  @override
  String get difficultyLevel => 'Difficulty Level:';

  @override
  String get score => 'Score:';

  @override
  String get highScore => 'High Score:';

  @override
  String get restart => 'Restart';

  @override
  String get youWin => 'You Win!';

  @override
  String winMessage(Object score) {
    return 'Congratulations, you cleared the board! Score: $score';
  }

  @override
  String get gameOver => 'Game Over';

  @override
  String gameOverMessage(Object score) {
    return 'No more valid moves available. Score: $score';
  }

  @override
  String get enterName => 'Enter your name to submit score:';

  @override
  String get yourName => 'Your name';

  @override
  String get submitScore => 'Submit Score';

  @override
  String get playAgain => 'Play Again';

  @override
  String get globalLeaderboard => 'Global Leaderboard';

  @override
  String get noScoresYet => 'No scores yet';

  @override
  String get close => 'Close';

  @override
  String get showLeaderboard => 'Show Leaderboard';

  @override
  String get errorUnexpected => 'An unexpected error occurred.';

  @override
  String get authErrorUserDisabled => 'This account has been disabled.';

  @override
  String get authErrorUserNotFound => 'No account found with this email.';

  @override
  String get authErrorWrongPassword => 'Incorrect password.';

  @override
  String get authErrorEmailAlreadyInUse => 'An account with this email already exists.';

  @override
  String get authErrorWeakPassword => 'Password is too weak.';

  @override
  String get authErrorInvalidEmail => 'Invalid email address.';

  @override
  String get authErrorOperationNotAllowed => 'This sign-in method is not enabled.';

  @override
  String get authErrorTooManyRequests => 'Too many failed attempts. Please try again later.';

  @override
  String get authErrorNetworkRequestFailed => 'Network error. Please check your connection.';

  @override
  String get authErrorUnexpected => 'Authentication failed. Please try again.';

  @override
  String get firestoreErrorPermissionDenied => 'You don\'t have permission to perform this action.';

  @override
  String get firestoreErrorNotFound => 'The requested data was not found.';

  @override
  String get firestoreErrorAlreadyExists => 'This data already exists.';

  @override
  String get firestoreErrorResourceExhausted => 'Too many requests. Please try again later.';

  @override
  String get firestoreErrorFailedPrecondition => 'Operation failed due to current state.';

  @override
  String get firestoreErrorAborted => 'Operation was aborted.';

  @override
  String get firestoreErrorOutOfRange => 'Requested data is out of range.';

  @override
  String get firestoreErrorUnimplemented => 'This feature is not implemented yet.';

  @override
  String get firestoreErrorInternal => 'An internal error occurred.';

  @override
  String get firestoreErrorUnavailable => 'Service is currently unavailable.';

  @override
  String get firestoreErrorDataLoss => 'Data loss occurred.';

  @override
  String get firestoreErrorUnauthenticated => 'You must be signed in to perform this action.';

  @override
  String get firestoreErrorDeadlineExceeded => 'Request timed out. Please try again.';

  @override
  String get firestoreErrorUnexpected => 'Database error occurred. Please try again.';

  @override
  String get admobErrorInternal => 'Ad service internal error.';

  @override
  String get admobErrorInvalidRequest => 'Invalid ad request.';

  @override
  String get admobErrorNetworkError => 'Network error while loading ad.';

  @override
  String get admobErrorNoFill => 'No ad available at this time.';

  @override
  String get admobErrorUnexpected => 'Ad error occurred.';

  @override
  String get purchaseErrorCancelled => 'Purchase was cancelled.';

  @override
  String get purchaseErrorPaymentInvalid => 'Payment information is invalid.';

  @override
  String get purchaseErrorClientInvalid => 'Client is not allowed to make purchases.';

  @override
  String get purchaseErrorPaymentNotAllowed => 'Device is not allowed to make payments.';

  @override
  String get purchaseErrorProductNotAvailable => 'Product is not available for purchase.';

  @override
  String get purchaseErrorProductInvalid => 'Product ID is invalid.';

  @override
  String get purchaseErrorStoreProductNotAvailable => 'Product is not available in the store.';

  @override
  String get purchaseErrorUnexpected => 'Purchase error occurred. Please try again.';

  @override
  String get networkErrorMessage => 'Network connection error. Please check your internet connection and try again.';
}
