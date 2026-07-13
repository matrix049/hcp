import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../data/datasources/auth_local_datasource.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_controller.dart';
import 'auth_state.dart';

/// Wires the auth feature onto the core DI graph (Dio, secure storage,
/// connectivity all come from `core/di/providers.dart`).

final _authRemoteDataSourceProvider = Provider(
  (ref) => AuthRemoteDataSource(ref.watch(dioProvider)),
);

final _authLocalDataSourceProvider = Provider(
  (ref) => AuthLocalDataSource(ref.watch(secureStorageProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    remote: ref.watch(_authRemoteDataSourceProvider),
    local: ref.watch(_authLocalDataSourceProvider),
    connectivity: ref.watch(connectivityServiceProvider),
  ),
);

/// The single source of auth state for the UI.
final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
