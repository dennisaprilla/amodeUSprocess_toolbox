clear; clc; close all;

addpath('functions');

% read data
[data, timestamps, indexes] = readTIFF_USsignal("D:\test\test2\walk_slow\", 30, 1500);

% test to cut data
data = data(:,1:1000,:);

% preparing constants
data_spec.n_ust     = size(data, 1);
data_spec.n_samples = size(data, 2);
data_spec.n_frames  = size(data, 3);

us_spec.v_sound     = 1500e3; % mm/s
us_spec.sample_rate = 50e6;
us_spec.index2distance_constant  = us_spec.v_sound / (2 * us_spec.sample_rate);

range = (1:data_spec.n_samples) .* us_spec.index2distance_constant;

%% SIGNAL PROCESSING

[allpeaks, envelope_data] = peaks_USsignal(data, data_spec, us_spec);


%% M-MODE VISUALIZATION
close all;

probeNumber_toShow = 19;
evelopeSignal_threshold = 1000;

probe = reshape( envelope_data(probeNumber_toShow,:,:), [data_spec.n_samples, data_spec.n_frames]);
probe_image = uint8(255 * mat2gray(probe, [0 evelopeSignal_threshold]));

figure1 = figure(1);
figure1.WindowState  = 'maximized';

ax = subplot(2,1,1, 'Parent', figure1);
imagesc([0 data_spec.n_frames], [0 range(end)], probe_image);
xlabel('Timestamp');
ylabel('Depth (mm)');
title(sprintf("Probe #%d", probeNumber_toShow));
colorbar;

for i=1:data_spec.n_frames
    delete(findobj('Tag', 'coba1'));
    xline(ax, i, '-', 'Timestamp', 'LineWidth', 2, 'Color', 'r',  'Tag', 'coba1');
    
    subplot(2,1,2);
    yyaxis left;
    plot(range, data(probeNumber_toShow, :, i), 'Color', 'g');
    xlabel('Distance (mm)');
    ylabel('Signal Amplitude');
    ylim([-2500, 2500]);

    yyaxis right;
    plot(range, envelope_data(probeNumber_toShow, :, i), 'Color', 'r');     
    xlabel('Distance (mm)');
    ylabel('Envelop Amplitude');
    ylim([0, evelopeSignal_threshold]);
    title(sprintf("Probe #%d", probeNumber_toShow));
    
    current_peaks = allpeaks.locations{probeNumber_toShow, i};
	delete(findobj('Tag', 'coba2'));
    for peak=1:length(current_peaks)
        xline(current_peaks(peak), '-', sprintf('Peak #%d', peak), 'Color', 'b',  'Tag', 'coba2');
    end
    
    grid on;
    drawnow;
end

%%

% figure(2);
% 
% test = imdiffusefilt(probe_image, 'NumberOfIterations', 7, 'ConductionMethod', 'quadratic');
% 
% subplot(1,2,1);
% imshow(probe_image);
% subplot(1,2,2);
% imshow(test);

