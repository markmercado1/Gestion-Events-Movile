module.exports = (entidad) => async (req, res, next) => {
  const originalJson = res.json.bind(res);
  res.json = (body) => {
    if (res.statusCode < 400 && ['POST','PUT','DELETE'].includes(req.method)) {
      const pool = require('../config/database');
      const entidad_id = body?.id || req.params?.id || null;
      const usuario_id = req.usuario?.id || null;
      const ip = req.ip || req.connection?.remoteAddress || null;
      const accion = `${req.method} /${entidad}`;
      pool.query('INSERT INTO auditoria (usuario_id,accion,entidad,entidad_id,ip) VALUES (?,?,?,?,?)',
        [usuario_id, accion, entidad, entidad_id, ip]).catch(() => {});
    }
    return originalJson(body);
  };
  next();
};
