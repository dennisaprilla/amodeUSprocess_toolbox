clc; clear; close all;

% add path for reading signal
addpath('../functions');
addpath('../functions/displays');
addpath('../functions/signal');
addpath(genpath('../functions/external'));

% get us data
dname = uigetdir(pwd);
[USData, ~, ~] = readTIFF_USsignal(dname, 30, 1500);

% preparing constants for data spesification
data_spec.n_ust     = size(USData, 1);
data_spec.n_samples = size(USData, 2);
data_spec.n_frames  = size(USData, 3);

% preparing constants for ultrasound spesification
us_spec.v_sound     = 1540e3; % mm/s
us_spec.sample_rate = 50e6;
us_spec.index2distance_constant  = us_spec.v_sound / (2 * us_spec.sample_rate);

% signal processing to get m-mode data
[envelope_data, ~] = process_USsignal(USData, data_spec, us_spec);

%% Preparing variables and constants

clc;
clearvars -except USData envelope_data data_spec us_spec;
close all;

n_probes  = size(USData,1);
n_samples = size(USData,2);
n_frames  = size(USData,3);

% signal constant
Fs = 50e6;
T = 1/Fs;
L = n_samples;
t_vector = ( (0:n_samples-1)*T ) * 1e6;

% ultrasound constant
v_sound = 1540;
index2distance_constant = (1e3 * v_sound) / (2*Fs);
d_vector = (0:n_samples-1) .* index2distance_constant;

% tgc filter increase the gain
tgc_dacdelay  = 2;    % in microsecond unit
tgc_dacslope  = 0.01; % in amplitude per microsecond unit
tgcFilt = tgc_simple(n_samples, tgc_dacdelay, tgc_dacslope, T);

% sigmoid filter to remove initial contact
% 1.7, 0.1
sig_halfpoint  = 1.7; % in microsecond unit
sig_rate       = 0.1;
sigFilt = sigmoid_simple(n_samples, sig_halfpoint, sig_rate, T);

% % gaussian window for each probes
% gauss_means = [ 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, ...
%                 4, 6, 9, 5, 5, 2, 5, 2.5, 5, 5, 5, 5, 5, 5, 5 ];
% gauss_sigma = 1.5;
% gaussFilt = zeros(n_probes, n_samples);
% for i=1:length(gauss_means)
%     gaussFilt(i,:) = normpdf(d_vector, gauss_means(i), gauss_sigma);
% end
            
% barkers code
path_barkerscode = '../data';
text_barkerscode = 'kenans_barkercode.txt';
fullpath_barkerscode = strcat(path_barkerscode, filesep, text_barkerscode);
barkerscode = readmatrix(fullpath_barkerscode);
%originally: length(S_corr) - n_samples - floor( 0.5 * length(barkerscode(:, 2)) ) +1;
sample_start = n_samples   - floor( 0.5 * length(barkerscode(:, 2)) ) +1;
%originally: length(S_corr) - floor(0.5 * length(barkerscode(:, 2)));
sample_end   = n_samples*2 - floor( 0.5 * length(barkerscode(:, 2)) );

% discrete wavelet transform
mra_level = 5;
mra_sel   = [2, 3, 4];

% constant for envelope and smoothing
start = 10;
step  = 5;
peak_alg = 'analytic';
envconstants = start + (0:step:(mra_level-1)*step);
start = 3;
step  = 3;
gausswindows =  start + (0:step:(mra_level-1)*step);
    
% Figure Preparation ------------------------------------------------------

% prepare window
figure1 = figure('Name', 'Wavelet Analysis');
figure1.WindowState = 'maximized';

subplot_rows  = 6;
subplot_cols  = 2;
subplot_index = reshape(1:(subplot_rows*subplot_cols), subplot_cols, subplot_rows)';

subplotidx_dwt = subplot_index(:,1)';
subplotidx_mmode = subplot_index(1:3,2);
subplotidx_amode = subplot_index(5,2);
subplotidx_gausswindow = subplot_index(6,2);

% axes for dwt signal
ax_dwt = {};
freq_list = ( 0.5*Fs ./ [1 2 4 6 8 16]) .* 1e-6; % in MHz
for mra_idx = 1:mra_level
    ax_dwt{mra_idx} = subplot(subplot_rows, subplot_cols, subplotidx_dwt(mra_idx), 'Parent', figure1);
    titlestr = strcat('$\tilde{D}$', num2str(mra_idx), ' (',  num2str(freq_list(mra_idx+1)), '-',  num2str(freq_list(mra_idx)) ,' MHz)');
    title(ax_dwt{mra_idx}, titlestr, 'Interpreter', 'latex');
    axis(ax_dwt{mra_idx}, 'tight');
    ax_dwt{mra_idx}.XGrid = 'on';
    hold(ax_dwt{mra_idx}, 'on');
end
ax_dwt{mra_idx+1} = subplot(subplot_rows, subplot_cols, subplotidx_dwt(end), 'Parent', figure1);
title(ax_dwt{mra_idx+1}, 'Low Frequency Component', 'Interpreter', 'latex');
axis(ax_dwt{mra_idx+1}, 'tight');
xlabel(ax_dwt{mra_idx+1}, 'Distance (mm)', 'Interpreter', 'latex');
ax_dwt{mra_idx+1}.XGrid = 'on';
hold(ax_dwt{mra_idx+1}, 'on');

% axes for mmode
ax_mmode = subplot(subplot_rows, subplot_cols, subplotidx_mmode, 'Parent', figure1);
title(ax_mmode, 'M-mode image', 'Interpreter', 'latex');
axis(ax_mmode, 'tight');
ax_mmode.XGrid = 'on';
hold(ax_mmode, 'on');

% axes for ammode
ax_amode = subplot(subplot_rows, subplot_cols, subplotidx_amode, 'Parent', figure1);
title(ax_amode, 'Adaptive Gaussian Windowing with Bayesian Inference', 'Interpreter', 'latex');
axis(ax_amode, 'tight');
ax_amode.XGrid = 'on';
hold(ax_amode, 'on');

% axes for window
ax_gausswindow = subplot(subplot_rows, subplot_cols, subplotidx_gausswindow, 'Parent', figure1);
axis(ax_gausswindow, 'tight');
xlabel(ax_gausswindow, 'Distance (mm)', 'Interpreter', 'latex');
ax_gausswindow.XGrid = 'on';
hold(ax_gausswindow, 'on');

% Start loop --------------------------------------------------------------

% flag for recording the plot
recordplot = false;

% data interest
probe_to_show  = 18;
frames_to_show = 50:350;

% if we specifiy record, prepare the writer object
if (recordplot)
    writerObj = VideoWriter('D:/Videos/plot.avi');
    writerObj.FrameRate = 30;
    open(writerObj);
end

% show m-mode first
display_mmode(ax_mmode, probe_to_show, envelope_data, data_spec, d_vector);

for current_frame=frames_to_show
     
    % obtain data
    S = USData(probe_to_show,:,current_frame);    
    
% Signal Processing -------------------------------------------------------

    % filter with TGC and sigmoid
    S_tgc       = S .* tgcFilt .* sigFilt;
    % correlate with barker code
    [S_corr, ~] = xcorr(S_tgc', barkerscode(:, 2));
    S_barker    = S_corr(sample_start:sample_end)';

% Wavelet -----------------------------------------------------------------

    % discrete wavelet transform
    % fk8, coif1, sym4, db5
    mra = modwtmra( modwt(S_barker, 'db5', mra_level) );
    
    % a variable to capture peak distribution in each mra level
    peak_dists = [];
    
    % loop trought all mra level
    delete(findobj('Tag', 'plot_dwt'));
    for mra_idx = 1:mra_level
        
        % get the current level of mra and subplot
        current_axes = ax_dwt{mra_idx};
        current_mra  = mra(mra_idx,:);
        
        % display the current level of mra
        yyaxis(current_axes, 'left');
        plot(current_axes, d_vector, mra(mra_idx,:), '-g', 'Tag', 'plot_dwt');
        axis(current_axes, 'tight');
        
        % i only take mra level 2-4
        if( find(mra_sel==mra_idx) )
            
            % envelope the signal
            current_mra_env  = smoothdata( ...
                                    envelope( current_mra, ...
                                    envconstants(mra_idx), peak_alg ), ...
                                    'gaussian', gausswindows(mra_idx));
            current_mra_norm = current_mra_env ./ max(current_mra_env);
            plot(current_axes, d_vector, current_mra_env, '-r','Tag', 'plot_dwt');
            
            % find peaks
            [~, loc, w, p] =  findpeaks( current_mra_norm, ...
                                           'NPeaks', 10, ...
                                           'MinPeakProminence', 0.3, ...
                                           'SortStr', 'descend');
            loc_mm   = loc*index2distance_constant;
            for i=1:length(loc_mm)
                xline(current_axes, loc_mm(i), '-b', 'LineWidth', 2, 'Tag', 'plot_dwt');
            end
            
            % fit the peaks to gaussian
            if(length(loc_mm)>1)
                if(true)
                    
                    if(false)
                        w_factor = [1 2 3 4 5];
                        w_sel    = flip(w_factor(1:length(loc_mm)));
                        new_loc_mm = [];
                        for i=1:length(w_sel)
                            for j=1:w_sel(i)
                                new_loc_mm = [new_loc_mm, loc_mm(i)];
                            end
                        end
                        [mu_peak, sigma_peak] = normfit(new_loc_mm);
                        
                    else
                        w_norm = w ./ max(w);
                        % w_factor = floor( 100* current_mra_norm(loc) .* (1 ./ w_norm));
                        w_factor = floor( current_mra_norm(loc) .* w);
                        new_loc_mm = [];
                        for i=1:length(w_factor)
                            for j=1:w_factor(i)
                                new_loc_mm = [new_loc_mm, loc_mm(i)];
                            end
                        end
                        [mu_peak, sigma_peak] = normfit(new_loc_mm);
                    end
                    
                else
                    [mu_peak, sigma_peak] = normfit(loc_mm);
                end
            else
                mu_peak = loc_mm;
                sigma_peak = 1; % in mm unit
            end
            
            if(~isempty(loc_mm))
                yyaxis(current_axes, 'right');
                plot(current_axes, d_vector, normpdf(d_vector, mu_peak, sigma_peak), '-c', 'Tag', 'plot_dwt');
                
                % store the peak distributions parameters
                peak_dists = [peak_dists; mu_peak, sigma_peak];
            end
            
        end
        
    end
    current_axes = ax_dwt{mra_idx+1};
    plot(current_axes, d_vector, mra(mra_idx+1,:), '-g', 'Tag', 'plot_dwt');
    axis(current_axes, 'tight');
    
% Displaying M-mode -------------------------------------------------------

    display_timestamp_mmode(ax_mmode, current_frame);
    drawnow;
    
% Displaying Bayesian Inference -------------------------------------------

    delete(findobj('Tag', 'plot_amode'));
    yyaxis(ax_amode, 'left');
    plot(ax_amode, d_vector, S_barker, '-g', 'Tag', 'plot_amode');
    
    postMean = peak_dists(1,1);
    postSD   = peak_dists(1,2);
    for peak_dists_idx = 2:size(peak_dists,1)        
        [postMean, postSD] = bayes_inference( postMean, postSD, ...
                                              peak_dists(peak_dists_idx, 1), ...
                                              peak_dists(peak_dists_idx, 2) );
    end

    yyaxis(ax_amode, 'right');
    peak_bayesian = normpdf(d_vector, postMean, postSD);
    plot(ax_amode, d_vector, peak_bayesian, '-c', 'Tag', 'plot_amode');
    
% Displaying Gauss Window (?) ---------------------------------------------

    delete(findobj('Tag', 'plot_gausswindow'));
    plot(ax_gausswindow, d_vector, S_barker .* peak_bayesian, '-g', 'Tag', 'plot_gausswindow');
    titlestr = strcat('Final Result (Frame \#', num2str(current_frame), ')');
    title(ax_gausswindow, titlestr, 'Interpreter', 'latex');
    
    
	% if user specify recordplot then grab the frame and write it to the
    % video object
    if(recordplot)
        frame = getframe(figure1);
        writeVideo(writerObj, frame);
    end
    
    % if user press any key, break
    isKeyPressed = ~isempty(get(figure1,'CurrentCharacter'));
    if isKeyPressed
        break
    end
    
end

% don't forget to close the writer object
if(recordplot)
    close(writerObj);
end
