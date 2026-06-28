const express = require('express');
const cors    = require('cors');
const env     = require('./config/env');

const app = express();
const corsOrigin = env.nodeEnv === 'development'
  ? (origin, cb) => cb(null, true)
  : env.frontendUrl;
app.use(cors({ origin: corsOrigin, methods: ['GET','POST','PUT','DELETE'], allowedHeaders: ['Content-Type','Authorization'], credentials: true }));
app.use(express.json());
app.use(express.urlencoded({ extended: false }));

app.use('/api/auth',         require('./routes/auth'));
app.use('/api/sedes',        require('./routes/sedes'));
app.use('/api/salas',        require('./routes/salas'));
app.use('/api/eventos',      require('./routes/eventos'));
app.use('/api/bloques',      require('./routes/bloques'));
app.use('/api/pagos',        require('./routes/pagos'));
app.use('/api/cotizaciones', require('./routes/cotizaciones'));
app.use('/api/participantes',require('./routes/participantes'));
app.use('/api/actividades',  require('./routes/actividades'));
app.use('/api/recursos',     require('./routes/recursos'));
app.use('/api/usuarios',     require('./routes/usuarios'));
app.use('/api/auditoria',    require('./routes/auditoria'));

const auth = require('./middleware/auth');
const dash = require('./controllers/dashboardController');
app.get('/api/dashboard/estadisticas', auth, dash.estadisticas);
app.get('/api/health', (_, res) => res.json({ status: 'ok', app: 'Event Juliaca API' }));
app.post('/api/debug/login', (req, res) => {
  res.json({ recibido: req.body, ip: req.ip, contentType: req.headers['content-type'] });
});
app.use((_, res) => res.status(404).json({ error: 'Ruta no encontrada' }));
app.use(require('./middleware/errorHandler'));

module.exports = app;
