classdef StateFeedbackController < handle
    % PIDController with discrete-time update (zero-order hold)
    
    properties
        K        % state gain matrix
        Ts       % sample time (sec)
        uMin     % min output
        uMax     % max output

        % logging of inputs
        execTimes = [0];
        u = [0];
        
        % internal states
        prevU = 0       % last output value (zero-order hold)
        nextSampleT = 0  % next time at which to update

        RefFunc = @(t) 0;
    end
    
    methods
        function obj = StateFeedbackController(K, Ts, uMin, uMax)
            obj.K = K;
            obj.Ts = Ts;
            %prevExcTime = -Ts; % prevents initial dt to be zero
            if nargin>=2
                obj.uMin = uMin;  obj.uMax = uMax;
            else
                obj.uMin = -1000000;  obj.uMax = 1000000;
            end
        end
        
        function u = step(obj, y, t)
            % y is the state vector
            % Only update at t >= nextSampleT
            if t > obj.nextSampleT
                % Compute error
                ref   = obj.RefFunc(t);
                error = ref - y;
                
                % SF law
                uraw = obj.K * error;
                
                % Saturate
                uraw = min(max(uraw, obj.uMin), obj.uMax);
                
                % Save for hold
                obj.prevU       = uraw;
                obj.nextSampleT = obj.nextSampleT + obj.Ts;
                
                % stores results
                obj.execTimes(end + 1) = t;
                obj.u(end + 1) = uraw;
            end
            
            % Return held value
            u = obj.prevU;
       
        end

        function [t, u] = getInputPlot(obj)
            u = obj.u;  % returns the output for logging
            t = obj.execTimes;  % returns execution times for logging
        end

    end
end