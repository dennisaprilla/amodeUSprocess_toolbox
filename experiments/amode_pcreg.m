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
% switched the area 1 and 2, because i want: lateral-medial order, not the
% otherwise, so it matched with amode measurement order
temp = preregistrationArea(2);
preregistrationArea(2) = preregistrationArea(1);
preregistrationArea(1) = temp;

% (!) The bone model and A-mode measurement is in different unit. So, here
% (!) i need to scale the bone model. But i actually dont know how much i
% (!) need to scale up, so in this program, i really use a arbitrary number
tibiaBone_scale = 1400; % super arbritrary number
tibiaBone = tibiaBone * tibiaBone_scale;
for i=1:preregistrationArea_number
    preregistrationArea{i} = preregistrationArea{i}*tibiaBone_scale;
end
preregistrationSphere = preregistrationSphere*tibiaBone_scale;

% 3) Load and prepare the A-mode measurement
load('pc_amode.mat');
samplepoints = pc_amode(16:30, :, :);
sampleponts_centroid = mean(samplepoints, 1);
samplepoints = bsxfun(@minus, samplepoints, sampleponts_centroid);


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

% display the A-mode measurement
plot3( axes1, ...
       samplepoints(:,1,1), ...
       samplepoints(:,2,1), ...
       samplepoints(:,3,1), ...
       'ob', ...
       'MarkerFaceColor', 'b', ...
       'Tag', 'plot_samplepoint');
   
clear distance i pc_amode sphere_centroid sphere_radius tibiaBone_centroid tibiaBone_scale

% rotationZ_range     = deg2rad(0:5:180)';
% rotationZ_matrix    = eul2rotm( [rotationZ_range, zeros(length(rotationZ_range), 2)], 'ZYX' );
% 
% for i=1:size(rotationZ_matrix, 3)
%     T = [rotationZ_matrix(:,:,i), [0 0 0]'; 0 0 0 1];
%     tibiaBone_transformed = rigidTransform( T, tibiaBone );
%     
%     delete(findobj('Tag', 'plot_bone'));
%     plot3( axes1, ...
%            tibiaBone_transformed(:,1), ...
%            tibiaBone_transformed(:,2), ...
%            tibiaBone_transformed(:,3), ...
%            '.', 'Color', [0.7 0.7 0.7], ...
%            'MarkerSize', 0.1, ...
%            'Tag', 'plot_bone');
% end

% R = eul2rotm( [deg2rad(140),0,0], 'ZYX' );
% T = [R, [0 0 0]'; 0 0 0 1];
% tibiaBone = rigidTransform( T, tibiaBone );
% for i=1:preregistrationArea_number
%     preregistrationArea{i} = rigidTransform( T, preregistrationArea{i} );
% end
% preregistrationSphere(:,1:3) = rigidTransform(T, preregistrationSphere(:,1:3));

% delete(findobj('Tag', 'plot_bone'));
% plot3( axes1, ...
%        tibiaBone(:,1), ...
%        tibiaBone(:,2), ...
%        tibiaBone(:,3), ...
%        '.', 'Color', [0.7 0.7 0.7], ...
%        'MarkerSize', 0.1, ...
%        'Tag', 'plot_bone');
   
   

%% 2) Registration

n_frame = size(samplepoints,3);

% calculate the centroid of preregistration areas

for frame=1:n_frame
    %% (2.1.) Preregistration step
    
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
    
    % display the correspondences for sanity check
    % loop for every preregistration Area
    for i=1:preregistrationArea_number
        % loop for every number of sample in current preregistration area
        n_samplepoints_preregArea = size(samplepoints_preregArea{i},1);
        for j=1:n_samplepoints_preregArea
            % get the point pair
            temp_pointPair = [samplepoints_preregArea{i}(j,:); preregistrationArea_assumedCentroid{i}(j,:)];
            % draw line between the point pair so we can se it clearly
            plot3( axes1, ...
                   temp_pointPair(:,1), temp_pointPair(:,2), temp_pointPair(:,3), ...
                   '-m', 'Tag', 'plot_pointpair');
        end
    end
    
	test1 = cell2mat(preregistrationArea_assumedCentroid);
	test2 = cell2mat(samplepoints_preregArea);
    test3 = cell2mat(preregistrationArea);
%     plot3( axes1, ...
%            test3(:,1), ...
%            test3(:,2), ...
%            test3(:,3), ...
%            'og', ...
%            'MarkerFaceColor', 'g', ...
%            'Tag', 'plot_test');
    
	% estimate the transformation 
    [tform] = estimateGeometricTransform3D( test1, ...
                                            test2, ...
                                            'rigid', ...
                                            'MaxNumTrials', 10000, ...
                                            'MaxDistance', 50);
                                                        
                                                        
    
%     % change the point structure to be suit to matlab icp built in function
%     test2PC = pointCloud(test2);
%     test3PC = pointCloud(test3);
%     % register with icp
%     tform = pcregistericp( test2PC, test3PC );

    T = tform.T';
    tibiaBone_transformed = rigidTransform(T, tibiaBone);    
    
    delete(findobj('Tag', 'plot_pointpair'));
    delete(findobj('Tag', 'plot_test'));
    delete(findobj('Tag', 'plot_bone'));
    plot3( axes1, ...
           tibiaBone_transformed(:,1), ...
           tibiaBone_transformed(:,2), ...
           tibiaBone_transformed(:,3), ...
           '.g', ...
           'MarkerSize', 0.1, ...
           'Tag', 'plot_femurBone_fineRegistered');
       
    break
end














