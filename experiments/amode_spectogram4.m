clc; clear; close all;

% add path for reading signal
addpath('../functions');
addpath('../functions/displays');
addpath('../functions/signal');
addpath(genpath('../functions/external'));

% get us data
dname = uigetdir(pwd);
[USData, ~, ~] = readTIFF_USsignal(dname, 30, 1500);

%% Preparing variables and constants

clc;
clearvars -except USData;
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
sig_halfpoint  = 1.7; % in microsecond unit
sig_rate       = 0.1;
sigFilt = sigmoid_simple(n_samples, sig_halfpoint, sig_rate, T);
     
% barkers code
path_barkerscode = 'data';
text_barkerscode = 'kenans_barkercode.txt';
fullpath_barkerscode = strcat(path_barkerscode, filesep, text_barkerscode);
barkerscode = readmatrix(fullpath_barkerscode);
%originally: length(S_corr) - n_samples - floor( 0.5 * length(barkerscode(:, 2)) ) +1;
sample_start = n_samples   - floor( 0.5 * length(barkerscode(:, 2)) ) +1;
%originally: length(S_corr) - floor(0.5 * length(barkerscode(:, 2)));
sample_end   = n_samples*2 - floor( 0.5 * length(barkerscode(:, 2)) );

% discrete wavelet transform
mra_level = 5;

% constant for envelope and smoothing
start = 10;
step  = 10;
envconstants = start + (0:step:(mra_level-1)*step);
start = 10;
step  = 5;
gausswindows =  start + (0:step:(mra_level-1)*step);

% constant for kalman filter
flag_xk_init = true;

dt = T * 1e6;           % let's use microsecond (mu) as unit of time for kalman
x_stdFk_init = 0.1;     % prediction matrix's position std (in mm unit)
v_stdFk_init = 0.002;   % prediction matrix's velocity std
x_stdQk_init = 0.125;     % prediction noise matrix's position std (in mm unit)
v_stdQk_init = 0.05;    % prediction noise matrix's velocity std (in mm/mus unit)
x_stdRk_init = 2.5;     % in mm unit

F_k = [1 dt; 0 1];           % prediction matrix 
P_k = [x_stdFk_init^2, 0; ...
       0 v_stdFk_init^2];    % covariance matrix (for prediction step)
Q_k = [x_stdQk_init^2, 0; ...
       0, v_stdQk_init^2];    % covariance matrix for process noise
H   = [1 0];                  % measurement matrix
R_k = x_stdRk_init^2;         % variance for measurement noise (we dont need 
                              % cov matrix since we are only measuring the position)

% Figure Preparation ------------------------------------------------------
    
% flag for recording the plot
recordplot = false;

% data interest
probe_to_show  = 24;
frames_to_show = 50:350;

% variable to store peak locations;
allpeaks_loc = [];
all_xk       = [];

% prepare window
figure1 = figure('Name', 'Wavelet Analysis');
figure1.WindowState = 'maximized';

% axes for signal
axes1     = subplot(3, 1, 1, 'Parent', figure1);
titlestr = strcat('Processed Signal against selected normalized $\tilde{D}$'); 
title(titlestr, 'Interpreter', 'latex');
xlabel(axes1, "Distance (mm)", 'Interpreter', 'latex');
grid(axes1, 'on');

% axes for peak detection over time
axes2     = subplot(3, 1, [2 3], 'Parent', figure1);
title('Detected peak troughout time', 'Interpreter', 'latex');
xlabel(axes2, "Frame", 'Interpreter', 'latex');
ylabel(axes2, "Distance (mm)", 'Interpreter', 'latex');
grid(axes2, 'on');
xlim([frames_to_show(1) frames_to_show(end)]);
ylim([0 20]);
hold(axes2, 'on');

% if we specifiy record, prepare the writer object
if (recordplot)
    writerObj = VideoWriter('D:/Videos/plot.avi');
    writerObj.FrameRate = 30;
    open(writerObj);
end

% Start loop --------------------------------------------------------------
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
    mra = modwtmra( modwt(S_barker, 'fk8', mra_level) );
    
    mra_mod = ones(1, length(S_barker));
    mra_sel = [2, 3, 4];
    for current_mra = mra_sel
        
        current_mra_env  = smoothdata( envelope( mra(current_mra,:), envconstants(current_mra), 'analytic' ), 'gaussian', gausswindows(current_mra));
        current_mra_norm = current_mra_env ./ max(current_mra_env);
        
        mra_mod = mra_mod .* current_mra_norm;
    end
    
% Peak Detection ----------------------------------------------------------
    
    [~, loc] =  findpeaks(mra_mod, 'NPeaks', 1, 'SortStr', 'descend');
    loc_mm   = loc*index2distance_constant;
    
    % get all loc_mm over time for display purposes
    allpeaks_loc = [allpeaks_loc, loc_mm];
    
% Kalman Filter -----------------------------------------------------------

    % init xk only happen once
    if (flag_xk_init)
        x_k = [loc_mm; 0.001];
        flag_xk_init = false;
    end

    % process update
    xhat_k = F_k * x_k;
    Phat_k = F_k * P_k * F_k' + Q_k;
    
    % kalman gain
    K = P_k * H' * inv(H*P_k*H' + R_k);
    
    % measurement update
    z_k = loc_mm;
    x_k = xhat_k + K*(z_k - H*xhat_k);
    P_k = Phat_k - K*H*Phat_k;
    
    % get all x_k over time for display purposes, only position
    all_xk = [all_xk, x_k(1)];
    
% Displaying --------------------------------------------------------------
    
    delete(findobj('Tag', 'plot_signal'));
    delete(findobj('Tag', 'plot_peak'));
    yyaxis(axes1, 'left');
    plot(axes1, d_vector, S_barker, '-g', 'Tag', 'plot_signal');
    yyaxis(axes1, 'right');
    plot(axes1, d_vector, mra_mod, '-r', 'LineWidth', 1.5, 'Tag', 'plot_signal');
    hold(axes1, 'on');
    xline(axes1, loc_mm, '-b', {'Possible Bone'}, 'LineWidth', 2, 'Tag', 'plot_peak'); 
    axis(axes1, 'tight');
    
    delete(findobj('Tag', 'plot_peakinframe'));
    plot(axes2, [frames_to_show(1):current_frame], allpeaks_loc, '-or', 'Tag', 'plot_peakinframe');
    hold(axes2, 'on');
    plot(axes2, [frames_to_show(1):current_frame], all_xk, '-ob', 'Tag', 'plot_peakinframe');
    
    drawnow;
    
    
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
