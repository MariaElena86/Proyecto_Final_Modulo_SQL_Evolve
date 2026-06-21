-- ==================================================================================================================
-- PROYECTO FINAL SQL: VENTAS DE TELÉFONOS MÓVILES EN ESPAÑA
-- ARCHIVO: 03_eda.sql
-- Creado con WORKBENCH - SQLITE

-- =====================================================================
-- CONSULTAS PARA VERIFICAR QUE SE INSERTARON LOS DATOS
-- =====================================================================
SELECT * FROM staging_ventas;
SELECT * FROM dim_marcas;
SELECT * FROM dim_tienda;
SELECT * FROM dim_productos;
SELECT * FROM hecho_ventas;

SELECT 
comunidad_autonoma,
nombre_tienda,
nombre_producto,
fecha_venta,
unidades_vendidas,
precio_venta,
ingresos
FROM hecho_ventas h
JOIN dim_tienda t ON h.id_tienda = t.id_tienda
JOIN dim_productos p ON h.id_producto = p.id_producto
JOIN dim_marcas m ON p.id_marca = m.id_marca;


-- =====================================================================
-- DETECTAR VALORES NULOS Y ACTUALIZARLOS
-- =====================================================================
SELECT *  
FROM hecho_ventas 
WHERE unidades_vendidas IS NULL OR precio_venta IS NULL OR fecha_venta IS NULL;
-- Se detectaron 3 filas con valores null en el campo  precio_venta

UPDATE hecho_ventas
SET unidades_vendidas = 1, precio_venta = 100
WHERE id_venta IN (
    SELECT id_venta FROM (
        SELECT id_venta
        FROM hecho_ventas
       WHERE unidades_vendidas IS NULL OR precio_venta IS NULL OR fecha_venta IS NULL
    ) t
);
-- =====================================================================
-- DETECTAR VALORES DUPLICADOS
-- =====================================================================
SELECT 
	sale_id, COUNT(*) 
FROM staging_ventas 
GROUP BY sale_id 
HAVING COUNT(*) > 1;
-- No se detectaron valores duplicados

-- =====================================================================
-- Análisis Descriptivo
-- =====================================================================
-- Resumen general de la tabla de hechos
SELECT 
    COUNT(*) AS total_transacciones,
    SUM(unidades_vendidas) AS total_unidades,
    SUM(ingresos) AS ingresos_totales,
    CONCAT(MIN(fecha_venta),' al ', MAX(fecha_venta)) as periodo
FROM hecho_ventas;
-- Resultados:
-- Total Transacciones: 2,997 - Dado que el fichero fuente original contiene 3,000 registros (incluyendo la cabecera), 
-- este número indica que el proceso de carga y normalización desde la tabla staging_ventas a hecho_ventas ha sido exitoso y casi completo.
-- Total Unidades: 9,116 - Se han comercializado un total de 9,116 dispositivos móviles en el periodo analizado del (2023-01-01 al 2025-12-31)
-- Ingresos Totales: 7063827.75 total de ingresos recaudados
-- Periodo de Ventas: 2023/01/01 al 2025/12/31


-- =====================================================================
-- Crear Vistas de Negocio
-- =====================================================================

-- Vista 1: Resumen de ventas por producto y marca
-- Esta vista transforma los datos de la tabla de hechos en información estratégica agregada.
-- Permite identificar qué marcas y modelos específicos están impulsando el volumen de ventas 
-- eliminando la necesidad de realizar múltiples JOINs en consultas recurrentes.
CREATE OR REPLACE VIEW vista_rendimiento_productos AS
SELECT 
    m.nombre_marca,
    p.nombre_producto,
    p.precio_catalogo,
    SUM(h.unidades_vendidas) AS unidades_totales, -- Suma acumulada de todos los dispositivos vendidos por modelo
    SUM(h.ingresos) AS ingresos_totales -- Suma el total de ingresos (unidades × precio de venta), reflejando la facturación bruta total
FROM hecho_ventas h
JOIN dim_productos p ON h.id_producto = p.id_producto
JOIN dim_marcas m ON p.id_marca = m.id_marca
GROUP BY m.nombre_marca, p.nombre_producto, p.precio_catalogo;

-- Vista 2: Rendimiento geográfico de las tiendas
-- Esta vista transforma los datos de la tabla de hechos en información estratégica agregada.
-- Permite identificar el total vendido y recaudado por region y por tienda. 
-- Ayuda a identificar que comunidades son las que mayor venta generan.
CREATE OR REPLACE VIEW vista_ventas_comunidad AS
SELECT 
    t.comunidad_autonoma,
    t.nombre_tienda,
    SUM(h.unidades_vendidas) AS unidades_totales, -- Suma acumulada de todos los dispositivos vendidos por comunidad y tienda
    SUM(h.ingresos) AS ingresos_totales -- Suma el total de ingresos (unidades × precio de venta) por comunidad y tienda
FROM hecho_ventas h
JOIN dim_tienda t ON h.id_tienda = t.id_tienda
GROUP BY t.comunidad_autonoma, t.nombre_tienda;

-- =====================================================================
-- Preguntas de Negocio
-- 1. ¿Cuál es la cuota de mercado por fabricante según el valor total de las ventas? 
-- 2. ¿Qué comunidad autónoma tiene los ingresos de venta medio más alto? 
-- 3. ¿Cuáles son los modelos de móviles más vendidos y qué cuota de volumen representan en el mercado?
-- 4. ¿Qué marcas generan el mayor beneficio neto y cuál es el % de margen real tras descontar costes?
-- 5. ¿Cómo han evolucionado los ingresos por año?
-- =====================================================================

-- Insight 1: ¿Cuál es la cuota de mercado por fabricante según el valor total de las ventas? 
-- Objetivo: Identificar las marcas con mayor peso financiero para optimizar la estrategia de marketing.
SELECT 
    nombre_marca, 
    -- Suma de todos los ingresos generados por marca.
    ROUND(SUM(ingresos_totales), 2) AS facturacion_total,
    -- Porcentaje_mercado: cuota de mercado de cada marca en términos ingresos.
    ROUND(SUM(ingresos_totales) * 100.0 / SUM(SUM(ingresos_totales)) OVER(), 2) AS porcentaje_mercado
FROM vista_rendimiento_productos
GROUP BY nombre_marca
ORDER BY facturacion_total DESC;
-- Resultado: El fabricante OPPO lidera el mercado español en valor, 
-- generando unos ingresos totales de 1.555.971,39€, lo que representa el 22,03% de la cuota de mercado total. 
-- Le siguen de cerca Xiaomi (19,71%), Apple (19,61%) y Samsung (19,57%), con diferencias mínimas entre ellos.

-- =====================================================================
-- Insight 2. ¿Qué comunidad autónoma tiene los ingresos de venta medio más alto? 
-- Objetivo: Identificar las regiones con el consumo más robusto y consistente 
-- para priorizar la expansión de la red de tiendas.
SELECT 
    comunidad_autonoma, 
    ROUND(AVG(ingresos_totales), 2) AS avg_ingresos_tienda,
    COUNT(nombre_tienda) AS total_puntos_venta
FROM vista_ventas_comunidad
GROUP BY comunidad_autonoma
ORDER BY avg_ingresos_tienda DESC
LIMIT 1;
-- Resultado: El País Vasco se posiciona como la región más rentable del análisis, 
-- con un ingreso medio por establecimiento de 940.993,81€.

-- =====================================================================
-- Insight 3.¿Cuáles son los modelos de móviles más vendidos y qué cuota de volumen representan en el mercado?
-- Objetivo: Identificar los productos de mayor venta para optimizar los niveles de stock.
SELECT 
    nombre_marca,
    nombre_producto,
    unidades_totales,    
    RANK() OVER (ORDER BY unidades_totales DESC) AS posicion_ranking, -- asigna una posición
    -- Calcular el % que representa cada producto sobre el total de ventas global
    ROUND(unidades_totales * 100.0 / SUM(unidades_totales) OVER (), 2) AS porcentaje_cuota_unidades
FROM vista_rendimiento_productos
ORDER BY posicion_ranking ASC;
-- Respuesta: Los modelos mejor vendidos son OPPO, Samsung y Apple

-- =====================================================================
-- Insight 4. ¿Qué marcas generan el mayor beneficio neto y cuál es el % de margen real tras descontar costes?
-- Objetivo: Identificar las marcas más rentables para optimizar las inversiones.
-- Coste Total (coste_total): Representa la inversión total realizada para adquirir los productos.
-- Beneficio Bruto (beneficio_bruto): Es la ganancia real que queda tras descontar el coste de inversion.
-- Porcentaje de Margen (porcentaje_margen): Mide la eficiencia de cada marca para convertir ventas en beneficios
SELECT 
    m.nombre_marca,
    ROUND(SUM(h.ingresos), 2) AS ingresos_totales,
    -- coste_total= unidades_vendidas * coste_producto
    ROUND(SUM(h.unidades_vendidas * p.coste_producto), 2) AS coste_total,
    -- beneficio_bruto = ingresos - coste_total
    ROUND(SUM(h.ingresos - (h.unidades_vendidas * p.coste_producto)), 2) AS beneficio_bruto,
    -- porcentaje_margen = (beneficio_bruto/ingresos) * 100
    ROUND((SUM(h.ingresos - (h.unidades_vendidas * p.coste_producto)) / SUM(h.ingresos)) * 100, 2) AS porcentaje_margen
FROM hecho_ventas h
JOIN dim_productos p ON h.id_producto = p.id_producto
JOIN dim_marcas m ON p.id_marca = m.id_marca
GROUP BY m.nombre_marca
ORDER BY beneficio_bruto DESC;
-- Resultado:
-- La marca OPPO no solo lidera en ingresos, sino que es el mas rentable, aportando un beneficio bruto total de 466.423,66€.
-- Motorola Aunque generan menos volumen que OPPO, es la marca más eficiente porcentualmente 
-- con un margen del 31,13%, seguida de Xiaomi (30,66%).

-- =====================================================================
-- Insight 5. ¿Cómo han evolucionado los ingresos por año?
-- Objetivo: Medir la tendencia de crecimiento anual para determinar 
-- la salud financiera y la escalabilidad de las ventas entre 2023 y 2025

WITH ventas_anuales AS (
    SELECT 
        YEAR(fecha_venta) AS anno,
        ROUND(SUM(ingresos), 2) AS ingresos_totales
    FROM hecho_ventas
    GROUP BY anno
)
SELECT 
    anno,
    ingresos_totales,
    -- Crecimiento % respecto al año anterior
    ROUND(((ingresos_totales / LAG(ingresos_totales) OVER (ORDER BY anno)) - 1) * 100, 2) AS porcentaje_crecimiento
FROM ventas_anuales;
-- Resultado:
-- 2023 (Año Base): Se registraron ingresos por 2.374.634,26€, estableciendo el punto de partida del modelo
-- 2024: La facturación descendió a 2.274.210,89€, lo que representa una caída del 4,23% respecto al año anterior.
-- 2025: Las ventas experimentaron una recuperación alcanzando los 2.414.982,60€, con un crecimiento positivo del 6,19% respecto a 2024.