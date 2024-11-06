-- Active: 1729102093806@@127.0.0.1@3306@mysql_database
CREATE SCHEMA IF NOT EXISTS proyectos_ciencia_tecnologia

-- estuctura de la tabla: https://datos.gob.ar/dataset/mincyt-proyectos-ciencia-tecnologia-e-innovacion/archivo/mincyt_7229ebac-6b7d-4680-8442-2c31ee3be934
CREATE TABLE IF NOT EXISTS proyectos_ciencia_tecnologia.funcion (
    id INT PRIMARY KEY,
    descripcion TEXT
);

-- estuctura de la tabla: https://datos.gob.ar/dataset/mincyt-proyectos-ciencia-tecnologia-e-innovacion/archivo/mincyt_731e60e6-b040-45c7-b031-1f08e2eaa7f1
CREATE TABLE IF NOT EXISTS proyectos_ciencia_tecnologia.estado_proyecto (
    id INT PRIMARY KEY,
    descripcion TEXT
);

-- estuctura de la tabla: https://datos.gob.ar/dataset/mincyt-proyectos-ciencia-tecnologia-e-innovacion/archivo/mincyt_e8510c58-1d69-4847-8284-4d28353b58e9
CREATE TABLE IF NOT EXISTS proyectos_ciencia_tecnologia.tipo_proyecto (
    id INT PRIMARY KEY,
    sigla VARCHAR(50),
    descripcion TEXT,
    tipo_proyecto_cyt_id INTEGER,
    tipo_proyecto_cyt_desc TEXT
);

-- estuctura de la tabla: https://datos.gob.ar/dataset/mincyt-proyectos-ciencia-tecnologia-e-innovacion/archivo/mincyt_93df382f-3254-4d45-89cb-85d809776598
CREATE TABLE IF NOT EXISTS proyectos_ciencia_tecnologia.moneda (
    id INT PRIMARY KEY,
    moneda VARCHAR(20),
    simbolo VARCHAR(20) 
);

-- estuctura de la tabla: https://datos.gob.ar/dataset/mincyt-proyectos-ciencia-tecnologia-e-innovacion/archivo/mincyt_1485e432-60f8-4f93-9710-8266d7e98c24
CREATE TABLE IF NOT EXISTS proyectos_ciencia_tecnologia.disciplina (
    id INT PRIMARY KEY,
    gran_area_codigo INTEGER,
    gran_area_descripcion TEXT,
    area_codigo INTEGER,
    area_descripcion TEXT,
    disciplina_codigo VARCHAR(20),
    disciplina_descripcion TEXT
);

-- estructura de la tabla: https://datos.gob.ar/dataset/mincyt-proyectos-ciencia-tecnologia-e-innovacion/archivo/mincyt_7155bdc8-c361-437c-9158-8eaa88f3d555
CREATE TABLE IF NOT EXISTS proyectos_ciencia_tecnologia.proyecto_participante (
    id INT PRIMARY KEY,
    proyecto_id INTEGER,
    persona_id INTEGER,
    funcion_id INTEGER,
    fecha_inicio DATE,
    fecha_fin DATE,
    FOREIGN KEY (funcion_id) REFERENCES funcion(id)
);

-- estructura de la tabla: https://datos.gob.ar/dataset/mincyt-proyectos-ciencia-tecnologia-e-innovacion/archivo/mincyt_aa97dfd8-4146-4f07-97b5-c36c6a7e9521
CREATE TABLE IF NOT EXISTS proyectos_ciencia_tecnologia.proyecto_disciplina (
    id INT PRIMARY KEY,
    proyecto_id INTEGER,
    disciplina_id INTEGER,
    FOREIGN KEY (disciplina_id) REFERENCES disciplina(id)
)

-- estructura de la tabla: https://datos.gob.ar/dataset/mincyt-proyectos-ciencia-tecnologia-e-innovacion/archivo/mincyt_28ec732b-b0de-4430-9029-70af77c968e8
CREATE TABLE IF NOT EXISTS proyectos_ciencia_tecnologia.proyecto_beneficiario (
    id INT PRIMARY KEY,
    proyecto_id INTEGER,
    organizacion_id INTEGER,
    persona_id INTEGER,
    financiadora CHAR,
    ejecutora CHAR,
    evaluadora CHAR,
    adoptante CHAR,
    beneficiaria CHAR,
    adquiriente CHAR,
    porcentaje_financiamiento DECIMAL(5, 2)
);

-- estructura de la tabla: https://datos.gob.ar/dataset/mincyt-proyectos-ciencia-tecnologia-e-innovacion/archivo/mincyt_bccbd57e-3a22-4f77-a6e4-5ad3296f981f
CREATE TABLE IF NOT EXISTS proyectos_ciencia_tecnologia.proyectos (
    id INT PRIMARY KEY,
    proyecto_fuente TEXT,
    titulo TEXT,
    fecha_inicio DATE,
    fecha_finalizacion DATE,
    resumen TEXT,
    moneda_id INTEGER,
    monto_total_solicitado INTEGER,
    monto_total_adjudicado INTEGER,
    monto_financiado_solicitado INTEGER,
    monto_financiado_adjudicado INTEGER,
    tipo_proyecto_id INTEGER,
    codigo_identificacion TEXT,
    palabras_clave TEXT,
    estado_id INTEGER,
    fondo_anpcyt TEXT,
    cantidad_miembros_F INTEGER,
    cantidad_miembros_M INTEGER,
    sexo_director TEXT,
    anio INTEGER,
    FOREIGN KEY (moneda_id) REFERENCES moneda(id),
    FOREIGN KEY (tipo_proyecto_id) REFERENCES tipo_proyecto(id),
    FOREIGN KEY (estado_id) REFERENCES estado_proyecto(id)
);

-- DROP TABLE IF EXISTS proyectos_ciencia_tecnologia.proyectos;
-- DROP TABLE IF EXISTS proyectos_ciencia_tecnologia.disciplina;
-- DROP TABLE IF EXISTS proyectos_ciencia_tecnologia.estado_proyecto;
-- DROP TABLE IF EXISTS proyectos_ciencia_tecnologia.funcion;
-- DROP TABLE IF EXISTS proyectos_ciencia_tecnologia.moneda;
-- DROP TABLE IF EXISTS proyectos_ciencia_tecnologia.proyecto_beneficiario;
-- DROP TABLE IF EXISTS proyectos_ciencia_tecnologia.proyecto_disciplina;
-- DROP TABLE IF EXISTS proyectos_ciencia_tecnologia.proyecto_participante;
-- DROP TABLE IF EXISTS proyectos_ciencia_tecnologia.tipo_proyecto;

CREATE OR REPLACE VIEW proyectos_ciencia_tecnologia.detalle_proyectos AS
SELECT 
    p.id AS proyecto_id,
    p.proyecto_fuente,
    p.titulo,
    p.fecha_inicio,
    p.fecha_finalizacion,
    p.resumen,
    m.moneda AS moneda_nombre,
    m.simbolo AS moneda_simbolo,
    p.monto_total_solicitado,
    p.monto_total_adjudicado,
    p.monto_financiado_solicitado,
    p.monto_financiado_adjudicado,
    tp.sigla AS tipo_proyecto_sigla,
    tp.descripcion AS tipo_proyecto_descripcion,
    ep.descripcion AS estado_proyecto_descripcion,
    p.codigo_identificacion,
    p.palabras_clave,
    p.fondo_anpcyt,
    p.cantidad_miembros_F,
    p.cantidad_miembros_M,
    p.sexo_director,
    p.anio
FROM 
    proyectos_ciencia_tecnologia.proyectos p
LEFT JOIN 
    proyectos_ciencia_tecnologia.moneda m ON p.moneda_id = m.id
LEFT JOIN 
    proyectos_ciencia_tecnologia.tipo_proyecto tp ON p.tipo_proyecto_id = tp.id
LEFT JOIN 
    proyectos_ciencia_tecnologia.estado_proyecto ep ON p.estado_id = ep.id;

CREATE OR REPLACE VIEW proyectos_ciencia_tecnologia.detalle_proyecto_participante AS
SELECT
    pp.proyecto_id AS "proyecto_id",
    pp.persona_id,
    f.descripcion,
    pp.fecha_inicio,
    pp.fecha_fin
FROM 
    proyectos_ciencia_tecnologia.proyecto_participante pp
LEFT JOIN
    proyectos_ciencia_tecnologia.funcion f ON pp.funcion_id = f.id;

CREATE OR REPLACE VIEW proyectos_ciencia_tecnologia.detalle_proyecto_disciplina AS
SELECT
    pd.proyecto_id AS "proyecto_id",
    d.gran_area_codigo,
    d.gran_area_descripcion,
    d.area_codigo,
    d.area_descripcion,
    d.disciplina_codigo,
    d.disciplina_descripcion
FROM 
    proyectos_ciencia_tecnologia.proyecto_disciplina pd
LEFT JOIN
    proyectos_ciencia_tecnologia.disciplina d ON pd.disciplina_id = d.id;