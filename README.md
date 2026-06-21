## Análisis de Ventas de Teléfonos Móviles en España

## Link al video con la presentacion [https://www.loom.com/share/3fbb7844d5214b9abdef1ee361474905]

### Descripción del Proyecto
Este proyecto implementa un modelo relacional diseñado específicamente para el análisis de ventas de 
dispositivos móviles en el mercado español.
El objetivo principal es transformar los datos brutos (desde un fichero CSV generado con ChatGPT)
en una estructura que permita realizar un analisis claro de los datos para responder las preguntas de negocio.

### Preguntas de Negocio
1. ¿Cuál es la cuota de mercado por fabricante según el valor total de las ventas? 
2. ¿Qué comunidad autónoma tiene los ingresos de venta medio más alto? 
3. ¿Cuáles son los modelos de móviles más vendidos y qué cuota de volumen representan en el mercado?
4. ¿Qué marcas generan el mayor beneficio neto y cuál es el % de margen real tras descontar costes?
5. ¿Cómo han evolucionado los ingresos por año?

### Requisitos del Sistema
Gestor de Base de Datos Workbench con MySQL.

### Estructura del proyecto
El proyecto se divide en tres ficheros:
01_schema.sql: Se define el modelo relacional de la base de datos. Se crea el esquema proyecto_final y las tablas dimensiones y echos.
02_data.sql: Se realiza la transformación de los datos. Utilizando la tabla stagin_ventas se realiza la transformacion a las tablas dimensiones y hechos.
03_eda.sql: Se realiza el Análisis Exploratorio de Datos (EDA), limpieza de los valores nulos, la creación de vistas y consultas para dar respuestas a las preguntas planteadas.

### Arquitectura de la Base de Datos
Se implemento un modelo realacional tipo estrella:
dim_marcas: Catálogo único de fabricantes (Samsung, Apple, OPPO, Xiaomi, etc.).
dim_tienda: Puntos de venta clasificados por comunidad autónoma.
dim_productos: Modelos de los productos vendidos en los puntos de venta, relacionados con la marca.
hecho_ventas: Tabla central que registra cada transacción, unidades vendidas por puntos de venta, precio real e ingresos calculados.

staging_ventas: Tabla temporal para realizar la carga de los datos brutos del CSV.


### Proceso de Carga y Limpieza
- Origen: Los datos se cargan desde un fichero csv con 3,000 registros.
- Normalización: Se transformaron fechas de formato texto a DATE y se derivaron campos como el precio_venta a partir del importe total y las unidades.
- Depuración: Se detectaron y corrigieron 3 filas con valores nulos en algunos campos para asegurar la integridad del análisis.
- Resultado final: 2,997 transacciones procesadas con éxito.

### Ejecutar el proyecto
- Paso1: Seleccionar todo el contenido del fichero 01_schema.sql y ejecutar.
- Paso 2: Importar los datos desde el csv a la tabla staging_ventas.
        Abrir la bd proyecto_final.
        Click derecho, seleccionar la opcion Tabla Data Import Wizard.
        Completar los pasos de improtar.
- Paso 3: Seleccionar todo el contenido del fichero 02_data.sql y ejecutar.
- Paso 4: Seleccionar todo el contenido del fichero 03_eda.sql y ejecutar.

### Insights de Negocio (Resultados)
Tras la ejecución del análisis en 03_eda.sql, se obtuvieron los siguientes hallazgos estratégicos:

- Cuota de Mercado: El modelo OPPO lidera el mercado en valor con un 22,03% de la facturación total (1.555.971,39€), seguido por Xiaomi, Apple y Samsung.
- Rentabilidad Geográfica: El País Vasco es la región más rentable, con un ingreso medio por tienda de 940.993,81€.
- Eficiencia Financiera: Aunque OPPO genera más volumen, Motorola es la marca más eficiente porcentualmente, con un margen de beneficio real del 31,13%.
- Tendencia Temporal: Tras un ligero descenso en 2024 (-4,23%), el mercado mostró una recuperación sólida en 2025 con un crecimiento del 6,19%.




