% Create controller
Ts = 0.01;            % integration/sample time
ctrl = PIDController(0, 0, 0, Ts, -10000, 10000);


% Define parameters
params.M   = 1.0;         % cart mass (1kg)
params.m   = 0.3;         % pendulum mass (0.3kg)
params.l   = .2;         % pendulum length (20cm)
params.b   = 0.1;         % cart viscous friction
params.c   = 0.00;        % pivot friction
params.g   = 9.81;        % gravity
params.controller = ctrl;

% Initial conditions: [x0; xdot0; theta0; thetadot0]
y0 = [ 0;    0;   pi+0.1;   0 ];  
% e.g. slightly perturbed upside-down pendulum

% Time span
tspan = [0, 40];  % simulate from t=0 to t=10 seconds

% Solve
opts = odeset('RelTol',1e-6,'AbsTol',1e-8);
[t, Y] = ode45(@(t,y) invpendulum(t, y, params), tspan, y0, opts);

% Extract results
x      = Y(:,1);
x_dot  = Y(:,2);
theta  = Y(:,3);
th_dot = Y(:,4);

% Plot
figure;
subplot(2,1,1);
plot(t, x, 'LineWidth',1.5)
xlabel('Time (s)'), ylabel('x (m)')
title('Cart Position');

subplot(2,1,2);
plot(t, theta, 'LineWidth',1.5)
xlabel('Time (s)'), ylabel('\theta (rad)')
title('Pendulum Angle');

animation_viewer