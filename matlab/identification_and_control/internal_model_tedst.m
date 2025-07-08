A = [0 1; -2 -1];
B = [0;1];
C = [1 0];


%% STEP
Ae_step = [0 C; [0;0] A];
Be_step = [0; B];

Co = ctrb(Ae_step, Be_step);
rank(Co)

K_step = place(Ae_step, Be_step, [-10, -5, -7]);
K1 = K_step(1)
K2 = K_step(2:3)


%% RAMP
Ae = [0 1 0 0;
     0 0 C;
     [0;0] [0;0] A];

Be = [0;0; B];

K = place(Ae, Be, [-1, -2, -3, -4]);

%K1 = K(1)
%K2 = K(2)
%K3 = K(3:4)