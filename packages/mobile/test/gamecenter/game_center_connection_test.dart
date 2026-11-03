import 'package:flutter_test/flutter_test.dart';
import 'package:modulo_squares/gamecenter/fake_platform_game_auth_service.dart';
import 'package:modulo_squares/gamecenter/game_center_connection.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  GameCenterConnection build({
    bool failSignIn = false,
    bool supported = true,
  }) => GameCenterConnection(
    auth: FakePlatformGameAuthService(failSignIn: failSignIn),
    supported: supported,
  );

  test('does nothing until the player opts in', () async {
    final connection = build();
    await connection.load();

    expect(connection.status, GameCenterStatus.off);
    expect(connection.shouldPrompt, isTrue);
  });

  test('connect signs in and remembers the choice', () async {
    final connection = build();
    await connection.load();
    await connection.connect();

    expect(connection.isConnected, isTrue);
    expect(connection.playerName, 'Test Player');
    expect(connection.shouldPrompt, isFalse);

    final reloaded = build();
    await reloaded.load();
    expect(reloaded.isConnected, isTrue, reason: 'reconnects silently');
  });

  test('declining is remembered and does not connect', () async {
    final connection = build();
    await connection.load();
    await connection.decline();

    expect(connection.isConnected, isFalse);
    expect(connection.shouldPrompt, isFalse);

    final reloaded = build();
    await reloaded.load();
    expect(reloaded.status, GameCenterStatus.off);
    expect(reloaded.shouldPrompt, isFalse);
  });

  test('a failed sign-in is unavailable and can be retried', () async {
    final auth = FakePlatformGameAuthService(failSignIn: true);
    final connection = GameCenterConnection(auth: auth, supported: true);
    await connection.load();
    await connection.connect();
    expect(connection.status, GameCenterStatus.unavailable);

    auth.failSignIn = false;
    await connection.connect();
    expect(connection.isConnected, isTrue);
  });

  test('disconnect stops using Game Center', () async {
    final connection = build();
    await connection.load();
    await connection.connect();
    await connection.disconnect();

    expect(connection.status, GameCenterStatus.off);
    expect(connection.playerName, isNull);

    final reloaded = build();
    await reloaded.load();
    expect(reloaded.status, GameCenterStatus.off);
  });

  test('is inert and never prompts where unsupported', () async {
    final connection = build(supported: false);
    await connection.load();
    await connection.connect();

    expect(connection.status, GameCenterStatus.off);
    expect(connection.shouldPrompt, isFalse);
  });
}
