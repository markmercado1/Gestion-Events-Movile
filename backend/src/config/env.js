require('dotenv').config();
module.exports = {
  port:      process.env.PORT        || 3000,
  nodeEnv:   process.env.NODE_ENV    || 'development',
  db: {
    host:     process.env.DB_HOST    || 'localhost',
    port:     parseInt(process.env.DB_PORT || '3306', 10),
    user:     process.env.DB_USER    || 'root',
    password: process.env.DB_PASSWORD || '',
    name:     process.env.DB_NAME    || 'event_juliaca',
  },
  jwt: {
    secret:    process.env.JWT_SECRET    || 'secreto_dev',
    expiresIn: process.env.JWT_EXPIRES_IN || '24h',
  },
  frontendUrl: process.env.FRONTEND_URL || 'http://localhost:5173',
};
