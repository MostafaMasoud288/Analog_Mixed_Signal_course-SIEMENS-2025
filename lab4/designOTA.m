function OTA = designOTA(specs)
% OTA Synthesis Function
% Inputs: specs.GBW, specs.CL, specs.AVDC
% Output: OTA structure with sizing and bias info

% Supply voltage
VDD = 1.8;

% Load lookup tables
load 180nch.mat;
load 180pch.mat;

% === Input Pair M1 ===
OTA.M1.gm = specs.GBW * specs.CL * 2 * pi;

% Estimate output resistance from DC gain
DC_Gain_mag = 10^(specs.AVDC / 20); % Convert from dB to magnitude
Rout = DC_Gain_mag / OTA.M1.gm;     % Total output resistance of OTA

% Assume ro(load) = 5 * ro(input), so:
% Rout = (ro_M1 * ro_M3) / (ro_M1 + ro_M3) ≈ ro_M1 * ro_M3 / ro_M3 = ro_M1 / 6
% => ro_M1 = 6 * Rout / 5
OTA.M1.ro = (3 / 2) * Rout;

OTA.M1.gds = 1 / OTA.M1.ro;
OTA.M1.VDS = VDD / 3; % Assume 1/3rd VDD
OTA.M1.gm_gds = OTA.M1.gm / OTA.M1.gds;
OTA.M1.gm_ID = 15; % Assumed gm/ID

% Get drain current from gm and gm/ID
OTA.M1.ID = OTA.M1.gm / OTA.M1.gm_ID;

% Search for the minimum L that gives gm/gds >= target
L_vector = nch.L;
gm_gds_vector = look_up(nch, 'GM_GDS', 'GM_ID', OTA.M1.gm_ID, ...
                        'VDS', OTA.M1.VDS, 'L', L_vector);
OTA.M1.L = min(L_vector(gm_gds_vector >= OTA.M1.gm_gds));

% Get ID/W for final W sizing
OTA.M1.ID_W = look_up(nch, 'ID_W', 'GM_ID', OTA.M1.gm_ID, ...
                      'VDS', OTA.M1.VDS, 'L', OTA.M1.L);
OTA.M1.W = OTA.M1.ID / OTA.M1.ID_W;

% === CM Load M3 ===
OTA.M3.ID = OTA.M1.ID;
OTA.M3.VDS = VDD / 3;
OTA.M3.gm_ID = 10; % Assumption
OTA.M3.gm = OTA.M3.gm_ID * OTA.M3.ID;

% Use ro = 2 * ro_M1
OTA.M3.ro = 2 * OTA.M1.ro;
OTA.M3.gds = 1 / OTA.M3.ro;
OTA.M3.gm_gds = OTA.M3.gm / OTA.M3.gds;

gm_gds_vector = look_up(pch, 'GM_GDS', 'GM_ID', OTA.M3.gm_ID, ...
                        'VDS', OTA.M3.VDS, 'L', L_vector);
OTA.M3.L = min(L_vector(gm_gds_vector > OTA.M3.gm_gds));

% Final sizing of M3
OTA.M3.ID_W = look_up(pch, 'ID_W', 'GM_ID', OTA.M3.gm_ID, ...
                      'VDS', OTA.M3.VDS, 'L', OTA.M3.L);
OTA.M3.W = OTA.M3.ID / OTA.M3.ID_W;

% === Tail Transistor M5 ===
OTA.M5.L = 1; % Assumption
OTA.M5.ID = 2 * OTA.M1.ID; % Sinks current from both M1 and M2
OTA.M5.VDS = VDD / 3;
OTA.M5.gm_ID = 10;

OTA.M5.ID_W = look_up(nch, 'ID_W', 'GM_ID', OTA.M5.gm_ID, ...
                      'VDS', OTA.M5.VDS, 'L', OTA.M5.L);
OTA.M5.W = OTA.M5.ID / OTA.M5.ID_W;

% === Common-mode Input Bias ===
% Get VGS from gm/ID
%OTA.M1.VGS = look_up(nch, 'VGS', 'GM_ID', OTA.M1.gm_ID, ...
 %                    'VDS', OTA.M1.VDS, 'L', OTA.M1.L);
                 
vgs_vec = nch.VGS;
gm_id_vec = look_up(nch, 'GM_ID', 'VGS', vgs_vec, ...
                    'VDS', OTA.M1.VDS, 'L',OTA.M1.L);
[~, idx] = min(abs(gm_id_vec -OTA.M1.gm_ID));
M1.VGS = vgs_vec(idx);

OTA.M1.VG = M1.VGS + OTA.M5.VDS; % DC common-mode input voltage

end
