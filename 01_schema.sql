-- =====================================================================
-- PROYECTO FINAL SQL: VENTAS DE TELÉFONOS MÓVILES EN ESPAÑA
-- ARCHIVO: 01_schema.sql
-- Creado con WORKBENCH - SQLITE

-- DESCRIPCION =====================================================================
-- Este modelo implementa un modelo relacional orientado al análisis de las ventas de productos de telefono movil en España.
-- El objetivo es transformar los datos de venta de un fichero csv, generado con ChatGPT y crear una tabla stagin-ventas,
-- y con los datos ya cargados en la tabla entonces generar el modelo relacional, creando una estructura optimizada para análisis analítico (BI / Analytics),
-- y asi facilitar la toma de decisiones basada en datos.

-- PASOS DE EJECUCUION =====================================================================
-- 1- Seleccionar todo el contenido del fichero y ejecutar


-- CREAR LA BASE DE DATOS =====================================================================
DROP SCHEMA IF EXISTS proyecto_final;
CREATE SCHEMA IF NOT EXISTS proyecto_final;
USE proyecto_final;

-- ELIMINAR TABLAS SI EXISTEN ==========================================
DROP TABLE IF EXISTS hecho_ventas;
DROP TABLE IF EXISTS dim_productos;
DROP TABLE IF EXISTS dim_tienda;
DROP TABLE IF EXISTS dim_marcas;
DROP TABLE IF EXISTS dim_ubicacion;
DROP TABLE IF EXISTS dim_calendario;


-- =====================================================================
-- CREAR TABLA DIMENSIÓN MARCAS
-- =====================================================================
-- Almacena el catálogo único de fabricantes de teléfonos móviles.
-- Permite garantizar la consistencia en el análisis por marca,
-- evitando duplicidades y estandarizando los nombres de fabricantes.
CREATE TABLE IF NOT EXISTS dim_marcas (
    id_marca INT AUTO_INCREMENT PRIMARY KEY,
    nombre_marca VARCHAR(50) -- Samsung, Apple, Oppo, Xiaomi
);

-- =====================================================================
-- CREAR TABLA DIMENSIÓN TIENDA
-- =====================================================================
-- Representa los puntos de venta.
-- Permite analizar el rendimiento comercial por ubicación geográfica.

CREATE TABLE IF NOT EXISTS dim_tienda (
    id_tienda INT AUTO_INCREMENT PRIMARY KEY,
    comunidad_autonoma VARCHAR(100),
    -- Nombre de la comunidad autonoma donde esta la tienda
    nombre_tienda VARCHAR(100)
    -- Nombre comercial del establecimiento
    -- Ejemplo: "Movistar, Vodafone, Orange, MediaMarkt, Fnac, El Corte Inglés"
);

-- =====================================================================
-- CREAR TABLA DIMENSIÓN PRODUCTOS
-- =====================================================================
-- Catálogo de modelos de teléfonos móviles disponibles para la venta.
-- Cada producto está asociado a una marca específica.
-- Permite analizar el rendimiento comercial a nivel de modelo de teléfonos móviles.

CREATE TABLE IF NOT EXISTS dim_productos (
    id_producto INT AUTO_INCREMENT PRIMARY KEY,
    id_marca INT,
    nombre_producto VARCHAR(100),
    -- Nombre comercial del modelo de teléfono móvil
    precio_catalogo DECIMAL(10,2),
    -- Precio oficial de referencia del producto (PVP)
    coste_producto DECIMAL(10,2),
    -- Coste interno del producto para la empresa (precio de adquisición)
    FOREIGN KEY (id_marca) REFERENCES dim_marcas(id_marca) 
    -- Clave foránea que referencia la dimensión de marcas.
	-- Permite identificar el fabricante o marca comercial de cada producto.
);

-- =====================================================================
-- CREAR TABLA DE HECHOS-VENTAS
-- =====================================================================
-- Tabla central del modelo relacional que registra las ventas de productos.
-- Cada registro representa la venta de un producto en una tienda
-- en una fecha específica. Cada fila es la venta de un producto en una tienda.

CREATE TABLE IF NOT EXISTS hecho_ventas (
    id_venta INT AUTO_INCREMENT PRIMARY KEY, 
    id_producto INT , -- Identificador del producto vendido
    id_tienda INT, -- Identificador de la tienda donde se realiza la venta
    fecha_venta DATE, -- Fecha en la que se realiza la venta
    unidades_vendidas INT, -- Número de unidades vendidas
    precio_venta DECIMAL(10,2), 
    -- Precio real aplicado en la venta (puede incluir descuentos o promociones)
    ingresos DECIMAL(10,2) GENERATED ALWAYS AS (unidades_vendidas * precio_venta) STORED,
    -- Ingresos totales generados por la venta

    FOREIGN KEY (id_producto) REFERENCES dim_productos(id_producto),
    -- Clave foránea que referencia el producto vendido.
    -- Permite relacionar la venta con la información del producto de la tabla dim_productos
    FOREIGN KEY (id_tienda) REFERENCES dim_tienda(id_tienda)
    -- Clave foránea que referencia la tienda donde se realizó la venta.
    -- Permite relacionar la venta con la información de la tienda de la tabla dim_tienda
);

-- =====================================================================
-- TABLA STAGIN VENTAS 
-- =====================================================================
-- Esta tabla temporal recibirá los datos brutos del CSV antes de repartirlos en el modelo dimensional.
DROP TABLE IF EXISTS staging_ventas;
CREATE TABLE IF NOT EXISTS staging_ventas (
    sale_id INT,
    date_sales VARCHAR(100),
    community VARCHAR(100),
    brand VARCHAR(100),
    model VARCHAR(100),
    units INT,
    unit_price DECIMAL(10,2),
    total_amount DECIMAL(10,2)
);
