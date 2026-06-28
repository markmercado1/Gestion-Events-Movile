import 'package:flutter/material.dart';
import '../models/cotizacion.dart';
import '../repositories/cotizaciones_repository.dart';

class CotizacionesScreen extends StatefulWidget {
  const CotizacionesScreen({super.key});

  @override
  State<CotizacionesScreen> createState() => _CotizacionesScreenState();
}

class _CotizacionesScreenState extends State<CotizacionesScreen> {
  List<Cotizacion> _cotizaciones = [];
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
      final cotizaciones = await CotizacionesRepository.listar();
      setState(() => _cotizaciones = cotizaciones);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _cambiarEstado(int id, String nuevoEstado) async {
    try {
      await CotizacionesRepository.cambiarEstado(id, nuevoEstado);
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
        title: const Text('Cotizaciones',
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
              : _cotizaciones.isEmpty
                  ? const Center(
                      child: Text('No hay cotizaciones',
                          style: TextStyle(color: Colors.grey)))
                  : RefreshIndicator(
                      color: const Color(0xFFF59E0B),
                      onRefresh: _cargar,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _cotizaciones.length,
                        itemBuilder: (_, i) => _buildCard(_cotizaciones[i]),
                      ),
                    ),
    );
  }

  Widget _buildCard(Cotizacion c) {
    Color estadoColor;
    switch (c.estado) {
      case 'contactado':
        estadoColor = Colors.green;
        break;
      case 'descartado':
        estadoColor = Colors.red;
        break;
      default:
        estadoColor = const Color(0xFFF59E0B);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        collapsedIconColor: Colors.grey,
        iconColor: const Color(0xFFF59E0B),
        title: Row(
          children: [
            Expanded(
              child: Text(c.nombre,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: estadoColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(c.estado,
                  style: TextStyle(color: estadoColor, fontSize: 11)),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(c.telefono,
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(color: Color(0xFF2A2A2A)),
                if (c.tipoEvento != null) _fila('Tipo evento', c.tipoEvento!),
                if (c.fechaEvento != null) _fila('Fecha', c.fechaEvento!),
                if (c.sedePreferida != null) _fila('Sede preferida', c.sedePreferida!),
                if (c.mensaje != null && c.mensaje!.isNotEmpty)
                  _fila('Mensaje', c.mensaje!),
                if (c.creadoEn != null) _fila('Recibido', c.creadoEn!),
                if (c.estado == 'pendiente') ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _cambiarEstado(c.id, 'contactado'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.green,
                            side: const BorderSide(color: Colors.green),
                          ),
                          child: const Text('Contactado'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _cambiarEstado(c.id, 'descartado'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                          child: const Text('Descartar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fila(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ),
          Expanded(
            child: Text(valor,
                style: const TextStyle(color: Colors.white, fontSize: 13)),
          ),
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
