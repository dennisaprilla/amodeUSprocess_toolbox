clc; clear; close all;

% add path for reading signal
addpath('../functions');
addpath('../functions/displays');
addpath(genpath('../functions/external'));

% get us data
dname = uigetdir(pwd);
[USData, ~, ~] = readTIFF_USsignal(dname, 30, 1500);

n_probes = size(USData,1);
n_samples = size(USData,2);
n_frame = size(USData,3);

probe_to_show = 18;
sample_to_show = 1:n_samples;
frame_to_show = 250;

%% 1) RAW Signal and FFT analysis

Fs = 50e6;
T = 1/Fs;
L = n_samples;
t = ( (0:n_samples-1)*T ) * 1e6;

S = USData(probe_to_show,:,frame_to_show);

Y = fft(S);
P2 = abs(Y/L);
P1 = P2(1:L/2+1);
P1(2:end-1) = 2*P1(2:end-1);

f = Fs*(0:(L/2))/L;

figure('Name', 'Raw Signal');
subplot(2,1,1);
plot(t, S, '-', 'Color', 'g', 'Tag', 'plot_raw1');
title(sprintf('Raw Signal (probe=%d, frame=%d)', probe_to_show, frame_to_show));
xlabel("Time (\mus)");
ylabel("Amplitude");
grid on;
subplot(2,1,2);
plot( f*1e-6, P1);
title("Single-Sided Amplitude Spectrum of S(t)");
xlabel("Frequency (MHz)");
ylabel("|P1(f)|");
grid on;

%% 2) TGC on Raw Signal and FFT analysis

% create tgc filter
tgc_nsamples  = n_samples;
tgc_dacdelay  = 2; % in microsecond unit
tgc_dacslope  = 0.02; % in amplitude per microsecond unit

tgc_dacdelay_samplenum     = (tgc_dacdelay * 1e-6) / T;
tgc_dacslope_ratepersample = tgc_dacslope * T / 1e-6;
tgc_dacslope_x = tgc_dacslope_ratepersample * (1:tgc_nsamples-tgc_dacdelay_samplenum);

tgc_filter = ones(1, n_samples);
tgc_filter(tgc_dacdelay_samplenum+1:end) = tgc_filter(tgc_dacdelay_samplenum+1:end)+tgc_dacslope_x;

%{
figure;
subplot(2,1,1);
plot(t, tgc_filter, '-b', 'LineWidth', 2);
grid on;
ylim([0,5]);
xlabel('Time (\mus)');
ylabel('Amplitude Multiplicator');
%}

% apply tgc filter and do fft
S_tgc = S .* tgc_filter;

Y = fft(S_tgc);
P2 = abs(Y/L);
P1 = P2(1:L/2+1);
P1(2:end-1) = 2*P1(2:end-1);

f = Fs*(0:(L/2))/L;

% display
figure('Name', 'TGC Signal');
subplot(2,1,1);
plot(t, S_tgc, '-', 'Color', 'g', 'Tag', 'plot_raw1');
title('TGC');
xlabel("Time (\mus)");
ylabel("Amplitude");
grid on;
subplot(2,1,2);
plot(f,P1);
title("Single-Sided Amplitude Spectrum of S(t)");
xlabel("Frequency (Hz)");
ylabel("|P1(f)|");
grid on;


%% 3) Filtered Signal and FFT analysis

lpFilt = designfilt('bandpassiir', 'FilterOrder', 20, ...
         'HalfPowerFrequency1', 0.3e7, 'HalfPowerFrequency2', 0.9e7, ...
         'SampleRate', Fs);
     
S_filtered = filtfilt(lpFilt, S_tgc);

Y = fft(S_filtered);
P2 = abs(Y/L);
P1 = P2(1:L/2+1);
P1(2:end-1) = 2*P1(2:end-1);

f = Fs*(0:(L/2))/L;

figure('Name', 'Filtered Signal');
subplot(2,1,1);
plot(t, S_filtered, '-', 'Color', 'g', 'Tag', 'plot_filter');
title('Bandpass Filtered Signal');
xlabel("Time (\mus)");
ylabel("Amplitude");
grid on;
subplot(2,1,2);
plot(f,P1);
title("Single-Sided Amplitude Spectrum of S(t)");
xlabel("f (Hz)");
ylabel("|P1(f)|");
grid on;


%% Correlation with barker's Code

path_barkerscode = '../data';
text_barkerscode = 'kenans_barkercode.txt';
fullpath_barkerscode = strcat(path_barkerscode, filesep, text_barkerscode);
barkerscode = readmatrix(fullpath_barkerscode);

%{
figure;
subplot(2,1,1);
plot(barkerscode(:,1), barkerscode(:,2), '-b', 'LineWidth', 2);
title('Barker code of length 5');
grid on;
ylabel('Normalized Amplitude');
xlabel('Time (\mus)');
%}

[S_correlated, lags] = xcorr(S_filtered', barkerscode(:, 2));
S_correlated = S_correlated';

% 1) start from the end tip of barkercode entering the US signal
sample_start = length(S_correlated)- n_samples - length(barkerscode(:, 2)) +1;
sample_end = length(S_correlated) - length(barkerscode(:, 2));
S_correlated1 = S_correlated(sample_start:sample_end);
% 2) start from halfway of barkercode entering the US signal
sample_start = length(S_correlated)- n_samples - floor( 0.5 * length(barkerscode(:, 2)) ) +1;
sample_end = length(S_correlated) - floor(0.5 * length(barkerscode(:, 2)));
S_correlated2 = S_correlated(sample_start:sample_end);
% 3) start from the entire barkercode entering the US signal
S_correlated3 = S_correlated( (end-n_samples)+1: end);

% it seems (2) is more logical
figure('Name', 'Correlation with barkers code');
subplot(3,1,1);
plot(t, S_correlated1, '-', 'Color', 'g', 'Tag', 'plot_filter'); hold on;
plot(t, S_filtered, '-', 'Color', 'b', 'Tag', 'plot_filter');
xlabel("Time (\mus)");
ylabel("Amplitude");
legend('correlated1', 'raw');
title('Indexing start from the end tip of barkers code entering the US signal');
grid on;
subplot(3,1,2);
plot(t, S_correlated2, '-', 'Color', 'g', 'Tag', 'plot_filter'); hold on;
plot(t, S_filtered, '-', 'Color', 'b', 'Tag', 'plot_filter');
xlabel("Time (\mus)");
ylabel("Amplitude");
legend('correlated2', 'raw');
title('Indexing start from halfway of barkers code entering the US signal');
grid on;
subplot(3,1,3);
plot(t, S_correlated3, '-', 'Color', 'g', 'Tag', 'plot_filter'); hold on;
plot(t, S_filtered, '-', 'Color', 'b', 'Tag', 'plot_filter');
xlabel("Time (\mus)");
ylabel("Amplitude");
legend('correlated3', 'raw');
title('Indexing start from the entire barkers code entering the US signal');
grid on;



%% Envelope and Post processing

S_env  = envelope(S_correlated2, 50, 'analytic');
S_env2 = smoothdata(S_env, 'gaussian', 20);

figure('Name', 'Enveloping the signal');
yyaxis left;
plot(t, S_correlated2, '-', 'Color', 'g', 'Tag', 'plot_filter');
xlabel('Time (\mus)');
ylabel('Signal Amplitude');
y_limit = get(gca, 'YLim');

yyaxis right
plot(t, S_env2, '-', 'Color', 'r', 'Tag', 'plot_envelop', 'LineWidth',1.5); hold on;
ylabel('Envelop Amplitude');
ylim(y_limit);
grid on;

legend('Processed Signal', 'Envelop');
title('Envelope (Hilbert Transform)');

%% Spectrogram and Mask
% create spectrogram

%{

window_length = pow2(5);
window = hamming(window_length, 'periodic');
noverlap = window_length/2;
fs = 50e6;

% s is a matrix with column as discrete time and row as discrete ft
% check output argument in matlab documentation for details
[spectro_matrix, spectro_f, spectro_t, spectro_pd] = spectrogram(S_correlated2, window, noverlap, [], fs, 'power', 'yaxis');
% convert STFT coeff to arbitrary unit of amplitude
spectro_ampmod = log10(abs(spectro_matrix));
% convert power to desibel
spectro_db      = 10*log10(spectro_pd+eps);

n_dft = length(spectro_f);
n_discretetime = length(spectro_t);

% ----------------------------------------------------------------------- %
% create spectrogram mask and applying to spectrogram

% create sigmoid mask
sig_datasample = 1:n_samples;
sig_halfpoint  = 100;
sig_rate       = 0.1;
sig_func       = 1./(1 + exp(-sig_rate.*(sig_datasample-sig_halfpoint)));
% apply sigmoid mask to our envelop (we don't want to be bothered by the
% big amplitude coming from US probe contact)
S_env2_clamped = S_env2 .* sig_func;

%{
figure;
subplot(3,1,1);
plot(t, S_env2, '-r', 'LineWidth', 2); grid on;
title('Envelop');
xlabel('Time (\mus)');
ylabel('Amplitude');
subplot(3,1,2);
plot(t, sig_func, '-g', 'LineWidth', 2); grid on;
title('Sigmoid Function (halfpoint at 2 \mus)');
xlabel('Time (\mus)');
ylabel('Normalized Amplitude');
subplot(3,1,3);
plot(t, S_env2_clamped, '-b', 'LineWidth', 2); grid on;
title('Envelop * Sigmoid');
xlabel('Time (\mus)');
ylabel('Amplitude');
%}

% create dicrete mask from envelope (it is discrete because the specrogram
% is discrete)
window_index = buffer(1:n_samples, window_length, noverlap);
window_index = window_index(:, 2:end-1); % (!) this indexing is so arbitrary, you need to be careful
S_env2_discrete = zeros(1, n_discretetime);
for i=1:size(window_index,2)
    current_window = window_index(:,i)';
    S_env2_discrete(i) = mean(S_env2_clamped(current_window));
end
S_env2_discretenorm = S_env2_discrete ./ max(S_env2_discrete, [], 'all');

spectro_ampmasked = spectro_ampmod .* repmat(S_env2_discretenorm, size(spectro_ampmod,1), 1);

% ----------------------------------------------------------------------- %

figure('Name', 'Spectogram');

% final signal
subplot(3,1,1);
yyaxis left;
plot(t, S_correlated2, '-', 'Color', 'g', 'Tag', 'plot_filter');
xlabel('Time');
ylabel('Signal Amplitude');
y_limit = get(gca, 'YLim');
yyaxis right
plot(t, S_env2_clamped, '-', 'Color', 'b', 'Tag', 'plot_envelop', 'LineWidth',1.5); hold on;
legend('Processed Signal', 'Envelop*Sigmoid');
ylabel('Envelope Amplitude');
ylim(y_limit);
grid on;
title("Processed Signal with Envelope");

% spectrogram arbitrary amplitude without mask
subplot(3,1,2);
surf(spectro_t, spectro_f, spectro_ampmod,'EdgeColor','none');
title("Spectrogram Amplitude: log10(|STFT_{coef}|), window=Hamming(32), noverlap=16");
xlabel('Discrete Time (\mus)');
ylabel('Frequency Bin (Hz)');
view([0,90]);
axis([spectro_t(1) spectro_t(end) spectro_f(1) spectro_f(end)]);
c = colorbar;
c.Label.String = "Amplitude";

% spectrogram arbitrary amplitude without mask
subplot(3,1,3);
surf(spectro_t, spectro_f, spectro_ampmasked,'EdgeColor','none');
title("Masked Spectrogram");
xlabel('Discrete Time (\mus)');
ylabel('Frequency Bin (Hz)');
view([0,90]);
axis([spectro_t(1) spectro_t(end) spectro_f(1) spectro_f(end)]);
c = colorbar;
c.Label.String = "Amplitude";

%}


%% Mel Spectogram?

%{

n_bands = 12;
f_range = [fs/14 fs/2];

[melspectro_matrix, melspectro_f, melspectro_t] = melSpectrogram(S_correlated2', fs, 'Window', window, 'OverlapLength', noverlap, 'NumBands', n_bands, 'FrequencyRange', f_range);
 % Convert to dB for plotting
melspectro_matrix = 10*log10(melspectro_matrix+eps);

% create masked melspectrogram
min_db = min(melspectro_matrix, [], 'all');
melspectro_masked = (melspectro_matrix+abs(min_db)) .* repmat(S_env2_discretenorm, size(melspectro_matrix,1), 1);

%-------------------------------------------------------------------------%

figure('Name', 'Mel Spectrogram');

% final signal
subplot(3,1,1);
yyaxis left;
plot(t, S_correlated2, '-', 'Color', 'g', 'Tag', 'plot_filter');
xlabel('Time');
ylabel('Signal Amplitude');
y_limit = get(gca, 'YLim');
yyaxis right
plot(t, S_env2_clamped, '-', 'Color', 'r', 'Tag', 'plot_envelop', 'LineWidth',1.5); hold on;
legend('Processed Signal', 'Envelop*Sigmoid');
ylabel('Envelop Amplitude');
ylim(y_limit);
grid on;
title("Processed Signal with Envelope");

% regular mel spectrogram
subplot(3,1,2);
surf(melspectro_t, melspectro_f, melspectro_matrix,'EdgeColor','none');
title(sprintf("Mel Spectrogram (n bands=%d, f range=[%.2f %.2f]MHz)", n_bands, f_range/1e6));
xlabel('Time (\mus)');
ylabel('Frequency Bin (MHz)');
view([0,90]);
axis([melspectro_t(1) melspectro_t(end) melspectro_f(1) melspectro_f(end)]);
c = colorbar;
c.Label.String = "Power (dB)";

% maksed mel spectrogram
subplot(3,1,3);
surf(melspectro_t, melspectro_f, melspectro_masked, 'EdgeColor','none');
title("Masked Mel Spectrogram (Shifted Power (dB) with Masking)");
xlabel('Time (\mus)');
ylabel('Frequency Bin (MHz)');
view([0,90]);
axis([melspectro_t(1) melspectro_t(end) melspectro_f(1) melspectro_f(end)]);
c = colorbar;
c.Label.String = "Arbitrary Amplitude";

%}

%% Wavelet Transform?

% create sigmoid mask
sig_datasample = 1:n_samples;
sig_halfpoint  = 86;
sig_rate       = 0.15;
sig_func       = 1./(1 + exp(-sig_rate.*(sig_datasample-sig_halfpoint)));

% apply sigmoid mask to our envelop (we don't want to be bothered by the
% big amplitude coming from US probe contact)
S_correlated3  = S_correlated2 .* sig_func;
S_env_clamped = S_env .* sig_func;

figure;
subplot(3,1,1);
plot(t, S_env2, '-r', 'LineWidth', 2); grid on;
title('Envelop');
xlabel('Time (\mus)');
ylabel('Amplitude');
subplot(3,1,2);
plot(t, sig_func, '-g', 'LineWidth', 2); grid on;
title('Sigmoid Function (halfpoint at 2 \mus)');
xlabel('Time (\mus)');
ylabel('Normalized Amplitude');
subplot(3,1,3);
plot(t, S_env_clamped, '-b', 'LineWidth', 2); grid on;
title('Envelop * Sigmoid');
xlabel('Time (\mus)');
ylabel('Amplitude');

%%

figure('Name', 'Wavelet Transform 1');
cwt(S_correlated3, Fs, 'FrequencyRange', [Fs/16 Fs/4], 'VoicesPerOctave', 32);

figure('Name', 'Wavelet Transform 2');
cwt(S_env_clamped, Fs, 'VoicesPerOctave', 32);

lev = 8;
mra = modwtmra(modwt(S_correlated3, 'db4', lev));

window = 6;
figure;
subplot(window,1,1)
for kk = 1:window
    subplot(window,1,kk)
    plot(t,mra(kk,:))
end
xlabel('Time (s)')











