function [MaxEnergyDetails, outputPlotFileNameFig] = ExtractBeadMaxEnergyBead(MD, energyDensityField, AnalysisFolderAsWell)
%% 
%{   
    v.2020-06-22 by Wadah Moghram. Based on ExtractBeadTractionBead.m
  %}  
%%
    PlotsFontName = 'XITS'; 
    EdgeErode = 1;
    gridMagnification = 1;
    bandSize = 0;
    ConversionJm2qtoFJmu2 = 10^3;
    
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
    if nargin < 1 || isempty(MD)
        [movieFileName, movieFilePath] = uigetfile('*.mat', 'Open the TFM-Package Movie Data File');
        if movieFileName == 0, return; end
        MovieFileFullName = fullfile(movieFilePath, movieFileName);
        try 
            load(MovieFileFullName, 'MD')
            fprintf('Movie Data (MD) file is: \n\t %s\n', MovieFileFullName);
            disp('------------------------------------------------------------------------------')
        catch 
            errordlg('Could not open the movie data file!')
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
    
    %% --------  nargin 2, Energy Density field (energyDensityField) -------------------------------------------------------------------
    ForceOutputPath = '';    
         InputFileFullName = [];
    if ~exist('energyDensityField','var'), energyDensityField = []; end
    
    %------------------
    if isempty(InputFileFullName)        
        TFMPackageFiles = fullfile(movieFilePath,'TFMPackage','*.mat');
        [forceFileName, ForceOutputPath] = uigetfile(TFMPackageFiles, 'Open the force field "energyDensityField.mat" under energyDensityField or backups');
        if forceFileName == 0, return, end
        InputFileFullName = fullfile(ForceOutputPath, forceFileName);
    end                 
    
    %------------------
    try
        load(InputFileFullName, 'energyDensityField')
        fprintf('Energy Density Field (energyDensityField) File is loaded successfully! \n\t %s\n', InputFileFullName);
        disp('------------------------------------------------------------------------------')
    catch
        errordlg('Could not open the energy density field file.');
        return
    end
    FramesDoneBoolean = arrayfun(@(x) ~isempty(x.vec), energyDensityField);
    FramesDoneNumbers = find(FramesDoneBoolean == 1);
    FramesDifference = diff(FramesDoneNumbers);
    VeryLastFrame = find(FramesDoneBoolean, 1, 'last');
    VeryFirstFrame =  find(FramesDoneBoolean, 1, 'first');
    
    for ii = VeryFirstFrame:VeryLastFrame
        energyDensityFieldtmp = energyDensityField(ii).vec;
        energyDensityField(ii).vec = energyDensityFieldtmp .* ConversionJm2qtoFJmu2;
    end
    
    %% -----------------------------------------------------------------------------------------------------------------------
    if ~exist('AnalysisFolderAsWell','var'), AnalysisFolderAsWell = []; end    
    if nargin < 3 || isempty(AnalysisFolderAsWell) || AnalysisFolderAsWell ==0 || upper(AnalysisFolderAsWell) == 'N'
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
    NumFrames = numel(energyDensityField);
    MaxEnergyFrameNumber = 0;
    MaxEnergyIndex = 0;
    
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

%% Finding maximum bead
    MaxEnergyPaNet = -1;
   
    reverseString = '';
%     maxInput = -1;
%     maxFrame = -1;
%     minInput = Inf;
%     bandSize = 0;
% %     

    disp('Evaluating the maximum and minimum Energy Density value in progress....')


    for CurrentFrame = FramesDoneNumbers
        ProgressMsg = sprintf('Searching Frame #%d/(%d-%d)...\n',CurrentFrame, FramesDoneNumbers(1),FramesDoneNumbers(end));
        fprintf([reverseString, ProgressMsg]);
        reverseString = repmat(sprintf('\b'), 1, length(ProgressMsg));
        
        EnergyNorm = energyDensityField(CurrentFrame).vec;
        [tmpMaxEnergyFieldNetInFrame, tmpMaxEnergyFieldInFrameIndex] =  max(EnergyNorm(:));          % maximum item in a column

        if tmpMaxEnergyFieldNetInFrame > MaxEnergyPaNet
            MaxEnergyPaNet = tmpMaxEnergyFieldNetInFrame;            
            MaxEnergyIndex = tmpMaxEnergyFieldInFrameIndex;
            MaxEnergyFrameNumber = CurrentFrame;
            MaxEnergyPaXYnet = energyDensityField(CurrentFrame).pos(MaxEnergyIndex);
            MaxPosXYnet = [energyDensityField(CurrentFrame).pos(MaxEnergyIndex,1), energyDensityField(CurrentFrame).pos(MaxEnergyIndex,2)];
        end 
    end
    fprintf('Maximum Energy Density = %g fJ/microns^2 at ', MaxEnergyPaNet);
    fprintf('[x,y] = [%g, %g] pixels in Frame #%d, Point Index #%d \n', MaxPosXYnet, MaxEnergyFrameNumber, MaxEnergyIndex)
    fprintf('Maximum Energy [sigma] = %g fJ/micron^2. \n', MaxEnergyPaXYnet)

%%  Track the max over all Frames.
    reverseString = '';        
    
    for CurrentFrame = FramesDoneNumbers
%         ProgressMsg = sprintf('Tracking Maximum Node at Frame #%d/(%d-%d)...\n',CurrentFrame, FramesDoneNumbers(1),FramesDoneNumbers(end));
%         fprintf([reverseString, ProgressMsg]);
%         reverseString = repmat(sprintf('\b'), 1, length(ProgressMsg));
        
        TxRedBeadMaxNetPositionPixels(CurrentFrame, :) =  energyDensityField(CurrentFrame).pos(MaxEnergyIndex,:);
        TxRedBeadMaxNetEnergyPa(CurrentFrame, :) =  energyDensityField(CurrentFrame).vec(MaxEnergyIndex,:);
    end
  
    %% ---------------- PLOTS
    figHandleBeadMaxNetDispl = figure('color','w', 'Renderer', 'painters');
    plot(TimeStampsSec, TxRedBeadMaxNetEnergyPa(FramesDoneNumbers), 'r.-',  'LineWidth', 1', 'MarkerSize', 2)
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
    ylabel('\bf|\it\sigma\rm_{TxRed}(\itt\rm)\bf|\rm [fJ/\mum^{2}]', 'FontName', PlotsFontName); 
    
    title({'Maximum EPI Bead Energy (Tracked)',sprintf('Max at (X,Y) = (%d,%d) pix in Frame %d/%d = %0.3f sec',...
        MaxPosXYnet, MaxEnergyFrameNumber,LastFrame, TimeStamps(MaxEnergyFrameNumber)), ...
        sprintf('Max Energy Density = %g fJ/\\mum^{2}', MaxEnergyPaNet)})

    MaxEnergyDetails.TimeFrameSeconds = TimeStampsSec;
    MaxEnergyDetails.TxRedBeadMaxNetPositionPixels = TxRedBeadMaxNetPositionPixels;
    MaxEnergyDetails.TxRedBeadMaxNetEnergyPa = TxRedBeadMaxNetEnergyPa;
    MaxEnergyDetails.MaxEnergyFrameNumber = MaxEnergyFrameNumber;
    MaxEnergyDetails.MaxEnergyPaNet = MaxEnergyPaNet;
    MaxEnergyDetails.MaxPosXYnet = MaxPosXYnet;
    MaxEnergyDetails.MaxEnergyIndex = MaxEnergyIndex;
    
    
        %%
    disp('**___to continue saving, type "dbcont" or press "F5", or click "Continue" under "Editor" Menu"___**')
    keyboard
    
    %%
    outputPlotFileNameFig = fullfile(FramesOutputPath, sprintf('Energy_TxRed_max_beads_%s.fig', TimeStampChoice));
%     outputPlotFileNameTIF = fullfile(FramesOutputPath,  sprintf('Energy_TxRed_max_beads_%s.tif', TimeStampChoice));
    outputPlotFileNamePNG = fullfile(FramesOutputPath,  sprintf('Energy_TxRed_max_beads_%s.png', TimeStampChoice));
    outputPlotFileNameMAT = fullfile(FramesOutputPath,  sprintf('Energy_TxRed_max_beads_%s.mat', TimeStampChoice));
    
    savefig(figHandleBeadMaxNetDispl, outputPlotFileNameFig,'compact'); 
%     FrameImage = getframe(figHandleBeadMaxNetDispl);       
%     imwrite(FrameImage.cdata, outputPlotFileNameTIF);
    saveas(figHandleBeadMaxNetDispl, outputPlotFileNamePNG, 'png')
    save(outputPlotFileNameMAT, 'TimeStampsSec', 'TxRedBeadMaxNetPositionPixels', 'TxRedBeadMaxNetPositionPixels', ...
        'MaxEnergyFrameNumber', 'TxRedBeadMaxNetEnergyPa', 'MaxPosXYnet', 'MaxEnergyIndex', '-v7.3')
    
    %%
    if AnalysisFolderAsWell
        outputPlotFileNameFigAnalysis = fullfile(AnalysisOutputPath, sprintf('07 Energy_TxRed_max_beads_%s.fig', TimeStampChoice));
    %     outputPlotFileNameTIFAnalysis = fullfile(AnalysisOutputPath, sprintf('07 Energy_TxRed_max_beads_%s.tif', TimeStampChoice));
        outputPlotFileNamePNGAnalysis = fullfile(AnalysisOutputPath, sprintf('07 Energy_TxRed_max_beads_%s.png', TimeStampChoice));
        outputPlotFileNameMATAnalysis = fullfile(AnalysisOutputPath, sprintf('07 Energy_TxRed_max_beads_%s.mat', TimeStampChoice));
  
        savefig(figHandleBeadMaxNetDispl, outputPlotFileNameFigAnalysis,'compact'); 
%         FrameImage = getframe(figHandleBeadMaxNetDispl);       
%         imwrite(FrameImage.cdata, outputPlotFileNameTIFAnalysis);
        saveas(figHandleBeadMaxNetDispl, outputPlotFileNamePNGAnalysis, 'png')
        save(outputPlotFileNameMATAnalysis, 'TimeStampsSec', 'TxRedBeadMaxNetPositionPixels', 'TxRedBeadMaxNetPositionPixels', ...
            'MaxEnergyFrameNumber', 'TxRedBeadMaxNetEnergyPa', 'MaxPosXYnet', 'MaxEnergyIndex', 'MaxEnergyDetails', '-v7.3')
    end
%++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++