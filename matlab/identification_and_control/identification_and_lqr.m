close all
clear
clc
format short

RECORDNAME_TRAIN = "readings_final/pid_train.mat";
RECORDNAME_TEST = "readings_final/pid_test.mat";

%% Caricamento del dataset

load(RECORDNAME_TRAIN);
recdata_train = recdata;
TIMESTEP = recdata.info.controller_ts;

%% Identification using linear regression

STATES_tr = recdata_train.states;
INPUTS_tr = recdata_train.inputs;

[A, B] = ident_lr(STATES_tr, INPUTS_tr);

%% Evaluation of trainining

eval_ident(A, B, STATES_tr, INPUTS_tr, "train"); % eval on train dataset

load(RECORDNAME_TEST);
eval_ident(A, B, recdata.states, recdata.inputs, "test");

%% State space analysis and LQR

eigs(A);
R = ctrb(A, B);
rank(R);

Q = diag([1000 0 100 0]);    % State cost matrix
R = .0001;              % Control cost matrix

% Compute the optimal gain K using discrete LQR
[K, P, E] = dlqr(A, B, Q, R);
disp('LQR Gain K:')
disp(strjoin(string(K), ', '));


%% Valutazione con simulazioni
compare_systems

%% Internal model design for STEP

Ad = A;
Bd = B;
Ts = TIMESTEP;

C = [1 0 0 0];
A_aug = [Ad, zeros(4,1); 
         C, 1];        % (5x5)
B_aug = [Bd; 
         0]; 

Qx = diag([1000,5,100,0]);         % penalize all 4 states equally
Qi = 1;            % penalize integrator state (helps enforce tracking)
Q = blkdiag(Qx, Qi); % 5x5
R = .01;               % penalize control effort

Ke = dlqr(A_aug, B_aug, Q, R);  % 1x5
Kx = Ke(1:4);   % State feedback
Ki = Ke(5);     % Integrator gain

disp('LQR Gain K on extended system (imd):')
disp(strjoin(string(Ke), ', '));

% Simulate
x = [-.01, 0, .1, 0]'; xi = 0;
r = .2;
N = 1000;
xlog = zeros(4,N); ylog = zeros(1,N); ulog = zeros(1,N);


for k = 1:N
    y = C*x;
    u = -Kx*x - Ki*xi;
    x = Ad*x + Bd*u;
    xi = xi + (y - r * (k > 500));  % discrete integrator

    xlog(:,k) = x;
    ylog(k) = y;
    ulog(k) = u;
end

time = (0:N-1)*Ts;
figure('WindowStyle', 'normal', 'Units', 'pixels', 'Position', [200, 200, 1000, 550]);
plot(time, ylog), grid on, hold on
plot(time, r * (1:N > 500))
title('Tracking x_1 with Discrete LQI')
xlabel('Time [s]'); ylabel('x_1')

%% IMD for ramp
error('Script execution has been forcefully stopped.');

Ad = A;
Bd = B;
Ts = TIMESTEP;

% Aumentiamo il sistema con 2 integratori
n = size(A,1);  % n = numero di stati

C = [1 0 0 0];
A_aug = [A         zeros(n,2);
         -C        1       0;
         zeros(1,n) 1       1];

B_aug = [B;
         0;
         0];

Qx  = diag([1000, 0, 1000, 0]);  % penalità sui tuoi 4 stati originali
Qi1 = 100;            % penalità sull'integratore (errore)
Qi2 = 0.0001;             % penalità sul doppio integratore
Q   = blkdiag(Qx, Qi1, Qi2);

R = 0.1; % o come desideri per il costo del controllo           % penalize control effor

K_aug = dlqr(A_aug, B_aug, Q, R);

Kx  = K_aug(1:n);        % guadagno sui tuoi stati originali
Ki1 = K_aug(n+1);        % guadagno sull'integratore dell'errore
Ki2 = K_aug(n+2);        % guadagno sul doppio integratore

disp('LQR Gain K on extended system (imd ramp):')
disp(strjoin(string(K_aug), ', '));


% Inizializzazione
x = [-.01; 0; .1; 0];     % stato iniziale del sistema
xe1 = 0;                 % primo integratore dell'errore
xe2 = 0;                 % secondo integratore (integra xe1)
r = 0.2;                 % riferimento (rampa o gradino)
N = 1000;                % numero di passi di simulazione
xlog = zeros(4,N);       % log stato
ylog = zeros(1,N);       % log uscita
ulog = zeros(1,N);       % log ingresso

ref = @(k) (k - 500) .* 1 .* r .* (k > 500) - (k - 510) .* 1 .* r .* (k > 510);

for k = 1:N
    y = C * x;
    
    % Calcolo dell'ingresso di controllo
    u = -Kx * x - Ki1 * xe1 - Ki2 * xe2;

    % Evoluzione sistema
    x = Ad * x + Bd * u;
    
    % Aggiornamento integratori
    err = ref(k) - y;  % inizia il riferimento dopo t = 500*Ts
    xe1 = xe1 + err;
    xe2 = xe2 + xe1;

    % Logging
    xlog(:,k) = x;
    ylog(k) = y;
    ulog(k) = u;
end

% Traccia risultati
time = (0:N-1) * Ts;
figure;
plot(time, ylog), grid on, hold on
plot(time, ref(1:N));
%figure
%plot(time, ulog), grid on

title('Tracking x_1 with Discrete LQI (2 integrators)')
xlabel('Time [s]');
ylabel('x_1');
