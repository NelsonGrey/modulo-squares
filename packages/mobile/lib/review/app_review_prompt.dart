import 'package:modulo_squares/gamecenter/game_center_ids.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Asks StoreKit to present the system review prompt.
///
/// Implementations must call the system API only. No custom rating dialog
/// and no App Store listing deep link.
abstract class AppReviewRequester {
  const AppReviewRequester();

  Future<void> requestReview();
}

/// Chooses a positive moment to ask StoreKit for a review, then stays quiet.
///
/// A resolved tile arms the prompt when the player beats the best score that
/// was already saved when this screen opened (the first points on a fresh
/// install do not qualify) or earns an achievement past the first-catch set
/// for the first time on this device. [maybeRequestReview] performs the
/// request. The game screen calls that only at a level-complete break, after
/// the interstitial, so the prompt is not raised over a falling tile, at
/// launch, or from a timer.
///
/// Game Center is not involved: achievements are the ids the achievement
/// tracker already computed, whether or not the player is connected. At most one
/// StoreKit call is made per session, and not again until [quietPeriodDefault]
/// has passed, which keeps attempts inside Apple's cap of three prompts in
/// 365 days. StoreKit may still show nothing.
class AppReviewPrompt {
  AppReviewPrompt({
    required AppReviewRequester requester,
    required SharedPreferences preferences,
    DateTime Function()? clock,
    Duration? quietPeriod,
  }) : _requester = requester,
       _preferences = preferences,
       _clock = clock ?? DateTime.now,
       _quietPeriod = quietPeriod ?? quietPeriodDefault,
       _disabled = false {
    _seen.addAll(preferences.getStringList(seenAchievementsKey) ?? const []);
  }

  /// Never calls StoreKit. Local media-capture entry points use this so a
  /// recording cannot raise the system dialog.
  AppReviewPrompt.disabled()
    : _requester = const _NoReviewRequest(),
      _preferences = null,
      _clock = DateTime.now,
      _quietPeriod = quietPeriodDefault,
      _disabled = true;

  /// Milliseconds since epoch of the last StoreKit request attempt.
  static const lastRequestMillisKey = 'reviewPrompt.lastRequestMillis';

  /// Achievement ids already celebrated on this device.
  static const seenAchievementsKey = 'reviewPrompt.seenAchievementIds';

  /// Long enough that three attempts cannot fit in Apple's 365-day window.
  static const quietPeriodDefault = Duration(days: 122);

  /// First-catch ids. They can unlock on the opening drop, which is too
  /// close to first launch to be a review moment.
  static const earlyAchievementIds = <String>{
    GameCenterIds.achievementFirstClean,
    GameCenterIds.achievementFirstBonus,
    GameCenterIds.achievementLuckySeven,
  };

  final AppReviewRequester _requester;
  final SharedPreferences? _preferences;
  final DateTime Function() _clock;
  final Duration _quietPeriod;
  final bool _disabled;
  final Set<String> _seen = {};

  int? _launchHighScore;
  bool _armed = false;
  bool _requestedThisSession = false;

  /// The best score loaded from disk for this visit. Later scores are
  /// compared with this value, so climbing off zero during a first session
  /// is not treated as beating a previous best.
  void rememberLaunchHighScore(int score) {
    if (_disabled) return;
    _launchHighScore ??= score;
  }

  /// Records [newlyEarnedAchievementIds] and arms the prompt when this tile
  /// is a review-worthy moment. Arming happens before the returned future
  /// yields, so the caller can request a review immediately afterward.
  Future<void> noteResolvedTile({
    required bool isNewHighScore,
    required int highScore,
    required List<String> newlyEarnedAchievementIds,
  }) {
    if (_disabled) return Future<void>.value();

    final freshMilestones = <String>[];
    var changed = false;
    for (final id in newlyEarnedAchievementIds) {
      if (_seen.add(id)) {
        changed = true;
        if (!earlyAchievementIds.contains(id)) freshMilestones.add(id);
      }
    }

    if (!_requestedThisSession &&
        !_armed &&
        (_beatSavedBest(isNewHighScore, highScore) ||
            freshMilestones.isNotEmpty)) {
      _armed = true;
    }

    final preferences = _preferences;
    if (!changed || preferences == null) return Future<void>.value();
    return preferences.setStringList(seenAchievementsKey, _seen.toList());
  }

  /// Asks StoreKit when a good moment was armed and the quiet period has
  /// elapsed. A no-op otherwise, including when StoreKit has already been
  /// asked during this session.
  Future<void> maybeRequestReview() async {
    if (_disabled || !_armed || _requestedThisSession) return;
    if (_inQuietPeriod()) return;

    _requestedThisSession = true;
    _armed = false;
    final preferences = _preferences;
    if (preferences != null) {
      await preferences.setInt(
        lastRequestMillisKey,
        _clock().millisecondsSinceEpoch,
      );
    }
    await _requester.requestReview();
  }

  bool _beatSavedBest(bool isNewHighScore, int highScore) {
    final saved = _launchHighScore;
    if (!isNewHighScore || saved == null || saved <= 0) return false;
    return highScore > saved;
  }

  bool _inQuietPeriod() {
    final millis = _preferences?.getInt(lastRequestMillisKey);
    if (millis == null) return false;
    final elapsed = _clock().difference(
      DateTime.fromMillisecondsSinceEpoch(millis),
    );
    if (elapsed.isNegative) return true;
    return elapsed < _quietPeriod;
  }
}

class _NoReviewRequest implements AppReviewRequester {
  const _NoReviewRequest();

  @override
  Future<void> requestReview() async {}
}
