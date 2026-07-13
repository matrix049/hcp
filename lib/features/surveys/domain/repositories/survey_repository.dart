import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/survey.dart';

abstract interface class SurveyRepository {
  /// Surveys available on the server, each flagged as downloaded or not.
  /// Online-only (the "what can I download" question needs the network).
  Future<Either<Failure, List<Survey>>> getAvailableSurveys();

  /// Downloads a survey's full definition and caches it in Drift.
  Future<Either<Failure, Unit>> downloadSurvey(String remoteId);

  /// Reactive stream of locally-downloaded surveys — works offline.
  Stream<List<Survey>> watchDownloadedSurveys();
}
