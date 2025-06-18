classdef RealisticController < BaseController
    % REALISTICCONTROLLER is a wrapper to a base controller
    %   Turns the wrapped controller into a real controller, by adding
    %   configurable amount of noise, packet losses, delays etc...

    properties
        controller          % any controller iheriting from BaseController
        RefFunc = @(t) 0;
        Ts = -1;            % -1 if wrapping a continuous controller
        noise_var           % variance of gaussian noise on input state
        state_loss_prob = 0       % probabilty of a state packet loss
        input_loss_prob = 0       % probabilty of a input packet loss
    end

    methods
        function obj = RealisticController(wrapped_controller)
            obj.controller = wrapped_controller;
            if isprop(wrapped_controller, 'Ts')
                % in case of discrete time controller
                obj.Ts = wrapped_controller.Ts;
            end
        end
           
        function set.RefFunc(obj, func)
            % sets own reference as well as wrapped controller reference
            obj.RefFunc = func;
            obj.controller.RefFunc = func;
        end


        function u = step(obj, y, t)
            
            % Y (STATE VECTOR) CHANNEL
            y_noisy = y + randn(size(y)) .* obj.noise_var'; % adds gaussian noise
            
            % y is dropped with probability
            y_loss = (rand() > obj.state_loss_prob) * y_noisy;

            u_raw = obj.controller.step(y_loss, t);  % step the underlying controller

            % U CHANNEL
            u_raw = u_raw * (rand() > obj.input_loss_prob);
            u = u_raw;
        end

        function [t, u] = getInputPlot(obj)
            [t, u] = obj.controller.getInputPlot();
        end
    end
end