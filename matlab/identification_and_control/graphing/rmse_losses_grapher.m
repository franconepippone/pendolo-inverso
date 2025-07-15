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
packet_loss_probs = 0:0.01:1; % Create an array of packet loss probabilities from 0 to 1
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
mean_rmse_values = mean(rmse_values_multi, 2); % Calculate the mean RMSE for each packet loss probability
figure; % Create a new figure
plot(packet_loss_probs, mean_rmse_values, '-', 'LineWidth', 1.5); % Plot mean RMSE values against packet loss probabilities
xlabel('Packet Loss Probability'); % Label for x-axis
ylabel('Mean RMSE'); % Label for y-axis
title('Mean RMSE vs Packet Loss Probability'); % Title of the plot
grid on; % Enable grid
hold on;
