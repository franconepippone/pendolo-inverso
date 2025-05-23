function [ K_R2D, K_D2R, K_IN2M, K_M2IN, K_RDPS2RPM, K_RPM2RDPS, ...
    K_OZ2N, K_N2OZ, K_LBS2N, K_N2LBS, K_G2MS, K_MS2G ] = ...
    calcConversionConstants ()
% The function provides conversion constants

%%
K_R2D = 180 / pi; % from radians to degrees
K_D2R = 1 / K_R2D; % from degrees to radians
K_IN2M = 0.0254; % from inch to meter
K_M2IN = 1 / K_IN2M; % from meter to inch
K_RDPS2RPM = 60 / ( 2 * pi ); % from rad/s to RPM
K_RPM2RDPS = 1 / K_RDPS2RPM; % from RPM to rad/s
K_OZ2N = 0.2780139; % from oz-force to N
K_N2OZ = 1 / K_OZ2N; % from N to oz-force
K_LBS2N = 4.4482216; % Pound to Newton (N/lbs)
K_N2LBS = 1 / K_LBS2N; % Newton to Pound (lbs/N/)
K_G2MS = 9.81; % from g to m/s^2
K_MS2G = 1 / K_G2MS; % from m/s^2 to g
