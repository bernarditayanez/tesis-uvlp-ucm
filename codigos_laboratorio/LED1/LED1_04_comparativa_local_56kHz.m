%% LED1_04_comparativa_local_56kHz_version_A.m
%
% INSTRUCCIONES DE USO
% Antes de ejecutar este script, revisar la variable carpeta_base
% y modificarla si los resultados del LED 1 se encuentran en otra ruta local.
% La carpeta indicada debe contener las subcarpetas 01_Periodogram,
% 02_Welch y 03_Multitaper, con los archivos .mat generados previamente
% por los scripts de cada metodo.
%
% Ejemplo:
% carpeta_base = 'C:\Users\NombreUsuario\Desktop\Pruebas (LED 1)\Resultados_LED1_modificados';

clear; 
clc; 
close all;

%% 1. Rutas

carpeta_base = 'C:\Users\mudrood\Desktop\Modulo Prof\Archivos Tesis\Toma de Datos\Pruebas (LED 1)\Resultados_LED1_modificados';

carpeta_periodograma = fullfile(carpeta_base, '01_Periodogram');
carpeta_welch        = fullfile(carpeta_base, '02_Welch');
carpeta_mt           = fullfile(carpeta_base, '03_Multitaper');

carpeta_salida = fullfile(carpeta_base, '04_Comparativa');

if ~exist(carpeta_salida, 'dir')
    mkdir(carpeta_salida);
end

archivo_periodograma = fullfile(carpeta_periodograma, 'datos_periodogram_LED1_graficas_v2.mat');
archivo_welch        = fullfile(carpeta_welch, 'datos_welch_LED1_graficas_v2.mat');
archivo_mt           = fullfile(carpeta_mt, 'datos_MT_LED1_V2_local_56kHz.mat');

if ~isfile(archivo_periodograma)
    error('No se encontro el archivo Periodograma:\n%s', archivo_periodograma);
end

if ~isfile(archivo_welch)
    error('No se encontro el archivo Welch:\n%s', archivo_welch);
end

if ~isfile(archivo_mt)
    error('No se encontro el archivo Multitaper:\n%s', archivo_mt);
end

fprintf('\n============================================\n');
fprintf('COMPARATIVA FINAL LED 1\n');
fprintf('============================================\n');

fprintf('\nArchivo Periodograma:\n%s\n', archivo_periodograma);
fprintf('\nArchivo Welch:\n%s\n', archivo_welch);
fprintf('\nArchivo Multitaper:\n%s\n', archivo_mt);

%% 2. Parametros de comparacion

fc_ref_Hz = 56.4e3;

tolerancia_abs_Hz = 2000; 

ancho_grafica_local_Hz = 2500; 

criterio_dB = 3;

%% 3. Cargar datos

Dper = load(archivo_periodograma);
Dwel = load(archivo_welch);
Dmt  = load(archivo_mt);

%% 4. Extraer resultados principales

res_periodograma = extraer_resultado_metodo(Dper, 'Periodograma');
res_welch        = extraer_resultado_metodo(Dwel, 'Welch');
res_mt           = extraer_resultado_metodo(Dmt,  'Multitaper local');

fc_metodos_Hz = [
    res_periodograma.fc_local_Hz
    res_welch.fc_local_Hz
    res_mt.fc_local_Hz
];

score_metodos_dB = [
    res_periodograma.score_local_dB
    res_welch.score_local_dB
    res_mt.score_local_dB
];

ON_metodos_dB = [
    res_periodograma.ON_dB
    res_welch.ON_dB
    res_mt.ON_dB
];

OFF_metodos_dB = [
    res_periodograma.OFF_dB
    res_welch.OFF_dB
    res_mt.OFF_dB
];

metodos = {
    'Periodograma'
    'Welch'
    'Multitaper local'
};

%% 5. Calcular parametros comparativos

fc_promedio_Hz  = mean(fc_metodos_Hz, 'omitnan');
fc_promedio_kHz = fc_promedio_Hz / 1e3;

fc_min_Hz = min(fc_metodos_Hz);
fc_max_Hz = max(fc_metodos_Hz);

rango_frecuencias_Hz  = fc_max_Hz - fc_min_Hz;
rango_frecuencias_kHz = rango_frecuencias_Hz / 1e3;

variacion_max_pct = rango_frecuencias_Hz / fc_promedio_Hz * 100;

desv_abs_Hz       = abs(fc_metodos_Hz - fc_promedio_Hz);
desv_abs_kHz      = desv_abs_Hz / 1e3;
desv_relativa_pct = desv_abs_Hz ./ fc_promedio_Hz * 100;

dentro_tolerancia = desv_abs_Hz <= tolerancia_abs_Hz;
supera_3dB        = score_metodos_dB >= criterio_dB;

%% 6. Crear tablas resumen

tabla_comparativa = table( ...
    metodos, ...
    fc_metodos_Hz, ...
    fc_metodos_Hz/1e3, ...
    score_metodos_dB, ...
    ON_metodos_dB, ...
    OFF_metodos_dB, ...
    supera_3dB, ...
    desv_abs_kHz, ...
    desv_relativa_pct, ...
    dentro_tolerancia, ...
    'VariableNames', { ...
    'Metodo', ...
    'fc_local_Hz', ...
    'fc_local_kHz', ...
    'score_local_dB', ...
    'ON_dB', ...
    'OFF_dB', ...
    'supera_3dB', ...
    'desv_abs_kHz', ...
    'desv_relativa_pct', ...
    'dentro_tolerancia'});

tabla_parametros = table( ...
    fc_ref_Hz, ...
    fc_ref_Hz/1e3, ...
    tolerancia_abs_Hz, ...
    tolerancia_abs_Hz/1e3, ...
    fc_promedio_Hz, ...
    fc_promedio_kHz, ...
    fc_min_Hz, ...
    fc_max_Hz, ...
    rango_frecuencias_kHz, ...
    variacion_max_pct, ...
    criterio_dB, ...
    'VariableNames', { ...
    'fc_ref_Hz', ...
    'fc_ref_kHz', ...
    'tolerancia_abs_Hz', ...
    'tolerancia_abs_kHz', ...
    'fc_promedio_Hz', ...
    'fc_promedio_kHz', ...
    'fc_min_Hz', ...
    'fc_max_Hz', ...
    'rango_frecuencias_kHz', ...
    'variacion_max_pct', ...
    'criterio_dB'});

%% 7. Mostrar resultados en consola

fprintf('\n============================================\n');
fprintf('TABLA RESUMEN FINAL COMPARATIVA LED 1\n');
fprintf('============================================\n');
disp(tabla_comparativa);

fprintf('\n============================================\n');
fprintf('PARAMETROS COMPARATIVA LOCAL LED 1\n');
fprintf('============================================\n');
disp(tabla_parametros);

fprintf('\nResumen:\n');
fprintf('fc promedio = %.3f Hz = %.4f kHz\n', fc_promedio_Hz, fc_promedio_kHz);
fprintf('Rango entre metodos = %.4f kHz\n', rango_frecuencias_kHz);
fprintf('Variacion maxima relativa = %.3f %%\n', variacion_max_pct);
fprintf('Tolerancia usada = +/- %.3f kHz\n', tolerancia_abs_Hz/1e3);

if all(dentro_tolerancia)
    fprintf('Resultado: los tres metodos quedan dentro de la tolerancia definida.\n');
else
    fprintf('Resultado: al menos un metodo queda fuera de la tolerancia definida.\n');
end

%% 8. Guardar tablas

writetable(tabla_comparativa, fullfile(carpeta_salida, 'tabla_comparativa_LED1.csv'));
writetable(tabla_parametros, fullfile(carpeta_salida, 'tabla_parametros_comparativa_LED1.csv'));

%% Tabla de parametros como figura, solo en kHz

tabla_parametros_fig = tabla_parametros;

if ismember('fc_min_Hz', tabla_parametros_fig.Properties.VariableNames)
    tabla_parametros_fig.fc_min_kHz = tabla_parametros_fig.fc_min_Hz / 1e3;
end

if ismember('fc_max_Hz', tabla_parametros_fig.Properties.VariableNames)
    tabla_parametros_fig.fc_max_kHz = tabla_parametros_fig.fc_max_Hz / 1e3;
end

cols_eliminar_parametros = { ...
    'fc_ref_Hz', ...
    'tolerancia_abs_Hz', ...
    'fc_promedio_Hz', ...
    'fc_min_Hz', ...
    'fc_max_Hz'};

for c = 1:numel(cols_eliminar_parametros)
    if ismember(cols_eliminar_parametros{c}, tabla_parametros_fig.Properties.VariableNames)
        tabla_parametros_fig.(cols_eliminar_parametros{c}) = [];
    end
end

cols_parametros_orden = { ...
    'fc_ref_kHz', ...
    'tolerancia_abs_kHz', ...
    'fc_promedio_kHz', ...
    'fc_min_kHz', ...
    'fc_max_kHz', ...
    'rango_frecuencias_kHz', ...
    'variacion_max_pct', ...
    'criterio_dB'};

cols_existentes = intersect(cols_parametros_orden, tabla_parametros_fig.Properties.VariableNames, 'stable');
tabla_parametros_fig = tabla_parametros_fig(:, cols_existentes);

guardar_tabla_como_figura( ...
    tabla_parametros_fig, ...
    'PARAMETROS COMPARATIVA LOCAL LED 1', ...
    fullfile(carpeta_salida, 'tabla_parametros_comparativa_LED1.png'), ...
    fullfile(carpeta_salida, 'tabla_parametros_comparativa_LED1.fig'));

%% Tabla resumen comparativa como figura, solo en kHz

tabla_comparativa_fig = tabla_comparativa;

if ismember('fc_local_Hz', tabla_comparativa_fig.Properties.VariableNames)
    tabla_comparativa_fig.fc_local_Hz = [];
end

tabla_comparativa_fig.Properties.VariableNames = { ...
    'Metodo', ...
    'fc_local_kHz', ...
    'score_local', ...
    'ON_dB', ...
    'OFF_dB', ...
    'supera_3dB', ...
    'desv_abs_kHz', ...
    'desv_rel_pct', ...
    'dentro_tol'};

guardar_tabla_como_figura( ...
    tabla_comparativa_fig, ...
    'TABLA RESUMEN FINAL COMPARATIVA LED 1', ...
    fullfile(carpeta_salida, 'tabla_comparativa_LED1.png'), ...
    fullfile(carpeta_salida, 'tabla_comparativa_LED1.fig'));

%% 9. Figura 1: frecuencia detectada por metodo

fig = figure('Color','w','Position',[100 100 1350 720]);

x = 1:numel(metodos);

b = bar(x, fc_metodos_Hz/1e3, 0.65);
b.FaceColor = 'flat';
b.CData = [ ...
    0.0000 0.4470 0.7410;   
    0.8500 0.3250 0.0980;   
    0.9290 0.6940 0.1250];  

hold on;
grid on;
box on;

yline(fc_ref_Hz/1e3, '--', sprintf('Referencia %.1f kHz', fc_ref_Hz/1e3), ...
    'LineWidth', 1.2, ...
    'LabelHorizontalAlignment','left', ...
    'HandleVisibility','off');

yline(fc_promedio_Hz/1e3, ':', sprintf('Promedio %.3f kHz', fc_promedio_Hz/1e3), ...
    'LineWidth', 1.4, ...
    'LabelHorizontalAlignment','right', ...
    'HandleVisibility','off');

xlabel('Metodo');
ylabel('Frecuencia local [kHz]');
title('LED 1 - Frecuencia local estimada por método', 'Interpreter','none');

xticks(x);
xticklabels(metodos);
xtickangle(25);

ylim([min(fc_metodos_Hz/1e3)-0.8, max(fc_metodos_Hz/1e3)+0.8]);

for i = 1:numel(metodos)
    text(x(i), fc_metodos_Hz(i)/1e3 + 0.08, ...
        sprintf('%.3f kHz\n%.2f dB', fc_metodos_Hz(i)/1e3, score_metodos_dB(i)), ...
        'HorizontalAlignment','center', ...
        'VerticalAlignment','bottom', ...
        'FontSize',9);
end

saveas(fig, fullfile(carpeta_salida, 'comparativa_LED1_frecuencia_por_metodo.png'));
savefig(fig, fullfile(carpeta_salida, 'comparativa_LED1_frecuencia_por_metodo.fig'));

%% 10. Figura 2: score maximo por metodo

fig = figure('Color','w','Position',[100 100 1350 720]);

b = bar(x, score_metodos_dB, 0.65);
b.FaceColor = 'flat';
b.CData = [ ...
    0.0000 0.4470 0.7410;   
    0.8500 0.3250 0.0980;   
    0.9290 0.6940 0.1250];  

hold on;
grid on;
box on;

yline(criterio_dB, '--', sprintf('Criterio %.1f dB', criterio_dB), ...
    'LineWidth', 1.2, ...
    'LabelHorizontalAlignment','right', ...
    'HandleVisibility','off');

yline(0, '--', '0 dB', ...
    'HandleVisibility','off');

xlabel('Metodo');
ylabel('Score local maximo ON-OFF [dB]');
title('LED 1 - Score local máximo por método', 'Interpreter','none');

xticks(x);
xticklabels(metodos);
xtickangle(25);

ylim([0, max(score_metodos_dB)+4]);

for i = 1:numel(metodos)
    text(x(i), score_metodos_dB(i) + 0.45, ...
        sprintf('%.2f dB\n%.3f kHz', ...
        score_metodos_dB(i), ...
        fc_metodos_Hz(i)/1e3), ...
        'HorizontalAlignment','center', ...
        'VerticalAlignment','bottom', ...
        'FontSize',9);
end

saveas(fig, fullfile(carpeta_salida, 'comparativa_LED1_score_por_metodo.png'));
savefig(fig, fullfile(carpeta_salida, 'comparativa_LED1_score_por_metodo.fig'));

%% 11. Extraer curvas para graficas de score

fmin_local = fc_promedio_Hz - ancho_grafica_local_Hz;
fmax_local = fc_promedio_Hz + ancho_grafica_local_Hz;

[f_per, score_per] = extraer_curva_score(Dper);
[f_wel, score_wel] = extraer_curva_score(Dwel);
[f_mt,  score_mt]  = extraer_curva_score(Dmt);

%% 12. Figura 3: comparativa local de score en 2D

fig = figure('Color','w','Position',[100 100 1600 720]);
hold on;

graficar_score_local(f_per, score_per, fmin_local, fmax_local, 'Periodograma');
graficar_score_local(f_wel, score_wel, fmin_local, fmax_local, 'Welch');
graficar_score_local(f_mt,  score_mt,  fmin_local, fmax_local, 'Multitaper local');

plot(fc_metodos_Hz/1e3, score_metodos_dB, 'ko', ...
    'MarkerSize', 8, ...
    'LineWidth', 1.5, ...
    'DisplayName','Maximos locales');

xline(fc_ref_Hz/1e3, '--', ...
    'LineWidth', 1.2, ...
    'HandleVisibility','off');

xline(fc_promedio_Hz/1e3, ':', ...
    'LineWidth', 1.3, ...
    'HandleVisibility','off');

yline(criterio_dB, '--', sprintf('Criterio %.1f dB', criterio_dB), ...
    'HandleVisibility','off', ...
    'LabelHorizontalAlignment','right');

yline(0, '--', '0 dB', ...
    'HandleVisibility','off', ...
    'LabelHorizontalAlignment','right');

grid on;
box on;

xlabel('Frecuencia [kHz]');
ylabel('Score ON - OFF [dB]');
title('LED 1 - Comparativa local de score entre métodos', 'Interpreter','none');

xlim([fmin_local fmax_local]/1e3);
ylim([-15 20]);

yl = ylim;
y_lbl_local = yl(2) - 2.4;

text(fc_ref_Hz/1e3 - 0.035, y_lbl_local, ...
    sprintf('Ref. %.1f kHz', fc_ref_Hz/1e3), ...
    'Rotation',90, ...
    'HorizontalAlignment','right', ...
    'VerticalAlignment','middle', ...
    'FontSize',9, ...
    'FontWeight','bold', ...
    'BackgroundColor','w', ...
    'Margin',0.5);

text(fc_promedio_Hz/1e3 + 0.035, y_lbl_local, ...
    sprintf('Prom. %.3f kHz', fc_promedio_Hz/1e3), ...
    'Rotation',-90, ...
    'HorizontalAlignment','left', ...
    'VerticalAlignment','middle', ...
    'FontSize',9, ...
    'FontWeight','bold', ...
    'BackgroundColor','w', ...
    'Margin',0.5);

lgd = legend('Location','eastoutside');
lgd.Box = 'on';

saveas(fig, fullfile(carpeta_salida, 'comparativa_LED1_score_local_metodos_2D.png'));
savefig(fig, fullfile(carpeta_salida, 'comparativa_LED1_score_local_metodos_2D.fig'));

%% 13. Figura 4: comparativa tipo cascada de score ON-OFF entre metodos

fig = figure('Color','w','Position',[100 100 1800 820]);
hold on;
grid on;
box on;

idx_per = f_per >= fmin_local & f_per <= fmax_local;
idx_wel = f_wel >= fmin_local & f_wel <= fmax_local;
idx_mt  = f_mt  >= fmin_local & f_mt  <= fmax_local;

offset_periodograma = 0;
offset_welch        = 32;
offset_mt           = 65;

plot(f_per(idx_per)/1e3, score_per(idx_per) + offset_periodograma, ...
    'LineWidth', 1.0, ...
    'DisplayName','Periodograma');

plot(f_wel(idx_wel)/1e3, score_wel(idx_wel) + offset_welch, ...
    'LineWidth', 1.0, ...
    'DisplayName','Welch');

plot(f_mt(idx_mt)/1e3, score_mt(idx_mt) + offset_mt, ...
    'LineWidth', 1.0, ...
    'DisplayName','Multitaper local');

yline(offset_periodograma, ':', 'HandleVisibility','off');
yline(offset_welch, ':', 'HandleVisibility','off');
yline(offset_mt, ':', 'HandleVisibility','off');

yline(offset_periodograma + criterio_dB, '--', 'HandleVisibility','off');
yline(offset_welch + criterio_dB, '--', 'HandleVisibility','off');
yline(offset_mt + criterio_dB, '--', 'HandleVisibility','off');

plot(fc_metodos_Hz(1)/1e3, score_metodos_dB(1) + offset_periodograma, ...
    'ko', ...
    'MarkerSize',9, ...
    'LineWidth',1.8, ...
    'MarkerFaceColor','w', ...
    'DisplayName','Maximo Periodograma');

plot(fc_metodos_Hz(2)/1e3, score_metodos_dB(2) + offset_welch, ...
    'ks', ...
    'MarkerSize',8, ...
    'LineWidth',1.6, ...
    'MarkerFaceColor','w', ...
    'DisplayName','Maximo Welch');

plot(fc_metodos_Hz(3)/1e3, score_metodos_dB(3) + offset_mt, ...
    'k*', ...
    'MarkerSize',11, ...
    'LineWidth',1.6, ...
    'DisplayName','Maximo Multitaper');

text(fc_metodos_Hz(1)/1e3 - 0.05, score_metodos_dB(1) + offset_periodograma + 1.6, ...
    sprintf('%.3f kHz\n%.2f dB', fc_metodos_Hz(1)/1e3, score_metodos_dB(1)), ...
    'HorizontalAlignment','right', ...
    'VerticalAlignment','bottom', ...
    'FontSize',8, ...
    'BackgroundColor','w', ...
    'Margin',0.5);

text(fc_metodos_Hz(2)/1e3 + 0.04, score_metodos_dB(2) + offset_welch + 1.6, ...
    sprintf('%.3f kHz\n%.2f dB', fc_metodos_Hz(2)/1e3, score_metodos_dB(2)), ...
    'HorizontalAlignment','left', ...
    'VerticalAlignment','bottom', ...
    'FontSize',8, ...
    'BackgroundColor','w', ...
    'Margin',0.5);

text(fc_metodos_Hz(3)/1e3 + 0.08, score_metodos_dB(3) + offset_mt + 1.6, ...
    sprintf('%.3f kHz\n%.2f dB', fc_metodos_Hz(3)/1e3, score_metodos_dB(3)), ...
    'HorizontalAlignment','left', ...
    'VerticalAlignment','bottom', ...
    'FontSize',8, ...
    'BackgroundColor','w', ...
    'Margin',0.5);

xline(fc_ref_Hz/1e3, '--', ...
    'LineWidth',1.2, ...
    'HandleVisibility','off');

xline(fc_promedio_Hz/1e3, ':', ...
    'LineWidth',1.2, ...
    'HandleVisibility','off');

xlabel('Frecuencia [kHz]');
ylabel('Score ON-OFF desplazado [dB]');
title('LED 1 - Comparativa tipo cascada de score ON-OFF entre metodos', ...
    'Interpreter','none');

xlim([fmin_local fmax_local]/1e3);

y_top = offset_mt + max(score_mt(idx_mt)) + 8;
ylim([min(score_per(idx_per)) - 5, y_top + 4]);

yl = ylim;
y_lbl_casc = yl(2) - 8.5;

text(fc_ref_Hz/1e3 - 0.035, y_lbl_casc, ...
    sprintf('Ref. %.1f kHz', fc_ref_Hz/1e3), ...
    'Rotation',90, ...
    'HorizontalAlignment','right', ...
    'VerticalAlignment','middle', ...
    'FontSize',10, ...
    'FontWeight','bold', ...
    'BackgroundColor','w', ...
    'Margin',0.5);

text(fc_promedio_Hz/1e3 + 0.035, y_lbl_casc, ...
    sprintf('Prom. %.3f kHz', fc_promedio_Hz/1e3), ...
    'Rotation',-90, ...
    'HorizontalAlignment','left', ...
    'VerticalAlignment','middle', ...
    'FontSize',10, ...
    'FontWeight','bold', ...
    'BackgroundColor','w', ...
    'Margin',0.5);

x_texto = fmin_local/1e3 + 0.03;

text(x_texto, offset_periodograma + 1.8, 'Periodograma', ...
    'FontWeight','bold', ...
    'FontSize',11, ...
    'BackgroundColor','w', ...
    'Margin',0.5);

text(x_texto, offset_welch + 1.8, 'Welch', ...
    'FontWeight','bold', ...
    'FontSize',11, ...
    'BackgroundColor','w', ...
    'Margin',0.5);

text(x_texto, offset_mt + 1.8, 'Multitaper local', ...
    'FontWeight','bold', ...
    'FontSize',11, ...
    'BackgroundColor','w', ...
    'Margin',0.5);

lgd = legend('Location','eastoutside');
lgd.Box = 'on';

saveas(fig, fullfile(carpeta_salida, ...
    'comparativa_LED1_score_cascada_2D.png'));

savefig(fig, fullfile(carpeta_salida, ...
    'comparativa_LED1_score_cascada_2D.fig'));

%% 14. Figura 5: comparativa 3D separada por metodo

fig = figure('Color','w','Position',[100 100 1750 850]);
hold on;

idx_per = f_per >= fmin_local & f_per <= fmax_local;
idx_wel = f_wel >= fmin_local & f_wel <= fmax_local;
idx_mt  = f_mt  >= fmin_local & f_mt  <= fmax_local;

y_periodograma = 1;
y_welch        = 2.2;
y_mt           = 3.4;

plot3(f_per(idx_per)/1e3, y_periodograma*ones(sum(idx_per),1), score_per(idx_per), ...
    'LineWidth',1.0, ...
    'DisplayName','Periodograma');

plot3(f_wel(idx_wel)/1e3, y_welch*ones(sum(idx_wel),1), score_wel(idx_wel), ...
    'LineWidth',1.0, ...
    'DisplayName','Welch');

plot3(f_mt(idx_mt)/1e3, y_mt*ones(sum(idx_mt),1), score_mt(idx_mt), ...
    'LineWidth',1.0, ...
    'DisplayName','Multitaper local');

[Xp,Yp] = meshgrid( ...
    linspace(fmin_local/1e3, fmax_local/1e3, 60), ...
    linspace(0.7, 3.7, 8));

Zp = criterio_dB * ones(size(Xp));

surf(Xp, Yp, Zp, ...
    'FaceColor',[0.85 0.85 0.85], ...
    'FaceAlpha',0.10, ...
    'EdgeColor','none', ...
    'DisplayName','Plano criterio 3 dB');

plot3(fc_metodos_Hz(1)/1e3, y_periodograma, score_metodos_dB(1), ...
    'ko', ...
    'MarkerSize',10, ...
    'LineWidth',2.0, ...
    'MarkerFaceColor','w', ...
    'DisplayName','Maximo Periodograma');

plot3(fc_metodos_Hz(2)/1e3, y_welch, score_metodos_dB(2), ...
    'ks', ...
    'MarkerSize',8, ...
    'LineWidth',1.6, ...
    'MarkerFaceColor','w', ...
    'DisplayName','Maximo Welch');

plot3(fc_metodos_Hz(3)/1e3, y_mt, score_metodos_dB(3), ...
    'k*', ...
    'MarkerSize',11, ...
    'LineWidth',1.6, ...
    'DisplayName','Maximo Multitaper');

text(fc_metodos_Hz(1)/1e3 - 0.12, y_periodograma + 0.08, score_metodos_dB(1) + 1.2, ...
    sprintf('%.3f kHz\n%.2f dB', fc_metodos_Hz(1)/1e3, score_metodos_dB(1)), ...
    'FontSize',8, ...
    'BackgroundColor','w', ...
    'Margin',0.5);

text(fc_metodos_Hz(2)/1e3 + 0.06, y_welch + 0.08, score_metodos_dB(2) + 1.2, ...
    sprintf('%.3f kHz\n%.2f dB', fc_metodos_Hz(2)/1e3, score_metodos_dB(2)), ...
    'FontSize',8, ...
    'BackgroundColor','w', ...
    'Margin',0.5);

text(fc_metodos_Hz(3)/1e3 + 0.06, y_mt + 0.08, score_metodos_dB(3) + 1.2, ...
    sprintf('%.3f kHz\n%.2f dB', fc_metodos_Hz(3)/1e3, score_metodos_dB(3)), ...
    'FontSize',8, ...
    'BackgroundColor','w', ...
    'Margin',0.5);

plot3([fc_ref_Hz fc_ref_Hz]/1e3, [0.7 3.7], [criterio_dB criterio_dB], ...
    'k--', ...
    'LineWidth',1.1, ...
    'DisplayName','Referencia 56.4 kHz');

plot3([fc_promedio_Hz fc_promedio_Hz]/1e3, [0.7 3.7], [criterio_dB criterio_dB], ...
    'k:', ...
    'LineWidth',1.3, ...
    'DisplayName','Promedio de metodos');

grid on;
box on;

xlabel('Frecuencia [kHz]');
ylabel('Metodo');
zlabel('Score ON-OFF [dB]');
title('LED 1 - Comparativa 3D de score ON-OFF entre metodos', ...
    'Interpreter','none');

yticks([y_periodograma y_welch y_mt]);
yticklabels({'Periodograma','Welch','Multitaper local'});

xlim([fmin_local fmax_local]/1e3);
ylim([0.7 3.7]);

z_min = min([score_per(idx_per); score_wel(idx_wel); score_mt(idx_mt)]) - 2;
z_max = max([score_per(idx_per); score_wel(idx_wel); score_mt(idx_mt)]) + 4;
zlim([z_min z_max]);

view(-40, 22);
pbaspect([2.2 1.1 0.9]);

lgd = legend('Location','eastoutside');
lgd.Box = 'on';

saveas(fig, fullfile(carpeta_salida, ...
    'comparativa_LED1_score_3D_metodos.png'));

savefig(fig, fullfile(carpeta_salida, ...
    'comparativa_LED1_score_3D_metodos.fig'));

%% 15. Figura 6: comparativa 3D tipo cascada de score ON-OFF

fig = figure('Color','w','Position',[100 100 1750 850]);
hold on;

z_base = z_min;

x_per_kHz = f_per(idx_per)/1e3;
y_per_3d  = y_periodograma*ones(sum(idx_per),1);
z_per_3d  = score_per(idx_per);

plot3(x_per_kHz, y_per_3d, z_per_3d, ...
    'LineWidth',1.0, ...
    'DisplayName','Periodograma');

patch([x_per_kHz; flipud(x_per_kHz)], ...
      [y_per_3d;  flipud(y_per_3d)], ...
      [z_per_3d;  z_base*ones(size(z_per_3d))], ...
      [0 0.4470 0.7410], ...
      'FaceAlpha',0.08, ...
      'EdgeColor','none', ...
      'HandleVisibility','off');

x_wel_kHz = f_wel(idx_wel)/1e3;
y_wel_3d  = y_welch*ones(sum(idx_wel),1);
z_wel_3d  = score_wel(idx_wel);

plot3(x_wel_kHz, y_wel_3d, z_wel_3d, ...
    'LineWidth',1.0, ...
    'DisplayName','Welch');

patch([x_wel_kHz; flipud(x_wel_kHz)], ...
      [y_wel_3d;  flipud(y_wel_3d)], ...
      [z_wel_3d;  z_base*ones(size(z_wel_3d))], ...
      [0.8500 0.3250 0.0980], ...
      'FaceAlpha',0.08, ...
      'EdgeColor','none', ...
      'HandleVisibility','off');

x_mt_kHz = f_mt(idx_mt)/1e3;
y_mt_3d  = y_mt*ones(sum(idx_mt),1);
z_mt_3d  = score_mt(idx_mt);

plot3(x_mt_kHz, y_mt_3d, z_mt_3d, ...
    'LineWidth',1.0, ...
    'DisplayName','Multitaper local');

patch([x_mt_kHz; flipud(x_mt_kHz)], ...
      [y_mt_3d;  flipud(y_mt_3d)], ...
      [z_mt_3d;  z_base*ones(size(z_mt_3d))], ...
      [0.9290 0.6940 0.1250], ...
      'FaceAlpha',0.08, ...
      'EdgeColor','none', ...
      'HandleVisibility','off');

surf(Xp, Yp, Zp, ...
    'FaceColor',[0.85 0.85 0.85], ...
    'FaceAlpha',0.10, ...
    'EdgeColor','none', ...
    'DisplayName','Plano criterio 3 dB');

plot3(fc_metodos_Hz(1)/1e3, y_periodograma, score_metodos_dB(1), ...
    'ko', ...
    'MarkerSize',10, ...
    'LineWidth',2.0, ...
    'MarkerFaceColor','w', ...
    'DisplayName','Maximo Periodograma');

plot3(fc_metodos_Hz(2)/1e3, y_welch, score_metodos_dB(2), ...
    'ks', ...
    'MarkerSize',8, ...
    'LineWidth',1.6, ...
    'MarkerFaceColor','w', ...
    'DisplayName','Maximo Welch');

plot3(fc_metodos_Hz(3)/1e3, y_mt, score_metodos_dB(3), ...
    'k*', ...
    'MarkerSize',11, ...
    'LineWidth',1.6, ...
    'DisplayName','Maximo Multitaper');

text(fc_metodos_Hz(1)/1e3 - 0.12, y_periodograma + 0.08, score_metodos_dB(1) + 1.2, ...
    sprintf('%.3f kHz\n%.2f dB', fc_metodos_Hz(1)/1e3, score_metodos_dB(1)), ...
    'FontSize',8, ...
    'BackgroundColor','w', ...
    'Margin',0.5);

text(fc_metodos_Hz(2)/1e3 + 0.06, y_welch + 0.08, score_metodos_dB(2) + 1.2, ...
    sprintf('%.3f kHz\n%.2f dB', fc_metodos_Hz(2)/1e3, score_metodos_dB(2)), ...
    'FontSize',8, ...
    'BackgroundColor','w', ...
    'Margin',0.5);

text(fc_metodos_Hz(3)/1e3 + 0.06, y_mt + 0.08, score_metodos_dB(3) + 1.2, ...
    sprintf('%.3f kHz\n%.2f dB', fc_metodos_Hz(3)/1e3, score_metodos_dB(3)), ...
    'FontSize',8, ...
    'BackgroundColor','w', ...
    'Margin',0.5);

plot3([fc_ref_Hz fc_ref_Hz]/1e3, [0.7 3.7], [criterio_dB criterio_dB], ...
    'k--', ...
    'LineWidth',1.1, ...
    'DisplayName','Referencia 56.4 kHz');

plot3([fc_promedio_Hz fc_promedio_Hz]/1e3, [0.7 3.7], [criterio_dB criterio_dB], ...
    'k:', ...
    'LineWidth',1.3, ...
    'DisplayName','Promedio de metodos');

grid on;
box on;

xlabel('Frecuencia [kHz]');
ylabel('Metodo');
zlabel('Score ON-OFF [dB]');
title('LED 1 - Comparativa 3D tipo cascada de score ON-OFF', ...
    'Interpreter','none');

yticks([y_periodograma y_welch y_mt]);
yticklabels({'Periodograma','Welch','Multitaper local'});

xlim([fmin_local fmax_local]/1e3);
ylim([0.7 3.7]);
zlim([z_min z_max]);

view(-40, 22);
pbaspect([2.2 1.1 0.9]);

lgd = legend('Location','eastoutside');
lgd.Box = 'on';

saveas(fig, fullfile(carpeta_salida, ...
    'comparativa_LED1_score_cascada_3D.png'));

savefig(fig, fullfile(carpeta_salida, ...
    'comparativa_LED1_score_cascada_3D.fig'));

%% 16. Guardar variables comparativas

save(fullfile(carpeta_salida, 'datos_comparativa_LED1.mat'), ...
    'tabla_comparativa', ...
    'tabla_parametros', ...
    'fc_metodos_Hz', ...
    'score_metodos_dB', ...
    'ON_metodos_dB', ...
    'OFF_metodos_dB', ...
    'fc_promedio_Hz', ...
    'rango_frecuencias_Hz', ...
    'variacion_max_pct', ...
    'tolerancia_abs_Hz', ...
    'criterio_dB', ...
    'fmin_local', ...
    'fmax_local');

fprintf('\n============================================\n');
fprintf('Comparativa LED 1 terminada.\n');
fprintf('Resultados guardados en:\n%s\n', carpeta_salida);
fprintf('============================================\n');

%% ============================================================
% FUNCIONES LOCALES


function res = extraer_resultado_metodo(D, nombre_metodo)

    res = struct();
    res.metodo = nombre_metodo;

    if isfield(D, 'tabla_resumen') && contains(nombre_metodo, 'Multitaper', 'IgnoreCase', true)

        T = D.tabla_resumen;

        res.fc_local_Hz    = extraer_variable_tabla(T, {'fc_local_Hz', 'fc_Hz'});
        res.score_local_dB = extraer_variable_tabla(T, {'score_local_dB', 'score_dB'});
        res.ON_dB          = extraer_variable_tabla(T, {'ON_dB'});
        res.OFF_dB         = extraer_variable_tabla(T, {'OFF_dB'});

        return;
    end

    if isfield(D, 'tabla')

        T = D.tabla;

        if isfield(D, 'fc_principal') && ~isnan(D.fc_principal)
            fc = D.fc_principal;
        else
            fc = extraer_variable_tabla(T, {'f_local_Hz', 'fc_Hz'});
        end

        if height(T) > 1
            if any(strcmp(T.Properties.VariableNames, 'f_local_Hz'))
                [~, idx] = min(abs(T.f_local_Hz - fc));
            elseif any(strcmp(T.Properties.VariableNames, 'fc_Hz'))
                [~, idx] = min(abs(T.fc_Hz - fc));
            else
                idx = 1;
            end
        else
            idx = 1;
        end

        res.fc_local_Hz    = obtener_valor_tabla(T, idx, {'f_local_Hz', 'fc_Hz'});
        res.score_local_dB = obtener_valor_tabla(T, idx, {'score_local_dB', 'score_peak_dB'});
        res.ON_dB          = obtener_valor_tabla(T, idx, {'ON_dB'});
        res.OFF_dB         = obtener_valor_tabla(T, idx, {'OFF_dB'});

        return;
    end

    error('No se pudo extraer resultado para %s. No se encontro tabla o tabla_resumen.', nombre_metodo);
end

function valor = extraer_variable_tabla(T, nombres_posibles)

    valor = NaN;

    for i = 1:numel(nombres_posibles)
        nombre = nombres_posibles{i};

        if any(strcmp(T.Properties.VariableNames, nombre))
            valor = T.(nombre)(1);
            return;
        end
    end
end

function valor = obtener_valor_tabla(T, idx, nombres_posibles)

    valor = NaN;

    for i = 1:numel(nombres_posibles)
        nombre = nombres_posibles{i};

        if any(strcmp(T.Properties.VariableNames, nombre))
            valor = T.(nombre)(idx);
            return;
        end
    end
end

function [f_out, score_out] = extraer_curva_score(D)

    f_out = [];
    score_out = [];

    if isfield(D, 'f')
        f_out = D.f(:);
    end

    if isfield(D, 'score_prom')
        score_out = D.score_prom(:);
    elseif isfield(D, 'score_local')
        score_out = D.score_local(:);
    end

    if isempty(f_out) || isempty(score_out)
        warning('No se pudo extraer curva score de uno de los metodos.');
        f_out = [];
        score_out = [];
        return;
    end

    n = min(numel(f_out), numel(score_out));
    f_out = f_out(1:n);
    score_out = score_out(1:n);
end

function graficar_score_local(f, score, fmin_local, fmax_local, nombre)

    if isempty(f) || isempty(score)
        warning('No se pudo graficar score local para %s porque la curva esta vacia.', nombre);
        return;
    end

    f = f(:);
    score = score(:);

    n = min(numel(f), numel(score));
    f = f(1:n);
    score = score(1:n);

    idx = f >= fmin_local & f <= fmax_local;

    if ~any(idx)
        warning('No hay datos de score local para %s en la ventana seleccionada.', nombre);
        return;
    end

    plot(f(idx)/1e3, score(idx), ...
        'LineWidth', 1.4, ...
        'DisplayName', nombre);
end

function graficar_score_3d(f, score, fmin_local, fmax_local, indice_metodo, nombre_metodo)

    if isempty(f) || isempty(score)
        warning('No se pudo graficar score 3D para %s porque la curva esta vacia.', nombre_metodo);
        return;
    end

    f = f(:);
    score = score(:);

    n = min(numel(f), numel(score));
    f = f(1:n);
    score = score(1:n);

    idx = f >= fmin_local & f <= fmax_local;

    if ~any(idx)
        warning('No hay datos de score 3D para %s en la ventana seleccionada.', nombre_metodo);
        return;
    end

    f_local_kHz = f(idx) / 1e3;
    score_local = score(idx);

    y_metodo = indice_metodo * ones(size(f_local_kHz));

    plot3(f_local_kHz, y_metodo, score_local, ...
        'LineWidth', 1.5, ...
        'DisplayName', nombre_metodo);
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
        ancho_col(c) = max(85, min(170, ancho_col(c)));
    end

    margen_izq = 30;
    margen_der = 30;
    margen_inf = 25;
    alto_titulo = 60;
    alto_fila = 32;
    alto_header = 36;

    ancho_tabla = sum(ancho_col);
    alto_tabla = alto_header + nfilas*alto_fila;

    ancho_fig = margen_izq + ancho_tabla + margen_der;
    alto_fig = margen_inf + alto_tabla + alto_titulo + 20;

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

    text(ax, ancho_fig/2, alto_fig - 30, titulo_tabla, ...
        'HorizontalAlignment','center', ...
        'VerticalAlignment','middle', ...
        'FontWeight','bold', ...
        'FontSize',16, ...
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

function graficar_score_3d_rotado(f, score, fmin_local, fmax_local, indice_metodo, nombre_metodo)

    if isempty(f) || isempty(score)
        warning('No se pudo graficar score 3D para %s porque la curva esta vacia.', nombre_metodo);
        return;
    end

    f = f(:);
    score = score(:);

    n = min(numel(f), numel(score));
    f = f(1:n);
    score = score(1:n);

    idx = f >= fmin_local & f <= fmax_local;

    if ~any(idx)
        warning('No hay datos de score 3D para %s en la ventana seleccionada.', nombre_metodo);
        return;
    end

    f_local_kHz = f(idx) / 1e3;
    score_local = score(idx);

    x_metodo = indice_metodo * ones(size(f_local_kHz));

    plot3(x_metodo, f_local_kHz, score_local, ...
        'LineWidth', 1.5, ...
        'DisplayName', nombre_metodo);
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

                elseif contains(nombre, 'pct', 'IgnoreCase', true)
                    texto = sprintf('%.3f', valor);

                elseif contains(nombre, 'dB', 'IgnoreCase', true)
                    texto = sprintf('%.4f', valor);

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

                texto = char(valor);

            elseif ischar(valor)

                texto = valor;

            else

                texto = char(string(valor));
            end

            data_cell{i,c} = texto;
        end
    end
end