%% COMPARES SIMULATED OUTPUT TO PREDICTED OUTPUT FROM SYSTEM
% Supposes these variables are available in workspace
% sys_cl: closed loop system to compare simulation data against

%% Compares linear to sim
load("readings\simrecord6.mat")
[y, tOut] = initial(sys_cl, recdata.info.initial_cond);
figure()
subplot(2, 1, 1)
plot(tOut, y(:, 1), 'LineWidth',1.5)
xlabel('Time (s)'), ylabel('x (m)')
title('Cart Position (predicted)');

subplot(2, 1, 2)
plot(tOut, y(:, 3), 'LineWidth',1.5)
xlabel('Time (s)'), ylabel('\theta (rad)')
title('Pendulum angle (predicted)');

plot_data