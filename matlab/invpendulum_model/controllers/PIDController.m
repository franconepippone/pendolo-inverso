classdef PIDController < handle
    % PIDController with discrete-time update
    
    properties
        Kp = 0       % proportional gain
        Ki = 0       % integral gain
        Kd = 0       % derivative gain
        
        % internal states
        intError = 0     % accumulated integral of error
        prevError = nan    % error at last update
        prevExcTime = -1000 % last time the controller was executed
        
        prevDerError = nan % use to correct jumps in derivative

        state_log = [0, 0]; % logs state
    end
    
    methods
        function obj = PIDController(Kp, Ki, Kd)
            obj.Kp = Kp;  obj.Ki = Ki;  obj.Kd = Kd;
            obj.reset();
        end
        
        function u = control(obj, err, t)
            if (t >= (6000 * 0.005) && obj.Kp == -400)
                t / 0.005;
                t;
            end
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
            derError = (error - obj.prevError) * 200; %NB HARD CODED 200
  
            % logs
            obj.state_log = [obj.state_log; error, derError];

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