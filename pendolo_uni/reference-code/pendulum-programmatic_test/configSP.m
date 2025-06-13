function [ g, Mp, Lp, lp, Jp, Bp, RtpnOp, RtpnOff, K_POT_PEN ] = ...
    configSP( PEND_TYPE, ROTPEN_OPTION )
% The function sets the model variables of the Quanser Single Pendulum
% module depending on the length/type specified (e.g., short, medium, long,
% or rotary arm)
% 
% Inputs:
%   PEND_TYPE: Type of pendulum;
%   ROTPEN_OPTION: Either 'ROTPEN' or 'ROTPEN-E'.
% 
% Outputs:
%   g: Gravitational constant [m/s^2];
%   Mp: Pendulum mass with T-fitting [kg];
%   Lp: Full length of the pendulum (with T-fitting) [m];
%   lp: Distance from pivot to centre of gravity [m];
%   Jp: Pendulum moment of inertia [kg.m^2];
%   Bp: Viscous damping coefficient as seen at the pendulum axis [N.m.s/rad];
%   RtpnOp: Used in Simulink model to identify rotpen option:
%           1 for potentiometer, 2 for encoder;
%   RtpnOff: Pendulum offset for starting inverted pendulum [rad];
%   K_POT_PEN: Potentiometer calibration gain for ROTPEN [rad/V].

%%
[ ~, ~, K_IN2M, ~, ~, ~, ~, ~, ~, ~, ~, ~ ] = ...
    calcConversionConstants(); % calculates useful conversion factors
g = 9.81; % Gravity constant
%%
if strcmp( PEND_TYPE, 'LONG_24IN')
    % Pendulum mass (with T-fitting)
    Mp = 0.230; 
    % Pendulum full length (with T-fitting, from axis of rotation to tip)
    Lp = ( 25 + 1 / 4 ) * K_IN2M;  % = 0.6413;
    % Distance from pivot to centre of gravity
    lp = 13 * K_IN2M; % = 0.3302
    % Pendulum moment of inertia [kg.m^2] - approximation
    Jp = Mp * Lp^2 / 12;  % = 7.8838 e-3
    % Equivalent viscous damping coefficient [N.m.s/rad]
    Bp = 0.0024;    
elseif ( strcmp( PEND_TYPE, 'MEDIUM_12IN') )
    % Assumption: 2-DOF Gantry is used with MEDIUM sized pendulum.
    % Pendulum mass (with T-fitting)
    Mp = 0.127;
    % Pendulum full length (with T-fitting, from axis of rotation to tip)
    Lp = ( 13 + 1 / 4 ) * K_IN2M;
    % Distance from pivot to centre of gravity: calculated experimentally
    lp = ( 6 + 1 / 8 ) * K_IN2M;
    % Pendulum moment of inertia [kg.m^2] - approximation
    Jp = Mp * Lp^2 / 12; 
    % Equivalent viscous damping coefficient [N.m.s/rad]
    Bp = 0.0024;
elseif strcmp( PEND_TYPE, 'SHORT_7IN')
    % Pendulum mass (with T-fitting)
    Mp = 0.097;
    % Pendulum full length (with T-fitting, from axis of rotation to tip)
    Lp = (7 + 7 / 8) * K_IN2M;
    % Distance from pivot to centre of gravity: estimated
    lp = (6 + 7 / 16) * K_IN2M ;
    % Pendulum moment of inertia [kg.m^2]
    Jp = Mp * Lp^2 / 12;
    % Equivalent viscous damping coefficient [N.m.s/rad]
    Bp = 0.0024;
elseif strcmp( PEND_TYPE, 'ROTARY_ARM')
    % Arm mass (with two thumb screws)
    Mp = 0.257;
    % Full length of arm (from axis of rotation to tip)
    Lp = 8.5 * K_IN2M; 
    % Distance from pivot to centre of gravity: calculated experimentally
    lp = (2 + 7/16) * K_IN2M;
    % Pendulum moment of inertia [kg.m^2] - approximation
    Jp = Mp * Lp^2 / 12;
    % Equivalent viscous damping coefficient [N.m.s/rad]
    Bp = 0.0024;
else 
    error( 'Error: Set the type of pendulum.' )
end % % end of the IF statement
% Rotary arm or 2-DOF Robot attachment, or 'NONE' for linear pendulum
%%
if strcmp( ROTPEN_OPTION, 'ROTPEN')
    RtpnOp = 1;
    RtpnOff = -2.898/2*0;
elseif strcmp( ROTPEN_OPTION, 'ROTPEN-E')
    RtpnOp = 2;
    RtpnOff = -pi;
elseif strcmp( ROTPEN_OPTION, '2DGANTRY')
    RtpnOp = 1;
    RtpnOff = 0;
elseif strcmp( ROTPEN_OPTION, '2DGANTRY-E')
    RtpnOp = 2;
    RtpnOff = 0;  
elseif strcmp( ROTPEN_OPTION, 'NONE')
    RtpnOp = [];
    RtpnOff = []; 
else
    error('Error: Set the rotary pendulum option correctly.')
end % % end of the IF statement
%%
K_POT_PEN = -(345 * pi / 180 / 24); % ROTPEN calibration gain [rad/V]
