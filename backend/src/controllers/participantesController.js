const pool = require('../config/database');
const { confirmarRegistroParticipante } = require('../services/mailer');
const { buscarPorClientUuid, esDuplicadoClientUuid, verificarConflicto } = require('../utils/syncHelpers');

exports.listar = async (req, res, next) => {
  try {
    const { evento_id, since } = req.query;
    if (!evento_id) return res.status(400).json({ error: "evento_id requerido" });
    const cond = ['evento_id=?']; const vals = [evento_id];
    if (since) { cond.push('updated_at > ?'); vals.push(since); }
    const [rows] = await pool.query(`SELECT * FROM participantes WHERE ${cond.join(' AND ')}`, vals);
    res.json(rows);
  } catch (err) { next(err); }
};

exports.crear = async (req, res, next) => {
  try {
    const { evento_id, nombre, email, telefono, client_uuid } = req.body;
    const existente = await buscarPorClientUuid('participantes', client_uuid);
    if (existente) return res.status(200).json(existente);
    const [r] = await pool.query(
      'INSERT INTO participantes (evento_id, nombre, email, telefono, client_uuid) VALUES (?, ?, ?, ?, ?)',
      [evento_id, nombre, email, telefono, client_uuid||null]
    );
    await pool.query('UPDATE eventos SET participantes = participantes + 1 WHERE id=?', [evento_id]);
    const [rows] = await pool.query('SELECT * FROM participantes WHERE id=?', [r.insertId]);
    const participante = rows[0];

    if (participante.email) {
      const [[evento]] = await pool.query(
        'SELECT e.nombre, e.fecha, e.hora_inicio, e.hora_fin, s.nombre AS sede FROM eventos e LEFT JOIN sedes s ON e.sede_id=s.id WHERE e.id=?',
        [evento_id]
      );
      try {
        await confirmarRegistroParticipante({
          nombre:      participante.nombre,
          email:       participante.email,
          eventoNombre: evento.nombre,
          fechaEvento:  evento.fecha,
          horaInicio:   evento.hora_inicio,
          horaFin:      evento.hora_fin,
          sede:         evento.sede,
        });
      } catch (mailErr) {
        console.error('Email de confirmación falló:', mailErr.message);
      }
    }

    res.status(201).json(participante);
  } catch (err) {
    if (esDuplicadoClientUuid(err)) {
      const existente = await buscarPorClientUuid('participantes', req.body.client_uuid);
      if (existente) return res.status(200).json(existente);
    }
    next(err);
  }
};

exports.crearLote = async (req, res, next) => {
  try {
    const { evento_id, participantes } = req.body;
    if (!participantes || !Array.isArray(participantes) || participantes.length === 0) {
      return res.status(400).json({ error: "No hay participantes para insertar" });
    }
    const values = participantes.map(p => [evento_id, p.nombre, p.email || null, p.telefono || null]);
    await pool.query('INSERT INTO participantes (evento_id, nombre, email, telefono) VALUES ?', [values]);
    await pool.query('UPDATE eventos SET participantes = participantes + ? WHERE id=?', [participantes.length, evento_id]);
    res.status(201).json({ mensaje: `${participantes.length} participantes agregados` });
  } catch (err) { next(err); }
};

exports.eliminar = async (req, res, next) => {
  try {
    const { id } = req.params;
    const [part] = await pool.query('SELECT evento_id FROM participantes WHERE id=?', [id]);
    if (!part.length) return res.json({ mensaje: 'Eliminado correctamente' });

    await pool.query('DELETE FROM participantes WHERE id=?', [id]);
    await pool.query('UPDATE eventos SET participantes = GREATEST(0, participantes - 1) WHERE id=?', [part[0].evento_id]);
    res.json({ mensaje: 'Eliminado correctamente' });
  } catch (err) { next(err); }
};

exports.marcarAsistencia = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { asistio, base_updated_at } = req.body;
    const conflicto = await verificarConflicto('participantes', id, base_updated_at);
    if (conflicto) return res.status(409).json(conflicto);
    const [r] = await pool.query('UPDATE participantes SET asistio=? WHERE id=?', [asistio ? 1 : 0, id]);
    if (!r.affectedRows) return res.status(404).json({ error: 'Participante no encontrado' });
    const [rows] = await pool.query('SELECT * FROM participantes WHERE id=?', [id]);
    res.json(rows[0]);
  } catch (err) { next(err); }
};

exports.importarArchivo = async (req, res, next) => {
  try {
    const { evento_id } = req.body;
    if (!evento_id) return res.status(400).json({ error: 'evento_id requerido' });
    if (!req.file) return res.status(400).json({ error: 'Archivo requerido' });
    const XLSX = require('xlsx');
    const wb = XLSX.read(req.file.buffer, { type: 'buffer' });
    const ws = wb.Sheets[wb.SheetNames[0]];
    const filas = XLSX.utils.sheet_to_json(ws);
    const errores = []; const insertados_arr = [];
    for (const fila of filas) {
      const nombre = fila.nombre || fila.Nombre || fila.NOMBRE || Object.values(fila)[0];
      if (!nombre) { errores.push({ fila, error: 'Nombre vacío' }); continue; }
      const email = fila.email || fila.Email || fila.EMAIL || fila.correo || null;
      const telefono = fila.telefono || fila.Telefono || fila.TELEFONO || fila.celular || null;
      insertados_arr.push([evento_id, String(nombre).trim(), email ? String(email).trim() : null, telefono ? String(telefono).trim() : null]);
    }
    if (insertados_arr.length) {
      await pool.query('INSERT INTO participantes (evento_id,nombre,email,telefono) VALUES ?', [insertados_arr]);
      await pool.query('UPDATE eventos SET participantes = participantes + ? WHERE id=?', [insertados_arr.length, evento_id]);
    }
    res.status(201).json({ insertados: insertados_arr.length, errores });
  } catch (err) { next(err); }
};
