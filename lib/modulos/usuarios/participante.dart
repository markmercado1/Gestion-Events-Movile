class Participante {
  final int id;
  final int eventoId;
  final String nombre;
  final String? email;
  final String? telefono;
  final bool asistio;

  Participante({
    required this.id,
    required this.eventoId,
    required this.nombre,
    this.email,
    this.telefono,
    required this.asistio,
  });

  factory Participante.fromJson(Map<String, dynamic> json) => Participante(
        id: json['id'],
        eventoId: json['evento_id'],
        nombre: json['nombre'],
        email: json['email'],
        telefono: json['telefono'],
        asistio: json['asistio'] == 1 || json['asistio'] == true,
      );
}
