function [invH] = inverseHMat(H)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

    R = H(1:3, 1:3);
    t = H(1:3, 4);
    
    invH = [R', -R'*t; 0 0 0 1];

end

