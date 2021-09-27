function calculateMovieForceField(movieData,varargin)
    % calculateMovieForceField calculate the displacement field
    %{
    calculateMovieForceField 
    
    SYNOPSIS calculateMovieForceField(movieData,paramsIn)
    
    INPUT   
      movieData - A MovieData object describing the movie to be processed
    
      paramsIn - Structure with inputs for optional parameters. The
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
    Last updated by Sangyoon Han, Oct 2014
    Updates by Andrew R. Jamieson, Feb 2017
    
    Modified by Waddah Ibrahim Moghram 2020-03-03
    %}
    %% Initial variables.
    gridMagnification = 1;          %% (to go with the rectangular grid created to interpolate displField)
    EdgeErode = 1;    
    
    %% Input
    %Check input
    ip = inputParser;
    ip.CaseSensitive = false;
    ip.addRequired('movieData', @(x) isa(x,'MovieData'));
    ip.addOptional('paramsIn',[], @isstruct);
    ip.parse(movieData,varargin{:});
    paramsIn=ip.Results.paramsIn;

    %Get the indices of any previous stage drift processes                                                                     
    iProc = movieData.getProcessIndex('ForceFieldCalculationProcess',1,0);

    %If the process doesn't exist, create it
    if isempty(iProc)
        iProc = numel(movieData.processes_)+1;
        movieData.addProcess(ForceFieldCalculationProcess(movieData,...
            movieData.outputDirectory_));                                                                                                 
    end
    forceFieldProc = movieData.processes_{iProc};

    %Parse input, store in parameter structure
    forceFieldParameters = parseProcessParams(forceFieldProc,paramsIn);
    forceFieldParameters.usePaxImg = false;
    forceFieldParameters.saveBEMparams = true;
    % forceFieldParameters.lastToFirst = false;
    forceFieldParameters.LcurveFactor = 10;
    forceFieldParameters.divideConquer = 1; % If this is 9, grid is divided by 9 sub-grids where force field will be calculated to reduce memory usage. It's under refined construction.

    %% --------------- Initialization ---------------%%
    if feature('ShowFigureWindows'),
        wtBar = waitbar(0,'Initializing...','Name',forceFieldProc.getName());
        wtBarArgs={'wtBar',wtBar};
    else
        wtBar=-1;
        wtBarArgs={};
    end

    % 0. Reading various constants
    nFrames = movieData.nFrames_;

    % 1. Check optional process Displacement field correction first
    iDisplFieldProc =movieData.getProcessIndex('DisplacementFieldCorrectionProcess',2,0);     
    
    if isempty(iDisplFieldProc)
        iDisplFieldProc =movieData.getProcessIndex('DisplacementFieldCalculationProcess',1,0);     
    end
    if isempty(iDisplFieldProc)
        error(['(ERROR in calculateMovieForceField.m): Displacement field calculation has not been run! '...
            'Please run displacement field calculation prior to force field calculation!'])
    end
    
    displFieldProc =movieData.processes_{iDisplFieldProc};   
    
    % Possible error in the next statement if the file is corrupted
     if ~displFieldProc.checkChannelOutput()
        error(['(ERROR in calculateMovieForceField.m): Missing displacement field ! Please apply displacement field '...
            'calculation/correction before running force field calculation!'])
    end

    % 2. define resolution depending on the grid information in displacementField step
    iDisplFieldCalProc =movieData.getProcessIndex('DisplacementFieldCalculationProcess',1,0);     
    displFieldCalProc=movieData.processes_{iDisplFieldCalProc};
    displacementFieldParameters = parseProcessParams(displFieldCalProc);
    try
        displacementFieldParameters.useGrid;
    catch
        displacementFieldParameters.useGrid = false;
    end
    if displacementFieldParameters.useGrid || displacementFieldParameters.addNonLocMaxBeads
        forceFieldParameters.highRes = false;
    else
        forceFieldParameters.highRes = true;
    end
    
    % 3. Set up the input file
    inFilePaths{1} = displFieldProc.outFilePaths_{1};
    forceFieldProc.setInFilePaths(inFilePaths);

    % 4. Set up the output files
    outputFile{1,1} = [forceFieldParameters.OutputDirectory filesep 'forceField.mat'];
    outputFile{2,1} = [forceFieldParameters.OutputDirectory filesep 'tractionMaps.mat'];
    outputFile{3,1} = [forceFieldParameters.OutputDirectory filesep 'BEMParams.mat'];
    % if  ~strcmp(forceFieldParameters.solMethodBEM,'QR')
    if forceFieldParameters.useLcurve
        outputFile{4,1} = [forceFieldParameters.OutputDirectory filesep 'Lcurve.fig'];
        outputFile{5,1} = [forceFieldParameters.OutputDirectory filesep 'LcurveData.mat'];
    end
    
    %---------- Added by Waddah Moghram on 5/28/2019
    outputFile{6,1} = [forceFieldParameters.OutputDirectory filesep 'forceFieldParameters.mat'];
    outputFile{7,1} = [forceFieldParameters.OutputDirectory filesep 'movieDataBefore.mat'];
    outputFile{8,1} = [forceFieldParameters.OutputDirectory filesep 'movieDataAfter.mat'];        
    
    %---------------------------

    % 5. Add a recovery mechanism if process has been stopped in the middle of the computation to re-use previous results
    firstFrame =1;                                                  % Set the starting frame to 1 by default
    lastFrame=nFrames;
    if exist(outputFile{1},'file')
        % 5.a. Check analyzed frames
        s= load(outputFile{1},'forceField');
        frameForceField=~arrayfun(@(x)isempty(x.pos),s.forceField);

        if ~all(frameForceField) && ~all(~frameForceField)
            % 5.a.1. Look at the first non-analyzed frame
            if forceFieldParameters.lastToFirst 
                firstFrame = find(frameForceField);
                numFramesAnalyzed=length(firstFrame);
                lastFrame = firstFrame(1)-1;
            else
                firstFrame = find(~frameForceField,1);
                numFramesAnalyzed=firstFrame-1;
            end
            % 5.a.2. Ask the user if display mode is active
            if ishandle(wtBar)
                recoverRun = questdlg(...
                    ['(calculateMovieForceField.m): A force field output has been dectected with ' ...
                    num2str(numFramesAnalyzed) ' analyzed frames. Do you' ...
                    ' want to use these results and continue the analysis'],...
                    'Recover previous run','Yes','No','Yes');
                if ~strcmpi(recoverRun,'Yes'), firstFrame=1; lastFrame=nFrames; end
            end
    %         if ~usejava('desktop')
    %             firstFrame=1;
    %         end
        end
    end
    
    % 6. asking if you want to reuse the fwdMap again
    % Note; (you have to make sure that you are solving the same problem with only different reg. param.) -SH
    reuseFwdMap = 'No';
    if strcmpi(forceFieldParameters.method,'FastBEM') && exist(outputFile{3,1},'file') 
        if usejava('desktop')
            reuseFwdMap = questdlg(...
                ['(calculateMovieForceField.m): BEM parameters were dectected. Do you' ...
                ' want to use these parameter and overwrite the results?'],...
                'Reuse Fwdmap','Yes','No','No');
        end
    end

    % 7. Backup the original vectors to backup folder
    if firstFrame==1 && (strcmpi(reuseFwdMap,'No') || strcmpi(forceFieldParameters.method,'FTTC')) && exist(outputFile{1,1},'file')
        disp('(calculateMovieForceField.m): Backing up the original data (movie data + traction forces)')
        
        backupFolder = [forceFieldParameters.OutputDirectory ' Backup']; % name]);
        if exist(forceFieldParameters.OutputDirectory,'dir')
            ii = 1;
            while exist(backupFolder,'dir')
                backupFolder = [forceFieldParameters.OutputDirectory ' Backup ' num2str(ii)];
                ii=ii+1;
            end
            mkdir(backupFolder);
            copyfile(forceFieldParameters.OutputDirectory, backupFolder,'f')
        end
        
        forceField(nFrames)=struct('pos','','vec','','par','');
        forceFieldShifted(nFrames)=struct('pos','','vec','');
        displErrField(nFrames)=struct('pos','','vec','');
        distBeadField(nFrames)=struct('pos','','vec','');
        
        mkClrDir(forceFieldParameters.OutputDirectory);
        M = [];
    elseif strcmpi(reuseFwdMap,'Yes') && strcmpi(forceFieldParameters.method,'FastBEM') && exist(outputFile{3,1},'file')
        fwdMapFile = load(outputFile{3,1},'M');
        M = fwdMapFile.M;
    elseif strcmpi(forceFieldParameters.method,'FastBEM') && strcmpi(reuseFwdMap,'No')  && exist(outputFile{3,1},'file') 
        % Load old force field structure 
        forceField = s.forceField;
        M = [];
    else
        mkClrDir(forceFieldParameters.OutputDirectory);
        M = [];
    end
    forceFieldProc.setOutFilePaths(outputFile);

%% --------------- Force field calculation ---------------%%% 
    disp('(calculateMovieForceField.m): Starting calculating force  field...')
    %----------- Added by Waddah Moghram on 5/27/2019
    movieDataBefore = movieData;
    save(outputFile{6}, 'forceFieldParameters', 'displacementFieldParameters', 'movieDataBefore', 'forceFieldProc', 'displFieldProc', '-v7.3');
    MD = movieData; 
    save(outputFile{7}, 'MD','-v7.3');            
    %-------------------------------

    if ~isempty(movieData.roiMaskPath_)
        maskArray = imread(movieData.roiMaskPath_);
    else
        maskArray = movieData.getROIMask;
    end
    
    if min(min(maskArray(:,:,1))) == 0
        iStep2Proc = movieData.getProcessIndex('DisplacementFieldCalculationProcess',1,0);
        step2Proc = movieData.processes_{iStep2Proc};
        displacementFieldParameters = parseProcessParams(step2Proc,paramsIn);

        % 1. Use mask of first frame to filter displacementfield
        iSDCProc =movieData.getProcessIndex('StageDriftCorrectionProcess',1,1);     
        displFieldOriginal=displFieldProc.loadChannelOutput;

        if ~isempty(iSDCProc)
            SDCProc=movieData.processes_{iSDCProc};
            if ~SDCProc.checkChannelOutput(displacementFieldParameters.ChannelIndex)
                error(['(ERROR in calculateMovieForceField.m): The channel must have been corrected ! ' ...
                    'Please apply stage drift correction to all needed channels before '...
                    'running displacement field calclation tracking!'])
            end
            
            % 2. Parse input, store in parameter structure
            refFrame = double(imread(SDCProc.outFilePaths_{2,displacementFieldParameters.ChannelIndex}));

            % 3. Use mask of first frame to filter bead detection
            firstMask = refFrame>0;                  %false(size(refFrame));
            tempMask = maskArray(:,:,1);
            
            if isa(SDCProc,'EfficientSubpixelRegistrationProcess')
                s = load(SDCProc.outFilePaths_{3,displacementFieldParameters.ChannelIndex},'T');
                T = s.T;
                meanYShift = round(T(1,1));
                meanXShift = round(T(1,2));
                firstMask = circshift(tempMask,[meanYShift meanXShift]);
                % Now I blacked out erroneously circularaly shifted bead image portion - SH 20171008
                if meanYShift>=0                                        %shifted downward
                    firstMask(1:meanYShift,:)=0;
                else %shifted upward
                    firstMask(end+meanYShift:end,:)=0;
                end
                if meanXShift>=0                                        %shifted right hand side
                    firstMask(:,1:meanXShift)=0;
                else                                                                %shifted left
                    firstMask(:,end+meanXShift:end)=0;
                end

            else                                                        % No Efficient Subpixel Registration Step done.
                % firstMask(1:size(tempMask,1),1:size(tempMask,2)) = tempMask;
                tempMask2 = false(size(refFrame));
                y_shift = find(any(firstMask,2),1);
                y_lastNonZero = find(any(firstMask,2),1,'last');
                x_shift = find(any(firstMask,1),1);

                x_lastNonZero = find(any(firstMask,1),1,'last');
                
                % It is possible that I created roiMask based on tMap which is based on reg_grid. 
                % In that case, I'll have to re-size firstMask accordingly check if maskArray is made based on channel
                if (y_lastNonZero-y_shift+1)==size(tempMask,1) ...
                        && (x_lastNonZero-x_shift+1)==size(tempMask,2)
                    tempMask2(y_shift:y_shift+size(tempMask,1)-1,x_shift:x_shift+size(tempMask,2)-1) = tempMask;
                    if (y_shift+size(tempMask,1))>size(firstMask,1) || x_shift+size(tempMask,2)>size(firstMask,2)
                        firstMask=padarray(firstMask,[y_shift-1 x_shift-1],'replicate','post');
                    end
                elseif size(firstMask,1)==size(tempMask,1) ... 
                        && size(firstMask,2)==size(tempMask,2) % In this case, maskArray (or roiMask) is based on reg_grid
                    disp('(calculateMovieForceField.m): Found that maskArray (or roiMask) is based on reg_grid')
                    tempMask2 = tempMask;
                else
                    error('(ERROR in calculateMovieForceField.m): Something is wrong! Please check your roiMask!')
                end
                firstMask = tempMask2 & firstMask;
            end
    %         firstMask = false(size(refFrame));
    %         tempMask = maskArray(:,:,1);
    %         firstMask(1:size(tempMask,1),1:size(tempMask,2)) = tempMask; % This was wrong
            displField = filterDisplacementField(displFieldOriginal,firstMask);
       
        else
            firstMask = maskArray(:,:,1);
            displField = filterDisplacementField(displFieldOriginal,firstMask);
        end
        
    else                                        % Process not empty
        displField=displFieldProc.loadChannelOutput;
        iSDCProc = movieData.getProcessIndex('StageDriftCorrectionProcess',1,1);     
        
        if ~isempty(iSDCProc)
            SDCProc = movieData.processes_{iSDCProc};
            if ~SDCProc.checkChannelOutput(displacementFieldParameters.ChannelIndex)
                error(['(ERROR in calculateMovieForceField.m): The channel must have been corrected ! ' ...
                    'Please apply stage drift correction to all needed channels before '...
                    'running displacement field calclation tracking!'])
            end
            
            % 2. Parse input, store in parameter structure
            refFrame = double(imread(SDCProc.outFilePaths_{2,displacementFieldParameters.ChannelIndex}));
            firstMask = false(size(refFrame));
        else
            firstMask = maskArray(:,:,1);
        end
        
    end

    % % Prepare displacement field for BEM
    % if strcmpi(forceFieldParameters.method,'fastBEM')
    %     displField(end).par=0; % for compatibility with Achim parameter saving
    %     displField=prepDisplForBEM(displField,'linear');
    % end
    % I don't think this is necessary anymore. - SH

    %{
        For Benedikt's software to work, the displacement field has to be
        interpolated on a rectangular grid, with an even number of grid points
        along each edge. Furthermore, one has to make sure that the noisy data 
        has not to be extrapolated. This may happen along the edges. To prevent
        this, extract the corner of the displacement grid, calculate how often 
        (even number) the optimal gridspacing fits into each dimension, then 
        place the regular grid centered to the orignal bounds. Thereby make sure 
        that the edges have been eroded to a certain extend. This is performed by
        the following function.
    %}
    
%     if ~forceFieldParameters.highRes
%         % we have to lower grid spacing because there are some redundant or aggregated displ vectors when additional non-loc-max beads were used for tracking SH170311
%         [reg_grid,~,~,gridSpacing] = createRegGridFromDisplField(displField,0.9,0); 
%     else
%          %no dense mesh in any case. It causes aliasing issue!
%         [reg_grid,~,~,gridSpacing] = createRegGridFromDisplField(displField,1.0,0);
%     end
%--------------------- modified by WIM on 2020-01-28 to match the rest for grid size. Edge Erosion is better

%     if ~forceFieldParameters.highRes
%         % we have to lower grid spacing because there are some redundant or aggregated displ vectors when additional non-loc-max beads were used for tracking SH170311
%         [reg_grid,~,~,gridSpacing] = createRegGridFromDisplField(displField,0.9,1); 
%     else
%          %no dense mesh in any case. It causes aliasing issue!
%         [reg_grid,~,~,gridSpacing] = createRegGridFromDisplField(displField,1,1);
%     end
    [reg_grid,~,~,gridSpacing] = createRegGridFromDisplField(displField, gridMagnification, EdgeErode);
 %-----------------------------------------------

    distToBead = zeros(size(reg_grid(:,:,1)));
    distToBead = distToBead(:);

    disp('(calculateMovieForceField.m): Calculating force field...')
    logMsg = '(calculateMovieForceField.m): \n Please wait, calculating force field';
    timeMsg = @(t) ['\n(calculateMovieForceField.m): Estimated time remaining: ' num2str(round(t/60)) 'min'];
    tic;

    if forceFieldParameters.lastToFirst 
        frameSequence = lastFrame:-1:1;
    else
        frameSequence = firstFrame:nFrames;
    end

    if strcmpi(forceFieldParameters.method,'FastBEM')
        % if FastBEM, we calculate forward map and mesh only in the first frame, and then use parfor for the rest of the frames to calculate forces - SH
        % For the first frame
        i=frameSequence(1);                                                                                                 
        [grid_mat,~, ~,~] = interp_vec2grid(displField(i).pos(:,1:2), displField(i).vec(:,1:2), [], reg_grid);

        % basis function table name adjustment
        expectedName = ['basisClass' num2str(forceFieldParameters.YoungModulus/1000) 'kPa' num2str(gridSpacing) 'pix.mat'];

        % Check if path exists - this step might not be needed because sometimes we need to build a new table with a new name.
        if isempty(forceFieldParameters.basisClassTblPath)
            disp(['(calculateMovieForceField.m): Note, no path given for basis tables, outputing to movieData.mat path: ' ...
                movieData.movieDataPath_]);
            forceFieldParameters.basisClassTblPath = fullfile(movieData.movieDataPath_, expectedName);
        
        else
            if exist(forceFieldParameters.basisClassTblPath,'file')==2 
                disp('(calculateMovieForceField.m): BasisFunctionFolderPath is valid.');
                if numel(whos('basisClassTbl', '-file', forceFieldParameters.basisClassTblPath)) ~= 1
                    disp(['(calculateMovieForceField.m): basisFunction.mat not valid!' forceFieldParameters.basisClassTblPath '. Will build a new basisFunction to this name.']);
                end
            else
                disp('(calculateMovieForceField.m): New basisFunctionFolderPath is entered. Will build a new table and save in this path.');
            end
    %         assert(exist(forceFieldParameters.basisClassTblPath,'file')==2, 'basisFunctionFolderPath not valid!');
    %         assert(numel(whos('basisClassTbl', '-file', forceFieldParameters.basisClassTblPath)) == 1, ['basisFunction.mat not valid!' forceFieldParameters.basisClassTblPath]);
        end

        % Sanity check the paths.
        basisFunctionFolderPath = fileparts(forceFieldParameters.basisClassTblPath);
        assert(exist(basisFunctionFolderPath, 'dir')==7, 'basisFunctionFolderPath not valid!');

        % Check if basis file name is correctly formatted.
        expectedPath = fullfile(basisFunctionFolderPath, expectedName);
        if ~strcmp(expectedPath, forceFieldParameters.basisClassTblPath)
            forceFieldParameters.basisClassTblPath = expectedPath;
            disp(['(calculateMovieForceField.m): basisClassTblPath has different name for estimated mesh grid spacing (' num2str(gridSpacing) '). ']);
            disp('(calculateMovieForceField.m): Now the path is automatically changed to :')
            disp([expectedPath '.']);
        end

        % If grid_mat=[], then an optimal hexagonal force mesh is created given the bead locations defined in displField:
        if forceFieldParameters.usePaxImg && length(movieData.channels_)>1
            for i=frameSequence
                paxImage = movieData.channels_(2).loadImage(i);
                
                [pos_f, force, forceMesh, M, ~, ~, ~, ~]=...
                    reg_FastBEM_TFM(grid_mat, displField, i, ...
                    forceFieldParameters.YoungModulus, forceFieldParameters.PoissonRatio, forceFieldParameters.regParam, forceFieldParameters.meshPtsFwdSol,forceFieldParameters.solMethodBEM,...
                    'basisClassTblPath',forceFieldParameters.basisClassTblPath,wtBarArgs{:},...
                    'imgRows',movieData.imSize_(1),'imgCols',movieData.imSize_(2),...
                    'thickness',forceFieldParameters.thickness/movieData.pixelSize_,'paxImg',paxImage,'pixelSize',movieData.pixelSize_);

                outputFile{3+i,1} = [forceFieldParameters.OutputDirectory filesep 'BEMParams ' num2str(i) ' frame.mat'];

                disp(['(calculateMovieForceField.m): savi ng forward map and custom force mesh at ' outputFile{3+i,1} '...'])
                save(outputFile{3+i,1},'forceMesh','M','-v7.3');
                display(['(calculateMovieForceField.m): Done: solution for frame: ',num2str(i)]);
                
                % Fill in the values to be stored:
                forceField(i).pos=pos_f;
                forceField(i).vec=force;
                display(['(calculateMovieForceField.m): saving ', outputFile{1}]);
                save(outputFile{1},'forceField');
            end
            
        elseif forceFieldParameters.usePaxImg && i>1
            disp('calculateMovieForceField.m): Loading BEM parameters... ')
            load(outputFile{3},'forceMesh','M','sol_mats');
            
            for i=frameSequence
                if forceFieldParameters.usePaxImg && length(movieData.channels_)>1
                    paxImage=movieData.channels_(2).loadImage(i);
                    
                    [pos_f,force,~]=calcSolFromSolMatsFastBEM(M,sol_mats,displField(i).pos(:,1),displField(i).pos(:,2),...
                        displField(i).vec(:,1),displField(i).vec(:,2),forceMesh,forceFieldParameters.regParam,[],[], 'paxImg', paxImage, 'useLcurve', forceFieldParameters.useLcurve);
                else
                    [pos_f,force,~]=calcSolFromSolMatsFastBEM(M,sol_mats,displField(i).pos(:,1),displField(i).pos(:,2),...
                        displField(i).vec(:,1),displField(i).vec(:,2),forceMesh,sol_mats.L,[],[]);
                end
                
                forceField(i).pos=pos_f;
                forceField(i).vec=force;
                % Save each iteration (for recovery of unfinished processes)
                save(outputFile{1},'forceField');
                
                display(['calculateMovieForceField.m): Done: solution for frame: ',num2str(i)]);
                %Update the waitbar
                if mod(i,5)==1 && ishandle(wtBar)
                    ti=toc;
                    waitbar(i/nFrames,wtBar,sprintf([logMsg timeMsg(ti*nFrames/i-ti)]));
                end
                
            end
        else
            if ishandle(wtBar)
                waitbar(0,wtBar,sprintf([logMsg ' for first frame']));
            end
            if forceFieldParameters.useLcurve
                if forceFieldParameters.divideConquer>1 % divide and conquer
                    nOverlap = 10; % the number of grid points to be overlapped
                    
                    % sub-divide grid_mat
                    nLength = sqrt(forceFieldParameters.divideConquer);
                    [nRows, nCols,~]=size(grid_mat);
                    subGridLimits(nLength,nLength) = struct('rowLim','','colLim','');
                    subGrid = cell(nLength);
                    subDisplField = cell(nLength);
                    nRowBlock = ceil(nRows/nLength);
                    nColBlock = ceil(nCols/nLength);
                    forceInFullGrid = zeros(size(grid_mat));
                    subForceInFullGrid = cell(nLength);% zeros(size(grid_mat));
                    fullGrid = zeros(size(grid_mat));
                    subFullGrid = cell(nLength); % zeros(size(grid_mat));
                    
                    % setting up the limits
                    for jj=1:nLength % rows
                        for kk=1:nLength % columns
                            nRowFirst = max(1,1+nRowBlock*(jj-1)-nOverlap);
                            nRowSecond = min(nRows,1+nRowBlock*(jj)+nOverlap);
                            subGridLimits(jj,kk).rowLim=[nRowFirst nRowSecond];
                            nColFirst = max(1,1+nColBlock*(kk-1)-nOverlap);
                            nColSecond = min(nCols,1+nColBlock*(kk)+nOverlap);
                            subGridLimits(jj,kk).colLim=[nColFirst nColSecond];
                        end
                    end

                    nOverlapComb = 1;
                    pp=0; %linear index
                    
                    % Combining...
                    for jj=1:nLength % rows
                        for kk=1:nLength % columns
                            pp=pp+1;
                            curRowRange = subGridLimits(jj,kk).rowLim(1):subGridLimits(jj,kk).rowLim(2);
                            curColRange = subGridLimits(jj,kk).colLim(1):subGridLimits(jj,kk).colLim(2);
                            subGrid{jj,kk} = grid_mat(curRowRange,curColRange,:);
                            % Constructing sub-displacement field
                            subForceMask=zeros(size(firstMask));
                            subDispYFirst = max(1,subGrid{jj,kk}(1,1,2)-2*gridSpacing);
                            subDispYLast = min(size(firstMask,1),subGrid{jj,kk}(end,end,2)+2*gridSpacing);
                            subDispXFirst = max(1,subGrid{jj,kk}(1,1,1)-2*gridSpacing);
                            subDispXLast = min(size(firstMask,2),subGrid{jj,kk}(end,end,1)+2*gridSpacing);
                            subForceMask(subDispYFirst:subDispYLast,subDispXFirst:subDispXLast)=1;
                            subDisplField{jj,kk} = filterDisplacementField(displField,subForceMask);
                            [pos_f_sub{jj,kk}, force_sub{jj,kk}, forceMesh_sub{jj,kk}, M_sub{jj,kk}, ~, ~, ~,  sol_mats{jj,kk}]=...
                                reg_FastBEM_TFM(subGrid{jj,kk}, subDisplField{jj,kk}, i, ...
                                forceFieldParameters.YoungModulus, forceFieldParameters.PoissonRatio, forceFieldParameters.regParam, forceFieldParameters.meshPtsFwdSol,forceFieldParameters.solMethodBEM,...
                                'basisClassTblPath',forceFieldParameters.basisClassTblPath,wtBarArgs{:},...
                                'useLcurve',forceFieldParameters.useLcurve>0, ...
                                'LcurveFactor',forceFieldParameters.LcurveFactor,'thickness',forceFieldParameters.thickness/movieData.pixelSize_,...
                                'LcurveDataPath',outputFile{5,1},'LcurveFigPath',outputFile{4,1},'fwdMap',M,...
                                'lcornerOptimal',forceFieldParameters.lcornerOptimal);
                            % Now we are adding code to use some shared part
                            % for matching the force coefficient outcome and adjusting regularization parameter
                            % Take the overlapping area
                            clear curForceInGrid
                            clear curGrid
                            curForceInGrid(:,:,1) = reshape(force_sub{jj,kk}(:,1),size(subGrid{jj,kk}(:,:,1),2),size(subGrid{jj,kk}(:,:,1),1)); 
                            curForceInGrid(:,:,2) = reshape(force_sub{jj,kk}(:,2),size(subGrid{jj,kk}(:,:,2),2),size(subGrid{jj,kk}(:,:,2),1));
                            curGrid(:,:,1) = reshape(pos_f_sub{jj,kk}(:,1),size(subGrid{jj,kk}(:,:,1),2),size(subGrid{jj,kk}(:,:,1),1));
                            curGrid(:,:,2) = reshape(pos_f_sub{jj,kk}(:,2),size(subGrid{jj,kk}(:,:,2),2),size(subGrid{jj,kk}(:,:,1),1));
                            % Define the overlapping area in the clock-wise
                            % fashion.
                            nRowFirst = max(1,1+nRowBlock*(jj-1)-nOverlapComb);
                            nRowSecond = min(nRows,1+nRowBlock*(jj)+nOverlapComb);
                            nColFirst = max(1,1+nColBlock*(kk-1)-nOverlapComb);
                            nColSecond = min(nCols,1+nColBlock*(kk)+nOverlapComb);
                            curRowRangeComb = nRowFirst:nRowSecond;
                            curColRangeComb =nColFirst:nColSecond;
                            %Insert in the full grid force
                            tempSubForceInFullGrid = zeros(size(grid_mat));
                            tempSubForceInFullGrid(curColRange,curRowRange,:) = curForceInGrid;
                            subForceInFullGrid{jj,kk}=zeros(size(grid_mat));
                            subForceInFullGrid{jj,kk}(curColRangeComb,curRowRangeComb,:)=tempSubForceInFullGrid(curColRangeComb,curRowRangeComb,:);
                            tempSubFullGrid = zeros(size(grid_mat));
                            tempSubFullGrid(curColRange,curRowRange,:) = curGrid;
                            subFullGrid{jj,kk}=zeros(size(grid_mat));
                            subFullGrid{jj,kk}(curColRangeComb,curRowRangeComb,:)=tempSubFullGrid(curColRangeComb,curRowRangeComb,:);

                            % Actual combining
                            forceInFullGrid(curColRangeComb,curRowRangeComb,:)=...
                                subForceInFullGrid{jj,kk}(curColRangeComb,curRowRangeComb,:);
                            fullGrid(curColRangeComb,curRowRangeComb,:)=...
                                subFullGrid{jj,kk}(curColRangeComb,curRowRangeComb,:);
                        end
                    end
                    
                    % re-format forceInFullGrid into vector format
                    forceField(i).pos=[reshape(fullGrid(:,:,1),[],1), reshape(fullGrid(:,:,2),[],1)];
                    forceField(i).vec=[reshape(forceInFullGrid(:,:,1),[],1), reshape(forceInFullGrid(:,:,2),[],1)];
                    
                    save(outputFile{1},'forceField');
                
                else    % No divide and conquer
                    [pos_f, force, forceMesh, M, pos_u, u, sol_coef,  sol_mats]=...
                        reg_FastBEM_TFM(grid_mat, displField, i, ...
                        forceFieldParameters.YoungModulus, forceFieldParameters.PoissonRatio, forceFieldParameters.regParam, forceFieldParameters.meshPtsFwdSol,forceFieldParameters.solMethodBEM,...
                        'basisClassTblPath',forceFieldParameters.basisClassTblPath,wtBarArgs{:},...
                        'imgRows',movieData.imSize_(1),'imgCols',movieData.imSize_(2),...
                        'useLcurve',forceFieldParameters.useLcurve>0, 'LcurveFactor',forceFieldParameters.LcurveFactor,'thickness',forceFieldParameters.thickness/movieData.pixelSize_,...
                        'LcurveDataPath',outputFile{5,1},'LcurveFigPath',outputFile{4,1},'fwdMap',M,...
                        'lcornerOptimal',forceFieldParameters.lcornerOptimal);
                    
                    params = parseProcessParams(forceFieldProc,paramsIn);
                    params.regParam = sol_mats.L;
                    forceFieldParameters.regParam = sol_mats.L;
                    forceFieldProc.setPara(params);
                    
                    forceField(i).pos=pos_f;
                    forceField(i).vec=force;
                    
                    save(outputFile{1},'forceField');
                end
                
            else    % No L-Curve used
                if forceFieldParameters.divideConquer>1        % divide and conquer
                    nOverlap = 10;               % the number of grid points to be overlapped
                    
                    % sub-divide grid_mat
                    nLength = sqrt(forceFieldParameters.divideConquer);
                    [nRows, nCols,~]=size(grid_mat);
                    subGridLimits(nLength,nLength) = struct('rowLim','','colLim','');
                    subGrid = cell(nLength);
                    subDisplField = cell(nLength);
                    nRowBlock = ceil(nRows/nLength);
                    nColBlock = ceil(nCols/nLength);
                    forceInFullGrid = zeros(size(grid_mat));
                    subForceInFullGrid = cell(nLength);% zeros(size(grid_mat));
                    fullGrid = zeros(size(grid_mat));
                    subFullGrid = cell(nLength); % zeros(size(grid_mat));
                    
                    % setting up the limits
                    for jj=1:nLength % rows
                        for kk=1:nLength % columns
                            nRowFirst = max(1,1+nRowBlock*(jj-1)-nOverlap);
                            nRowSecond = min(nRows,1+nRowBlock*(jj)+nOverlap);
                            subGridLimits(jj,kk).rowLim=[nRowFirst nRowSecond];
                            nColFirst = max(1,1+nColBlock*(kk-1)-nOverlap);
                            nColSecond = min(nCols,1+nColBlock*(kk)+nOverlap);
                            subGridLimits(jj,kk).colLim=[nColFirst nColSecond];
                        end
                    end

                    nOverlapComb = 1;
                    pp=0; %linear index
                    
                    % Combining...
                    for jj=1:nLength % rows
                        for kk=1:nLength % columns
                            pp=pp+1;
                            curRowRange = subGridLimits(jj,kk).rowLim(1):subGridLimits(jj,kk).rowLim(2);
                            curColRange = subGridLimits(jj,kk).colLim(1):subGridLimits(jj,kk).colLim(2);
                            subGrid{jj,kk} = grid_mat(curRowRange,curColRange,:);
                            % Constructing sub-displacement field
                            subForceMask=zeros(size(firstMask));
                            subDispYFirst = max(1,subGrid{jj,kk}(1,1,2)-2*gridSpacing);
                            subDispYLast = min(size(firstMask,1),subGrid{jj,kk}(end,end,2)+2*gridSpacing);
                            subDispXFirst = max(1,subGrid{jj,kk}(1,1,1)-2*gridSpacing);
                            subDispXLast = min(size(firstMask,2),subGrid{jj,kk}(end,end,1)+2*gridSpacing);
                            subForceMask(subDispYFirst:subDispYLast,subDispXFirst:subDispXLast)=1;
                            subDisplField{jj,kk} = filterDisplacementField(displField,subForceMask);
                            [pos_f_sub{jj,kk}, force_sub{jj,kk}, forceMesh_sub{jj,kk}, M_sub{jj,kk}, ~, ~, ~,  sol_mats{jj,kk}]=...
                                reg_FastBEM_TFM(subGrid{jj,kk}, subDisplField{jj,kk}, i, ...
                                forceFieldParameters.YoungModulus, forceFieldParameters.PoissonRatio, forceFieldParameters.regParam, forceFieldParameters.meshPtsFwdSol,forceFieldParameters.solMethodBEM,...
                                'basisClassTblPath',forceFieldParameters.basisClassTblPath,wtBarArgs{:},...
                                'useLcurve',forceFieldParameters.useLcurve>0, 'thickness',forceFieldParameters.thickness/movieData.pixelSize_);
                            % Now we are adding code to use some shared part
                            % for matching the force coefficient outcome and adjusting regularization parameter
                            % Take the overlapping area
                            clear curForceInGrid
                            clear curGrid
                            curForceInGrid(:,:,1) = reshape(force_sub{jj,kk}(:,1),size(subGrid{jj,kk}(:,:,1),2),size(subGrid{jj,kk}(:,:,1),1)); 
                            curForceInGrid(:,:,2) = reshape(force_sub{jj,kk}(:,2),size(subGrid{jj,kk}(:,:,2),2),size(subGrid{jj,kk}(:,:,2),1));
                            curGrid(:,:,1) = reshape(pos_f_sub{jj,kk}(:,1),size(subGrid{jj,kk}(:,:,1),2),size(subGrid{jj,kk}(:,:,1),1));
                            curGrid(:,:,2) = reshape(pos_f_sub{jj,kk}(:,2),size(subGrid{jj,kk}(:,:,2),2),size(subGrid{jj,kk}(:,:,1),1));
                            % Define the overlapping area in the clock-wise
                            % fashion.
                            nRowFirst = max(1,1+nRowBlock*(jj-1)-nOverlapComb);
                            nRowSecond = min(nRows,1+nRowBlock*(jj)+nOverlapComb);
                            nColFirst = max(1,1+nColBlock*(kk-1)-nOverlapComb);
                            nColSecond = min(nCols,1+nColBlock*(kk)+nOverlapComb);
                            curRowRangeComb = nRowFirst:nRowSecond;
                            curColRangeComb =nColFirst:nColSecond;
                            %Insert in the full grid force
                            tempSubForceInFullGrid = zeros(size(grid_mat));
                            tempSubForceInFullGrid(curColRange,curRowRange,:) = curForceInGrid;
                            subForceInFullGrid{jj,kk}=zeros(size(grid_mat));
                            subForceInFullGrid{jj,kk}(curColRangeComb,curRowRangeComb,:)=tempSubForceInFullGrid(curColRangeComb,curRowRangeComb,:);
                            tempSubFullGrid = zeros(size(grid_mat));
                            tempSubFullGrid(curColRange,curRowRange,:) = curGrid;
                            subFullGrid{jj,kk}=zeros(size(grid_mat));
                            subFullGrid{jj,kk}(curColRangeComb,curRowRangeComb,:)=tempSubFullGrid(curColRangeComb,curRowRangeComb,:);

                            % Find the overlapping area
                            if ~(pp==1)
                                % find indices of overlapping grid
                                numOverlap = zeros(pp-1,1);
                                idxOverlap = cell(pp-1,1);
                                for qq=1:(pp-1)
                                    jjp = floor((qq-1)/nLength)+1;
                                    kkp = qq-(jjp-1)*nLength;
                                    idxOverlap{qq}=subFullGrid{jjp,kkp}(:,:,1)== subFullGrid{jj,kk}(:,:,1) & ...
                                        subFullGrid{jjp,kkp}(:,:,2)== subFullGrid{jj,kk}(:,:,2) & ...
                                        subFullGrid{jjp,kkp}(:,:,1) & subFullGrid{jjp,kkp}(:,:,2) & ...
                                        subFullGrid{jj,kk}(:,:,1) & subFullGrid{jj,kk}(:,:,2);
                                    numOverlap(qq) = sum(idxOverlap{qq}(:));
                                end
                                % Find the subGrid that has the most overlaps
                                [~,iMaxSubGrid]=max(numOverlap);
                                % Compare force between the current subgrid vs.
                                % iMaxSubGrid
                                jjpSelected = floor((iMaxSubGrid-1)/nLength)+1;
                                kkpSelected = iMaxSubGrid-(jjpSelected-1)*nLength;
                                idxSelectedX = idxOverlap{iMaxSubGrid};
                                idxSelectedY(:,:,2)=idxOverlap{iMaxSubGrid};

                                % force vectors in iMaxSubGrid'th subgrid
                                clear forceInPrevSub gridInPrevSub forceInCurSub gridInCurSub
                                forceInPrevSub(:,1) = subForceInFullGrid{jjpSelected,kkpSelected}(idxSelectedX);
                                forceInPrevSub(:,2) = subForceInFullGrid{jjpSelected,kkpSelected}(idxSelectedY);
                                gridInPrevSub(:,1) = subFullGrid{jjpSelected,kkpSelected}(idxSelectedX);
                                gridInPrevSub(:,2) = subFullGrid{jjpSelected,kkpSelected}(idxSelectedY);

                                % force vectors in the current subgrid
                                forceInCurSub(:,1) = subForceInFullGrid{jj,kk}(idxSelectedX);
                                forceInCurSub(:,2) = subForceInFullGrid{jj,kk}(idxSelectedY);
                                gridInCurSub(:,1) = subFullGrid{jj,kk}(idxSelectedX);
                                gridInCurSub(:,2) = subFullGrid{jj,kk}(idxSelectedY);

                                L=forceFieldParameters.regParam;
                                % calculate difference
                                diffNorm=norm(forceInCurSub)-norm(forceInPrevSub);
                                % Inner product between the two vector field
                                innerProdAll = forceInPrevSub*forceInCurSub';
                                innerProd = diag(innerProdAll);
                                innerProdSum = sum(abs(innerProd));
                                prevSelfProdAll = forceInPrevSub*forceInPrevSub';
                                prevSelfProd = diag(prevSelfProdAll);
                                prevSelfProdSum = sum(abs(prevSelfProd));
                                ratioProdSum=innerProdSum/prevSelfProdSum; %<1 if the current subgrid has underestimating force than overlap from previous subgrid.

                                regFactor=10;
    %                             oldDiffNorm=0;
                                oldRatio = ratioProdSum;
                                % For debugging
                                sc=0.01;
                                figure,quiver(gridInPrevSub(:,1),gridInPrevSub(:,2),sc*forceInPrevSub(:,1),sc*forceInPrevSub(:,2),0,'k')
                                hold on,quiver(gridInCurSub(:,1),gridInCurSub(:,2),sc*forceInCurSub(:,1),sc*forceInCurSub(:,2),0,'r')
                                disp(['ratioProdSum: ' num2str(ratioProdSum) ])
                                accuFactor=0.1; %deviation by 10 % is allowed
                                while (ratioProdSum>(1+accuFactor) || ratioProdSum<(1-accuFactor)) && regFactor>=1.01 %while the difference in norm is more than 100 Pa,
                                    % change regularization parameter appropriately
                                    if ratioProdSum<1 % if the current norm is smaller, L should be smaller to yield less-underestimated solution
                                        if oldRatio>1
                                            regFactor=regFactor^0.9;
                                        end
                                        L=L*1/regFactor;
                                    elseif ratioProdSum>1 % if the current dot product sum is larger, the larger L should be applied to yield suppressed solution.
                                        if oldRatio<1 
                                            regFactor=regFactor^0.9;
                                        end
                                        L=L*regFactor;
                                    end
                                    disp(['Testing L= ' num2str(L)])
                                    oldRatio=ratioProdSum;
                                    [pos_f_sub{jj,kk}, force_sub{jj,kk}, forceMesh_sub{jj,kk}, M_sub{jj,kk}, ~, ~, ~,  sol_mats{jj,kk}]=...
                                        reg_FastBEM_TFM(subGrid{jj,kk}, subDisplField{jj,kk}, i, ...
                                        forceFieldParameters.YoungModulus, forceFieldParameters.PoissonRatio, L, forceFieldParameters.meshPtsFwdSol,forceFieldParameters.solMethodBEM,...
                                        'basisClassTblPath',forceFieldParameters.basisClassTblPath,wtBarArgs{:}, 'fwdMap', M_sub{jj,kk},...
                                        'useLcurve',false, 'thickness',forceFieldParameters.thickness/movieData.pixelSize_);

                                    clear curForceInGrid
                                    clear curGrid
                                    curForceInGrid(:,:,1) = reshape(force_sub{jj,kk}(:,1),size(subGrid{jj,kk}(:,:,1),2),size(subGrid{jj,kk}(:,:,1),1)); 
                                    curForceInGrid(:,:,2) = reshape(force_sub{jj,kk}(:,2),size(subGrid{jj,kk}(:,:,2),2),size(subGrid{jj,kk}(:,:,2),1));
                                    curGrid(:,:,1) = reshape(pos_f_sub{jj,kk}(:,1),size(subGrid{jj,kk}(:,:,1),2),size(subGrid{jj,kk}(:,:,1),1));
                                    curGrid(:,:,2) = reshape(pos_f_sub{jj,kk}(:,2),size(subGrid{jj,kk}(:,:,2),2),size(subGrid{jj,kk}(:,:,1),1));
                                    % Define the overlapping area in the clock-wise
                                    % fashion.
                                    %Insert in the full grid force
                                    tempSubForceInFullGrid = zeros(size(grid_mat));
                                    tempSubForceInFullGrid(curColRange,curRowRange,:) = curForceInGrid;
                                    subForceInFullGrid{jj,kk}=zeros(size(grid_mat));
                                    subForceInFullGrid{jj,kk}(curColRangeComb,curRowRangeComb,:)=tempSubForceInFullGrid(curColRangeComb,curRowRangeComb,:);
                                    tempSubFullGrid = zeros(size(grid_mat));
                                    tempSubFullGrid(curColRange,curRowRange,:) = curGrid;
                                    subFullGrid{jj,kk}=zeros(size(grid_mat));
                                    subFullGrid{jj,kk}(curColRangeComb,curRowRangeComb,:)=tempSubFullGrid(curColRangeComb,curRowRangeComb,:);

                                    forceInCurSub(:,1) = subForceInFullGrid{jj,kk}(idxSelectedX);
                                    forceInCurSub(:,2) = subForceInFullGrid{jj,kk}(idxSelectedY);
                                    gridInCurSub(:,1) = subFullGrid{jj,kk}(idxSelectedX);
                                    gridInCurSub(:,2) = subFullGrid{jj,kk}(idxSelectedY);
    %                                 diffNorm=norm(forceInCurSub)-norm(forceInPrevSub);

                                    innerProdAll = forceInPrevSub*forceInCurSub';
                                    innerProd = diag(innerProdAll);
                                    innerProdSum = sum(abs(innerProd));
                                    ratioProdSum=innerProdSum/prevSelfProdSum; %<1 if the current subgrid has underestimating force than overlap from previous subgrid.
                                    % For debugging
                                    sc=0.01;
                                    figure,quiver(gridInPrevSub(:,1),gridInPrevSub(:,2),sc*forceInPrevSub(:,1),sc*forceInPrevSub(:,2),0,'k')
                                    hold on,quiver(gridInCurSub(:,1),gridInCurSub(:,2),sc*forceInCurSub(:,1),sc*forceInCurSub(:,2),0,'r')
                                    disp(['calculateMovieForceField.m): ratioProdSum: ' num2str(ratioProdSum) ' at L=' num2str(L)])
                                end
                            end

                            % Actual combining
                            forceInFullGrid(curColRangeComb,curRowRangeComb,:)=...
                                subForceInFullGrid{jj,kk}(curColRangeComb,curRowRangeComb,:);
                            fullGrid(curColRangeComb,curRowRangeComb,:)=...
                                subFullGrid{jj,kk}(curColRangeComb,curRowRangeComb,:);
                        end
                    end
                    
                    % re-format forceInFullGrid into vector format
                    forceField(i).pos=[reshape(fullGrid(:,:,1),[],1), reshape(fullGrid(:,:,2),[],1)];
                    forceField(i).vec=[reshape(forceInFullGrid(:,:,1),[],1), reshape(forceInFullGrid(:,:,2),[],1)];
                    
                    save(outputFile{1},'forceField');
                else               % No divide and conquer
                    [pos_f, force, forceMesh, M, pos_u, u, sol_coef,  sol_mats]=...
                        reg_FastBEM_TFM(grid_mat, displField, i, ...
                        forceFieldParameters.YoungModulus, forceFieldParameters.PoissonRatio, forceFieldParameters.regParam, forceFieldParameters.meshPtsFwdSol,forceFieldParameters.solMethodBEM,...
                        'basisClassTblPath',forceFieldParameters.basisClassTblPath,wtBarArgs{:},...
                        'imgRows',movieData.imSize_(1),'imgCols',movieData.imSize_(2),...
                        'useLcurve',forceFieldParameters.useLcurve>0, 'thickness',forceFieldParameters.thickness/movieData.pixelSize_,'fwdMap',M);
                    
                    forceField(i).pos=pos_f;
                    forceField(i).vec=force;
                    
                    save(outputFile{1},'forceField');
                end
            end
            
            
            % Error estimation
            % I will use forward matrix to estimate relative uncertainty of calculated displacement field for each force node. - SH            % 09/08/2015
            % First, get the maxima for each force node from M
            forceNodeMaxima = max(M);
    %             [neigh,bounds,bdPtsID]=findNeighAndBds(p,t);
    %         forceConfidence.pos = forceMesh.p;
            cellPosition = arrayfun(@(x) x.node, forceMesh.basis,'UniformOutput',false);
            forceConfidence.pos = cell2mat(cellPosition');
            forceConfidence.vec = reshape(forceNodeMaxima,[],2);
            
            % Make it relative
            maxCfd = max(forceNodeMaxima);
            forceConfidence.vec = forceConfidence.vec/maxCfd;
            u_org = vertcat(displField(i).vec(:,1),displField(i).vec(:,2));
    %         if forceFieldParameters.divideConquer>1
    %             %reconstruct M from M_sub
    %             
    %             u_predict = M*sol_coef;
    %         else
    %             u_predict = M*sol_coef;
    %         end
    %         u_diff = u_org-u_predict;
    %         u_diff_vec=reshape(u_diff,[],2);
    %         displErrField(i).pos=pos_u;
    %         displErrField(i).vec=u_diff_vec;
    
            % Distance to the closest bead from each force node
            % check if pos_u is already nan-clear in terms of u
            if length(pos_u(:))==length(u)
                beadsWhole = pos_u;
            else
                idNanU = isnan(u_org);
                pos_u = pos_u(~idNanU);
                beadsWhole = pos_u;
            end
            
%             % This parfor was uncommented by WIM on 2/17/2019
%             parfor i=1:length(forceField(i).pos(:,1))
%                 [~,distToBead(i)] = KDTreeClosestPoint(beadsWhole,forceField(i).pos(:,1));
%             end

            %             display('(calculateMovieForceField.m): The total time for calculating the FastBEM solution: ')

            % The following values should/could be stored for the BEM-method.
            % In most cases, except the sol_coef this has to be stored only once for all frames!
            if forceFieldParameters.saveBEMparams && strcmpi(reuseFwdMap,'No') && forceFieldParameters.divideConquer==1
                disp(['(calculateMovieForceField.m): saving forward map and force mesh at ' outputFile{3} '...'])
                save(outputFile{3},'forceMesh','M','sol_mats','pos_u','u','-v7.3');
                
            elseif forceFieldParameters.saveBEMparams && strcmpi(reuseFwdMap,'No') && forceFieldParameters.divideConquer>1
                disp(['(calculateMovieForceField.m): saving forward map and force mesh at ' outputFile{3} '...'])
                save(outputFile{3},'pos_f_sub','force_sub','M_sub','forceMesh_sub','sol_mats','-v7.3');
            end
            
            for i=frameSequence(2:end)
                % since the displ field has been prepared such
                % that the measurements in different frames are ordered in the
                % same way, we don't need the position information any
                % more. The displ. measurements are enough.
                disp('(calculateMovieForceField.m): 5.) Re-evaluate the solution:... ')
                if forceFieldParameters.usePaxImg && length(movieData.channels_)>1
                    paxImage=movieData.channels_(2).loadImage(i);
                    
                    [pos_f,force,sol_coef]=calcSolFromSolMatsFastBEM(M,sol_mats,displField(i).pos(:,1),displField(i).pos(:,2),...
                        displField(i).vec(:,1),displField(i).vec(:,2),forceMesh,forceFieldParameters.regParam,[],[], 'paxImg', paxImage, 'useLcurve', forceFieldParameters.useLcurve);
                else
                    [pos_f,force,sol_coef]=calcSolFromSolMatsFastBEM(M,sol_mats,displField(i).pos(:,1),displField(i).pos(:,2),...
                        displField(i).vec(:,1),displField(i).vec(:,2),forceMesh,sol_mats.L,[],[]);
                end
                forceField(i).pos=pos_f;
                forceField(i).vec=force;
                % Save each iteration (for recovery of unfinished processes)
                save(outputFile{1},'forceField');
                % Error estimation
                u_org = vertcat(displField(i).vec(:,1),displField(i).vec(:,2));
                u_predict = M*sol_coef;
                u_diff = u_org-u_predict;
                u_diff_vec=reshape(u_diff,[],2);
                displErrField(i).pos=pos_u;
                displErrField(i).vec=u_diff_vec;
                display(['Done: solution for frame: ',num2str(i)]);
                %Update the waitbar
                if mod(i,5)==1 && ishandle(wtBar)
                    ti=toc;
                    waitbar(i/nFrames,wtBar,sprintf([logMsg timeMsg(ti*nFrames/i-ti)]));
                end
            end
        end        
    else  %% ********* FTTC ****************
        reg_corner = forceFieldParameters.regParam;
        if ~exist('s', 'var')
            [displacementFileName, outputPath] = uigetfile(movieData.outputDirectory_, 'Open the displacement field "displField.mat" under displacementField or backups');
            if displacementFileName == 0, return; end
            InputFileFullName = fullfile(outputPath, displacementFileName);        
            s = load(InputFileFullName);
        end
        framePlotted =~arrayfun(@(x)isempty(x.pos),s.displField);
        frameSequencetmp = frameSequence;
        frameSequence = frameSequencetmp(framePlotted);
        for i = frameSequence 
            [grid_mat, iu_mat, i_max,j_max] = interp_vec2grid(displField(i).pos(:,1:2), displField(i).vec(:,1:2),[],reg_grid);
            
            %____________________________ Updated by Waddah Moghram on 2019-12-16. 2020-03-03. Switch to zeros only.
            if forceFieldParameters.PadRandomZeros
                [iu_mat_Padded, ~, iu_mat_Padded_TopLeftCorner, iu_mat_Padded_BottomRightCorner] =  PadArrayRandomAndZeros(iu_mat, true);
                [i_max,j_max, ~] = size(iu_mat_Padded);
            else
                iu_mat_Padded = iu_mat;
            end
            
            if forceFieldParameters.WienerFilter
               for kk = 1:size(iu_mat_Padded,3), iu_mat_Padded(:,:,kk) = wiener2(iu_mat_Padded(:,:,kk), forceFieldParameters.WienerWindowSize); end    
            end
            
            if forceFieldParameters.HanWindow
                iu_mat_Padded = HanWindow(iu_mat_Padded);
            end
            
             if forceFieldParameters.useLcurve && i == frameSequence(1)
                 %_____ added by WIM on 2020-02-20
                SizeX = size(iu_mat_Padded);
                SizeY = size(iu_mat_Padded);
                xVecGrid = 1:SizeX;
                yVecGrid = 1:SizeY;
                [Xvec, Yvec] = ndgrid(xVecGrid, yVecGrid);
                grid_mat_padded(:,:,1) = Xvec;
                grid_mat_padded(:,:,2) = Yvec;
                disp('Calculating L-Curve values in progress...');

                [rho,eta,reg_corner,alphas] = calculateLcurveFTTC(grid_mat_padded, iu_mat_Padded, forceFieldParameters.YoungModulus,...
                    forceFieldParameters.PoissonRatio, gridSpacing, i_max, j_max, forceFieldParameters.regParam,forceFieldParameters.LcurveFactor);

                [reg_corner,ireg_corner,~,hLcurve] = regParamSelecetionLcurve(alphas',eta,alphas,reg_corner,'manualSelection',true);

                save(outputFile{5,1},'rho','eta','reg_corner','ireg_corner');
                saveas(hLcurve,outputFile{4,1});
                close(hLcurve)
            end
            
            
            [pos_f,~,force,~,~] = reg_fourier_TFM(grid_mat, iu_mat_Padded, forceFieldParameters.YoungModulus,...
                forceFieldParameters.PoissonRatio, movieData.pixelSize_/1000, gridSpacing, i_max, j_max, reg_corner);
            
            
            % Trimming the padding.
            if forceFieldParameters.PadRandomZeros
                iu_mat_Padded_Size = size(iu_mat_Padded);
                force_Padded_grid = reshape(force, iu_mat_Padded_Size);    
                clear force_grid_trimmed
                for kk = 1:size(force_Padded_grid, 3)
                    force_grid_trimmed(:,:,kk) = force_Padded_grid(iu_mat_Padded_TopLeftCorner(1):iu_mat_Padded_BottomRightCorner(1) , iu_mat_Padded_TopLeftCorner(2):iu_mat_Padded_BottomRightCorner(2), kk);
                end
                force = reshape(force_grid_trimmed, size(pos_f));
            end
            %______________________________________________________________________________
            forceField(i).pos = pos_f;
            forceField(i).vec = force;
        end
    end
    
    %% For calculation of traction map and prediction error map
    % The drift-corrected frames should have independent channel
    % ->StageDriftCorrectionProcess
%     disp('(calculateMovieForceField.m): Creating traction map...')
%     tic
%     [tMapIn, tmax, tmin, cropInfo,tMapXin,tMapYin] = generateHeatmapShifted(forceField,displField,0);
%     disp(['(calculateMovieForceField.m): Estimated traction maximum = ' num2str(tmax) ' Pa.'])
%     toc
    
    
    
    % Commented out by Waddah Moghram on 1/23/2019. I am not sure why the line below was multiplied by 0.8
%     tmax = 0.8*tmax;
%     disp(['(generateHeatmapShifted.m): Estimated force maximum = ' num2str(tmax) ' Pa.'])
     

%     
%     if strcmpi(forceFieldParameters.method,'FastBEM')
%         [fCfdMapIn, fCmax, fCmin, cropInfoFC] = generateHeatmapShifted(forceConfidence,displField,0);
%         fCfdMapIn{1} = fCfdMapIn{1}/max(fCfdMapIn{1}(:));
%     end
   %% Line below commented out by WIM on 2/18/2019
%     disp(['(calculateMovieForceField.m): Displacement error minimum = ' num2str(dEmax) ' pixel.'])
% 
%     for ii=frameSequence
%         distBeadField(ii).pos = forceField(ii).pos;
%         distBeadField(ii).vec = [distToBead zeros(size(distToBead))];
%     end
%     [distBeadMapIn, dBeadmax, dBeadmin] = generateHeatmapShifted(distBeadField,displField,0);
% 
%     display(['(calculateMovieForceField.m): Distance to closest bead maximum = ' num2str(tmax) ' Pa.'])
    
%     %% Insert traction map in forceField.pos 
%     disp('(calculateMovieForceField.m): Writing traction maps ...')
%     tMap = cell(1,nFrames);
%     tMapX = cell(1,nFrames);
%     tMapY = cell(1,nFrames);
%     fCfdMap = cell(1,1);                                                     %force confidence
% 
%     % Set up the output directories
%     outputDir = fullfile(forceFieldParameters.OutputDirectory,'tractionMaps');
%     mkClrDir(outputDir);
%     fString = ['%0' num2str(floor(log10(nFrames))+1) '.f'];
%     numStr = @(frame) num2str(frame,fString);
%     outFileTMap=@(frame) [outputDir filesep 'tractionMap' numStr(frame) '.mat'];
% 
%     % distBeadMap = cell(1,nFrames);
%     for ii=frameSequence
%         % starts with original size of beads
%         cur_tMap = zeros(size(firstMask));
%         cur_tMapX = zeros(size(firstMask));
%         cur_tMapY = zeros(size(firstMask));
%     %     cur_distBeadMap = zeros(size(firstMask));
%         cur_tMap(cropInfo(2):cropInfo(4),cropInfo(1):cropInfo(3)) = tMapIn{ii};
%         cur_tMapX(cropInfo(2):cropInfo(4),cropInfo(1):cropInfo(3)) = tMapXin{ii};
%         cur_tMapY(cropInfo(2):cropInfo(4),cropInfo(1):cropInfo(3)) = tMapYin{ii};
%     %     cur_distBeadMap(cropInfo(2):cropInfo(4),cropInfo(1):cropInfo(3)) = distBeadMapIn{ii};
%         tMap{ii} = cur_tMap;
%         tMapX{ii} = cur_tMapX;
%         tMapY{ii} = cur_tMapY;
%         if ii==1 && strcmpi(forceFieldParameters.method,'FastBEM')
%             cur_fCfdMap = zeros(size(firstMask));
%             cur_fCfdMap(cropInfoFC(2):cropInfoFC(4),cropInfoFC(1):cropInfoFC(3)) = fCfdMapIn{ii};
%             fCfdMap = cur_fCfdMap;
%         end     
%     %     distBeadMap{ii} = cur_distBeadMap;
%         % Shifted forceField vector field
%         curDispVec = displField(ii).vec;
%         curDispVec = curDispVec(~isnan(curDispVec(:,1)),:); % This will remove the warning 
%         curDispPos = displField(ii).pos;
%         curDispPos = curDispPos(~isnan(curDispVec(:,1)),:); % This will remove the warning 
%         [grid_mat,iu_mat, ~,~] = interp_vec2grid(curDispPos(:,1:2), curDispVec(:,1:2),[],reg_grid);
%     %     [grid_mat,iu_mat, ~,~] = interp_vec2grid(displField(ii).pos(:,1:2), displField(ii).vec(:,1:2),[],reg_grid);
%         displ_vec = [reshape(iu_mat(:,:,1),[],1) reshape(iu_mat(:,:,2),[],1)]; 
% 
%         [forceFieldShiftedpos,forceFieldShiftedvec, ~, ~] = interp_vec2grid(forceField(ii).pos+displ_vec, forceField(ii).vec(:,1:2),[],grid_mat); %1:cluster size
%         pos = [reshape(forceFieldShiftedpos(:,:,1),[],1) reshape(forceFieldShiftedpos(:,:,2),[],1)]; %dense
%         force_vec = [reshape(forceFieldShiftedvec(:,:,1),[],1) reshape(forceFieldShiftedvec(:,:,2),[],1)]; 
% 
%         forceFieldShifted(ii).pos = pos;
%         forceFieldShifted(ii).vec = force_vec;
        
        % Modified by Waddah Moghram on 2/18/2019 to save also tMapX and tMapY in the individual files.
        % to be used with TractionForcesAllFrames2_0.m or TractionForceSingleFrame2_0.m 
%         save(outFileTMap(ii),'cur_tMap','-v7.3');
%         save(outFileTMap(ii),'cur_tMap', 'cur_tMapX', 'cur_tMapY','-v7.3')
%     end
    
    % Fill in the values to be stored:
    clear grid_mat;
    clear iu;
    clear iu_mat;

    disp('(calculateMovieForceField.m): Saving traction maps...')
    
    % save(outputFile{1},'forceField','forceFieldShifted','displErrField');
    % save(outputFile{2},'tMap','tMapX','tMapY','dErrMap','distBeadMap'); % need to be updated for faster loading. SH 20141106
%     
%     save(outputFile{1},'forceField','forceFieldShifted');
%             
    save(outputFile{1},'forceField');  
%     if strcmpi(forceFieldParameters.method,'FastBEM')
%         save(outputFile{2},'tMap','tMapX','tMapY','fCfdMap','-v7.3'); % need to be updated for faster loading. SH 20141106
%     else
%         save(outputFile{2},'tMap','tMapX','tMapY','-v7.3'); % need to be updated for faster loading. SH 20141106
%     end


%     forceFieldProc.setTractionMapLimits([tmin tmax])
    % forceFieldProc.setDisplErrMapLimits([dEmin dEmax])
    % forceFieldProc.setDistBeadMapLimits([dBeadmin dBeadmax])

     %% Added by Generated Heat Map to Identify the limits of the heat map without actually generating it yet...by Waddah Moghram 
    tmax = -1;
    tmin = Inf;
    band = 0;
    reg_grid1 = createRegGridFromDisplField(forceField,1,1);                                    % Updated by WIM on 2020-01-20, mag = 1, erodeEdge = 1
%     ---------------------------------- 
    for ii=1:numel(forceField)
        %Load the saved body heat map.
        [~,fmat, ~, ~] = interp_vec2grid(forceField(ii).pos, forceField(ii).vec(:,1:2),[],reg_grid1);            % 1:cluster size
        fnorm = (fmat(:,:,1).^2 + fmat(:,:,2).^2).^0.5;
    
        % Boundary cutting - I'll take care of this boundary effect later
        fnorm(end-round(band/2):end,:)=[];
        fnorm(:,end-round(band/2):end)=[];
        fnorm(1:1+round(band/2),:)=[];
        fnorm(:,1:1+round(band/2))=[];
        fnorm_vec = reshape(fnorm,[],1); 
    
        tmax = max(tmax, max(fnorm_vec));
        tmin = min(tmin, min(fnorm_vec));
    end
    
    save(outputFile{6},'tmax', 'tmin', '-append');                  % Added by WIM on 2019-09-23
    movieDataAfter = movieData;
    save(outputFile{6},'movieDataAfter', '-append');                  % Added by WIM on 2019-09-23    
    MD = movieData; 
    save(outputFile{7}, 'MD','-v7.3');         
    
    forceFieldProc.setTractionMapLimits([tmin, tmax])
    disp(['Estimated maximum traction stress = ' num2str(tmax) ' Pa.'])
    
    % Close waitbar
    if feature('ShowFigureWindows') || ishandle(wtBar), close(wtBar); end
    disp('(calculateMovieForceField.m): Finished calculating force field!')
end
