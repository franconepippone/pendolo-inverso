close all 
clear
clc
format long

%% Caricamento del dataset
data = readtable("14-4/libero_pid.csv");

STATES = [data.theta, data.theta_dot, data.pos, data.vel];


%% Costruzione delle matrici di training con interpolazione
% iterpola i dati e li ricampiona alla frequenza esatta specificata da
% TIMESTEP

TIMESTEP = 10^-2 % 10ms

old_timestamps_s = data.timestamp / 1000; % converte i timestamps da ms a s

% crea la nuova sequenza di timestamps
new_timestamps = min(old_timestamps_s):TIMESTEP:max(old_timestamps_s); 

[inutile, N] = size(new_timestamps);
STATES_NEW = zeros(N, 4);
INPUTS_NEW = zeros(N, 1);

% popola le matrici di stato nuovo interpolando e ricampionando alla
% frequenza specificata
STATES_NEW(:, 1) = interp1(old_timestamps_s, data.theta, new_timestamps, 'pchip')';
STATES_NEW(:, 2) = interp1(old_timestamps_s, data.theta_dot, new_timestamps, 'pchip');
STATES_NEW(:, 3) = interp1(old_timestamps_s, data.pos, new_timestamps, 'pchip');
STATES_NEW(:, 4) = interp1(old_timestamps_s, data.vel, new_timestamps, 'pchip');
INPUTS_NEW(:, 1) = interp1(old_timestamps_s, data.input, new_timestamps, 'pchip');

Y = STATES_NEW(2:end, :); % elimina la prima riga (porta Y avanti nel tempo di un iterazione)
X = [STATES_NEW INPUTS_NEW];    % concatena gli inputs allo stato per creare l'intera matrice X
X = X(1:end-1, :); % elimina l'ultima riga di X per fargli avere le stesse righe di Y

% X e Y sono pronte ad essere usate per il training
disp("Number of training samples in X and Y:")
disp(N)

%% Stima delle matrici A e B del sistema con regressione lineare

% TRAIN_WINDOW stabilisce la porzione del dataset che viene usata per il training (utile se si vuole
% isolare una specifica finestra temporale, o per tagliare fuori porzioni
% di dati rumorose o troppo instabili)

train_percentuale = .7; % percentuale del dataset che viene usata come training
TRAIN_WINDOW = 1:round((N-1) * train_percentuale); % indici per estrarre la percentuale specificata
%TRAIN_WINDOW = 8800:(N-1)

Y_train = Y(TRAIN_WINDOW, :);
X_train = X(TRAIN_WINDOW, :);

% Linear regression 
M_hat = X_train\Y_train;

% estraggo le matrici A e B dal risultato
A = M_hat(1:4, :)';
B = M_hat(5, :)';

%% Testing

TEST_WINDOW = round((N-1) * train_percentuale):(N-1); % prende la restante parte del dataset

Y_test = Y(TEST_WINDOW, :);
X_test = X(TEST_WINDOW, :);

Y_predicted = X_test * M_hat;
err = Y_test - Y_predicted;

figure(1)
plot(err);
title('Errore sul dataset di test.');
grid on;

disp("Root mean squared error:")
rmse_value = sqrt(mean((Y_test - Y_predicted).^2, 'all'));
disp(rmse_value)


%% Grafico dei dati di partenza processati

% finestra delle iterazioni visualizzate sul grafico
ITER_WINDOW = 10000:15000;

% calcola, da ITER_WINDOW, la finestra temporale da visualizzare.
TIMEWINDOW_VIEW = [new_timestamps(ITER_WINDOW(1)), new_timestamps(ITER_WINDOW(end))];

% Plot della porzione di dataset specificato da ITER_WINDOW
figure(2)
plot(new_timestamps(ITER_WINDOW), STATES_NEW(ITER_WINDOW, :));
legend({'theta', "theta'", 'position', 'velocity'});

xlabel('time (s)');
ylim([-23, 23]);
xlim(TIMEWINDOW_VIEW);
title('Misurazione sistema reale');
grid on;


%% Simulazione del sistema con le matrici ottenute
% vediamo quanto si discosta dalle misurazioni reali

sys = ss(A, B, eye(4), 0, TIMESTEP);

% Intervallo su cui viene svolta la simulazione (lo riprende dalla section
% precedente)
ITER_START = ITER_WINDOW(1);
ITER_MAX = ITER_WINDOW(end);
U = INPUTS_NEW(ITER_START:ITER_MAX) * 0;
t = new_timestamps(ITER_START:ITER_MAX)';

x0 = STATES_NEW(ITER_START, :); % estrae lo stato a quell'iterazione

% simula il sistema dalle condizioni iniziali desiderate, 
% riproducendo gli ingressi presenti nel dataset
y = lsim(sys, U, t, x0);

figure(3)
plot(t, y);
legend({'theta', "theta'", 'position', 'velocity'}); 
ylim([-23, 23]);
xlim(TIMEWINDOW_VIEW);
title('Sistema simulato');
grid on;

% Plot dell'errore nel tempo

figure(4)
plot(t, STATES_NEW(ITER_START:ITER_MAX, :) - y);
legend({'theta err', "theta' err", 'position err', 'velocity err'}); 
ylim([-23, 23]);
xlim(TIMEWINDOW_VIEW);
title('Errore');
grid on;

%% Analisi del sistema state-space e costruzione del controllore State-Feedback

eigs(A);
R = ctrb(A, B);
rank(R);

poles = [.9996*exp(.0001i), .94*exp(-.0001i), .98*exp(.00i), .98*exp(-.00i)];
poles = [0.9996, 0.97190, 0.8614996, -0.089104]

K = acker(A, B, poles);
disp('Pole placement Gain K:')
disp(K);

%K = [7000 600 5 15]
eigs(A - B*K)

figure(5)

sys_cl = ss(A - B*K, zeros(4, 0), eye(4), 0, TIMESTEP);

x0 = [.2, -.5, 0, 10];
initial(sys_cl, x0);

Q = [10 0 0 0; 
    0 1 0 0; 
    0 0 1 0; 
    0 0 0 0];       % State cost matrix
R = 1;              % Control cost matrix

% Compute the optimal gain K using discrete LQR
[K, P, E] = dlqr(A, B, Q, R);

% Display results
disp('LQR Gain K:');
disp(K);

disp('Closed-loop eigenvalues:');
disp(E);
disp(P);

figure(6)

sys_cl_LQR = ss(A - B*K, zeros(4, 0), eye(4), 0, TIMESTEP);

initial(sys_cl_LQR, x0);



