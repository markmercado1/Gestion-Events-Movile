const mysql = require('mysql2/promise');
const env   = require('./env');
const pool  = mysql.createPool({
  host: env.db.host, port: env.db.port, user: env.db.user,
  password: env.db.password, database: env.db.name,
  waitForConnections: true, connectionLimit: 10, queueLimit: 0, charset: 'utf8mb4',
});
pool.getConnection()
  .then(conn => { console.log('✅ MySQL conectado correctamente'); conn.release(); })
  .catch(err  => { console.error('❌ Error MySQL:', err.message); process.exit(1); });
module.exports = pool;
