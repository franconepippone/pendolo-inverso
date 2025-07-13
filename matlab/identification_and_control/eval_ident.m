function eval_ident(A, B, states_test, inputs_test, dataset_name)
    % Generates error graphs and prints rmse by testing the A, B matrices
    % againts the provided dataset

    %% Train dataset preparation
    Y_test = states_test(2:end, :); % elimina la prima riga (porta Y avanti nel tempo di un iterazione)
    X_test = [states_test inputs_test];    % concatena gli inputs allo stato per creare l'intera matrice X
    X_test = X_test(1:end-1, :); % elimina l'ultima riga di X per fargli avere le stesse righe di Y
    
    M_hat = [A'; B']; % rebuild M hat

    %% Plot results
    Y_pred = X_test * M_hat;
    err = Y_test - Y_pred;
    
    figure('WindowStyle', 'normal', 'Units', 'pixels', 'Position', [200, 200, 1100, 700]);
    subplot(4, 1, 1); plot([X_test(:, 1) ]); ylabel('m'); title("x (meters)");
    subplot(4, 1, 2); plot([err(:, 1)], 'Color', [0.85, 0.32, 0.09]); title("Error on next prediction of x"); grid on;
    subplot(4, 1, 3); plot([X_test(:, 3)]); title("theta (radians)"); ylabel('rad');
    subplot(4, 1, 4); plot([err(:, 3)], 'Color', [0.85, 0.32, 0.09]); title("Error on next prediction of theta");
    grid on;
    
    text = "";
    if nargin > 4
        text = " " + dataset_name;
    end

    sgtitle("Errore sul" + text + " dataset"); % Assigns a title to the whole group

    disp("Root mean squared error on" + text + " dataset:")
    rmse_value = sqrt(mean((Y_test - Y_pred).^2, 'all'));
    disp(rmse_value)
    
end