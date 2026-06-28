import '../models/sede.dart';
import 'generic_repository.dart';

class SedesRepository {
  static final _generic = GenericRepository('sedes');

  static Future<List<Sede>> listar() async =>
      (await _generic.listar(orderBy: 'id DESC')).map(Sede.fromJson).toList();

  static Future<Sede> crear(Map<String, dynamic> body) async =>
      Sede.fromJson(await _generic.crear(body));

  static Future<Sede> actualizar(int id, Map<String, dynamic> body) async =>
      Sede.fromJson(await _generic.actualizar(id, body));

  static Future<void> eliminar(int id) => _generic.eliminar(id);
}
