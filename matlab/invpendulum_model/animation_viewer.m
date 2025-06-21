function animation_viewer(recdata)
    %% PREPARE DATA ------------------------------------------------
    params = recdata.info.sim_params;
    theta = recdata.states(:, 3);
    t = recdata.t;
    x = recdata.states(:, 1);
    
    %% SET UP FIGURE ------------------------------------------------
    fig = figure('Color','w');
    ax = axes(fig);        % Create axes and get handle
    axis equal;
    hold on;
    grid on;
    xlabel('x (m)');
    ylabel('y (m)');
    %xlim([min(x)-params.l-0.5, max(x)+params.l+0.5]);
    xlim([-1, 1])
    ylim([-params.l-0.2, params.l+0.2]);
    
    % Draw ground line
    plot([-10000, 100000], [0 0], 'k', 'LineWidth', 1);
    
    % Initial cart rectangle
    cartW = 0.1;  % cart half‐width
    cartH = 0.05;  % cart half‐height
    cartY = -cartH;  % so top of cart is at y=0
    cartX = x(1) + [-cartW, +cartW, +cartW, -cartW, -cartW];
    cartYv= cartY + [0, 0, cartH*2, cartH*2, 0];
    hCart = fill(cartX, cartYv, [0.2 0.2 0.8]);  % blue cart
    
    % Initial pendulum line
    xp = x(1) - params.l*sin(theta(1));
    yp =            + params.l*cos(theta(1));
    hPend = plot([x(1), xp], [0, yp], 'r-', 'LineWidth', 2);
    
    % Add Restart Button
    uicontrol('Style', 'pushbutton', 'String', 'Restart', ...
              'Position', [20 20 60 30], ...
              'Callback', @(src, event) run_animation());

    xl = xlim;
    xmin = xl(1);
    xmax = xl(2);
    xsize = xmax - xmin;
    current_disp_offset = 0;

    %% ANIMATION LOOP -----------------------------------------------
    function run_animation()
        for k = 1:length(t)
            if ~isvalid(fig), return; end
            % Current state
            xc = x(k);
            th = theta(k);
            
            % Update cart
            cartX = xc + [-cartW, +cartW, +cartW, -cartW, -cartW];
            set(hCart, 'XData', cartX);
            
            % Update pendulum
            xp = xc - params.l*sin(th);
            yp =        + params.l*cos(th);
            set(hPend, 'XData', [xc, xp], 'YData', [0, yp]);

            disp_offset = xsize * floor((xc + 1)/xsize);
            if disp_offset ~= current_disp_offset
                current_disp_offset = disp_offset;
                xlim(ax, [-1 + disp_offset, 1 + disp_offset]);
            end
            
            % Draw and pause
            %drawnow;
            % Optionally slow down to real time:
            pause( t( min(k+1,end) ) - t(k) );
        end
    end

    run_animation();

end