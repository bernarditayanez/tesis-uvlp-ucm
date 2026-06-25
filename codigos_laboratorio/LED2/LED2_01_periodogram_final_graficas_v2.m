%% LED2_01_periodogram_final_graficas_v2.m
%
% INSTRUCCIONES DE USO
% Antes de ejecutar este script, revisar la variable carpeta_csv
% y modificarla si los archivos .csv se encuentran en otra ruta local.
% La carpeta indicada debe contener los archivos ON_LED2_rep*.csv
% y OFF_LED2_rep*.csv definidos en las listas archivos_ON
% y archivos_OFF.
%
% Ejemplo:
% carpeta_csv = 'C:\Users\NombreUsuario\Desktop\Pruebas LED 2';

clear; 
clc; 
close all;
%% 1. Configuracion del experimento

carpeta_csv = 'C:\Users\mudrood\Desktop\Modulo Prof\Archivos Tesis\Toma de Datos\Pruebas LED 2';

carpeta_general = fullfile(carpeta_csv, 'Resultados_LED2_modificados');
carpeta_salida = fullfile(carpeta_general, '01_Periodogram');

if ~exist(carpeta_general, 'dir')
    mkdir(carpeta_general);
end

if ~exist(carpeta_salida, 'dir')
    mkdir(carpeta_salida);
end

archivos_ON = {
    'ON_LED2_rep1.csv'
    'ON_LED2_rep2.csv'
    'ON_LED2_rep3.csv'
    'ON_LED2_rep4.csv'
};

archivos_OFF = {
    'OFF_LED2_rep1.csv'
    'OFF_LED2_rep2.csv'
    'OFF_LED2_rep3.csv'
    'OFF_LED2_rep4.csv'
};

nrep = numel(archivos_ON);

fmin = 30e3;
fmax = 90e3;

num_candidatos = 7;
distancia_minima_Hz = 300;
ventana_local_Hz = 200;

umbralScore_dB = 3;

%% 2. Lectura y calculo del Periodograma

P_ON = [];
P_OFF = [];
info_archivos = table();

fprintf('\n============================================\n');
fprintf('PERIODOGRAM LED 2 - GRAFICAS V2\n');
fprintf('============================================\n');
fprintf('Carpeta entrada:\n%s\n', carpeta_csv);
fprintf('\nCarpeta salida:\n%s\n', carpeta_salida);

for k = 1:nrep

    archivo_on = fullfile(carpeta_csv, archivos_ON{k});
    archivo_off = fullfile(carpeta_csv, archivos_OFF{k});

    [t_on, y_on] = leer_csv_rigol_simple_local(archivo_on);
    [t_off, y_off] = leer_csv_rigol_simple_local(archivo_off);

    Fs = 1 / median(diff(t_on));

    Fs_mean_on = 1 / mean(diff(t_on));
    Fs_median_on = 1 / median(diff(t_on));
    Fs_mean_off = 1 / mean(diff(t_off));
    Fs_median_off = 1 / median(diff(t_off));

    N_on = numel(y_on);
    N_off = numel(y_off);

    N = N_on;

    T_on = t_on(end) - t_on(1);
    T_off = t_off(end) - t_off(1);

    fprintf('\n--------------------------------------------\n');
    fprintf('Repeticion %d/%d\n', k, nrep);
    fprintf('ON : %s\n', archivos_ON{k});
    fprintf('OFF: %s\n', archivos_OFF{k});
    fprintf('N ON  = %d muestras\n', N_on);
    fprintf('N OFF = %d muestras\n', N_off);
    fprintf('Fs usada = %.6f MSa/s\n', Fs/1e6);
    fprintf('Fs ON mean   = %.6f MSa/s\n', Fs_mean_on/1e6);
    fprintf('Fs ON median = %.6f MSa/s\n', Fs_median_on/1e6);
    fprintf('Fs OFF mean   = %.6f MSa/s\n', Fs_mean_off/1e6);
    fprintf('Fs OFF median = %.6f MSa/s\n', Fs_median_off/1e6);
    fprintf('T ON  = %.9f s\n', T_on);
    fprintf('T OFF = %.9f s\n', T_off);
    fprintf('df grilla = %.6f Hz\n', Fs/N);

    info_archivos = [info_archivos; crear_fila_info( ...
        string(archivos_ON{k}), "ON", k, N_on, Fs_mean_on, Fs_median_on, T_on)];

    info_archivos = [info_archivos; crear_fila_info( ...
        string(archivos_OFF{k}), "OFF", k, N_off, Fs_mean_off, Fs_median_off, T_off)];

    if N_on ~= N_off
        warning('La repeticion %d tiene distinto numero de muestras ON/OFF.', k);
    end

    ventana = hann(N);

    [Pxx_on, f] = periodogram(y_on, ventana, N, Fs);
    [Pxx_off, f_off] = periodogram(y_off, ventana, N, Fs);

    if numel(f) ~= numel(f_off) || max(abs(f - f_off)) > 1e-9
        error('La grilla de frecuencia ON/OFF no coincide en la repeticion %d.', k);
    end

    P_ON(:,k) = 10*log10(Pxx_on + eps);
    P_OFF(:,k) = 10*log10(Pxx_off + eps);
end

%% 3. Promedio entre repeticiones

P_ON_prom = mean(P_ON, 2);
P_OFF_prom = mean(P_OFF, 2);

score_prom = P_ON_prom - P_OFF_prom;
score_rep = P_ON - P_OFF;

%% 4. Busqueda de candidatos

idx_rango = f >= fmin & f <= fmax;

f_rango = f(idx_rango);
P_ON_rango = P_ON_prom(idx_rango);
P_OFF_rango = P_OFF_prom(idx_rango);
score_rango = score_prom(idx_rango);

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

    warning('No se encontraron candidatos positivos en el rango %.1f-%.1f kHz.', ...
        fmin/1e3, fmax/1e3);

    tabla = table();
    fc_principal = NaN;

else

    %% 5. Analisis local de cada candidato

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

    %% 6. Tabla resumen

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
        'rep_totales'});

    tabla = sortrows(tabla, 'score_local_dB', 'descend');

    fc_principal = tabla.fc_Hz(1);

end

fprintf('\n============================================\n');
fprintf('TABLA DE CANDIDATOS PERIODOGRAM LED 2\n');
fprintf('============================================\n');
disp(tabla);

if ~isnan(fc_principal)
    fprintf('\nFrecuencia principal Periodogram LED2 = %.3f Hz = %.3f kHz\n', ...
        fc_principal, fc_principal/1e3);
else
    fprintf('\nNo se definio frecuencia principal.\n');
end

%% Guardar tablas en formato CSV

writetable(tabla, fullfile(carpeta_salida, 'tabla_periodogram_LED2_graficas_v2.csv'));
writetable(info_archivos, fullfile(carpeta_salida, 'info_archivos_periodogram_LED2_graficas_v2.csv'));

%% Guardar tabla de candidatos como figura

if ~isempty(tabla)

    tabla_fig = tabla;

    supera_3dB_fig = tabla_fig.score_local_dB >= umbralScore_dB;

    if ismember('fc_Hz', tabla_fig.Properties.VariableNames)
        tabla_fig.fc_Hz = [];
    end

    if ismember('f_local_Hz', tabla_fig.Properties.VariableNames)
        tabla_fig.f_local_Hz = [];
    end

    tabla_fig.supera_3dB = supera_3dB_fig;

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
        'TABLA DE CANDIDATOS PERIODOGRAM LED 2', ...
        fullfile(carpeta_salida, 'tabla_periodogram_LED2_graficas_v2.png'), ...
        fullfile(carpeta_salida, 'tabla_periodogram_LED2_graficas_v2.fig'));
end

%% 7. Figura 1: PSD promedio ON/OFF en rango amplio

fmax_amplio = min(5e6, max(f));
idx_amplio = f >= 0 & f <= fmax_amplio;

fig = figure('Color','w','Position',[100 100 1200 700]);

plot(f(idx_amplio)/1e6, P_ON_prom(idx_amplio), 'LineWidth', 1.2); hold on;
plot(f(idx_amplio)/1e6, P_OFF_prom(idx_amplio), 'LineWidth', 1.2);

grid on;
xlabel('Frecuencia [MHz]');
ylabel('PSD Periodogram [dB/Hz]');
title('LED 2 - Periodogram: PSD promedio ON/OFF, rango amplio', 'Interpreter','none');
legend('LED encendido','LED apagado','Location','best');
xlim([0 fmax_amplio/1e6]);

saveas(fig, fullfile(carpeta_salida, 'Periodogram_LED2_ON_OFF_rango_amplio.png'));
savefig(fig, fullfile(carpeta_salida, 'Periodogram_LED2_ON_OFF_rango_amplio.fig'));

%% 8. Figura 2: PSD promedio ON/OFF en 30-90 kHz

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
ylabel('PSD Periodogram [dB/Hz]');
title('LED 2 - Periodogram: PSD promedio ON/OFF en banda de analisis', 'Interpreter','none');
legend('LED encendido','LED apagado','Location','best');
xlim([fmin fmax]/1e3);

saveas(fig, fullfile(carpeta_salida, 'Periodogram_LED2_ON_OFF_30_90kHz.png'));
savefig(fig, fullfile(carpeta_salida, 'Periodogram_LED2_ON_OFF_30_90kHz.fig'));

%% 9. Figura 3: score ON-OFF en 30-90 kHz

fig = figure('Color','w','Position',[100 100 1200 700]);

plot(f_rango/1e3, score_rango, 'LineWidth', 1.5); hold on;

yline(0, '--', '0 dB', 'HandleVisibility','off');
yline(umbralScore_dB, '--', sprintf('Criterio %.1f dB', umbralScore_dB), ...
    'HandleVisibility','off');

if ~isnan(fc_principal)
    xline(fc_principal/1e3, ':', sprintf('%.3f kHz', fc_principal/1e3), ...
        'LineWidth', 1.3, ...
        'HandleVisibility','off');
end

grid on;
xlabel('Frecuencia [kHz]');
ylabel('Score ON - OFF [dB]');
title('LED 2 - Periodogram: score ON-OFF en banda de analisis', 'Interpreter','none');
xlim([fmin fmax]/1e3);

saveas(fig, fullfile(carpeta_salida, 'Periodogram_LED2_score_ON_OFF_30_90kHz.png'));
savefig(fig, fullfile(carpeta_salida, 'Periodogram_LED2_score_ON_OFF_30_90kHz.fig'));

%% 10. Figura 4: repeticiones ON en 30-90 kHz

fig = figure('Color','w','Position',[100 100 1200 700]);

plot(f_rango/1e3, P_ON(idx_rango,:), 'LineWidth', 1.0);

grid on;
xlabel('Frecuencia [kHz]');
ylabel('PSD Periodogram [dB/Hz]');
title('LED 2 - Periodogram: repeticiones ON en banda de analisis', 'Interpreter','none');
legend(compose('ON rep %d', 1:nrep), 'Location','best');
xlim([fmin fmax]/1e3);

saveas(fig, fullfile(carpeta_salida, 'Periodogram_LED2_repeticiones_ON_30_90kHz.png'));
savefig(fig, fullfile(carpeta_salida, 'Periodogram_LED2_repeticiones_ON_30_90kHz.fig'));

%% 11. Figura 5: repeticiones OFF en 30-90 kHz

fig = figure('Color','w','Position',[100 100 1200 700]);

plot(f_rango/1e3, P_OFF(idx_rango,:), 'LineWidth', 1.0);

grid on;
xlabel('Frecuencia [kHz]');
ylabel('PSD Periodogram [dB/Hz]');
title('LED 2 - Periodogram: repeticiones OFF en banda de analisis', 'Interpreter','none');
legend(compose('OFF rep %d', 1:nrep), 'Location','best');
xlim([fmin fmax]/1e3);

saveas(fig, fullfile(carpeta_salida, 'Periodogram_LED2_repeticiones_OFF_30_90kHz.png'));
savefig(fig, fullfile(carpeta_salida, 'Periodogram_LED2_repeticiones_OFF_30_90kHz.fig'));

%% 12. Figura 6: barras de candidatos principales

if ~isempty(tabla)

    fig = figure('Color','w','Position',[100 100 1350 720]);

    x = 1:height(tabla);

    hBar = bar(x, tabla.score_local_dB, 0.65);
    hold on;
    grid on;
    box on;

    hBar.DisplayName = 'Score local ON-OFF';

    yline(umbralScore_dB, '--', sprintf('Criterio %.1f dB', umbralScore_dB), ...
        'LineWidth', 1.2, ...
        'Color', [0.35 0.35 0.35], ...
        'LabelHorizontalAlignment','right', ...
        'LabelVerticalAlignment','bottom', ...
        'HandleVisibility','off');

    [~, idx_best] = max(tabla.score_local_dB);

    hStar = plot(idx_best, tabla.score_local_dB(idx_best) + 0.45, ...
        'kp', ...
        'MarkerSize', 18, ...
        'LineWidth', 2, ...
        'MarkerFaceColor','none', ...
        'DisplayName','Candidato principal');

    xlabel('Frecuencia candidata [kHz]');
    ylabel('Score local ON-OFF [dB]');
    title('LED 2 - Periodogram: candidatos principales', 'Interpreter','none');

    xticks(x);
    xticklabels(compose('%.3f', tabla.f_local_kHz));
    xtickangle(45);

    for i = 1:height(tabla)

        if i == idx_best
            y_text = tabla.score_local_dB(i) + 1.05;
        else
            y_text = tabla.score_local_dB(i) + 0.35;
        end

        text(x(i), y_text, ...
            sprintf('%.2f dB\n%d/%d', ...
            tabla.score_local_dB(i), ...
            tabla.rep_positivas(i), ...
            tabla.rep_totales(i)), ...
            'HorizontalAlignment','center', ...
            'VerticalAlignment','bottom', ...
            'FontSize',9);
    end

    ylim([0, max(tabla.score_local_dB) + 2.8]);
    xlim([0.3, height(tabla) + 0.7]);

    legend([hBar hStar], ...
        {'Score local ON-OFF','Candidato principal'}, ...
        'Location','eastoutside');

    saveas(fig, fullfile(carpeta_salida, 'Periodogram_LED2_barras_candidatos.png'));
    savefig(fig, fullfile(carpeta_salida, 'Periodogram_LED2_barras_candidatos.fig'));

end

%% 13. Guardar variables

save(fullfile(carpeta_salida, 'datos_periodogram_LED2_graficas_v2.mat'), ...
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
    'umbralScore_dB');

fprintf('\n============================================\n');
fprintf('Periodogram LED2 graficas V2 terminado.\n');
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

function fila = crear_fila_info(archivo, condicion, repeticion, muestras, Fs_mean_Hz, Fs_median_Hz, duracion_s)

    diferencia_mean_median_pct = abs(Fs_mean_Hz - Fs_median_Hz) / Fs_median_Hz * 100;

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

%% ============================================================
% Funcion local para guardar tablas como figura

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
        ancho_col(c) = max(75, min(160, ancho_col(c)));
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

%% ============================================================
% Funcion local para formatear valores de tabla

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