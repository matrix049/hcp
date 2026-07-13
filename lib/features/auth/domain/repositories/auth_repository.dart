import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/agent_user.dart';

/// Contract for authentication. The implementation (data layer) decides between
/// online and offline login; callers only see `Either<Failure, AgentUser>`.
abstract interface class AuthRepository {
  /// Logs in with matricule + password.
  ///
  /// Online → validates against the server and caches the session for later
  /// offline use. Offline → validates against the cached credentials, but only
  /// if a previous online login exists on this device.
  Future<Either<Failure, AgentUser>> login({
    required String matricule,
    required String password,
  });

  /// Restores the cached agent on app startup, or `null` if none is stored.
  Future<Either<Failure, AgentUser?>> getCurrentAgent();

  /// Clears the cached session (tokens + profile + password hash).
  Future<void> logout();
}
