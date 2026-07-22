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
- `codigos_terreno`: scripts MATLAB para el análisis espectral de las mediciones realizadas en terreno.
- `resultados_terreno`: tablas y figuras obtenidas a partir del análisis de terreno.
- `codigos_complementarios`: códigos de apoyo metodológico y versiones descartadas documentadas.

## Datos crudos

Los archivos CSV originales adquiridos desde el osciloscopio no se incluyen en este repositorio debido a su tamaño. Estos archivos se encuentran disponibles en:

[ENLACE_DRIVE](https://drive.google.com/drive/folders/12-3iKfvaBkIH_hp0NsVCcrXfb7bPhxMP?usp=sharing)

Para ejecutar los scripts, se deben descargar los datos crudos y modificar las variables de ruta indicadas al inicio de cada archivo MATLAB.

## Orden general de ejecución

1. Descargar los datos crudos desde la carpeta de almacenamiento en la nube.
2. Modificar las rutas locales al inicio de cada script MATLAB.
3. Ejecutar los scripts individuales de Periodograma, Welch y Multitaper según corresponda.
4. Ejecutar los scripts comparativos correspondientes.
5. Revisar las tablas y figuras generadas en las carpetas de resultados.
