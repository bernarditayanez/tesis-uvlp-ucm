%% T13_RESUMEN_GENERAL_COMPARATIVAS_TERRENO.m
% -------------------------------------------------------------------------
% Antes de ejecutar este script, verificar que ya existan los resultados
% generados por las comparativas:
%
%   T10 -> P1_Leds_1_2
%   T11 -> P2_Leds_1_2_3
%   T12 -> P3_Leds_2_3
%
% Este script NO recalcula PSD. Solo consolida las tablas .csv ya generadas
% por las comparativas de terreno.
%
% Los resultados se guardan en:
%
% Resultados_Terreno\Comparativas\Resumen_General_Terreno
%
% -------------------------------------------------------------------------
% T13 - Resumen general de comparativas de terreno
% -------------------------------------------------------------------------
% Métodos considerados:
%   - Periodograma: método principal
%   - Welch: método complementario
%   - Multitaper: método complementario
% -------------------------------------------------------------------------

clear; clc; close all;

%% ------------------------------------------------------------------------
% 1. RUTAS DE TRABAJO
% -------------------------------------------------------------------------

carpeta_base = 'C:\Users\berni\OneDrive\Escritorio\Modulo Prof\Archivos Tesis\Toma de Datos\Pruebas en terreno';

carpeta_comparativas = fullfile(carpeta_base, ...
    'Resultados_Terreno', ...
    'Comparativas');

carpeta_salida = fullfile(carpeta_comparativas, ...
    'Resumen_General_Terreno');

if ~exist(carpeta_salida, 'dir')
    mkdir(carpeta_salida);
end

limpiar_resultados_T13_previos = true;

if limpiar_resultados_T13_previos
    delete_si_existe(fullfile(carpeta_salida, 'T13_*.csv'));
    delete_si_existe(fullfile(carpeta_salida, 'T13_*.xlsx'));
    delete_si_existe(fullfile(carpeta_salida, 'T13_*.png'));
    delete_si_existe(fullfile(carpeta_salida, 'T13_*.fig'));
end

%% ------------------------------------------------------------------------
% 2. CONFIGURACIÓN GENERAL
% -------------------------------------------------------------------------

criterio_dB = 3.0;

metodos = ["Periodograma", "Welch", "Multitaper"];

comparativas(1).punto = "P1";
comparativas(1).nombre = "P1_Leds_1_2";
comparativas(1).titulo = "P1 - Comparativa global LED 1 y LED 2";
comparativas(1).leds = ["LED 1", "LED 2"];
comparativas(1).tipo_led = ["Principal en P1", "Influencia secundaria esperada"];

comparativas(2).punto = "P2";
comparativas(2).nombre = "P2_Leds_1_2_3";
comparativas(2).titulo = "P2 - Comparativa global LED 1, LED 2 y LED 3";
comparativas(2).leds = ["LED 1", "LED 2", "LED 3"];
comparativas(2).tipo_led = ["Influencia secundaria esperada", "Principal en P2", "Influencia secundaria esperada"];

comparativas(3).punto = "P3";
comparativas(3).nombre = "P3_Leds_2_3";
comparativas(3).titulo = "P3 - Comparativa global LED 2 y LED 3";
comparativas(3).leds = ["LED 2", "LED 3"];
comparativas(3).tipo_led = ["Influencia secundaria esperada", "Principal en P3"];

%% ------------------------------------------------------------------------
% 3. CARGA DE TABLAS GENERADAS POR T10, T11 Y T12
% -------------------------------------------------------------------------

tablas_cargadas = {};

fprintf('\n============================================================\n');
fprintf('T13 - CARGA DE TABLAS DE COMPARATIVAS\n');
fprintf('============================================================\n\n');

for i = 1:numel(comparativas)

    punto_actual = comparativas(i).punto;
    nombre_actual = comparativas(i).nombre;

    carpeta_punto = fullfile(carpeta_comparativas, nombre_actual);

    if ~exist(carpeta_punto, 'dir')
        error('No existe la carpeta de comparativa: %s', carpeta_punto);
    end

    fprintf('Comparativa %s: %s\n', punto_actual, carpeta_punto);

    for j = 1:numel(metodos)

        metodo_actual = metodos(j);
        n_leds_esperados = numel(comparativas(i).leds);

        [Tmetodo, archivo_usado] = cargar_tabla_metodo( ...
            carpeta_punto, ...
            punto_actual, ...
            metodo_actual, ...
            n_leds_esperados);

        fprintf('  %-12s -> %s\n', metodo_actual, archivo_usado);

        tablas_cargadas{end+1, 1} = Tmetodo;

    end

    fprintf('\n');

end

T_resumen = vertcat(tablas_cargadas{:});

T_resumen = ordenar_tabla_resumen(T_resumen, comparativas, metodos);

T_resumen.estado_metodo = clasificar_estado_metodo( ...
    T_resumen.score_dB, ...
    T_resumen.rep_3dB, ...
    T_resumen.rep_total, ...
    criterio_dB);

%% ------------------------------------------------------------------------
% 4. GUARDAR TABLA GENERAL DETALLADA
% -------------------------------------------------------------------------

archivo_resumen_detallado_csv = fullfile(carpeta_salida, ...
    'T13_tabla_resumen_general_detallada.csv');

archivo_resumen_detallado_xlsx = fullfile(carpeta_salida, ...
    'T13_tabla_resumen_general_detallada.xlsx');

writetable(T_resumen, archivo_resumen_detallado_csv);
writetable(T_resumen, archivo_resumen_detallado_xlsx, 'Sheet', 'Resumen_general');

fprintf('Tabla detallada guardada en:\n%s\n\n', archivo_resumen_detallado_csv);

%% ------------------------------------------------------------------------
% 5. CREAR TABLA FINAL POR PUNTO Y LED
% -------------------------------------------------------------------------

T_estado = crear_tabla_estado_final(T_resumen, comparativas, metodos);

archivo_estado_final_csv = fullfile(carpeta_salida, ...
    'T13_tabla_estado_final_por_punto_led.csv');

archivo_estado_final_xlsx = fullfile(carpeta_salida, ...
    'T13_tabla_estado_final_por_punto_led.xlsx');

writetable(T_estado, archivo_estado_final_csv);
writetable(T_estado, archivo_estado_final_xlsx, 'Sheet', 'Estado_final');

fprintf('Tabla de estado final guardada en:\n%s\n\n', archivo_estado_final_csv);

%% ------------------------------------------------------------------------
% 6. TABLA RESUMIDA PARA INFORME
% -------------------------------------------------------------------------

T_informe = T_estado(:, { ...
    'punto', ...
    'led_evaluado', ...
    'tipo_led', ...
    'score_periodograma_dB', ...
    'estado_periodograma', ...
    'score_welch_dB', ...
    'estado_welch', ...
    'score_multitaper_dB', ...
    'estado_multitaper', ...
    'decision_final'});

archivo_tabla_informe_csv = fullfile(carpeta_salida, ...
    'T13_tabla_para_informe.csv');

archivo_tabla_informe_xlsx = fullfile(carpeta_salida, ...
    'T13_tabla_para_informe.xlsx');

writetable(T_informe, archivo_tabla_informe_csv);
writetable(T_informe, archivo_tabla_informe_xlsx, 'Sheet', 'Tabla_informe');

fprintf('Tabla resumida para informe guardada en:\n%s\n\n', archivo_tabla_informe_csv);

%% ------------------------------------------------------------------------
% 7. FIGURA: TABLA GENERAL DETALLADA
% -------------------------------------------------------------------------

columnas_tabla_general = { ...
    'punto', ...
    'metodo', ...
    'rol_metodo', ...
    'modo_evaluacion', ...
    'led_evaluado', ...
    'tipo_led', ...
    'f_ref_kHz', ...
    'f_evaluada_kHz', ...
    'delta_kHz', ...
    'score_dB', ...
    'rep_3dB', ...
    'rep_total', ...
    'estado_metodo'};

T_figura_general = T_resumen(:, columnas_tabla_general);

fig1 = crear_figura_tabla_texto( ...
    T_figura_general, ...
    'TABLA RESUMEN GENERAL - COMPARATIVAS DE TERRENO', ...
    [80 80 2800 1300], ...
    8);

guardar_figura(fig1, carpeta_salida, ...
    'T13_01_tabla_resumen_general_comparativas');

%% ------------------------------------------------------------------------
% 8. FIGURA: TABLA FINAL DE INTERPRETACIÓN
% -------------------------------------------------------------------------

fig2 = crear_figura_tabla_texto( ...
    T_informe, ...
    'TABLA FINAL DE INTERPRETACIÓN - COMPARATIVAS DE TERRENO', ...
    [80 80 2800 1000], ...
    9);

guardar_figura(fig2, carpeta_salida, ...
    'T13_02_tabla_final_interpretacion');

%% ------------------------------------------------------------------------
% 9. FIGURA: RESUMEN GLOBAL DE SCORES
% -------------------------------------------------------------------------

fig3 = figure('Color', 'w', 'Position', [100 100 2200 1000]);

etiquetas_x = T_estado.punto + " - " + T_estado.led_evaluado;

M_scores = [ ...
    T_estado.score_periodograma_dB, ...
    T_estado.score_welch_dB, ...
    T_estado.score_multitaper_dB];

b = bar(M_scores, 'grouped');

grid on;
box on;

set(gca, 'XTick', 1:numel(etiquetas_x));
set(gca, 'XTickLabel', etiquetas_x);
set(gca, 'FontSize', 13);

xtickangle(35);

ylabel('Score local ON-OFF [dB]', 'FontSize', 15);
xlabel('Punto y LED evaluado', 'FontSize', 15);
title('Resumen general de scores por punto, LED y método', ...
    'FontSize', 18, ...
    'FontWeight', 'bold');

hcrit = yline(criterio_dB, '--', 'LineWidth', 1.1);
hcrit.HandleVisibility = 'off';
hcrit.Annotation.LegendInformation.IconDisplayStyle = 'off';

lgd = legend(b, metodos, 'Location', 'northeast');
lgd.AutoUpdate = 'off';

valores_validos = M_scores(~isnan(M_scores));

if isempty(valores_validos)
    valores_validos = 0;
end

ylim([min(0, min(valores_validos) - 1), max(criterio_dB, max(valores_validos) + 2)]);

agregar_etiqueta_criterio(gca, criterio_dB);
agregar_valores_barras(b, M_scores, criterio_dB, 0.18, 10);

guardar_figura(fig3, carpeta_salida, ...
    'T13_03_resumen_global_scores');

%% ------------------------------------------------------------------------
% 10. FIGURAS DE SCORES POR PUNTO
% -------------------------------------------------------------------------

for i = 1:numel(comparativas)

    punto_actual = comparativas(i).punto;

    idx_punto = T_estado.punto == punto_actual;
    T_punto = T_estado(idx_punto, :);

    fig_punto = figure('Color', 'w', 'Position', [100 100 1900 950]);

    M_punto = [ ...
        T_punto.score_periodograma_dB, ...
        T_punto.score_welch_dB, ...
        T_punto.score_multitaper_dB];

    b_punto = bar(M_punto, 'grouped');

    grid on;
    box on;

    set(gca, 'XTick', 1:height(T_punto));
    set(gca, 'XTickLabel', T_punto.led_evaluado);
    set(gca, 'FontSize', 14);

    ylabel('Score local ON-OFF [dB]', 'FontSize', 15);
    xlabel('LED evaluado', 'FontSize', 15);
    title(comparativas(i).titulo, ...
        'FontSize', 18, ...
        'FontWeight', 'bold');

    hcrit = yline(criterio_dB, '--', 'LineWidth', 1.1);
    hcrit.HandleVisibility = 'off';
    hcrit.Annotation.LegendInformation.IconDisplayStyle = 'off';

    lgd = legend(b_punto, metodos, 'Location', 'northeast');
    lgd.AutoUpdate = 'off';

    valores_punto = M_punto(~isnan(M_punto));

    if isempty(valores_punto)
        valores_punto = 0;
    end

    ylim([min(0, min(valores_punto) - 1), max(criterio_dB, max(valores_punto) + 2)]);

    agregar_etiqueta_criterio(gca, criterio_dB);
    agregar_valores_barras(b_punto, M_punto, criterio_dB, 0.18, 11);

    nombre_figura = sprintf('T13_04_resumen_scores_%s', punto_actual);
    guardar_figura(fig_punto, carpeta_salida, nombre_figura);

end

%% ------------------------------------------------------------------------
% 11. FIGURA: DECISIÓN FINAL POR PUNTO Y LED
% -------------------------------------------------------------------------

T_decision = T_estado(:, { ...
    'punto', ...
    'led_evaluado', ...
    'tipo_led', ...
    'estado_periodograma', ...
    'estado_welch', ...
    'estado_multitaper', ...
    'decision_final'});

fig4 = crear_figura_tabla_texto( ...
    T_decision, ...
    'DECISIÓN FINAL POR PUNTO Y LED', ...
    [80 80 2500 900], ...
    10);

guardar_figura(fig4, carpeta_salida, ...
    'T13_05_decision_final_por_punto_led');

%% ------------------------------------------------------------------------
% 12. MOSTRAR RESULTADOS EN CONSOLA
% -------------------------------------------------------------------------

fprintf('\n============================================================\n');
fprintf('T13 FINALIZADO\n');
fprintf('============================================================\n\n');

disp('TABLA GENERAL DETALLADA:');
disp(T_resumen);

disp('TABLA FINAL POR PUNTO Y LED:');
disp(T_estado);

fprintf('\nArchivos generados en:\n%s\n\n', carpeta_salida);

%% ========================================================================
% FUNCIONES LOCALES
% ========================================================================

function [Tmetodo, archivo_usado] = cargar_tabla_metodo(carpeta_punto, punto_defecto, metodo_defecto, n_leds_esperados)

    archivos = dir(fullfile(carpeta_punto, '**', '*.csv'));

    if isempty(archivos)
        error('No se encontraron archivos .csv en: %s', carpeta_punto);
    end

    prioridad = zeros(numel(archivos), 1);

    for i = 1:numel(archivos)
        prioridad(i) = calcular_prioridad_archivo(archivos(i), metodo_defecto);
    end

    metrica = prioridad * 1e9 + [archivos.datenum]';
    [~, orden] = sort(metrica, 'descend');

    metodo_defecto = string(metodo_defecto);
    punto_defecto = string(punto_defecto);

    for ii = 1:numel(orden)

        idx_archivo = orden(ii);
        archivo_actual = fullfile(archivos(idx_archivo).folder, archivos(idx_archivo).name);

        try
            Traw = readtable(archivo_actual);
        catch
            continue;
        end

        if height(Traw) == 0
            continue;
        end

        Tstd = normalizar_tabla(Traw, punto_defecto, metodo_defecto);

        if height(Tstd) == 0
            continue;
        end

        idx_metodo = lower(strtrim(Tstd.metodo)) == lower(strtrim(metodo_defecto));
        idx_punto = lower(strtrim(Tstd.punto)) == lower(strtrim(punto_defecto));

        Tstd = Tstd(idx_metodo & idx_punto, :);

        if height(Tstd) < n_leds_esperados
            continue;
        end

        Tstd = Tstd(1:n_leds_esperados, :);

        Tmetodo = Tstd;
        archivo_usado = archivo_actual;
        return;

    end

    error('No se encontró una tabla válida para %s en %s', metodo_defecto, carpeta_punto);

end

function p = calcular_prioridad_archivo(archivo, metodo)

    ruta = lower(fullfile(archivo.folder, archivo.name));
    metodo = lower(string(metodo));

    p = 0;

    if metodo == "periodograma"
        if contains(ruta, 'periodograma') || contains(ruta, 'periodogram')
            p = p + 50;
        end
    elseif metodo == "welch"
        if contains(ruta, 'welch')
            p = p + 50;
        end
    elseif metodo == "multitaper"
        if contains(ruta, 'multitaper') || contains(ruta, 'mt')
            p = p + 50;
        end
    end

    if contains(ruta, 'comparativa')
        p = p + 30;
    end

    if contains(ruta, 'tabla')
        p = p + 20;
    end

    if contains(ruta, 'resumen')
        p = p + 15;
    end

    if contains(ruta, 'final')
        p = p + 10;
    end

    if contains(ruta, 'repet')
        p = p - 40;
    end

    if contains(ruta, 'candidato')
        p = p - 40;
    end

    if contains(ruta, 'detalle')
        p = p - 10;
    end

end

function Tstd = normalizar_tabla(Traw, punto_defecto, metodo_defecto)

    n = height(Traw);

    if n == 0
        Tstd = table();
        return;
    end

    Tstd = table();

    Tstd.punto = obtener_columna_texto(Traw, ...
        ["punto"], ...
        repmat(string(punto_defecto), n, 1));

    Tstd.metodo = obtener_columna_texto(Traw, ...
        ["metodo", "método"], ...
        repmat(string(metodo_defecto), n, 1));

    Tstd.rol_metodo = obtener_columna_texto(Traw, ...
        ["rol_metodo", "rolmetodo"], ...
        repmat("", n, 1));

    Tstd.modo_evaluacion = obtener_columna_texto(Traw, ...
        ["modo_evaluacion", "modoevaluacion"], ...
        repmat("", n, 1));

    Tstd.led_evaluado = obtener_columna_texto(Traw, ...
        ["led_evaluado", "ledevaluado", "led"], ...
        repmat("", n, 1));

    Tstd.tipo_led = obtener_columna_texto(Traw, ...
        ["tipo_led", "tipoled"], ...
        repmat("", n, 1));

    Tstd.f_ref_kHz = obtener_columna_numerica(Traw, ...
        ["f_ref_kHz", "f_ref_khz", "frefkhz", "fref"], ...
        nan(n, 1));

    Tstd.f_evaluada_kHz = obtener_columna_numerica(Traw, ...
        ["f_evaluada_kHz", "f_evaluada_khz", "fevaluadakhz", ...
         "f_detectada_kHz", "f_detectada_khz", "fdetectadakhz", ...
         "fc_kHz", "fc_khz", "f_local_kHz", "f_local_khz", "flocalkhz"], ...
        nan(n, 1));

    Tstd.delta_kHz = obtener_columna_numerica(Traw, ...
        ["delta_kHz", "delta_khz", "deltakhz"], ...
        nan(n, 1));

    Tstd.semiancho_busqueda_kHz = obtener_columna_numerica(Traw, ...
        ["semiancho_busqueda_kHz", "semiancho_busqueda_khz", ...
         "semianchobusquedakhz", "ventana_kHz", "ventana_khz"], ...
        nan(n, 1));

    Tstd.score_dB = obtener_columna_numerica(Traw, ...
        ["score_dB", "score_db", "scoredb", "score_local", ...
         "score_local_dB", "score_local_db", "scorelocaldb", "score_peak"], ...
        nan(n, 1));

    Tstd.ON_prom_dB = obtener_columna_numerica(Traw, ...
        ["ON_prom_dB", "on_prom_db", "onpromdb", "ON_dB", "on_db", "ondb"], ...
        nan(n, 1));

    Tstd.OFF_prom_dB = obtener_columna_numerica(Traw, ...
        ["OFF_prom_dB", "off_prom_db", "offpromdb", "OFF_dB", "off_db", "offdb"], ...
        nan(n, 1));

    Tstd.rep_0dB = obtener_columna_numerica(Traw, ...
        ["rep_0dB", "rep_0db", "rep0db", "rep_positivas", "reppositivas"], ...
        nan(n, 1));

    Tstd.rep_3dB = obtener_columna_numerica(Traw, ...
        ["rep_3dB", "rep_3db", "rep3db"], ...
        nan(n, 1));

    Tstd.rep_total = obtener_columna_numerica(Traw, ...
        ["rep_total", "rep_totales", "reptotal", "reptotales"], ...
        nan(n, 1));

    if all(isnan(Tstd.delta_kHz)) && any(~isnan(Tstd.f_ref_kHz)) && any(~isnan(Tstd.f_evaluada_kHz))
        Tstd.delta_kHz = Tstd.f_evaluada_kHz - Tstd.f_ref_kHz;
    end

    Tstd.punto = strtrim(Tstd.punto);
    Tstd.metodo = strtrim(Tstd.metodo);
    Tstd.rol_metodo = strtrim(Tstd.rol_metodo);
    Tstd.modo_evaluacion = strtrim(Tstd.modo_evaluacion);
    Tstd.led_evaluado = strtrim(Tstd.led_evaluado);
    Tstd.tipo_led = strtrim(Tstd.tipo_led);

end

function idx = buscar_columna(T, nombres)

    vars = string(T.Properties.VariableNames);
    vars_norm = strings(size(vars));

    for i = 1:numel(vars)
        vars_norm(i) = normalizar_nombre(vars(i));
    end

    nombres = string(nombres);
    nombres_norm = strings(size(nombres));

    for i = 1:numel(nombres)
        nombres_norm(i) = normalizar_nombre(nombres(i));
    end

    idx = 0;

    for i = 1:numel(nombres_norm)
        pos = find(vars_norm == nombres_norm(i), 1, 'first');
        if ~isempty(pos)
            idx = pos;
            return;
        end
    end

end

function nombre_norm = normalizar_nombre(nombre)

    nombre = lower(char(nombre));
    nombre = regexprep(nombre, '[^a-zA-Z0-9]', '');
    nombre_norm = string(nombre);

end

function salida = obtener_columna_texto(T, nombres, defecto)

    idx = buscar_columna(T, nombres);

    if idx == 0
        salida = defecto;
        return;
    end

    nombre_col = T.Properties.VariableNames{idx};
    raw = T.(nombre_col);

    if isstring(raw)
        salida = raw;
    elseif iscell(raw)
        salida = string(raw);
    elseif iscategorical(raw)
        salida = string(raw);
    elseif isnumeric(raw)
        salida = string(raw);
    else
        salida = string(raw);
    end

    salida = salida(:);

end

function salida = obtener_columna_numerica(T, nombres, defecto)

    idx = buscar_columna(T, nombres);

    if idx == 0
        salida = defecto;
        return;
    end

    nombre_col = T.Properties.VariableNames{idx};
    raw = T.(nombre_col);

    if isnumeric(raw)
        salida = double(raw);
    elseif isstring(raw)
        salida = str2double(strrep(raw, ',', '.'));
    elseif iscell(raw)
        salida = str2double(strrep(string(raw), ',', '.'));
    elseif iscategorical(raw)
        salida = str2double(strrep(string(raw), ',', '.'));
    else
        salida = str2double(strrep(string(raw), ',', '.'));
    end

    salida = salida(:);

end

function Tordenada = ordenar_tabla_resumen(T, comparativas, metodos)

    Tordenada = T([], :);

    for i = 1:numel(comparativas)

        punto_actual = comparativas(i).punto;

        for j = 1:numel(metodos)

            metodo_actual = metodos(j);

            for k = 1:numel(comparativas(i).leds)

                led_actual = comparativas(i).leds(k);

                idx = T.punto == punto_actual & ...
                      T.metodo == metodo_actual & ...
                      T.led_evaluado == led_actual;

                if any(idx)
                    fila = T(find(idx, 1, 'first'), :);
                    Tordenada = [Tordenada; fila]; %#ok<AGROW>
                end

            end

        end

    end

end

function estado = clasificar_estado_metodo(score_dB, rep_3dB, rep_total, criterio_dB)

    n = numel(score_dB);
    estado = strings(n, 1);

    for i = 1:n

        score = score_dB(i);
        r3 = rep_3dB(i);
        rt = rep_total(i);

        if isnan(score)
            estado(i) = "Sin dato";

        elseif score >= criterio_dB && ~isnan(r3) && ~isnan(rt) && rt > 0 && r3 >= rt
            estado(i) = "Confirmado";

        elseif score >= criterio_dB && ~isnan(r3) && r3 > 0
            estado(i) = "Indicio parcial";

        elseif score >= criterio_dB && (isnan(r3) || isnan(rt))
            estado(i) = "Sobre criterio";

        elseif score > 0
            estado(i) = "Indicio debil";

        else
            estado(i) = "No confirmado";
        end

    end

end

function T_estado = crear_tabla_estado_final(T_resumen, comparativas, metodos)

    punto = strings(0, 1);
    led_evaluado = strings(0, 1);
    tipo_led = strings(0, 1);

    f_periodograma_kHz = [];
    score_periodograma_dB = [];
    rep3_periodograma = [];
    rep_total_periodograma = [];
    estado_periodograma = strings(0, 1);

    f_welch_kHz = [];
    score_welch_dB = [];
    rep3_welch = [];
    rep_total_welch = [];
    estado_welch = strings(0, 1);

    f_multitaper_kHz = [];
    score_multitaper_dB = [];
    rep3_multitaper = [];
    rep_total_multitaper = [];
    estado_multitaper = strings(0, 1);

    decision_final = strings(0, 1);

    for i = 1:numel(comparativas)

        punto_actual = comparativas(i).punto;

        for j = 1:numel(comparativas(i).leds)

            led_actual = comparativas(i).leds(j);
            tipo_actual = comparativas(i).tipo_led(j);

            [score_p, estado_p, f_p, r3_p, rt_p] = obtener_resultado_metodo( ...
                T_resumen, punto_actual, led_actual, metodos(1));

            [score_w, estado_w, f_w, r3_w, rt_w] = obtener_resultado_metodo( ...
                T_resumen, punto_actual, led_actual, metodos(2));

            [score_m, estado_m, f_m, r3_m, rt_m] = obtener_resultado_metodo( ...
                T_resumen, punto_actual, led_actual, metodos(3));

            decision = decidir_resultado_final(estado_p, estado_w, estado_m, tipo_actual);

            punto(end+1, 1) = punto_actual; %#ok<AGROW>
            led_evaluado(end+1, 1) = led_actual; %#ok<AGROW>
            tipo_led(end+1, 1) = tipo_actual; %#ok<AGROW>

            f_periodograma_kHz(end+1, 1) = f_p; %#ok<AGROW>
            score_periodograma_dB(end+1, 1) = score_p; %#ok<AGROW>
            rep3_periodograma(end+1, 1) = r3_p; %#ok<AGROW>
            rep_total_periodograma(end+1, 1) = rt_p; %#ok<AGROW>
            estado_periodograma(end+1, 1) = estado_p; %#ok<AGROW>

            f_welch_kHz(end+1, 1) = f_w; %#ok<AGROW>
            score_welch_dB(end+1, 1) = score_w; %#ok<AGROW>
            rep3_welch(end+1, 1) = r3_w; %#ok<AGROW>
            rep_total_welch(end+1, 1) = rt_w; %#ok<AGROW>
            estado_welch(end+1, 1) = estado_w; %#ok<AGROW>

            f_multitaper_kHz(end+1, 1) = f_m; %#ok<AGROW>
            score_multitaper_dB(end+1, 1) = score_m; %#ok<AGROW>
            rep3_multitaper(end+1, 1) = r3_m; %#ok<AGROW>
            rep_total_multitaper(end+1, 1) = rt_m; %#ok<AGROW>
            estado_multitaper(end+1, 1) = estado_m; %#ok<AGROW>

            decision_final(end+1, 1) = decision; %#ok<AGROW>

        end

    end

    T_estado = table( ...
        punto, ...
        led_evaluado, ...
        tipo_led, ...
        f_periodograma_kHz, ...
        score_periodograma_dB, ...
        rep3_periodograma, ...
        rep_total_periodograma, ...
        estado_periodograma, ...
        f_welch_kHz, ...
        score_welch_dB, ...
        rep3_welch, ...
        rep_total_welch, ...
        estado_welch, ...
        f_multitaper_kHz, ...
        score_multitaper_dB, ...
        rep3_multitaper, ...
        rep_total_multitaper, ...
        estado_multitaper, ...
        decision_final);

end

function [score, estado, f_eval, rep3, rep_total] = obtener_resultado_metodo(T, punto, led, metodo)

    idx = T.punto == punto & ...
          T.led_evaluado == led & ...
          T.metodo == metodo;

    if ~any(idx)
        score = NaN;
        estado = "Sin dato";
        f_eval = NaN;
        rep3 = NaN;
        rep_total = NaN;
        return;
    end

    fila = T(find(idx, 1, 'first'), :);

    score = fila.score_dB;
    estado = fila.estado_metodo;
    f_eval = fila.f_evaluada_kHz;
    rep3 = fila.rep_3dB;
    rep_total = fila.rep_total;

end

function decision = decidir_resultado_final(estado_p, estado_w, estado_m, tipo_led)

    estado_p = string(estado_p);
    estado_w = string(estado_w);
    estado_m = string(estado_m);
    tipo_led = string(tipo_led);

    periodograma_confirma = estado_p == "Confirmado";
    welch_confirma = estado_w == "Confirmado";
    multitaper_confirma = estado_m == "Confirmado";

    complementario_confirma = welch_confirma || multitaper_confirma;

    periodograma_parcial = estado_p == "Indicio parcial" || ...
                           estado_p == "Indicio debil" || ...
                           estado_p == "Sobre criterio";

    welch_parcial = estado_w == "Indicio parcial" || ...
                    estado_w == "Indicio debil" || ...
                    estado_w == "Sobre criterio";

    multitaper_parcial = estado_m == "Indicio parcial" || ...
                         estado_m == "Indicio debil" || ...
                         estado_m == "Sobre criterio";

    complementario_parcial = welch_parcial || multitaper_parcial;

    if contains(lower(tipo_led), "principal")

        if periodograma_confirma && complementario_confirma
            decision = "LED principal confirmado";

        elseif periodograma_confirma && complementario_parcial
            decision = "LED principal detectado con apoyo parcial";

        elseif periodograma_confirma
            decision = "LED principal detectado por Periodograma";

        elseif ~periodograma_confirma && complementario_confirma
            decision = "Confirmacion complementaria sin Periodograma";

        elseif periodograma_parcial || complementario_parcial
            decision = "Indicio del LED principal";

        else
            decision = "No confirmado";
        end

    else

        if periodograma_confirma && complementario_confirma
            decision = "Influencia secundaria confirmada";

        elseif periodograma_confirma && complementario_parcial
            decision = "Influencia secundaria con apoyo parcial";

        elseif periodograma_confirma
            decision = "Influencia secundaria detectada por Periodograma";

        elseif ~periodograma_confirma && complementario_confirma
            decision = "Influencia secundaria sugerida por complementario";

        elseif periodograma_parcial || complementario_parcial
            decision = "Indicio de influencia secundaria";

        else
            decision = "Sin influencia confirmada";
        end

    end

end

function fig = crear_figura_tabla_texto(T, titulo, posicion, font_size_base)

    fig = figure('Color', 'w', 'Position', posicion);

    ax = axes(fig, ...
        'Position', [0.015 0.04 0.97 0.88]);

    axis(ax, 'off');
    xlim(ax, [0 1]);
    ylim(ax, [0 1]);
    hold(ax, 'on');

    annotation(fig, 'textbox', [0.01 0.935 0.98 0.055], ...
        'String', titulo, ...
        'EdgeColor', 'none', ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'middle', ...
        'FontSize', 18, ...
        'FontWeight', 'bold', ...
        'Interpreter', 'none');

    datos = tabla_a_celdas_texto(T);
    columnas = string(T.Properties.VariableNames);

    n_filas = size(datos, 1);
    n_columnas = size(datos, 2);

    alto_fila = 1 / (n_filas + 1.4);

    font_size = min(font_size_base, max(6, 13 - 0.16*n_filas - 0.06*n_columnas));

    anchos = calcular_anchos_columnas(columnas, datos);
    x_edges = [0, cumsum(anchos)];
    x_edges = x_edges / x_edges(end);

    y_top = 0.985;
    y_edges = y_top - (0:n_filas+1) * alto_fila;

    if y_edges(end) < 0.015
        escala = (y_top - 0.015) / ((n_filas + 1) * alto_fila);
        alto_fila = alto_fila * escala;
        y_edges = y_top - (0:n_filas+1) * alto_fila;
    end

    color_header = [0.90 0.90 0.90];
    color_fila_1 = [1.00 1.00 1.00];
    color_fila_2 = [0.94 0.94 0.94];
    color_linea = [0.75 0.75 0.75];

    for c = 1:n_columnas

        x0 = x_edges(c);
        w = x_edges(c+1) - x_edges(c);

        rectangle(ax, ...
            'Position', [x0 y_edges(2) w alto_fila], ...
            'FaceColor', color_header, ...
            'EdgeColor', color_linea, ...
            'LineWidth', 0.8);

        text(ax, x0 + w/2, y_edges(2) + alto_fila/2, ...
            limpiar_texto_tabla(columnas(c), 24), ...
            'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'middle', ...
            'FontSize', font_size, ...
            'FontWeight', 'bold', ...
            'Interpreter', 'none');

    end

    for r = 1:n_filas

        if mod(r, 2) == 1
            color_fila = color_fila_1;
        else
            color_fila = color_fila_2;
        end

        y0 = y_edges(r+2);

        for c = 1:n_columnas

            x0 = x_edges(c);
            w = x_edges(c+1) - x_edges(c);

            rectangle(ax, ...
                'Position', [x0 y0 w alto_fila], ...
                'FaceColor', color_fila, ...
                'EdgeColor', color_linea, ...
                'LineWidth', 0.5);

            nombre_col = lower(string(columnas(c)));

            if contains(nombre_col, "decision")
                max_caracteres = 38;
            elseif contains(nombre_col, "tipo")
                max_caracteres = 34;
            elseif contains(nombre_col, "estado")
                max_caracteres = 26;
            else
                max_caracteres = 24;
            end

            texto = limpiar_texto_tabla(datos{r, c}, max_caracteres);

            text(ax, x0 + w/2, y0 + alto_fila/2, texto, ...
                'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'middle', ...
                'FontSize', font_size, ...
                'Interpreter', 'none');

        end

    end

end

function anchos = calcular_anchos_columnas(columnas, datos)

    n_columnas = numel(columnas);
    anchos = zeros(1, n_columnas);

    for c = 1:n_columnas

        contenido = string(datos(:, c));
        largo_max = max(strlength([columnas(c); contenido]));

        nombre = lower(columnas(c));

        if contains(nombre, "decision")
            anchos(c) = max(24, min(34, largo_max));
        elseif contains(nombre, "tipo")
            anchos(c) = max(18, min(28, largo_max));
        elseif contains(nombre, "estado")
            anchos(c) = max(14, min(20, largo_max));
        elseif contains(nombre, "modo")
            anchos(c) = max(15, min(22, largo_max));
        elseif contains(nombre, "rol")
            anchos(c) = max(12, min(16, largo_max));
        elseif contains(nombre, "metodo")
            anchos(c) = max(11, min(15, largo_max));
        elseif contains(nombre, "led")
            anchos(c) = max(10, min(15, largo_max));
        elseif contains(nombre, "score")
            anchos(c) = 10;
        elseif contains(nombre, "rep")
            anchos(c) = 8;
        elseif contains(nombre, "khz")
            anchos(c) = 11;
        elseif contains(nombre, "punto")
            anchos(c) = 7;
        else
            anchos(c) = max(8, min(14, largo_max));
        end

    end

    anchos = double(anchos);

end

function datos = tabla_a_celdas_texto(T)

    datos = cell(height(T), width(T));

    for i = 1:height(T)

        for j = 1:width(T)

            valor = T{i, j};

            if isnumeric(valor)

                if isnan(valor)
                    datos{i, j} = '';
                else
                    nombre_col = lower(string(T.Properties.VariableNames{j}));

                    if contains(nombre_col, "rep_total")
                        datos{i, j} = sprintf('%.0f', valor);
                    elseif contains(nombre_col, "rep")
                        datos{i, j} = sprintf('%.0f', valor);
                    elseif contains(nombre_col, "score")
                        datos{i, j} = sprintf('%.2f', valor);
                    elseif contains(nombre_col, "khz")
                        datos{i, j} = sprintf('%.4f', valor);
                    else
                        datos{i, j} = sprintf('%.4f', valor);
                    end
                end

            elseif isstring(valor)

                datos{i, j} = char(valor);

            elseif iscell(valor)

                datos{i, j} = char(string(valor{1}));

            elseif iscategorical(valor)

                datos{i, j} = char(string(valor));

            else

                datos{i, j} = char(string(valor));

            end

        end

    end

end

function texto = limpiar_texto_tabla(texto, max_caracteres)

    texto = char(string(texto));

    if strlength(string(texto)) > max_caracteres
        texto = char(extractBefore(string(texto), max_caracteres - 2) + "...");
    end

end

function agregar_etiqueta_criterio(ax, valor_criterio)

    xl = xlim(ax);
    yl = ylim(ax);

    margen_x = 0.015 * (xl(2) - xl(1));
    margen_y = 0.025 * (yl(2) - yl(1));

    text(ax, xl(1) + margen_x, valor_criterio + margen_y, ...
        'Criterio 3.0 dB', ...
        'HorizontalAlignment', 'left', ...
        'VerticalAlignment', 'bottom', ...
        'FontSize', 12, ...
        'BackgroundColor', 'w', ...
        'Margin', 2, ...
        'Interpreter', 'none');

end

function agregar_valores_barras(b, M_scores, criterio_dB, separacion, font_size)

    for k = 1:numel(b)

        x_bar = b(k).XEndPoints;
        y_bar = b(k).YEndPoints;

        for r = 1:size(M_scores, 1)

            if ~isnan(M_scores(r, k))

                valor = M_scores(r, k);
                txt = sprintf('%.2f', valor);

                extra = 0;

                if abs(valor - criterio_dB) < 0.25
                    extra = 0.25;
                end

                if valor >= 0
                    y_txt = y_bar(r) + separacion + extra;
                    va = 'bottom';
                else
                    y_txt = y_bar(r) - separacion;
                    va = 'top';
                end

                text(x_bar(r), y_txt, txt, ...
                    'HorizontalAlignment', 'center', ...
                    'VerticalAlignment', va, ...
                    'FontSize', font_size, ...
                    'Interpreter', 'none');

            end

        end

    end

end

function guardar_figura(fig, carpeta_salida, nombre_base)

    archivo_png = fullfile(carpeta_salida, [nombre_base '.png']);
    archivo_fig = fullfile(carpeta_salida, [nombre_base '.fig']);

    drawnow;
    pause(0.2);

    exportgraphics(fig, archivo_png, 'Resolution', 200);
    savefig(fig, archivo_fig);

end

function delete_si_existe(patron)

    archivos = dir(patron);

    for i = 1:numel(archivos)

        archivo = fullfile(archivos(i).folder, archivos(i).name);

        if exist(archivo, 'file')
            delete(archivo);
        end

    end

end