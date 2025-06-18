% Assume we have:
%   recdata: a simulation record struct available

theta = recdata.states(:, 3);
x = recdata.states(:, 1);
U = recdata.inputs;
x_ref = recdata.reference;

%% Plot results
figure;
subplot(3,1,1);
plot(recdata.t, x_ref(1, :), 'LineWidth', 1.5, 'Color', 'red')
hold on;
plot(recdata.t, x, 'LineWidth',1.5, 'Color', 	[0.0000, 0.4470, 0.7410])
xlabel('Time (s)'), ylabel('x (m)')
title('Cart Position');

subplot(3,1,2);
plot(recdata.t, rad2deg(theta), 'LineWidth',1.5)
xlabel('Time (s)'), ylabel('\theta (deg)')
title('Pendulum Angle');


subplot(3,1,3);
plot(recdata.t, U, 'LineWidth',1.5)
xlabel('Time (s)'), ylabel('u (newtons)')
title('Input force');

if isfield(recdata.info, 'title')
    sgtitle(recdata.info.title); % Assigns a title to the whole group
end