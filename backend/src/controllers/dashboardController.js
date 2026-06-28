const pool = require('../config/database');
exports.estadisticas = async (req, res, next) => {
  try {
    const [[totales]] = await pool.query(`
      SELECT
        (SELECT COUNT(*) FROM eventos) AS total_eventos,
        (SELECT COUNT(*) FROM eventos WHERE estado='activo') AS eventos_activos,
        (SELECT COUNT(*) FROM eventos WHERE estado='proximo') AS eventos_proximos,
        (SELECT COUNT(*) FROM eventos WHERE estado='completado') AS eventos_completados,
        (SELECT COUNT(*) FROM eventos WHERE tipo='pagado') AS eventos_pagados,
        (SELECT COUNT(*) FROM eventos WHERE tipo='gratuito') AS eventos_gratuitos,
        (SELECT COALESCE(SUM(participantes),0) FROM eventos) AS total_participantes,
        (SELECT COUNT(*) FROM sedes) AS total_sedes,
        (SELECT COUNT(*) FROM salas) AS total_salas,
        (SELECT COUNT(*) FROM salas WHERE estado='disponible') AS salas_disponibles,
        (SELECT COUNT(*) FROM pagos) AS total_pagos,
        (SELECT COUNT(*) FROM pagos WHERE estado='pendiente') AS pagos_pendientes,
        (SELECT COUNT(*) FROM pagos WHERE estado='verificado') AS pagos_verificados,
        (SELECT COALESCE(SUM(monto),0) FROM pagos WHERE estado='verificado') AS ingresos_verificados
    `);
    const [proximos] = await pool.query(`
      SELECT e.id,e.nombre,e.fecha,e.hora_inicio,e.tipo,e.participantes,se.nombre AS sede_nombre
      FROM eventos e LEFT JOIN sedes se ON e.sede_id=se.id
      WHERE e.estado='proximo' ORDER BY e.fecha ASC LIMIT 5
    `);
    res.json({ ...totales, proximos_eventos: proximos });
  } catch (err) { next(err); }
};
