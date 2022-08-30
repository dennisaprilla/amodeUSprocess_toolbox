% this code requires ini2struct function which can be found here:
% https://nl.mathworks.com/matlabcentral/fileexchange/17177-ini2struct

clear; clc; close all;

probeConfigStruct= ini2struct('transducerconfig_10-8-2022_20-05-56.ini');

% get the field names
probeConfig_fieldnames = fieldnames(probeConfigStruct);
% get the number of ultrasound
probeConfig_n_ust = length(probeConfig_fieldnames);
% loop through all the fields
for i=1:probeConfig_n_ust
    % get lower and upper bound data
    lowerbound_str = probeConfigStruct.(probeConfig_fieldnames{i}).LowerBound;
    upperbound_str = probeConfigStruct.(probeConfig_fieldnames{i}).UpperBound;
    
    % but because it is string, and the US machine somehow uses comma 
    % separator for floating point, so we need to replace the comma as 
    % point first, then convert it to double.
    lowerbound = str2double(strrep(lowerbound_str, ',', '.'));
    upperbound = str2double(strrep(upperbound_str, ',', '.'));
end