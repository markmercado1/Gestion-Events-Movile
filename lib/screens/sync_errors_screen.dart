import 'package:flutter/material.dart';
import '../db/daos/pending_operations_dao.dart';
import '../services/sync_manager.dart';

class SyncErrorsScreen extends StatefulWidget {
  const SyncErrorsScreen({super.key});

  @override
  State<SyncErrorsScreen> createState() => _SyncErrorsScreenState();
}

class _SyncErrorsScreenState extends State<SyncErrorsScreen> {
  List<PendingOperation> _errores = [];
  bool _cargando = true;
  bool _reintentandoTodos = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final errores = await PendingOperationsDao.getErrores();
    setState(() {
      _errores = errores;
      _cargando = false;
    });
  }

  Future<void> _reintentar(PendingOperation op) async {
    await PendingOperationsDao.reintentarManual(op.id);
    await SyncManager.instance.syncAll();
    await _cargar();
  }

  Future<void> _reintentarTodos() async {
    setState(() => _reintentandoTodos = true);
    for (final op in _errores) {
      await PendingOperationsDao.reintentarManual(op.id);
    }
    await SyncManager.instance.syncAll();
    await _cargar();
    if (mounted) setState(() => _reintentandoTodos = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Errores de sincronización',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.grey), onPressed: _cargar),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B)))
          : _errores.isEmpty
              ? const Center(
                  child: Text('No hay errores de sincronización',
                      style: TextStyle(color: Colors.grey)))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _reintentandoTodos ? null : _reintentarTodos,
                          icon: _reintentandoTodos
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.black))
                              : const Icon(Icons.refresh, size: 18),
                          label: Text('Reintentar todos (${_errores.length})'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF59E0B),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: _errores.length,
                        itemBuilder: (_, i) => _buildCard(_errores[i]),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildCard(PendingOperation op) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text('${op.entity} · ${op.operation}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 6),
          Text(op.lastError ?? 'Error desconocido',
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          Text('Intentos automáticos: ${op.attempts}',
              style: const TextStyle(color: Colors.grey, fontSize: 11)),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: () => _reintentar(op),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Reintentar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFF59E0B),
                side: const BorderSide(color: Color(0xFFF59E0B)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
