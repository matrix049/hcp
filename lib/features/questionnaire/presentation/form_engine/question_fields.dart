import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../l10n/app_localizations.dart';

import '../../domain/entities/survey_question.dart';
import 'localized_text.dart';
import 'question_help.dart';

/// Shared label + error scaffold around each field.
class _FieldShell extends StatelessWidget {
  const _FieldShell({
    required this.question,
    required this.child,
    this.errorText,
    required this.locale,
  });

  final SurveyQuestion question;
  final Widget child;
  final String? errorText;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: localizedText(question.label, locale: locale),
                  children: question.required
                      ? [
                          TextSpan(
                            text: ' *',
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        ]
                      : null,
                ),
                style: theme.textTheme.titleSmall,
              ),
            ),
            // Offline help — shown only when the question defines `help`.
            if (question.hasHelp)
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: AppLocalizations.of(context).helpTitle,
                icon: const Icon(Icons.help_outline),
                onPressed: () => showQuestionHelp(context, question, locale),
              ),
          ],
        ),
        const SizedBox(height: 6),
        child,
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              errorText!,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.error),
            ),
          ),
      ],
    );
  }
}

/// text / textarea (multiline).
class TextQuestionField extends StatefulWidget {
  const TextQuestionField({
    super.key,
    required this.question,
    required this.value,
    required this.onChanged,
    required this.locale,
    this.errorText,
  });

  final SurveyQuestion question;
  final Object? value;
  final ValueChanged<Object?> onChanged;
  final String locale;
  final String? errorText;

  @override
  State<TextQuestionField> createState() => _TextQuestionFieldState();
}

class _TextQuestionFieldState extends State<TextQuestionField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.value as String? ?? '');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _FieldShell(
      question: widget.question,
      errorText: widget.errorText,
      locale: widget.locale,
      child: TextField(
        controller: _controller,
        maxLines: widget.question.multiline ? 4 : 1,
        decoration: const InputDecoration(border: OutlineInputBorder()),
        onChanged: widget.onChanged,
      ),
    );
  }
}

/// number / decimal — stores a parsed [num] (or null while empty/invalid).
class NumberQuestionField extends StatefulWidget {
  const NumberQuestionField({
    super.key,
    required this.question,
    required this.value,
    required this.onChanged,
    required this.locale,
    this.errorText,
  });

  final SurveyQuestion question;
  final Object? value;
  final ValueChanged<Object?> onChanged;
  final String locale;
  final String? errorText;

  @override
  State<NumberQuestionField> createState() => _NumberQuestionFieldState();
}

class _NumberQuestionFieldState extends State<NumberQuestionField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.value?.toString() ?? '');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _FieldShell(
      question: widget.question,
      errorText: widget.errorText,
      locale: widget.locale,
      child: TextField(
        controller: _controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]')),
        ],
        decoration: const InputDecoration(border: OutlineInputBorder()),
        onChanged: (raw) => widget.onChanged(num.tryParse(raw)),
      ),
    );
  }
}

/// radio — single choice, stores the option value (String).
class RadioQuestionField extends StatelessWidget {
  const RadioQuestionField({
    super.key,
    required this.question,
    required this.value,
    required this.onChanged,
    required this.locale,
    this.errorText,
  });

  final SurveyQuestion question;
  final Object? value;
  final ValueChanged<Object?> onChanged;
  final String locale;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return _FieldShell(
      question: question,
      errorText: errorText,
      locale: locale,
      child: RadioGroup<String>(
        groupValue: value as String?,
        onChanged: onChanged,
        child: Column(
          children: [
            for (final option in question.options)
              RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(localizedText(option.label, locale: locale)),
                value: option.value,
              ),
          ],
        ),
      ),
    );
  }
}

/// checkbox — multiple choice, stores a List<String> of selected values.
class CheckboxQuestionField extends StatelessWidget {
  const CheckboxQuestionField({
    super.key,
    required this.question,
    required this.value,
    required this.onChanged,
    required this.locale,
    this.errorText,
  });

  final SurveyQuestion question;
  final Object? value;
  final ValueChanged<Object?> onChanged;
  final String locale;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final selected = (value as List?)?.cast<String>() ?? const <String>[];
    return _FieldShell(
      question: question,
      errorText: errorText,
      locale: locale,
      child: Column(
        children: [
          for (final option in question.options)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(localizedText(option.label, locale: locale)),
              value: selected.contains(option.value),
              onChanged: (checked) {
                final next = [...selected];
                if (checked == true) {
                  next.add(option.value);
                } else {
                  next.remove(option.value);
                }
                onChanged(next);
              },
            ),
        ],
      ),
    );
  }
}

/// dropdown — single choice via a menu, stores the option value (String).
class DropdownQuestionField extends StatelessWidget {
  const DropdownQuestionField({
    super.key,
    required this.question,
    required this.value,
    required this.onChanged,
    required this.locale,
    this.errorText,
  });

  final SurveyQuestion question;
  final Object? value;
  final ValueChanged<Object?> onChanged;
  final String locale;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return _FieldShell(
      question: question,
      errorText: errorText,
      locale: locale,
      child: DropdownButtonFormField<String>(
        initialValue: value as String?,
        isExpanded: true,
        decoration: const InputDecoration(border: OutlineInputBorder()),
        items: [
          for (final option in question.options)
            DropdownMenuItem(
              value: option.value,
              child: Text(localizedText(option.label, locale: locale)),
            ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

/// date — stores an ISO date string (yyyy-MM-dd).
class DateQuestionField extends StatelessWidget {
  const DateQuestionField({
    super.key,
    required this.question,
    required this.value,
    required this.onChanged,
    required this.locale,
    this.errorText,
  });

  final SurveyQuestion question;
  final Object? value;
  final ValueChanged<Object?> onChanged;
  final String locale;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final iso = value as String?;
    return _FieldShell(
      question: question,
      errorText: errorText,
      locale: locale,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.calendar_today),
        label: Text(iso ?? 'Select a date'),
        onPressed: () async {
          final now = DateTime.now();
          final picked = await showDatePicker(
            context: context,
            initialDate: iso != null ? DateTime.tryParse(iso) ?? now : now,
            firstDate: DateTime(now.year - 100),
            lastDate: DateTime(now.year + 1),
          );
          if (picked != null) {
            onChanged(picked.toIso8601String().split('T').first);
          }
        },
      ),
    );
  }
}

/// Placeholder for reserved/unimplemented types (gps, signature, …).
class UnsupportedQuestionField extends StatelessWidget {
  const UnsupportedQuestionField({
    super.key,
    required this.question,
    required this.locale,
  });

  final SurveyQuestion question;
  final String locale;

  @override
  Widget build(BuildContext context) {
    return _FieldShell(
      question: question,
      locale: locale,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.construction, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                AppLocalizations.of(context)
                    .questionnaireUnsupportedType(question.type.name),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
