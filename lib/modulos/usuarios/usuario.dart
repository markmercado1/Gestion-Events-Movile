class Usuario {
  final int id;
  final String email;
  final String rol;

  Usuario({required this.id, required this.email, required this.rol});

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
        id: json['id'],
        email: json['email'],
        rol: json['rol'] ?? 'usuario',
      );

  bool get esAdmin => rol == 'admin';
  bool get esOrganizador => rol == 'organizador' || rol == 'admin';
}
