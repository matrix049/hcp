/// User-facing, domain-level error types.
///
/// Every use case returns `Either<Failure, T>` (via the `dartz` package): the
/// left side is one of these failures, the right side is the success value.
/// This makes error handling explicit and type-safe — no uncaught exceptions
/// leaking into the UI.
///
/// `sealed` lets the presentation layer `switch` over every failure kind with
/// compile-time exhaustiveness checks.
library;

sealed class Failure {
  const Failure(this.message);
  final String message;

  @override
  String toString() => '$runtimeType(message: $message)';
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'A server error occurred']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Local storage error']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication failed']);
}

class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Invalid data']);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'An unexpected error occurred']);
}
