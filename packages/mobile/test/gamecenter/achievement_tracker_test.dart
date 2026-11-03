import 'package:flutter_test/flutter_test.dart';
import 'package:modulo_squares/features/game/models/falling_modulo_game_engine.dart';
import 'package:modulo_squares/gamecenter/achievement_tracker.dart';
import 'package:modulo_squares/gamecenter/game_center_ids.dart';

FallingModuloResolution _res({
  bool success = true,
  int bucket = 3,
  int combo = 1,
  bool bonus = false,
  bool leveledUp = false,
}) => FallingModuloResolution(
  success: success,
  fallingValue: 18,
  bucketValue: bucket,
  remainder: success ? 0 : 1,
  scoreDelta: 10,
  scoreAfter: 10,
  comboAfter: combo,
  leveledUp: leveledUp,
  isHighestBucket: bonus,
);

FallingModuloGameState _state({
  int level = 1,
  int score = 0,
  GameDifficulty difficulty = GameDifficulty.normal,
}) => FallingModuloGameEngine().createInitialState().copyWith(
  level: level,
  score: score,
  difficulty: difficulty,
);

void main() {
  late AchievementTracker tracker;

  setUp(() => tracker = AchievementTracker());

  test('first clean division', () {
    expect(tracker.onTileResolved(_res(), _state()), [
      GameCenterIds.achievementFirstClean,
    ]);
  });

  test('a miss earns nothing', () {
    expect(tracker.onTileResolved(_res(success: false), _state()), isEmpty);
  });

  test('bonus bucket and lucky seven', () {
    final earned = tracker.onTileResolved(
      _res(bonus: true, bucket: 7),
      _state(),
    );
    expect(
      earned,
      containsAll([
        GameCenterIds.achievementFirstBonus,
        GameCenterIds.achievementLuckySeven,
      ]),
    );
  });

  test('lucky seven needs a successful landing', () {
    expect(
      tracker.onTileResolved(_res(success: false, bucket: 7), _state()),
      isNot(contains(GameCenterIds.achievementLuckySeven)),
    );
  });

  test('combo tiers unlock cumulatively once', () {
    expect(
      tracker.onTileResolved(_res(combo: 10), _state()),
      containsAll([
        GameCenterIds.achievementCombo5,
        GameCenterIds.achievementCombo10,
      ]),
    );
    final later = tracker.onTileResolved(_res(combo: 25), _state());
    expect(later, [GameCenterIds.achievementCombo25]);
  });

  test('score tiers', () {
    final earned = tracker.onTileResolved(_res(), _state(score: 5200));
    expect(
      earned,
      containsAll([
        GameCenterIds.achievementScore1000,
        GameCenterIds.achievementScore5000,
      ]),
    );
    expect(earned, isNot(contains(GameCenterIds.achievementScore25000)));
  });

  test('level tiers', () {
    final earned = tracker.onTileResolved(_res(), _state(level: 10));
    expect(
      earned,
      containsAll([
        GameCenterIds.achievementFirstLevel,
        GameCenterIds.achievementLevel5,
        GameCenterIds.achievementLevel10,
      ]),
    );
    expect(earned, isNot(contains(GameCenterIds.achievementLevel20)));
  });

  test('hard level 5 needs Hard difficulty', () {
    expect(
      tracker.onTileResolved(_res(), _state(level: 5)),
      isNot(contains(GameCenterIds.achievementHardLevel5)),
    );
    expect(
      tracker.onTileResolved(
        _res(),
        _state(level: 5, difficulty: GameDifficulty.hard),
      ),
      contains(GameCenterIds.achievementHardLevel5),
    );
  });

  test('perfect level: completing a level with no misses', () {
    tracker.onTileResolved(_res(), _state());
    final earned = tracker.onTileResolved(
      _res(leveledUp: true),
      _state(level: 2),
    );
    expect(earned, contains(GameCenterIds.achievementPerfectLevel));
  });

  test('a miss spoils the perfect level, and the count resets per level', () {
    tracker.onTileResolved(_res(success: false), _state());
    expect(
      tracker.onTileResolved(_res(leveledUp: true), _state(level: 2)),
      isNot(contains(GameCenterIds.achievementPerfectLevel)),
    );
    // Next level is clean again.
    expect(
      tracker.onTileResolved(_res(leveledUp: true), _state(level: 3)),
      contains(GameCenterIds.achievementPerfectLevel),
    );
  });

  test('starting a new run clears the miss count', () {
    tracker.onTileResolved(_res(success: false), _state());
    tracker.startNewRun();
    expect(
      tracker.onTileResolved(_res(leveledUp: true), _state(level: 2)),
      contains(GameCenterIds.achievementPerfectLevel),
    );
  });

  test('every ID in GameCenterIds.all is reachable', () {
    final earned = <String>{};
    earned.addAll(
      tracker.onTileResolved(
        _res(combo: 25, bonus: true, bucket: 7, leveledUp: true),
        _state(level: 20, score: 30000, difficulty: GameDifficulty.hard),
      ),
    );
    expect(earned, GameCenterIds.all.toSet());
  });
}
