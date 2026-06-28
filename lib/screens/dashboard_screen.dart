import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/dashboard_stats.dart';
import '../models/evento.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardStats? _stats;
  List<Evento> _proximosEventos = [];
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
      final statsData = await ApiService.get('/dashboard/estadisticas');
      final eventosData = await ApiService.get('/eventos?estado=proximo');
      setState(() {
        _stats = DashboardStats.fromJson(statsData);
        final lista = eventosData is List ? eventosData : eventosData['data'] ?? [];
        _proximosEventos =
            (lista as List).map((e) => Evento.fromJson(e)).take(5).toList();
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthService>().usuario;
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dashboard',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            if (usuario != null)
              Text(usuario.email,
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.grey),
            onPressed: _cargar,
          ),
        ],
        elevation: 0,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B)))
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  color: const Color(0xFFF59E0B),
                  onRefresh: _cargar,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (_stats != null) ...[
                        _buildKpiGrid(),
                        const SizedBox(height: 24),
                        _buildIngresosCard(),
                        const SizedBox(height: 24),
                      ],
                      if (_proximosEventos.isNotEmpty) ...[
                        const Text('Próximos eventos',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        ..._proximosEventos.map(_buildEventoCard),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildKpiGrid() {
    final s = _stats!;
    final kpis = [
      _KpiData('Total eventos', s.totalEventos.toString(), Icons.event, Colors.blue),
      _KpiData('Activos', s.eventosActivos.toString(), Icons.play_circle, Colors.green),
      _KpiData('Próximos', s.eventosProximos.toString(), Icons.schedule, const Color(0xFFF59E0B)),
      _KpiData('Participantes', s.totalParticipantes.toString(), Icons.people, Colors.purple),
      _KpiData('Sedes', s.totalSedes.toString(), Icons.location_on, Colors.teal),
      _KpiData('Cotizaciones', s.cotizacionesPendientes.toString(), Icons.description, Colors.orange),
    ];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1,
      children: kpis.map(_buildKpiCard).toList(),
    );
  }

  Widget _buildKpiCard(_KpiData kpi) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(kpi.icon, color: kpi.color, size: 24),
          const SizedBox(height: 8),
          Text(kpi.valor,
              style: const TextStyle(
                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(kpi.label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildIngresosCard() {
    final formato = NumberFormat.currency(locale: 'es_PE', symbol: 'S/');
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.attach_money, color: Colors.black, size: 32),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Ingresos totales',
                  style: TextStyle(color: Colors.black87, fontSize: 12)),
              Text(
                formato.format(_stats!.ingresosTotales),
                style: const TextStyle(
                    color: Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEventoCard(Evento e) {
    Color estadoColor;
    switch (e.estado) {
      case 'activo':
        estadoColor = Colors.green;
        break;
      case 'completado':
        estadoColor = Colors.grey;
        break;
      default:
        estadoColor = const Color(0xFFF59E0B);
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 50,
            decoration: BoxDecoration(
              color: estadoColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.nombre,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('${e.fecha}  â€¢  ${e.horaInicio} - ${e.horaFin}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
                if (e.nombreSede != null)
                  Text(e.nombreSede!,
                      style: const TextStyle(
                          color: Color(0xFFF59E0B), fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: estadoColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(e.estado,
                style: TextStyle(color: estadoColor, fontSize: 11)),
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
          const Icon(Icons.wifi_off, color: Colors.grey, size: 48),
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _cargar,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B)),
            child: const Text('Reintentar', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }
}

class _KpiData {
  final String label;
  final String valor;
  final IconData icon;
  final Color color;
  _KpiData(this.label, this.valor, this.icon, this.color);
}
