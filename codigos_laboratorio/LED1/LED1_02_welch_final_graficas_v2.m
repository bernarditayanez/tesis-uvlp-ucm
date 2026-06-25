%% LED1_02_welch_final_graficas_v2.m
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

%% 1. Configuracion del experimento

carpeta_csv = 'C:\Users\mudrood\Desktop\Modulo Prof\Archivos Tesis\Toma de Datos\Pruebas (LED 1)';

carpeta_general = fullfile(carpeta_csv, 'Resultados_LED1_modificados');
carpeta_salida = fullfile(carpeta_general, '02_Welch');

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

nrep = 4;

fmin = 30e3;   
fmax = 90e3;   

num_candidatos = 7;
distancia_minima_Hz = 300;
ventana_local_Hz = 200;

umbralScore_dB = 3;

freqs_revision = [56.286e3, 56.400e3, 57.144e3, 57.704e3];

%% 2. Lectura de datos y calculo de Welch

P_ON = [];
P_OFF = [];
info_archivos = table();

fprintf('\n============================================\n');
fprintf('WELCH LED 1 - GRAFICAS V2\n');
fprintf('============================================\n');
fprintf('Carpeta entrada:\n%s\n', carpeta_csv);
fprintf('\nCarpeta salida:\n%s\n', carpeta_salida);

for k = 1:nrep

    archivo_on = fullfile(carpeta_csv, archivos_ON{k});
    archivo_off = fullfile(carpeta_csv, archivos_OFF{k});

    [t_on, y_on] = leer_csv_rigol_simple_local(archivo_on);
    [t_off, y_off] = leer_csv_rigol_simple_local(archivo_off);

    N_on = numel(y_on);
    N_off = numel(y_off);

    N = min(N_on, N_off);

    y_on  = y_on(1:N);
    y_off = y_off(1:N);
    t_on  = t_on(1:N);
    t_off = t_off(1:N);

    T_on = t_on(end) - t_on(1);
    T_off = t_off(end) - t_off(1);

    if T_on <= 0 || T_off <= 0
        error('El vector de tiempo no tiene una duracion valida en la repeticion %d.', k);
    end

    %% Frecuencia de muestreo

    dt_on = diff(t_on);
    dt_off = diff(t_off);

    dt_on_pos = dt_on(dt_on > 0);
    dt_off_pos = dt_off(dt_off > 0);

    if isempty(dt_on_pos) || isempty(dt_off_pos)
        error('No se encontraron diferencias de tiempo positivas en la repeticion %d.', k);
    end

    Fs_median_on = 1 / median(dt_on_pos);
    Fs_median_off = 1 / median(dt_off_pos);

    Fs_mean_on = 1 / mean(dt_on_pos);
    Fs_mean_off = 1 / mean(dt_off_pos);

    Fs = mean([Fs_median_on, Fs_median_off]);

    Fs_on_duracion  = (N - 1) / T_on;
    Fs_off_duracion = (N - 1) / T_off;

    %% Parametros Welch

    Nseg = N;
    num_segmentos_welch = 1;

    ventana_w = hann(Nseg);
    noverlap = 0;
    nfft = N;

    fprintf('\n--------------------------------------------\n');
    fprintf('Repeticion %d/%d\n', k, nrep);
    fprintf('ON : %s\n', archivos_ON{k});
    fprintf('OFF: %s\n', archivos_OFF{k});
    fprintf('N ON  = %d muestras\n', N_on);
    fprintf('N OFF = %d muestras\n', N_off);
    fprintf('N usado = %d muestras\n', N);
    fprintf('Fs usada = %.6f MSa/s\n', Fs/1e6);
    fprintf('Fs ON por duracion  = %.6f MSa/s\n', Fs_on_duracion/1e6);
    fprintf('Fs OFF por duracion = %.6f MSa/s\n', Fs_off_duracion/1e6);
    fprintf('Fs ON median dt positivo  = %.6f MSa/s\n', Fs_median_on/1e6);
    fprintf('Fs OFF median dt positivo = %.6f MSa/s\n', Fs_median_off/1e6);
    fprintf('T ON  = %.9f s\n', T_on);
    fprintf('T OFF = %.9f s\n', T_off);
    fprintf('Nseg = %d muestras\n', Nseg);
    fprintf('noverlap = %d muestras\n', noverlap);
    fprintf('nfft = %d\n', nfft);
    fprintf('df grilla aproximada = %.6f Hz\n', Fs/nfft);

    info_archivos = [info_archivos; crear_fila_info( ...
        string(archivos_ON{k}), "ON", k, N_on, Fs_mean_on, Fs_median_on, T_on)];

    info_archivos = [info_archivos; crear_fila_info( ...
        string(archivos_OFF{k}), "OFF", k, N_off, Fs_mean_off, Fs_median_off, T_off)];

    if N_on ~= N_off
        warning('La repeticion %d tiene distinto numero de muestras ON/OFF.', k);
    end

    %% Calculo Welch

    [Pxx_on, f] = pwelch(y_on, ventana_w, noverlap, nfft, Fs);
    [Pxx_off, f_off] = pwelch(y_off, ventana_w, noverlap, nfft, Fs);

    f = f(:);
    f_off = f_off(:);

    if numel(f) ~= numel(f_off) || max(abs(f - f_off)) > 1e-9
        error('La grilla de frecuencia ON/OFF no coincide en la repeticion %d.', k);
    end

    if any(~isfinite(f)) || max(f) < fmax
        fprintf('\nERROR EN GRILLA WELCH REP %d\n', k);
        fprintf('Fs = %.6g Hz\n', Fs);
        fprintf('N = %d\n', N);
        fprintf('Nseg = %d\n', Nseg);
        fprintf('nfft = %d\n', nfft);
        fprintf('min(f) = %.6g Hz\n', min(f));
        fprintf('max(f) = %.6g Hz\n', max(f));
        error('La grilla de frecuencia Welch no cubre la banda de analisis.');
    end

    P_ON(:,k) = 10*log10(Pxx_on + eps);
    P_OFF(:,k) = 10*log10(Pxx_off + eps);

    fprintf('Rango f = %.3f Hz a %.3f Hz\n', min(f), max(f));
    fprintf('Cantidad de puntos entre 30 y 90 kHz = %d\n', ...
        sum(f >= 30e3 & f <= 90e3));
end

%% 3. Promedios entre repeticiones

P_ON_prom = mean(P_ON, 2);
P_OFF_prom = mean(P_OFF, 2);

score_prom = P_ON_prom - P_OFF_prom;
score_rep = P_ON - P_OFF;

f = f(:);
P_ON_prom = P_ON_prom(:);
P_OFF_prom = P_OFF_prom(:);
score_prom = score_prom(:);

%% 4. Preparar banda de analisis

idx_rango = (f >= fmin) & (f <= fmax);

if ~any(idx_rango)
    fprintf('\nERROR: no hay puntos dentro del rango de analisis.\n');
    fprintf('Rango solicitado: %.1f Hz a %.1f Hz\n', fmin, fmax);
    fprintf('Rango disponible en f: %.1f Hz a %.1f Hz\n', min(f), max(f));
    error('La mascara de frecuencia quedo vacia. Revisar unidades.');
end

f_rango = f(idx_rango);
score_rango = score_prom(idx_rango);
P_ON_rango = P_ON_prom(idx_rango);
P_OFF_rango = P_OFF_prom(idx_rango);

idx_validos = isfinite(f_rango) & isfinite(score_rango) & ...
              isfinite(P_ON_rango) & isfinite(P_OFF_rango);

f_rango = f_rango(idx_validos);
score_rango = score_rango(idx_validos);
P_ON_rango = P_ON_rango(idx_validos);
P_OFF_rango = P_OFF_rango(idx_validos);

if isempty(score_rango)
    error('score_rango quedo vacio despues de eliminar NaN/Inf.');
end

%% 5. Diagnostico de maximo global y frecuencias clave

[score_max_global, idx_max_global] = max(score_rango);
f_max_global = f_rango(idx_max_global);

fprintf('\n=== MAXIMO GLOBAL WELCH EN %.1f-%.1f kHz ===\n', fmin/1e3, fmax/1e3);
fprintf('f_max_global = %.3f Hz = %.4f kHz\n', f_max_global, f_max_global/1e3);
fprintf('score_max_global = %.4f dB\n', score_max_global);

fprintf('\n=== REVISION DE FRECUENCIAS CLAVE WELCH ===\n');

for i = 1:numel(freqs_revision)

    [~, idx_tmp] = min(abs(f - freqs_revision(i)));

    fprintf(['f objetivo = %.3f kHz | f grilla = %.3f kHz | ', ...
             'score = %.4f dB | ON = %.4f dB | OFF = %.4f dB\n'], ...
        freqs_revision(i)/1e3, ...
        f(idx_tmp)/1e3, ...
        score_prom(idx_tmp), ...
        P_ON_prom(idx_tmp), ...
        P_OFF_prom(idx_tmp));
end

%% 6. Busqueda de candidatos globales

[pks, locs] = findpeaks(score_rango, f_rango, ...
    'MinPeakDistance', distancia_minima_Hz);

idx_pos = pks > 0;

pks = pks(idx_pos);
locs = locs(idx_pos);

if isempty(pks)

    warning('No se encontraron picos positivos. Se usara el maximo global del score.');

    pks = score_max_global;
    locs = f_max_global;
end

fc_candidatas = locs(:);
score_peak_dB = pks(:);

%% 7. Ordenar y limitar candidatos

[score_peak_dB, idx_orden] = sort(score_peak_dB, 'descend');
fc_candidatas = fc_candidatas(idx_orden);

num_cand_usados = min(num_candidatos, numel(score_peak_dB));

score_peak_dB = score_peak_dB(1:num_cand_usados);
fc_candidatas = fc_candidatas(1:num_cand_usados);

n_cand = numel(fc_candidatas);

%% 8. Analisis local de candidatos

if n_cand == 0

    warning('No fue posible definir candidatos en Welch.');
    tabla = table();
    fc_principal = NaN;

else

    score_local_dB = zeros(n_cand,1);
    f_local_Hz = zeros(n_cand,1);
    ON_dB = zeros(n_cand,1);
    OFF_dB = zeros(n_cand,1);
    rep_positivas = zeros(n_cand,1);

    for i = 1:n_cand

        fc = fc_candidatas(i);

        idx_local = f >= fc - ventana_local_Hz & f <= fc + ventana_local_Hz;

        f_local = f(idx_local);
        score_local = score_prom(idx_local);

        if isempty(score_local)

            score_local_dB(i) = NaN;
            f_local_Hz(i) = NaN;
            ON_dB(i) = NaN;
            OFF_dB(i) = NaN;
            rep_positivas(i) = 0;
            continue;
        end

        [score_local_dB(i), idx_max] = max(score_local);
        f_local_Hz(i) = f_local(idx_max);

        ON_dB(i) = interp1(f, P_ON_prom, fc, 'linear');
        OFF_dB(i) = interp1(f, P_OFF_prom, fc, 'linear');

        cuenta = 0;

        for r = 1:nrep
            if max(score_rep(idx_local,r)) > 0
                cuenta = cuenta + 1;
            end
        end

        rep_positivas(i) = cuenta;
    end

    supera_3dB = score_local_dB >= umbralScore_dB;

    tabla = table( ...
        fc_candidatas, ...
        fc_candidatas/1e3, ...
        score_peak_dB, ...
        f_local_Hz, ...
        f_local_Hz/1e3, ...
        score_local_dB, ...
        ON_dB, ...
        OFF_dB, ...
        rep_positivas, ...
        repmat(nrep,n_cand,1), ...
        supera_3dB, ...
        'VariableNames', { ...
        'fc_Hz', ...
        'fc_kHz', ...
        'score_peak_dB', ...
        'f_local_Hz', ...
        'f_local_kHz', ...
        'score_local_dB', ...
        'ON_dB', ...
        'OFF_dB', ...
        'rep_positivas', ...
        'rep_totales', ...
        'supera_3dB'});

    tabla = sortrows(tabla, 'score_local_dB', 'descend');

    %% 9. Seleccion de frecuencia principal Welch global

    idx_validos_principal = tabla.score_local_dB >= umbralScore_dB & ...
                            tabla.rep_positivas == tabla.rep_totales;

    if any(idx_validos_principal)

        tabla_validos = tabla(idx_validos_principal, :);
        [~, idx_best] = max(tabla_validos.score_local_dB);

        fc_principal = tabla_validos.f_local_Hz(idx_best);

        fprintf('\n=== SELECCION WELCH GLOBAL POR CRITERIO EXPERIMENTAL ===\n');
        fprintf('Criterio: score >= %.1f dB y repetibilidad completa.\n', umbralScore_dB);
        fprintf('fc_principal Welch = %.3f Hz = %.4f kHz\n', ...
            fc_principal, fc_principal/1e3);

    else

        warning('No hay candidatos que cumplan score >= %.1f dB y repetibilidad completa. Se usara el mayor score disponible.', ...
            umbralScore_dB);

        fc_principal = tabla.f_local_Hz(1);

        fprintf('\n=== SELECCION WELCH GLOBAL POR MAXIMO DISPONIBLE ===\n');
        fprintf('fc_principal Welch = %.3f Hz = %.4f kHz\n', ...
            fc_principal, fc_principal/1e3);
    end
end

%% 10. Mostrar tabla en consola

fprintf('\n============================================\n');
fprintf('TABLA DE CANDIDATOS WELCH LED 1\n');
fprintf('============================================\n');
disp(tabla);

if ~isnan(fc_principal)
    fprintf('\nFrecuencia principal Welch LED1 = %.3f Hz = %.3f kHz\n', ...
        fc_principal, fc_principal/1e3);
else
    fprintf('\nNo se definio frecuencia principal.\n');
end

%% 11. Guardar tablas

writetable(tabla, fullfile(carpeta_salida, 'tabla_welch_LED1_graficas_v2.csv'));
writetable(info_archivos, fullfile(carpeta_salida, 'info_archivos_welch_LED1_graficas_v2.csv'));

%% Guardar tabla de candidatos como figura

if ~isempty(tabla)

    tabla_fig = tabla;

    if ismember('fc_Hz', tabla_fig.Properties.VariableNames)
        tabla_fig.fc_Hz = [];
    end

    if ismember('f_local_Hz', tabla_fig.Properties.VariableNames)
        tabla_fig.f_local_Hz = [];
    end

    tabla_fig.Properties.VariableNames = { ...
        'fc_kHz', ...
        'score_peak', ...
        'f_local_kHz', ...
        'score_local', ...
        'ON_dB', ...
        'OFF_dB', ...
        'rep_positivas', ...
        'rep_totales', ...
        'supera_3dB'};

    guardar_tabla_como_figura( ...
        tabla_fig, ...
        'TABLA DE CANDIDATOS WELCH LED 1', ...
        fullfile(carpeta_salida, 'tabla_welch_LED1_graficas_v2.png'), ...
        fullfile(carpeta_salida, 'tabla_welch_LED1_graficas_v2.fig'));
end

%% 12. Figura 1: PSD promedio ON/OFF en rango amplio

fmax_amplio = min(5e6, max(f));
idx_amplio = f >= 0 & f <= fmax_amplio;

fig = figure('Color','w','Position',[100 100 1200 700]);

plot(f(idx_amplio)/1e6, P_ON_prom(idx_amplio), 'LineWidth', 1.2); hold on;
plot(f(idx_amplio)/1e6, P_OFF_prom(idx_amplio), 'LineWidth', 1.2);

grid on;
xlabel('Frecuencia [MHz]');
ylabel('PSD Welch [dB/Hz]');
title('LED 1 - Welch: PSD promedio ON/OFF, rango amplio', 'Interpreter','none');
legend('LED encendido','LED apagado','Location','best');
xlim([0 fmax_amplio/1e6]);

saveas(fig, fullfile(carpeta_salida, 'Welch_LED1_ON_OFF_rango_amplio.png'));
savefig(fig, fullfile(carpeta_salida, 'Welch_LED1_ON_OFF_rango_amplio.fig'));

%% 13. Figura 2: PSD promedio ON/OFF en 30-90 kHz

fig = figure('Color','w','Position',[100 100 1200 700]);

plot(f_rango/1e3, P_ON_rango, 'LineWidth', 1.5); hold on;
plot(f_rango/1e3, P_OFF_rango, 'LineWidth', 1.5);

if ~isnan(fc_principal)
    xline(fc_principal/1e3, ':', sprintf('%.3f kHz', fc_principal/1e3), ...
        'LineWidth', 1.3, ...
        'LabelOrientation','aligned', ...
        'HandleVisibility','off');
end

grid on;
xlabel('Frecuencia [kHz]');
ylabel('PSD Welch [dB/Hz]');
title('LED 1 - Welch: PSD promedio ON/OFF en banda de análisis', 'Interpreter','none');
legend('LED encendido','LED apagado','Location','best');
xlim([fmin fmax]/1e3);

saveas(fig, fullfile(carpeta_salida, 'Welch_LED1_ON_OFF_30_90kHz.png'));
savefig(fig, fullfile(carpeta_salida, 'Welch_LED1_ON_OFF_30_90kHz.fig'));

%% 14. Figura 3: score ON-OFF en 30-90 kHz

fig = figure('Color','w','Position',[100 100 1200 700]);

plot(f_rango/1e3, score_rango, 'LineWidth', 1.5); hold on;

yline(0, '--', '0 dB', 'HandleVisibility','off');
yline(umbralScore_dB, '--', sprintf('Criterio %.1f dB', umbralScore_dB), ...
    'HandleVisibility','off');

if ~isnan(fc_principal)
    xline(fc_principal/1e3, ':', sprintf('%.3f kHz', fc_principal/1e3), ...
        'LineWidth', 1.3, ...
        'LabelOrientation','aligned', ...
        'HandleVisibility','off');
end

grid on;
xlabel('Frecuencia [kHz]');
ylabel('Score ON - OFF [dB]');
title('LED 1 - Welch: score ON-OFF en banda de análisis', 'Interpreter','none');
xlim([fmin fmax]/1e3);

saveas(fig, fullfile(carpeta_salida, 'Welch_LED1_score_ON_OFF_30_90kHz.png'));
savefig(fig, fullfile(carpeta_salida, 'Welch_LED1_score_ON_OFF_30_90kHz.fig'));

%% 15. Figura 4: repeticiones ON en 30-90 kHz

P_ON_rango_rep = P_ON(idx_rango,:);
P_ON_rango_rep = P_ON_rango_rep(idx_validos,:);

fig = figure('Color','w','Position',[100 100 1200 700]);

plot(f_rango/1e3, P_ON_rango_rep, 'LineWidth', 1.0);

grid on;
xlabel('Frecuencia [kHz]');
ylabel('PSD Welch [dB/Hz]');
title('LED 1 - Welch: repeticiones ON en banda de análisis', 'Interpreter','none');
legend(compose('ON rep %d', 1:nrep), 'Location','best');
xlim([fmin fmax]/1e3);

saveas(fig, fullfile(carpeta_salida, 'Welch_LED1_repeticiones_ON_30_90kHz.png'));
savefig(fig, fullfile(carpeta_salida, 'Welch_LED1_repeticiones_ON_30_90kHz.fig'));

%% 16. Figura 5: repeticiones OFF en 30-90 kHz

P_OFF_rango_rep = P_OFF(idx_rango,:);
P_OFF_rango_rep = P_OFF_rango_rep(idx_validos,:);

fig = figure('Color','w','Position',[100 100 1200 700]);

plot(f_rango/1e3, P_OFF_rango_rep, 'LineWidth', 1.0);

grid on;
xlabel('Frecuencia [kHz]');
ylabel('PSD Welch [dB/Hz]');
title('LED 1 - Welch: repeticiones OFF en banda de análisis', 'Interpreter','none');
legend(compose('OFF rep %d', 1:nrep), 'Location','best');
xlim([fmin fmax]/1e3);

saveas(fig, fullfile(carpeta_salida, 'Welch_LED1_repeticiones_OFF_30_90kHz.png'));
savefig(fig, fullfile(carpeta_salida, 'Welch_LED1_repeticiones_OFF_30_90kHz.fig'));

%% 17. Figura 6: barras de candidatos principales

if ~isempty(tabla)

    fig = figure('Color','w','Position',[100 100 1200 700]);

    x = 1:height(tabla);

    bar(x, tabla.score_local_dB, 0.65); 
    hold on;
    grid on;
    box on;

    yline(umbralScore_dB, '--', sprintf('Criterio %.1f dB', umbralScore_dB), ...
        'LineWidth', 1.1, ...
        'LabelHorizontalAlignment','right', ...
        'HandleVisibility','off');

    [~, idx_best] = min(abs(tabla.f_local_Hz - fc_principal));

    plot(idx_best, tabla.score_local_dB(idx_best) + 0.9, ...
        'kp', ...
        'MarkerSize', 16, ...
        'LineWidth', 2, ...
        'DisplayName','Candidato principal');

    xlabel('Frecuencia candidata [kHz]');
    ylabel('Score local ON-OFF [dB]');
    title('LED 1 - Welch: candidatos principales', 'Interpreter','none');

    xticks(x);
    xticklabels(compose('%.3f', tabla.f_local_kHz));
    xtickangle(45);

    for i = 1:height(tabla)

        texto_barra = sprintf('%.2f dB\n%d/%d', ...
            tabla.score_local_dB(i), ...
            tabla.rep_positivas(i), ...
            tabla.rep_totales(i));

        if i == idx_best
            y_texto = tabla.score_local_dB(i) + 1.45;
        else
            y_texto = tabla.score_local_dB(i) + 0.55;
        end

        text(x(i), y_texto, texto_barra, ...
            'HorizontalAlignment','center', ...
            'VerticalAlignment','bottom', ...
            'FontSize',9);
    end

    ylim([0, max(tabla.score_local_dB) + 3.2]);

    legend({'Score local ON-OFF','Candidato principal'}, 'Location','best');

    saveas(fig, fullfile(carpeta_salida, 'Welch_LED1_barras_candidatos.png'));
    savefig(fig, fullfile(carpeta_salida, 'Welch_LED1_barras_candidatos.fig'));
end

%% 18. Guardar variables

save(fullfile(carpeta_salida, 'datos_welch_LED1_graficas_v2.mat'), ...
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
    'num_candidatos', ...
    'distancia_minima_Hz', ...
    'umbralScore_dB', ...
    'num_segmentos_welch', ...
    'Nseg', ...
    'noverlap', ...
    'nfft');

fprintf('\n============================================\n');
fprintf('Welch LED1 graficas V2 terminado.\n');
fprintf('Resultados guardados en:\n%s\n', carpeta_salida);
fprintf('============================================\n');

%% ============================================================
% FUNCIONES LOCALES

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

    if any(diff(t) < 0)
        [t, idx] = sort(t, 'ascend');
        y = y(idx);
    end

    y = y - mean(y, 'omitnan');
end

function fila = crear_fila_info(archivo, condicion, repeticion, muestras, Fs_mean_Hz, Fs_median_Hz, duracion_s)

    if isnan(Fs_median_Hz) || Fs_median_Hz == 0
        diferencia_mean_median_pct = NaN;
    else
        diferencia_mean_median_pct = abs(Fs_mean_Hz - Fs_median_Hz) / Fs_median_Hz * 100;
    end

    fila = table( ...
        archivo, ...
        condicion, ...
        repeticion, ...
        muestras, ...
        Fs_mean_Hz, ...
        Fs_median_Hz, ...
        diferencia_mean_median_pct, ...
        duracion_s, ...
        'VariableNames', { ...
        'Archivo', ...
        'Condicion', ...
        'Repeticion', ...
        'Muestras', ...
        'Fs_mean_Hz', ...
        'Fs_median_Hz', ...
        'Diferencia_mean_median_pct', ...
        'Duracion_s'} );
end

function guardar_tabla_como_figura(tabla, titulo_tabla, archivo_png, archivo_fig)

    if isempty(tabla)
        warning('La tabla esta vacia. No se guardara figura de tabla.');
        return;
    end

    data_cell = formatear_tabla_para_figura(tabla);

    nombres = tabla.Properties.VariableNames;
    nfilas = height(tabla);
    ncols = width(tabla);

    ancho_col = zeros(1, ncols);

    for c = 1:ncols

        textos_columna = data_cell(:,c);
        largo_max_datos = 0;

        for i = 1:nfilas
            largo_max_datos = max(largo_max_datos, length(textos_columna{i}));
        end

        largo_max = max(length(nombres{c}), largo_max_datos);

        ancho_col(c) = 8*largo_max + 24;
        ancho_col(c) = max(75, min(150, ancho_col(c)));
    end

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

    text(ax, ancho_fig/2, alto_fig - 28, titulo_tabla, ...
        'HorizontalAlignment','center', ...
        'VerticalAlignment','middle', ...
        'FontWeight','bold', ...
        'FontSize',15, ...
        'Interpreter','none');

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

    drawnow;

    print(fig, archivo_png, '-dpng', '-r300');
    savefig(fig, archivo_fig);
end

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