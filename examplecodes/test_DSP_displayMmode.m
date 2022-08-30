clear; clc; close all;

addpath('..\functions');

% read data
[data, timestamps, indexes] = readTIFF_USsignal("..\data\experiment_wo_mocap\test4\legswinging\", 30, 1500);

% preparing constants
data_spec.n_ust     = size(data, 1);
data_spec.n_samples = size(data, 2);
data_spec.n_frames  = size(data, 3);

us_spec.v_sound     = 1540e3; % mm/s
us_spec.sample_rate = 50e6;
us_spec.index2distance_constant  = us_spec.v_sound / (2 * us_spec.sample_rate);

x_mm = (1:data_spec.n_samples) .* us_spec.index2distance_constant;

%% SIGNAL PROCESSING

load('..\data\experiment_wo_mocap\test4\legswinging\legswinging_windowUS.mat');
addpath('..\functions\experimental');

% signal pre-processing
envelope = process_USsignal(data, data_spec, us_spec);


%% DISPLAY

addpath('..\functions\displays');

% process the data
probeNumber_toShow = 16;
timestamp_toShow = 1;

display_peak_all([3 3 5 4], 16, envelope, data_spec, x_mm);

% figure1 = figure(1);
% axes1 = axes('Parent', figure1);
% display_mmode( axes1, ...
%                probeNumber_toShow, ...
%                envelope, ...
%                data_spec, ...
%                x_mm);
% 
% hold on;
% plot(movmean(allpeaks.locations(16,:),10));





