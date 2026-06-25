%% A_LEDS_02_welch_graficas_v2.m
%
% INSTRUCCIONES DE USO
% Antes de ejecutar este script, revisar la variable carpeta_base
% y modificarla si los archivos .csv se encuentran en otra ruta local.
% La carpeta indicada debe contener los archivos ON_ALEDS_REP*.csv
% y OFF_ALEDS_REP*.csv definidos en las listas archivos_ON
% y archivos_OFF.
%
% Ejemplo:
% carpeta_base = 'C:\Users\NombreUsuario\Desktop\Prueba AMBOS LED';

clear; 
clc; 
close all;

%% ===================== CONFIGURACION GENERAL =====================

carpeta_base = 'C:\Users\mudrood\Desktop\Modulo Prof\Archivos Tesis\Toma de Datos\Prueba AMBOS LED';

carpeta_salida = fullfile(carpeta_base, 'Resultados_Ambos_LEDS_modificados', '02_Welch');

if ~exist(carpeta_salida, 'dir')
    mkdir(carpeta_salida);
end

nombre_metodo = 'Welch';
nombre_sistema = 'Ambos LEDS';

num_reps = 4;

archivos_ON = cell(num_reps, 1);
archivos_OFF = cell(num_reps, 1);

for r = 1:num_reps
    archivos_ON{r}  = fullfile(carpeta_base, sprintf('ON_ALEDS_REP%d.csv', r));
    archivos_OFF{r} = fullfile(carpeta_base, sprintf('OFF_ALEDS_REP%d.csv', r));
end

fc_ref_LED1_kHz = 56.513;
fc_ref_LED2_kHz = 44.926;

fc_ref_kHz = [fc_ref_LED1_kHz; fc_ref_LED2_kHz];
nombres_led = {'LED 1'; 'LED 2'};

tol_kHz = 2.0;

fmin_kHz = 30;
fmax_kHz = 90;

criterio_dB = 3;

c_led1 = [0.36 0.52 0.66];   
c_led2 = [0.68 0.55 0.36];   
c_neutro = [0.55 0.55 0.55]; 

num_candidatos_globales = 10;

Nmax = Inf;

usar_fraccion_senal = 1/8;      
overlap_frac = 0.50;           
nfft_min = 1e6;                

%% ===================== LECTURA Y CALCULO WELCH =====================

PSD_ON_dB = cell(num_reps, 1);
PSD_OFF_dB = cell(num_reps, 1);
score_rep_dB = cell(num_reps, 1);

f_ref = [];

fprintf('\n============================================================\n');
fprintf('ANALISIS WELCH - %s\n', upper(nombre_sistema));
fprintf('============================================================\n\n');

for r = 1:num_reps

    fprintf('------------------------------------------------------------\n');
    fprintf('Repeticion %d/%d\n', r, num_reps);
    fprintf('ON : %s\n', archivos_ON{r});
    fprintf('OFF: %s\n', archivos_OFF{r});

    if ~exist(archivos_ON{r}, 'file')
        error('No existe el archivo ON:\n%s', archivos_ON{r});
    end

    if ~exist(archivos_OFF{r}, 'file')
        error('No existe el archivo OFF:\n%s', archivos_OFF{r});
    end

    [t_on, y_on] = leer_csv_rigol_robusto_local(archivos_ON{r}, Nmax);
    [t_off, y_off] = leer_csv_rigol_robusto_local(archivos_OFF{r}, Nmax);

    N_on = numel(y_on);
    N_off = numel(y_off);

    N = min(N_on, N_off);

    t_on = t_on(1:N);
    y_on = y_on(1:N);

    t_off = t_off(1:N);
    y_off = y_off(1:N);

    Fs_on = calcular_Fs_local(t_on);
    Fs_off = calcular_Fs_local(t_off);

    Fs = mean([Fs_on Fs_off], 'omitnan');

    if ~isfinite(Fs) || Fs <= 0
        error('Fs no valido en repeticion %d. Revisar vector de tiempo.', r);
    end

    fprintf('N ON usado  = %d muestras\n', N);
    fprintf('N OFF usado = %d muestras\n', N);
    fprintf('Fs ON       = %.6f MSa/s\n', Fs_on/1e6);
    fprintf('Fs OFF      = %.6f MSa/s\n', Fs_off/1e6);
    fprintf('Fs usada    = %.6f MSa/s\n', Fs/1e6);

    y_on = y_on(:);
    y_off = y_off(:);

    y_on = y_on - mean(y_on, 'omitnan');
    y_off = y_off - mean(y_off, 'omitnan');

    y_on(~isfinite(y_on)) = 0;
    y_off(~isfinite(y_off)) = 0;

    Nseg = floor(N * usar_fraccion_senal);
    Nseg = max(Nseg, 1024);

    noverlap = floor(Nseg * overlap_frac);

    nfft = max(nfft_min, 2^nextpow2(Nseg));
    nfft = min(nfft, N);

    ventana = hann(Nseg, 'periodic');

    fprintf('Welch rep %d:\n', r);
    fprintf('Nseg     = %d muestras\n', Nseg);
    fprintf('noverlap = %d muestras\n', noverlap);
    fprintf('nfft     = %d muestras\n', nfft);

    [P_on, f] = pwelch(y_on, ventana, noverlap, nfft, Fs, 'onesided');
    [P_off, f2] = pwelch(y_off, ventana, noverlap, nfft, Fs, 'onesided');

    if numel(f) ~= numel(f2) || max(abs(f - f2)) > 1e-6
        error('Las grillas de frecuencia ON/OFF no coinciden en repeticion %d.', r);
    end

    P_on_dB = 10*log10(P_on + eps);
    P_off_dB = 10*log10(P_off + eps);

    score_dB = P_on_dB - P_off_dB;

    PSD_ON_dB{r} = P_on_dB;
    PSD_OFF_dB{r} = P_off_dB;
    score_rep_dB{r} = score_dB;

    if isempty(f_ref)
        f_ref = f(:);
    else
        if numel(f_ref) ~= numel(f) || max(abs(f_ref - f(:))) > 1e-6
            error('La grilla de frecuencia cambio entre repeticiones.');
        end
    end

    fprintf('Rango f = %.3f Hz a %.3f MHz\n', min(f)/1e6, max(f)/1e6);
    fprintf('df aprox = %.3f Hz\n\n', mean(diff(f)));
end

%% ===================== MATRICES Y PROMEDIOS =====================

f_Hz = f_ref(:);
f_kHz = f_Hz / 1e3;
f_MHz = f_Hz / 1e6;

PSD_ON_mat = cell2mat(PSD_ON_dB');
PSD_OFF_mat = cell2mat(PSD_OFF_dB');
score_mat = cell2mat(score_rep_dB');

PSD_ON_prom = mean(PSD_ON_mat, 2, 'omitnan');
PSD_OFF_prom = mean(PSD_OFF_mat, 2, 'omitnan');
score_prom = mean(score_mat, 2, 'omitnan');

idx_banda = f_kHz >= fmin_kHz & f_kHz <= fmax_kHz;

if sum(idx_banda) == 0
    error('No hay puntos dentro de %.1f-%.1f kHz. Revisar Fs, nfft o unidades.', fmin_kHz, fmax_kHz);
end

%% ===================== DETECCION LOCAL POR LED =====================

resultados = table();

for i = 1:numel(fc_ref_kHz)

    fc_ref_actual = fc_ref_kHz(i);

    idx_local = idx_banda & ...
                f_kHz >= (fc_ref_actual - tol_kHz) & ...
                f_kHz <= (fc_ref_actual + tol_kHz);

    if sum(idx_local) == 0
        error('No hay puntos en ventana local para %s.', nombres_led{i});
    end

    f_local = f_kHz(idx_local);
    score_local = score_prom(idx_local);

    [score_max, idx_max_local] = max(score_local);

    fc_det_kHz = f_local(idx_max_local);

    idx_global = find(idx_local);
    idx_fc = idx_global(idx_max_local);

    ON_val = PSD_ON_prom(idx_fc);
    OFF_val = PSD_OFF_prom(idx_fc);

    score_reps_en_fc = score_mat(idx_fc, :);

    rep_0dB = sum(score_reps_en_fc > 0);
    rep_3dB = sum(score_reps_en_fc >= criterio_dB);
    rep_total = num_reps;

    if score_max >= criterio_dB
        supera_3dB = "Si";
    else
        supera_3dB = "No";
    end

    err_kHz = abs(fc_det_kHz - fc_ref_actual);
    err_pct = 100 * err_kHz / fc_ref_actual;

    nueva_fila = table( ...
        string(nombres_led{i}), ...
        fc_ref_actual, ...
        fc_det_kHz, ...
        score_max, ...
        ON_val, ...
        OFF_val, ...
        rep_0dB, ...
        rep_3dB, ...
        rep_total, ...
        supera_3dB, ...
        err_kHz, ...
        err_pct, ...
        'VariableNames', {'LED','fc_ref_kHz','fc_det_kHz','score_dB','ON_dB','OFF_dB','rep_0dB','rep_3dB','rep_total','supera_3dB','err_kHz','err_pct'} ...
    );

    resultados = [resultados; nueva_fila];

end

fprintf('\n============================================================\n');
fprintf('FRECUENCIAS DETECTADAS - WELCH AMBOS LEDS\n');
fprintf('============================================================\n');
disp(resultados);

%% ===================== CANDIDATOS GLOBALES INFORMATIVOS =====================

f_b = f_kHz(idx_banda);
score_b = score_prom(idx_banda);

score_suav = movmean(score_b, 5, 'omitnan');

min_dist_kHz = 0.5;
df_kHz = mean(diff(f_b));
min_dist_pts = max(1, round(min_dist_kHz / df_kHz));

try
    [pks, locs] = findpeaks(score_suav, ...
        'MinPeakDistance', min_dist_pts, ...
        'SortStr', 'descend');
catch
    [pks, locs] = findpeaks(score_suav);
    [pks, orden] = sort(pks, 'descend');
    locs = locs(orden);
end

num_candidatos = min(num_candidatos_globales, numel(pks));

fc_glob_kHz = zeros(num_candidatos, 1);
score_glob = zeros(num_candidatos, 1);
ON_glob = zeros(num_candidatos, 1);
OFF_glob = zeros(num_candidatos, 1);
rep0_glob = zeros(num_candidatos, 1);
rep3_glob = zeros(num_candidatos, 1);
rep_total_glob = num_reps * ones(num_candidatos, 1);
supera_glob = strings(num_candidatos, 1);

idx_banda_global = find(idx_banda);

for c = 1:num_candidatos

    idx_c_banda = locs(c);
    idx_c_global = idx_banda_global(idx_c_banda);

    fc_glob_kHz(c) = f_kHz(idx_c_global);
    score_glob(c) = score_prom(idx_c_global);
    ON_glob(c) = PSD_ON_prom(idx_c_global);
    OFF_glob(c) = PSD_OFF_prom(idx_c_global);

    scores_reps = score_mat(idx_c_global, :);

    rep0_glob(c) = sum(scores_reps > 0);
    rep3_glob(c) = sum(scores_reps >= criterio_dB);

    if score_glob(c) >= criterio_dB
        supera_glob(c) = "Si";
    else
        supera_glob(c) = "No";
    end
end

tabla_global = table( ...
    fc_glob_kHz, ...
    score_glob, ...
    ON_glob, ...
    OFF_glob, ...
    rep0_glob, ...
    rep3_glob, ...
    rep_total_glob, ...
    supera_glob, ...
    'VariableNames', {'fc_kHz','score_peak','ON_dB','OFF_dB','rep_0dB','rep_3dB','rep_total','supera_3dB'} ...
);

tabla_global_fig = tabla_global;

for i = 1:height(resultados)

    fc_local = resultados.fc_det_kHz(i);

    existe = any(abs(tabla_global_fig.fc_kHz - fc_local) < 0.05);

    if ~existe
        nueva_fila = table( ...
            resultados.fc_det_kHz(i), ...
            resultados.score_dB(i), ...
            resultados.ON_dB(i), ...
            resultados.OFF_dB(i), ...
            resultados.rep_0dB(i), ...
            resultados.rep_3dB(i), ...
            resultados.rep_total(i), ...
            resultados.supera_3dB(i), ...
            'VariableNames', {'fc_kHz','score_peak','ON_dB','OFF_dB','rep_0dB','rep_3dB','rep_total','supera_3dB'} ...
        );

        tabla_global_fig = [tabla_global_fig; nueva_fila];
    end
end

tabla_global_fig = sortrows(tabla_global_fig, 'score_peak', 'descend');

fprintf('\n============================================================\n');
fprintf('CANDIDATOS GLOBALES INFORMATIVOS - NO USADOS COMO FC FINAL\n');
fprintf('============================================================\n');
disp(tabla_global_fig);

%% ===================== GUARDAR DATOS =====================

archivo_mat = fullfile(carpeta_salida, 'datos_welch_Ambos_LEDS.mat');
save(archivo_mat, ...
    'f_Hz', 'f_kHz', 'f_MHz', ...
    'PSD_ON_mat', 'PSD_OFF_mat', 'score_mat', ...
    'PSD_ON_prom', 'PSD_OFF_prom', 'score_prom', ...
    'resultados', 'tabla_global', 'tabla_global_fig', ...
    'fc_ref_kHz', 'tol_kHz', 'criterio_dB', ...
    'Nseg', 'noverlap', 'nfft', ...
    '-v7.3');

writetable(resultados, fullfile(carpeta_salida, 'tabla_resultados_welch_Ambos_LEDS.csv'));
writetable(tabla_global_fig, fullfile(carpeta_salida, 'tabla_candidatos_globales_welch_Ambos_LEDS.csv'));

%% ===================== GRAFICAS =====================

%% Figura 1: frecuencias detectadas por LED

fig1 = figure('Color','w','Position',[100 100 1400 800]);

b = bar(resultados.score_dB, 0.65);
b.FaceColor = 'flat';
b.EdgeColor = 'k';
b.CData = [
    c_led1
    c_led2
];

grid on;
box on;

ylabel('Score local ON-OFF [dB]');
xlabel('Componente');
title('Ambos LEDS - Welch: frecuencias detectadas por LED', ...
    'Interpreter','none');

set(gca, 'XTick', 1:height(resultados), 'XTickLabel', resultados.LED);

yline(criterio_dB, '--', sprintf('Criterio %.1f dB', criterio_dB), ...
    'Color',[0.45 0.45 0.45], ...
    'LineWidth',1.1, ...
    'LabelHorizontalAlignment','right');

for i = 1:height(resultados)
    txt = sprintf('%.3f kHz\n%.2f dB\n%d/%d\n%s', ...
        resultados.fc_det_kHz(i), ...
        resultados.score_dB(i), ...
        resultados.rep_3dB(i), ...
        resultados.rep_total(i), ...
        resultados.supera_3dB(i));

    text(i, resultados.score_dB(i) + 0.25, txt, ...
        'HorizontalAlignment','center', ...
        'VerticalAlignment','bottom', ...
        'FontSize',11);
end

ylim([0 max([criterio_dB + 1; resultados.score_dB + 3.6])]);

guardar_figura_local(fig1, carpeta_salida, '01_Ambos_LEDS_welch_frecuencias_detectadas');

%% Figura 2: candidatos globales informativos

fig2 = figure('Color','w','Position',[100 100 1500 850]);

colores_candidatos = repmat(c_neutro, height(tabla_global_fig), 1);

for i = 1:height(tabla_global_fig)
    if abs(tabla_global_fig.fc_kHz(i) - fc_ref_LED1_kHz) <= tol_kHz
        colores_candidatos(i,:) = c_led1;
    elseif abs(tabla_global_fig.fc_kHz(i) - fc_ref_LED2_kHz) <= tol_kHz
        colores_candidatos(i,:) = c_led2;
    end
end

b = bar(tabla_global_fig.score_peak, 0.68);
b.FaceColor = 'flat';
b.EdgeColor = 'k';
b.CData = colores_candidatos;

grid on;
box on;

ylabel('Score local ON-OFF [dB]');
xlabel('Frecuencia candidata [kHz]');
title('Ambos LEDS - Welch: candidatos globales informativos', ...
    'Interpreter','none');

set(gca, ...
    'XTick', 1:height(tabla_global_fig), ...
    'XTickLabel', compose('%.3f', tabla_global_fig.fc_kHz), ...
    'XTickLabelRotation', 45);

yline(criterio_dB, '--', sprintf('Criterio %.1f dB', criterio_dB), ...
    'Color',[0.45 0.45 0.45], ...
    'LineWidth',1.1, ...
    'LabelHorizontalAlignment','right');

for i = 1:height(tabla_global_fig)
    txt = sprintf('%.2f dB\n%d/%d', ...
        tabla_global_fig.score_peak(i), ...
        tabla_global_fig.rep_3dB(i), ...
        tabla_global_fig.rep_total(i));

    text(i, tabla_global_fig.score_peak(i) + 0.12, txt, ...
        'HorizontalAlignment','center', ...
        'VerticalAlignment','bottom', ...
        'FontSize',10);
end

ylim([0 max([criterio_dB + 1; tabla_global_fig.score_peak + 3.6])]);

hold on;
h_led1 = bar(nan, nan, 'FaceColor', c_led1, 'EdgeColor','k');
h_led2 = bar(nan, nan, 'FaceColor', c_led2, 'EdgeColor','k');
h_otro = bar(nan, nan, 'FaceColor', c_neutro, 'EdgeColor','k');

legend([h_led1 h_led2 h_otro], ...
    {'Candidato asociado a LED 1', ...
     'Candidato asociado a LED 2', ...
     'Candidato global informativo'}, ...
    'Location','northeast');

guardar_figura_local(fig2, carpeta_salida, '02_Ambos_LEDS_welch_candidatos_globales');

%% Figura 3: PSD promedio ON/OFF en banda

fig3 = figure('Color','w','Position',[100 100 1500 850]);

plot(f_kHz(idx_banda), PSD_ON_prom(idx_banda), ...
    'LineWidth', 1.0, ...
    'Color', [0.0000 0.4470 0.7410]);
hold on;

plot(f_kHz(idx_banda), PSD_OFF_prom(idx_banda), ...
    'LineWidth', 1.0, ...
    'Color', [0.8500 0.3250 0.0980]);

grid on;
box on;

xlabel('Frecuencia [kHz]');
ylabel('PSD Welch [dB/Hz]');
title('Ambos LEDS - Welch: PSD promedio ON/OFF en banda de analisis', ...
    'Interpreter','none');

legend({'LED encendido','LED apagado'}, 'Location','best');

for i = 1:height(resultados)

    if resultados.LED(i) == "LED 1"
        color_linea = c_led1;
    else
        color_linea = c_led2;
    end

    xline(resultados.fc_det_kHz(i), '--', ...
        sprintf('%s %.3f kHz', resultados.LED(i), resultados.fc_det_kHz(i)), ...
        'Color', color_linea, ...
        'LineWidth', 1.8, ...
        'LabelOrientation','horizontal', ...
        'LabelVerticalAlignment','top', ...
        'LabelHorizontalAlignment','center', ...
        'HandleVisibility','off');
end

xlim([fmin_kHz fmax_kHz]);

guardar_figura_local(fig3, carpeta_salida, '03_Ambos_LEDS_welch_PSD_promedio_ON_OFF_banda');

%% Figura 4: PSD promedio ON/OFF rango amplio

fig4 = figure('Color','w','Position',[100 100 1500 850]);

plot(f_MHz, PSD_ON_prom, ...
    'LineWidth', 1.0, ...
    'Color', [0.0000 0.4470 0.7410]);
hold on;

plot(f_MHz, PSD_OFF_prom, ...
    'LineWidth', 1.0, ...
    'Color', [0.8500 0.3250 0.0980]);

grid on;
box on;

xlabel('Frecuencia [MHz]');
ylabel('PSD Welch [dB/Hz]');
title('Ambos LEDS - Welch: PSD promedio ON/OFF, rango amplio', ...
    'Interpreter','none');

legend({'LED encendido','LED apagado'}, 'Location','best');

xlim([0 5]);

guardar_figura_local(fig4, carpeta_salida, '04_Ambos_LEDS_welch_PSD_promedio_ON_OFF_rango_amplio');

%% Figura 5: repeticiones OFF en banda

fig5 = figure('Color','w','Position',[100 100 1500 850]);
hold on;

for r = 1:num_reps
    plot(f_kHz(idx_banda), PSD_OFF_mat(idx_banda, r), 'LineWidth', 0.8);
end

grid on;
box on;

xlabel('Frecuencia [kHz]');
ylabel('PSD Welch [dB/Hz]');
title('Ambos LEDS - Welch: repeticiones OFF en banda de analisis', ...
    'Interpreter','none');

legend({'OFF rep 1','OFF rep 2','OFF rep 3','OFF rep 4'}, 'Location','best');

xlim([fmin_kHz fmax_kHz]);

guardar_figura_local(fig5, carpeta_salida, '05_Ambos_LEDS_welch_repeticiones_OFF_banda');

%% Figura 6: repeticiones ON en banda

fig6 = figure('Color','w','Position',[100 100 1500 850]);
hold on;

for r = 1:num_reps
    plot(f_kHz(idx_banda), PSD_ON_mat(idx_banda, r), 'LineWidth', 0.8);
end

grid on;
box on;

xlabel('Frecuencia [kHz]');
ylabel('PSD Welch [dB/Hz]');
title('Ambos LEDS - Welch: repeticiones ON en banda de analisis', ...
    'Interpreter','none');

legend({'ON rep 1','ON rep 2','ON rep 3','ON rep 4'}, 'Location','best');

xlim([fmin_kHz fmax_kHz]);

guardar_figura_local(fig6, carpeta_salida, '06_Ambos_LEDS_welch_repeticiones_ON_banda');

%% Figura 7: score ON-OFF en banda

fig7 = figure('Color','w','Position',[100 100 1500 850]);

plot(f_kHz(idx_banda), score_prom(idx_banda), ...
    'LineWidth', 1.0, ...
    'Color', [0.0000 0.4470 0.7410]);

grid on;
box on;
hold on;

xlabel('Frecuencia [kHz]');
ylabel('Score ON - OFF [dB]');
title('Ambos LEDS - Welch: score ON-OFF en banda de analisis', ...
    'Interpreter','none');

yline(0, '--', '0 dB', ...
    'Color',[0.45 0.45 0.45], ...
    'LineWidth',1.1, ...
    'LabelHorizontalAlignment','right');

yline(criterio_dB, '--', sprintf('Criterio %.1f dB', criterio_dB), ...
    'Color',[0.35 0.35 0.35], ...
    'LineWidth',1.4, ...
    'LabelHorizontalAlignment','right');

yl = ylim;
dy = range(yl);

for i = 1:height(resultados)

    if resultados.LED(i) == "LED 1"
        color_linea = c_led1;
        x_offset = 0.25;
    else
        color_linea = c_led2;
        x_offset = -0.25;
    end

    xline(resultados.fc_det_kHz(i), '--', ...
        'Color', color_linea, ...
        'LineWidth', 2.3, ...
        'HandleVisibility','off');

    text(resultados.fc_det_kHz(i) + x_offset, yl(2) - 0.03*dy, ...
        sprintf('%s\n%.3f kHz', resultados.LED(i), resultados.fc_det_kHz(i)), ...
        'HorizontalAlignment','center', ...
        'VerticalAlignment','top', ...
        'FontWeight','bold', ...
        'FontSize',10, ...
        'BackgroundColor','w', ...
        'Margin',0.5, ...
        'Color',[0.1 0.1 0.1]);
end

xlim([fmin_kHz fmax_kHz]);

guardar_figura_local(fig7, carpeta_salida, '07_Ambos_LEDS_welch_score_ON_OFF_banda');

%% Figura 8: tabla resultados principales

tabla_resultados_fig = resultados;
tabla_resultados_fig.LED = string(tabla_resultados_fig.LED);
tabla_resultados_fig.supera_3dB = string(tabla_resultados_fig.supera_3dB);

fig8 = crear_tabla_figura_local( ...
    tabla_resultados_fig, ...
    'TABLA RESULTADOS WELCH AMBOS LEDS', ...
    [1450 300]);

guardar_figura_local(fig8, carpeta_salida, '08_Tabla_resultados_welch_Ambos_LEDS');

%% Figura 9: tabla candidatos globales

tabla_candidatos_img = tabla_global_fig;
tabla_candidatos_img.supera_3dB = string(tabla_candidatos_img.supera_3dB);

fig9 = crear_tabla_figura_local( ...
    tabla_candidatos_img, ...
    'TABLA CANDIDATOS GLOBALES WELCH AMBOS LEDS', ...
    [1250 600]);

guardar_figura_local(fig9, carpeta_salida, '09_Tabla_candidatos_globales_welch_Ambos_LEDS');

%% ===================== FINAL =====================

fprintf('\n============================================================\n');
fprintf('ANALISIS WELCH AMBOS LEDS FINALIZADO\n');
fprintf('Resultados guardados en:\n%s\n', carpeta_salida);
fprintf('============================================================\n');

%% ===================== FUNCIONES LOCALES =====================

function [t, y] = leer_csv_rigol_robusto_local(nombre_archivo, Nmax)

    fid = fopen(nombre_archivo, 'r');

    if fid < 0
        error('No se pudo abrir el archivo:\n%s', nombre_archivo);
    end

    data_line = [];
    ncols = [];

    max_lineas_revision = 300;

    for k = 1:max_lineas_revision
        linea = fgetl(fid);

        if ~ischar(linea)
            break;
        end

        linea_limpia = strtrim(linea);

        if isempty(linea_limpia)
            continue;
        end

        partes = strsplit(linea_limpia, ',');

        nums = nan(1, numel(partes));

        for p = 1:numel(partes)
            valor = str2double(strtrim(partes{p}));
            nums(p) = valor;
        end

        if sum(isfinite(nums)) >= 2
            data_line = k;
            ncols = numel(partes);
            break;
        end
    end

    fclose(fid);

    if isempty(data_line)
        error('No se encontro inicio numerico de datos en:\n%s', nombre_archivo);
    end

    fid = fopen(nombre_archivo, 'r');

    formato = repmat('%f', 1, ncols);

    C = textscan(fid, formato, ...
        'Delimiter', ',', ...
        'HeaderLines', data_line - 1, ...
        'CollectOutput', true, ...
        'ReturnOnError', false);

    fclose(fid);

    A = C{1};

    if isempty(A) || size(A,2) < 2
        error('No se pudieron leer columnas numericas en:\n%s', nombre_archivo);
    end

    A = A(all(isfinite(A(:,1:2)), 2), :);

    t = A(:,1);

    y = A(:,2);

    if isfinite(Nmax)
        Nusar = min(numel(y), Nmax);
        t = t(1:Nusar);
        y = y(1:Nusar);
    end

    t = t(:);
    y = y(:);

    if numel(t) < 10 || numel(y) < 10
        error('Archivo con muy pocos datos validos:\n%s', nombre_archivo);
    end

    dt = diff(t);
    dt = dt(isfinite(dt) & dt > 0);

    if isempty(dt)
        error('El vector de tiempo no es valido en:\n%s', nombre_archivo);
    end
end

function Fs = calcular_Fs_local(t)

    t = t(:);
    dt = diff(t);
    dt = dt(isfinite(dt) & dt > 0);

    if isempty(dt)
        Fs = NaN;
        return;
    end

    dt_prom = mean(dt, 'omitnan');

    Fs = 1 / dt_prom;
end

function guardar_figura_local(fig, carpeta_salida, nombre_base)

    archivo_png = fullfile(carpeta_salida, [nombre_base '.png']);
    archivo_fig = fullfile(carpeta_salida, [nombre_base '.fig']);

    try
        exportgraphics(fig, archivo_png, 'Resolution', 200);
    catch
        saveas(fig, archivo_png);
    end
end

function fig = crear_tabla_figura_local(T, titulo_txt, tam_px)

    Tmostrar = preparar_tabla_para_uitable_local(T);

    nombres = string(Tmostrar.Properties.VariableNames);
    nombres = reemplazar_nombres_tabla_local(nombres);

    nfil = height(Tmostrar);
    ncol = width(Tmostrar);

    data = strings(nfil, ncol);

    for c = 1:ncol
        col = Tmostrar.(Tmostrar.Properties.VariableNames{c});

        for r = 1:nfil
            if iscell(col)
                data(r,c) = string(col{r});
            elseif isstring(col)
                data(r,c) = col(r);
            elseif isnumeric(col)
                data(r,c) = string(col(r));
            else
                data(r,c) = string(col(r));
            end
        end
    end

    if ncol >= 11
        ancho_col = 108;
    elseif ncol >= 8
        ancho_col = 122;
    else
        ancho_col = 135;
    end

    alto_fila = 36;
    alto_header = 38;
    margen_x = 25;
    margen_inf = 18;
    alto_titulo = 48;

    fig_w = max(tam_px(1), margen_x*2 + ancho_col*ncol);
    fig_h = max(tam_px(2), margen_inf + alto_titulo + alto_header + alto_fila*nfil + 10);

    fig = figure('Color','w', 'Position', [100 100 fig_w fig_h]);

    ax = axes('Parent', fig, ...
        'Units','pixels', ...
        'Position', [0 0 fig_w fig_h]);

    axis(ax, [0 fig_w 0 fig_h]);
    axis(ax, 'off');
    hold(ax, 'on');

    text(ax, fig_w/2, fig_h - 24, titulo_txt, ...
        'HorizontalAlignment','center', ...
        'VerticalAlignment','middle', ...
        'FontSize',18, ...
        'FontWeight','bold', ...
        'Interpreter','none');

    tabla_w = ancho_col*ncol;
    tabla_h = alto_header + alto_fila*nfil;

    x0 = (fig_w - tabla_w)/2;
    y0 = fig_h - alto_titulo;

    color_header = [0.86 0.86 0.86];
    color_fila_1 = [1 1 1];
    color_fila_2 = [0.92 0.92 0.92];
    color_borde = [0.65 0.65 0.65];

    for c = 1:ncol
        x = x0 + (c-1)*ancho_col;

        rectangle(ax, ...
            'Position', [x y0-alto_header ancho_col alto_header], ...
            'FaceColor', color_header, ...
            'EdgeColor', color_borde, ...
            'LineWidth', 1.0);

        text(ax, x + ancho_col/2, y0 - alto_header/2, nombres(c), ...
            'HorizontalAlignment','center', ...
            'VerticalAlignment','middle', ...
            'FontSize',10.3, ...
            'FontWeight','bold', ...
            'Interpreter','none');
    end

    for r = 1:nfil
        for c = 1:ncol

            x = x0 + (c-1)*ancho_col;
            y = y0 - alto_header - r*alto_fila;

            if mod(r,2) == 0
                color_fila = color_fila_2;
            else
                color_fila = color_fila_1;
            end

            rectangle(ax, ...
                'Position', [x y ancho_col alto_fila], ...
                'FaceColor', color_fila, ...
                'EdgeColor', [0.82 0.82 0.82], ...
                'LineWidth', 0.8);

            text(ax, x + ancho_col/2, y + alto_fila/2, data(r,c), ...
                'HorizontalAlignment','center', ...
                'VerticalAlignment','middle', ...
                'FontSize',9.8, ...
                'Interpreter','none');
        end
    end

    rectangle(ax, ...
        'Position', [x0 y0-tabla_h tabla_w tabla_h], ...
        'EdgeColor', color_borde, ...
        'LineWidth', 1.2);
end

function T2 = preparar_tabla_para_uitable_local(T)

    T2 = T;

    for c = 1:width(T2)

        varname = T2.Properties.VariableNames{c};
        x = T2.(varname);

        if isnumeric(x)
            if all(abs(x - round(x)) < 1e-10 | isnan(x))
                T2.(varname) = arrayfun(@(v) sprintf('%d', round(v)), x, 'UniformOutput', false);
            else
                T2.(varname) = arrayfun(@(v) sprintf('%.4f', v), x, 'UniformOutput', false);
            end

        elseif isstring(x)
            T2.(varname) = cellstr(x);

        elseif iscell(x)
            for r = 1:numel(x)
                if isnumeric(x{r})
                    x{r} = sprintf('%.4f', x{r});
                elseif isstring(x{r})
                    x{r} = char(x{r});
                end
            end
            T2.(varname) = x;
        end
    end
end

function nombres_out = reemplazar_nombres_tabla_local(nombres_in)

    nombres_out = nombres_in;

    for i = 1:numel(nombres_out)
        s = nombres_out(i);

        s = replace(s, "fc_ref_kHz", "fc_ref_kHz");
        s = replace(s, "fc_det_kHz", "fc_det_kHz");
        s = replace(s, "score_peak", "score_peak");
        s = replace(s, "score_dB", "score_dB");
        s = replace(s, "rep_total", "rep_total");
        s = replace(s, "supera_3dB", "supera_3dB");
        s = replace(s, "err_kHz", "err_kHz");
        s = replace(s, "err_pct", "err_pct");

        nombres_out(i) = s;
    end
end