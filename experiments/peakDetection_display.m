clear; clc; close all;

addpath('functions');

% read data
[data, timestamps, indexes] = readTIFF_USsignal("D:\test\test2\walk_slow\", 30, 1500);

% preparing constants
data_spec.n_ust     = size(data, 1);
data_spec.n_samples = size(data, 2);
data_spec.n_frames  = size(data, 3);

us_spec.v_sound     = 1500e3; % mm/s
us_spec.sample_rate = 50e6;
us_spec.index2distance_constant  = us_spec.v_sound / (2 * us_spec.sample_rate);

x_mm = (1:data_spec.n_samples) .* us_spec.index2distance_constant;

%% SIGNAL PROCESSING

load('data\probes_related\test2\dorsiflexion.mat');

% define window range
probesProperties.WindowRange = [1 1].*probesProperties.WindowPosition + [-1 1].*0.5.*probesProperties.WindowWidth;
% convert windows mm to windows indices
probesProperties.Window_i = floor(probesProperties.WindowRange/us_spec.index2distance_constant + 1);


% signal pre-processing
envelope = process_USsignal_woPeaks(data, data_spec, us_spec);
% peak detection
% here


%% DISPLAY

addpath('functions\displays');

% process the data
probes_toProcess = 16;
timestamp_toProcess = 1;

data_clipped     = data( :, probesProperties.Window_i(probes_toProcess, 1):probesProperties.Window_i(probes_toProcess, 2), : );
envelope_clipped = envelope( :, probesProperties.Window_i(probes_toProcess, 1):probesProperties.Window_i(probes_toProcess, 2), : );
x_mm_clipped     = x_mm(probesProperties.Window_i(probes_toProcess, 1):probesProperties.Window_i(probes_toProcess, 2));

figure1 = figure(1);
% axes1 = axes('Parent', figure1);

for i=1:data_spec.n_frames
    axes1 = subplot(2,2, [1 2]);
    display_amode_woPeaks( axes1, ...
                           probes_toProcess, ...
                           i, ...
                           data, ...
                           envelope, ...
                           x_mm, ...
                           'plot_raw1', ...
                           'plot_env1');
                       
    display_signalwindow_amode( axes1, ...
                                probesProperties.WindowPosition(probes_toProcess), ...
                                probesProperties.WindowWidth(probes_toProcess) )
    
    axes2 = subplot(2,2, 3);
    display_amode_woPeaks( axes2, ...
                           probes_toProcess, ...
                           i, ...
                           data_clipped, ...
                           envelope_clipped, ...
                           x_mm_clipped, ...
                           'plot_raw2', ...
                           'plot_env2');
    hold(axes2, 'off');
    
    drawnow;
end












