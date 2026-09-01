import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hcp_survey_app/features/questionnaire/data/survey_definition_parser.dart';
import 'package:hcp_survey_app/features/questionnaire/domain/entities/question_type.dart';

/// The admin tool now builds surveys with an LLM. Its output is a different
/// shape of "correct" from the hand-written sample: every label is bilingual,
/// every question carries `help`, and the option values are generated slugs.
///
/// This fixture is real captured output (Word document -> Gemini -> publish),
/// so a prompt or schema change that produces something the app cannot render
/// fails here instead of on an agent's phone in the field.
void main() {
  group('LLM-generated survey', () {
    late Map<String, dynamic> json;

    setUpAll(() async {
      final raw =
          await File('test/fixtures/llm_generated_survey.json').readAsString();
      json = jsonDecode(raw) as Map<String, dynamic>;
    });

    test('parses without error', () {
      final survey = SurveyDefinitionParser.parse(json);
      expect(survey.id, 'survey_emploi_jeunes_2026');
      expect(survey.pages, isNotEmpty);
      expect(survey.pages.first.questions.length, 14);
    });

    test('every question uses a type the app actually renders', () {
      const rendered = {
        QuestionType.text,
        QuestionType.number,
        QuestionType.radio,
        QuestionType.checkbox,
        QuestionType.dropdown,
        QuestionType.date,
      };
      final survey = SurveyDefinitionParser.parse(json);
      for (final q in survey.pages.first.questions) {
        expect(
          rendered.contains(q.type),
          isTrue,
          reason: '${q.id} has non-rendered type ${q.type}',
        );
      }
    });

    test('choice questions carry at least two options', () {
      const choice = {
        QuestionType.radio,
        QuestionType.checkbox,
        QuestionType.dropdown,
      };
      final survey = SurveyDefinitionParser.parse(json);
      final withChoices =
          survey.pages.first.questions.where((q) => choice.contains(q.type));
      expect(withChoices, isNotEmpty);
      for (final q in withChoices) {
        expect(q.options.length, greaterThanOrEqualTo(2), reason: q.id);
      }
    });

    test('labels and help are bilingual (fr + ar)', () {
      final survey = SurveyDefinitionParser.parse(json);
      expect(survey.title['ar'], isNotEmpty);
      for (final q in survey.pages.first.questions) {
        expect(q.label['fr'], isNotEmpty, reason: '${q.id} fr label');
        expect(q.label['ar'], isNotEmpty, reason: '${q.id} ar label');
        expect(q.help['ar'], isNotEmpty, reason: '${q.id} ar help');
      }
    });

    test('option values are unique within a question', () {
      final survey = SurveyDefinitionParser.parse(json);
      for (final q in survey.pages.first.questions) {
        final values = q.options.map((o) => o.value).toList();
        expect(values.toSet().length, values.length, reason: '${q.id} has duplicate values');
      }
    });
  });
}
