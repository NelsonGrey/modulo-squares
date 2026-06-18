// /Users/marknelson/Circus/Repositories/modulo_flutter_project/lib/src/features/profile/domain/entities/user_profile.dart

import 'package:flutter/foundation.dart';

@immutable
class UserProfile {
  final String id;
  final String? displayName;
  final String? email;
  final String? photoUrl;
  final int highScore;
  // Add other domain-specific profile fields

  const UserProfile({
    required this.id,
    this.displayName,
    this.email,
    this.photoUrl,
    this.highScore = 0,
  });

  // You might add copyWith, equality, and hashCode methods here if needed
}