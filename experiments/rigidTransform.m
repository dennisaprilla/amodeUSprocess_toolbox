function [cartesianPoints_transformed] = rigidTransform(homogeneousMatrix, Points)
%RIGIDTRANSFORM Summary of this function goes here
%   Detailed explanation goes here
    homogeneousPoint_flag = true;
    
    dimension = size(Points);
    if ( dimension(2)==4 )
        if all(Points(4,:) == 1)
            homogeneousPoint_flag = true;
        else
            homogeneousPoint_flag = false;
        end
    else
        homogeneousPoint_flag = false;
    end
            
    if (homogeneousPoint_flag)
        cartesianPoints_transformed = homogeneous2cartesian( homogeneousMatrix * Points );
    else
        cartesianPoints_transformed = homogeneous2cartesian( homogeneousMatrix * cartesian2homogeneous(Points) );
    end
end

