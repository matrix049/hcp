import '../../domain/entities/agent_user.dart';

/// UI-facing authentication state. `sealed` so widgets can switch over it with
/// compile-time exhaustiveness.
sealed class AuthState {
  const AuthState();
}

/// App just started; we're checking for a cached session.
class AuthChecking extends AuthState {
  const AuthChecking();
}

/// A login request is in flight.
class AuthAuthenticating extends AuthState {
  const AuthAuthenticating();
}

/// Logged in (online or offline).
class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.agent);
  final AgentUser agent;
}

/// Not logged in. [message] carries the last error, if any.
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated({this.message});
  final String? message;
}
