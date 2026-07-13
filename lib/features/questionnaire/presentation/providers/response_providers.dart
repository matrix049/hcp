import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../data/repositories/response_repository_impl.dart';
import '../../domain/entities/survey_response.dart';
import '../../domain/repositories/response_repository.dart';

final _responsesDaoProvider = Provider(
  (ref) => ref.watch(appDatabaseProvider).responsesDao,
);

final responseRepositoryProvider = Provider<ResponseRepository>(
  (ref) => ResponseRepositoryImpl(ref.watch(_responsesDaoProvider)),
);

/// Reactive list of responses for a survey — drives the responses list UI.
final responsesForSurveyProvider =
    StreamProvider.family<List<SurveyResponse>, String>(
  (ref, surveyRemoteId) =>
      ref.watch(responseRepositoryProvider).watchResponsesForSurvey(surveyRemoteId),
);

/// Reactive list of every response across all surveys — drives the history UI.
final allResponsesProvider = StreamProvider<List<SurveyResponse>>(
  (ref) => ref.watch(responseRepositoryProvider).watchAllResponses(),
);
