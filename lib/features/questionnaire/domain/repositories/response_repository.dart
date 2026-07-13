import '../entities/survey_response.dart';

/// Persistence for survey responses (local Drift database).
///
/// These are local-only operations (the single source of truth); the sync
/// engine (Step 8) later pushes finalized responses to the server. Kept as
/// plain Futures/Streams — no Either wrapping — since local writes rarely fail
/// and we want to stay simple.
abstract interface class ResponseRepository {
  /// Loads a single response by id, or null if it doesn't exist.
  Future<SurveyResponse?> getResponse(String id);

  /// Inserts or updates a response as a `draft` (auto-save).
  Future<void> saveDraft(SurveyResponse response);

  /// Marks a response `pending` — finished and ready for the sync engine.
  Future<void> finalizeResponse(String id);

  /// Reactive list of responses for a given survey (newest first).
  Stream<List<SurveyResponse>> watchResponsesForSurvey(String surveyRemoteId);

  /// Reactive list of ALL responses across every survey (for history).
  Stream<List<SurveyResponse>> watchAllResponses();
}
