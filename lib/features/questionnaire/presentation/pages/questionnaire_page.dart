import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/settings/locale_controller.dart';
import '../../../../core/sync/sync_status.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import '../../../sync/presentation/providers/sync_providers.dart';
import '../../domain/entities/survey_definition.dart';
import '../../domain/entities/survey_question.dart';
import '../../domain/entities/survey_response.dart';
import '../form_engine/localized_text.dart';
import '../form_engine/question_widget_factory.dart';
import '../providers/questionnaire_providers.dart';
import '../providers/response_providers.dart';

/// Renders a downloaded survey dynamically and persists answers to Drift.
/// - `responseId == null` → new response (a fresh draft).
/// - `responseId != null` → resume/edit an existing response.
class QuestionnairePage extends ConsumerWidget {
  const QuestionnairePage({
    super.key,
    required this.surveyRemoteId,
    this.responseId,
  });

  final String surveyRemoteId;
  final String? responseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final definition = ref.watch(surveyDefinitionProvider(surveyRemoteId));

    return Scaffold(
      appBar: AppBar(
        title: Text(responseId == null ? 'Nouvelle réponse' : 'Modifier la réponse'),
      ),
      body: definition.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text(err is Failure ? err.message : 'Impossible de charger l’enquête'),
        ),
        data: (survey) => _QuestionnaireForm(
          survey: survey,
          surveyRemoteId: surveyRemoteId,
          responseId: responseId,
        ),
      ),
    );
  }
}

class _QuestionnaireForm extends ConsumerStatefulWidget {
  const _QuestionnaireForm({
    required this.survey,
    required this.surveyRemoteId,
    required this.responseId,
  });

  final SurveyDefinition survey;
  final String surveyRemoteId;
  final String? responseId;

  @override
  ConsumerState<_QuestionnaireForm> createState() => _QuestionnaireFormState();
}

class _QuestionnaireFormState extends ConsumerState<_QuestionnaireForm> {
  final Map<String, Object?> _answers = {};
  final Map<String, String?> _errors = {};

  late final String _responseId;
  late final String _agentId;
  bool _loading = true;
  bool _readOnly = false;

  @override
  void initState() {
    super.initState();
    _responseId = widget.responseId ?? const Uuid().v4();

    final auth = ref.read(authControllerProvider);
    _agentId = auth is AuthAuthenticated ? auth.agent.id : 'unknown';

    _loadExisting();
  }

  Future<void> _loadExisting() async {
    if (widget.responseId != null) {
      final existing = await ref
          .read(responseRepositoryProvider)
          .getResponse(widget.responseId!);
      if (existing != null) {
        _answers.addAll(existing.answers);
        // Lock-after-sync: a response already accepted by the server opens
        // read-only until the agent explicitly chooses to make a correction.
        _readOnly = existing.status == SyncStatus.synced;
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  // --- Visibility & validation helpers ---

  bool _isVisible(SurveyQuestion q) {
    final rule = q.visibleWhen;
    if (rule == null) return true;
    final other = _answers[rule.questionId];
    if (other is List) return other.contains(rule.equals);
    return other == rule.equals;
  }

  bool _isEmpty(Object? value) {
    if (value == null) return true;
    if (value is String) return value.trim().isEmpty;
    if (value is List) return value.isEmpty;
    return false;
  }

  // --- Persistence (auto-save as draft) ---

  SurveyResponse _currentResponse(SyncStatus status) => SurveyResponse(
        id: _responseId,
        surveyRemoteId: widget.surveyRemoteId,
        agentId: _agentId,
        answers: Map.of(_answers),
        status: status,
        updatedAt: DateTime.now(),
      );

  Future<void> _saveDraft() =>
      ref.read(responseRepositoryProvider).saveDraft(_currentResponse(SyncStatus.draft));

  void _setAnswer(String id, Object? value) {
    setState(() {
      _answers[id] = value;
      _errors.remove(id);
    });
    // Fire-and-forget auto-save so nothing is lost offline.
    _saveDraft();
  }

  Future<void> _finalize() async {
    final errors = <String, String?>{};
    for (final page in widget.survey.pages) {
      for (final q in page.questions) {
        if (!_isVisible(q)) continue;
        final value = _answers[q.id];
        if (q.required && _isEmpty(value)) {
          errors[q.id] = 'Cette question est obligatoire';
          continue;
        }
        if (value is num && q.validation != null) {
          final v = q.validation!;
          if (v.min != null && value < v.min!) {
            errors[q.id] = 'Minimum : ${v.min}';
          } else if (v.max != null && value > v.max!) {
            errors[q.id] = 'Maximum : ${v.max}';
          }
        }
      }
    }

    setState(() => _errors
      ..clear()
      ..addAll(errors));
    if (errors.isNotEmpty) return;

    await _saveDraft();
    await ref.read(responseRepositoryProvider).finalizeResponse(_responseId);
    // Try to upload immediately if online (also runs on reconnect / app start).
    unawaited(ref.read(syncControllerProvider.notifier).syncNow());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Réponse enregistrée et mise en file d’envoi')),
    );
    Navigator.of(context).pop();
  }

  Future<void> _onSaveDraftPressed() async {
    await _saveDraft();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Brouillon enregistré')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final locale = ref.watch(localeControllerProvider).code;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_readOnly) ...[
          _buildLockedBanner(),
          const SizedBox(height: 16),
        ],
        Text(
          localizedText(widget.survey.title, locale: locale),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        // A synced response is shown read-only; wrapping the questions in an
        // AbsorbPointer disables all input without touching the per-question
        // widgets. "Make a correction" flips _readOnly and re-enables editing.
        AbsorbPointer(
          absorbing: _readOnly,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final page in widget.survey.pages) ..._buildPage(page, locale),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ..._buildActions(),
      ],
    );
  }

  /// Bottom actions depend on whether the response is locked (synced).
  List<Widget> _buildActions() {
    if (_readOnly) {
      return [
        FilledButton.tonalIcon(
          onPressed: () => setState(() => _readOnly = false),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Corriger'),
        ),
      ];
    }
    return [
      OutlinedButton.icon(
        onPressed: _onSaveDraftPressed,
        icon: const Icon(Icons.save_outlined),
        label: const Text('Enregistrer le brouillon'),
      ),
      const SizedBox(height: 8),
      FilledButton(
        onPressed: _finalize,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text('Valider et mettre en file d’envoi'),
        ),
      ),
    ];
  }

  Widget _buildLockedBanner() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.lock_outline),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Cette réponse a déjà été envoyée au serveur, elle est donc '
                'en lecture seule. Appuyez sur « Corriger » pour la modifier et la renvoyer.',
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPage(SurveyPage page, String locale) {
    return [
      Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: Text(
          localizedText(page.title, locale: locale),
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      const Divider(),
      for (final q in page.questions)
        if (_isVisible(q))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: QuestionWidgetFactory.build(
              question: q,
              value: _answers[q.id],
              onChanged: (v) => _setAnswer(q.id, v),
              errorText: _errors[q.id],
              locale: locale,
            ),
          ),
    ];
  }
}
