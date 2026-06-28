import '../models/sala.dart';
import 'generic_repository.dart';

class SalasRepository {
  static final _generic = GenericRepository('salas');

  static Future<List<Sala>> listar({int? sedeId}) async {
    final rows = await _generic.listar(
      where: sedeId != null ? 'sede_id=?' : null,
      whereArgs: sedeId != null ? [sedeId] : null,
      orderBy: 'sede_id,id',
    );
    return rows.map(Sala.fromJson).toList();
  }

  static Future<Sala> crear(Map<String, dynamic> body) async =>
      Sala.fromJson(await _generic.crear(body));

  static Future<Sala> actualizar(int id, Map<String, dynamic> body) async =>
      Sala.fromJson(await _generic.actualizar(id, body));

  static Future<void> eliminar(int id) => _generic.eliminar(id);
}
