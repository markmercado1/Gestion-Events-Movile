import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';

class SyncMetaDao {
  static Future<Database> get _db async => DatabaseHelper.instance.database;

  static Future<String?> getLastSyncedAt(String entity) async {
    final db = await _db;
    final rows =
        await db.query('sync_meta', where: 'entity=?', whereArgs: [entity]);
    return rows.isEmpty ? null : rows.first['last_synced_at'] as String?;
  }

  static Future<void> setLastSyncedAt(String entity, String isoTimestamp) async {
    final db = await _db;
    await db.insert(
      'sync_meta',
      {'entity': entity, 'last_synced_at': isoTimestamp},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
