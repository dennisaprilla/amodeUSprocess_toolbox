clc; clear; close all;

% add path for reading signal
addpath('../functions');
addpath('../functions/signal');
addpath(genpath('../functions/displays'));
addpath(genpath('../functions/external'));

% get us data
dname = uigetdir(pwd);
[USData, ~, ~] = readTIFF_USsignal(dname, 30, 2500);

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
mra_sel   = [2, 3, 4, 5];

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
x_stdFk_init = 0.100;   % prediction matrix's position std (in mm unit)
v_stdFk_init = 0.002;   % prediction matrix's velocity std
x_stdQk_init = 0.100;   % prediction noise matrix's position std (in mm unit)
v_stdQk_init = 0.050;   % prediction noise matrix's velocity std (in mm/mus unit)
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
frames_to_show = 1:n_frames;

% variable to store peak locations;
allpeaks_measurement_mean = [];
allpeaks_measurement_std  = [];
allpeaks_kalman_mean      = [];
allpeaks_kalman_std       = [];

% prepare window
figure1 = figure('Name', 'Wavelet Analysis');
figure1.WindowState = 'maximized';

% axes for signal
axes1     = subplot(3, 1, 1, 'Parent', figure1);
titlestr = strcat('Processed Signal with DWT-Bayesian Probability (Probe \#', num2str(probe_to_show), ')');
title(titlestr, 'Interpreter', 'latex');
xlabel(axes1, "Distance (mm)", 'Interpreter', 'latex');
grid(axes1, 'on');

% axes for peak detection over time
axes2     = subplot(3, 1, [2 3], 'Parent', figure1);
title('Detected peak trough time', 'Interpreter', 'latex');
xlabel(axes2, "Frame", 'Interpreter', 'latex');
ylabel(axes2, "Distance (mm)", 'Interpreter', 'latex');
grid(axes2, 'on');
xlim(axes2, [frames_to_show(1) frames_to_show(end)]);
ylim(axes2, [0 20]);
hold(axes2, 'on');

flag_legend = true;

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
    
    [peak_bayes, peak_dists] = dwt_bayesian_peak(mra, mra_sel, true, index2distance_constant);
    peak_mean = peak_bayes(1);
    peak_std  = peak_bayes(2);
    
% Kalman Filter -----------------------------------------------------------

    % init xk only happen once
    if (flag_xk_init)
        x_k = [peak_mean; 0.001];
        flag_xk_init = false;
    end
    R_k = peak_std; 

    % process update
    xhat_k = F_k * x_k;
    Phat_k = F_k * P_k * F_k' + Q_k;
    
    % kalman gain
    K = P_k * H' * inv(H*P_k*H' + R_k);
    
    % measurement update
    z_k = peak_mean;
    x_k = xhat_k + K*(z_k - H*xhat_k);
    P_k = Phat_k - K*H*Phat_k;
    
% Obtaining data (display purposes) ---------------------------------------
    
    % get peak estimation from dwt bayesian peak
    allpeaks_measurement_mean = [allpeaks_measurement_mean, peak_mean];
    % get peak std from dwt bayesian peak
    allpeaks_measurement_std  = [allpeaks_measurement_std, peak_std];
    % get peak estimation from kalman
    allpeaks_kalman_mean      = [allpeaks_kalman_mean, x_k(1)]; 
    % get peak std from kalman
    allpeaks_kalman_std       = [allpeaks_kalman_std, sqrt(P_k(1,1))];    
    
% Displaying --------------------------------------------------------------
    
    delete(findobj('Tag', 'plot_signal'));
    delete(findobj('Tag', 'plot_peak'));
    yyaxis(axes1, 'left');
    plot(axes1, d_vector, S_barker, '-g', 'Tag', 'plot_signal');
    yyaxis(axes1, 'right');
    plot(axes1, d_vector, normpdf(d_vector, peak_mean, peak_std), '-c', 'Tag', 'plot_signal');
    axis(axes1, 'tight');
    
    delete(findobj('Tag', 'plot_peakinframe'));
    plot(axes2, [frames_to_show(1):current_frame], allpeaks_measurement_mean, '-or', 'Tag', 'plot_peakinframe');
    hold(axes2, 'on');
    plot(axes2, [frames_to_show(1):current_frame], allpeaks_kalman_mean, '-ob', 'Tag', 'plot_peakinframe');
    % e = errorbar(axes2, [frames_to_show(1):current_frame], allpeaks_kalman_mean, allpeaks_measurement_std, '-ob', 'Tag', 'plot_peakinframe');
    % e.CapSize = 0;
    
    drawnow;
    
% Something else ----------------------------------------------------------
    
	% if user specify recordplot then grab the frame and write it
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

%%  prepare window
close all;

figure2 = figure('Name', 'Wavelet Analysis');
shadedErrorBar([frames_to_show(1):current_frame], allpeaks_measurement_mean, allpeaks_measurement_std, 'lineProps',{'-r','LineWidth', 1.5});
titlestr = strcat('Peak Detection, DWT-Bayesian and After Kalman (Probe \#', num2str(probe_to_show), ')');
title(titlestr, 'Interpreter', 'latex');
xlabel('Frame');
ylabel('Depth (mm)');
hold on;
grid on;
shadedErrorBar([frames_to_show(1):current_frame], allpeaks_kalman_mean, allpeaks_kalman_std, 'lineProps',{'-b','LineWidth', 1.5});
ylim([0 20]);
legend('DWT Bayesian Peak', 'After Kalman Filter');









