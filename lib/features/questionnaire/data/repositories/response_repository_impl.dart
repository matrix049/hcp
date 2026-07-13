import 'dart:convert';

import 'package:drift/drift.dart' show Value;

import '../../../../core/database/app_database.dart' show SurveyResponsesCompanion;
import '../../../../core/database/daos/responses_dao.dart';
import '../../../../core/sync/sync_status.dart';
import '../../domain/entities/survey_response.dart';
import '../../domain/repositories/response_repository.dart';

class ResponseRepositoryImpl implements ResponseRepository {
  const ResponseRepositoryImpl(this._dao);

  final ResponsesDao _dao;

  @override
  Future<SurveyResponse?> getResponse(String id) async {
    final row = await _dao.getById(id);
    return row == null ? null : _toEntity(row);
  }

  @override
  Future<void> saveDraft(SurveyResponse response) {
    return _dao.upsertResponse(
      SurveyResponsesCompanion(
        id: Value(response.id),
        surveyRemoteId: Value(response.surveyRemoteId),
        agentId: Value(response.agentId),
        answersJson: Value(jsonEncode(response.answers)),
        syncStatus: const Value(SyncStatus.draft),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> finalizeResponse(String id) =>
      _dao.updateSyncStatus(id, SyncStatus.pending);

  @override
  Stream<List<SurveyResponse>> watchResponsesForSurvey(String surveyRemoteId) {
    return _dao
        .watchResponsesFor(surveyRemoteId)
        .map((rows) => rows.map(_toEntity).toList());
  }

  @override
  Stream<List<SurveyResponse>> watchAllResponses() {
    return _dao.watchAllResponses().map((rows) => rows.map(_toEntity).toList());
  }

  // `row` is Drift's generated data class (also named SurveyResponse), so it is
  // intentionally left untyped here to avoid a name clash with our entity.
  SurveyResponse _toEntity(dynamic row) => SurveyResponse(
        id: row.id as String,
        surveyRemoteId: row.surveyRemoteId as String,
        agentId: row.agentId as String,
        answers: jsonDecode(row.answersJson as String) as Map<String, dynamic>,
        status: row.syncStatus as SyncStatus,
        updatedAt: row.updatedAt as DateTime,
      );
}
