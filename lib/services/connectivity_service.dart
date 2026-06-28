import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'sync_manager.dart';

/// Singleton + ChangeNotifier: expone el estado de conectividad tanto para
/// la UI (via Provider) como para código no-UI (repositories, SyncManager)
/// que necesita preguntar "¿hay red?" sin un BuildContext a mano.
class ConnectivityService extends ChangeNotifier {
  static final ConnectivityService instance = ConnectivityService._();
  ConnectivityService._() {
    _checkInitial();
    Connectivity().onConnectivityChanged.listen(_onChange);
  }

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  Future<void> _checkInitial() async {
    final result = await Connectivity().checkConnectivity();
    _isOnline = result.any((r) => r != ConnectivityResult.none);
    notifyListeners();
  }

  Future<void> _onChange(List<ConnectivityResult> results) async {
    final wasOffline = !_isOnline;
    _isOnline = results.any((r) => r != ConnectivityResult.none);
    notifyListeners();
    if (wasOffline && _isOnline) {
      SyncManager.instance.syncAll();
    }
  }
}
