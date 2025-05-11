%% Data viewer and editor

data = readtable("analisi_dati/bad/buone/libero_2.csv", "CommentStyle", "#");

STATES = [data.theta, data.theta_dot, data.pos, data.vel];

TIMESTEP = 10^-2 % 10ms

old_timestamps_s = data.timestamp / 1000; % li trasforma in secondi

% nuovi timestamps
new_timestamps = min(old_timestamps_s):TIMESTEP:max(old_timestamps_s); 

[m, N] = size(new_timestamps)
STATES_NEW = zeros(N, 4);
INPUTS_NEW = zeros(N, 1);

% Interpolate using PCHIP
STATES_NEW(:, 1) = interp1(old_timestamps_s, data.theta, new_timestamps, 'pchip')';
STATES_NEW(:, 2) = interp1(old_timestamps_s, data.theta_dot, new_timestamps, 'pchip');
STATES_NEW(:, 3) = interp1(old_timestamps_s, data.pos, new_timestamps, 'pchip');
STATES_NEW(:, 4) = interp1(old_timestamps_s, data.vel, new_timestamps, 'pchip');
INPUTS_NEW(:, 1) = interp1(old_timestamps_s, data.input, new_timestamps, 'pchip');

TIMEWINDOW_VIEW = [90 95]

% finestra delle iterazioni visualizzate sul grafico
ITER_WINDOW = 1:N;
%ITER_WINDOW = 1070:1800;

% Plot dello stato dal dataset e interpolato
figure(1)
plot(ITER_WINDOW, [INPUTS_NEW(ITER_WINDOW) STATES_NEW(ITER_WINDOW, :)]);
legend({'input', 'theta', "theta'", 'position', 'velocity'});

TIME_START = 45
TIME_END = 49

figure(2)
title('Dati raccolti');
subplot(2,1,1);  % 2 righe, 1 colonna, primo plot
plot(new_timestamps(ITER_WINDOW) - TIME_START, rad2deg(STATES_NEW(ITER_WINDOW, 1)), 'LineWidth',1.5);
yline(0, '--');
xlabel('time (s)');
ylabel('theta (deg)');
xlim([0, TIME_END-TIME_START])
ylim([-22, 18])

subplot(2,1,2);  % 2 righe, 1 colonna, primo plot
yline(0);
plot(new_timestamps(ITER_WINDOW) - TIME_START, STATES_NEW(ITER_WINDOW, 4), 'LineWidth',1.5);
yline(0, '--');
ylabel('cart position');
xlabel('time (s)');
xlim([0, TIME_END-TIME_START])
ylim([-160, 150])

%ylim([-23, 23]);
%xlim(TIMEWINDOW_VIEW);
grid on;

% 262 - 6290
% 6347 - 6583
% 7147 - 8197
% 8222 - 9408
% 9450 - 9829
% 9850 - 10621