function display_peak_mmode(current_axes, allpeaks, probeNumber_toShow, tag)

delete(findobj('Tag', tag));

hold(current_axes, 'on');
plot(current_axes, allpeaks.locations(probeNumber_toShow,:), '-m', 'Tag', tag);
hold(current_axes, 'off');

end

