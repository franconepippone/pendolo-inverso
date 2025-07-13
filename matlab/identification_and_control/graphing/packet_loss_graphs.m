close all
%clear
clc
format short

%% Simulazione

function [points, succ_rate] = get_points_ploss(p_loss_vals, samples, ref_func, alpha)
    
    
    fprintf('Simulation started with alpha = %.1f\n', alpha);

    points = zeros(length(p_loss_vals), samples);
    succ_rate = zeros(length(p_loss_vals), 1);

    Ts = 0.005;
    Usat = 25;
    
    
    %% Simulate
    % Initial conditions: [x0; xdot0; theta0; thetadot0]
    x0 = [0, .2, .1, -.1]';
    t_max = 20;
    
    iter = 0;
    ITER_MAX = length(p_loss_vals);
    for p_loss = p_loss_vals
        points_row = zeros(1, samples);
        fail_count = 0;
        for i = 1:samples
            % --------------- pid
            Ke = [-1092.9579, -315.95446, 638.34815, 98.460198, -8.8319058];
            Kx = Ke(1:4);
            Ki = Ke(5);
            ctrl_imd = LQIController(Kx, Ki, 0, Ts, -Usat, Usat); 

            % Turns it into a realistic controller (adds noise, packet loss...)
            ctrl = RealisticController(ctrl_imd);
            ctrl.noise_std = .0003 * [1 1 1 1];
            ctrl.state_loss_prob = 0;
            ctrl_imd.p_input_loss = p_loss; % NB accessing original object, this needs to be reworked
            ctrl_imd.alpha = alpha;
            
            ctrl.RefFunc = @(t) [
                ref_func(t); %square(pi / 4 * t);
                zeros(size(t)); %poly_f(derivative_sq, t); 
                zeros(size(t)); 
                zeros(size(t))];
    
            % if (std < 0.002 && i >= 2)
            %     points_row(i) = points_row(i-1);
            %     continue
            % end
            recdata = solve_invpen(x0, ctrl, t_max); 
            % plot_data;
            % animation_viewer(recdata);
            % close all;

            % if has fallen, increment
            fail_count = fail_count + any(abs(recdata.states(:, 3)) > 0.8);
    
           % computing cost
            %disp("Tracking cost:");
            cost = sum(abs(recdata.states(:, 1) - recdata.reference(1, :)'));
            %disp(cost)
            %disp(p_loss)
            %disp(fail_count)

            points_row(i) = cost;
            
            % Log progress
            fprintf('\rIteration: %d/%d, Sample: %d/%d for alpha= %.1f', iter, ITER_MAX, i, samples, alpha);
        end
        iter = iter + 1;
        points(iter, :) = points_row;
        succ_rate(iter) = (samples - fail_count) / samples * 100; %gives %
    end

end



% ================ Generate smooth square wave reference signal of amplitude 1
T = 5; % period
k = 20; % the lower the smoother
A = .15; % amplitude
smooth_wave = @(t) A * tanh(k * sin(2*pi*(t-T/4)/T)) + A;


% Generates reference signal by combining square waves
poly_f = @(f, t) f(t);

p_loss_vals = 0:.03:.8;

% --------------- GENERATE P% POINTS
n = 100;                     % total number of points
p = linspace(0, 1, n);       % uniform quantile values

mu = 0.63;                    % center around 70
sigma = 0.3;                 % tighter = more clustering near center

x = norminv(p, mu, sigma);   % inverse normal CDF (quantile function)

% Clip values to [0, 1]
x(x < 0) = 0;
x(x > 1) = 1;

% Ensure exact start and end points
x(1) = 0;
x(end) = 1;
% ----- CHOOSES 
p_loss_vals = x;

figure
plot(x, x, '-o');

SAMPLES = 30;
alpha_values = [0.3, 0.2, 0.1]; % Example alpha values for the loop

for alpha = alpha_values
    [points, succ_rates] = get_points_ploss(p_loss_vals, SAMPLES, smooth_wave, alpha);
    fprintf("Processing alpha %.1f", alpha);

    filename = sprintf('a_%.1f_%d_%d_around_%.2f.mat', alpha, n, SAMPLES, mu);
    save(fullfile("identification_and_control", "graphing", "succ_rates", filename), "succ_rates", "points", "alpha", "mu", "p_loss_vals");
end


%% plot
mean_values = median(points, 2);

figure;
hold on; % Hold on to plot multiple points
for row = 1:size(points, 1)
    p = plot(100*p_loss_vals(row) * ones(size(points, 2), 1)', points(row, :), 'x', 'Color','r', 'LineWidth',1); % Plot each column
end
h = plot(100*p_loss_vals, mean_values,'-',  'Color', [1 0.5 0], 'LineWidth', 2);

% for row = 1:size(HD_points, 1)
%     p = plot(100*HD_p_loss_vals(row) * ones(size(HD_points, 2), 1)', HD_points(row, :), 'x', 'Color','r', 'LineWidth',1); % Plot each column
% end
% h = plot(100*HD_p_loss_vals, median(HD_points, 2),'-',  'Color', [1 0.5 0], 'LineWidth', 2);


% Automatically place the legend at the best location
legend([p, h], {'Individual simulations', 'Median trend'}, 'Location', 'best');
hold off; % Release the hold
xlabel('Packet loss probability (%)');
ylabel('Tracking cost');
title('Tracking cost vs packet loss chance Plot');
grid on; % Add grid for better visualizationzxc
ylim([298.2, 299]);

%% plot success rate
figure
plot(p_loss_vals * 100, succ_rates)
ylim([-5, 105]);
xlim([40, 70]);
grid on;
xlabel('Packet loss probability (%)');
ylabel('Stabilization success rate (%)');
title('Success rate of stabilization vs packet loss chance Plot')
% Add a dotted line at y = 50
yline(50, 'k--', 'success% = 50', 'LabelHorizontalAlignment', 'left', 'LabelVerticalAlignment', 'bottom');