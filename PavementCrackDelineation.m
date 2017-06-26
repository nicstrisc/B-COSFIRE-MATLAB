function [ output_args ] = PavementCrackDelineation( input_args )
return;
CRACK_IVC = 1;
CRACK_PV14 = 2;


if nargin < 8 
    stdFactor = 0;
    inhibFactor = 0;
end

if dataset == CRACK_IVC
    dname = 'crack_ivc_data';
    imagesdir = 'images';
    gtdir = 'gt';
    prefix_gt = 'B_';
elseif dataset == CRACK_PV14
    dname = 'CrackPV14';
    imagesdir = 'cracks14';        
    gtdir = 'cracks14_gt';
    prefix_gt = '';
end

outputdir = [experimentpath 's' num2str(sigma) '_r' num2str(len) '_s0_' num2str(sigma0) '_a' num2str(alpha) '_sf' num2str(stdFactor) '_if' num2str(inhibFactor) '/'];
if ~exist(outputdir)
    mkdir(outputdir);
end

% Binarization thresholds
thresholds = 0.01:0.01:0.99;
nthresholds = numel(thresholds);

if ~exist([outputdir 'result.mat'], 'file')
    %% Symmetric filter params and configuration
    x = 101; y = 101; % center
    line1(:, :) = zeros(201);
    line1(:, x) = 1; %prototype line

    % Symmetric filter params
    symmfilter = cell(1);
    symm_params = SystemConfig;
    % COSFIRE params
    symm_params.inputfilter.DoG.sigmalist = sigma;
    symm_params.COSFIRE.rholist = 0:2:len;
    symm_params.COSFIRE.sigma0 = sigma0 / 6;
    symm_params.COSFIRE.alpha = alpha / 6;
    % Orientations
    numoriens = 12;
    symm_params.invariance.rotation.psilist = 0:pi/numoriens:pi-pi/numoriens;
    % Configuration
    symmfilter{1} = configureCOSFIRE(line1, round([y x]), symm_params);

    % Prepare the filter set
    filterset(1) = symmfilter;

    %% Inhibitory part configuration
    if inhibFactor ~= 0
        inhibSymmfilter{1} = symmfilter{1};
        inhibSymmfilter{1}.tuples(1,:) = 0;
        inhibSymmfilter{1}.tuples(2,:) = inhibSymmfilter{1}.tuples(2,:) * stdFactor;
        filterset(2) = inhibSymmfilter;
    end

    files = rdir([datasetpath dname '/' imagesdir  '/*.bmp']);
    nfiles = size(files, 1);

    % Initialize result matrix
    nmetrics = 6;
    RESULTS = zeros(nfiles + 1, nmetrics, nthresholds);
    time = zeros(1, nfiles);
    for n = 1:nfiles
        imageInput = double(imread(files(n).name)) ./ 255;

%             if ~isdeployed
%                 figure; 
%                 subplot(2,3,1);
%                 imagesc(imageInput); colormap gray; title('Original');
%             end


        %imageInput = adapthisteq(imageInput);
        %imageInput = medfilt2(imageInput, [5 5]);
        %imageInput = imguidedfilter(imageInput,'NeighborhoodSize',[11 11]); 
        %imageInput = imadjust(imageInput);
%             if ~isdeployed
%                 subplot(2,3,2);
%                 imagesc(imageInput); colormap gray; title('Filtered');
%             end


        [p name ext] = fileparts(files(n).name);
        gt = double(imread([datasetpath dname '/' gtdir '/' prefix_gt name '.bmp'])) ./ 255;

%             if ~isdeployed
%                 imagesc(gt); colormap gray; title('GT');
%                 subplot(2,3,3);
%             end
        tic;
        imageInput = imcomplement(imageInput);

        % Pad input image to avoid border effects
        NP = 50; imageInput = padarray(imageInput, [NP NP], 'replicate');

        %% Filter response
        tuple = computeTuples(imageInput, filterset);
        [response rotations] = applyCOSFIRE_inhib(imageInput, filterset, inhibFactor, tuple);
        response = response{1};
        response = response(NP+1:end-NP, NP+1:end-NP);
        time1 = toc;
%             if ~isdeployed
%                 subplot(2,3,4);
%                 imagesc(response); colormap gray;
%             end

        rotations_final = zeros(size(response, 1), size(response, 2), size(rotations, 3));
        for j = 1:size(rotations, 3)
            rotations_final(:,:,j) = rotations(NP+1:end-NP, NP+1:end-NP, j);
        end

        % Evaluation
        for j = 1:nthresholds
            binImg = binarize(rotations_final, thresholds(j));

            binImg2 = bwmorph(binImg, 'close');
            binImg2 = bwmorph(binImg2,'skel',Inf);
            imwrite(binImg2 .* 255, 'skeleton.jpg');
            [cpt2, crt2, F2] = evaluate(binImg2, gt, 2);
            [cpt3, crt3, F3] = evaluate(binImg2, gt, 3);

            RESULTS(n, :, j) = [cpt2, crt2, F2, cpt3, crt3, F3];
        end

        tic;
        binImg = binarize(rotations_final, 0.49);
        binImg2 = bwmorph(binImg, 'close');
        binImg2 = bwmorph(binImg2,'skel',Inf);
        time2 = toc;

        time(n) = time1 + time2;
    end
    disp(['Mean execution time: ' num2str(mean(time))]);
    disp(['Std execution time: ' num2str(std(time))]);
    % Average Results
    avg_results = reshape(mean(RESULTS(1:nfiles, :, :)), nmetrics, nthresholds)';
%         for j = 1:nthresholds
%             RESULTS(end, :, j) = avgRES(j, :);
%         end
    [M idx] = max(avg_results(:,3))

    % Save results
    %dlmwrite([outputdir 'result.txt'], res);        
    save([outputdir 'result.mat'], 'avg_results');
    save([outputdir 'RESULTS.mat'], 'RESULTS');
    RESULTS = [];
end

end

