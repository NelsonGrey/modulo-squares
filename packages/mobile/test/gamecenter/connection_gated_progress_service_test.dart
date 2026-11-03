import 'package:flutter_test/flutter_test.dart';
import 'package:modulo_squares/gamecenter/connection_gated_progress_service.dart';
import 'package:modulo_squares/gamecenter/fake_game_center_progress_service.dart';
import 'package:modulo_squares/gamecenter/fake_platform_game_auth_service.dart';
import 'package:modulo_squares/gamecenter/game_center_connection.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late FakeGameCenterProgressService inner;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    inner = FakeGameCenterProgressService();
  });

  test('forwards everything while connected', () async {
    final service = ConnectionGatedProgressService(
      inner,
      GameCenterConnection.connectedFake(),
    );

    await service.submitScore(120);
    await service.unlockAchievement('a');
    await service.showLeaderboard();
    await service.showAchievements();

    expect(inner.scores, [120]);
    expect(inner.unlocked, {'a'});
    expect(inner.leaderboardShown, 1);
    expect(inner.achievementsShown, 1);
  });

  test('drops scores and screens while disconnected', () async {
    final connection = GameCenterConnection(
      auth: FakePlatformGameAuthService(),
      supported: true,
    );
    final service = ConnectionGatedProgressService(inner, connection);

    await service.submitScore(120);
    await service.showLeaderboard();
    await service.showAchievements();

    expect(inner.scores, isEmpty);
    expect(inner.leaderboardShown, 0);
    expect(inner.achievementsShown, 0);
  });

  test(
    'keeps achievements earned while disconnected and grants them later',
    () async {
      final connection = GameCenterConnection(
        auth: FakePlatformGameAuthService(),
        supported: true,
      );
      final service = ConnectionGatedProgressService(inner, connection);

      await service.unlockAchievement('level_5');
      expect(inner.unlocked, isEmpty);

      await connection.connect();
      await service.flushEarned();
      expect(inner.unlocked, {'level_5'});

      // The queue is cleared once granted.
      inner.unlocked.clear();
      await service.flushEarned();
      expect(inner.unlocked, isEmpty);
    },
  );

  test(
    'does not queue achievements where Game Center is unsupported',
    () async {
      final service = ConnectionGatedProgressService(
        inner,
        GameCenterConnection.unsupportedFake(),
      );

      await service.unlockAchievement('level_5');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('gamecenter.earnedWhileDisconnected'), isNull);
    },
  );
}
