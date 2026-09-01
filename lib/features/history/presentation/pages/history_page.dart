import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/date_format.dart';
import '../../../questionnaire/presentation/pages/questionnaire_page.dart';
import '../../../questionnaire/presentation/providers/response_providers.dart';
import '../../../surveys/presentation/providers/survey_providers.dart';
import '../../../sync/presentation/widgets/sync_status_chip.dart';

/// All responses the agent collected, across every survey, newest first.
class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final responses = ref.watch(allResponsesProvider);
    // Resolve survey titles for display (falls back to the id).
    final surveys = ref.watch(downloadedSurveysProvider).valueOrNull ?? const [];
    final titleById = {for (final s in surveys) s.remoteId: s.title};

    return Scaffold(
      appBar: AppBar(title: const Text('Historique')),
      body: responses.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Impossible de charger l’historique')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('Aucune réponse collectée.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final r = list[i];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.assignment_turned_in_outlined),
                  title: Text(titleById[r.surveyRemoteId] ?? r.surveyRemoteId),
                  subtitle: Text(
                    '#${r.shortId} · ${formatShortDateTime(r.updatedAt)}',
                  ),
                  trailing: SyncStatusChip(status: r.status),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => QuestionnairePage(
                        surveyRemoteId: r.surveyRemoteId,
                        responseId: r.id,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
