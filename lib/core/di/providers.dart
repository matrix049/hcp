import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../connectivity/connectivity_service.dart';
import '../database/app_database.dart';
import '../network/dio_client.dart';
import '../storage/secure_storage_service.dart';

/// Global (core) dependency-injection graph.
///
/// Riverpod IS our service locator — no extra DI package needed. Feature
/// providers (auth, surveys, …) will `ref.watch` these core providers instead
/// of constructing their own database/Dio/storage instances, so there is
/// exactly one of each at runtime.

/// The single [AppDatabase] instance for the whole app.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final secureStorageProvider = Provider<SecureStorageService>(
  (ref) => SecureStorageService(),
);

final connectivityServiceProvider = Provider<ConnectivityService>(
  (ref) => ConnectivityService(),
);

/// Convenience stream of the current online/offline state.
final connectivityStreamProvider = StreamProvider<bool>((ref) {
  return ref.watch(connectivityServiceProvider).onConnectivityChanged;
});

/// Bumped whenever the interceptor fails to refresh an expired session.
/// `AuthController` listens to this to send the agent back to login. Kept in
/// core (neutral) so the network layer never imports the auth feature.
final sessionExpiredProvider = StateProvider<int>((ref) => 0);

/// The shared, pre-configured Dio client (auth interceptor attached).
final dioProvider = Provider<Dio>((ref) {
  return DioClient.create(
    secureStorage: ref.watch(secureStorageProvider),
    onSessionExpired: () =>
        ref.read(sessionExpiredProvider.notifier).state++,
  );
});
