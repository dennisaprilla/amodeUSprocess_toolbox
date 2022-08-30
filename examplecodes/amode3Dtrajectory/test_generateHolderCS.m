%% Several Notes from Dennis
% - This program is used to generate ultrasound coordinate in Holder Local
%   Coordinate System.
% - It is very unfortunate I can't have CAD file of the last generation of
%   the holder from Kenan, so what i did is measure the position of the probe
%   manually, using a very sophisticated measurement ever (aka, ruler) and
%   wrote them down.
% - I will use this only for the first measurement trial. Just to make sure
%   everything is okay.
% - Ignore this file. i want to delete it actually, but affraid i will use
%   this during my coding..

clear; clc;

n_ust = 30;
t_holder_usttip = repmat(zeros(3,1), 1, 1, n_ust);

marker_radius = 6.5;
z_offset = 15.5 + marker_radius;

% TBEL
t_holder_usttip(:,:,16) = [ 10.5; 16.5; -z_offset ]; % t_tib_epi_lat_16
t_holder_usttip(:,:,17) = [ 35.5; 16.5; -z_offset ]; % t_tib_epi_lat_17
t_holder_usttip(:,:,18) = [ 21.5; 41.0; -z_offset ]; % t_tib_epi_lat_18

% TBEM
t_holder_usttip(:,:,19) = [ 10.5; 16.5; -z_offset ]; % t_tib_epi_med_19
t_holder_usttip(:,:,20) = [ 35.5; 16.5; -z_offset ]; % t_tib_epi_med_20
t_holder_usttip(:,:,21) = [ 21.5; 41.0; -z_offset ]; % t_tib_epi_med_21

% TBM
t_holder_usttip(:,:,22) = [ 16.5; -20.0; -z_offset ]; % t_tib_mid_22
t_holder_usttip(:,:,23) = [ 27.0;   0.0; -z_offset ]; % t_tib_mid_23
t_holder_usttip(:,:,24) = [ 16.5;  20.0; -z_offset ]; % t_tib_mid_24
t_holder_usttip(:,:,25) = [ 27.0;  40.0; -z_offset ]; % t_tib_mid_25
t_holder_usttip(:,:,26) = [ 16.5;  60.0; -z_offset ]; % t_tib_mid_26

% ANK
t_holder_usttip(:,:,27) = [ 18.5; 37.0; -z_offset ]; % t_tib_ank_27
t_holder_usttip(:,:,28) = [  7.5; 17.0; -z_offset ]; % t_tib_ank_28
t_holder_usttip(:,:,29) = [ 30.0; 17.0; -z_offset ]; % t_tib_ank_29
t_holder_usttip(:,:,30) = [ 18.5; -3.0; -z_offset ]; % t_tib_ank_30


%%
% So, in order to transform depth by ultrasound system, we need to make a
% series of transformation
% 1. Global to Holder
% 2. Holder to Probe
% 3. Probe to Depth

T_holder_usttip = repmat(eye(4), 1, 1, n_ust);

R_holder_usttip = -eye(3);

for i=1:n_ust
    T_holder_usttip(:,:,i) = [ R_holder_usttip, t_holder_usttip(:,:,i); zeros(1,3), 1];    
end

save('T_holder_usttip.mat', 'T_holder_usttip');


