import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

import '../../../../core/sync/sync_status.dart';

/// A small coloured chip showing a response's sync status. Shared by the
/// per-survey responses list and the history screen.
class SyncStatusChip extends StatelessWidget {
  const SyncStatusChip({super.key, required this.status});

  final SyncStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (label, color) = switch (status) {
      SyncStatus.draft => (l10n.statusDraft, Colors.grey),
      SyncStatus.pending => (l10n.statusPending, Colors.orange),
      SyncStatus.syncing => (l10n.statusSyncing, Colors.blue),
      SyncStatus.synced => (l10n.statusSynced, Colors.green),
      SyncStatus.failed => (l10n.statusFailed, Colors.red),
      SyncStatus.conflict => (l10n.statusConflict, Colors.purple),
    };
    return Chip(
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.15),
      side: BorderSide(color: color),
      visualDensity: VisualDensity.compact,
    );
  }
}
