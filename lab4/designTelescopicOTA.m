function OTA = designTelescopicOTA(specs)
% High-Swing Telescopic Cascode OTA Synthesis
% specs.GBW, specs.CL, specs.AVDC (in dB)

VDD = 1.8;
load 180nch.mat;
load 180pch.mat;

% === Required Transconductance ===
gm_req = 2 * pi * specs.GBW * specs.CL;
AV_mag = 10^(specs.AVDC / 20);
Rout_req = AV_mag / gm_req;

% === Design assumptions ===
OTA.M1.gm_ID = 15;
OTA.M3.gm_ID = 10;
OTA.M5.gm_ID = 15;
OTA.M7.gm_ID = 10;
OTA.M9.gm_ID = 10;

% === M1: NMOS Input ===
OTA.M1.gm = gm_req;
OTA.M1.ID = OTA.M1.gm / OTA.M1.gm_ID;
OTA.M1.VDS = 0.6; % Reasonable value for VDS > VDSAT
Lvec = nch.L;

% Estimate ro from gm/ro = gds
% Require: ro_total = Rout_req ≈ ro1*ro3/(ro1+ro3)
ro_target = Rout_req * 2; % ≈ for two cascodes in parallel

% Estimate ro1 = ro3 = sqrt(ro_target)
ro_M1 = sqrt(ro_target);
gds_M1 = 1 / ro_M1;
gm_gds_target = OTA.M1.gm / gds_M1;

gm_gds_vector = look_up(nch, 'GM_GDS', 'GM_ID', OTA.M1.gm_ID, ...
    'VDS', OTA.M1.VDS, 'L', Lvec);
OTA.M1.L = min(Lvec(gm_gds_vector >= gm_gds_target));

OTA.M1.ID_W = look_up(nch, 'ID_W', 'GM_ID', OTA.M1.gm_ID, ...
    'VDS', OTA.M1.VDS, 'L', OTA.M1.L);
OTA.M1.W = OTA.M1.ID / OTA.M1.ID_W;

% === M3: NMOS cascode ===
OTA.M3.ID = OTA.M1.ID;
OTA.M3.VDS = 0.6;
gm_M3 = OTA.M3.ID * OTA.M3.gm_ID;

gm_gds_vector = look_up(nch, 'GM_GDS', 'GM_ID', OTA.M3.gm_ID, ...
    'VDS', OTA.M3.VDS, 'L', Lvec);
gm_gds_target = gm_M3 / gds_M1;
OTA.M3.L = min(Lvec(gm_gds_vector >= gm_gds_target));

OTA.M3.ID_W = look_up(nch, 'ID_W', 'GM_ID', OTA.M3.gm_ID, ...
    'VDS', OTA.M3.VDS, 'L', OTA.M3.L);
OTA.M3.W = OTA.M3.ID / OTA.M3.ID_W;

% === M5: PMOS load ===
OTA.M5.ID = OTA.M1.ID;
OTA.M5.VDS = 0.6;
gm_M5 = OTA.M5.ID * OTA.M5.gm_ID;
gm_gds_vector = look_up(pch, 'GM_GDS', 'GM_ID', OTA.M5.gm_ID, ...
    'VDS', OTA.M5.VDS, 'L', Lvec);
gm_gds_target = gm_M5 / gds_M1;
OTA.M5.L = min(Lvec(gm_gds_vector >= gm_gds_target));
OTA.M5.ID_W = look_up(pch, 'ID_W', 'GM_ID', OTA.M5.gm_ID, ...
    'VDS', OTA.M5.VDS, 'L', OTA.M5.L);
OTA.M5.W = OTA.M5.ID / OTA.M5.ID_W;

% === M7: PMOS cascode ===
OTA.M7 = OTA.M5;
OTA.M7.gm_ID = 8;
gm_M7 = OTA.M7.ID * OTA.M7.gm_ID;
gm_gds_vector = look_up(pch, 'GM_GDS', 'GM_ID', OTA.M7.gm_ID, ...
    'VDS', OTA.M7.VDS, 'L', Lvec);
gm_gds_target = gm_M7 / gds_M1;
OTA.M7.L = min(Lvec(gm_gds_vector >= gm_gds_target));
OTA.M7.ID_W = look_up(pch, 'ID_W', 'GM_ID', OTA.M7.gm_ID, ...
    'VDS', OTA.M7.VDS, 'L', OTA.M7.L);
OTA.M7.W = OTA.M7.ID / OTA.M7.ID_W;

% === M9: Tail NMOS ===
OTA.M9.ID = 2 * OTA.M1.ID;
OTA.M9.VDS = 0.6;
OTA.M9.gm_ID = 10;
OTA.M9.ID_W = look_up(nch, 'ID_W', 'GM_ID', OTA.M9.gm_ID, ...
    'VDS', OTA.M9.VDS, 'L', 1);
OTA.M9.W = OTA.M9.ID / OTA.M9.ID_W;
OTA.M9.L = 1;

% === Bias Voltages ===
vgs_vec = nch.VGS;
gm_id_vec = look_up(nch, 'GM_ID', 'VGS', vgs_vec, ...
    'VDS', OTA.M1.VDS, 'L', OTA.M1.L);
[~, idx] = min(abs(gm_id_vec - OTA.M1.gm_ID));
VGS_M1 = vgs_vec(idx);
OTA.VCM = VGS_M1 + OTA.M9.VDS;

OTA.Vb1 = OTA.M3.VDS;
OTA.Vb2 = VDD - OTA.M7.VDS;

end
