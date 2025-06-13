% Assume we have:
%   X:      state vector 
%   U:      input vector
%   x_ref:  state reference matrix (the tracked state)
%   t:      time vector
%   t_u:    input time vector


%% Plot results
figure;
subplot(3,1,1);
plot(t, x_ref(1, :), 'LineWidth', 1.5, 'Color', 'red')
hold on;
plot(t, x, 'LineWidth',1.5, 'Color', 	[0.3010 0.7450 0.9330])
xlabel('Time (s)'), ylabel('x (m)')
title('Cart Position');

subplot(3,1,2);
plot(t, theta, 'LineWidth',1.5)
xlabel('Time (s)'), ylabel('\theta (rad)')
title('Pendulum Angle');


subplot(3,1,3);
plot(t_u, U, 'LineWidth',1.5)
xlabel('Time (s)'), ylabel('u (newtons)')
title('Input force');