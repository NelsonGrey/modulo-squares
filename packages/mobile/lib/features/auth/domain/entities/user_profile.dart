import 'package:flutter/foundation.dart';

@immutable
class UserProfile {
  final String id;
  final String? displayName;
  final String? email;
  final String? photoUrl;
  final int highScore;
  final String? gamertag;

  const UserProfile({
    required this.id,
    this.displayName,
    this.email,
    this.photoUrl,
    this.highScore = 0,
    this.gamertag,
  });
}
