%% A_LEDS_01_periodogram_graficas_v2.m
%
% INSTRUCCIONES DE USO
% Antes de ejecutar este script, revisar la variable carpeta_datos
% y modificarla si los archivos .csv se encuentran en otra ruta local.
% La carpeta indicada debe contener los archivos ON_ALEDS_REP*.csv
% y OFF_ALEDS_REP*.csv definidos en las listas archivos_ON
% y archivos_OFF.
%
% Ejemplo:
% carpeta_datos = 'C:\Users\NombreUsuario\Desktop\Prueba AMBOS LED';

clear; 
clc;
close all;

%% 1. Configuracion general

carpeta_datos = 'C:\Users\mudrood\Desktop\Modulo Prof\Archivos Tesis\Toma de Datos\Prueba AMBOS LED';

carpeta_salida = fullfile(carpeta_datos, 'Resultados_Ambos_LEDS_modificados', '01_Periodogram');
if ~exist(carpeta_salida, 'dir')
    mkdir(carpeta_salida);
end

nombre_base = 'Ambos LEDS';
metodo = 'Periodogram';

num_reps = 4;

archivos_ON  = cell(num_reps, 1);
archivos_OFF = cell(num_reps, 1);

for r = 1:num_reps
    archivos_ON{r}  = fullfile(carpeta_datos, sprintf('ON_ALEDS_REP%d.csv', r));
    archivos_OFF{r} = fullfile(carpeta_datos, sprintf('OFF_ALEDS_REP%d.csv', r));
end

led_nombres = ["LED 1"; "LED 2"];

fc_led1_kHz = [56.286, 57.704, 55.549];
fc_led2_kHz = [45.375, 44.581, 44.821];

fc_ref_kHz = [
    mean(fc_led1_kHz)
    mean(fc_led2_kHz)
];

fc_ref_kHz(1) = 56.513;
fc_ref_kHz(2) = 44.926;

tol_ref_kHz = 2.0;

fmin_kHz = 30;
fmax_kHz = 90;

fmax_amplio_MHz = 5;

criterio_dB = 3.0;
umbral_repeticiones = 3;

c_led1 = [0.36 0.52 0.66];
c_led2 = [0.68 0.55 0.36];
c_neutro = [0.55 0.55 0.55];

num_candidatos_globales = 10;

dist_min_candidatos_Hz = 500;

Fs_default = 50e6;

Nmax = Inf;

nfft_max = Inf;

fprintf('\n============================================================\n');
fprintf('INICIO ANALISIS PERIODOGRAM - AMBOS LEDS\n');
fprintf('============================================================\n');
fprintf('Carpeta de datos:\n%s\n\n', carpeta_datos);
fprintf('Carpeta de salida:\n%s\n\n', carpeta_salida);
fprintf('Referencias usadas:\n');
fprintf('  LED 1 = %.3f kHz, tolerancia +- %.1f kHz\n', fc_ref_kHz(1), tol_ref_kHz);
fprintf('  LED 2 = %.3f kHz, tolerancia +- %.1f kHz\n', fc_ref_kHz(2), tol_ref_kHz);

%% 2. Lectura y calculo de PSD por repeticion

P_on_dB_banda  = [];
P_off_dB_banda = [];
P_on_dB_amplio  = [];
P_off_dB_amplio = [];

f_banda_Hz = [];
f_amplio_Hz = [];

info_reps = table();

for r = 1:num_reps

    fprintf('\n------------------------------------------------------------\n');
    fprintf('Repeticion %d/%d\n', r, num_reps);
    fprintf('ON : %s\n', archivos_ON{r});
    fprintf('OFF: %s\n', archivos_OFF{r});

    if ~exist(archivos_ON{r}, 'file')
        error('No existe el archivo ON: %s', archivos_ON{r});
    end

    if ~exist(archivos_OFF{r}, 'file')
        error('No existe el archivo OFF: %s', archivos_OFF{r});
    end

    [t_on, y_on, Fs_on] = leer_csv_rigol_simple_local(archivos_ON{r}, Fs_default);
    [t_off, y_off, Fs_off] = leer_csv_rigol_simple_local(archivos_OFF{r}, Fs_default);

    Fs = mean([Fs_on, Fs_off], 'omitnan');

    if ~isfinite(Fs) || Fs <= 0
        Fs = Fs_default;
        warning('Fs no valida. Se usa Fs_default = %.3f MSa/s', Fs_default/1e6);
    end

    N_on = numel(y_on);
    N_off = numel(y_off);
    N = min(N_on, N_off);

    if isfinite(Nmax)
        N = min(N, Nmax);
    end

    y_on = y_on(1:N);
    y_off = y_off(1:N);

    y_on = y_on(:);
    y_off = y_off(:);

    y_on = y_on - mean(y_on, 'omitnan');
    y_off = y_off - mean(y_off, 'omitnan');

    if isfinite(nfft_max)
        nfft = min(N, nfft_max);
    else
        nfft = N;
    end

    nfft = floor(nfft);

    fprintf('N ON  = %d muestras\n', N_on);
    fprintf('N OFF = %d muestras\n', N_off);
    fprintf('N usado = %d muestras\n', N);
    fprintf('Fs usada = %.6f MSa/s\n', Fs/1e6);
    fprintf('nfft = %d\n', nfft);
    fprintf('df aprox = %.6f Hz\n', Fs/nfft);

    [P_on, f]  = periodogram(y_on,  rectwin(N), nfft, Fs, 'psd');
    [P_off, ~] = periodogram(y_off, rectwin(N), nfft, Fs, 'psd');

    P_on_dB = 10*log10(P_on + eps);
    P_off_dB = 10*log10(P_off + eps);

    if r == 1
        idx_banda = (f >= fmin_kHz*1e3) & (f <= fmax_kHz*1e3);
        idx_amplio = (f >= 0) & (f <= fmax_amplio_MHz*1e6);

        f_banda_Hz = f(idx_banda);
        f_amplio_Hz = f(idx_amplio);

        P_on_dB_banda  = nan(numel(f_banda_Hz), num_reps);
        P_off_dB_banda = nan(numel(f_banda_Hz), num_reps);

        P_on_dB_amplio  = nan(numel(f_amplio_Hz), num_reps);
        P_off_dB_amplio = nan(numel(f_amplio_Hz), num_reps);
    end

    if numel(f) ~= numel(P_on_dB)
        error('Error interno: f y PSD tienen largos distintos.');
    end

    P_on_dB_banda(:, r)  = interp1(f, P_on_dB,  f_banda_Hz,  'linear', 'extrap');
    P_off_dB_banda(:, r) = interp1(f, P_off_dB, f_banda_Hz,  'linear', 'extrap');

    P_on_dB_amplio(:, r)  = interp1(f, P_on_dB,  f_amplio_Hz, 'linear', 'extrap');
    P_off_dB_amplio(:, r) = interp1(f, P_off_dB, f_amplio_Hz, 'linear', 'extrap');

    info_reps = [info_reps; table( ...
        r, N_on, N_off, N, Fs, nfft, Fs/nfft, ...
        'VariableNames', {'repeticion','N_ON','N_OFF','N_usado','Fs_Hz','nfft','df_Hz'})];

end

%% 3. Promedios y score ON-OFF

f_banda_kHz = f_banda_Hz / 1e3;
f_amplio_MHz = f_amplio_Hz / 1e6;

P_on_prom_banda_dB  = mean(P_on_dB_banda,  2, 'omitnan');
P_off_prom_banda_dB = mean(P_off_dB_banda, 2, 'omitnan');

P_on_prom_amplio_dB  = mean(P_on_dB_amplio,  2, 'omitnan');
P_off_prom_amplio_dB = mean(P_off_dB_amplio, 2, 'omitnan');

score_reps_dB = P_on_dB_banda - P_off_dB_banda;
score_prom_dB = mean(score_reps_dB, 2, 'omitnan');

rep_positivas_0dB = sum(score_reps_dB > 0, 2);
rep_positivas_3dB = sum(score_reps_dB >= criterio_dB, 2);

%% ===================== DETECCION LOCAL POR LED ==========================
resultados_LED = table();

for i = 1:numel(fc_ref_kHz)

    fc_ref = fc_ref_kHz(i);

    fmin_local = fc_ref - tol_ref_kHz;
    fmax_local = fc_ref + tol_ref_kHz;

    idx_local = (f_banda_kHz >= fmin_local) & (f_banda_kHz <= fmax_local);

    if ~any(idx_local)
        error('No hay puntos dentro de la ventana local para %s.', led_nombres(i));
    end

    idx_validos = idx_local & ...
                  (score_prom_dB >= criterio_dB) & ...
                  (rep_positivas_3dB >= umbral_repeticiones);

    if any(idx_validos)
        f_aux = f_banda_kHz(idx_validos);
        score_aux = score_prom_dB(idx_validos);

        [score_max, idx_max] = max(score_aux);
        fc_detectada = f_aux(idx_max);

        supera_3dB = "Si";
    else

        f_aux = f_banda_kHz(idx_local);
        score_aux = score_prom_dB(idx_local);

        [score_max, idx_max] = max(score_aux);
        fc_detectada = f_aux(idx_max);

        supera_3dB = "No";
    end

    idx_fc = buscar_indice_mas_cercano(f_banda_kHz, fc_detectada);

    ON_dB = P_on_prom_banda_dB(idx_fc);
    OFF_dB = P_off_prom_banda_dB(idx_fc);

    rep_0dB = rep_positivas_0dB(idx_fc);
    rep_3dB = rep_positivas_3dB(idx_fc);

    err_ref_kHz = abs(fc_detectada - fc_ref);
    err_ref_pct = 100 * err_ref_kHz / fc_ref;

    resultados_LED = [resultados_LED; table( ...
        led_nombres(i), fc_ref, fc_detectada, score_max, ...
        ON_dB, OFF_dB, rep_0dB, rep_3dB, num_reps, supera_3dB, ...
        err_ref_kHz, err_ref_pct, ...
        'VariableNames', {'LED','fc_ref_kHz','fc_detectada_kHz','score_dB', ...
        'ON_dB','OFF_dB','rep_0dB','rep_3dB','rep_total','supera_3dB', ...
        'err_ref_kHz','err_ref_pct'})];

end

%% ===================== CANDIDATOS GLOBALES INFORMATIVOS ================
[pks, locs] = findpeaks(score_prom_dB, f_banda_Hz, ...
    'SortStr', 'descend', ...
    'NPeaks', num_candidatos_globales, ...
    'MinPeakDistance', dist_min_candidatos_Hz);

fc_global_kHz = locs(:) / 1e3;
score_global = pks(:);

ON_global = nan(numel(fc_global_kHz), 1);
OFF_global = nan(numel(fc_global_kHz), 1);
rep0_global = nan(numel(fc_global_kHz), 1);
rep3_global = nan(numel(fc_global_kHz), 1);
supera_global = strings(numel(fc_global_kHz), 1);

for i = 1:numel(fc_global_kHz)
    idx_i = buscar_indice_mas_cercano(f_banda_kHz, fc_global_kHz(i));

    ON_global(i) = P_on_prom_banda_dB(idx_i);
    OFF_global(i) = P_off_prom_banda_dB(idx_i);
    rep0_global(i) = rep_positivas_0dB(idx_i);
    rep3_global(i) = rep_positivas_3dB(idx_i);

    if score_global(i) >= criterio_dB && rep3_global(i) >= umbral_repeticiones
        supera_global(i) = "Si";
    else
        supera_global(i) = "No";
    end
end

tabla_global = table( ...
    fc_global_kHz, score_global, ON_global, OFF_global, ...
    rep0_global, rep3_global, repmat(num_reps, numel(fc_global_kHz), 1), supera_global, ...
    'VariableNames', {'fc_kHz','score_peak','ON_dB','OFF_dB','rep_0dB','rep_3dB','rep_total','supera_3dB'});

%% ===================== MOSTRAR TABLAS EN COMMAND WINDOW =================
fprintf('\n============================================================\n');
fprintf('FRECUENCIAS DETECTADAS - AMBOS LEDS\n');
fprintf('============================================================\n');
disp(resultados_LED);

fprintf('\n============================================================\n');
fprintf('CANDIDATOS GLOBALES INFORMATIVOS\n');
fprintf('============================================================\n');
disp(tabla_global);

%% ===================== GUARDAR CSV Y MAT ================================
writetable(resultados_LED, fullfile(carpeta_salida, 'tabla_resultados_periodogram_Ambos_LEDS.csv'));
writetable(tabla_global,   fullfile(carpeta_salida, 'tabla_candidatos_globales_periodogram_Ambos_LEDS.csv'));
writetable(info_reps,      fullfile(carpeta_salida, 'info_repeticiones_periodogram_Ambos_LEDS.csv'));

save(fullfile(carpeta_salida, 'datos_periodogram_Ambos_LEDS.mat'), ...
    'f_banda_kHz', 'f_banda_Hz', 'f_amplio_MHz', 'f_amplio_Hz', ...
    'P_on_dB_banda', 'P_off_dB_banda', ...
    'P_on_dB_amplio', 'P_off_dB_amplio', ...
    'P_on_prom_banda_dB', 'P_off_prom_banda_dB', ...
    'P_on_prom_amplio_dB', 'P_off_prom_amplio_dB', ...
    'score_reps_dB', 'score_prom_dB', ...
    'rep_positivas_0dB', 'rep_positivas_3dB', ...
    'resultados_LED', 'tabla_global', 'info_reps', ...
    'fc_ref_kHz', 'tol_ref_kHz', 'criterio_dB', 'umbral_repeticiones');

%% ===================== GRAFICO 01: SCORE EN BANDA =======================
fig = figure('Color','w', 'Position', [100 100 1500 850]);
plot(f_banda_kHz, score_prom_dB, 'LineWidth', 1.0);
grid on; box on;
xlabel('Frecuencia [kHz]');
ylabel('Score ON - OFF [dB]');
title(sprintf('%s - %s: score ON-OFF en banda de analisis', nombre_base, metodo));

yline(0, '--', '0 dB', 'LabelHorizontalAlignment','right');
yline(criterio_dB, '--', sprintf('Criterio %.1f dB', criterio_dB), ...
    'LabelHorizontalAlignment','right');

for i = 1:height(resultados_LED)
    xline(resultados_LED.fc_detectada_kHz(i), ':', 'LineWidth', 1.1);
    yl = ylim;
    text(resultados_LED.fc_detectada_kHz(i), yl(2)-0.05*range(yl), ...
        sprintf('%s %.3f kHz', resultados_LED.LED(i), resultados_LED.fc_detectada_kHz(i)), ...
        'Rotation', 90, 'VerticalAlignment','top', 'HorizontalAlignment','right');
end

xlim([fmin_kHz fmax_kHz]);

guardar_figura(fig, carpeta_salida, '01_Ambos_LEDS_periodogram_score_ON_OFF_banda');

%% ===================== GRAFICO 02: FRECUENCIAS DETECTADAS ==============
fig = figure('Color','w', 'Position', [100 100 1500 850]);

b = bar(resultados_LED.score_dB, 0.65);
b.FaceColor = 'flat';
b.EdgeColor = 'k';
b.CData = [
    c_led1
    c_led2
];

grid on; box on;
ylabel('Score local ON-OFF [dB]');
xlabel('Componente');
title(sprintf('%s - %s: frecuencias detectadas por LED', nombre_base, metodo), ...
    'Interpreter','none');

set(gca, 'XTick', 1:height(resultados_LED), ...
    'XTickLabel', resultados_LED.LED);

yline(criterio_dB, '--', sprintf('Criterio %.1f dB', criterio_dB), ...
    'Color',[0.45 0.45 0.45], ...
    'LineWidth',1.1, ...
    'LabelHorizontalAlignment','right');

for i = 1:height(resultados_LED)
    text(i, resultados_LED.score_dB(i) + 0.35, ...
        sprintf('%.3f kHz\n%.2f dB\n%d/%d\n%s', ...
        resultados_LED.fc_detectada_kHz(i), ...
        resultados_LED.score_dB(i), ...
        resultados_LED.rep_3dB(i), resultados_LED.rep_total(i), ...
        resultados_LED.supera_3dB(i)), ...
        'HorizontalAlignment','center', ...
        'VerticalAlignment','bottom', ...
        'FontSize',10);
end

ylim([0, max(resultados_LED.score_dB)*1.25]);

guardar_figura(fig, carpeta_salida, '02_Ambos_LEDS_periodogram_frecuencias_detectadas');

%% ===================== GRAFICO 03: CANDIDATOS GLOBALES ================
fig = figure('Color','w', 'Position', [100 100 1500 850]);

colores_candidatos = repmat(c_neutro, height(tabla_global), 1);

for i = 1:height(tabla_global)
    if abs(tabla_global.fc_kHz(i) - fc_ref_kHz(1)) <= tol_ref_kHz
        colores_candidatos(i,:) = c_led1;
    elseif abs(tabla_global.fc_kHz(i) - fc_ref_kHz(2)) <= tol_ref_kHz
        colores_candidatos(i,:) = c_led2;
    end
end

b = bar(tabla_global.score_peak, 0.68);
b.FaceColor = 'flat';
b.EdgeColor = 'k';
b.CData = colores_candidatos;

grid on; box on;
xlabel('Frecuencia candidata [kHz]');
ylabel('Score local ON-OFF [dB]');
title(sprintf('%s - %s: candidatos globales informativos', nombre_base, metodo), ...
    'Interpreter','none');

set(gca, 'XTick', 1:height(tabla_global));
set(gca, 'XTickLabel', compose('%.3f', tabla_global.fc_kHz));
xtickangle(45);

yline(criterio_dB, '--', sprintf('Criterio %.1f dB', criterio_dB), ...
    'Color',[0.45 0.45 0.45], ...
    'LineWidth',1.1, ...
    'LabelHorizontalAlignment','right');

for i = 1:height(tabla_global)
    text(i, tabla_global.score_peak(i) + 0.25, ...
        sprintf('%.2f dB\n%d/%d', ...
        tabla_global.score_peak(i), ...
        tabla_global.rep_3dB(i), tabla_global.rep_total(i)), ...
        'HorizontalAlignment','center', ...
        'VerticalAlignment','bottom', ...
        'FontSize',9);
end

ylim([0, max(tabla_global.score_peak)*1.17]);

hold on;

h_led1 = bar(nan, nan, 'FaceColor', c_led1, 'EdgeColor','k');
h_led2 = bar(nan, nan, 'FaceColor', c_led2, 'EdgeColor','k');
h_otro = bar(nan, nan, 'FaceColor', c_neutro, 'EdgeColor','k');

legend([h_led1 h_led2 h_otro], ...
    {'Candidato asociado a LED 1', ...
     'Candidato asociado a LED 2', ...
     'Candidato global informativo'}, ...
    'Location','northeast');

guardar_figura(fig, carpeta_salida, '03_Ambos_LEDS_periodogram_candidatos_globales');

%% ===================== GRAFICO 04: PSD PROMEDIO BANDA ==================
fig = figure('Color','w', 'Position', [100 100 1500 850]);

plot(f_banda_kHz, P_on_prom_banda_dB, 'LineWidth', 1.0); hold on;
plot(f_banda_kHz, P_off_prom_banda_dB, 'LineWidth', 1.0);
grid on; box on;
xlabel('Frecuencia [kHz]');
ylabel('PSD Periodogram [dB/Hz]');
title(sprintf('%s - %s: PSD promedio ON/OFF en banda de analisis', nombre_base, metodo));
legend('LED encendido','LED apagado', 'Location','best');

for i = 1:height(resultados_LED)
    xline(resultados_LED.fc_detectada_kHz(i), ':', ...
        'LineWidth', 1.1, ...
        'HandleVisibility', 'off');

    yl = ylim;
    text(resultados_LED.fc_detectada_kHz(i), yl(2)-0.05*range(yl), ...
        sprintf('%s %.3f kHz', resultados_LED.LED(i), resultados_LED.fc_detectada_kHz(i)), ...
        'Rotation', 90, ...
        'VerticalAlignment','top', ...
        'HorizontalAlignment','right');
end

legend('LED encendido','LED apagado', 'Location','best');

xlim([fmin_kHz fmax_kHz]);

guardar_figura(fig, carpeta_salida, '04_Ambos_LEDS_periodogram_PSD_promedio_ON_OFF_banda');

%% ===================== GRAFICO 05: PSD PROMEDIO RANGO AMPLIO ===========
fig = figure('Color','w', 'Position', [100 100 1500 850]);

plot(f_amplio_MHz, P_on_prom_amplio_dB, 'LineWidth', 1.0); hold on;
plot(f_amplio_MHz, P_off_prom_amplio_dB, 'LineWidth', 1.0);
grid on; box on;
xlabel('Frecuencia [MHz]');
ylabel('PSD Periodogram [dB/Hz]');
title(sprintf('%s - %s: PSD promedio ON/OFF, rango amplio', nombre_base, metodo));
legend('LED encendido','LED apagado', 'Location','best');

xlim([0 fmax_amplio_MHz]);

guardar_figura(fig, carpeta_salida, '05_Ambos_LEDS_periodogram_PSD_promedio_ON_OFF_rango_amplio');

%% ===================== GRAFICO 06: REPETICIONES OFF ====================
fig = figure('Color','w', 'Position', [100 100 1500 850]);

hold on;
for r = 1:num_reps
    plot(f_banda_kHz, P_off_dB_banda(:,r), 'LineWidth', 0.8);
end
grid on; box on;
xlabel('Frecuencia [kHz]');
ylabel('PSD Periodogram [dB/Hz]');
title(sprintf('%s - %s: repeticiones OFF en banda de analisis', nombre_base, metodo));
legend(compose('OFF rep %d', 1:num_reps), 'Location','best');

xlim([fmin_kHz fmax_kHz]);

guardar_figura(fig, carpeta_salida, '06_Ambos_LEDS_periodogram_repeticiones_OFF_banda');

%% ===================== GRAFICO 07: REPETICIONES ON =====================
fig = figure('Color','w', 'Position', [100 100 1500 850]);

hold on;
for r = 1:num_reps
    plot(f_banda_kHz, P_on_dB_banda(:,r), 'LineWidth', 0.8);
end
grid on; box on;
xlabel('Frecuencia [kHz]');
ylabel('PSD Periodogram [dB/Hz]');
title(sprintf('%s - %s: repeticiones ON en banda de analisis', nombre_base, metodo));
legend(compose('ON rep %d', 1:num_reps), 'Location','best');

xlim([fmin_kHz fmax_kHz]);

guardar_figura(fig, carpeta_salida, '07_Ambos_LEDS_periodogram_repeticiones_ON_banda');

%% ===================== TABLAS COMO IMAGEN ===============================
tabla_resultados_img = resultados_LED;
tabla_resultados_img.fc_ref_kHz = round(tabla_resultados_img.fc_ref_kHz, 4);
tabla_resultados_img.fc_detectada_kHz = round(tabla_resultados_img.fc_detectada_kHz, 4);
tabla_resultados_img.score_dB = round(tabla_resultados_img.score_dB, 4);
tabla_resultados_img.ON_dB = round(tabla_resultados_img.ON_dB, 4);
tabla_resultados_img.OFF_dB = round(tabla_resultados_img.OFF_dB, 4);
tabla_resultados_img.err_ref_kHz = round(tabla_resultados_img.err_ref_kHz, 4);
tabla_resultados_img.err_ref_pct = round(tabla_resultados_img.err_ref_pct, 2);

guardar_tabla_como_imagen( ...
    tabla_resultados_img, ...
    'TABLA RESULTADOS PERIODOGRAM AMBOS LEDS', ...
    fullfile(carpeta_salida, '08_Tabla_resultados_periodogram_Ambos_LEDS.png'));

tabla_global_img = tabla_global;
tabla_global_img.fc_kHz = round(tabla_global_img.fc_kHz, 4);
tabla_global_img.score_peak = round(tabla_global_img.score_peak, 4);
tabla_global_img.ON_dB = round(tabla_global_img.ON_dB, 4);
tabla_global_img.OFF_dB = round(tabla_global_img.OFF_dB, 4);

guardar_tabla_como_imagen( ...
    tabla_global_img, ...
    'TABLA CANDIDATOS GLOBALES PERIODOGRAM AMBOS LEDS', ...
    fullfile(carpeta_salida, '09_Tabla_candidatos_globales_periodogram_Ambos_LEDS.png'));

fprintf('\n============================================================\n');
fprintf('ANALISIS FINALIZADO\n');
fprintf('Resultados guardados en:\n%s\n', carpeta_salida);
fprintf('============================================================\n');

%% ========================================================================
% FUNCIONES LOCALES

function [t, y, Fs] = leer_csv_rigol_simple_local(nombre_archivo, Fs_default)

    C = readcell(nombre_archivo);

    nfil = size(C,1);
    ncol = size(C,2);

    M = nan(nfil, ncol);

    for i = 1:nfil
        for j = 1:ncol
            v = C{i,j};

            if isnumeric(v) && isscalar(v)
                M(i,j) = v;
            elseif ischar(v) || isstring(v)
                s = string(v);
                s = strrep(s, ',', '.');
                x = str2double(s);
                if isfinite(x)
                    M(i,j) = x;
                end
            end
        end
    end

    filas_validas = sum(isfinite(M), 2) >= 2;
    M = M(filas_validas, :);

    if isempty(M)
        error('No se encontraron datos numericos validos en: %s', nombre_archivo);
    end

    min_datos = max(10, round(0.1 * size(M,1)));
    cols_validas = sum(isfinite(M), 1) >= min_datos;
    M = M(:, cols_validas);

    if size(M,2) < 2
        error('No hay al menos dos columnas numericas validas en: %s', nombre_archivo);
    end

    mejor_col_t = 1;
    mejor_score = -Inf;

    for c = 1:size(M,2)
        x = M(:,c);
        x = x(isfinite(x));

        if numel(x) < 10
            continue;
        end

        dx = diff(x);
        dx = dx(isfinite(dx));

        if isempty(dx)
            continue;
        end

        prop_pos = mean(dx > 0);
        rango = max(x) - min(x);

        score = prop_pos + 0.1*double(rango > 0);

        if score > mejor_score
            mejor_score = score;
            mejor_col_t = c;
        end
    end

    cols = 1:size(M,2);
    cols_y = cols(cols ~= mejor_col_t);

    var_cols = nan(numel(cols_y),1);
    for k = 1:numel(cols_y)
        yy = M(:, cols_y(k));
        var_cols(k) = var(yy, 'omitnan');
    end

    [~, idx_var] = max(var_cols);
    mejor_col_y = cols_y(idx_var);

    t = M(:, mejor_col_t);
    y = M(:, mejor_col_y);

    idx = isfinite(t) & isfinite(y);
    t = t(idx);
    y = y(idx);

    t = t(:);
    y = y(:);

    if numel(y) < 10
        error('Vector de señal demasiado corto en: %s', nombre_archivo);
    end

    dt = diff(t);
    dt = dt(isfinite(dt) & dt > 0);

    if isempty(dt)
        Fs = Fs_default;
        t = (0:numel(y)-1).' / Fs;
        return;
    end

    dt_med = median(dt);

    if ~isfinite(dt_med) || dt_med <= 0
        Fs = Fs_default;
        t = (0:numel(y)-1).' / Fs;
        return;
    end

    Fs = 1 / dt_med;

    if ~isfinite(Fs) || Fs <= 0 || Fs > 1e12
        Fs = Fs_default;
        t = (0:numel(y)-1).' / Fs;
    end

end

function idx = buscar_indice_mas_cercano(vector, valor)
    [~, idx] = min(abs(vector - valor));
end

function guardar_figura(fig, carpeta_salida, nombre_archivo)

    archivo_png = fullfile(carpeta_salida, [nombre_archivo '.png']);
    archivo_fig = fullfile(carpeta_salida, [nombre_archivo '.fig']);

    try
        exportgraphics(fig, archivo_png, 'Resolution', 200);
    catch
        saveas(fig, archivo_png);
    end

    try
        savefig(fig, archivo_fig);
    catch
        warning('No se pudo guardar FIG: %s', archivo_fig);
    end

end

function guardar_tabla_como_imagen(T, titulo, archivo_png)


    nombres = string(T.Properties.VariableNames);
    nfil = height(T);
    ncol = width(T);

    datos = strings(nfil, ncol);

    for c = 1:ncol
        col = T.(nombres(c));

        for r = 1:nfil
            v = col(r);

            if isnumeric(v)
                if abs(v - round(v)) < 1e-10
                    datos(r,c) = sprintf('%.0f', v);
                else
                    datos(r,c) = sprintf('%.4f', v);
                end
            elseif isstring(v)
                datos(r,c) = v;
            elseif iscell(v)
                datos(r,c) = string(v{1});
            elseif iscategorical(v)
                datos(r,c) = string(v);
            else
                datos(r,c) = string(v);
            end
        end
    end

    nombres = reemplazar_nombres_tabla(nombres);

    ancho_col = 135;
    alto_fila = 42;
    margen_x = 45;
    margen_y = 95;

    fig_w = max(1200, margen_x*2 + ancho_col*ncol);
    fig_h = max(260, margen_y + alto_fila*(nfil+1) + 60);

    fig = figure('Color','w', 'Position', [100 100 fig_w fig_h]);
    axis off;

    ax = axes('Position', [0 0 1 1]);
    axis(ax, [0 fig_w 0 fig_h]);
    axis(ax, 'off');
    hold(ax, 'on');

    text(fig_w/2, fig_h-45, titulo, ...
        'HorizontalAlignment','center', ...
        'VerticalAlignment','middle', ...
        'FontSize', 20, ...
        'FontWeight','bold', ...
        'Interpreter','none');

    x0 = margen_x;
    y0 = fig_h - margen_y;

    tabla_w = ancho_col*ncol;
    tabla_h = alto_fila*(nfil+1);

    for c = 1:ncol
        x = x0 + (c-1)*ancho_col;
        y = y0;

        rectangle('Position', [x y-alto_fila ancho_col alto_fila], ...
            'FaceColor', [0.86 0.86 0.86], ...
            'EdgeColor', [0.65 0.65 0.65], ...
            'LineWidth', 1.0);

        text(x + ancho_col/2, y - alto_fila/2, nombres(c), ...
            'HorizontalAlignment','center', ...
            'VerticalAlignment','middle', ...
            'FontSize', 11, ...
            'FontWeight','bold', ...
            'Interpreter','none');
    end

    for r = 1:nfil
        for c = 1:ncol

            x = x0 + (c-1)*ancho_col;
            y = y0 - r*alto_fila;

            if mod(r,2) == 0
                color_fila = [0.92 0.92 0.92];
            else
                color_fila = [1 1 1];
            end

            rectangle('Position', [x y-alto_fila ancho_col alto_fila], ...
                'FaceColor', color_fila, ...
                'EdgeColor', [0.82 0.82 0.82], ...
                'LineWidth', 0.8);

            text(x + ancho_col/2, y - alto_fila/2, datos(r,c), ...
                'HorizontalAlignment','center', ...
                'VerticalAlignment','middle', ...
                'FontSize', 10.5, ...
                'Interpreter','none');
        end
    end

    rectangle('Position', [x0 y0-tabla_h tabla_w tabla_h], ...
        'EdgeColor', [0.65 0.65 0.65], ...
        'LineWidth', 1.2);

    try
        exportgraphics(fig, archivo_png, 'Resolution', 200);
    catch
        saveas(fig, archivo_png);
    end

    archivo_fig = strrep(archivo_png, '.png', '.fig');
    try
        savefig(fig, archivo_fig);
    catch
        warning('No se pudo guardar tabla FIG.');
    end

end

function nombres_out = reemplazar_nombres_tabla(nombres_in)

    nombres_out = nombres_in;

    for i = 1:numel(nombres_out)
        s = nombres_out(i);

        s = replace(s, "fc_detectada_kHz", "fc_det_kHz");
        s = replace(s, "fc_ref_kHz", "fc_ref_kHz");
        s = replace(s, "score_peak", "score_peak");
        s = replace(s, "score_dB", "score_dB");
        s = replace(s, "score_local_dB", "score_local");
        s = replace(s, "rep_total", "rep_total");
        s = replace(s, "rep_positivas_0dB", "rep_0dB");
        s = replace(s, "rep_positivas_3dB", "rep_3dB");
        s = replace(s, "supera_3dB", "supera_3dB");
        s = replace(s, "err_ref_kHz", "err_kHz");
        s = replace(s, "err_ref_pct", "err_pct");

        nombres_out(i) = s;
    end

end