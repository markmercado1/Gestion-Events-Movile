const pool = require('../config/database');

// Busca una fila ya procesada con ese client_uuid (idempotencia ante reintentos offline).
async function buscarPorClientUuid(tabla, clientUuid, selectSql) {
  if (!clientUuid) return null;
  const sql = selectSql || `SELECT * FROM ${tabla} WHERE client_uuid=?`;
  const [rows] = await pool.query(sql, [clientUuid]);
  return rows.length ? rows[0] : null;
}

// Detecta el choque contra la constraint UNIQUE(client_uuid) (red de seguridad ante carreras).
function esDuplicadoClientUuid(err) {
  return !!(err && err.code === 'ER_DUP_ENTRY' && /client_uuid/.test(err.message || ''));
}

// Server-wins: si el cliente editaba una versión más vieja que la actual en BD, hay conflicto.
async function verificarConflicto(tabla, id, baseUpdatedAt, selectSql) {
  if (!baseUpdatedAt) return null;
  const sql = selectSql || `SELECT * FROM ${tabla} WHERE id=?`;
  const [rows] = await pool.query(sql, [id]);
  if (!rows.length) return null;
  const actual = rows[0];
  if (actual.updated_at && new Date(baseUpdatedAt).getTime() < new Date(actual.updated_at).getTime()) {
    return actual;
  }
  return null;
}

module.exports = { buscarPorClientUuid, esDuplicadoClientUuid, verificarConflicto };
