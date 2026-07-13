import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/agent_user.dart';
import '../models/agent_user_model.dart';

/// Result of a successful server login.
class AuthLoginResponse {
  const AuthLoginResponse({
    required this.accessToken,
    required this.user,
    this.refreshToken,
  });

  final String accessToken;
  final String? refreshToken;
  final AgentUser user;
}

/// Talks to the Node/Express auth endpoints.
///
/// Expected contract (backend, built in a later step):
///   POST /auth/login  { matricule, password }
///     200 -> { accessToken, refreshToken?, user: { id, matricule,
///              firstName, lastName, role, region, phone? } }
///     401 -> invalid credentials
class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._dio);

  final Dio _dio;

  Future<AuthLoginResponse> login({
    required String matricule,
    required String password,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'matricule': matricule, 'password': password},
      );
      final data = res.data!;
      return AuthLoginResponse(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String?,
        user: AgentUserModel.fromJson(data['user'] as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw AuthException('Invalid matricule or password');
      }
      throw ServerException('Login failed', e.response?.statusCode);
    }
  }
}
