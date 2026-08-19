# Tesis uVLP UCM

Repositorio asociado al trabajo de título:

Factibilidad del Posicionamiento por Luz Visible No Modulada en la Universidad Católica del Maule, Campus San Miguel, Talca.

Este repositorio contiene los scripts MATLAB utilizados para el análisis espectral de las señales adquiridas en laboratorio y en terreno, junto con tablas y figuras de resultados.

Los archivos CSV originales adquiridos desde el osciloscopio no se incluyen directamente en GitHub debido a su tamaño. Estos datos se encuentran disponibles en una carpeta complementaria de almacenamiento en la nube.

## Estructura del repositorio

- `codigos_laboratorio/LED1`: scripts MATLAB para el análisis individual del LED 1 en laboratorio.
- `codigos_laboratorio/LED2`: scripts MATLAB para el análisis individual del LED 2 en laboratorio.
- `codigos_laboratorio/Ambos_LEDS`: scripts MATLAB para el análisis simultáneo de ambos LEDS en laboratorio.
- `resultados_laboratorio/LED1`: tablas y figuras del LED 1 en laboratorio.
- `resultados_laboratorio/LED2`: tablas y figuras del LED 2 en laboratorio.
- `resultados_laboratorio/Ambos_LEDS`: tablas y figuras del análisis simultáneo en laboratorio.
- `codigos_terreno/P1_LED1`: scripts MATLAB para el análisis individual del punto P1 y LED 1 en terreno.
- `codigos_terreno/P2_LED2`: scripts MATLAB para el análisis individual del punto P2 y LED 2 en terreno.
- `codigos_terreno/P3_LED3`: scripts MATLAB para el análisis individual del punto P3 y LED 3 en terreno.
- `codigos_terreno/Comparativas`: scripts MATLAB para las comparativas entre LEDS evaluados en terreno.
- `resultados_terreno/P1_LED1`: tablas y figuras del punto P1 y LED 1 en terreno.
- `resultados_terreno/P2_LED2`: tablas y figuras del punto P2 y LED 2 en terreno.
- `resultados_terreno/P3_LED3`: tablas y figuras del punto P3 y LED 3 en terreno.
- `resultados_terreno/Comparativas`: tablas y figuras de las comparativas realizadas en terreno.
- `codigos_complementarios`: códigos de apoyo metodológico y versiones descartadas documentadas.

## Datos crudos y figuras editables

Los archivos `.csv` originales adquiridos desde el osciloscopio no se incluyen directamente en este repositorio debido a su tamaño. Estos datos se encuentran disponibles en la carpeta complementaria de Drive:

**Drive de datos crudos:**  
https://drive.google.com/drive/u/1/folders/12-3iKfvaBkIH_hp0NsVCcrXfb7bPhxMP

Las figuras editables en formato `.fig` de MATLAB, junto con sus versiones `.png`, se encuentran disponibles en la siguiente carpeta complementaria:

**Drive de figuras editables:**  
https://drive.google.com/drive/u/1/folders/1AINsJb4_ADLHhj7FFFH9OWg6UuHwlGNK

Para ejecutar los scripts, se deben descargar los datos crudos y modificar las variables de ruta indicadas al inicio de cada archivo MATLAB.

## Orden general de ejecución

1. Descargar los datos crudos desde la carpeta de almacenamiento en la nube.
2. Modificar las rutas locales al inicio de cada script MATLAB.
3. Ejecutar los scripts individuales de Periodograma, Welch y Multitaper según corresponda.
4. Ejecutar los scripts comparativos correspondientes.
5. Revisar las tablas y figuras generadas en las carpetas de resultados.
