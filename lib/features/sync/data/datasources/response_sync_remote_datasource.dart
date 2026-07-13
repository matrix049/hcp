import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';

/// Uploads a single response to `POST /api/responses` (JWT attached by the Dio
/// interceptor). The server upserts by the client id, so retries are safe.
class ResponseSyncRemoteDataSource {
  const ResponseSyncRemoteDataSource(this._dio);

  final Dio _dio;

  /// Returns the server id of the stored response.
  Future<String> upload({
    required String id,
    required String surveyId,
    required Map<String, dynamic> answers,
    required DateTime updatedAt,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/responses',
        data: {
          'id': id,
          'surveyId': surveyId,
          'answers': answers,
          'updatedAt': updatedAt.toIso8601String(),
        },
      );
      return res.data!['id'] as String;
    } on DioException catch (e) {
      throw ServerException('Upload failed', e.response?.statusCode);
    }
  }
}
