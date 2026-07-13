import '../../../../core/sync/sync_status.dart';

/// One filled-in questionnaire (one respondent/household visit).
///
/// Answers are a generic `{ questionId: value }` map — the same shape for every
/// survey. The respondent's data lives inside [answers], NOT in the agent User.
class SurveyResponse {
  const SurveyResponse({
    required this.id,
    required this.surveyRemoteId,
    required this.agentId,
    required this.answers,
    required this.status,
    required this.updatedAt,
  });

  final String id;
  final String surveyRemoteId;
  final String agentId;
  final Map<String, dynamic> answers;
  final SyncStatus status;
  final DateTime updatedAt;

  /// Short id for display (e.g. in the responses list).
  String get shortId => id.length >= 8 ? id.substring(0, 8) : id;
}
