classdef MultiPIDController < BaseController
    % PIDController with discrete-time update (zero-order hold)
    
    properties
        pid1       % angle pid
        pid2      % cart pid
    end
    
    methods
        function obj = MultiPIDController(pid1, pid2, Ts, uMin, uMax)
            obj@BaseController(Ts, uMin, uMax)
            % binds the two internal pid controllers
            obj.pid1 = pid1;
            obj.pid2 = pid2;
            
        end
        
        function u = control_law(obj, y_ref, y, t)
            y = (y_ref - y);
            err1 = y(3); % extract theta
            err2 = y(1); % extract x
            u1 = obj.pid1.control(err1, t);
            u2 = obj.pid2.control(err2, t);
            u = u1 + u2;
        end
    end
end
