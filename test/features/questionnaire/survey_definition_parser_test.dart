import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hcp_survey_app/features/questionnaire/data/survey_definition_parser.dart';
import 'package:hcp_survey_app/features/questionnaire/domain/entities/question_type.dart';

void main() {
  group('SurveyDefinitionParser', () {
    late Map<String, dynamic> json;

    setUpAll(() async {
      final raw = await File(
        'assets/surveys/sample_household_survey.json',
      ).readAsString();
      json = jsonDecode(raw) as Map<String, dynamic>;
    });

    test('parses top-level metadata', () {
      final survey = SurveyDefinitionParser.parse(json);
      expect(survey.id, 'survey_household_2026');
      expect(survey.version, 2);
      expect(survey.pages.length, 2);
      expect(survey.title['fr'], 'Enquête sur les ménages');
    });

    test('maps question types (incl. synonyms tolerance)', () {
      final survey = SurveyDefinitionParser.parse(json);
      final byId = {
        for (final p in survey.pages)
          for (final q in p.questions) q.id: q,
      };
      expect(byId['q_region']!.type, QuestionType.dropdown);
      expect(byId['q_household_size']!.type, QuestionType.number);
      expect(byId['q_visit_date']!.type, QuestionType.date);
      expect(byId['q_has_income']!.type, QuestionType.radio);
      expect(byId['q_income_sources']!.type, QuestionType.checkbox);
      expect(byId['q_comments']!.type, QuestionType.text);
      expect(byId['q_gps']!.type, QuestionType.gps); // reserved type
    });

    test('parses options, validation and conditional visibility', () {
      final survey = SurveyDefinitionParser.parse(json);
      final byId = {
        for (final p in survey.pages)
          for (final q in p.questions) q.id: q,
      };

      expect(byId['q_region']!.options.length, 3);
      expect(byId['q_household_size']!.validation!.min, 1);
      expect(byId['q_household_size']!.validation!.max, 30);

      final income = byId['q_monthly_income']!;
      expect(income.visibleWhen, isNotNull);
      expect(income.visibleWhen!.questionId, 'q_has_income');
      expect(income.visibleWhen!.equals, 'yes');

      expect(byId['q_comments']!.multiline, isTrue);
    });

    test('parses optional localized help (fr + ar) and defaults to empty', () {
      final survey = SurveyDefinitionParser.parse(json);
      final byId = {
        for (final p in survey.pages)
          for (final q in p.questions) q.id: q,
      };
      // q_household_size has help in the sample survey.
      expect(byId['q_household_size']!.hasHelp, isTrue);
      expect(byId['q_household_size']!.help['fr'], isNotEmpty);
      expect(byId['q_household_size']!.help['ar'], isNotEmpty);
      // q_visit_date has no help.
      expect(byId['q_visit_date']!.hasHelp, isFalse);
    });

    test('accepts legacy synonym type names', () {
      final survey = SurveyDefinitionParser.parse({
        'id': 's1',
        'version': 1,
        'pages': [
          {
            'id': 'p1',
            'questions': [
              {'id': 'a', 'type': 'single_choice', 'label': 'A'},
              {'id': 'b', 'type': 'multi_choice', 'label': 'B'},
            ],
          },
        ],
      });
      final types = {
        for (final q in survey.pages.first.questions) q.id: q.type,
      };
      expect(types['a'], QuestionType.radio);
      expect(types['b'], QuestionType.checkbox);
    });
  });
}
