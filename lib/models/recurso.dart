class Recurso {
  final int id;
  final String nombre;
  final String? categoria;
  final int cantidad;
  final String estado;
  final String? descripcion;

  Recurso({
    required this.id,
    required this.nombre,
    this.categoria,
    required this.cantidad,
    required this.estado,
    this.descripcion,
  });

  factory Recurso.fromJson(Map<String, dynamic> json) => Recurso(
        id: json['id'],
        nombre: json['nombre'],
        categoria: json['categoria'],
        cantidad: json['cantidad'] ?? 1,
        estado: json['estado'] ?? 'disponible',
        descripcion: json['descripcion'],
      );
}
