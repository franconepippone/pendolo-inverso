classdef SFController < DiscreteTimeController
    % PIDController with discrete-time update (zero-order hold)
    
    properties
        K        % state gain matrix
        prev_y = nan   % previous state (used for packet loss correction)
        sigma = .9999;
    end
    
    methods
        function obj = SFController(K, Ts, uMin, uMax)
            obj@DiscreteTimeController(Ts, uMin, uMax);
            obj.K = K;
        end
        
        function u = control_law(obj, y_ref, y, t)
            % if outside linearity
            if (abs(y(3)) > 0.262)
                u = 0;
                return
            end

            isAllZero = all(y(:) == 0);
            if isAllZero
                if isnan(obj.prev_y)
                    obj.prev_y = zeros(size(y));
                end
                % y(1) = obj.prev_y(1) + obj.prev_y(2) * obj.Ts;
                % y(3) = obj.prev_y(3) + obj.prev_y(4) * obj.Ts;
                % y(2) = obj.prev_y(2) * obj.sigma;
                % y(4) = obj.prev_y(4) * obj.sigma;
                y = obj.prev_y * obj.sigma;
            end
            u = obj.K * (y_ref - y);
            obj.prev_y = y;
        end

    end
end