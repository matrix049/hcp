import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../data/datasources/survey_remote_datasource.dart';
import '../../data/repositories/survey_repository_impl.dart';
import '../../domain/entities/survey.dart';
import '../../domain/repositories/survey_repository.dart';

/// The Drift DAO for surveys, taken from the shared database.
final _surveysDaoProvider = Provider(
  (ref) => ref.watch(appDatabaseProvider).surveysDao,
);

final _surveyRemoteDataSourceProvider = Provider(
  (ref) => SurveyRemoteDataSource(ref.watch(dioProvider)),
);

final surveyRepositoryProvider = Provider<SurveyRepository>(
  (ref) => SurveyRepositoryImpl(
    remote: ref.watch(_surveyRemoteDataSourceProvider),
    dao: ref.watch(_surveysDaoProvider),
    connectivity: ref.watch(connectivityServiceProvider),
  ),
);

/// Locally downloaded surveys (reactive, offline-capable).
final downloadedSurveysProvider = StreamProvider<List<Survey>>(
  (ref) => ref.watch(surveyRepositoryProvider).watchDownloadedSurveys(),
);

/// Surveys available on the server. Errors (e.g. offline) surface as
/// `AsyncError` so the UI can fall back to the downloaded list.
final availableSurveysProvider = FutureProvider<List<Survey>>((ref) async {
  final result = await ref.watch(surveyRepositoryProvider).getAvailableSurveys();
  return result.fold((failure) => throw failure, (surveys) => surveys);
});
