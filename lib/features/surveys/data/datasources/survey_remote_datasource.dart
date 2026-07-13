import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/survey.dart';
import '../models/survey_model.dart';

/// Calls the protected survey endpoints (JWT attached by the Dio interceptor).
class SurveyRemoteDataSource {
  const SurveyRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<Survey>> fetchSurveys() async {
    try {
      final res = await _dio.get<List<dynamic>>('/surveys');
      return (res.data ?? [])
          .map((e) => SurveyModel.summaryFromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException('Failed to load surveys', e.response?.statusCode);
    }
  }

  Future<SurveyDetail> fetchSurvey(String id) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/surveys/$id');
      return SurveyModel.detailFromJson(res.data!);
    } on DioException catch (e) {
      throw ServerException('Failed to download survey', e.response?.statusCode);
    }
  }
}
