close all 
clear
clc
format longG


%% Caricamento del dataset

data1 = readtable("fixed_reading/PID-lenti-tracking-target.csv", "CommentStyle", "#"); % La regressione lineare non funziona
% usa ident

data2 = readtable("simulazioni/old/nonlin_normalnoise1.csv", "CommentStyle", "#"); 

data3 = readtable("recuperati/bassi_autovalori_con_target.csv", "CommentStyle", "#");

data4 = readtable("simulazioni/new/data2.csv", "CommentStyle", "#");

data = data4;

STATES = [data.theta, data.theta_dot, data.pos, data.vel];
INPUTS = data.input;

%% Post-processing dei dati

STATES = STATES(100:end, :);
INPUTS = INPUTS(100:end, :);

[N, ~] = size(INPUTS);

%% Preparazione dei database di test e train

Y = STATES(2:end, :); % elimina la prima riga (porta Y avanti nel tempo di un iterazione)
X = [STATES INPUTS];    % concatena gli inputs allo stato per creare l'intera matrice X
X = X(1:end-1, :); % elimina l'ultima riga di X per fargli avere le stesse righe di Y

% usate per la regressione
X_train = X;
Y_train = Y;

% usate per il testing
X_test = X;
Y_test = Y;

%% Regressione lineare

% Linear regression 
M_hat = X_train\Y_train;

% estraggo le matrici A e B dal risultato
A = M_hat(1:4, :)';
B = M_hat(5, :)';

%% Valutazione sul database di TEST
Y_pred = X_test * M_hat;
err = Y_test - Y_pred;

figure()
subplot(4, 1, 1); plot([X(:, 1) err(:, 1)]); legend({'theta', "error"}); 
title('Errore sul dataset di test.');
subplot(4, 1, 2); plot([X(:, 2) err(:, 2)]); legend({'theta prime', "error"});
subplot(4, 1, 3); plot([0.0001 * X(:, 3) err(:, 3)]); legend({'cart position (x10-4)', "error"});
subplot(4, 1, 4); plot([0.02 * X(:, 4) err(:, 4)]); legend({'cart velocity (x10-1)', "error"});
grid on;

disp("Root mean squared error on test database:")
rmse_value = sqrt(mean((Y_test - Y_pred).^2, 'all'));
disp(rmse_value)

%% Valutazione sul database di TRAIN
Y_pred = X_train * M_hat;
err = Y_train - Y_pred;

figure()
subplot(4, 1, 1); plot([X(:, 1) err(:, 1)]); legend({'theta', "error"});
title('Errore sul dataset di train.');
subplot(4, 1, 2); plot([X(:, 2) err(:, 2)]); legend({'theta prime', "error"});
subplot(4, 1, 3); plot([.01 * X(:, 3) err(:, 3)]); legend({'cart position (x10-2)', "error"});
subplot(4, 1, 4); plot([0.02 * X(:, 4) err(:, 4)]); legend({'cart velocity (x10-1)', "error"});
grid on;

disp("Root mean squared error on train database:")
rmse_value = sqrt(mean((Y_train - Y_pred).^2, 'all'));
disp(rmse_value)

%% Simulazione sistema discreto
TIMESTEP = 0.01;

sys = ss(A, B, eye(4), 0, TIMESTEP);

ITER_START = 100;
U = INPUTS(ITER_START:end);
t = (ITER_START:N) * 0.01;

x0 = STATES(ITER_START, :); % estrae lo stato a quell'iterazione

% simula il sistema dalle condizioni iniziali
% riproducendo gli ingressi presenti nel dataset
y = lsim(sys, U, t, x0);

figure()
title("Stato del sistema simulato");
title("Stato del sistema simulato");
plot(t, [U y]);
ylim([-23, 23]);
legend({'input', 'theta', "theta'", 'position', 'velocity'}); 

figure()
title("Stato del sistema misurato")
plot(t, [U STATES(ITER_START:end, :)]);
ylim([-23, 23]);
legend({'input','theta', "theta'", 'position', 'velocity'});


%% Analisi del sistema state-space e costruzione del controllore State-Feedback

eigs(A);
R = ctrb(A, B);
rank(R);

poles = [.9996*exp(.0001i), .94*exp(-.0001i), .98*exp(.00i), .98*exp(-.00i)];
%poles = [0.9996, 0.97190, 0.8614996, -0.089104];

K = acker(A, B, poles);
disp('Pole placement Gain K:')
disp(K);

Q = [100 0 0 0; 
    0 10 0 0; 
    0 0 100 0; 
    0 0 0 10];       % State cost matrix
R = .01;              % Control cost matrix

% Compute the optimal gain K using discrete LQR
[K, P, E] = dlqr(A, B, Q, R);
disp('LQR Gain K:')
disp(strjoin(string(K), ', '));
figure()

sys_cl = ss(A - B*K, zeros(4, 0), eye(4), 0, TIMESTEP);

initial(sys_cl, x0);




