import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

final connectivityProvider = StateNotifierProvider<ConnectivityNotifier, bool>(
  (ref) => ConnectivityNotifier(),
);

class ConnectivityNotifier extends StateNotifier<bool> {
  final Connectivity _connectivity = Connectivity();
  final InternetConnection _internetChecker = InternetConnection();

  ConnectivityNotifier() : super(true) {
    _monitorConnectivity();
  }

  void _monitorConnectivity() {
    _connectivity.onConnectivityChanged.listen((connectivityResult) async {
      if (connectivityResult.every((result) => result == ConnectivityResult.none)) {
        state = false; // Pas de réseau
      } else {
        final hasInternet = await _internetChecker.hasInternetAccess;
        state = hasInternet; // True si Internet est accessible
      }
    });
  }

  Future<void> refreshConnectionStatus() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult.every((result) => result == ConnectivityResult.none)) {
      state = false; // Pas de réseau
    } else {
      final hasInternet = await _internetChecker.hasInternetAccess;
      state = hasInternet; // True si Internet est accessible
    }
  }
}
