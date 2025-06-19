close all 
clear
clc
format short

CUSTOM_NAME = "";
SIM_NOTES = "test con realistic controller";

%% Create controller
Ts = 0.005;            % controller loop time (200 Hz)
Usat = 100;            % input saturation value

% PID
ctrl1 = PIDController(1000, 0, 85);
ctrl2 = PIDController(-500, 0, -300);
ctrl_pid = MultiPIDController(ctrl1, ctrl2, Ts, -Usat, Usat);

% SF
K = [-74.66163, -65.4395, 247.9755, 43.78731];
K = [-16756.6426, -6084.35995, 10885.565, 1678.14523];
K = [0,0,0,0];
ctrl_sf = SFController(K, Ts, -Usat, Usat);

% chooses controller
ctrl_ideal = ctrl_sf;

% Turns it into a realistic controller (adds noise, packet loss...)
ctrl = RealisticController(ctrl_ideal);
ctrl.noise_var = 0 * [1 1 .1 .1];
ctrl.state_loss_prob = 0;
ctrl.input_loss_prob = 0;

% Generate smooth square wave reference signal of amplitude 1
T = 5; % period
k = 5; % the lower the smoother
square_wave = @(t) (1 ./ (1 + exp(-k * (mod(t, T) - T/4))) - ...
                     1 ./ (1 + exp(-k * (mod(t, T) - 3*T/4))));

derivative_sq = @(t) ...
    k*exp(-k*(mod(t,T) - T/4))    ./ (1 + exp(-k*(mod(t,T) - T/4))).^2 ...
  - k*exp(-k*(mod(t,T) - 3*T/4))./(1 + exp(-k*(mod(t,T) - 3*T/4))).^2;

% maps square wave to state variables and uses it as the reference state
ctrl.RefFunc = @(t) [.2; 0; 0; 0] * ( ...
    square_wave(t) + 0.4 * square_wave(t*2.15))*0; 

ctrl.RefFunc = @(t) [square_wave(t');0; 0; 0];


%% Simulate
% Initial conditions: [x0; xdot0; theta0; thetadot0]
x0 = [ 0;    0;   0.01;   0];
t_max = 20;

recdata = solve_invpen(x0, ctrl, t_max);
recdata.info.notes = SIM_NOTES;  % add description to simulation

%% Save simulation
if CUSTOM_NAME == ""
    save_recdata(recdata);
else
    save_recdata(recdata, CUSTOM_NAME)
end


%% Plot results
plot_data

%% Play animation
animation_viewer(recdata)