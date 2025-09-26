% OTA Design Script
% Write the SPECS
clear all;
AVDC = 34; %dB
GBW = 1e8; %Hz
CL = 500e-15; %Farad
specs = struct('AVDC', AVDC,... 
'CL', CL,...
'GBW', GBW);

% Load transistor models
load 180nch.mat;
load 180pch.mat;

% Nominal design
OTA = goptOTA(specs);

% Define corners: nominal, +10% IB, -10% IB
corners = [1.0, 1.1, 0.9];
corner_names = {'Nominal', '+10% IB', '-10% IB'};

% Initialize array to store OTA for each corner
OTA_corners = cell(1,3);
IB_NOM=OTA.IB_NOM;
for i = 1:3
    OTA.IB = IB_NOM * corners(i);
    
    % Recalculate currents
    OTA.M1.ID = OTA.IB / 2;
    OTA.M3.ID = OTA.IB / 2;
    OTA.M5.ID = OTA.IB;
    
    % Recalculate transconductances
    OTA.M1.gm = OTA.M1.ID * OTA.M1.gm_ID;
    OTA.M3.gm = OTA.M3.ID * OTA.M3.gm_ID;
    
    % Recalculate output conductances (gds)
    OTA.M1.gm_gds = diag(look_up(nch, 'GM_GDS', 'GM_ID', OTA.M1.gm_ID, 'VDS', OTA.M1.VDS, 'L', OTA.M1.L));
    OTA.M1.gds = OTA.M1.gm / OTA.M1.gm_gds;
    
    OTA.M3.gm_gds = diag(look_up(pch, 'GM_GDS', 'GM_ID', OTA.M3.gm_ID, 'VDS', OTA.M3.VDS, 'L', OTA.M3.L));
    OTA.M3.gds = OTA.M3.gm / OTA.M3.gm_gds;
    
    % Recalculate drain capacitances (cdd)
    OTA.M1.gm_cdd = diag(look_up(nch, 'GM_CDD', 'GM_ID', OTA.M1.gm_ID, 'VDS', OTA.M1.VDS, 'L', OTA.M1.L));
    OTA.M1.cdd = OTA.M1.gm / OTA.M1.gm_cdd;
    
    OTA.M3.gm_cdd = diag(look_up(pch, 'GM_CDD', 'GM_ID', OTA.M3.gm_ID, 'VDS', OTA.M3.VDS, 'L', OTA.M3.L));
    OTA.M3.cdd = OTA.M3.gm / OTA.M3.gm_cdd;
    
    % Total capacitance at output node
    C_total = OTA.M1.cdd + OTA.M3.cdd + specs.CL;
    
    % Compute performance metrics
    OTA.AVDC_actual = OTA.M1.gm / (OTA.M1.gds + OTA.M3.gds);
    OTA.GBW_actual = OTA.M1.gm / (2 * pi * C_total);
    
    % Store
    OTA_corners{i} = OTA;
end

% Print results for each corner
for i = 1:3
    OTA = OTA_corners{i};
    fprintf('\n**** Corner: %s ****\n', corner_names{i});
    fprintf('IB = %.2e A\n', OTA.IB);
    fprintf('AVDC = %.2f dB (spec: %.2f dB)\n', 20*log10(OTA.AVDC_actual), specs.AVDC);
    fprintf('GBW = %.2e Hz (spec: %.2e Hz)\n', OTA.GBW_actual, specs.GBW);
    fprintf('Power = %.2e W\n', OTA.IB * 1.8);
end
