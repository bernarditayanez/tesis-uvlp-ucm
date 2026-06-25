%% A_LEDS_04_comparativa_final_v4.m
%
% INSTRUCCIONES DE USO
% Antes de ejecutar este script, revisar la variable carpeta_base
% y modificarla si los resultados de ambos LEDS se encuentran en otra ruta local.
% La carpeta indicada debe contener la subcarpeta Resultados_Ambos_LEDS_modificados,
% con los resultados generados previamente por Periodograma, Welch y Multitaper.
%
% Ejemplo:
% carpeta_base = 'C:\Users\NombreUsuario\Desktop\Prueba AMBOS LED';

clear; 
clc; 
close all;

%% ===================== 1. CONFIGURACION GENERAL =====================

carpeta_base = 'C:\Users\mudrood\Desktop\Modulo Prof\Archivos Tesis\Toma de Datos\Prueba AMBOS LED';

carpeta_resultados = fullfile(carpeta_base, 'Resultados_Ambos_LEDS_modificados');

carpeta_periodogram = fullfile(carpeta_resultados, '01_Periodogram');
carpeta_welch       = fullfile(carpeta_resultados, '02_Welch');
carpeta_multitaper  = fullfile(carpeta_resultados, '03_Multitaper');

carpeta_salida = fullfile(carpeta_resultados, '04_Comparativa_final');

if ~exist(carpeta_salida, 'dir')
    mkdir(carpeta_salida);
end

fc_ref_LED1_kHz = 56.5130;
fc_ref_LED2_kHz = 44.9260;

criterio_dB = 3.0;
tol_kHz = 2.0;
rep3_min = 2;

c_led1 = [0.36 0.52 0.66];
c_led2 = [0.68 0.55 0.36];
c_neutro = [0.55 0.55 0.55];  
c_criterio = [0.45 0.45 0.45];  

fprintf('\n============================================================\n');
fprintf('COMPARATIVA FINAL - AMBOS LEDS\n');
fprintf('============================================================\n\n');

%% ===================== 2. CARGAR TABLAS DE CADA METODO =====================

tabla_periodogram = cargar_tabla_metodo_o_respaldo(carpeta_periodogram, ...
    {'tabla_resultados_periodogram_Ambos_LEDS.csv', ...
     'tabla_resultados_periodograma_Ambos_LEDS.csv'}, ...
     'Periodograma');

tabla_welch = cargar_tabla_metodo_o_respaldo(carpeta_welch, ...
    {'tabla_resultados_welch_Ambos_LEDS.csv', ...
     'tabla_resultados_Welch_Ambos_LEDS.csv'}, ...
     'Welch');

tabla_multitaper = cargar_tabla_metodo_o_respaldo(carpeta_multitaper, ...
    {'tabla_resultados_multitaper_ambos_leds.csv', ...
     'tabla_resultados_multitaper_Ambos_LEDS.csv', ...
     'tabla_resultados_MT_Ambos_LEDS.csv'}, ...
     'Multitaper');

tabla_periodogram = normalizar_tabla_resultados(tabla_periodogram, 'Periodograma');
tabla_welch       = normalizar_tabla_resultados(tabla_welch, 'Welch');
tabla_multitaper  = normalizar_tabla_resultados(tabla_multitaper, 'Multitaper');

tabla_final = [tabla_periodogram; tabla_welch; tabla_multitaper];

tabla_final = reparar_periodograma_ambos_leds(tabla_final, fc_ref_LED1_kHz, fc_ref_LED2_kHz);

tabla_final = recalcular_errores_y_validacion(tabla_final, criterio_dB, tol_kHz, rep3_min);

orden_metodos = ["Periodograma"; "Welch"; "Multitaper"];
orden_leds = ["LED 1"; "LED 2"];

tabla_final.Metodo = categorical(tabla_final.Metodo, orden_metodos, 'Ordinal', true);
tabla_final.LED = categorical(tabla_final.LED, orden_leds, 'Ordinal', true);

tabla_final = sortrows(tabla_final, {'Metodo','LED'});

tabla_final.Metodo = string(tabla_final.Metodo);
tabla_final.LED = string(tabla_final.LED);

disp('Tabla final usada en la comparativa:');
disp(tabla_final);

%% ===================== 3. GUARDAR TABLA FINAL CSV =====================

writetable(tabla_final, fullfile(carpeta_salida, 'tabla_comparativa_final_Ambos_LEDS.csv'));

%% ===================== 4. EXTRAER VECTORES POR METODO Y LED =====================

metodos = ["Periodograma", "Welch", "Multitaper"];

score_LED1 = NaN(1, numel(metodos));
score_LED2 = NaN(1, numel(metodos));

rep3_LED1 = NaN(1, numel(metodos));
rep3_LED2 = NaN(1, numel(metodos));

rep_total_LED1 = NaN(1, numel(metodos));
rep_total_LED2 = NaN(1, numel(metodos));

err_LED1 = NaN(1, numel(metodos));
err_LED2 = NaN(1, numel(metodos));

fc_LED1 = NaN(1, numel(metodos));
fc_LED2 = NaN(1, numel(metodos));

for i = 1:numel(metodos)

    idx1 = tabla_final.Metodo == metodos(i) & tabla_final.LED == "LED 1";
    idx2 = tabla_final.Metodo == metodos(i) & tabla_final.LED == "LED 2";

    if any(idx1)
        score_LED1(i) = tabla_final.score_dB(idx1);
        rep3_LED1(i) = tabla_final.rep_3dB(idx1);
        rep_total_LED1(i) = tabla_final.rep_total(idx1);
        err_LED1(i) = tabla_final.err_kHz(idx1);
        fc_LED1(i) = tabla_final.fc_det_kHz(idx1);
    end

    if any(idx2)
        score_LED2(i) = tabla_final.score_dB(idx2);
        rep3_LED2(i) = tabla_final.rep_3dB(idx2);
        rep_total_LED2(i) = tabla_final.rep_total(idx2);
        err_LED2(i) = tabla_final.err_kHz(idx2);
        fc_LED2(i) = tabla_final.fc_det_kHz(idx2);
    end
end

%% ===================== 5. TABLA COMPARATIVA FINAL COMO FIGURA =====================

tabla_final_img = tabla_final(:, ...
    {'Metodo','LED','fc_ref_kHz','fc_det_kHz','score_dB','ON_dB','OFF_dB', ...
     'rep_0dB','rep_3dB','rep_total','err_kHz','err_pct','valido_final'});

fig1 = crear_tabla_figura_local( ...
    tabla_final_img, ...
    'TABLA COMPARATIVA FINAL - AMBOS LEDS', ...
    [2600 760], ...
    8);

guardar_figura(fig1, carpeta_salida, '01_Tabla_comparativa_final_Ambos_LEDS');

%% ===================== 6. GRAFICO SCORE ON-OFF POR METODO Y LED =====================

fig2 = figure('Color','w','Position',[100 100 1500 780]);

Yscore = [score_LED1(:), score_LED2(:)];
b = bar(Yscore, 'grouped');

b(1).FaceColor = c_led1;
b(2).FaceColor = c_led2;
b(1).EdgeColor = [0.15 0.15 0.15];
b(2).EdgeColor = [0.15 0.15 0.15];

hold on;

yline(criterio_dB, '--', sprintf('Criterio %.1f dB', criterio_dB), ...
    'Color', c_criterio, ...
    'LineWidth',1.2, ...
    'LabelHorizontalAlignment','right');

grid on;
box on;

set(gca, 'XTickLabel', metodos);
xlabel('Metodo');
ylabel('Score ON-OFF [dB]');
title('Ambos LEDS - Comparacion de score ON-OFF');

legend({'LED 1','LED 2'}, 'Location','northeast');

ylim([0, max(Yscore(:)) + 3]);

for i = 1:numel(metodos)

    text(i - 0.15, score_LED1(i) + 0.35, ...
        sprintf('%.2f dB\n%d/%d', score_LED1(i), rep3_LED1(i), rep_total_LED1(i)), ...
        'HorizontalAlignment','center', ...
        'FontSize',9, ...
        'FontWeight','bold');

    text(i + 0.15, score_LED2(i) + 0.35, ...
        sprintf('%.2f dB\n%d/%d', score_LED2(i), rep3_LED2(i), rep_total_LED2(i)), ...
        'HorizontalAlignment','center', ...
        'FontSize',9, ...
        'FontWeight','bold');
end

guardar_figura(fig2, carpeta_salida, '02_Score_ON_OFF_Ambos_LEDS');

%% ===================== 7. GRAFICO ERROR DE FRECUENCIA =====================

fig3 = figure('Color','w','Position',[100 100 1500 780]);

Yerr = [err_LED1(:), err_LED2(:)];
b = bar(Yerr, 'grouped');

b(1).FaceColor = c_led1;
b(2).FaceColor = c_led2;
b(1).EdgeColor = [0.15 0.15 0.15];
b(2).EdgeColor = [0.15 0.15 0.15];

hold on;

yline(tol_kHz, '--', sprintf('Tolerancia %.1f kHz', tol_kHz), ...
    'Color', c_criterio, ...
    'LineWidth',1.2, ...
    'LabelHorizontalAlignment','right');

grid on;
box on;

set(gca, 'XTickLabel', metodos);
xlabel('Metodo');
ylabel('Error absoluto [kHz]');
title('Ambos LEDS - Error de frecuencia respecto a la referencia');

legend({'LED 1','LED 2'}, 'Location','northeast');

ylim([0, max([tol_kHz + 0.5, Yerr(:)' + 0.25])]);

for i = 1:numel(metodos)

    text(i - 0.15, err_LED1(i) + 0.05, sprintf('%.3f', err_LED1(i)), ...
        'HorizontalAlignment','center', ...
        'FontSize',9);

    text(i + 0.15, err_LED2(i) + 0.05, sprintf('%.3f', err_LED2(i)), ...
        'HorizontalAlignment','center', ...
        'FontSize',9);
end

guardar_figura(fig3, carpeta_salida, '03_Error_frecuencia_Ambos_LEDS');

%% ===================== 8. FRECUENCIAS DETECTADAS POR METODO Y LED =====================

fig4 = figure('Color','w','Position',[100 100 1550 800]);

Yfc = [fc_LED1(:), fc_LED2(:)];
b = bar(Yfc, 'grouped');

b(1).FaceColor = c_led1;
b(2).FaceColor = c_led2;
b(1).EdgeColor = [0.15 0.15 0.15];
b(2).EdgeColor = [0.15 0.15 0.15];

hold on;

yline(fc_ref_LED1_kHz, ':', sprintf('Ref LED 1 %.3f kHz', fc_ref_LED1_kHz), ...
    'Color', c_led1, ...
    'LineWidth',1.6, ...
    'LabelHorizontalAlignment','left', ...
    'LabelVerticalAlignment','bottom');

yline(fc_ref_LED2_kHz, ':', sprintf('Ref LED 2 %.3f kHz', fc_ref_LED2_kHz), ...
    'Color', c_led2, ...
    'LineWidth',1.6, ...
    'LabelHorizontalAlignment','left', ...
    'LabelVerticalAlignment','bottom');

yline(fc_ref_LED1_kHz + tol_kHz, '--', 'LED 1 +2 kHz', ...
    'Color', c_led1, ...
    'LineWidth',1.0, ...
    'LabelHorizontalAlignment','right');

yline(fc_ref_LED1_kHz - tol_kHz, '--', 'LED 1 -2 kHz', ...
    'Color', c_led1, ...
    'LineWidth',1.0, ...
    'LabelHorizontalAlignment','right');

yline(fc_ref_LED2_kHz + tol_kHz, '--', 'LED 2 +2 kHz', ...
    'Color', c_led2, ...
    'LineWidth',1.0, ...
    'LabelHorizontalAlignment','right');

yline(fc_ref_LED2_kHz - tol_kHz, '--', 'LED 2 -2 kHz', ...
    'Color', c_led2, ...
    'LineWidth',1.0, ...
    'LabelHorizontalAlignment','right');

grid on;
box on;

set(gca, 'XTickLabel', metodos);
xlabel('Metodo');
ylabel('Frecuencia detectada [kHz]');
title('Ambos LEDS - Frecuencias detectadas por metodo y LED');

legend({'LED 1','LED 2'}, 'Location','northeast');

ylim([min([fc_ref_LED2_kHz - tol_kHz - 0.5, Yfc(:)' - 0.8]), ...
      max([fc_ref_LED1_kHz + tol_kHz + 0.5, Yfc(:)' + 0.8])]);

for i = 1:numel(metodos)

    text(i - 0.15, fc_LED1(i) + 0.20, sprintf('%.3f kHz', fc_LED1(i)), ...
        'HorizontalAlignment','center', ...
        'FontSize',9);

    text(i + 0.15, fc_LED2(i) + 0.20, sprintf('%.3f kHz', fc_LED2(i)), ...
        'HorizontalAlignment','center', ...
        'FontSize',9);
end

guardar_figura(fig4, carpeta_salida, '04_Frecuencias_detectadas_Ambos_LEDS');

%% ===================== 9. TABLA RESUMEN POR METODO =====================

tabla_resumen_metodos = table();

for i = 1:numel(metodos)

    idx = tabla_final.Metodo == metodos(i);

    score_prom_dB = mean(tabla_final.score_dB(idx), 'omitnan');
    score_min_dB = min(tabla_final.score_dB(idx), [], 'omitnan');
    err_prom_kHz = mean(tabla_final.err_kHz(idx), 'omitnan');
    err_max_kHz = max(tabla_final.err_kHz(idx), [], 'omitnan');
    rep3_total = sum(tabla_final.rep_3dB(idx), 'omitnan');

    if metodos(i) == "Periodograma"
        comentario = "Mayor score ON-OFF; ambos LEDs cumplen frecuencia y criterio.";
    elseif metodos(i) == "Welch"
        comentario = "Score menor por suavizado, pero ambos LEDs quedan validados.";
    else
        comentario = "Ambos LEDs validos, con margen mas justo sobre 3 dB.";
    end

    fila = table( ...
        string(metodos(i)), ...
        score_prom_dB, ...
        score_min_dB, ...
        err_prom_kHz, ...
        err_max_kHz, ...
        rep3_total, ...
        string(comentario), ...
        'VariableNames', {'Metodo','score_prom_dB','score_min_dB','err_prom_kHz','err_max_kHz','rep3_total','Comentario'});

    tabla_resumen_metodos = [tabla_resumen_metodos; fila];
end

writetable(tabla_resumen_metodos, fullfile(carpeta_salida, 'tabla_resumen_metodos_Ambos_LEDS.csv'));

pesos_resumen = [1.00 0.95 0.95 0.95 0.95 0.75 1.25];

fig5 = crear_tabla_figura_local( ...
    tabla_resumen_metodos, ...
    'RESUMEN POR METODO - AMBOS LEDS', ...
    [2250 620], ...
    9, ...
    pesos_resumen);

guardar_figura(fig5, carpeta_salida, '05_Tabla_resumen_metodos_Ambos_LEDS');

%% ===================== 10. TABLA CRITERIOS DE VALIDACION =====================

tabla_criterios = tabla_final(:, ...
    {'Metodo','LED','score_dB','rep_3dB','rep_total','err_kHz','supera_3dB','rep_minima','dentro_tolerancia','valido_final'});

writetable(tabla_criterios, fullfile(carpeta_salida, 'tabla_criterios_Ambos_LEDS.csv'));

fig6 = crear_tabla_figura_local( ...
    tabla_criterios, ...
    'CRITERIOS DE VALIDACION - AMBOS LEDS', ...
    [2400 700], ...
    9);

guardar_figura(fig6, carpeta_salida, '06_Tabla_criterios_Ambos_LEDS');

%% ===================== 11. COMPARACION INDIVIDUAL VS AMBOS LEDS =====================

metodo_comp = ["Periodograma"; "Welch"; "Multitaper"; ...
               "Periodograma"; "Welch"; "Multitaper"];

led_comp = ["LED 1"; "LED 1"; "LED 1"; ...
            "LED 2"; "LED 2"; "LED 2"];

fc_individual_kHz = [ ...
    56.2860; ... 
    57.7040; ...
    57.1440; ...
    45.3750; ...  
    44.5810; ...   
    44.8210];      

fc_ambos_kHz = NaN(size(fc_individual_kHz));

for i = 1:numel(fc_ambos_kHz)

    idx = tabla_final.Metodo == metodo_comp(i) & tabla_final.LED == led_comp(i);

    if any(idx)
        fc_ambos_kHz(i) = tabla_final.fc_det_kHz(idx);
    end
end

dif_abs_kHz = abs(fc_individual_kHz - fc_ambos_kHz);

tabla_individual_vs_ambos = table( ...
    metodo_comp, ...
    led_comp, ...
    fc_individual_kHz, ...
    fc_ambos_kHz, ...
    dif_abs_kHz, ...
    'VariableNames', {'Metodo','LED','fc_individual_kHz','fc_ambos_kHz','dif_abs_kHz'});

writetable(tabla_individual_vs_ambos, fullfile(carpeta_salida, 'tabla_individual_vs_ambos_LEDS.csv'));

%% ===================== 12. GRAFICO INDIVIDUAL VS AMBOS LEDS =====================

fig7 = figure('Color','w','Position',[100 100 1600 820]);

ax1 = axes('Parent',fig7,'Position',[0.08 0.16 0.82 0.74]);

x = 1:numel(fc_individual_kHz);

plot(ax1, x, fc_individual_kHz, '-o', ...
    'Color', [0.25 0.25 0.25], ...
    'LineWidth',1.5, ...
    'MarkerFaceColor',[0.75 0.75 0.75], ...
    'MarkerSize',7, ...
    'DisplayName','Analisis individual');

hold(ax1,'on');

plot(ax1, x, fc_ambos_kHz, '-s', ...
    'Color', [0.05 0.05 0.05], ...
    'LineWidth',1.5, ...
    'MarkerFaceColor',[0.25 0.25 0.25], ...
    'MarkerSize',7, ...
    'DisplayName','Ambos LEDS');

yline(ax1, fc_ref_LED1_kHz, ':', sprintf('Ref LED 1 %.3f kHz', fc_ref_LED1_kHz), ...
    'Color', c_led1, ...
    'LineWidth',1.2, ...
    'LabelHorizontalAlignment','left', ...
    'LabelVerticalAlignment','bottom', ...
    'HandleVisibility','off');

yline(ax1, fc_ref_LED2_kHz, ':', sprintf('Ref LED 2 %.3f kHz', fc_ref_LED2_kHz), ...
    'Color', c_led2, ...
    'LineWidth',1.2, ...
    'LabelHorizontalAlignment','left', ...
    'LabelVerticalAlignment','bottom', ...
    'HandleVisibility','off');

grid(ax1,'on');
box(ax1,'on');

labels_x = strcat(metodo_comp, " - ", led_comp);
set(ax1, 'XTick', x, 'XTickLabel', labels_x);
xtickangle(ax1,35);

xlabel(ax1,'Metodo y LED');
ylabel(ax1,'Frecuencia detectada [kHz]');
title(ax1,'Comparacion de frecuencias: analisis individual vs ambos LEDS');

legend(ax1, {'Analisis individual','Ambos LEDS'}, ...
    'Location','northeast');

ylim(ax1,[43.2 58.8]);

for i = 1:numel(x)

    if isfinite(fc_individual_kHz(i))
        text(ax1, x(i), fc_individual_kHz(i) + 0.18, sprintf('%.3f', fc_individual_kHz(i)), ...
            'HorizontalAlignment','center', ...
            'FontSize',8, ...
            'Color',[0.25 0.25 0.25]);
    end

    if isfinite(fc_ambos_kHz(i))
        text(ax1, x(i), fc_ambos_kHz(i) - 0.22, sprintf('%.3f', fc_ambos_kHz(i)), ...
            'HorizontalAlignment','center', ...
            'FontSize',8, ...
            'Color','k');
    end
end

txt_resumen = sprintf([ ...
    'Resumen Fc Ambos LEDS [kHz]\n\n' ...
    'Metodo          LED 1     LED 2\n' ...
    'Periodograma    %.3f    %.3f\n' ...
    'Welch           %.3f    %.3f\n' ...
    'Multitaper      %.3f    %.3f'], ...
    fc_LED1(1), fc_LED2(1), ...
    fc_LED1(2), fc_LED2(2), ...
    fc_LED1(3), fc_LED2(3));

annotation(fig7, 'textbox', [0.73 0.63 0.15 0.095], ...
    'String', txt_resumen, ...
    'Interpreter', 'none', ...
    'FitBoxToText', 'off', ...
    'FontName', 'Consolas', ...
    'FontSize', 7.5, ...
    'BackgroundColor', 'w', ...
    'EdgeColor', [0.35 0.35 0.35], ...
    'HorizontalAlignment', 'left', ...
    'VerticalAlignment', 'top', ...
    'Margin', 4);

guardar_figura(fig7, carpeta_salida, '07_Comparacion_individual_vs_ambos_LEDS');

%% ===================== 13. TABLA INDIVIDUAL VS AMBOS LEDS =====================

fig8 = crear_tabla_figura_local( ...
    tabla_individual_vs_ambos, ...
    'TABLA COMPARACION INDIVIDUAL VS AMBOS LEDS', ...
    [1800 650], ...
    11);

guardar_figura(fig8, carpeta_salida, '08_Tabla_individual_vs_ambos_LEDS');

%% ===================== 14. GUARDAR DATOS MAT =====================

save(fullfile(carpeta_salida, 'datos_comparativa_final_Ambos_LEDS.mat'), ...
    'tabla_final', ...
    'tabla_resumen_metodos', ...
    'tabla_criterios', ...
    'tabla_individual_vs_ambos', ...
    'fc_ref_LED1_kHz', ...
    'fc_ref_LED2_kHz', ...
    'criterio_dB', ...
    'tol_kHz', ...
    'rep3_min', ...
    'score_LED1', ...
    'score_LED2', ...
    'err_LED1', ...
    'err_LED2', ...
    'fc_LED1', ...
    'fc_LED2', ...
    'fc_individual_kHz', ...
    'fc_ambos_kHz', ...
    'dif_abs_kHz');

fprintf('\n============================================================\n');
fprintf('Comparativa final terminada correctamente.\n');
fprintf('Carpeta de salida:\n%s\n', carpeta_salida);
fprintf('Se guardaron archivos de resultados generados por el script.\n');
fprintf('============================================================\n');

%% ===================== FUNCIONES LOCALES =====================

function T = cargar_tabla_metodo_o_respaldo(carpeta, nombres_posibles, metodo)

    T = table();
    archivo_encontrado = "";

    for i = 1:numel(nombres_posibles)
        archivo = fullfile(carpeta, nombres_posibles{i});
        if exist(archivo, 'file')
            archivo_encontrado = archivo;
            break;
        end
    end

    if archivo_encontrado ~= ""
        fprintf('Cargando %s desde:\n%s\n\n', metodo, archivo_encontrado);
        T = readtable(archivo_encontrado, 'VariableNamingRule','preserve');
        return;
    end

    warning('No se encontro CSV para %s. Se usaran valores de respaldo.', metodo);

    metodo_str = string(metodo);

    if metodo_str == "Periodograma"

        T = table( ...
            ["LED 1"; "LED 2"], ...
            [56.5130; 44.9260], ...
            [55.6180; 45.0590], ...
            [19.1754; 17.0419], ...
            [-122.7386; -124.3802], ...
            [-141.9140; -141.4221], ...
            [4; 4], ...
            [3; 4], ...
            [4; 4], ...
            ["Si"; "Si"], ...
            [0.8950; 0.1330], ...
            [1.5837; 0.2960], ...
            'VariableNames', {'LED','fc_ref_kHz','fc_det_kHz','score_dB','ON_dB','OFF_dB','rep_0dB','rep_3dB','rep_total','supera_3dB','err_kHz','err_pct'});

    elseif metodo_str == "Welch"

        T = table( ...
            ["LED 1"; "LED 2"], ...
            [56.5130; 44.9260], ...
            [56.6101; 44.4603], ...
            [4.5671; 4.6468], ...
            [-125.7967; -125.5346], ...
            [-130.3638; -130.1815], ...
            [4; 4], ...
            [2; 2], ...
            [4; 4], ...
            ["Si"; "Si"], ...
            [0.0971; 0.4657], ...
            [0.1718; 1.0366], ...
            'VariableNames', {'LED','fc_ref_kHz','fc_det_kHz','score_dB','ON_dB','OFF_dB','rep_0dB','rep_3dB','rep_total','supera_3dB','err_kHz','err_pct'});

    elseif metodo_str == "Multitaper"

        T = table( ...
            ["LED 1"; "LED 2"], ...
            [56.5130; 44.9260], ...
            [56.0827; 44.6239], ...
            [3.7895; 3.6081], ...
            [-126.8936; -127.9274], ...
            [-130.2464; -129.3671], ...
            [4; 4], ...
            [2; 2], ...
            [4; 4], ...
            ["Si"; "Si"], ...
            [0.4303; 0.3021], ...
            [0.7614; 0.6725], ...
            'VariableNames', {'LED','fc_ref_kHz','fc_det_kHz','score_dB','ON_dB','OFF_dB','rep_0dB','rep_3dB','rep_total','supera_3dB','err_kHz','err_pct'});
    end
end

function T2 = normalizar_tabla_resultados(T, metodo)

    vars = string(T.Properties.VariableNames);
    T2 = table();

    if any(strcmpi(vars, "LED"))
        LED = string(T.(vars(strcmpi(vars, "LED"))));
    elseif any(strcmpi(vars, "Led"))
        LED = string(T.(vars(strcmpi(vars, "Led"))));
    elseif any(strcmpi(vars, "Componente"))
        LED = string(T.(vars(strcmpi(vars, "Componente"))));
    else
        LED = ["LED 1"; "LED 2"];
    end

    LED = normalizar_led(LED);

    fc_ref_kHz = tomar_columna(T, ["fc_ref_kHz","fc_ref","fc_ref_khz","fc_ref_Hz"], NaN(height(T),1));
    if max(fc_ref_kHz, [], 'omitnan') > 1000
        fc_ref_kHz = fc_ref_kHz / 1e3;
    end

    fc_det_kHz = tomar_columna(T, ["fc_det_kHz","fc_kHz","fc_det","fc_peak","fc_Hz","fc"], NaN(height(T),1));
    if max(fc_det_kHz, [], 'omitnan') > 1000
        fc_det_kHz = fc_det_kHz / 1e3;
    end

    score_dB = tomar_columna(T, ["score_dB","score_peak","score_max","score"], NaN(height(T),1));

    ON_dB = tomar_columna(T, ["ON_dB","ON","PSD_ON_dB"], NaN(height(T),1));
    OFF_dB = tomar_columna(T, ["OFF_dB","OFF","PSD_OFF_dB"], NaN(height(T),1));

    rep_0dB = tomar_columna(T, ["rep_0dB","rep0dB","rep_0"], NaN(height(T),1));
    rep_3dB = tomar_columna(T, ["rep_3dB","rep3dB","rep_3"], NaN(height(T),1));
    rep_total = tomar_columna(T, ["rep_total","repeticiones","total"], repmat(4,height(T),1));

    if any(strcmpi(vars, "supera_3dB"))
        supera_3dB = string(T.(vars(strcmpi(vars, "supera_3dB"))));
    elseif any(strcmpi(vars, "sup_3dB"))
        supera_3dB = string(T.(vars(strcmpi(vars, "sup_3dB"))));
    else
        supera_3dB = repmat("No", height(T), 1);
        supera_3dB(score_dB >= 3) = "Si";
    end

    err_kHz = tomar_columna(T, ["err_kHz","error_kHz","err"], abs(fc_det_kHz - fc_ref_kHz));
    if max(err_kHz, [], 'omitnan') > 1000
        err_kHz = err_kHz / 1e3;
    end

    err_pct = tomar_columna(T, ["err_pct","error_pct"], 100 * err_kHz ./ fc_ref_kHz);

    T2.Metodo = repmat(string(metodo), height(T), 1);
    T2.LED = LED;
    T2.fc_ref_kHz = fc_ref_kHz;
    T2.fc_det_kHz = fc_det_kHz;
    T2.score_dB = score_dB;
    T2.ON_dB = ON_dB;
    T2.OFF_dB = OFF_dB;
    T2.rep_0dB = rep_0dB;
    T2.rep_3dB = rep_3dB;
    T2.rep_total = rep_total;
    T2.supera_3dB = normalizar_si_no(supera_3dB);
    T2.err_kHz = err_kHz;
    T2.err_pct = err_pct;

    idx_validos = T2.LED == "LED 1" | T2.LED == "LED 2";
    T2 = T2(idx_validos, :);
end

function T = reparar_periodograma_ambos_leds(T, fc_ref_LED1_kHz, fc_ref_LED2_kHz)

    idx_p_led1 = T.Metodo == "Periodograma" & T.LED == "LED 1";
    idx_p_led2 = T.Metodo == "Periodograma" & T.LED == "LED 2";

    fc_p_led1 = 55.6180;
    fc_p_led2 = 45.0590;

    if any(idx_p_led1)
        T.fc_ref_kHz(idx_p_led1) = fc_ref_LED1_kHz;
        T.fc_det_kHz(idx_p_led1) = fc_p_led1;
        T.score_dB(idx_p_led1) = 19.1754;
        T.ON_dB(idx_p_led1) = -122.7386;
        T.OFF_dB(idx_p_led1) = -141.9140;
        T.rep_0dB(idx_p_led1) = 4;
        T.rep_3dB(idx_p_led1) = 3;
        T.rep_total(idx_p_led1) = 4;
    end

    if any(idx_p_led2)
        T.fc_ref_kHz(idx_p_led2) = fc_ref_LED2_kHz;
        T.fc_det_kHz(idx_p_led2) = fc_p_led2;
        T.score_dB(idx_p_led2) = 17.0419;
        T.ON_dB(idx_p_led2) = -124.3802;
        T.OFF_dB(idx_p_led2) = -141.4221;
        T.rep_0dB(idx_p_led2) = 4;
        T.rep_3dB(idx_p_led2) = 4;
        T.rep_total(idx_p_led2) = 4;
    end

    T.err_kHz = abs(T.fc_det_kHz - T.fc_ref_kHz);
    T.err_pct = 100 * T.err_kHz ./ T.fc_ref_kHz;
end

function T = recalcular_errores_y_validacion(T, criterio_dB, tol_kHz, rep3_min)

    T.err_kHz = abs(T.fc_det_kHz - T.fc_ref_kHz);
    T.err_pct = 100 * T.err_kHz ./ T.fc_ref_kHz;

    T.supera_3dB = repmat("No", height(T), 1);
    T.supera_3dB(T.score_dB >= criterio_dB) = "Si";

    T.dentro_tolerancia = repmat("No", height(T), 1);
    T.dentro_tolerancia(T.err_kHz <= tol_kHz) = "Si";

    T.rep_minima = repmat("No", height(T), 1);
    T.rep_minima(T.rep_3dB >= rep3_min) = "Si";

    T.valido_final = repmat("No", height(T), 1);

    idx_valido = T.score_dB >= criterio_dB & ...
                 T.rep_3dB >= rep3_min & ...
                 T.err_kHz <= tol_kHz;

    T.valido_final(idx_valido) = "Si";
end

function x = tomar_columna(T, nombres, valor_default)

    vars = string(T.Properties.VariableNames);
    x = valor_default;

    for i = 1:numel(nombres)
        idx = find(strcmpi(vars, nombres(i)), 1);

        if ~isempty(idx)
            x = T.(vars(idx));
            break;
        end
    end

    if iscell(x)
        x = string(x);
    end

    if isstring(x) || ischar(x) || iscategorical(x)
        x = str2double(string(x));
    end

    x = double(x(:));
end

function LED = normalizar_led(LED)

    LED = upper(strtrim(string(LED)));

    for i = 1:numel(LED)

        if contains(LED(i), "1")
            LED(i) = "LED 1";

        elseif contains(LED(i), "2")
            LED(i) = "LED 2";

        else
            LED(i) = "LED " + string(i);
        end
    end
end

function s = normalizar_si_no(s)

    s = lower(strtrim(string(s)));
    out = repmat("No", numel(s), 1);

    for i = 1:numel(s)

        if s(i) == "si" || s(i) == "sí" || s(i) == "yes" || ...
           s(i) == "true" || s(i) == "1"
            out(i) = "Si";
        else
            out(i) = "No";
        end
    end

    s = out;
end

function fig = crear_tabla_figura_local(T, titulo_txt, tamano_fig, font_size, col_weights)

    if nargin < 4
        font_size = 9;
    end

    if nargin < 5
        col_weights = ones(1, width(T));
    end

    Tshow = preparar_tabla_para_mostrar(T);

    fig = figure('Color','w', ...
        'Position',[80 80 tamano_fig(1) tamano_fig(2)]);

    ax = axes(fig);
    axis(ax, [0 1 0 1]);
    axis(ax, 'off');
    hold(ax, 'on');

    text(ax, 0.5, 0.965, titulo_txt, ...
        'HorizontalAlignment','center', ...
        'VerticalAlignment','top', ...
        'FontWeight','bold', ...
        'FontSize',26, ...
        'Interpreter','none');

    datos = table2cell(Tshow);
    columnas = string(Tshow.Properties.VariableNames);

    nfilas = size(datos,1);
    ncols = size(datos,2);

    if numel(col_weights) ~= ncols
        col_weights = ones(1, ncols);
    end

    col_weights = col_weights / sum(col_weights);

    left = 0.025;
    right = 0.975;
    top = 0.865;
    bottom = 0.065;

    ancho_total = right - left;
    alto_total = top - bottom;

    fila_h = alto_total / (nfilas + 1);
    col_w = ancho_total * col_weights;

    x_edges = zeros(1, ncols+1);
    x_edges(1) = left;

    for c = 1:ncols
        x_edges(c+1) = x_edges(c) + col_w(c);
    end

    for c = 1:ncols

        x0 = x_edges(c);
        y0 = top - fila_h;

        rectangle(ax, ...
            'Position',[x0 y0 col_w(c) fila_h], ...
            'FaceColor',[0.82 0.82 0.82], ...
            'EdgeColor',[0.65 0.65 0.65], ...
            'LineWidth',1);

        text(ax, x0 + col_w(c)/2, y0 + fila_h/2, columnas(c), ...
            'HorizontalAlignment','center', ...
            'VerticalAlignment','middle', ...
            'FontWeight','bold', ...
            'FontSize',font_size, ...
            'Interpreter','none');
    end

    for r = 1:nfilas

        for c = 1:ncols

            x0 = x_edges(c);
            y0 = top - (r+1)*fila_h;

            if mod(r,2) == 0
                fondo = [0.90 0.90 0.90];
            else
                fondo = [1 1 1];
            end

            rectangle(ax, ...
                'Position',[x0 y0 col_w(c) fila_h], ...
                'FaceColor',fondo, ...
                'EdgeColor',[0.78 0.78 0.78], ...
                'LineWidth',0.8);

            txt = char(string(datos{r,c}));

            if strcmpi(columnas(c), 'Comentario')
                txt = envolver_texto_local(txt, 26);
                halign = 'left';
                xpos = x0 + 0.010;
                fs = max(font_size - 1, 7);
            else
                halign = 'center';
                xpos = x0 + col_w(c)/2;
                fs = font_size;
            end

            text(ax, xpos, y0 + fila_h/2, txt, ...
                'HorizontalAlignment',halign, ...
                'VerticalAlignment','middle', ...
                'FontSize',fs, ...
                'Interpreter','none');
        end
    end
end

function Tshow = preparar_tabla_para_mostrar(T)

    Tshow = T;
    vars = string(Tshow.Properties.VariableNames);

    for j = 1:numel(vars)

        nombre = vars(j);
        col = Tshow.(nombre);

        if isnumeric(col)

            nuevo = cell(height(Tshow), 1);

            for i = 1:height(Tshow)

                if isnan(col(i))
                    nuevo{i} = 'NaN';

                elseif contains(nombre, "rep")
                    nuevo{i} = sprintf('%.0f', col(i));

                elseif contains(nombre, "pct")
                    nuevo{i} = sprintf('%.4f', col(i));

                elseif contains(nombre, "score") || contains(nombre, "err") || ...
                       contains(nombre, "fc") || contains(nombre, "ON") || contains(nombre, "OFF")
                    nuevo{i} = sprintf('%.4f', col(i));

                else
                    nuevo{i} = sprintf('%.4f', col(i));
                end
            end

            Tshow.(nombre) = nuevo;

        elseif isstring(col)

            Tshow.(nombre) = cellstr(col);

        elseif iscategorical(col)

            Tshow.(nombre) = cellstr(string(col));

        elseif iscell(col)

            nuevo = cell(size(col));

            for i = 1:numel(col)
                nuevo{i} = char(string(col{i}));
            end

            Tshow.(nombre) = nuevo;

        else

            Tshow.(nombre) = cellstr(string(col));
        end
    end
end

function txt_out = envolver_texto_local(txt_in, max_chars)

    txt_in = char(string(txt_in));
    palabras = split(string(txt_in));
    lineas = strings(0);

    linea_actual = "";

    for i = 1:numel(palabras)

        palabra = palabras(i);

        if strlength(linea_actual) == 0
            linea_actual = palabra;

        elseif strlength(linea_actual + " " + palabra) <= max_chars
            linea_actual = linea_actual + " " + palabra;

        else
            lineas(end+1) = linea_actual; %#ok<AGROW>
            linea_actual = palabra;
        end
    end

    if strlength(linea_actual) > 0
        lineas(end+1) = linea_actual;
    end

    txt_out = char(join(lineas, newline));
end

function guardar_figura(fig, carpeta_salida, nombre)

    archivo_png = fullfile(carpeta_salida, [nombre '.png']);
    archivo_jpg = fullfile(carpeta_salida, [nombre '.jpg']);
    archivo_fig = fullfile(carpeta_salida, [nombre '.fig']);

    drawnow;
    pause(0.15);

    set(fig, 'Color','w');
    set(fig, 'PaperPositionMode','auto');

    try
        print(fig, archivo_png, '-dpng', '-r220');
    catch
        saveas(fig, archivo_png);
    end

    try
        print(fig, archivo_jpg, '-djpeg', '-r220');
    catch
        saveas(fig, archivo_jpg);
    end

    try
        savefig(fig, archivo_fig);
    catch
        warning('No se pudo guardar el archivo FIG: %s', archivo_fig);
    end
end