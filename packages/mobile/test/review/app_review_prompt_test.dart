import 'package:flutter_test/flutter_test.dart';
import 'package:modulo_squares/gamecenter/game_center_ids.dart';
import 'package:modulo_squares/review/app_review_prompt.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeReviewRequester implements AppReviewRequester {
  int requests = 0;

  @override
  Future<void> requestReview() async => requests++;
}

class _Clock {
  _Clock(this.now);
  DateTime now;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<
    ({AppReviewPrompt prompt, _FakeReviewRequester requester, _Clock clock})
  >
  build({Map<String, Object> values = const <String, Object>{}}) async {
    SharedPreferences.setMockInitialValues(values);
    final prefs = await SharedPreferences.getInstance();
    final requester = _FakeReviewRequester();
    final clock = _Clock(DateTime.utc(2026, 11, 6));
    final prompt = AppReviewPrompt(
      requester: requester,
      preferences: prefs,
      clock: () => clock.now,
    );
    return (prompt: prompt, requester: requester, clock: clock);
  }

  test('a first-catch on a fresh install does not ask', () async {
    final harness = await build();
    harness.prompt.rememberLaunchHighScore(0);

    await harness.prompt.noteResolvedTile(
      isNewHighScore: true,
      highScore: 36,
      newlyEarnedAchievementIds: const [
        GameCenterIds.achievementFirstClean,
        GameCenterIds.achievementFirstBonus,
      ],
    );
    await harness.prompt.maybeRequestReview();

    expect(harness.requester.requests, 0);
  });

  test('the first level-up achievement asks once', () async {
    final harness = await build();
    harness.prompt.rememberLaunchHighScore(0);

    await harness.prompt.noteResolvedTile(
      isNewHighScore: true,
      highScore: 400,
      newlyEarnedAchievementIds: const [
        GameCenterIds.achievementFirstClean,
        GameCenterIds.achievementFirstLevel,
      ],
    );
    expect(harness.requester.requests, 0);

    await harness.prompt.maybeRequestReview();
    await harness.prompt.maybeRequestReview();

    expect(harness.requester.requests, 1);
  });

  test('beating a saved best asks, and a later session stays quiet', () async {
    final harness = await build();
    harness.prompt.rememberLaunchHighScore(120);

    await harness.prompt.noteResolvedTile(
      isNewHighScore: true,
      highScore: 180,
      newlyEarnedAchievementIds: const [GameCenterIds.achievementFirstClean],
    );
    await harness.prompt.maybeRequestReview();
    expect(harness.requester.requests, 1);

    final prefs = await SharedPreferences.getInstance();
    final again = _FakeReviewRequester();
    final later = AppReviewPrompt(
      requester: again,
      preferences: prefs,
      clock: () => harness.clock.now.add(const Duration(days: 30)),
    );
    later.rememberLaunchHighScore(180);
    await later.noteResolvedTile(
      isNewHighScore: true,
      highScore: 240,
      newlyEarnedAchievementIds: const [GameCenterIds.achievementCombo5],
    );
    await later.maybeRequestReview();

    expect(again.requests, 0);
  });

  test('a new milestone after the quiet period asks again', () async {
    final harness = await build();
    harness.prompt.rememberLaunchHighScore(0);
    await harness.prompt.noteResolvedTile(
      isNewHighScore: false,
      highScore: 10,
      newlyEarnedAchievementIds: const [GameCenterIds.achievementFirstLevel],
    );
    await harness.prompt.maybeRequestReview();

    final prefs = await SharedPreferences.getInstance();
    final again = _FakeReviewRequester();
    final later = AppReviewPrompt(
      requester: again,
      preferences: prefs,
      clock: () => harness.clock.now.add(AppReviewPrompt.quietPeriodDefault),
    );
    later.rememberLaunchHighScore(10);
    await later.noteResolvedTile(
      isNewHighScore: false,
      highScore: 10,
      newlyEarnedAchievementIds: const [GameCenterIds.achievementCombo10],
    );
    await later.maybeRequestReview();

    expect(again.requests, 1);
  });

  test(
    'an achievement already celebrated on this device does not ask',
    () async {
      final harness = await build();
      harness.prompt.rememberLaunchHighScore(0);
      await harness.prompt.noteResolvedTile(
        isNewHighScore: false,
        highScore: 10,
        newlyEarnedAchievementIds: const [GameCenterIds.achievementFirstLevel],
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppReviewPrompt.lastRequestMillisKey);
      final again = _FakeReviewRequester();
      final later = AppReviewPrompt(
        requester: again,
        preferences: prefs,
        clock: () => harness.clock.now.add(const Duration(days: 400)),
      );
      later.rememberLaunchHighScore(10);
      await later.noteResolvedTile(
        isNewHighScore: false,
        highScore: 10,
        newlyEarnedAchievementIds: const [GameCenterIds.achievementFirstLevel],
      );
      await later.maybeRequestReview();

      expect(again.requests, 0);
      expect(harness.requester.requests, 0);
    },
  );

  test('a stored request timestamp in the future stays quiet', () async {
    final future = DateTime.utc(2027, 1, 1).millisecondsSinceEpoch;
    final harness = await build(
      values: <String, Object>{AppReviewPrompt.lastRequestMillisKey: future},
    );
    harness.prompt.rememberLaunchHighScore(20);
    await harness.prompt.noteResolvedTile(
      isNewHighScore: true,
      highScore: 90,
      newlyEarnedAchievementIds: const [GameCenterIds.achievementScore1000],
    );
    await harness.prompt.maybeRequestReview();

    expect(harness.requester.requests, 0);
  });

  test('the disabled prompt never writes or asks', () async {
    final prefs = await SharedPreferences.getInstance();
    final prompt = AppReviewPrompt.disabled();
    prompt.rememberLaunchHighScore(40);
    await prompt.noteResolvedTile(
      isNewHighScore: true,
      highScore: 80,
      newlyEarnedAchievementIds: const [GameCenterIds.achievementFirstLevel],
    );
    await prompt.maybeRequestReview();

    expect(prefs.getInt(AppReviewPrompt.lastRequestMillisKey), isNull);
    expect(prefs.getStringList(AppReviewPrompt.seenAchievementsKey), isNull);
  });
}
