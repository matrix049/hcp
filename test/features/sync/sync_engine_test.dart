import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hcp_survey_app/core/database/app_database.dart';
import 'package:hcp_survey_app/core/connectivity/connectivity_service.dart';
import 'package:hcp_survey_app/core/error/exceptions.dart';
import 'package:hcp_survey_app/core/sync/sync_status.dart';
import 'package:hcp_survey_app/features/sync/data/datasources/response_sync_remote_datasource.dart';
import 'package:hcp_survey_app/features/sync/data/sync_engine.dart';

class _FakeRemote extends ResponseSyncRemoteDataSource {
  _FakeRemote({this.fail = false}) : super(Dio());
  final bool fail;
  int calls = 0;

  @override
  Future<String> upload({
    required String id,
    required String surveyId,
    required Map<String, dynamic> answers,
    required DateTime updatedAt,
  }) async {
    calls++;
    if (fail) throw ServerException('boom');
    return id;
  }
}

class _FakeConnectivity extends ConnectivityService {
  _FakeConnectivity(this.online);
  final bool online;
  @override
  Future<bool> get isConnected async => online;
}

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> seedPending(String id) => db.responsesDao.upsertResponse(
        SurveyResponsesCompanion(
          id: Value(id),
          surveyRemoteId: const Value('survey_household_2026'),
          agentId: const Value('AG001'),
          answersJson: const Value('{"q_region":"marrakech_safi"}'),
          syncStatus: const Value(SyncStatus.pending),
        ),
      );

  test('uploads pending responses and marks them synced', () async {
    await seedPending('r1');
    final remote = _FakeRemote();
    final engine = SyncEngine(db.responsesDao, remote, _FakeConnectivity(true));

    final result = await engine.syncPending();

    expect(result.synced, 1);
    expect(remote.calls, 1);
    final row = await db.responsesDao.getById('r1');
    expect(row!.syncStatus, SyncStatus.synced);
    expect(row.remoteId, 'r1');
  });

  test('failed upload reverts to pending and increments attempts', () async {
    await seedPending('r2');
    final engine =
        SyncEngine(db.responsesDao, _FakeRemote(fail: true), _FakeConnectivity(true));

    final result = await engine.syncPending();

    expect(result.failed, 1);
    final row = await db.responsesDao.getById('r2');
    expect(row!.syncStatus, SyncStatus.pending); // retryable
    expect(row.attempts, 1);
    expect(row.lastError, isNotNull);
  });

  test('offline does nothing', () async {
    await seedPending('r3');
    final remote = _FakeRemote();
    final engine = SyncEngine(db.responsesDao, remote, _FakeConnectivity(false));

    final result = await engine.syncPending();

    expect(result.synced, 0);
    expect(remote.calls, 0);
    final row = await db.responsesDao.getById('r3');
    expect(row!.syncStatus, SyncStatus.pending);
  });
}
