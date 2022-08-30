clc; clear all; close all;
addpath('..\functions\displays\');

%% 1) Data Preparation 

figure1 = figure(1);
figure1.WindowState  = 'maximized';
axes1 = axes('Parent', figure1);

% 1) load and prepare the bone point cloud
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

% 2) Prepare preregistration area point cloud. sphere properties  (e.g. 
% centroid and radius) for determining preregistration area is stored
% in this structure
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

% 3) Load and prepare the A-mode measurement
load('pc_amode.mat');
samplepoints = pc_amode(16:30, :, :);

% % display the A-mode measurement
% plot3( axes1, ...
%        samplepoints(:,1,1), ...
%        samplepoints(:,2,1), ...
%        samplepoints(:,3,1), ...
%        'ob', ...
%        'MarkerFaceColor', 'b', ...
%        'Tag', 'plot_samplepoint');
   
% display global coordinate system base vector
display_basevector(axes1, [0 0 0], [1 0 0; 0 1 0; 0 0 1], 50, 'plot_basevector');

clear distance i pc_amode sphere_centroid sphere_radius tibiaBone_centroid tibiaBone_scale


%% 2) Registration

delete(findobj('Tag', 'plot_bone'));
delete(findobj('Tag', 'plot_preregistrationarea'));

n_frame = size(samplepoints,3);
T_allframes = repmat( eye(4), 1,1,n_frame);

% grouping the sample points of preregistration area with cell. i need
% to do this because each of preregistration area could have different
% number of sample points. if i store it in normal array, i dont know
% which sample points for which preregistration area
samplepoints_preregArea = [{samplepoints(1:3,   :,1)}; ...
                           {samplepoints(4:6,   :,1)}; ...
                           {samplepoints(12:15, :,1)}];

% Code below is using center point of the registration area as Kenan's work
% described it. We could exploit the preregistration sphere to search the
% centroid of the preregistration area. We assume that nearest point to the
% preregistration sphere centroid is the preregistration area centroid
preregistrationSphere_centroid = preregistrationSphere(:, 1:preregistrationArea_number);
preregistrationArea_assumedCentroid = [];

% The output of this loop is a matrix with ( preregistrationArea_number * 
% preregistrationArea_samplingNumber) rows. Remember, since we structurally
% arranged the sample point, this matrix will match with them.
for i=1:preregistrationArea_number
    % search for the nearest neighbor index
    [nearestIndex, ~] = knnsearch(preregistrationArea{i}, preregistrationSphere_centroid(i,:));

    % obtain the centroid 
    assumedCentroid = preregistrationArea{i}(nearestIndex, :);

    % since there are multiple sample point in one preregistration area,
    % and registration algorithm requires 1-to-1 point pairs, so we
    % duplicate the centroid as the number
    n_samplepoints_preregArea = size(samplepoints_preregArea{i},1);
    preregistrationArea_assumedCentroid = [ preregistrationArea_assumedCentroid; ...
                                            {repmat(assumedCentroid, n_samplepoints_preregArea, 1)} ];

end

for frame=1:n_frame
    
    delete(findobj('Tag', 'plot_samplepoint'));
    delete(findobj('Tag', 'plot_tibiaBone_icpregistered'));
    delete(findobj('Tag', 'plot_preregistrationArea_icpregistered'));
    
	% display the A-mode measurement
    plot3( axes1, ...
           samplepoints(:,1,frame), ...
           samplepoints(:,2,frame), ...
           samplepoints(:,3,frame), ...
           'ob', ...
           'MarkerFaceColor', 'b', ...
           'Tag', 'plot_samplepoint');
       
    %% Preregistration Step

    % grouping the sample points of preregistration area with cell. i need
    % to do this because each of preregistration area could have different
    % number of sample points. if i store it in normal array, i dont know
    % which sample points for which preregistration area
    samplepoints_preregArea = [{samplepoints(1:3,   :,frame)}; ...
                               {samplepoints(4:6,   :,frame)}; ...
                               {samplepoints(12:15, :,frame)}];
                           
    
%     % display the correspondences for sanity check
%     % loop for every preregistration Area
%     for i=1:preregistrationArea_number
%         % loop for every number of sample in current preregistration area
%         n_samplepoints_preregArea = size(samplepoints_preregArea{i},1);
%         for j=1:n_samplepoints_preregArea
%             % get the point pair
%             temp_pointPair = [samplepoints_preregArea{i}(j,:); preregistrationArea_assumedCentroid{i}(j,:)];
%             % draw line between the point pair so we can se it clearly
%             plot3( axes1, ...
%                    temp_pointPair(:,1), temp_pointPair(:,2), temp_pointPair(:,3), ...
%                    '-m', 'Tag', 'plot_pointpair');
%         end
%     end
    
	% estimate the transformation 
    [tform] = estimateGeometricTransform3D( cell2mat(preregistrationArea_assumedCentroid), ...
                                            cell2mat(samplepoints_preregArea), ...
                                            'rigid', ...
                                            'MaxNumTrials', 10000, ...
                                            'MaxDistance', 50);
    T_coarse = tform.T';
    tibiaBone_coarseregistered = rigidTransform(T_coarse, tibiaBone);
    preregistrationArea_coarseregistered = rigidTransform(T_coarse, cell2mat(preregistrationArea));
    
%     delete(findobj('Tag', 'plot_pointpair'));
%     plot3( axes1, ...
%            tibiaBone_coarseregistered(:,1), ...
%            tibiaBone_coarseregistered(:,2), ...
%            tibiaBone_coarseregistered(:,3), ...
%            '.g', ...
%            'MarkerSize', 0.1, ...
%            'Tag', 'plot_tibiaBone_coarseRegistered');
%     plot3( axes1, ...
%            preregistrationArea_coarseregistered(:,1), ...
%            preregistrationArea_coarseregistered(:,2), ...
%            preregistrationArea_coarseregistered(:,3), ...
%            '.r', ...
%            'MarkerSize', 0.1, ...
%            'Tag', 'plot_preregistrationArea_coarseRegistered');
       
	%% ICP Step
    
    % change the point structure to be suit to matlab icp built in function
    test1 = pointCloud(tibiaBone_coarseregistered);
    test2 = pointCloud(preregistrationArea_coarseregistered);
    test3 = pointCloud(cell2mat(samplepoints_preregArea));

    % register with icp
    [tform, ~, icp_rmse] = pcregistericp( test3, ...
                                          test2, ...
                                          'InlierRatio', 1, ...
                                          'Verbose', false, ...
                                          'MaxIteration', 30);
                                      
    T_icp = inverseHMat(tform.T');
    T_allframes(:,:,frame) = T_icp * T_coarse;
    tibiaBone_icpregistered = rigidTransform(T_allframes(:,:,frame), tibiaBone);
    preregistrationArea_icpregistered = rigidTransform(T_allframes(:,:,frame), cell2mat(preregistrationArea));
       
    delete(findobj('Tag', 'plot_tibiaBone_coarseRegistered'));
    delete(findobj('Tag', 'plot_preregistrationArea_coarseRegistered'));
    plot3( axes1, ...
           tibiaBone_icpregistered(:,1), ...
           tibiaBone_icpregistered(:,2), ...
           tibiaBone_icpregistered(:,3), ...
           '.g', ...
           'MarkerSize', 0.1, ...
           'Tag', 'plot_tibiaBone_icpregistered');
%     plot3( axes1, ...
%            preregistrationArea_icpregistered(:,1), ...
%            preregistrationArea_icpregistered(:,2), ...
%            preregistrationArea_icpregistered(:,3), ...
%            '.r', ...
%            'MarkerSize', 0.1, ...
%            'Tag', 'plot_preregistrationArea_icpregistered');
       
	drawnow;
    
end














