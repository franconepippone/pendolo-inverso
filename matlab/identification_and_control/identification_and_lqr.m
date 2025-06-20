close all
clear
clc
format short

RECORDNAME_TRAIN = "readings/tesi_pid_train1.mat";
RECORDNAME_TEST = "readings/tesi_pid_test1.mat";

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

Q = diag([10000 0 0 0]);    % State cost matrix
R = .00001;              % Control cost matrix

% Compute the optimal gain K using discrete LQR
[K, P, E] = dlqr(A, B, Q, R);
disp('LQR Gain K:')
disp(strjoin(string(K), ', '));


%% Valutazione con simulazioni
compare_systems
