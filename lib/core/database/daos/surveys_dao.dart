import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/surveys_table.dart';

part 'surveys_dao.g.dart';

/// Data-access object for cached survey definitions.
///
/// `watch*` methods return reactive streams: the UI rebuilds automatically when
/// a survey is downloaded or updated — no manual refresh needed.
@DriftAccessor(tables: [Surveys])
class SurveysDao extends DatabaseAccessor<AppDatabase> with _$SurveysDaoMixin {
  SurveysDao(super.db);

  Future<List<Survey>> getAllSurveys() => select(surveys).get();

  Stream<List<Survey>> watchAllSurveys() => select(surveys).watch();

  Future<Survey?> getSurvey(String remoteId) =>
      (select(surveys)..where((s) => s.remoteId.equals(remoteId)))
          .getSingleOrNull();

  /// Insert or update — used when (re)downloading a survey.
  Future<void> upsertSurvey(SurveysCompanion survey) =>
      into(surveys).insertOnConflictUpdate(survey);

  Future<void> deleteSurvey(String remoteId) =>
      (delete(surveys)..where((s) => s.remoteId.equals(remoteId))).go();
}
