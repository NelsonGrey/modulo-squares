import 'dart:io';

import 'package:modulo_squares/gamecenter/connection_gated_progress_service.dart';
import 'package:modulo_squares/gamecenter/fake_game_center_progress_service.dart';
import 'package:modulo_squares/gamecenter/fake_platform_game_auth_service.dart';
import 'package:modulo_squares/gamecenter/game_center_auth_service.dart';
import 'package:modulo_squares/gamecenter/game_center_connection.dart';
import 'package:modulo_squares/gamecenter/game_center_progress_service.dart';
import 'package:modulo_squares/gamecenter/games_services_progress_service.dart';
import 'package:modulo_squares/gamecenter/platform_game_auth_service.dart';

/// The app's Game Center wiring: the player's opt-in [connection] and the
/// [progress] calls (leaderboard, achievements) that only act while connected.
///
/// Game Center exists on iOS/macOS only; elsewhere this falls back to fakes
/// and [GameCenterConnection.supported] is false, so every control hides.
class GameCenterServices {
  GameCenterServices({
    PlatformGameAuthService? auth,
    GameCenterProgressService? backend,
    GameCenterConnection? connection,
  }) {
    final platformAuth = auth ?? _defaultAuth();
    this.connection =
        connection ??
        GameCenterConnection(auth: platformAuth, supported: _supported);
    progress = ConnectionGatedProgressService(
      backend ?? _defaultBackend(),
      this.connection,
    );
    this.connection.addListener(_flushOnConnect);
  }

  static bool get _supported => Platform.isIOS || Platform.isMacOS;

  static PlatformGameAuthService _defaultAuth() =>
      _supported ? GameCenterAuthService() : FakePlatformGameAuthService();

  static GameCenterProgressService _defaultBackend() =>
      _supported
          ? GamesServicesProgressService()
          : FakeGameCenterProgressService();

  late final GameCenterConnection connection;
  late final ConnectionGatedProgressService progress;

  bool _wasConnected = false;

  /// After each Game Center sign-in, grant achievements earned while
  /// disconnected.
  void _flushOnConnect() {
    final connected = connection.isConnected;
    if (connected && !_wasConnected) progress.flushEarned();
    _wasConnected = connected;
  }
}
