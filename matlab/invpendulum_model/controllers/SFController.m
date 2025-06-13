classdef SFController < BaseController
    % PIDController with discrete-time update (zero-order hold)
    
    properties
        K        % state gain matrix
    end
    
    methods
        function obj = SFController(K, Ts, uMin, uMax)
            obj@BaseController(Ts, uMin, uMax);
            obj.K = K;
        end
        
        function u = control_law(obj, y_ref, y, t)
            u = obj.K * (y_ref - y);
        end

    end
end