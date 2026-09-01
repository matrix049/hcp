import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hcp_survey_app/core/database/app_database.dart' hide SurveyResponse;
import 'package:hcp_survey_app/core/sync/sync_status.dart';
import 'package:hcp_survey_app/features/questionnaire/data/repositories/response_repository_impl.dart';
import 'package:hcp_survey_app/features/questionnaire/domain/entities/survey_response.dart';

void main() {
  late AppDatabase db;
  late ResponseRepositoryImpl repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = ResponseRepositoryImpl(db.responsesDao);
  });

  tearDown(() => db.close());

  SurveyResponse draft(String id, String surveyId, Map<String, dynamic> a) =>
      SurveyResponse(
        id: id,
        surveyRemoteId: surveyId,
        agentId: 'AG001',
        answers: a,
        status: SyncStatus.draft,
        updatedAt: DateTime(2026, 1, 1),
      );

  test('saveDraft then getResponse round-trips answers as a draft', () async {
    await repo.saveDraft(draft('r1', 's1', {'q1': 'value', 'q2': 3}));

    final loaded = await repo.getResponse('r1');
    expect(loaded, isNotNull);
    expect(loaded!.answers['q1'], 'value');
    expect(loaded.answers['q2'], 3);
    expect(loaded.status, SyncStatus.draft);
  });

  test('saveDraft is an upsert (editing keeps one row)', () async {
    await repo.saveDraft(draft('r1', 's1', {'q1': 'first'}));
    await repo.saveDraft(draft('r1', 's1', {'q1': 'edited'}));

    final list = await repo.watchResponsesForSurvey('s1').first;
    expect(list.length, 1);
    expect(list.single.answers['q1'], 'edited');
  });

  test('finalizeResponse flips draft -> pending', () async {
    await repo.saveDraft(draft('r2', 's1', {}));
    await repo.finalizeResponse('r2');

    final loaded = await repo.getResponse('r2');
    expect(loaded!.status, SyncStatus.pending);
  });

  // Regression: auto-save used to force `draft` on every write, so an agent who
  // finalised a response offline and then reopened it silently pulled it back
  // out of the upload queue — it looked queued but was never sent again.
  test('editing a finalised response keeps it in the upload queue', () async {
    await repo.saveDraft(draft('r1', 's1', {'q1': 'a'}));
    await repo.finalizeResponse('r1');
    expect((await repo.getResponse('r1'))!.status, SyncStatus.pending);

    // The agent reopens it and changes an answer — this is what auto-save does.
    await repo.saveDraft(draft('r1', 's1', {'q1': 'corrected'}));

    final after = await repo.getResponse('r1');
    expect(after!.status, SyncStatus.pending, reason: 'must stay queued');
    expect(after.answers['q1'], 'corrected');
  });

  test('a brand-new response is still created as a draft', () async {
    await repo.saveDraft(draft('r2', 's1', {'q1': 'x'}));
    expect((await repo.getResponse('r2'))!.status, SyncStatus.draft);
  });

  // Regression: a response flipped to `syncing` just before an upload stayed
  // that way forever if the app was killed — invisible to getPendingResponses,
  // yet still counted as unsynced.
  test('requeueStuckSyncing rescues responses stranded mid-upload', () async {
    await repo.saveDraft(draft('r3', 's1', {'q1': 'x'}));
    await repo.finalizeResponse('r3');
    await db.responsesDao.updateSyncStatus('r3', SyncStatus.syncing);
    expect(await db.responsesDao.getPendingResponses(), isEmpty);

    await db.responsesDao.requeueStuckSyncing();

    final pending = await db.responsesDao.getPendingResponses();
    expect(pending.map((r) => r.id), ['r3']);
  });

  test('watchResponsesForSurvey only returns that survey', () async {
    await repo.saveDraft(draft('a', 'sX', {}));
    await repo.saveDraft(draft('b', 'sY', {}));

    final list = await repo.watchResponsesForSurvey('sX').first;
    expect(list.map((e) => e.id), ['a']);
  });
}
