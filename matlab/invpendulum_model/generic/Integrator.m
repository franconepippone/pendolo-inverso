classdef Integrator < handle
    %INTEGRATOR Summary of this class goes here
    %   Detailed explanation goes here

    properties
        scale double % scalar
        val double % stored value
        last_t = 0;
    end

    methods
        function obj = Integrator(scale)
            %INTEGRATOR Construct an instance of this class
            %   Detailed explanation goes here
            obj.scale = scale;
            obj.val = 0;
        end

        function integrate(obj, x, t)
            dt = t - obj.last_t;
            obj.val = obj.val + x*dt;
            obj.last_t = t; % Update last_t for the next integration step
        end

        function integrateDiscrete(obj, x)
            % just adds the value to the integral
            obj.val = obj.val + x;
        end

        function val = getValue(obj)
            val = obj.val * obj.scale;
        end

    end
end