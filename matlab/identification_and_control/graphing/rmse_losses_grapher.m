close all
clear
clc
format short

RECORDNAME_TRAIN = "readings_final/pid_train.mat";
RECORDNAME_TEST = "readings_final/pid_train.mat";

%% Caricamento del dataset

load(RECORDNAME_TRAIN);
recdata_train = recdata;
load(RECORDNAME_TEST);
recdata_test_global = recdata;
TIMESTEP = recdata.info.controller_ts;

function [states, inputs] = compensate_lerp(states, inputs)
    % Interpolazione lineare per riempire i valori NaN
    for j = 1:size(states, 2) % per ogni stato
        states(:, j) = fillmissing(states(:, j), 'linear');
    end
    inputs = fillmissing(inputs, 'linear');
end

function RMSE = get_rmse_lerp(packet_loss_prob, recdata_instance, recdata_test)
    %% Adding packet loss to dataset
    
    % Replace values in states with NaN based on Bernoulli chance
    for i = 1:length(recdata_instance.inputs)
        if rand() < packet_loss_prob
            recdata_instance.states(i, :) = [NaN NaN NaN NaN];
            recdata_instance.inputs(i) = NaN;
        end
    end
    
    % compensazione con interpolazione lineare
    [recdata_instance.states, recdata_instance.inputs] = compensate_lerp(recdata_instance.states, recdata_instance.inputs);

    
    
    
    %% Identification using linear regression
    
    STATES_tr = recdata_instance.states;
    INPUTS_tr = recdata_instance.inputs;
    
    [A, B] = ident_lr(STATES_tr, INPUTS_tr);
    M_hat = [A'; B']; % rebuild M hat

    Y_test = recdata_test.states(2:end, :); % elimina la prima riga (porta Y avanti nel tempo di un iterazione)
    X_test = [recdata_test.states recdata_test.inputs];    % concatena gli inputs allo stato per creare l'intera matrice X
    X_test = X_test(1:end-1, :); % elimina l'ultima riga di X per fargli avere le stesse righe di Y
    
    Y_pred = X_test * M_hat;
    err = Y_test - Y_pred;
    
    rmse_value = sqrt(mean((Y_test - Y_pred).^2, 'all'));
    RMSE = rmse_value;
end


%% test



%% train loop
packet_loss_probs = 0:0.02:1; % Create an array of packet loss probabilities from 0 to 1
rmse_values = zeros(size(packet_loss_probs)); % Preallocate array for RMSE values
num_samples = 100; % Number of samples to average for each packet loss probability
rmse_values_multi = zeros(length(packet_loss_probs), num_samples); % Preallocate array for multiple RMSE values

parfor idx = 1:length(packet_loss_probs)
    for sample_idx = 1:num_samples
        rmse_values_multi(idx, sample_idx) = get_rmse_lerp(packet_loss_probs(idx), recdata_train, recdata_train); % Calculate RMSE for each probability
    end
    disp(idx)
end

%% plot
% — your original data —
% points: 40×100   (40 original p_loss levels × 100 samples each)
% p_loss_vals: 1×40   (the true packet‐loss rates, not equally spaced)

% 1) choose how many new x‑positions you want:
K = 80;   % e.g. 80 evenly spaced levels

% 2) build the new, evenly spaced vector between min and max of your original:
p_vals = linspace( min(p_loss_vals), max(p_loss_vals), K );  % 1×K

% 3) interpolate your 40×100 matrix along the "loss" dimension
%    interp1 will give you a K×100 matrix `points_new`:
points_new = interp1( ...
    p_loss_vals, ...     % x locations of your existing rows
    points,    ...       % the 40×100 data matrix
    p_vals,    ...       % new x locations (1×K)
    'linear'...        % interpolation metho         % extrapolate outside [min,max] if needed
);  


% 3) Draw the boxes *only* at those real x‑positions:
figure;
h = boxplot(X_sorted', ...
           'positions', pos_sorted, ...
           'Widths',    0.5, ...    % try thinner boxes if they overlap
           'Labels',    {});        % turn off the default 1–40 labels
set(h, 'LineWidth', 1.2)

% 4) Pick a sparse subset of ticks so they don't overlap:
step = 1;   % every 5th box
sel  = 1:step:numel(pos_sorted);

%xticks( pos_sorted(sel) )
%xticklabels( arrayfun(@(x) sprintf('%.1f%%', x), pos_sorted(sel), 'uni',0) )
%xtickangle(45)

xlabel('Packet‑loss probability (%)')
ylabel('Tracking cost')
title('Tracking cost vs Packet‑Loss Rate')
grid on

% 5) (Optional) Tweak the limits so the outer boxes aren't cut off:
%xlim( [ min(pos_sorted) - step/2,  max(pos_sorted) + step/2 ] )
