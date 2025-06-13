function [] = plotrun( filename )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
    load(filename)
    figure();
    title(filename);
    subplot(2, 1, 1);
    
    
    t = datarun.t;
    u = datarun.u;
    states = datarun.states;
    trackpoint = datarun.trackpoint;
    
    plot(t, [states trackpoint])
    ylim([-2, 2])
    xlim([0, t(end)])
    legend('theta','alpha', 'theta dot', 'alpha dot', 'trackpoint')

    subplot(2,1, 2);
    plot(t, [u trackpoint])
    xlim([0, t(end)])
    legend('u', 'trackpoint')

end

