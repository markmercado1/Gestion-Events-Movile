const pool = require('../config/database');

exports.listar = async (req, res, next) => {
  try {
    const [rows] = await pool.query('SELECT id,email,rol,creado_en FROM usuarios ORDER BY creado_en DESC');
    res.json(rows);
  } catch (err) { next(err); }
};

exports.actualizarRol = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { rol } = req.body;
    if (!['admin','organizador','usuario'].includes(rol))
      return res.status(400).json({ error: 'Rol inválido. Use: admin, organizador o usuario' });
    const [r] = await pool.query('UPDATE usuarios SET rol=? WHERE id=?', [rol, id]);
    if (!r.affectedRows) return res.status(404).json({ error: 'Usuario no encontrado' });
    const [rows] = await pool.query('SELECT id,email,rol,creado_en FROM usuarios WHERE id=?', [id]);
    res.json(rows[0]);
  } catch (err) { next(err); }
};

exports.me = async (req, res, next) => {
  try {
    const { id } = req.usuario;
    const [rows] = await pool.query('SELECT id,email,rol,creado_en FROM usuarios WHERE id=?', [id]);
    if (!rows.length) return res.status(404).json({ error: 'Usuario no encontrado' });
    res.json(rows[0]);
  } catch (err) { next(err); }
};
