function [etat, proba_sain, proba_faible, proba_grave] = predict_BK4(...
    T_bobA, T_bobB, T_bobC, T_pal_DE, T_pal_NDE, ...
    T_huile, T_pal1_red, T_pal2_red, ...
    vib_moteur, vib_red, pos_galet)

% Charge le modèle UNE SEULE FOIS
persistent trainedModel

if isempty(trainedModel)
    S = load('modele_IA_BK4_v5.mat');
    trainedModel = S.trainedModel1;
    fprintf('Modele SVM chargé !\n');
end

% Prépare les données
X = table(T_bobA, T_bobB, T_bobC, T_pal_DE, T_pal_NDE, ...
          T_huile, T_pal1_red, T_pal2_red, ...
          vib_moteur, vib_red, pos_galet);

% Classifie avec le VRAI SVM
[label, scores] = trainedModel.predictFcn(X);

% Convertit le résultat
if strcmp(label{1}, 'sain')
    etat = 1;
elseif strcmp(label{1}, 'faible')
    etat = 2;
else
    etat = 3;
end

scores_pos = scores - min(scores);  % rend tout positif
total = sum(scores_pos);
if total > 0
  proba_faible = (scores_pos(1) / total) * 100;
proba_grave  = (scores_pos(2) / total) * 100;
proba_sain   = (scores_pos(3) / total) * 100;
else
    proba_sain   = 100;
    proba_faible = 0;
    proba_grave  = 0;
end
