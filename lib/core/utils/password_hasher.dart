import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Pure, dependency-free password hashing used for **offline login**.
///
/// After a successful ONLINE login (server has validated the password), we
/// store `salt` + `hash(password, salt)` in secure storage. Offline, we re-hash
/// the entered password with the stored salt and compare — the plaintext
/// password is never persisted.
///
/// Being a pure static helper makes it trivially unit-testable (no plugins).
class PasswordHasher {
  const PasswordHasher._();

  /// Cryptographically-random salt, base64url-encoded.
  static String generateSalt([int length = 16]) {
    final rng = Random.secure();
    final bytes = List<int>.generate(length, (_) => rng.nextInt(256));
    return base64Url.encode(bytes);
  }

  /// Salted SHA-256 of the password.
  static String hash(String password, String salt) {
    final digest = sha256.convert(utf8.encode('$salt::$password'));
    return digest.toString();
  }

  /// True if [password] matches the previously stored [expectedHash].
  static bool verify(String password, String salt, String expectedHash) {
    return hash(password, salt) == expectedHash;
  }
}
