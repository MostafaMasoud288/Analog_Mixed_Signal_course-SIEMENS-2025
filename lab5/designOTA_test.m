% OTA Design Script
clear all; close all; clc;

% === SPECS ===
AVDC = 34;           % DC gain in dB
GBW = 100e6;         % Gain-bandwidth product in Hz
CL = 500e-15;        % Load capacitance in Farads

% Create specs structure
specs = struct('AVDC', AVDC, ...
               'CL', CL, ...
               'GBW', GBW);

% Call the OTA synthesis function
OTA = designOTA(specs);

% === Print the results ===
fprintf('**** OTA Design ****\n\n');

fprintf('Input Differential Pair (M1):\n');
fprintf('    L = %.2f um\n', OTA.M1.L);
fprintf('    W = %.2f um\n', OTA.M1.W);
fprintf('    Bias Current = %.2f uA\n', OTA.M1.ID * 1e6);
fprintf('    ViCM = %.4f V\n\n', OTA.M1.VG);

fprintf('Current Mirror Load (M3):\n');
fprintf('    L = %.2f um\n', OTA.M3.L);
fprintf('    W = %.2f um\n', OTA.M3.W);
fprintf('    Bias Current = %.2f uA\n', OTA.M3.ID * 1e6);


fprintf('Tail Current Source (M5):\n');
fprintf('    L = %.2f um\n', OTA.M5.L);
fprintf('    W = %.2f um\n', OTA.M5.W);
fprintf('    Tail Bias Current = %.2f uA\n', OTA.M5.ID * 1e6);

