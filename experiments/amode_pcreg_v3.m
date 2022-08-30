clc; clear all; close all;


%% 1) Data Preparation 

% 1) load and prepare the bone point cloud
tibiaBone = stlread('Tibia_R_Rene.stl');
tibiaBone_centroid = mean(tibiaBone.Points, 1);
tibiaBone = bsxfun(@minus, tibiaBone.Points, tibiaBone_centroid);

% 2) load and prepare preregistration area point cloud. sphere properties 
% (e.g. centroid and radius) for determining preregistration area is stored
% in this mat file
load('amode_areasphere_5cm.mat');           
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
% (!) switched the area 1 and 2, because i want: lateral-medial order, not 
% (!) the otherwise, so it matched with amode measurement order
temp = preregistrationArea(2);
preregistrationArea(2) = preregistrationArea(1);
preregistrationArea(1) = temp;

% (!) The bone model and A-mode measurement is in different unit. So, here
% (!) i need to scale the bone model. But i actually dont know how much i
% (!) need to scale up, so in this program, i really use a arbitrary number
tibiaBone_scale = 1300; % super arbritrary number
tibiaBone = tibiaBone * tibiaBone_scale;
for i=1:preregistrationArea_number
    preregistrationArea{i} = preregistrationArea{i}*tibiaBone_scale;
end
preregistrationSphere = preregistrationSphere*tibiaBone_scale;

% 3) Load and prepare the A-mode measurement
load('pc_amode.mat');
samplepoints = pc_amode(16:30, :, :);
% sampleponts_centroid = mean(samplepoints, 1);
% samplepoints = bsxfun(@minus, samplepoints, sampleponts_centroid);

% display bone point cloud
figure1 = figure(1);
figure1.WindowState  = 'maximized';
axes1 = axes('Parent', figure1);
plot3( axes1, ...
       tibiaBone(:,1), ...
       tibiaBone(:,2), ...
       tibiaBone(:,3), ...
       '.', 'Color', [0.7 0.7 0.7], ...
       'MarkerSize', 0.1, ...
       'Tag', 'plot_bone');
xlabel('X'); ylabel('Y'); zlabel('Z');
grid on; axis equal; hold on;

% display the preregistration area
for i=1:preregistrationArea_number
    plot3( axes1, ...
           preregistrationArea{i}(:,1), ...
           preregistrationArea{i}(:,2), ...
           preregistrationArea{i}(:,3), ...
           '.r', ...
           'MarkerSize', 0.1, ...
           'Tag', 'plot_preregistrationarea');
end


delete(findobj('Tag', 'plot_bone'));
delete(findobj('Tag', 'plot_preregistrationarea'));
   
clear temp distance i pc_amode sphere_centroid sphere_radius tibiaBone_centroid tibiaBone_scale
   

%% 2) Registration

n_frame = size(samplepoints,3);

T_betweenframe = repmat( eye(4), 1,1,n_frame);
T_accumulation = repmat( eye(4), 1,1,n_frame);

for frame=1:n_frame
    
    % display the A-mode measurement
    delete(findobj('Tag', 'plot_samplepoint'));
    plot3( axes1, ...
           samplepoints(:,1,frame), ...
           samplepoints(:,2,frame), ...
           samplepoints(:,3,frame), ...
           'ob', ...
           'MarkerFaceColor', 'b', ...
           'Tag', 'plot_samplepoint');
    
    if(frame==1)
    %% (2.1.) Preregistration step
    
        % grouping the sample points of preregistration area with cell. i need
        % to do this because each of preregistration area could have different
        % number of sample points. if i store it in normal array, i dont know
        % which sample points for which preregistration area
        samplepoints_preregArea = [{samplepoints(1:3,   :, frame)}; ...
                                   {samplepoints(4:6,   :, frame)}; ...
                                   {samplepoints(12:15, :, frame)}];

        preregistrationArea_all = [];
        samplepoints_duplicated = [];
        samplepoints_index = 1;
        for i=1:preregistrationArea_number
            preregistrationArea_size = size(preregistrationArea{i},1);
            preregistrationArea_samplingNumber = size(samplepoints_preregArea{i},1);

            for j=1:preregistrationArea_samplingNumber
                preregistrationArea_all = [ preregistrationArea_all; preregistrationArea{i}];
                samplepoints_duplicated = [ samplepoints_duplicated; ...
                                            repmat( samplepoints_preregArea{i}(j,:), preregistrationArea_size, 1)];
                samplepoints_index = samplepoints_index+1;
            end

        end

        [tform, inliers] = estimateGeometricTransform3D( samplepoints_duplicated, ...
                                                         preregistrationArea_all, ...
                                                         'rigid', ...
                                                         'MaxNumTrials', 10000, ...
                                                         'MaxDistance', 15);

        T_coarse = inverseHMat(tform.T');
        tibiaBone_coarseregistered = rigidTransform(T_coarse, tibiaBone);

%         plot3( axes1, ...
%                tibiaBone_coarseregistered(:,1), ...
%                tibiaBone_coarseregistered(:,2), ...
%                tibiaBone_coarseregistered(:,3), ...
%                '.g', ...
%                'MarkerSize', 0.1, ...
%                'Tag', 'plot_femurBone_ransacRegistered');

        %% (2.2) ICP step

        % change the point structure to be suit to matlab icp built in function
        tibiaBonePC_coarseRegistered = pointCloud(tibiaBone_coarseregistered);
        samplepointsPC = pointCloud(samplepoints(:,:,frame));

        % register with icp
        [tform, ~, icp_rmse] = pcregistericp( tibiaBonePC_coarseRegistered, ...
                                              samplepointsPC, ...
                                              'InlierRatio', 0.1, ...
                                              'Verbose', false, ...
                                              'MaxIteration', 30 );

        T_icp = inverseHMat(tform.T');
        T_betweenframe(:,:,frame) = T_icp * T_coarse;
        T_accumulation(:,:,frame) = T_betweenframe(:,:,frame);

        tibiaBone_icpregistered = rigidTransform(T_accumulation(:,:,frame), tibiaBone);
        
        delete(findobj('Tag', 'plot_femurBone_ransacRegistered'));
        plot3( axes1, ...
               tibiaBone_icpregistered(:,1), ...
               tibiaBone_icpregistered(:,2), ...
               tibiaBone_icpregistered(:,3), ...
               '.g', ...
               'MarkerSize', 0.1, ...
               'Tag', 'plot_tibiaBone_icpregistered');
           
        clear preregistrationArea preregistrationArea_all preregistrationArea_number ...
              preregistrationArea_samplingNumber preregistrationArea_size ...
              preregistrationSphere samplepoints_duplicated samplepoints_index ...
              samplepoints_preregArea;

    else
        tform = estimateGeometricTransform3D( samplepoints(:,:, frame-1), ...
                                              samplepoints(:,:, frame), ...
                                              'rigid');
                                          
        T_coarse= tform.T';
        tibiaBone_coarseregistered = rigidTransform(T_coarse, tibiaBone_icpregistered);
                                          
%         delete(findobj('Tag', 'plot_tibiaBone_icpregistered'))
%         plot3( axes1, ...
%                tibiaBone_coarseregistered(:,1), ...
%                tibiaBone_coarseregistered(:,2), ...
%                tibiaBone_coarseregistered(:,3), ...
%                '.g', ...
%                'MarkerSize', 0.1, ...
%                'Tag', 'plot_femurBone_ransacRegistered');
        
        % change the point structure to be suit to matlab icp built in function
        tibiaBonePC_coarseRegistered = pointCloud(tibiaBone_coarseregistered);
        samplepointsPC = pointCloud(samplepoints(:,:,frame));

        % register with icp
        [tform, ~, icp_rmse] = pcregistericp( tibiaBonePC_coarseRegistered, ...
                                              samplepointsPC, ...
                                              'InlierRatio', 0.1, ...
                                              'Verbose', false, ...
                                              'MaxIteration', 30 );

        T_icp = tform.T';        
        T_betweenframe(:,:,frame) = T_icp * T_coarse;
        
        T_untilcurrentframe = eye(4);
        for i=1:(frame-1)
            T_untilcurrentframe = T_betweenframe(:,:,i) * T_untilcurrentframe;
        end        
        T_accumulation(:,:,frame) = T_icp * T_coarse * T_untilcurrentframe;
        tibiaBone_icpregistered = rigidTransform(T_accumulation(:,:,frame), tibiaBone);
        
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














