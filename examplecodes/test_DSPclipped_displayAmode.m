clear; clc; close all;

addpath('..\functions');

% read data
[data, timestamps, indexes] = readTIFF_USsignal("..\data\experiment_wo_mocap\test4\legswinging\", 30, 1500);

% preparing constants
data_spec.n_ust     = size(data, 1);
data_spec.n_samples = size(data, 2);
data_spec.n_frames  = size(data, 3);

us_spec.v_sound     = 1500e3; % mm/s
us_spec.sample_rate = 50e6;
us_spec.index2distance_constant  = us_spec.v_sound / (2 * us_spec.sample_rate);

x_mm = (1:data_spec.n_samples) .* us_spec.index2distance_constant;

%% SIGNAL PROCESSING

load('..\data\experiment_wo_mocap\test4\legswinging\legswinging_windowUS.mat');
% addpath('..\functions\experimental');

% define window range
% probeProperties.WindowRange = [1 1].*probeProperties.WindowPosition + [-1 1].*0.5.*probeProperties.WindowWidth;
probeProperties.WindowRange = [probeProperties.WindowLowerBound probeProperties.WindowUpperBound];
% convert windows mm to windows indices
probeProperties.WindowRange_i = floor(probeProperties.WindowRange/us_spec.index2distance_constant + 1);

% signal pre-processing
[allpeaks, envelope_clipped] = peaks_USsignal_windowed(data, data_spec, us_spec, probeProperties.WindowRange, probeProperties.WindowRange_i);


%% DISPLAY

addpath('..\functions\displays');

% process the data
probeNumber_toShow = 27;
timestamp_toShow = 1;

data_clipped = data(:, probeProperties.WindowRange_i(probeNumber_toShow, 1):probeProperties.WindowRange_i(probeNumber_toShow, 2), :);
x_mm_clipped = x_mm(probeProperties.WindowRange_i(probeNumber_toShow, 1):probeProperties.WindowRange_i(probeNumber_toShow, 2));

figure1 = figure(1);
axes1 = axes('Parent', figure1);
for i=1:data_spec.n_frames
    
    display_amode( axes1, ...
                   probeNumber_toShow, ...
                   i, ...
                   data_clipped, ...
                   envelope_clipped, ...
                   x_mm_clipped, ...
                   'plot_raw', ...
                   'plot_env');
                       
	display_peak_amode(axes1, allpeaks, probeNumber_toShow, i, 'plot_peak');
    
    if(i==400)
        break;
    end
    
    drawnow;
end






