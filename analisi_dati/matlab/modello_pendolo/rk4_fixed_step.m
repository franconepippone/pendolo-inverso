function [T, Y] = rk4_fixed_step(odefun, tspan, y0, dt)
% Fixed-step Runge-Kutta 4 integrator
%
% Inputs:
%   odefun - function handle: dydt = f(t, y)
%   tspan  - [t0 tf] simulation time span
%   y0     - initial condition vector
%   dt     - fixed time step
%
% Outputs:
%   T - time vector
%   Y - state matrix, each row is y at a time step

    t0 = tspan(1);
    tf = tspan(2);
    T = t0:dt:tf;
    N = numel(T);
    y = y0(:);             % ensure column vector
    Y = zeros(N, length(y));
    Y(1, :) = y';

    for i = 1:N-1
        t = T(i);
        k1 = odefun(t, y);
        k2 = odefun(t + dt/2, y + dt/2 * k1);
        k3 = odefun(t + dt/2, y + dt/2 * k2);
        k4 = odefun(t + dt,   y + dt   * k3);

        y = y + dt/6 * (k1 + 2*k2 + 2*k3 + k4);
        Y(i+1, :) = y';
    end
end
