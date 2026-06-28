import '../models/pago.dart';
import 'generic_repository.dart';

class PagosRepository {
  static final _generic = GenericRepository('pagos');

  static Future<List<Pago>> listar() async =>
      (await _generic.listar(orderBy: 'creado_en DESC')).map(Pago.fromJson).toList();

  static Future<Pago> crear(Map<String, dynamic> body) async =>
      Pago.fromJson(await _generic.crear(body));

  static Future<Pago> cambiarEstado(int id, String nuevoEstado) async =>
      Pago.fromJson(await _generic.actualizar(id, {'estado': nuevoEstado}));
}
