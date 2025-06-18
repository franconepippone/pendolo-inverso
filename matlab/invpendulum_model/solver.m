close all 
clear
clc
format short

RECORDS_DIRECTORY = "readings/";
DEFAULT_RECORDNAME = "simrecord";
SIM_NOTES = "risposta a condizioni iniziali con sf gain calcolato con regressione su pid_train_1";

%% Create controller
Ts = 0.005;            % controller loop time (200 Hz)
Usat = 100;            % input saturation value

% PID
ctrl1 = PIDController(1200, 0, 100);
ctrl1 = PIDController(1200, 0, 90);
ctrl2 = PIDController(-500, 0, -300);
ctrl2 = PIDController(-1000, 0, -300);
ctrl_pid = MultiPIDController(ctrl1, ctrl2, Ts, -Usat, Usat);

% SF
K = [-500,-300, 1200,100];
K = [54.9983, -9.66205, 75.1428, 28.6297];
K = [-74.66163, -65.4395, 247.9755, 43.78731];
ctrl_sf = SFController(K, Ts, -Usat, Usat);

% chooses controller
ctrl = ctrl_sf;

% Generate smooth square wave reference signal of amplitude 1
T = 5; % period
k = 5; % the lower the smoother
square_wave = @(t) (1 ./ (1 + exp(-k * (mod(t, T) - T/4))) - ...
                     1 ./ (1 + exp(-k * (mod(t, T) - 3*T/4))));

% maps square wave to state variables and uses it as the reference state
ctrl.RefFunc = @(t) [.2; 0; 0; 0] * ( ...
    square_wave(t) + 0.4 * square_wave(t*2.15)) * 0; 

%% Setup simulation
% Define parameters
params.M   = 1.0;         % cart mass (1kg)
params.m   = 0.3;         % pendulum mass (0.3kg)
params.l   = .2;         % pendulum length (20cm)
params.b   = 1.2;         % cart viscous friction
params.c   = 0.01;        % pivot friction
params.g   = 9.81;        % gravity
params.controller = ctrl;

% Initial conditions: [x0; xdot0; theta0; thetadot0]
x0 = [ 1;    -1;   .2;   -.6];

% Time span
tspan = [0, 5];  % simulate from t=0 to t=10 seconds

%% Simulate
% Solve
simTs = 0.001;
x0_real = x0 + [0; 0; pi; 0]; % brings theta in the simulation frame (0 is downards, pi is upwards)
[t_sim, X_sim] = rk4_fixed_step(@(t, x) invpendulum(t, x, params), tspan, x0_real, simTs);
X_sim(:, 3) = X_sim(:, 3) - pi; % sets zero angle to be upwards

% Extract input 
[t, U] = ctrl.getInputPlot();
t = floor(t * 1000) / 1000; % truncates up to third decimal digit

% Extracts simulation states at time points matching controller execution times within epsilon tolerance
epsilon = 1e-6;
sameIdxs = any(abs(t_sim' - t) < epsilon, 2);
X = X_sim(sameIdxs, :);

% Extract results
x      = X(:,1);
x_dot  = X(:,2);
theta  = X(:,3);
th_dot = X(:,4);

% Calculates reference state
x_ref = ctrl.RefFunc(t);

%% Saves data in a struct
recdata.states = X;
recdata.inputs = U';
recdata.reference = x_ref;
recdata.t = t;

% saves additional meta data
recdata.info.sim_timespan = tspan;
recdata.info.initial_cond = x0;
recdata.info.sim_params = params;
recdata.info.controller_ts = Ts;
recdata.info.simulation_ts = simTs;
recdata.info.input_saturation = Usat;
recdata.info.date = datetime;
recdata.info.notes = SIM_NOTES;

% extract/increment/saves file counter (avoid duplicate files)
load(RECORDS_DIRECTORY + "counter.mat")
sim_file_counter = sim_file_counter + 1;
save(RECORDS_DIRECTORY + "counter.mat", "sim_file_counter");

recdata.info.og_filename = DEFAULT_RECORDNAME + string(sim_file_counter);
fullpath = RECORDS_DIRECTORY + recdata.info.og_filename + ".mat";
save(fullpath,"recdata");

%% Plot results
plot_data

%% Play animation
animation_viewer