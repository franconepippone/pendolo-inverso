%% Quanser Inverted Rotary Pendulum model
% The script provides the system matrices of rotary inverted pendulum. 
% It requires the Control System Toolbox to be installed.
%
% Outputs:
%   A: the system state matrix;
%   B: the system input matrix;
%   C: the system output matrix;
%   D: the direct transition matrix.

%% 
% The (linearized) discrete-time state-space model is
%   $x_{k+1} = A x_k + B u_k$,
%       $y_k = C x_k + D u_k$,
% where
%   $x_k$ is a system state vector of $n_x$ variables,
%   $u_k$ is a control vector of $n_u$ variables, and
%   $y_k$ is an output vector of $n_y$ variables.

initialization

Ts = 0.05; % sampling time

decimal = 3;%  number of decimal digits for presenting the results
laggingAnalysis = false; % to plot continuous and discrete responses to impulse
consoleMessage = true; % to display continuous-state matrices

%% 
% *SRV02 Configuration:*
%%
% External Gear Configuration: set to |'HIGH'| or |'LOW'|
EXT_GEAR_CONFIG = 'HIGH';
%%
% Encoder Type: set to |'E'| or |'EHR'|
ENCODER_TYPE = 'E';
%%
% Is |SRV02| equipped with a Tachometer? (i.e. option |T|): set to |'YES'|
% or |'NO'|
TACH_OPTION = 'YES';
%%
% Type of Load: set to |'NONE'|, |'DISC'|, or |'BAR'|
LOAD_TYPE = 'NONE';
%%
% Power Amplifier Type: set to |'VoltPAQ'|, |'UPM_1503'|, |'UPM_2405'|, or
% |'Q3'|
AMP_TYPE = 'VoltPAQ';
%%
% *Inverted Pendulum Configuration*
%%
% |ROTPEN| Option: |'ROTPEN'| or |'ROTPEN-E'|
ROTPEN_OPTION = 'ROTPEN-E';
%%
% Define rotary arm attached to |SRV02| load gear.
SRV02_ARM = 'ROTARY_ARM';
%% 
% Length of the pendulum: the 12-inch medium link.
PEND_1_TYPE = 'MEDIUM_12IN';
%%
% Setting model variables according to the user-defined SRV02 configuration
[ Rm, kt, ~, Kg, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~ ] = configSRV02( ...
    EXT_GEAR_CONFIG, ENCODER_TYPE, TACH_OPTION, AMP_TYPE, LOAD_TYPE );
%%
% Load rotary arm parameters
[ ~, ~, Lr, ~, Jr, Dr ] = configSP( SRV02_ARM, ROTPEN_OPTION );
%% 
% Load medium 12-inch pendulum parameters
[ g, Mp, Lp, ~, Jp, Dp ] = configSP( PEND_1_TYPE, ROTPEN_OPTION );
%% Setting Open-loop state-space model of rotary double-inverted pendulum
% Total inertia
Jt = Jr*Jp + Mp*(Lp/2)^2*Jr + Jp*Mp*Lr^2;
%%
% System state matrix for the continuous-time model
cA = [0 0 1 0;
      0 0 0 1;
      0 Mp^2*(Lp/2)^2*Lr*g/Jt ...
          -Dr*(Jp+Mp*(Lp/2)^2)/Jt -Mp*(Lp/2)*Lr*Dp/Jt;
      0 Mp*g*(Lp/2)*(Jr+Mp*Lr^2)/Jt ...
          -Mp*(Lp/2)*Lr*Dr/Jt -Dp*(Jr+Mp*Lr^2)/Jt];
%%
% System input matrix for the continuous-time model
cB = [0; 0; (Jp+Mp*(Lp/2)^2)/Jt; Mp*(Lp/2)*Lr/Jt];
%%
% System output matrix for the continuous-time model
cC = eye(2,4);
%%
% System direct transition matrix for the continuous-time model
cD = zeros(2,1);
%%
% Add actuator dynamics
cB = Kg * kt * cB / Rm;
cA(3,3) = cA(3,3) - Kg^2*kt*kt/Rm*cB(3);
cA(4,3) = cA(4,4) - Kg^2*kt*kt/Rm*cB(4);

if consoleMessage
    fprintf('Continuous-time system matrices:\n\n')
    fprintf('Continuous-time A = \n')
    showMatrix(cA,decimal)
    fprintf('\n')
    fprintf('Continuous-time B = \n')
    showMatrix(cB,decimal)
    fprintf('\n')
    fprintf('Continuous-time C = \n')
    showMatrix(cC,decimal)
    fprintf('\n')
    fprintf('Continuous-time D = \n')
    showMatrix(cD,decimal)
end

%%
% Initial condition used in the state-space model for simulation is the
% point of transition between the swing-up and balancing control, exactly
% x0 = [0; 9.931640625000002; 0; 43.945312500004441] * pi / 180; % approx.
% x0 = [0; 10; 0; 44] * pi / 180; % in radiants
x0 = [0; 0.174; 0; 0.767];
%%
% Creates a continuous-time state-space model via |ss|
sysc = ss(cA,cB,cC,cD);
cI = eye(size(cA));
cO = 0*cB;

%% 
% Convert continuous-time dynamic system to discrete time with sample time Ts
sys = c2d(sysc,Ts);

A = sys.A;
B = sys.B;
C = sys.C;
D = sys.D;

%% Lagging analysis
if laggingAnalysis == 1
    impulse(sysc,3) % plots continuous output response
    hold on
    [x,t]=impulse(sys,3);
    plot(t,x(:,2),'ro') % plots discrete output response
    hold off
    grid on
end

if consoleMessage
    fprintf('\n\n')
    fprintf('Discrete-time system matrices:\n\n')
    fprintf('Discrete-time A = \n')
    showMatrix(A)
    fprintf('\n')
    fprintf('Discrete-time B = \n')
    showMatrix(B)
    fprintf('\n')    
    fprintf('Discrete-time C = \n')
    showMatrix(C)
    fprintf('\n')
    fprintf('Discrete-time D = \n')
    showMatrix(D)
end

%% Controllability test
dCo = ctrb(A,B);
unco = length(A) - rank(dCo);
if unco ~= 0
    error('The described plant is uncontrollable!\n\n')
end

%% LQR design
Q = eye(4); % system state weighting matrix
R = 1; % control input weighting matrix
[K,S,CLP] = lqr(sys,Q,R); % discrete-time LQR

if consoleMessage
    fprintf('\n\n')
    fprintf('Discrete-time LQR gain K:\n')
    showMatrix(K)
end

clear AMP_TYPE Dp Dr ENCODER_TYPE EXT_GEAR_CONFIG Jp Jr Jt Kg ...
    LOAD_TYPE Lp Lr Mp PEND_1_TYPE ROTPEN_OPTION Rm SRV02_ARM ...
    TACH_OPTION consoleMessage decimal g kt laggingAnalysis

%% Acknowledgement
% This function is based on |setup_rotpen.m| function from Quanser Consulting Inc., 
% which sets the necessary parameters to define the rotary inverted pendulum.

%% Reference
% Jacob Apkarian, Paul Karam, and Michel Lévis, "Inverted Pendulum Experiment ...
% for MATLAB®/Simulink® Users", Quanser Inc., 2020.