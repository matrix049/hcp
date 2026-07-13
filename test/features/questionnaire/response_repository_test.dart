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

  test('watchResponsesForSurvey only returns that survey', () async {
    await repo.saveDraft(draft('a', 'sX', {}));
    await repo.saveDraft(draft('b', 'sY', {}));

    final list = await repo.watchResponsesForSurvey('sX').first;
    expect(list.map((e) => e.id), ['a']);
  });
}
