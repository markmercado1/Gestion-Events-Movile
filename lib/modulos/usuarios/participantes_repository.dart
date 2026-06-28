import '../db/local_dao.dart';
import '../models/participante.dart';
import 'generic_repository.dart';

class ParticipantesRepository {
  static final _generic = GenericRepository('participantes');
  static final _eventosDao = LocalDao('eventos_local');

  static Future<List<Participante>> listar({required int eventoId}) async {
    final rows = await _generic.listar(where: 'evento_id=?', whereArgs: [eventoId]);
    return rows.map(Participante.fromJson).toList();
  }

  static Future<Participante> crear(Map<String, dynamic> body) async {
    String? dependsOnUuid;
    final eventoId = body['evento_id'] as int?;
    if (eventoId != null && eventoId < 0) {
      final evento = await _eventosDao.obtener(eventoId);
      dependsOnUuid = evento?['client_uuid'] as String?;
    }
    return Participante.fromJson(await _generic.crear(body, dependsOnUuid: dependsOnUuid));
  }

  static Future<Participante> marcarAsistencia(int id, bool nuevoValor) async =>
      Participante.fromJson(await _generic.actualizar(id, {'asistio': nuevoValor}));

  static Future<void> eliminar(int id) => _generic.eliminar(id);
}
