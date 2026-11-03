import 'dart:async';
import 'dart:io';

import 'package:games_services/games_services.dart';
import 'package:modulo_squares/gamecenter/app_user.dart';
import 'package:modulo_squares/gamecenter/platform_game_auth_service.dart';

/// Real [PlatformGameAuthService] backed by Game Center, via the
/// `games_services` plugin's `GameAuth` API. iOS/macOS only.
class GameCenterAuthService implements PlatformGameAuthService {
  GameCenterAuthService() {
    if (!_isSupportedPlatform) {
      throw UnsupportedError(
        'GameCenterAuthService is only supported on iOS/macOS.',
      );
    }
    // games_services has no synchronous "current player" getter, only the
    // `player` stream and async lookups, so cache the stream's latest value.
    _authStateChanges.listen((user) => _currentUser = user);
  }

  static bool get _isSupportedPlatform => Platform.isIOS || Platform.isMacOS;

  AppUser? _currentUser;

  Stream<AppUser?> get _authStateChanges => GameAuth.player.map(_toAppUser);

  AppUser? _toAppUser(PlayerData? player) =>
      player?.playerID == null
          ? null
          : AppUser(uid: player!.playerID!, displayName: player.displayName);

  @override
  Stream<AppUser?> authStateChanges() => _authStateChanges;

  @override
  AppUser? get currentUser => _currentUser;

  @override
  Future<AppUser> signIn() async {
    await GameAuth.signIn();
    final player = await GameAuth.player.first;
    final user = _toAppUser(player);
    if (user == null) {
      throw StateError('Game Center did not return a signed-in player.');
    }
    _currentUser = user;
    return user;
  }

  @override
  Future<void> signOut() async {
    // Game Center has no programmatic sign-out; the player manages their
    // session in iOS Settings. Nothing to do here.
  }
}
