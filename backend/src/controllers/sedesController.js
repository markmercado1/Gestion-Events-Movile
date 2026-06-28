const pool = require('../config/database');
const { buscarPorClientUuid, esDuplicadoClientUuid, verificarConflicto } = require('../utils/syncHelpers');
exports.listar = async (req, res, next) => {
  try {
    const { since } = req.query;
    let sql = 'SELECT * FROM sedes'; const vals = [];
    if (since) { sql += ' WHERE updated_at > ?'; vals.push(since); }
    sql += ' ORDER BY creado_en DESC';
    const [r] = await pool.query(sql, vals);
    res.json(r);
  } catch (err) { next(err); }
};
exports.crear = async (req, res, next) => {
  try {
    const { nombre, direccion, telefono, imagen_url, client_uuid } = req.body;
    const existente = await buscarPorClientUuid('sedes', client_uuid);
    if (existente) return res.status(200).json(existente);
    const [r] = await pool.query('INSERT INTO sedes (nombre,direccion,telefono,imagen_url,client_uuid) VALUES (?,?,?,?,?)', [nombre,direccion,telefono,imagen_url,client_uuid||null]);
    const [rows] = await pool.query('SELECT * FROM sedes WHERE id=?', [r.insertId]);
    res.status(201).json(rows[0]);
  } catch (err) {
    if (esDuplicadoClientUuid(err)) {
      const existente = await buscarPorClientUuid('sedes', req.body.client_uuid);
      if (existente) return res.status(200).json(existente);
    }
    next(err);
  }
};
exports.actualizar = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { nombre, direccion, telefono, imagen_url, base_updated_at } = req.body;
    const conflicto = await verificarConflicto('sedes', id, base_updated_at);
    if (conflicto) return res.status(409).json(conflicto);
    const [r] = await pool.query('UPDATE sedes SET nombre=?,direccion=?,telefono=?,imagen_url=? WHERE id=?', [nombre,direccion,telefono,imagen_url,id]);
    if (!r.affectedRows) return res.status(404).json({ error: 'Sede no encontrada' });
    const [rows] = await pool.query('SELECT * FROM sedes WHERE id=?', [id]);
    res.json(rows[0]);
  } catch (err) { next(err); }
};
exports.eliminar = async (req, res, next) => {
  try {
    await pool.query('DELETE FROM sedes WHERE id=?', [req.params.id]);
    res.json({ mensaje: 'Sede eliminada correctamente' });
  } catch (err) { next(err); }
};
