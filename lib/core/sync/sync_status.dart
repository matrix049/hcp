/// Lifecycle of a locally-stored survey response with respect to the server.
///
/// This enum IS our "sync queue": instead of a separate outbox table that
/// duplicates response data, each response row carries its own status and the
/// sync engine simply queries `WHERE syncStatus = pending`. Simpler, no data
/// duplication, and sufficient because each agent owns their own responses.
///
/// IMPORTANT: the order of these values is persisted as an integer index by
/// Drift (`intEnum`). Only ever APPEND new values — never reorder or remove —
/// or existing local data will be misinterpreted.
enum SyncStatus {
  /// Being edited by the agent; not yet queued for upload.
  draft,

  /// Finalised locally, waiting for connectivity to upload.
  pending,

  /// Currently being uploaded.
  syncing,

  /// Successfully stored on the server.
  synced,

  /// Upload failed (see `attempts` / `lastError`); will be retried.
  failed,

  /// Server rejected the upload because a conflicting version exists.
  /// Reserved for a future conflict-resolution phase — NOT handled yet.
  /// Appended last so existing persisted indices stay valid.
  conflict,
}
