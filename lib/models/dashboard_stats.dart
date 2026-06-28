class DashboardStats {
  final int totalEventos;
  final int eventosActivos;
  final int eventosProximos;
  final int eventosCompletados;
  final int totalParticipantes;
  final int totalSedes;
  final int pagosPendientes;
  final double ingresosTotales;
  final int cotizacionesPendientes;

  DashboardStats({
    required this.totalEventos,
    required this.eventosActivos,
    required this.eventosProximos,
    required this.eventosCompletados,
    required this.totalParticipantes,
    required this.totalSedes,
    required this.pagosPendientes,
    required this.ingresosTotales,
    required this.cotizacionesPendientes,
  });

  static int _toInt(dynamic v) => int.tryParse(v?.toString() ?? '0') ?? 0;

  factory DashboardStats.fromJson(Map<String, dynamic> json) => DashboardStats(
        totalEventos: _toInt(json['total_eventos']),
        eventosActivos: _toInt(json['eventos_activos']),
        eventosProximos: _toInt(json['eventos_proximos']),
        eventosCompletados: _toInt(json['eventos_completados']),
        totalParticipantes: _toInt(json['total_participantes']),
        totalSedes: _toInt(json['total_sedes']),
        pagosPendientes: _toInt(json['pagos_pendientes']),
        ingresosTotales:
            double.tryParse(json['ingresos_totales']?.toString() ?? '0') ?? 0,
        cotizacionesPendientes: _toInt(json['cotizaciones_pendientes']),
      );
}
