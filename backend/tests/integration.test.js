const request = require('supertest');
const app = require('../src/app');

let token;
let pool;

beforeAll(async () => {
  pool = require('../src/config/database');
  const res = await request(app)
    .post('/api/auth/login')
    .send({ email: 'admin@eventjuliaca.com', password: 'admin123' });
  token = res.body.token;
});

afterAll(async () => {
  await pool.end();
});

const auth = () => ({ Authorization: `Bearer ${token}` });

// ─── Ciclo de vida de Evento ────────────────────────────────
describe('Ciclo de vida de Evento', () => {
  let eventoId;

  test('Crear evento → 201 con id', async () => {
    const res = await request(app)
      .post('/api/eventos')
      .set(auth())
      .send({
        nombre: 'Evento Integration Test',
        fecha: '2026-12-31',
        hora_inicio: '10:00',
        hora_fin: '18:00',
        tipo: 'gratuito',
        estado: 'proximo',
      });
    expect(res.status).toBe(201);
    expect(res.body).toHaveProperty('id');
    eventoId = res.body.id;
  });

  test('Listar eventos → el evento creado aparece', async () => {
    const res = await request(app).get('/api/eventos');
    expect(res.status).toBe(200);
    const encontrado = res.body.find(e => e.id === eventoId);
    expect(encontrado).toBeDefined();
    expect(encontrado.nombre).toBe('Evento Integration Test');
  });

  test('Eliminar evento → 200 con mensaje', async () => {
    const res = await request(app)
      .delete(`/api/eventos/${eventoId}`)
      .set(auth());
    expect(res.status).toBe(200);
    expect(res.body).toHaveProperty('mensaje');
  });

  test('Listar eventos → el evento ya no existe', async () => {
    const res = await request(app).get('/api/eventos');
    expect(res.status).toBe(200);
    const encontrado = res.body.find(e => e.id === eventoId);
    expect(encontrado).toBeUndefined();
  });
});

// ─── Ciclo de vida de Participante ──────────────────────────
describe('Ciclo de vida de Participante', () => {
  let eventoId;
  let participanteId;

  beforeAll(async () => {
    const res = await request(app)
      .post('/api/eventos')
      .set(auth())
      .send({
        nombre: 'Evento Participantes Test',
        fecha: '2026-12-31',
        hora_inicio: '10:00',
        hora_fin: '18:00',
        tipo: 'gratuito',
        estado: 'proximo',
      });
    eventoId = res.body.id;
  });

  afterAll(async () => {
    if (eventoId) {
      await request(app).delete(`/api/eventos/${eventoId}`).set(auth());
    }
  });

  test('Registrar participante → 201 con id', async () => {
    const res = await request(app)
      .post('/api/participantes')
      .set(auth())
      .send({ evento_id: eventoId, nombre: 'Ana Participante Test', email: 'ana@test.com' });
    expect(res.status).toBe(201);
    expect(res.body).toHaveProperty('id');
    participanteId = res.body.id;
  });

  test('Listar participantes → aparece sin asistencia', async () => {
    const res = await request(app)
      .get(`/api/participantes?evento_id=${eventoId}`)
      .set(auth());
    expect(res.status).toBe(200);
    const encontrado = res.body.find(p => p.id === participanteId);
    expect(encontrado).toBeDefined();
    expect(encontrado.asistio).toBeFalsy();
  });

  test('Marcar asistencia → asistio truthy', async () => {
    const res = await request(app)
      .patch(`/api/participantes/${participanteId}/asistencia`)
      .set(auth())
      .send({ asistio: true });
    expect(res.status).toBe(200);
    expect(res.body.asistio).toBeTruthy();
  });

  test('Verificar en lista → asistio=true', async () => {
    const res = await request(app)
      .get(`/api/participantes?evento_id=${eventoId}`)
      .set(auth());
    expect(res.status).toBe(200);
    const encontrado = res.body.find(p => p.id === participanteId);
    expect(encontrado).toBeDefined();
    expect(encontrado.asistio).toBeTruthy();
  });
});

// ─── Ciclo de vida de Recurso ────────────────────────────────
describe('Ciclo de vida de Recurso', () => {
  let recursoId;
  const eventoIdSeed = 1;

  afterAll(async () => {
    if (recursoId) {
      await request(app).delete(`/api/recursos/${recursoId}`).set(auth());
    }
  });

  test('Crear recurso → 201 disponible', async () => {
    const res = await request(app)
      .post('/api/recursos')
      .set(auth())
      .send({ nombre: 'Proyector Test Integration', categoria: 'Audio/Video', cantidad: 1, estado: 'disponible' });
    expect(res.status).toBe(201);
    expect(res.body).toHaveProperty('id');
    expect(res.body.estado).toBe('disponible');
    recursoId = res.body.id;
  });

  test('Asignar recurso a evento → 201', async () => {
    const res = await request(app)
      .post('/api/recursos/asignar')
      .set(auth())
      .send({ evento_id: eventoIdSeed, recurso_id: recursoId, cantidad_asignada: 1 });
    expect(res.status).toBe(201);
    expect(res.body).toHaveProperty('mensaje');
  });

  test('Verificar recurso → estado en_uso', async () => {
    const res = await request(app).get('/api/recursos');
    expect(res.status).toBe(200);
    const recurso = res.body.find(r => r.id === recursoId);
    expect(recurso).toBeDefined();
    expect(recurso.estado).toBe('en_uso');
  });

  test('Listar recursos del evento → incluye el asignado', async () => {
    const res = await request(app).get(`/api/recursos/evento/${eventoIdSeed}`);
    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
    const encontrado = res.body.find(r => r.recurso_id === recursoId);
    expect(encontrado).toBeDefined();
  });
});

// ─── Ciclo de vida de Cotización ─────────────────────────────
describe('Ciclo de vida de Cotización', () => {
  let cotizacionId;

  afterAll(async () => {
    if (cotizacionId && pool) {
      await pool.query('DELETE FROM cotizaciones WHERE id=?', [cotizacionId]);
    }
  });

  test('Crear cotización (pública) → 201 pendiente', async () => {
    const res = await request(app)
      .post('/api/cotizaciones')
      .send({
        nombre: 'Test Cotizacion Integration',
        telefono: '000000001',
        tipo_evento: 'Conferencia',
        mensaje: 'Test de integración automatizado',
      });
    expect(res.status).toBe(201);
    expect(res.body).toHaveProperty('id');
    expect(res.body.estado).toBe('pendiente');
    cotizacionId = res.body.id;
  });

  test('Listar cotizaciones → aparece la creada', async () => {
    const res = await request(app).get('/api/cotizaciones').set(auth());
    expect(res.status).toBe(200);
    const encontrada = res.body.find(c => c.id === cotizacionId);
    expect(encontrada).toBeDefined();
    expect(encontrada.estado).toBe('pendiente');
  });

  test('Cambiar estado a contactado → 200', async () => {
    const res = await request(app)
      .put(`/api/cotizaciones/${cotizacionId}/estado`)
      .set(auth())
      .send({ estado: 'contactado' });
    expect(res.status).toBe(200);
    expect(res.body.estado).toBe('contactado');
  });
});
