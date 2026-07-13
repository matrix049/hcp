import 'package:drift/drift.dart';

import '../../sync/sync_status.dart';
import '../app_database.dart';
import '../tables/survey_responses_table.dart';

part 'responses_dao.g.dart';

/// Data-access object for survey responses and the sync outbox queries.
@DriftAccessor(tables: [SurveyResponses])
class ResponsesDao extends DatabaseAccessor<AppDatabase>
    with _$ResponsesDaoMixin {
  ResponsesDao(super.db);

  // --- Reads (reactive where the UI needs live updates) ---

  Stream<List<SurveyResponse>> watchResponsesFor(String surveyRemoteId) =>
      (select(surveyResponses)
            ..where((r) => r.surveyRemoteId.equals(surveyRemoteId))
            ..orderBy([(r) => OrderingTerm.desc(r.updatedAt)]))
          .watch();

  /// History view — every response newest first.
  Stream<List<SurveyResponse>> watchAllResponses() =>
      (select(surveyResponses)
            ..orderBy([(r) => OrderingTerm.desc(r.updatedAt)]))
          .watch();

  Future<SurveyResponse?> getById(String id) =>
      (select(surveyResponses)..where((r) => r.id.equals(id)))
          .getSingleOrNull();

  /// The sync queue: responses ready to upload, oldest first.
  Future<List<SurveyResponse>> getPendingResponses() =>
      (select(surveyResponses)
            ..where((r) => r.syncStatus.equalsValue(SyncStatus.pending))
            ..orderBy([(r) => OrderingTerm.asc(r.createdAt)]))
          .get();

  /// Live count of not-yet-synced work — drives the sync status badge.
  Stream<int> watchUnsyncedCount() {
    final count = surveyResponses.id.count();
    final query = selectOnly(surveyResponses)
      ..addColumns([count])
      ..where(
        surveyResponses.syncStatus.equalsValue(SyncStatus.synced).not(),
      );
    return query.map((row) => row.read(count) ?? 0).watchSingle();
  }

  // --- Writes ---

  Future<void> upsertResponse(SurveyResponsesCompanion response) =>
      into(surveyResponses).insertOnConflictUpdate(response);

  Future<void> updateSyncStatus(
    String id,
    SyncStatus status, {
    String? remoteId,
    String? lastError,
    int? attempts,
  }) {
    return (update(surveyResponses)..where((r) => r.id.equals(id))).write(
      SurveyResponsesCompanion(
        syncStatus: Value(status),
        remoteId: remoteId == null ? const Value.absent() : Value(remoteId),
        lastError: Value(lastError),
        attempts: attempts == null ? const Value.absent() : Value(attempts),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteResponse(String id) =>
      (delete(surveyResponses)..where((r) => r.id.equals(id))).go();
}
