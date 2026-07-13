/// Low-level exceptions thrown by the **data layer** (datasources).
///
/// These are internal: repositories catch them and translate them into
/// [Failure] objects (see `failures.dart`) that the rest of the app understands.
/// Keeping exceptions and failures separate is a Clean Architecture convention —
/// the domain/presentation layers never deal with raw exceptions.
library;

class ServerException implements Exception {
  ServerException([this.message = 'Server error', this.statusCode]);
  final String message;
  final int? statusCode;
}

class CacheException implements Exception {
  CacheException([this.message = 'Local storage error']);
  final String message;
}

class NetworkException implements Exception {
  NetworkException([this.message = 'No internet connection']);
  final String message;
}

class AuthException implements Exception {
  AuthException([this.message = 'Authentication failed']);
  final String message;
}
