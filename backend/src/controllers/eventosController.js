const pool = require('../config/database');
const { buscarPorClientUuid, esDuplicadoClientUuid, verificarConflicto } = require('../utils/syncHelpers');
const BASE = `SELECT e.*,se.nombre AS sede_nombre,sa.nombre AS sala_nombre FROM eventos e LEFT JOIN sedes se ON e.sede_id=se.id LEFT JOIN salas sa ON e.sala_id=sa.id`;
exports.listar = async (req, res, next) => {
  try {
    const { estado, tipo, sede_id, page, limit, since } = req.query;
    let sql = BASE; const vals=[]; const cond=[];
    if (estado)  { cond.push('e.estado=?');  vals.push(estado); }
    if (tipo)    { cond.push('e.tipo=?');    vals.push(tipo); }
    if (sede_id) { cond.push('e.sede_id=?'); vals.push(sede_id); }
    if (since)   { cond.push('e.updated_at > ?'); vals.push(since); }
    if (cond.length) sql += ' WHERE '+cond.join(' AND ');
    sql += ' ORDER BY e.fecha DESC';
    // Paginación opcional (si no se envía page/limit, devuelve todos)
    if (page && limit) {
      const p = Math.max(1, parseInt(page));
      const l = Math.min(100, parseInt(limit));
      const offset = (p - 1) * l;
      const [[{ total }]] = await pool.query(`SELECT COUNT(*) AS total FROM eventos e${cond.length?' WHERE '+cond.join(' AND '):''}`, vals);
      const [rows] = await pool.query(sql + ' LIMIT ? OFFSET ?', [...vals, l, offset]);
      return res.json({ data: rows, total, page: p, totalPages: Math.ceil(total / l) });
    }
    const [rows] = await pool.query(sql, vals);
    res.json(rows);
  } catch (err) { next(err); }
};
exports.obtener = async (req, res, next) => {
  try {
    const [rows] = await pool.query(BASE+' WHERE e.id=?', [req.params.id]);
    if (!rows.length) return res.status(404).json({ error: 'Evento no encontrado' });
    res.json(rows[0]);
  } catch (err) { next(err); }
};
exports.crear = async (req, res, next) => {
  try {
    const { nombre,fecha,hora_inicio,hora_fin,tipo,precio=0,sede_id,sala_id,nombre_cliente,telefono_cliente,participantes=0,estado='proximo',descripcion,client_uuid } = req.body;
    const existente = await buscarPorClientUuid('eventos', client_uuid, BASE+' WHERE e.client_uuid=?');
    if (existente) return res.status(200).json(existente);
    const [r] = await pool.query(
      `INSERT INTO eventos (nombre,fecha,hora_inicio,hora_fin,tipo,precio,sede_id,sala_id,nombre_cliente,telefono_cliente,participantes,estado,descripcion,client_uuid) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)`,
      [nombre,fecha,hora_inicio,hora_fin,tipo,precio,sede_id,sala_id,nombre_cliente,telefono_cliente,participantes,estado,descripcion,client_uuid||null]
    );
    const [rows] = await pool.query(BASE+' WHERE e.id=?', [r.insertId]);
    res.status(201).json(rows[0]);
  } catch (err) {
    if (esDuplicadoClientUuid(err)) {
      const existente = await buscarPorClientUuid('eventos', req.body.client_uuid, BASE+' WHERE e.client_uuid=?');
      if (existente) return res.status(200).json(existente);
    }
    next(err);
  }
};
exports.actualizar = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { nombre,fecha,hora_inicio,hora_fin,tipo,precio,sede_id,sala_id,nombre_cliente,telefono_cliente,participantes,estado,descripcion,base_updated_at } = req.body;
    const conflicto = await verificarConflicto('eventos', id, base_updated_at, BASE+' WHERE e.id=?');
    if (conflicto) return res.status(409).json(conflicto);
    const [r] = await pool.query(
      `UPDATE eventos SET nombre=?,fecha=?,hora_inicio=?,hora_fin=?,tipo=?,precio=?,sede_id=?,sala_id=?,nombre_cliente=?,telefono_cliente=?,participantes=?,estado=?,descripcion=? WHERE id=?`,
      [nombre,fecha,hora_inicio,hora_fin,tipo,precio,sede_id,sala_id,nombre_cliente,telefono_cliente,participantes,estado,descripcion,id]
    );
    if (!r.affectedRows) return res.status(404).json({ error: 'Evento no encontrado' });
    const [rows] = await pool.query(BASE+' WHERE e.id=?', [id]);
    res.json(rows[0]);
  } catch (err) { next(err); }
};
exports.eliminar = async (req, res, next) => {
  try {
    const [r] = await pool.query('DELETE FROM eventos WHERE id=?', [req.params.id]);
    if (!r.affectedRows) return res.json({ mensaje: 'Evento eliminado correctamente' });
    res.json({ mensaje: 'Evento eliminado correctamente' });
  } catch (err) { next(err); }
};
