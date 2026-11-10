import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:modulo_squares/review/app_review_prompt.dart';

/// iOS implementation of [AppReviewRequester].
///
/// `in_app_review` calls `SKStoreReviewController.requestReview(in:)` on
/// iOS 15 and `AppStore.requestReview(in:)` on iOS 16 and later. Both are
/// Apple's system prompt. The system decides whether a dialog appears and
/// limits display to three times in a 365-day period. This does not call
/// `openStoreListing`.
class StoreKitReviewRequester implements AppReviewRequester {
  const StoreKitReviewRequester();

  @override
  Future<void> requestReview() async {
    if (kIsWeb || !Platform.isIOS) return;
    try {
      await InAppReview.instance.requestReview();
    } catch (_) {
      // Best-effort, same as Game Center submissions. A missing plugin or a
      // StoreKit refusal must not break the level-complete flow.
    }
  }
}
