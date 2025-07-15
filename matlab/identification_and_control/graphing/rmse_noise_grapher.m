close all
clear
clc
format short



%% Simulazione

function points = get_points(std_vals, samples, ref_func)
    
    points = zeros(length(std_vals), samples);
    
    Ts = 0.005;
    Usat = 25;
    
    
    %% Simulate
    % Initial conditions: [x0; xdot0; theta0; thetadot0]
    x0 = [0, .2, .1, -.1]';
    t_max = 20;
    
    iter = 0;
    for std = std_vals
        points_row = zeros(1, samples);
        
        for i = 1:samples
            % --------------- pid
            ctrl1 = PIDController(1000, 10, 100);
            ctrl2 = PIDController(-500, -50, -300);
            ctrl_pid = MultiPIDController(ctrl1, ctrl2, Ts, -Usat, Usat);
                
            % Turns it into a realistic controller (adds noise, packet loss...)
            ctrl = RealisticController(ctrl_pid);
            ctrl.noise_std = .000 * [1 1 1 1];
            ctrl.state_loss_prob = .0;
            ctrl.input_loss_prob = 0;
            
            ctrl.RefFunc = @(t) [
                zeros(size(t)); %square(pi / 4 * t);
                zeros(size(t)); %poly_f(derivative_sq, t); 
                zeros(size(t)); 
                zeros(size(t))];
    
            ctrl.noise_std = std * [1 1 1 1];
            if (std < 0.002 && i >= 2)
                points_row(i) = points_row(i-1);
                continue
            end
            recdata = solve_invpen(x0, ctrl, t_max); 
            %plot_data;
            %animation_viewer(recdata);
            %close all;
    
           % linear regression
            [A, B] = ident_lr(recdata.states, recdata.inputs);
        
            Y_test = recdata.states(2:end, :); % elimina la prima riga (porta Y avanti nel tempo di un iterazione)
            X_test = [recdata.states recdata.inputs];    % concatena gli inputs allo stato per creare l'intera matrice X
            X_test = X_test(1:end-1, :); % elimina l'ultima riga di X per fargli avere le stesse righe di Y
    
            M_hat = [A'; B']; % rebuild M hat
    
            Y_pred = X_test * M_hat;
            err = Y_test - Y_pred;
            
            rmse_value = sqrt(mean((Y_test - Y_pred).^2, 'all'));
            disp(rmse_value)
            points_row(i) = rmse_value;

        end
        iter = iter + 1;
        points(iter, :) = points_row;
    end

end



% ================ Generate smooth square wave reference signal of amplitude 1
T = 5; % period
k = 20; % the lower the smoother
A = .15; % amplitude
smooth_wave = @(t) A * tanh(k * sin(2*pi*(t-T/4)/T)) + A;


% Generates reference signal by combining square waves
poly_f = @(f, t) f(t) + f(t * 2.15) * 0.4 + 0.1 *f(t * 5) + f(t * 0.5);

std_vals = 0:.0001:.003;
points = get_points(std_vals, 15, poly_f);

mean_values = mean(points, 2);

%% plot
figure;
hold on; % Hold on to plot multiple points
for row = 1:size(points, 1)
    p = plot(std_vals(row) * ones(size(points, 2), 1)', points(row, :), 'x', 'Color','r', 'LineWidth',1); % Plot each column
end
h = plot(std_vals, mean_values,'-',  'Color', [1 0.5 0], 'LineWidth', 2);


% Automatically place the legend at the best location
legend([p, h], {'Individual simulations', 'Mean trend'}, 'Location', 'best');
hold off; % Release the hold
xlabel('Standard Deviation Values (σ)');
ylabel('RMSE on train dataset');
title('RMSE of Linear Regression vs noise std Plot');
grid on; % Add grid for better visualizationzxc