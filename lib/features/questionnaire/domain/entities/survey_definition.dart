import 'survey_question.dart';

/// A page/section of a survey, grouping related questions.
class SurveyPage {
  const SurveyPage({
    required this.id,
    required this.title,
    required this.questions,
  });

  final String id;
  final Map<String, String> title;
  final List<SurveyQuestion> questions;
}

/// The parsed, typed representation of a survey's JSON definition.
class SurveyDefinition {
  const SurveyDefinition({
    required this.id,
    required this.version,
    required this.title,
    required this.locales,
    required this.pages,
  });

  final String id;
  final int version;
  final Map<String, String> title;
  final List<String> locales;
  final List<SurveyPage> pages;
}
