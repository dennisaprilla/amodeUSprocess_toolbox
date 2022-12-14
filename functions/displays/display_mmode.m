function display_mmode_windowed(current_axes, probeNumber_toShow, envelope_data, data_spec, x_axis_values)

% set the constant
mmode_threshold = 1000;

if (iscell(envelope_data))
    
    % cell2mat(envelope_data(x,:))   -> give me looong vector since each cell
    % contains long vector
    % cell2mat(envelope_data(x,:)')  -> transpose will stack the vector of cell 
    % vertically, so almost what i wanted, the row is now the timestamp
    % cell2mat(envelope_data(x,:)')' -> now it is perfect
    probe = cell2mat(envelope_data(probeNumber_toShow,:)')';
    
else
    probe = reshape( envelope_data(probeNumber_toShow,:,:), [data_spec.n_samples, data_spec.n_frames]);
end

probe_image = uint8(255 * mat2gray(probe, [0 mmode_threshold]));

% show m-mode
imagesc(current_axes, [1 data_spec.n_frames], [x_axis_values(1) x_axis_values(end)], probe_image);
xlabel(current_axes, 'Timestamp');
ylabel(current_axes, 'Depth (mm)');
title(current_axes, sprintf("M-Mode Probe #%d", probeNumber_toShow));
colorbar(current_axes);

end

