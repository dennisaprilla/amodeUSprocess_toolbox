clear; clc; close all;

addpath('Functions');

% read data
[data, timestamps, indexes] = readTIFF_USsignal("D:\test\log11\", 30, 1500);

% preparing constants
data_spec.n_ust     = size(data, 1);
data_spec.n_samples = size(data, 2);
data_spec.n_frames  = size(data, 3);

us_spec.v_sound     = 1500e3; % mm/s
us_spec.sample_rate = 50e6;
us_spec.index2distance_constant  = us_spec.v_sound / (2 * us_spec.sample_rate);

range = (1:data_spec.n_samples) .* us_spec.index2distance_constant;

%% SIGNAL PROCESSING

[allpeaks, envelope_data] = process_USsignal(data, data_spec, us_spec);


%% VISUALIZATION

figure(1)
probeNumber_toShow = 17;

for i=1:data_spec.n_frames
    yyaxis left;
    plot(range, data(probeNumber_toShow, :, i), 'Color', 'g');
    xlabel('Distance (mm)');
    ylabel('Signal Amplitude');
    ylim([-2500, 2500]);
    title(sprintf("Probe #%d", probeNumber_toShow));

    yyaxis right;
    plot(range, envelope_data(probeNumber_toShow, :, i), 'Color', 'r');
    xlabel('Distance (mm)');
    ylabel('Envelop Amplitude');
    ylim([0, 2000]);
    
    current_peaks = allpeaks.locations{probeNumber_toShow, i};
	delete(findobj('Tag', 'coba'));
    for j=1:length(current_peaks)
        xline(current_peaks(j), '-', sprintf('Peak #%d', j), 'Color', 'b',  'Tag', 'coba');
    end
    
    grid on;
    drawnow;
end
