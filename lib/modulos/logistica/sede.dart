class Sede {
  final int id;
  final String nombre;
  final String? direccion;
  final String? telefono;
  final String? imagenUrl;

  Sede({
    required this.id,
    required this.nombre,
    this.direccion,
    this.telefono,
    this.imagenUrl,
  });

  factory Sede.fromJson(Map<String, dynamic> json) => Sede(
        id: json['id'],
        nombre: json['nombre'],
        direccion: json['direccion'],
        telefono: json['telefono'],
        imagenUrl: json['imagen_url'],
      );
}
