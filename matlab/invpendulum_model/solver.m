close all 
clear
clc
format short

RECORDNAME = "readings/pid1";

%% Create controller
Ts = 0.005;            % controller loop time (200 Hz)
Usat = 100;            % input saturation value

% PID
ctrl1 = PIDController(1200, 0, 100);
ctrl2 = PIDController(-500, 0, -300);
ctrl_pid = MultiPIDController(ctrl1, ctrl2, Ts, -Usat, Usat);

% SF
K = [-500,-300, 1200,100];
ctrl_sf = SFController(K, Ts, -Usat, Usat);

% chooses controller
ctrl = ctrl_pid;

% Generate smooth square wave reference signal of amplitude 1
T = 5; % period
k = 20;
square_wave = @(t) (1 ./ (1 + exp(-k * (mod(t, T) - T/4))) - ...
                     1 ./ (1 + exp(-k * (mod(t, T) - 3*T/4))));

% maps square wave to state variables
ctrl.RefFunc = @(t) [.2; 0; 0; 0] * square_wave(t); 

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
x0 = [ .3;    -.2;   pi+0.02;   -.01];  
% e.g. slightly perturbed upside-down pendulum

% Time span
tspan = [0, 10];  % simulate from t=0 to t=10 seconds

%% Simulate
% Solve
%opts = odeset('RelTol',1e-6,'AbsTol',1e-8);
%[t, Y] = ode45(@(t,y) invpendulum(t, y, params), tspan, y0, opts);
simTs = 0.001;
[t, X] = rk4_fixed_step(@(t, x) invpendulum(t, x, params), tspan, x0, simTs);

% Extract results
x      = X(:,1);
x_dot  = X(:,2);
theta  = X(:,3) - pi;
th_dot = X(:,4);

% Extract input 
[t_u, U] = ctrl.getInputPlot();

% Calculates reference state
x_ref = ctrl.RefFunc(t);

%% Saves data (WIP fixa gli intervalli di campionamento del controller t_u)
save(RECORDNAME + ".mat","X", "U", "x_ref", "t", "t_u");

%% Plot results
plot_data

%% Play animation
animation_viewer