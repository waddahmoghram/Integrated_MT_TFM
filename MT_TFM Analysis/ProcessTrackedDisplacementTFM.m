%{
    v.2020-07-27 by Waddah Moghram,
        1. Minor adjustments to deal with controlled displacement mode
Part 1: Displacement Processing. This is the output 
    v.2020-07-11.12 by Waddah Moghram, PhD Candidate in Biomedical Engineering at the University of Iowa
        1. Update so that it can output the displacement at any points
    v.2020-06-30 by Waddah Moghram
       based on VideoAnalysisEPI.m v.2020-06-26..29
        1. This version will be a simple-to-use file that can manipulate the displacement *.mat files directly, 
    and embed the related timestamps (RT timestamps) for future purposes.
%}

function [movieData, displField, TimeStamps, DisplPathName, ScaleMicronPerPixel, FramesDoneNumbers, controlMode, ...
    rect, DriftROIs, DriftROIsCombined, reg_grid, gridSpacing, NoiseROIs, NoiseROIsCombined, TimeFilterChoiceStr, ...
    DriftCorrectionChoiceStr, DisplacementFileFullName] = ...
    ProcessTrackedDisplacementTFM(movieData, displField, TimeStamps, DisplacementFileFullName, gridMagnification, EdgeErode, GridtypeChoiceStr, ...
    InterpolationMethod, ShowOutput, FirstFrame, LastFrame, SaveOutput, controlMode, ScaleMicronPerPixel, CornerPercentage)

%% Keyvariables:
    %%
    disp('_____________________________________________________________________________________________')
% 1. Experiment mode: Controlled Force vs. Controlled Displacement?
%     dlgQuestion = 'What is the control mode for EPI experiment? ';
%     dlgTitle = 'Control Mode?';
%     controlMode = questdlg(dlgQuestion, dlgTitle, 'Controlled Force', 'Controlled Displacement', 'Controlled Force');
    if isempty(controlMode), controlMode = 'Controlled Force'; end   
    
    if ~exist('gridMagnification', 'var'), gridMagnification = [];end
    if isempty(gridMagnification) || nargin < 5; gridMagnification = 1; end
    
    if ~exist('EdgeErode', 'var'), EdgeErode = [];end
    if isempty(EdgeErode) || nargin < 6; EdgeErode = 1; end
    
    if ~exist('GridtypeChoiceStr', 'var'), GridtypeChoiceStr = [];end
    if isempty(GridtypeChoiceStr) || nargin < 7; GridtypeChoiceStr = 'Even Grid'; end
    
    if ~exist('InterpolationMethod', 'var'), InterpolationMethod = [];end
    if isempty(InterpolationMethod) || nargin < 8; InterpolationMethod = 'griddata'; end
    
    if ~exist('ShowOutput', 'var'), ShowOutput = [];end
    if isempty(ShowOutput) || nargin < 10; ShowOutput = true; end

    if ~exist('SaveOutput', 'var'), SaveOutput = [];end
    if isempty(SaveOutput) || nargin < 12
        dlgQuestion = 'Do you want to save the output?';
        dlgTitle = 'Save output?';
        SaveOutputChoice = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No', 'Yes');
        switch SaveOutputChoice
            case 'Yes'
                SaveOutput = true;
            case 'No'
                SaveOutput = false;
        end
    end

    %% --------  nargin 1, Movie Data (MD) by TFM Package -------------------------------------------------------------------  
    if ~exist('movieData', 'var'), movieData = []; end
    try 
        isMD = (class(movieData) ~= 'MovieData');
    catch 
        movieData = [];
    end   
    if isempty(movieData) || nargin < 1
        [movieFileName, movieFilePath] = uigetfile('*.mat', 'Open the TFM-Package Movie Data File');
        if movieFileName == 0, return; end
        MovieFileFullName = fullfile(movieFilePath, movieFileName);
        try 
            load(MovieFileFullName, 'movieData')
            fprintf('Movie Data (MD) file is: \n\t %s\n', MovieFileFullName);
            disp('------------------------------------------------------------------------------')
        catch 
            errordlg('Could not open the movie data file!')
        end
        try 
            isMD = (class(movieData) ~= 'MovieData');
        catch 
            errordlg('Could not open the movie data file!')
        end
        movieData = movieData;   
    else
        movieFilePath = movieData.getPath;
    end

%% 5. choose the scale (microns/pixels) & image Bits    
    if ~exist('ScaleMicronPerPixel', 'var'), ScaleMicronPerPixel = []; end
    if isempty(ScaleMicronPerPixel)
        try
            try
                ScaleMicronPerPixel = movieData.pixelSize_/1000;           % from Nanometers/pixel to micron/pixel
            catch
                % continue
            end            
            if ~exist('ScaleMicronPerPixel', 'var')
                dlgQuestion = sprintf('Do you want the scaling found in the movie file (%0.5g micron/pixels)?', ScaleMicronPerPixel);
                dlgTitle = 'Use Embedded Scale?';
                ScalingChoice = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No', 'Yes');
            else
                ScalingChoice = 'No';
            end            
            switch ScalingChoice
                case 'No'
                    [ScaleMicronPerPixel, ~, MagnificationTimes] = MagnificationScalesMicronPerPixel();    
                case 'Yes'
                    % Continue
                otherwise 
                    return
            end
            catch
        end
    end
    fprintf('Magnification scale is %.5f microns/pixel\n', ScaleMicronPerPixel)
    
    % 1. choose camBitDepth 
    try
        ImageBits = movieData.camBitdepth_ - 2;   % Typically if 16 bits are used. Then image will be saved in 14 bits.
    catch
        ImageBits = 14;
    end    
    
%% 2 ==================== ask for & load tracked displacement file (displField.mat) ====================             
    if ~exist('displField','var'), displField = []; end
    if isempty(displField) || nargin < 2
        try 
            ProcessTag =  movieData.findProcessTag('DisplacementFieldCorrectionProcess').tag_;
        catch
            try 
                ProcessTag =  movieData.findProcessTag('DisplacementFieldCalculationProcess').tag_;
            catch
                ProcessTag = '';
                disp('No Completed Displacement Field Calculated!');
                disp('------------------------------------------------------------------------------')
            end
        end
        if exist('ProcessTag', 'var') 
            fprintf('Displacement Process Tag is: %s\n', ProcessTag);
            try
                DisplacementFileFullName = movieData.findProcessTag(ProcessTag).outFilePaths_{1};
                if exist(DisplacementFileFullName, 'file')
                    dlgQuestion = sprintf('Do you want to open the displacement field referred to in the movie data file?\n\n%s\n', ...
                        DisplacementFileFullName);
                    dlgTitle = 'Open displacement field (displField.mat) file?';
                    OpenDisplacementChoice = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No', 'Yes');
                    switch OpenDisplacementChoice
                        case 'Yes'
                            [DisplPathName, ~, ~] = fileparts(DisplacementFileFullName);
                        case 'No'
                            DisplacementFileFullName = [];
                        otherwise
                            return
                    end                    
                else
                    DisplacementFileFullName = [];
                end
            catch
                DisplacementFileFullName = [];
            end
        end
         %------------------
        if isempty(DisplacementFileFullName) || ~exist('ProcessTag', 'var')             
            TFMPackageFiles = fullfile(movieFilePath,'TFMPackage','*.mat');
            [DisplFileExtName, DisplPathName] = uigetfile(TFMPackageFiles, 'Open the displacement field "displField.mat" under displacementField or backups');
            if DisplFileExtName == 0, return; end
            DisplacementFileFullName = fullfile(DisplPathName, DisplFileExtName);
        end                 
        %------------------
        try
            load(DisplacementFileFullName, 'displField');   
            fprintf('Displacement Field (displField) File is successfully loaded!: \n\t %s\n', DisplacementFileFullName);
            disp('------------------------------------------------------------------------------')
            [~, DisplFileName, DisplFileExt] = fileparts(DisplacementFileFullName);
        catch
            errordlg('Could not open the displacement field file.');
            return
        end
    end
    
%% 5 ==================== find first & last frame numbers to be plotted ==================== 
    FramesDoneBoolean = arrayfun(@(x) ~isempty(x.vec), displField);
    FramesDoneNumbers = find(FramesDoneBoolean == 1);       
    VeryFirstFrame = find(FramesDoneBoolean, 1, 'first');   
    VeryLastFrame =  find(FramesDoneBoolean, 1, 'last');


    %%
     try 
        ProcessTag =  movieData.findProcessTag('DisplacementFieldCorrectionProcess').tag_;
    catch
        try 
            ProcessTag =  movieData.findProcessTag('DisplacementFieldCalculationProcess').tag_;
        catch
            ProcessTag = '';
            disp('No Completed Displacement Field Calculated!');
            disp('------------------------------------------------------------------------------')
        end
    end
    if exist('ProcessTag', 'var') 
        fprintf('Displacement Process Tag is: %s\n', ProcessTag);
        try
            DisplacementFileFullName = movieData.findProcessTag(ProcessTag).outFilePaths_{1};
            if exist(DisplacementFileFullName, 'file')
                [DisplPathName, ~, ~] = fileparts(DisplacementFileFullName);
           else
                DisplacementFileFullName = [];
            end
        catch
            DisplacementFileFullName = [];
        end
    end

%% Ask if you want to insert Timestamps
    if ~exist('TimeStamps', 'var'), TimeStamps = []; end
    if isempty(TimeStamps) || nargin < 3
        switch controlMode
            case 'Controlled Force'
                dlgQuestion = ({'Which timestamps do you want to use)?'});
                dlgTitle = 'Real-Time vs. Camera-Time vs. from FPS rate?';
                if isempty(TimeStampChoice)
                    TimeStampChoice = questdlg(dlgQuestion, dlgTitle, 'Real-Time', 'Camera-Time', 'From FPS rate', 'Real-Time');
                    if isempty(TimeStampChoice), error('No Choice was made'); end
                end
            case 'Controlled Displacement'
                dlgQuestion = ({'Which timestamps do you want to use)?'});
                dlgTitle = 'Real-Time vs. Camera-Time vs. from FPS rate?';
                if isempty(TimeStampChoice)
                    TimeStampChoice = questdlg(dlgQuestion, dlgTitle, 'Real-Time', 'Camera-Time', 'From FPS rate', 'Camera-Time');
                    if isempty(TimeStampChoice), error('No Choice was made'); end
                end
        end 
        if ~exist('movieFilePath', 'var')
            try
                movieFilePath = movieData.outputDirectory_;
            catch
                try
                    movieFilePath = DisplacementFileFullName;
                catch
                    movieFilePath = pwd;
                end
            end
        end
        switch TimeStampChoice
            case 'Real-Time'
                try 
                    [TimeStampFileNameEPI, TimeStampPathEPI] = uigetfile(movieFilePath, 'EPI TimeStamps RT Sec');
                    if isempty(TimeStampFileNameEPI), error('No File Was chosen'); end
                    TimeStampFullFileNameEPI = fullfile(TimeStampPathEPI, TimeStampFileNameEPI);
                    TimeStampsRT_SecData = load(TimeStampFullFileNameEPI);
                    TimeStamps = TimeStampsRT_SecData.TimeStampsAbsoluteRT_Sec;
                    try
                        FrameRate = 1/mean(diff(TimeStampsRT_SecData.TimeStampsRelativeRT_Sec));
                    catch
                        FrameRate = 1/mean(diff(TimeStamps));
                    end
                catch
                    if strcmpi(controlMode, 'Controlled Force')
                        [TimeStamps, ~, ~, ~, AverageFrameRate] = TimestampRTfromSensorData();
                        FrameRate = 1/AverageFrameRate;
                    end
                end

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
                        [TimeStamps, ~, AverageTimeInterval] = ND2TimeFrameExtract(movieData.channels_(ChannelNum).channelPath_);
                    catch
                        [TimeStamps, ~, AverageTimeInterval] = ND2TimeFrameExtract();            
                    end
                    FrameRate = 1/AverageTimeInterval;
                end

            case 'From FPS rate'
                try 
                    FrameRateDefault = 1/movieData.timeInterval_;
                catch
                    FrameRateDefault = 1/ 0.025;           % (40 frames per seconds)              
                end

                prompt = {sprintf('Choose the Frame Rate per second for this movie. [Default, %.4g]', FrameRateDefault)};
                dlgTitle =  'Frames Per Second';
                FrameRateStr = inputdlg(prompt, dlgTitle, [1, 90], {num2str(FrameRateDefault)});
                if isempty(FrameRateStr), error('No Frame Rate was chosen'); end
                FrameRate = str2double(FrameRateStr{1});      

                TimeStamps = FramesDoneNumbers ./ FrameRate;                
        end
        if ~exist('TimeStamps', 'var')
            TimeStamps = (VeryFirstFrame:VeryLastFrame)' ./ FrameRate;
            TimeStamps = TimeStamps - TimeStamps(1);                                    % MAKE THE FIRST FRAME IDENTICALLY ZERO 2020-01-28
        end
        %% Saving this in the Analysis Path along with the timesetamps and movieData       
       

        [DisplPathName, DisplFileName, DisplFileExt] = fileparts(DisplacementFileFullName);
        displacementFileNameRaw = sprintf('%s%s', DisplFileName, DisplFileExt); 
        DisplacementFileFullName = fullfile(DisplPathName, displacementFileNameRaw);
        if SaveOutput
            save(DisplacementFileFullName, 'displField', 'TimeStamps', 'movieData', '-v7.3');
            try save(DisplacementFileFullName, 'TimeStampChoice', 'FrameRate', '-append'); catch; end
        end
    end
    
    TimeStampChoice = 'Real-Time' ;
    switch TimeStampChoice
        case 'Real-Time' 
            xLabelTime = 'Real Time [s]';
        case 'Camera-Time'
            xLabelTime = 'Camera Time [s]';
        case 'From FPS rate'
            xLabelTime = 'Time based on frame rate [s]';
        otherwise
            xLabelTime = 'Time [s]';
    end

%% Temporal time filtering
%     dlgPrompt = sprintf('Do you want to filter displacements in the file listed below with low-pass equiripples filter (LPEF)?\n\t %s', DisplacementFileFullName); 
%     TimeFilterChoiceStr = questdlg(dlgPrompt, 'Low-Pass Equiripples Filter?','Yes', 'No', 'Yes');
%     if isempty(TimeFilterChoiceStr), error('No choice was given'); end
    TimeFilterChoiceStr = 'Yes';
    switch TimeFilterChoiceStr
        case 'No'
            TimeFilterChoiceStr = 'No temporal Filter';
        case 'Yes'
            [displField, ~, ~,~, LPEF_FilterParametersStruct] = FilterDisplacementLowPassEquiripples(displField);
            TimeFilterChoiceStr = 'Low-Pass Equiripples Filtered';
            disp('------------------------------------------------------------------------------')
%             displacementFileNameLPEF = sprintf('%s_LPEF%s', DisplFileName, DisplFileExt); 
%             DisplacementFileFullName = fullfile(displacementFilePath, displacementFileNameLPEF);
            [DisplPathName, DisplFileName, DisplFileExt] = fileparts(DisplacementFileFullName);
            DisplacementFileFullName = fullfile(DisplPathName, strcat(DisplFileName,  '_LPEF', DisplFileExt));
            
            if SaveOutput
                save(DisplacementFileFullName, 'displField', 'TimeStamps', 'movieData', 'LPEF_FilterParametersStruct', 'TimeFilterChoiceStr', '-v7.3');
                try save(DisplacementFileFullName, 'TimeStampChoice', 'FrameRate', '-append'); catch; end
                fprintf('Filtered Displacement Field (displField) File is successfully saved as!: \n\t %s\n', DisplacementFileFullName);
            end
%             try
%                 dirFile = dir(displacementFilePath);
%                 % removing initial output in a separate folder, and dump all in analysis
%                 for k = 3:length(dir(displacementFilePath))
%                     delete(fullfile(displacementFilePath, dirFile(k).name))
%                 end
%                 rmdir(displacementFilePath)
%             catch
%                 % do nothing
%             end
        otherwise
            error('X was selected');      
    end
    % check again to see if there any omitted framess. 20 frames if using the parameters for controlled displacement
    FramesDoneBoolean = arrayfun(@(x) ~isempty(x.vec), displField);
    FramesDoneNumbers = find(FramesDoneBoolean == 1); 
    FirstFrame = FramesDoneNumbers(1);
    LastFrame = FramesDoneNumbers(end);
    fprintf('First Frame now is %d\n', FirstFrame);
    fprintf('Last Frame now is %d\n', LastFrame);
    displField = displField(FramesDoneNumbers);
    
%     end

%% 2 =================== Load position and displacement vectors for maximum frame (FrameNum) for drift-correction plot ==================== 
    maxDisplacement = 0;
    maxIntensity = 0;
    MaxGrayLevel = 2^(ImageBits + 2);
    minIntensity = MaxGrayLevel;

%     reverseString = '';
%     for CurrentFrame = FramesDoneNumbers
%         ProgressMsg = sprintf('\nInspecting Frame %d/%d for maxima and minima.\n', CurrentFrame, FramesDoneNumbers(end));
%         fprintf([reverseString, ProgressMsg]);
%         reverseString = repmat(sprintf('\b'), 1, length(ProgressMsg));
%     
%         NetDisplacementCurrentFrame = vecnorm(displField(CurrentFrame).vec(:,1:2),2,2);
%         [tmpMaxDisplacement,tmpMaxDisplacementIndex] =  max(NetDisplacementCurrentFrame);          % maximum item in a column
% 
%         if tmpMaxDisplacement > maxDisplacement
%             maxDisplacement = tmpMaxDisplacement;
%             maxDisplacementIndex = tmpMaxDisplacementIndex;
%             MaxDisplFrameNumber = CurrentFrame;
%         end 
% %         
%         try
%            CurrentImage =  MD.channels_.loadImage(CurrentFrame);        
%         catch
%            % continue
%         end
%         [tmpMaxItensity,tmpIntensityIndex] = max(CurrentImage(:)) ;          % maximum item in a column
%         if tmpMaxItensity > maxIntensity
%             maxIntensity = tmpMaxItensity;
%             maxIntensityIndex = tmpIntensityIndex;
%             maxIntensityFrame = CurrentFrame;
%         end 
% 
%         [tmpMinIntensity, tmpMinIntensity] = min(CurrentImage(:)) ;          % maximum item in a column
%         if tmpMinIntensity < minIntensity
%             minIntensity = tmpMinIntensity;
%             minIntensityIndex = tmpMinIntensity;
%             minIntensityFrame = CurrentFrame;
%         end 
%     end                     
    
    FramesNum = numel(displField);
    dmaxTMP = nan(FramesNum, 1);
    dmaxTMPindex = nan(FramesNum, 1);
    dminTMP = nan(FramesNum, 1);
    dminTMPindex = nan(FramesNum, 1);

    disp('Finding the bead with the maximum displacement...in progress')
    parfor_progress(numel(FramesDoneNumbers));
    parfor CurrentFrame = FramesDoneNumbers
        dnorm_vec = vecnorm(displField(CurrentFrame).vec(:,1:2), 2,2);  
        displField(CurrentFrame).vec(:,3)  = dnorm_vec;
        dmaxTMP(CurrentFrame) = max(dnorm_vec);
        [~, dminIdxTMP] = max(dnorm_vec);
%         dmaxTMPindex(CurrentFrame) = dminIdxTMP;

%         dminTMP(CurrentFrame) = min(dnorm_vec);
%         [~, dminTMPindex] = min(dnorm_vec);
%         dmaxTMPindex(CurrentFrame) = dminTMPindex;

        parfor_progress;
    end
    parfor_progress(0);
    disp('Finding the bead with the maximum displacement...complete')
    [~, MaxDisplFrameNumber]  = max(dmaxTMP);

    displFieldPos = displField(MaxDisplFrameNumber).pos;
    displFieldVecNotDriftCorrected = displField(MaxDisplFrameNumber).vec;
    displFieldVecNotDriftCorrected(:,3) = vecnorm(displFieldVecNotDriftCorrected(:,1:2), 2, 2);
    clear displFieldVecMean corner_noise displFieldVecDriftCorrected
    
%% Drift-Correction of the displacement field.
    % 2. Drift Correction Mode?
%     if ~exist('DriftCorrectionChoiceStr', 'var'), DriftCorrectionChoiceStr = []; end
    
    DriftCorrectionChoiceStr = 'Yes';
    if isempty(DriftCorrectionChoiceStr)
        DriftCorrectionChoiceStr = questdlg('Do you want to drift-correct displacements?', 'Drift Correction?','Yes', 'No', 'Yes');
        if isempty(DriftCorrectionChoiceStr), return; end       
    end
    
    switch DriftCorrectionChoiceStr
        case 'Yes'
            DriftCorrectionChoiceStr = 'Drift-Corrected';
        case 'No'
            DriftCorrectionChoiceStr = 'Drift-Uncorrected';
        otherwise
            error('X was selected');      
    end
        
    switch DriftCorrectionChoiceStr
        case 'Drift-Corrected'
            % 2. Choose LUT            
%                 dlgQuestion = 'Select Colormap Look Up Table (LUT):';
%                 listStr = {'Red', 'Green', 'Blue', 'Other'};
%                 [colormapLUTchoice, TF1] = listdlg('ListString', listStr, 'PromptString',dlgQuestion, 'InitialValue', 1, 'SelectionMode' ,'Single', ...
%                     'ListSize', [200, 70]);    
%                 if TF1 == 0, return; end
%                 colormapLUTchoice = listStr{colormapLUTchoice};   
%                 
%                 colormapLUTchoice = 'Red';
              
%                 switch colormapLUTchoice             % represented as RGB = [Red, Green, Blue]
%                     case 'Red'
                        colormapLUT = [linspace(0,1,MaxGrayLevel)', zeros(MaxGrayLevel,2)];                           
%                     case 'Green'
%                         colormapLUT = [zeros(GrayLevels,1), linspace(0,1,GrayLevels)', zeros(GrayLevels,1)];    
%                     case 'Blue'
%                         colormapLUT = [zeros(GrayLevels,2), linspace(0,1,GrayLevels)'];    
%                     otherwise
%                         GrayLevelsStr = num2str(MaxGrayLevel);
%                         GrayLevelRangeStr = strcat('[0,', GrayLevelsStr, ']');
%                         ColormapListStr = {'Red Channel Gray Level [min, max]:' , 'Blue Channel Gray Level [min, max]:', 'Green Channel Gray Level [min, max]:'};
%                         ColormapDefaults = cell(1,3); 
%                         ColormapDefaults(:) = {GrayLevelRangeStr};
% %                         colormapLUTstr = inputdlg(ColormapListStr, 'Enter RGB LUTs', [1, 50; 1,50; 1,50], ColormapDefaults);
% 
%                         colormapRangeRed = str2num(colormapLUTstr{1});
%                         colormapRangeGreen = str2num(colormapLUTstr{2});
%                         colormapRangeBlue = str2num(colormapLUTstr{3});
%                         colormapRangeRed = [minIntensity, maxIntensity];
%                         colormapRangeGreen = [1, MaxGrayLevel];
%                         colormapRangeBlue = [1, MaxGrayLevel];
% 
%                         colormapRangeRedScaled = colormapRangeRed ./ MaxGrayLevel;
%                         colormapRangeGreenScaled = colormapRangeGreen ./ MaxGrayLevel;
%                         colormapRangeBlueScaled = colormapRangeBlue ./ MaxGrayLevel;
% 
%                         colormapLUT = [colormapRangeRedScaled', colormapRangeGreenScaled', colormapRangeBlueScaled']; 
%                 end
            % 3. heatmap colors             
                try
                   colormapRGBs = fake_parula(2^ImageBits);
                catch
                   colormapRGBs = fake_parula(2^ImageBits);
                end            
            % 4. choose quiver color that is complemenetary to the color LUT            
                QuiverColor = median(imcomplement(colormapLUT));               % User Complement of the colormap for maximum visibililty of the quiver.
                ImageSizePixels = movieData.imSize_;            

            % 13 =================== Load EPI image and adjust contrast ==================== 
                ChannelCount = numel(movieData.channels_);                                             % updated on 2020-04-15
                ChannelNum = ChannelCount;
                if ChannelCount ~= 1
                    prompt = {sprintf('Choose the channel to be plotted. [Channel Count = %i]', ChannelCount)};
                    dlgTitle = 'Channel To Be Plotted';
                    ChannelNumStr = inputdlg(prompt, dlgTitle, [1, 70], {num2str(ChannelNum)});
                    if isempty(ChannelNumStr), return; end
                    ChannelNum = str2double(ChannelNumStr{1});                                  % Convert to a number
                end
                GrayLevelsPercentile = [0.05,0.999];
%                 GrayLevelsPercentileStr = {strcat('[', num2str(GrayLevelsPercentile(1)), ',', num2str(GrayLevelsPercentile(2)), ']')};
%                 prompt = {sprintf('Enter Histogram Percentile Adjustment (Default: [%0.3f, %0.3f]): ', GrayLevelsPercentile(1), GrayLevelsPercentile(2))};
%                 GrayLevelsPercentileStr = inputdlg(prompt, 'Enter Percentile Adjustment', [1, 70], GrayLevelsPercentileStr);
%                 GrayLevelsPercentile = str2num(GrayLevelsPercentileStr{:});        
                try
                    curr_Image = movieData.channels_(ChannelNum).loadImage(MaxDisplFrameNumber);
                    if useGPU, curr_Image = gpuArray(curr_Image); end
                    curr_ImageAdjust = imadjust(curr_Image, stretchlim(curr_Image,GrayLevelsPercentile));       % Make beads contrast more
                catch
%                     BioformatsPath = uigetdir([], 'Select directory containing bioformats folder (e.g., TFMpackagefolder)');
                    BioformatsPath = 'Y:\Waddah_Aim3\Codes\MT_TFM Analysis\bioformats';             % for liux, replace "\" with "/" ,,,(strfind(path_unix,'\'))='/';
                    addpath(genpath(BioformatsPath));        % include subfolders
                    curr_Image = movieData.channels_(ChannelNum).loadImage(MaxDisplFrameNumber);
                    curr_ImageAdjust = imadjust(curr_Image, stretchlim(curr_Image,GrayLevelsPercentile));       % make beads contrast more.
                end    
            % =================== 
                figHandle = figure('color', 'w', 'Renderer', 'Painters');
                axes
                figAxesHandle = findobj(figHandle, 'type', 'Axes');
                colormap(colormapLUT);
                imagesc(figAxesHandle, 1, 1, curr_ImageAdjust);
                truesize(figHandle);
                hold on
                quiver(figAxesHandle, displFieldPos(:,1), displFieldPos(:,2), displFieldVecNotDriftCorrected(:,1), displFieldVecNotDriftCorrected(:,2), 'color', QuiverColor, ...
                    'Marker', '.', 'ShowArrowHead', 'on', 'LineWidth',  0.75, 'MarkerSize', 1)
                set(figAxesHandle,'LineWidth',1, 'XTick', [], 'YTick', [], 'Box', 'off')    
            %     xlabel('\itX \rm[pixels]'), ylabel('\itY \rm[pixels]')
                axis image
                figHandle.Visible = 'on';    

              %**** CONSIDER SAVING THE IMAGE **** %
                cornerCount = 4;
                clear rect rectHandle rectCorners DriftROIxx DriftROIyy nDriftROIxx corner_noise   
                IdenticalCornersChoice = 'Yes';
                CornerPercentageDefault = 0.10;     % 10% default
                commandwindow;
                if ~exist('CornerPercentage', 'var'), CornerPercentage = []; end
                if isempty(CornerPercentage)
                    inputStr = sprintf('Choose the percentage of the images size to use for noise adjustment [Default = %0.2g%%]: ', CornerPercentageDefault * 100);
                    CornerPercentage = input(inputStr);
                    if isempty(CornerPercentage)
                       CornerPercentage =  CornerPercentageDefault; 
                    else
                       CornerPercentage = CornerPercentage / 100;
                    end
                end       
                %% Plotting
                figure(figHandle)
                [displFieldBeadsDriftCorrected, rect, DriftROIs, DriftROIsCombined, reg_grid, gridSpacing, NoiseROIs, NoiseROIsCombined] = ...
                    DisplacementDriftCorrectionIdenticalCorners(displField, CornerPercentage, MaxDisplFrameNumber, gridMagnification, ...
                    EdgeErode, GridtypeChoiceStr, InterpolationMethod, 0);

                switch DriftCorrectionChoiceStr
                    case 'Yes'
                        displFieldVecDriftCorrected(:,1:2) = displFieldBeadsDriftCorrected(MaxDisplFrameNumber).vec(:,1:2);
                        displFieldVecDriftCorrected(:,3) = vecnorm(displFieldVecDriftCorrected(:,1:2), 2, 2); 
                        displFieldVec = displFieldVecDriftCorrected;

                        title(figAxesHandle, {sprintf('%d Corners of ROIs %0.2g%% per side to adjust for drift.', cornerCount, CornerPercentageDefault * 100), ...
                            sprintf('Frame %d/%d. Numbers of Points = %d', MaxDisplFrameNumber,FramesDoneNumbers(end), size(DriftROIsCombined(MaxDisplFrameNumber).pos, 1))});   
                    case 'No'
                        figHandle.Visible = 'off';
                        CornerPercentage = 0.10;
                        displFieldVec = displFieldVecNotDriftCorrected;

                        title(figAxesHandle, sprintf('Frame %d/%d.', MaxDisplFrameNumber,FramesDoneNumbers(end))); 
                end

                % plot the corners onto the figure now.
                for jj = 1:cornerCount
                   rectHandle(jj) = drawrectangle(figAxesHandle,'Position', rect(jj, :), 'StripeColor', QuiverColor, 'FaceAlpha', 0);             % make it fully transparent
                end
                pause(0.1)              % pause to allow it to draw the rectangles.
%                 title(figAxesHandle, 'ROIs to adjust for noise');

                % 17 =================== Insert Scale bar onto drift ROIs figure  ==================== 

%                 ScaleBarChoice = questdlg({'Do you want to insert a scalebar?','If yes, choose the right-edge position'}, 'ScaleBar Position?', 'Yes', 'No', 'Yes');
                ScaleBarChoice = 'Yes';
                if strcmpi(ScaleBarChoice, 'Yes')
                    ScaleBarNotOK = true;
                    while ScaleBarNotOK
                        ScaleBarUnits = sprintf('%sm', char(181));         % in Microns
                        figure(figHandle)

                        gridXmin = min(displField(FirstFrame).pos(:,1));
                        gridXmax = max(displField(FirstFrame).pos(:,1));
                        gridYmin = min(displField(FirstFrame).pos(:,2));
                        gridYmax = max(displField(FirstFrame).pos(:,2));                        
%                         [Location(1), Location(2)] = ginputc(1, 'Color', QuiverColor);                        
%                         Location = [gridXmax, gridYmax];
                        Location = movieData.imSize_ - [3,3];                  % bottom right corner

%                         prompt = sprintf('Scale Bar Length [%s]:', ScaleBarUnits);
%                         dlgTitle = 'Scale Bar Length?';
%                         dims = [1 40];
%                         defInput = {num2str(round((round((gridXmax*ScaleMicronPerPixel* CornerPercentage)/10) * 10)))};          % ideal scale length. CornerPercentage is 10%    
%                         opts.Interpreter = 'tex';
%                         ScaleLengthStr = inputdlg(prompt, dlgTitle, dims, defInput, opts);
%                         ScaleLength = str2double(ScaleLengthStr{:});
                        ScaleLength =   round((max(movieData.imSize_) - max([gridXmax - gridXmin, gridYmax - gridYmin]))/4, 1, 'significant');
%                         ScaleBarColor = uisetcolor(QuiverColor, 'Select the ScaleBar Color');   % [1,1,0] is the RGB for yellow        
                        ScaleBarColor = QuiverColor;
                        s = scalebar(figAxesHandle,'ScaleLength', ScaleLength, 'ScaleLengthRatio', ScaleMicronPerPixel, 'color', ScaleBarColor, ...
                            'bold', true, 'unit', sprintf('%sm', char(181)), 'location', Location);             % Modified by WIM
                        IsScaleBarOK = 'Yes';
                        %                         IsScaleBarOK = questdlg('Is the scale bar length & color looking OK?', 'Scalebar Length/Color OK?', 'Yes', 'No', 'Yes');
                        switch IsScaleBarOK
                            case 'Yes'
                                ScaleBarNotOK = false;
                            case 'No'
%                                 disp('**___to continue, type "dbcont" or press "F5, or click "Continue" under "Editor" Menu"___**')
%                                 keyboard
                        end
                    end
                end

%                 disp('**___to continue, type "dbcont" or press "F5, or click "Continue" under "Editor" Menu"___**')
%                 commandwindow
%                 keyboard
                
                % 18 =================== Save drift ROIs figure  ==================== 
                [~, DisplFileNamePrefix, ~] = fileparts(DisplacementFileFullName);
                displacementFileNameDC = sprintf('%s_DC%s', DisplFileNamePrefix, DisplFileExt); 
                DisplacementFileFullName = fullfile(DisplPathName, displacementFileNameDC);
                
                if SaveOutput
                    PlotChoice = {'PNG', 'FIG'};
                    for CurrentPlotType = 1:numel(PlotChoice)
                        tmpPlotChoice =  PlotChoice{CurrentPlotType};
                        switch tmpPlotChoice
                            case 'FIG'
                                savefig(figHandle, fullfile(DisplPathName, sprintf('%s_DC_ROIs.fig', DisplFileName)), 'compact')   
                            case 'PNG'
                                saveas(figHandle, fullfile(DisplPathName, sprintf('%s_DC_ROIs.png', DisplFileName)), 'png')
                            case 'EPS'
                                print(figHandle, fullfile(DisplPathName, sprintf('%s_DC.eps', DisplFileName)),'-depsc')
                        end
                    end
                end
                close(figHandle)    
                %% Finished Plotting
                [displFieldBeadsDriftCorrected, rect, DriftROIs, DriftROIsCombined, reg_grid, gridSpacing, NoiseROIs, NoiseROIsCombined] = ...
                    DisplacementDriftCorrectionIdenticalCorners(displField, CornerPercentage, FramesDoneNumbers, gridMagnification, ...
                    EdgeErode, GridtypeChoiceStr, InterpolationMethod, ShowOutput);

                displField = displFieldBeadsDriftCorrected;
                if SaveOutput
                    save(DisplacementFileFullName, 'displField', 'TimeStamps', 'movieData', 'rect', ...
                        'CornerPercentage', 'gridMagnification', 'EdgeErode', 'GridtypeChoiceStr', 'InterpolationMethod', ...
                        'DriftROIs', 'DriftROIsCombined', 'reg_grid', 'gridSpacing', 'NoiseROIs', 'NoiseROIsCombined' , 'DriftCorrectionChoiceStr', '-v7.3');    
                    try save(DisplacementFileFullName, 'TimeStampChoice', 'FrameRate', '-append'); catch; end
                    try save(DisplacementFileFullName, 'TimeFilterChoiceStr', '-append'); catch; end
                end
                Msg = sprintf('Drift-Corrected Displacement Field (displField) File is successfully saved as!: \n\t %s\n', DisplacementFileFullName);
                disp(Msg)
    end
    if ~exist('rect', 'var')
        try 
            load(DisplacementFileFullName,  'rect', 'DriftROIs', 'DriftROIsCombined', 'reg_grid', 'gridSpacing', 'NoiseROIs', 'NoiseROIsCombined')
        catch
            rect = []; DriftROIs = []; DriftROIsCombined = []; reg_grid = []; gridSpacing = []; NoiseROIs = []; NoiseROIsCombined = [];
        end
    end
 
    LastFrameOverall = min([LastFrame, numel(TimeStamps), numel(displField)]);
    FramesDoneNumbers = FramesDoneNumbers(1:find(FramesDoneNumbers == LastFrameOverall));
    if isempty(FramesDoneNumbers), FramesDoneNumbers = 1:LastFrameOverall; end
    LastFrame = FramesDoneNumbers(end);
    commandwindow;
    fprintf('Last Frame (min) of times stamps and tracked displacement frames = %d\n', LastFrame);
    
    TimeStamps = TimeStamps(FramesDoneNumbers);    
    displField = displField(FramesDoneNumbers);
    
    try
        DriftROIs = DriftROIs(FramesDoneNumbers);
        DriftROIsCombined = DriftROIsCombined(FramesDoneNumbers);
        NoiseROIs = NoiseROIs(FramesDoneNumbers);
        NoiseROIsCombined = NoiseROIsCombined(FramesDoneNumbers);
    catch
        % continue
    end
%     if isempty(AnalysisPath)
%         AnalysisPath = displacementFilePath;
%     end
%     
    %% saving now
    disp('** Processing displacements is complete!**')
    [~, FileNameDescription, ~] = fileparts(DisplacementFileFullName);          
    movieData.findProcessTag(ProcessTag).notes_  = FileNameDescription;
    disp('_____________________________________________________________________________________________')
end