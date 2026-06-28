require('./config/database');
const env = require('./config/env');
const app = require('./app');

app.listen(env.port, () => {
  console.log('Servidor corriendo en http://localhost:' + env.port);
  console.log('Entorno: ' + env.nodeEnv);
});
