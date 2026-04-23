# Revisión del esquema `workshop/idk.sql` — Sistema de Asistencia por QR

> Base: `asistencia_qr` (MySQL 8 / InnoDB / utf8mb4).
> Archivos analizados: `workshop/idk.sql` y `workshop/nose.sql`.

Este documento responde punto por punto a los seis ítems solicitados y se
acompaña del archivo `workshop/idk_fixed.sql`, donde está la propuesta de
esquema corregido.

---

## 1. Entidades esperadas vs. entidades presentes

| Entidad esperada                        | ¿Está? | Tabla en el SQL                                          |
|-----------------------------------------|--------|----------------------------------------------------------|
| Usuarios del sistema (login/auth)       | **No** | — (falta `Usuario`)                                      |
| Roles (RBAC: admin / docente / etc.)    | **No** | — (falta `Rol`, `Usuario_rol`)                           |
| Estudiantes                             | Sí     | `Estudiante`                                             |
| Docentes (guía)                         | Sí     | `Docente_guia`                                           |
| Asistencias                             | Sí     | `Asistencia`                                             |
| Estados de asistencia                   | Sí     | `Estado_asistencia`                                      |
| Período académico                       | Sí     | `Periodo_acad`                                           |
| Estructura académica (grado/sección)    | Sí     | `Grado_seccion`, `Nivel_academico`, `Carrera`, `Jornada` |
| Historial del estudiante                | Sí     | `Historial_estudiante`                                   |
| Actitudinal + bitácora                  | Sí     | `Actitudinal_est`, `Bitacora_actitudinal`                |
| Token/sesión QR (rotación)              | **No** | — (se reutiliza `Codigo_personal` como payload fijo)     |

**Hallazgos clave en este punto:**

- El enunciado pide *usuarios* y *roles*. El esquema **no los modela**. Hoy
  `Docente_guia` y `Estudiante` son entidades de negocio, no cuentas de
  sistema, por lo que nadie puede “iniciar sesión” ni quedar registrado como
  quien marcó una asistencia.
- `Bitacora_actitudinal.Usuario_responsable VARCHAR(100)` es un texto libre;
  debería ser una FK a `Usuario`.
- `Asistencia` no guarda quién registró el escaneo (en QR casi siempre es
  el docente o un kiosco; sin ese dato no hay auditoría).
- No existe una tabla para el **ciclo de vida del QR** (token, vigencia,
  revocación). Si el QR es simplemente `Estudiante.Codigo_personal`, todo
  alumno con foto del carnet ajeno puede marcarse — el modelo no ofrece
  forma de rotar el código sin alterar datos maestros.

---

## 2. Integridad referencial

Puntos positivos:

- Casi todas las FK tienen `ON UPDATE CASCADE` + `ON DELETE RESTRICT` o
  `SET NULL`, lo cual es razonable.
- `Historial_estudiante.ID_estudiante` con `ON DELETE SET NULL` preserva el
  histórico si se borra el alumno.
- Se usa la columna generada `ID_carrera_key` para sortear la semántica
  “NULL ≠ NULL” y poder garantizar unicidad real en `Grado_seccion`.

Problemas detectados:

1. **`fk_gradoseccion_carrera` es inconsistente** con el resto: no declara
   `ON UPDATE CASCADE`. Las demás FKs sí lo hacen.
2. **`Bitacora_actitudinal.Usuario_responsable` no es FK.** Queda como dato
   libre → no hay integridad referencial sobre quién hizo el movimiento.
3. **`Asistencia` no tiene FK a quien la registró** (docente, kiosco,
   admin). Esto rompe trazabilidad esperada en un sistema QR.
4. **Bloque de `DROP TABLE` contiene `actitudinal`** (minúsculas) que **no
   existe** en el `CREATE`. Es residuo de otra versión. Además se dropea
   antes que `Actitudinal_est` y `Bitacora_actitudinal`, que sí son las
   reales; el orden está invertido (hijas después de padres), aunque se
   salva por `SET FOREIGN_KEY_CHECKS = 0`.
5. **Orden lógico de los `CREATE`**: `Actitudinal_est` y
   `Bitacora_actitudinal` están bajo el bloque “TABLAS MAESTRAS” cuando en
   realidad son tablas dependientes (referencian `Estudiante` y
   `Periodo_acad`). Funciona, pero confunde el modelo.
6. **`Historial_estudiante` snapshot vs. FK**: se guardan `Nombre_completo`,
   `Nombre_jornada`, `Codigo_personal`, `Grado_seccion_texto`. Si el
   estudiante o la sección se renombran, el snapshot queda desfasado. Es
   una decisión consciente (historial inmutable), pero debe documentarse;
   hoy el `trg_historial_bu` **sí** recalcula el snapshot en cada UPDATE,
   lo que contradice la intención.

---

## 3. Normalización (evitar redundancia)

- **Redundancia real dentro de `Asistencia`:** existen dos campos que
  cumplen el mismo rol, `Observacion VARCHAR(255) NULL` **y**
  `Comentario VARCHAR(255)`. `Comentario` no está citado en ningún trigger
  ni CHECK; es columna huérfana y duplicada. **Debe eliminarse** (o
  unificarse con `Observacion`).
- **Redundancia controlada en `Historial_estudiante`:** los campos
  snapshot son una desnormalización deliberada para preservar historia
  aunque cambien FKs. Aceptable en 3FN práctica de auditoría, siempre
  que se documente.
- **`Estado TINYINT (1,2)`** en `Estudiante`, `Docente_guia`, `Carrera`.
  Son números mágicos. Lo correcto es un catálogo `Estado_entidad` o
  simplemente `ENUM('ACTIVO','INACTIVO')`. Hoy no es redundancia, pero
  mezcla la semántica de negocio con el tipo de dato.
- **Seed de `Jornada`:** `('Matutina','Vespertina','Sabado','Domingo')`.
  “Jornada/turno” es `Matutina|Vespertina|Nocturna|Fin de semana`. Sábado
  y Domingo son **días**, no jornadas. Mezcla de dominios.

---

## 4. Errores lógicos y restricciones faltantes

1. **Duplicado `Observacion`/`Comentario`** en `Asistencia` (ver §3).
2. **`Docente_guia` sin identificador único**: solo tiene `Nombre` y
   `Apellido`. Dos docentes homónimos colisionan. Falta `Codigo_docente`
   (o DPI) `UNIQUE NOT NULL`.
3. **`Codigo_personal` del estudiante sin longitud mínima útil**: hoy el
   CHECK sólo exige que `TRIM()` tenga longitud > 0. Un carnet real pide
   formato (ej. `^[A-Z0-9]{6,20}$`). Afecta la calidad del QR.
4. **QR vs. payload**: no hay campo `QR_token`, `QR_expires_at`, ni tabla
   `Sesion_qr`. Si alguien duplica el `Codigo_personal` ya no hay forma
   de invalidarlo sin mutar el maestro.
5. **`Asistencia.Metodo_registro` sin FK a catálogo**: se valida por
   `CHECK` + trigger. Mejor una tabla `Metodo_registro(id, nombre)` con
   FK, así se pueden agregar métodos (NFC, huella) sin alterar DDL.
6. **`trg_estudiante_ai` (after insert)**: inserta filas en
   `Actitudinal_est` sólo para periodos con `Anio = YEAR(CURDATE())`. Si
   no existen períodos ese año, **no inserta nada y no falla**: silencio.
   Además crea 4 filas (una por unidad), lo cual mezcla la semántica de
   `Periodo_acad` (unidad bimestral) con “período vigente del alumno”.
7. **Inconsistencia NULL en `Historial_estudiante.ID_estudiante`**: la
   FK es `ON DELETE SET NULL` (permitiendo NULL), pero
   `trg_historial_bi` exige `NOT NULL`. El UPDATE sí contempla el NULL.
   El diseño funciona, pero la contradicción hay que dejarla explícita
   en un comentario o mediante `NOT NULL` en la columna + un segundo
   campo de “estudiante histórico” desnormalizado.
8. **`chk_asistencia_observacion`** exige `TRIM(Observacion) > 0` cuando
   no es NULL, pero el trigger convierte `''` en NULL con `NULLIF(TRIM...)`.
   Con el trigger activo el CHECK es redundante, pero si alguien
   desactiva el trigger (p.ej. `SET @TRIGGER_DISABLED`) el CHECK actúa
   como salvavidas: está bien, sólo documentar.
9. **`Grado_seccion.ID_jornada`/`ID_carrera` sin índices individuales**
   aparte de los de la UK compuesta. Puede no importar, pero conviene
   para FK performance.
10. **`fk_gradoseccion_carrera` sin `ON UPDATE CASCADE`** (ver §2).
11. **`Bitacora_actitudinal.Puntos > 0 AND Puntos <= 10`**: un SUMA/RESTA
    de 10 puntos de un solo golpe es sospechoso. Considerar un tope
    realista (p. ej. 5) o al menos exigir `Comentario` más extenso en
    movimientos mayores.
12. **`idx_historial_estudiante_fechas(ID_estudiante, Fecha_inicio, Fecha_fin)`**:
    útil, pero falta un parcial para “histórico activo”:
    `(ID_estudiante)` donde `Fecha_fin IS NULL`. MySQL no soporta
    índices parciales, así que lo más que podemos ayudar es ese orden.
13. **Trigger `trg_asistencia_bi` con `TIMESTAMP(NEW.Fecha)` aritmético**:
    válido, pero difícil de leer. Podría ser `NEW.Fecha BETWEEN
    DATE(h.Fecha_inicio) AND IFNULL(DATE(h.Fecha_fin), '9999-12-31')`.
14. **Ausencia de `CHECK`** sobre `Asistencia.Fecha <= CURDATE()` para QR
    (no se deberían permitir marcas futuras). Con CHECKs no deterministas
    MySQL 8 protesta, así que va en trigger.
15. **Ausencia de tabla/columna de roles**: sin roles no se puede
    restringir “¿quién puede dar de alta un estudiante?” ni “¿quién
    puede editar asistencias?”. Es el punto más grave para un sistema
    real.

---

## 5. Qué falta y por qué (resumen accionable)

| # | Falta                                              | Por qué importa                                                                 |
|---|----------------------------------------------------|---------------------------------------------------------------------------------|
| 1 | Tabla `Usuario`                                    | Sin cuenta de sistema no hay login ni auditoría real.                           |
| 2 | Tabla `Rol` + `Usuario_rol`                        | Sin RBAC no se puede limitar quién escanea, quién edita, quién ve reportes.    |
| 3 | `Asistencia.ID_usuario_registro`                   | Trazabilidad del QR: quién operó el escaneo / captura manual.                   |
| 4 | `Bitacora_actitudinal.ID_usuario` (FK)             | Hoy `Usuario_responsable` es texto libre, cero integridad.                      |
| 5 | `Docente_guia.Codigo_docente UNIQUE`               | Identificación única del docente (DPI/código institucional).                    |
| 6 | Tabla `Metodo_registro`                            | Catálogo extensible (QR, Manual, NFC, biométrico).                              |
| 7 | Eliminar `Asistencia.Comentario`                   | Campo duplicado de `Observacion`, sin uso.                                      |
| 8 | Arreglar `fk_gradoseccion_carrera`                 | Añadir `ON UPDATE CASCADE` para consistencia.                                   |
| 9 | Quitar `DROP TABLE IF EXISTS actitudinal;`         | Tabla inexistente; residuo de versión anterior.                                 |
|10 | Reordenar `DROP TABLE`                             | Hijas (`Bitacora_actitudinal`, `Actitudinal_est`) antes que `Estudiante`.       |
|11 | Seed `Jornada` correcto                            | Remover `Sabado`/`Domingo`, no son jornadas.                                    |
|12 | CHECK `Asistencia.Fecha <= CURDATE()` por trigger  | Evitar asistencias futuras por error/abuso.                                     |
|13 | Documentar snapshot en `Historial_estudiante`      | Separar intención “snapshot inmutable” vs. “recalculable en UPDATE”.            |

---

## 6. Propuesta de SQL corregido

El archivo [`workshop/idk_fixed.sql`](./idk_fixed.sql) contiene el DDL con
**todos los cambios listados**. Los puntos más importantes:

- Nuevas tablas `Rol`, `Usuario`, `Usuario_rol`, `Metodo_registro`.
- `Asistencia.ID_usuario_registro INT NULL` con FK a `Usuario` y FK a
  `Metodo_registro` (reemplaza el `VARCHAR` con CHECK).
- `Bitacora_actitudinal` reemplaza `Usuario_responsable VARCHAR(100)` por
  `ID_usuario INT NOT NULL` con FK.
- `Docente_guia.Codigo_docente VARCHAR(20) NOT NULL UNIQUE`.
- `Asistencia.Comentario` eliminado; se conserva sólo `Observacion`.
- `fk_gradoseccion_carrera` con `ON UPDATE CASCADE`.
- Orden de `DROP TABLE` corregido; se remueve `DROP TABLE actitudinal`.
- Seed de `Jornada` sin `Sabado`/`Domingo`.
- Nuevo trigger `trg_asistencia_bi` que además:
  - Rechaza `Fecha` futura.
  - Exige `ID_usuario_registro` NOT NULL cuando `Metodo_registro='Manual'`.
- Trigger `trg_bitacora_actitudinal_bi` revisado para usar FK de usuario.

La estructura se mantiene compatible con la intención original; la
migración desde `idk.sql` actual requiere un `ALTER TABLE` por cada
diferencia, pero el `idk_fixed.sql` es autocontenido y reemplaza al
original para un entorno de desarrollo que se reconstruye con el mismo
`docker exec -i ... mysql ... < workshop/idk_fixed.sql`.
