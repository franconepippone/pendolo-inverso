function eval_ident(A, B, states_test, inputs_test)
    %% Train dataset preparation
    Y_test = states_test(2:end, :); % elimina la prima riga (porta Y avanti nel tempo di un iterazione)
    X_test = [states_test inputs_test];    % concatena gli inputs allo stato per creare l'intera matrice X
    X_test = X_test(1:end-1, :); % elimina l'ultima riga di X per fargli avere le stesse righe di Y
    
    M_hat = [A'; B']; % rebuild M hat

    %% Plot results
    Y_pred = X_test * M_hat;
    err = Y_test - Y_pred;
    
    figure()
    subplot(4, 1, 1); plot([X_test(:, 1) err(:, 1)]); legend({'theta', "error"}); 
    title('Errore sul dataset di test.');
    subplot(4, 1, 2); plot([X_test(:, 2) err(:, 2)]); legend({'theta prime', "error"});
    subplot(4, 1, 3); plot([0.01 * X_test(:, 3) err(:, 3)]); legend({'cart position (x10-2)', "error"});
    subplot(4, 1, 4); plot([0.02 * X_test(:, 4) err(:, 4)]); legend({'cart velocity (x2*10-2)', "error"});
    grid on;
    
    disp("Root mean squared error on test database:")
    rmse_value = sqrt(mean((Y_test - Y_pred).^2, 'all'));
    disp(rmse_value)

end