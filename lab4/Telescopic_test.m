% Telescopic OTA Design Script
clear all; close all; clc;

% === SPECS ===
AVDC = 50;           % DC gain in dB
GBW = 100e6;         % Gain-bandwidth product in Hz
CL = 1e-12;        % Load capacitance in Farads

% Create specs structure
specs = struct('AVDC', AVDC, ...
               'CL', CL, ...
               'GBW', GBW);

% Call the OTA synthesis function
OTA = designTelescopicOTA(specs);

% === Print the results ===
fprintf('**** Telescopic Cascode OTA Design ****\n\n');

fprintf('Input Differential Pair (M1/M2):\n');
fprintf('    L = %.2f um\n', OTA.M1.L);
fprintf('    W = %.2f um\n', OTA.M1.W);
fprintf('    Bias Current (each) = %.2f uA\n', OTA.M1.ID * 1e6);
fprintf('    Total Bias Current = %.2f uA\n', 2 * OTA.M1.ID * 1e6);
fprintf('    VCM (common-mode input) = %.4f V\n\n', OTA.VCM);

fprintf('NMOS Cascode Devices (M3/M4):\n');
fprintf('    L = %.2f um\n', OTA.M3.L);
fprintf('    W = %.2f um\n', OTA.M3.W);
fprintf('    Bias Current = %.2f uA\n\n', OTA.M3.ID * 1e6);

fprintf('PMOS Load Devices (M5/M6):\n');
fprintf('    L = %.2f um\n', OTA.M5.L);
fprintf('    W = %.2f um\n', OTA.M5.W);
fprintf('    Bias Current = %.2f uA\n\n', OTA.M5.ID * 1e6);

fprintf('PMOS Cascode Devices (M7/M8):\n');
fprintf('    L = %.2f um\n', OTA.M7.L);
fprintf('    W = %.2f um\n', OTA.M7.W);
fprintf('    Bias Current = %.2f uA\n\n', OTA.M7.ID * 1e6);

fprintf('Tail Current Source (M9):\n');
fprintf('    L = %.2f um\n', OTA.M9.L);
fprintf('    W = %.2f um\n', OTA.M9.W);
fprintf('    Tail Bias Current = %.2f uA\n\n', OTA.M9.ID * 1e6);

fprintf('Bias Voltages:\n');
fprintf('    Vb1 (NMOS cascode bias) = %.3f V\n', OTA.Vb1);
fprintf('    Vb2 (PMOS cascode bias) = %.3f V\n', OTA.Vb2);
