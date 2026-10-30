import 'package:flutter_test/flutter_test.dart';
import 'package:modulo_squares/core/di/service_locator.dart';
import 'package:modulo_squares/features/game/falling_modulo_game_screen.dart';
import 'package:modulo_squares/gamecenter/fake_game_center_progress_service.dart';
import 'package:modulo_squares/gamecenter/fake_platform_game_auth_service.dart';
import 'package:modulo_squares/gamecenter/game_center_connection.dart';
import 'package:modulo_squares/gamecenter/game_center_services.dart';
import 'package:modulo_squares/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('starts straight into the game with no account step', (
    tester,
  ) async {
    // Game Center has been answered already, so no first-run prompt covers
    // the screen.
    getIt.registerSingleton<GameCenterServices>(
      GameCenterServices(
        auth: FakePlatformGameAuthService(),
        backend: FakeGameCenterProgressService(),
        connection: GameCenterConnection.connectedFake(),
      ),
    );

    await tester.pumpWidget(const ModuloApp());
    await tester.pump();

    expect(find.byType(FallingModuloGameScreen), findsOneWidget);
    expect(find.textContaining('Sign'), findsNothing);
  });

  testWidgets('offers Game Center once on first launch', (tester) async {
    getIt.registerSingleton<GameCenterServices>(
      GameCenterServices(
        auth: FakePlatformGameAuthService(),
        backend: FakeGameCenterProgressService(),
        connection: GameCenterConnection(
          auth: FakePlatformGameAuthService(),
          supported: true,
        ),
      ),
    );

    await tester.pumpWidget(const ModuloApp());
    await tester.pump();
    await tester.pump();

    expect(find.text('Connect to Game Center?'), findsOneWidget);
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(find.text('Connect to Game Center?'), findsNothing);
  });
}
