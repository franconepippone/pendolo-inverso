%% Inverted Rotary Pendulum Controlled Directly: Programmatic Model
% The script programmatically creates a Simulink model of a rotary inverted 
% pendulum directly connected to the linear quadratic regulator

%% Inverted pendulum model derivation
inverted_rotary_pendulum
% the script sets the sampling time Ts, derives system state matrices in
% continuous- and discrete-time settings, and computes descrete-time linear
% quadratic regulator (LQR) gain

% Setting possible Simulink model removal after the execution of the script
closesimfile = false;
cleanup = false;

%% Programmatic Simulink model creation and setup 
% Set the new Simulink model name
modelname = 'rotpendirect';
filename = [modelname '.slx'];

%% Setting the names of the model blocks
% Plant
zoh1block = 'zoh_input';
penblock = 'pendulum';
sumblock = 'sum';
noiseblock = 'awgn';
zoh2block = 'zoh_output';
% Controller
gainblock = 'lqrgain';
% Output variable
outplantstates = 'plant_states';
outprocessnoise = 'process_noise';
outplantmeasures = 'sensor_mearurements';

%% Creating the Simulink syetem model
% Open the model if it exists, otherwise create and open the model
if ~exist(filename,'file')
    % Create and open the model
    open_system(new_system(modelname));
end

%% Configure the system blocks (plant, controller, ZOH, etc.)

% Add and Configure Inverted Pendulum model
add_block('simulink/Continuous/State-Space',[modelname '/' penblock],...
    'MakeNameUnique','on');
% BlockParameterValue = get_param(penblockname,'A')
set_param([modelname '/' penblock],...
    'A','cA','B','cB','C','cI','D','cO','X0','x0');

% Add the Input Zero-Order-Hold Block
add_block('simulink/Discrete/Zero-Order Hold',[modelname '/' zoh1block],...
    'MakeNameUnique','on');

% Add the Output Zero-Order-Hold Block
add_block('simulink/Discrete/Zero-Order Hold',[modelname '/' zoh2block],...
    'MakeNameUnique','on');

% Add the Configure Control Gain Block
add_block('simulink/Math Operations/Gain',[modelname '/' gainblock],...
    'MakeNameUnique','on');
set_param([modelname '/' gainblock],'Gain','-K',...
    'Multiplication','Matrix(K*u)');

% Add and Cinfigure Sum Block for the plant outputs
add_block('simulink/Math Operations/Sum',[modelname '/' sumblock],...
    'MakeNameUnique','on','NameLocation','top');
set_param([modelname '/' sumblock],'IconShape','round',...
    'Inputs','|++');
% phs = get_param(gcb,'PortHandles')

% Add and Configure the AWGN Block
add_block('simulink/Sources/Random Number',[modelname '/' noiseblock],...
    'MakeNameUnique','on');
set_param([modelname '/' noiseblock],'Variance','2.5e-9');
set_param([modelname '/' noiseblock],'SampleTime','Ts');

% Add and Configure the output plant states transfered to workspace
add_block("simulink/Sinks/To Workspace",[modelname '/' outplantstates]);
set_param([modelname '/' outplantstates],...
    'VariableName','x')

% Add and Configure the output plant states transfered to workspace
add_block("simulink/Sinks/To Workspace",[modelname '/' outprocessnoise]);
set_param([modelname '/' outprocessnoise],...
    'VariableName','w')

% Add and Configure the sensed plant states transfered to workspace
add_block("simulink/Sinks/To Workspace",[modelname '/' outplantmeasures]);
set_param([modelname '/' outplantmeasures],...
    'VariableName','y')

%% Make Connections Between the Blocks
add_line(modelname,[zoh1block '/1'],[penblock '/1'])
add_line(modelname,[penblock '/1'],[sumblock '/1'])
add_line(modelname,[noiseblock '/1'],[sumblock '/2'])

add_line(modelname,[noiseblock '/1'],[outprocessnoise '/1'])
add_line(modelname,[zoh2block '/1'],[outplantstates '/1'])

add_line(modelname,[sumblock '/1'],[zoh2block '/1'])
add_line(modelname,[zoh2block '/1'],[gainblock '/1'])
add_line(modelname,[gainblock '/1'],[zoh1block '/1'])

add_line(modelname,[penblock '/1'],[outplantmeasures '/1'])

% Arrange system blocks of the main system
Simulink.BlockDiagram.arrangeSystem(modelname)

%% Save and execute the system model 
save_system(modelname)
out = sim(modelname);

%% Plot the system states
figure(1)
plot(out.x)
grid on

%% Close and delete the Simulink model if required
if closesimfile
    % Close the system model
    close_system(modelname) %#ok<UNRCH>
end

if cleanup
    % Delete the existing system model
    delete(filename) %#ok<UNRCH>
end

clear closesimfile cleanup