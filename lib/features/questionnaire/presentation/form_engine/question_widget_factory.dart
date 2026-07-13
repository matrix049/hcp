import 'package:flutter/material.dart';

import '../../domain/entities/question_type.dart';
import '../../domain/entities/survey_question.dart';
import 'question_fields.dart';

/// Maps a [SurveyQuestion] to its input widget. **The one place** that decides
/// how each question type renders — adding a new type = one new `case`.
class QuestionWidgetFactory {
  const QuestionWidgetFactory._();

  static Widget build({
    required SurveyQuestion question,
    required Object? value,
    required ValueChanged<Object?> onChanged,
    String? errorText,
    String locale = 'fr',
  }) {
    switch (question.type) {
      case QuestionType.text:
      case QuestionType.textarea:
        return TextQuestionField(
          question: question,
          value: value,
          onChanged: onChanged,
          errorText: errorText,
          locale: locale,
        );

      case QuestionType.number:
      case QuestionType.decimal:
        return NumberQuestionField(
          question: question,
          value: value,
          onChanged: onChanged,
          errorText: errorText,
          locale: locale,
        );

      case QuestionType.radio:
        return RadioQuestionField(
          question: question,
          value: value,
          onChanged: onChanged,
          errorText: errorText,
          locale: locale,
        );

      case QuestionType.checkbox:
        return CheckboxQuestionField(
          question: question,
          value: value,
          onChanged: onChanged,
          errorText: errorText,
          locale: locale,
        );

      case QuestionType.dropdown:
        return DropdownQuestionField(
          question: question,
          value: value,
          onChanged: onChanged,
          errorText: errorText,
          locale: locale,
        );

      case QuestionType.date:
        return DateQuestionField(
          question: question,
          value: value,
          onChanged: onChanged,
          errorText: errorText,
          locale: locale,
        );

      // Reserved types render a graceful placeholder until implemented.
      default:
        return UnsupportedQuestionField(question: question, locale: locale);
    }
  }
}
