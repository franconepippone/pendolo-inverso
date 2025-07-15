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
        tic
        parfor i = 1:samples
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
            fprintf('\rIteration: %d/%d, Sample: %d/%d for alpha= %.2f', iter, ITER_MAX, i, samples, alpha);
        end
        toc
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

% --------------- GENERATE P% POINTS1
n = 40;                     % total number of points
p = linspace(0, 1, n);       % uniform quantile values

mu = 0.75;                    % center around 70
sigma = 0.05;                 % tighter = more clustering near center

x = norminv(p, mu, sigma);   % inverse normal CDF (quantile function)

% Clip values to [0, 1]
x(x < 0) = 0;
x(x > 1) = 1;

% Ensure exact start and end points
x(1) = 0;
x(end) = 1;

x_75 = x;

% --------------- GENERATE P% POINTS2
n = 50;                     % total number of points
p = linspace(0, 1, n);       % uniform quantile values

mu = 0.55;                    % center around 70
sigma = 0.05;                 % tighter = more clustering near center

x = norminv(p, mu, sigma);   % inverse normal CDF (quantile function)

% Clip values to [0, 1]
x(x < 0) = 0;
x(x > 1) = 1;

% Ensure exact start and end points
x(1) = 0;
x(end) = 1;

x_55 = x;
% ----- CHOOSES 
p_loss_vals = x_75;

figure
plot(x, x, '-o');

SAMPLES = 100;
alpha_values = [1, 0]; % Example alpha values for the loop

idx = 0;
for alpha = alpha_values
    idx = idx +1;
    if idx == 2
        p_loss_vals = x_55;
    end
    fprintf("Using %d", idx);
    [points, succ_rates] = get_points_ploss(p_loss_vals, SAMPLES, smooth_wave, alpha);
    fprintf("Processing alpha %.2f", alpha);

    filename = sprintf('a_%.2f_%d_%d_around_%.2f.mat', alpha, n, SAMPLES, mu);
    save(fullfile("identification_and_control", "graphing", "succ_rates", filename), "succ_rates", "points", "alpha", "mu", "p_loss_vals");
end


%% plot cost (normal and boxplot)
load("identification_and_control\graphing\succ_rates\a_1.0_100_30_around_0.63.mat")
mean_values = median(points, 2);

figure;
hold on; % Hold on to plot multiple points
% for row = 1:size(points, 1)
% 
%     % Set transparency for the plot
% 
%     p = plot(100*p_loss_vals(row) * ones(size(points, 2), 1)', points(row, :), 'x', 'Color','r', 'LineWidth',1); % Plot each column
% 
% end

ORANGE = [1 0.5 0];
BLUE = [0.000, 0.447, 0.741];
GREEN = [0.467, 0.675, 0.188];

for i = 1:length(p_loss_vals)
    % x = a 1×30 vector all equal to p_loss_vals(i)
    x = repmat(p_loss_vals(i) * 100, 1, size(points,2));
    y = points(i,:);           % the 30 Y‑values in row i
    p = scatter(x, y, 60, BLUE, 'x', ...      % 36 is the marker size
        'MarkerFaceAlpha', 0.3, ...           % 30% opaque faces
        'MarkerEdgeAlpha', 0.4);
end
ylim([298.2, 299]);
h = plot(100*p_loss_vals, mean_values,'-',  'Color', BLUE, 'LineWidth', 2);
p = scatter(-2, -2, 40, BLUE, 'x');
% Automatically place the legend at the best location
legend([p, h], {'Individual simulations', 'Median trend'}, 'Location', 'best');
hold off; % Release the hold
xlabel('Packet loss probability (%)');
ylabel('Tracking cost');
title('Tracking cost vs packet loss chance Plot');
grid on; % Add grid for better visualizationzxc
ylim([298.2, 299]);

% Create boxplot with x-axis scale defined by p_loss_vals and y-values from points
figure;
boxplot(points', 'Widths', 0.5);
xlabel('Packet loss probability (%)');
ylabel('Tracking cost');
title('Boxplot of Tracking Cost vs Packet Loss Probability');
grid on; % Add grid for better visualization

%% plot success rate
figure
hold on;
plot(p_loss_vals * 100, succ_rates, 'LineWidth', 1.5)
ylim([-5, 105]);
xlim([0, 100]);
grid on;
xlabel('Packet loss probability (%)');
ylabel('Stabilization success rate (%)');
title('Success rate of stabilization vs packet loss chance Plot')
% Add a dotted line at y = 50
yline(50, 'k--', 'success% = 50', 'LabelHorizontalAlignment', 'left', 'LabelVerticalAlignment', 'bottom');

%% plot different success rates
figure;
hold on;
grid on;
xlabel('Packet loss probability (%)');
ylabel('Stabilization success rate (%)');
title('Success rate of stabilization vs packet loss chance Plot')
% Add a dotted line at y = 50
yline(50, 'k--', 'success% = 50', 'LabelHorizontalAlignment', 'left', 'LabelVerticalAlignment', 'bottom');


files = [
    "identification_and_control\graphing\succ_rates\a_1.0_100_30_around_0.63.mat";
    "identification_and_control\graphing\succ_rates\a_0.95_50_30_around_0.80.mat";
    "identification_and_control\graphing\succ_rates\a_0.9_100_30_around_0.63.mat";
    "identification_and_control\graphing\succ_rates\a_0.8_100_30_around_0.63.mat";
    "identification_and_control\graphing\succ_rates\a_06_40_18_around_75.mat";
    "identification_and_control\graphing\succ_rates\a_0.4_100_30_around_0.63.mat";
    "identification_and_control\graphing\succ_rates\a_0.2_100_30_around_0.63.mat";
    "identification_and_control\graphing\succ_rates\a_0.1_100_30_around_0.63.mat";
    "identification_and_control\graphing\succ_rates\a_0.0_100_30_around_0.63.mat"
];

alphas = [1.0, 0.95, 0.9, 0.8, 0.6, 0.4, 0.2, 0.1, 0];

plots = zeros(length(files), 1);
failure_points = zeros(9, 2);

for i = 1:length(files)
    load(files(i));
    style = '-';
    if i == 1 || i == 9
        style = '--';
    end
    p = plot(p_loss_vals * 100, succ_rates, style);
    idx = find(succ_rates < 100, 1);
    failure_points(i, :) = [alphas(i), p_loss_vals(idx) * 100];
    plots(i) = p;
end


legend(plots, { ...
    'alpha = 1.0 (ZOH)', ...
    'alpha = 0.95', 'alpha = 0.9', ...
    'alpha = 0.8', 'alpha=0.6', 'alpha = 0.4', 'alpha = 0.2', 'alpha = 0.1', 'alpha = 0'}, 'Location', 'best');

ylim([-1, 101]);

figure;
plot(failure_points(:, 1), failure_points(:, 2), 'LineWidth',2);
hold on;
plot([0, 0.95, 0.95], [73.0291, 73.0291, 0], '--', 'Color', [0,0,0])
grid on;
xlabel('Decay factor alpha');
ylabel('No-fail packet drop probabilty threshold (%)');
title('Stabilization no‑fail threshold vs alpha Plot')

xlim([0, 1])
ylim([20, 90]);

%% plot of different cost

files = [
    "identification_and_control\graphing\succ_rates\a_1.0_100_30_around_0.63.mat";
    "identification_and_control\graphing\succ_rates\a_0.95_40_18_around_0.70.mat";
    "identification_and_control\graphing\succ_rates\a_0.9_40_8_around_0.40.mat";
    "identification_and_control\graphing\succ_rates\a_0.8_100_30_around_0.63.mat";
    "identification_and_control\graphing\succ_rates\a_0.6_40_8_around_0.40.mat";
    "identification_and_control\graphing\succ_rates\a_0.4_100_30_around_0.63.mat";
    "identification_and_control\graphing\succ_rates\a_0.2_100_30_around_0.63.mat";
    "identification_and_control\graphing\succ_rates\a_0.1_100_30_around_0.63.mat";
    "identification_and_control\graphing\succ_rates\a_0.0_100_30_around_0.63.mat"
];

figure;

plots = zeros(length(files), 1);

for i = 1:length(files)
    load(files(i));
    style = '-';
    if i == 1 || i == 9
        style = '--';
    end
    mean_values = median(points, 2);
    p = plot(100*p_loss_vals, mean_values,style, 'LineWidth', 1); hold on;
    plots(i) = p;
end


% Automatically place the legend at the best location
legend(plots, { ...
    'alpha = 1.0 (ZOH)', ...
    'alpha = 0.95', 'alpha = 0.9', ...
    'alpha = 0.8', 'alpha=0.6', 'alpha = 0.4', 'alpha = 0.2', 'alpha = 0.1', 'alpha = 0'}, 'Location', 'best');



grid on; % Add grid for better visualizationzxc
ylim([298.2, 299]);
xlabel('Packet loss probability (%)');
ylabel('Tracking cost');
title('Tracking cost vs packet loss chance Plot for various values of alpha');


