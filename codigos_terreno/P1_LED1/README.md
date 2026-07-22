# P1 - LED terreno 1

Esta carpeta contiene los scripts MATLAB utilizados para el análisis espectral del punto de medición P1, asociado al LED 1 en terreno.

## Orden de ejecución

1. `T01_P1_periodogram_terreno.m`
2. `T02_P1_welch_terreno.m`
3. `T03_P1_multitaper_terreno.m`

El Periodograma se utiliza como método principal de detección. Welch y Multitaper se emplean como métodos complementarios.

## Datos de entrada

Los scripts utilizan archivos ON correspondientes al punto P1 y archivos OFF comunes para los análisis de terreno.

Los archivos CSV originales no se incluyen en GitHub debido a su tamaño.

## Ejecución

Antes de ejecutar cada script, se deben modificar las rutas locales indicadas al inicio del archivo MATLAB.
