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
- **Power BI:** modelado, medidas y dashboard.
- **Python:** optimización, simulación y análisis prescriptivo.
- **QGIS:** representación y análisis de nodos y rutas.
- **Git / GitHub:** control de versiones y publicación.

## Estructura del proyecto

```text
Freight_Operations_Analysis/
│
├── dashboard/
│   └── Archivos y recursos utilizados para desarrollar el dashboard en Power BI.
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
│   │   └── Gráficos y visualizaciones exportados.
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
│   │   └── Importación automatizada y comprobación inicial de los archivos CSV.
│   └── 02_Data_Quality.R
│       └── Diagnóstico estructural, relacional y lógico de los datos originales.
│
├── .gitignore
│   └── Reglas para excluir del control de versiones archivos temporales,
│       locales o no necesarios.
│
├── Freight_Operations_Analysis.Rproj
│   └── Archivo de proyecto de RStudio.
│
└── README.md
    └── Descripción general, estado, metodología y próximos pasos del proyecto.
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

El script:

- localiza los CSV de `data/raw_data/`;
- construye rutas relativas con `here`;
- importa automáticamente los archivos con `read_csv`;
- guarda las 13 tablas en la lista nombrada `datasets`;
- revisa problemas de lectura y la estructura inicial de los datos.

Los archivos originales no se modifican.

### 2. Evaluación de calidad

**Script:** [`R/02_Data_Quality.R`](R/02_Data_Quality.R)

El script realiza un diagnóstico general antes de limpiar o transformar los datos.

Se revisan:

- problemas de importación;
- valores ausentes;
- cadenas vacías y espacios sobrantes;
- claves primarias;
- claves de negocio;
- claves foráneas e integridad referencial;
- variables binarias con valores `Y` y `N`;
- ausencias según el modo de transporte;
- continuidad y coherencia del calendario;
- reglas básicas de proyectos e instalaciones.

#### Resultados principales

- No se detectaron problemas de importación.
- Las claves primarias revisadas son completas y únicas.
- No se encontraron duplicados en las claves de negocio comprobadas.
- No se detectaron referencias huérfanas entre las tablas.
- No se encontraron problemas generales de formato en variables de texto.
- Las variables binarias revisadas contienen únicamente los valores esperados.
- La dimensión calendario contiene 731 fechas continuas entre 2024-01-01 y 2025-12-31.
- Las reglas básicas de fechas, porcentajes, prioridades, coordenadas y capacidades no mostraron errores.

#### Valores ausentes relevantes

En `fact_shipments` se identificaron:

- 132 `origin_port_id` ausentes;
- 132 `destination_port_id` ausentes;
- 311 `vessel_id` ausentes.

Interpretación:

- Los 132 envíos por carretera no requieren puertos ni buques. Son ausencias estructurales esperadas.
- Los 179 envíos intermodales no tienen `vessel_id`.
- Los 179 tramos `Container Sea` de esos envíos intermodales tampoco tienen buque asignado.

La ausencia de buque en las operaciones intermodales queda documentada como una limitación pendiente de revisión. No se realizará ninguna imputación sin una regla que la justifique.

#### Calendario ISO

La columna `week` utiliza numeración ISO.

Se detectaron cinco fechas de final de año en las que el año natural y el año ISO son diferentes. No son errores, pero será necesario utilizar conjuntamente `iso_year` e `iso_week` en los análisis semanales.

## Aspectos pendientes de revisión

- Confirmar la interpretación de los buques ausentes en operaciones intermodales.
- Mantener los `NA` estructurales de los envíos por carretera.
- Validar que las fechas de las tablas operativas estén cubiertas por `dim_calendar`.
- Revisar reglas de coherencia entre fechas planificadas y reales, retrasos, estado y puntualidad.
- Validar costes, pesos, dimensiones, emisiones, daños y reclamaciones.
- Confirmar la granularidad de las claves de negocio con el diccionario de datos.
- Revisar en QGIS la coherencia entre coordenadas, ciudades y países.

## Próximos pasos

### 3. Limpieza y preparación en R

Crear `R/03_Data_Cleaning.R` para:

- trabajar sobre copias de los datos originales;
- conservar las ausencias estructurales;
- crear variables temporales e indicadores derivados;
- incorporar `iso_year`, `iso_week` e `iso_year_week`;
- preparar las tablas necesarias para el análisis;
- exportar los resultados a `data/processed_data/`.

### 4. Análisis exploratorio en R

Analizar:

- volumen de envíos;
- puntualidad y retrasos;
- tiempos de tránsito;
- costes y emisiones;
- incidencias, daños y reclamaciones;
- rendimiento por proyecto, modo, ruta, puerto y transportista.

### 5. Fases posteriores

- Construcción del dashboard en Power BI.
- Análisis prescriptivo y optimización en Python.
- Representación y análisis de rutas en QGIS.
- Documentación de resultados y conclusiones.

## Estado del proyecto

- [x] Estructura inicial.
- [x] Modelo de datos preliminar.
- [x] Importación automatizada.
- [x] Evaluación inicial de calidad.
- [ ] Limpieza y preparación.
- [ ] Análisis exploratorio en R.
- [ ] Dashboard en Power BI.
- [ ] Análisis prescriptivo en Python.
- [ ] Análisis geoespacial en QGIS.
