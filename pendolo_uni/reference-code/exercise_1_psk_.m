%% Solution to the first question of the exercise no. 1

initialization % prepares the MATLAB environment for execution

%% Link parameters
d = 50; % TX-RX distance [m]
fc = 2.45e9; % carrier frequency [Hz]
lambda = physconst('LightSpeed')/fc; % wavelength [m]
W = 2e6; % available bandwidth [Hz]
Ls = (lambda/(4*pi*d))^2; % free-space attenuation
T = 300; % [K] temperature
No = physconst('Boltzmann')*T; % noise power spectral density
Gt = 3; % TX antenna gain
Gr = 0; % RX antenna gain

%% Design constraint
ber_target = 1e-3; % bit-error-rate target

%% Simulation stop parameters
maxNumErrs = 1e2;
maxNumBits = maxNumErrs/ber_target;

%% Plot parameters
sim_marker = {'.k','.b','.r'};
theory_line = {'--k','--b','--r'};
theory_awgn = {'-k','-b','-r'};
plotname = 'psk-ber';

%% Index
marker = 1;

%% Energy per bit to noise power spectral density ratio range:
EbNoValues = 0 : 0.5 : 15;
awgn_EbNo = 0 : 0.1 : 15;

%% Transmit power achieving the target BER in the AWGN setting
P_awgn = zeros(1,3);

%% Simulink file name and its block names
modelname = 'exercise_1_psk'; % Simulink model name
filename = [modelname '.slx']; % Simulink filename
sourceblock = 'Random Integer'; % Source block name
modulatorblock = 'M-PSK Modulator'; % Modulator block name
awgnblock = 'AWGN Channel'; % AWGN Channel block name
demodulatorblock = 'M-PSK Demodulator'; % Demodulator block name
errorrateblock = 'Error Rate Calculation'; % Error rate calculation block

if ~exist(filename,'file')
    % Create and open the model
    open_system(new_system(modelname));

    %% Add and configure source block
    add_block('commrandsrc3/Random Integer Generator', ...
        [modelname '/' sourceblock])
    % Set size: <SetSize>
    set_param([modelname '/' sourceblock], 'SetSize', '2');
    % Source of initial seed: <SeedSource>
    set_param([modelname '/' sourceblock], 'SeedSource', 'Auto');
    % Initial seed: <Seed>
    set_param([modelname '/' sourceblock], 'Seed', '0');
    % Sample time: <SampleTime>
    set_param([modelname '/' sourceblock], 'SampleTime', '1/(W*k)');
    % Samples per frame: <SamplesPerFrame>
    set_param([modelname '/' sourceblock], 'SamplesPerFrame', 'k');
    % Output data type: <OutputDataType>
    set_param([modelname '/' sourceblock], 'OutputDataType', 'double');
    % Simulate using: <SimulateUsing>
    set_param([modelname '/' sourceblock], 'SimulateUsing', ...
        'Interpreted execution');
    
    %% Add and configure modulator block
    add_block('commdigbbndpm3/M-PSK Modulator Baseband', ...
        [modelname '/' modulatorblock])
    % M-ary number: <M>
      set_param([modelname '/' modulatorblock], 'M', 'M');
    % Input type: <InType>
      set_param([modelname '/' modulatorblock], 'InType', 'Bit');
    % Constellation ordering: <Enc>
      set_param([modelname '/' modulatorblock], 'Enc', 'Gray');
    % Constellation mapping: <Mapping>
      set_param([modelname '/' modulatorblock], 'Mapping', '[0:7]');
    % Phase offset (rad): <Ph>
      set_param([modelname '/' modulatorblock], 'Ph', 'pi/M');
    
    %% Add and configure AWGN channel block
    add_block('commchan3/AWGN Channel', ...
        [modelname '/' awgnblock]);
    % Legacy mode <LegacyMode>
      set_param([modelname '/' awgnblock], 'LegacyMode', 'on');
    % Mode: <NoiseMethod>
      set_param([modelname '/' awgnblock], 'NoiseMethod', ...
          'Signal to noise ratio  (SNR)');
    % Mode: <noiseMode>
      set_param([modelname '/' awgnblock], 'noiseMode', ...
          'Signal to noise ratio  (Eb/No)');
    % Eb/No (dB): <EbNo>
      set_param([modelname '/' awgnblock], 'EbNo', 'EbNo');
    % Number of bits per symbol: <BitsPerSymbol>
      set_param([modelname '/' awgnblock], 'BitsPerSymbol', 'k');
    % Input signal power, referenced to 1 ohm (watts): <SignalPower>
      set_param([modelname '/' awgnblock], 'SignalPower', '1');
    % Samples per symbol: <SamplesPerSymbol>
      set_param([modelname '/' awgnblock], 'SamplesPerSymbol', '1');
    % Symbol period (s): <SymbolPeriod>
      set_param([modelname '/' awgnblock], 'SymbolPeriod', '1/W');
    % Noise variance source: <VarianceSource>
      set_param([modelname '/' awgnblock], 'VarianceSource', 'Parameter');
    % Noise variance: <Variance>
      set_param([modelname '/' awgnblock], 'Variance', '1');
    % Random number source: <RandomStream>
      set_param([modelname '/' awgnblock], 'RandomStream', 'Global stream');
    % Initial seed: <Seed>
      set_param([modelname '/' awgnblock], 'Seed', '67');
    % Simulate using: <SimulateUsing>
      set_param([modelname '/' awgnblock], 'SimulateUsing', ...
          'Code generation')
    
    %% Add and configure demodulator block
    add_block('commdigbbndpm3/M-PSK Demodulator Baseband', ...
        [modelname '/' demodulatorblock])
    % M-ary number: <M>
      set_param([modelname '/' demodulatorblock], 'M', 'M');
    % Output type: <OutType>
      set_param([modelname '/' demodulatorblock], 'OutType', 'Bit');
    % Decision type: <DecType>
      set_param([modelname '/' demodulatorblock], 'DecType', ...
          'Hard decision');
    % Noise variance source: <VarSource>
      set_param([modelname '/' demodulatorblock], 'VarSource', 'Dialog');
    % Noise variance: <Variance>
      set_param([modelname '/' demodulatorblock], 'Variance', '1');
    % Constellation ordering: <Dec>
      set_param([modelname '/' demodulatorblock], 'Dec', 'Gray');
    % Constellation mapping: <Mapping>
      set_param([modelname '/' demodulatorblock], 'Mapping', '[0:7]');
    % Phase offset (rad): <Ph>
      set_param([modelname '/' demodulatorblock], 'Ph', 'pi/M');
    % Output data type: <outDtype1>
      set_param([modelname '/' demodulatorblock], 'outDtype1', ...
          'Inherit via internal rule');
    % Output data type: <outDtype2>
      set_param([modelname '/' demodulatorblock], 'outDtype2', ...
          'Inherit via internal rule');
    
    %% Add and configure error rate calculation block
    add_block('commsink2/Error Rate Calculation', ...
        [modelname '/' errorrateblock])
    % Receive delay: <N>
      set_param([modelname '/' errorrateblock], 'N', '0');
    % Computation delay: <st_delay>
      set_param([modelname '/' errorrateblock], 'st_delay', '0');
    % Computation mode: <cp_mode>
      set_param([modelname '/' errorrateblock], 'cp_mode', 'Entire frame');
    % Selected samples from frame: <subframe>
      set_param([modelname '/' errorrateblock], 'subframe', '[]');
    % Output data: <PMode>
      set_param([modelname '/' errorrateblock], 'PMode', 'Workspace');
    % Variable name: <WsName>
      set_param([modelname '/' errorrateblock], 'WsName', 'ErrorVec0');
    % Reset port <RsMode2>
      set_param([modelname '/' errorrateblock], 'RsMode2', 'off');
    % Stop simulation <stop>
      set_param([modelname '/' errorrateblock], 'stop', 'on');
    % Target number of errors: <numErr>
      set_param([modelname '/' errorrateblock], 'numErr', 'maxNumErrs');
    % Maximum number of symbols: <maxBits>
      set_param([modelname '/' errorrateblock], 'maxBits', 'maxNumBits')
    
    %% Add lines
    add_line(modelname,[sourceblock '/1'],[modulatorblock '/1'])
    add_line(modelname,[sourceblock '/1'],[errorrateblock '/1'])
    
    add_line(modelname,[modulatorblock '/1'],[awgnblock '/1'])
    add_line(modelname,[awgnblock '/1'],[demodulatorblock '/1'])
    add_line(modelname,[demodulatorblock '/1'],[errorrateblock '/2'])
    
    %% Arrange system blocks of the main system
    Simulink.BlockDiagram.arrangeSystem(modelname)
    
    %% Save the Simulink system model 
    save_system(modelname)

else
    open_system(modelname)
end

%% Solving the model for different transmit power values
for k = 2 : 4    
    M = 2^k;
    
    err0 = zeros(1,length(EbNoValues));
    
    h = waitbar(0,'Calculating BER values');

    for i = 1 : length(EbNoValues)

        EbNo = EbNoValues(i); % scaling the constellation radius

        waitbar(i/length(EbNoValues),h,sprintf(...
            'Solving model for Eb/N0 = %.1f dB...', EbNoValues(i)));

        sim(modelname);

        err0(i) = ErrorVec0(1);

    end

    close(h)
    
    disp([num2str(M),'-PSK'])
    
    % Bit error rate (BER) for uncoded AWGN channels:
    ber_awgn = berawgn(awgn_EbNo,'psk',M,'nondiff');
    
    [~,ind] = min(abs(err0-ber_target));
    disp(['BER value:',num2str(err0(ind))])
    
    EbNoTarget = EbNoValues(ind);
    disp(['  The required EbNo is ',num2str(EbNoTarget),' dB'])
    
    Ptawgn = EbNoTarget + pow2db(No) + pow2db(k) + pow2db(W) ...
        - Gt - Gr - pow2db(Ls) + 30; % [dBm]
    P_awgn(marker) = Ptawgn;
    
    disp(['  The required transmit power in the AWGN case is ', ...
        num2str(Ptawgn), ' dBm'])
    
    figure(1)
    xlabel('$\mathcal{E}_b/N_0$ dB','interpreter','latex')
    ylabel('Bit Error Rate','interpreter','latex')
    a0 = semilogy(EbNoValues,err0,sim_marker{marker},...
        'LineWidth',3,'MarkerSize',15); hold on
    semilogy(awgn_EbNo,ber_awgn,theory_line{marker}); hold on
    grid on
 
    marker=marker+1;
    
end

fig = figure(1);
lin = yline(1e-3,'','BER constraint');
lin.LabelHorizontalAlignment = 'left';
lin.LabelVerticalAlignment = 'bottom';
lin.Color = '#D95319';
lin.LineWidth = 1.5;
xticks(0:1:max(EbNoValues))

legend('4-PSK sim','4-PSK theory','8-PSK sim','8-PSK theory',...
    '16-PSK sim','16-PSK theory','BER constraint','Location','southwest')

exportgraphics(fig,[plotname '.pdf'],'ContentType','vector',...
    'BackgroundColor','none','Colorspace','rgb')