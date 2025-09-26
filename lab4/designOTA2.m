function OTA = designOTA2(specs)
% OTA Synthesis Function with Self-Loading Consideration (Cdd)
% Inputs: specs.GBW, specs.CL, specs.AVDC
% Output: OTA structure with sizing and bias info

VDD = 1.8;

% Load device data
load 180nch.mat;
load 180pch.mat;

% === Initial assumptions for M3 ===
VDS_M3 = VDD / 3;
gm_ID_M3 = 10;
L_vector = pch.L;

% Use typical L to find initial W for Cdd estimation
L_tmp = min(L_vector);
ID_M3_tmp = 21e-5;  % Arbitrary small current for initial estimation
ID_W_tmp = look_up(pch, 'ID_W', 'GM_ID', gm_ID_M3, ...
                   'VDS', VDS_M3, 'L', L_tmp);
W_tmp = ID_M3_tmp / ID_W_tmp;

% Lookup Cdd for M3 (VGS=VDD assumed for PMOS diode-connected load)
vds_vec = pch.VDS;
vgs_vec = pch.VGS;
l_vec = pch.L;
w_vec = pch.W;

% Choose closest VGS and VDS for lookup
vgs_use = VDD;
[~, vgs_idx] = min(abs(vgs_vec - vgs_use));
[~, vds_idx] = min(abs(vds_vec - VDS_M3));
[~, l_idx] = min(abs(l_vec - L_tmp));
[~, w_idx] = min(abs(w_vec - W_tmp));

Cdd_M3 = look_up(pch, 'CDD','VGS', 0.58,'VDS', 0.6,'L', 0.8);
Cdd_M1 = look_up(nch, 'CDD','VGS', 0.58,'VDS', 0.6,'L', 0.4);
Cdd_total = Cdd_M3+Cdd_M1;  % One PMOS contributes to output node
CL_total = specs.CL + Cdd_total;
OTA.CL_total = CL_total;
% === Input Pair M1 ===
OTA.M1.gm = specs.GBW * CL_total * 2 * pi;

DC_Gain_mag = 10^(specs.AVDC / 20);
Rout = DC_Gain_mag / OTA.M1.gm;

OTA.M1.ro = (3 / 2) * Rout;
OTA.M1.gds = 1 / OTA.M1.ro;
OTA.M1.VDS = VDD / 3;
OTA.M1.gm_gds = OTA.M1.gm / OTA.M1.gds;
OTA.M1.gm_ID = 15;

OTA.M1.ID = OTA.M1.gm / OTA.M1.gm_ID;

% Find minimum L meeting gm/gds
gm_gds_vector = look_up(nch, 'GM_GDS', 'GM_ID', OTA.M1.gm_ID, ...
                        'VDS', OTA.M1.VDS, 'L', L_vector);
OTA.M1.L = min(L_vector(gm_gds_vector >= OTA.M1.gm_gds));
OTA.M1.ID_W = look_up(nch, 'ID_W', 'GM_ID', OTA.M1.gm_ID, ...
                      'VDS', OTA.M1.VDS, 'L', OTA.M1.L);
OTA.M1.W = OTA.M1.ID / OTA.M1.ID_W;

% === M3 Load (PMOS diode-connected) ===
OTA.M3.ID = OTA.M1.ID;
OTA.M3.VDS = VDS_M3;
OTA.M3.gm_ID = 10;
OTA.M3.gm = OTA.M3.gm_ID * OTA.M3.ID;
OTA.M3.ro = 2 * OTA.M1.ro;
OTA.M3.gds = 1 / OTA.M3.ro;
OTA.M3.gm_gds = OTA.M3.gm / OTA.M3.gds;

gm_gds_vector = look_up(pch, 'GM_GDS', 'GM_ID', OTA.M3.gm_ID, ...
                        'VDS', OTA.M3.VDS, 'L', L_vector);
OTA.M3.L = min(L_vector(gm_gds_vector > OTA.M3.gm_gds));
OTA.M3.ID_W = look_up(pch, 'ID_W', 'GM_ID', OTA.M3.gm_ID, ...
                      'VDS', OTA.M3.VDS, 'L', OTA.M3.L);
OTA.M3.W = OTA.M3.ID / OTA.M3.ID_W;

% === Tail Transistor M5 ===
OTA.M5.L = 1;
OTA.M5.ID = 2 * OTA.M1.ID;
OTA.M5.VDS = VDD / 3;
OTA.M5.gm_ID = 10;
OTA.M5.ID_W = look_up(nch, 'ID_W', 'GM_ID', OTA.M5.gm_ID, ...
                      'VDS', OTA.M5.VDS, 'L', OTA.M5.L);
OTA.M5.W = OTA.M5.ID / OTA.M5.ID_W;

% === VGS and Common-mode bias ===
vgs_vec = nch.VGS;
gm_id_vec = look_up(nch, 'GM_ID', 'VGS', vgs_vec, ...
                    'VDS', OTA.M1.VDS, 'L', OTA.M1.L);
[~, idx] = min(abs(gm_id_vec - OTA.M1.gm_ID));
OTA.M1.VGS = vgs_vec(idx);
OTA.M1.VG = OTA.M1.VGS + OTA.M5.VDS;

% Save total output cap info
OTA.selfloading_Cdd = Cdd_total;
OTA.CL_total = CL_total;

end
