-- ==========================================================
-- SCRIPT DE TRABAJO: LABORATORIO HASHY EL GOLOSO (MySQL)
-- TEC - Arquitectura de Datos
-- ==========================================================

-- 1. BITÁCORA DE OPERACIONES (Misión de la Llave 6)
-- Registra el rastro de cada transformación del pipeline.
CREATE TABLE logs_hashy (
    id SERIAL PRIMARY KEY,
    nombre_funcion VARCHAR(255),
    fecha_ejecucion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    mensaje_accion TEXT,
    usuario_db VARCHAR(100) DEFAULT (CURRENT_USER())
);

-- 2. MERCADO NEGRO DE TORTUGA (Misión de la Llave 3)
-- Sirve para realizar las subconsultas de comparación de precios.
CREATE TABLE mercado_negro (
    id SERIAL PRIMARY KEY,
    categoria VARCHAR(100) UNIQUE, 
    precio_referencia DECIMAL(10,2),
    ultima_actualizacion DATE
);

-- 3. INVENTARIO DE GOLOSINAS (La tabla principal)
-- Contiene los datos "sucios" que deben ser procesados por las 7 llaves.
CREATE TABLE inventario_pirata (
    id INT PRIMARY KEY,               -- Usado para la Llave 1 (Primalidad)
    nombre_sucio VARCHAR(255),        -- Usado para la Llave 4 (Sanitización)
    categoria VARCHAR(100),           -- Relación con Mercado Negro
    precio_finca DECIMAL(10,2),       -- Usado para la Llave 3 (Tasación)
    prioridad_logica INT,             -- Metadata adicional
    fecha_ingreso DATE,               -- Usado para la Llave 2 (Reloj de Arena)
    meses_validez INT,                -- Usado para la Llave 2 (Reloj de Arena)
    FOREIGN KEY (categoria) REFERENCES mercado_negro(categoria)
);

-- ==========================================================
-- DATOS SEMILLA
-- ==========================================================

-- Llenado del Mercado Negro
INSERT INTO mercado_negro (categoria, precio_referencia, ultima_actualizacion) VALUES 
('Caramelos', 15.00, '2026-01-01'),
('Chocolates', 45.00, '2026-01-01'),
('Gomitas', 20.00, '2026-01-01');

-- Llenado del Inventario
-- Incluimos la 'Gomita Mágica' (ID 7) para que haya variedad en el resultado.
INSERT INTO inventario_pirata (id, nombre_sucio, categoria, precio_finca, prioridad_logica, fecha_ingreso, meses_validez) VALUES 
(1, '  cArr-Amelo_Menta  ', 'Caramelos', 12.00, 2, '2026-02-15', 6),   -- ID 1: No es primo.
(2, 'CHoco-late...Amargo', 'Chocolates', 55.00, 3, '2025-10-01', 3),     -- ID 2: VENCIDO.
(3, ' gomita-O_O-fresa ', 'Gomitas', 18.00, 4, '2026-03-01', 12),         -- ID 3: PASA (Primo + Fresco).
(4, '---TRUFA_Oscura---', 'Chocolates', 40.00, 5, '2026-01-10', 5),       -- ID 4: No es primo.
(5, 'Caramelo_Salado!!', 'Caramelos', 18.00, 7, '2025-12-01', 2),         -- ID 5: VENCIDO.
(6, 'Gomita_Osa', 'Gomitas', 25.00, 11, '2026-04-10', 8),                  -- ID 6: No es primo.
(7, '  !!Gomita_Mágica??  ', 'Gomitas', 22.00, 13, '2026-04-01', 10);     -- ID 7: PASA (Primo + Fresco).

-- ==========================================================
-- RESULTADO FINAL ESPERADO (VERIFICACIÓN)
-- ==========================================================
-- Los únicos IDs que deben generar un Hash al final son el 3 y el 7.
-- La consulta final debe devolver: hash(ID 3) # hash(ID 7)

-- ==========================================================
-- LLAVE 1: Cernidor (validación de número primo)
-- ==========================================================

DELIMITER $$

CREATE FUNCTION fn_cernidor(p_id INT)
RETURNS BOOLEAN
DETERMINISTIC
BEGIN
    DECLARE es_primo BOOLEAN DEFAULT TRUE;
    DECLARE divisor INT DEFAULT 2;
    DECLARE limite INT;

    -- Los números menores o iguales a 1 no son primos
    IF p_id <= 1 THEN
        SET es_primo = FALSE;
    ELSE
        SET limite = FLOOR(SQRT(p_id));

        ciclo_primos: WHILE divisor <= limite DO
            IF p_id % divisor = 0 THEN
                SET es_primo = FALSE;
                LEAVE ciclo_primos;
            END IF;

            SET divisor = divisor + 1;
        END WHILE ciclo_primos;
    END IF;

    RETURN es_primo;
END$$

DELIMITER ;

-- ==========================================================
-- LLAVE 2: Reloj de Arena (validación de frescura)
-- ==========================================================

DELIMITER $$

CREATE FUNCTION fn_reloj_arena(p_fecha_ingreso DATE, p_meses_validez INT)
RETURNS VARCHAR(10)
DETERMINISTIC
BEGIN
    DECLARE fecha_actual DATE;
    DECLARE fecha_vencimiento DATE;
    DECLARE estado VARCHAR(10);

    -- Manejo de valores nulos
    IF p_fecha_ingreso IS NULL OR p_meses_validez IS NULL THEN
        SET estado = 'Expirado';
    ELSE
        SET fecha_actual = CURRENT_DATE();
        SET fecha_vencimiento = DATE_ADD(p_fecha_ingreso, INTERVAL p_meses_validez MONTH);

        IF fecha_vencimiento >= fecha_actual THEN
            SET estado = 'Fresco';
        ELSE
            SET estado = 'Expirado';
        END IF;
    END IF;

    RETURN estado;
END$$

DELIMITER ;
