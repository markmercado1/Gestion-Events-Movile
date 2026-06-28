const bcrypt = require('bcryptjs');
const jwt    = require('jsonwebtoken');
const pool   = require('../config/database');
const env    = require('../config/env');
const { notificarIntentosFallidos } = require('../services/mailer');

const genToken = (u) => jwt.sign({ id: u.id, email: u.email, rol: u.rol }, env.jwt.secret, { expiresIn: env.jwt.expiresIn });

// Contador de intentos fallidos por IP: ip -> { count, timer }
const failedAttempts = new Map();
const FAIL_LIMIT = 3;
const FAIL_WINDOW_MS = 15 * 60 * 1000;

function getIp(req) {
  return (req.headers['x-forwarded-for'] || req.ip || 'unknown').split(',')[0].trim();
}
function recordFail(ip) {
  const entry = failedAttempts.get(ip) || { count: 0, timer: null };
  if (entry.timer) clearTimeout(entry.timer);
  entry.count++;
  entry.timer = setTimeout(() => failedAttempts.delete(ip), FAIL_WINDOW_MS);
  failedAttempts.set(ip, entry);
  return entry.count;
}
function resetFail(ip) {
  const entry = failedAttempts.get(ip);
  if (entry?.timer) clearTimeout(entry.timer);
  failedAttempts.delete(ip);
}

exports.registro = async (req, res, next) => {
  try {
    const { email, password, rol = 'usuario' } = req.body;
    const hash = await bcrypt.hash(password, 10);
    const [r] = await pool.query('INSERT INTO usuarios (email, password_hash, rol) VALUES (?, ?, ?)', [email, hash, rol]);
    const u = { id: r.insertId, email, rol };
    res.status(201).json({ token: genToken(u), usuario: u });
  } catch (err) { next(err); }
};

exports.login = async (req, res, next) => {
  try {
    const ip = getIp(req);
    const { email, password } = req.body;
    const [rows] = await pool.query('SELECT id, email, password_hash, rol FROM usuarios WHERE email = ?', [email]);
    const u = rows[0];
    if (!u || !await bcrypt.compare(password, u.password_hash)) {
      const count = recordFail(ip);
      if (count >= FAIL_LIMIT) {
        try {
          await notificarIntentosFallidos({ ip, fecha: new Date(), intentos: count });
        } catch (mailErr) {
          console.error('Email intentos fallidos no enviado:', mailErr.message);
        }
      }
      return res.status(401).json({ error: 'Credenciales invalidas' });
    }
    resetFail(ip);
    const payload = { id: u.id, email: u.email, rol: u.rol };
    res.json({ token: genToken(payload), usuario: payload });
  } catch (err) { next(err); }
};

exports.refreshToken = (req, res) => {
  // req.usuario ya fue verificado por el middleware auth
  const { id, email, rol } = req.usuario;
  const token = genToken({ id, email, rol });
  res.json({ token });
};
