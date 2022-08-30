clear; clc;

%% READ DEPTH DATA
% the output is 2d matrix,
% first dimension is the measurements
% second dimension is consists of header, depth data (mm), and amplitude
% column 1     : timestamp
% column 2     : index
% column 3-32  : depth (mm)
% column 33-62 : amplitude

% all_ultrasounddepth = readmatrix("D:\test\log5\1628787238.603903.csv");

%% READ RAW DATA
% the output is 3d matrix,
% first dimension is the probes
% second dimension is the samples
% third dimension is measurements

% array to store the timestamps and index
timestamps = [];
indexes = [];

% specify where is the folder
% filenames = dir('D:\Documents\BELANDA\PhD Thesis\Code\MATLAB\Test_qualisys\data\experiment1\Amode\testAmode2\*.tiff');
filenames = dir('D:\test\log11\*.tiff');

% specify the configuration of the ultrasound machine
number_probes = 30;
number_samples = 1500;
number_files = size(filenames, 1);
all_ultrasoundfrd = zeros(number_probes, number_samples, number_files);

disp("Reading the data, please wait ...");

% loop for all ever the tiff image
for file=1:number_files
    
    % get the timestamp from the file name
    strings = split(filenames(file).name, "_");
    timestamp = str2double(strings{1});
    % get the image index number (if we specify index for data retreival)
    strings = split(strings{2}, ".");
    index = str2num(strings{1});
    % save it to array for some reason
    timestamps = [timestamps; timestamp];
    indexes = [indexes; index];
    
    % read the tiff file
    tiff_image = read(Tiff(strcat(filenames(file).folder, '\', filenames(file).name)));
    
    % loop for each if the image
    for probe=1:number_probes
        % convert it to int16 and store it to a huge matrix
        all_ultrasoundfrd(probe, :, file) = typecast(tiff_image(probe,:), 'int16');
    end
    
end

all_ultrasoundfrd_info = whos('all_ultrasoundfrd');
fprintf("Reading finished. Variable size: %.2f MB\n", all_ultrasoundfrd_info.bytes/(1024*1024));


%% PROCESS THE DATA
% implements your algorithm here to process the ultrasound raw data

figure(1);
for i=1:size(all_ultrasoundfrd,3)
    
    plot_number=1;
    for probe=16:18
        subplot(3,2,plot_number);
        plot(all_ultrasoundfrd(probe,1:end, i));
        ylim([-2000 2000]);
        title(sprintf("Probe #%d", probe));
        
        plot_number=plot_number+2;
        if(plot_number>6) 
            plot_number=2; 
        end
    end
    
    disp(i);
   	drawnow;
end













