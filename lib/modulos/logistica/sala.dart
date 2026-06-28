class Sala {
  final int id;
  final int sedeId;
  final String nombre;
  final int? capacidad;
  final String estado;

  Sala({
    required this.id,
    required this.sedeId,
    required this.nombre,
    this.capacidad,
    required this.estado,
  });

  factory Sala.fromJson(Map<String, dynamic> json) => Sala(
        id: json['id'],
        sedeId: json['sede_id'],
        nombre: json['nombre'],
        capacidad: json['capacidad'],
        estado: json['estado'] ?? 'disponible',
      );
}
