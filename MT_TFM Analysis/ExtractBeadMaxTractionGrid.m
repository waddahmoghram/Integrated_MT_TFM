% function [MaxTractionDetails, outputPlotFileNameFig] = ExtractBeadMaxTractionGrid(MD, forceField, AnalysisFolderAsWell, FrameNumberMaxTractionGuess)
%% 
%{   
    v.2020-02-06..07 by Waddah Moghram
        1. Updated interpolation from griddata to use V4 based on the cubic interpolation to ensure a C2 continuous function.
        2. Renamed from ExtractBeadCoordinatesEpiMaxInterp.m to ExtractBeadMaxTractionGrid.m
    v.2020-02-04 by Waddah Moghram
        1. supersedes FluoroBeadTractionMaxInterp.m (v.2019-02-07) and 
        is based on ExtractBeadCoordinatesEpiMax.m (v.2020-01-29).

  % **********************TO DO: Re-do by using interpolated value instead of the coordniates of an individual value *********************
    v.2020-01-29 by Waddah Moghram
        1. updated so that t=0 for the first frame.
    v.2020-01-17 by Waddah Moghram
        1. Save max Traction in *.mat to be used by VideoAnalysisCombined.mat
    v.2020-01-16 by Waddah Moghram
        Fixed the time frame so that they are in seconds.
  
    Written by Waddah Moghram, PhD Student in Biomedical Engineering at the University of Iowa... Updated on 2019-05-27
    % update
  %}

%%
    PlotsFontName = 'XITS'; 
    EdgeErode = 1;
    gridMagnification = 1;
    bandSize = 0;
    
    % Check if this device has a GPU device. Take advantage of it. 
    nGPU = gpuDeviceCount;
    if nGPU > 0
        useGPU = true;
    else
        useGPU = false;
    end  
    
    %% --------  nargin 1, Movie Data (MD) by TFM Package -------------------------------------------------------------------  
    if ~exist('MD', 'var'), MD = []; end
    try 
        isMD = (class(MD) ~= 'MovieData');
    catch 
        MD = [];
    end   
%     if nargin < 1 || isempty(MD)
    if isempty(MD)
        [movieFileName, movieFilePath] = uigetfile('*.mat', 'Open the TFM-Package Movie Data File');
        if movieFileName == 0, return; end
        MovieFileFullName = fullfile(movieFilePath, movieFileName);
        try 
            load(MovieFileFullName, 'MD')
            fprintf('Movie Data (MD) file is: \n\t %s\n', MovieFileFullName);
            disp('------------------------------------------------------------------------------')
        catch 
            errordlg('Could not open the movie data file!')
            return
        end
        try 
            isMD = (class(MD) ~= 'MovieData');
        catch 
            errordlg('Could not open the movie data file!')
            return
        end   
    else
        movieFilePath = MD.getPath;
    end
    
  %% --------  nargin 2, force field (forceField) -------------------------------------------------------------------
    ForceOutputPath = '';    
    
    if ~exist('forceField','var'), forceField = []; end
%     if nargin < 2 || isempty(forceField)
    if isempty(forceField)
        try 
            ProcessTag =  MD.findProcessTag('ForceFieldCalculationProcess').tag_;
        catch
            ProcessTag = '';
            disp('No Completed Force Field Calculated!');
            disp('------------------------------------------------------------------------------')
        end

        %------------------
        if exist('ProcessTag', 'var') 
            fprintf('Force Process Tag is: %s\n', ProcessTag);
            try
                InputFileFullName = MD.findProcessTag(ProcessTag).outFilePaths_{1};
                if exist(InputFileFullName, 'file')
                    dlgQuestion = sprintf('Do you want to open the force field referred to in the movie data file?\n\n%s\n', ...
                        InputFileFullName);
                    dlgTitle = 'Open force field (forceField.mat) file?';
                    OpenForceChoice = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No', 'Yes');
                    switch OpenForceChoice
                        case 'Yes'
                            [ForceOutputPath, ~, ~] = fileparts(InputFileFullName);
                        case 'No'
                            InputFileFullName = [];
                        otherwise
                            return
                    end            
                else
                    InputFileFullName = [];
                end
            catch
                InputFileFullName = [];
            end    
        end
    end
    
    %------------------
    if isempty(InputFileFullName) || ~exist('ProcessTag', 'var')          
        TFMPackageFiles = fullfile(movieFilePath,'TFMPackage','*.mat');
        [forceFileName, ForceOutputPath] = uigetfile(TFMPackageFiles, 'Open the force field "forceField.mat" under forceField or backups');
        if forceFileName == 0, return, end
        InputFileFullName = fullfile(ForceOutputPath, forceFileName);
    end                 
    
    %------------------
    try
        load(InputFileFullName, 'forceField')
        fprintf('Force Field (forceField) File is loaded successfully! \n\t %s\n', InputFileFullName);
        disp('------------------------------------------------------------------------------')
    catch
        errordlg('Could not open the force field file.');
        return
    end
    
    %% -----------------------------------------------------------------------------------------------------------------------
    if ~exist('AnalysisFolderAsWell','var'), AnalysisFolderAsWell = []; end    
%     if nargin < 3 || isempty(AnalysisFolderAsWell) || AnalysisFolderAsWell ==0 || upper(AnalysisFolderAsWell) == 'N'
    if isempty(AnalysisFolderAsWell) || AnalysisFolderAsWell ==0 || upper(AnalysisFolderAsWell) == 'N'
        if exist('ForceOutputPath','var')
            dlgQuestion = ({'Do you want to save the output to this folder?', ForceOutputPath});
            dlgTitle = 'Output folder?';
            outputFolderChoice = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No', 'Yes');
            switch outputFolderChoice
                case 'Yes'
                    FramesOutputPath = ForceOutputPath;
                    if ~exist(FramesOutputPath,'dir')   % Check for a directory
                        mkdir(FramesOutputPath);
                    end
                case 'No'
                    FramesOutputPath = uigetdir(movieFilePath,'Choose the directory where the tracked output will be saved.');    
                otherwise
                    return;
            end
        end
        dlgQuestion = ({'Do you want to save in an Analysis output folder?'});
        dlgTitle = 'Analysis folder?';
        AnalysisFolderAsWell = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No', 'No');
        switch AnalysisFolderAsWell
            case 'Yes'
                AnalysisFolderAsWell = 1;
            case 'No'
                AnalysisFolderAsWell = 0;
        end
    end
    
    if AnalysisFolderAsWell == 1 || upper(AnalysisFolderAsWell) == 'Y'
        if ~exist('movieFileDir','var'), movieFileDir = pwd; end
        AnalysisOutputPath = uigetdir(movieFileDir,'Choose the directory where the tracked output will be saved.');          
    end
    if ~exist('AnalysisOutputPath', 'var'), AnalysisOutputPath = []; end
    
    
    %% -----------------------------------------------------------------------------------------------------------------------
    NumFrames = numel(forceField);
    MaxTractionFrameNumber = 0;
    MaxTractionIndex = 0;
           
    FramesDoneBoolean = arrayfun(@(x) ~isempty(x.vec), forceField);
    FramesDoneNumbers = find(FramesDoneBoolean == 1);
    FramesDifference = diff(FramesDoneNumbers);
    VeryLastFrame = find(FramesDoneBoolean, 1, 'last');
    VeryFirstFrame =  find(FramesDoneBoolean, 1, 'first');    
    
    prompt = {sprintf('Choose the first frame to plotted. [Default, Frame = %d]', VeryFirstFrame)};
    dlgTitle = 'First Frame Plotted';
    FirstFrameStr = inputdlg(prompt, dlgTitle, [1, 90], {num2str(VeryFirstFrame)});
    if isempty(FirstFrameStr), return; end
    FirstFrame = str2double(FirstFrameStr{1});          
    [~, FirstFrameIndex] = min(abs(FramesDoneNumbers - FirstFrame));
    FirstFrame = FramesDoneNumbers(FirstFrameIndex);
    
    prompt = {sprintf('Choose the last frame to plotted. [Default, Frame = %d]', VeryLastFrame)};
    dlgTitle = 'Last Frame Plotted';
    LastFrameStr = inputdlg(prompt, dlgTitle, [1, 90], {num2str(VeryLastFrame)});
    if isempty(LastFrameStr), return; end
    LastFrame = str2double(LastFrameStr{1});          
    [~, LastFrameIndex] = min(abs(FramesDoneNumbers - LastFrame));
    LastFrame = FramesDoneNumbers(LastFrameIndex);
    
    FramesDoneNumbers = FramesDoneNumbers(FirstFrameIndex:LastFrameIndex);
    
    dlgQuestion = ({'Which timestamps do you want to use)?'});
    dlgTitle = 'Real-Time vs. Camera-Time vs. from FPS rate?';
    TimeStampChoice = questdlg(dlgQuestion, dlgTitle, 'Real-Time', 'Camera-Time', 'From FPS rate', 'Camera-Time');
    if isempty(TimeStampChoice), error('No Choice was made'); end

    switch TimeStampChoice
        case 'Real-Time'
            try 
                [TimeStampFileNameEPI, TimeStampPathEPI] = uigetfile(movieFilePath, 'EPI TimeStamps RT Sec');
                if isempty(TimeStampFileNameEPI), error('No File Was chosen'); end
                TimeStampFullFileNameEPI = fullfile(TimeStampPathEPI, TimeStampFileNameEPI);
                TimeStampsRT_SecData = load(TimeStampFullFileNameEPI);
                TimeStamps = TimeStampsRT_SecData.TimeStampsAbsoluteRT_Sec;
                FrameRate = 1/mean(diff(TimeStampsRT_SecData.TimeStampsAbsoluteRT_Sec));
            catch                        
                [TimeStamps, ~, ~, ~, AverageFrameRate] = TimestampRTfromSensorData();
                FrameRate = 1/AverageFrameRate;
            end
            xLabelTime = 'Real Time [s]';
            
        case 'Camera-Time'
            try 
                [TimeStampFileNameEPI, TimeStampPathEPI] = uigetfile(movieFilePath, 'EPI TimeStamps ND2 Sec');
                if isempty(TimeStampFileNameEPI), error('No File Was chosen'); end
                TimeStampFullFileNameEPI = fullfile(TimeStampPathEPI, TimeStampFileNameEPI);
                TimeStampsND2_SecData = load(TimeStampFullFileNameEPI);
                TimeStamps = TimeStampsND2_SecData.TimeStampsND2;
                FrameRate = 1/TimeStampsND2_SecData.AverageTimeInterval;
            catch          
                try
                    [TimeStamps, ~, AverageTimeInterval] = ND2TimeFrameExtract(movieData.channels_.channelPath_);
                catch
                    [TimeStamps, ~, AverageTimeInterval] = ND2TimeFrameExtract();            
                end
                FrameRate = 1/AverageTimeInterval;
            end            
            xLabelTime = 'Camera Time [s]';
            
        case 'From FPS rate'
            try 
                FrameRateDefault = 1/MD.timeInterval_;
            catch
                FrameRateDefault = 1/ 0.025;           % (40 frames per seconds)              
            end

            prompt = {sprintf('Choose the Frame Rate per second for this movie. [Default, %.4g]', FrameRateDefault)};
            dlgTitle =  'Frames Per Second';
            FrameRateStr = inputdlg(prompt, dlgTitle, [1, 90], {num2str(FrameRateDefault)});
            if isempty(FrameRateStr), error('No Frame Rate was chosen'); end
            FrameRate = str2double(FrameRateStr{1});      
            
            TimeStamps = FramesDoneNumbers ./ FrameRate;
            xLabelTime = 'Time based on frame rate [s]';
    end
    
    LastFrameOverall = min([LastFrame, numel(TimeStamps)]);
    FramesDoneNumbers = FramesDoneNumbers(1:find(FramesDoneNumbers == LastFrameOverall));
    TimeStampsSec = TimeStamps(FramesDoneNumbers);
%     TimeStampsSec = TimeStampsSec - TimeStampsSec(1);               % MAKE SURE TIME IS REFERENCE TO T = 0 FOR THE FIRST FRAME
    
    %% Check if there is a given frame or frame range where you know the maximum Traction is there
    if ~exist('FrameNumberMaxTractionGuess', 'var'), FrameNumberMaxTractionGuess = []; end
%     if nargin < 4 || isempty(FrameNumberMaxTractionGuess)
    if isempty(FrameNumberMaxTractionGuess)        
        dlgQuestion = 'Do you want to search for the frame of maximum Traction in a certain range?';
        dlgTitle = 'Search for max frame?';
        MaxFrameSearchChoice = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No', 'Yes');
    end
    switch MaxFrameSearchChoice
        case 'Yes'
            prompt = {sprintf('Choose the first frame to searched. [Default, Frame = %d]', FirstFrame)};
            dlgTitle = 'First Frame Searched';
            FirstFrameStr = inputdlg(prompt, dlgTitle, [1, 60], {num2str(FirstFrame)});
            if isempty(FirstFrameStr), return; end
            FirstFrameSearch = str2double(FirstFrameStr{1});          
            [~, FirstFrameIndexSearch] = min(abs(FramesDoneNumbers - FirstFrameSearch));
%             FirstFrameSearch = FramesDoneNumbers(FirstFrameIndex);

            prompt = {sprintf('Choose the last frame to searched. [Default, Frame = %d]', LastFrame)};
            dlgTitle = 'Last Frame Searched';
            LastFrameStr = inputdlg(prompt, dlgTitle, [1, 90], {num2str(LastFrame)});
            if isempty(LastFrameStr), return; end
            LastFrameSearch = str2double(LastFrameStr{1});          
            [~, LastFrameIndexSearch] = min(abs(FramesDoneNumbers - LastFrameSearch));
%             LastFrameSearch = FramesDoneNumbers(LastFrameIndex);

            FramesDoneNumbersSearch = FramesDoneNumbers(FirstFrameIndexSearch:LastFrameIndexSearch);    
            
        case 'No'
            FramesDoneNumbersSearch = FramesDoneNumbers;
            % Continue
        otherwise
            return
    end   
    
    
%% Finding maximum bead
    MaxTractionPaNet = -1;

    [reg_grid, ~, ~, GridSpacing] = createRegGridFromDisplField(forceField(FramesDoneNumbers(1)).pos, gridMagnification, EdgeErode);                                                % 2=2 times fine interpolation
    
    reverseString = '';
    for CurrentFrame = FramesDoneNumbersSearch
        ProgressMsg = sprintf('Searching Frame #%d/(%d-%d)...\n',CurrentFrame, FramesDoneNumbersSearch(1),FramesDoneNumbersSearch(end));
        fprintf([reverseString, ProgressMsg]);
        reverseString = repmat(sprintf('\b'), 1, length(ProgressMsg));
        
        [grid_mat, TractionVecGridXY,~,~] = interp_vec2grid(forceField(CurrentFrame).pos(:,1:2), forceField(CurrentFrame).vec(:,1:2) ,[], reg_grid);
    
        grid_spacingX = grid_mat(1,2,1)- grid_mat(1,1,1);
        grid_spacingY = grid_mat(2,1,2)- grid_mat(1,1,2);        
        imSizeX = (grid_mat(end,end,1) - grid_mat(1,1,1)) + grid_spacingX;
        imSizeY = (grid_mat(end,end,2) - grid_mat(1,1,2)) + grid_spacingY; 

        width = imSizeX;
        height = imSizeY;
        centerX = ((grid_mat(end,end,1) + grid_mat(1,1,1))/2);
        centerY = ((grid_mat(end,end,2) + grid_mat(1,1,2))/2);
        % [XI,YI] = meshgrid(grid_mat(1,1,1):grid_mat(1,1,1)+imSizeX,grid_mat(1,1,2):grid_mat(1,1,2)+imSizeY);
        Xmin = centerX - width/2 + bandSize;
        Xmax = centerX + width/2 - bandSize;
        Ymin = centerY - height/2 + bandSize;
        Ymax = centerY + height/2 - bandSize;
%         [XI, YI] = meshgrid(Xmin:Xmax,Ymin:Ymax);
        [XI, YI] = ndgrid(Xmin:Xmax,Ymin:Ymax);  
        
        reg_gridFull(:,:,1)  = XI; reg_gridFull(:,:,2)  = YI;
        [grid_mat_full, TraccionVecGridFullXY,~,~] = interp_vec2grid(forceField(CurrentFrame).pos(:,1:2), forceField(CurrentFrame).vec(:,1:2) ,[], reg_gridFull, 'griddata');    
        TractionHeatMapFullX = TraccionVecGridFullXY(:,:,1);
        TractionHeatMapFullY = TraccionVecGridFullXY(:,:,2);
        TractionHeatMapFullNorm =  (TraccionVecGridFullXY(:,:,1).^2 + TraccionVecGridFullXY(:,:,2).^2).^0.5;     
   
        [tmpMaxTractionFieldNetInFrame, tmpMaxTractionFieldInFrameIndex] =  max(TractionHeatMapFullNorm(:));          % maximum item in a column

        if tmpMaxTractionFieldNetInFrame > MaxTractionPaNet
            MaxTractionPaNet = tmpMaxTractionFieldNetInFrame;            
            MaxTractionIndex = tmpMaxTractionFieldInFrameIndex;
            MaxTractionFrameNumber = CurrentFrame;
            MaxTractionPaXYnet = [TractionHeatMapFullX(MaxTractionIndex), TractionHeatMapFullY(MaxTractionIndex) , TractionHeatMapFullNorm(MaxTractionIndex)];
            MaxPosXYnet = [XI(MaxTractionIndex), YI(MaxTractionIndex)];
        end 
    end
    fprintf('Maximum Traction = %g Pa at ', MaxTractionPaNet);
    fprintf('[x,y] = [%g, %g] pixels in Frame #%d, Point Index #%d \n', MaxPosXYnet, MaxTractionFrameNumber, MaxTractionIndex)
    fprintf('Maximum Traction [T_x, T_y] =  [%0.4g, %0.4g] Pa==> Net Traction = [%g] Pa. \n', MaxTractionPaXYnet)

%%  Track the max over all Frames.
    reverseString = '';        
    for CurrentFrame = FramesDoneNumbers
        ProgressMsg = sprintf('Tracking Maximum Node at Frame #%d/(%d-%d)...\n',CurrentFrame, FramesDoneNumbers(1),FramesDoneNumbers(end));
        fprintf([reverseString, ProgressMsg]);
        reverseString = repmat(sprintf('\b'), 1, length(ProgressMsg));
        
        [grid_mat, TractionVecGridXY,~,~] = interp_vec2grid(forceField(CurrentFrame).pos(:,1:2), forceField(CurrentFrame).vec(:,1:2) ,[], reg_grid, 'griddata');    
        grid_spacingX = grid_mat(1,2,1)- grid_mat(1,1,1);
        grid_spacingY = grid_mat(2,1,2)- grid_mat(1,1,2);        
        imSizeX = (grid_mat(end,end,1) - grid_mat(1,1,1)) + grid_spacingX;
        imSizeY = (grid_mat(end,end,2) - grid_mat(1,1,2)) + grid_spacingY; 

        width = imSizeX;
        height = imSizeY;
        centerX = ((grid_mat(end,end,1) + grid_mat(1,1,1))/2);
        centerY = ((grid_mat(end,end,2) + grid_mat(1,1,2))/2);
        % [XI,YI] = meshgrid(grid_mat(1,1,1):grid_mat(1,1,1)+imSizeX,grid_mat(1,1,2):grid_mat(1,1,2)+imSizeY);
        Xmin = centerX - width/2 + bandSize;
        Xmax = centerX + width/2 - bandSize;
        Ymin = centerY - height/2 + bandSize;
        Ymax = centerY + height/2 - bandSize;
%         [XI, YI] = meshgrid(Xmin:Xmax,Ymin:Ymax);
        [XI, YI] = ndgrid(Xmin:Xmax,Ymin:Ymax);       
        reg_gridFull(:,:,1)  = XI; reg_gridFull(:,:,2)  = YI;
        [grid_mat_full, TraccionVecGridFullXY,~,~] = interp_vec2grid(forceField(CurrentFrame).pos(:,1:2), forceField(CurrentFrame).vec(:,1:2) ,[], reg_gridFull, 'griddata');    
        TractionHeatMapFullX = TraccionVecGridFullXY(:,:,1);
        TractionHeatMapFullY = TraccionVecGridFullXY(:,:,2);
        TractionHeatMapFullNorm =  (TraccionVecGridFullXY(:,:,1).^2 + TraccionVecGridFullXY(:,:,2).^2).^0.5;     
        
        TxRedBeadMaxNetPositionPixels(CurrentFrame, :) = [XI(MaxTractionIndex),YI(MaxTractionIndex)];
        TxRedBeadMaxNetTractionPa(CurrentFrame, 1:3) = [TractionHeatMapFullX(MaxTractionIndex), TractionHeatMapFullY(MaxTractionIndex),  TractionHeatMapFullNorm(MaxTractionIndex)];
    end
  
    %% ---------------- PLOTS
    figHandleBeadMaxNetDispl = figure('color','w', 'Renderer', 'painters');
    plot(TimeStampsSec, TxRedBeadMaxNetTractionPa(FramesDoneNumbers,3), 'r.-',  'LineWidth', 1', 'MarkerSize', 2)
    xlim( [0, TimeStampsSec(end)]);
    set(findobj(gcf,'type', 'axes'), ...
        'FontSize',12, ...
        'FontName', 'Helvetica', ...
        'LineWidth',1, ...
        'XMinorTick', 'on', ...
        'YMinorTick', 'on', ...
        'TickDir', 'out', ...
        'TitleFontSizeMultiplier', 0.9, ...
        'TitleFontWeight', 'bold');     % Make axes bold 
    xlabelHandle = xlabel(sprintf('\\rm %s', xLabelTime));
    set(xlabelHandle, 'FontName', PlotsFontName)
    ylabel('\bf|\itT\rm_{TxRed}(\itt\rm)\bf|\rm [Pa]', 'FontName', PlotsFontName); 
    
    title({'Maximum EPI Bead Traction (Interpolated)',sprintf('Max at (X,Y) = (%d,%d) pix in Frame %d/%d = %0.3f sec',...
        XI(MaxTractionIndex), YI(MaxTractionIndex), ...
        MaxTractionFrameNumber,LastFrame, TimeStamps(MaxTractionFrameNumber)), ...
        sprintf('Max Traction = %0.4f Pa', MaxTractionPaXYnet(3))})

    MaxTractionDetails.TimeFrameSeconds = TimeStampsSec;
    MaxTractionDetails.TxRedBeadMaxNetPositionPixels = TxRedBeadMaxNetPositionPixels;
    MaxTractionDetails.TxRedBeadMaxNetTractionPa = TxRedBeadMaxNetTractionPa;
    MaxTractionDetails.MaxTractionFrameNumber = MaxTractionFrameNumber;
    MaxTractionDetails.MaxTractionPaNet = MaxTractionPaNet;
    MaxTractionDetails.MaxPosXYnet = MaxPosXYnet;
    MaxTractionDetails.MaxTractionIndex = MaxTractionIndex;
    
    
        %%
    disp('**___to continue saving, type "dbcont" or press "F5", or click "Continue" under "Editor" Menu"___**')
    keyboard
    
    %%
    outputPlotFileNameFig = fullfile(FramesOutputPath, sprintf('Traction_TxRed_max_interp_%s.fig', TimeStampChoice));
%     outputPlotFileNameTIF = fullfile(FramesOutputPath,  sprintf('Traction_TxRed_max_interp_%s.tif', TimeStampChoice));
    outputPlotFileNamePNG = fullfile(FramesOutputPath,  sprintf('Traction_TxRed_max_interp_%s.png', TimeStampChoice));
    outputPlotFileNameMAT = fullfile(FramesOutputPath,  sprintf('Traction_TxRed_max_interp_%s.mat', TimeStampChoice));
    
    savefig(figHandleBeadMaxNetDispl, outputPlotFileNameFig,'compact'); 
%     FrameImage = getframe(figHandleBeadMaxNetDispl);       
%     imwrite(FrameImage.cdata, outputPlotFileNameTIF);
    saveas(figHandleBeadMaxNetDispl, outputPlotFileNamePNG, 'png')
    save(outputPlotFileNameMAT, 'TimeStampsSec', 'TxRedBeadMaxNetPositionPixels', 'TxRedBeadMaxNetPositionPixels', ...
        'MaxTractionFrameNumber', 'TxRedBeadMaxNetTractionPa', 'MaxPosXYnet', 'MaxTractionIndex', 'FrameRate', '-v7.3')
    
    %%
    if AnalysisFolderAsWell
        outputPlotFileNameFigAnalysis = fullfile(AnalysisOutputPath, sprintf('07 Traction_TxRed_max_interp_%s.fig', TimeStampChoice));
    %     outputPlotFileNameTIFAnalysis = fullfile(AnalysisOutputPath, sprintf('07 Traction_TxRed_max_interp_%s.tif', TimeStampChoice));
        outputPlotFileNamePNGAnalysis = fullfile(AnalysisOutputPath, sprintf('07 Traction_TxRed_max_interp_%s.png', TimeStampChoice));
        outputPlotFileNameMATAnalysis = fullfile(AnalysisOutputPath, sprintf('07 Traction_TxRed_max_interp_%s.mat', TimeStampChoice));
  
        savefig(figHandleBeadMaxNetDispl, outputPlotFileNameFigAnalysis,'compact'); 
%         FrameImage = getframe(figHandleBeadMaxNetDispl);       
%         imwrite(FrameImage.cdata, outputPlotFileNameTIFAnalysis);
        saveas(figHandleBeadMaxNetDispl, outputPlotFileNamePNGAnalysis, 'png')
        save(outputPlotFileNameMATAnalysis, 'TimeStampsSec', 'TxRedBeadMaxNetPositionPixels', 'TxRedBeadMaxNetPositionPixels', ...
            'MaxTractionFrameNumber', 'TxRedBeadMaxNetTractionPa', 'MaxPosXYnet', 'MaxTractionIndex','FrameRate', '-v7.3')
    end
    
 
%++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 

%++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

%      function displHeatMap = interp_gridNoNaNsByIndex(grid_matX, grid_matY, dMapX,dMapY, XI, YI, CurrentFrame, MaskSizePerSide,Index)
%             displHeatMapX =  griddata(grid_matX, grid_matY, dMapX{CurrentFrame} ,XI(Index), YI(Index), 'cubic'); 
%             displHeatMapY = griddata(grid_matX, grid_matY, dMapY{CurrentFrame} ,XI(Index), YI(Index), 'cubic');   
% 
%             %__________________________ CORRECTING for NaNs out of griddata(cubic) using griddata(v4)
%             dispHeatMapNANindX = find(isnan(displHeatMapX(:)));
%             dispHeatMapNANindY = find(isnan(displHeatMapY(:)));
%             dispHeatMapNANind = unique(horzcat(dispHeatMapNANindX, dispHeatMapNANindY));          % combine poins together            
%             if ~isempty(dispHeatMapNANindX) || ~isempty(dispHeatMapNANindY)
%     %             Method 1. Using inpaint_nan3 to fill the NaN, which solves some PDEs to interpolate (or extrapolate the data).
%     %             warning('NaN values where found in X-component')  
%     %             displHeatMapX = inpaint_nans3(displHeatMapX);
%     %             displHeatMapY = inpaint_nans3(displHeatMapY);
%     % 
%     %             Method 2: Re-use griddata to interpolate using '-V4" only for the points that are missing
%     %             displHeatMapX =  griddata(grid_matX, grid_matY, dMapX{CurrentFrame} ,XI, YI, 'v4'); 
%     %             displHeatMapY = griddata(grid_matX, grid_matY, dMapY{CurrentFrame} ,XI, YI, 'v4'); 
%     % 
%     %             Method 3: Use the output from cubic grid data to interpolate using griddata(v4)            
%                  [dispHeatMapNANindX, dispHeatMapNANindY] = ind2sub(size(displHeatMapX), dispHeatMapNANind);
% 
%                  dispHeatMapNANindXRange = [dispHeatMapNANindX - MaskSizePerSide, dispHeatMapNANindX + MaskSizePerSide];
%                  dispHeatMapNANindYRange = [dispHeatMapNANindY - MaskSizePerSide, dispHeatMapNANindY + MaskSizePerSide];
% 
%                  % If negative range, choose the first grid point. displHeatMapX should have the same size.
%                  dispHeatMapNANindXRange(logical(dispHeatMapNANindXRange(:,1) < 1), 1) = 1;
%                  dispHeatMapNANindYRange(logical(dispHeatMapNANindYRange(:,1) < 1), 1) = 1;  
% 
%                  dispHeatMapNANindXRange(logical(dispHeatMapNANindXRange(:,2) > size(displHeatMapX,1)), 2) = size(displHeatMapX,1);
%                  dispHeatMapNANindYRange(logical(dispHeatMapNANindYRange(:,2) > size(displHeatMapX,2)), 2) = size(displHeatMapX,2);  
% 
% 
%                  for ii = 1:numel(dispHeatMapNANind)
%                     % NOTE: using the line below crashes for very large grid sizes as input;
%                     XI_ii = XI(dispHeatMapNANindXRange(ii,1):dispHeatMapNANindXRange(ii,2), dispHeatMapNANindYRange(ii,1):dispHeatMapNANindYRange(ii,2));
%                     YI_ii = YI(dispHeatMapNANindXRange(ii,1):dispHeatMapNANindXRange(ii,2), dispHeatMapNANindYRange(ii,1):dispHeatMapNANindYRange(ii,2));
%                     displHeatMapX_ii = displHeatMapX(dispHeatMapNANindXRange(ii,1):dispHeatMapNANindXRange(ii,2), dispHeatMapNANindYRange(ii,1):dispHeatMapNANindYRange(ii,2));
%                     displHeatMapY_ii = displHeatMapY(dispHeatMapNANindXRange(ii,1):dispHeatMapNANindXRange(ii,2), dispHeatMapNANindYRange(ii,1):dispHeatMapNANindYRange(ii,2));
% 
% 
%                     XI_ii_NoNaN = XI_ii(~logical(isnan(displHeatMapX_ii)));
%                     YI_ii_NoNaN = YI_ii(~logical(isnan(displHeatMapY_ii)));                 
%                     displHeatMapX_ii_NoNaN = displHeatMapX_ii(~logical(isnan(displHeatMapX_ii)));
%                     displHeatMapY_ii_NoNaN = displHeatMapY_ii(~logical(isnan(displHeatMapY_ii)));
% 
%                     displHeatMapX(dispHeatMapNANind(ii)) =  griddata(XI_ii_NoNaN, YI_ii_NoNaN, displHeatMapX_ii_NoNaN, XI(dispHeatMapNANind(ii)), YI(dispHeatMapNANind(ii)), 'v4'); 
%                     displHeatMapY(dispHeatMapNANind(ii)) =  griddata(XI_ii_NoNaN, YI_ii_NoNaN, displHeatMapY_ii_NoNaN, XI(dispHeatMapNANind(ii)), YI(dispHeatMapNANind(ii)), 'v4');  
%                  end            
%             end
%             %__________________________
%             displHeatMap = (displHeatMapX.^2 + displHeatMapY.^2).^0.5;              % Find the norm   
%         end
% end