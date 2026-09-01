import 'package:dartz/dartz.dart';

import '../../../../core/connectivity/connectivity_service.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/agent_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';

/// The online/offline decision-maker for authentication.
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required this.remote,
    required this.local,
    required this.connectivity,
  });

  final AuthRemoteDataSource remote;
  final AuthLocalDataSource local;
  final ConnectivityService connectivity;

  @override
  Future<Either<Failure, AgentUser>> login({
    required String matricule,
    required String password,
  }) async {
    final online = await connectivity.isConnected;
    final hasLocal = await local.hasStoredCredentials();

    if (online) {
      try {
        final res = await remote.login(matricule: matricule, password: password);
        await local.persistSession(
          accessToken: res.accessToken,
          refreshToken: res.refreshToken,
          user: res.user,
          matricule: matricule,
          password: password,
        );
        return Right(res.user);
      } on AuthException catch (e) {
        // Wrong credentials must NEVER fall back to offline.
        return Left(AuthFailure(e.message));
      } on ServerException catch (e) {
        // Server/network hiccup: fall back to offline if we can.
        if (hasLocal) return _offlineLogin(matricule, password);
        return Left(ServerFailure(e.message));
      }
    }

    // Offline path.
    if (!hasLocal) {
      return const Left(
        NetworkFailure('La première connexion nécessite Internet.'),
      );
    }
    return _offlineLogin(matricule, password);
  }

  Future<Either<Failure, AgentUser>> _offlineLogin(
    String matricule,
    String password,
  ) async {
    final valid = await local.validateOffline(
      matricule: matricule,
      password: password,
    );
    if (!valid) {
      return const Left(AuthFailure('Matricule ou mot de passe incorrect.'));
    }
    final user = await local.getStoredUser();
    if (user == null) return const Left(CacheFailure());
    return Right(user);
  }

  @override
  Future<Either<Failure, AgentUser?>> getCurrentAgent() async {
    try {
      return Right(await local.getStoredUser());
    } catch (_) {
      return const Left(CacheFailure());
    }
  }

  @override
  Future<void> logout() => local.clear();
}
