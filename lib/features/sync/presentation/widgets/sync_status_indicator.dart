import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';

import '../providers/sync_providers.dart';

/// App-bar action: shows the unsynced count as a badge, a spinner while
/// syncing, and triggers a manual sync on tap.
class SyncStatusIndicator extends ConsumerWidget {
  const SyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Announce sync results.
    final l10n = AppLocalizations.of(context);

    ref.listen<SyncUiState>(syncControllerProvider, (prev, next) {
      final justFinished = (prev?.syncing ?? false) && !next.syncing;
      if (justFinished && next.hasResult) {
        final msg = next.lastFailed > 0
            ? l10n.syncPartial(next.lastSynced, next.lastFailed)
            : next.lastSynced > 0
                ? l10n.syncDone(next.lastSynced)
                : l10n.syncUpToDate;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(msg)));
      }
    });

    final sync = ref.watch(syncControllerProvider);
    final unsynced = ref.watch(unsyncedCountProvider).valueOrNull ?? 0;

    return IconButton(
      tooltip: l10n.syncNow,
      onPressed: sync.syncing
          ? null
          : () => ref.read(syncControllerProvider.notifier).syncNow(),
      icon: sync.syncing
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Badge(
              isLabelVisible: unsynced > 0,
              label: Text('$unsynced'),
              child: const Icon(Icons.sync),
            ),
    );
  }
}
