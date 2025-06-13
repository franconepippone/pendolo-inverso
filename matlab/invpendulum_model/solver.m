% close all 
% clear
% clc
% format short

%% Create controller
Ts = 0.005;            % controller loop time (200 Hz)
Usat = 100;

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
y0 = [ .3;    -.2;   pi+0.02;   -.01];  
% e.g. slightly perturbed upside-down pendulum

% Time span
tspan = [0, 10];  % simulate from t=0 to t=10 seconds

%% Simulate
% Solve
%opts = odeset('RelTol',1e-6,'AbsTol',1e-8);
%[t, Y] = ode45(@(t,y) invpendulum(t, y, params), tspan, y0, opts);
simTs = 0.001;
[t, Y] = rk4_fixed_step(@(t, y) invpendulum(t, y, params), tspan, y0, simTs);

% Extract results
x      = Y(:,1);
x_dot  = Y(:,2);
theta  = Y(:,3);
th_dot = Y(:,4);

% Extract input 
[t_u, u] = ctrl.getInputPlot();

%% Plot results
figure;
subplot(3,1,1);
y_ref = ctrl.RefFunc(t);
plot(t, y_ref(1, :), 'LineWidth', 1.5, 'Color', 'red')
hold on;
plot(t, x, 'LineWidth',1.5, 'Color', 	[0.3010 0.7450 0.9330])
xlabel('Time (s)'), ylabel('x (m)')
title('Cart Position');

subplot(3,1,2);
plot(t, theta - pi, 'LineWidth',1.5)
xlabel('Time (s)'), ylabel('\theta (rad)')
title('Pendulum Angle');


subplot(3,1,3);
plot(t_u, u, 'LineWidth',1.5)
xlabel('Time (s)'), ylabel('u (newtons)')
title('Input force');


%% Play animation
animation_viewer