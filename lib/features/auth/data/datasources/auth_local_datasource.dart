import 'dart:convert';

import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/utils/password_hasher.dart';
import '../../domain/entities/agent_user.dart';
import '../models/agent_user_model.dart';

/// Persists and validates the agent session on-device, enabling offline login.
///
/// Everything here lives in encrypted secure storage: the JWT (via the existing
/// token helpers), the cached agent profile, the matricule, and a salted hash
/// of the password.
class AuthLocalDataSource {
  const AuthLocalDataSource(this._storage);

  final SecureStorageService _storage;

  static const _kUser = 'auth_user';
  static const _kMatricule = 'auth_matricule';
  static const _kPwdHash = 'auth_pwd_hash';
  static const _kPwdSalt = 'auth_pwd_salt';

  /// Caches the full session after a successful ONLINE login.
  Future<void> persistSession({
    required String accessToken,
    String? refreshToken,
    required AgentUser user,
    required String matricule,
    required String password,
  }) async {
    await _storage.saveAccessToken(accessToken);
    if (refreshToken != null) {
      await _storage.saveRefreshToken(refreshToken);
    }

    final salt = PasswordHasher.generateSalt();
    await _storage.write(_kPwdSalt, salt);
    await _storage.write(_kPwdHash, PasswordHasher.hash(password, salt));
    await _storage.write(_kMatricule, matricule);
    await _storage.write(_kUser, jsonEncode(AgentUserModel.toJson(user)));
  }

  /// Whether a previous online login exists on this device.
  Future<bool> hasStoredCredentials() async {
    final user = await _storage.read(_kUser);
    final hash = await _storage.read(_kPwdHash);
    return user != null && hash != null;
  }

  Future<AgentUser?> getStoredUser() async {
    final raw = await _storage.read(_kUser);
    if (raw == null) return null;
    return AgentUserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  /// Validates offline credentials against the stored salted hash.
  Future<bool> validateOffline({
    required String matricule,
    required String password,
  }) async {
    final storedMatricule = await _storage.read(_kMatricule);
    final salt = await _storage.read(_kPwdSalt);
    final hash = await _storage.read(_kPwdHash);
    if (storedMatricule == null || salt == null || hash == null) return false;
    if (storedMatricule != matricule) return false;
    return PasswordHasher.verify(password, salt, hash);
  }

  Future<void> clear() => _storage.clear();
}
