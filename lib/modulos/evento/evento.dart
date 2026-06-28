class Evento {
  final int id;
  final String nombre;
  final String fecha;
  final String horaInicio;
  final String horaFin;
  final String tipo;
  final double precio;
  final int? sedeId;
  final int? salaId;
  final String? nombreCliente;
  final String? telefonoCliente;
  final int participantes;
  final String estado;
  final String? descripcion;
  final String? nombreSede;

  Evento({
    required this.id,
    required this.nombre,
    required this.fecha,
    required this.horaInicio,
    required this.horaFin,
    required this.tipo,
    required this.precio,
    this.sedeId,
    this.salaId,
    this.nombreCliente,
    this.telefonoCliente,
    required this.participantes,
    required this.estado,
    this.descripcion,
    this.nombreSede,
  });

  factory Evento.fromJson(Map<String, dynamic> json) => Evento(
        id: json['id'],
        nombre: json['nombre'],
        fecha: json['fecha'] ?? '',
        horaInicio: json['hora_inicio'] ?? '',
        horaFin: json['hora_fin'] ?? '',
        tipo: json['tipo'] ?? 'gratuito',
        precio: double.tryParse(json['precio']?.toString() ?? '0') ?? 0,
        sedeId: json['sede_id'],
        salaId: json['sala_id'],
        nombreCliente: json['nombre_cliente'],
        telefonoCliente: json['telefono_cliente'],
        participantes: json['participantes'] ?? 0,
        estado: json['estado'] ?? 'proximo',
        descripcion: json['descripcion'],
        nombreSede: json['nombre_sede'],
      );
}
