# Freight Operations Analysis

Proyecto personal de análisis de datos aplicado a operaciones de transporte de mercancías y logística de proyectos.

El proyecto utiliza un conjunto de datos sintético para construir un flujo de trabajo completo, desde la preparación y exploración de los datos hasta la visualización, el análisis prescriptivo y el análisis geoespacial de rutas.

> **Nota:** los datos utilizados son sintéticos y se emplean exclusivamente con fines de aprendizaje y portfolio. No representan el rendimiento real de ninguna empresa, cliente, transportista, puerto o proyecto.

## Objetivo general

Desarrollar un caso práctico de análisis de operaciones de transporte que permita estudiar el comportamiento de los envíos, identificar patrones operativos, evaluar el rendimiento logístico y explorar oportunidades de mejora mediante herramientas de análisis de datos, optimización y sistemas de información geográfica.

## Objetivos específicos

- Organizar y documentar un modelo de datos orientado al análisis de operaciones de transporte.
- Preparar, limpiar y validar los datos antes de su análisis.
- Realizar un análisis exploratorio y descriptivo en **R**.
- Diseñar un dashboard interactivo en **Power BI** para el seguimiento de indicadores operativos.
- Desarrollar análisis prescriptivos y modelos de apoyo a la decisión en **Python**.
- Analizar nodos, tramos y rutas de transporte en **QGIS**.
- Generar gráficos, mapas y otros resultados reutilizables.
- Mantener una estructura de proyecto clara, reproducible y adecuada para portfolio.

## Preguntas de análisis iniciales

El proyecto podrá evolucionar para responder, entre otras, a preguntas como:

- ¿Qué factores están asociados con los retrasos de los envíos?
- ¿Qué proyectos, rutas, puertos o transportistas presentan mayores desviaciones?
- ¿Cómo varían los tiempos de tránsito, costes e incidencias según el tipo de carga?
- ¿Qué patrones aparecen en los hitos y eventos operativos?
- ¿Cómo afectan la congestión portuaria y el precio del combustible a las operaciones?
- ¿Qué rutas o decisiones operativas podrían mejorarse mediante optimización o simulación?
- ¿Cómo pueden representarse geográficamente los nodos y tramos de transporte?

## Herramientas previstas

- **R / RStudio:** limpieza, análisis exploratorio, estadística descriptiva y visualización.
- **Power BI:** modelado, indicadores y dashboard interactivo.
- **Python:** análisis prescriptivo, optimización, simulación y automatización.
- **QGIS:** análisis espacial, representación de nodos y evaluación de rutas.
- **Git y GitHub:** control de versiones y publicación del proyecto.

## Estructura del proyecto

```text
15_Freight_Operations_Analysis/
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
│   └── Scripts de Python y un README o archivo TXT con los objetivos
│       específicos de esta fase del proyecto.
│
├── qgis/
│   └── Archivos de proyecto, procesos o scripts de QGIS y un README o
│       archivo TXT con los objetivos específicos del análisis geoespacial.
│
├── R/
│   ├── 01_Import.R
│   │   └── Importación automatizada y comprobación inicial de los archivos CSV.
│   └── README.md o archivo TXT
│       └── Objetivos específicos y documentación de la fase de análisis en R.
│
├── .gitignore
│   └── Reglas para excluir del control de versiones archivos temporales,
│       locales o no necesarios.
│
├── Freight_Operations_Analysis.Rproj
│   └── Archivo de proyecto de RStudio.
│
└── README.md
    └── Descripción general, objetivos y estructura del proyecto.
```

## Modelo de datos

El modelo está planteado alrededor de una tabla central de envíos y varias tablas relacionadas con tramos de ruta, eventos, incidencias e indicadores externos.

De forma general, incluye:

- Una tabla principal con un registro por envío.
- Tablas de detalle para tramos de ruta, hitos operativos e incidencias.
- Dimensiones de calendario, proyectos, instalaciones, puertos, transportistas, buques y tipos de carga.
- Datos auxiliares sobre congestión portuaria y precios del combustible.
- Archivos geográficos con nodos y tramos de ruta preparados para su análisis en QGIS.

La definición detallada de las relaciones se encuentra en [`docs/relationships.md`](docs/relationships.md).

## Flujo de trabajo previsto

1. Revisar el diccionario y las relaciones entre tablas.
2. Conservar los datos originales en `data/raw_data/`.
3. Limpiar, transformar y validar los datos.
4. Guardar los resultados preparados en `data/processed_data/`.
5. Realizar el análisis exploratorio y descriptivo en R.
6. Construir el modelo y el dashboard en Power BI.
7. Desarrollar análisis prescriptivos en Python.
8. Analizar nodos y rutas en QGIS.
9. Exportar gráficos y mapas a `output/`.
10. Documentar los resultados, decisiones y limitaciones.

## Desarrollo del proyecto

### Paso 1 en R: importación y comprobación inicial de los datos

**Script:** [`R/01_Import.R`](R/01_Import.R)

El primer script del proyecto prepara el entorno de trabajo y realiza una revisión inicial de los archivos almacenados en `data/raw_data/`.

#### Objetivos

- Importar de forma automatizada todos los archivos CSV de datos originales.
- Evitar rutas absolutas para que el proyecto pueda ejecutarse en otros equipos.
- Centralizar las tablas importadas en una estructura única y fácil de consultar.
- Detectar posibles problemas de lectura o interpretación de los archivos.
- Revisar la estructura y los nombres de las variables de cada tabla.
- Comprobar que `shipment_id` funciona como identificador único en la tabla principal de envíos.

#### Proceso realizado

1. Se cargan los paquetes `tidyverse` y `here`.
2. `here()` construye la ruta relativa a `data/raw_data/` desde la raíz del proyecto.
3. `list.files()` localiza todos los archivos con extensión `.csv`.
4. `lapply()` y `read_csv()` importan cada archivo como un tibble.
5. Cada tabla recibe como nombre el nombre original de su archivo, sin la extensión `.csv`.
6. `problems()` comprueba si se han producido errores o advertencias durante la importación.
7. Se revisan los nombres de las columnas de todas las tablas.
8. Se visualizan inicialmente las principales tablas dimensionales:
   - proyectos;
   - puertos;
   - transportistas;
   - instalaciones;
   - tipos de carga;
   - buques.
9. En `fact_shipments` se compara:
   - el número total de filas, mediante `nrow()`;
   - el número de valores únicos de `shipment_id`, mediante `n_distinct()`.

Si ambos resultados coinciden, se obtiene una primera evidencia de que la granularidad de `fact_shipments` es de **una fila por envío**.

#### Resultado del paso

El script genera en memoria el objeto `datasets`, una lista nombrada que contiene todas las tablas importadas. Este objeto servirá como punto de partida para las siguientes fases de revisión de calidad, limpieza, transformación y análisis exploratorio.

En este paso todavía no se modifican los datos originales ni se generan archivos en `data/processed_data/`.

## Estado del proyecto

Proyecto en fase inicial de organización, documentación y preparación de los datos. La estructura, los objetivos específicos y las herramientas podrán ajustarse a medida que avance el análisis.
