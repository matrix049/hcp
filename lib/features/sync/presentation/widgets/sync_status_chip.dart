import 'package:flutter/material.dart';

import '../../../../core/sync/sync_status.dart';

/// A small coloured chip showing a response's sync status. Shared by the
/// per-survey responses list and the history screen.
class SyncStatusChip extends StatelessWidget {
  const SyncStatusChip({super.key, required this.status});

  final SyncStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      SyncStatus.draft => ('Draft', Colors.grey),
      SyncStatus.pending => ('Pending', Colors.orange),
      SyncStatus.syncing => ('Syncing', Colors.blue),
      SyncStatus.synced => ('Synced', Colors.green),
      SyncStatus.failed => ('Failed', Colors.red),
      SyncStatus.conflict => ('Conflict', Colors.purple),
    };
    return Chip(
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.15),
      side: BorderSide(color: color),
      visualDensity: VisualDensity.compact,
    );
  }
}
