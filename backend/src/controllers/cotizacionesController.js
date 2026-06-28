const pool = require('../config/database');
const { notificarCotizacion } = require('../services/mailer');
const { enviarWhatsApp } = require('../services/whatsapp');
const { buscarPorClientUuid, esDuplicadoClientUuid, verificarConflicto } = require('../utils/syncHelpers');

exports.listar = async (req, res, next) => {
  try {
    const { since } = req.query;
    let sql = 'SELECT * FROM cotizaciones'; const vals = [];
    if (since) { sql += ' WHERE updated_at > ?'; vals.push(since); }
    sql += ' ORDER BY creado_en DESC';
    const [rows] = await pool.query(sql, vals);
    res.json(rows);
  } catch (err) { next(err); }
};

exports.crear = async (req, res, next) => {
  try {
    const { nombre, telefono, tipo_evento, fecha_evento, sede_preferida, mensaje, client_uuid } = req.body;
    const existente = await buscarPorClientUuid('cotizaciones', client_uuid);
    if (existente) return res.status(200).json(existente);
    const fecha = fecha_evento || null;
    const [r] = await pool.query(
      'INSERT INTO cotizaciones (nombre, telefono, tipo_evento, fecha_evento, sede_preferida, mensaje, client_uuid) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [nombre, telefono, tipo_evento, fecha, sede_preferida, mensaje, client_uuid||null]
    );
    const [rows] = await pool.query('SELECT * FROM cotizaciones WHERE id=?', [r.insertId]);

    // Enviar notificaciones de forma asíncrona (sin bloquear la respuesta)
    notificarCotizacion({ nombre, telefono, tipo_evento, fecha_evento, sede_preferida, mensaje })
      .then(() => console.log(`📧 Email de cotización enviado para: ${nombre}`))
      .catch(err => console.error('⚠️  Error enviando email de cotización:', err.message));

    enviarWhatsApp({ nombre, telefono, tipo_evento, fecha_evento, sede_preferida, mensaje })
      .catch(err => console.error('⚠️  Error enviando WhatsApp de cotización:', err.message));

    res.status(201).json(rows[0]);
  } catch (err) {
    if (esDuplicadoClientUuid(err)) {
      const existente = await buscarPorClientUuid('cotizaciones', req.body.client_uuid);
      if (existente) return res.status(200).json(existente);
    }
    next(err);
  }
};

exports.actualizarEstado = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { estado, base_updated_at } = req.body;
    const conflicto = await verificarConflicto('cotizaciones', id, base_updated_at);
    if (conflicto) return res.status(409).json(conflicto);
    const [r] = await pool.query('UPDATE cotizaciones SET estado=? WHERE id=?', [estado, id]);
    if (!r.affectedRows) return res.status(404).json({ error: 'Cotización no encontrada' });
    const [rows] = await pool.query('SELECT * FROM cotizaciones WHERE id=?', [id]);
    res.json(rows[0]);
  } catch (err) { next(err); }
};
