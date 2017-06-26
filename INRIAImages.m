function [] = INRIAImages()
% Detection and segmentation of elongated structures in images
%
% Version:      v1.0 
% Author:       Nicola Strisciuglio (nic.strisciuglio@gmail.com)
% 
% Application of the B-COSFIRE filters for detection of elongated
% structures in images.
%
% This code provides the benchmark results on the images of the INRIA line network data
% set used in the paper Strisciuglio, N. Petkov, N. Delineation of line patterns in
% images using B-COSFIRE filters, IWOBI 2017".
%
% If you use this software please cite the following paper:
%
% George Azzopardi, Nicola Strisciuglio, Mario Vento, Nicolai Petkov, 
% Trainable COSFIRE filters for vessel delineation with application to retinal images, 
% Medical Image Analysis, Volume 19 , Issue 1 , 46 - 57, ISSN 1361-8415
%
% Strisciuglio, N. Petkov, N. "Delineation of line patterns in images
% using B-COSFIRE filters", IWOBI 2017

    if ~isdeployed
        addpath('./COSFIRE');
        addpath('./Gabor');
        addpath('./Performance');
        addpath('./Preprocessing');
    end

    % NOTE: It requires a compiled mex-file of the fast implementation 
    % of the max-blurring function.
    if ~exist('./COSFIRE/dilate')
        BeforeUsing();
    end

    
    %% Process images
    LEAF = 1;
    ROAD = 2;
    RIVER = 3;
    TILE = 4;
    images = [LEAF, ROAD, RIVER, TILE];
    
    for n = 1:numel(images)    
        [dname, eval_radius, params] = GetParameters(images(n));
        
        disp(['Processing image: ' dname]);
        [img, response, GT, mask] = ProcessImage(images(n), dname, params);
        [th, tpr, fpr, mcc] = ComputePerformance(response, GT, mask, eval_radius);
        
        figure;
        subplot(1,3,1); imagesc(img); axis off; axis image; title(['Image: ' dname]);
        subplot(1,3,2); imagesc(response); colormap gray; axis off; axis image; title('B-COSFIRE response');
        subplot(1,3,3); imagesc((rescaleImage(response, 0, 255) + 1) .* mask > th); colormap gray; axis off; axis image; title(['Binary - Mcc: ' num2str(mcc)]);
        
        disp(['TPR: ' num2str(tpr) ' - FPR: ' num2str(fpr) ' - MCC: ' num2str(mcc)]);
    end
    
    
end


function [imageInput, response, GT, mask] = ProcessImage(dataset, dname, params)
    datasetpath = './data/INRIA_line_networks/';
    LEAF = 1;
    ROAD = 2;
    RIVER = 3;
    TILE = 4;
    
    %% B-COSFIRE filter configuration
    % Symmetric filter params and configuration
    x = 101; y = 101; % center
    line1(:, :) = zeros(201);
    line1(:, x) = 1; %prototype line

    symmfilter = cell(1);
    symm_params = SystemConfig;
    % COSFIRE params
    symm_params.inputfilter.DoG.sigmalist = params.sigma;
    symm_params.COSFIRE.rholist = 0:2:params.len;
    symm_params.COSFIRE.sigma0 = params.sigma0 / 6;
    symm_params.COSFIRE.alpha = params.alpha / 6;
    % Orientations
    symm_params.invariance.rotation.psilist = 0 : pi / params.noriens : pi - pi / params.noriens;
    % Configuration
    symmfilter{1} = configureCOSFIRE(line1, round([y x]), symm_params);

    % Prepare the filter set
    filterset(1) = symmfilter;

    % Inhibitory part configuration
%     if inhibFactor ~= 0
%         inhibSymmfilter{1} = symmfilter{1};
%         inhibSymmfilter{1}.tuples(1,:) = 0;
%         inhibSymmfilter{1}.tuples(2,:) = inhibSymmfilter{1}.tuples(2,:) * stdFactor;
%         filterset(2) = inhibSymmfilter;
%     end

    %% Processing
    imageInput = double(imread([datasetpath dname '/' dname '.bmp'])) ./ 255;
    if size(imageInput, 3) > 1
        imageInput = rgb2gray(imageInput);
    end
    %imageInput = double(imageInput) ./ 255;

    if dataset == RIVER || dataset == TILE 
        imageInput = imcomplement(imageInput);
    end

    % Read the corresponding ground-truth
    GT = double(imread([datasetpath dname '/' dname '_GT.bmp'])) ./ 255;
    if size(GT, 3) > 1
        GT = GT(:, :, 1);
    end
    GT = imcomplement(GT);

    % Prepare input image
    if dataset == ROAD
        imageInput = imresize(imageInput, size(GT));
    end

    % Prepare mask
    mask = ones(size(imageInput, 1), size(imageInput, 2), 1);
    if dataset == LEAF
        mask = double(rgb2gray(imread([datasetpath dname '/' dname '_mask.bmp']))) ./ 255;
    end

    % Pad input image to avoid border effects
    NP = 50;
    imageInput = padarray(imageInput, [NP NP], 'replicate');

    %% Filter response
    %tic;
    %response = applyCOSFIRE(imageInput, filterset);
    tuple = computeTuples(imageInput, filterset);
    response = applyCOSFIRE_inhib(imageInput, filterset, 0, tuple);
    %toc;
    response = response{1};
    % unpad response image
    response = response(NP+1:end-NP, NP+1:end-NP);
    % unpad original image
    imageInput = imageInput(NP+1:end-NP, NP+1:end-NP);
end

function [dbname, eval_radius, params] = GetParameters(dataset)
    % These parameters are reported in the paper:
    % Strisciuglio, N. Petkov, N. "Delineation of line patterns in images
    % using B-COSFIRE filters", IWOBI 2017
    LEAF = 1;
    ROAD = 2;
    RIVER = 3;
    TILE = 4;
    
    if dataset == LEAF
        dbname = 'leaf';
        eval_radius = 0;
        params.sigma = 2.9;
        params.len = 10;
        params.sigma0 = 2;
        params.alpha = 0.8;
        params.noriens = 12;
    elseif dataset == ROAD
        dbname = 'road';
        eval_radius = 1;
        params.sigma = 1.7;
        params.len = 22;
        params.sigma0 = 4;
        params.alpha = 1.1;
        params.noriens = 12;
    elseif dataset == RIVER
        dbname = 'river';
        eval_radius = 0;
        params.sigma = 2.4;
        params.len = 12;
        params.sigma0 = 3;
        params.alpha = 0.8;
        params.noriens = 12;
    elseif dataset == TILE
        dbname = 'tiles';
        eval_radius = 0;
        params.sigma = 1.4;
        params.len = 8;
        params.sigma0 = 2;
        params.alpha = 0.4;
        params.noriens = 12;
    end
end

function [threshold, tpr, fpr, mcc] = ComputePerformance(response, GT, mask, eval_radius)
    scaledresp = rescaleImage(response, 0, 255);
    numth = numel(0:255);
    TPR = [];
    FPR = [];
    MCC = [];
    % CAL = [];
    %RESULTS = [];
    for j = 1:numth
        binresp = (scaledresp + 1 > j) .* mask;
        % Standard evaluation metrics
        thresult = EvaluateINRIA(binresp, GT, eval_radius);

        % CAL
%         [SG, gtdil, gtthin] = getGTInfo(binresp, GT, mask);
%         [calTMP, ~, ~, ~] = CAL_evaluate_binary(binresp, GT, mask, SG, gtdil, gtthin);

        % Results accumulation
        %RESULTS = [RESULTS; thresult];
        FPR = [FPR thresult(5)];    
        TPR = [TPR thresult(6)];
        MCC = [MCC thresult(7)]; 
        %CAL = [CAL calTMP]; 
        binresp = [];
    end

    % Best threshold (trade-off TPR and FPR)
%     D = sqrt((ones(1, numth) - TPR).^2 + FPR.^2);
%     [m, thopt] = min(D);
%     res = [thopt RESULTS(thopt, :);];

    % Best threshold (the one that maximizes MCC)
    [mcc, threshold] = max(MCC);
    tpr = TPR(threshold);
    fpr = FPR(threshold);
    
    %res_mcc = [thmcc RESULTS(thmcc, :)]; % CAL(thmcc)];
end
