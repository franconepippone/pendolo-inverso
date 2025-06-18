close all
clear
clc
format short

RECORDNAME_TRAIN = "readings/pid_train_1.mat";
RECORDNAME_TEST = "readings/pid_train_1.mat";

%% Caricamento del dataset

load(RECORDNAME_TRAIN);
recdata_train = recdata;
TIMESTEP = recdata.info.controller_ts;

%% Identification using linear regression

STATES_tr = recdata_train.states;
INPUTS_tr = recdata_train.inputs;

[A, B] = ident_lr(STATES_tr, INPUTS_tr);

%% Evaluation of trainining

eval_ident(A, B, STATES_tr, INPUTS_tr); % eval on train dataset

load(RECORDNAME_TEST);
eval_ident(A, B, recdata.states, recdata.inputs);

%% State space analysis and LQR

eigs(A);
R = ctrb(A, B);
rank(R);

Q = [100 0 0 0; 
    0 10 0 0; 
    0 0 100 0; 
    0 0 0 10];       % State cost matrix
R = .01;              % Control cost matrix

% Compute the optimal gain K using discrete LQR
[K, P, E] = dlqr(A, B, Q, R);
disp('LQR Gain K:')
disp(strjoin(string(K), ', '));

sys_cl = ss(A - B*K, zeros(4, 0), eye(4), 0, TIMESTEP);
