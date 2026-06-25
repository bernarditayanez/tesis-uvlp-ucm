%% LED1_multitaper_descartado_78kHz.m
%
% INSTRUCCIONES DE USO
% Este script corresponde a una version preliminar del analisis Multitaper
% aplicado al LED 1. Se conserva como codigo complementario porque entrego
% una frecuencia candidata que posteriormente fue descartada del flujo
% principal de resultados.
%
% Antes de ejecutar este script, revisar la variable carpeta_csv
% y modificarla si los archivos .csv se encuentran en otra ruta local.
% La carpeta indicada debe contener los archivos ON_10msdiv_10M_rep*.csv
% y OFF_10msdiv_10M_rep*.csv definidos en las listas archivos_ON
% y archivos_OFF.
%
% Ejemplo:
% carpeta_csv = 'C:\Users\NombreUsuario\Desktop\Pruebas LED 1';

clear; 
clc; 
close all;

%% 1. Configuracion de carpetas

carpeta_csv = 'C:\Users\mudrood\Desktop\Modulo Prof\Archivos Tesis\Toma de Datos\Pruebas (LED 1)';

carpeta_general = 'C:\Users\mudrood\Desktop\Modulo Prof\Archivos Tesis\Toma de Datos\Pruebas (LED 1)\Resultados_LED1_modificados';

carpeta_salida = fullfile(carpeta_general, '03_Multitaper_descartado_78kHz');

if ~exist(carpeta_general, 'dir')
    mkdir(carpeta_general);
end

if ~exist(carpeta_salida, 'dir')
    mkdir(carpeta_salida);
end

%% 2. Archivos de entrada

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

%% 3. Parametros del analisis

fmin = 30e3;
fmax = 90e3;

num_candidatos = 10;
distancia_minima_Hz = 300;
ventana_local_Hz = 200;

umbralScoreRep_dB = 3;

%% 4. Parametros Multitaper

NW = 2.5;
NFFT = 2^21;

%% 5. Variables de almacenamiento

P_ON = [];
P_OFF = [];

info_archivos = table();

fprintf('\n============================================\n');
fprintf('MULTITAPER PRELIMINAR DESCARTADO LED 1\n');
fprintf('============================================\n');
fprintf('Carpeta de entrada:\n%s\n', carpeta_csv);
fprintf('\nCarpeta de salida:\n%s\n', carpeta_salida);
fprintf('\nBanda de analisis: %.1f kHz a %.1f kHz\n', fmin/1e3, fmax/1e3);
fprintf('Criterio repetibilidad: score local >= %.1f dB\n', umbralScoreRep_dB);
fprintf('NW Multitaper: %.2f\n', NW);
fprintf('NFFT Multitaper: %d\n', NFFT);

%% 6. Lectura de datos y calculo Multitaper

for k = 1:nrep

    archivo_on = fullfile(carpeta_csv, archivos_ON{k});
    archivo_off = fullfile(carpeta_csv, archivos_OFF{k});

    [t_on, y_on_raw, y_on] = leer_csv_rigol_led1(archivo_on);
    [t_off, y_off_raw, y_off] = leer_csv_rigol_led1(archivo_off);

    Fs_on = 1 / mean(diff(t_on));
    Fs_off = 1 / mean(diff(t_off));

    dur_on = t_on(end) - t_on(1);
    dur_off = t_off(end) - t_off(1);

    N_on = numel(y_on);
    N_off = numel(y_off);

    Fs = mean([Fs_on, Fs_off]);

    diferencia_Fs_rel = abs(Fs_on - Fs_off) / Fs;

    fprintf('\n--------------------------------------------\n');
    fprintf('Repeticion %d/%d\n', k, nrep);
    fprintf('ON : %s\n', archivos_ON{k});
    fprintf('OFF: %s\n', archivos_OFF{k});
    fprintf('Muestras ON : %d\n', N_on);
    fprintf('Muestras OFF: %d\n', N_off);
    fprintf('Fs ON  estimada: %.6f Hz\n', Fs_on);
    fprintf('Fs OFF estimada: %.6f Hz\n', Fs_off);
    fprintf('Fs usada par ON/OFF: %.6f Hz\n', Fs);
    fprintf('Duracion ON : %.9f s\n', dur_on);
    fprintf('Duracion OFF: %.9f s\n', dur_off);
    fprintf('Diferencia relativa Fs ON/OFF: %.6f %%\n', diferencia_Fs_rel*100);
    fprintf('Resolucion grilla Multitaper aprox: %.6f Hz\n', Fs/NFFT);

    if diferencia_Fs_rel > 0.005
        warning('La Fs estimada entre ON y OFF difiere mas de 0.5 %% en la repeticion %d.', k);
    end

    info_archivos = [info_archivos; crear_fila_info( ...
        string(archivos_ON{k}), "ON", k, N_on, Fs_on, dur_on, ...
        mean(y_on_raw, 'omitnan'), std(y_on_raw, 'omitnan'))];

    info_archivos = [info_archivos; crear_fila_info( ...
        string(archivos_OFF{k}), "OFF", k, N_off, Fs_off, dur_off, ...
        mean(y_off_raw, 'omitnan'), std(y_off_raw, 'omitnan'))];

    [Pxx_on, f] = pmtm(y_on, NW, NFFT, Fs);
    [Pxx_off, f_off] = pmtm(y_off, NW, NFFT, Fs);

    if numel(f) ~= numel(f_off) || max(abs(f - f_off)) > 1e-9
        error('La grilla de frecuencia ON/OFF no coincide en la repeticion %d.', k);
    end

    P_ON(:,k) = 10*log10(Pxx_on + eps);
    P_OFF(:,k) = 10*log10(Pxx_off + eps);
end

%% 7. Promedio entre repeticiones

P_ON_prom = mean(P_ON, 2, 'omitnan');
P_OFF_prom = mean(P_OFF, 2, 'omitnan');

score_prom = P_ON_prom - P_OFF_prom;
score_rep = P_ON - P_OFF;

idx_rango = f >= fmin & f <= fmax;

f_rango = f(idx_rango);
P_ON_rango = P_ON_prom(idx_rango);
P_OFF_rango = P_OFF_prom(idx_rango);
score_rango = score_prom(idx_rango);

%% 8. Busqueda de candidatos espectrales

[pks, locs] = findpeaks(score_rango, f_rango, ...
    'SortStr', 'descend', ...
    'NPeaks', num_candidatos, ...
    'MinPeakDistance', distancia_minima_Hz);

idx_pos = pks > 0;
pks = pks(idx_pos);
locs = locs(idx_pos);

fc_candidatas = locs(:);
score_peak_dB = pks(:);

n_cand = numel(fc_candidatas);

if n_cand == 0

    warning('No se encontraron candidatos con score positivo en la banda %.1f-%.1f kHz.', ...
        fmin/1e3, fmax/1e3);

    tabla = table();
    fc_principal = NaN;

else

    %% 9. Analisis local y repetibilidad

    score_local_dB = zeros(n_cand,1);
    f_local_Hz = zeros(n_cand,1);
    ON_dB = zeros(n_cand,1);
    OFF_dB = zeros(n_cand,1);
    rep_positivas_3dB = zeros(n_cand,1);
    rep_positivas_0dB = zeros(n_cand,1);

    for i = 1:n_cand

        fc = fc_candidatas(i);

        idx_local = f >= fc - ventana_local_Hz & f <= fc + ventana_local_Hz;

        f_local = f(idx_local);
        score_local = score_prom(idx_local);

        [score_local_dB(i), idx_max] = max(score_local, [], 'omitnan');
        f_local_Hz(i) = f_local(idx_max);

        ON_dB(i) = interp1(f, P_ON_prom, fc, 'linear');
        OFF_dB(i) = interp1(f, P_OFF_prom, fc, 'linear');

        cuenta_3dB = 0;
        cuenta_0dB = 0;

        for r = 1:nrep

            maxScoreLocalRep = max(score_rep(idx_local,r), [], 'omitnan');

            if maxScoreLocalRep >= umbralScoreRep_dB
                cuenta_3dB = cuenta_3dB + 1;
            end

            if maxScoreLocalRep > 0
                cuenta_0dB = cuenta_0dB + 1;
            end

        end

        rep_positivas_3dB(i) = cuenta_3dB;
        rep_positivas_0dB(i) = cuenta_0dB;
    end

    %% 10. Tabla resumen de candidatos

    tabla = table( ...
        fc_candidatas, ...
        fc_candidatas/1e3, ...
        score_peak_dB, ...
        f_local_Hz, ...
        f_local_Hz/1e3, ...
        score_local_dB, ...
        ON_dB, ...
        OFF_dB, ...
        rep_positivas_3dB, ...
        rep_positivas_0dB, ...
        repmat(nrep,n_cand,1), ...
        repmat(umbralScoreRep_dB,n_cand,1), ...
        'VariableNames', { ...
        'fc_Hz', ...
        'fc_kHz', ...
        'score_peak_dB', ...
        'f_local_Hz', ...
        'f_local_kHz', ...
        'score_local_dB', ...
        'ON_dB', ...
        'OFF_dB', ...
        'rep_positivas_3dB', ...
        'rep_positivas_0dB', ...
        'rep_totales', ...
        'umbral_repetibilidad_dB'} );

    tabla = sortrows(tabla, {'rep_positivas_3dB','score_local_dB'}, {'descend','descend'});

    fc_principal = tabla.fc_Hz(1);

end

%% 11. Mostrar y guardar tablas

fprintf('\n============================================\n');
fprintf('TABLA DE CANDIDATOS MULTITAPER MODIFICADO LED 1\n');
fprintf('============================================\n');

disp(tabla);

if ~isnan(fc_principal)
    fprintf('\nFrecuencia candidata principal Multitaper LED 1 = %.3f Hz = %.3f kHz\n', ...
        fc_principal, fc_principal/1e3);
else
    fprintf('\nNo se definio frecuencia principal porque no hubo candidatos positivos.\n');
end

writetable(tabla, fullfile(carpeta_salida, 'tabla_multitaper_LED1_modificado.csv'));
writetable(info_archivos, fullfile(carpeta_salida, 'info_archivos_multitaper_LED1.csv'));

%% 12. Figura 1: PSD promedio ON/OFF en banda amplia

fmax_amplio = min(5e6, max(f));
idx_amplio = f >= 0 & f <= fmax_amplio;

fig = figure('Color','w','Position',[100 100 1200 700]);

plot(f(idx_amplio)/1e6, P_ON_prom(idx_amplio), 'LineWidth', 1.2); hold on;
plot(f(idx_amplio)/1e6, P_OFF_prom(idx_amplio), 'LineWidth', 1.2);

grid on;
xlabel('Frecuencia [MHz]');
ylabel('PSD Multitaper [dB/Hz]');
title('LED 1 - Multitaper: PSD promedio ON/OFF, rango amplio', 'Interpreter','none');
legend('LED encendido','LED apagado','Location','best');
xlim([0 fmax_amplio/1e6]);

saveas(fig, fullfile(carpeta_salida, 'Multitaper_LED1_ON_OFF_rango_amplio.png'));
savefig(fig, fullfile(carpeta_salida, 'Multitaper_LED1_ON_OFF_rango_amplio.fig'));

%% 13. Figura 2: PSD promedio ON/OFF en 30-90 kHz

fig = figure('Color','w','Position',[100 100 1200 700]);

plot(f_rango/1e3, P_ON_rango, 'LineWidth', 1.5); hold on;
plot(f_rango/1e3, P_OFF_rango, 'LineWidth', 1.5);

if ~isnan(fc_principal)
    xline(fc_principal/1e3, ':', sprintf('%.3f kHz', fc_principal/1e3), ...
        'LineWidth', 1.3, ...
        'HandleVisibility','off');
end

grid on;
xlabel('Frecuencia [kHz]');
ylabel('PSD Multitaper [dB/Hz]');
title('LED 1 - Multitaper: PSD promedio ON/OFF en banda de analisis', 'Interpreter','none');
legend('LED encendido','LED apagado','Location','best');
xlim([fmin fmax]/1e3);

saveas(fig, fullfile(carpeta_salida, 'Multitaper_LED1_ON_OFF_30_90kHz.png'));
savefig(fig, fullfile(carpeta_salida, 'Multitaper_LED1_ON_OFF_30_90kHz.fig'));

%% 14. Figura 3: score ON-OFF en 30-90 kHz

fig = figure('Color','w','Position',[100 100 1200 700]);

plot(f_rango/1e3, score_rango, 'LineWidth', 1.5); hold on;
yline(0, '--', '0 dB', 'HandleVisibility','off');
yline(umbralScoreRep_dB, '--', sprintf('Criterio %.1f dB', umbralScoreRep_dB), ...
    'HandleVisibility','off');

if ~isnan(fc_principal)
    xline(fc_principal/1e3, ':', sprintf('%.3f kHz', fc_principal/1e3), ...
        'LineWidth', 1.3, ...
        'HandleVisibility','off');
end

grid on;
xlabel('Frecuencia [kHz]');
ylabel('Score ON - OFF [dB]');
title('LED 1 - Multitaper: score ON-OFF en banda de analisis', 'Interpreter','none');
xlim([fmin fmax]/1e3);

saveas(fig, fullfile(carpeta_salida, 'Multitaper_LED1_score_ON_OFF_30_90kHz.png'));
savefig(fig, fullfile(carpeta_salida, 'Multitaper_LED1_score_ON_OFF_30_90kHz.fig'));

%% 15. Figura 4: repeticiones ON

fig = figure('Color','w','Position',[100 100 1200 700]);

plot(f_rango/1e3, P_ON(idx_rango,:), 'LineWidth', 1.0);

grid on;
xlabel('Frecuencia [kHz]');
ylabel('PSD Multitaper [dB/Hz]');
title('LED 1 - Multitaper: repeticiones ON', 'Interpreter','none');
legend(compose('ON rep %d', 1:nrep), 'Location','best');
xlim([fmin fmax]/1e3);

saveas(fig, fullfile(carpeta_salida, 'Multitaper_LED1_repeticiones_ON_30_90kHz.png'));
savefig(fig, fullfile(carpeta_salida, 'Multitaper_LED1_repeticiones_ON_30_90kHz.fig'));

%% 16. Figura 5: repeticiones OFF

fig = figure('Color','w','Position',[100 100 1200 700]);

plot(f_rango/1e3, P_OFF(idx_rango,:), 'LineWidth', 1.0);

grid on;
xlabel('Frecuencia [kHz]');
ylabel('PSD Multitaper [dB/Hz]');
title('LED 1 - Multitaper: repeticiones OFF', 'Interpreter','none');
legend(compose('OFF rep %d', 1:nrep), 'Location','best');
xlim([fmin fmax]/1e3);

saveas(fig, fullfile(carpeta_salida, 'Multitaper_LED1_repeticiones_OFF_30_90kHz.png'));
savefig(fig, fullfile(carpeta_salida, 'Multitaper_LED1_repeticiones_OFF_30_90kHz.fig'));

%% 17. Figura 6: barras de candidatos principales

if ~isempty(tabla)

    fig = figure('Color','w','Position',[100 100 1200 700]);

    x = 1:height(tabla);

    bar(x, tabla.score_local_dB);
    hold on;

    yline(umbralScoreRep_dB, '--', sprintf('Criterio %.1f dB', umbralScoreRep_dB), ...
        'LineWidth', 1.2);

    grid on;
    xlabel('Frecuencia candidata [kHz]');
    ylabel('Score local ON-OFF [dB]');
    title('LED 1 - Multitaper: candidatos principales', 'Interpreter','none');

    xticks(x);
    xticklabels(compose('%.3f', tabla.fc_kHz));
    xtickangle(45);

    for i = 1:height(tabla)
        text(x(i), tabla.score_local_dB(i)+0.15, ...
            sprintf('%.2f dB\n%d/%d', ...
            tabla.score_local_dB(i), ...
            tabla.rep_positivas_3dB(i), ...
            tabla.rep_totales(i)), ...
            'HorizontalAlignment','center', ...
            'FontSize',8);
    end

    saveas(fig, fullfile(carpeta_salida, 'Multitaper_LED1_barras_candidatos.png'));
    savefig(fig, fullfile(carpeta_salida, 'Multitaper_LED1_barras_candidatos.fig'));

end

%% 18. Guardar variables principales

save(fullfile(carpeta_salida, 'datos_multitaper_LED1_modificado.mat'), ...
    'f', ...
    'P_ON', ...
    'P_OFF', ...
    'P_ON_prom', ...
    'P_OFF_prom', ...
    'score_prom', ...
    'score_rep', ...
    'tabla', ...
    'info_archivos', ...
    'fc_principal', ...
    'fmin', ...
    'fmax', ...
    'nrep', ...
    'ventana_local_Hz', ...
    'umbralScoreRep_dB', ...
    'NW', ...
    'NFFT');

fprintf('\n============================================\n');
fprintf('Multitaper LED 1 modificado terminado.\n');
fprintf('Resultados guardados en:\n%s\n', carpeta_salida);
fprintf('============================================\n');

%% ============================================================
% Funcion local: leer CSV Rigol

function [t, y_raw, y_sinDC] = leer_csv_rigol_led1(nombre_archivo)

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
    y_raw = M(:,2);

    t = t(:);
    y_raw = y_raw(:);

    [t, idx] = unique(t, 'stable');
    y_raw = y_raw(idx);

    y_sinDC = y_raw - mean(y_raw, 'omitnan');
end

%% ============================================================
% Funcion local: crear fila de informacion de archivo

function fila = crear_fila_info(archivo, condicion, repeticion, muestras, Fs_Hz, duracion_s, media_raw_V, std_raw_V)

    fila = table( ...
        archivo, ...
        condicion, ...
        repeticion, ...
        muestras, ...
        Fs_Hz, ...
        Fs_Hz/1e6, ...
        duracion_s, ...
        media_raw_V, ...
        std_raw_V, ...
        'VariableNames', { ...
        'Archivo', ...
        'Condicion', ...
        'Repeticion', ...
        'Muestras', ...
        'Fs_Hz', ...
        'Fs_MHz', ...
        'Duracion_s', ...
        'Media_raw_V', ...
        'Std_raw_V'} );
end