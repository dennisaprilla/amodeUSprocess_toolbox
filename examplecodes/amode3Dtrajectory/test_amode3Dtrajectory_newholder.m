%% Several Notes from Dennis
% SUMMARY: The goal of this code is basically the same as in
% test_amode3Dtrajectory.mat. However, since the new experiment used
% different type of holder, there are some changes in determining the
% coordinate system of ultrasound signal.
%
% DETAILS on holder: We are detaching the dependency on holder local
% transformation for determining the ultrasound signal local
% transformation buy putting the three markers directly on the ultrasound
% transducer. In this experiment, the markers are shaped as isosceles 
% triangle with the height is longer than the base. The vector connecting 
% the top vertex to the line of the base is the direction of the
% ultrasound beam:
%
% GENERAL DESCRIPTION: This is a program for recovering 3D trajectory of 
% A-mode ultrasound measurement. It requires ultrasound data and motion 
% tracking data. In practice, there will be some other necessary file which 
% required to run this program, there are:
%
% 1. TIFF files : An uint16 image with (30, n_sample) resolution
%                 representing all raw signal of ultrasound measurements
% 2. TRC file   : Raw 3D position of each marker tracked by Qualisys system
%                 with computer timestamp
% 3. TRC file   : Raw 3D position of each marker tracked by Qualisys system
%                 with qualisys timestamp
% 4. MAT file   : A post-processed motion tracking data by Qualisys Track
%                 Manager Software. Some missing markers in several
%                 timestamps are filled by the software. It also provides 
%                 rigid-body transformation of the holder and 
% 5. INI file   : Transducer configuration, consists of neccessary
%                 information about the transducers in practice such as
%                 window signal, local coordinate system, holder name, etc.
% 6. CSV file   : Transducer calibration file, consists of rigid body
%                 transformation from Marker Stick Origin to UST tips.
%
% In theory, you can only use file #1, #2, and #5 #6. In this case, 
% since you use raw 3D position, it means that you need to process the data 
% (such as calculate 3D rigid-body transformation, filling the timestamp 
% gap of missing markers, etc.) by yourself.
%
% If you are lazy (just like me), you can use the QTM software to
% post-process the tracking data and export it to MAT file (file #4). But, 
% since QTM will use their own timestamp (it uses different computer when 
% recording), it means you need a bridge to map timestamps between US 
% measurement (file #1) and post-processed qualisys measurement (file #4).
% That is why you need file #3. So in practice, you will need file 1-4 for
% synchronization.
%
% DA. Christie (University of Twente)

clear; close all;

%% 1.1) Matching between US TIFF files and Qualisys TRC files
% Our first goal is to synchronize US measurement (file #1) and
% post-processed Qualisys data (file #4). Because there is local time
% timestamp difference, we will require timestamp information in raw 
% Qualisys data (file #2 and #3). So, first, let's synchronize the 
% timestamp between US measurement and the Raw Qualisys Data

addpath('..\..\functions');
addpath('..\..\functions\trc_tiff_synchronization');

% get path to US Signal data (file #1)
disp('Get path to TIFF files: Ultrasound raw signal');
directory_toUSData = uigetdir();
% get file to Raw Qualisys data with computer timestamp (file #2)
disp('Get path to TRC file: Qualisys data with computer timestamp');
[file_mypc, path_mypc] = uigetfile('*.trc');
% get file to Raw Qualisys data with qualisys timestamp (file #3)
disp('Get path to TRC file: Qualisys data with qualisys timestamp');
[file_qualisys, path_qualisys] = uigetfile('*.trc');

% read US data
[USData, timestamps_USData, ~] = readTIFF_USsignal(directory_toUSData, 30, 1500);
% read file with computer timestamp
[markerfile_mypc, markerdata_mypc] = readTRC_qualisysData(strcat(path_mypc, '\', file_mypc));
% read file with qualisys timestamp
[markerfile_qualisys, markerdata_qualisys] = readTRC_qualisysData(strcat(path_qualisys, '\', file_qualisys));

% match timestamp between US tiff data and Qualisys trc data
indexMatch_USQualisys = matchTimestamp(timestamps_USData, markerdata_mypc.Time, 0.01);

% delete the US Data which doesn't have match. This might be the case if US
% TIFF data has bigger amount than the Qualisys TRC files.
lastUSindex_hasMatch = length(indexMatch_USQualisys);
if ( length(timestamps_USData) > lastUSindex_hasMatch )
    timestamps_USData(lastUSindex_hasMatch+1:end) = [];
    USData(:,:,lastUSindex_hasMatch+1:end)        = []; 
end

% select qualisys data which do have match
markerdata_mypc = markerdata_mypc(indexMatch_USQualisys,:);
markerdata_qualisys = markerdata_qualisys(indexMatch_USQualisys,:);

% uncomment this if you want to look at the matched timestamps
for i=1:length(indexMatch_USQualisys)
    disp(sprintf('US timestamp: %.5f, \t Qualisys timestamp: %.5f', timestamps_USData(i), markerdata_mypc.Time(i) ));
end
disp(sprintf('mean absolute time difference: %d', mean(abs(timestamps_USData(i) - markerdata_mypc.Time(i))) ));

% clear unneccesary variable
clear file_mypc path_mypc file_qualisys path_qualisys directory_toUSData indexMatch_USQualisys lastUSindex_hasMatch i


%% 1.2) Matching between US Qualisys TRC file and Qualisys MAT file from QTM
% From the previous section, we obtain markerdata_mypc and
% markerdata_qualisys which synchronized with USData by their index. Now
% it is the time to synchronize those data with Qualysis MAT file from
% QTM software.

% load the Qualisys MAT file. it can be obtained after post processing of
% the Qualisys data from QTM software
disp('Get path to MAT file: Qualisys data generated from QTM');
[file_mypc, path_mypc] = uigetfile('*.mat');
load(strcat(path_mypc, file_mypc));

% MAT file that is exported from QTM file doesn't have list of timestamp,
% so we need to generate it by ourself using framerate information.
% (!) WARNING:
% (!) The variable name within .MAT file from QTM depends on the filename.
% (!) This is so annoying since you need to call a different variable name 
% (!) for different file. So, i make this "very unrecommended way" to
% (!) rename the variable to a name we can all agree with.
matfilename = split(file_mypc, '.');
eval(['matqtm_postprocess = ', matfilename{1}, ';']);
% generate the timestamp
timestamps_qualisysQTM = generateQualisysTimestamp(matqtm_postprocess);
% match timestamp between Qualisys TRC file and Qualisis .mat (qtm) file
indexMatch_TRCandQTM = matchTimestamp(markerdata_qualisys.Time, timestamps_qualisysQTM, 0.01);

% delete qualisys TRC file and US TIFF data which doesn't have any match 
% with qualisys qtm (qualisys TRC file and US TIFF data are matched, so, if
% one is modified, the other must be modified too). This might be the case
% if TRC file have bigger amount of record than QTM file
lastTRCindex_hasMatch = length(indexMatch_TRCandQTM);
if( size(markerdata_qualisys, 1) > lastTRCindex_hasMatch )
    % qualisys TRC data
    markerdata_qualisys(lastTRCindex_hasMatch+1:end, :) = [];
    markerdata_mypc(lastTRCindex_hasMatch+1:end, :)     = [];
    % US TIFF data
    timestamps_USData(lastTRCindex_hasMatch+1:end)      = [];
    USData(:,:,lastTRCindex_hasMatch+1:end)             = [];
end

% select Qualisys .mat file which do have match (we only focus for R and t
% field in the structure)
holder_t_global = matqtm_postprocess.RigidBodies.Positions(:,:,indexMatch_TRCandQTM);
holder_R_global = matqtm_postprocess.RigidBodies.Rotations(:,:,indexMatch_TRCandQTM);

% clear unneccesary variable
clear file_mypc path_mypc timestamps_qualisysQTM indexMatch_TRCandQTM lastTRCindex_hasMatch matfilename

% load('offlinesync_exp2.mat');

%% 2) Ultrasound Signal Processing & Peak Detection
% At this point, we already synchronized US measurement (USData) and 
% Qualisys measurement (holder_R_global, holder_t_global). Now we can
% process our ultrasound data with bunch of signal processing to extract
% the depth data

% (!) WARNING:
% (!) The different with test_amode3Dtrajectory.mat we are not using .csv
% (!) file anymore, instead we are using .ini file. When it imported to the
% (!) program, it will be read as struct, then converted into table (easier
% (!) to handle).

% add necessary function path
addpath('..\..\functions\external\ini2struct');

% obtain ultrasound settings, we need window information for peak
% detection, and we also need several other information for the next phases
disp('Get path to INI files: Ultrasound configuration files');
% get path to window properties
[fname, path] = uigetfile('*.ini');
ust_struct = ini2struct(strcat(path,fname));

% preparing data_spec structs which needed by the peak detection algorithm
data_spec.n_ust     = size(USData, 1);
data_spec.n_samples = size(USData, 2);
data_spec.n_frames  = size(USData, 3);
% preparing us_spec structs which needed by the peak detection algorithm
us_spec.v_sound     = 1540e3; % mm/s
us_spec.sample_rate = 50e6;
us_spec.index2distance_constant  = us_spec.v_sound / (2 * us_spec.sample_rate);

% initialize a table for containing the probe properties
ust_config = table( 'Size', [1,3], ...
                    'VariableTypes', ["string", "double", "double"], ...
                    'VariableNames', ["Group", "WindowLowerBound", "WindowUpperBound"]);
% get the field names
ust_struct_fieldnames = fieldnames(ust_struct);
% loop through all the fields
for i=1:data_spec.n_ust
    % get lower and upper bound data
    lowerbound_str = ust_struct.(ust_struct_fieldnames{i}).LowerBound;
    upperbound_str = ust_struct.(ust_struct_fieldnames{i}).UpperBound;
    group_str      = ust_struct.(ust_struct_fieldnames{i}).Group;
    
    % but because it is string, and the US machine somehow uses comma 
    % separator for floating point, so we need to replace the comma as 
    % point first, then convert it to double.
    ust_config.WindowLowerBound(i) = str2double(strrep(lowerbound_str, ',', '.'));
    ust_config.WindowUpperBound(i) = str2double(strrep(upperbound_str, ',', '.'));
    % remove double quote in the group string from ini fle
    ust_config.Group(i) = strrep(group_str, '"', '');
end

% define window range
windowRange = [ust_config.WindowLowerBound ust_config.WindowUpperBound];
% convert windows mm to windows indices
windowRange_i = floor(windowRange / us_spec.index2distance_constant + 1);

% detect the peak with bunch of predetermined series of signal processing
[allpeaks, ~] = peaks_USsignal_windowed(USData, data_spec, us_spec, windowRange, windowRange_i);

% clear unneccesary variable
clear file_ustconfig path_ustconfig probeProperties x_mm probeProperties windowRange windowRange_i ust_struct ust_struct_fieldnames

% load('allpeaks_ustconfig_exp2.mat');

%% 3.1) Reformatting the Transformations
% From the last section, we obtained the depth data from each of our
% ultrasound probe. Now, if we properly transform our depth data with
% series of rigid body transformation, we can recover the 3D trajectory of
% ultrasound measurement.
%
% There are several transformation matrix that is required, there are
% 1. T to Marker Stick in global coordinate frame
% 2. T to UST tip in holder coordinate frame
% 3. T to Bone Surface in UST tip coordinate frame
%
% WARNING:
% (!) Instead of T to holder, we have now T to Marker Stick. This is
% (!) because individual trasnducers is now has markers on it.
% WARNING:
% (!) With the current holder that is used in this experiment, we can
% (!) actually bypass transformation #2, and if we assume the the
% (!) transducer positioning with the marker stick is perfect, we can
% (!) further simplify transformation #3 as only rotation. In this script,
% (!) i will assume the positioning is perfect (as i was not conducting a
% (!) calibration yet, so the transformation is just #1 + translation

% First, let's reformat T to holder in global coordinate frame
% allocate memory for variable
T_global_markerstick = repmat(eye(4),  1, 1, data_spec.n_ust, data_spec.n_frames);

% (!) WARNING:
% (!) In the last experiment, i only use 2 trasnducers, it means that i
% (!) need to adjust that i will only grab 2 transformation from 
% (!) holder_t_global and holder_R_global. YOU SHOULD CHANGED if you use
% (!) different number of transducers
start_ust = 29;

for frame = 1:data_spec.n_frames
     
    % in previous implementation, we are grouping several transducers into one
    % holder, so several trasnducers shares same transformation #2. but now,
    % because each transducer has individual T, it means that the number of 
    % transducer is the same as the number of T.
    for markerstick = start_ust:data_spec.n_ust
        
        % (!) WARNING:
        % (!) This line of code below is here because the previous warning,
        % (!) i only use 2 transducers. So i need to adjust the indexing so
        % (!) i can store holder_t_global and holder_R_global properly.
        % (!) YOU SHOULD CHANGE if you use different number of transducers
        adjusted_idx = (markerstick - start_ust) + 1;
        
        % obtain transfomation data
        t = holder_t_global(adjusted_idx, :, frame)';
        R = reshape(holder_R_global(adjusted_idx, :, frame), 3,3);
        % rearrange holder_t_global and holder_R_global to homogeneous
        % transformation matrix [R, t; 0 1]
        T_global_markerstick(:, :, markerstick, frame) = [ R, t; zeros(1,3), 1];
    end
end

% Second, let's reformat T to UST tip in holder coordinate frame. This
% transformation is stored in calibration file (.CSV).
disp('Get path to INI files: Ultrasound configuration files');
% get path to calibration file
[fname, path] = uigetfile('*.csv');
calibration_markerstick = readmatrix(strcat(path, fname));

% allocate memory for variable
T_markerstick_usttip = repmat(eye(4), 1, 1, data_spec.n_ust);

for current_ust=1:data_spec.n_ust
    % each line of calibration_markerstick is calibration for 1 transducer
    T_markerstick_usttip(:,:,current_ust) = reshape(calibration_markerstick(current_ust,:), [4,4])';
end

% clear unneccesary variable
clear fname path calibration_markerstick start_ust adjusted_idx holder_t_global holder_R_global frame holder R t i

%% 3.2) Recovering 3D Trajectory of Ultrasound Data
% Now, everything is ready. We reformatted the structure of our
% transformation matrices. Now, the transformation can be easily done by
% v' = T*v, where T is 4x4 homogeneous matrices, and v is homogeneous
% vector. To recover the 3D trajectory or A-mode ultrasound data, the
% transformation series will be:
% T_global_markerstick * T_markerstick_usttip * allpeaks

% here i only use 15 transducer (16-30), so i only consider those data
start_ust = 29;

% allocate memory for variable
pc_amode = zeros(data_spec.n_ust, 3, data_spec.n_frames);
% (//) uncomment this part if you dont want to have point cloud for ust
% tip, this is just for display only
pc_usttip = zeros(data_spec.n_ust, 3, data_spec.n_frames);

for frame = 1:data_spec.n_frames
    for ust = start_ust:data_spec.n_ust
        
        % two steps of transformation
        amode = T_global_markerstick(:,:, ust, frame) * ...
                T_markerstick_usttip(:,:, ust) * ...
                [0, 0, allpeaks.locations(ust, frame), 1]';   

        % (//) uncomment this to follow qualisys base vector
        basevector_Rcorrection = eul2rotm([0 0 deg2rad(90)]);
        amode = [basevector_Rcorrection, zeros(3,1); zeros(1,3), 1] * amode;
        
        % from homogeneous back to cartesian
        pc_amode(ust, :, frame) = amode(1:3)';
        
        % (//) uncomment this part if you dont want to have point cloud for 
        % ust tip, this is just for display only
        usttip = T_global_markerstick(:,:, ust, frame) * ...
                 T_markerstick_usttip(:,:, ust) * ...
                 [0, 0, 0, 1]';
        usttip = [basevector_Rcorrection, zeros(3,1); zeros(1,3), 1] * usttip;
        
        % from homogeneous back to cartesian
        pc_usttip(ust, :, frame) = usttip(1:3)';
        
    end
    
end

clear frame ust amode basevector_Rcorrection usttip

%% 4) Display Recovered A-mode Measurement in 3D Space
% For sanity check, we should plot our results.

close all;
addpath('..\..\functions\displays');

% prepare the window
figure1 = figure(1);
figure1.WindowState = 'maximized';
axes1 = subplot(2,2,[1 3], 'Parent', figure1);
axes2 = subplot(2,2,4, 'Parent', figure1);

% display basis vector, so we know the reference
hold(axes1, 'on');
display_basevector(axes1, [0 0 0], [1 0 0; 0 1 0; 0 0 1], 50, 'plot_basevector');


% some addition configuration for the plot
grid(axes1, 'on'); 
axis(axes1, 'equal');
xlabel(axes1, 'X (cm)');
ylabel(axes1, 'Y (cm)');
zlabel(axes1, 'Z (cm)');
xlim(axes1, [-300, 300]);
ylim(axes1, [-250, 0]);
zlim(axes1, [0, 450]);
view(axes1, 50,30);
offset_ustext = 5;

for frame = 1:data_spec.n_frames
    
    % plot the amode
    delete(findobj('Tag', 'plot_amode'));
    plot3(axes1, pc_amode(start_ust:end, 1, frame), pc_amode(start_ust:end, 2, frame), pc_amode(start_ust:end, 3, frame), ...
          '.r', 'MarkerFaceColor', 'red', 'Tag', 'plot_amode');
	% plot the US-tip
    delete(findobj('Tag', 'plot_usttip'));
    plot3(axes1, pc_usttip(start_ust:end, 1, frame), pc_usttip(start_ust:end, 2, frame), pc_usttip(start_ust:end, 3, frame), ...
          'ob', 'MarkerFaceColor', 'blue', 'Tag', 'plot_usttip');
    
    % plot the text for indicator
    delete(findobj('Tag', 'plot_ustext'));
    for current_ust=start_ust:data_spec.n_ust
        text( axes1, ...
              pc_usttip(current_ust, 1, frame)+offset_ustext, ...
              pc_usttip(current_ust, 2, frame)+offset_ustext, ...
              pc_usttip(current_ust, 3, frame)+offset_ustext, ...
              sprintf('US%2d', current_ust), ...
              'Tag', 'plot_ustext');
    end
    
    % write the title with frame number
    title(axes1, sprintf('Reconstructed A-mode, Frame %d', frame));
    
    % bar plot for depth
    delete(findobj('Tag', 'bar_depth'));
    bar(axes2, (start_ust:30), allpeaks.locations(start_ust:end, frame), 'Tag', 'bar_depth', 'FaceColor', 'blue');
    grid(axes2, 'on');
    xlabel(axes2, 'Ultrasound Transducer #');
    ylabel(axes2, 'Depth (mm)');
    ylim(axes2, [0 10]);
    title(axes2, 'Depth measurements');
    
    drawnow;
end

















