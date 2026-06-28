import 'package:uuid/uuid.dart';
import '../db/local_dao.dart';
import '../db/daos/pending_operations_dao.dart';
import '../services/connectivity_service.dart';
import '../services/sync_manager.dart';

const _uuid = Uuid();

/// Motor común de lectura/escritura offline-first compartido por las 7
/// entidades de dominio (eventos, sedes, salas, pagos, participantes,
/// cotizaciones, recursos). Cada una lo envuelve en un repositorio propio
/// (lib/repositories/<entidad>_repository.dart) que sólo añade los filtros
/// de consulta específicos — la lógica de cache/cola/sync es idéntica.
class GenericRepository {
  final String entity;
  final LocalDao dao;
  GenericRepository(this.entity) : dao = LocalDao('${entity}_local');

  Future<List<Map<String, dynamic>>> listar(
      {String? where, List<Object?>? whereArgs, String? orderBy}) async {
    final locales = await dao.listar(where: where, whereArgs: whereArgs, orderBy: orderBy);
    if (ConnectivityService.instance.isOnline) {
      SyncManager.instance.refreshEntity(entity);
    }
    return locales;
  }

  Future<Map<String, dynamic>> crear(Map<String, dynamic> datos,
      {String? dependsOnUuid}) async {
    final clientUuid = _uuid.v4();
    final localId = await dao.crearPendiente(datos, clientUuid);
    await PendingOperationsDao.enqueue(
      entity: entity,
      operation: 'create',
      localId: localId,
      clientUuid: clientUuid,
      payload: {...datos, 'client_uuid': clientUuid},
      dependsOnUuid: dependsOnUuid,
    );
    await _avisarCambioPendiente();
    return {...datos, 'id': localId, 'client_uuid': clientUuid};
  }

  Future<Map<String, dynamic>> actualizar(int id, Map<String, dynamic> datos) async {
    final actual = await dao.obtener(id);
    await dao.actualizarPendiente(id, datos);
    if (actual != null && actual['sync_status'] == 'pending_create') {
      // Aún no se sincronizó la creación: se fusiona en el mismo payload de
      // creación en vez de encolar un update sobre un id temporal.
      await PendingOperationsDao.mergePayloadByClientUuid(
          actual['client_uuid'] as String, datos);
    } else {
      final clientUuid = actual?['client_uuid'] as String? ?? _uuid.v4();
      final baseUpdatedAt = actual?['updated_at'] as String?;
      await PendingOperationsDao.enqueue(
        entity: entity,
        operation: 'update',
        localId: id,
        clientUuid: clientUuid,
        payload: {...datos, if (baseUpdatedAt != null) 'base_updated_at': baseUpdatedAt},
      );
    }
    await _avisarCambioPendiente();
    return {...?actual, ...datos, 'id': id};
  }

  Future<void> eliminar(int id) async {
    final actual = await dao.obtener(id);
    final necesitaSync = await dao.marcarEliminarPendiente(id);
    if (!necesitaSync) {
      if (actual != null) {
        await PendingOperationsDao.cancelarPorClientUuid(actual['client_uuid'] as String);
      }
      await SyncManager.instance.refreshPendingCount();
      return;
    }
    final clientUuid = actual!['client_uuid'] as String;
    await PendingOperationsDao.enqueue(
      entity: entity,
      operation: 'delete',
      localId: id,
      clientUuid: clientUuid,
      payload: {},
    );
    await _avisarCambioPendiente();
  }

  Future<void> _avisarCambioPendiente() async {
    if (ConnectivityService.instance.isOnline) {
      SyncManager.instance.syncAll();
    } else {
      await SyncManager.instance.refreshPendingCount();
    }
  }
}
