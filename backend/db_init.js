const mysql = require('mysql2/promise');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

async function initDb() {
  console.log('🔄 Iniciando inicialización de la base de datos MySQL...');
  
  const host = process.env.DB_HOST || 'localhost';
  const port = parseInt(process.env.DB_PORT || '3306', 10);
  const user = process.env.DB_USER || 'root';
  const password = process.env.DB_PASSWORD || '123456';
  
  console.log(`Conectando a MySQL en ${host}:${port} como usuario '${user}'...`);
  
  let connection;
  try {
    connection = await mysql.createConnection({
      host,
      port,
      user,
      password,
      multipleStatements: true
    });
    console.log('✅ Conexión establecida con éxito con el servidor MySQL.');
  } catch (err) {
    console.error('❌ Error de conexión a MySQL:', err.message);
    console.error('Por favor, asegúrate de que MySQL esté ejecutándose y las credenciales en .env sean correctas.');
    process.exit(1);
  }

  try {
    // Dropear la base de datos si ya existe para asegurar un estado limpio y evitar duplicados del seed
    console.log('🧹 Limpiando base de datos existente (si aplica)...');
    await connection.query('DROP DATABASE IF EXISTS event_juliaca;');
    console.log('✅ Base de datos previa eliminada (si existía).');

    // Leer y ejecutar schema.sql
    const schemaPath = path.join(__dirname, 'db', 'schema.sql');
    if (!fs.existsSync(schemaPath)) {
      throw new Error(`No se encontró el archivo schema.sql en: ${schemaPath}`);
    }
    const schemaSql = fs.readFileSync(schemaPath, 'utf8');
    console.log('🏗️ Creando base de datos y tablas (schema.sql)...');
    await connection.query(schemaSql);
    console.log('✅ Estructura de base de datos y tablas creada exitosamente.');

    // Leer y ejecutar seed.sql
    const seedPath = path.join(__dirname, 'db', 'seed.sql');
    if (!fs.existsSync(seedPath)) {
      throw new Error(`No se encontró el archivo seed.sql en: ${seedPath}`);
    }
    const seedSql = fs.readFileSync(seedPath, 'utf8');
    console.log('🌱 Insertando datos de prueba iniciales (seed.sql)...');
    await connection.query(seedSql);
    console.log('✅ Datos de prueba insertados con éxito.');

    console.log('🎉 ¡Base de datos de Event Juliaca inicializada correctamente y lista para usar!');
  } catch (err) {
    console.error('❌ Error durante la inicialización de la base de datos:', err);
  } finally {
    if (connection) {
      await connection.end();
      console.log('🔌 Conexión con MySQL cerrada.');
    }
  }
}

initDb();
