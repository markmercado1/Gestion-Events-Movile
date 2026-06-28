const request = require('supertest');
const app = require('../src/app');

afterAll(async () => {
  const pool = require('../src/config/database');
  await pool.end();
});

describe('POST /api/auth/login', () => {
  test('credenciales válidas → 200 y token', async () => {
    const res = await request(app)
      .post('/api/auth/login')
      .send({ email: 'admin@eventjuliaca.com', password: 'admin123' });
    expect(res.status).toBe(200);
    expect(res.body).toHaveProperty('token');
    expect(res.body).toHaveProperty('usuario');
    expect(res.body.usuario.rol).toBe('admin');
  });

  test('password incorrecto → 401', async () => {
    const res = await request(app)
      .post('/api/auth/login')
      .send({ email: 'admin@eventjuliaca.com', password: 'wrongpassword' });
    expect(res.status).toBe(401);
    expect(res.body).toHaveProperty('error');
  });

  test('email inválido → 422', async () => {
    const res = await request(app)
      .post('/api/auth/login')
      .send({ email: 'not-an-email', password: 'admin123' });
    expect(res.status).toBe(422);
    expect(res.body).toHaveProperty('errores');
  });
});

describe('Rutas públicas y protegidas', () => {
  test('GET /api/eventos sin token → 200 con array', async () => {
    const res = await request(app).get('/api/eventos');
    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
  });

  test('GET /api/dashboard/estadisticas sin token → 401', async () => {
    const res = await request(app).get('/api/dashboard/estadisticas');
    expect(res.status).toBe(401);
    expect(res.body).toHaveProperty('error');
  });

  test('GET /api/usuarios sin token → 401', async () => {
    const res = await request(app).get('/api/usuarios');
    expect(res.status).toBe(401);
    expect(res.body).toHaveProperty('error');
  });

  test('POST /api/participantes sin token → 401', async () => {
    const res = await request(app)
      .post('/api/participantes')
      .send({ evento_id: 1, nombre: 'Test' });
    expect(res.status).toBe(401);
    expect(res.body).toHaveProperty('error');
  });
});
