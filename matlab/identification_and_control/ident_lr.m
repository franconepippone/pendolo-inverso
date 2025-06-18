function [A, B] = ident_lr(states, inputs)
    %% Train dataset preparation
    Y = states(2:end, :); % elimina la prima riga (porta Y avanti nel tempo di un iterazione)
    X = [states inputs];    % concatena gli inputs allo stato per creare l'intera matrice X
    X = X(1:end-1, :); % elimina l'ultima riga di X per fargli avere le stesse righe di Y
    
    %% Linear regression
    M_hat = X\Y;
    
    % estraggo le matrici A e B dal risultato
    A = M_hat(1:4, :)';
    B = M_hat(5, :)';

end