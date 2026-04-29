USE asistencia_qr;

SELECT VERSION() AS version_mysql;

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

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

DROP TABLE IF EXISTS Asistencia;
DROP TABLE IF EXISTS Estado_asistencia;
DROP TABLE IF EXISTS Historial_estudiante;
DROP TABLE IF EXISTS Grado_seccion;
DROP TABLE IF EXISTS Carrera;
DROP TABLE IF EXISTS Nivel_academico;
DROP TABLE IF EXISTS Docente_guia;
DROP TABLE IF EXISTS Jornada;
DROP TABLE IF EXISTS Periodo_acad;
DROP TABLE IF EXISTS Estudiante;
DROP TABLE IF EXISTS actitudinal;

SET FOREIGN_KEY_CHECKS = 1;