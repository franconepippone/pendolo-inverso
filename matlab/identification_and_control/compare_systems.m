%% This script compares the closed loop response of the linear [A, B] system
% againts the closed loop response of the non-linear system.
% Ideally, we would like the two outputs to be similar, indicating that
% the identified system, when close to the linearization point, matches the 
% real system and the system can therefore be arbitrarily controlled.

% We assume that:
%   A, B, and K are known
%   TIMESTEP is also known

Ts = TIMESTEP;                  % controller loop time
x0 = [ .2;    -.2;   .1;   -.2];  % initial cond [x, x_dot, theta, theta_dot]
t_max = 5;                      % simulation timespan

%% Simulation of the LINEAR A, B system
sys_cl = ss(A - B*K, zeros(4, 0), eye(4), 0, Ts);

[~, tOut, statesOut] = initial(sys_cl, x0, 0:Ts:t_max);
% sets up a recdata object so that plot_data can display it
recdata.states = statesOut;
recdata.inputs = (- K * statesOut')';
recdata.t = tOut;
recdata.reference = zeros(size(tOut));
recdata.info.title = "Linear A, B system";

plot_data
recdata_lin = recdata; % backup of this data

%% Simulation of the real system
% Create controller
Usat = 25;            % input saturation value

% SF
ctrl = SFController(K, Ts, -Usat, Usat);
ctrl.RefFunc = @(t) 0; % brings state to 0

recdata = solve_invpen(x0, ctrl, t_max);
recdata.info.title = "Non-linear system";

plot_data
recdata_real = recdata; % backup of this data

%% Plotting state difference (error) between the two systems
recdata.states = recdata_lin.states - recdata_real.states; % subtract states of ln sys to states of nonln sys
recdata.inputs = recdata_lin.inputs - recdata_real.inputs; % same thing for inputs
recdata.info.title = "Error between systems";

plot_data

%% Animation (optional)
recdata = recdata_real;
animation_viewer(recdata)