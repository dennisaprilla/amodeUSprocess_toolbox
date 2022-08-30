clear; clc; close all;

addpath('..\functions');

% read data
[data, timestamps, indexes] = readTIFF_USsignal("D:\test\test2\walk_slow\", 30, 1500);

% preparing constants
data_spec.n_ust     = size(data, 1);
data_spec.n_samples = size(data, 2);
data_spec.n_frames  = size(data, 3);

us_spec.v_sound     = 1540e3; % mm/s
us_spec.sample_rate = 50e6;
us_spec.index2distance_constant  = us_spec.v_sound / (2 * us_spec.sample_rate);

x_mm = (1:data_spec.n_samples) .* us_spec.index2distance_constant;

%% SIGNAL PROCESSING
close all;
load('..\data\experiment_wo_mocap\test2\dorsiflexion\dorsiflexion_windowUS.mat');

% define window range
probeProperties.WindowRange = [1 1].*probeProperties.WindowPosition + [-1 1].*0.5.*probeProperties.WindowWidth;
% convert windows mm to windows indices
probeProperties.WindowRange_i = floor(probeProperties.WindowRange/us_spec.index2distance_constant + 1);

% load barker's table
barker_table = readtable('..\data\kenans_barkercode.txt', 'Delimiter', '\t');
figure(1);
plot(barker_table.Amplitude_Plot0);

% define the signal we want to process
probeNumber_toProcess = 16;
timestamp_toProcess = 1;

figure(2);
for i=1:data_spec.n_frames

    delete(findobj('Tag', 'plot_raw'));
    delete(findobj('Tag', 'plot_correlated'));

    data_toProcess = data(probeNumber_toProcess, :, i);
    plot(data_toProcess, 'Tag', 'plot_raw'); hold on;

    data_correlated = xcorr(data_toProcess, barker_table.Amplitude_Plot0);
    data_correlated = data_correlated(length(data_toProcess):end);
    plot(data_correlated, '-g', 'Tag', 'plot_correlated');

    drawnow;
end
