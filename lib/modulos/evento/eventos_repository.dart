import '../models/evento.dart';
import 'generic_repository.dart';

class EventosRepository {
  static final _generic = GenericRepository('eventos');

  static Future<List<Evento>> listar({String? estado}) async {
    final rows = await _generic.listar(
      where: estado != null ? 'estado=?' : null,
      whereArgs: estado != null ? [estado] : null,
      orderBy: 'fecha DESC',
    );
    return rows.map(Evento.fromJson).toList();
  }

  static Future<Evento> crear(Map<String, dynamic> body) async =>
      Evento.fromJson(await _generic.crear(body));

  static Future<Evento> actualizar(int id, Map<String, dynamic> body) async =>
      Evento.fromJson(await _generic.actualizar(id, body));

  static Future<void> eliminar(int id) => _generic.eliminar(id);
}
