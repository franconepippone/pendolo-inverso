function points = get_points_parallel_rmse(std_vals, ref_func)
    points = zeros(length(std_vals), 1);
    
    Ts = 0.005;
    Usat = 25;
    x0 = [0, .2, .1, -.1]';
    t_max = 40;
    
    parfor iter = 1:length(std_vals)
        try
            std = std_vals(iter);
    
            ctrl1 = PIDController(1000, 10, 100);
            ctrl2 = PIDController(-500, -50, -300);
            ctrl_pid = MultiPIDController(ctrl1, ctrl2, Ts, -Usat, Usat);
    
            ctrl = RealisticController(ctrl_pid);
            ctrl.noise_std = std * [1 1 1 1];
            ctrl.state_loss_prob = 0;
            ctrl.input_loss_prob = 0;
    
            ctrl.RefFunc = @(t) [
                zeros(size(t));
                zeros(size(t));
                zeros(size(t));
                zeros(size(t))];
    
            recdata = solve_invpen(x0, ctrl, t_max);  % <-- likely hangs here
    
            [A, B] = ident_lr(recdata.states, recdata.inputs);
            Y_test = recdata.states(2:end, :);
            X_test = [recdata.states recdata.inputs];
            X_test = X_test(1:end-1, :);
            M_hat = [A'; B'];
            Y_pred = X_test * M_hat;
            rmse_value = sqrt(mean((Y_test - Y_pred).^2, 'all'));
            points(iter) = rmse_value;
    
        catch ME
            fprintf('Iteration %d failed: %s\n', iter, ME.message);
            points(iter) = NaN;
        end
    end

end
