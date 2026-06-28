const pool = require('../config/database');
exports.listar = async (req, res, next) => {
  try {
    const { sala_id, fecha } = req.query;
    let sql = 'SELECT bh.*,e.nombre AS evento_nombre FROM bloques_horario bh LEFT JOIN eventos e ON bh.evento_id=e.id';
    const vals=[]; const cond=[];
    if (sala_id) { cond.push('bh.sala_id=?'); vals.push(sala_id); }
    if (fecha)   { cond.push('bh.fecha=?');   vals.push(fecha); }
    if (cond.length) sql += ' WHERE '+cond.join(' AND ');
    sql += ' ORDER BY bh.fecha,bh.hora_inicio';
    const [rows] = await pool.query(sql, vals);
    res.json(rows);
  } catch (err) { next(err); }
};
exports.crear = async (req, res, next) => {
  try {
    const { sala_id,fecha,hora_inicio,hora_fin,etiqueta,evento_id,tipo='evento' } = req.body;
    const [r] = await pool.query('INSERT INTO bloques_horario (sala_id,fecha,hora_inicio,hora_fin,etiqueta,evento_id,tipo) VALUES (?,?,?,?,?,?,?)', [sala_id,fecha,hora_inicio,hora_fin,etiqueta,evento_id,tipo]);
    const [rows] = await pool.query('SELECT * FROM bloques_horario WHERE id=?', [r.insertId]);
    res.status(201).json(rows[0]);
  } catch (err) { next(err); }
};
exports.eliminar = async (req, res, next) => {
  try {
    const [r] = await pool.query('DELETE FROM bloques_horario WHERE id=?', [req.params.id]);
    if (!r.affectedRows) return res.status(404).json({ error: 'Bloque no encontrado' });
    res.json({ mensaje: 'Bloque eliminado correctamente' });
  } catch (err) { next(err); }
};
