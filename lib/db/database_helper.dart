import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Columnas de control compartidas por todas las tablas `*_local`.
const controlColumns = '''
  client_uuid TEXT UNIQUE,
  updated_at TEXT,
  sync_status TEXT NOT NULL DEFAULT 'synced',
  deleted_local INTEGER NOT NULL DEFAULT 0
''';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'event_juliaca_local.db');
    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE eventos_local (
        id INTEGER PRIMARY KEY,
        nombre TEXT NOT NULL,
        fecha TEXT NOT NULL,
        hora_inicio TEXT NOT NULL,
        hora_fin TEXT NOT NULL,
        tipo TEXT NOT NULL,
        precio REAL DEFAULT 0,
        sede_id INTEGER,
        sala_id INTEGER,
        nombre_cliente TEXT,
        telefono_cliente TEXT,
        participantes INTEGER DEFAULT 0,
        estado TEXT DEFAULT 'proximo',
        descripcion TEXT,
        nombre_sede TEXT,
        $controlColumns
      )
    ''');
    await db.execute('''
      CREATE TABLE sedes_local (
        id INTEGER PRIMARY KEY,
        nombre TEXT NOT NULL,
        direccion TEXT,
        telefono TEXT,
        imagen_url TEXT,
        $controlColumns
      )
    ''');
    await db.execute('''
      CREATE TABLE salas_local (
        id INTEGER PRIMARY KEY,
        sede_id INTEGER NOT NULL,
        nombre TEXT NOT NULL,
        capacidad INTEGER,
        estado TEXT DEFAULT 'disponible',
        sede_nombre TEXT,
        $controlColumns
      )
    ''');
    await db.execute('''
      CREATE TABLE pagos_local (
        id INTEGER PRIMARY KEY,
        evento_id INTEGER NOT NULL,
        monto REAL NOT NULL,
        estado TEXT DEFAULT 'pendiente',
        url_comprobante TEXT,
        creado_en TEXT,
        evento_nombre TEXT,
        $controlColumns
      )
    ''');
    await db.execute('''
      CREATE TABLE participantes_local (
        id INTEGER PRIMARY KEY,
        evento_id INTEGER NOT NULL,
        nombre TEXT NOT NULL,
        email TEXT,
        telefono TEXT,
        asistio INTEGER DEFAULT 0,
        $controlColumns
      )
    ''');
    await db.execute('''
      CREATE TABLE cotizaciones_local (
        id INTEGER PRIMARY KEY,
        nombre TEXT NOT NULL,
        telefono TEXT NOT NULL,
        tipo_evento TEXT,
        fecha_evento TEXT,
        sede_preferida TEXT,
        mensaje TEXT,
        estado TEXT DEFAULT 'pendiente',
        creado_en TEXT,
        $controlColumns
      )
    ''');
    await db.execute('''
      CREATE TABLE recursos_local (
        id INTEGER PRIMARY KEY,
        nombre TEXT NOT NULL,
        categoria TEXT,
        cantidad INTEGER DEFAULT 1,
        estado TEXT DEFAULT 'disponible',
        descripcion TEXT,
        $controlColumns
      )
    ''');
    await db.execute('''
      CREATE TABLE pending_operations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entity TEXT NOT NULL,
        operation TEXT NOT NULL,
        local_id INTEGER NOT NULL,
        client_uuid TEXT NOT NULL,
        payload TEXT NOT NULL,
        depends_on_uuid TEXT,
        status TEXT NOT NULL DEFAULT 'pending',
        attempts INTEGER NOT NULL DEFAULT 0,
        last_error TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_pending_status ON pending_operations(status, created_at)');
    await db.execute('''
      CREATE TABLE sync_meta (
        entity TEXT PRIMARY KEY,
        last_synced_at TEXT
      )
    ''');
  }
}
