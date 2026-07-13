import 'package:dio/dio.dart';

import '../config/app_constants.dart';
import '../storage/secure_storage_service.dart';

/// Attaches the JWT to every request and transparently refreshes it on 401.
///
/// Flow on a 401 (for a non-auth endpoint that hasn't already been retried):
///   1. Call `POST /auth/refresh` once (guarded so concurrent 401s share it).
///   2. On success → save the new tokens and RETRY the original request.
///   3. On failure → clear the session and notify [onSessionExpired] so the app
///      can send the agent back to login.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required SecureStorageService storage,
    required Dio dio,
    this.onSessionExpired,
  })  : _storage = storage,
        _dio = dio,
        // A bare Dio (no interceptors) for the refresh call, to avoid recursion.
        _refreshDio = Dio(
          BaseOptions(
            baseUrl: AppConstants.apiBaseUrl,
            connectTimeout: AppConstants.connectTimeout,
            receiveTimeout: AppConstants.receiveTimeout,
            contentType: Headers.jsonContentType,
          ),
        );

  final SecureStorageService _storage;
  final Dio _dio;
  final Dio _refreshDio;
  final void Function()? onSessionExpired;

  /// Single in-flight refresh so a burst of 401s triggers only one call.
  Future<bool>? _refreshing;

  static const _retriedFlag = '__auth_retried__';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.readAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final is401 = err.response?.statusCode == 401;
    final alreadyRetried = err.requestOptions.extra[_retriedFlag] == true;

    if (!is401 || alreadyRetried || _isAuthEndpoint(err.requestOptions.path)) {
      return handler.next(err);
    }

    final refreshed = await _refreshOnce();
    if (!refreshed) {
      await _storage.clear();
      onSessionExpired?.call();
      return handler.next(err);
    }

    // Retry the original request with the fresh access token.
    try {
      final token = await _storage.readAccessToken();
      final options = err.requestOptions
        ..headers['Authorization'] = 'Bearer $token'
        ..extra[_retriedFlag] = true;
      final response = await _dio.fetch<dynamic>(options);
      return handler.resolve(response);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }

  bool _isAuthEndpoint(String path) =>
      path.contains('/auth/login') || path.contains('/auth/refresh');

  Future<bool> _refreshOnce() {
    return _refreshing ??=
        _performRefresh().whenComplete(() => _refreshing = null);
  }

  Future<bool> _performRefresh() async {
    final refreshToken = await _storage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;
    try {
      final res = await _refreshDio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final data = res.data!;
      await _storage.saveAccessToken(data['accessToken'] as String);
      final newRefresh = data['refreshToken'] as String?;
      if (newRefresh != null && newRefresh.isNotEmpty) {
        await _storage.saveRefreshToken(newRefresh);
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
