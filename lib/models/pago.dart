class Pago {
  final int id;
  final int eventoId;
  final double monto;
  final String estado;
  final String? urlComprobante;
  final String? creadoEn;
  final String? nombreEvento;

  Pago({
    required this.id,
    required this.eventoId,
    required this.monto,
    required this.estado,
    this.urlComprobante,
    this.creadoEn,
    this.nombreEvento,
  });

  factory Pago.fromJson(Map<String, dynamic> json) => Pago(
        id: json['id'],
        eventoId: json['evento_id'],
        monto: double.tryParse(json['monto']?.toString() ?? '0') ?? 0,
        estado: json['estado'] ?? 'pendiente',
        urlComprobante: json['url_comprobante'],
        creadoEn: json['creado_en'],
        nombreEvento: json['nombre_evento'],
      );
}
