# Freight Operations Analysis

Proyecto personal de análisis de datos aplicado a operaciones de transporte de mercancías y logística de proyectos.

El objetivo es desarrollar un flujo de trabajo completo que combine:

- análisis exploratorio y descriptivo en **R**;
- visualización y dashboard en **Power BI**;
- análisis prescriptivo en **Python**;
- análisis geoespacial de rutas en **QGIS**.

> **Nota:** todos los datos son sintéticos y se utilizan exclusivamente con fines de aprendizaje y portfolio. No representan operaciones ni resultados reales de empresas, clientes, transportistas, puertos o proyectos.

## Objetivos

- Preparar y validar un modelo de datos de operaciones de transporte.
- Analizar puntualidad, retrasos, costes, incidencias, emisiones y rendimiento operativo.
- Explorar diferencias entre proyectos, modos de transporte, rutas, puertos, transportistas y tipos de carga.
- Construir visualizaciones, indicadores y herramientas de apoyo a la decisión.
- Mantener un proyecto reproducible, documentado y apto para portfolio.

## Herramientas

- **R / RStudio:** importación, calidad, limpieza, EDA y visualización.
- **Power BI:** modelado, medidas DAX y dashboard.
- **Python:** optimización, simulación y análisis prescriptivo.
- **QGIS:** representación y análisis de nodos y rutas.
- **Git / GitHub:** control de versiones y publicación.

## Estructura del proyecto

```text
Freight_Operations_Analysis/
│
├── dashboard/
│   └── 2024-2025_Freight-Operations-Analysis.pbix
│       └── Modelo semántico y desarrollo del dashboard en Power BI.
│
├── data/
│   ├── external_sources/
│   │   └── Fuentes externas o datos auxiliares incorporados al proyecto.
│   ├── processed_data/
│   │   └── Datos limpios, transformados y preparados para el análisis.
│   └── raw_data/
│       └── Datos originales sin modificar.
│
├── docs/
│   ├── datasets_dictionary.xlsx
│   │   └── Diccionario de datos de los archivos y variables del proyecto.
│   ├── ideas_exploration.txt
│   │   └── Ideas, hipótesis y posibles líneas de análisis.
│   └── relationships.md
│       └── Descripción de las tablas, relaciones y modelo de datos propuesto.
│
├── output/
│   ├── figures/
│   │   ├── 04_EDA_histograms.png
│   │   ├── 04_EDA_boxplots.png
│   │   ├── 04_EDA_scatterplots.png
│   │   ├── 04_EDA_project-performance.png
│   │   ├── 04_EDA_lineplots.png
│   │   ├── 04_EDA_lineplot_port_congestion.png
│   │   └── 04_EDA_lineplot_fuel_prices.png
│   └── maps/
│       └── Mapas y resultados geoespaciales exportados.
│
├── python/
│   └── Scripts de Python y documentación específica del análisis prescriptivo.
│
├── qgis/
│   └── Archivos de proyecto, procesos, scripts y documentación del análisis geoespacial.
│
├── R/
│   ├── 01_Import.R
│   ├── 02_Data_Quality.R
│   ├── 03_Data_Cleaning.R
│   └── 04_EDA.R
│
├── .gitignore
├── Freight_Operations_Analysis.Rproj
└── README.md
```

## Modelo de datos

El modelo se organiza alrededor de `fact_shipments`, con un registro por envío.

Tablas de detalle:

- `fact_route_legs`: tramos de cada envío.
- `fact_events`: hitos y eventos operativos.
- `fact_incidents`: incidencias asociadas a los envíos.
- `fact_port_congestion`: indicadores mensuales por puerto.
- `fact_fuel_prices`: indicadores mensuales de combustible.

Dimensiones:

- calendario;
- proyectos;
- instalaciones;
- puertos;
- transportistas;
- buques;
- tipos de carga.

Las relaciones están documentadas en [`docs/relationships.md`](docs/relationships.md).

## Desarrollo realizado

### 1. Importación de datos

**Script:** [`R/01_Import.R`](R/01_Import.R)

El script localiza e importa automáticamente los CSV de `data/raw_data/`, construye rutas relativas con `here`, almacena las 13 tablas en la lista `datasets` y revisa problemas de lectura y estructura inicial. Los archivos originales no se modifican.

### 2. Evaluación de calidad

**Script:** [`R/02_Data_Quality.R`](R/02_Data_Quality.R)

Se revisaron problemas de importación, valores ausentes, formato de texto, claves primarias y de negocio, integridad referencial, variables binarias, ausencias según modo de transporte, continuidad del calendario y reglas básicas de negocio.

#### Resultados principales

- No se detectaron problemas de importación, referencias huérfanas ni duplicados en las claves de negocio comprobadas.
- Las claves primarias revisadas son completas y únicas.
- Las variables binarias contienen únicamente los valores esperados.
- La dimensión calendario original contiene 731 fechas continuas entre 2024-01-01 y 2025-12-31.
- Se identificaron 132 ausencias de puertos y 311 ausencias de buque en `fact_shipments`; las asociadas a transporte por carretera son estructurales y esperadas.
- Los 179 envíos intermodales y sus tramos `Container Sea` no tienen buque asignado; se mantiene como limitación documentada sin imputación.
- Se detectaron cinco fechas en las que el año natural y el año ISO difieren, por lo que el análisis semanal requiere utilizar conjuntamente año y semana ISO.

### 3. Limpieza y preparación de datos

**Script:** [`R/03_Data_Cleaning.R`](R/03_Data_Cleaning.R)

El script crea una copia de trabajo independiente, incorpora `iso_year` e `iso_year_week`, convierte variables binarias de `Y/N` a `TRUE/FALSE`, conserva los valores ausentes estructurales, valida la estructura final y exporta las 13 tablas limpias a `data/processed_data/`.

#### Resultados principales

- Las 13 tablas conservaron exactamente el mismo número de filas que los datos originales.
- `dim_calendar` incorporó únicamente las dos columnas previstas.
- Las 14 variables binarias revisadas se convirtieron correctamente a tipo lógico.
- La validación estructural final fue correcta y se generaron los 13 CSV procesados esperados.

### 4. Análisis exploratorio de datos

**Script:** [`R/04_EDA.R`](R/04_EDA.R)

El EDA mantiene separadas las distintas granularidades del modelo y analiza volumen operativo, distribuciones, valores atípicos, correlaciones de Spearman, puntualidad, retrasos, costes, daños, emisiones, proyectos, transportistas, tipos de carga, incidencias, rutas, eventos, congestión portuaria y precios de combustible.

El script se ejecutó completo desde una sesión limpia sin errores. Las tablas agregadas creadas durante el EDA se mantienen como resultados analíticos y no sustituyen al modelo relacional utilizado posteriormente en Power BI.

## Principales hallazgos del EDA

### Operaciones generales

- 900 envíos, 7 proyectos, 11 transportistas utilizados y 10 tipos de carga.
- 23.085 toneladas y 2.184.346 km acumulados.
- 11.665.158 € de coste logístico total y aproximadamente 12.961 € por envío.
- Puntualidad global del 79,3 %, con 186 entregas fuera de plazo.
- Tasa de daños del 4,11 %.

### Costes, servicio y sostenibilidad

- El coste logístico presenta sus relaciones más fuertes con emisiones absolutas, peso, volumen, riesgo y distancia.
- `Sea Breakbulk` concentra las operaciones de mayor peso, coste y complejidad.
- Carretera presenta la mejor puntualidad y la mayor intensidad de emisiones por tonelada-kilómetro.
- Ninguno de los siete proyectos alcanza su objetivo de puntualidad; Dammam presenta la mayor desviación (-18,17 pp).
- Las cargas sobredimensionadas y heavy lift presentan mayor complejidad operativa y económica.
- La intensidad mediana de emisiones es mayor en carretera (0,095 kg CO₂e/t·km) y menor en `Container Sea` (0,0215 kg CO₂e/t·km).

### Incidencias, rutas y entorno externo

- 55 incidencias afectan al 6,11 % de los envíos; el 69,1 % se clasificó como prevenible.
- Las incidencias generaron 692 horas de retraso, 271.966 € de coste directo y 61.575 € en reclamaciones.
- Los 900 envíos disponen de información de ruta, con 2.436 tramos y una mediana de 3 tramos por envío.
- Se analizaron 5.772 eventos operativos, con una media de 6,41 eventos por envío.
- La tabla de congestión cubre 18 puertos durante 24 meses; la mediana del índice de congestión es 40 y la espera mediana de buques 9,2 horas.
- El recargo de combustible presenta una relación positiva moderada con el diésel en carretera y con MGO en operaciones marítimas.

### Composición del coste

- Flete: 75,30 %.
- Costes portuarios: 10,80 %.
- Recargo de combustible: 8,42 %.
- Costes aduaneros: 5,52 %.

## Visualizaciones generadas

Las visualizaciones del EDA se encuentran en `output/figures/`.

### Distribución de variables numéricas

![Histogramas de las principales variables numéricas](output/figures/04_EDA_histograms.png)

### Identificación visual de valores extremos

![Boxplots de las principales variables numéricas](output/figures/04_EDA_boxplots.png)

### Relaciones con el coste logístico

![Relaciones entre el coste y las principales variables operativas](output/figures/04_EDA_scatterplots.png)

### Puntualidad por proyecto

![Puntualidad real frente al objetivo por proyecto](output/figures/04_EDA_project-performance.png)

### Evolución mensual del rendimiento operativo

![Evolución mensual de envíos, puntualidad, retraso y coste](output/figures/04_EDA_lineplots.png)

### Evolución de la congestión portuaria

![Evolución mensual de la congestión portuaria](output/figures/04_EDA_lineplot_port_congestion.png)

### Evolución de los precios de combustible

![Evolución mensual de los precios de combustible](output/figures/04_EDA_lineplot_fuel_prices.png)

## Modelado en Power BI

### 5. Preparación y modelado del modelo semántico

**Archivo:** [`dashboard/2024-2025_Freight-Operations-Analysis.pbix`](dashboard/2024-2025_Freight-Operations-Analysis.pbix)

Power BI utiliza las tablas procesadas como fuente. Se creó una nueva `dim_calendar` calculada, marcada como tabla de fechas, con cobertura continua entre 2023-01-01 y 2026-12-31 y atributos de año, trimestre, mes, día de la semana y calendario ISO.

El modelo contiene actualmente 16 tablas: seis tablas de hechos, dimensiones de proyectos, instalaciones, puertos y tipos de carga, dimensiones de rol separadas para transportistas y buques, `dim_calendar` y una tabla `Medidas` para centralizar los cálculos DAX.

El desdoblamiento de transportistas y buques distingue los roles principales del envío de los asignados a cada tramo y evita caminos de filtrado ambiguos.

#### Relaciones del modelo

El modelo utiliza principalmente relaciones **1:* con filtro único desde las dimensiones hacia los hechos**. `fact_shipments` se relaciona con `fact_route_legs`, `fact_events` y `fact_incidents` mediante `shipment_id`; `dim_ports` se relaciona con la congestión portuaria y `dim_calendar` con las tablas que requieren análisis temporal.

Cuando una dimensión representa varios roles, se mantiene una única relación activa por ruta de filtrado y las alternativas se conservan inactivas. `actual_delivery_date` actúa como relación temporal principal de `fact_shipments`; otras fechas quedan disponibles mediante relaciones inactivas y `USERELATIONSHIP()`.

La capa semántica se simplificó ocultando claves exclusivamente técnicas, campos auxiliares de ordenación y variables geográficas reservadas principalmente para QGIS, manteniendo visibles los identificadores y atributos necesarios para el análisis operativo.

### 6. Medidas DAX y `Freight Operations Control Tower`

Se inició la primera página del dashboard con segmentadores de **Year, Quarter, Month y Weekday** y una capa de KPIs centralizada en la tabla `Medidas`.

Las medidas implementadas hasta el momento cubren:

- volumen y actividad: envíos, proyectos activos, peso y distancia;
- servicio: envíos on-time, puntualidad, retrasos y mediana de horas de retraso;
- coste: coste logístico total, coste por envío, claims y coste logístico sobre valor de carga;
- sostenibilidad: emisiones totales e intensidad de CO₂e;
- riesgo y carga especial: risk score, heavy lift, oversize, hazardous y temperature-controlled;
- incidencias: porcentaje de envíos afectados y proporción de incidentes prevenibles.

Los principales KPIs obtenidos en Power BI reproducen los resultados del EDA, entre ellos 900 envíos, 7 proyectos, 79,3 % de puntualidad, 20,7 % de entregas fuera de plazo, 4,1 % de daños, 11.665.158 € de coste logístico, 12.961 € por envío, 23.085 t, 2.184.346 km y 1.888.974 kg CO₂e.

Para ratios globales se priorizan medidas ponderadas cuando corresponde; por ejemplo, el coste logístico representa aproximadamente el 2,3 % del valor total de la carga. Las medidas base se diseñan para responder al contexto de filtro y reutilizarse por proyecto, transportista, modo o tipo de carga sin duplicar lógica DAX.

También se definió el catálogo de medidas necesario para las siguientes páginas: rendimiento de proyectos y servicio, costes, transportistas y carga, incidencias y riesgo, rutas, puertos y combustible, sostenibilidad y comparaciones temporales.

#### Estado de esta fase

El modelo semántico está preparado, la primera página `Freight Operations Control Tower` está en desarrollo y la capa inicial de KPIs DAX ha sido implementada y contrastada con el EDA. El siguiente bloque de trabajo consiste en completar las visualizaciones, incorporar las medidas restantes según cada página y validar el comportamiento de filtros y relaciones inactivas.

## Aspectos pendientes de revisión

- Confirmar la interpretación de los buques ausentes en operaciones intermodales.
- Mantener los `NA` estructurales de los envíos por carretera.
- Revisar en QGIS la coherencia entre coordenadas, ciudades y países.
- Mantener cautela al interpretar categorías con pocos registros, especialmente riesgo alto, huelgas y modos con bajo volumen mensual.
- Tratar `None` en las causas como ausencia de una causa específica registrada, no necesariamente como ausencia de retraso.
- Evitar atribuir causalidad a las relaciones observadas durante el EDA.
- Validar las relaciones inactivas y las medidas que requieran `USERELATIONSHIP()` antes de cerrar el dashboard.

## Próximos pasos

- Completar los KPIs y visuales de `Freight Operations Control Tower`.
- Construir las páginas de servicio/proyectos, costes, transportistas/carga, incidencias/riesgo, rutas, puertos/combustible y sostenibilidad.
- Incorporar las medidas de inteligencia temporal y comparaciones interanuales cuando corresponda.
- Validar sistemáticamente los resultados de Power BI frente al EDA en R.
- Desarrollar el análisis prescriptivo y de optimización en Python.
- Representar y analizar nodos, puertos y rutas en QGIS.

## Estado del proyecto

- [x] Estructura inicial.
- [x] Modelo de datos preliminar.
- [x] Importación automatizada.
- [x] Evaluación inicial de calidad.
- [x] Limpieza y preparación.
- [x] Análisis exploratorio en R.
- [x] Modelado semántico en Power BI.
- [x] Medidas DAX base para `Freight Operations Control Tower`.
- [ ] Dashboard completo en Power BI.
- [ ] Análisis prescriptivo en Python.
- [ ] Análisis geoespacial en QGIS.
