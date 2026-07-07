import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

const _kNonceCharset =
    '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';

/// Generates a cryptographically secure random nonce for use with Sign in
/// with Apple. Firebase requires the SHA-256 hash of this raw value to be
/// passed to Apple, and the raw value itself passed back to Firebase, to
/// verify the returned identity token was issued for this exact request.
String generateAppleSignInNonce([int length = 32]) {
  final random = Random.secure();
  return List.generate(
    length,
    (_) => _kNonceCharset[random.nextInt(_kNonceCharset.length)],
  ).join();
}

String sha256OfString(String input) {
  final bytes = utf8.encode(input);
  return sha256.convert(bytes).toString();
}
