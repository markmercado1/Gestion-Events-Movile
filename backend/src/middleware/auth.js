const jwt = require('jsonwebtoken');
const env  = require('../config/env');
const authMiddleware = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  if (!authHeader || !authHeader.startsWith('Bearer '))
    return res.status(401).json({ error: 'Token requerido' });
  const token = authHeader.split(' ')[1];
  try { req.usuario = jwt.verify(token, env.jwt.secret); next(); }
  catch { return res.status(401).json({ error: 'Token invalido o expirado' }); }
};

authMiddleware.soloAdmin = (req, res, next) => {
  if (!req.usuario || req.usuario.rol !== 'admin')
    return res.status(403).json({ error: 'Acceso restringido a administradores' });
  next();
};

module.exports = authMiddleware;
