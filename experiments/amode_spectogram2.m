clc; clear; close all;

% add path for reading signal
addpath('functions');
addpath('functions/displays');
addpath('functions/signal');
addpath(genpath('functions/external'));

% get us data
dname = uigetdir(pwd);
[USData, ~, ~] = readTIFF_USsignal(dname, 30, 1500);

%% Preparing variables and constants

clc;
clearvars -except USData;
close all;

n_probes  = size(USData,1);
n_samples = size(USData,2);
n_frame   = size(USData,3);

% measurent constant
Fs = 50e6;
T = 1/Fs;
L = n_samples;
t_vector = ( (0:n_samples-1)*T ) * 1e6;

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

bpFilt = designfilt('bandpassiir', 'FilterOrder', 20, ...
         'HalfPowerFrequency1', 0.3e7, 'HalfPowerFrequency2', 0.9e7, ...
         'SampleRate', Fs);
     
% barkers code
path_barkerscode = '../data';
text_barkerscode = 'kenans_barkercode.txt';
fullpath_barkerscode = strcat(path_barkerscode, filesep, text_barkerscode);
barkerscode = readmatrix(fullpath_barkerscode);


% Monitor Signal ----------------------------------------------------------

% prepare window
figure1 = figure('Name', 'Wavelet Analysis');
figure1.WindowState = 'maximized';

% data interest
probe_to_show = 29;
frames_to_show = 101;

% flag for recording the plot
recordplot = false;

% if we specifiy record, prepare the writer object
if (recordplot)
    writerObj = VideoWriter('D:/Videos/plot.avi');
    writerObj.FrameRate = 30;
    open(writerObj);
end

% start loop
for frame_to_show=frames_to_show
     
    % obtain data
    S = USData(probe_to_show,:,frame_to_show);
    
% Signal Processing -------------------------------------------------------

    % filter with TGC
    S_tgc      = S .* tgcFilt;
    % filter with sigmoid
    S_sig      = S_tgc .* sigFilt;
    % correlate with barker code
    [S_corr, lags] = xcorr(S_sig', barkerscode(:, 2));
    S_corr = S_corr';
    sample_start = length(S_corr) - ...
                   n_samples - ...
                   floor( 0.5 * length(barkerscode(:, 2)) ) +1;
    sample_end   = length(S_corr) - ...
                   floor(0.5 * length(barkerscode(:, 2)));
    S_barker     = S_corr(sample_start:sample_end);
    
    % filter with bandpass filter
    S_bp       = filtfilt(bpFilt, S_barker);
    S_env      = smoothdata( envelope(S_bp, 20, 'analytic'), 'gaussian', 20);

% Wavelet -----------------------------------------------------------------
    S_final = S_barker;

    % continous wavelet transform
    [cfs, frq] = cwt(S_final, Fs, 'bump', 'VoicesPerOctave', 32, 'FrequencyLimits', [Fs/16 Fs/4]);
    subplotcol_cwt = 2;

    % discrete wavelet transform
    level = 5;
    mra = modwtmra( modwt(S_final, 'fk8', level) );
    subplotcol_dwt  = 1;
    subplotrow_dwt  = size(mra,1);

    % let's make (dwtlvl_toshow x 3) subplot
    subplotrow = subplotrow_dwt;
    subplotcol = subplotcol_dwt + subplotcol_cwt;

    subplot_index     = reshape(1:(subplotrow*subplotcol), subplotcol, subplotrow)';
    subplotidx_dwt    = subplot_index(:,1)';
    subplotidx_cwt    = subplot_index(1:end-2, 2:3);
    subplotidx_env    = subplot_index(end-1, 2:3);
    subplotidx_mramod = subplot_index(end, 2:3);

    clf;

    % plot dwt ------------------------------------------------------------
    mra_idx = 1;
    mra_env = [];
    mra_env_norm = [];
    
    start_envfl = 10;
    step_envfl = 10;
    envfl =  start_envfl + (0:step_envfl:(level-1)*step_envfl);
    
    start_smoothgauss = 10;
    step_smoothgaus   = 5;
    smoothgauss       =  start_smoothgauss + (0:step_smoothgaus:(level-1)*step_smoothgaus);
    
    % the last row of mra is the lowfreq (approx) coeff, we will not
    % using it, only displaying it here. we need only the highfreq (details)
    for current_subplotidx_dwt = subplotidx_dwt(1:end-1)
        
        mra_env  = [ mra_env; ...
                     smoothdata( envelope(mra(mra_idx,:), envfl(mra_idx), 'analytic'), 'gaussian', smoothgauss(mra_idx)) ];
        % mra_env  = [ mra_env; ...
        %              envelope(mra(mra_idx,:), mra_env_np(mra_idx), 'peak') ];       
        mra_env_norm = [ mra_env_norm; ...
                         mra_env(mra_idx,:) ./ max(mra_env(mra_idx,:)) ];
                     
        axes = subplot(subplotrow, subplotcol, current_subplotidx_dwt, 'Parent', figure1);
        plot(axes, d_vector, mra(mra_idx,:), '-g'); hold(axes, 'on');
        plot(axes, d_vector, mra_env(mra_idx,:), '-r', 'LineWidth', 1.5);
        
        titlestr = strcat('$\tilde{D}$', num2str(mra_idx));
        title(axes, titlestr, 'Interpreter', 'latex');
        axis(axes, 'tight');

        mra_idx = mra_idx+1;
        
    end
    axes = subplot(subplotrow, subplotcol, subplotidx_dwt(end), 'Parent', figure1);
    plot(axes, d_vector, mra(mra_idx,:), '-g'); hold(axes, 'on');
    title(axes, 'Low Frequency Component', 'Interpreter', 'latex');
    axis(axes, 'tight');
    xlabel(axes, 'Distance (mm)', 'Interpreter', 'latex')
    % ---------------------------------------------------------------------
    
    
    % plot raw against normal envelope ------------------------------------
    %{
    axes = subplot(subplotrow, subplotcol, subplotidx_env(:), 'Parent', figure1);
    yyaxis(axes, 'left');
    plot(axes, d_vector, S_barker, '-g'); hold(axes, 'on');
    yyaxis(axes, 'right');
    plot(axes, d_vector, S_env, '-r', 'LineWidth', 1.5);
    axis(axes, 'tight');
    grid(axes, 'on');
    title('Processed Signal against Envelope', 'Interpreter', 'latex');
    %}
    % ---------------------------------------------------------------------
    
    
    % plot raw against dwt ------------------------------------------------
    mra_mod = ones(1, length(mra_env_norm));
    lvl_sel = [4, 5];
    for i=lvl_sel
        mra_mod = mra_mod .* mra_env_norm(i,:);
    end
    axes = subplot(subplotrow, subplotcol, subplotidx_mramod(:), 'Parent', figure1);
    yyaxis(axes, 'left');
    plot(axes, d_vector, S_barker, '-g');
    yyaxis(axes, 'right');
    plot(axes, d_vector, mra_mod, '-r', 'LineWidth', 1.5);
    axis(axes, 'tight');
    grid(axes, 'on');
    titlestr = strcat('Processed Signal against selected normalized $\tilde{D}$'); 
    title(titlestr, 'Interpreter', 'latex');
    xlabel(axes, "Distance (mm)", 'Interpreter', 'latex');
    % ---------------------------------------------------------------------
    

    % plot cwt ------------------------------------------------------------
    axes = subplot(subplotrow, subplotcol, subplotidx_cwt(:), 'Parent', figure1);
    surface(axes, d_vector, frq*1e-6, abs(cfs));
    shading(axes, 'flat');
    axis(axes, 'tight');
    grid(axes, 'on');
    view(axes, [0 90]);
    titlestr = strcat('CWT, Probe:\,', num2str(probe_to_show), ', Frame:\,', num2str(frame_to_show));
    title(axes, titlestr, 'Interpreter', 'latex');
    ylabel(axes, "MHz (Log scale)", 'Interpreter', 'latex');
    set(axes,"yscale","log");
    drawnow
    % ---------------------------------------------------------------------
    
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
