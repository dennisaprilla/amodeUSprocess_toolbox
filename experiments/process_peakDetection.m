function peaks = process_peakDetection(envelope_data, probeNumber_toShow, timestamp_toshow, window, index2distance_constant)

% preparing constants for peak window
window_startindex = (window.center - window.width) / index2distance_constant;
window_stopindex  = (window.center + window.width) / index2distance_constant;

% preparing constants for peak detection
minpeakwidth = 5;
minpeakprominence = 300;

% 6) Local maxima detection
[peaks, locs] =  findpeaks( ...
                    envelope_data(probeNumber_toShow, window_startindex:window_stopindex, timestamp_toshow), ...
                    'MinPeakWidth', minpeakwidth,           ...
                    'MinPeakProminence', minpeakprominence, ...
                    'SortStr', 'descend'                    ...
                  );

% we only store the locs value if it is not empty, or else, it will
% produce an error
if locs
    peaks.sharpness = peaks;
    peaks.locations = locs * us_spec.index2distance_constant;
end


end

