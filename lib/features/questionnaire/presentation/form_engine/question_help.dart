import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/survey_question.dart';
import 'localized_text.dart';

/// EXTENSION POINT for a future online AI explanation.
///
/// The offline help (the `help` field in the survey JSON) is the default and
/// always available. When Phase 2 arrives, provide an implementation of this
/// interface and override [aiQuestionExplainerProvider] — the help sheet will
/// automatically show an "Explain with AI" button with NO other UI changes.
///
/// No implementation exists yet (the provider returns null), so `lib/ai/`
/// remains an empty placeholder.
abstract interface class AiQuestionExplainer {
  Future<String> explain(SurveyQuestion question, {required String locale});
}

/// Null until an AI provider is registered in a later phase.
final aiQuestionExplainerProvider = Provider<AiQuestionExplainer?>((ref) => null);

/// Opens the offline help for a question (bottom sheet).
void showQuestionHelp(
  BuildContext context,
  SurveyQuestion question,
  String locale,
) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _QuestionHelpSheet(question: question, locale: locale),
  );
}

class _QuestionHelpSheet extends ConsumerStatefulWidget {
  const _QuestionHelpSheet({required this.question, required this.locale});

  final SurveyQuestion question;
  final String locale;

  @override
  ConsumerState<_QuestionHelpSheet> createState() => _QuestionHelpSheetState();
}

class _QuestionHelpSheetState extends ConsumerState<_QuestionHelpSheet> {
  String? _aiText;
  bool _aiLoading = false;

  Future<void> _askAi(AiQuestionExplainer explainer) async {
    setState(() => _aiLoading = true);
    try {
      final text =
          await explainer.explain(widget.question, locale: widget.locale);
      if (mounted) setState(() => _aiText = text);
    } catch (_) {
      if (mounted) {
        setState(() => _aiText = 'AI explanation is unavailable right now.');
      }
    } finally {
      if (mounted) setState(() => _aiLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final offlineHelp = localizedText(widget.question.help, locale: widget.locale);
    // Null today → the AI button never renders (offline help is the default).
    final aiExplainer = ref.watch(aiQuestionExplainerProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.help_outline),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    localizedText(widget.question.label, locale: widget.locale),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(offlineHelp, style: theme.textTheme.bodyMedium),
            if (aiExplainer != null) ...[
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: _aiLoading ? null : () => _askAi(aiExplainer),
                icon: _aiLoading
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome),
                label: const Text('Explain with AI (online)'),
              ),
              if (_aiText != null) ...[
                const SizedBox(height: 12),
                Text(_aiText!, style: theme.textTheme.bodyMedium),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
