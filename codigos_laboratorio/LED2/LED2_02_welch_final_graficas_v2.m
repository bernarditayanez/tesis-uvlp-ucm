%% LED2_02_welch_final_graficas_v2.m
%
% INSTRUCCIONES DE USO
% Antes de ejecutar este script, revisar la variable ruta
% y modificarla si los archivos .csv se encuentran en otra ruta local.
% La carpeta indicada debe contener los archivos ON_LED2_rep*.csv
% y OFF_LED2_rep*.csv definidos en las listas archivos_ON
% y archivos_OFF.
%
% Ejemplo:
% ruta = 'C:\Users\NombreUsuario\Desktop\Pruebas LED 2';

clear; 
clc; 
close all;

%% 1. Configuracion del experimento

ruta = 'C:\Users\mudrood\Desktop\Modulo Prof\Archivos Tesis\Toma de Datos\Pruebas LED 2';

archivos_ON = {
    fullfile(ruta, 'ON_LED2_rep1.csv')
    fullfile(ruta, 'ON_LED2_rep2.csv')
    fullfile(ruta, 'ON_LED2_rep3.csv')
    fullfile(ruta, 'ON_LED2_rep4.csv')
};

archivos_OFF = {
    fullfile(ruta, 'OFF_LED2_rep1.csv')
    fullfile(ruta, 'OFF_LED2_rep2.csv')
    fullfile(ruta, 'OFF_LED2_rep3.csv')
    fullfile(ruta, 'OFF_LED2_rep4.csv')
};

nombreLED = 'LED 2';

fc_ref_consenso = 45.375e3;      
tol_consenso_Hz = 1e3;           

fmin_local = fc_ref_consenso - tol_consenso_Hz;
fmax_local = fc_ref_consenso + tol_consenso_Hz;

fmin_banda = 30e3;
fmax_banda = 90e3;

Fs_fallback = 50e6;            

Nmax = Inf;

nfft = 10e6;
Nseg = 1250000;

umbral_0dB = 0;
umbral_3dB = 3;
max_candidatos = 7;

min_dist_Hz = 100;
min_prom_dB = 0.05;

%% 2. Verificacion de archivos

for k = 1:numel(archivos_ON)
    if ~isfile(archivos_ON{k})
        error('No se encontro archivo ON: %s', archivos_ON{k});
    end
    if ~isfile(archivos_OFF{k})
        error('No se encontro archivo OFF: %s', archivos_OFF{k});
    end
end

num_reps = numel(archivos_ON);

%% 3. Lectura y calculo de Welch por repeticion

P_ON_dB_reps = [];
P_OFF_dB_reps = [];
score_reps = [];
f = [];

Fs_reps = zeros(num_reps,1);
N_usado_reps = zeros(num_reps,1);

for r = 1:num_reps

    fprintf('\n--------------------------------------------\n');
    fprintf('Repeticion %d/%d\n', r, num_reps);
    fprintf('ON : %s\n', archivos_ON{r});
    fprintf('OFF: %s\n', archivos_OFF{r});

    [t_on, y_on, Fs_on] = leer_csv_rigol_simple_local(archivos_ON{r}, Fs_fallback);
    [t_off, y_off, Fs_off] = leer_csv_rigol_simple_local(archivos_OFF{r}, Fs_fallback);

    y_on = y_on(:);
    y_off = y_off(:);

    N = min(length(y_on), length(y_off));
    if isfinite(Nmax)
        N = min(N, Nmax);
    end

    y_on = y_on(1:N);
    y_off = y_off(1:N);

    y_on = y_on - mean(y_on, 'omitnan');
    y_off = y_off - mean(y_off, 'omitnan');

    if isfinite(Fs_on) && isfinite(Fs_off) && Fs_on > 0 && Fs_off > 0
        Fs = mean([Fs_on, Fs_off]);
    elseif isfinite(Fs_on) && Fs_on > 0
        Fs = Fs_on;
    elseif isfinite(Fs_off) && Fs_off > 0
        Fs = Fs_off;
    else
        Fs = Fs_fallback;
    end

    Fs_reps(r) = Fs;
    N_usado_reps(r) = N;

    fprintf('N usado = %d muestras\n', N);
    fprintf('Fs usada = %.6f MSa/s\n', Fs/1e6);

    Nseg_r = min(Nseg, floor(N/2));
    if Nseg_r < 1024
        error('Muy pocas muestras para Welch en repeticion %d.', r);
    end

    ventana_r = hamming(Nseg_r, 'periodic');
    noverlap_r = round(Nseg_r/2);

    [Pxx_on, f_tmp] = pwelch(y_on, ventana_r, noverlap_r, nfft, Fs);
    [Pxx_off, f_off_tmp] = pwelch(y_off, ventana_r, noverlap_r, nfft, Fs);

    if isempty(f)
        f = f_tmp;
    else
        if length(f_tmp) ~= length(f) || max(abs(f_tmp - f)) > 1e-6
            error('La grilla de frecuencia cambio entre repeticiones.');
        end
    end

    P_ON_dB = 10*log10(Pxx_on + eps);
    P_OFF_dB = 10*log10(Pxx_off + eps);
    score_dB = P_ON_dB - P_OFF_dB;

    P_ON_dB_reps(:,r) = P_ON_dB;
    P_OFF_dB_reps(:,r) = P_OFF_dB;
    score_reps(:,r) = score_dB;

    fprintf('=== VERIFICACION FRECUENCIAS WELCH REP %d ===\n', r);
    fprintf('Fs = %.6f Hz\n', Fs);
    fprintf('Nseg = %d muestras\n', Nseg_r);
    fprintf('noverlap = %d muestras\n', noverlap_r);
    fprintf('nfft = %d\n', nfft);
    fprintf('f min = %.3f Hz\n', min(f_tmp));
    fprintf('f max = %.3f Hz\n', max(f_tmp));
    fprintf('df = %.6f Hz\n', f_tmp(2)-f_tmp(1));
    fprintf('Puntos 30-90 kHz = %d\n', sum(f_tmp >= fmin_banda & f_tmp <= fmax_banda));
    fprintf('Puntos ventana local %.3f-%.3f kHz = %d\n', ...
        fmin_local/1e3, fmax_local/1e3, ...
        sum(f_tmp >= fmin_local & f_tmp <= fmax_local));
end

%% 4. Promedios entre repeticiones

P_ON_prom_dB = mean(P_ON_dB_reps, 2, 'omitnan');
P_OFF_prom_dB = mean(P_OFF_dB_reps, 2, 'omitnan');
score_prom_dB = P_ON_prom_dB - P_OFF_prom_dB;

%% Mascaras de frecuencia 

idx_banda = f >= fmin_banda & f <= fmax_banda;
idx_local = f >= fmin_local & f <= fmax_local;

if ~any(idx_banda)
    error('No hay puntos dentro de 30-90 kHz. Revisar Fs, nfft o unidades.');
end

if ~any(idx_local)
    error('No hay puntos dentro de %.3f-%.3f kHz. Revisar Fs, nfft o unidades.', ...
        fmin_local/1e3, fmax_local/1e3);
end

f_banda = f(idx_banda);
P_ON_banda = P_ON_prom_dB(idx_banda);
P_OFF_banda = P_OFF_prom_dB(idx_banda);
score_banda = score_prom_dB(idx_banda);

f_local = f(idx_local);
P_ON_local = P_ON_prom_dB(idx_local);
P_OFF_local = P_OFF_prom_dB(idx_local);
score_local = score_prom_dB(idx_local);

%% Busqueda de candidatos locales

df = f(2) - f(1);
min_dist_pts = max(1, round(min_dist_Hz / df));

[pks, locs] = findpeaks(score_local, ...
    'MinPeakDistance', min_dist_pts, ...
    'MinPeakProminence', min_prom_dB);

if isempty(pks)
    warning('No se encontraron picos locales con findpeaks. Se usara maximo directo en ventana local.');
    [pks, locs] = max(score_local);
end

f_cand = f_local(locs);
score_cand = pks;

[score_cand, orden] = sort(score_cand, 'descend');
f_cand = f_cand(orden);

nCand = min(max_candidatos, numel(f_cand));
f_cand = f_cand(1:nCand);
score_cand = score_cand(1:nCand);

fc_Hz = zeros(nCand,1);
fc_kHz = zeros(nCand,1);
score_peak_dB = zeros(nCand,1);
f_local_Hz = zeros(nCand,1);
f_local_kHz = zeros(nCand,1);
score_local_dB = zeros(nCand,1);
ON_dB = zeros(nCand,1);
OFF_dB = zeros(nCand,1);
rep_positivas_0dB = zeros(nCand,1);
rep_positivas_3dB = zeros(nCand,1);
rep_totales = num_reps * ones(nCand,1);
supera_3dB = cell(nCand,1);

for c = 1:nCand

    fc_Hz(c) = f_cand(c);
    fc_kHz(c) = fc_Hz(c)/1e3;
    score_peak_dB(c) = score_cand(c);

    [~, idx_global] = min(abs(f - fc_Hz(c)));

    f_local_Hz(c) = f(idx_global);
    f_local_kHz(c) = f(idx_global)/1e3;
    score_local_dB(c) = score_prom_dB(idx_global);
    ON_dB(c) = P_ON_prom_dB(idx_global);
    OFF_dB(c) = P_OFF_prom_dB(idx_global);

    scores_rep_c = score_reps(idx_global, :);

    rep_positivas_0dB(c) = sum(scores_rep_c >= umbral_0dB);
    rep_positivas_3dB(c) = sum(scores_rep_c >= umbral_3dB);

    if score_local_dB(c) >= umbral_3dB
        supera_3dB{c} = 'Si';
    else
        supera_3dB{c} = 'No';
    end
end

tabla_candidatos = table( ...
    fc_Hz, ...
    fc_kHz, ...
    score_peak_dB, ...
    f_local_Hz, ...
    f_local_kHz, ...
    score_local_dB, ...
    ON_dB, ...
    OFF_dB, ...
    rep_positivas_0dB, ...
    rep_positivas_3dB, ...
    rep_totales, ...
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
    'rep_positivas_0dB', ...
    'rep_positivas_3dB', ...
    'rep_totales', ...
    'supera_3dB'});

%% Candidato principal

idx_principal = 1;

fc_principal_Hz = tabla_candidatos.fc_Hz(idx_principal);
fc_principal_kHz = tabla_candidatos.fc_kHz(idx_principal);
score_principal_dB = tabla_candidatos.score_local_dB(idx_principal);
rep0_principal = tabla_candidatos.rep_positivas_0dB(idx_principal);
rep3_principal = tabla_candidatos.rep_positivas_3dB(idx_principal);

fprintf('\n================================================\n');
fprintf('TABLA DE CANDIDATOS WELCH LED 2 - VENTANA LOCAL\n');
fprintf('================================================\n');
disp(tabla_candidatos);

fprintf('\nCandidato principal Welch LED 2:\n');
fprintf('Fc = %.3f kHz\n', fc_principal_kHz);
fprintf('Score = %.3f dB\n', score_principal_dB);
fprintf('Repeticiones >= 0 dB = %d/%d\n', rep0_principal, num_reps);
fprintf('Repeticiones >= 3 dB = %d/%d\n', rep3_principal, num_reps);
fprintf('Ventana local usada: %.3f kHz a %.3f kHz\n', fmin_local/1e3, fmax_local/1e3);

if score_principal_dB < umbral_3dB
    fprintf('\nNota: Welch NO supera 3 dB en la ventana local.\n');
    fprintf('Se debe reportar como evidencia complementaria y no como Fc principal.\n');
end

%% Graficas de resultados

carpeta_salida = fullfile(ruta, 'Resultados_LED2_modificados', '02_Welch');

if ~exist(carpeta_salida, 'dir')
    mkdir(carpeta_salida);
end

fmin = fmin_banda;
fmax = fmax_banda;
nrep = num_reps;

f_rango = f_banda;
P_ON_rango = P_ON_banda;
P_OFF_rango = P_OFF_banda;
score_rango = score_banda;

tabla = tabla_candidatos;
fc_principal = fc_principal_Hz;
umbralScore_dB = umbral_3dB;

%% 1. Figura: PSD promedio ON/OFF en rango amplio

fmax_amplio = min(5e6, max(f));
idx_amplio = f >= 0 & f <= fmax_amplio;

fig = figure('Color','w','Position',[100 100 1200 700]);

plot(f(idx_amplio)/1e6, P_ON_prom_dB(idx_amplio), 'LineWidth', 1.2); hold on;
plot(f(idx_amplio)/1e6, P_OFF_prom_dB(idx_amplio), 'LineWidth', 1.2);

grid on;
xlabel('Frecuencia [MHz]');
ylabel('PSD Welch [dB/Hz]');
title('LED 2 - Welch: PSD promedio ON/OFF, rango amplio', 'Interpreter','none');
legend('LED encendido','LED apagado','Location','best');
xlim([0 fmax_amplio/1e6]);

saveas(fig, fullfile(carpeta_salida, 'Welch_LED2_ON_OFF_rango_amplio.png'));
savefig(fig, fullfile(carpeta_salida, 'Welch_LED2_ON_OFF_rango_amplio.fig'));

%% 2. Figura: PSD promedio ON/OFF en 30-90 kHz

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
ylabel('PSD Welch [dB/Hz]');
title('LED 2 - Welch: PSD promedio ON/OFF en banda de análisis', 'Interpreter','none');
legend('LED encendido','LED apagado','Location','best');
xlim([fmin fmax]/1e3);

saveas(fig, fullfile(carpeta_salida, 'Welch_LED2_ON_OFF_30_90kHz.png'));
savefig(fig, fullfile(carpeta_salida, 'Welch_LED2_ON_OFF_30_90kHz.fig'));

%% 3. Figura: score ON-OFF en 30-90 kHz

fig = figure('Color','w','Position',[100 100 1200 700]);

plot(f_rango/1e3, score_rango, 'LineWidth', 1.5); hold on;

yline(0, '--', '0 dB', ...
    'Color', [0.25 0.25 0.25], ...
    'LineWidth', 1.1, ...
    'HandleVisibility','off', ...
    'LabelHorizontalAlignment','right', ...
    'LabelVerticalAlignment','bottom');

yline(umbralScore_dB, '--', sprintf('Criterio %.1f dB', umbralScore_dB), ...
    'Color', [0.35 0.35 0.35], ...
    'LineWidth', 1.2, ...
    'HandleVisibility','off', ...
    'LabelHorizontalAlignment','right', ...
    'LabelVerticalAlignment','bottom');

if ~isnan(fc_principal)
    xline(fc_principal/1e3, ':', sprintf('%.3f kHz', fc_principal/1e3), ...
        'LineWidth', 1.3, ...
        'HandleVisibility','off');
end

grid on;
xlabel('Frecuencia [kHz]');
ylabel('Score ON - OFF [dB]');
title('LED 2 - Welch: score ON-OFF en banda de análisis', 'Interpreter','none');
xlim([fmin fmax]/1e3);

ymin_fig = min([score_rango(:); -0.2]);
ymax_fig = max([score_rango(:); umbralScore_dB]) + 0.25;
ylim([ymin_fig ymax_fig]);

saveas(fig, fullfile(carpeta_salida, 'Welch_LED2_score_ON_OFF_30_90kHz.png'));
savefig(fig, fullfile(carpeta_salida, 'Welch_LED2_score_ON_OFF_30_90kHz.fig'));

%% 4. Figura: repeticiones ON en 30-90 kHz

fig = figure('Color','w','Position',[100 100 1200 700]);

plot(f_rango/1e3, P_ON_dB_reps(idx_banda,:), 'LineWidth', 1.0);

grid on;
xlabel('Frecuencia [kHz]');
ylabel('PSD Welch [dB/Hz]');
title('LED 2 - Welch: repeticiones ON en banda de análisis', 'Interpreter','none');
legend(compose('ON rep %d', 1:nrep), 'Location','best');
xlim([fmin fmax]/1e3);

saveas(fig, fullfile(carpeta_salida, 'Welch_LED2_repeticiones_ON_30_90kHz.png'));
savefig(fig, fullfile(carpeta_salida, 'Welch_LED2_repeticiones_ON_30_90kHz.fig'));

%% 5. Figura: repeticiones OFF en 30-90 kHz

fig = figure('Color','w','Position',[100 100 1200 700]);

plot(f_rango/1e3, P_OFF_dB_reps(idx_banda,:), 'LineWidth', 1.0);

grid on;
xlabel('Frecuencia [kHz]');
ylabel('PSD Welch [dB/Hz]');
title('LED 2 - Welch: repeticiones OFF en banda de análisis', 'Interpreter','none');
legend(compose('OFF rep %d', 1:nrep), 'Location','best');
xlim([fmin fmax]/1e3);

saveas(fig, fullfile(carpeta_salida, 'Welch_LED2_repeticiones_OFF_30_90kHz.png'));
savefig(fig, fullfile(carpeta_salida, 'Welch_LED2_repeticiones_OFF_30_90kHz.fig'));

%% 6. Figura: barras de candidatos principales

if ~isempty(tabla)

    fig = figure('Color','w','Position',[100 100 1350 720]);

    x = 1:height(tabla);

    hBar = bar(x, tabla.score_local_dB, 0.72);
    hold on;
    grid on;
    box on;

    hBar.DisplayName = 'Score local ON-OFF';

    yline(umbralScore_dB, '--', sprintf('Criterio %.1f dB', umbralScore_dB), ...
        'Color', [0.35 0.35 0.35], ...
        'LineWidth', 1.2, ...
        'HandleVisibility','off', ...
        'LabelHorizontalAlignment','right', ...
        'LabelVerticalAlignment','bottom');

    [~, idx_best] = max(tabla.score_local_dB);

    hStar = plot(x(idx_best), tabla.score_local_dB(idx_best) + 0.03, ...
        'kp', ...
        'MarkerSize', 18, ...
        'LineWidth', 2, ...
        'MarkerFaceColor','none', ...
        'DisplayName','Candidato principal');

    xlabel('Frecuencia candidata [kHz]');
    ylabel('Score local ON-OFF [dB]');
    title('LED 2 - Welch: candidatos principales', 'Interpreter','none');

    xticks(x);
    xticklabels(compose('%.3f', tabla.fc_kHz));
    xtickangle(45);

    for i = 1:height(tabla)

        if i == idx_best
            dy = 0.22;  
        else
            dy = 0.10;
        end

        text(x(i), tabla.score_local_dB(i) + dy, ...
            sprintf('%.2f dB\n%d/%d\n%s', ...
            tabla.score_local_dB(i), ...
            tabla.rep_positivas_3dB(i), ...
            tabla.rep_totales(i), ...
            tabla.supera_3dB{i}), ...
            'HorizontalAlignment','center', ...
            'VerticalAlignment','bottom', ...
            'FontSize', 9);
    end

    ylim([0, max([tabla.score_local_dB; umbralScore_dB]) + 1.0]);
    xlim([0.25, height(tabla) + 0.75]);

    legend([hBar hStar], ...
        {'Score local ON-OFF','Candidato principal'}, ...
        'Location','northeastoutside');

    saveas(fig, fullfile(carpeta_salida, 'Welch_LED2_barras_candidatos.png'));
    savefig(fig, fullfile(carpeta_salida, 'Welch_LED2_barras_candidatos.fig'));

end

%% 7. Figura: tabla de candidatos compacta

if ~isempty(tabla)

    tabla_fig = table( ...
        tabla.fc_kHz, ...
        tabla.score_peak_dB, ...
        tabla.f_local_kHz, ...
        tabla.score_local_dB, ...
        tabla.ON_dB, ...
        tabla.OFF_dB, ...
        tabla.rep_positivas_0dB, ...
        tabla.rep_positivas_3dB, ...
        tabla.rep_totales, ...
        tabla.supera_3dB, ...
        'VariableNames', { ...
        'fc_kHz', ...
        'score_peak', ...
        'f_local_kHz', ...
        'score_local', ...
        'ON_dB', ...
        'OFF_dB', ...
        'rep_0dB', ...
        'rep_3dB', ...
        'rep_total', ...
        'supera_3dB'} );

    guardar_tabla_como_figura_compacta( ...
        tabla_fig, ...
        'TABLA DE CANDIDATOS WELCH LED 2', ...
        fullfile(carpeta_salida, 'tabla_welch_LED2_candidatos.png'), ...
        fullfile(carpeta_salida, 'tabla_welch_LED2_candidatos.fig'));

    fprintf('\nTabla visual guardada en:\n%s\n', ...
        fullfile(carpeta_salida, 'tabla_welch_LED2_candidatos.png'));
end

%% ===================== GUARDAR VARIABLES =====================

nombre_mat = fullfile(carpeta_salida, 'datos_welch_LED2_graficas_v2.mat');
nombre_csv = fullfile(carpeta_salida, 'tabla_welch_LED2_candidatos.csv');

save(nombre_mat, ...
    'f', ...
    'P_ON_dB_reps', ...
    'P_OFF_dB_reps', ...
    'P_ON_prom_dB', ...
    'P_OFF_prom_dB', ...
    'score_prom_dB', ...
    'score_reps', ...
    'tabla_candidatos', ...
    'fc_principal_Hz', ...
    'fc_principal_kHz', ...
    'score_principal_dB', ...
    'fc_ref_consenso', ...
    'tol_consenso_Hz', ...
    'fmin_banda', ...
    'fmax_banda', ...
    'fmin_local', ...
    'fmax_local', ...
    'num_reps');

writetable(tabla_candidatos, nombre_csv);

fprintf('\n============================================\n');
fprintf('Welch LED2 graficas V2 terminado.\n');
fprintf('Resultados guardados en:\n%s\n', carpeta_salida);
fprintf('============================================\n');

%% ===================== FUNCIONES LOCALES =====================

function [t, y, Fs] = leer_csv_rigol_simple_local(nombre_archivo, Fs_fallback)

    if nargin < 2
        Fs_fallback = 50e6;
    end

    if ~isfile(nombre_archivo)
        error('No existe el archivo: %s', nombre_archivo);
    end

    A = readmatrix(nombre_archivo);

    A = A(:, any(isfinite(A), 1));
    A = A(any(isfinite(A), 2), :);

    if isempty(A)
        error('No se pudieron leer datos numericos en: %s', nombre_archivo);
    end

    if size(A,2) >= 2
        t = A(:,1);
        y = A(:,2);
    else
        y = A(:,1);
        t = (0:length(y)-1).' / Fs_fallback;
        Fs = Fs_fallback;
        return;
    end

    t = t(:);
    y = y(:);

    idx_valid = isfinite(y);
    t = t(idx_valid);
    y = y(idx_valid);

    tiempo_valido = true;

    if isempty(t) || length(t) ~= length(y)
        tiempo_valido = false;
    elseif any(~isfinite(t))
        tiempo_valido = false;
    else
        dt = diff(t);
        dt_pos = dt(isfinite(dt) & dt > 0);

        if isempty(dt_pos)
            tiempo_valido = false;
        else
            dt_med = median(dt_pos);

            if ~isfinite(dt_med) || dt_med <= 0
                tiempo_valido = false;
            else
                Fs = 1 / dt_med;

                if ~isfinite(Fs) || Fs <= 0 || Fs > 1e12
                    tiempo_valido = false;
                end
            end
        end
    end

    if ~tiempo_valido
        Fs = Fs_fallback;
        t = (0:length(y)-1).' / Fs;
    end

    if any(~isfinite(y))
        y = fillmissing(y, 'linear', 'EndValues', 'nearest');
    end
end

function guardar_tabla_como_figura_compacta(tabla, titulo_tabla, archivo_png, archivo_fig)

    if isempty(tabla)
        warning('La tabla esta vacia. No se guardara figura.');
        return;
    end

    nombres = tabla.Properties.VariableNames;
    datos = table2cell(tabla);

    nRows = size(datos,1);
    nCols = numel(nombres);

    datos_txt = strings(nRows, nCols);

    for i = 1:nRows
        for j = 1:nCols

            v = datos{i,j};
            nombre_col = nombres{j};

            if iscell(v)
                if isempty(v)
                    datos_txt(i,j) = "";
                else
                    datos_txt(i,j) = string(v{1});
                end

            elseif isnumeric(v) && isscalar(v)

                if contains(nombre_col, 'rep', 'IgnoreCase', true)
                    datos_txt(i,j) = sprintf('%d', round(v));

                elseif contains(nombre_col, 'kHz', 'IgnoreCase', true)
                    datos_txt(i,j) = sprintf('%.4f', v);

                elseif contains(nombre_col, 'dB', 'IgnoreCase', true)
                    datos_txt(i,j) = sprintf('%.4f', v);

                else
                    datos_txt(i,j) = sprintf('%.4f', v);
                end

            elseif islogical(v) && isscalar(v)

                if v
                    datos_txt(i,j) = "Si";
                else
                    datos_txt(i,j) = "No";
                end

            elseif isstring(v) || ischar(v)

                datos_txt(i,j) = string(v);

            else

                datos_txt(i,j) = string(v);
            end
        end
    end

    %% Tamaño compacto de figura

    margen_izq = 25;
    margen_der = 25;
    margen_sup = 18;
    margen_inf = 20;

    alto_titulo = 48;
    alto_header = 36;
    alto_fila = 34;

    ancho_col = zeros(1,nCols);

    for c = 1:nCols

        nombre_col = nombres{c};

        switch nombre_col
            case {'fc_kHz','f_local_kHz'}
                ancho_col(c) = 105;

            case {'score_peak','score_local'}
                ancho_col(c) = 125;

            case {'ON_dB','OFF_dB'}
                ancho_col(c) = 105;

            case {'rep_0dB','rep_3dB'}
                ancho_col(c) = 110;

            case {'rep_total'}
                ancho_col(c) = 95;

            case {'supera_3dB'}
                ancho_col(c) = 110;

            otherwise
                ancho_col(c) = 110;
        end
    end

    ancho_tabla = sum(ancho_col);
    alto_tabla = alto_header + nRows*alto_fila;

    ancho_fig = margen_izq + ancho_tabla + margen_der;
    alto_fig = margen_sup + alto_titulo + alto_tabla + margen_inf;

    fig = figure('Color','w', ...
        'Units','pixels', ...
        'Position',[80 80 ancho_fig alto_fig], ...
        'Name', titulo_tabla, ...
        'NumberTitle','off');

    ax = axes('Parent',fig, ...
        'Units','pixels', ...
        'Position',[0 0 ancho_fig alto_fig]);

    axis(ax, [0 ancho_fig 0 alto_fig]);
    axis(ax, 'off');
    hold(ax, 'on');

    %% Titulo

    y_titulo = alto_fig - margen_sup - alto_titulo/2;

    text(ax, ancho_fig/2, y_titulo, titulo_tabla, ...
        'HorizontalAlignment','center', ...
        'VerticalAlignment','middle', ...
        'FontWeight','bold', ...
        'FontSize',22, ...
        'Interpreter','none');

    %% Coordenadas tabla

    x0 = margen_izq;
    y0 = margen_inf + alto_tabla;

    color_header = [0.86 0.86 0.86];
    color_fila_1 = [1 1 1];
    color_fila_2 = [0.92 0.92 0.92];
    color_borde = [0.65 0.65 0.65];

    %% Header

    x = x0;

    for c = 1:nCols

        rectangle(ax, ...
            'Position',[x, y0 - alto_header, ancho_col(c), alto_header], ...
            'FaceColor',color_header, ...
            'EdgeColor',color_borde, ...
            'LineWidth',0.9);

        text(ax, x + ancho_col(c)/2, y0 - alto_header/2, nombres{c}, ...
            'HorizontalAlignment','center', ...
            'VerticalAlignment','middle', ...
            'FontWeight','bold', ...
            'FontSize',10, ...
            'Interpreter','none');

        x = x + ancho_col(c);
    end

    %% Filas

    for r = 1:nRows

        y = y0 - alto_header - r*alto_fila;

        if mod(r,2) == 0
            color_fila = color_fila_2;
        else
            color_fila = color_fila_1;
        end

        x = x0;

        for c = 1:nCols

            rectangle(ax, ...
                'Position',[x, y, ancho_col(c), alto_fila], ...
                'FaceColor',color_fila, ...
                'EdgeColor',[0.82 0.82 0.82], ...
                'LineWidth',0.7);

            text(ax, x + ancho_col(c)/2, y + alto_fila/2, datos_txt(r,c), ...
                'HorizontalAlignment','center', ...
                'VerticalAlignment','middle', ...
                'FontSize',10, ...
                'Interpreter','none');

            x = x + ancho_col(c);
        end
    end

    drawnow;

    set(fig, 'PaperPositionMode', 'auto');

    print(fig, archivo_png, '-dpng', '-r300');
    savefig(fig, archivo_fig);
end