function [T_bobA, T_bobB, T_bobC, T_pal_DE, T_pal_NDE, ...
          T_huile, T_pal1_red, T_pal2_red, ...
          vib_mot, vib_red, pos_galet, ...
          Pjs, Pfs, Pjr, Pm] = fcn(Is_a, Is_b, Is_c, wm, Te, ...
          w_table, T_charge, P_hydr1, P_hydr2, t, cmd_marche, cmd_defaut, cmd_vib)

%#codegen
assert(isa(t,'double'));

% ================================================================
% VARIABLES PERSISTANTES
% ================================================================
persistent T_cu_s T_fer_s T_cu_r T_fer_r T_carc ...
           T_pDE T_pNDE T_oil T_pr1 T_pr2 t_prev init

if isempty(init)
    T_cu_s = 35; T_fer_s = 35;
    T_cu_r = 35; T_fer_r = 35;
    T_carc = 35;
    T_pDE  = 35; T_pNDE = 35;
    T_oil  = 35; T_pr1  = 35; T_pr2 = 35;
    t_prev = 0;
    init   = true;
end

% ================================================================
% PAS DE TEMPS
% ================================================================
dt = t - t_prev;
if dt <= 0 || dt > 0.1
    dt = 1e-4;
end
t_prev = t;

% ================================================================
% COMMANDE ARRÊT
% ================================================================
if cmd_marche < 0.5
    Is_a = 0; Is_b = 0; Is_c = 0;
    Te = 0; w_table = 0; wm = 0;
    T_cu_s  = T_cu_s  + (35 - T_cu_s)  * 0.01;
    T_fer_s = T_fer_s + (35 - T_fer_s) * 0.01;
    T_cu_r  = T_cu_r  + (35 - T_cu_r)  * 0.01;
    T_fer_r = T_fer_r + (35 - T_fer_r) * 0.01;
    T_carc  = T_carc  + (35 - T_carc)  * 0.01;
    T_pDE   = T_pDE   + (35 - T_pDE)   * 0.01;
    T_pNDE  = T_pNDE  + (35 - T_pNDE)  * 0.01;
    T_oil   = T_oil   + (35 - T_oil)   * 0.01;
    T_pr1   = T_pr1   + (35 - T_pr1)   * 0.01;
    T_pr2   = T_pr2   + (35 - T_pr2)   * 0.01;
end

% ================================================================
% FRÉQUENCES DE ROTATION
% ================================================================
fr       = abs(wm)      / (2*pi);
fr_table = abs(w_table) / (2*pi);

% ================================================================
% PARAMÈTRES GÉOMÉTRIQUES
% ================================================================
nb    = 8;
Db    = 0.025;
Dc    = 0.115;
theta = 0;
Z1    = 23;

Rth1 = 0.008;
Rth2 = 0.005;
Rth3 = 0.008;
Rth4 = 0.01;
Rth5 = 0.003;

C_cu_s  = 5000;
C_fer_s = 30000;
C_cu_r  = 3000;
C_fer_r = 10000;
C_carc  = 50000;

% ================================================================
% DÉSÉQUILIBRE ÉLECTRIQUE
% ================================================================
Is_moy = (abs(Is_a) + abs(Is_b) + abs(Is_c)) / 3;
deseq  = 0;
if Is_moy > 1
    deseq = max(abs(abs(Is_a)-Is_moy), ...
            max(abs(abs(Is_b)-Is_moy), ...
                abs(abs(Is_c)-Is_moy))) / Is_moy;
end

% ================================================================
% FACTEUR DÉFAUT (cmd_defaut → thermique)
% cmd_defaut = 0  → facteur_defaut = 1.0 (SAIN)
% cmd_defaut = 30 → facteur_defaut = 2.0 (FAIBLE)
% cmd_defaut = 60 → facteur_defaut = 3.0 (GRAVE)
% ================================================================
facteur_defaut = max(1.0 + cmd_defaut/30.0, 1.0 + cmd_vib/30.0);

% ================================================================
% FACTEUR VIBRATION (cmd_vib → vibrations + bobines)
% cmd_vib = 0  → t_vib = 0.0 (SAIN)
% cmd_vib = 30 → t_vib = 0.5 (FAIBLE)
% cmd_vib = 60 → t_vib = 1.0 (GRAVE)
% ================================================================
t_vib    = max(0, min(1, cmd_vib / 60.0));

% Coefficient bobines interpolé
coef_bob  = 0.08 + (0.35 - 0.08) * t_vib;

% Amplitudes vibratoires interpolées
A_balourd = 0.3  + (0.8  - 0.3)  * t_vib;
A_bpfo    = 0.0  + (4.0  - 0.0)  * t_vib;
A_bpfi    = 0.0  + (2.0  - 0.0)  * t_vib;
A_gmf     = 0.5  + (2.6  - 0.5)  * t_vib;
A_engr    = 0.0  + (1.5  - 0.0)  * t_vib;

% ================================================================
% CALCUL DES PERTES (avec facteur_defaut)
% ================================================================
Pjs   = 0.0294 * (Is_a^2 + Is_b^2 + Is_c^2) * facteur_defaut;
Pfs   = 450 * facteur_defaut;
Pjr   = 0.007 * abs(Te * wm) * facteur_defaut;
Pm    = max(0.015 * abs(Te * wm), 80) * facteur_defaut;
P_red = max(0.04 * abs(T_charge * w_table), 120) * facteur_defaut;

% ================================================================
% MODÈLE THERMIQUE
% ================================================================
Pfs_rotor = 0.3 * Pfs;

% Noeud 1 : Cuivre STATOR
T_cu_s = T_cu_s + (Pjs*0.7 - (T_cu_s - T_fer_s)/Rth1) / C_cu_s * dt;

% Noeud 2 : Fer STATOR
T_fer_s = T_fer_s + (Pfs + (T_cu_s-T_fer_s)/Rth1 ...
                         - (T_fer_s-T_carc)/Rth2) / C_fer_s * dt;

% Noeud 3 : Cuivre ROTOR
T_cu_r = T_cu_r + (Pjr*0.6 - (T_cu_r - T_fer_r)/Rth3) / C_cu_r * dt;

% Noeud 4 : Fer ROTOR
T_fer_r = T_fer_r + (Pfs_rotor + (T_cu_r-T_fer_r)/Rth3 ...
                               - (T_fer_r-T_carc)/Rth4) / C_fer_r * dt;

% Noeud 5 : CARCASSE
T_carc = T_carc + ((T_fer_s-T_carc)/Rth2 + (T_fer_r-T_carc)/Rth4 ...
                 - (T_carc-35)/Rth5) / C_carc * dt;

% Noeud 6 : Palier Drive End
T_pDE  = T_pDE  + (Pm*0.55  - (T_pDE -35)/0.001) / 3000 * dt;

% Noeud 7 : Palier Non-Drive End
T_pNDE = T_pNDE + (Pm*0.45  - (T_pNDE-35)/0.001) / 3000 * dt;

% Noeud 8 : Huile réducteur
T_oil  = T_oil  + (P_red*0.1  - (T_oil-35)/0.004) / 5000 * dt;

% Noeud 9 : Palier réducteur 1
T_pr1  = T_pr1  + (P_red*0.25 - (T_pr1-35)/0.0015) / 3000 * dt;

% Noeud 10 : Palier réducteur 2
T_pr2  = T_pr2  + (P_red*0.35 - (T_pr2-35)/0.0012) / 3000 * dt;

% ================================================================
% TEMPÉRATURES BOBINES (coef_bob variable selon cmd_vib)
% ================================================================
T_bobA = T_cu_s + abs(Is_a) * coef_bob;
T_bobB = T_cu_s + abs(Is_b) * coef_bob;
T_bobC = T_cu_s + abs(Is_c) * coef_bob;

% ================================================================
% VIBRATIONS MOTEUR (amplitudes variables selon cmd_vib)
% ================================================================
vib_mot = 0;
if fr > 1
    BPFO = (nb/2) * fr * (1 - (Db/Dc)*cos(theta));
    BPFI = (nb/2) * fr * (1 + (Db/Dc)*cos(theta));

    vib_balourd = A_balourd * sin(2*pi * fr * t);
    vib_bpfo    = A_bpfo    * sin(2*pi * BPFO * t);
    vib_bpfi    = A_bpfi    * (1 + 0.3*cos(2*pi*fr*t)) * sin(2*pi * BPFI * t);

    vib_roul = vib_bpfo + vib_bpfi;
    vib_mot  = vib_balourd + vib_roul;
end
vib_mot = abs(vib_mot);

% ================================================================
% VIBRATIONS RÉDUCTEUR (amplitudes variables selon cmd_vib)
% ================================================================
vib_red = 0;
if fr > 1
    GMF        = Z1 * fr;
    vib_gmf    = A_gmf  * sin(2*pi * GMF * t);
    vib_defaut = A_engr * (1 + 0.5*cos(2*pi*fr*t)) * sin(2*pi*GMF*t);
    vib_red    = vib_gmf + vib_defaut;
end
vib_red = abs(vib_red);

% ================================================================
% POSITION GALETS
% ================================================================
P_hydr_moy      = (abs(P_hydr1) + abs(P_hydr2)) / 2;
T_charge_nominal = 280000;
ratio_charge     = abs(T_charge) / max(T_charge_nominal, 1);
ratio_P          = max(min(P_hydr_moy / 15, 2), 0);

pos_galet = 65 + ratio_charge * 10 - ratio_P * 2 + 8*sin(2*pi*2*fr_table*t);
pos_galet = max(50, min(pos_galet, 100));

% ================================================================
% LIMITES DE SÉCURITÉ
% ================================================================
T_bobA     = max(35, min(T_bobA,  180));
T_bobB     = max(35, min(T_bobB,  180));
T_bobC     = max(35, min(T_bobC,  180));
T_pal_DE   = max(35, min(T_pDE,   130));
T_pal_NDE  = max(35, min(T_pNDE,  130));
T_huile    = max(35, min(T_oil,   110));
T_pal1_red = max(35, min(T_pr1,   110));
T_pal2_red = max(35, min(T_pr2,   110));

end
