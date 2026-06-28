-- ============================================================
-- Event Juliaca - Datos de Prueba (Seed)
-- ============================================================

USE event_juliaca;

-- -------------------------------------------------------
-- Usuario admin (password: admin123, bcrypt cost=10)
-- -------------------------------------------------------
INSERT INTO usuarios (email, password_hash, rol) VALUES
('admin@eventjuliaca.com',
 '$2a$10$oaPUPPKnQPFcNscxmYYZZ.d6/0E1dAewNVo2umncTwXBqZJGbJtva',
 'admin');

-- -------------------------------------------------------
-- Sedes
-- -------------------------------------------------------
INSERT INTO sedes (nombre, direccion, telefono, imagen_url) VALUES
('Event Juliaca Centro',
 'Jr. Comercio 123, Juliaca',
 '051-321001',
 'https://placehold.co/800x400?text=EJ+Centro'),
('Event Juliaca Norte',
 'Av. Independencia 456, Juliaca',
 '051-321002',
 'https://placehold.co/800x400?text=EJ+Norte'),
('Event Juliaca Sur',
 'Av. Manco Capac 789, Juliaca',
 '051-321003',
 'https://placehold.co/800x400?text=EJ+Sur');

-- -------------------------------------------------------
-- Salas (3 por sede)
-- -------------------------------------------------------
INSERT INTO salas (sede_id, nombre, capacidad, estado) VALUES
(1, 'Salon A',    150, 'disponible'),
(1, 'Salon B',    80,  'disponible'),
(1, 'Auditorio A',  300, 'disponible'),
(2, 'Salon A',    120, 'disponible'),
(2, 'Salon B',    60,  'disponible'),
(2, 'Auditorio B',  250, 'disponible'),
(3, 'Salon A',    100, 'disponible'),
(3, 'Salon B',    50,  'disponible'),
(3, 'Auditorio C',  200, 'disponible');

-- -------------------------------------------------------
-- Eventos de ejemplo
-- -------------------------------------------------------
INSERT INTO eventos
  (nombre, fecha, hora_inicio, hora_fin, tipo, precio,
   sede_id, sala_id, nombre_cliente, telefono_cliente,
   participantes, estado, descripcion)
VALUES
('Conferencia de Tecnologia 2026',
 '2026-05-10', '09:00:00', '18:00:00',
 'pagado', 50.00, 1, 3,
 'Tech Peru SAC', '999111001',
 280, 'proximo',
 'Conferencia anual de tecnologia e innovacion.'),

('Feria de Emprendimiento Juliaca',
 '2026-05-15', '10:00:00', '20:00:00',
 'gratuito', 0.00, 2, 6,
 'Municipalidad Juliaca', '051-321100',
 200, 'proximo',
 'Feria de emprendedores locales.'),

('Taller de Fotografia Profesional',
 '2026-04-20', '14:00:00', '18:00:00',
 'pagado', 30.00, 1, 1,
 'Estudio Focus', '999222003',
 45, 'completado',
 'Taller practico de fotografia.'),

('Seminario de Finanzas Personales',
 '2026-04-22', '08:00:00', '13:00:00',
 'pagado', 20.00, 3, 7,
 'FinanceClub Puno', '999333004',
 80, 'completado',
 'Aprende a manejar tus finanzas.'),

('Concierto Benefico Juliaca',
 '2026-06-01', '19:00:00', '23:00:00',
 'pagado', 15.00, 2, 4,
 'Asociacion Cultural Puno', '999444005',
 110, 'proximo',
 'Concierto para recaudar fondos.'),

('Capacitacion en Marketing Digital',
 '2026-04-23', '09:00:00', '17:00:00',
 'pagado', 25.00, 1, 2,
 'Agencia Digital Norte', '999555006',
 60, 'activo',
 'Curso intensivo de marketing digital.');

-- -------------------------------------------------------
-- Bloques horarios
-- -------------------------------------------------------
INSERT INTO bloques_horario (sala_id, fecha, hora_inicio, hora_fin, etiqueta, evento_id, tipo) VALUES
(3, '2026-05-10',  9, 18, 'Conferencia Tecnologia',  1, 'evento'),
(6, '2026-05-15', 10, 20, 'Feria Emprendimiento',    2, 'evento'),
(1, '2026-04-20', 14, 18, 'Taller Fotografia',       3, 'evento'),
(7, '2026-04-22',  8, 13, 'Seminario Finanzas',      4, 'evento'),
(4, '2026-06-01', 19, 23, 'Concierto Benefico',      5, 'evento'),
(2, '2026-04-23',  9, 17, 'Capacitacion Marketing',  6, 'evento'),
-- Bloques de mantenimiento y reservas manuales para la semana demostrativa del 20 de Abril 2026
(2, '2026-04-20',  8, 12, 'Limpieza General',        NULL, 'mantenimiento'),
(3, '2026-04-20', 15, 20, 'Reservado Municipal',      NULL, 'bloqueado'),
(1, '2026-04-21',  9, 13, 'Fumigación Anual',        NULL, 'mantenimiento'),
(2, '2026-04-21', 14, 19, 'Bloqueo Técnico de Audio', NULL, 'bloqueado'),
(4, '2026-04-22', 10, 14, 'Sanitización Preventiva',  NULL, 'mantenimiento'),
(5, '2026-04-23', 12, 16, 'Reparación de Luces LED',  NULL, 'mantenimiento');

-- -------------------------------------------------------
-- Pagos de ejemplo
-- -------------------------------------------------------
INSERT INTO pagos (evento_id, monto, estado, url_comprobante) VALUES
(1, 50.00, 'verificado', 'https://placehold.co/400x300?text=Comprobante+Conf+Tecnologia'),
(3, 30.00, 'verificado', 'https://placehold.co/400x300?text=Comprobante+Taller+Fotografia'),
(4, 20.00, 'verificado', 'https://placehold.co/400x300?text=Comprobante+Seminario+Finanzas'),
(5, 15.00, 'pendiente',  'https://placehold.co/400x300?text=Comprobante+Concierto+Benefico'),
(6, 25.00, 'pendiente',  'https://placehold.co/400x300?text=Comprobante+Marketing+Digital');

-- -------------------------------------------------------
-- Cotizaciones de ejemplo
-- -------------------------------------------------------
INSERT INTO cotizaciones (nombre, telefono, tipo_evento, fecha_evento, sede_preferida, mensaje, estado, creado_en) VALUES
('Sofía Quispe Condori', '951445566', 'Quinceañero Familiar', '2026-06-15', 'Event Juliaca Centro', 'Deseo cotizar el salón principal para 150 invitados. Incluir catering básico, DJ y luces inteligentes.', 'pendiente', '2026-05-27 14:30:00'),
('Dr. Robert Huamán Pineda', '950223344', 'Conferencia Corporativa', '2026-06-20', 'Event Juliaca Norte', 'Requerimos el auditorio completo para capacitación de personal de Caja Arequipa. Capacidad 200 personas, con proyector, micrófonos y Coffee Break.', 'pendiente', '2026-05-28 09:15:00'),
('Ronald & Kelly (Novios)', '987654321', 'Boda Civil y Fiesta de Gala', '2026-07-04', 'Event Juliaca Sur', 'Matrimonio civil y banquete especial para 120 personas. Solicitamos paquete premium todo incluido (decoración floral, foto y video).', 'contactado', '2026-05-25 18:20:00'),
('Carlos Pineda Luna', '933445566', 'Fiesta de Promoción Escolar', '2026-12-10', 'Event Juliaca Centro', 'Cotización preliminar para fiesta de promoción del colegio Politécnico Regional Los Andes. Presupuesto aproximado por alumno.', 'descartado', '2026-05-20 11:05:00');

-- -------------------------------------------------------
-- Recursos (inventario logístico)
-- -------------------------------------------------------
INSERT INTO recursos (nombre, categoria, cantidad, estado, descripcion) VALUES
('Proyector Epson EB-X51',    'Audio/Video', 2,  'disponible', 'Proyector 3800 lúmenes, resolución XGA, incluye cable HDMI y VGA'),
('Sillas Tipo Conferencia',   'Mobiliario',  50, 'disponible', 'Sillas apilables acolchadas, ideales para eventos y capacitaciones'),
('Micrófono Inalámbrico UHF', 'Audio/Video', 4,  'en_uso',     'Micrófono de mano inalámbrico con 50 m de alcance y receptor');

-- -------------------------------------------------------
-- Actividades para Conferencia de Tecnología 2026 (evento_id=1)
-- -------------------------------------------------------
INSERT INTO actividades (evento_id, nombre, descripcion, hora_inicio, hora_fin, responsable) VALUES
(1, 'Bienvenida e inscripción',         'Recepción de asistentes, entrega de materiales y acreditación',       '09:00:00', '10:00:00', 'Comité Organizador'),
(1, 'Conferencia magistral: IA y futuro','Ponencia central sobre inteligencia artificial aplicada a negocios', '10:30:00', '12:30:00', 'Dr. Carlos Mendoza'),
(1, 'Talleres prácticos y demos',       'Sesiones interactivas con demostraciones en vivo de tecnología',      '14:00:00', '17:00:00', 'Equipo Técnico');

-- -------------------------------------------------------
-- Registros de auditoría de ejemplo
-- -------------------------------------------------------
INSERT INTO auditoria (usuario_id, accion, entidad, entidad_id, ip, creado_en) VALUES
(1, 'POST /eventos', 'eventos', 1, '127.0.0.1', '2026-05-10 08:30:00'),
(1, 'PUT /pagos',   'pagos',   1, '127.0.0.1', '2026-05-10 09:15:00');
