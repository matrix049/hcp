import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_providers.dart';
import 'auth_state.dart';

/// Holds auth state and drives login/logout. Calls the repository directly —
/// no use-case layer, kept intentionally lean for the current phase.
class AuthController extends Notifier<AuthState> {
  AuthRepository get _repository => ref.read(authRepositoryProvider);

  @override
  AuthState build() {
    // If the interceptor gives up refreshing an expired session, log out.
    ref.listen(sessionExpiredProvider, (previous, next) {
      if ((previous ?? 0) < next) {
        state = const AuthUnauthenticated(
          message: 'Your session has expired. Please sign in again.',
        );
      }
    });
    _restoreSession();
    return const AuthChecking();
  }

  /// On startup, restore a cached agent so the app can open offline.
  Future<void> _restoreSession() async {
    final result = await _repository.getCurrentAgent();
    state = result.fold(
      (_) => const AuthUnauthenticated(),
      (agent) => agent == null
          ? const AuthUnauthenticated()
          : AuthAuthenticated(agent),
    );
  }

  Future<void> login({
    required String matricule,
    required String password,
  }) async {
    state = const AuthAuthenticating();
    final result = await _repository.login(
      matricule: matricule,
      password: password,
    );
    state = result.fold(
      (failure) => AuthUnauthenticated(message: failure.message),
      (agent) => AuthAuthenticated(agent),
    );
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthUnauthenticated();
  }
}
