import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/connectivity_service.dart';
import '../services/sync_manager.dart';

/// Banner reutilizable que muestra el estado de conexión y cuántos cambios
/// locales quedan por sincronizar con el servidor.
class SyncStatusBanner extends StatelessWidget {
  const SyncStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final online = context.watch<ConnectivityService>().isOnline;
    return StreamBuilder<int>(
      stream: SyncManager.instance.pendingCountStream,
      initialData: SyncManager.instance.lastKnownPendingCount,
      builder: (_, snap) {
        final pending = snap.data ?? 0;
        if (online && pending == 0) return const SizedBox.shrink();
        return Container(
          width: double.infinity,
          color: online ? const Color(0xFFF59E0B) : Colors.red,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          child: Text(
            online
                ? 'Sincronizando $pending cambio(s) pendiente(s)...'
                : 'Sin conexión — $pending cambio(s) pendiente(s) de sincronizar',
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        );
      },
    );
  }
}
