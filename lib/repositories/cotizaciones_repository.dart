import '../models/cotizacion.dart';
import 'generic_repository.dart';

class CotizacionesRepository {
  static final _generic = GenericRepository('cotizaciones');

  static Future<List<Cotizacion>> listar() async =>
      (await _generic.listar(orderBy: 'creado_en DESC')).map(Cotizacion.fromJson).toList();

  static Future<Cotizacion> crear(Map<String, dynamic> body) async =>
      Cotizacion.fromJson(await _generic.crear(body));

  static Future<Cotizacion> cambiarEstado(int id, String nuevoEstado) async =>
      Cotizacion.fromJson(await _generic.actualizar(id, {'estado': nuevoEstado}));
}
