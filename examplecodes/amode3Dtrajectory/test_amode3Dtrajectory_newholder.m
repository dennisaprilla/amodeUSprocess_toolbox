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
% 5. CSV file   : Transducer configuration, consists of neccessary
%                 information about the transducers in practice such as
%                 window signal, local coordinate system, holder name, etc.
%
% In theory, you can only use file #1, #2, and #5. In this case, since you use
% raw 3D position, it means that you need to process the data (such as
% calculate 3D rigid-body transformation, filling the timestamp gap of
% missing markers) by yourself.
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
addpath('..\..\functions\external');

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


%% 2) Ultrasound Signal Processing & Peak Detection
% At this point, we already synchronized US measurement (USData) and 
% Qualisys measurement (holder_R_global, holder_t_global). Now we can
% process our ultrasound data with bunch of signal processing to extract
% the depth data

% (!) the different with test_amode3Dtrajectory.mat we are not using 

% obtain ultrasound settings, we need window information for peak
% detection, and we also need several other information for the next phases
disp('Get path to INI files: Ultrasound configuration files');

































