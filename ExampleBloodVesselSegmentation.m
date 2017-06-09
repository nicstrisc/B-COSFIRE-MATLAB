function [output, oriensmap] = ExampleBloodVesselSegmentation( )
% Delineation of blood vessels in retinal images based on combination of BCOSFIRE filter responses
%
% Version:      v1.3 
% Author(s):    Nicola Strisciuglio (nic.strisciuglio@gmail.com)
%               George Azzopardi
% 
% Description:
% Example application for the B-COSFIRE filters for delineation of
% elongated structures in images. This example demonstrates how to
% configure different types of filters (line and line-ending detectors) and
% how to combine their responses. 
%
% Application() returns:
%      output       A struct that contains the BCOSFIRE filters response
%                   and the final segmented image. In details
%                       - output.respimage: response of the combination of a symmetric and an
%                         asymemtric COSFIRE filters
%                       - output.segmented: the binary output image after
%                         thresholding
%      oriensmap    [optional] map of the orientation that gives the strongest 
%                   response at each pixel. 
%
% If you use this software please cite the following paper:
%
% "George Azzopardi, Nicola Strisciuglio, Mario Vento, Nicolai Petkov, 
% Trainable COSFIRE filters for vessel delineation with application to retinal images, 
% Medical Image Analysis, Volume 19 , Issue 1 , 46 - 57, ISSN 1361-8415
%

% Requires the compiling of the mex-file for the fast implementation of the
% max-blurring function in case it is not compiled already
if ~exist('./COSFIRE/dilate.*')
    BeforeUsing();
end


% Example with an image from DRIVE data set
image = double(imread('./data/DRIVE/test/images/01_test.tif')) ./ 255;

%% Symmetric filter params
symmfilter = struct();
symmfilter.sigma     = 2.4;
symmfilter.len       = 8;
symmfilter.sigma0    = 3;
symmfilter.alpha     = 0.7;

%% Asymmetric filter params
asymmfilter = struct();
asymmfilter.sigma     = 1.8;
asymmfilter.len       = 22;
asymmfilter.sigma0    = 2;
asymmfilter.alpha     = 0.1;

%% Filters responses
% Tresholds values
% DRIVE -> preprocessthresh = 0.5, thresh = 37
% STARE -> preprocessthresh = 0.5, thresh = 40
% CHASE_DB1 -> preprocessthresh = 0.1, thresh = 38
output = struct();
if nargout == 1 || nargout == 0
    [output.respimage] = BCOSFIRE(image, symmfilter, asymmfilter, 0.5);
elseif nargout == 2
    [output.respimage, oriensmap] = BCOSFIRE(image, symmfilter, asymmfilter, 0.5);
else
    error('ERROR: too many output arguments.');
end

output.segmented = (output.respimage > 37);

if nargout == 0
    figure; imagesc(output.respimage); colormap(gray); axis off; axis image; title('B-COSFIRE response image');
    figure; imagesc(output.segmented); colormap(gray); axis off; axis image; title('B-COSFIRE segmented image');
end