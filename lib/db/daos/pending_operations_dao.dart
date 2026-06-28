import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';

String encodeJson(Map<String, dynamic> data) => jsonEncode(data);

Map<String, dynamic> decodeJson(String s) =>
    s.isEmpty ? {} : Map<String, dynamic>.from(jsonDecode(s));

class PendingOperation {
  final int id;
  final String entity;
  final String operation; // create|update|delete
  final int localId;
  final String clientUuid;
  final Map<String, dynamic> payload;
  final String? dependsOnUuid;
  final String status; // pending|in_progress|error|done
  final int attempts;
  final String? lastError;

  PendingOperation({
    required this.id,
    required this.entity,
    required this.operation,
    required this.localId,
    required this.clientUuid,
    required this.payload,
    this.dependsOnUuid,
    required this.status,
    required this.attempts,
    this.lastError,
  });
}

class PendingOperationsDao {
  static Future<Database> get _db async => DatabaseHelper.instance.database;

  /// Tope de reintentos automáticos: pasado este número, una operación en
  /// error sólo se reintenta si el usuario lo pide explícitamente.
  static const maxAutoAttempts = 5;

  /// Backoff exponencial simple (capado a 10 min) entre reintentos automáticos.
  static Duration _backoffPara(int attempts) =>
      Duration(seconds: (attempts * attempts * 10).clamp(10, 600));

  static Future<int> enqueue({
    required String entity,
    required String operation,
    required int localId,
    required String clientUuid,
    required Map<String, dynamic> payload,
    String? dependsOnUuid,
  }) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();
    return db.insert('pending_operations', {
      'entity': entity,
      'operation': operation,
      'local_id': localId,
      'client_uuid': clientUuid,
      'payload': encodeJson(payload),
      'depends_on_uuid': dependsOnUuid,
      'status': 'pending',
      'attempts': 0,
      'created_at': now,
      'updated_at': now,
    });
  }

  /// Operaciones listas para que la sync AUTOMÁTICA las procese: excluye las
  /// que ya agotaron el tope de reintentos automáticos, y las que están
  /// dentro de su ventana de backoff tras el último error.
  static Future<List<PendingOperation>> getPendingOrdered() async {
    final db = await _db;
    final rows = await db.query(
      'pending_operations',
      where: "status IN ('pending','error')",
      orderBy: 'created_at ASC',
    );
    final ahora = DateTime.now();
    final listas = rows.where((row) {
      if (row['status'] != 'error') return true;
      final attempts = row['attempts'] as int;
      if (attempts >= maxAutoAttempts) return false; // requiere reintento manual
      final ultimoIntento = DateTime.tryParse(row['updated_at'] as String);
      if (ultimoIntento == null) return true;
      return ahora.difference(ultimoIntento) >= _backoffPara(attempts);
    });
    final ops = listas.map(_fromRow).toList();
    final doneUuids = (await db.query('pending_operations', where: "status='done'"))
        .map((r) => r['client_uuid'] as String)
        .toSet();
    // Orden topológico simple: las que no dependen de nada (o cuya dependencia
    // ya está 'done') van primero, sin reordenar dentro de cada grupo.
    ops.sort((a, b) {
      final aListo = a.dependsOnUuid == null || doneUuids.contains(a.dependsOnUuid);
      final bListo = b.dependsOnUuid == null || doneUuids.contains(b.dependsOnUuid);
      if (aListo == bListo) return 0;
      return aListo ? -1 : 1;
    });
    return ops;
  }

  static Future<List<PendingOperation>> getErrores() async {
    final db = await _db;
    final rows = await db.query('pending_operations', where: "status='error'");
    return rows.map(_fromRow).toList();
  }

  static Future<int> contarPendientes() async {
    final db = await _db;
    final r = await db.rawQuery(
        "SELECT COUNT(*) as c FROM pending_operations WHERE status IN ('pending','error','in_progress')");
    return (r.first['c'] as int?) ?? 0;
  }

  static Future<void> markInProgress(int id) async {
    final db = await _db;
    await db.update('pending_operations', {'status': 'in_progress'},
        where: 'id=?', whereArgs: [id]);
  }

  static Future<void> markDone(int id) async {
    final db = await _db;
    await db.update('pending_operations', {'status': 'done'},
        where: 'id=?', whereArgs: [id]);
  }

  static Future<void> markError(int id, String error) async {
    final db = await _db;
    final rows = await db.query('pending_operations', where: 'id=?', whereArgs: [id]);
    final attempts = rows.isNotEmpty ? (rows.first['attempts'] as int? ?? 0) + 1 : 1;
    await db.update(
      'pending_operations',
      {
        'status': 'error',
        'attempts': attempts,
        'last_error': error,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id=?',
      whereArgs: [id],
    );
  }

  /// Al arranque de la app no puede existir legítimamente ninguna operación
  /// 'in_progress': si quedó así es porque el proceso murió a mitad de un push
  /// (kill, crash, force-stop). Sin este reset queda huérfana para siempre,
  /// ya que getPendingOrdered() sólo recoge 'pending'/'error'.
  static Future<void> resetEnCursoHuerfanas() async {
    final db = await _db;
    await db.update('pending_operations', {'status': 'pending'},
        where: "status='in_progress'");
  }

  static Future<void> markPending(int id) async {
    final db = await _db;
    await db.update('pending_operations', {'status': 'pending'},
        where: 'id=?', whereArgs: [id]);
  }

  /// Reintento manual desde la UI: ignora el tope de intentos automáticos y
  /// el backoff, reseteando el contador para darle una oportunidad limpia.
  static Future<void> reintentarManual(int id) async {
    final db = await _db;
    await db.update(
      'pending_operations',
      {'status': 'pending', 'attempts': 0, 'last_error': null},
      where: 'id=?',
      whereArgs: [id],
    );
  }

  static Future<void> updatePayload(int id, Map<String, dynamic> payload) async {
    final db = await _db;
    await db.update('pending_operations', {'payload': encodeJson(payload)},
        where: 'id=?', whereArgs: [id]);
  }

  /// Fusiona campos nuevos en el payload de una operación 'create' aún
  /// pendiente (evita encolar un update sobre un id temporal sin sincronizar).
  static Future<void> mergePayloadByClientUuid(
      String clientUuid, Map<String, dynamic> nuevosCampos) async {
    final db = await _db;
    final rows = await db.query('pending_operations',
        where: "client_uuid=? AND operation='create' AND status IN ('pending','error')",
        whereArgs: [clientUuid]);
    if (rows.isEmpty) return;
    final row = rows.first;
    final payload = decodeJson(row['payload'] as String)..addAll(nuevosCampos);
    await db.update('pending_operations', {'payload': encodeJson(payload)},
        where: 'id=?', whereArgs: [row['id']]);
  }

  /// Cancela una operación 'create' pendiente (la fila local se eliminó
  /// antes de llegar a sincronizarse, ya no hay nada que mandar al servidor).
  static Future<void> cancelarPorClientUuid(String clientUuid) async {
    final db = await _db;
    await db.delete('pending_operations',
        where: "client_uuid=? AND status IN ('pending','error')",
        whereArgs: [clientUuid]);
  }

  /// true si la operación con ese client_uuid existe y todavía no terminó.
  static Future<bool> estaPendiente(String clientUuid) async {
    final db = await _db;
    final rows = await db.query('pending_operations',
        where: "client_uuid=? AND status!='done'", whereArgs: [clientUuid]);
    return rows.isNotEmpty;
  }

  /// Reemplaza, en todas las operaciones encoladas, cualquier referencia al
  /// id temporal [oldId] (en local_id o en cualquier campo del payload) por
  /// el id real [newId] confirmado por el servidor.
  static Future<void> remapId(int oldId, int newId) async {
    final db = await _db;
    final rows = await db.query('pending_operations',
        where: "status IN ('pending','error','in_progress')");
    for (final row in rows) {
      var changed = false;
      var localId = row['local_id'] as int;
      if (localId == oldId) {
        localId = newId;
        changed = true;
      }
      final payload = decodeJson(row['payload'] as String);
      final nuevoPayload = <String, dynamic>{};
      payload.forEach((k, v) {
        if (v == oldId) {
          nuevoPayload[k] = newId;
          changed = true;
        } else {
          nuevoPayload[k] = v;
        }
      });
      if (changed) {
        await db.update(
          'pending_operations',
          {'local_id': localId, 'payload': encodeJson(nuevoPayload)},
          where: 'id=?',
          whereArgs: [row['id']],
        );
      }
    }
  }

  /// Operaciones encoladas que dependían del client_uuid recién confirmado,
  /// para reemplazar el id temporal embebido en su payload.
  static Future<List<PendingOperation>> getDependientesDe(String clientUuid) async {
    final db = await _db;
    final rows = await db.query('pending_operations',
        where: 'depends_on_uuid=?', whereArgs: [clientUuid]);
    return rows.map(_fromRow).toList();
  }

  static PendingOperation _fromRow(Map<String, dynamic> row) {
    return PendingOperation(
      id: row['id'] as int,
      entity: row['entity'] as String,
      operation: row['operation'] as String,
      localId: row['local_id'] as int,
      clientUuid: row['client_uuid'] as String,
      payload: decodeJson(row['payload'] as String),
      dependsOnUuid: row['depends_on_uuid'] as String?,
      status: row['status'] as String,
      attempts: row['attempts'] as int,
      lastError: row['last_error'] as String?,
    );
  }
}
