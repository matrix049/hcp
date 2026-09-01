import 'dart:convert';

import '../../../core/config/app_constants.dart';
import '../../../core/connectivity/connectivity_service.dart';
import '../../../core/database/daos/responses_dao.dart';
import '../../../core/sync/sync_status.dart';
import 'datasources/response_sync_remote_datasource.dart';

/// Outcome of a sync pass.
class SyncResult {
  const SyncResult({this.synced = 0, this.failed = 0});
  final int synced;
  final int failed;
}

/// Drains the local outbox: uploads every `pending` response when online.
///
/// Per response: `pending → syncing → synced` (stamping the server id), or on
/// failure: attempts++ and back to `pending`, until [AppConstants.maxSyncAttempts]
/// is reached → `failed`. A single in-flight guard prevents overlapping passes.
class SyncEngine {
  SyncEngine(this._dao, this._remote, this._connectivity);

  final ResponsesDao _dao;
  final ResponseSyncRemoteDataSource _remote;
  final ConnectivityService _connectivity;

  bool _running = false;

  Future<SyncResult> syncPending() async {
    if (_running) return const SyncResult();
    _running = true;
    var synced = 0;
    var failed = 0;
    try {
      if (!await _connectivity.isConnected) return const SyncResult();

      // Recover anything a previous run left mid-upload before reading the
      // queue, otherwise those responses are invisible to this pass too.
      await _dao.requeueStuckSyncing();

      final pending = await _dao.getPendingResponses();
      for (final row in pending) {
        await _dao.updateSyncStatus(row.id, SyncStatus.syncing);
        try {
          final answers = jsonDecode(row.answersJson) as Map<String, dynamic>;
          final serverId = await _remote.upload(
            id: row.id,
            surveyId: row.surveyRemoteId,
            answers: answers,
            updatedAt: row.updatedAt,
          );
          await _dao.updateSyncStatus(
            row.id,
            SyncStatus.synced,
            remoteId: serverId,
          );
          synced++;
        } catch (e) {
          final attempts = row.attempts + 1;
          final status = attempts >= AppConstants.maxSyncAttempts
              ? SyncStatus.failed
              : SyncStatus.pending;
          await _dao.updateSyncStatus(
            row.id,
            status,
            attempts: attempts,
            lastError: e.toString(),
          );
          failed++;
        }
      }
      return SyncResult(synced: synced, failed: failed);
    } finally {
      _running = false;
    }
  }
}
