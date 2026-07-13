import '../../domain/entities/survey.dart';

/// Full survey payload returned by `GET /api/surveys/:id`, including the raw
/// definition JSON that gets cached in Drift.
class SurveyDetail {
  const SurveyDetail({
    required this.remoteId,
    required this.title,
    required this.version,
    required this.definition,
  });

  final String remoteId;
  final String title;
  final int version;
  final Map<String, dynamic> definition;
}

/// JSON mapping for surveys (kept out of the domain entity).
class SurveyModel {
  const SurveyModel._();

  /// From `GET /api/surveys` (list item — no definition).
  static Survey summaryFromJson(Map<String, dynamic> json) => Survey(
        remoteId: json['id'] as String,
        title: json['title'] as String,
        version: (json['version'] as num).toInt(),
      );

  /// From `GET /api/surveys/:id` (full definition).
  static SurveyDetail detailFromJson(Map<String, dynamic> json) => SurveyDetail(
        remoteId: json['id'] as String,
        title: json['title'] as String,
        version: (json['version'] as num).toInt(),
        definition: json['definition'] as Map<String, dynamic>,
      );
}
