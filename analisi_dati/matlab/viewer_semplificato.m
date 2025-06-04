close all 
clear
clc
format long

data = readtable("simulazioni/nonlinear_pid_2.csv", "CommentStyle", "#");

STATES = [data.theta, data.theta_dot, data.pos, data.vel];

TIMESTEP = 10^-2; % 10ms

ITER_WINDOW = 0:100;
times = 0:TIMESTEP:(length(data.theta) * TIMESTEP - TIMESTEP);

figure()
plot(times, [data.input STATES]);
legend({'input', 'theta', "theta'", 'position', 'velocity'});