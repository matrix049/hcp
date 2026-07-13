/// Global, compile-time configuration for the app.
///
/// `apiBaseUrl` is read from a `--dart-define=API_BASE_URL=...` at build time so
/// we never hardcode environment URLs into source. Defaults target a local
/// backend during development.
class AppConstants {
  AppConstants._();

  /// Base URL of the Node/Express REST API.
  /// - Windows desktop / web dev: http://localhost:3000/api
  /// - Android emulator: use http://10.0.2.2:3000/api (emulator alias to host)
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api',
  );

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);

  /// How many times the sync engine retries a failed response before giving up.
  static const int maxSyncAttempts = 5;

  /// Local SQLite database file name (managed by Drift).
  static const String databaseName = 'hcp_survey_db';
}
