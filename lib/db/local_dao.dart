import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

/// DAO genérico de CRUD local para una tabla `<entidad>_local`.
/// Todas las entidades de dominio (eventos, sedes, salas, pagos,
/// participantes, cotizaciones, recursos) comparten la misma forma:
/// columnas propias + client_uuid/updated_at/sync_status/deleted_local.
class LocalDao {
  final String table;
  LocalDao(this.table);

  Future<Database> get _db async => DatabaseHelper.instance.database;

  static final Map<String, Set<String>> _columnsCache = {};

  /// El servidor puede devolver columnas que no existen en la tabla local
  /// (ej. joins como sede_nombre/sala_nombre, o creado_en). Se filtran para
  /// no romper el INSERT/UPDATE de sqflite.
  Future<Map<String, dynamic>> _soloColumnasValidas(Map<String, dynamic> data) async {
    var columnas = _columnsCache[table];
    if (columnas == null) {
      final db = await _db;
      final info = await db.rawQuery('PRAGMA table_info($table)');
      columnas = info.map((c) => c['name'] as String).toSet();
      _columnsCache[table] = columnas;
    }
    return {
      for (final entry in data.entries)
        if (columnas.contains(entry.key)) entry.key: entry.value
    };
  }

  int nextTempId() => -(DateTime.now().microsecondsSinceEpoch);

  Future<List<Map<String, dynamic>>> listar(
      {String? where, List<Object?>? whereArgs, String? orderBy}) async {
    final db = await _db;
    final cond = where != null ? '($where) AND deleted_local=0' : 'deleted_local=0';
    return db.query(table, where: cond, whereArgs: whereArgs, orderBy: orderBy);
  }

  Future<Map<String, dynamic>?> obtener(int id) async {
    final db = await _db;
    final rows = await db.query(table, where: 'id=?', whereArgs: [id]);
    return rows.isEmpty ? null : rows.first;
  }

  /// Inserta o actualiza una fila proveniente del servidor (ya sincronizada).
  Future<void> upsertSincronizado(Map<String, dynamic> data) async {
    final db = await _db;
    final row = {
      ...await _soloColumnasValidas(data),
      'sync_status': 'synced',
      'deleted_local': 0,
    };
    await db.insert(table, row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Crea una fila offline con id temporal negativo, encolada para sync.
  Future<int> crearPendiente(
      Map<String, dynamic> datosDominio, String clientUuid) async {
    final db = await _db;
    final id = nextTempId();
    await db.insert(table, {
      ...datosDominio,
      'id': id,
      'client_uuid': clientUuid,
      'sync_status': 'pending_create',
      'deleted_local': 0,
    });
    return id;
  }

  /// Aplica una edición local. Si la fila aún no fue creada en el servidor
  /// (id negativo), se mantiene como pending_create; si ya estaba sincronizada
  /// pasa a pending_update.
  Future<void> actualizarPendiente(
      int id, Map<String, dynamic> datosDominio) async {
    final db = await _db;
    final actual = await obtener(id);
    final estadoActual = actual?['sync_status'] as String?;
    final nuevoEstado =
        estadoActual == 'pending_create' ? 'pending_create' : 'pending_update';
    await db.update(table, {...datosDominio, 'sync_status': nuevoEstado},
        where: 'id=?', whereArgs: [id]);
  }

  /// Marca eliminación local. Si la fila nunca llegó a sincronizarse
  /// (id negativo, sin operación de create confirmada), se borra de inmediato.
  Future<bool> marcarEliminarPendiente(int id) async {
    final db = await _db;
    final actual = await obtener(id);
    if (actual == null) return false;
    if (id < 0 && actual['sync_status'] == 'pending_create') {
      await db.delete(table, where: 'id=?', whereArgs: [id]);
      return false; // no quedó nada por sincronizar (se cancela localmente)
    }
    await db.update(table, {'deleted_local': 1, 'sync_status': 'pending_delete'},
        where: 'id=?', whereArgs: [id]);
    return true;
  }

  /// Reemplaza el id temporal negativo por el id real del servidor,
  /// fusionando los datos definitivos devueltos por el backend.
  Future<void> remapId(
      int oldId, int newId, Map<String, dynamic> serverData) async {
    final db = await _db;
    final filtrado = await _soloColumnasValidas(serverData);
    await db.transaction((txn) async {
      await txn.delete(table, where: 'id=?', whereArgs: [oldId]);
      await txn.insert(
        table,
        {...filtrado, 'id': newId, 'sync_status': 'synced', 'deleted_local': 0},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<void> eliminarFisico(int id) async {
    final db = await _db;
    await db.delete(table, where: 'id=?', whereArgs: [id]);
  }

  /// Actualiza toda FK de [columnaFk] que apunte a [oldId] para que apunte a [newId].
  /// Usado cuando una entidad dependiente (ej. participante) referenciaba el id
  /// temporal de una entidad padre (ej. evento) recién confirmada por el servidor.
  Future<void> remapForeignKey(String columnaFk, int oldId, int newId) async {
    final db = await _db;
    await db.update(table, {columnaFk: newId},
        where: '$columnaFk=?', whereArgs: [oldId]);
  }

  /// Reconcilia el set completo traído del servidor: upsert de todo lo recibido
  /// y borrado de filas sincronizadas que ya no existen remotamente.
  Future<void> reconciliarCompleto(List<Map<String, dynamic>> filasServidor) async {
    final db = await _db;
    final idsServidor = filasServidor.map((f) => f['id']).toSet();
    // Se filtran las columnas ANTES de abrir la transacción: _soloColumnasValidas
    // usa `db` (no `txn`), y llamarlo dentro de la transacción provoca un
    // deadlock porque la transacción ya tiene el lock de la base.
    final filasFiltradas = [
      for (final fila in filasServidor) await _soloColumnasValidas(fila)
    ];
    await db.transaction((txn) async {
      for (final filtrado in filasFiltradas) {
        await txn.insert(table, {...filtrado, 'sync_status': 'synced', 'deleted_local': 0},
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      final sincronizadas = await txn.query(table, where: "sync_status='synced'");
      for (final fila in sincronizadas) {
        if (!idsServidor.contains(fila['id'])) {
          await txn.delete(table, where: 'id=?', whereArgs: [fila['id']]);
        }
      }
    });
  }
}
