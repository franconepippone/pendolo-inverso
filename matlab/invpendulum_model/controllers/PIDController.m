classdef PIDController < handle
    % PIDController with discrete-time update
    
    properties
        Kp = 0       % proportional gain
        Ki = 0       % integral gain
        Kd = 0       % derivative gain
        
        % internal states
        intError = 0     % accumulated integral of error
        prevError = nan    % error at last update
        prevExcTime = 0 % last time the controller was executed
    end
    
    methods
        function obj = PIDController(Kp, Ki, Kd)
            obj.Kp = Kp;  obj.Ki = Ki;  obj.Kd = Kd;
            obj.reset();
        end
        
        function u = control(obj, err, t)
            % Only update at t >= nextSampleT
            dt = t - obj.prevExcTime;
            obj.prevExcTime = t;

            error = err;
            
            % Integrate (simple Euler)
            obj.intError = obj.intError + error * dt;
            
            % Derivative (use error difference from last sample)
            if isnan(obj.prevError)
                obj.prevError = error;
            end
            derError = (error - obj.prevError) / dt;

            % Save for next iteration
            obj.prevError   = error;

            % PID law
            u = obj.Kp*error ...
                 + obj.Ki*obj.intError ...
                 + obj.Kd*derError;
        end
        
        function reset(obj)
            obj.intError     = 0;
            obj.prevError    = nan;
        end
    end
end