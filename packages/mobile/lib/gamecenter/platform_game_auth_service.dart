import 'dart:async';

import 'package:modulo_squares/gamecenter/app_user.dart';

/// Sign-in through the platform's own game-services identity (Game Center on
/// iOS/macOS). The platform picks the identity, so there is no
/// choice-of-provider: one [signIn] call authenticates the local player.
abstract class PlatformGameAuthService {
  Stream<AppUser?> authStateChanges();
  AppUser? get currentUser;

  Future<AppUser> signIn();

  /// Game Center has no real "sign out" — the platform owns the session.
  /// Implementations may treat this as a local-state reset only.
  Future<void> signOut();
}
