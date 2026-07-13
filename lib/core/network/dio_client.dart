import 'package:dio/dio.dart';

import '../config/app_constants.dart';
import '../storage/secure_storage_service.dart';
import 'auth_interceptor.dart';

/// Factory for the configured [Dio] instance used across the data layer.
///
/// Centralising Dio here means base URL, timeouts, and interceptors live in one
/// place. Repositories receive this single instance via Riverpod (see
/// `core/di/providers.dart`) rather than constructing their own.
class DioClient {
  const DioClient._();

  static Dio create({
    required SecureStorageService secureStorage,
    void Function()? onSessionExpired,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        contentType: Headers.jsonContentType,
        responseType: ResponseType.json,
      ),
    );

    dio.interceptors.add(
      AuthInterceptor(
        storage: secureStorage,
        dio: dio,
        onSessionExpired: onSessionExpired,
      ),
    );

    // Verbose logging in debug only. `assert` runs only in debug builds.
    assert(() {
      dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true),
      );
      return true;
    }());

    return dio;
  }
}
