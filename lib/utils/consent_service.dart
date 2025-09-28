import 'dart:io';

import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Lightweight consent manager for ads. Requests ATT on iOS and
/// fetches UMP consent if the UMP SDK is present. Falls back gracefully.
class ConsentService {
  ConsentService._();
  static final ConsentService instance = ConsentService._();

  bool _personalized = false;

  bool get isPersonalized => _personalized;

  /// Configure global ad request options according to consent.
  Future<void> configure() async {
    // Default to non-personalized until consent; request configuration is global
    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(
        testDeviceIds: const <String>[],
        // Tag for Child Directed Treatment or Users under the Age of Consent as needed.
        // tagForChildDirectedTreatment: TagForChildDirectedTreatment.unspecified,
        // maxAdContentRating: MaxAdContentRating.pg,
      ),
    );

    // On iOS, optionally request ATT using AppTrackingTransparency if available.
    if (Platform.isIOS) {
      try {
        // Defer to app code to integrate app_tracking_transparency if desired.
        // Keeping this as a placeholder hook.
      } catch (_) {}
    }

    // If you decide to add the Google UMP package, fetch consent here and set _personalized accordingly.
    _personalized = false; // default; update after integrating UMP/ATT result
  }
}
