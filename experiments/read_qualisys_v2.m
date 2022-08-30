%% Several Notes
% Currently, this program need 6 files to run. 4 of them are the Data, 2 of
% them related to the Ultrasound Configuration. There are:
% 1. TRC file: qualisys data with qualisys timestamp
% 2. TRC file: qualisys data with computer timestamp
% 3. TIFF files: US raw signal
% 4. MAT file: Qualisys data generated by QTM
% 5. MAT file: Ultrasound window properties
% 6. MAT file: Holder local coordinate system

clear; close all;

%% Read US TIFF file and Qualisys TRC file 

% addpath('..\functions');
% 
% % get file with qualisys timestamp
% disp('Get path to TRC file: Qualisys data with qualisys timestamp');
% [file_qualisys, path_qualisys] = uigetfile('*.trc');
% 
% % get file with computer timestamp
% disp('Get path to TRC file: Qualisys data with computer timestamp');
% [file_mypc, path_mypc] = uigetfile('*.trc');
% 
% % get path with us signal data (tiff images)
% disp('Get path to TIFF files: Ultrasound raw signal');
% directory_toUSData = uigetdir();
% 
% % read file with qualisys timestamp
% [markerfile_qualisys, markerdata_qualisys] = readTRC_qualisysData(strcat(path_qualisys, '\', file_qualisys));
% % read file with computer timestamp
% [markerfile_mypc, markerdata_mypc] = readTRC_qualisysData(strcat(path_mypc, '\', file_mypc));
% % read US data
% [USData, timestamps_USData, ~] = readTIFF_USsignal(directory_toUSData, 30, 1500);
% 
% % clear unneccesary variable
% clear file_qualisys path_qualisys file_mypc path_mypc directory_toUSData

%% Matching between US TIFF image and Qualisys TRC file

% % match timestamp between US tiff data and Qualisys trc data
% indexMatch_USQualisys = matchTimestamp(timestamps_USData, markerdata_mypc.Time, 0.01);
% 
% % delete the US Data which doesn't have match. This might be the case if US
% % TIFF data has bigger amount than the Qualisys TRC files.
% lastUSindex_hasMatch = length(indexMatch_USQualisys);
% if ( length(timestamps_USData) > lastUSindex_hasMatch )
%     timestamps_USData(lastUSindex_hasMatch+1:end) = [];
%     USData(:,:,lastUSindex_hasMatch+1:end)        = []; 
% end
% 
% % select qualisys data which do have match
% markerdata_mypc = markerdata_mypc(indexMatch_USQualisys,:);
% markerdata_qualisys = markerdata_qualisys(indexMatch_USQualisys,:);
% 
% % for i=1:length(indexMatch_USQualisys)
% %     disp(sprintf('US timestamp: %.5f, \t Qualisys timestamp: %.5f', timestamps_USData(i), markerdata_mypc.Time(i) ));
% % end
% 
% % clear unneccesary variable
% clear indexMatch_USQualisys lastUSindex_hasMatch 

%% Matching between Qualisys TRC file and Qualisis .mat (qtm) file

% % load the mat file, the name of the variable will be the same as the file.
% % it is unfortunate we can't dynamicaly call the variable name (or is it?)
% disp('Get path to MAT file: Qualisys data generated from QTM');
% [file_mypc, path_mypc] = uigetfile('*.mat');
% load(strcat(path_mypc, file_mypc));
% % load('..\data\experiment1\Qualisys\Data\TestDennis2_editDennis3.mat');
% 
% % mat file that is exported from qtm file doesn't have list of timestamp,
% % so we need to generate it by ourself using framerate information.
% timestamps_qualisysQTM = generateQualisysTimestamp(TestDennis2_editDennis3);
% 
% % match timestamp between Qualisys TRC file and Qualisis .mat (qtm) file
% indexMatch_TRCandQTM = matchTimestamp(markerdata_qualisys.Time, timestamps_qualisysQTM, 0.01);
% 
% % delete qualisys trc file and us tiff data which doesn't have any match 
% % with qualisys qtm (qualisys trc file and us tiff data are matched, so, if
% % one is modified, the other must be modified too). This might be the case
% % if TRC file have bigger amount of record than QTM file
% lastTRCindex_hasMatch = length(indexMatch_TRCandQTM);
% if( size(markerdata_qualisys, 1) > lastTRCindex_hasMatch )
%     markerdata_qualisys(lastTRCindex_hasMatch+1:end, :) = [];
%     markerdata_mypc(lastTRCindex_hasMatch+1:end, :)     = [];
%     timestamps_USData(lastTRCindex_hasMatch+1:end)      = [];
%     USData(:,:,lastTRCindex_hasMatch+1:end)             = [];
% end
% 
% % select Qualisys .mat file which do have match (we only focus for R and t
% % field in the structure)
% holder_t_global = TestDennis2_editDennis3.RigidBodies.Positions(:,:,indexMatch_TRCandQTM);
% holder_R_global = TestDennis2_editDennis3.RigidBodies.Rotations(:,:,indexMatch_TRCandQTM);
% 
% % clear unneccesary variable
% clear file_mypc path_mypc timestamps_qualisysQTM indexMatch_TRCandQTM lastTRCindex_hasMatch

load('test_offlinesync.mat');

%% Ultrasound Signal Processing & Peak Detection

% addpath('..\functions');
% 
% % load ultrasound window spesification. this will be provided by the
% % a-mode ultrasound toolbox, maybe in the future we should gather necessary
% % information to one single text file or mat file.
% disp('Get path to MAT file for: Ultrasound Window Properties');
% [file_mypc, path_mypc] = uigetfile('*.mat');
% load(strcat(path_mypc, file_mypc));
% % load('..\data\experiment1\Amode\testAmode2\guillaume_test1_window.mat');
% 
% % preparing structs which needed by the peak detection algorithm
% data_spec.n_ust     = size(USData, 1);
% data_spec.n_samples = size(USData, 2);
% data_spec.n_frames  = size(USData, 3);
% 
% us_spec.v_sound     = 1500e3; % mm/s
% us_spec.sample_rate = 50e6;
% us_spec.index2distance_constant  = us_spec.v_sound / (2 * us_spec.sample_rate);
% 
% % define window range
% probeProperties.WindowRange = [1 1].*probeProperties.WindowPosition + [-1 1].*0.5.*probeProperties.WindowWidth;
% % convert windows mm to windows indices
% probeProperties.WindowRange_i = floor(probeProperties.WindowRange/us_spec.index2distance_constant + 1);
% 
% % signal pre-processing
% [allpeaks, ~] = peaks_USsignal_windowed(USData, data_spec, us_spec, probeProperties.WindowRange, probeProperties.WindowRange_i);
% 
% clear probeProperties data_spec us_spec x_mm probeProperties

load('allpeaks.mat');

%% Rearrange Global Transformation Matrix from Qualisys Data

% get the necessary variable
n_frame  = size(markerdata_qualisys, 1);
n_holder = TestDennis2_editDennis3.RigidBodies.Bodies;
% allocate memory for variable
T_global_holder = repmat(eye(4),  1,1,n_holder,n_frame);

for frame = 1:n_frame    
    for holder = 1:n_holder
        
        t = holder_t_global(holder, :, frame)';
        R = reshape(holder_R_global(holder, :, frame), 3,3);
        
        % rearrange holder_t_global and holder_R_global to homogeneous
        % transformation matrix [R, t; 0 1]
        T_global_holder(:, :, holder, frame) = [ R, t; zeros(1,3), 1];
        
    end
end

% clear unneccesary variable
clear holder_t_global holder_R_global frame holder R t

%% Get global coordinate

% get the transformation from holder to USTip. this will be provided by the
% CAD model, which means, in the future we need to read a configuration
% from other files.
% disp('Get path to MAT file for: Holder Local Coordinate System');
% [file_mypc, path_mypc] = uigetfile('*.mat');
% load(strcat(path_mypc, file_mypc));
load('T_holder_usttip.mat');

% get the necessary variable
n_ust = size(USData, 1);
% allocate memory for variable
pc_amode = zeros(n_ust, 3, n_frame);
% (//) uncomment this part if you dont want to have point cloud for ust
% tip, this is just for display only
pc_usttip = zeros(n_ust, 3, n_frame);

% (!) THE VARIABLE BELOW IS ONLY FOR THIS SIMULATION
% here i only use 15 transducer (16-30), so i only consider those data
start_ust = 16;
% in the future, there will be a configuration file which describes the
% arrangement of the probes within holders. Here, it is as simple
% predefined vector, but later there will be changes.
probeholder_map = [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 2 2 2 3 3 3 3 3 4 4 4 4];
% (!) THE VARIABLE ABOVE IS ONLY FOR THIS SIMULATION

for frame = 1:n_frame
    for ust = start_ust:n_ust
        
        % three step of transformation
        amode = T_global_holder(:,:, probeholder_map(ust), frame) * ...
                T_holder_usttip(:,:, ust) * ...
                [0, 0, allpeaks.locations(ust, frame), 1]';            
        
        % (//) uncomment this to follow qualisys base vector
        basevector_Rcorrection = eul2rotm([0 0 deg2rad(90)]);
        amode = [basevector_Rcorrection, zeros(3,1); zeros(1,3), 1] * amode;
        
        % from homogeneous back to cartesian
        pc_amode(ust, :, frame) = amode(1:3)';
        
        % (//) uncomment this part if you dont want to have point cloud for 
        % ust tip, this is just for display only
        usttip = T_global_holder(:,:, probeholder_map(ust), frame) * ...
                 T_holder_usttip(:,:, ust) * ...
                 [0, 0, 0, 1]';
        usttip = [basevector_Rcorrection, zeros(3,1); zeros(1,3), 1] * usttip;
        pc_usttip(ust, :, frame) = usttip(1:3)';
        
    end
end

clear frame ust amode basevector_Rcorrection usttip

%% Display Recovered A-mode Measurement in 3D Space

close all;
addpath('..\functions\displays');

% prepare the window
figure1 = figure(1);
figure1.WindowState = 'maximized';
% axes1 = subplot(2,2,[1 3], 'Parent', figure1);
% axes2 = subplot(2,2,4, 'Parent', figure1);
axes1 = axes('Parent', figure1);
figure2 = figure(2);
axes2 = axes('Parent', figure2);

% display basis vector, so we know the reference
hold(axes1, 'on');
display_basevector(axes1, [0 0 0], [1 0 0; 0 1 0; 0 0 1], 50, 'plot_basevector');

for frame = 1:n_frame
    
    % plot the amode
    %delete(findobj('Tag', 'plot_amode'));
    plot3(axes1, pc_amode(start_ust:end, 1, frame), pc_amode(start_ust:end, 2, frame), pc_amode(start_ust:end, 3, frame), ...
          '.r', 'MarkerFaceColor', 'red', 'Tag', 'plot_amode');
    delete(findobj('Tag', 'plot_usttip'));
    plot3(axes1, pc_usttip(start_ust:end, 1, frame), pc_usttip(start_ust:end, 2, frame), pc_usttip(start_ust:end, 3, frame), ...
          'ob', 'MarkerFaceColor', 'blue', 'Tag', 'plot_usttip');
    
    % some addition configuration for the plot
    grid(axes1, 'on'); 
    axis(axes1, 'equal');
    xlabel(axes1, 'X (cm)');
    ylabel(axes1, 'Y (cm)');
    zlabel(axes1, 'Z (cm)');
    title(axes1, sprintf('Reconstructed A-mode, Frame %d', frame));
    view(axes1, 50,30);
    
%     % bar plot for depth
%     delete(findobj('Tag', 'bar_depth'));
%     bar(axes2, (16:30), allpeaks.locations(start_ust:end, frame), 'Tag', 'bar_depth', 'FaceColor', 'blue');
%     grid(axes2, 'on');
%     xlabel(axes2, 'Ultrasound Transducer #');
%     ylabel(axes2, 'Depth (mm)');
%     ylim(axes2, [0 10]);
%     title(axes2, 'Depth measurements');
    
    drawnow;
end









