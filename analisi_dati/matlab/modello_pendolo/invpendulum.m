function dy = invpendulum(t, y, params)
    % Unpack parameters
    M       = params.M;          % cart mass
    m       = params.m;          % pendulum mass
    l       = params.l;          % pendulum length
    b  = params.b;          % cart viscous friction
    c = params.c;          % pivot viscous friction
    g       = params.g;          % gravity
    
    % State variables
    x      = y(1);
    x_dot  = y(2);
    theta  = y(3);
    th_dot = y(4);
    
    % Control and Cart Friction
    % you feed the controller the pendulum error (theta - pi) and time
    F      = params.controller.step(theta - pi, t);
    Ffric  = -b * x_dot;      
    
    % Pivot Friction Torque
    Tpiv   = c * th_dot;
    
    % Precompute geometry
    sinT = sin(theta);
    cosT = cos(theta);
    I    = (1/3)*m*l^2;             % rod inertia about pivot
    J    = I + m*l^2;               % shorthand for equations
    D    = (M + m)*J - (m*l*cosT)^2;
    
    % Equations of Motion
    % Cart acceleration:
    %   ddx = [ J*(F + Ffric + m l sinθ tḣ²) + m l cosθ * (m g l sinθ + pivot friction torque) ] / D
    ddx = ( ...
      J*(F + Ffric + m*l*sinT*th_dot^2) ...
    + m*l*cosT*(m*g*l*sinT + Tpiv) ...
    ) / D;
    
    % Pendulum angular acceleration:
    %   ddth = [ -(M+m)*(m g l sinθ + Tpiv) - m l cosθ*(F + Ffric + m l sinθ tḣ²) ] / D
    ddth = ( ...
      -(M + m)*(m*g*l*sinT + Tpiv) ...
    - m*l*cosT*(F + Ffric + m*l*sinT*th_dot^2) ...
    ) / D;
    
    % Return derivative
    dy = [ x_dot;
         ddx;
         th_dot;
         ddth ];
end