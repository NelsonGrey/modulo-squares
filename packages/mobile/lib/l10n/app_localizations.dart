import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Modulo Squares'**
  String get appTitle;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @uid.
  ///
  /// In en, this message translates to:
  /// **'UID'**
  String get uid;

  /// No description provided for @difficultyLevel.
  ///
  /// In en, this message translates to:
  /// **'Difficulty Level:'**
  String get difficultyLevel;

  /// No description provided for @score.
  ///
  /// In en, this message translates to:
  /// **'Score:'**
  String get score;

  /// No description provided for @highScore.
  ///
  /// In en, this message translates to:
  /// **'High Score:'**
  String get highScore;

  /// No description provided for @restart.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get restart;

  /// No description provided for @youWin.
  ///
  /// In en, this message translates to:
  /// **'You Win!'**
  String get youWin;

  /// No description provided for @winMessage.
  ///
  /// In en, this message translates to:
  /// **'Congratulations, you cleared the board! Score: {score}'**
  String winMessage(Object score);

  /// No description provided for @gameOver.
  ///
  /// In en, this message translates to:
  /// **'Game Over'**
  String get gameOver;

  /// No description provided for @gameOverMessage.
  ///
  /// In en, this message translates to:
  /// **'No more valid moves available. Score: {score}'**
  String gameOverMessage(Object score);

  /// No description provided for @enterName.
  ///
  /// In en, this message translates to:
  /// **'Enter your name to submit score:'**
  String get enterName;

  /// No description provided for @yourName.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get yourName;

  /// No description provided for @submitScore.
  ///
  /// In en, this message translates to:
  /// **'Submit Score'**
  String get submitScore;

  /// No description provided for @playAgain.
  ///
  /// In en, this message translates to:
  /// **'Play Again'**
  String get playAgain;

  /// No description provided for @globalLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'Global Leaderboard'**
  String get globalLeaderboard;

  /// No description provided for @noScoresYet.
  ///
  /// In en, this message translates to:
  /// **'No scores yet'**
  String get noScoresYet;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @showLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'Show Leaderboard'**
  String get showLeaderboard;

  /// No description provided for @errorUnexpected.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred.'**
  String get errorUnexpected;

  /// No description provided for @authErrorUserDisabled.
  ///
  /// In en, this message translates to:
  /// **'This account has been disabled.'**
  String get authErrorUserDisabled;

  /// No description provided for @authErrorUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'No account found with this email.'**
  String get authErrorUserNotFound;

  /// No description provided for @authErrorWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password.'**
  String get authErrorWrongPassword;

  /// No description provided for @authErrorEmailAlreadyInUse.
  ///
  /// In en, this message translates to:
  /// **'An account with this email already exists.'**
  String get authErrorEmailAlreadyInUse;

  /// No description provided for @authErrorWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password is too weak.'**
  String get authErrorWeakPassword;

  /// No description provided for @authErrorInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email address.'**
  String get authErrorInvalidEmail;

  /// No description provided for @authErrorOperationNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'This sign-in method is not enabled.'**
  String get authErrorOperationNotAllowed;

  /// No description provided for @authErrorTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many failed attempts. Please try again later.'**
  String get authErrorTooManyRequests;

  /// No description provided for @authErrorNetworkRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your connection.'**
  String get authErrorNetworkRequestFailed;

  /// No description provided for @authErrorUnexpected.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed. Please try again.'**
  String get authErrorUnexpected;

  /// No description provided for @firestoreErrorPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to perform this action.'**
  String get firestoreErrorPermissionDenied;

  /// No description provided for @firestoreErrorNotFound.
  ///
  /// In en, this message translates to:
  /// **'The requested data was not found.'**
  String get firestoreErrorNotFound;

  /// No description provided for @firestoreErrorAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'This data already exists.'**
  String get firestoreErrorAlreadyExists;

  /// No description provided for @firestoreErrorResourceExhausted.
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Please try again later.'**
  String get firestoreErrorResourceExhausted;

  /// No description provided for @firestoreErrorFailedPrecondition.
  ///
  /// In en, this message translates to:
  /// **'Operation failed due to current state.'**
  String get firestoreErrorFailedPrecondition;

  /// No description provided for @firestoreErrorAborted.
  ///
  /// In en, this message translates to:
  /// **'Operation was aborted.'**
  String get firestoreErrorAborted;

  /// No description provided for @firestoreErrorOutOfRange.
  ///
  /// In en, this message translates to:
  /// **'Requested data is out of range.'**
  String get firestoreErrorOutOfRange;

  /// No description provided for @firestoreErrorUnimplemented.
  ///
  /// In en, this message translates to:
  /// **'This feature is not implemented yet.'**
  String get firestoreErrorUnimplemented;

  /// No description provided for @firestoreErrorInternal.
  ///
  /// In en, this message translates to:
  /// **'An internal error occurred.'**
  String get firestoreErrorInternal;

  /// No description provided for @firestoreErrorUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Service is currently unavailable.'**
  String get firestoreErrorUnavailable;

  /// No description provided for @firestoreErrorDataLoss.
  ///
  /// In en, this message translates to:
  /// **'Data loss occurred.'**
  String get firestoreErrorDataLoss;

  /// No description provided for @firestoreErrorUnauthenticated.
  ///
  /// In en, this message translates to:
  /// **'You must be signed in to perform this action.'**
  String get firestoreErrorUnauthenticated;

  /// No description provided for @firestoreErrorDeadlineExceeded.
  ///
  /// In en, this message translates to:
  /// **'Request timed out. Please try again.'**
  String get firestoreErrorDeadlineExceeded;

  /// No description provided for @firestoreErrorUnexpected.
  ///
  /// In en, this message translates to:
  /// **'Database error occurred. Please try again.'**
  String get firestoreErrorUnexpected;

  /// No description provided for @admobErrorInternal.
  ///
  /// In en, this message translates to:
  /// **'Ad service internal error.'**
  String get admobErrorInternal;

  /// No description provided for @admobErrorInvalidRequest.
  ///
  /// In en, this message translates to:
  /// **'Invalid ad request.'**
  String get admobErrorInvalidRequest;

  /// No description provided for @admobErrorNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Network error while loading ad.'**
  String get admobErrorNetworkError;

  /// No description provided for @admobErrorNoFill.
  ///
  /// In en, this message translates to:
  /// **'No ad available at this time.'**
  String get admobErrorNoFill;

  /// No description provided for @admobErrorUnexpected.
  ///
  /// In en, this message translates to:
  /// **'Ad error occurred.'**
  String get admobErrorUnexpected;

  /// No description provided for @purchaseErrorCancelled.
  ///
  /// In en, this message translates to:
  /// **'Purchase was cancelled.'**
  String get purchaseErrorCancelled;

  /// No description provided for @purchaseErrorPaymentInvalid.
  ///
  /// In en, this message translates to:
  /// **'Payment information is invalid.'**
  String get purchaseErrorPaymentInvalid;

  /// No description provided for @purchaseErrorClientInvalid.
  ///
  /// In en, this message translates to:
  /// **'Client is not allowed to make purchases.'**
  String get purchaseErrorClientInvalid;

  /// No description provided for @purchaseErrorPaymentNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Device is not allowed to make payments.'**
  String get purchaseErrorPaymentNotAllowed;

  /// No description provided for @purchaseErrorProductNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Product is not available for purchase.'**
  String get purchaseErrorProductNotAvailable;

  /// No description provided for @purchaseErrorProductInvalid.
  ///
  /// In en, this message translates to:
  /// **'Product ID is invalid.'**
  String get purchaseErrorProductInvalid;

  /// No description provided for @purchaseErrorStoreProductNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Product is not available in the store.'**
  String get purchaseErrorStoreProductNotAvailable;

  /// No description provided for @purchaseErrorUnexpected.
  ///
  /// In en, this message translates to:
  /// **'Purchase error occurred. Please try again.'**
  String get purchaseErrorUnexpected;

  /// No description provided for @networkErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Network connection error. Please check your internet connection and try again.'**
  String get networkErrorMessage;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
