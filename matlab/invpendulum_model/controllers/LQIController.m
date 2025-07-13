classdef LQIController < DiscreteTimeController
    
    properties
        Kstate        % state gain matrix
        itg1 Integrator
        itg2 Integrator
        prev_y
    end
    
    methods
        function obj = LQIController(Kstate, Kitg1, Kitg2, Ts, uMin, uMax)
            obj@DiscreteTimeController(Ts, uMin, uMax);
            obj.Kstate = Kstate;
            obj.itg1 = Integrator(Kitg1);
            obj.itg2 = Integrator(Kitg2);
        end
        
        function u = control_law(obj, y_ref, y, t)
            isAllZero = all(y(:) == 0);
            if isAllZero
                if isnan(obj.prev_y)
                    obj.prev_y = zeros(size(y));
                end
                % y(1) = obj.prev_y(1) + obj.prev_y(2) * obj.Ts;
                % y(3) = obj.prev_y(3) + obj.prev_y(4) * obj.Ts;
                % y(2) = obj.prev_y(2) * obj.sigma;
                % y(4) = obj.prev_y(4) * obj.sigma;
                y = obj.prev_y * obj.sigma;
            end

            r = y_ref(1);
            err = y(1) - r;
            u = - obj.itg1.getValue() - obj.Kstate * (y);

            obj.itg1.integrateDiscrete(err);
            obj.itg2.integrateDiscrete(obj.itg1.val);   


            obj.prev_y = y;
        end

    end
end