import 'package:connectivity_plus/connectivity_plus.dart';

/// Thin wrapper around `connectivity_plus`.
///
/// The **Sync Engine** listens to [onConnectivityChanged] and drains the
/// pending-response queue whenever the device comes back online. UI can also
/// use [isConnected] to show an online/offline badge.
///
/// Note: connectivity only tells us a network *interface* is up, not that the
/// server is reachable. The sync engine therefore still treats every HTTP call
/// as potentially failing and relies on retry/status flags — this service is
/// just the trigger.
class ConnectivityService {
  ConnectivityService([Connectivity? connectivity])
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  /// Emits `true` when at least one network interface is available.
  Stream<bool> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged.map(_isConnected);

  /// One-shot check of the current connectivity state.
  Future<bool> get isConnected async =>
      _isConnected(await _connectivity.checkConnectivity());

  bool _isConnected(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);
}
