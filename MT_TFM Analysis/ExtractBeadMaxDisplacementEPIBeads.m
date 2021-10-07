function [MaxDisplacementDetails, figHandleBeadMaxNetDispl] = ExtractBeadMaxDisplacementEPIBeads(MD, displField, AnalysisFolderAsWell, TimeStamps, ScaleMicronPerPixel)
%% 
%{   
    v.2020-06-28 by Waddah Moghram
        1. Updated so that it can be called externally.
    v.2020-06-14 by Waddah Moghram
        1. Accept time stamps. Fixed error if given displacement field as input, and output the figure as needed.
    v.2020-02-12 by Waddah Moghram.
        1. Gives the use the option to use either Real-timestamps or camera timestamps or timstamps based on Frame rate per second.
  % **********************TO DO: Re-do by using interpolated value instead of the coordniates of an individual value *********************
*** v.2020-02-05 by Waddah Moghram
        1. Fixed vecnorm so that it is for [X,Y] instead of [X,Y,vecnorm], which was given me 4.2 microns instead of 3 microns for max.
        2. Renamed from ExtractBeadCoordinatesEpiMax.m to ExtractBeadMaxDisplacementBeads.m
    v.2020-01-29 by Waddah Moghram
        1. updated so that t=0 for the first frame.
    v.2020-01-17 by Waddah Moghram
        1. Save max displacement in *.mat to be used by VideoAnalysisCombined.mat
    v.2020-01-16 by Waddah Moghram
        Fixed the time frame so that they are in seconds.
  
    Written by Waddah Moghram, PhD Student in Biomedical Engineering. Updated on 2019-05-27
    % update
  %}  
%%
    PlotsFontName = 'XITS';     
 
     % Check if this device has a GPU device. Take advantage of it. 
    nGPU = gpuDeviceCount;
    if nGPU > 0
        useGPU = true;
    else
        useGPU = false;
    end  
    
%% ----------------------------------------------------------------------------------------------------------------------
    if ~exist('MD', 'var'), MD = []; end
    try 
        isMD = (class(MD) ~= 'MovieData');
    catch 
        MD = [];
    end    
    if nargin < 1 || isempty(MD)
        [movieFileName, movieFilePath] = uigetfile('*.mat', 'Open the Movie Data File');
        if movieFileName == 0, return; end
        movieFileFullName = fullfile(movieFilePath, movieFileName);
        try 
            load(movieFileFullName, 'MD')
            fprintf('Movie Data is: \n %s', movieFileFullName);
        catch 
            error('Could not open the movie data file!')
        end
        try 
            isMD = (class(MD) ~= 'MovieData');
        catch 
            errordlg('Could not open the movie data file!')
            return
        end         
    end
    %     ImageFileNames = MD.getImageFileNames{1};    

    if nargin < 5
        try
            ScaleMicronPerPixel = MD.pixelSize_ / 1000;
        catch
            [ScaleMicronPerPixel, ~, ~] = MagnificationScalesMicronPerPixel([]);
        end
    end
    
    %% --------  nargin 2, displacement field (displField) -------------------------------------------------------------------   
    if ~exist('displField','var'), displField = []; end
    if nargin < 2 || isempty(displField)
        try 
            ProcessTag =  MD.findProcessTag('DisplacementFieldCorrectionProcess').tag_;
        catch
            try 
                ProcessTag =  MD.findProcessTag('DisplacementFieldCalculationProcess').tag_;
            catch
                ProcessTag = '';
                disp('No Completed Displacement Field Calculated!');
                disp('------------------------------------------------------------------------------')
            end
        end

        %------------------
        if exist('ProcessTag', 'var') 
            fprintf('Displacement Process Tag is: %s\n', ProcessTag);
            try
                InputFileFullName = MD.findProcessTag(ProcessTag).outFilePaths_{1};
                if exist(InputFileFullName, 'file')
                    dlgQuestion = sprintf('Do you want to open the displacement field referred to in the movie data file?\n\n%s\n', ...
                        InputFileFullName);
                    dlgTitle = 'Open displacement field (displField.mat) file?';
                    OpenDisplacementChoice = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No', 'Yes');
                    switch OpenDisplacementChoice
                        case 'Yes'
                            [displacementOutputPath, ~, ~] = fileparts(InputFileFullName);
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
    if exist('InputFileFullName', 'var') || ~exist('ProcessTag', 'var') && isempty(displField)      
        TFMPackageFiles = fullfile(movieFilePath,'TFMPackage','*.mat');
        [displacementFileName, displacementOutputPath] = uigetfile(TFMPackageFiles, 'Open the displacement field "displField.mat" under displacementField or backups');
        if displacementFileName == 0, return; end
        InputFileFullName = fullfile(displacementOutputPath, displacementFileName);
                %------------------
        try
            load(InputFileFullName, 'displField');   
            fprintf('Displacement Field (displField) File is successfully loaded!: \n\t %s\n', InputFileFullName);
            disp('------------------------------------------------------------------------------')
        catch
            errordlg('Could not open the displacement field file.');
            return
        end
    end 
    FramesDoneBoolean = arrayfun(@(x) ~isempty(x.vec), displField);
    FramesDoneNumbers = find(FramesDoneBoolean == 1);
    FramesDifference = diff(FramesDoneNumbers);
    VeryLastFrame = find(FramesDoneBoolean, 1, 'last');
    VeryFirstFrame =  find(FramesDoneBoolean, 1, 'first');    

    
    %% -----------------------------------------------------------------------------------------------------------------------
    if ~exist('AnalysisFolderAsWell','var'), AnalysisFolderAsWell = []; end    
    if nargin < 3 || isempty(AnalysisFolderAsWell)
        if exist('displacementOutputPath','var')
            dlgQuestion = ({'Do you want to save the output to this folder?', displacementOutputPath});
            dlgTitle = 'Output folder?';
            outputFolderChoice = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No', 'Yes');
            switch outputFolderChoice
                case 'Yes'
                    FramesOutputPath = displacementOutputPath;
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
    elseif AnalysisFolderAsWell ==0 || upper(AnalysisFolderAsWell) == 'N'
        AnalysisFolderAsWell = 0;
    end
    
    if AnalysisFolderAsWell == 1 || upper(AnalysisFolderAsWell) == 'Y'
        if ~exist('movieFileDir','var'), movieFilePath = pwd; end
        AnalysisOutputPath = uigetdir(movieFilePath,'Choose the directory where the tracked output will be saved.');          
    end
    if ~exist('AnalysisOutputPath', 'var'), AnalysisOutputPath = []; end
       
    %% -----------------------------------------------------------------------------------------------------------------------
    NumFrames = numel(displField);
    MaxDisplFrameNumber = 0;
    MaxDisplFieldIndex = 0;
       
    FramesDoneBoolean = arrayfun(@(x) ~isempty(x.vec), displField);
    FramesDoneNumbers = find(FramesDoneBoolean == 1);
    FramesDifference = diff(FramesDoneNumbers);
    VeryLastFrame = find(FramesDoneBoolean, 1, 'last');
    VeryFirstFrame =  find(FramesDoneBoolean, 1, 'first');    
    
%     prompt = {sprintf('Choose the first frame to plotted. [Default, Frame = %d]', VeryFirstFrame)};
%     dlgTitle = 'First Frame Plotted';
%     FirstFrameStr = inputdlg(prompt, dlgTitle, [1, 90], {num2str(VeryFirstFrame)});
%     if isempty(FirstFrameStr), return; end
%     FirstFrame = str2double(FirstFrameStr{1});          
%     [~, FirstFrameIndex] = min(abs(FramesDoneNumbers - FirstFrame));
%     FirstFrame = FramesDoneNumbers(FirstFrameIndex);


%     prompt = {sprintf('Choose the last frame to plotted. [Default, Frame = %d]', VeryLastFrame)};
%     dlgTitle = 'Last Frame Plotted';
%     LastFrameStr = inputdlg(prompt, dlgTitle, [1, 90], {num2str(VeryLastFrame)});
%     if isempty(LastFrameStr), return; end
%     LastFrame = str2double(LastFrameStr{1});          
%     [~, LastFrameIndex] = min(abs(FramesDoneNumbers - LastFrame));
%     LastFrame = FramesDoneNumbers(LastFrameIndex);

% FramesDoneNumbers = FramesDoneNumbers(FirstFrameIndex:LastFrameIndex);
    
    FirstFrame = VeryFirstFrame;
    LastFrame = VeryLastFrame;    
        
    if ~exist('TimeStamps', 'var'), TimeStamps = []; end
    if ischar(TimeStamps), if upper(TimeStamps) == 'N', TimeStamps = 0; end; end
    if isempty(TimeStamps) || nargin < 4
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
    elseif TimeStamps == 0
        try 
            FrameRate = 1/MD.timeInterval_;
        catch
            FrameRate = 1/ 0.025;           % (40 frames per seconds)              
        end 
        TimeStamps = FramesDoneNumbers ./ FrameRate;
        xLabelTime = 'Time [s]';
    else
        xLabelTime = 'Time [s]';            % time stamps is given to the function
    end
    
    LastFrameOverall = min([LastFrame, numel(TimeStamps)]);
    FramesDoneNumbers = FramesDoneNumbers(1:find(FramesDoneNumbers == LastFrameOverall));
    TimeStampsSec = TimeStamps(FramesDoneNumbers);
%     TimeStampsSec = TimeStampsSec - TimeStampsSec(1);               % MAKE SURE TIME IS REFERENCE TO T = 0 FOR THE FIRST FRAME
    
    %% Finding maximum bead
%     displFieldNetMaxPointInFrame = -1;
%     reverseString = '';
    FramesNum = numel(displField);
    dmaxTMP = nan(FramesNum, 1);
    dmaxTMPindex = nan(FramesNum, 1);

    if ~exist('FramesOutputPath', 'var')
        [FramesOutputPath, ~ , ~] = fileparts(MD.processes_{end}.outFilePaths_{1});
    end
    disp('Finding the bead with the maximum displacement...in progress')
    parfor_progress(numel(FramesDoneNumbers), FramesOutputPath);
    parfor CurrentFrame = FramesDoneNumbers
        dnorm_vec = vecnorm(displField(CurrentFrame).vec(:,1:2), 2,2);  
        displField(CurrentFrame).vec(:,3)  = dnorm_vec;
        dmaxTMP(CurrentFrame) = max(dnorm_vec);
        [~, IdxTMP] = max(dnorm_vec);
        dmaxTMPindex(CurrentFrame) = IdxTMP;
        parfor_progress(-1, FramesOutputPath);
    end
    parfor_progress(0, FramesOutputPath);
    disp('Finding the bead with the maximum displacement...complete')

    [~, MaxDisplFrameNumber]  = max(dmaxTMP);

    MaxDisplFieldIndex = dmaxTMPindex(MaxDisplFrameNumber);
    MaxDispl_PosXY_Pixels =  displField(MaxDisplFrameNumber).pos(MaxDisplFieldIndex,:);
    MaxDisplNetPixels = displField(MaxDisplFrameNumber).vec(MaxDisplFieldIndex,:);
    MaxDisplNetMicrons =  MaxDisplNetPixels .* ScaleMicronPerPixel;

    fprintf('Maximum displacement = %0.4g pixels at ', MaxDisplNetPixels(3));
    fprintf('[x,y] = [%g, %g] pixels in Frame #%d, Point Index #%d \n', MaxDispl_PosXY_Pixels, MaxDisplFrameNumber, MaxDisplFieldIndex)
    fprintf('Maximum displacement [disp_x, disp_y] =  [%0.4g, %0.4g] pixels==> Net displacement [disp_net] = [%0.4g] pixels. \n', MaxDisplNetPixels)
    fprintf('Maximum displacement [disp_x, disp_y] =  [%0.4g, %0.4g] microns==> Net displacement [disp_net] = [%0.4g] microns. \n', MaxDisplNetMicrons)

%%     
    TxRedBeadMaxNetPositionPixels = nan(numel(FramesDoneNumbers), 2);
    TxRedBeadMaxNetDisplacementPixels = nan(numel(FramesDoneNumbers), 3);
    disp('Extracting the displacement of the bead with the maximum displacement...in progress')
    parfor_progress(numel(FramesDoneNumbers), FramesOutputPath);
    parfor CurrentFrame = FramesDoneNumbers
        TxRedBeadMaxNetPositionPixels(CurrentFrame, :) = displField(CurrentFrame).pos(MaxDisplFieldIndex,:);
        TxRedBeadMaxNetDisplacementPixels(CurrentFrame, :) = displField(CurrentFrame).vec(MaxDisplFieldIndex,:);
        parfor_progress(-1, FramesOutputPath);
    end
    parfor_progress(0, FramesOutputPath);
    disp('Extracting the displacement of the bead with the maximum displacement...complete')    
    TxRedBeadMaxNetDisplacementMicrons = TxRedBeadMaxNetDisplacementPixels .* ScaleMicronPerPixel;            % convert from micron to nm
       
    %% ---------------- PLOTS
%     % From field vectors are not cumulative.
%     TxRedBeadMaxNetDisplacementPixels(:,3) = vecnorm(TxRedBeadMaxNetDisplacementPixels(:,1:2),2,2);
%     TxRedBeadMaxNetDisplacementMicrons(:,3) = vecnorm(TxRedBeadMaxNetDisplacementMicrons(:,1:2),2,2);
    
    figHandleBeadMaxNetDispl = figure('color','w', 'Renderer', 'painters');
    plot(TimeStampsSec, TxRedBeadMaxNetDisplacementMicrons(FramesDoneNumbers,3), 'r.-',  'LineWidth', 1', 'MarkerSize', 2)
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
    ylabel('\bf|\it\Delta\rm_{TxRed}(\itt\rm)\bf|\rm [\mum]', 'FontName', PlotsFontName); 
    
    try
        CorrectionType =  MD.findProcessTag('DisplacementFieldCorrectionProcess').notes_;
    catch
        CorrectionType = '';
    end
    DisplType = sprintf('Maximum Net EPI Bead Displacement (tracked). %s', CorrectionType);
    title({DisplType,sprintf('Max at (X,Y) = (%0.2f,%0.2f) pix in Frame %d/%d = %0.3f sec', ...
        MaxDispl_PosXY_Pixels, MaxDisplFrameNumber, LastFrame, TimeStamps(MaxDisplFrameNumber)), ...
        sprintf('Max displacement = %0.3f pix = %0.3f %sm', MaxDisplNetPixels(3), MaxDisplNetMicrons(3),char(181))}, 'interpreter', 'none')

    MaxDisplacementDetails.TimeFrameSeconds = TimeStampsSec;
    MaxDisplacementDetails.TxRedBeadMaxNetPositionPixels = TxRedBeadMaxNetPositionPixels;
    MaxDisplacementDetails.TxRedBeadMaxNetDisplacementPixels = TxRedBeadMaxNetDisplacementPixels;
    MaxDisplacementDetails.TxRedBeadMaxNetDisplacementMicrons = TxRedBeadMaxNetDisplacementMicrons;
    MaxDisplacementDetails.MaxDisplFrameNumber = MaxDisplFrameNumber;
    MaxDisplacementDetails.MaxDisplMicronsXYnet = MaxDisplNetMicrons;
    MaxDisplacementDetails.MaxDisplPixelsXYnet = MaxDisplNetPixels;
    MaxDisplacementDetails.MaxDisplPixelsXYnet = MaxDisplNetPixels;
    MaxDisplacementDetails.MaxDisplFieldIndex = MaxDisplFieldIndex;
    
        %%
%     disp('**___to continue saving, type "dbcont" or press "F5", or click "Continue" under "Editor" Menu"___**')
%     keyboard
    
    %%
    if exist('FramesOutputPath', 'var')
        outputPlotFileNameFig = fullfile(FramesOutputPath, sprintf('Net Displacement_TxRed_max_beads_%s.fig', TimeStampChoice));
    %     outputPlotFileNameTIF = fullfile(FramesOutputPath,  sprintf('Net Displacement_TxRed_max_beads_%s.tif', TimeStampChoice));
        outputPlotFileNamePNG = fullfile(FramesOutputPath,  sprintf('Net Displacement_TxRed_max_beads_%s.png', TimeStampChoice));
        outputPlotFileNameMAT = fullfile(FramesOutputPath,  sprintf('Net Displacement_TxRed_max_beads_%s.mat', TimeStampChoice));

        savefig(figHandleBeadMaxNetDispl, outputPlotFileNameFig,'compact'); 
    %     FrameImage = getframe(figHandleBeadMaxNetDispl);       
    %     imwrite(FrameImage.cdata, outputPlotFileNameTIF);
        saveas(figHandleBeadMaxNetDispl, outputPlotFileNamePNG, 'png')
        save(outputPlotFileNameMAT, 'TimeStampsSec', 'TxRedBeadMaxNetPositionPixels', 'TxRedBeadMaxNetDisplacementPixels', ...
            'TxRedBeadMaxNetDisplacementMicrons', 'MaxDisplFrameNumber', 'FrameRate',  '-v7.3')
    end

    %%
    if AnalysisFolderAsWell
        outputPlotFileNameFigAnalysis = fullfile(AnalysisOutputPath, sprintf('07 Net Displacement_TxRed_max_beads_%s.fig', TimeStampChoice));
    %     outputPlotFileNameTIFAnalysis = fullfile(AnalysisOutputPath, sprintf('07 Net Displacement_TxRed_max_beads_%s.tif', TimeStampChoice));
        outputPlotFileNamePNGAnalysis = fullfile(AnalysisOutputPath, sprintf('07 Net Displacement_TxRed_max_beads_%s.png', TimeStampChoice));
        outputPlotFileNameMATAnalysis = fullfile(AnalysisOutputPath, sprintf('07 Net Displacement_TxRed_max_beads_%s.mat', TimeStampChoice));
  
        savefig(figHandleBeadMaxNetDispl, outputPlotFileNameFigAnalysis,'compact'); 
%         FrameImage = getframe(figHandleBeadMaxNetDispl);       
%         imwrite(FrameImage.cdata, outputPlotFileNameTIFAnalysis);
        saveas(figHandleBeadMaxNetDispl, outputPlotFileNamePNGAnalysis, 'png')
        save(outputPlotFileNameMATAnalysis, 'TimeStampsSec', 'TxRedBeadMaxNetPositionPixels', 'TxRedBeadMaxNetDisplacementPixels', ...
        'TxRedBeadMaxNetDisplacementMicrons', 'MaxDisplFrameNumber', 'FrameRate', '-v7.3')
    end