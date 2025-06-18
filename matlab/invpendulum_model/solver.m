close all 
clear
clc
format short

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


%% Simulate
% Initial conditions: [x0; xdot0; theta0; thetadot0]
x0 = [ 1;    -1;   .2;   -.6];
t_max = 5;

recdata = solve_invpen(x0, ctrl, 5);
recdata.info.notes = SIM_NOTES;  % add description to simulation 

%% Save simulation
save_recdata(recdata);

%% Plot results
plot_data

%% Play animation
animation_viewer