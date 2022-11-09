function display_amode(current_axes, probeNumber_toShow, timestamp_toShow, raw_data, envelope_data, x_axis_values, tag1, tag2)

% just to make sure the plot is clean
delete(findobj('Tag', tag1));
delete(findobj('Tag', tag2));

% show a-mode
yyaxis(current_axes, 'left');
plot(current_axes, x_axis_values, raw_data(probeNumber_toShow, :, timestamp_toShow), '-', 'Color', 'g', 'Tag', tag1);
xlabel(current_axes, 'Distance (mm)');
ylabel(current_axes, 'Signal Amplitude');
y_limit = [min(raw_data(probeNumber_toShow, :, timestamp_toShow)), ...
           max(raw_data(probeNumber_toShow, :, timestamp_toShow) )];
ylim(current_axes, y_limit);

% Check whether the envelop variable is a cell or not. Why cell? because if
% we clipped the envelop signal based on the window, the length of the
% signal may varies, so it is not possible to store it in an array/matrix.
% As i want to make this function as general as possible i will put the
% cheking here
if ( iscell(envelope_data) )
    envelop_data_toShow = envelope_data{probeNumber_toShow, timestamp_toShow};
else
    envelop_data_toShow = envelope_data(probeNumber_toShow, :, timestamp_toShow);
end

% show the envelope
yyaxis(current_axes, 'right');
plot(current_axes, x_axis_values, envelop_data_toShow, '-', 'Color', 'r', 'LineWidth',1.5, 'Tag', tag2);     
xlabel(current_axes, 'Distance (mm)');
ylabel(current_axes, 'Envelop Amplitude');
% ylim(current_axes, [0, 1500]);
ylim(current_axes, y_limit);
title(current_axes, sprintf("A-Mode Probe #%d", probeNumber_toShow));

grid(current_axes, 'on');

end

