classdef DoublePIDController < handle
    % PIDController with discrete-time update (zero-order hold)
    
    properties
        pid1       % angle pid
        pid2      % cart pid

        uMin     % min output
        uMax     % max output
           
        % logging of inputs
        execTimes = [0];
        u = [0];

        % x reference
        RefFunc = @(t) 0; % for x = 0 tracking
    end
    
    methods
        function obj = DoublePIDController(pid1, pid2, uMin, uMax)
            % binds the two internal pid controllers
            obj.pid1 = pid1;
            obj.pid2 = pid2;
            if nargin>=3
                obj.uMin = uMin;  obj.uMax = uMax;
            else
                obj.uMin = -Inf;  obj.uMax = Inf;
            end
        end
        
        function u = step(obj, y, t)
            theta = y(3);
            x = y(1);

            % calls internal pids step functions
            u1 = obj.pid1.step(theta, t);  % Step for angle PID
            u2 = obj.pid2.step(obj.RefFunc(t) - x, t);  % Step for cart PID
            uraw = u1 + u2;  % Combine outputs from both PID controllers
            
            % apply saturation
            u = min(max(uraw, obj.uMin), obj.uMax);

            % stores results
            if abs(obj.execTimes(end) - t) > 0.0001
                obj.execTimes(end + 1) = t;
                obj.u(end + 1) = u;
            end
        end

        function [t, u] = getInputPlot(obj)
            [t_1, u_1] = obj.pid1.getInputPlot();
            [~, u_2] = obj.pid1.getInputPlot();
            
            u = u_1 + u_2;
            u = min(max(u, obj.uMin), obj.uMax);
            t = t_1;
        end
    end
end
