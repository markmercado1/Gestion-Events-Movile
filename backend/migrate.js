// Script de migración seguro para MySQL 8 (Event Juliaca v2.0)
require('dotenv').config();
const mysql = require('mysql2/promise');

async function migrate() {
  const conn = await mysql.createConnection({
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT || '3306'),
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'event_juliaca',
    multipleStatements: true,
  });

  console.log('✅ Conectado a MySQL. Aplicando migraciones...\n');

  // 1. Agregar columna asistio si no existe
  const [cols] = await conn.query(`SHOW COLUMNS FROM participantes LIKE 'asistio'`);
  if (cols.length === 0) {
    await conn.query(`ALTER TABLE participantes ADD COLUMN asistio BOOLEAN DEFAULT FALSE`);
    console.log('✅ [1/6] Columna participantes.asistio agregada');
  } else {
    console.log('⏭️  [1/6] participantes.asistio ya existe, omitiendo');
  }

  // 2. Modificar rol en usuarios
  await conn.query(`ALTER TABLE usuarios MODIFY COLUMN rol ENUM('admin','organizador','usuario') DEFAULT 'usuario'`);
  console.log('✅ [2/6] Enum rol actualizado (admin/organizador/usuario)');

  // 3. Crear tabla actividades
  await conn.query(`CREATE TABLE IF NOT EXISTS actividades (
    id INT AUTO_INCREMENT PRIMARY KEY,
    evento_id INT NOT NULL,
    nombre VARCHAR(255) NOT NULL,
    descripcion TEXT,
    hora_inicio TIME NOT NULL,
    hora_fin TIME NOT NULL,
    responsable VARCHAR(255),
    creado_en DATETIME DEFAULT NOW(),
    FOREIGN KEY (evento_id) REFERENCES eventos(id) ON DELETE CASCADE
  )`);
  console.log('✅ [3/6] Tabla actividades OK');

  // 4. Crear tabla recursos
  await conn.query(`CREATE TABLE IF NOT EXISTS recursos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(255) NOT NULL,
    categoria VARCHAR(100),
    cantidad INT DEFAULT 1,
    estado ENUM('disponible','en_uso','mantenimiento') DEFAULT 'disponible',
    descripcion TEXT,
    creado_en DATETIME DEFAULT NOW()
  )`);
  console.log('✅ [4/6] Tabla recursos OK');

  // 5. Crear tabla evento_recursos
  await conn.query(`CREATE TABLE IF NOT EXISTS evento_recursos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    evento_id INT NOT NULL,
    recurso_id INT NOT NULL,
    cantidad_asignada INT DEFAULT 1,
    FOREIGN KEY (evento_id) REFERENCES eventos(id) ON DELETE CASCADE,
    FOREIGN KEY (recurso_id) REFERENCES recursos(id) ON DELETE CASCADE
  )`);
  console.log('✅ [5/6] Tabla evento_recursos OK');

  // 6. Crear tabla auditoria
  await conn.query(`CREATE TABLE IF NOT EXISTS auditoria (
    id INT AUTO_INCREMENT PRIMARY KEY,
    usuario_id INT,
    accion VARCHAR(255) NOT NULL,
    entidad VARCHAR(100),
    entidad_id INT,
    ip VARCHAR(45),
    creado_en DATETIME DEFAULT NOW(),
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE SET NULL
  )`);
  console.log('✅ [6/6] Tabla auditoria OK');

  // 7. Índices de rendimiento (ignorar si ya existen)
  const indices = [
    ['idx_eventos_fecha',       'CREATE INDEX idx_eventos_fecha       ON eventos(fecha)'],
    ['idx_eventos_estado',      'CREATE INDEX idx_eventos_estado      ON eventos(estado)'],
    ['idx_eventos_tipo',        'CREATE INDEX idx_eventos_tipo        ON eventos(tipo)'],
    ['idx_eventos_sede',        'CREATE INDEX idx_eventos_sede        ON eventos(sede_id)'],
    ['idx_participantes_evento','CREATE INDEX idx_participantes_evento ON participantes(evento_id)'],
  ];
  for (const [name, sql] of indices) {
    try {
      await conn.query(sql);
      console.log(`✅ Índice ${name} creado`);
    } catch (e) {
      if (e.code === 'ER_DUP_KEYNAME') {
        console.log(`⏭️  Índice ${name} ya existe`);
      } else {
        throw e;
      }
    }
  }

  // 8. Agregar client_uuid + updated_at a tablas de dominio (soporte offline/sync)
  const tablasSync = ['sedes', 'salas', 'eventos', 'pagos', 'participantes', 'cotizaciones', 'recursos'];
  for (const tabla of tablasSync) {
    const [colUuid] = await conn.query(`SHOW COLUMNS FROM ${tabla} LIKE 'client_uuid'`);
    if (colUuid.length === 0) {
      await conn.query(`ALTER TABLE ${tabla} ADD COLUMN client_uuid CHAR(36) NULL UNIQUE`);
    }
    const [colUpd] = await conn.query(`SHOW COLUMNS FROM ${tabla} LIKE 'updated_at'`);
    if (colUpd.length === 0) {
      await conn.query(`ALTER TABLE ${tabla} ADD COLUMN updated_at DATETIME NULL DEFAULT NOW() ON UPDATE CURRENT_TIMESTAMP`);
    }
    try {
      await conn.query(`CREATE INDEX idx_${tabla}_updated_at ON ${tabla}(updated_at)`);
    } catch (e) {
      if (e.code !== 'ER_DUP_KEYNAME') throw e;
    }
  }
  console.log('✅ [8/8] client_uuid + updated_at agregados a tablas de dominio');

  await conn.end();
  console.log('\n🎉 ¡Migraciones aplicadas exitosamente!');
}

migrate().catch(err => {
  console.error('❌ Error en migración:', err.message);
  process.exit(1);
});
