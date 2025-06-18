function varargout = solve_invpen(initial_x, controller, max_time, save_to_disk)
    arguments
        initial_x (4,1) double % enforce initial_x to be a 4x1 double matrix
        controller BaseController % enforce controller to be a controller object
        max_time double
        save_to_disk boolean
    end

    %% Setup simulation
    % Define parameters
    params.M   = 1.0;         % cart mass (1kg)
    params.m   = 0.3;         % pendulum mass (0.3kg)
    params.l   = .2;         % pendulum length (20cm)
    params.b   = 1.2;         % cart viscous friction
    params.c   = 0.01;        % pivot friction
    params.g   = 9.81;        % gravity
    params.controller = controller;
    
    % Initial conditions: [x0; xdot0; theta0; thetadot0]
    x0 = initial_x;
    
    % Time span
    tspan = [0, max_time];  % simulate from t=0 to t=10 seconds
    
    %% Simulate
    % Solve
    simTs = 0.001;
    x0_real = x0 + [0; 0; pi; 0]; % brings theta in the simulation frame (0 is downards, pi is upwards)
    [t_sim, X_sim] = rk4_fixed_step(@(t, x) invpendulum(t, x, params), tspan, x0_real, simTs);
    X_sim(:, 3) = X_sim(:, 3) - pi; % sets zero angle to be upwards
    
    % Extract input 
    [t, U] = ctrl.getInputPlot();
    t = floor(t * 1000) / 1000; % truncates up to third decimal digit
    
    % Extracts simulation states at time points matching controller execution times within epsilon tolerance
    epsilon = 1e-6;
    sameIdxs = any(abs(t_sim' - t) < epsilon, 2);
    X = X_sim(sameIdxs, :);
    
    % Extract results
    x      = X(:,1);
    x_dot  = X(:,2);
    theta  = X(:,3);
    th_dot = X(:,4);
    
    % Calculates reference state
    x_ref = ctrl.RefFunc(t);
    
    %% Saves data in a struct
    recdata.states = X;
    recdata.inputs = U';
    recdata.reference = x_ref;
    recdata.t = t;
    
    % saves additional meta data
    recdata.info.sim_timespan = tspan;
    recdata.info.initial_cond = x0;
    recdata.info.sim_params = params;
    recdata.info.controller_ts = Ts;
    recdata.info.simulation_ts = simTs;
    recdata.info.input_saturation = Usat;
    recdata.info.date = datetime;
    recdata.info.notes = SIM_NOTES;

    if nargout == 0
        varargout{1} = x^2; % Return square if one output is expected
    elseif nargout == 2
        varargout{1} = x^2; % First output: square
        varargout{2} = sqrt(x); % Second output: square root
    else
        varargout{1} = 'Invalid number of outputs!';
    end



end 