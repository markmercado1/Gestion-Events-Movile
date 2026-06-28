const pool = require('../config/database');

exports.listar = async (req, res, next) => {
  try {
    const { evento_id } = req.query;
    if (!evento_id) return res.status(400).json({ error: 'evento_id requerido' });
    const [rows] = await pool.query(
      'SELECT * FROM actividades WHERE evento_id=? ORDER BY hora_inicio ASC',
      [evento_id]
    );
    res.json(rows);
  } catch (err) { next(err); }
};

exports.crear = async (req, res, next) => {
  try {
    const { evento_id, nombre, descripcion, hora_inicio, hora_fin, responsable } = req.body;
    if (hora_fin <= hora_inicio) return res.status(400).json({ error: 'hora_fin debe ser mayor que hora_inicio' });
    // Verificar solapamiento
    const [conflictos] = await pool.query(
      `SELECT id FROM actividades WHERE evento_id=? AND id!=0
       AND hora_inicio < ? AND hora_fin > ?`,
      [evento_id, hora_fin, hora_inicio]
    );
    if (conflictos.length) return res.status(409).json({ error: 'Conflicto de horario con otra actividad' });
    const [r] = await pool.query(
      'INSERT INTO actividades (evento_id,nombre,descripcion,hora_inicio,hora_fin,responsable) VALUES (?,?,?,?,?,?)',
      [evento_id, nombre, descripcion || null, hora_inicio, hora_fin, responsable || null]
    );
    const [rows] = await pool.query('SELECT * FROM actividades WHERE id=?', [r.insertId]);
    res.status(201).json(rows[0]);
  } catch (err) { next(err); }
};

exports.actualizar = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { evento_id, nombre, descripcion, hora_inicio, hora_fin, responsable } = req.body;
    if (hora_fin <= hora_inicio) return res.status(400).json({ error: 'hora_fin debe ser mayor que hora_inicio' });
    // Verificar solapamiento excluyendo el registro actual
    const [conflictos] = await pool.query(
      `SELECT id FROM actividades WHERE evento_id=? AND id!=?
       AND hora_inicio < ? AND hora_fin > ?`,
      [evento_id, id, hora_fin, hora_inicio]
    );
    if (conflictos.length) return res.status(409).json({ error: 'Conflicto de horario con otra actividad' });
    const [r] = await pool.query(
      'UPDATE actividades SET nombre=?,descripcion=?,hora_inicio=?,hora_fin=?,responsable=? WHERE id=?',
      [nombre, descripcion || null, hora_inicio, hora_fin, responsable || null, id]
    );
    if (!r.affectedRows) return res.status(404).json({ error: 'Actividad no encontrada' });
    const [rows] = await pool.query('SELECT * FROM actividades WHERE id=?', [id]);
    res.json(rows[0]);
  } catch (err) { next(err); }
};

exports.eliminar = async (req, res, next) => {
  try {
    const [r] = await pool.query('DELETE FROM actividades WHERE id=?', [req.params.id]);
    if (!r.affectedRows) return res.status(404).json({ error: 'Actividad no encontrada' });
    res.json({ mensaje: 'Actividad eliminada correctamente' });
  } catch (err) { next(err); }
};

exports.generarIcal = async (req, res, next) => {
  try {
    const { evento_id } = req.params;
    const [[evento]] = await pool.query('SELECT id, nombre, fecha FROM eventos WHERE id=?', [evento_id]);
    if (!evento) return res.status(404).json({ error: 'Evento no encontrado' });

    const [actividades] = await pool.query(
      'SELECT * FROM actividades WHERE evento_id=? ORDER BY hora_inicio ASC',
      [evento_id]
    );

    function toIcalDate(fechaVal, horaStr) {
      const d = fechaVal instanceof Date
        ? `${fechaVal.getFullYear()}${String(fechaVal.getMonth()+1).padStart(2,'0')}${String(fechaVal.getDate()).padStart(2,'0')}`
        : String(fechaVal).substring(0, 10).replace(/-/g, '');
      const h = String(horaStr).substring(0, 5).replace(':', '') + '00';
      return `${d}T${h}`;
    }
    function esc(str) {
      return String(str || '').replace(/\\/g, '\\\\').replace(/;/g, '\\;').replace(/,/g, '\\,').replace(/\n|\r/g, '\\n');
    }

    const vevents = actividades.map(a => [
      'BEGIN:VEVENT',
      `UID:${a.id}-${evento_id}@eventjuliaca`,
      `DTSTART:${toIcalDate(evento.fecha, a.hora_inicio)}`,
      `DTEND:${toIcalDate(evento.fecha, a.hora_fin)}`,
      `SUMMARY:${esc(a.nombre)}`,
      a.descripcion ? `DESCRIPTION:${esc(a.descripcion)}` : null,
      'END:VEVENT',
    ].filter(Boolean).join('\r\n')).join('\r\n');

    const ical = [
      'BEGIN:VCALENDAR',
      'VERSION:2.0',
      'PRODID:-//Event Juliaca//ES',
      'CALSCALE:GREGORIAN',
      'METHOD:PUBLISH',
      ...(vevents ? [vevents] : []),
      'END:VCALENDAR',
    ].join('\r\n');

    res.setHeader('Content-Type', 'text/calendar; charset=utf-8');
    res.setHeader('Content-Disposition', `attachment; filename=evento_${evento_id}.ics`);
    res.send(ical);
  } catch (err) { next(err); }
};
