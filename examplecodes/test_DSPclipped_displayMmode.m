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
addpath('..\functions\experimental');

% define window range
% probeProperties.WindowRange = [1 1].*probeProperties.WindowPosition + [-1 1].*0.5.*probeProperties.WindowWidth;
probeProperties.WindowRange = [probeProperties.WindowLowerBound probeProperties.WindowUpperBound];
% convert windows mm to windows indices
probeProperties.WindowRange_i = floor(probeProperties.WindowRange/us_spec.index2distance_constant + 1);

% signal pre-processing
% [allpeaks, envelope_clipped] = peaks_USsignal_windowed(data, data_spec, us_spec, probesProperties.WindowRange, probesProperties.WindowRange_i);
envelope_clipped = process_USsignal_windowed(data, data_spec, us_spec, probeProperties.WindowRange_i);


%% DISPLAY

addpath('..\functions\displays');

% process the data
probeNumber_toShow = 16;
timestamp_toShow = 1;

data_clipped = data(:, probeProperties.WindowRange_i(probeNumber_toShow, 1):probeProperties.WindowRange_i(probeNumber_toShow, 2), :);
x_mm_clipped = x_mm(probeProperties.WindowRange_i(probeNumber_toShow, 1):probeProperties.WindowRange_i(probeNumber_toShow, 2));

display_peak_all([3 3 5 4], 16, envelope_clipped, data_spec, x_mm_clipped);

% hold on;
% plot(movmean(allpeaks.locations(16,:),10));





