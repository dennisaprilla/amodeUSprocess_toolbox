%% Several Notes
% This is a demonstration program for visualizing the kinematics of the
% bone. At the time this program is written, we only have kinematic of one
% bone segment (tibia). Therefore, we can't calculate the joint kinematics
% since it needs another bone segment (femur) for reference frame.
%
% We adopt existing framework (Niu et al.) for the registration with slight
% different implementation. We didn't use the perturbation phase for
% simplicity, and we estimates transformation between frame for the
% preregistration step instead of using preregistration area's centroid.
%
% There are several files required to run this program:
% 1. STL file : A bone model (tibia) which can be obtianed from CT/MRI Scan
% 2. MAT file : A-mode measurement in global coordinate frame. This data
%               can be generated using test_amode3Dtrajectory.m program
% 3. Any file which can represents the preregistration sphere, a (n_sphere x 4) 
%    matrix that is columnly structured as [center_x, center_y, center_z, radius]
% 
% DA. Christie (University of Twente)

clc; clear all; close all;
addpath('..\functions\displays\');

%% 1) Data Preparation 

% prepare the figure so we can use over and over again troughout the program
figure1 = figure(1);
figure1.WindowState  = 'maximized';
axes1 = axes('Parent', figure1);

% (1) Load and prepare the bone point cloud
tibiaBone = stlread('Tibia_R_Guillaume.stl');
tibiaBone_centroid = mean(tibiaBone.Points, 1);
tibiaBone = bsxfun(@minus, tibiaBone.Points, tibiaBone_centroid);

% display bone point cloud
plot3( axes1, ...
       tibiaBone(:,1), ...
       tibiaBone(:,2), ...
       tibiaBone(:,3), ...
       '.', 'Color', [0.7 0.7 0.7], ...
       'MarkerSize', 0.1, ...
       'Tag', 'plot_bone');
xlabel('X'); ylabel('Y'); zlabel('Z');
view(axes1, 50,30);
grid on; axis equal; hold on;

% (2) Prepare preregistration area point cloud. sphere properties  (e.g. 
% centroid and radius) for determining preregistration area is stored
% in this structure.
% (!) This is still manually, and will be different for each of bone model
% (!) we obtain, due to the bone geometry or point cloud origin. We can use
% (!) specify it prior to the program with the toolbox i made (i will 
% (!) specify the name of the toolbox here once it is finished)
preregistrationSphere = [ -16.97, -20.36, 115.0, 22.5; ...
                           14.20, -25.30, 115.0, 22.5; ...
                           4.84, 11.25, -180.10, 20.0 ];

% obtain preregistration area 
preregistrationArea_number = size(preregistrationSphere, 1);
preregistrationArea = {};
for i=1:preregistrationArea_number
    % get the sphere properties and determine the distance of the points to
    % the centroid of the sphere
    sphere_centroid = preregistrationSphere(i, 1:3);
    distance = sqrt( sum( bsxfun(@minus, tibiaBone, sphere_centroid).^2 , 2 ) );
    % obtain list of points that lies within preregistrationSphere and
    % consider it as preregistrationArea
    sphere_radius = preregistrationSphere(i, 4);
    preregistrationArea{i} = tibiaBone(distance < sphere_radius, :);
end
preregistrationArea = preregistrationArea';

% % if you wonder where the sphere is, you can uncomment code below
% for i=1:preregistrationArea_number
%     display_sphere(axes1, ...
%                    [ preregistrationSphere(1, 1), ...
%                      preregistrationSphere(1, 2), ...
%                      preregistrationSphere(1, 3) ], ...
%                    preregistrationSphere(1, 4), ...
%                    'Tag', "amode_sphere");
% end

% % display the preregistration area
% for i=1:preregistrationArea_number
%     plot3( axes1, ...
%            preregistrationArea{i}(:,1), ...
%            preregistrationArea{i}(:,2), ...
%            preregistrationArea{i}(:,3), ...
%            '.r', ...
%            'MarkerSize', 0.1, ...
%            'Tag', 'plot_preregistrationarea');
% end

% 3) Load and prepare the A-mode measurement. This A-mode can be produced
% by running the test_amode3Dtrajectory.m program
load('pc_amode.mat');
samplepoints = pc_amode(16:30, :, :);

% % display the A-mode measurement
% plot3( axes1, ...
%        samplepoints(:,1,1), ...
%        samplepoints(:,2,1), ...
%        samplepoints(:,3,1), ...
%        'or', ...
%        'MarkerFaceColor', 'r', ...
%        'Tag', 'plot_samplepoint');
   
% display global coordinate system base vector
display_basevector(axes1, [0 0 0], [1 0 0; 0 1 0; 0 0 1], 50, 'plot_basevector');

% clear variable that will not be used anymore
clear distance i pc_amode sphere_centroid sphere_radius tibiaBone_centroid tibiaBone_scale   

%% 2) Registration

delete(findobj('Tag', 'plot_bone'));
delete(findobj('Tag', 'plot_preregistrationarea'));

% prepare some necessary variables
n_frame = size(samplepoints,3);
% (4,4,n_frame) matrix stores the transformation matrix for the entire frame
T_betweenframe = repmat( eye(4), 1,1,n_frame);
T_accumulation = repmat( eye(4), 1,1,n_frame);

% we loop trough all frames we have
for frame=1:n_frame
    
    % delete plot from previous frame
    delete(findobj('Tag', 'plot_samplepoint'));
    delete(findobj('Tag', 'plot_tibiaBone_icpregistered'));
    delete(findobj('Tag', 'plot_preregistrationArea_icpregistered'));
    
    % display the A-mode measurement
    plot3( axes1, ...
           samplepoints(:,1,frame), ...
           samplepoints(:,2,frame), ...
           samplepoints(:,3,frame), ...
           'or', ...
           'MarkerFaceColor', 'r', ...
           'Tag', 'plot_samplepoint');
       
	% Preregistration is conducted with exploiting prior knowledge of
	% general position of the A-mode transducers. We predetermined 3
	% preregistration areas (lateral, medial epicondyle, and ankle). There
	% are groups of transducers (sample_points) that is corresponds with 
    % one of the preregistration areas. 
    % sample_points variable is structured in regular matrix, we don't have 
    % any information about the group. Thus, we arrange the structure to be
    % a cell like below.
    samplepoints_preregArea = [{samplepoints(1:3,   :, frame)}; ...
                               {samplepoints(4:6,   :, frame)}; ...
                               {samplepoints(12:15, :, frame)}];

    % We will do preregistration with centroid only in the first frame. In
    % the next frame we will estimate the transformation between frames.
    % So, let's have special case for frame 1
    if(frame==1)
        %% (2.1.) Preregistration step (Using Centroid)

        % Code below is using center point of the registration area as Kenan's work
        % described it. We could exploit the preregistration sphere to search the
        % centroid of the preregistration area. We assume that nearest point to the
        % preregistration sphere centroid is the preregistration area centroid
        preregistrationSphere_centroid = preregistrationSphere(:, 1:preregistrationArea_number);
        preregistrationArea_assumedCentroid = [];

        % For each of preregistration area, we will find the centroid of
        % the area by using the centroid of the sphere. Then we need to
        % copy the centroid as much as sample_points in that area. So we
        % have 1-to-1 point pair for estimating the transformation later.
        % The output of this loop is a matrix with ( preregistrationArea_number * 
        % preregistrationArea_samplingNumber) rows.
        for i=1:preregistrationArea_number
            % search for the nearest neighbor index
            [nearestIndex, ~] = knnsearch(preregistrationArea{i}, preregistrationSphere_centroid(i,:));
            % obtain the centroid 
            assumedCentroid = preregistrationArea{i}(nearestIndex, :);

            % There are multiple sample_point in one preregistration area,
            % and registration algorithm requires 1-to-1 point pairs, so we
            % duplicate the centroid as the number of sample_point in each area
            n_samplepoints_preregArea = size(samplepoints_preregArea{i},1);
            preregistrationArea_assumedCentroid = [ preregistrationArea_assumedCentroid; ...
                                                    {repmat(assumedCentroid, n_samplepoints_preregArea, 1)} ];
        end

%         % display the correspondences for sanity check
%         % loop for every preregistration Area
%         for i=1:preregistrationArea_number
%             % loop for every number of sample in current preregistration area
%             n_samplepoints_preregArea = size(samplepoints_preregArea{i},1);
%             for j=1:n_samplepoints_preregArea
%                 % get the point pair
%                 temp_pointPair = [samplepoints_preregArea{i}(j,:); preregistrationArea_assumedCentroid{i}(j,:)];
%                 % draw line between the point pair so we can se it clearly
%                 plot3( axes1, ...
%                        temp_pointPair(:,1), temp_pointPair(:,2), temp_pointPair(:,3), ...
%                        '-m', 'Tag', 'plot_pointpair');
%             end
%         end

        % estimate the transformation, because we structured our point
        % pairs with cells, we need to convert back to matrix since it is 
        % the requirement function below
        [tform] = estimateGeometricTransform3D( cell2mat(preregistrationArea_assumedCentroid), ...
                                                cell2mat(samplepoints_preregArea), ...
                                                'rigid', ...
                                                'MaxNumTrials', 10000, ...
                                                'MaxDistance', 50);

        % in literature, homogeneous transformation matrix is structured as
        % [R, t; 0 1] but matlab store it as [R, 0; t, 1]. I dont like it,
        % so i transpose it.
        T_coarse = tform.T';
        % transform the tibiaBone point cloud...
        tibiaBone_coarseregistered           = rigidTransform(T_coarse, tibiaBone);
        % ...and the preregistration area, since we need that for
        % registration in the next frame
        preregistrationArea_coarseregistered = rigidTransform(T_coarse, cell2mat(preregistrationArea));

        % plot the coarse registration for sanity check
        plot3( axes1, ...
               tibiaBone_coarseregistered(:,1), ...
               tibiaBone_coarseregistered(:,2), ...
               tibiaBone_coarseregistered(:,3), ...
               '.g', ...
               'MarkerSize', 0.1, ...
               'Tag', 'plot_femurBone_ransacRegistered');
           
        % clear variable that will not be used anymore
        clear i n_samplepoints_preregArea nearestIndex assumedCentroid ...
              preregistrationArea_assumedCentroid preregistrationSphere_centroid

        %% (2.2) ICP step

        % Change the point structure to be suit to matlab icp built in 
        % function. We have two option: 
        % 1) register all sample points to bone model, or, 
        % 2) register sample_point in preregistration area to
        %   preregistration area point cloud
        % Second option is much more spesific. i hypothesized we dont
        % actually need sample points in the midle of the bone, since it is
        % lack of geometrical feature.
        preregistrationAreaPC_coarseregistered = pointCloud(preregistrationArea_coarseregistered);
        samplepointsPC_preregArea              = pointCloud(cell2mat(samplepoints_preregArea));

        % Register with icp. Note that i choose samplepointsPC_preregArea
        % as first parameter (moving) and preregistrationAreaPC_coarseregistered
        % second parameter (fixed). 
        % It is supposed to be the other way around (we register bone 
        % (moving) to sample points (fixed)). But if i do this way and i 
        % specify InlierRatio = 1, i can get perfect 1-1 pair  match (check
        % the function inside, for clarity what i meant). 
        [tform, ~, icp_rmse] = pcregistericp( samplepointsPC_preregArea, ...
                                              preregistrationAreaPC_coarseregistered, ...
                                              'InlierRatio', 1, ...
                                              'Verbose', false, ...
                                              'MaxIteration', 30 );

        % Because i choose that specific arrangement of parameter for the 
        % pcregistericp, i need to inverse the transformation.
        T_icp = inverseHMat(tform.T');
        % Full transformation will be combination of T_icp and T_coarse
        T_betweenframe(:,:,frame) = T_icp * T_coarse;
        % This is the first frame, so the the T_accumulation will be the
        % same as T_betweenframe
        T_accumulation(:,:,frame) = T_betweenframe(:,:,frame);

        % transform the tibiaBone and preregistrationArea
        tibiaBone_icpregistered           = rigidTransform(T_accumulation(:,:,frame), tibiaBone);
        preregistrationArea_icpregistered = rigidTransform(T_accumulation(:,:,frame), cell2mat(preregistrationArea));
       
%         % plot the icp registration for sanity check
%         delete(findobj('Tag', 'plot_femurBone_ransacRegistered'));
%         plot3( axes1, ...
%                tibiaBone_icpregistered(:,1), ...
%                tibiaBone_icpregistered(:,2), ...
%                tibiaBone_icpregistered(:,3), ...
%                '.g', ...
%                'MarkerSize', 0.1, ...
%                'Tag', 'plot_tibiaBone_icpregistered');

        % clear variable that will not be used anymore
        clear preregistrationArea_all preregistrationArea_number ...
              preregistrationArea_samplingNumber preregistrationArea_size ...
              preregistrationSphere samplepoints_duplicated samplepoints_index
          

    else
        %% (3.1) Preregistration step (using transformation between frame)
        % Assuming the sample_point between frames is generally rigid-body
        % we can estimate the transformation using usual approach. We know
        % the assumption is not true, so in the later phase, we will
        % correct it using fine registration algorithm.
        tform = estimateGeometricTransform3D( samplepoints(:,:, frame-1), ...
                                              samplepoints(:,:, frame), ...
                                              'rigid');
                                          
        % transpose (the same reason as before)
        T_coarse= tform.T';
        % transform the necessary point cloud
        tibiaBone_coarseregistered           = rigidTransform(T_coarse, tibiaBone_icpregistered);
        preregistrationArea_coarseregistered = rigidTransform(T_coarse, preregistrationArea_icpregistered);

%         % plot the transformation for sanity check                        
%         delete(findobj('Tag', 'plot_tibiaBone_icpregistered'))
%         plot3( axes1, ...
%                tibiaBone_coarseregistered(:,1), ...
%                tibiaBone_coarseregistered(:,2), ...
%                tibiaBone_coarseregistered(:,3), ...
%                '.g', ...
%                'MarkerSize', 0.1, ...
%                'Tag', 'plot_femurBone_ransacRegistered');
        
        % Change the point structure to be suit to matlab icp built in function
        % (check the previous section (first frame case) to see the idea
        % behind this line of codes)
        preregistrationAreaPC_coarseregistered = pointCloud(preregistrationArea_coarseregistered);
        samplepointsPC_preregArea              = pointCloud(cell2mat(samplepoints_preregArea));
        
        %% (3.2) Preregistration step (using transformation between frame)

        % Register with icp (check the previous section (first frame case) 
        % to see the idea behind this line of codes)
        [tform, ~, icp_rmse] = pcregistericp( samplepointsPC_preregArea, ...
                                              preregistrationAreaPC_coarseregistered, ...
                                              'InlierRatio', 1, ...
                                              'Verbose', false, ...
                                              'MaxIteration', 30 );
                                          
        % inverse the transformation due to the parameter's order of pcregistericp 
        T_icp = inverseHMat(tform.T');
        % store the transformation between frame
        T_betweenframe(:,:,frame) = T_icp * T_coarse;
        
        % calculate the accumulation transformation. We need to multiply
        % the transformation from first frame to the current frame
        T_untilcurrentframe = eye(4);
        for i=1:(frame-1)
            T_untilcurrentframe = T_betweenframe(:,:,i) * T_untilcurrentframe;
        end        
        T_accumulation(:,:,frame) = T_icp * T_coarse * T_untilcurrentframe;
        
        % transform the necessary point cloud
        tibiaBone_icpregistered           = rigidTransform(T_accumulation(:,:,frame), tibiaBone);
        preregistrationArea_icpregistered = rigidTransform(T_accumulation(:,:,frame), cell2mat(preregistrationArea));
        
        % plot the transformation for sanity check 
        delete(findobj('Tag', 'plot_femurBone_ransacRegistered'));
        delete(findobj('Tag', 'plot_tibiaBone_icpregistered'));
        plot3( axes1, ...
               tibiaBone_icpregistered(:,1), ...
               tibiaBone_icpregistered(:,2), ...
               tibiaBone_icpregistered(:,3), ...
               '.g', ...
               'MarkerSize', 0.1, ...
               'Tag', 'plot_tibiaBone_icpregistered');

    end

          
    drawnow;
    
end














