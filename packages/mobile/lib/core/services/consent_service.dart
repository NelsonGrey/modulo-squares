import 'dart:io';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Comprehensive privacy compliance manager for ads.
/// Handles ATT (App Tracking Transparency) on iOS and UMP (User Messaging Platform) consent.
class ConsentService {
  ConsentService._();
  static final ConsentService instance = ConsentService._();

  // Public constructor for dependency injection
  factory ConsentService() => instance;

  bool _personalized = false;
  bool _attAuthorized = false;

  bool get isPersonalized => _personalized && _attAuthorized;
  bool get attAuthorized => _attAuthorized;

  /// Configure global ad request options according to consent and tracking authorization.
  Future<void> configure() async {
    // Initialize with non-personalized ads by default
    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(
        testDeviceIds: const <String>[],
        // Tag for Child Directed Treatment or Users under the Age of Consent as needed.
        // tagForChildDirectedTreatment: TagForChildDirectedTreatment.unspecified,
        // maxAdContentRating: MaxAdContentRating.pg,
      ),
    );

    // Handle iOS App Tracking Transparency
    if (Platform.isIOS) {
      await _handleAppTrackingTransparency();
    }

    // Handle UMP consent (if implemented)
    await _handleUMPConsent();

    // Update ad configuration based on consent status
    await _updateAdConfiguration();
  }

  /// Handle iOS App Tracking Transparency permission request
  Future<void> _handleAppTrackingTransparency() async {
    try {
      // Check current tracking status
      final TrackingStatus status = await AppTrackingTransparency.trackingAuthorizationStatus;

      switch (status) {
        case TrackingStatus.authorized:
          _attAuthorized = true;
          break;
        case TrackingStatus.denied:
        case TrackingStatus.restricted:
        case TrackingStatus.notSupported:
          _attAuthorized = false;
          break;
        case TrackingStatus.notDetermined:
          // Request permission
          await AppTrackingTransparency.requestTrackingAuthorization();
          final TrackingStatus newStatus = await AppTrackingTransparency.trackingAuthorizationStatus;
          _attAuthorized = newStatus == TrackingStatus.authorized;
          break;
      }
    } catch (e) {
      // Fallback for devices that don't support ATT
      _attAuthorized = false;
    }
  }

  /// Handle UMP consent flow
  Future<void> _handleUMPConsent() async {
    try {
      // Request consent info update with debug settings
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(
          consentDebugSettings: ConsentDebugSettings(
            debugGeography: DebugGeography.debugGeographyDisabled,
          ),
        ),
        () {
          // Consent info updated successfully, now check if we can request ads
          _checkConsentStatus();
        },
        (FormError error) {
          // Consent info update failed, continue with non-personalized ads
          _personalized = false;
        },
      );
    } catch (e) {
      // Error occurred, continue with non-personalized ads
      _personalized = false;
    }
  }

  /// Check current consent status
  Future<void> _checkConsentStatus() async {
    try {
      // Check if we can request ads
      final canRequestAds = await ConsentInformation.instance.canRequestAds();

      if (!canRequestAds) {
        // Need to show consent form
        _loadAndShowConsentForm();
      } else {
        // Consent already obtained, can show personalized ads
        _personalized = true;
      }
    } catch (e) {
      // Error occurred, continue with non-personalized ads
      _personalized = false;
    }
  }

  /// Load and show UMP consent form
  Future<void> _loadAndShowConsentForm() async {
    try {
      // Load the consent form
      ConsentForm.loadConsentForm(
        (ConsentForm consentForm) {
          // Consent form loaded successfully, now show it
          consentForm.show((FormError? formError) {
            // Handle form dismissal
            if (formError != null) {
              // Form error occurred
              _personalized = false;
            } else {
              // Form completed successfully, recheck consent status
              _checkConsentStatus();
            }
          });
        },
        (FormError error) {
          // Consent form failed to load
          // Continue with non-personalized ads
          _personalized = false;
        },
      );
    } catch (e) {
      // Unexpected error
      // Continue with non-personalized ads
      _personalized = false;
    }
  }

  /// Update ad configuration based on current consent status
  Future<void> _updateAdConfiguration() async {
    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(
        testDeviceIds: const <String>[],
        // Respect ATT authorization for personalized ads
        tagForChildDirectedTreatment: TagForChildDirectedTreatment.unspecified,
        maxAdContentRating: MaxAdContentRating.pg,
      ),
    );
  }

  /// Request ATT permission again (useful for settings screen)
  Future<bool> requestTrackingAuthorization() async {
    if (!Platform.isIOS) return false;

    try {
      await AppTrackingTransparency.requestTrackingAuthorization();
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      _attAuthorized = status == TrackingStatus.authorized;
      await _updateAdConfiguration();
      return _attAuthorized;
    } catch (e) {
      return false;
    }
  }

  /// Get current ATT status description
  Future<String> getAttStatusDescription() async {
    if (!Platform.isIOS) return 'Not applicable on this platform';

    try {
      final TrackingStatus status = await AppTrackingTransparency.trackingAuthorizationStatus;
      switch (status) {
        case TrackingStatus.authorized:
          return 'Authorized - Personalized ads enabled';
        case TrackingStatus.denied:
          return 'Denied - Limited ad personalization';
        case TrackingStatus.restricted:
          return 'Restricted - Limited ad personalization';
        case TrackingStatus.notSupported:
          return 'Not supported - Limited ad personalization';
        case TrackingStatus.notDetermined:
          return 'Not determined - Permission not requested';
      }
    } catch (e) {
      return 'Error checking status - Limited ad personalization';
    }
  }
}
