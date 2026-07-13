import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../data/datasources/response_sync_remote_datasource.dart';
import '../../data/sync_engine.dart';

/// UI-facing sync state.
class SyncUiState {
  const SyncUiState({
    this.syncing = false,
    this.lastSynced = 0,
    this.lastFailed = 0,
    this.hasResult = false,
  });

  final bool syncing;
  final int lastSynced;
  final int lastFailed;
  final bool hasResult;
}

final _responseSyncRemoteProvider = Provider(
  (ref) => ResponseSyncRemoteDataSource(ref.watch(dioProvider)),
);

final syncEngineProvider = Provider<SyncEngine>(
  (ref) => SyncEngine(
    ref.watch(appDatabaseProvider).responsesDao,
    ref.watch(_responseSyncRemoteProvider),
    ref.watch(connectivityServiceProvider),
  ),
);

/// Live count of not-yet-synced responses (drives the badge).
final unsyncedCountProvider = StreamProvider<int>(
  (ref) => ref.watch(appDatabaseProvider).responsesDao.watchUnsyncedCount(),
);

/// Orchestrates automatic sync (app start + on reconnect) and manual sync.
final syncControllerProvider =
    NotifierProvider<SyncController, SyncUiState>(SyncController.new);

class SyncController extends Notifier<SyncUiState> {
  @override
  SyncUiState build() {
    // Auto-sync whenever connectivity is (re)gained.
    ref.listen(connectivityStreamProvider, (_, next) {
      if (next.valueOrNull ?? false) _sync();
    });
    // Auto-sync once on startup (when this controller first comes alive).
    Future.microtask(_sync);
    return const SyncUiState();
  }

  /// Manual "Sync now", and the hook called after finalizing a response.
  Future<void> syncNow() => _sync();

  Future<void> _sync() async {
    if (state.syncing) return;
    state = const SyncUiState(syncing: true);
    final result = await ref.read(syncEngineProvider).syncPending();
    state = SyncUiState(
      syncing: false,
      lastSynced: result.synced,
      lastFailed: result.failed,
      hasResult: true,
    );
  }
}
