import '../models/recurso.dart';
import 'generic_repository.dart';

class RecursosRepository {
  static final _generic = GenericRepository('recursos');

  static Future<List<Recurso>> listar() async =>
      (await _generic.listar(orderBy: 'nombre ASC')).map(Recurso.fromJson).toList();

  static Future<Recurso> crear(Map<String, dynamic> body) async =>
      Recurso.fromJson(await _generic.crear(body));

  static Future<Recurso> actualizar(int id, Map<String, dynamic> body) async =>
      Recurso.fromJson(await _generic.actualizar(id, body));

  static Future<void> eliminar(int id) => _generic.eliminar(id);
}
