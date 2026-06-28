import 'dart:async';
import 'package:synchronized/synchronized.dart';
import '../db/local_dao.dart';
import '../db/daos/pending_operations_dao.dart';
import '../db/daos/sync_meta_dao.dart';
import 'api_service.dart';

class _FkRef {
  final String table;
  final String column;
  const _FkRef(this.table, this.column);
}

class _EntityInfo {
  final String table;
  final String listPath;
  final List<_FkRef> dependents;
  const _EntityInfo(this.table, this.listPath, [this.dependents = const []]);
}

/// Registro de las 7 entidades sincronizables: su tabla local, el endpoint
/// de listado, y qué otras tablas locales tienen una FK apuntando a su id
/// (para remapear ids temporales -> reales en cascada tras un create).
const _entities = {
  'eventos': _EntityInfo('eventos_local', '/eventos', [
    _FkRef('participantes_local', 'evento_id'),
    _FkRef('pagos_local', 'evento_id'),
  ]),
  'sedes': _EntityInfo('sedes_local', '/sedes', [
    _FkRef('eventos_local', 'sede_id'),
    _FkRef('salas_local', 'sede_id'),
  ]),
  'salas': _EntityInfo('salas_local', '/salas', [
    _FkRef('eventos_local', 'sala_id'),
  ]),
  'pagos': _EntityInfo('pagos_local', '/pagos'),
  'participantes': _EntityInfo('participantes_local', '/participantes'),
  'cotizaciones': _EntityInfo('cotizaciones_local', '/cotizaciones'),
  'recursos': _EntityInfo('recursos_local', '/recursos'),
};

/// Orquesta la sincronización bidireccional: sube la cola de operaciones
/// pendientes (resolviendo dependencias y remapeando ids temporales) y
/// luego descarga cambios del servidor (?since=) para refrescar el cache.
class SyncManager {
  SyncManager._();
  static final SyncManager instance = SyncManager._();

  final _lock = Lock();
  final _pendingCountController = StreamController<int>.broadcast();
  Stream<int> get pendingCountStream => _pendingCountController.stream;

  int lastKnownPendingCount = 0;

  Future<void> _emitPendingCount() async {
    lastKnownPendingCount = await PendingOperationsDao.contarPendientes();
    _pendingCountController.add(lastKnownPendingCount);
  }

  Future<void> syncAll() => _lock.synchronized(() async {
        await _pushPending();
        for (final entity in _entities.keys) {
          await _pullUpdates(entity);
        }
      });

  Future<void> refreshEntity(String entity) => _lock.synchronized(() async {
        await _pullUpdates(entity);
      });

  /// Refresca el contador de pendientes en la UI inmediatamente, sin
  /// intentar sincronizar (se usa al encolar una operación estando offline).
  Future<void> refreshPendingCount() => _emitPendingCount();

  Future<void> _pushPending() async {
    final completedUuids = <String>{};
    final ops = await PendingOperationsDao.getPendingOrdered();
    for (final op in ops) {
      if (op.dependsOnUuid != null && !completedUuids.contains(op.dependsOnUuid)) {
        if (await PendingOperationsDao.estaPendiente(op.dependsOnUuid!)) {
          continue; // su dependencia aún no se resolvió, se reintenta en la próxima pasada
        }
      }
      try {
        await PendingOperationsDao.markInProgress(op.id);
        final info = _entities[op.entity]!;
        final result = await _executeOperation(op);
        if (op.operation == 'create' && op.localId < 0) {
          final newId = result!['id'] as int;
          await LocalDao(info.table).remapId(op.localId, newId, result);
          for (final fk in info.dependents) {
            await LocalDao(fk.table).remapForeignKey(fk.column, op.localId, newId);
          }
          await PendingOperationsDao.remapId(op.localId, newId);
        } else if (op.operation == 'update' && result != null) {
          await LocalDao(info.table).upsertSincronizado(result);
        } else if (op.operation == 'delete') {
          await LocalDao(info.table).eliminarFisico(op.localId);
        }
        await PendingOperationsDao.markDone(op.id);
        completedUuids.add(op.clientUuid);
      } catch (e) {
        if (e is ApiException && e.statusCode == 409) {
          final servidor = e.body;
          if (servidor is Map) {
            await LocalDao(_entities[op.entity]!.table)
                .upsertSincronizado(Map<String, dynamic>.from(servidor));
          }
          await PendingOperationsDao.markDone(op.id); // server-wins: se descarta el cambio local
          completedUuids.add(op.clientUuid);
        } else if (e is NetworkException) {
          break; // se perdió la red de nuevo: el resto se reintenta en la próxima sync
        } else {
          await PendingOperationsDao.markError(op.id, e.toString());
        }
      }
    }
    await _emitPendingCount();
  }

  Future<Map<String, dynamic>?> _executeOperation(PendingOperation op) async {
    switch (op.entity) {
      case 'pagos':
        if (op.operation == 'create') {
          return Map<String, dynamic>.from(await ApiService.post('/pagos', op.payload));
        }
        if (op.operation == 'update') {
          return Map<String, dynamic>.from(
              await ApiService.put('/pagos/${op.localId}/estado', op.payload));
        }
        throw StateError('pagos no soporta delete offline');
      case 'cotizaciones':
        if (op.operation == 'create') {
          return Map<String, dynamic>.from(await ApiService.post('/cotizaciones', op.payload));
        }
        if (op.operation == 'update') {
          return Map<String, dynamic>.from(
              await ApiService.put('/cotizaciones/${op.localId}/estado', op.payload));
        }
        throw StateError('cotizaciones no soporta delete offline');
      case 'participantes':
        if (op.operation == 'create') {
          return Map<String, dynamic>.from(await ApiService.post('/participantes', op.payload));
        }
        if (op.operation == 'update') {
          return Map<String, dynamic>.from(
              await ApiService.patch('/participantes/${op.localId}/asistencia', op.payload));
        }
        if (op.operation == 'delete') {
          await ApiService.delete('/participantes/${op.localId}');
          return null;
        }
        throw StateError('operación inválida');
      default:
        final path = _entities[op.entity]!.listPath;
        if (op.operation == 'create') {
          return Map<String, dynamic>.from(await ApiService.post(path, op.payload));
        }
        if (op.operation == 'update') {
          return Map<String, dynamic>.from(
              await ApiService.put('$path/${op.localId}', op.payload));
        }
        if (op.operation == 'delete') {
          await ApiService.delete('$path/${op.localId}');
          return null;
        }
        throw StateError('operación inválida');
    }
  }

  /// Cada cuánto se fuerza una reconciliación completa (ignorando `?since=`)
  /// para detectar registros borrados en el servidor que el sync incremental
  /// no puede ver (un id ausente no genera ningún evento "delete").
  static const _intervaloFullRefresh = Duration(hours: 6);

  Future<void> _pullUpdates(String entity) async {
    final info = _entities[entity]!;
    try {
      final ultimoFull = await SyncMetaDao.getLastSyncedAt('${entity}__full');
      final necesitaFullRefresh = ultimoFull == null ||
          DateTime.now().difference(DateTime.parse(ultimoFull)) > _intervaloFullRefresh;
      final since =
          necesitaFullRefresh ? null : await SyncMetaDao.getLastSyncedAt(entity);
      final path = since != null ? '${info.listPath}?since=$since' : info.listPath;
      final data = await ApiService.get(path);
      final rows = (data is List) ? data : (data['data'] ?? []);
      final filas = (rows as List).map((r) => Map<String, dynamic>.from(r)).toList();
      final ahora = DateTime.now().toIso8601String();
      if (since == null) {
        await LocalDao(info.table).reconciliarCompleto(filas);
        await SyncMetaDao.setLastSyncedAt('${entity}__full', ahora);
      } else {
        for (final fila in filas) {
          await LocalDao(info.table).upsertSincronizado(fila);
        }
      }
      await SyncMetaDao.setLastSyncedAt(entity, ahora);
    } catch (_) {
      // sin red o error de servidor: se mantiene el cache local, se reintenta en la próxima sync
    }
  }
}
