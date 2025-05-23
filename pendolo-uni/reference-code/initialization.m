%% The initialisation script 
% preparing the environment for execution
clear % removes all variables from the current workspace
close all hidden % deletes all figures including those with hidden handles
clc % clears all input and output from the Command Window display
format long % changes the output display format in the Command Window
dirName = '2025-cdc-lcss-wireless--code';
fldr = what(dirName);
folderMain = fldr.path;
% pwd

if isunix
    dividerSign = '/';
elseif ispc
    dividerSign = '\';
else
    disp('Platform not supported')
end

folderFunctions = [folderMain dividerSign 'functions'];
folderData =      [folderMain dividerSign 'data'];
folderScript =    [folderMain dividerSign 'scripts'];
folderSupport =   [folderMain dividerSign 'support'];
folderFigures =   [folderMain dividerSign 'figures'];
folderLog =       [folderMain dividerSign 'log'];
folderOut =       [folderMain dividerSign 'outputs'];

path(folderMain,path)
path(folderFunctions,path)
path(folderData,path)
path(folderScript,path)
path(folderSupport,path)
path(folderFigures,path)
path(folderLog,path)
path(folderOut,path)

% Saving the folders name in backup variables to recall when using the data
% from server
folderMainName = folderMain;
folderFunctionsName = folderFunctions;
folderDataName = folderData;
folderScriptName = folderScript;
folderSupportName = folderSupport;
folderFiguresName = folderFigures;
folderLogName = folderLog;
folderOutName = folderOut;

clear fldr