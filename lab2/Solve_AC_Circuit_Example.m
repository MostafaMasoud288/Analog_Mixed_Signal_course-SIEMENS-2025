% Cleaning the workspace and command window
clear all;
clc;

% Frequency sweep parameters
start_freq = 10;         % Hz
stop_freq = 1e6;         % 1 MHz
points_per_decade = 100;

% Run first SPICE netlist
fprintf('The first netlist:\n');
[sym1, num1, freq1] = Solve_AC_Circuit('RLC_OD.txt', points_per_decade, start_freq, stop_freq);

% Choose which variable to plot (e.g., output node V_2)
% You may change the index based on your node of interest
output_index = 3;

% Plot magnitude and phase for circuit 1
figure;
subplot(2,1,1);
semilogx(freq1, 20*log10(abs(num1(:, output_index))), 'b', 'LineWidth', 1.5);
xlabel('Frequency (Hz)');
ylabel('|V_{out}| (dB)');
title('Circuit 1: Magnitude Response');
grid on;

subplot(2,1,2);
semilogx(freq1, angle(num1(:, output_index)) * 180/pi, 'r', 'LineWidth', 1.5);
xlabel('Frequency (Hz)');
ylabel('Phase (degrees)');
title('Circuit 1: Phase Response');
grid on;


