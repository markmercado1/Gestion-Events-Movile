class Cotizacion {
  final int id;
  final String nombre;
  final String telefono;
  final String? tipoEvento;
  final String? fechaEvento;
  final String? sedePreferida;
  final String? mensaje;
  final String estado;
  final String? creadoEn;

  Cotizacion({
    required this.id,
    required this.nombre,
    required this.telefono,
    this.tipoEvento,
    this.fechaEvento,
    this.sedePreferida,
    this.mensaje,
    required this.estado,
    this.creadoEn,
  });

  factory Cotizacion.fromJson(Map<String, dynamic> json) => Cotizacion(
        id: json['id'],
        nombre: json['nombre'],
        telefono: json['telefono'],
        tipoEvento: json['tipo_evento'],
        fechaEvento: json['fecha_evento'],
        sedePreferida: json['sede_preferida'],
        mensaje: json['mensaje'],
        estado: json['estado'] ?? 'pendiente',
        creadoEn: json['creado_en'],
      );
}
