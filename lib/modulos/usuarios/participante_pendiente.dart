class ParticipantePendiente {
  final String idLocal;
  String nombre;
  String? email;
  String? telefono;
  String origen; // 'manual' | 'texto' | 'excel'
  String? errorValidacion;

  ParticipantePendiente({
    required this.idLocal,
    required this.nombre,
    this.email,
    this.telefono,
    required this.origen,
    this.errorValidacion,
  });

  bool get esValido => nombre.trim().isNotEmpty;

  Map<String, dynamic> toCrearBody(int eventoId) => {
        'evento_id': eventoId,
        'nombre': nombre.trim(),
        if (email != null && email!.trim().isNotEmpty) 'email': email!.trim(),
        if (telefono != null && telefono!.trim().isNotEmpty)
          'telefono': telefono!.trim(),
      };
}
