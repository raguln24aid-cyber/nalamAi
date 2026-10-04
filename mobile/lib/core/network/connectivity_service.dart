import 'package:connectivity_plus/connectivity_plus.dart';

/// Thin wrapper over connectivity_plus so the rest of the app depends on one small interface
/// (easier to fake in tests, and the single place that decides what counts as "online").
class ConnectivityService {
  ConnectivityService({Connectivity? connectivity}) : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  Future<bool> get isOnline async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  Stream<bool> get onStatusChange =>
      _connectivity.onConnectivityChanged.map((results) => results.any((r) => r != ConnectivityResult.none));
}
