%% Ejemplo conceptual: señal senoidal y métodos espectrales
clear; clc; close all;

%% Parámetros de la señal
fs = 10000;              % Frecuencia de muestreo [Hz]
T = 1;                   % Duración [s]
t = 0:1/fs:T-1/fs;       % Vector de tiempo
f0 = 1000;               % Frecuencia de la señal senoidal [Hz]
A = 0.8;                 % Amplitud

%% Señal senoidal con ruido
rng(1);                  % Reproducibilidad
x = A*sin(2*pi*f0*t) + 0.02*randn(size(t));

%% Colores
c_per   = [0 0.4470 0.7410];   % Azul - Periodograma/FFT
c_welch = [1 0 0];             % Rojo - Welch
c_mt    = [0 0.9 0];             % Verde - Multitaper
c_ref   = [0 0 0];    % Gris para frecuencia de referencia

%% Parámetros comunes
x_lim = [0 3000];
y_lim = [-120 0];

%% ============================================================
% 1) Periodograma basado en FFT
%% ============================================================
[pxx_per, f_per] = periodogram(x, [], [], fs);
pxx_per_db = 10*log10(pxx_per);

fig1 = figure('Color','w','Position',[100 100 1000 700]);

plot(f_per, pxx_per_db, 'Color', c_per, 'LineWidth', 1.2); hold on;
xline(f0, '--', 'Color', c_ref, 'LineWidth', 1.2);

text(f0+25, -105, 'f_0 = 1000 Hz', ...
    'Rotation', 90, ...
    'FontSize', 11, ...
    'Color', c_ref, ...
    'VerticalAlignment', 'bottom');

grid on;
xlim(x_lim);
ylim(y_lim);

xlabel('Frecuencia [Hz]', 'FontSize', 16);
ylabel('PSD [dB/Hz]', 'FontSize', 16);
title('Ejemplo conceptual mediante Periodograma/FFT', ...
    'FontSize', 18, 'FontWeight', 'bold');

legend('Periodograma/FFT', ...
    'Location', 'northeast', ...
    'FontSize', 13, ...
    'Box', 'on');

set(gca, 'FontSize', 14, 'LineWidth', 1.0);
set(gca, 'LooseInset', max(get(gca,'TightInset'), 0.02));

exportgraphics(fig1, 'ejemplo_periodograma_fft.png', 'Resolution', 300);

%% ============================================================
% 2) Welch
%% ============================================================
ventana = hamming(512);
noverlap = 256;
nfft = 1024;

[pxx_welch, f_welch] = pwelch(x, ventana, noverlap, nfft, fs);
pxx_welch_db = 10*log10(pxx_welch);

fig2 = figure('Color','w','Position',[100 100 1000 700]);

plot(f_welch, pxx_welch_db, 'Color', c_welch, 'LineWidth', 1.8); hold on;
xline(f0, '--', 'Color', c_ref, 'LineWidth', 1.2);

text(f0+25, -105, 'f_0 = 1000 Hz', ...
    'Rotation', 90, ...
    'FontSize', 11, ...
    'Color', c_ref, ...
    'VerticalAlignment', 'bottom');

grid on;
xlim(x_lim);
ylim(y_lim);

xlabel('Frecuencia [Hz]', 'FontSize', 16);
ylabel('PSD [dB/Hz]', 'FontSize', 16);
title('Ejemplo conceptual mediante Welch', ...
    'FontSize', 18, 'FontWeight', 'bold');

legend('Welch', ...
    'Location', 'northeast', ...
    'FontSize', 13, ...
    'Box', 'on');

set(gca, 'FontSize', 14, 'LineWidth', 1.0);
set(gca, 'LooseInset', max(get(gca,'TightInset'), 0.02));

exportgraphics(fig2, 'ejemplo_welch.png', 'Resolution', 300);

%% ============================================================
% 3) Multitaper
%% ============================================================
[pxx_mt, f_mt] = pmtm(x, 4, nfft, fs);
pxx_mt_db = 10*log10(pxx_mt);

fig3 = figure('Color','w','Position',[100 100 1000 700]);

plot(f_mt, pxx_mt_db, 'Color', c_mt, 'LineWidth', 1.8); hold on;
xline(f0, '--', 'Color', c_ref, 'LineWidth', 1.2);

text(f0+25, -105, 'f_0 = 1000 Hz', ...
    'Rotation', 90, ...
    'FontSize', 11, ...
    'Color', c_ref, ...
    'VerticalAlignment', 'bottom');

grid on;
xlim(x_lim);
ylim(y_lim);

xlabel('Frecuencia [Hz]', 'FontSize', 16);
ylabel('PSD [dB/Hz]', 'FontSize', 16);
title('Ejemplo conceptual mediante Multitaper', ...
    'FontSize', 18, 'FontWeight', 'bold');

legend('Multitaper', ...
    'Location', 'northeast', ...
    'FontSize', 13, ...
    'Box', 'on');

set(gca, 'FontSize', 14, 'LineWidth', 1.0);
set(gca, 'LooseInset', max(get(gca,'TightInset'), 0.02));

exportgraphics(fig3, 'ejemplo_multitaper.png', 'Resolution', 300);

%% ============================================================
% 4) Comparación completa
%% ============================================================
fig4 = figure('Color','w','Position',[100 100 1200 750]);

h1 = plot(f_per, pxx_per_db, 'Color', c_per, 'LineWidth', 1.1); hold on;
h3 = plot(f_mt, pxx_mt_db, 'Color', c_mt, 'LineWidth', 1.8);
h2 = plot(f_welch, pxx_welch_db, 'Color', c_welch, 'LineWidth', 1.8);

xline(f0, '--', 'Color', c_ref, 'LineWidth', 1.2);

text(f0+25, -105, 'f_0 = 1000 Hz', ...
    'Rotation', 90, ...
    'FontSize', 11, ...
    'Color', c_ref, ...
    'VerticalAlignment', 'bottom');

grid on;
xlim(x_lim);
ylim(y_lim);

xlabel('Frecuencia [Hz]', 'FontSize', 18);
ylabel('PSD [dB/Hz]', 'FontSize', 18);
title('Ejemplo conceptual de análisis espectral con señal senoidal', ...
    'FontSize', 18, 'FontWeight', 'bold');

legend([h1 h2 h3], {'Periodograma/FFT', 'Welch', 'Multitaper'}, ...
    'Location', 'northeast', ...
    'FontSize', 14, ...
    'Box', 'on');

set(gca, 'FontSize', 16, 'LineWidth', 1.0);
set(gca, 'LooseInset', max(get(gca,'TightInset'), 0.02));

exportgraphics(fig4, 'ejemplo_senoidal_metodos.png', 'Resolution', 300);