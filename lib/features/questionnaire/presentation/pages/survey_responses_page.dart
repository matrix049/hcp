import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';

import '../../../../core/utils/date_format.dart';
import '../../../sync/presentation/widgets/sync_status_chip.dart';
import '../../domain/entities/survey_response.dart';
import '../providers/response_providers.dart';
import 'questionnaire_page.dart';

/// Lists the responses collected for one survey, and lets the agent start a new
/// one or resume/edit an existing draft.
class SurveyResponsesPage extends ConsumerWidget {
  const SurveyResponsesPage({
    super.key,
    required this.surveyRemoteId,
    required this.surveyTitle,
  });

  final String surveyRemoteId;
  final String surveyTitle;

  void _openResponse(BuildContext context, {String? responseId}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuestionnairePage(
          surveyRemoteId: surveyRemoteId,
          responseId: responseId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final responses = ref.watch(responsesForSurveyProvider(surveyRemoteId));

    return Scaffold(
      appBar: AppBar(title: Text(surveyTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openResponse(context),
        icon: const Icon(Icons.add),
        label: Text(AppLocalizations.of(context).questionnaireNew),
      ),
      body: responses.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(AppLocalizations.of(context).responsesLoadFailed)),
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Text('Aucune réponse pour le moment.\nAppuyez sur « Nouvelle réponse » pour commencer.',
                  textAlign: TextAlign.center),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _ResponseTile(
              response: list[i],
              onTap: () => _openResponse(context, responseId: list[i].id),
            ),
          );
        },
      ),
    );
  }
}

class _ResponseTile extends StatelessWidget {
  const _ResponseTile({required this.response, required this.onTap});

  final SurveyResponse response;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.description_outlined),
        title: Text(AppLocalizations.of(context).responseNumber(response.shortId)),
        subtitle: Text(AppLocalizations.of(context).responseUpdatedAt(formatShortDateTime(response.updatedAt))),
        trailing: SyncStatusChip(status: response.status),
        onTap: onTap,
      ),
    );
  }
}
