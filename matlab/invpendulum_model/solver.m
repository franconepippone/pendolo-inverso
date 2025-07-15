close all 
clear
clc
format short

CUSTOM_NAME = "readings_final/test.mat";
SIM_NOTES = "new_fisica";

%% Create controller
Ts = 0.005;            % controller loop time (200 Hz)
Usat = 25;            % input saturation value


% -------------- PID
ctrl1 = PIDController(1000, 10, 100);
ctrl2 = PIDController(-500, -50, -300);
ctrl_pid = MultiPIDController(ctrl1, ctrl2, Ts, -Usat, Usat);



% --------------- SF
K = [-74.66163, -65.4395, 247.9755, 43.78731];
K = [-16756.6426, -6084.35995, 10885.565, 1678.14523];
K = [-2462.4194, -997.80662, 2118.703, 302.65539];
%K = [0,0,0,0];
%K = [-12688.634, 22078.6897, 3450.06451, 528.551888];
%K = [-2448.7728, -1010.5814, 2070.126, 296.5453];
%K = [-351.0722, -106.2279, 234.4758, 3640.24725];
ctrl_sf = SFController(K, Ts, -Usat, Usat);



% --------------- SF + Internal model design
Ke = [-1092.9579, -315.95446, 638.34815, 98.460198, -8.8319058];
Kx = Ke(1:4);
Ki = Ke(5);
ctrl_imd = LQIController(Kx, Ki, 0, Ts, -Usat, Usat); 


% chooses controller
ctrl_ideal = ctrl_sf;

% Turns it into a realistic controller (adds noise, packet loss...)
ctrl = RealisticController(ctrl_ideal);
ctrl.noise_std = .000 * [1 1 1 1];
ctrl.state_loss_prob = .0;
ctrl.input_loss_prob = 0;

% ================ Generate smooth square wave reference signal of amplitude 1
T = 10; % period
k = 2; % the lower the smoother
A = .2; % amplitude
smooth_wave = @(t) A * tanh(k * sin(2*pi*(t-T/4)/T)) + A;


% Generates reference signal by combining square waves
poly_f = @(f, t) f(t) + f(t * 2.15) * 0.4 + 0.1 *f(t * 5) + f(t * 0.5); 
%poly_f = @(f, t) f(t) - 0.4 * f(t*2.15) + 0.8 * f(t * 0.3) - f(t*1.5);
%poly_f = @(f, t) f(t)*0;
%poly_f = @(f, t) 0;

ctrl.RefFunc = @(t) [
    poly_f(smooth_wave, t); %square(pi / 4 * t);
    zeros(size(t)); %poly_f(derivative_sq, t); 
    zeros(size(t)); 
    zeros(size(t))];

% Smooth ramp reference
b = 8000; % roll-in factor
m = 100; % target speed (m/s)
smooth_ramp = @(t) (m*m * (t.*t))./(m*t + b);
der_smooth_ramp = @(t) (m*m*m* (t.*t) + 2 * m*m*b*t) ./ power(m*t + b, 2);

%ctrl.RefFunc = @(t) [smooth_ramp(t); der_smooth_ramp(t); 
%    zeros(size(t)); zeros(size(t))];


%% Simulate
% Initial conditions: [x0; xdot0; theta0; thetadot0]
x0 = [0,0,0,0.2]';
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

%% Debug simulation info
disp("Reference parameters:")
% Print variables in a compact format
fprintf('T: %.2f, k: %.2f, A: %.2f\n\n', T, k, A);
disp("Simulation parameters:")
% Print variables in a compact format
fprintf('t_max: %.2f, x0: [%.2f, %.2f, %.2f, %.2f]\n\n', t_max, x0);

disp("PID Gains for ctrl1:")
fprintf('Kp: %.2f, Ki: %.2f, Kd: %.2f\n', ctrl1.Kp, ctrl1.Ki, ctrl1.Kd);

disp("PID Gains for ctrl2:")
fprintf('Kp: %.2f, Ki: %.2f, Kd: %.2f\n', ctrl2.Kp, ctrl2.Ki, ctrl2.Kd);

poly_f

% % Automatically copy the command window text to clipboard
% commandWindowText = evalc('disp(get(0, ''CommandWindow'')'); % Capture the command window text
% clipboard('copy', commandWindowText); % Copy to clipboard
% disp('Command window text copied to clipboard.');

%% Compute tracking fitness

% disp("Tracking fitness:")
% fit = 1 / (sum(abs(recdata.states(:, 1) - recdata.reference(1, :)')) / t_max);
% disp(fit)

%% Debugging the instant jumps error
% the cause was found to be sudden jumps in reference signal first
% derivative. We made the reference signal differentiable to solve this
% figure;
% subplot(1, 3, 1);
% plot(ctrl_pid.pid2.state_log);
% hold on;
% plot(recdata.reference(1, :), 'Color', 'Red'); hold on;
% plot(recdata.states(:, 1), 'Color', 'Blue');
% subplot(1, 3, 2);
% plot(ctrl_pid.pid1.state_log);
% subplot(1, 3, 3);
% plot(recdata.inputs);
% linkaxes(findall(gcf,'Type','axes'),'x');
% 
% figure;
% plot(ctrl_pid.pid2.state_log(:, 2) / -ctrl_pid.pid2.Kd );
% hold on;
% plot(recdata.states(:, 2));
% linkaxes(findall(gcf,'Type','axes'),'x');


%% Play animation
animation_viewer(recdata)
