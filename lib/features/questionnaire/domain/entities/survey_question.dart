import 'question_type.dart';

/// One selectable choice for radio / checkbox / dropdown questions.
class QuestionOption {
  const QuestionOption({required this.value, required this.label});

  final String value;
  final Map<String, String> label;
}

/// Numeric bounds for number/decimal questions.
class QuestionValidation {
  const QuestionValidation({this.min, this.max});

  final num? min;
  final num? max;
}

/// Conditional visibility: show the question only when another question's
/// answer equals [equals]. Powers `visible_when` in the JSON.
class VisibleWhen {
  const VisibleWhen({required this.questionId, required this.equals});

  final String questionId;
  final Object? equals;
}

/// A single question, fully described by data (no hardcoding).
class SurveyQuestion {
  const SurveyQuestion({
    required this.id,
    required this.type,
    required this.label,
    this.required = false,
    this.options = const [],
    this.validation,
    this.visibleWhen,
    this.multiline = false,
    this.help = const {},
  });

  final String id;
  final QuestionType type;
  final Map<String, String> label;
  final bool required;
  final List<QuestionOption> options;
  final QuestionValidation? validation;
  final VisibleWhen? visibleWhen;
  final bool multiline;

  /// Optional localized help text shown offline via the help icon.
  /// Empty when the survey JSON has no `help` for this question.
  final Map<String, String> help;

  bool get hasHelp => help.isNotEmpty;
}
