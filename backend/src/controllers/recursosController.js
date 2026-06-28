const pool = require('../config/database');
const { buscarPorClientUuid, esDuplicadoClientUuid, verificarConflicto } = require('../utils/syncHelpers');

exports.listar = async (req, res, next) => {
  try {
    const { estado, categoria, since } = req.query;
    let sql = 'SELECT * FROM recursos'; const vals=[]; const cond=[];
    if (estado)    { cond.push('estado=?');    vals.push(estado); }
    if (categoria) { cond.push('categoria=?'); vals.push(categoria); }
    if (since)     { cond.push('updated_at > ?'); vals.push(since); }
    if (cond.length) sql += ' WHERE ' + cond.join(' AND ');
    sql += ' ORDER BY nombre ASC';
    const [rows] = await pool.query(sql, vals);
    res.json(rows);
  } catch (err) { next(err); }
};

exports.crear = async (req, res, next) => {
  try {
    const { nombre, categoria, cantidad=1, estado='disponible', descripcion, client_uuid } = req.body;
    const existente = await buscarPorClientUuid('recursos', client_uuid);
    if (existente) return res.status(200).json(existente);
    const [r] = await pool.query(
      'INSERT INTO recursos (nombre,categoria,cantidad,estado,descripcion,client_uuid) VALUES (?,?,?,?,?,?)',
      [nombre, categoria||null, cantidad, estado, descripcion||null, client_uuid||null]
    );
    const [rows] = await pool.query('SELECT * FROM recursos WHERE id=?', [r.insertId]);
    res.status(201).json(rows[0]);
  } catch (err) {
    if (esDuplicadoClientUuid(err)) {
      const existente = await buscarPorClientUuid('recursos', req.body.client_uuid);
      if (existente) return res.status(200).json(existente);
    }
    next(err);
  }
};

exports.actualizar = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { nombre, categoria, cantidad, estado, descripcion, base_updated_at } = req.body;
    const conflicto = await verificarConflicto('recursos', id, base_updated_at);
    if (conflicto) return res.status(409).json(conflicto);
    const [r] = await pool.query(
      'UPDATE recursos SET nombre=?,categoria=?,cantidad=?,estado=?,descripcion=? WHERE id=?',
      [nombre, categoria||null, cantidad, estado, descripcion||null, id]
    );
    if (!r.affectedRows) return res.status(404).json({ error: 'Recurso no encontrado' });
    const [rows] = await pool.query('SELECT * FROM recursos WHERE id=?', [id]);
    res.json(rows[0]);
  } catch (err) { next(err); }
};

exports.eliminar = async (req, res, next) => {
  try {
    await pool.query('DELETE FROM recursos WHERE id=?', [req.params.id]);
    res.json({ mensaje: 'Recurso eliminado correctamente' });
  } catch (err) { next(err); }
};

exports.asignar = async (req, res, next) => {
  try {
    const { evento_id, recurso_id, cantidad_asignada=1 } = req.body;
    // Verificar que el recurso esté disponible
    const [recursos] = await pool.query('SELECT * FROM recursos WHERE id=?', [recurso_id]);
    if (!recursos.length) return res.status(404).json({ error: 'Recurso no encontrado' });
    if (recursos[0].estado !== 'disponible') return res.status(409).json({ error: 'El recurso no está disponible' });
    // Insertar en evento_recursos
    const [r] = await pool.query(
      'INSERT INTO evento_recursos (evento_id,recurso_id,cantidad_asignada) VALUES (?,?,?)',
      [evento_id, recurso_id, cantidad_asignada]
    );
    // Actualizar estado del recurso a 'en_uso'
    await pool.query('UPDATE recursos SET estado=? WHERE id=?', ['en_uso', recurso_id]);
    res.status(201).json({ id: r.insertId, evento_id, recurso_id, cantidad_asignada, mensaje: 'Recurso asignado correctamente' });
  } catch (err) { next(err); }
};

exports.listarPorEvento = async (req, res, next) => {
  try {
    const { evento_id } = req.params;
    const [rows] = await pool.query(
      `SELECT er.*, r.nombre, r.categoria, r.estado, r.descripcion
       FROM evento_recursos er
       JOIN recursos r ON er.recurso_id = r.id
       WHERE er.evento_id=?`,
      [evento_id]
    );
    res.json(rows);
  } catch (err) { next(err); }
};
