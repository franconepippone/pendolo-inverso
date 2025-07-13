classdef (Abstract) DiscreteTimeController < BaseController
    % Abstract class for all DT controllers
    
    properties
        % saturation margins
        uMin = -1000000    % min output
        uMax = 1000000    % max output
        Ts = 1       % update period

        % logging of inputs
        execTimes = [];
        u = [];
        
        % internal states
        prevU = 0       % last output value (zero-order hold)
        nextSampleT = 0  % next time at which to update
        hasJustStepped = false

        RefFunc = @(t) 0;

        %packet losses
        p_input_loss = 0;
        alpha = .5; % decay rate
    end
    
    methods (Abstract)
        % this is the specific controller control law
        u = control_law(obj, y_ref, y, t)
    end

    methods
        function obj = DiscreteTimeController(Ts, uMin, uMax)
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
            obj.hasJustStepped = false;

            % Only update at t >= nextSampleT
            if t >= obj.nextSampleT
                obj.hasJustStepped = true; % true only if step occurred
                % get reference
                ref   = obj.RefFunc(t);
                
                % law
                uraw = obj.control_law(ref, y, t);
                
                % Saturate
                uraw = min(max(uraw, obj.uMin), obj.uMax);

                gamma = (rand() > obj.p_input_loss);
                uraw = (gamma)* uraw + obj.prevU * (1-gamma) * obj.alpha; % last at .5

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