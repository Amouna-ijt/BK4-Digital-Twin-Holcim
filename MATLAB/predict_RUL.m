function [RUL_moteur, RUL_reducteur, tendance_mot, tendance_red, etat_rul, ...
          fiab_moteur, fiab_reducteur, mtbf_mot, mtbf_red] = predict_RUL( ...
    T_bobA, T_bobB, T_bobC, T_pal_DE, T_pal_NDE, ...
    T_huile, T_pal1_red, T_pal2_red, vib_moteur, vib_red)

    persistent hist_bob hist_red hist_vm hist_vr idx init

    N = 500;

   if isempty(init)
    T_bob_init = max([T_bobA, T_bobB, T_bobC]);
    T_red_init = max([T_pal1_red, T_pal2_red, T_huile]);
    hist_bob = ones(1, N) * T_bob_init;
    hist_red = ones(1, N) * T_red_init;
    hist_vm  = ones(1, N) * abs(vib_moteur);
    hist_vr  = ones(1, N) * abs(vib_red);
    idx = 0;
    init = true;
    end

    idx = idx + 1;
    pos = mod(idx-1, N) + 1;
    hist_bob(pos) = max([T_bobA, T_bobB, T_bobC]);
    hist_red(pos) = max([T_pal1_red, T_pal2_red, T_huile]);
    hist_vm(pos)  = abs(vib_moteur);
    hist_vr(pos)  = abs(vib_red);

    n_pts = min(idx, N);
    RUL_moteur = 9999;
    RUL_reducteur = 9999;
    tendance_mot = 0;
    tendance_red = 0;
    etat_rul = 1;
    fiab_moteur = 100;
    fiab_reducteur = 100;
    mtbf_mot = 8000;
    mtbf_red = 15000;

    if n_pts < 5
        return;
    end

    nb = min(n_pts, 50);
    indices = zeros(1, nb);
    for k = 1:nb
        indices(k) = mod(idx - nb + k - 1, N) + 1;
    end

    temps = (0:nb-1)';
    n = length(temps);
    sum_t = sum(temps);
    sum_t2 = sum(temps.^2);
    denom = n * sum_t2 - sum_t^2;

    if abs(denom) < 0.001
        return;
    end

    %% ===== PARTIE 1 : RUL PAR TENDANCE LINÉAIRE =====
    
    % MOTEUR
    vals_bob = hist_bob(indices)';
    a_bob = (n * sum(temps .* vals_bob) - sum_t * sum(vals_bob)) / denom;
    tendance_mot = a_bob;

    T_bob_now = max([T_bobA, T_bobB, T_bobC]);
    if a_bob > 0.001
        RUL_moteur = (180 - T_bob_now) / a_bob;
        RUL_moteur = max(RUL_moteur, 0);
        RUL_moteur = min(RUL_moteur, 9999);
    end

    vals_vm = hist_vm(indices)';
    a_vm = (n * sum(temps .* vals_vm) - sum_t * sum(vals_vm)) / denom;
    if a_vm > 0.001
        rul_v = (7.1 - abs(vib_moteur)) / a_vm;
        RUL_moteur = min(RUL_moteur, max(rul_v, 0));
    end

    % REDUCTEUR
    vals_red = hist_red(indices)';
    a_red = (n * sum(temps .* vals_red) - sum_t * sum(vals_red)) / denom;
    tendance_red = a_red;

    T_red_now = max([T_pal1_red, T_pal2_red, T_huile]);
    if a_red > 0.001
        RUL_reducteur = (110 ...
            - T_red_now) / a_red;
        RUL_reducteur = max(RUL_reducteur, 0);
        RUL_reducteur = min(RUL_reducteur, 9999);
    end

    vals_vr = hist_vr(indices)';
    a_vr = (n * sum(temps .* vals_vr) - sum_t * sum(vals_vr)) / denom;
    if a_vr > 0.001
        rul_v = (7 - abs(vib_red)) / a_vr;
        RUL_reducteur = min(RUL_reducteur, max(rul_v, 0));
    end

    %% ===== PARTIE 2 : MTBF ADAPTATIF =====
    
    % MTBF nominal (heures) - valeurs industrielles standards
    MTBF_mot_nom = 8000;
    MTBF_red_nom = 15000;
    
    % Facteur température bobines (loi d'Arrhenius)
    f_bob = 1.0;
    if T_bob_now > 80
        f_bob = 2^(-(T_bob_now - 80) / 10);
    end
    
    % Facteur vibrations moteur
    f_vib_m = 1.0;
    if abs(vib_moteur) > 4.5
        f_vib_m = max(1 - 0.3 * (abs(vib_moteur) - 4.5) / 2.5, 0.05);
    end
    
    % Facteur paliers moteur
    maxPalMot = max([T_pal_DE, T_pal_NDE]);
    f_pal_m = 1.0;
    if maxPalMot > 60
        f_pal_m = 2^(-(maxPalMot - 60) / 10);
    end
    
    mtbf_mot = MTBF_mot_nom * max(f_bob * f_vib_m * f_pal_m, 0.01);
    
    % Facteur température réducteur
    f_red = 1.0;
    if T_red_now > 50
        f_red = 2^(-(T_red_now - 50) / 10);
    end
    
    % Facteur vibrations réducteur
    f_vib_r = 1.0;
    if abs(vib_red) > 2.5
        f_vib_r = max(1 - 0.3 * (abs(vib_red) - 2.5) / 2.5, 0.05);
    end
    
    mtbf_red = MTBF_red_nom * max(f_red * f_vib_r, 0.01);

   %% ===== PARTIE 3 : FIABILITÉ WEIBULL =====
    
    % Paramètre de forme (beta > 1 = usure)
    beta = 2.5;
    
    % Fiabilité basée sur le RATIO de dégradation
    % Plus le MTBF diminue par rapport au nominal, plus la fiabilité baisse
    
    % Moteur
    ratio_mot = mtbf_mot / MTBF_mot_nom;  % 1.0 = neuf, 0.1 = très usé
    fiab_moteur = ratio_mot^beta * 100;
    fiab_moteur = min(max(fiab_moteur, 0), 100);
    
    % Réducteur
    ratio_red = mtbf_red / MTBF_red_nom;
    fiab_reducteur = ratio_red^beta * 100;
    fiab_reducteur = min(max(fiab_reducteur, 0), 100);

   rul_min = min(RUL_moteur, RUL_reducteur);
if rul_min > 200
    etat_rul = 1;
elseif rul_min > 50
    etat_rul = 2;
elseif rul_min > 10
    etat_rul = 3;
else
    etat_rul = 4;
end
end
