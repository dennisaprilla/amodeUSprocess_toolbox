function [cartesianPoints] = homogeneous2cartesian(homogeneousPoints)
%HOMOGENEOUS2CARTESIAN Summary of this function goes here
%   Detailed explanation goes here
    cartesianPoints = homogeneousPoints(1:3,:)';
end

