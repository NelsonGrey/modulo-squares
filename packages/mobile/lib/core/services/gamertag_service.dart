import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

class GamertagService {
  static const int _minLength = 3;
  static const int _maxLength = 20;

  // Lowercase substrings that are never allowed in gamertags.
  // Server-side enforcement (Firestore rules / Cloud Functions) is the primary
  // guard; this list provides immediate client-side feedback.
  static const List<String> _blockedTerms = [
    'nigger', 'nigga', 'faggot', 'fag', 'retard', 'chink', 'spic', 'wetback',
    'kike', 'gook', 'tranny', 'cunt', 'whore', 'slut', 'rape', 'hitler',
    'nazi', 'kkk', 'jihad', 'isis', 'pedophile', 'pedo', 'molest',
  ];

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Returns an error message, or null if the tag is acceptable.
  static String? validate(String tag) {
    if (tag.length < _minLength) {
      return 'Gamertag must be at least $_minLength characters.';
    }
    if (tag.length > _maxLength) {
      return 'Gamertag must be $_maxLength characters or fewer.';
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(tag)) {
      return 'Only letters, numbers, and underscores are allowed.';
    }
    if (tag.startsWith('_') || tag.endsWith('_')) {
      return 'Gamertag cannot start or end with an underscore.';
    }
    if (RegExp(r'^[0-9]+$').hasMatch(tag)) {
      return 'Gamertag must contain at least one letter.';
    }
    final lower = tag.toLowerCase();
    for (final term in _blockedTerms) {
      if (lower.contains(term)) {
        return 'That gamertag is not allowed.';
      }
    }
    return null;
  }

  /// Returns true when no other account holds this tag (case-insensitive).
  static Future<bool> isAvailable(String tag) async {
    try {
      final doc = await _db
          .collection('gamertags')
          .doc(tag.toLowerCase())
          .get();
      return !doc.exists;
    } catch (_) {
      // Treat Firestore errors as available to avoid blocking the user;
      // the server-side uniqueness constraint is the real guard.
      return true;
    }
  }

  /// Returns the gamertag for a user, or null if not yet set.
  static Future<String?> getGamertag(String uid) async {
    // Right after sign-in, the Auth ID token can take a moment to propagate
    // to Firestore's underlying connection, so this first read can fail with
    // permission-denied even though the security rules are correct and the
    // user really is authenticated. Retry briefly before giving up so a
    // returning user with a real gamertag isn't misdiagnosed as new.
    const maxAttempts = 3;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final doc = await _db.collection('users').doc(uid).get();
        return doc.data()?['gamertag'] as String?;
      } on FirebaseException catch (e) {
        if (e.code == 'permission-denied' && attempt < maxAttempts) {
          await Future.delayed(Duration(milliseconds: 400 * attempt));
          continue;
        }
        return null;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Saves the gamertag atomically: user record + uniqueness index.
  static Future<void> setGamertag(String uid, String tag) async {
    final batch = _db.batch();
    batch.set(
      _db.collection('users').doc(uid),
      {'gamertag': tag},
      SetOptions(merge: true),
    );
    batch.set(
      _db.collection('gamertags').doc(tag.toLowerCase()),
      {'uid': uid, 'tag': tag},
    );
    await batch.commit();
  }
}
