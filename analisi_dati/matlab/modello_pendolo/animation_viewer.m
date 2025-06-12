%--- PREPARE DATA ------------------------------------------------
% Suppose you've already solved and have:
% t      : [N×1] time vector
% x      : [N×1] cart positions
% theta  : [N×1] pendulum angles (rad)
% l      : pendulum length (scalar)

%--- SET UP FIGURE ------------------------------------------------
figure('Color','w');
axis equal;
hold on;
grid on;
xlabel('x (m)');
ylabel('y (m)');
%xlim([min(x)-params.l-0.5, max(x)+params.l+0.5]);
xlim([-1, 1])
ylim([-params.l-0.2, params.l+0.2]);

% Draw ground line
plot(xlim, [0 0], 'k', 'LineWidth', 1);

% Initial cart rectangle
cartW = 0.1;  % cart half‐width
cartH = 0.05;  % cart half‐height
cartY = -cartH;  % so top of cart is at y=0
cartX = x(1) + [-cartW, +cartW, +cartW, -cartW, -cartW];
cartYv= cartY + [0, 0, cartH*2, cartH*2, 0];
hCart = fill(cartX, cartYv, [0.2 0.2 0.8]);  % blue cart

% Initial pendulum line
xp = x(1) + params.l*sin(theta(1));
yp =            - params.l*cos(theta(1));
hPend = plot([x(1), xp], [0, yp], 'r-', 'LineWidth', 2);

%--- ANIMATION LOOP -----------------------------------------------
for k = 1:length(t)
    % Current state
    xc = x(k);
    th = theta(k);
    
    % Update cart
    cartX = xc + [-cartW, +cartW, +cartW, -cartW, -cartW];
    set(hCart, 'XData', cartX);
    
    % Update pendulum
    xp = xc + params.l*sin(th);
    yp =        - params.l*cos(th);
    set(hPend, 'XData', [xc, xp], 'YData', [0, yp]);
    
    % Draw and pause
    %drawnow;
    % Optionally slow down to real time:
    pause( t( min(k+1,end) ) - t(k) );
end