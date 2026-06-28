const pool = require('../config/database');
const { buscarPorClientUuid, esDuplicadoClientUuid, verificarConflicto } = require('../utils/syncHelpers');
const BASE = 'SELECT p.*,e.nombre AS evento_nombre FROM pagos p JOIN eventos e ON p.evento_id=e.id';
exports.listar = async (req, res, next) => {
  try {
    const { since } = req.query;
    let sql = BASE; const vals = [];
    if (since) { sql += ' WHERE p.updated_at > ?'; vals.push(since); }
    sql += ' ORDER BY p.creado_en DESC';
    const [rows] = await pool.query(sql, vals);
    res.json(rows);
  } catch (err) { next(err); }
};
exports.crear = async (req, res, next) => {
  try {
    const { evento_id, monto, url_comprobante, client_uuid } = req.body;
    const existente = await buscarPorClientUuid('pagos', client_uuid, BASE+' WHERE p.client_uuid=?');
    if (existente) return res.status(200).json(existente);
    const [r] = await pool.query('INSERT INTO pagos (evento_id,monto,url_comprobante,client_uuid) VALUES (?,?,?,?)', [evento_id,monto,url_comprobante,client_uuid||null]);
    const [rows] = await pool.query(BASE+' WHERE p.id=?', [r.insertId]);
    res.status(201).json(rows[0]);
  } catch (err) {
    if (esDuplicadoClientUuid(err)) {
      const existente = await buscarPorClientUuid('pagos', req.body.client_uuid, BASE+' WHERE p.client_uuid=?');
      if (existente) return res.status(200).json(existente);
    }
    next(err);
  }
};
exports.actualizarEstado = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { estado, base_updated_at } = req.body;
    const validos = ['pendiente','verificado','rechazado'];
    if (!validos.includes(estado)) return res.status(400).json({ error: 'Estado debe ser: '+validos.join(', ') });
    const conflicto = await verificarConflicto('pagos', id, base_updated_at, BASE+' WHERE p.id=?');
    if (conflicto) return res.status(409).json(conflicto);
    const [r] = await pool.query('UPDATE pagos SET estado=? WHERE id=?', [estado,id]);
    if (!r.affectedRows) return res.status(404).json({ error: 'Pago no encontrado' });
    const [rows] = await pool.query(BASE+' WHERE p.id=?', [id]);
    res.json(rows[0]);
  } catch (err) { next(err); }
};
