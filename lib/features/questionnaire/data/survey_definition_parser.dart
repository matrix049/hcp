import '../domain/entities/question_type.dart';
import '../domain/entities/survey_definition.dart';
import '../domain/entities/survey_question.dart';

/// Converts a raw survey JSON map into typed domain models.
///
/// Pure and side-effect free → fully unit-testable without a device.
/// Tolerant of missing optional fields and of labels given either as a
/// localized map (`{"fr": "...", "en": "..."}`) or a plain string.
class SurveyDefinitionParser {
  const SurveyDefinitionParser._();

  static SurveyDefinition parse(Map<String, dynamic> json) {
    final pages = (json['pages'] as List? ?? [])
        .map((p) => _parsePage(p as Map<String, dynamic>))
        .toList();

    return SurveyDefinition(
      id: json['id'] as String,
      version: (json['version'] as num?)?.toInt() ?? 1,
      title: _labels(json['title']),
      locales:
          (json['locales'] as List? ?? []).map((e) => e.toString()).toList(),
      pages: pages,
    );
  }

  static SurveyPage _parsePage(Map<String, dynamic> json) {
    return SurveyPage(
      id: json['id'] as String,
      title: _labels(json['title']),
      questions: (json['questions'] as List? ?? [])
          .map((q) => _parseQuestion(q as Map<String, dynamic>))
          .toList(),
    );
  }

  static SurveyQuestion _parseQuestion(Map<String, dynamic> json) {
    return SurveyQuestion(
      id: json['id'] as String,
      type: QuestionType.parse(json['type'] as String? ?? 'unknown'),
      label: _labels(json['label']),
      required: json['required'] as bool? ?? false,
      multiline: json['multiline'] as bool? ?? false,
      help: _labels(json['help']),
      options: (json['options'] as List? ?? [])
          .map((o) => _parseOption(o as Map<String, dynamic>))
          .toList(),
      validation: _parseValidation(json['validation']),
      visibleWhen: _parseVisibleWhen(json['visible_when']),
    );
  }

  static QuestionOption _parseOption(Map<String, dynamic> json) => QuestionOption(
        value: json['value'].toString(),
        label: _labels(json['label']),
      );

  static QuestionValidation? _parseValidation(dynamic raw) {
    if (raw is! Map) return null;
    return QuestionValidation(
      min: raw['min'] as num?,
      max: raw['max'] as num?,
    );
  }

  static VisibleWhen? _parseVisibleWhen(dynamic raw) {
    if (raw is! Map) return null;
    return VisibleWhen(
      questionId: raw['question'] as String,
      equals: raw['equals'],
    );
  }

  /// Normalises a label into a `Map<String, String>`. A plain string is stored
  /// under the '*' key and returned by [localizedText] as a fallback.
  static Map<String, String> _labels(dynamic raw) {
    if (raw is String) return {'*': raw};
    if (raw is Map) {
      return raw.map((k, v) => MapEntry(k.toString(), v.toString()));
    }
    return const {};
  }
}
