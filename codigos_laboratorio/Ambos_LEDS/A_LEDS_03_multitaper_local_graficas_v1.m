%% A_LEDS_03_multitaper_local_graficas_v2.m
%
% INSTRUCCIONES DE USO
% Antes de ejecutar este script, revisar la variable carpeta_datos
% y modificarla si los archivos .csv se encuentran en otra ruta local.
% La carpeta indicada debe contener los archivos ON_ALEDS_REP*.csv
% y OFF_ALEDS_REP*.csv definidos en las variables nombre_base_ON,
% nombre_base_OFF y nRep.
%
% Ejemplo:
% carpeta_datos = 'C:\Users\NombreUsuario\Desktop\Prueba AMBOS LED';

clear; 
clc; 
close all;
%% ===================== CONFIGURACION GENERAL =====================

carpeta_datos = 'C:\Users\mudrood\Desktop\Modulo Prof\Archivos Tesis\Toma de Datos\Prueba AMBOS LED';

carpeta_salida = fullfile(carpeta_datos, 'Resultados_Ambos_LEDS_modificados', '03_Multitaper');
if ~exist(carpeta_salida, 'dir')
    mkdir(carpeta_salida);
end

nombre_base_ON  = 'ON_ALEDS_REP';
nombre_base_OFF = 'OFF_ALEDS_REP';

nRep = 4;

fc_ref_LED1_kHz = 56.513;
fc_ref_LED2_kHz = 44.926;

tol_kHz = 2.0;

fmin_banda_kHz = 30;
fmax_banda_kHz = 90;

criterio_dB = 3;

NW = 4;
nfft_min = 2^20;

Nmax = Inf;

usar_suavizado = true;
ventana_suavizado_kHz = 0.05;

c_led1 = [0.36 0.52 0.66];
c_led2 = [0.68 0.55 0.36]; 
c_neutro = [0.55 0.55 0.55]; 

fprintf('============================================================\n');
fprintf('MULTITAPER LOCAL - AMBOS LEDS\n');
fprintf('============================================================\n\n');

%% ===================== VARIABLES DE ALMACENAMIENTO =====================

f_banda_ref = [];

Pxx_ON_mat  = [];
Pxx_OFF_mat = [];
score_mat   = [];

Pxx_ON_all  = cell(nRep, 1);
Pxx_OFF_all = cell(nRep, 1);
score_all   = cell(nRep, 1);

%% ===================== PROCESAMIENTO POR REPETICION =====================

for r = 1:nRep

    archivoON  = fullfile(carpeta_datos, sprintf('%s%d.csv', nombre_base_ON, r));
    archivoOFF = fullfile(carpeta_datos, sprintf('%s%d.csv', nombre_base_OFF, r));

    fprintf('----------------------------------------\n');
    fprintf('Repeticion %d/%d\n', r, nRep);
    fprintf('ON : %s\n', archivoON);
    fprintf('OFF: %s\n', archivoOFF);

    [tON, xON]   = leer_csv_rigol_generico(archivoON);
    [tOFF, xOFF] = leer_csv_rigol_generico(archivoOFF);

    xON  = xON(:);
    xOFF = xOFF(:);
    tON  = tON(:);
    tOFF = tOFF(:);

    idxON = isfinite(tON) & isfinite(xON);
    idxOFF = isfinite(tOFF) & isfinite(xOFF);

    tON = tON(idxON);
    xON = xON(idxON);

    tOFF = tOFF(idxOFF);
    xOFF = xOFF(idxOFF);

    N = min(length(xON), length(xOFF));

    if isfinite(Nmax)
        N = min(N, Nmax);
    end

    xON = xON(1:N);
    xOFF = xOFF(1:N);
    tON = tON(1:N);
    tOFF = tOFF(1:N);

    dtON = diff(tON);
    dtON = dtON(isfinite(dtON) & dtON > 0);

    dtOFF = diff(tOFF);
    dtOFF = dtOFF(isfinite(dtOFF) & dtOFF > 0);

    FsON = 1 / mean(dtON, 'omitnan');
    FsOFF = 1 / mean(dtOFF, 'omitnan');

    Fs = mean([FsON FsOFF], 'omitnan');

    if ~isfinite(Fs) || Fs <= 0
        error('No se pudo estimar Fs en la repeticion %d. Revisar columnas de tiempo.', r);
    end

    fprintf('N usado = %d muestras\n', N);
    fprintf('Fs ON   = %.6f MSa/s\n', FsON/1e6);
    fprintf('Fs OFF  = %.6f MSa/s\n', FsOFF/1e6);
    fprintf('Fs usada = %.6f MSa/s\n', Fs/1e6);

    xON = xON - mean(xON, 'omitnan');
    xOFF = xOFF - mean(xOFF, 'omitnan');

    xON(~isfinite(xON)) = 0;
    xOFF(~isfinite(xOFF)) = 0;

    nfft = max(nfft_min, 2^nextpow2(N));

    fprintf('Multitaper rep %d:\n', r);
    fprintf('NW   = %.2f\n', NW);
    fprintf('nfft = %d muestras\n', nfft);

    [PxxON, f]  = pmtm(xON,  NW, nfft, Fs);
    [PxxOFF, ~] = pmtm(xOFF, NW, nfft, Fs);

    PxxON_dB  = 10*log10(PxxON + eps);
    PxxOFF_dB = 10*log10(PxxOFF + eps);

    f_kHz_rep = f / 1e3;

    idxBanda = f_kHz_rep >= fmin_banda_kHz & f_kHz_rep <= fmax_banda_kHz;

    f_banda = f_kHz_rep(idxBanda);
    ON_banda = PxxON_dB(idxBanda);
    OFF_banda = PxxOFF_dB(idxBanda);

    score = ON_banda - OFF_banda;

    if usar_suavizado
        df_kHz = median(diff(f_banda), 'omitnan');
        nSmooth = max(3, round(ventana_suavizado_kHz / df_kHz));
        score_proc = movmean(score, nSmooth, 'omitnan');
    else
        score_proc = score;
    end

    if isempty(f_banda_ref)
        f_banda_ref = f_banda(:);
        Pxx_ON_mat  = nan(length(f_banda_ref), nRep);
        Pxx_OFF_mat = nan(length(f_banda_ref), nRep);
        score_mat   = nan(length(f_banda_ref), nRep);
    end

    ON_interp    = interp1(f_banda, ON_banda, f_banda_ref, 'linear', NaN);
    OFF_interp   = interp1(f_banda, OFF_banda, f_banda_ref, 'linear', NaN);
    score_interp = interp1(f_banda, score_proc, f_banda_ref, 'linear', NaN);

    Pxx_ON_mat(:, r)  = ON_interp;
    Pxx_OFF_mat(:, r) = OFF_interp;
    score_mat(:, r)   = score_interp;

    Pxx_ON_all{r}  = ON_banda;
    Pxx_OFF_all{r} = OFF_banda;
    score_all{r}   = score_proc;

    fprintf('Rango f banda = %.3f a %.3f kHz\n', min(f_banda), max(f_banda));
    fprintf('df aprox = %.6f kHz\n\n', median(diff(f_banda), 'omitnan'));
end

%% ===================== PROMEDIOS ENTRE REPETICIONES =====================

ON_prom = mean(Pxx_ON_mat, 2, 'omitnan');
OFF_prom = mean(Pxx_OFF_mat, 2, 'omitnan');
score_prom = mean(score_mat, 2, 'omitnan');

f_kHz = f_banda_ref(:);

%% ===================== BUSQUEDA LOCAL POR LED =====================

refs_kHz = [fc_ref_LED1_kHz; fc_ref_LED2_kHz];
nLED = length(refs_kHz);

LED_nombre = strings(nLED, 1);
fc_ref_kHz = nan(nLED, 1);
fc_det_kHz = nan(nLED, 1);
score_dB = nan(nLED, 1);
ON_dB = nan(nLED, 1);
OFF_dB = nan(nLED, 1);
rep_0dB = nan(nLED, 1);
rep_3dB = nan(nLED, 1);
rep_total = nRep * ones(nLED, 1);
supera_3dB = strings(nLED, 1);
err_kHz = nan(nLED, 1);
err_pct = nan(nLED, 1);

for i = 1:nLED

    fc0 = refs_kHz(i);

    idxLocal = f_kHz >= (fc0 - tol_kHz) & f_kHz <= (fc0 + tol_kHz);

    if ~any(idxLocal)
        error('No hay puntos en la ventana local para LED %d.', i);
    end

    f_local = f_kHz(idxLocal);
    score_local = score_prom(idxLocal);

    [scoreMax, idxMaxLocal] = max(score_local);
    fcMax = f_local(idxMaxLocal);

    idxGlobal = find(abs(f_kHz - fcMax) == min(abs(f_kHz - fcMax)), 1);

    LED_nombre(i) = sprintf('LED %d', i);
    fc_ref_kHz(i) = fc0;
    fc_det_kHz(i) = fcMax;
    score_dB(i) = scoreMax;
    ON_dB(i) = ON_prom(idxGlobal);
    OFF_dB(i) = OFF_prom(idxGlobal);

    rep0 = 0;
    rep3 = 0;

    for r = 1:nRep
        score_rep = score_mat(:, r);
        val_rep = score_rep(idxGlobal);

        if isfinite(val_rep) && val_rep > 0
            rep0 = rep0 + 1;
        end

        if isfinite(val_rep) && val_rep >= criterio_dB
            rep3 = rep3 + 1;
        end
    end

    rep_0dB(i) = rep0;
    rep_3dB(i) = rep3;

    if scoreMax >= criterio_dB
        supera_3dB(i) = "Si";
    else
        supera_3dB(i) = "No";
    end

    err_kHz(i) = abs(fcMax - fc0);
    err_pct(i) = 100 * err_kHz(i) / fc0;
end

tabla_resultados = table(LED_nombre, fc_ref_kHz, fc_det_kHz, score_dB, ...
    ON_dB, OFF_dB, rep_0dB, rep_3dB, rep_total, supera_3dB, err_kHz, err_pct, ...
    'VariableNames', {'LED','fc_ref_kHz','fc_det_kHz','score_dB', ...
    'ON_dB','OFF_dB','rep_0dB','rep_3dB','rep_total','supera_3dB','err_kHz','err_pct'});

fprintf('\n============================================================\n');
fprintf('FRECUENCIAS DETECTADAS - MULTITAPER LOCAL AMBOS LEDS\n');
fprintf('============================================================\n');
disp(tabla_resultados);

%% ===================== CANDIDATOS GLOBALES INFORMATIVOS =====================

try
    [pks, locs] = findpeaks(score_prom, f_kHz, ...
        'MinPeakDistance', 0.3, ...
        'SortStr', 'descend');
catch
    [pks, idx_locs] = findpeaks(score_prom);
    locs = f_kHz(idx_locs);
    [pks, orden] = sort(pks, 'descend');
    locs = locs(orden);
end

nCand = min(10, length(pks));
pks = pks(1:nCand);
locs = locs(1:nCand);

ON_cand = nan(nCand, 1);
OFF_cand = nan(nCand, 1);
rep0_cand = nan(nCand, 1);
rep3_cand = nan(nCand, 1);
rep_total_cand = nRep * ones(nCand, 1);
supera_cand = strings(nCand, 1);

for k = 1:nCand

    idx = find(abs(f_kHz - locs(k)) == min(abs(f_kHz - locs(k))), 1);

    ON_cand(k) = ON_prom(idx);
    OFF_cand(k) = OFF_prom(idx);

    rep0 = 0;
    rep3 = 0;

    for r = 1:nRep
        val = score_mat(idx, r);

        if isfinite(val) && val > 0
            rep0 = rep0 + 1;
        end

        if isfinite(val) && val >= criterio_dB
            rep3 = rep3 + 1;
        end
    end

    rep0_cand(k) = rep0;
    rep3_cand(k) = rep3;

    if pks(k) >= criterio_dB
        supera_cand(k) = "Si";
    else
        supera_cand(k) = "No";
    end
end

tabla_candidatos = table(locs(:), pks(:), ON_cand, OFF_cand, ...
    rep0_cand, rep3_cand, rep_total_cand, supera_cand, ...
    'VariableNames', {'fc_kHz','score_peak','ON_dB','OFF_dB', ...
    'rep_0dB','rep_3dB','rep_total','supera_3dB'});

tabla_candidatos_fig = tabla_candidatos;

for i = 1:height(tabla_resultados)

    fc_local = tabla_resultados.fc_det_kHz(i);

    existe = any(abs(tabla_candidatos_fig.fc_kHz - fc_local) < 0.05);

    if ~existe
        nueva_fila = table( ...
            tabla_resultados.fc_det_kHz(i), ...
            tabla_resultados.score_dB(i), ...
            tabla_resultados.ON_dB(i), ...
            tabla_resultados.OFF_dB(i), ...
            tabla_resultados.rep_0dB(i), ...
            tabla_resultados.rep_3dB(i), ...
            tabla_resultados.rep_total(i), ...
            tabla_resultados.supera_3dB(i), ...
            'VariableNames', {'fc_kHz','score_peak','ON_dB','OFF_dB', ...
            'rep_0dB','rep_3dB','rep_total','supera_3dB'} ...
        );

        tabla_candidatos_fig = [tabla_candidatos_fig; nueva_fila];
    end
end

tabla_candidatos_fig = sortrows(tabla_candidatos_fig, 'score_peak', 'descend');

fprintf('\n============================================================\n');
fprintf('CANDIDATOS GLOBALES INFORMATIVOS - NO USADOS COMO FC FINAL\n');
fprintf('============================================================\n');
disp(tabla_candidatos_fig);

%% ===================== GUARDAR DATOS =====================

save(fullfile(carpeta_salida, 'datos_multitaper_ambos_leds.mat'), ...
    'f_kHz', 'ON_prom', 'OFF_prom', 'score_prom', ...
    'Pxx_ON_mat', 'Pxx_OFF_mat', 'score_mat', ...
    'tabla_resultados', 'tabla_candidatos', 'tabla_candidatos_fig', ...
    'fc_ref_LED1_kHz', 'fc_ref_LED2_kHz', 'tol_kHz', 'criterio_dB', 'NW', ...
    '-v7.3');

writetable(tabla_resultados, fullfile(carpeta_salida, 'tabla_resultados_multitaper_ambos_leds.csv'));
writetable(tabla_candidatos_fig, fullfile(carpeta_salida, 'tabla_candidatos_multitaper_ambos_leds.csv'));

%% ===================== GRAFICAS =====================

%% Figura 1: frecuencias detectadas por LED

fig1 = figure('Color','w','Position',[100 100 1400 800]);

b = bar(score_dB, 0.65);
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
title('Ambos LEDS - Multitaper: frecuencias detectadas por LED', ...
    'Interpreter','none');

set(gca, 'XTick', 1:nLED, 'XTickLabel', cellstr(LED_nombre));

yline(criterio_dB, '--', sprintf('Criterio %.1f dB', criterio_dB), ...
    'Color',[0.45 0.45 0.45], ...
    'LineWidth',1.1, ...
    'LabelHorizontalAlignment','right');

for i = 1:nLED
    txt = sprintf('%.3f kHz\n%.2f dB\n%d/%d\n%s', ...
        fc_det_kHz(i), score_dB(i), rep_3dB(i), rep_total(i), supera_3dB(i));

    text(i, score_dB(i) + 0.18, txt, ...
        'HorizontalAlignment','center', ...
        'VerticalAlignment','bottom', ...
        'FontSize',11);
end

ylim([0 max([criterio_dB + 1; score_dB + 1.2])]);

guardar_figura(fig1, carpeta_salida, 'A_LEDS_MT_01_frecuencias_detectadas');

%% Figura 2: candidatos globales informativos

fig2 = figure('Color','w','Position',[100 100 1500 850]);

colores_candidatos = repmat(c_neutro, height(tabla_candidatos_fig), 1);

for i = 1:height(tabla_candidatos_fig)

    if abs(tabla_candidatos_fig.fc_kHz(i) - fc_ref_LED1_kHz) <= tol_kHz
        colores_candidatos(i,:) = c_led1;

    elseif abs(tabla_candidatos_fig.fc_kHz(i) - fc_ref_LED2_kHz) <= tol_kHz
        colores_candidatos(i,:) = c_led2;
    end
end

b = bar(tabla_candidatos_fig.score_peak, 0.68);
b.FaceColor = 'flat';
b.EdgeColor = 'k';
b.CData = colores_candidatos;

grid on;
box on;

xlabel('Frecuencia candidata [kHz]');
ylabel('Score local ON-OFF [dB]');
title('Ambos LEDS - Multitaper: candidatos globales informativos', ...
    'Interpreter','none');

set(gca, ...
    'XTick', 1:height(tabla_candidatos_fig), ...
    'XTickLabel', compose('%.3f', tabla_candidatos_fig.fc_kHz), ...
    'XTickLabelRotation', 45);

yline(criterio_dB, '--', sprintf('Criterio %.1f dB', criterio_dB), ...
    'Color',[0.45 0.45 0.45], ...
    'LineWidth',1.1, ...
    'LabelHorizontalAlignment','right');

for k = 1:height(tabla_candidatos_fig)
    txt = sprintf('%.2f dB\n%d/%d', ...
        tabla_candidatos_fig.score_peak(k), ...
        tabla_candidatos_fig.rep_3dB(k), ...
        tabla_candidatos_fig.rep_total(k));

    text(k, tabla_candidatos_fig.score_peak(k) + 0.06, txt, ...
        'HorizontalAlignment','center', ...
        'VerticalAlignment','bottom', ...
        'FontSize',9.5);
end

ylim([0 max([criterio_dB + 1; tabla_candidatos_fig.score_peak + 0.75])]);

hold on;
h_led1 = bar(nan, nan, 'FaceColor', c_led1, 'EdgeColor','k');
h_led2 = bar(nan, nan, 'FaceColor', c_led2, 'EdgeColor','k');
h_otro = bar(nan, nan, 'FaceColor', c_neutro, 'EdgeColor','k');

legend([h_led1 h_led2 h_otro], ...
    {'Candidato en ventana LED 1', ...
     'Candidato en ventana LED 2', ...
     'Candidato global informativo'}, ...
    'Location','northeast');

guardar_figura(fig2, carpeta_salida, 'A_LEDS_MT_02_candidatos_globales');

%% Figura 3: PSD promedio ON/OFF en banda

fig3 = figure('Color','w','Position',[100 100 1500 850]);

plot(f_kHz, ON_prom, ...
    'LineWidth', 1.0, ...
    'Color', [0.0000 0.4470 0.7410]);
hold on;

plot(f_kHz, OFF_prom, ...
    'LineWidth', 1.0, ...
    'Color', [0.8500 0.3250 0.0980]);

grid on;
box on;

xlabel('Frecuencia [kHz]');
ylabel('PSD Multitaper [dB/Hz]');
title('Ambos LEDS - Multitaper: PSD promedio ON/OFF en banda de analisis', ...
    'Interpreter','none');

legend({'LED encendido','LED apagado'}, 'Location','best');

yl = ylim;
dy = range(yl);

for i = 1:nLED

    if LED_nombre(i) == "LED 1"
        color_linea = c_led1;
        x_offset = 0.25;
    else
        color_linea = c_led2;
        x_offset = -0.25;
    end

    xline(fc_det_kHz(i), '--', ...
        'Color', color_linea, ...
        'LineWidth', 2.1, ...
        'HandleVisibility','off');

    text(fc_det_kHz(i) + x_offset, yl(2) - 0.02*dy, ...
        sprintf('%s %.3f kHz', LED_nombre(i), fc_det_kHz(i)), ...
        'HorizontalAlignment','center', ...
        'VerticalAlignment','top', ...
        'FontWeight','bold', ...
        'FontSize',10, ...
        'Color', color_linea, ...
        'BackgroundColor','w', ...
        'Margin',0.5);
end

xlim([fmin_banda_kHz fmax_banda_kHz]);

guardar_figura(fig3, carpeta_salida, 'A_LEDS_MT_03_PSD_promedio_banda');

%% Figura 4: score ON-OFF en banda

fig4 = figure('Color','w','Position',[100 100 1500 850]);

plot(f_kHz, score_prom, ...
    'LineWidth', 1.0, ...
    'Color', [0.0000 0.4470 0.7410]);

grid on;
box on;
hold on;

xlabel('Frecuencia [kHz]');
ylabel('Score ON - OFF [dB]');
title('Ambos LEDS - Multitaper: score ON-OFF en banda de analisis', ...
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

for i = 1:nLED

    if LED_nombre(i) == "LED 1"
        color_linea = c_led1;
        x_offset = 0.25;
    else
        color_linea = c_led2;
        x_offset = -0.25;
    end

    xline(fc_det_kHz(i), '--', ...
        'Color', color_linea, ...
        'LineWidth', 2.3, ...
        'HandleVisibility','off');

    text(fc_det_kHz(i) + x_offset, yl(2) - 0.04*dy, ...
        sprintf('%s\n%.3f kHz', LED_nombre(i), fc_det_kHz(i)), ...
        'HorizontalAlignment','center', ...
        'VerticalAlignment','top', ...
        'FontWeight','bold', ...
        'FontSize',10, ...
        'Color',[0.1 0.1 0.1], ...
        'BackgroundColor','w', ...
        'Margin',0.5);
end

xlim([fmin_banda_kHz fmax_banda_kHz]);

guardar_figura(fig4, carpeta_salida, 'A_LEDS_MT_04_score_banda');

%% Figura 5: repeticiones ON en banda

fig5 = figure('Color','w','Position',[100 100 1500 850]);

hold on;
for r = 1:nRep
    plot(f_kHz, Pxx_ON_mat(:,r), 'LineWidth', 0.9);
end

grid on;
box on;

xlabel('Frecuencia [kHz]');
ylabel('PSD Multitaper [dB/Hz]');
title('Ambos LEDS - Multitaper: repeticiones ON en banda de analisis', ...
    'Interpreter','none');

legend({'ON rep 1','ON rep 2','ON rep 3','ON rep 4'}, 'Location','best');

xlim([fmin_banda_kHz fmax_banda_kHz]);

guardar_figura(fig5, carpeta_salida, 'A_LEDS_MT_05_repeticiones_ON');

%% Figura 6: repeticiones OFF en banda

fig6 = figure('Color','w','Position',[100 100 1500 850]);

hold on;
for r = 1:nRep
    plot(f_kHz, Pxx_OFF_mat(:,r), 'LineWidth', 0.9);
end

grid on;
box on;

xlabel('Frecuencia [kHz]');
ylabel('PSD Multitaper [dB/Hz]');
title('Ambos LEDS - Multitaper: repeticiones OFF en banda de analisis', ...
    'Interpreter','none');

legend({'OFF rep 1','OFF rep 2','OFF rep 3','OFF rep 4'}, 'Location','best');

xlim([fmin_banda_kHz fmax_banda_kHz]);

guardar_figura(fig6, carpeta_salida, 'A_LEDS_MT_06_repeticiones_OFF');

%% Figura 7: tabla resultados principales

tabla_resultados_img = tabla_resultados;
tabla_resultados_img.LED = string(tabla_resultados_img.LED);
tabla_resultados_img.supera_3dB = string(tabla_resultados_img.supera_3dB);

fig7 = crear_tabla_figura_local( ...
    tabla_resultados_img, ...
    'TABLA RESULTADOS MULTITAPER AMBOS LEDS', ...
    [1450 300]);

guardar_figura(fig7, carpeta_salida, 'A_LEDS_MT_07_tabla_resultados');

%% Figura 8: tabla candidatos globales

tabla_candidatos_img = tabla_candidatos_fig;
tabla_candidatos_img.supera_3dB = string(tabla_candidatos_img.supera_3dB);

fig8 = crear_tabla_figura_local( ...
    tabla_candidatos_img, ...
    'TABLA CANDIDATOS GLOBALES MULTITAPER AMBOS LEDS', ...
    [1250 600]);

guardar_figura(fig8, carpeta_salida, 'A_LEDS_MT_08_tabla_candidatos');

%% ===================== FINAL =====================

fprintf('\n============================================================\n');
fprintf('Proceso terminado correctamente.\n');
fprintf('Resultados guardados en:\n%s\n', carpeta_salida);
fprintf('============================================================\n');

%% ========================================================================
%% FUNCIONES LOCALES
%% ========================================================================

function [t, x] = leer_csv_rigol_generico(nombre_archivo)

    if ~exist(nombre_archivo, 'file')
        error('No existe el archivo: %s', nombre_archivo);
    end

    C = readcell(nombre_archivo);

    nFilas = size(C,1);
    nCols  = size(C,2);

    M = NaN(nFilas, nCols);

    for i = 1:nFilas
        for j = 1:nCols

            val = C{i,j};

            if isnumeric(val)
                M(i,j) = val;

            elseif ischar(val) || isstring(val)
                txt = string(val);
                txt = strrep(txt, ',', '.');
                num = str2double(txt);

                if isfinite(num)
                    M(i,j) = num;
                end
            end
        end
    end

    filas_validas = any(isfinite(M), 2);
    M = M(filas_validas, :);

    cols_validas = false(1, size(M,2));

    for j = 1:size(M,2)
        cols_validas(j) = sum(isfinite(M(:,j))) > 10;
    end

    M = M(:, cols_validas);

    if size(M,2) < 2
        error('El archivo %s no tiene al menos dos columnas numericas utiles.', nombre_archivo);
    end

    t = M(:,1);
    x = M(:,2);

    idx = isfinite(t) & isfinite(x);

    t = t(idx);
    x = x(idx);

    t = t(:);
    x = x(:);

    if length(t) < 100 || length(x) < 100
        error('El archivo %s tiene muy pocos datos numericos despues de limpiar.', nombre_archivo);
    end
end

function guardar_figura(fig, carpeta_salida, nombre)

    archivo_png = fullfile(carpeta_salida, [nombre '.png']);
    archivo_fig = fullfile(carpeta_salida, [nombre '.fig']);

    try
        exportgraphics(fig, archivo_png, 'Resolution', 200);
    catch
        saveas(fig, archivo_png);
    end
end

function fig = crear_tabla_figura_local(T, titulo_txt, tam_px)

    Tmostrar = preparar_tabla_para_figure_local(T);

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

function T2 = preparar_tabla_para_figure_local(T)

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