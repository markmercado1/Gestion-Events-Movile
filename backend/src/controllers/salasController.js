const pool = require('../config/database');
const { buscarPorClientUuid, esDuplicadoClientUuid, verificarConflicto } = require('../utils/syncHelpers');
exports.listar = async (req, res, next) => {
  try {
    const { sede_id, since } = req.query;
    const cond = []; const vals = [];
    if (sede_id) { cond.push('s.sede_id=?'); vals.push(sede_id); }
    if (since)   { cond.push('s.updated_at > ?'); vals.push(since); }
    let sql = 'SELECT s.*, se.nombre AS sede_nombre FROM salas s JOIN sedes se ON s.sede_id=se.id';
    if (cond.length) sql += ' WHERE ' + cond.join(' AND ');
    sql += ' ORDER BY s.sede_id,s.id';
    const [rows] = await pool.query(sql, vals);
    res.json(rows);
  } catch (err) { next(err); }
};
exports.crear = async (req, res, next) => {
  try {
    const { sede_id, nombre, capacidad, estado='disponible', client_uuid } = req.body;
    const existente = await buscarPorClientUuid('salas', client_uuid);
    if (existente) return res.status(200).json(existente);
    const [r] = await pool.query('INSERT INTO salas (sede_id,nombre,capacidad,estado,client_uuid) VALUES (?,?,?,?,?)', [sede_id,nombre,capacidad,estado,client_uuid||null]);
    const [rows] = await pool.query('SELECT * FROM salas WHERE id=?', [r.insertId]);
    res.status(201).json(rows[0]);
  } catch (err) {
    if (esDuplicadoClientUuid(err)) {
      const existente = await buscarPorClientUuid('salas', req.body.client_uuid);
      if (existente) return res.status(200).json(existente);
    }
    next(err);
  }
};
exports.actualizar = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { sede_id, nombre, capacidad, estado, base_updated_at } = req.body;
    const conflicto = await verificarConflicto('salas', id, base_updated_at);
    if (conflicto) return res.status(409).json(conflicto);
    const [r] = await pool.query('UPDATE salas SET sede_id=?,nombre=?,capacidad=?,estado=? WHERE id=?', [sede_id,nombre,capacidad,estado,id]);
    if (!r.affectedRows) return res.status(404).json({ error: 'Sala no encontrada' });
    const [rows] = await pool.query('SELECT * FROM salas WHERE id=?', [id]);
    res.json(rows[0]);
  } catch (err) { next(err); }
};
exports.eliminar = async (req, res, next) => {
  try {
    await pool.query('DELETE FROM salas WHERE id=?', [req.params.id]);
    res.json({ mensaje: 'Sala eliminada correctamente' });
  } catch (err) { next(err); }
};
