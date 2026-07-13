import 'package:drift/drift.dart';

import '../../sync/sync_status.dart';

/// A single filled-in questionnaire (one household, one visit, …).
///
/// Answers are stored as a JSON map in [answersJson] keyed by question id — the
/// same generic shape for every survey. The sync columns ([syncStatus],
/// [attempts], [lastError], [remoteId]) implement the offline outbox: the sync
/// engine finds work via `syncStatus`, records retries, and stamps the server
/// id once uploaded.
class SurveyResponses extends Table {
  /// Client-generated UUID — assigned offline so a response has a stable
  /// identity before it ever reaches the server.
  TextColumn get id => text()();

  /// FK to [Surveys.remoteId] — which survey this response answers.
  TextColumn get surveyRemoteId => text()();

  /// The agent who collected it (for multi-user devices / audit).
  TextColumn get agentId => text()();

  /// `{ "q_region": "marrakech_safi", "q_household_size": 4, ... }`
  TextColumn get answersJson => text().withDefault(const Constant('{}'))();

  /// Persisted as its integer index — see [SyncStatus] append-only warning.
  IntColumn get syncStatus =>
      intEnum<SyncStatus>().withDefault(const Constant(0))();

  IntColumn get attempts => integer().withDefault(const Constant(0))();

  TextColumn get lastError => text().nullable()();

  /// Server id, populated after a successful upload (null while offline).
  TextColumn get remoteId => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
