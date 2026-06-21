-- ==================================================================================================================
-- PROYECTO FINAL SQL: VENTAS DE TELÉFONOS MÓVILES EN ESPAÑA
-- ARCHIVO: 02_data.sql
-- Creado con WORKBENCH - SQLITE

-- DESCRIPCION:
-- En la normalizacion utilizaramos:
-- La tabla stagin-ventas cargada previamente con los datos del fichero ventas_moviles_espana.csv
-- date_sales-> para generar los datos del campo fecha_venta de la tabla  hecho_ventas 
-- units-> para generar los datos del campo unidades_vendidas de la tabla hecho_ventas 
-- total_amount-> para generar los datos del campo precio_venta = total_amount/units  de la tabla hecho_ventas 
-- community -> para generar los datos del campo comunidad_autonoma en la tabla dim_tienda 
-- brand-> para generar los datos del campo nombre_marca de la tabla dim_marc 
-- model-> para generar los datos del campo nombre_producto de la tabla dim_producto 
-- unit_price-> para generar los datos del campo precio_catalogo de la tabla dim_productos 

-- ==================================================================

-- TRANFORMACION DE LOS DATOS 
-- Antes de ejecutar este fichero es necesario importar los datos desde el csv.
-- Abrir la bd proyecto_final
-- Click derecho, seleccionar la opcion Tabla Data Import Wizard
-- Completar los pasos de improtar

-- PASOS DE EJECUCUION =====================================================================
-- 1- Seleccionar todo el contenido del fichero y ejecutar

-- Poblar la tabla dim_marcas  ===========================
INSERT INTO 
	dim_marcas (nombre_marca)
SELECT 
	DISTINCT TRIM(brand) 
FROM staging_ventas;

-- Poblar la tabla  dim_tienda ===========================
-- Como el CSV no tiene nombre de tienda, creamos una por comunidad con los siguientes ejemplos
-- "Movistar, Vodafone, Orange, MediaMarkt, El Corte Inglés"

INSERT INTO 
	dim_tienda (comunidad_autonoma, nombre_tienda)
SELECT
    community,
    CASE
        WHEN rn BETWEEN 1 AND 2 THEN 'Movistar'
        WHEN rn BETWEEN 3 AND 4 THEN 'Vodafone'
        WHEN rn BETWEEN 5 AND 6 THEN 'Orange'
        WHEN rn = 7 THEN 'MediaMarkt'
        ELSE 'El Corte Inglés'
    END AS nombre_tienda
FROM (
	SELECT DISTINCT
        community,
        ROW_NUMBER() OVER (ORDER BY community) AS rn -- aplicar un indice a las comunidades para crear las tiendas
    FROM (SELECT
			DISTINCT community
		  FROM staging_ventas
		  WHERE community IS NOT NULL 
          AND community <> ''
		  ) c    
	) t;

-- Poblar dim_productos ===========================
INSERT INTO dim_productos (id_marca, nombre_producto, precio_catalogo, coste_producto)
SELECT 
    m.id_marca, 
    sv.model, 
    ROUND(AVG(sv.unit_price), 2) AS precio_promedio,-- Usar el promedio como precio de catálogo
    ROUND(AVG(sv.unit_price) * 0.7, 2) AS coste_estimado-- El coste es el 70% del promedio
FROM staging_ventas sv
JOIN dim_marcas m ON sv.brand = m.nombre_marca
GROUP BY m.id_marca, sv.model;


-- Poblar la tabla  hecho_ventas ===========================
INSERT INTO 
	hecho_ventas (id_producto, id_tienda, fecha_venta, unidades_vendidas, precio_venta)
SELECT 
	p.id_producto,
	t.id_tienda,
	STR_TO_DATE(sv.date_sales, '%m/%d/%Y'),
	sv.units,
	sv.total_amount / NULLIF(sv.units,0) as precio_venta
FROM staging_ventas sv 
JOIN dim_productos p ON p.nombre_producto = sv.model 
JOIN dim_tienda t ON t.comunidad_autonoma = sv.community
WHERE sv.date_sales IS NOT NULL
  AND sv.date_sales <> '';


