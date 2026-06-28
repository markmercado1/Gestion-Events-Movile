import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/pago.dart';
import '../repositories/pagos_repository.dart';

class PagosScreen extends StatefulWidget {
  const PagosScreen({super.key});

  @override
  State<PagosScreen> createState() => _PagosScreenState();
}

class _PagosScreenState extends State<PagosScreen> {
  List<Pago> _pagos = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final pagos = await PagosRepository.listar();
      setState(() => _pagos = pagos);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _cambiarEstado(int id, String nuevoEstado) async {
    try {
      await PagosRepository.cambiarEstado(id, nuevoEstado);
      _cargar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Pagos',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.grey),
            onPressed: _cargar,
          ),
        ],
        elevation: 0,
      ),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFF59E0B)))
          : _error != null
              ? _buildError()
              : _pagos.isEmpty
                  ? const Center(
                      child: Text('No hay pagos registrados',
                          style: TextStyle(color: Colors.grey)))
                  : RefreshIndicator(
                      color: const Color(0xFFF59E0B),
                      onRefresh: _cargar,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _pagos.length,
                        itemBuilder: (_, i) => _buildCard(_pagos[i]),
                      ),
                    ),
    );
  }

  Widget _buildCard(Pago p) {
    final formato = NumberFormat.currency(locale: 'es_PE', symbol: 'S/');
    Color estadoColor;
    IconData estadoIcon;
    switch (p.estado) {
      case 'verificado':
        estadoColor = Colors.green;
        estadoIcon = Icons.check_circle;
        break;
      case 'rechazado':
        estadoColor = Colors.red;
        estadoIcon = Icons.cancel;
        break;
      default:
        estadoColor = const Color(0xFFF59E0B);
        estadoIcon = Icons.pending;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  p.nombreEvento ?? 'Evento #${p.eventoId}',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
              Icon(estadoIcon, color: estadoColor, size: 20),
              const SizedBox(width: 4),
              Text(p.estado,
                  style: TextStyle(color: estadoColor, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            formato.format(p.monto),
            style: const TextStyle(
                color: Color(0xFFF59E0B),
                fontSize: 22,
                fontWeight: FontWeight.bold),
          ),
          if (p.creadoEn != null) ...[
            const SizedBox(height: 4),
            Text(p.creadoEn!,
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
          if (p.estado == 'pendiente') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _cambiarEstado(p.id, 'verificado'),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Verificar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                      side: const BorderSide(color: Colors.green),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _cambiarEstado(p.id, 'rechazado'),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Rechazar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.grey, size: 48),
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _cargar,
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B)),
            child: const Text('Reintentar', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }
}
