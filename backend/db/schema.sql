-- ============================================================
-- Event Juliaca - Esquema de Base de Datos MySQL 8
-- ============================================================

CREATE DATABASE IF NOT EXISTS event_juliaca
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE event_juliaca;

-- Tabla: usuarios
CREATE TABLE IF NOT EXISTS usuarios (
  id            INT AUTO_INCREMENT PRIMARY KEY,
  email         VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  rol           ENUM('admin','usuario') DEFAULT 'usuario',
  creado_en     DATETIME DEFAULT NOW()
);

-- Tabla: sedes
CREATE TABLE IF NOT EXISTS sedes (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  nombre      VARCHAR(255) NOT NULL,
  direccion   VARCHAR(255),
  telefono    VARCHAR(20),
  imagen_url  VARCHAR(500),
  creado_en   DATETIME DEFAULT NOW(),
  client_uuid CHAR(36) NULL UNIQUE,
  updated_at  DATETIME NULL DEFAULT NOW() ON UPDATE CURRENT_TIMESTAMP
);

-- Tabla: salas
CREATE TABLE IF NOT EXISTS salas (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  sede_id     INT NOT NULL,
  nombre      VARCHAR(100) NOT NULL,
  capacidad   INT,
  estado      ENUM('disponible','ocupada','mantenimiento') DEFAULT 'disponible',
  client_uuid CHAR(36) NULL UNIQUE,
  updated_at  DATETIME NULL DEFAULT NOW() ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (sede_id) REFERENCES sedes(id) ON DELETE CASCADE
);

-- Tabla: eventos
CREATE TABLE IF NOT EXISTS eventos (
  id               INT AUTO_INCREMENT PRIMARY KEY,
  nombre           VARCHAR(255) NOT NULL,
  fecha            DATE NOT NULL,
  hora_inicio      TIME NOT NULL,
  hora_fin         TIME NOT NULL,
  tipo             ENUM('gratuito','pagado') NOT NULL,
  precio           DECIMAL(10,2) DEFAULT 0,
  sede_id          INT,
  sala_id          INT,
  nombre_cliente   VARCHAR(255),
  telefono_cliente VARCHAR(20),
  participantes    INT DEFAULT 0,
  estado           ENUM('activo','completado','proximo') DEFAULT 'proximo',
  descripcion      TEXT,
  creado_en        DATETIME DEFAULT NOW(),
  client_uuid      CHAR(36) NULL UNIQUE,
  updated_at       DATETIME NULL DEFAULT NOW() ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (sede_id) REFERENCES sedes(id) ON DELETE SET NULL,
  FOREIGN KEY (sala_id) REFERENCES salas(id) ON DELETE SET NULL
);

-- Tabla: bloques_horario
CREATE TABLE IF NOT EXISTS bloques_horario (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  sala_id     INT NOT NULL,
  fecha       DATE NOT NULL,
  hora_inicio INT NOT NULL,
  hora_fin    INT NOT NULL,
  etiqueta    VARCHAR(255),
  evento_id   INT,
  tipo        ENUM('evento','bloqueado','mantenimiento') DEFAULT 'evento',
  FOREIGN KEY (sala_id)   REFERENCES salas(id) ON DELETE CASCADE,
  FOREIGN KEY (evento_id) REFERENCES eventos(id) ON DELETE SET NULL
);

-- Tabla: pagos
CREATE TABLE IF NOT EXISTS pagos (
  id              INT AUTO_INCREMENT PRIMARY KEY,
  evento_id       INT NOT NULL,
  monto           DECIMAL(10,2) NOT NULL,
  estado          ENUM('pendiente','verificado','rechazado') DEFAULT 'pendiente',
  url_comprobante VARCHAR(500),
  creado_en       DATETIME DEFAULT NOW(),
  client_uuid     CHAR(36) NULL UNIQUE,
  updated_at      DATETIME NULL DEFAULT NOW() ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (evento_id) REFERENCES eventos(id) ON DELETE CASCADE
);

-- Tabla: participantes
CREATE TABLE IF NOT EXISTS participantes (
  id INT AUTO_INCREMENT PRIMARY KEY,
  evento_id INT NOT NULL,
  nombre VARCHAR(255) NOT NULL,
  email VARCHAR(255),
  telefono VARCHAR(20),
  creado_en DATETIME DEFAULT NOW(),
  client_uuid CHAR(36) NULL UNIQUE,
  updated_at DATETIME NULL DEFAULT NOW() ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (evento_id) REFERENCES eventos(id) ON DELETE CASCADE
);

-- Tabla: cotizaciones
CREATE TABLE IF NOT EXISTS cotizaciones (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(255) NOT NULL,
  telefono VARCHAR(20) NOT NULL,
  tipo_evento VARCHAR(100),
  fecha_evento DATE,
  sede_preferida VARCHAR(255),
  mensaje TEXT,
  estado ENUM('pendiente', 'contactado', 'descartado') DEFAULT 'pendiente',
  creado_en DATETIME DEFAULT NOW(),
  client_uuid CHAR(36) NULL UNIQUE,
  updated_at DATETIME NULL DEFAULT NOW() ON UPDATE CURRENT_TIMESTAMP
);

-- ============================================================
-- EXTENSIONES v2.0 — Actividades, Recursos, Auditoría
-- ============================================================

-- Agregar campo asistio a participantes
ALTER TABLE participantes ADD COLUMN IF NOT EXISTS asistio BOOLEAN DEFAULT FALSE;

-- Agregar rol 'organizador' a usuarios
ALTER TABLE usuarios MODIFY COLUMN rol ENUM('admin','organizador','usuario') DEFAULT 'usuario';

-- Tabla: actividades
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

-- Tabla: recursos
CREATE TABLE IF NOT EXISTS recursos (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(255) NOT NULL,
  categoria VARCHAR(100),
  cantidad INT DEFAULT 1,
  estado ENUM('disponible','en_uso','mantenimiento') DEFAULT 'disponible',
  descripcion TEXT,
  creado_en DATETIME DEFAULT NOW(),
  client_uuid CHAR(36) NULL UNIQUE,
  updated_at DATETIME NULL DEFAULT NOW() ON UPDATE CURRENT_TIMESTAMP
);

-- Tabla: evento_recursos
CREATE TABLE IF NOT EXISTS evento_recursos (
  id INT AUTO_INCREMENT PRIMARY KEY,
  evento_id INT NOT NULL,
  recurso_id INT NOT NULL,
  cantidad_asignada INT DEFAULT 1,
  FOREIGN KEY (evento_id) REFERENCES eventos(id) ON DELETE CASCADE,
  FOREIGN KEY (recurso_id) REFERENCES recursos(id) ON DELETE CASCADE
);

-- Tabla: auditoria
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

-- Índices de rendimiento
CREATE INDEX IF NOT EXISTS idx_eventos_fecha ON eventos(fecha);
CREATE INDEX IF NOT EXISTS idx_eventos_estado ON eventos(estado);
CREATE INDEX IF NOT EXISTS idx_eventos_tipo ON eventos(tipo);
CREATE INDEX IF NOT EXISTS idx_eventos_sede ON eventos(sede_id);
CREATE INDEX IF NOT EXISTS idx_participantes_evento ON participantes(evento_id);

-- Índices para sincronización offline (?since=)
CREATE INDEX IF NOT EXISTS idx_sedes_updated_at ON sedes(updated_at);
CREATE INDEX IF NOT EXISTS idx_salas_updated_at ON salas(updated_at);
CREATE INDEX IF NOT EXISTS idx_eventos_updated_at ON eventos(updated_at);
CREATE INDEX IF NOT EXISTS idx_pagos_updated_at ON pagos(updated_at);
CREATE INDEX IF NOT EXISTS idx_participantes_updated_at ON participantes(updated_at);
CREATE INDEX IF NOT EXISTS idx_cotizaciones_updated_at ON cotizaciones(updated_at);
CREATE INDEX IF NOT EXISTS idx_recursos_updated_at ON recursos(updated_at);
