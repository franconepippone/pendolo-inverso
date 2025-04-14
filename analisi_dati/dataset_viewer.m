%% Data viewer and editor

data = readtable("14-4/libero_pid_long.csv");

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

% Plot dello stato dal dataset e interpolato
figure(1)
plot(ITER_WINDOW, STATES_NEW(ITER_WINDOW, :));
legend({'theta', "theta'", 'position', 'velocity'});

xlabel('sample');
%ylim([-23, 23]);
%xlim(TIMEWINDOW_VIEW);
title('Dati raccolti');
grid on;

% 262 - 6290
% 6347 - 6583
% 7147 - 8197
% 8222 - 9408
% 9450 - 9829
% 9850 - 10621