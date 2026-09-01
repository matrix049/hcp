import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../history/presentation/pages/history_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../questionnaire/presentation/pages/survey_responses_page.dart';
import '../../../sync/presentation/widgets/sync_status_indicator.dart';
import '../../domain/entities/survey.dart';
import '../providers/survey_providers.dart';

/// The agent's home: the list of surveys, with download-to-offline support.
class SurveysPage extends ConsumerWidget {
  const SurveysPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final available = ref.watch(availableSurveysProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enquêtes'),
        actions: [
          const SyncStatusIndicator(),
          IconButton(
            tooltip: 'Historique',
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HistoryPage()),
            ),
          ),
          IconButton(
            tooltip: 'Profil',
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(availableSurveysProvider),
        child: available.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          data: (surveys) => _SurveyList(surveys: surveys),
          error: (err, _) => _OfflineFallback(
            message: err is Failure ? err.message : 'Could not reach the server',
          ),
        ),
      ),
    );
  }
}

class _SurveyList extends StatelessWidget {
  const _SurveyList({required this.surveys});

  final List<Survey> surveys;

  @override
  Widget build(BuildContext context) {
    if (surveys.isEmpty) {
      return const _CenteredMessage('No surveys available.');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: surveys.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _SurveyTile(survey: surveys[i]),
    );
  }
}

/// When the server is unreachable, show the downloaded surveys (offline).
class _OfflineFallback extends ConsumerWidget {
  const _OfflineFallback({required this.message});

  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloaded = ref.watch(downloadedSurveysProvider);
    return Column(
      children: [
        MaterialBanner(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          leading: const Icon(Icons.cloud_off),
          content: Text('Hors ligne — enquêtes téléchargées uniquement.\n$message'),
          actions: [
            TextButton(
              onPressed: () => ref.invalidate(availableSurveysProvider),
              child: const Text('Réessayer'),
            ),
          ],
        ),
        Expanded(
          child: downloaded.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            data: (surveys) => _SurveyList(surveys: surveys),
            error: (_, __) => const _CenteredMessage('No downloaded surveys.'),
          ),
        ),
      ],
    );
  }
}

class _SurveyTile extends ConsumerStatefulWidget {
  const _SurveyTile({required this.survey});

  final Survey survey;

  @override
  ConsumerState<_SurveyTile> createState() => _SurveyTileState();
}

class _SurveyTileState extends ConsumerState<_SurveyTile> {
  bool _downloading = false;

  Future<void> _download() async {
    setState(() => _downloading = true);
    final result = await ref
        .read(surveyRepositoryProvider)
        .downloadSurvey(widget.survey.remoteId);
    if (!mounted) return;
    setState(() => _downloading = false);

    result.fold(
      (f) => _snack(f.message),
      (_) {
        _snack('Téléchargée "${widget.survey.title}"');
        // Refresh the "downloaded" flags on the available list.
        ref.invalidate(availableSurveysProvider);
      },
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.survey;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.assignment_outlined),
        title: Text(s.title),
        subtitle: Text(
          s.isDownloaded ? 'Version ${s.version} · Tap to open' : 'Version ${s.version}',
        ),
        trailing: _buildTrailing(s),
        // Only downloaded surveys can be opened (offline-first).
        onTap: s.isDownloaded
            ? () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SurveyResponsesPage(
                      surveyRemoteId: s.remoteId,
                      surveyTitle: s.title,
                    ),
                  ),
                )
            : null,
      ),
    );
  }

  Widget _buildTrailing(Survey s) {
    if (_downloading) {
      return const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    if (s.isDownloaded) {
      return const Chip(
        avatar: Icon(Icons.check, size: 18),
        label: Text('Téléchargée'),
      );
    }
    return FilledButton.tonalIcon(
      onPressed: _download,
      icon: const Icon(Icons.download),
      label: const Text('Télécharger'),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    // Wrapped in a scroll view so RefreshIndicator still works when empty.
    return LayoutBuilder(
      builder: (_, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(child: Text(text)),
        ),
      ),
    );
  }
}
