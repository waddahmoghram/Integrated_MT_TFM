function correctMovieDisplacementField(movieData,varargin)
    % correctMovieDisplacementField calculate the displacement field
    %{
    correctMovieDisplacementField 
    
    SYNOPSIS correctMovieDisplacementField(movieData,paramsIn)
    
    INPUT   
          movieData -       A MovieData object describing the movie to be processed    
          paramsIn -         Structure with inputs for optional parameters. The
  parameters should be stored as fields in the structure, with the field names and possible values as described below 
    
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
            
    Waddah Moghram,  2019..06...2020-09
    Sebastien Besson, Sep 2011
    Sangyoon Han, from Oct 2014
    % ----------- Input ----------- %%
    %}
    %% =====================================
    %Check input
    ip = inputParser;
    ip.CaseSensitive = false;
    ip.addRequired('movieData', @(x) isa(x,'MovieData'));
    ip.addOptional('paramsIn',[], @isstruct);
    ip.parse(movieData,varargin{:});
    paramsIn=ip.Results.paramsIn;

    %Get the indices of any previous stage drift processes                                                                     
    iProc = movieData.getProcessIndex('DisplacementFieldCorrectionProcess',1,0);

    %If the process doesn't exist, create it
    if isempty(iProc)
        iProc = numel(movieData.processes_)+1;
        movieData.addProcess(DisplacementFieldCorrectionProcess(movieData,...
            movieData.outputDirectory_)); 
        movieData.processes_{iProc}.startTime_ = clock;
    end
    displFieldCorrProc = movieData.processes_{iProc};
    %Parse input, store in parameter structure
    correctionParameters = parseProcessParams(displFieldCorrProc,paramsIn);

    %% Backup the original vectors to backup folder
    if exist(correctionParameters.OutputDirectory,'dir')
        disp('Backing up the original data')
        ii = 1;
        backupFolder = [correctionParameters.OutputDirectory ' Backup ' num2str(ii)];
        while exist(backupFolder,'dir')
            backupFolder = [correctionParameters.OutputDirectory ' Backup ' num2str(ii)];
            ii=ii+1;
        end
        mkdir(backupFolder);
        copyfile(correctionParameters.OutputDirectory, backupFolder,'f')
    end
    mkClrDir(correctionParameters.OutputDirectory);
    
    %% --------------- Initialization ---------------%%
    if feature('ShowFigureWindows')
        wtBar = waitbar(0,'Initializing...','Name',displFieldCorrProc.getName());
    end

    % Reading various constants
    nFrames = movieData.nFrames_;
   
    % Check displacement field process
    iDisplFieldCalcProc =movieData.getProcessIndex('DisplacementFieldCalculationProcess',1,1);     
    if isempty(iDisplFieldCalcProc)
        error(['(ERROR in calculateMovieDisplacementField.m): Displacement field calculation has not been run! '...
            'Please run displacement field calculation prior to force field calculation!'])   
    end

    displFieldCalcProc=movieData.processes_{iDisplFieldCalcProc};
    if ~displFieldCalcProc.checkChannelOutput
        error(['(ERROR in calculateMovieDisplacementField.m): The channel must have a displacement field ! ' ...
            'Please calculate displacement field to all needed channels before '...
            'running force field calculation!'])
    end
    displParams = displFieldCalcProc.funParams_;
    inFilePaths{1} = displFieldCalcProc.outFilePaths_{1};
    displFieldCorrProc.setInFilePaths(inFilePaths);

    %------------------------Modified by Waddah Moghram on 2019-09-18
    % Set up the output directories
    outputFile{1,1} = [correctionParameters.OutputDirectory filesep 'displField.mat'];
%     outputFile{2,1} = [correctionParameters.OutputDirectory filesep 'dispMaps.mat'];
    outputFile{3,1} = [correctionParameters.OutputDirectory filesep 'displFieldCorrectionAllParameters.mat'];
    outputFile{4,1} = [correctionParameters.OutputDirectory filesep 'movieDataBefore.mat'];
    outputFile{5,1} = [correctionParameters.OutputDirectory filesep 'movieDataAfter.mat'];    
    
    mkClrDir(correctionParameters.OutputDirectory);
    displFieldCorrProc.setOutFilePaths(outputFile);
    % ------------------------------------------------------------------------------------------
    
    % get firstMask
    iSDCProc =movieData.getProcessIndex('StageDriftCorrectionProcess',1,1);     
    pDistProc = displFieldCalcProc.funParams_;
    if ~isempty(iSDCProc)
        SDCProc=movieData.processes_{iSDCProc};
        if ~SDCProc.checkChannelOutput(pDistProc.ChannelIndex)
            error(['(ERROR in calculateMovieDisplacementField.m): The channel must have been corrected ! ' ...
                'Please apply stage drift correction to all needed channels before '...
                'running displacement field calclation tracking!'])
        end
        refFrame = double(imread(SDCProc.outFilePaths_{2,pDistProc.ChannelIndex}));
    else
        refFrame = double(imread(pDistProc.referenceFramePath));
    end
    firstMask = refFrame > 0;
    
    %% --------------- Displacement field correction ---------------%%% 
    disp('Starting correcting displacement field...')
    % ---- added by Waddah Moghram on 2019-06-18------------------------------------------
    movieDataBefore = movieData;
    save(outputFile{3}, 'correctionParameters', 'movieDataBefore', 'iSDCProc', 'displFieldCorrProc','displFieldCalcProc','-v7.3');   
    MD = movieData; 
    save(outputFile{4}, 'MD','-v7.3');        
    %----------------------------------------------------------------------  
    % Anonymous functions for reading input/output
    displField = displFieldCalcProc.loadChannelOutput;

    FramesTrackedTF = (arrayfun(@(x) ~isempty(x.vec), displField));          % in case previous step was not tracked completely. WIM 2021-08-04
    FramesTrackedNumbers = find(FramesTrackedTF);
    firstFrame = FramesTrackedNumbers(1);
    displField(~FramesTrackedTF) = [];                              % remove frames that were not tracked.
     
    useGrid=displParams.useGrid;
    % Perform vector field outlier detection
    % %Parse input, store in parameter structure
    % pd = parseProcessParams(displFieldCalcProc,paramsIn);

    disp('Detecting and filtering vector field outliers...')
    logMsg = 'Please wait, detecting and filtering vector field outliers';
    timeMsg = @(t) ['\nEstimated time remaining: ' num2str(round(t/60)) 'min'];
    if feature('ShowFigureWindows'), waitbar(0,wtBar,sprintf(logMsg)); end
    if feature('ShowFigureWindows'),parfor_progress(nFrames); end

    outlierThreshold = correctionParameters.outlierThreshold;
                              % Remove the empty ones. 
    FramesToBeTracked = 1:nFrames;
    FramesToBeTrackedCount = numel(FramesToBeTracked);
    parfor_progressPath = movieData.outputDirectory_;
    parfor_progress(nFrames, parfor_progressPath);
%     parfor CurrentFrame = FramesToBeTracked
    for CurrentFrame = FramesTrackedNumbers
        % Outlier detection
        tick = tic;
        dispMat = [displField(CurrentFrame).pos displField(CurrentFrame).vec];
%         fprintf('Correcting Frame #%d\n', CurrentFrame);
        % Take out duplicate points (Sangyoon)
        [dispMat,~,~] = unique(dispMat,'rows'); %dispMat2 = dispMat(idata,:),dispMat = dispMat2(iudata,:)
        displField(CurrentFrame).pos=dispMat(:,1:2);
        displField(CurrentFrame).vec=dispMat(:,3:4);

        if ~isempty(outlierThreshold)
            if useGrid
                if CurrentFrame==1
                    disp('In previous step, PIV was used, which does not require the current filtering step. skipping...')
                end
            else
                [outlierIndex,sparselyLocatedIdx,~,neighborhood_distance(CurrentFrame)] = detectVectorFieldOutliersTFM(dispMat,outlierThreshold,1);
                AllOutlierIndices{CurrentFrame} = outlierIndex;
                
                %displField(CurrentFrame).pos(outlierIndex,:)=[];
                %displField(CurrentFrame).vec(outlierIndex,:)=[];
                dispMat(outlierIndex,3:4)=NaN;
                dispMat(sparselyLocatedIdx,3:4)=NaN;
            end
            % I deleted this part for later gap-closing
            % Filter out NaN from the initial data (but keep the index for the
            % outliers)
    %         ind= ~isnan(dispMat(:,3));
    %         dispMat=dispMat(ind,:);

            displField(CurrentFrame).pos=dispMat(:,1:2);
            displField(CurrentFrame).vec=dispMat(:,3:4);

            % I deleted this part because artificially interpolated vector can
            % cause more error or false force. - Sangyoon June 2013
    %         % Filling all NaNs with interpolated displacement vectors -
    %         % We also calculate the interpolated displacements with a bigger correlation length.
    %         % They are considered smoothed displacements at the data points. Sangyoon
    %         dispMat = [dispMat(:,2:-1:1) dispMat(:,2:-1:1)+dispMat(:,4:-1:3)];
    %         intDisp = vectorFieldSparseInterp(dispMat,...
    %             displField(CurrentFrame).pos(:,2:-1:1),...
    %             pd.minCorLength,pd.minCorLength,[],true);
    %         displField(CurrentFrame).vec = intDisp(:,4:-1:3) - intDisp(:,2:-1:1);
        end
%         Update the waitbar
        if mod(CurrentFrame,5)==1 && feature('ShowFigureWindows')
            if ishandle(wtBar)
                timeSec =toc(tick);
                FramesTrackedSoFarCount = (CurrentFrame-firstFrame);
                FramesLeftCount = FramesToBeTrackedCount - FramesTrackedSoFarCount ;
                waitbar((CurrentFrame-firstFrame)/FramesToBeTrackedCount,wtBar,sprintf([logMsg, timeMsg(timeSec*FramesLeftCount)]));
            end
        end
%         if feature('ShowFigureWindows'), parfor_progress; end
        parfor_progress(-1, parfor_progressPath);
    end
%     if feature('ShowFigureWindows'), parfor_progress(0); end
    parfor_progress(0, parfor_progressPath);
    
    if correctionParameters.fillVectors
        % Now this is the real cool step, to run trackStackFlow with known
        % information of existing displacement in neighbors
        % Check optional process Flow Tracking
        pStep2 = displParams;
        if ~isempty(iSDCProc)
            s = load(SDCProc.outFilePaths_{3,pStep2.ChannelIndex},'T');
            residualT = s.T-round(s.T);
            refFrame = double(imread(SDCProc.outFilePaths_{2,pStep2.ChannelIndex}));
        else
            refFrame = double(imread(pStep2.referenceFramePath));
            residualT = zeros(nFrames,2);
        end
        logMsg = 'Please wait, retracking untracked points ...';
        timeMsg = @(t) ['\nEstimated time remaining: ' num2str(round(t/60)) 'min'];
        tic
        nFillingTries = 10;             % Modified by Waddah Moghram on 2019-06-02 from 5 to 30, to have smaller increases in search radius
        for CurrentFrame = FramesTrackedNumbers
            % Read image and perform correlation
            if ~isempty(iSDCProc)
                currImage = double(SDCProc.loadChannelOutput(pStep2.ChannelIndex(1),CurrentFrame));
            else
                currImage = double(movieData.channels_(pStep2.ChannelIndex(1)).loadImage(CurrentFrame));
            end
            nTracked=1000;
            nFailed=0;
            for k = 0:nFillingTries   % Modified by Waddah Moghram on 2019-06-02 from 1  to 0, for starting value so that radius is always the same at first, to be more consistent.
                % only un-tracked vectors
                unTrackedBeads=isnan(displField(CurrentFrame).vec(:,1));
                ratioUntracked = sum(unTrackedBeads)/length(unTrackedBeads);
                if logical(ratioUntracked<0.0001) || logical(nTracked==0 && nFailed>30)
                    break
                end
                currentBeads = displField(CurrentFrame).pos(unTrackedBeads,:);
                neighborBeads = displField(CurrentFrame).pos(~unTrackedBeads,:);
                neighborVecs = displField(CurrentFrame).vec(~unTrackedBeads,:);
                % Get neighboring vectors from these vectors (meanNeiVecs)
                [idx] = KDTreeBallQuery(neighborBeads, currentBeads, (1+5*k/nFillingTries)*neighborhood_distance(CurrentFrame)); % Increasing search radius with further iteration
    %             [idx] = KDTreeBallQuery(neighborBeads, currentBeads, (2-1.5*k/nFillingTries)*neighborhood_distance(CurrentFrame)); % Increasing search radius with further iteration
                % In case of empty idx, search with larger radius.
                emptyCases = cellfun(@isempty,idx);
                mulFactor=1;
                while any(emptyCases)
                    mulFactor=mulFactor+0.5;
                    idxEmpty = KDTreeBallQuery(neighborBeads, currentBeads(emptyCases,:), mulFactor*(1+5*k/nFillingTries)*neighborhood_distance(CurrentFrame));
                    idx(emptyCases)=idxEmpty;
                    emptyCases = cellfun(@isempty,idx);
                end
                % Subsample idx to reduce computing time
                % Calculate the subsampling rate
                leap = cellfun(@(x) max(1,round(length(x)/100)),idx,'Unif',false);
                idx = cellfun(@(x,y) x(1:y:end,1),idx,leap,'Unif',false);
                closeNeiVecs = cellfun(@(x) neighborVecs(x,:),idx,'Unif',false);
            %     meanNeiVecs = cellfun(@mean,closeNeiVecs,'Unif',false);

            %-----------------------------------------Fixed by Waddah Moghram to account for subsequent or not subsequent tracking
                if ~pStep2.trackSuccessively
                    prevImage = refFrame;
                    % Track beads displacement in the xy coordinate system
                    [v,nTracked] = trackStackFlowWithHardCandidate(cat(3,prevImage,currImage),currentBeads,...
                        pStep2.minCorLength,pStep2.minCorLength,'maxSpd',pStep2.maxFlowSpeed,...
                        'mode',pStep2.mode,'hardCandidates',closeNeiVecs);%,'usePIVSuite', pStep2.usePIVSuite);
                else
                    if CurrentFrame == 1
                        prevImage = refFrame;
                    else
                        if ~exist('prevImage', 'var')
                            if ~isempty(SDCProc)
                                prevImage = double(SDCProc.loadChannelOutput(correctionParameters.ChannelIndex(1), CurrentFrame - 1));
                            else
                                prevImage = double(movieData.channels_(correctionParameters.ChannelIndex(1)).loadImage(CurrentFrame - 1));
                            end
                        end
                    end
                    [v,nTracked] = trackStackFlowWithHardCandidate(cat(3,prevImage,currImage),currentBeads,...
                        pStep2.minCorLength,pStep2.minCorLength,'maxSpd',pStep2.maxFlowSpeed,...
                        'mode',pStep2.mode,'hardCandidates',closeNeiVecs);%,'usePIVSuite', pStep2.usePIVSuite);
                    prevImage = currImage;
                end
            %----------------------------------  
%                 [v,nTracked] = trackStackFlowWithHardCandidate(cat(3,refFrame,currImage),currentBeads,...
%                     pStep2.minCorLength,pStep2.minCorLength,'maxSpd',pStep2.maxFlowSpeed,...
%                     'mode',pStep2.mode,'hardCandidates',closeNeiVecs);%,'usePIVSuite', pStep2.usePIVSuite);               
                if nTracked==0
                    nFailed = nFailed + 1;
                else
                    nFailed = 0;
                end

            %     displField(CurrentFrame).pos(unTrackedBeads,:)=currentBeads; % validV is removed to include NaN location - SH 030417
                displField(CurrentFrame).vec(unTrackedBeads,:) = [v(:,1)+residualT(CurrentFrame,2), v(:,2)+residualT(CurrentFrame,1)]; % residual should be added with oppiste order! -SH 072514
            end
            disp(['Done for frame ' num2str(CurrentFrame) '/' num2str(nFrames) '.'])
            % Update the waitbar
%             if feature('ShowFigureWindows')
%                 tj=toc;
%                 waitbar(CurrentFrame/nFrames,wtBar,sprintf([logMsg timeMsg(tj*(nFrames-CurrentFrame)/CurrentFrame)]));
%             end
        end
        
        %Filtering again
        for CurrentFrame= FramesTrackedNumbers
            % Outlier detection
            dispMat = [displField(CurrentFrame).pos displField(CurrentFrame).vec];
            % Take out duplicate points (Sangyoon)
            [dispMat,~,~] = unique(dispMat,'rows'); %dispMat2 = dispMat(idata,:),dispMat = dispMat2(iudata,:)
            displField(CurrentFrame).pos = dispMat(:,1:2);
            displField(CurrentFrame).vec = dispMat(:,3:4);

            [outlierIndex,sparselyLocatedIdx] = detectVectorFieldOutliersTFM(dispMat,outlierThreshold*3,1);
            %displField(CurrentFrame).pos(outlierIndex,:)=[];
            %displField(CurrentFrame).vec(outlierIndex,:)=[];
            dispMat(outlierIndex,3:4)=NaN;
            dispMat(sparselyLocatedIdx,3:4)=NaN;

            displField(CurrentFrame).pos=dispMat(:,1:2);
            displField(CurrentFrame).vec=dispMat(:,3:4);
            if feature('ShowFigureWindows'), parfor_progress(-1, parfor_progressPath); end
        end
        if feature('ShowFigureWindows'), parfor_progress(0, parfor_progressPath); end
    end
    
    % Here, if nFrame>1, we do inter- and extrapolation of displacement vectors to prevent sudden, wrong force field change.
    if FramesTrackedNumbers(1) >1 && ~displParams.useGrid
        disp('Performing displacement vector gap closing ...')
        %{
            Depending on stage drift correction, some beads can be missed in certain
            frames. Now it's time to make the same positions for all frames
            go through each frame and filter points to the common ones in
            iMinPointFrame - this needs to be improved by checking intersection
            of all frames to find truly common beads, once there is error here.
        %}
        mostCommonPos = displField(1).pos;
        for ii= 2:FramesTrackedNumbers(end)
            commonPos=intersect(displField(ii).pos,mostCommonPos,'rows');
            mostCommonPos = commonPos;
        end
        for ii= FramesTrackedNumbers
            [commonPos,ia,~]=intersect(displField(ii).pos,mostCommonPos,'rows');
            displField(ii).pos = commonPos;
            displField(ii).vec = displField(ii).vec(ia,:);
        end
        
        % going through each point, see if there is NaN at each displacment history and fill the gap
        logMsg = 'Performing displacement vector gap closing ...';

        nPoints = length(displField(1).pos(:,1));
        for k = 1:nPoints
            % build each disp vector history
            curVecX = arrayfun(@(x) x.vec(k,1),displField);
            curVecY = arrayfun(@(x) x.vec(k,2),displField);
            if any(isnan(curVecX)) && sum(~isnan(curVecX))/numel(FramesTrackedNumbers)>0.6
                t = 1:length(curVecX);
                t_nn = t(~isnan(curVecX));
                curVecX2 = interp1(t_nn,curVecX(~isnan(curVecX)),t,'linear');
                curVecY2 = interp1(t_nn,curVecY(~isnan(curVecX)),t,'linear');
                for ii=find(isnan(curVecX))
                    displField(ii).vec(k,:) = [curVecX2(ii), curVecY2(ii)];
                end
            else
                continue
            end
            if mod(k,5)==1 && feature('ShowFigureWindows')
                tj = toc;
                waitbar(k/nPoints,wtBar,sprintf([logMsg timeMsg(tj*(nPoints-k)/k)]));
            end
        end
    else
        if displParams.useGrid
            disp('In previous step, PIV was used, which does not require the current gap closing step. skipping...')
        end
    end

    % Find rotational registration
    if correctionParameters.doRotReg, displField = perfRotReg(displField); end 

     %% Displacement map creation - this is shifted version
%     [dMapIn, dmax, dmin, cropInfo,dMapXin,dMapYin,reg_grid] = generateHeatmapShifted(displField,displField,0);
%     % Insert traction map in forceField.pos 
%     disp('Generating displacement maps ...')
%     dMap = cell(1,nFrames);
%     dMapX = cell(1,nFrames);
%     dMapY = cell(1,nFrames);
%     displFieldShifted(nFrames)=struct('pos','','vec','');
%     for ii=FramesTrackedNumbers
%         % starts with original size of beads
%         cur_dMap = zeros(size(firstMask));
%         cur_dMapX = zeros(size(firstMask));
%         cur_dMapY = zeros(size(firstMask));
%         cur_dMap(cropInfo(2):cropInfo(4),cropInfo(1):cropInfo(3)) = dMapIn{ii};
%         cur_dMapX(cropInfo(2):cropInfo(4),cropInfo(1):cropInfo(3)) = dMapXin{ii};
%         cur_dMapY(cropInfo(2):cropInfo(4),cropInfo(1):cropInfo(3)) = dMapYin{ii};
%         dMap{ii} = cur_dMap;
%         dMapX{ii} = cur_dMapX;
%         dMapY{ii} = cur_dMapY;
%         % Shifted displField vector field
%         [grid_mat,iu_mat, ~,~] = interp_vec2grid(displField(ii).pos, displField(ii).vec,[],reg_grid);
% 
%         [displFieldShiftedpos,displFieldShiftedvec, ~, ~] = interp_vec2grid(grid_mat+iu_mat, iu_mat,[],grid_mat); %1:cluster size
%         pos = [reshape(displFieldShiftedpos(:,:,1),[],1) reshape(displFieldShiftedpos(:,:,2),[],1)]; %dense
%         disp_vec = [reshape(displFieldShiftedvec(:,:,1),[],1) reshape(displFieldShiftedvec(:,:,2),[],1)]; 
% 
%         displFieldShifted(ii).pos = pos;
%         displFieldShifted(ii).vec = disp_vec;
%     end
    disp('Saving Corrected Displacement Field ...')
    %------------------------------------------------- Fixed by Waddah Moghram on 2019-06-02
%     save(outputFile{1},'displField','displFieldShifted','-v7.3');
    save(outputFile{1},'displField','-v7.3');

%     save(outputFile{2},'dMap','dMapX','dMapY','-v7.3'); % need to be updated for faster loading. SH 20141106
    %

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
    displFieldCorrProc.setTractionMapLimits([dmin, dmax])
    dminMicrons = dmin  * (movieData.pixelSize_ / 1000);                  % Convert from nanometer to microns. 2019-06-08 WIM
    dmaxMicrons = dmax  * (movieData.pixelSize_ / 1000);                  % Convert from nanometer to microns. 2019-06-08 WIM
    disp(['Estimated displacement minimum = ' num2str(dminMicrons) ' microns.'])
    disp(['Estimated displacement maximum = ' num2str(dmaxMicrons) ' microns.'])
%     displFieldProc.setTractionMapLimitsMicrons([dminMicrons, dmaxMicrons])
    
    % displFieldProc.setTractionMapLimitsMicrons([dminMicrons, dmaxMicrons])
    save(outputFile{3}, 'dmin', 'dmax', 'dminMicrons', 'dmaxMicrons', 'AllOutlierIndices', '-append');           % Added 2019-09-23 by WIM. Updated on 2020-09-15   
    movieData.processes_{iProc}.finishTime_ = clock;
    movieDataAfter = MovieData;
    save(outputFile{3}, 'movieDataAfter', '-append');                                                                                    % Updated movie data at the end of the process.
    MD = movieData; 
    save(outputFile{5}, 'MD','-v7.3');          

    %% Close waitbar
%     if feature('ShowFigureWindows'), close(wtBar); end

    disp('============================= Finished correcting displacement field! =======================')

end