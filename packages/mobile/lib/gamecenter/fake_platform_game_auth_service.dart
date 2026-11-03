import 'dart:async';

import 'package:modulo_squares/gamecenter/app_user.dart';
import 'package:modulo_squares/gamecenter/platform_game_auth_service.dart';

/// Deterministic [PlatformGameAuthService] for tests and non-iOS platforms.
class FakePlatformGameAuthService implements PlatformGameAuthService {
  FakePlatformGameAuthService({this.failSignIn = false});

  /// When true, [signIn] throws, as if no Game Center account were available.
  bool failSignIn;

  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _currentUser;

  @override
  Stream<AppUser?> authStateChanges() => _controller.stream;

  @override
  AppUser? get currentUser => _currentUser;

  @override
  Future<AppUser> signIn() async {
    if (failSignIn) throw StateError('Game Center unavailable.');
    final user = const AppUser(uid: 'fake-player', displayName: 'Test Player');
    _currentUser = user;
    _controller.add(user);
    return user;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _controller.add(null);
  }
}
