import 'package:drift/drift.dart';

/// Locally cached survey **definitions** downloaded from the server.
///
/// The questionnaire itself is NOT modelled as columns — it lives untouched in
/// [definitionJson] (the raw survey JSON). This is what makes the app support
/// arbitrary surveys without schema changes: to add a new survey shape, the
/// server just serves different JSON.
class Surveys extends Table {
  /// Server-side identifier (e.g. "survey_household_2026"). Primary key so a
  /// re-download of the same survey upserts rather than duplicates.
  TextColumn get remoteId => text()();

  TextColumn get title => text()();

  IntColumn get version => integer().withDefault(const Constant(1))();

  /// The full, untouched survey JSON (pages, questions, options, validation).
  TextColumn get definitionJson => text()();

  DateTimeColumn get downloadedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {remoteId};
}
