import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/error/failures.dart';
import '../../data/survey_definition_parser.dart';
import '../../domain/entities/survey_definition.dart';

/// Loads a downloaded survey's definition from Drift and parses it.
/// Keyed by the survey's remoteId. Offline-capable (reads local cache).
final surveyDefinitionProvider =
    FutureProvider.family<SurveyDefinition, String>((ref, remoteId) async {
  final dao = ref.watch(appDatabaseProvider).surveysDao;
  final row = await dao.getSurvey(remoteId);
  if (row == null) {
    throw const CacheFailure('Cette enquête n’est pas téléchargée sur cet appareil');
  }
  final json = jsonDecode(row.definitionJson) as Map<String, dynamic>;
  return SurveyDefinitionParser.parse(json);
});
