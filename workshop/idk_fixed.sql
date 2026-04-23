-- =========================================================
-- asistencia_qr — esquema corregido
-- Cambios frente a idk.sql (ver workshop/REVISION.md):
--   1. Agregadas tablas Rol, Usuario, Usuario_rol, Metodo_registro.
--   2. Asistencia trazable por Usuario + Metodo_registro (FK).
--   3. Bitacora_actitudinal usa ID_usuario (FK) en vez de VARCHAR libre.
--   4. Docente_guia con Codigo_docente UNIQUE.
--   5. Eliminada columna duplicada Asistencia.Comentario.
--   6. fk_gradoseccion_carrera con ON UPDATE CASCADE.
--   7. Reordenado el bloque de DROP TABLE; quitada la referencia a
--      "actitudinal" (tabla inexistente).
--   8. Seed de Jornada sin Sabado/Domingo.
--   9. Trigger de Asistencia rechaza fechas futuras y exige usuario
--      cuando el registro es Manual.
-- Ejecución:
--   docker exec -i asistencia_mysql mysql -u root -proot asistencia_qr \
--     < workshop/idk_fixed.sql
-- =========================================================

CREATE DATABASE IF NOT EXISTS asistencia_qr;
USE asistencia_qr;

SELECT VERSION() AS version_mysql;

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- Triggers
DROP TRIGGER IF EXISTS trg_asistencia_bu;
DROP TRIGGER IF EXISTS trg_asistencia_bi;
DROP TRIGGER IF EXISTS trg_historial_bu;
DROP TRIGGER IF EXISTS trg_historial_bi;
DROP TRIGGER IF EXISTS trg_gradoseccion_bu;
DROP TRIGGER IF EXISTS trg_gradoseccion_bi;
DROP TRIGGER IF EXISTS trg_carrera_bu;
DROP TRIGGER IF EXISTS trg_carrera_bi;
DROP TRIGGER IF EXISTS trg_nivel_bu;
DROP TRIGGER IF EXISTS trg_nivel_bi;
DROP TRIGGER IF EXISTS trg_docente_bu;
DROP TRIGGER IF EXISTS trg_docente_bi;
DROP TRIGGER IF EXISTS trg_jornada_bu;
DROP TRIGGER IF EXISTS trg_jornada_bi;
DROP TRIGGER IF EXISTS trg_estudiante_bu;
DROP TRIGGER IF EXISTS trg_estudiante_bi;
DROP TRIGGER IF EXISTS trg_estudiante_ai;
DROP TRIGGER IF EXISTS trg_bitacora_actitudinal_bi;
DROP TRIGGER IF EXISTS trg_bitacora_actitudinal_ai;
DROP TRIGGER IF EXISTS trg_actitudinal_est_bu;
DROP TRIGGER IF EXISTS trg_usuario_bi;
DROP TRIGGER IF EXISTS trg_usuario_bu;

-- Orden correcto de DROP: primero hijas, luego maestras.
DROP TABLE IF EXISTS Bitacora_actitudinal;
DROP TABLE IF EXISTS Actitudinal_est;
DROP TABLE IF EXISTS Asistencia;
DROP TABLE IF EXISTS Historial_estudiante;
DROP TABLE IF EXISTS Usuario_rol;
DROP TABLE IF EXISTS Metodo_registro;
DROP TABLE IF EXISTS Estado_asistencia;
DROP TABLE IF EXISTS Grado_seccion;
DROP TABLE IF EXISTS Carrera;
DROP TABLE IF EXISTS Nivel_academico;
DROP TABLE IF EXISTS Docente_guia;
DROP TABLE IF EXISTS Jornada;
DROP TABLE IF EXISTS Periodo_acad;
DROP TABLE IF EXISTS Usuario;
DROP TABLE IF EXISTS Rol;
DROP TABLE IF EXISTS Estudiante;

SET FOREIGN_KEY_CHECKS = 1;

-- =========================================================
-- 1. SEGURIDAD / CUENTAS DE SISTEMA
-- =========================================================

CREATE TABLE Rol (
    ID_rol INT AUTO_INCREMENT PRIMARY KEY,
    Codigo VARCHAR(20) NOT NULL,
    Nombre VARCHAR(60) NOT NULL,
    Descripcion VARCHAR(255) NULL,
    Fecha_creacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uk_rol_codigo UNIQUE (Codigo),
    CONSTRAINT chk_rol_codigo CHECK (CHAR_LENGTH(TRIM(Codigo)) > 0),
    CONSTRAINT chk_rol_nombre CHECK (CHAR_LENGTH(TRIM(Nombre)) > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE Usuario (
    ID_usuario INT AUTO_INCREMENT PRIMARY KEY,
    Username VARCHAR(60) NOT NULL,
    Email VARCHAR(120) NOT NULL,
    Password_hash VARCHAR(255) NOT NULL,
    Nombre VARCHAR(50) NOT NULL,
    Apellido VARCHAR(50) NOT NULL,
    Estado TINYINT UNSIGNED NOT NULL DEFAULT 1,
    Fecha_creacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    Fecha_actualizacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT uk_usuario_username UNIQUE (Username),
    CONSTRAINT uk_usuario_email UNIQUE (Email),
    CONSTRAINT chk_usuario_estado CHECK (Estado IN (1, 2)),
    CONSTRAINT chk_usuario_username CHECK (CHAR_LENGTH(TRIM(Username)) >= 3),
    CONSTRAINT chk_usuario_email CHECK (Email LIKE '%_@__%.__%'),
    CONSTRAINT chk_usuario_nombre CHECK (CHAR_LENGTH(TRIM(Nombre)) > 0),
    CONSTRAINT chk_usuario_apellido CHECK (CHAR_LENGTH(TRIM(Apellido)) > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE Usuario_rol (
    ID_usuario INT NOT NULL,
    ID_rol INT NOT NULL,
    Fecha_asignacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (ID_usuario, ID_rol),

    CONSTRAINT fk_usuariorol_usuario
        FOREIGN KEY (ID_usuario) REFERENCES Usuario(ID_usuario)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_usuariorol_rol
        FOREIGN KEY (ID_rol) REFERENCES Rol(ID_rol)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- 2. CATÁLOGOS MAESTROS
-- =========================================================

CREATE TABLE Estudiante (
    ID_estudiante INT AUTO_INCREMENT PRIMARY KEY,
    Nombre VARCHAR(50) NOT NULL,
    Apellido VARCHAR(50) NOT NULL,
    Codigo_personal VARCHAR(20) NOT NULL,
    Estado TINYINT UNSIGNED NOT NULL DEFAULT 1,
    Fecha_creacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    Fecha_actualizacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT uk_estudiante_codigo UNIQUE (Codigo_personal),
    CONSTRAINT chk_estudiante_estado CHECK (Estado IN (1, 2)),
    CONSTRAINT chk_estudiante_nombre CHECK (CHAR_LENGTH(TRIM(Nombre)) > 0),
    CONSTRAINT chk_estudiante_apellido CHECK (CHAR_LENGTH(TRIM(Apellido)) > 0),
    CONSTRAINT chk_estudiante_codigo_personal CHECK (CHAR_LENGTH(TRIM(Codigo_personal)) >= 4)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE Periodo_acad (
    ID_periodo INT AUTO_INCREMENT PRIMARY KEY,
    Unidad TINYINT UNSIGNED NOT NULL,
    Anio YEAR NOT NULL,
    Fecha_creacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uk_periodo_unidad_anio UNIQUE (Unidad, Anio),
    CONSTRAINT chk_periodo_unidad CHECK (Unidad BETWEEN 1 AND 4)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE Jornada (
    ID_jornada INT AUTO_INCREMENT PRIMARY KEY,
    Nombre_jornada VARCHAR(50) NOT NULL,

    CONSTRAINT uk_jornada_nombre UNIQUE (Nombre_jornada),
    CONSTRAINT chk_jornada_nombre CHECK (CHAR_LENGTH(TRIM(Nombre_jornada)) > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE Docente_guia (
    ID_docente INT AUTO_INCREMENT PRIMARY KEY,
    Codigo_docente VARCHAR(20) NOT NULL,
    Nombre VARCHAR(50) NOT NULL,
    Apellido VARCHAR(50) NOT NULL,
    ID_usuario INT NULL,
    Estado TINYINT UNSIGNED NOT NULL DEFAULT 1,

    CONSTRAINT uk_docente_codigo UNIQUE (Codigo_docente),
    CONSTRAINT uk_docente_usuario UNIQUE (ID_usuario),
    CONSTRAINT fk_docente_usuario
        FOREIGN KEY (ID_usuario) REFERENCES Usuario(ID_usuario)
        ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT chk_docente_estado CHECK (Estado IN (1, 2)),
    CONSTRAINT chk_docente_codigo CHECK (CHAR_LENGTH(TRIM(Codigo_docente)) > 0),
    CONSTRAINT chk_docente_nombre CHECK (CHAR_LENGTH(TRIM(Nombre)) > 0),
    CONSTRAINT chk_docente_apellido CHECK (CHAR_LENGTH(TRIM(Apellido)) > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE Nivel_academico (
    ID_nivel INT AUTO_INCREMENT PRIMARY KEY,
    Codigo_nivel VARCHAR(10) NOT NULL,
    Nombre_nivel VARCHAR(30) NOT NULL,

    CONSTRAINT uk_nivel_codigo UNIQUE (Codigo_nivel),
    CONSTRAINT uk_nivel_nombre UNIQUE (Nombre_nivel),
    CONSTRAINT chk_nivel_codigo CHECK (Codigo_nivel IN ('PRI', 'BAS', 'DIV')),
    CONSTRAINT chk_nivel_nombre CHECK (CHAR_LENGTH(TRIM(Nombre_nivel)) > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE Carrera (
    ID_carrera INT AUTO_INCREMENT PRIMARY KEY,
    Nombre_carrera VARCHAR(60) NOT NULL,
    Estado TINYINT UNSIGNED NOT NULL DEFAULT 1,

    CONSTRAINT uk_carrera_nombre UNIQUE (Nombre_carrera),
    CONSTRAINT chk_carrera_estado CHECK (Estado IN (1, 2)),
    CONSTRAINT chk_carrera_nombre CHECK (CHAR_LENGTH(TRIM(Nombre_carrera)) > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE Metodo_registro (
    ID_metodo INT AUTO_INCREMENT PRIMARY KEY,
    Codigo VARCHAR(15) NOT NULL,
    Descripcion VARCHAR(100) NOT NULL,

    CONSTRAINT uk_metodo_codigo UNIQUE (Codigo),
    CONSTRAINT chk_metodo_codigo CHECK (CHAR_LENGTH(TRIM(Codigo)) > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- 3. ACTITUDINAL + BITÁCORA
-- =========================================================

CREATE TABLE Actitudinal_est (
    ID_actitudinal INT AUTO_INCREMENT PRIMARY KEY,
    ID_estudiante INT NOT NULL,
    ID_periodo INT NOT NULL,
    Punteo_actual DECIMAL(4,2) NOT NULL DEFAULT 10.00,
    Fecha_creacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    Fecha_actualizacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_actitudinal_estudiante
        FOREIGN KEY (ID_estudiante) REFERENCES Estudiante(ID_estudiante)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_actitudinal_periodo
        FOREIGN KEY (ID_periodo) REFERENCES Periodo_acad(ID_periodo)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT uk_actitudinal_estudiante_periodo UNIQUE (ID_estudiante, ID_periodo),
    CONSTRAINT chk_actitudinal_punteo CHECK (Punteo_actual BETWEEN 0 AND 10)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE Bitacora_actitudinal (
    ID_bitacora INT AUTO_INCREMENT PRIMARY KEY,
    ID_actitudinal INT NOT NULL,
    ID_usuario INT NOT NULL,
    Tipo_movimiento VARCHAR(10) NOT NULL,
    Puntos DECIMAL(4,2) NOT NULL,
    Punteo_anterior DECIMAL(4,2) NOT NULL,
    Punteo_nuevo DECIMAL(4,2) NOT NULL,
    Comentario VARCHAR(255) NOT NULL,
    Fecha_movimiento TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_bitacora_actitudinal
        FOREIGN KEY (ID_actitudinal) REFERENCES Actitudinal_est(ID_actitudinal)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_bitacora_usuario
        FOREIGN KEY (ID_usuario) REFERENCES Usuario(ID_usuario)
        ON UPDATE CASCADE ON DELETE RESTRICT,

    CONSTRAINT chk_bitacora_tipo CHECK (Tipo_movimiento IN ('SUMA', 'RESTA')),
    CONSTRAINT chk_bitacora_puntos CHECK (Puntos > 0 AND Puntos <= 10),
    CONSTRAINT chk_bitacora_comentario CHECK (CHAR_LENGTH(TRIM(Comentario)) > 0),
    CONSTRAINT chk_bitacora_rango_nuevo CHECK (Punteo_nuevo BETWEEN 0 AND 10),
    CONSTRAINT chk_bitacora_rango_anterior CHECK (Punteo_anterior BETWEEN 0 AND 10)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- 4. ESTRUCTURA ACADÉMICA
-- =========================================================

CREATE TABLE Grado_seccion (
    ID_gradoseccion INT AUTO_INCREMENT PRIMARY KEY,
    Grado TINYINT UNSIGNED NOT NULL,
    Seccion VARCHAR(5) NOT NULL,
    ID_nivel INT NOT NULL,
    ID_jornada INT NOT NULL,
    ID_docente INT NULL,
    ID_carrera INT NULL,
    ID_periodo INT NOT NULL,

    ID_carrera_key INT GENERATED ALWAYS AS (IFNULL(ID_carrera, 0)) STORED,

    Fecha_creacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    Fecha_actualizacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_gradoseccion_nivel
        FOREIGN KEY (ID_nivel) REFERENCES Nivel_academico(ID_nivel)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_gradoseccion_jornada
        FOREIGN KEY (ID_jornada) REFERENCES Jornada(ID_jornada)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_gradoseccion_docente
        FOREIGN KEY (ID_docente) REFERENCES Docente_guia(ID_docente)
        ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT fk_gradoseccion_carrera
        FOREIGN KEY (ID_carrera) REFERENCES Carrera(ID_carrera)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_gradoseccion_periodo
        FOREIGN KEY (ID_periodo) REFERENCES Periodo_acad(ID_periodo)
        ON UPDATE CASCADE ON DELETE RESTRICT,

    CONSTRAINT chk_gradoseccion_grado CHECK (Grado BETWEEN 1 AND 6),
    CONSTRAINT chk_gradoseccion_seccion CHECK (CHAR_LENGTH(TRIM(Seccion)) > 0),
    CONSTRAINT uk_gradoseccion UNIQUE (ID_nivel, Grado, Seccion, ID_jornada, ID_carrera_key, ID_periodo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE Historial_estudiante (
    ID_historial INT AUTO_INCREMENT PRIMARY KEY,
    ID_estudiante INT NULL,
    ID_gradoseccion INT NOT NULL,

    Nombre_completo VARCHAR(120) NOT NULL,
    Grado_seccion_texto VARCHAR(120) NOT NULL,
    Nombre_jornada VARCHAR(50) NOT NULL,
    Codigo_personal VARCHAR(20) NOT NULL,

    Fecha_inicio DATETIME NOT NULL,
    Fecha_fin DATETIME NULL,

    Fecha_creacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    Fecha_actualizacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_historial_estudiante
        FOREIGN KEY (ID_estudiante) REFERENCES Estudiante(ID_estudiante)
        ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT fk_historial_gradoseccion
        FOREIGN KEY (ID_gradoseccion) REFERENCES Grado_seccion(ID_gradoseccion)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_historial_fechas CHECK (Fecha_fin IS NULL OR Fecha_fin > Fecha_inicio)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- 5. ASISTENCIA
-- =========================================================

CREATE TABLE Estado_asistencia (
    ID_estado INT AUTO_INCREMENT PRIMARY KEY,
    Nombre_estado VARCHAR(15) NOT NULL,

    CONSTRAINT uk_estado_asistencia_nombre UNIQUE (Nombre_estado),
    CONSTRAINT chk_estado_asistencia_nombre CHECK (Nombre_estado IN ('Presente', 'Tarde', 'Ausente'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE Asistencia (
    ID_asistencia INT AUTO_INCREMENT PRIMARY KEY,
    ID_estudiante INT NOT NULL,
    ID_estado INT NOT NULL,
    ID_metodo INT NOT NULL,
    ID_usuario_registro INT NULL,
    Fecha DATE NOT NULL,
    Hora TIME NULL,
    Observacion VARCHAR(255) NULL,
    Fecha_creacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    Fecha_actualizacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_asistencia_estudiante
        FOREIGN KEY (ID_estudiante) REFERENCES Estudiante(ID_estudiante)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_asistencia_estado
        FOREIGN KEY (ID_estado) REFERENCES Estado_asistencia(ID_estado)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_asistencia_metodo
        FOREIGN KEY (ID_metodo) REFERENCES Metodo_registro(ID_metodo)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_asistencia_usuario
        FOREIGN KEY (ID_usuario_registro) REFERENCES Usuario(ID_usuario)
        ON UPDATE CASCADE ON DELETE SET NULL,

    CONSTRAINT uk_asistencia_estudiante_fecha UNIQUE (ID_estudiante, Fecha),
    CONSTRAINT chk_asistencia_observacion CHECK (Observacion IS NULL OR CHAR_LENGTH(TRIM(Observacion)) > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- 6. ÍNDICES
-- =========================================================

CREATE INDEX idx_historial_estudiante_fechas
    ON Historial_estudiante (ID_estudiante, Fecha_inicio, Fecha_fin);
CREATE INDEX idx_historial_gradoseccion
    ON Historial_estudiante (ID_gradoseccion);
CREATE INDEX idx_asistencia_fecha_estado
    ON Asistencia (Fecha, ID_estado);
CREATE INDEX idx_asistencia_usuario
    ON Asistencia (ID_usuario_registro);
CREATE INDEX idx_asistencia_metodo
    ON Asistencia (ID_metodo);
CREATE INDEX idx_gradoseccion_periodo
    ON Grado_seccion (ID_periodo);
CREATE INDEX idx_gradoseccion_docente
    ON Grado_seccion (ID_docente);
CREATE INDEX idx_bitacora_usuario
    ON Bitacora_actitudinal (ID_usuario);

-- =========================================================
-- 7. TRIGGERS
-- =========================================================
DELIMITER $$

CREATE TRIGGER trg_usuario_bi
BEFORE INSERT ON Usuario
FOR EACH ROW
BEGIN
    SET NEW.Username = TRIM(NEW.Username);
    SET NEW.Email = LOWER(TRIM(NEW.Email));
    SET NEW.Nombre = TRIM(NEW.Nombre);
    SET NEW.Apellido = TRIM(NEW.Apellido);

    IF CHAR_LENGTH(NEW.Username) < 3 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El username debe tener al menos 3 caracteres.';
    END IF;
    IF NEW.Email NOT LIKE '%_@__%.__%' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Formato de email inválido.';
    END IF;
    IF NEW.Estado NOT IN (1, 2) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Estado de usuario inválido.';
    END IF;
END$$

CREATE TRIGGER trg_usuario_bu
BEFORE UPDATE ON Usuario
FOR EACH ROW
BEGIN
    SET NEW.Username = TRIM(NEW.Username);
    SET NEW.Email = LOWER(TRIM(NEW.Email));
    SET NEW.Nombre = TRIM(NEW.Nombre);
    SET NEW.Apellido = TRIM(NEW.Apellido);

    IF CHAR_LENGTH(NEW.Username) < 3 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El username debe tener al menos 3 caracteres.';
    END IF;
    IF NEW.Email NOT LIKE '%_@__%.__%' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Formato de email inválido.';
    END IF;
    IF NEW.Estado NOT IN (1, 2) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Estado de usuario inválido.';
    END IF;
END$$

CREATE TRIGGER trg_estudiante_bi
BEFORE INSERT ON Estudiante
FOR EACH ROW
BEGIN
    SET NEW.Nombre = TRIM(NEW.Nombre);
    SET NEW.Apellido = TRIM(NEW.Apellido);
    SET NEW.Codigo_personal = TRIM(NEW.Codigo_personal);

    IF NEW.Nombre = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El nombre del estudiante no puede estar vacío.';
    END IF;
    IF NEW.Apellido = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El apellido del estudiante no puede estar vacío.';
    END IF;
    IF CHAR_LENGTH(NEW.Codigo_personal) < 4 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El código personal debe tener al menos 4 caracteres.';
    END IF;
    IF NEW.Estado NOT IN (1, 2) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Estado de estudiante inválido.';
    END IF;
END$$

CREATE TRIGGER trg_estudiante_bu
BEFORE UPDATE ON Estudiante
FOR EACH ROW
BEGIN
    SET NEW.Nombre = TRIM(NEW.Nombre);
    SET NEW.Apellido = TRIM(NEW.Apellido);
    SET NEW.Codigo_personal = TRIM(NEW.Codigo_personal);

    IF NEW.Nombre = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El nombre del estudiante no puede estar vacío.';
    END IF;
    IF NEW.Apellido = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El apellido del estudiante no puede estar vacío.';
    END IF;
    IF CHAR_LENGTH(NEW.Codigo_personal) < 4 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El código personal debe tener al menos 4 caracteres.';
    END IF;
    IF NEW.Estado NOT IN (1, 2) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Estado de estudiante inválido.';
    END IF;
END$$

CREATE TRIGGER trg_jornada_bi
BEFORE INSERT ON Jornada
FOR EACH ROW
BEGIN
    SET NEW.Nombre_jornada = TRIM(NEW.Nombre_jornada);
    IF NEW.Nombre_jornada = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El nombre de la jornada no puede estar vacío.';
    END IF;
END$$

CREATE TRIGGER trg_jornada_bu
BEFORE UPDATE ON Jornada
FOR EACH ROW
BEGIN
    SET NEW.Nombre_jornada = TRIM(NEW.Nombre_jornada);
    IF NEW.Nombre_jornada = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El nombre de la jornada no puede estar vacío.';
    END IF;
END$$

CREATE TRIGGER trg_docente_bi
BEFORE INSERT ON Docente_guia
FOR EACH ROW
BEGIN
    SET NEW.Codigo_docente = UPPER(TRIM(NEW.Codigo_docente));
    SET NEW.Nombre = TRIM(NEW.Nombre);
    SET NEW.Apellido = TRIM(NEW.Apellido);

    IF NEW.Codigo_docente = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El código del docente es obligatorio.';
    END IF;
    IF NEW.Nombre = '' OR NEW.Apellido = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Nombre y apellido del docente son obligatorios.';
    END IF;
    IF NEW.Estado NOT IN (1, 2) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Estado de docente inválido.';
    END IF;
END$$

CREATE TRIGGER trg_docente_bu
BEFORE UPDATE ON Docente_guia
FOR EACH ROW
BEGIN
    SET NEW.Codigo_docente = UPPER(TRIM(NEW.Codigo_docente));
    SET NEW.Nombre = TRIM(NEW.Nombre);
    SET NEW.Apellido = TRIM(NEW.Apellido);

    IF NEW.Codigo_docente = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El código del docente es obligatorio.';
    END IF;
    IF NEW.Nombre = '' OR NEW.Apellido = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Nombre y apellido del docente son obligatorios.';
    END IF;
    IF NEW.Estado NOT IN (1, 2) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Estado de docente inválido.';
    END IF;
END$$

CREATE TRIGGER trg_nivel_bi
BEFORE INSERT ON Nivel_academico
FOR EACH ROW
BEGIN
    SET NEW.Codigo_nivel = UPPER(TRIM(NEW.Codigo_nivel));
    SET NEW.Nombre_nivel = TRIM(NEW.Nombre_nivel);
    IF NEW.Codigo_nivel NOT IN ('PRI', 'BAS', 'DIV') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Código de nivel inválido. Use PRI, BAS o DIV.';
    END IF;
    IF NEW.Nombre_nivel = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El nombre del nivel no puede estar vacío.';
    END IF;
END$$

CREATE TRIGGER trg_nivel_bu
BEFORE UPDATE ON Nivel_academico
FOR EACH ROW
BEGIN
    SET NEW.Codigo_nivel = UPPER(TRIM(NEW.Codigo_nivel));
    SET NEW.Nombre_nivel = TRIM(NEW.Nombre_nivel);
    IF NEW.Codigo_nivel NOT IN ('PRI', 'BAS', 'DIV') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Código de nivel inválido. Use PRI, BAS o DIV.';
    END IF;
    IF NEW.Nombre_nivel = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El nombre del nivel no puede estar vacío.';
    END IF;
END$$

CREATE TRIGGER trg_carrera_bi
BEFORE INSERT ON Carrera
FOR EACH ROW
BEGIN
    SET NEW.Nombre_carrera = TRIM(NEW.Nombre_carrera);
    IF NEW.Nombre_carrera = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El nombre de la carrera no puede estar vacío.';
    END IF;
    IF NEW.Estado NOT IN (1, 2) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Estado de carrera inválido.';
    END IF;
END$$

CREATE TRIGGER trg_carrera_bu
BEFORE UPDATE ON Carrera
FOR EACH ROW
BEGIN
    SET NEW.Nombre_carrera = TRIM(NEW.Nombre_carrera);
    IF NEW.Nombre_carrera = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El nombre de la carrera no puede estar vacío.';
    END IF;
    IF NEW.Estado NOT IN (1, 2) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Estado de carrera inválido.';
    END IF;
END$$

CREATE TRIGGER trg_gradoseccion_bi
BEFORE INSERT ON Grado_seccion
FOR EACH ROW
BEGIN
    DECLARE v_codigo_nivel VARCHAR(10);

    SET NEW.Seccion = UPPER(TRIM(NEW.Seccion));
    IF NEW.Seccion = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La sección no puede estar vacía.';
    END IF;

    SELECT Codigo_nivel INTO v_codigo_nivel
      FROM Nivel_academico WHERE ID_nivel = NEW.ID_nivel LIMIT 1;

    IF v_codigo_nivel IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El nivel académico indicado no existe.';
    ELSEIF v_codigo_nivel = 'PRI' THEN
        IF NEW.Grado NOT BETWEEN 1 AND 6 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'En Primaria solo se permiten grados del 1 al 6.';
        END IF;
        IF NEW.ID_carrera IS NOT NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Primaria no debe tener carrera asignada.';
        END IF;
    ELSEIF v_codigo_nivel = 'BAS' THEN
        IF NEW.Grado NOT BETWEEN 1 AND 3 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'En Básico solo se permiten grados del 1 al 3.';
        END IF;
        IF NEW.ID_carrera IS NOT NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Básico no debe tener carrera asignada.';
        END IF;
    ELSEIF v_codigo_nivel = 'DIV' THEN
        IF NEW.Grado NOT BETWEEN 1 AND 3 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'En Diversificado solo se permiten grados del 1 al 3.';
        END IF;
        IF NEW.ID_carrera IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Diversificado requiere una carrera asignada.';
        END IF;
    END IF;
END$$

CREATE TRIGGER trg_gradoseccion_bu
BEFORE UPDATE ON Grado_seccion
FOR EACH ROW
BEGIN
    DECLARE v_codigo_nivel VARCHAR(10);

    SET NEW.Seccion = UPPER(TRIM(NEW.Seccion));
    IF NEW.Seccion = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La sección no puede estar vacía.';
    END IF;

    SELECT Codigo_nivel INTO v_codigo_nivel
      FROM Nivel_academico WHERE ID_nivel = NEW.ID_nivel LIMIT 1;

    IF v_codigo_nivel IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El nivel académico indicado no existe.';
    ELSEIF v_codigo_nivel = 'PRI' THEN
        IF NEW.Grado NOT BETWEEN 1 AND 6 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'En Primaria solo se permiten grados del 1 al 6.';
        END IF;
        IF NEW.ID_carrera IS NOT NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Primaria no debe tener carrera asignada.';
        END IF;
    ELSEIF v_codigo_nivel = 'BAS' THEN
        IF NEW.Grado NOT BETWEEN 1 AND 3 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'En Básico solo se permiten grados del 1 al 3.';
        END IF;
        IF NEW.ID_carrera IS NOT NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Básico no debe tener carrera asignada.';
        END IF;
    ELSEIF v_codigo_nivel = 'DIV' THEN
        IF NEW.Grado NOT BETWEEN 1 AND 3 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'En Diversificado solo se permiten grados del 1 al 3.';
        END IF;
        IF NEW.ID_carrera IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Diversificado requiere una carrera asignada.';
        END IF;
    END IF;
END$$

CREATE TRIGGER trg_historial_bi
BEFORE INSERT ON Historial_estudiante
FOR EACH ROW
BEGIN
    DECLARE v_nombre VARCHAR(50);
    DECLARE v_apellido VARCHAR(50);
    DECLARE v_codigo_personal VARCHAR(20);
    DECLARE v_grado TINYINT;
    DECLARE v_seccion VARCHAR(5);
    DECLARE v_jornada VARCHAR(50);
    DECLARE v_nivel_nombre VARCHAR(30);
    DECLARE v_carrera_nombre VARCHAR(60);
    DECLARE v_codigo_nivel VARCHAR(10);

    IF NEW.ID_estudiante IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El historial debe asociarse a un estudiante al crearse.';
    END IF;
    IF NEW.Fecha_fin IS NOT NULL AND NEW.Fecha_fin <= NEW.Fecha_inicio THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La Fecha_fin debe ser mayor que Fecha_inicio.';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM Estudiante WHERE ID_estudiante = NEW.ID_estudiante) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El estudiante indicado no existe.';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM Grado_seccion WHERE ID_gradoseccion = NEW.ID_gradoseccion) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La asignación de grado/sección indicada no existe.';
    END IF;

    IF NEW.Fecha_fin IS NULL AND EXISTS (
        SELECT 1 FROM Historial_estudiante
         WHERE ID_estudiante = NEW.ID_estudiante AND Fecha_fin IS NULL
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El estudiante ya tiene una asignación académica activa.';
    END IF;

    IF EXISTS (
        SELECT 1 FROM Historial_estudiante h
         WHERE h.ID_estudiante = NEW.ID_estudiante
           AND (
               (NEW.Fecha_fin IS NULL AND (h.Fecha_fin IS NULL OR h.Fecha_fin > NEW.Fecha_inicio))
               OR (NEW.Fecha_fin IS NOT NULL AND h.Fecha_inicio < NEW.Fecha_fin
                   AND (h.Fecha_fin IS NULL OR h.Fecha_fin > NEW.Fecha_inicio))
           )
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El período del historial se traslapa con otro registro del mismo estudiante.';
    END IF;

    SELECT e.Nombre, e.Apellido, e.Codigo_personal
      INTO v_nombre, v_apellido, v_codigo_personal
      FROM Estudiante e WHERE e.ID_estudiante = NEW.ID_estudiante LIMIT 1;

    SELECT gs.Grado, gs.Seccion, j.Nombre_jornada,
           n.Nombre_nivel, n.Codigo_nivel, c.Nombre_carrera
      INTO v_grado, v_seccion, v_jornada, v_nivel_nombre, v_codigo_nivel, v_carrera_nombre
      FROM Grado_seccion gs
      JOIN Jornada j ON j.ID_jornada = gs.ID_jornada
      JOIN Nivel_academico n ON n.ID_nivel = gs.ID_nivel
 LEFT JOIN Carrera c ON c.ID_carrera = gs.ID_carrera
     WHERE gs.ID_gradoseccion = NEW.ID_gradoseccion LIMIT 1;

    SET NEW.Nombre_completo = CONCAT(TRIM(v_nombre), ' ', TRIM(v_apellido));
    SET NEW.Codigo_personal = v_codigo_personal;
    SET NEW.Nombre_jornada = v_jornada;

    IF v_codigo_nivel = 'DIV' THEN
        SET NEW.Grado_seccion_texto = CONCAT(v_grado, ' ', v_nivel_nombre, ' - ', v_carrera_nombre, ' Sección ', v_seccion);
    ELSE
        SET NEW.Grado_seccion_texto = CONCAT(v_grado, ' ', v_nivel_nombre, ' Sección ', v_seccion);
    END IF;
END$$

-- Nota: el UPDATE NO recalcula el snapshot de texto para preservar el
-- historial inmutable (cambio frente a idk.sql).
CREATE TRIGGER trg_historial_bu
BEFORE UPDATE ON Historial_estudiante
FOR EACH ROW
BEGIN
    IF NEW.Fecha_fin IS NOT NULL AND NEW.Fecha_fin <= NEW.Fecha_inicio THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La Fecha_fin debe ser mayor que Fecha_inicio.';
    END IF;

    IF NEW.ID_estudiante IS NOT NULL
       AND NEW.Fecha_fin IS NULL
       AND EXISTS (
            SELECT 1 FROM Historial_estudiante
             WHERE ID_estudiante = NEW.ID_estudiante
               AND Fecha_fin IS NULL
               AND ID_historial <> OLD.ID_historial
       ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El estudiante ya tiene otra asignación académica activa.';
    END IF;
END$$

CREATE TRIGGER trg_asistencia_bi
BEFORE INSERT ON Asistencia
FOR EACH ROW
BEGIN
    DECLARE v_estado_nombre VARCHAR(15);
    DECLARE v_estudiante_estado TINYINT;
    DECLARE v_metodo_codigo VARCHAR(15);

    SET NEW.Observacion = NULLIF(TRIM(NEW.Observacion), '');

    IF NEW.Fecha > CURDATE() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se permite registrar asistencias con fecha futura.';
    END IF;

    SELECT Estado INTO v_estudiante_estado
      FROM Estudiante WHERE ID_estudiante = NEW.ID_estudiante LIMIT 1;
    IF v_estudiante_estado IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El estudiante indicado no existe.';
    END IF;
    IF v_estudiante_estado <> 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede registrar asistencia a un estudiante inactivo.';
    END IF;

    SELECT Nombre_estado INTO v_estado_nombre
      FROM Estado_asistencia WHERE ID_estado = NEW.ID_estado LIMIT 1;
    IF v_estado_nombre IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El estado de asistencia indicado no existe.';
    END IF;

    SELECT Codigo INTO v_metodo_codigo
      FROM Metodo_registro WHERE ID_metodo = NEW.ID_metodo LIMIT 1;
    IF v_metodo_codigo IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El método de registro indicado no existe.';
    END IF;

    IF v_metodo_codigo = 'MANUAL' AND NEW.ID_usuario_registro IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Las asistencias manuales requieren un usuario responsable.';
    END IF;

    IF v_estado_nombre = 'Ausente' AND NEW.Hora IS NOT NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Un estudiante ausente no debe tener hora registrada.';
    END IF;
    IF v_estado_nombre IN ('Presente', 'Tarde') AND NEW.Hora IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Presente o Tarde requiere hora registrada.';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM Historial_estudiante h
         WHERE h.ID_estudiante = NEW.ID_estudiante
           AND NEW.Fecha BETWEEN DATE(h.Fecha_inicio) AND IFNULL(DATE(h.Fecha_fin), '9999-12-31')
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El estudiante no tiene asignación académica válida para la fecha de asistencia.';
    END IF;
END$$

CREATE TRIGGER trg_asistencia_bu
BEFORE UPDATE ON Asistencia
FOR EACH ROW
BEGIN
    DECLARE v_estado_nombre VARCHAR(15);
    DECLARE v_estudiante_estado TINYINT;
    DECLARE v_metodo_codigo VARCHAR(15);

    SET NEW.Observacion = NULLIF(TRIM(NEW.Observacion), '');

    IF NEW.Fecha > CURDATE() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se permite registrar asistencias con fecha futura.';
    END IF;

    SELECT Estado INTO v_estudiante_estado
      FROM Estudiante WHERE ID_estudiante = NEW.ID_estudiante LIMIT 1;
    IF v_estudiante_estado IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El estudiante indicado no existe.';
    END IF;
    IF v_estudiante_estado <> 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede registrar asistencia a un estudiante inactivo.';
    END IF;

    SELECT Nombre_estado INTO v_estado_nombre
      FROM Estado_asistencia WHERE ID_estado = NEW.ID_estado LIMIT 1;
    IF v_estado_nombre IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El estado de asistencia indicado no existe.';
    END IF;

    SELECT Codigo INTO v_metodo_codigo
      FROM Metodo_registro WHERE ID_metodo = NEW.ID_metodo LIMIT 1;
    IF v_metodo_codigo IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El método de registro indicado no existe.';
    END IF;

    IF v_metodo_codigo = 'MANUAL' AND NEW.ID_usuario_registro IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Las asistencias manuales requieren un usuario responsable.';
    END IF;

    IF v_estado_nombre = 'Ausente' AND NEW.Hora IS NOT NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Un estudiante ausente no debe tener hora registrada.';
    END IF;
    IF v_estado_nombre IN ('Presente', 'Tarde') AND NEW.Hora IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Presente o Tarde requiere hora registrada.';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM Historial_estudiante h
         WHERE h.ID_estudiante = NEW.ID_estudiante
           AND NEW.Fecha BETWEEN DATE(h.Fecha_inicio) AND IFNULL(DATE(h.Fecha_fin), '9999-12-31')
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El estudiante no tiene asignación académica válida para la fecha de asistencia.';
    END IF;
END$$

CREATE TRIGGER trg_estudiante_ai
AFTER INSERT ON Estudiante
FOR EACH ROW
BEGIN
    DECLARE v_inserted INT DEFAULT 0;

    INSERT INTO Actitudinal_est (ID_estudiante, ID_periodo, Punteo_actual)
    SELECT NEW.ID_estudiante, p.ID_periodo, 10.00
      FROM Periodo_acad p
     WHERE p.Anio = YEAR(CURDATE());

    SET v_inserted = ROW_COUNT();
    IF v_inserted = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No hay períodos académicos cargados para el año actual.';
    END IF;
END$$

CREATE TRIGGER trg_bitacora_actitudinal_bi
BEFORE INSERT ON Bitacora_actitudinal
FOR EACH ROW
BEGIN
    DECLARE v_punteo_actual DECIMAL(4,2);
    DECLARE v_usuario_estado TINYINT;

    SET NEW.Tipo_movimiento = UPPER(TRIM(NEW.Tipo_movimiento));
    SET NEW.Comentario = TRIM(NEW.Comentario);

    IF NEW.Tipo_movimiento NOT IN ('SUMA', 'RESTA') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tipo_movimiento inválido. Use SUMA o RESTA.';
    END IF;
    IF NEW.Puntos <= 0 OR NEW.Puntos > 10 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Los puntos deben ser mayores a 0 y menores o iguales a 10.';
    END IF;
    IF NEW.Comentario = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El comentario no puede estar vacío.';
    END IF;

    SELECT Estado INTO v_usuario_estado
      FROM Usuario WHERE ID_usuario = NEW.ID_usuario LIMIT 1;
    IF v_usuario_estado IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El usuario responsable no existe.';
    END IF;
    IF v_usuario_estado <> 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El usuario responsable está inactivo.';
    END IF;

    SELECT Punteo_actual INTO v_punteo_actual
      FROM Actitudinal_est WHERE ID_actitudinal = NEW.ID_actitudinal LIMIT 1;
    IF v_punteo_actual IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El registro actitudinal indicado no existe.';
    END IF;

    SET NEW.Punteo_anterior = v_punteo_actual;
    IF NEW.Tipo_movimiento = 'SUMA' THEN
        SET NEW.Punteo_nuevo = v_punteo_actual + NEW.Puntos;
    ELSE
        SET NEW.Punteo_nuevo = v_punteo_actual - NEW.Puntos;
    END IF;

    IF NEW.Punteo_nuevo < 0 OR NEW.Punteo_nuevo > 10 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El movimiento deja el punteo fuera del rango permitido (0 a 10).';
    END IF;
END$$

CREATE TRIGGER trg_bitacora_actitudinal_ai
AFTER INSERT ON Bitacora_actitudinal
FOR EACH ROW
BEGIN
    UPDATE Actitudinal_est
       SET Punteo_actual = NEW.Punteo_nuevo
     WHERE ID_actitudinal = NEW.ID_actitudinal;
END$$

CREATE TRIGGER trg_actitudinal_est_bu
BEFORE UPDATE ON Actitudinal_est
FOR EACH ROW
BEGIN
    IF NEW.ID_estudiante <> OLD.ID_estudiante THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se permite cambiar el estudiante de un registro actitudinal.';
    END IF;
    IF NEW.ID_periodo <> OLD.ID_periodo THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se permite cambiar el período de un registro actitudinal.';
    END IF;
    IF NEW.Punteo_actual < 0 OR NEW.Punteo_actual > 10 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El punteo actual debe permanecer entre 0 y 10.';
    END IF;
END$$

DELIMITER ;

-- =========================================================
-- 8. DATOS INICIALES
-- =========================================================

INSERT INTO Rol (Codigo, Nombre, Descripcion) VALUES
('ADMIN', 'Administrador', 'Acceso total al sistema.'),
('DOCENTE', 'Docente', 'Registra asistencias y puntajes actitudinales.'),
('KIOSCO', 'Kiosco QR', 'Cuenta de servicio para lectores QR.'),
('CONSULTA', 'Consulta', 'Solo lectura de reportes.');

INSERT INTO Nivel_academico (Codigo_nivel, Nombre_nivel) VALUES
('PRI', 'Primaria'),
('BAS', 'Basico'),
('DIV', 'Diversificado');

INSERT INTO Estado_asistencia (Nombre_estado) VALUES
('Presente'),
('Tarde'),
('Ausente');

INSERT INTO Jornada (Nombre_jornada) VALUES
('Matutina'),
('Vespertina'),
('Nocturna'),
('Fin de semana');

INSERT INTO Periodo_acad (Unidad, Anio) VALUES
(1, 2026),
(2, 2026),
(3, 2026),
(4, 2026);

INSERT INTO Metodo_registro (Codigo, Descripcion) VALUES
('QR', 'Escaneo de código QR del carnet estudiantil.'),
('MANUAL', 'Registro manual por docente o administrador.');
