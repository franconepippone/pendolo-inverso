classdef (Abstract) BaseController < handle
    % Abstract class for all controllers
    properties (Abstract)
        RefFunc     % reference function for the controller i.e.: @(t) 0;
    end

    methods (Abstract)
        u = step(obj, y, t) % step the controller, returns input

        [t, u] = getInputPlot(obj) % returns given inputs
    end
end