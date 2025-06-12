classdef PIDController < handle
    % PIDController with discrete-time update (zero-order hold)
    
    properties
        Kp       % proportional gain
        Ki       % integral gain
        Kd       % derivative gain
        Ts       % sample time (sec)
        uMin     % min output
        uMax     % max output

        % logging of inputs
        execTimes = [0];
        u = [0];
        
        % internal states
        intError     % accumulated integral of error
        prevError    % error at last update
        prevU        % last output value (zero-order hold)
        nextSampleT  % next time at which to update
        prevExcTime = 0 % last exact time the controller was executed
    end
    
    methods
        function obj = PIDController(Kp, Ki, Kd, Ts, uMin, uMax)
            obj.Kp = Kp;  obj.Ki = Ki;  obj.Kd = Kd;
            obj.Ts = Ts;
            %prevExcTime = -Ts; % prevents initial dt to be zero
            if nargin>=5
                obj.uMin = uMin;  obj.uMax = uMax;
            else
                obj.uMin = -1000000;  obj.uMax = 1000000;
            end
            obj.reset();
        end
        
        function u = step(obj, y, t)
            % Only update at t >= nextSampleT
            if t > obj.nextSampleT
                dt = t - obj.prevExcTime;
                obj.prevExcTime = t;

                % Compute error
                ref   = obj.getReference(t);
                error = ref - y;
                
                % Integrate (simple Euler)
                obj.intError = obj.intError + error * dt;
                
                % Derivative (use error difference from last sample)
                if isnan(obj.prevError)
                    obj.prevError = error;
                end
                derError = (error - obj.prevError) / dt;
                
                % PID law
                uraw = obj.Kp*error ...
                     + obj.Ki*obj.intError ...
                     + obj.Kd*derError;
                
                % Saturate
                uraw = min(max(uraw, obj.uMin), obj.uMax);
                
                % Anti‑windup: if saturated, undo that last integration step
                if uraw == obj.uMin || uraw == obj.uMax
                    obj.intError = obj.intError - error * obj.Ts;
                end
                
                % Save for hold
                obj.prevError   = error;
                obj.prevU       = uraw;
                obj.nextSampleT = obj.nextSampleT + obj.Ts;

                % stores results
                obj.execTimes(end + 1) = t;
                obj.u(end + 1) = obj.prevU;
            end
            
            % Return held value
            u = obj.prevU;
        end
        
        function reset(obj)
            obj.intError     = 0;
            obj.prevError    = nan;
            obj.prevU        = 0;
            obj.nextSampleT  = 0;  % so first call at t>=0 updates
        end
        
        function ref = getReference(~, t)
            % zero reference by default; override in subclass
            ref = 0;
        end

        function [t, u] = getInputPlot(obj)
            u = obj.u;  % returns the output for logging
            t = obj.execTimes;  % returns execution times for logging
        end
    end
end