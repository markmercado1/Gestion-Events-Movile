-- ============================================================
-- migrate.sql — Migración para BD existentes (Event Juliaca v2.0)
-- Ejecutar en la BD event_juliaca ya existente
-- ============================================================

USE event_juliaca;

-- 1. Agregar columna asistio a participantes (si no existe)
ALTER TABLE participantes ADD COLUMN IF NOT EXISTS asistio BOOLEAN DEFAULT FALSE;

-- 2. Modificar rol en usuarios para agregar 'organizador'
ALTER TABLE usuarios MODIFY COLUMN rol ENUM('admin','organizador','usuario') DEFAULT 'usuario';

-- 3. Tabla: actividades
CREATE TABLE IF NOT EXISTS actividades (
  id INT AUTO_INCREMENT PRIMARY KEY,
  evento_id INT NOT NULL,
  nombre VARCHAR(255) NOT NULL,
  descripcion TEXT,
  hora_inicio TIME NOT NULL,
  hora_fin TIME NOT NULL,
  responsable VARCHAR(255),
  creado_en DATETIME DEFAULT NOW(),
  FOREIGN KEY (evento_id) REFERENCES eventos(id) ON DELETE CASCADE
);

-- 4. Tabla: recursos
CREATE TABLE IF NOT EXISTS recursos (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(255) NOT NULL,
  categoria VARCHAR(100),
  cantidad INT DEFAULT 1,
  estado ENUM('disponible','en_uso','mantenimiento') DEFAULT 'disponible',
  descripcion TEXT,
  creado_en DATETIME DEFAULT NOW()
);

-- 5. Tabla: evento_recursos
CREATE TABLE IF NOT EXISTS evento_recursos (
  id INT AUTO_INCREMENT PRIMARY KEY,
  evento_id INT NOT NULL,
  recurso_id INT NOT NULL,
  cantidad_asignada INT DEFAULT 1,
  FOREIGN KEY (evento_id) REFERENCES eventos(id) ON DELETE CASCADE,
  FOREIGN KEY (recurso_id) REFERENCES recursos(id) ON DELETE CASCADE
);

-- 6. Tabla: auditoria
CREATE TABLE IF NOT EXISTS auditoria (
  id INT AUTO_INCREMENT PRIMARY KEY,
  usuario_id INT,
  accion VARCHAR(255) NOT NULL,
  entidad VARCHAR(100),
  entidad_id INT,
  ip VARCHAR(45),
  creado_en DATETIME DEFAULT NOW(),
  FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE SET NULL
);

-- 7. Índices de rendimiento
CREATE INDEX IF NOT EXISTS idx_eventos_fecha ON eventos(fecha);
CREATE INDEX IF NOT EXISTS idx_eventos_estado ON eventos(estado);
CREATE INDEX IF NOT EXISTS idx_eventos_tipo ON eventos(tipo);
CREATE INDEX IF NOT EXISTS idx_eventos_sede ON eventos(sede_id);
CREATE INDEX IF NOT EXISTS idx_participantes_evento ON participantes(evento_id);
