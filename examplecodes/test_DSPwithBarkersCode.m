%% Comments:
% I don't know, it seems that barker code correlation shift the signal a
% little bit. And after seeing the results, it seems that the correlation
% is not making the signal better, it is just amplifying the signal, so it
% gives us more noise. Run this program if you want know what i mean.
%
% So, it looks like the correlation with barker's code is impressive, but
% when i filter it with lp filter, the signal is just about the same as the
% original.

clear; clc; close all;

addpath('..\functions');

% read data
[data, timestamps, indexes] = readTIFF_USsignal("..\data\experiment_wo_mocap\test2\dorsiflexion\", 30, 1500);

% preparing constants
data_spec.n_ust     = size(data, 1);
data_spec.n_samples = size(data, 2);
data_spec.n_frames  = size(data, 3);

us_spec.v_sound     = 1500e3; % mm/s
us_spec.sample_rate = 50e6;
us_spec.index2distance_constant  = us_spec.v_sound / (2 * us_spec.sample_rate);

x_mm = (1:data_spec.n_samples) .* us_spec.index2distance_constant;

%% SIGNAL PROCESSING
close all;
load('..\data\experiment_wo_mocap\test2\dorsiflexion\dorsiflexion_windowUS.mat');

% define window range
% probesProperties.WindowRange = [1 1].*probesProperties.WindowPosition + [-1 1].*0.5.*probesProperties.WindowWidth;
probeProperties.WindowRange = [probeProperties.WindowLowerBound probeProperties.WindowUpperBound];
% convert windows mm to windows indices
probeProperties.WindowRange_i = floor(probeProperties.WindowRange/us_spec.index2distance_constant + 1);

% load barker's table
barker_table = readtable('..\data\kenans_barkercode.txt', 'Delimiter', '\t');
% figure(1);
% plot(barker_table.Amplitude_Plot0);

% define the signal we want to process
probeNumber_toProcess = 17;
timestamp_toProcess = 1;
tic;

% 1) take the data
data_toProcess = data(probeNumber_toProcess, :, timestamp_toProcess);

% 2) hp filter
hpFilt = designfilt('highpassiir','FilterOrder',2, ...
         'PassbandFrequency',3.5e6,'PassbandRipple',0.2, ...
         'SampleRate', us_spec.sample_rate);
data_hpfiltered = filtfilt(hpFilt, data_toProcess);

% 3) barker's code correlation
data_correlated = xcorr(data_hpfiltered, barker_table.Amplitude_Plot0);
data_correlated = data_correlated(length(data_hpfiltered):end);


% 3) lp filter
lpFilt = designfilt('lowpassiir','FilterOrder',2, ...
         'PassbandFrequency', 2.5e6,'PassbandRipple',0.3, ...
         'SampleRate', us_spec.sample_rate);
data_lpfiltered = filtfilt(lpFilt, data_correlated);

% 5) enveloping the signal
envelop_windowlength = 30;
data_enveloped = envelope(data_lpfiltered, envelop_windowlength, 'rms');

t_dsp = toc;
fprintf("DSP is finished, 1 signal 1 timestamp: %.4f seconds\n", t_dsp);

%% plot the data

figure1 = figure(1);
axes1 = axes('Parent', figure1);

yyaxis(axes1, 'left');
plot(axes1, x_mm, data_toProcess); hold on;
plot(axes1, x_mm, data_lpfiltered, '-g');
xlabel(axes1, 'Distance (mm)');
ylabel(axes1, 'Signal Amplitude');
ylim(axes1, [-10000, 10000]);

yyaxis(axes1, 'right');
plot(axes1, x_mm, data_enveloped);
xlabel(axes1, 'Distance (mm)');
ylabel(axes1, 'Envelop Amplitude');

title(axes1, sprintf("A-Mode Probe #%d", probeNumber_toProcess));
grid(axes1, 'on');






