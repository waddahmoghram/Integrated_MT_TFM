%{
    v.2020-09-10 by Waddah Moghram, PhD Candidate in biomedical Engineering at the University of Iowa.
        1. noW, you can use DC File based on how it is output as of today.
    v.2020-08-14 by Waddah Moghram, PhD Candidate in biomedical Engineering at the University of Iowa.
        Conduct statistics on DIC displacement field.
        Create a movie file 
    v.2020-07-30 by Waddah Moghram, PhD Candidate in Biomedical Engineering at the Unviersity of iowa.
        Based on TrackedEpiBeadsDynamics.m (v.2020-07-19)
        1. Takes DIC magnetic bead displacement and calculates the displacements (equivalent to max displacement)
%} 

function [MD, displFieldMicronMax, veloFieldMicronPerSecMax, accelFieldMicronPerSecSqMax, FirstFrame, LastFrame, movieFilePath, displacementFilePath, AnalysisPath, NetDisplacementPath] = TrackedDICBeadsDynamics(MD, displField, ...
    FirstFrame, LastFrame, NetDisplacementPath, ...
    ScaleMicronPerPixel, showPlot, AnalysisPath, TimeStamps)

   %% Check if there is a GPU. take advantage of it if is there.
    nGPU = gpuDeviceCount;
%     if nGPU > 0
%         dlgQuestion = 'Do you want to use GPU-Acceleration?';
%         dlgTitle = 'Use GPU?';
%         useGPUchoice = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No', 'Yes');
%         switch useGPUchoice
%             case 'Yes'
%                 useGPU = true;
%             case 'No'
%                 useGPU = false;
%             otherwise
%                 return;
%         end        
%     else
%         useGPU = false; 
%     end
    if nGPU > 0
        useGPU = true;
    else
        useGPU = false;
    end

    GelType = 'Type I Collagen';
    
    commandwindow;    

    SigmaOrAlpha = questdlg(strcat('Do you want to enter stardard deviation (', char(963), ') or Significance Level (', char(945), ')'), ...
        strcat(char(963), ' or ',  char(945)), 'Sigma', 'Alpha', 'Sigma');

    switch SigmaOrAlpha
        case 'Alpha'
            fprintf('List of Significant Levels: \n\t')
            fprintf('1 Sigma = 1 - 0.682689492137086 \n\t')
            fprintf('2 Sigma = 1 - 0.954499736103642 \n\t')
            fprintf('3 sigma = 1 - 0.997300203936740 \n\t')
            fprintf('4 sigma = 1 - 0.999936657516334 \n\t')
            fprintf('5 sigma = 1 - 0.999999426696856 \n\t')
            fprintf('6 sigma = 1 - 0.999999998026825 \n')

            StatAlpha = input('Choose the level of statistical significant. [Default = 0.05]: ');
            if isempty(StatAlpha), StatAlpha = 0.05; end
        case 'Sigma'
            SigmaLevelStr = inputdlg(strcat('Enter the value of Standard Deviations (', char(963), ') ='), char(963), [1, 50], {'6'});
            SigmaLevel = str2double(SigmaLevelStr{:});
            StatAlpha = 1 - erf(SigmaLevel/sqrt(2));           % by definition.
        otherwise
            return
    end
    
    
    %% -----------------------------------------------------------------------------------------------
    commandwindow;
    disp('============================== Running PlotBeadCoordinatesEpiMax.m GPU-enabled ===============================================')
    
    %% -----------------------------------------------------------------------------------------------
    if ~exist('MD', 'var'), MD = []; end
    if nargin < 1 || isempty(MD)
        CreateDIC_MDfile = questdlg('Do you want to create an *.mat MovieData file from the DIC ND2 file', 'Create DIC Movie Data File?', 'Yes', 'No', 'Yes');
        switch CreateDIC_MDfile
            case 'Yes'
                [ND2FileName, ND2FilePath] = uigetfile('*.nd2', 'Open *.ND2 Movie File');
                ND2FileFullName = fullfile(ND2FilePath, ND2FileName);
                MD = bfImport(ND2FileFullName, 'outputDirectory', ND2FilePath);         % Create a movieData file so that it can be processed, loaded etc.
                fprintf('Movie Data (MD) file is saved as: \n\t %s\n', MD.getFullPath);
                disp('------------------------------------------------------------------------------')
            case 'No'
                [movieFileName, movieFilePath] = uigetfile('*.mat', 'Open the TFM-Package Movie Data File');
                MovieFileFullName = fullfile(movieFilePath, movieFileName);
                try 
                    load(MovieFileFullName, 'MD')
                    fprintf('Movie Data (MD) file is: \n\t %s\n', MovieFileFullName);
                    disp('------------------------------------------------------------------------------')
                catch 
                    errordlg('Could not open the movie data file!')
                    return
                end
            otherwise
                return            
        end
    end    
    if ~exist('ND2FilePath', 'var'), ND2FilePath = pwd; end
    
    %% -----------------------------------------------------------------------------------------------
    [displacementFileName, displacementFilePath] = uigetfile(fullfile(ND2FilePath,'*.mat'), 'Open Tracked DIC Displacement *.mat file');
    if isempty(displacementFileName), return; end
    displacementFullFilename = fullfile(displacementFilePath, displacementFileName);
    try
       load(displacementFullFilename, 'BeadPositionXYdisplMicron', 'MagBeadCoordinatesXYNetpixels', 'MagBeadCoordinatesXYpixels')
    catch
        load(displacementFullFilename, 'MagBeadDisplacementMicronXYBigDelta', 'MagBeadCoordinatesXYpixels', 'MagBeadCoordinatesMicronXY')        
        BeadPositionXYdisplMicron = MagBeadCoordinatesMicronXY - MagBeadCoordinatesMicronXY(1,:);
        BeadPositionXYdisplMicron(:,3) = MagBeadDisplacementMicronXYBigDelta;               % should be the same vecnorm(MagBeadDisplacementMicronXYBigDelta);
    end
    
    FramesDoneBoolean = arrayfun(@(x) ~isempty(x), BeadPositionXYdisplMicron(:,3))';
    FramesDoneNumbers = find(FramesDoneBoolean == 1);     
    % 5 ==================== find first & last frame numbers to be plotted ==================== 
   if ~exist('FirstFrame', 'var'), FirstFrame = []; end
   if isempty(FirstFrame)|| nargin < 3      
            VeryFirstFrame = find(FramesDoneBoolean, 1, 'first');   
            VeryLastFrame =  find(FramesDoneBoolean, 1, 'last');
            commandwindow;
            prompt = {sprintf('Choose the first frame to plotted. [Default, Frame # = %d]', VeryFirstFrame)};
            dlgTitle = 'First Frame';
            FirstFrameStr = inputdlg(prompt, dlgTitle, [1, 90], {num2str(VeryFirstFrame)});
            if isempty(FirstFrameStr), return; end
            FirstFrame = str2double(FirstFrameStr{1});
            [~, FirstFrameIndex] = min(abs(FramesDoneNumbers - FirstFrame));
            FirstFrame = FramesDoneNumbers(FirstFrameIndex);
   end
   if ~exist('LastFrame', 'var') , LastFrame = []; end
   if isempty(LastFrame)|| nargin < 4
            prompt = {sprintf('Choose the last frame to plotted. [Default, Frame # = %d]. Note: Might be truncated if sensor signal is less', VeryLastFrame)};
            dlgTitle = 'Last Frame';
            LastFrameStr = inputdlg(prompt, dlgTitle, [1, 90], {num2str(VeryLastFrame)});
            if isempty(LastFrameStr), return; end
            LastFrame = str2double(LastFrameStr{1});
            [~, LastFrameIndex] = min(abs(FramesDoneNumbers - LastFrame));
            LastFrame = FramesDoneNumbers(LastFrameIndex);   
            FramesDoneBoolean = FramesDoneBoolean(FirstFrameIndex:LastFrameIndex);
            FramesDoneNumbers = FramesDoneNumbers(FirstFrameIndex:LastFrameIndex);
   end
   
    %% -----------------------------------------------------------------------------------------------
    if ~exist('NetDisplacementPath','var'), NetDisplacementPath = []; end
    if nargin < 5 || isempty(NetDisplacementPath)
        if ~exist('displacementFilePath', 'var'), displacementFilePath = []; end
        if isempty(displacementFilePath)
            try
                displacementFilePath = movieFilePath;
            catch
                displacementFilePath = pwd;
            end
        end
        NetDisplacementPath = uigetdir(displacementFilePath,'Choose the directory where you want to store the Mag bead displacement DIC.');
        if NetDisplacementPath == 0  % Cancel was selected
            clear NetDisplacementPath;
        elseif ~exist(NetDisplacementPath,'dir')
            mkdir(NetDisplacementPath);
        end
        
        fprintf('NetDisplacementDIC Path is: \n\t %s\n', NetDisplacementPath);
        disp('------------------------------------------------------------------------------')
    end    
    
    %% -----------------------------------------------------------------------------------------------
    if ~exist('ScaleMicronPerPixel', 'var') || nargin < 6
        try
            ScaleMicronPerPixel = MD.pixelSize_ / 1000;         % convert from nm/pixel to micron/pixels.
            MagnificationTimes = round(((MagnificationScalesMicronPerPixel(20)/ScaleMicronPerPixel) * 20));
        catch
            [ScaleMicronPerPixel, ~, MagnificationTimes] = MagnificationScalesMicronPerPixel();    
        end
    end
    fprintf('Magnification scale is %.5f microns/pixel\n', ScaleMicronPerPixel)
    
    %% -----------------------------------------------------------------------------------------------
    if ~exist('showPlot','var'), showPlot = []; end
    if nargin < 7 || isempty(showPlot)
        dlgQuestion = 'Do you want to show the plot of max net displacement EPI vs. time?';
        dlgTitle = 'Show Net Displacement EPI Max?';
        showPlotChoice = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No', 'Yes');
    elseif showPlot == 0 || strcmpi(showPlot, 'N') || strcmpi(showPlot, 'No') || strcmpi(showPlot, 'Off')
        showPlotChoice = 'No';
    elseif showPlot == 1 || strcmpi(showPlot, 'Y') || strcmpi(showPlot, 'Yes') || strcmpi(showPlot, 'On')
        showPlotChoice = 'Yes';
    end    
    switch showPlotChoice
        case 'Yes'
            showPlot = 'on';
        case 'No'
            showPlot = 'off';
        otherwise
            return
    end
    
    %% -----------------------------------------------------------------------------------------------
    dlgQuestion = 'Select image format.';
    listStr = {'PNG', 'FIG', 'EPS'};
    PlotChoice = listdlg('ListString', listStr, 'PromptString',dlgQuestion, 'InitialValue', [1,2], 'SelectionMode' ,'multiple');    
    PlotChoice = listStr(PlotChoice);                 % get the names of the string.   

    NetDisplacementNameMAT = fullfile(NetDisplacementPath, 'Bead Dynamics Results.mat');
    fprintf('Net Displacement MAT file name is: \n\t %s\n', NetDisplacementNameMAT);
    
   disp('------------------------------------------------------------------------------')
    
    %% -----------------------------------------------------------------------------------------------
    if ~exist('AnalysisPath','var'), AnalysisPath = []; end    
    if nargin < 8 || isempty(AnalysisPath)        
        dlgQuestion = ({'Do you want to save in an Analysis output folder?'});
        dlgTitle = 'Analysis folder?';
        AnalysisFolderChoice = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No', 'No');
        switch AnalysisFolderChoice
            case 'Yes'
                if ~exist('movieFilePath','var'), movieFilePath = pwd; end
                AnalysisPath = uigetdir(movieFilePath,'Choose the analysis directory where the max net displacement Epi will be saved.');     
                if AnalysisPath == 0  % Cancel was selected
                    clear AnalysisPath;
                    return
                elseif ~exist(AnalysisPath,'dir')   % Check for a directory
                    mkdir(AnalysisPath);
                end
                                    
            case 'No'
                % continue. Do nothing
            otherwise
                return
        end               
    end
    
    %% -----------------------------------------------------------------------------------------------
    if ~exist('maxDisplacement','var'), maxDisplacement = []; end              % this is necessary if you know what the max is ahread of it
    
    if nargin < 9 || isempty(maxDisplacement)
        maxDisplacement = -1;
        maxFrame = -1;
        minDisplacement = Inf;
        disp('Evaluating the maximum and minimum displacement value in progress....')
        reverseString = ''; 
        clear CurrentFrame
        
        if ~exist('MagBeadCoordinatesXYNetpixels', 'var')
           MagBeadCoordinatesXYNetpixels =  MagBeadCoordinatesXYpixels - MagBeadCoordinatesXYpixels(1,:);
           MagBeadCoordinatesXYNetpixels(:,3) = vecnorm(MagBeadCoordinatesXYNetpixels(:,1:2), 2, 2);
        end
        
        for CurrentFrame = FramesDoneNumbers
            ProgressMsg = sprintf('\nEvaluating Frame #%d/%d...\n', CurrentFrame, FramesDoneNumbers(end));
            fprintf([reverseString, ProgressMsg]);
            reverseString = repmat(sprintf('\b'), 1, length(ProgressMsg));        
            FieldVecNorm = MagBeadCoordinatesXYNetpixels(CurrentFrame, 3);
            if nargin < 4 || isempty(maxDisplacement)
                [maxDisplacement, maxDisplacementIndex] = max([maxDisplacement, max(FieldVecNorm)]);
                if maxDisplacementIndex == 2, maxFrame = CurrentFrame; end
                minDisplacement = min([minDisplacement,min(FieldVecNorm)]);
            end
        end      
%     else
%         msgbox('Make sure the entered Maximum Displacement is in microns.')
    end
        
    maxDisplacementMicron = maxDisplacement * ScaleMicronPerPixel;   
    minDisplacementMicron = minDisplacement * ScaleMicronPerPixel;
   
    fprintf('Maximum displacement is %g pixels at Frame %d/%d \n', maxDisplacement, maxFrame, FramesDoneNumbers(end));
    fprintf('Maximum displacement is %g microns, based on tracked points. \n', maxDisplacementMicron);  
    disp('------------------------------------------------------------------------------')
    
    %% Converting to displField format instead

    reverseString = '';
    for CurrentFrame = FramesDoneNumbers
        ProgressMsg = sprintf('Searching Frame #%d/(%d-%d)...\n',CurrentFrame, FramesDoneNumbers(1),FramesDoneNumbers(end));
        fprintf([reverseString, ProgressMsg]);
        reverseString = repmat(sprintf('\b'), 1, length(ProgressMsg));
        
        displField(CurrentFrame).vec(1,:) = MagBeadCoordinatesXYNetpixels(CurrentFrame,:).* [1,-1, 1];            % Reverse Y-coordinates to the same notation (Y*-positive downwards)                            
        displField(CurrentFrame).pos(1,:) = MagBeadCoordinatesXYpixels(CurrentFrame,:) .* [1,-1];            % Reverse Y-coordinates to the same notation (Y*-positive downwards)   
    end   

    MaxPosPixelsXYnet = displField(maxFrame).pos; 
    MaxDisplPixelsXYnet = displField(maxFrame).vec;     
    
    MaxDisplMicronsXYnet =  MaxDisplPixelsXYnet * ScaleMicronPerPixel;
    fprintf('[x,y] = [%g, %g] pixels in Frame #%d\n', MaxPosPixelsXYnet, maxFrame)
    fprintf('Maximum displacement [disp_x, disp_y] =  [%0.4g, %0.4g] pixels==> Net displacement [disp_net] = [%0.4g] pixels. \n', MaxDisplPixelsXYnet)
    fprintf('Maximum displacement [disp_x, disp_y] =  [%0.4g, %0.4g] microns==> Net displacement [disp_net] = [%0.4g] microns. \n', MaxDisplMicronsXYnet)
    
    %% -----------------------------------------------------------------------------------------------    
    if ~exist('TimeStamps','var'), TimeStamps = []; end
    if nargin < 9 || isempty(TimeStamps)        
        dlgQuestion = ({'Which timestamps do you want to use)?'});
        dlgTitle = 'Real-Time vs. Camera-Time vs. from FPS rate?';
        TimeStampChoice = questdlg(dlgQuestion, dlgTitle, 'Real-Time', 'Camera-Time', 'From FPS rate', 'Real-Time');
        if isempty(TimeStampChoice), error('No Choice was made'); end
        try
            movieDir = movieData.outputDirectory_;
        catch
            try movieDir = NetDisplacementPath; catch, movieDir = pwd; end
        end
        switch TimeStampChoice
            case 'Real-Time'
                try 
                    [TimeStampFileNameEPI, TimeStampPathEPI] = uigetfile(movieDir, 'EPI TimeStamps RT Sec');
                    if isempty(TimeStampFileNameEPI), error('No File Was chosen'); end
                    TimeStampFullFileNameEPI = fullfile(TimeStampPathEPI, TimeStampFileNameEPI);
                    TimeStampsRT_SecData = load(TimeStampFullFileNameEPI);
                    TimeStamps = TimeStampsRT_SecData.TimeStampsAbsoluteRT_Sec;
                    FrameRate = 1/mean(diff(TimeStampsRT_SecData.TimeStampsRelativeRT_Sec));
                catch                        
                    [TimeStamps, ~, ~, ~, AverageFrameRate] = TimestampRTfromSensorData();
                    FrameRate = 1/AverageFrameRate;
                end
                xLabelTime = 'Real Time [s]';

            case 'Camera-Time'
                try 
                    [TimeStampFileNameEPI, TimeStampPathEPI] = uigetfile(movieDir, 'EPI TimeStamps ND2 Sec');
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
                xLabelTime = 'Camera Time [s]';

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
                xLabelTime = 'Time based on frame rate [s]';
        end
    else
        FrameRate = 1/mean(diff(TimeStamps));
        xLabelTime = 'Time based on frame rate [s]';
    end
    
    if ~exist('TimeStamps', 'var')
        TimeStamps = (VeryFirstFrame:VeryLastFrame)' ./ FrameRate;
        TimeStamps = TimeStamps - TimeStamps(1);                                    % MAKE THE FIRST FRAME IDENTICALLY ZERO 2020-01-28
    end
    prompt = {sprintf('Choose the Frame Rate per second for this movie. [Default, %.4f]', FrameRate)};
    dlgTitle =  'Frames Per Second';
    FrameRateStr = inputdlg(prompt, dlgTitle, [1, 90], {num2str(FrameRate)});
    if isempty(FrameRateStr), return; end
    FrameRate = str2double(FrameRateStr{1});                                  % Convert to a number
    
    LastFrameOverall = min([LastFrame, numel(TimeStamps)]);
    FramesDoneBoolean = FramesDoneBoolean(1:find(FramesDoneNumbers == LastFrameOverall));
    FramesDoneNumbers = FramesDoneNumbers(1:find(FramesDoneNumbers == LastFrameOverall));
    
    TimeStamps = TimeStamps(FramesDoneNumbers);
        
    %% ---------------------------------------------------------------------------------------------- 
    if nargin > 10
        errordlg('Too many arguments in this function, or wrong argument structure!')
        return
    end      
    
    %% ==================================================================================  
    % 2. Covnert only displacements (.vec) to microns. Keep Starting positions in pixels. Keep the same structure
    totalPoints = size(displField(FirstFrame).pos, 1);
    MaxDisplFieldIndex = 1;
    displFieldMicronMax = struct('pos', displField(FirstFrame).pos(MaxDisplFieldIndex,:), 'vec',  NaN(1, 3));
    
    displMicronMaxVecX = nan([numel(FramesDoneNumbers), 1]);
    displMicronMaxVecY = nan([numel(FramesDoneNumbers), 1]);
    displMicronMaxVecNorm = nan([numel(FramesDoneNumbers), 1]);
    
    for CurrentFrame = FramesDoneNumbers               
        displFieldMicronMax(CurrentFrame).pos = displField(CurrentFrame).pos; 
        displFieldMicronMax(CurrentFrame).vec = displField(CurrentFrame).vec .* ScaleMicronPerPixel;       
        
        displMicronMaxVecX(CurrentFrame) = displFieldMicronMax(CurrentFrame).vec(:,1);
        displMicronMaxVecY(CurrentFrame) = displFieldMicronMax(CurrentFrame).vec(:,2);
        displMicronMaxVecNorm(CurrentFrame) = displFieldMicronMax(CurrentFrame).vec(:,3);
    end        

    %% Calculate the bead instantaneous velocity: Foward derivative for first frame. Backward derivative for last frame. Central for anything in between (best method). Overkill Not needed.
    veloFieldMicronPerSecMax =  struct('pos', displField(FirstFrame).pos(MaxDisplFieldIndex,:), 'vec',  NaN(1, 3));  
    
    accelFieldMicronPerSecSqMax =  struct('pos', displField(FirstFrame).pos(MaxDisplFieldIndex,:), 'vec',  NaN(1, 3));

    veloMicronPerSecMaxVecX = nan([numel(FramesDoneNumbers), 1]);
    veloMicronPerSecMaxVecY = nan([numel(FramesDoneNumbers), 1]);
    veloMicronPerSecMaxVecNorm = nan([numel(FramesDoneNumbers), 1]); 
    
    accelMicronPerSecSqMaxVecX = nan([numel(FramesDoneNumbers), 1]);
    accelMicronPerSecSqMaxVecY = nan([numel(FramesDoneNumbers), 1]);
    accelMicronPerSecSqMaxVecNorm = nan([numel(FramesDoneNumbers), 1]);
    
    for CurrentFrame = FramesDoneNumbers
        veloFieldMicronPerSecMax(CurrentFrame).pos = displField(CurrentFrame).pos;
        accelFieldMicronPerSecSqMax(CurrentFrame).pos = displField(CurrentFrame).pos;
        
        if CurrentFrame > FramesDoneNumbers(1)
            veloFieldMicronPerSecMax(CurrentFrame).vec(:,1:2) = (displFieldMicronMax(CurrentFrame).vec(:,1:2) - displFieldMicronMax(CurrentFrame - 1).vec(:,1:2)) / (TimeStamps(CurrentFrame) - TimeStamps(CurrentFrame - 1));      
            if CurrentFrame > FramesDoneNumbers(2)               
                accelFieldMicronPerSecSqMax(CurrentFrame).vec(:,1:2) = (veloFieldMicronPerSecMax(CurrentFrame).vec(:,1:2) - veloFieldMicronPerSecMax(CurrentFrame - 1).vec(:,1:2)) / (TimeStamps(CurrentFrame) - TimeStamps(CurrentFrame - 1));
            else
                accelFieldMicronPerSecSqMax(CurrentFrame).vec = accelFieldMicronPerSecSqMax(FramesDoneNumbers(1)).vec;
            end 
        end
        
        veloFieldMicronPerSecMax(CurrentFrame).vec(:,3) = vecnorm(veloFieldMicronPerSecMax(CurrentFrame).vec(:,1:2), 2, 2);
        
        accelFieldMicronPerSecSqMax(CurrentFrame).vec(:,3) = vecnorm(accelFieldMicronPerSecSqMax(CurrentFrame).vec(:,1:2), 2, 2); 
  
        veloMicronPerSecMaxVecX(CurrentFrame) = veloFieldMicronPerSecMax(CurrentFrame).vec(:,1);
        veloMicronPerSecMaxVecY(CurrentFrame) = veloFieldMicronPerSecMax(CurrentFrame).vec(:,2);
        veloMicronPerSecMaxVecNorm(CurrentFrame) = veloFieldMicronPerSecMax(CurrentFrame).vec(:,3);          
        
        accelMicronPerSecSqMaxVecX(CurrentFrame) = accelFieldMicronPerSecSqMax(CurrentFrame).vec(:,1);
        accelMicronPerSecSqMaxVecY(CurrentFrame) = accelFieldMicronPerSecSqMax(CurrentFrame).vec(:,2);
        accelMicronPerSecSqMaxVecNorm(CurrentFrame) = accelFieldMicronPerSecSqMax(CurrentFrame).vec(:,3);
    end
    
%% Stats to bound the Displacement (two-tailed for norm distribution, and a one-tailed for the Rayleigh distribution).
%----- max bead
    [displMicronMuHatMaxX, displMicronSigmaHatMaxX, displMicronMuCImaxX, displMicronSigmaCImaxX] = normfit(rmmissing(displMicronMaxVecX'), StatAlpha);
    displMicronCImaxX = norminv([StatAlpha/2, 1-StatAlpha/2], displMicronMuHatMaxX, displMicronSigmaHatMaxX);
     
    [displMicronMuHatMaxY, displMicronSigmaHatMaxY, displMicronMuCImaxY, displMicronSigmaCImaxY] = normfit(rmmissing(displMicronMaxVecY'), StatAlpha);
    displMicronCImaxY = norminv([StatAlpha/2, 1-StatAlpha/2], displMicronMuHatMaxY, displMicronSigmaHatMaxY);
    
    [displBparamMuHatMaxNorm, displBparamCImaxNorm] = raylfit(rmmissing(displMicronMaxVecNorm'), StatAlpha);
    displMicronCImaxNorm(1) = 0;
    displMicronCImaxNorm(2) = raylinv(1 - StatAlpha, displBparamMuHatMaxNorm);   % one-tailed test    
    [displMicronMuHatMaxNorm, displMicronVarHatMaxNorm] = raylstat(displBparamMuHatMaxNorm);
    displMicronSigmaHatMaxNorm = sqrt(displMicronVarHatMaxNorm);    
    [displMicronMuCIMaxNorm, displMicronVarCIMaxNorm] = raylstat(displBparamCImaxNorm);
    displMicronSigmaCImaxNorm = sqrt(displMicronVarCIMaxNorm);

    
    %% Velocity & Accelerations Now
%----- max bead    
    [veloMicronPerSecMuHatMaxX, veloMicronPerSecSigmaHatMaxX, veloMicronPerSecMuCImaxX, veloMicronPerSecSigmaCImaxX] = normfit(rmmissing(veloMicronPerSecMaxVecX'), StatAlpha);
    veloMicronPerSecCImaxX = norminv([StatAlpha/2, 1-StatAlpha/2], veloMicronPerSecMuHatMaxX, veloMicronPerSecSigmaHatMaxX);
    [accelMicronPerSecSqMuHatMaxX, accelMicronPerSecSqSigmaHatMaxX, accelMicronPerSecSqMuCImaxX, accelMicronPerSecSqSigmaCImaxX] = normfit(rmmissing(accelMicronPerSecSqMaxVecX'), StatAlpha/2);
    accelMicronPerSecSqCImaxX = norminv([StatAlpha/2, 1-StatAlpha/2], accelMicronPerSecSqMuHatMaxX, accelMicronPerSecSqSigmaHatMaxX);    
     
    [veloMicronPerSecMuHatMaxY, veloMicronPerSecSigmaHatMaxY, veloMicronPerSecMuCImaxY, veloMicronPerSecSigmaCImaxY] = normfit(rmmissing(veloMicronPerSecMaxVecY'), StatAlpha);
    veloMicronPerSecCImaxY = norminv([StatAlpha/2, 1-StatAlpha/2], veloMicronPerSecMuHatMaxY, veloMicronPerSecSigmaHatMaxY);
    [accelMicronPerSecSqMuHatMaxY, accelMicronPerSecSqSigmaHatMaxY, accelMicronPerSecSqMuCImaxY, accelMicronPerSecSqSigmaCImaxY] = normfit(rmmissing(accelMicronPerSecSqMaxVecY'), StatAlpha/2);
    accelMicronPerSecSqCImaxY = norminv([StatAlpha/2, 1-StatAlpha/2], accelMicronPerSecSqMuHatMaxY, accelMicronPerSecSqSigmaHatMaxY);
    
    [veloBparamMuHatMaxNorm, veloBparamCImaxNorm] = raylfit(rmmissing(veloMicronPerSecMaxVecNorm'), StatAlpha);
    veloMicronPerSecCImaxNorm(1) = 0;
    veloMicronPerSecCImaxNorm(2) = raylinv(1 - StatAlpha, veloBparamMuHatMaxNorm);   % one-tailed test    
    [veloMicronPerSecMuHatMaxNorm, veloMicronPerSecVarHatMaxNorm] = raylstat(veloBparamMuHatMaxNorm);
    veloMicronPerSecSigmaHatMaxNorm = sqrt(veloMicronPerSecVarHatMaxNorm);    
    [veloMicronPerSecMuCIMaxNorm, veloMicronPerSecVarCIMaxNorm] = raylstat(veloBparamCImaxNorm);
    veloMicronPerSecSigmaCImaxNorm = sqrt(veloMicronPerSecVarCIMaxNorm);
    
    [accelBparamMuHatMaxNorm, accelBparamCImaxNorm] = raylfit(rmmissing(accelMicronPerSecSqMaxVecNorm'), StatAlpha);
    accelMicronPerSecSqCImaxNorm(1) = 0;
    accelMicronPerSecSqCImaxNorm(2) = raylinv(1 - StatAlpha, accelBparamMuHatMaxNorm);   % one-tailed test    
    [accelMicronPerSecSqMuHatMaxNorm, accelMicronPerSecSqVarHatMaxNorm] = raylstat(accelBparamMuHatMaxNorm);
    accelMicronPerSecSqSigmaHatMaxNorm = sqrt(accelMicronPerSecSqVarHatMaxNorm);    
    [accelMicronPerSecSqMuCIMaxNorm, accelMicronPerSecSqVarCIMaxNorm] = raylstat(accelBparamCImaxNorm);
    accelMicronPerSecSqSigmaCImaxNorm = sqrt(accelMicronPerSecSqVarCIMaxNorm);
    
    
        %% Plotting the overall maximum overtime
         % -----------------------------------------------------------------------------------------------           .
    commandwindow;            
    GelConcentrationMgMl = input('What was the gel concentration in mg/mL? '); 
    if isempty(GelConcentrationMgMl)
        GelConcentrationMgMlStr = 'N/A';
        GelConcentrationMgMl = NaN;
    else
        GelConcentrationMgMlStr = sprintf('%.1f', GelConcentrationMgMl);
    end
    fprintf('Gel Concentration Chosen is %s mg/mL. \n', GelConcentrationMgMlStr);
    %----------------------------------------------
    try
        try
            thickness_um = forceFieldCalculationInfo.funParams_.thickness_nm/1000;
        catch
            thickness_um = forceFieldCalculationInfo.funParams_.thickness/1000;
        end
    catch
        thickness_um = [];
    end
    commandwindow;
    if isempty(thickness_um)
        commandwindow;
        thickness_um = input('What was the gel thickness in microns? ');
        fprintf('Gel thickness is %d  microns. \n', thickness_um);
    else
        thickness_um_input = input(sprintf('Do you want to use %g microns as the gel thickness?\n\t Press Enter to continue. Enter the value and enter otherwise: ',thickness_um));  
        if ~isempty(thickness_um_input), thickness_um = thickness_um_input; end
        fprintf('Gel thickness is %d  microns. \n', thickness_um);
    end
    %----------------------------------------------
    try
        YoungModulusPa = forceFieldCalculationInfo.funParams_.YoungModulus;
    catch
        YoungModulusPa = [];
    end
    commandwindow;
    if isempty(YoungModulusPa)
        YoungModulusPa = input('What was the gel''s Young Elastic modulus (in Pa)? ');  
        fprintf('Gel''s elastic modulus (E) is %g  Pa. \n', YoungModulusPa);
    else        
        YoungModulusPa_input = input(sprintf('Do you want to use %g Pa as the gel''s elastic modulus?\n\t Press Enter to continue. Enter the value and enter otherwise: ',YoungModulusPa));  
        if ~isempty(YoungModulusPa_input), YoungModulusPa = YoungModulusPa_input; end
        fprintf('Gel''s elastic modulus (E) is %g Pa. \n', YoungModulusPa);   
    end
    %----------------------------------------------
    try
        PoissonRatio = forceFieldCalculationInfo.funParams_.PoissonRatio;
    catch
        PoissonRatio = [];
    end            
    commandwindow;
    if isempty(PoissonRatio)
        PoissonRatio = input('What was the gel''s Poisson Ratio (unitless)? ');  
        fprintf('Gel''s Poisson Ratio (nu) is %g. \n', PoissonRatio);
    else
        PoissonRatio_input = input(sprintf('Do you want to use %g as the gel''s Poisson Ratio (unitless)?\n\t Press Enter to continue. Enter the value and enter otherwise: ',PoissonRatio));  
        if ~isempty(PoissonRatio_input), PoissonRatio = PoissonRatio_input; end
        fprintf('Gel''s Poisson Ratio (nu) is %g. \n', PoissonRatio);       
    end
    commandwindow;
    if isempty(GelType)
        GelType = input('What type of gel was used for the experiment? ', 's');
        if ~isempty(GelType)
           fprintf('Gel type is: "%s" \n', GelType);
        else
           disp('No gel type was given')
        end
    else
        GelTypeInput = input(sprintf('Do you want to use "%s" as the gel type?\n\t Press Enter to continue. Type the gel type otherwise: ',GelType), 's');  
        if ~isempty(GelTypeInput), GelType = GelTypeInput; end
        fprintf('Gel type is: "%s" \n', GelType);     
    end
     
    %%    
    try 
        save(NetDisplacementNameMAT, 'GelConcentrationMgMl', 'thickness_um', 'GelType', '-v7.3');          % Modified by WIM on 2/5/2019
    %     if  strcmpi(AnalysisFolderChoice , 'Yes')
    %         save(AnalysisNetDisplacementNameMAT, 'GelConcentrationMgMl', 'thickness_um', '-v7.3');                   % Modified by WIM on 2/5/2019
    %     end
    catch
        % Do nothing
    end    
    
    %% Do you want to add a negative control experiment confidence intervals
    dlgQuestion = sprintf('Do you want to use instead a negative-control experiment confidence intervals displacement and acceleration from another "Bead Dynamics Results.m" file?');
    dlgTitle = 'Open displacement field?';
    NegativeBeadDynamicsStatsChoice = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No', 'Yes');
    switch NegativeBeadDynamicsStatsChoice
        case 'Yes'
            [NegativeBeadDynamicsFileName, NegativeBeadDynamicsFilePath] = uigetfile(fullfile(displacementFilePath, '*.mat'), ...
                'Open negative "Bead Dynamics Results.m" file');
            NegativeBeadDynamicsFileFullName = fullfile(NegativeBeadDynamicsFilePath, NegativeBeadDynamicsFileName);
            try 
                NegativeBeadDynamics = load(NegativeBeadDynamicsFileFullName);
                fprintf('Negative Bead Dynamics file is: \n\t %s\n', NegativeBeadDynamicsFileFullName)
                disp('------------------------------------------------------------------------------')
            catch 
                errordlg('Could not open the movie data file!')
                return
            end
    end
 
%%  Generating the plots
    Style1 = 'k-';       %Style1 = 'k:';
    Style2 = 'b-';      %Style2 = 'b--';

    FrameCount = numel(FramesDoneNumbers);
    um = sprintf('%sm', char(181));
    titleStr1_1 = sprintf('%.0f %s-thick, %.1f mg/mL %s gel', thickness_um, um, GelConcentrationMgMl, GelType);
    titleStr1_2 = sprintf('Young Modulus = %g Pa. Poisson Ratio = %g', YoungModulusPa, PoissonRatio);
    if strcmpi(SigmaOrAlpha, 'Sigma')
        titleStr1_3 = sprintf('Gaussian Fit %.3g%s CI bounds', SigmaLevel, char(963));             % sigma in unicode
        titleStr1_4 = sprintf('Rayleigh Fit %.3g%s CI bounds', SigmaLevel, char(963));             % sigma in unicode
    else
        titleStr1_3 = sprintf('Gaussian Fit %s = %.10f CI bounds', char(945), (1-StatAlpha)*100);     % sigma in unicode
        titleStr1_4 = sprintf('Rayleigh Fit %.3g%s CI bounds', SigmaLevel, char(963));             % sigma in unicode
    end
    titleStr1 = {titleStr1_1, titleStr1_2, titleStr1_3};
    titleStr2 = {titleStr1_1, titleStr1_2, titleStr1_4};

%% ___ Plot max norm 
    figHandleBeadDynamicsMaxNorm = figure('visible',showPlot, 'color', 'w');     % added by WIM on 2019-02-07. To show, remove 'visible
    set(figHandleBeadDynamicsMaxNorm, 'Position', [200, 300, 825, 775])
    pause(0.1)          % give some time so that the figure loads well
    subplot(3,1,1);
    plot(TimeStamps(FramesDoneNumbers), displMicronMaxVecNorm, 'r.-', 'LineWidth', 1, 'MarkerSize', 1, 'HandleVisibility', 'off')
    hold on
    if strcmpi(NegativeBeadDynamicsStatsChoice, 'Yes')
        plot(TimeStamps(FramesDoneNumbers), repmat(NegativeBeadDynamics.displMicronMuHatMaxNorm, FrameCount, 1)', Style1, 'LineWidth', 1)   
        plot(TimeStamps(FramesDoneNumbers), repmat(NegativeBeadDynamics.displMicronCImaxNorm(2), FrameCount, 1)', Style2, 'LineWidth', 1)
        txt = sprintf('\\mu=%0.5f, CI = [%0.5f, %0.5f] %s', NegativeBeadDynamics.displMicronMuHatMaxNorm, NegativeBeadDynamics.displMicronCImaxNorm, um);            
    else
        plot(TimeStamps(FramesDoneNumbers), repmat(displMicronMuHatMaxNorm, FrameCount, 1)', Style1, 'LineWidth', 1)   
        plot(TimeStamps(FramesDoneNumbers), repmat(displMicronCImaxNorm(2), FrameCount, 1)', Style2, 'LineWidth', 1)
        txt = sprintf('\\mu=%0.5f, CI = [%0.5f, %0.5f] %s', displMicronMuHatMaxNorm, displMicronCImaxNorm, um);
    end
    text(0.05,1.1, txt, 'Units', 'normalized');
    xlim([0, TimeStamps(end)]);
    %     xlim([0, TimeStamps(LastFramePlotted)]);
    title(titleStr1);
    set(findobj(gcf,'type', 'axes'), ...
    'FontSize',11, ...
    'FontName', 'Helvetica', ...
    'LineWidth',1, ...
    'XMinorTick', 'on', ...
    'YMinorTick', 'on', ...
    'TickDir', 'out', ...
    'TickLength', [0.02, 0.03], ...
    'TitleFontSizeMultiplier', 0.9, ...
    'TitleFontWeight', 'bold');     % Make axes bold
    ylabel(strcat('\itu\rm_{max}(\itt\rm) [', um, ']'));
    hold on  
    if strcmpi(NegativeBeadDynamicsStatsChoice, 'Yes')
        legend('Rayleigh Fit Mean  ',strcat(titleStr1_3, ' -ve ctrl'),'Location', 'best', 'Orientation', 'horizontal')
    else
        legend('Rayleigh Fit Mean', titleStr1_3, 'Location', 'best', 'Orientation', 'horizontal')
    end

    subplot(3,1,2);
    plot(TimeStamps(FramesDoneNumbers), veloMicronPerSecMaxVecNorm', 'r.-', 'LineWidth', 1, 'MarkerSize', 2, 'HandleVisibility', 'off')
    hold on
    if strcmpi(NegativeBeadDynamicsStatsChoice, 'Yes')
        plot(TimeStamps(FramesDoneNumbers), repmat(NegativeBeadDynamics.veloMicronPerSecMuHatMaxNorm', FrameCount, 1)', Style1, 'LineWidth', 1)   
        plot(TimeStamps(FramesDoneNumbers), repmat(NegativeBeadDynamics.veloMicronPerSecCImaxNorm(2)', FrameCount, 1)', Style2, 'LineWidth', 1)
        txt = sprintf('\\mu=%0.5f, CI = [%0.5f, %0.5f] %s/s', NegativeBeadDynamics.veloMicronPerSecMuHatMaxNorm, NegativeBeadDynamics.veloMicronPerSecCImaxNorm, um);
    else
        plot(TimeStamps(FramesDoneNumbers), repmat(veloMicronPerSecMuHatMaxNorm, FrameCount, 1)', Style1, 'LineWidth', 1)   
        plot(TimeStamps(FramesDoneNumbers), repmat(veloMicronPerSecCImaxNorm(2), FrameCount, 1)', Style2, 'LineWidth', 1)        
        txt = sprintf('\\mu=%0.5f, CI = [%0.5f, %0.5f] %s/s', veloMicronPerSecMuHatMaxNorm, veloMicronPerSecCImaxNorm, um);
    end
    text(0.05,1.1, txt, 'Units', 'normalized');
    xlim([0, TimeStamps(end)]);
    set(findobj(gcf,'type', 'axes'), ...
    'FontSize',11, ...
    'FontName', 'Helvetica', ...
    'LineWidth',1, ...
    'XMinorTick', 'on', ...
    'YMinorTick', 'on', ...
    'TickDir', 'out', ...
    'TickLength', [0.02, 0.03], ...
    'TitleFontSizeMultiplier', 0.9, ...
    'TitleFontWeight', 'bold');     % Make axes bold
    ylabel(strcat('{\partial\itu\rm_{max}(\itt\rm)}/{\partial\itt\rm} [', um, '/s]'), 'Interpreter', 'tex');
  
    subplot(3,1,3);
    plot(TimeStamps(FramesDoneNumbers), accelMicronPerSecSqMaxVecNorm, 'r.-', 'LineWidth', 1, 'MarkerSize', 2, 'HandleVisibility', 'off')
    hold on
    if strcmpi(NegativeBeadDynamicsStatsChoice, 'Yes')
        plot(TimeStamps(FramesDoneNumbers), repmat(NegativeBeadDynamics.accelMicronPerSecSqMuHatMaxNorm, FrameCount, 1)', Style1, 'LineWidth', 1)   
        plot(TimeStamps(FramesDoneNumbers), repmat(NegativeBeadDynamics.accelMicronPerSecSqCImaxNorm(2), FrameCount, 1)', Style2, 'LineWidth', 1)
        txt = sprintf('\\mu=%0.5f, CI = [%0.5f, %0.5f] %s/s^2', NegativeBeadDynamics.accelMicronPerSecSqMuHatMaxNorm, NegativeBeadDynamics.accelMicronPerSecSqCImaxNorm, um);  
    else
        plot(TimeStamps(FramesDoneNumbers), repmat(accelMicronPerSecSqMuHatMaxNorm, FrameCount, 1)', Style1, 'LineWidth', 1)   
        plot(TimeStamps(FramesDoneNumbers), repmat(accelMicronPerSecSqCImaxNorm(2), FrameCount, 1)', Style2, 'LineWidth', 1)      
        txt = sprintf('\\mu=%0.5f, CI = [%0.5f, %0.5f] %s/s^2', accelMicronPerSecSqMuHatMaxNorm, accelMicronPerSecSqCImaxNorm, um);     
    end
    text(0.05,1.1, txt, 'Units', 'normalized');  
    xlim([0, TimeStamps(end)]);
    set(findobj(gcf,'type', 'axes'), ...
    'FontSize',11, ...
    'FontName', 'Helvetica', ...
    'LineWidth',1, ...
    'XMinorTick', 'on', ...
    'YMinorTick', 'on', ...
    'TickDir', 'out', ...
    'TickLength', [0.02, 0.03], ...
    'TitleFontSizeMultiplier', 0.9, ...
    'TitleFontWeight', 'bold');     % Make axes bold
    xlabelHandle = xlabel(sprintf('\\rm %s', xLabelTime));
    ylabel(strcat('{\partial^{2}\itu\rm_{max}(\itt\rm)}/{\partial\itt\rm^{2}} [', um, '/s^2]'), 'Interpreter', 'tex');
    pause(1)

%% ___ Plot max X 
    figHandleBeadDynamicsMaxX = figure('visible',showPlot, 'color', 'w');     % added by WIM on 2019-02-07. To show, remove 'visible
    set(figHandleBeadDynamicsMaxX, 'Position', [250, 250, 825, 775])
    pause(0.1)          % give some time so that the figure loads well
    subplot(3,1,1);
    plot(TimeStamps(FramesDoneNumbers), displMicronMaxVecX, 'r.-', 'LineWidth', 1, 'MarkerSize', 1, 'HandleVisibility', 'off')
    hold on
    if strcmpi(NegativeBeadDynamicsStatsChoice, 'Yes')
        plot(TimeStamps(FramesDoneNumbers), repmat(NegativeBeadDynamics.displMicronMuHatMaxX, FrameCount, 1)', Style1, 'LineWidth', 1)   
        plot(TimeStamps(FramesDoneNumbers), repmat(NegativeBeadDynamics.displMicronCImaxX, FrameCount, 1)', Style2, 'LineWidth', 1)
        txt = sprintf('\\mu=%0.5f, CI = [%0.5f, %0.5f] %s', NegativeBeadDynamics.displMicronMuHatMaxX, NegativeBeadDynamics.displMicronCImaxX, um);
    else
        plot(TimeStamps(FramesDoneNumbers), repmat(displMicronMuHatMaxX, FrameCount, 1)', Style1, 'LineWidth', 1)   
        plot(TimeStamps(FramesDoneNumbers), repmat(displMicronCImaxX, FrameCount, 1)', Style2, 'LineWidth', 1)
        txt = sprintf('\\mu=%0.5f, CI = [%0.5f, %0.5f] %s', displMicronMuHatMaxX, displMicronCImaxX, um);
    end
    text(0.05,1.1, txt, 'Units', 'normalized');
    xlim([0, TimeStamps(end)]);
    %     xlim([0, TimeStamps(LastFramePlotted)]);
    title(titleStr1);
    set(findobj(gcf,'type', 'axes'), ...
    'FontSize',11, ...
    'FontName', 'Helvetica', ...
    'LineWidth',1, ...
    'XMinorTick', 'on', ...
    'YMinorTick', 'on', ...
    'TickDir', 'out', ...
    'TickLength', [0.02, 0.03], ...
    'TitleFontSizeMultiplier', 0.9, ...
    'TitleFontWeight', 'bold');     % Make axes bold
    ylabel(strcat('\itu\rm_{max,x*}(\itt\rm) [', um, ']'));
    hold on  
    if strcmpi(NegativeBeadDynamicsStatsChoice, 'Yes')
        legend('Gaussian Fit Meann',strcat(titleStr1_3, ' -ve ctrl'),'Location', 'best', 'Orientation', 'horizontal')
    else
        legend('Gaussian Fit Mean', titleStr1_3, 'Location', 'best', 'Orientation', 'horizontal')
    end
    
    subplot(3,1,2);
    plot(TimeStamps(FramesDoneNumbers), veloMicronPerSecMaxVecX, 'r.-', 'LineWidth', 1, 'MarkerSize', 2, 'HandleVisibility', 'off')
    hold on
    if strcmpi(NegativeBeadDynamicsStatsChoice, 'Yes')
        plot(TimeStamps(FramesDoneNumbers), repmat(NegativeBeadDynamics.veloMicronPerSecMuHatMaxX, FrameCount, 1)', Style1, 'LineWidth', 1)   
        plot(TimeStamps(FramesDoneNumbers), repmat(NegativeBeadDynamics.veloMicronPerSecCImaxX, FrameCount, 1)', Style2, 'LineWidth', 1)
        txt = sprintf('\\mu=%0.5f, CI = [%0.5f, %0.5f] %s/s', NegativeBeadDynamics.veloMicronPerSecMuHatMaxX, NegativeBeadDynamics.veloMicronPerSecCImaxX, um);
    else
        plot(TimeStamps(FramesDoneNumbers), repmat(veloMicronPerSecMuHatMaxX, FrameCount, 1)', Style1, 'LineWidth', 1)   
        plot(TimeStamps(FramesDoneNumbers), repmat(veloMicronPerSecCImaxX, FrameCount, 1)', Style2, 'LineWidth', 1) 
        txt = sprintf('\\mu=%0.5f, CI = [%0.5f, %0.5f] %s/s', veloMicronPerSecMuHatMaxX, veloMicronPerSecCImaxX, um);
    end
    text(0.05,1.1, txt, 'Units', 'normalized');
    xlim([0, TimeStamps(end)]);
    set(findobj(gcf,'type', 'axes'), ...
    'FontSize',11, ...
    'FontName', 'Helvetica', ...
    'LineWidth',1, ...
    'XMinorTick', 'on', ...
    'YMinorTick', 'on', ...
    'TickDir', 'out', ...
    'TickLength', [0.02, 0.03], ...
    'TitleFontSizeMultiplier', 0.9, ...
    'TitleFontWeight', 'bold');     % Make axes bold
    ylabel(strcat('{\partial\itu\rm_{max,x*}(\itt\rm)}/{\partial\itt\rm} [', um, '/s]'), 'Interpreter', 'tex');
    % Flip to Cartesian Coordinates in the Plot (Negative pointing downwards). Add a negative Sign before plot.
    
    subplot(3,1,3);
    plot(TimeStamps(FramesDoneNumbers), accelMicronPerSecSqMaxVecX, 'r.-', 'LineWidth', 1, 'MarkerSize', 2, 'HandleVisibility', 'off')
    hold on
    if strcmpi(NegativeBeadDynamicsStatsChoice, 'Yes')    
        plot(TimeStamps(FramesDoneNumbers), repmat(NegativeBeadDynamics.accelMicronPerSecSqMuHatMaxX, FrameCount, 1)', Style1, 'LineWidth', 1)   
        plot(TimeStamps(FramesDoneNumbers), repmat(NegativeBeadDynamics.accelMicronPerSecSqCImaxX, FrameCount, 1)', Style2, 'LineWidth', 1)
        txt = sprintf('\\mu=%0.5f, CI = [%0.5f, %0.5f] %s/s^2', NegativeBeadDynamics.accelMicronPerSecSqMuHatMaxX, NegativeBeadDynamics.accelMicronPerSecSqCImaxX, um);
    else
        plot(TimeStamps(FramesDoneNumbers), repmat(accelMicronPerSecSqMuHatMaxX, FrameCount, 1)', Style1, 'LineWidth', 1)   
        plot(TimeStamps(FramesDoneNumbers), repmat(accelMicronPerSecSqCImaxX, FrameCount, 1)', Style2, 'LineWidth', 1)
        txt = sprintf('\\mu=%0.5f, CI = [%0.5f, %0.5f] %s/s^2', accelMicronPerSecSqMuHatMaxX, accelMicronPerSecSqCImaxX, um);
    end
    text(0.05,1.1, txt, 'Units', 'normalized');
    xlim([0, TimeStamps(end)]);
    set(findobj(gcf,'type', 'axes'), ...
    'FontSize',11, ...
    'FontName', 'Helvetica', ...
    'LineWidth',1, ...
    'XMinorTick', 'on', ...
    'YMinorTick', 'on', ...
    'TickDir', 'out', ...
    'TickLength', [0.02, 0.03], ...
    'TitleFontSizeMultiplier', 0.9, ...
    'TitleFontWeight', 'bold');     % Make axes bold
    xlabelHandle = xlabel(sprintf('\\rm %s', xLabelTime));
    ylabel(strcat('{\partial^{2}\itu\rm_{max,x*}(\itt\rm)}/{\partial\itt\rm^{2}} [', um, '/s^2]'), 'Interpreter', 'tex');
    pause(1)
  
%% ___ Plot max Y 
    figHandleBeadDynamicsMaxY = figure('visible',showPlot, 'color', 'w');     % added by WIM on 2019-02-07. To show, remove 'visible
    set(figHandleBeadDynamicsMaxY, 'Position', [250, 250, 825, 775])
    pause(0.1)          % give some time so that the figure loads well
    subplot(3,1,1);
    plot(TimeStamps(FramesDoneNumbers), displMicronMaxVecY, 'r.-', 'LineWidth', 1, 'MarkerSize', 1, 'HandleVisibility', 'off')
    hold on
    if strcmpi(NegativeBeadDynamicsStatsChoice, 'Yes')
        plot(TimeStamps(FramesDoneNumbers), repmat(NegativeBeadDynamics.displMicronMuHatMaxY, FrameCount, 1)', Style1, 'LineWidth', 1)   
        plot(TimeStamps(FramesDoneNumbers), repmat(NegativeBeadDynamics.displMicronCImaxY, FrameCount, 1)', Style2, 'LineWidth', 1)
        txt = sprintf('\\mu=%0.5f, CI = [%0.5f, %0.5f] %s', NegativeBeadDynamics.displMicronMuHatMaxY, NegativeBeadDynamics.displMicronCImaxY, um);        
    else
        plot(TimeStamps(FramesDoneNumbers), repmat(displMicronMuHatMaxY, FrameCount, 1)', Style1, 'LineWidth', 1)   
        plot(TimeStamps(FramesDoneNumbers), repmat(displMicronCImaxY, FrameCount, 1)', Style2, 'LineWidth', 1)
        txt = sprintf('\\mu=%0.5f, CI = [%0.5f, %0.5f] %s', displMicronMuHatMaxY, displMicronCImaxY, um);        
    end
    text(0.05,1.1, txt, 'Units', 'normalized');
    xlim([0, TimeStamps(end)]);
    %     xlim([0, TimeStamps(LastFramePlotted)]);
    title(titleStr1);
    set(findobj(gcf,'type', 'axes'), ...
    'FontSize',11, ...
    'FontName', 'Helvetica', ...
    'LineWidth',1, ...
    'XMinorTick', 'on', ...
    'YMinorTick', 'on', ...
    'TickDir', 'out', ...
    'TickLength', [0.02, 0.03], ...
    'TitleFontSizeMultiplier', 0.9, ...
    'TitleFontWeight', 'bold');     % Make axes bold
    ylabel(strcat('\itu\rm_{max,y*}(\itt\rm) [', um, ']'));
    hold on  
    if strcmpi(NegativeBeadDynamicsStatsChoice, 'Yes')
        legend('Gaussian Fit Mean',strcat(titleStr1_3, ' -ve ctrl'),'Location', 'best', 'Orientation', 'horizontal')
    else
        legend('Gaussian Fit Mean', titleStr1_3, 'Location', 'best', 'Orientation', 'horizontal')
    end
    
    subplot(3,1,2);
    plot(TimeStamps(FramesDoneNumbers), veloMicronPerSecMaxVecY, 'r.-', 'LineWidth', 1, 'MarkerSize', 2, 'HandleVisibility', 'off')
    hold on
    if strcmpi(NegativeBeadDynamicsStatsChoice, 'Yes')
        plot(TimeStamps(FramesDoneNumbers), repmat(NegativeBeadDynamics.veloMicronPerSecMuHatMaxY, FrameCount, 1)', Style1, 'LineWidth', 1)   
        plot(TimeStamps(FramesDoneNumbers), repmat(NegativeBeadDynamics.veloMicronPerSecCImaxY, FrameCount, 1)', Style2, 'LineWidth', 1)
        txt = sprintf('\\mu=%0.5f, CI = [%0.5f, %0.5f] %s/s', NegativeBeadDynamics.veloMicronPerSecMuHatMaxY, NegativeBeadDynamics.veloMicronPerSecCImaxY, um);
    else
        plot(TimeStamps(FramesDoneNumbers), repmat(veloMicronPerSecMuHatMaxY, FrameCount, 1)', Style1, 'LineWidth', 1)   
        plot(TimeStamps(FramesDoneNumbers), repmat(veloMicronPerSecCImaxY, FrameCount, 1)', Style2, 'LineWidth', 1)    
        txt = sprintf('\\mu=%0.5f, CI = [%0.5f, %0.5f] %s/s', veloMicronPerSecMuHatMaxY, veloMicronPerSecCImaxY, um);
    end
    text(0.05,1.1, txt, 'Units', 'normalized');
    xlim([0, TimeStamps(end)]);
    set(findobj(gcf,'type', 'axes'), ...
    'FontSize',11, ...
    'FontName', 'Helvetica', ...
    'LineWidth',1, ...
    'XMinorTick', 'on', ...
    'YMinorTick', 'on', ...
    'TickDir', 'out', ...
    'TickLength', [0.02, 0.03], ...
    'TitleFontSizeMultiplier', 0.9, ...
    'TitleFontWeight', 'bold');     % Make axes bold
    ylabel(strcat('{\partial\itu\rm_{max,y*}(\itt\rm)}/{\partial\itt\rm} [', um, '/s]'), 'Interpreter', 'tex');
    % Flip to Cartesian Coordinates in the Plot (Negative pointing downwards). Add a negative Sign before plot.
    
    subplot(3,1,3);
    plot(TimeStamps(FramesDoneNumbers), accelMicronPerSecSqMaxVecY, 'r.-', 'LineWidth', 1, 'MarkerSize', 2, 'HandleVisibility', 'off')
    hold on
    if strcmpi(NegativeBeadDynamicsStatsChoice, 'Yes')    
        plot(TimeStamps(FramesDoneNumbers), repmat(NegativeBeadDynamics.accelMicronPerSecSqMuHatMaxY, FrameCount, 1)', Style1, 'LineWidth', 1)   
        plot(TimeStamps(FramesDoneNumbers), repmat(NegativeBeadDynamics.accelMicronPerSecSqCImaxY, FrameCount, 1)', Style2, 'LineWidth', 1)
        txt = sprintf('\\mu=%0.5f, CI = [%0.5f, %0.5f] %s/s^2', NegativeBeadDynamics.accelMicronPerSecSqMuHatMaxY, NegativeBeadDynamics.accelMicronPerSecSqCImaxY, um);
    else
        plot(TimeStamps(FramesDoneNumbers), repmat(accelMicronPerSecSqMuHatMaxY, FrameCount, 1)', Style1, 'LineWidth', 1)   
        plot(TimeStamps(FramesDoneNumbers), repmat(accelMicronPerSecSqCImaxY, FrameCount, 1)', Style2, 'LineWidth', 1)
        txt = sprintf('\\mu=%0.5f, CI = [%0.5f, %0.5f] %s/s^2', accelMicronPerSecSqMuHatMaxY, accelMicronPerSecSqCImaxY, um);
    end
    text(0.05,1.1, txt, 'Units', 'normalized');
    xlim([0, TimeStamps(end)]);
    set(findobj(gcf,'type', 'axes'), ...
    'FontSize',11, ...
    'FontName', 'Helvetica', ...
    'LineWidth',1, ...
    'XMinorTick', 'on', ...
    'YMinorTick', 'on', ...
    'TickDir', 'out', ...
    'TickLength', [0.02, 0.03], ...
    'TitleFontSizeMultiplier', 0.9, ...
    'TitleFontWeight', 'bold');     % Make axes bold
    xlabelHandle = xlabel(sprintf('\\rm %s', xLabelTime));
    ylabel(strcat('{\partial^{2}\itu\rm_{max,y*}(\itt\rm)}/{\partial\itt\rm^{2}} [', um, '/s^2]'), 'Interpreter', 'tex');
    pause(1)

    %%
%     disp('**___Adjust Figures as needed then click any key to save the images___**')
%     commandwindow;
%     pause('on');
%     pause

    disp('**___to continue, type "dbcont" or press "F5", or click "Continue" under "Editor" Menu___**')
    commandwindow;
    keyboard
    
    %% --------------
    for ii = 1:numel(PlotChoice)
        tmpPlotChoice =  PlotChoice{ii};
        switch tmpPlotChoice
            case 'PNG'
                BeadDynamicsMaxPNGNorm = fullfile(NetDisplacementPath, 'Bead Dynamics Max Norm.png');
                fprintf('Bead Dynamics (Max - Norm) *.png File Name is: \n\t %s\n', BeadDynamicsMaxPNGNorm);
            case 'FIG'                 
                BeadDynamicsMaxFIGNorm = fullfile(NetDisplacementPath, 'Bead Dynamics Max Norm.fig');
                fprintf('Bead Dynamics (Max - Norm) *.fig File Name is: \n\t %s\n', BeadDynamicsMaxFIGNorm);
            case 'EPS'
                BeadDynamicsMaxEPSNorm = fullfile(NetDisplacementPath, 'Bead Dynamics Max Norm.eps');
                fprintf('Bead Dynamics (Max - Norm) *.eps File Name is: \n\t %s\n', BeadDynamicsMaxEPSNorm);
        otherwise
            return
        end
    end    
    for ii = 1:numel(PlotChoice)
        tmpPlotChoice =  PlotChoice{ii};
        switch tmpPlotChoice
            case 'PNG'
                BeadDynamicsMaxPNGX = fullfile(NetDisplacementPath, 'Bead Dynamics Max X.png');
                fprintf('Bead Dynamics (Max - X) *.png File Name is: \n\t %s\n', BeadDynamicsMaxPNGX);
            case 'FIG'                 
                BeadDynamicsMaxFIGX = fullfile(NetDisplacementPath, 'Bead Dynamics Max X.fig');
                fprintf('Bead Dynamics (Max - X) *.fig File Name is: \n\t %s\n', BeadDynamicsMaxFIGX);
            case 'EPS'
                BeadDynamicsMaxEPSX = fullfile(NetDisplacementPath, 'Bead Dynamics Max X.eps');
                fprintf('Bead Dynamics (Max - X) *.eps File Name is: \n\t %s\n', BeadDynamicsMaxEPSX);
        otherwise
            return
        end
    end    
    for ii = 1:numel(PlotChoice)
        tmpPlotChoice =  PlotChoice{ii};
        switch tmpPlotChoice
            case 'PNG'
                BeadDynamicsMaxPNGY = fullfile(NetDisplacementPath, 'Bead Dynamics Max Y.png');
                fprintf('Bead Dynamics (Max - Y) *.png File Name is: \n\t %s\n', BeadDynamicsMaxPNGY);
            case 'FIG'                 
                BeadDynamicsMaxFIGY = fullfile(NetDisplacementPath, 'Bead Dynamics Max Y.fig');
                fprintf('Bead Dynamics (Max - Y) *.fig File Name is: \n\t %s\n', BeadDynamicsMaxFIGY);
            case 'EPS'
                BeadDynamicsMaxEPSY = fullfile(NetDisplacementPath, 'Bead Dynamics Max Y.eps');
                fprintf('Bead Dynamics (Max - Y) *.eps File Name is: \n\t %s\n', BeadDynamicsMaxEPSY);
        otherwise
            return
        end
    end   
    %% Analysis Path case
    if ~isempty(AnalysisPath)
        for ii = 1:numel(PlotChoice)
            tmpPlotChoice =  PlotChoice{ii};
            switch tmpPlotChoice
                case 'PNG'
                    BeadDynamicsMaxPNGNorm = fullfile(AnalysisPath, '08 Bead Dynamics Max Norm.png');
                    fprintf('08 Bead Dynamics (Max - Norm) *.png File Name is: \n\t %s\n', BeadDynamicsMaxPNGNorm);
                case 'FIG'                 
                    BeadDynamicsMaxFIGNorm = fullfile(AnalysisPath, '08 Bead Dynamics Max Norm.fig');
                    fprintf('08 Bead Dynamics (Max - Norm) *.fig File Name is: \n\t %s\n', BeadDynamicsMaxFIGNorm);
                case 'EPS'
                    BeadDynamicsMaxEPSNorm = fullfile(AnalysisPath, '08 Bead Dynamics Max Norm.eps');
                    fprintf('08 Bead Dynamics (Max - Norm) *.eps File Name is: \n\t %s\n', BeadDynamicsMaxEPSNorm);
            otherwise
                return
            end
        end    
        for ii = 1:numel(PlotChoice)
            tmpPlotChoice =  PlotChoice{ii};
            switch tmpPlotChoice
                case 'PNG'
                    BeadDynamicsMaxPNGX = fullfile(AnalysisPath, '08 Bead Dynamics Max X.png');
                    fprintf('08 Bead Dynamics (Max - X) *.png File Name is: \n\t %s\n', BeadDynamicsMaxPNGX);
                case 'FIG'                 
                    BeadDynamicsMaxFIGX = fullfile(AnalysisPath, '08 Bead Dynamics Max X.fig');
                    fprintf('08 Bead Dynamics (Max - X) *.fig File Name is: \n\t %s\n', BeadDynamicsMaxFIGX);
                case 'EPS'
                    BeadDynamicsMaxEPSX = fullfile(AnalysisPath, '08 Bead Dynamics Max X.eps');
                    fprintf('08 Bead Dynamics (Max - X) *.eps File Name is: \n\t %s\n', BeadDynamicsMaxEPSX);
            otherwise
                return
            end
        end    
        for ii = 1:numel(PlotChoice)
            tmpPlotChoice =  PlotChoice{ii};
            switch tmpPlotChoice
                case 'PNG'
                    BeadDynamicsMaxPNGY = fullfile(AnalysisPath, '08 Bead Dynamics Max Y.png');
                    fprintf('08 Bead Dynamics (Max - Y) *.png File Name is: \n\t %s\n', BeadDynamicsMaxPNGY);
                case 'FIG'                 
                    BeadDynamicsMaxFIGY = fullfile(AnalysisPath, '08 Bead Dynamics Max Y.fig');
                    fprintf('08 Bead Dynamics (Max - Y) *.fig File Name is: \n\t %s\n', BeadDynamicsMaxFIGY);
                case 'EPS'
                    BeadDynamicsMaxEPSY = fullfile(AnalysisPath, '08 Bead Dynamics Max Y.eps');
                    fprintf('08 Bead Dynamics (Max - Y) *.eps File Name is: \n\t %s\n', BeadDynamicsMaxEPSY);
            otherwise
                return
            end
        end   
    end
    %% Saving the output files to the desired file format.       
    for ii = 1:numel(PlotChoice)
        tmpPlotChoice =  PlotChoice{ii};
        switch tmpPlotChoice                
            case 'PNG'
                saveas(figHandleBeadDynamicsMaxNorm, BeadDynamicsMaxPNGNorm, 'png')                
                if  strcmpi(AnalysisFolderChoice , 'Yes')
                    saveas(figHandleBeadDynamicsMaxNorm, BeadDynamicsMaxPNGNorm, 'png')            
                end                

            case 'FIG'
                hgsave(figHandleBeadDynamicsMaxNorm,  BeadDynamicsMaxFIGNorm,'-v7.3')                
                if  strcmpi(AnalysisFolderChoice , 'Yes')
                    hgsave(figHandleBeadDynamicsMaxNorm, BeadDynamicsMaxFIGNorm,'-v7.3')                             
                end                
                
            case 'EPS'
                print(figHandleBeadDynamicsMaxNorm, BeadDynamicsMaxEPSNorm,'-depsc')                  
                if  strcmpi(AnalysisFolderChoice , 'Yes')
                    print(figHandleBeadDynamicsMaxNorm, BeadDynamicsMaxEPSNorm,'-depsc')          
                end
            otherwise
                 return
        end       
    end
    for ii = 1:numel(PlotChoice)
        tmpPlotChoice =  PlotChoice{ii};
        switch tmpPlotChoice                
            case 'PNG'
                saveas(figHandleBeadDynamicsMaxX, BeadDynamicsMaxPNGX, 'png')                
                if  strcmpi(AnalysisFolderChoice , 'Yes')
                    saveas(figHandleBeadDynamicsMaxX, BeadDynamicsMaxPNGX, 'png')            
                end                

            case 'FIG'
                hgsave(figHandleBeadDynamicsMaxX,  BeadDynamicsMaxFIGX,'-v7.3')                
                if  strcmpi(AnalysisFolderChoice , 'Yes') 
                    hgsave(figHandleBeadDynamicsMaxX, BeadDynamicsMaxFIGX,'-v7.3')                             
                end                
                
            case 'EPS'
                print(figHandleBeadDynamicsMaxX, BeadDynamicsMaxEPSX,'-depsc')                  
                if  strcmpi(AnalysisFolderChoice , 'Yes')
                    print(figHandleBeadDynamicsMaxX, BeadDynamicsMaxEPSX,'-depsc')          
                end
            otherwise
                 return
        end       
    end    
    for ii = 1:numel(PlotChoice)
        tmpPlotChoice =  PlotChoice{ii};
        switch tmpPlotChoice                
            case 'PNG'
                saveas(figHandleBeadDynamicsMaxY, BeadDynamicsMaxPNGY, 'png')                
                if  strcmpi(AnalysisFolderChoice , 'Yes')
                    saveas(figHandleBeadDynamicsMaxY, BeadDynamicsMaxPNGY, 'png')            
                end                

            case 'FIG'
                hgsave(figHandleBeadDynamicsMaxY,  BeadDynamicsMaxFIGY,'-v7.3')                
                if  strcmpi(AnalysisFolderChoice , 'Yes') 
                    hgsave(figHandleBeadDynamicsMaxY, BeadDynamicsMaxFIGY,'-v7.3')                             
                end                
                
            case 'EPS'
                print(figHandleBeadDynamicsMaxY, BeadDynamicsMaxEPSY,'-depsc')                  
                if  strcmpi(AnalysisFolderChoice , 'Yes')
                    print(figHandleBeadDynamicsMaxY, BeadDynamicsMaxEPSY,'-depsc')          
                end
            otherwise
                 return
        end       
    end
    
    close all
    clear figHandle*
    clear BeadDyn*
    clear displField
    clear xlabelHandle
    
     %% save the entire workspace
    save(NetDisplacementNameMAT)
    disp('Generating Bead Dynamics Plots Complete!')
    