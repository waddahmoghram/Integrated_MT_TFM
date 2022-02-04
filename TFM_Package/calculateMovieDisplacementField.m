% calculateMovieDisplacementField calculate the displacement field
%{
    calculateMovieDisplacementField 

    SYNOPSIS calculateMovieDisplacementField(movieData,paramsIn)

    INPUT   
      movieData - A MovieData object describing the movie to be processed

      paramsIn - Structure with inputs for optional parameters. Theedit 
      parameters should be stored as fields in the structure, with the field
      names and possible values as described below


    Copyright (C) 2019, Danuser Lab - UTSouthwestern 

    This file is part of TFM_Package.

    TFM_Package is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    TFM_Package is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with TFM_Package.  If not, see <http://www.gnu.org/licenses/>.



    Sebastien Besson, Sep 2011
    Sangyoon Han, From Oct 2012. Last updated: May 2017
%}

function calculateMovieDisplacementField(movieData,varargin)
%% ----------- Input ----------- %%
    %Check input
    ip = inputParser;
    ip.CaseSensitive = false;
    ip.addRequired('movieData', @(x) isa(x,'MovieData'));
    ip.addOptional('paramsIn',[], @isstruct);
    ip.parse(movieData,varargin{:});
    paramsIn = ip.Results.paramsIn;
    
    %----------------------------------
    %Get the indices of any previous stage drift processes                                                                     
    iProc = movieData.getProcessIndex('DisplacementFieldCalculationProcess',1,0);
    %If the process doesn't exist, create it
    if isempty(iProc)
        iProc = numel(movieData.processes_)+1;
        movieData.addProcess(DisplacementFieldCalculationProcess(movieData,...
            movieData.outputDirectory_));
        movieData.processes_{iProc}.startTime_ = clock;   
    end
    %----------------------------------
    displFieldProc = movieData.processes_{iProc};
    %Parse input, store in parameter structure
    displacementParameters = parseProcessParams(displFieldProc,paramsIn);
    addNonLocMaxBeads = displacementParameters.addNonLocMaxBeads;
    displacementParameters.usePIVSuite=true;
    
    %_________________ added by WIM on 2019-12-11
    UseFitMixtureModel = false;                 % revert back to true on 2020-08-26 and see how that affects Controlled displacement
    %_______________________________________________

%% --------------- Initialization ---------------%%
    if feature('ShowFigureWindows')
        wtBar = waitbar(0,'Initializing...','Name',displFieldProc.getName());
    else
        wtBar = -1;
    end
    %----------------------------------
    % Reading various constants
    nFrames = movieData.nFrames_;
    %----------------------------------
    % Check optional process Flow Tracking
    % iSDCProc = movieData.getProcessIndex('StageDriftCorrectionProcess',1,1);     
    iTFMPack = movieData.getPackageIndex('TFMPackage');
    tfmPackageHere=movieData.packages_{iTFMPack}; iSDCProc=1;
    SDCProc=tfmPackageHere.processes_{iSDCProc};
    %----------------------------------
    if ~isempty(SDCProc)
    %     SDCProc=movieData.processes_{iSDCProc};
        if ~SDCProc.checkChannelOutput(displacementParameters.ChannelIndex)
            error(['(ERROR in calculateMovieDisplacementField.m): The channel must have been corrected ! ' ...
                'Please apply stage drift correction to all needed channels before '...
                'running displacement field calclation tracking!'])
        end
        imDirs{1} = SDCProc.outFilePaths_{1,displacementParameters.ChannelIndex};
        s = load(SDCProc.outFilePaths_{3,displacementParameters.ChannelIndex},'T');
        residualT = s.T-round(s.T);
        T = s.T;
        refFrame = double(imread(SDCProc.outFilePaths_{2,displacementParameters.ChannelIndex}));
    %----------------------------------
    else
        imDirs  = movieData.getChannelPaths(displacementParameters.ChannelIndex);
        refFrame = double(imread(displacementParameters.referenceFramePath));
        residualT = zeros(nFrames,2);
    end
    %----------------------------------
    inFilePaths{1,displacementParameters.ChannelIndex} = imDirs{:};
    displFieldProc.setInFilePaths(inFilePaths);

    %------------------------Modified by Waddah Moghram on 2019-09-06. Modified on 2019-12-12 to save moviedata separately as well
    % Set up the output directories
    outputFile{1,1} = [displacementParameters.OutputDirectory filesep 'displField.mat'];
    % outputFile{2,1} = [displacementParameters.OutputDirectory filesep 'dispMaps.mat'];
    outputFile{3,1} = [displacementParameters.OutputDirectory filesep 'displFieldCalculationAllParameters.mat'];
    outputFile{4,1} = [displacementParameters.OutputDirectory filesep 'movieDataBefore.mat'];
    outputFile{5,1} = [displacementParameters.OutputDirectory filesep 'movieDataAfter.mat'];
    outputFile{6,1} = [displacementParameters.OutputDirectory filesep 'psfSigmaPlot'];
    % ------------------------------------------------------------------------------------------
    
    % Add a recovery mechanism if process has been stopped in the middle of the computation to re-use previous results
    firstFrame =1; % Set the strating fram eto 1 by default
    if exist(outputFile{1},'file')
        % Check analyzed frames
        sDisp=load(outputFile{1},'displField');
        frameDisplField=~arrayfun(@(x)isempty(x.pos),sDisp.displField);

        if ~all(frameDisplField) && ~all(~frameDisplField) && usejava('desktop')
            % Look at the first non-analyzed frame
            firstFrame = find(~frameDisplField,1);
            % Ask the user if display mode is active
            if ishandle(wtBar)
                recoverRun = questdlg(...
                    ['A displacement field output has been dectected with ' ...
                    num2str(firstFrame-1) ' analyzed frames. Do you' ...
                    ' want to use these results and continue the analysis'],...
                    'Recover previous run','Yes','No','Yes');
                if ~strcmpi(recoverRun,'Yes'), firstFrame=1; end
            end
        end
    end
    
    %----------------------------------
    if firstFrame == 1 
        % Backup the original vectors to backup folder
        disp('Backing up the original data')
        backupFolder = [displacementParameters.OutputDirectory ' Backup']; % name]);
        if exist(displacementParameters.OutputDirectory,'dir')
            ii = 1;
            while exist(backupFolder,'dir')
                backupFolder = [displacementParameters.OutputDirectory ' Backup ' num2str(ii)];
                ii=ii+1;
            end
            mkdir(backupFolder);
            copyfile(displacementParameters.OutputDirectory, backupFolder)
        end
        % Clean output file and initialize displacement field structure
        mkClrDir(displacementParameters.OutputDirectory); 
        displField(nFrames)=struct('pos',[],'vec',[]);
    %----------------------------------
    else
        % Load old displacement field structure 
        displField = sDisp.displField;                          % Corrected by WIM ON 2/21/2019
    end
    %----------------------------------
    displFieldProc.setOutFilePaths(outputFile);

%% --------------- Displacement field calculation ---------------%%% 
    disp('Starting calculating displacement field...')
    % Get the mask
    maskArray = movieData.getROIMask;
    % Use mask of first frame to filter bead detection
    firstMask = refFrame>0; %false(size(refFrame));
    tempMask = maskArray(:,:,1);
    firstMask(1:size(tempMask,1),1:size(tempMask,2)) = tempMask;
    tempMask2 = false(size(refFrame));
    %----------------------------------
    if ~isempty(SDCProc)
        if isa(SDCProc,'EfficientSubpixelRegistrationProcess')
            meanYShift = round(T(1,1));
            meanXShift = round(T(1,2));
            firstMask = circshift(tempMask,[meanYShift meanXShift]);
            % Now I blacked out erroneously circularaly shifted bead image
            % portion - SH 20171008
            if meanYShift>=0 %shifted downward
                firstMask(1:meanYShift,:)=0;
            else %shifted upward
                firstMask(end+meanYShift:end,:)=0;
            end
            if meanXShift>=0 %shifted right hand side
                firstMask(:,1:meanXShift)=0;
            else %shifted left
                firstMask(:,end+meanXShift:end)=0;
            end
        else
            y_shift = find(any(firstMask,2),1);
            x_shift = find(any(firstMask,1),1);

            tempMask2(y_shift:y_shift+size(tempMask,1)-1,x_shift:x_shift+size(tempMask,2)-1) = tempMask;
            firstMask = tempMask2 & firstMask;
        end
    end
    %----------------------------------
        % if ~displacementParameters.useGrid
    % end
    %----------------------------------
    % if displacementParameters.useGrid && displacementParameters.highRes
    %     tempDisplField.pos = beads;
    %     [~,xvec,yvec,~]=createRegGridFromDisplField(tempDisplField,1,1);
    %     beads = [xvec yvec];
    % end
    %----------------------------------
    disp('Calculating displacement field...')           
    
    % ---- added by Waddah Moghram on 2019-06-18------------------------------------------
    movieDataBefore = movieData;
    save(outputFile{3}, 'displacementParameters', 'movieDataBefore', 'SDCProc', 'displFieldProc','-v7.3');  
    MD = movieData; 
    save(outputFile{4}, 'MD','-v7.3');      
    %----------------------------------------------------------------------
    
    logMsg = 'Please wait, calculating displacement field';
    timeMsg = @(t) ['\nEstimated time remaining about: ' num2str(round(t/60)) ' min'];
  
    % % Perform sub-pixel registration
    if ishandle(wtBar), waitbar(0,wtBar,sprintf(logMsg)); end

    % ---- added by Waddah Moghram on 2019-11-11------------------------------------------    
%     ImageList = cell(nFrames - firstFrame, 1);
%     ImageListMat = zeros([movieData.imSize_, nFrames]);
%     for k = firstFrame:nFrames
%         if ~isempty(SDCProc)
%             tmpCurrImage = double(SDCProc.loadChannelOutput(displacementParameters.ChannelIndex(1),k));
%         else
%             tmpCurrImage = double(movieData.channels_(displacementParameters.ChannelIndex(1)).loadImage(k));
%         end
%         ImageList{k} = tmpCurrImage;
%         ImageListMat(:,:,k) = tmpCurrImage;
%     end
    %----------------------------------------------------------------------
FramesToBeTracked = firstFrame:nFrames;
FramesToBeTrackedCount = numel(FramesToBeTracked);
%----------------------------------
for CurrentFrame = FramesToBeTracked
    % Read image and perform correlation
    tick = tic;
    fprintf('---Tracking Frame %d/%d. \n',CurrentFrame, nFrames);
%----------------------------------
    if ~isempty(SDCProc)
        currImage = double(SDCProc.loadChannelOutput(displacementParameters.ChannelIndex(1),CurrentFrame));
    else
        currImage = double(movieData.channels_(displacementParameters.ChannelIndex(1)).loadImage(CurrentFrame));
    end
%----------------------------------
    if ~displacementParameters.useGrid
    % if strcmp(movieData.getChannel(displacementParameters.ChannelIndex).imageType_,'Widefield')
        % Detect beads in reference frame
    %----------------------------------
        if CurrentFrame==firstFrame && firstFrame==1
            disp('Determining PSF sigma from reference frame...')
            % Adaptation of psfSigma from bead channel image data
        %----------------------------------PARALLEL POOL
            poolobj = gcp('nocreate'); % If no pool, do not create new one.
            if isempty(poolobj)
                %                 poolsize = feature('numCores');
                poolsize = str2double(getenv('NUMBER_OF_PROCESSORS')) - 1;          % Modified by Waddah Moghram on 12/10/2018 and is better to get all cores.
            else
                poolsize = poolobj.NumWorkers;
            end
            if isempty(gcp('nocreate'))
                try
                    parpool('local', poolsize);
                catch
                    try 
                        parpool;
                    catch 
                        warning('matlabpool has been removed, and parpool is not working in this instance');
                    end
                end
            end
        %----------------------------------
            try
                [~, psfSigma, psfSigmaPlot] = getGaussianSmallestPSFsigmaFromData(refFrame,'Display',true);       % Changed to True by Waddah Moghram on 5/27/2019
                savefig(psfSigmaPlot, strcat(outputFile{6,1}, '.fig'), 'compact')
                saveas(psfSigmaPlot, strcat(outputFile{6,1}, '.png'), 'png')
                close(psfSigmaPlot)
            catch
                psfSigma = nan;                    
            end
            if isnan(psfSigma) || psfSigma>movieData.channels_(1).psfSigma_*3 
                if strcmp(movieData.getChannel(displacementParameters.ChannelIndex(1)).imageType_,'Widefield') || movieData.pixelSize_> 130
                    psfSigma = movieData.channels_(1).psfSigma_; %*2 scale up for widefield.                  % TERRIBLE FOR OUR EPI Experiments. Waddah Moghram on 2019-10-27
                elseif strcmp(movieData.getChannel(displacementParameters.ChannelIndex(1)).imageType_,'Confocal')
                    psfSigma = movieData.channels_(1).psfSigma_*0.79; %*4/7 scale down for  Confocal finer detection SH012913
                elseif strcmp(movieData.getChannel(displacementParameters.ChannelIndex(1)).imageType_,'TIRF')
                    psfSigma = movieData.channels_(1).psfSigma_*3/7; %*3/7 scale down for TIRF finer detection SH012913
                else
                    error('(ERROR in calculateMovieDisplacementField.m): image type should be chosen among Widefield, confocal and TIRF!');
                end
            end                           
            disp(['Determined sigma: ' num2str(psfSigma)])
        %----------------------------------
            disp('Detecting beads in the reference frame...')
            pstruct = pointSourceDetection(refFrame, psfSigma, 'alpha', displacementParameters.alpha,'Mask',firstMask,'FitMixtures', UseFitMixtureModel);            % Changed by Waddah Moghram on 2019-10-27. To go along with 
            save(outputFile{3}, 'psfSigma', 'pstruct', 'UseFitMixtureModel', '-append')    
        %----------------------------------
            assert(~isempty(pstruct), 'Could not detect any bead in the reference frame');
            % filtering out points in saturated image based on pstruct.c
            [N,edges] = histcounts(pstruct.c);
            % starting with median, find a edge disconnected with two consequtive zeros.
            medC = median(pstruct.c);
            idxAfterMedC= find(edges>medC);
            qq=idxAfterMedC(1);
            while N(qq)>0 || N(qq+1)>0
                qq=qq+1;
                if qq>=length(edges)-1
                    break
                end
            end
            idx = pstruct.c<edges(qq);
            beads = [pstruct.x(idx)', pstruct.y(idx)'];   
%                 beads = [round(pstruct.x(idx)'), round(pstruct.y(idx)')];         % changed by WIM on 2020-08-26 so that it is not rounded
            %     beads = [ceil(pstruct.x'), ceil(pstruct.y')];
        %----------------------------------
            % Subsample detected beads ensuring beads are separated by at least half of the correlation length - commented out to get more beads
            if ~displacementParameters.highRes
                disp('Subsampling detected beads (normal resolution)...')
                max_beads_distance = floor(displacementParameters.minCorLength/2);
            %----------------------------------
            else
                % To get high-resolution information, subsample detected beads ensuring  beads are separated by 100 um the correlation length 
                disp('Subsampling detected beads (high resolution)...')
                max_beads_distance = (100/movieData.pixelSize_);
            end
        %----------------------------------
            idx = KDTreeBallQuery(beads, beads, max_beads_distance);
            valid = true(numel(idx),1);
            for i = 1 : numel(idx)
                if ~valid(i), continue; end
                neighbors = idx{i}(idx{i} ~= i);
                valid(neighbors) = false;
            end
            beads = beads(valid, :);
            %{
                It doesn't critically require local maximal pixel to start
                x-correlation-based tracking. Thus, to increase spatial resolution,
                we add additional points in the mid points of pstruct
                We first randomly distribute point, and if it is not too close to
                existing points and the intensity of the point is above a half of the
                existing points, include the point into the point set
            %}
        %----------------------------------
            if displacementParameters.addNonLocMaxBeads
                disp('Finding additional non-local-maximal points with high intensity ...')
                distance=zeros(length(beads),1);
                for i=1:length(beads)
                    neiBeads = beads;
                    neiBeads(i,:)=[];
                    [~,distance(i)] = KDTreeClosestPoint(neiBeads,beads(i,:));
                end
                avg_beads_distance = quantile(distance,0.5);%mean(distance);%size(refFrame,1)*size(refFrame,2)/length(beads);
                notSaturated = true;
                xmin = min(pstruct.x);
                xmax = max(pstruct.x);
                ymin = min(pstruct.y);
                ymax = max(pstruct.y);
            %     avgAmp = mean(pstruct.A);
            %     avgBgd = mean(pstruct.c);
            %     thresInten = avgBgd+0.02*avgAmp;
%                 thresInten = quantile(pstruct.c,0.25);
                thresInten = quantile(pstruct.c,0.5); % try to pick up bright-enough spots
                maxNumNotDetected = 20; % the number of maximum trial without detecting possible point
                numNotDetected = 0;
                numPrevBeads = size(beads,1);

                % To avoid camera noise, Gaussian-filtered image will be used - SH 20171010
                refFrameFiltered = filterGauss2D(refFrame, psfSigma*0.90);                      
            %----------------------------------
%                     tic
                while notSaturated
                    x_new = xmin + (xmax-xmin)*rand(10000,1);
                    y_new = ymin + (ymax-ymin)*rand(10000,1);
                    [~,distToPoints] = KDTreeClosestPoint(beads,[x_new,y_new]);
                    inten_new = arrayfun(@(x,y) refFrameFiltered(round(y),round(x)),x_new,y_new);
                    idWorthAdding = distToPoints>avg_beads_distance & inten_new>thresInten;
                    if sum(idWorthAdding)>1
                        beads = [beads; [x_new(idWorthAdding), y_new(idWorthAdding)]];
                        numNotDetected = 0;
                    else
                        numNotDetected=numNotDetected+1;
                    end
                    if numNotDetected>maxNumNotDetected
                        notSaturated = false; % this means now we have all points to start tracking from the image
                    end
                end
%                     toc
            %----------------------------------
                disp([num2str(size(beads,1)-numPrevBeads) ' points were additionally detected for fine tracking. Total detected beads: ' num2str(length(beads))])
            end
            % Exclude all beads which are less  than half the correlation length 
            % away from the padded border. By default, no centered template should 
            % include any NaN's for correlation
            % Create beads mask with zero intensity points as false
            beadsMask = true(size(refFrame));
            % beadsMask(currImage==0)=false;
            % Remove false regions non-adjacent to the image border
            beadsMask = beadsMask | imclearborder(~beadsMask);
            %         % Erode the mask with half the correlation length and filter beads
            %         erosionDist=round((displacementParameters.minCorLength+1)/2);
            % Erode the mask with the correlation length + half maxFlowSpeed
            % and filter beads to minimize error
        %----------------------------------
            if displacementParameters.noFlowOutwardOnBorder
                erosionDist = (displacementParameters.minCorLength+1);
            else
                erosionDist = displacementParameters.minCorLength+1+round(displacementParameters.maxFlowSpeed/4);
            end
        %----------------------------------
            beadsMask = bwmorph(beadsMask,'erode',erosionDist);
            %         beadsMask=imerode(beadsMask,strel('square',erosionDist));
            indx = beadsMask(sub2ind(size(beadsMask),ceil(beads(:,2)), ceil(beads(:,1))));
            localbeads = beads(indx,:);
            currentBeads = localbeads; %This will keep updated
            cumulativeV_forV = zeros(size(localbeads));
            cumulativeV_forBeads = zeros(size(localbeads));
        %----------------------------------
        elseif CurrentFrame == firstFrame && firstFrame>1
            localbeads = displField(CurrentFrame-1).pos;
            currentBeads = localbeads; %This will keep updated
        end
    %----------------------------------
        %     % Select only beads which are min correlation length away from the border of the reference frame 
        %     beadsMask = true(size(refFrame));
        %     erosionDist=displacementParameters.minCorLength;
        %     % erosionDist=displacementParameters.minCorLength+1;
        %     beadsMask(erosionDist:end-erosionDist,erosionDist:end-erosionDist)=false;
        %     indx=beadsMask(sub2ind(size(beadsMask),ceil(beads(:,2)),ceil(beads(:,1))));
        %     beads(indx,:)=[];

%------------------------- Fixed by Waddah Moghram on 2019-06-01
        if ~displacementParameters.trackSuccessively
            scoreCalculation='xcorr';
%                scoreCalculation='difference';
            prevImage = refFrame;
            %----------------------------------
            % Track beads displacement in the xy coordinate system
%                 v = trackStackFlow(cat(3,refFrame,currImage),currentBeads,...
%                     displacementParameters.minCorLength, displacementParameters.minCorLength, 'maxSpd',displacementParameters.maxFlowSpeed,...
%                     'mode',displacementParameters.mode, 'scoreCalculation',scoreCalculation);              % , 'minFeatureSize', 1.5/(movieData.pixelSize_/1000));                  % Updated by Waddah Moghram on 2019-12-02. 1.5 micron for 0.5 micron red beads
            v = trackStackFlow(cat(3,prevImage,currImage),currentBeads,...
                0, 'maxCorL', displacementParameters.minCorLength, 'maxSpd',displacementParameters.maxFlowSpeed,...
                'mode',displacementParameters.mode, 'scoreCalculation',scoreCalculation);                % , 'minFeatureSize', 1.5/(movieData.pixelSize_/1000));                  % Updated by Waddah Moghram on 2019-12-02. 1.5 micron for 0.5 micron red beads
                          
        %----------------------------------
        else
%                 scoreCalculation='difference';
            scoreCalculation='xcorr';
            %----------------------------------
            % Track beads displacement in the xy coordinate system
            if CurrentFrame== 1
                prevImage = refFrame;
            else
                if ~exist('prevImage', 'var')
                    if ~isempty(SDCProc)
                        prevImage = double(SDCProc.loadChannelOutput(displacementParameters.ChannelIndex(1), CurrentFrame - 1));
                    else
                        prevImage = double(movieData.channels_(displacementParameters.ChannelIndex(1)).loadImage(CurrentFrame - 1));
                    end
                end
            end
            %----------------------------------
%                 v = trackStackFlow(cat(3,prevImage,currImage),currentBeads,...
%                     displacementParameters.minCorLength, 'maxCorL', displacementParameters.minCorLength, 'maxSpd',displacementParameters.maxFlowSpeed,...
%                     'mode',displacementParameters.mode, 'scoreCalculation',scoreCalculation)              % , 'minFeatureSize', 1.5/(movieData.pixelSize_/1000));                  % Updated by Waddah Moghram on 2019-12-02. 1.5 micron for 0.5 micron red beads     
            v = trackStackFlow(cat(3,prevImage,currImage),currentBeads,...
                0, 'maxCorL', displacementParameters.minCorLength, 'maxSpd',displacementParameters.maxFlowSpeed,...
                'mode',displacementParameters.mode, 'scoreCalculation',scoreCalculation);                % , 'minFeatureSize', 1.5/(movieData.pixelSize_/1000));                  % Updated by Waddah Moghram on 2019-12-02. 1.5 micron for 0.5 micron red beads
            %----------------------------------
            prevImage = currImage;
        end
        %----------------------------------        
        % Extract finite displacement and prepare displField structure in the xy coordinate system
%         if CurrentFrame==firstFrame
        validV = ~isinf(v(:,1)) & ~isnan(v(:,1));
%         end
        %----------------------------------
        if ~displacementParameters.trackSuccessively
%             displField(CurrentFrame).pos=localbeads(validV,:);
%             displField(CurrentFrame).vec=[v(validV,1)+residualT(CurrentFrame,2) v(validV,2)+residualT(CurrentFrame,1)]; % residual should be added with oppiste order! -SH 072514
            displField(CurrentFrame).pos = localbeads; % validV is removed to include NaN location - SH 030417
            displField(CurrentFrame).vec = [v(:,1)+residualT(CurrentFrame,2), v(:,2)+residualT(CurrentFrame,1)]; % residual should be added with oppiste order! -SH 072514
    %----------------------------------
        else
            v2 = v;
            % ------------------------------ Fixed by Waddah Moghram on 2019-06-01 to fixed error for cumulativeV_forV not existing
            if ~exist('cumulativeV_forV','var'), cumulativeV_forV = zeros(size(v2)); end       
            if ~exist('cumulativeV_forBeads','var'), cumulativeV_forBeads = zeros(size(v2)); end
            % --------------------------------------------------------------------------------------------------------------------------------------------
            cumulativeV_forV = cumulativeV_forV + v2;
            v2(~validV,1) = 0;
            v2(~validV,2) = 0;
            %----------------------------------
            cumulativeV_forBeads = cumulativeV_forBeads + v2;
            currentBeads = localbeads + cumulativeV_forBeads;
%                 currentBeads = currentBeads + v2;                             % Modified by Waddah Moghram on 2019-10-27
            %----------------------------------
            displField(CurrentFrame).pos = localbeads(validV,:);
            displField(CurrentFrame).vec = [cumulativeV_forV(validV,1) + residualT(CurrentFrame,2), cumulativeV_forV(validV,2) + residualT(CurrentFrame,1)]; % residual should be added with oppiste order! -SH 072514
        end
%----------------------------------
    else
        pivPar = [];      % variable for settings
        pivData = [];     % variable for storing results
        %----------------------------------
        [pivPar, pivData] = pivParams(pivData,pivPar,'defaults');     
        % Set the size of interrogation areas via fields |iaSizeX| and |iaSizeY| of |pivPar| variable:
%         pivPar.iaSizeX = [64 32 16 2^(nextpow2(displacementParameters.minCorLength)-1)];     % size of interrogation area in X 
        nextPow2max=nextpow2(displacementParameters.maxFlowSpeed);
        nextPow2min=nextpow2(displacementParameters.minCorLength)-2;
        %----------------------------------
        sizeArray=2.^([nextPow2max:-1:nextPow2min+1 nextPow2min+1]);
        stepArray=2.^(nextPow2max:-1:nextPow2min);
        %----------------------------------
        pivPar.anNpasses = length(stepArray);
        pivPar.iaSizeX = sizeArray;     % size of interrogation area in X 
        pivPar.iaStepX = stepArray;     % grid spacing of velocity vectors in X
        pivPar.iaSizeY = sizeArray;     % size of interrogation area in X 
        pivPar.iaStepY = stepArray;    % grid spacing of velocity vectors in X
%         pivPar.iaSizeX = [64 32 16 8];     % size of interrogation area in X 
%         pivPar.iaStepX = [32 16  8 4];     % grid spacing of velocity vectors in X
%         pivPar.iaSizeY = [64 32 16 8];     % size of interrogation area in X 
%         pivPar.iaStepY = [32 16  8 4];     % grid spacing of velocity vectors in X
% %         pivPar.iaStepX = [32 16  8 8];     % grid spacing of velocity vectors in X
% %         pivPar.iaSizeY = [64 32 16 16];     % size of interrogation area in Y 
% %         pivPar.iaStepY = [32 16  8 8];     % grid spacing of velocity vectors in Y
        pivPar.ccMaxDisplacement = displacementParameters.maxFlowSpeed/sizeArray(end);   % This filter is relatively narrow and will 
        pivPar.ccWindow = 'Gauss2';   % This filter is relatively narrow and will 
        pivPar.smMethod = 'none';
        pivPar.iaMethod = 'defspline';
        pivPar.iaImageInterpolationMethod = 'spline';
        pivPar.imMask1=firstMask;
        pivPar.imMask2=firstMask;
%         pivData.X=localbeads(:,1);
%         pivData.Y=localbeads(:,2);
%         pivData.U=zeros(size(pivData.X));
%         pivData.V=zeros(size(pivData.Y));
        %----------------------------------
        [pivData] = pivAnalyzeImagePair(refFrame,currImage,pivData,pivPar);
        %----------------------------------
        validV = ~isnan(pivData.V);
    %------ Modified by Waddah Moghram on 2019-04-07. Added (validV)
        if ~displacementParameters.trackSuccessively
            displField(CurrentFrame).pos=[pivData.X(validV), pivData.Y(validV)];                                          % Added validV. WIM on 4/7/2019
            displField(CurrentFrame).vec=[pivData.U(validV)+residualT(CurrentFrame,2), pivData.V(validV)+residualT(CurrentFrame,1)];       % residual should be added with oppiste order! -SH 072514
        %----------------------------------
        else
            v2 = [pivData.U(validV), pivData.V(validV)];                                                            % Added validV. WIM on 4/7/2019
            if CurrentFrame== firstFrame
                cumulativeV_forV = zeros(size(pivData.U(validV),1),2);                                              % Added validV. WIM on 4/7/2019
                cumulativeV_forBeads = zeros(size(pivData.X(validV),1),2);                                      % Added validV. WIM on 4/7/2019
            else
                cumulativeV_forV = cumulativeV_forV+v2;
                v2(~validV,1)=0;
                v2(~validV,2)=0;
                cumulativeV_forBeads = cumulativeV_forBeads+v2;
            end
            %----------------------------------
            currentBeads = [pivData.X(validV), pivData.Y(validV)] + cumulativeV_forBeads;
            displField(CurrentFrame).pos = [pivData.X(validV), pivData.Y(validV)];
            displField(CurrentFrame).vec = [cumulativeV_forV(validV,1)+residualT(CurrentFrame,2), cumulativeV_forV(validV,2)+residualT(CurrentFrame,1)]; % residual should be added with oppiste order! -SH 072514
            %----------------------------------
            prevImage = currImage;   % added by WIM on 2019-04-07 to track frames successively.
        end
%------------------------            
%         % testing additional pass of piv processing
%         pivPar.iaSizeX=[ 8];
%         pivPar.iaStepX=[ 4];
%         pivPar.anVelocityEst = 'pivData'; % use velocity data stored in pivData as velocity estimate used for image deformation. 
%         % By this setting, results of previous passes are transferred
%         pivPar.ccMethod = 'dcn';
%         pivPar.qvPair = {'U', 'clipLo', -0.2, 'clipHi', 0.2};
%         figure;
%         [pivPar2] = pivParams([],pivPar,'defaults');
%         pivData2 = pivAnalyzeImagePair(refFrame,currImage,pivData,pivPar2);
%         
%         displField(CurrentFrame).pos=[pivData2.X(:), pivData2.Y(:)];
%         displField(CurrentFrame).vec=[pivData2.U(:)+residualT(CurrentFrame,2), pivData2.V(:)+residualT(CurrentFrame,1)]; % residual should be added with oppiste order! -SH 072514
    end
%    
%----------------------------------
    % Update the waitbar
    if ishandle(wtBar)
        timeSec =toc(tick);
        FramesTrackedSoFarCount = (CurrentFrame-firstFrame);
        FramesLeftCount = FramesToBeTrackedCount - FramesTrackedSoFarCount ;
        waitbar((CurrentFrame-firstFrame)/FramesToBeTrackedCount,wtBar,sprintf([logMsg, timeMsg(timeSec*FramesLeftCount)]));
    end
%----------------------------------
    % Save each iteration (fozr recovery of unfinished processes)
    save(outputFile{1},'displField');  
%-----------------------------------------------------------------------------------
end

    %% Displacement map creation - this is shifted version

%     % Commented out by WIM on 2019-04-29 and modified on 2019-06-08 to include displacement limits
%     [dMapIn, dmax, dmin, cropInfo,dMapXin,dMapYin,reg_grid] = generateHeatmapShifted(displField,displField,0);
%     disp(['Estimated displacement maximum = ' num2str(dmax) ' pixel.'])
    
    % % Insert traction map in forceField.pos 
    % disp('Generating displacement maps ...')
    % dMap = cell(1,nFrames);
    % dMapX = cell(1,nFrames);
    % dMapY = cell(1,nFrames);
    % displFieldShifted(nFrames)=struct('pos','','vec','');
    % for ii=1:nFrames
    %     % starts with original size of beads
    %     cur_dMap = zeros(size(firstMask));
    %     cur_dMapX = zeros(size(firstMask));
    %     cur_dMapY = zeros(size(firstMask));
    %     cur_dMap(cropInfo(2):cropInfo(4),cropInfo(1):cropInfo(3)) = dMapIn{ii};
    %     cur_dMapX(cropInfo(2):cropInfo(4),cropInfo(1):cropInfo(3)) = dMapXin{ii};
    %     cur_dMapY(cropInfo(2):cropInfo(4),cropInfo(1):cropInfo(3)) = dMapYin{ii};
    %     dMap{ii} = cur_dMap;
    %     dMapX{ii} = cur_dMapX;
    %     dMapY{ii} = cur_dMapY;
    %     % Shifted displField vector field
    %     [grid_mat,iu_mat, ~,~] = interp_vec2grid(displField(ii).pos(:,1:2), displField(ii).vec(:,1:2),[],reg_grid);
    %    
    %     [displFieldShiftedpos,displFieldShiftedvec, ~, ~] = interp_vec2grid(grid_mat+iu_mat, iu_mat,[],grid_mat); %1:cluster size
    %     pos = [reshape(displFieldShiftedpos(:,:,1),[],1) reshape(displFieldShiftedpos(:,:,2),[],1)]; %dense
    %     disp_vec = [reshape(displFieldShiftedvec(:,:,1),[],1) reshape(displFieldShiftedvec(:,:,2),[],1)]; 
    % 
    %     displFieldShifted(ii).pos = pos;
    %     displFieldShifted(ii).vec = disp_vec;
    % end

%% ----------------------------------
    % Commented out by WIM on 2019-04-29
    disp('Saving ...')
    save(outputFile{1},'displField','-v7.3');
%     if displacementParameters.useGrid==0
%         
%         save(outputFile{3}, 'displacementParameters','movieData', 'SDCProc', 'displFieldProc','psfSigma', '-append')    
%     else
%         save(outputFile{3}, 'displacementParameters', 'movieData', 'SDCProc', 'displFieldProc','-append'');     % psfSigma does not have a meaning in the case of using a grid.    end
%     end
    % save(outputFile{2},'dMap','dMapX','dMapY','-v7.3'); % need to be updated for faster loading. SH 20141106
% ----------------------------------
    
    %% Added by Generated Heat Map to Identify the limits of the heat map without actually generating it yet...Last update by Waddah Moghram  on 2021-10-01 to use parfor
%     dmax = -1;
%     dmin = Inf;
    band = 0;
    reg_grid = createRegGridFromDisplField(displField,1,0);
%     ---------------------------------- 
    disp('Identifying the limits of the interpolated displacement grid limits over all frames without generating it yet.')
    disp('Note that these values might be extreme due to noise. Rely more on outlier-cleaned/filtered/drift corrected values')
    FramesNum = numel(displField);
    dmaxTMP = nan(FramesNum, 2);
    dminTMP = nan(FramesNum, 2);

    parfor_progressPath = movieData.outputDirectory_;
    parfor_progress(FramesNum, parfor_progressPath);
    parfor ii=1:FramesNum
        %Load the saved body heat map.
        [~,fmat, ~, ~] = interp_vec2grid(displField(ii).pos(:,1:2), displField(ii).vec(:,1:2),[],reg_grid);            % 1:cluster size
        fnorm = (fmat(:,:,1).^2 + fmat(:,:,2).^2).^0.5;
    
        % Boundary cutting - I'll take care of this boundary effect later
        fnorm(end-round(band/2):end,:)=[];
        fnorm(:,end-round(band/2):end)=[];
        fnorm(1:1+round(band/2),:)=[];
        fnorm(:,1:1+round(band/2))=[];
        fnorm_vec = reshape(fnorm,[],1); 
  
        dmaxTMP(ii, :) = max(max(fnorm_vec));
        dminTMP(ii, :) = min(min(fnorm_vec));

        parfor_progress(-1, parfor_progressPath);
    end
    parfor_progress(0, parfor_progressPath);
    [dmax, dmaxIdx] = max(dmaxTMP(:,1));
    [dmin, dminIdx] = min(dminTMP(:,1));
%     ----------------------------------
    %%
    displFieldProc.setTractionMapLimits([dmin, dmax])
    dminMicrons = dmin  * (movieData.pixelSize_ / 1000);                  % Convert from nanometer to microns. 2019-06-08 WIM
    dmaxMicrons = dmax  * (movieData.pixelSize_ / 1000);                  % Convert from nanometer to microns. 2019-06-08 WIM
    disp(['Estimated displacement minimum = ' num2str(dminMicrons) ' microns.'])
    disp(['Estimated displacement maximum = ' num2str(dmaxMicrons) ' microns.'])
%     displFieldProc.setTractionMapLimitsMicrons([dminMicrons, dmaxMicrons])
    
    save(outputFile{3}, 'dmin', 'dmax', 'dminMicrons', 'dmaxMicrons', 'dmaxIdx', 'dminIdx', '-append');           % Added 2019-09-23 by WIM
    movieData.processes_{iProc}.finishTime_ = clock;
    movieDataAfter = movieData;
    save(outputFile{3}, 'movieDataAfter', '-append');      
    % Updated movie data at the end of the process.
    MD = movieData; 
    save(outputFile{5}, 'MD','-v7.3');
    
    %% ----------------------------------
    % Close waitbar
    if ishandle(wtBar), close(wtBar); end

    %% ----------------------------------

    disp('-------------------------- Displacement field calculation COMPLETE --------------------------')