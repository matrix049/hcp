import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Encrypted key/value storage for sensitive values (JWT access + refresh
/// tokens). Backed by the OS keystore/keychain via `flutter_secure_storage`,
/// so tokens are never stored in plain SQLite or SharedPreferences.
///
/// Wrapping the plugin behind our own service keeps the rest of the app
/// decoupled from the package and makes it trivial to mock in tests.
class SecureStorageService {
  SecureStorageService([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _storage;

  static const _kAccessToken = 'access_token';
  static const _kRefreshToken = 'refresh_token';

  Future<void> saveAccessToken(String token) =>
      _storage.write(key: _kAccessToken, value: token);

  Future<String?> readAccessToken() => _storage.read(key: _kAccessToken);

  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: _kRefreshToken, value: token);

  Future<String?> readRefreshToken() => _storage.read(key: _kRefreshToken);

  // --- Generic secure key/value access ---
  // Used by features (e.g. auth) to store other sensitive values such as the
  // cached agent profile and the offline-login password hash.

  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  Future<String?> read(String key) => _storage.read(key: key);

  Future<void> delete(String key) => _storage.delete(key: key);

  /// Clears everything (tokens + cached profile + password hash) — called on
  /// logout or on an unrecoverable 401.
  Future<void> clear() => _storage.deleteAll();
}
