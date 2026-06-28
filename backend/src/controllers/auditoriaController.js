const pool = require('../config/database');

exports.listar = async (req, res, next) => {
  try {
    const { usuario_id, accion } = req.query;
    let sql = `SELECT a.*, u.email FROM auditoria a LEFT JOIN usuarios u ON a.usuario_id=u.id`;
    const vals=[]; const cond=[];
    if (usuario_id) { cond.push('a.usuario_id=?'); vals.push(usuario_id); }
    if (accion)     { cond.push('a.accion LIKE ?'); vals.push(`%${accion}%`); }
    if (cond.length) sql += ' WHERE ' + cond.join(' AND ');
    sql += ' ORDER BY a.creado_en DESC LIMIT 200';
    const [rows] = await pool.query(sql, vals);
    res.json(rows);
  } catch (err) { next(err); }
};
