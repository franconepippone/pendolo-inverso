modelname = 'mymodel';
filename = [modelname '.slx'];
blockname = 'waveform generator';

% Create the Simulink system model
open_system(new_system(modelname));

% Add the waveform generator block
add_block('simulink/Sources/Waveform Generator',[modelname '/' blockname]);

% Configure the waveform generator block
set_param([modelname '/' blockname],...
    'Signals',"gaussian('Mean',0,'Variance',0.5,'Seed', 1)");

