%% COMPARES SIMULATED OUTPUT TO PREDICTED OUTPUT FROM SYSTEM
% Supposes these variables are available in workspace
% A: A system matrix
% B: system input matrix
% K: State-feedback gain matrix
% TIMESTEP: timestep of controller

function comparePlots()

sys_cl = ss(A - B*K, zeros(4, 0), eye(4), 0, TIMESTEP);

initial(sys_cl, recdata.info.initial_cond);
