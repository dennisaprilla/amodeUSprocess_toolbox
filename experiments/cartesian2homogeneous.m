function [homogeneousPoints] = cartesian2homogeneous(cartesianPoints)
%CARTESIAN2HOMOGENEOUS Summary of this function goes here
%   Detailed explanation goes here
    points_number = size( cartesianPoints, 1 );
    
    homogeneousPoints = [ cartesianPoints'; ones(1, points_number) ];
end

