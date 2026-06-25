%% LED1_03_multitaper_V2_afinada_local.m
%
% INSTRUCCIONES DE USO
% Antes de ejecutar este script, revisar la variable carpeta_csv
% y modificarla si los archivos .csv se encuentran en otra ruta local.
% La carpeta indicada debe contener los archivos ON_10msdiv_10M_rep*.csv
% y OFF_10msdiv_10M_rep*.csv definidos en las listas archivos_ON
% y archivos_OFF.
%
% Ejemplo:
% carpeta_csv = 'C:\Users\NombreUsuario\Desktop\Pruebas (LED 1)';

clear; 
clc; 
close all;

%% 1. Configuracion

carpeta_csv = 'C:\Users\mudrood\Desktop\Modulo Prof\Archivos Tesis\Toma de Datos\Pruebas (LED 1)';

carpeta_general = fullfile(carpeta_csv, 'Resultados_LED1_modificados');
carpeta_salida = fullfile(carpeta_general, '03_Multitaper');

if ~exist(carpeta_general, 'dir')
    mkdir(carpeta_general);
end

if ~exist(carpeta_salida, 'dir')
    mkdir(carpeta_salida);
end

archivos_ON = {
    'ON_10msdiv_10M_rep1.csv'
    'ON_10msdiv_10M_rep2.csv'
    'ON_10msdiv_10M_rep3.csv'
    'ON_10msdiv_10M_rep4.csv'
};

archivos_OFF = {
    'OFF_10msdiv_10M_rep1.csv'
    'OFF_10msdiv_10M_rep2.csv'
    'OFF_10msdiv_10M_rep3.csv'
    'OFF_10msdiv_10M_rep4.csv'
};

nrep = numel(archivos_ON);

if numel(archivos_ON) ~= numel(archivos_OFF)
    error('La cantidad de archivos ON y OFF no coincide.');
end

%% 2. Parametros locales

fc_ref = 56400;             
ancho_local_Hz = 1000;      

fmin_local = fc_ref - ancho_local_Hz;
fmax_local = fc_ref + ancho_local_Hz;

ventana_rep_Hz = 200;

umbralScoreRep_dB = 3;

NW = 2.5;
NFFT = 2^20;

%% 3. Calculo Multitaper

P_ON = [];
P_OFF = [];

info_archivos = table();

fprintf('\n============================================\n');
fprintf('MULTITAPER LED 1 V2 AFINADA - SOLO LOCAL\n');
fprintf('============================================\n');
fprintf('Carpeta entrada:\n%s\n', carpeta_csv);
fprintf('\nCarpeta salida:\n%s\n', carpeta_salida);
fprintf('\nFrecuencia referencia: %.3f kHz\n', fc_ref/1e3);
fprintf('Ventana local: %.3f a %.3f kHz\n', fmin_local/1e3, fmax_local/1e3);
fprintf('NW = %.2f\n', NW);
fprintf('NFFT = %d\n', NFFT);

for k = 1:nrep

    archivo_on = fullfile(carpeta_csv, archivos_ON{k});
    archivo_off = fullfile(carpeta_csv, archivos_OFF{k});

    [t_on, y_on] = leer_csv_rigol_simple_local(archivo_on);
    [t_off, y_off] = leer_csv_rigol_simple_local(archivo_off);

    %% Estimacion de frecuencia de muestreo

    Fs_on_mean = 1 / mean(diff(t_on));
    Fs_off_mean = 1 / mean(diff(t_off));

    Fs_on_median = 1 / median(diff(t_on));
    Fs_off_median = 1 / median(diff(t_off));

    Fs_on_duracion = (numel(t_on)-1) / (t_on(end)-t_on(1));
    Fs_off_duracion = (numel(t_off)-1) / (t_off(end)-t_off(1));

    Fs = mean([Fs_on_duracion, Fs_off_duracion]);

    diferencia_mean_median_on = abs(Fs_on_mean - Fs_on_median) / Fs_on_mean * 100;
    diferencia_mean_median_off = abs(Fs_off_mean - Fs_off_median) / Fs_off_mean * 100;

    if diferencia_mean_median_on > 1 || diferencia_mean_median_off > 1
        warning(['Fs_mean y Fs_median difieren mas de 1%%. ', ...
                 'Se usara Fs por duracion/media porque es coherente con muestras y duracion.']);
    end

    N_on = numel(y_on);
    N_off = numel(y_off);

    dur_on = t_on(end) - t_on(1);
    dur_off = t_off(end) - t_off(1);

    fprintf('\n--------------------------------------------\n');
    fprintf('Repeticion %d/%d\n', k, nrep);
    fprintf('ON : %s\n', archivos_ON{k});
    fprintf('OFF: %s\n', archivos_OFF{k});
    fprintf('Muestras ON : %d\n', N_on);
    fprintf('Muestras OFF: %d\n', N_off);
    fprintf('Fs ON median : %.6f Hz\n', Fs_on_median);
    fprintf('Fs OFF median: %.6f Hz\n', Fs_off_median);
    fprintf('Fs ON mean   : %.6f Hz\n', Fs_on_mean);
    fprintf('Fs OFF mean  : %.6f Hz\n', Fs_off_mean);
    fprintf('Fs ON duracion : %.6f Hz\n', Fs_on_duracion);
    fprintf('Fs OFF duracion: %.6f Hz\n', Fs_off_duracion);
    fprintf('Fs usada       : %.6f Hz\n', Fs);
    fprintf('Duracion ON : %.9f s\n', dur_on);
    fprintf('Duracion OFF: %.9f s\n', dur_off);
    fprintf('df grilla MT: %.6f Hz\n', Fs/NFFT);

    info_archivos = [info_archivos; crear_fila_info( ...
        string(archivos_ON{k}), "ON", k, N_on, Fs_on_median, Fs_on_mean, Fs_on_duracion, dur_on)];

    info_archivos = [info_archivos; crear_fila_info( ...
        string(archivos_OFF{k}), "OFF", k, N_off, Fs_off_median, Fs_off_mean, Fs_off_duracion, dur_off)];

    %% Calculo Multitaper

    [Pxx_on, f] = pmtm(y_on, NW, NFFT, Fs);
    [Pxx_off, f_off] = pmtm(y_off, NW, NFFT, Fs);

    if numel(f) ~= numel(f_off) || max(abs(f - f_off)) > 1e-9
        error('La grilla de frecuencia ON/OFF no coincide en la repeticion %d.', k);
    end

    P_ON(:,k) = 10*log10(Pxx_on + eps);
    P_OFF(:,k) = 10*log10(Pxx_off + eps);
end

%% 4. Promedios y score local

P_ON_prom = mean(P_ON, 2, 'omitnan');
P_OFF_prom = mean(P_OFF, 2, 'omitnan');

score_prom = P_ON_prom - P_OFF_prom;
score_rep = P_ON - P_OFF;

idx_local = f >= fmin_local & f <= fmax_local;

f_local = f(idx_local);
P_ON_local = P_ON_prom(idx_local);
P_OFF_local = P_OFF_prom(idx_local);
score_local = score_prom(idx_local);

%% 5. Maximo local en torno a la frecuencia de referencia

[score_local_max, idx_max] = max(score_local, [], 'omitnan');

fc_local = f_local(idx_max);

ON_local_dB = interp1(f, P_ON_prom, fc_local, 'linear');
OFF_local_dB = interp1(f, P_OFF_prom, fc_local, 'linear');

%% 6. Repetibilidad local por repeticion

idx_rep = f >= fc_local - ventana_rep_Hz & f <= fc_local + ventana_rep_Hz;

rep_positivas_0dB = 0;
rep_positivas_3dB = 0;

fc_por_rep = zeros(nrep,1);
score_por_rep = zeros(nrep,1);
score_positivo_0dB = false(nrep,1);
score_positivo_3dB = false(nrep,1);

for k = 1:nrep

    score_k = score_rep(idx_local,k);

    [score_por_rep(k), idx_k] = max(score_k, [], 'omitnan');
    fc_por_rep(k) = f_local(idx_k);

    if score_por_rep(k) > 0
        rep_positivas_0dB = rep_positivas_0dB + 1;
        score_positivo_0dB(k) = true;
    end

    maxScoreRep_3dB = max(score_rep(idx_rep,k), [], 'omitnan');

    if maxScoreRep_3dB >= umbralScoreRep_dB
        rep_positivas_3dB = rep_positivas_3dB + 1;
        score_positivo_3dB(k) = true;
    end
end

%% 7. Tablas

tabla_resumen = table( ...
    fc_ref, ...
    fc_ref/1e3, ...
    ancho_local_Hz, ...
    fmin_local, ...
    fmax_local, ...
    fc_local, ...
    fc_local/1e3, ...
    score_local_max, ...
    ON_local_dB, ...
    OFF_local_dB, ...
    rep_positivas_0dB, ...
    rep_positivas_3dB, ...
    nrep, ...
    umbralScoreRep_dB, ...
    ventana_rep_Hz, ...
    NW, ...
    NFFT, ...
    Fs/NFFT, ...
    'VariableNames', { ...
    'fc_ref_Hz', ...
    'fc_ref_kHz', ...
    'ancho_local_Hz', ...
    'fmin_local_Hz', ...
    'fmax_local_Hz', ...
    'fc_local_Hz', ...
    'fc_local_kHz', ...
    'score_local_dB', ...
    'ON_dB', ...
    'OFF_dB', ...
    'rep_positivas_0dB', ...
    'rep_positivas_3dB', ...
    'rep_totales', ...
    'umbral_repetibilidad_dB', ...
    'ventana_repetibilidad_Hz', ...
    'NW', ...
    'NFFT', ...
    'df_grilla_Hz'} );

tabla_repeticiones = table( ...
    (1:nrep)', ...
    fc_por_rep, ...
    fc_por_rep/1e3, ...
    score_por_rep, ...
    score_positivo_0dB, ...
    score_positivo_3dB, ...
    'VariableNames', { ...
    'repeticion', ...
    'fc_local_Hz', ...
    'fc_local_kHz', ...
    'score_local_dB', ...
    'score_positivo_0dB', ...
    'score_positivo_3dB'} );

fprintf('\n============================================\n');
fprintf('RESULTADO MULTITAPER LOCAL LED 1\n');
fprintf('============================================\n');

disp(tabla_resumen);
disp(tabla_repeticiones);

fprintf('\nFrecuencia local detectada = %.3f Hz = %.3f kHz\n', fc_local, fc_local/1e3);
fprintf('Score local ON-OFF = %.3f dB\n', score_local_max);
fprintf('Repetibilidad > 0 dB: %d/%d\n', rep_positivas_0dB, nrep);
fprintf('Repetibilidad >= %.1f dB: %d/%d\n', umbralScoreRep_dB, rep_positivas_3dB, nrep);

%% Guardar tablas en formato CSV

writetable(tabla_resumen, fullfile(carpeta_salida, ...
    'tabla_MT_LED1_V2_local_resumen.csv'));

writetable(tabla_repeticiones, fullfile(carpeta_salida, ...
    'tabla_MT_LED1_V2_local_repeticiones.csv'));

writetable(info_archivos, fullfile(carpeta_salida, ...
    'info_archivos_MT_LED1_V2_local.csv'));

%% Guardar tablas como figuras

tabla_resumen_fig = tabla_resumen;

cols_eliminar_resumen = { ...
    'fc_ref_Hz', ...
    'ancho_local_Hz', ...
    'fmin_local_Hz', ...
    'fmax_local_Hz', ...
    'fc_local_Hz', ...
    'ventana_repetibilidad_Hz', ...
    'NFFT', ...
    'df_grilla_Hz'};

for c = 1:numel(cols_eliminar_resumen)
    if ismember(cols_eliminar_resumen{c}, tabla_resumen_fig.Properties.VariableNames)
        tabla_resumen_fig.(cols_eliminar_resumen{c}) = [];
    end
end

tabla_resumen_fig.Properties.VariableNames = { ...
    'fc_ref_kHz', ...
    'fc_local_kHz', ...
    'score_local', ...
    'ON_dB', ...
    'OFF_dB', ...
    'rep_0dB', ...
    'rep_3dB', ...
    'rep_totales', ...
    'umbral_3dB', ...
    'NW'};

guardar_tabla_como_figura( ...
    tabla_resumen_fig, ...
    'TABLA RESUMEN MULTITAPER LOCAL LED 1', ...
    fullfile(carpeta_salida, 'tabla_MT_LED1_V2_local_resumen.png'), ...
    fullfile(carpeta_salida, 'tabla_MT_LED1_V2_local_resumen.fig'));

tabla_repeticiones_fig = tabla_repeticiones;

if ismember('fc_local_Hz', tabla_repeticiones_fig.Properties.VariableNames)
    tabla_repeticiones_fig.fc_local_Hz = [];
end

tabla_repeticiones_fig.Properties.VariableNames = { ...
    'repeticion', ...
    'fc_local_kHz', ...
    'score_local', ...
    'score_positivo_0dB', ...
    'score_positivo_3dB'};

guardar_tabla_como_figura( ...
    tabla_repeticiones_fig, ...
    'TABLA REPETICIONES MULTITAPER LOCAL LED 1', ...
    fullfile(carpeta_salida, 'tabla_MT_LED1_V2_local_repeticiones.png'), ...
    fullfile(carpeta_salida, 'tabla_MT_LED1_V2_local_repeticiones.fig'));

%% 8. Figura 1: PSD ON/OFF local

fig = figure('Color','w','Position',[100 100 1200 700]);

plot(f_local/1e3, P_ON_local, 'LineWidth', 1.6); hold on;
plot(f_local/1e3, P_OFF_local, 'LineWidth', 1.6);

xline(fc_local/1e3, ':', sprintf('Local %.3f kHz', fc_local/1e3), ...
    'LineWidth', 1.4, ...
    'LabelOrientation','horizontal', ...
    'LabelVerticalAlignment','bottom', ...
    'HandleVisibility','off');

grid on;
xlabel('Frecuencia [kHz]');
ylabel('PSD Multitaper [dB/Hz]');
title(sprintf('LED 1 - Multitaper local: PSD ON/OFF, referencia %.1f kHz', fc_ref/1e3), ...
    'Interpreter','none');
legend('LED encendido','LED apagado','Location','best');
xlim([fmin_local fmax_local]/1e3);

saveas(fig, fullfile(carpeta_salida, ...
    'MT_LED1_V2_local_ON_OFF_56kHz.png'));
savefig(fig, fullfile(carpeta_salida, ...
    'MT_LED1_V2_local_ON_OFF_56kHz.fig'));

%% 9. Figura 2: score local promedio

fig = figure('Color','w','Position',[100 100 1200 700]);

plot(f_local/1e3, score_local, 'LineWidth', 1.8); hold on;

yline(0, '--', '0 dB', 'HandleVisibility','off');
yline(umbralScoreRep_dB, '--', sprintf('Criterio %.1f dB', umbralScoreRep_dB), ...
    'HandleVisibility','off');

xline(fc_ref/1e3, '--', 'Referencia 56.4 kHz', ...
    'LineWidth', 1.1, ...
    'HandleVisibility','off');

xline(fc_local/1e3, ':', sprintf('Local %.3f kHz', fc_local/1e3), ...
    'LineWidth', 1.4, ...
    'HandleVisibility','off');

plot(fc_local/1e3, score_local_max, 'o', ...
    'MarkerSize', 8, ...
    'LineWidth', 2, ...
    'DisplayName','Maximo local');

grid on;
xlabel('Frecuencia [kHz]');
ylabel('Score ON - OFF [dB]');
title('LED 1 - Multitaper local: score ON-OFF alrededor de 56.4 kHz', ...
    'Interpreter','none');
legend('Score promedio','Maximo local','Location','best');
xlim([fmin_local fmax_local]/1e3);

saveas(fig, fullfile(carpeta_salida, ...
    'MT_LED1_V2_local_score_56kHz.png'));
savefig(fig, fullfile(carpeta_salida, ...
    'MT_LED1_V2_local_score_56kHz.fig'));

%% 10. Figura 3: score local por repeticion

fig = figure('Color','w','Position',[100 100 1200 700]);

plot(f_local/1e3, score_rep(idx_local,:), 'LineWidth', 1.1); hold on;

plot(f_local/1e3, score_local, 'k', 'LineWidth', 2.0, ...
    'DisplayName','Promedio');

yline(0, '--', '0 dB', 'HandleVisibility','off');
yline(umbralScoreRep_dB, '--', sprintf('Criterio %.1f dB', umbralScoreRep_dB), ...
    'HandleVisibility','off');

xline(fc_local/1e3, ':', sprintf('Local %.3f kHz', fc_local/1e3), ...
    'LineWidth', 1.4, ...
    'HandleVisibility','off');

grid on;
xlabel('Frecuencia [kHz]');
ylabel('Score ON - OFF [dB]');
title('LED 1 - Multitaper local: score por repeticion alrededor de 56.4 kHz', ...
    'Interpreter','none');
legend([compose('Rep %d', 1:nrep), {'Promedio'}], 'Location','best');
xlim([fmin_local fmax_local]/1e3);

saveas(fig, fullfile(carpeta_salida, ...
    'MT_LED1_V2_local_score_repeticiones_56kHz.png'));
savefig(fig, fullfile(carpeta_salida, ...
    'MT_LED1_V2_local_score_repeticiones_56kHz.fig'));

%% 11. Figura 4: frecuencias locales por repeticion

fig = figure('Color','w','Position',[100 100 1200 700]);

bar(1:nrep, fc_por_rep/1e3, 0.65);
hold on;
grid on;
box on;

yline(fc_ref/1e3, '--', sprintf('Referencia %.1f kHz', fc_ref/1e3), ...
    'LineWidth', 1.1, ...
    'LabelHorizontalAlignment','left', ...
    'HandleVisibility','off');

yline(fc_local/1e3, ':', sprintf('Local promedio %.3f kHz', fc_local/1e3), ...
    'LineWidth', 1.4, ...
    'LabelHorizontalAlignment','right', ...
    'HandleVisibility','off');

xlabel('Repeticion');
ylabel('Frecuencia local [kHz]');
title('LED 1 - Multitaper local: frecuencia detectada por repeticion', ...
    'Interpreter','none');

xticks(1:nrep);
ylim([(fmin_local/1e3) (fmax_local/1e3)]);

for k = 1:nrep
    text(k, fc_por_rep(k)/1e3 + 0.025, ...
        sprintf('%.3f kHz', fc_por_rep(k)/1e3), ...
        'HorizontalAlignment','center', ...
        'VerticalAlignment','bottom', ...
        'FontSize',9);
end

saveas(fig, fullfile(carpeta_salida, ...
    'MT_LED1_V2_local_frecuencia_por_repeticion.png'));
savefig(fig, fullfile(carpeta_salida, ...
    'MT_LED1_V2_local_frecuencia_por_repeticion.fig'));

%% 12. Figura 5: score local por repeticion

fig = figure('Color','w','Position',[100 100 1200 700]);

bar(1:nrep, score_por_rep, 0.65);
hold on;
grid on;
box on;

yline(0, '--', '0 dB', ...
    'HandleVisibility','off');

yline(umbralScoreRep_dB, '--', sprintf('Criterio %.1f dB', umbralScoreRep_dB), ...
    'LineWidth', 1.1, ...
    'LabelHorizontalAlignment','right', ...
    'HandleVisibility','off');

xlabel('Repeticion');
ylabel('Score local maximo [dB]');
title('LED 1 - Multitaper local: score maximo por repeticion', ...
    'Interpreter','none');

xticks(1:nrep);

ylim([0, max(score_por_rep) + 1.5]);

for k = 1:nrep
    text(k, score_por_rep(k) + 0.25, ...
        sprintf('%.2f dB\n%.3f kHz', score_por_rep(k), fc_por_rep(k)/1e3), ...
        'HorizontalAlignment','center', ...
        'VerticalAlignment','bottom', ...
        'FontSize',9);
end

saveas(fig, fullfile(carpeta_salida, ...
    'MT_LED1_V2_local_score_por_repeticion.png'));
savefig(fig, fullfile(carpeta_salida, ...
    'MT_LED1_V2_local_score_por_repeticion.fig'));

%% 13. Guardar variables

save(fullfile(carpeta_salida, 'datos_MT_LED1_V2_local_56kHz.mat'), ...
    'f', ...
    'P_ON', ...
    'P_OFF', ...
    'P_ON_prom', ...
    'P_OFF_prom', ...
    'score_prom', ...
    'score_rep', ...
    'fc_ref', ...
    'fc_local', ...
    'score_local_max', ...
    'fc_por_rep', ...
    'score_por_rep', ...
    'rep_positivas_0dB', ...
    'rep_positivas_3dB', ...
    'tabla_resumen', ...
    'tabla_repeticiones', ...
    'info_archivos', ...
    'NW', ...
    'NFFT', ...
    'nrep', ...
    'fmin_local', ...
    'fmax_local', ...
    'ancho_local_Hz', ...
    'ventana_rep_Hz', ...
    'umbralScoreRep_dB');

fprintf('\n============================================\n');
fprintf('Multitaper LED 1 V2 local terminado.\n');
fprintf('fc local = %.3f Hz = %.3f kHz\n', fc_local, fc_local/1e3);
fprintf('score local = %.3f dB\n', score_local_max);
fprintf('Resultados guardados en:\n%s\n', carpeta_salida);
fprintf('============================================\n');

%% ============================================================
% Funcion local para leer CSV Rigol

function [t, y] = leer_csv_rigol_simple_local(nombre_archivo)

    if ~isfile(nombre_archivo)
        error('No se encuentra el archivo: %s', nombre_archivo);
    end

    T = readtable(nombre_archivo, 'VariableNamingRule', 'preserve');

    M = [];

    for c = 1:width(T)

        col = T{:, c};

        if iscell(col)
            col_num = str2double(col);
        elseif isstring(col)
            col_num = str2double(col);
        else
            col_num = double(col);
        end

        if sum(~isnan(col_num)) > 10
            M = [M, col_num]; %#ok<AGROW>
        end
    end

    M = M(all(~isnan(M), 2), :);

    if size(M, 2) < 2
        error('No se detectaron dos columnas numericas en: %s', nombre_archivo);
    end

    t = M(:,1);
    y = M(:,2);

    t = t(:);
    y = y(:);

    [t, idx] = unique(t, 'stable');
    y = y(idx);

    y = y - mean(y, 'omitnan');
end

%% ============================================================
% Funcion local para tabla de informacion

function fila = crear_fila_info(archivo, condicion, repeticion, muestras, Fs_median_Hz, Fs_mean_Hz, Fs_duracion_Hz, duracion_s)

    diferencia_mean_median_pct = abs(Fs_mean_Hz - Fs_median_Hz) / Fs_mean_Hz * 100;
    diferencia_duracion_mean_pct = abs(Fs_duracion_Hz - Fs_mean_Hz) / Fs_mean_Hz * 100;

    fila = table( ...
        archivo, ...
        condicion, ...
        repeticion, ...
        muestras, ...
        Fs_median_Hz, ...
        Fs_mean_Hz, ...
        Fs_duracion_Hz, ...
        diferencia_mean_median_pct, ...
        diferencia_duracion_mean_pct, ...
        duracion_s, ...
        'VariableNames', { ...
        'Archivo', ...
        'Condicion', ...
        'Repeticion', ...
        'Muestras', ...
        'Fs_median_Hz', ...
        'Fs_mean_Hz', ...
        'Fs_duracion_Hz', ...
        'Diferencia_mean_median_pct', ...
        'Diferencia_duracion_mean_pct', ...
        'Duracion_s'} );
end

%% ============================================================
% Funcion local para guardar una tabla como figura

function guardar_tabla_como_figura(tabla, titulo_tabla, archivo_png, archivo_fig)


    if isempty(tabla)
        warning('La tabla esta vacia. No se guardara figura de tabla.');
        return;
    end

    data_cell = formatear_tabla_para_figura(tabla);

    nombres = tabla.Properties.VariableNames;
    nfilas = height(tabla);
    ncols = width(tabla);

    %% 1. Definir ancho automatico de columnas

    ancho_col = zeros(1, ncols);

    for c = 1:ncols

        textos_columna = data_cell(:,c);
        largo_max_datos = 0;

        for i = 1:nfilas
            largo_max_datos = max(largo_max_datos, length(textos_columna{i}));
        end

        largo_max = max(length(nombres{c}), largo_max_datos);

        ancho_col(c) = 8*largo_max + 24;
        ancho_col(c) = max(75, min(155, ancho_col(c)));
    end

    %% 2. Definir tamaño compacto de figura

    margen_izq = 30;
    margen_der = 30;
    margen_inf = 25;
    alto_titulo = 55;
    alto_fila = 28;
    alto_header = 30;

    ancho_tabla = sum(ancho_col);
    alto_tabla = alto_header + nfilas*alto_fila;

    ancho_fig = margen_izq + ancho_tabla + margen_der;
    alto_fig = margen_inf + alto_tabla + alto_titulo + 15;

    fig = figure('Color','w', ...
        'Units','pixels', ...
        'Position',[100 100 ancho_fig alto_fig], ...
        'Visible','on');

    ax = axes('Parent',fig, ...
        'Units','pixels', ...
        'Position',[0 0 ancho_fig alto_fig]);

    axis(ax, [0 ancho_fig 0 alto_fig]);
    axis(ax, 'off');
    hold(ax, 'on');

    %% 3. Titulo centrado

    text(ax, ancho_fig/2, alto_fig - 28, titulo_tabla, ...
        'HorizontalAlignment','center', ...
        'VerticalAlignment','middle', ...
        'FontWeight','bold', ...
        'FontSize',15, ...
        'Interpreter','none');

    %% 4. Dibujar encabezado y filas

    x0 = margen_izq;
    y0 = margen_inf + alto_tabla;

    color_header = [0.93 0.93 0.93];
    color_fila_1 = [1 1 1];
    color_fila_2 = [0.94 0.94 0.94];
    color_borde = [0.65 0.65 0.65];

    x = x0;

    for c = 1:ncols

        rectangle(ax, ...
            'Position',[x, y0 - alto_header, ancho_col(c), alto_header], ...
            'FaceColor',color_header, ...
            'EdgeColor',color_borde, ...
            'LineWidth',0.8);

        text(ax, x + ancho_col(c)/2, y0 - alto_header/2, nombres{c}, ...
            'HorizontalAlignment','center', ...
            'VerticalAlignment','middle', ...
            'FontWeight','bold', ...
            'FontSize',9, ...
            'Interpreter','none');

        x = x + ancho_col(c);
    end

    for i = 1:nfilas

        y = y0 - alto_header - i*alto_fila;

        if mod(i,2) == 0
            color_fila = color_fila_2;
        else
            color_fila = color_fila_1;
        end

        x = x0;

        for c = 1:ncols

            rectangle(ax, ...
                'Position',[x, y, ancho_col(c), alto_fila], ...
                'FaceColor',color_fila, ...
                'EdgeColor',[0.88 0.88 0.88], ...
                'LineWidth',0.5);

            text(ax, x + ancho_col(c)/2, y + alto_fila/2, data_cell{i,c}, ...
                'HorizontalAlignment','center', ...
                'VerticalAlignment','middle', ...
                'FontSize',9, ...
                'Interpreter','none');

            x = x + ancho_col(c);
        end
    end

    %% 5. Guardar figura

    drawnow;

    print(fig, archivo_png, '-dpng', '-r300');
    savefig(fig, archivo_fig);
end

%% ============================================================
% Funcion local para formatear tabla antes de dibujarla

function data_cell = formatear_tabla_para_figura(tabla)

    nfilas = height(tabla);
    ncols = width(tabla);

    data_cell = cell(nfilas, ncols);
    nombres = tabla.Properties.VariableNames;

    for c = 1:ncols

        nombre = nombres{c};
        col = tabla.(nombre);

        for i = 1:nfilas

            if iscell(col)
                valor = col{i};
            else
                valor = col(i);
            end

            if isnumeric(valor)

                if isnan(valor)
                    texto = '';

                elseif contains(nombre, 'kHz', 'IgnoreCase', true)
                    texto = sprintf('%.4f', valor);

                elseif contains(nombre, 'Hz', 'IgnoreCase', true)
                    texto = sprintf('%.0f', valor);

                elseif contains(nombre, 'dB', 'IgnoreCase', true)
                    texto = sprintf('%.4f', valor);

                elseif contains(nombre, 'rep', 'IgnoreCase', true)
                    texto = sprintf('%.0f', valor);

                elseif contains(nombre, 'NFFT', 'IgnoreCase', true)
                    texto = sprintf('%.0f', valor);

                elseif contains(nombre, 'NW', 'IgnoreCase', true)
                    texto = sprintf('%.2f', valor);

                else
                    texto = sprintf('%.4f', valor);
                end

            elseif islogical(valor)

                if valor
                    texto = 'Si';
                else
                    texto = 'No';
                end

            elseif isstring(valor)

                if strlength(valor) == 0
                    texto = '';
                else
                    texto = char(valor);
                end

            elseif ischar(valor)

                texto = valor;

            else

                texto = char(string(valor));
            end

            data_cell{i,c} = texto;
        end
    end
end