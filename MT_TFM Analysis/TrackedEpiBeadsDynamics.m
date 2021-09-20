%{
    v.2020-08-03..04 by Waddah Moghram, PhD Candidate in Biomedical Engineering at the Unviersity of iowa.
        1. Fixed problem where the acceleration and velocities were not in terms of microns but in terms of pixels
        2. Replaced Normal Distribution with Raleigh Distribution to find the mean and limits of the "norms" or "resultants" of displacement, 
            velocity and acceleration.
        3. Made sure the y-axis values do not flip signs. Our Cartesian coordinates are x* and y*
    v.2020-07-19 by Waddah Moghram, PhD Candidate in Biomedical Engineering at the Unviersity of iowa.
        1. Made sure the maximum bead is included in the decimated frames.
    v.2020-07-15 by Waddah Moghram
        1. Added Displacement Statistics
    v.2020-06-17..18 by Waddah Moghram, PhD Candidate in Biomedical Engineering at the Unviersity of iowa.
        1. Added Statistical information for all beads. 
        2. Added plots for x-, and  y-components and two-tailed statistical tests for the data points.
    v.2020-06-07 by Waddah Moghram, 
        1. Fixed problem with FirstFrame and LastFrame if given as inputs.
    v.2020-05-21..26 by Waddah Moghram
        based on PlotBeadEpiMaxDisplacement_Velocity v.2019-10-14        
%} 

function [MD, displFieldMicronMax, veloFieldMicronPerSecMax, accelFieldMicronPerSecSqMax, FirstFrame, LastFrame, movieFilePath, displacementFilePath, AnalysisPath, NetDisplacementPath] = TrackedEpiBeadsDynamics(MD, displField, ...
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
    end    
    
    %% -----------------------------------------------------------------------------------------------
    ProcessTag = '';
    displacementFilePath = '';
    if ~exist('movieFilePath', 'var')
        movieFilePath = pwd;
    end
    if ~exist('displField','var'), displField = []; end
    % no displacement field is given
    % find the displacement process tag or the correction process tag
    if nargin < 2 || isempty(displField)
        try 
            ProcessTag =  MD.findProcessTag('DisplacementFieldCorrectionProcess').tag_;
        catch
            try 
                ProcessTag =  MD.findProcessTag('DisplacementFieldCalculationProcess').tag_;
            catch
                disp('No Completed Displacement Field Calculated!');
                disp('------------------------------------------------------------------------------')
            end
        end
        if exist('ProcessTag', 'var') 
            fprintf('Displacement Process Tag is: %s\n', ProcessTag);
            try
                DisplacementFileFullName = MD.findProcessTag(ProcessTag).outFilePaths_{1};
                if exist(DisplacementFileFullName, 'file')
                    dlgQuestion = sprintf('Do you want to open the displacement field referred to in the movie data file?\n%s\n', ...
                        DisplacementFileFullName);
                    dlgTitle = 'Open displacement field?';
                    OpenDisplacementChoice = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No', 'Yes');
                    switch OpenDisplacementChoice
                        case 'Yes'
                            [displacementFilePath, ~, ~] = fileparts(DisplacementFileFullName);
                            try
                                load(DisplacementFileFullName, 'displField');   
                                fprintf('Displacement Field (displField) File is: \n\t %s\n', DisplacementFileFullName);
                                disp('Original displacement field loaded!!')
                                disp('------------------------------------------------------------------------------')
                            catch
                                errordlg('Could not open the displacement field file.');
                                return
                            end
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
            if isempty(DisplacementFileFullName)             
                    TFMPackageFiles = fullfile(movieFilePath,'TFMPackage','*.mat');
                    [displacementFileName, displacementFilePath] = uigetfile(TFMPackageFiles, 'Open the displacement field "displField.mat" under displacementField or backups');
                    DisplacementFileFullName = fullfile(displacementFilePath, displacementFileName);
                    try
                        load(DisplacementFileFullName, 'displField')
                        fprintf('Displacement Field (displField) File is: \n\t %s\n', DisplacementFileFullName);
                        disp('Displacement field loaded.');
                        disp('------------------------------------------------------------------------------')
                    catch
                        errordlg('Could not open the displacement field file.');
                        return
                    end
            end                     
        end
    end
    
    FramesDoneBoolean = arrayfun(@(x) ~isempty(x.vec), displField);
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
        NetDisplacementPath = uigetdir(displacementFilePath,'Choose the directory where you want to store Bead dynamics Output.');
        if NetDisplacementPath == 0  % Cancel was selected
            clear NetDisplacementPath;
        elseif ~exist(NetDisplacementPath,'dir')
            mkdir(NetDisplacementPath);
        end
        
        fprintf('NetDisplacementEPI Path is: \n\t %s\n', NetDisplacementPath);
        disp('------------------------------------------------------------------------------')
    end    
    
    %% -----------------------------------------------------------------------------------------------
    if ~exist('ScaleMicronPerPixel', 'var') || nargin < 6
        [ScaleMicronPerPixel, ~, MagnificationTimes] = MagnificationScalesMicronPerPixel();    
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
                AnalysisPath = uigetdir(movieFilePath,'Choose the analysis directory where bead dynamics output will be saved.');     
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
%     try 
%         minDisplacement  = MD.findProcessTag(ProcessTag).tMapLimits_(1);
%         maxDisplacement = MD.findProcessTag(ProcessTag).tMapLimits_(2);            
%     catch
        disp('Evaluating the maximum and minimum displacement value in progress....')
        reverseString = ''; 
        for CurrentFrame = FramesDoneNumbers
            ProgressMsg = sprintf('\nEvaluating Frame #%d/%d...\n', CurrentFrame, FramesDoneNumbers(end));
            fprintf([reverseString, ProgressMsg]);
            reverseString = repmat(sprintf('\b'), 1, length(ProgressMsg));
            if useGPU
                FieldVec = gpuArray(displField(CurrentFrame).vec);
            else
                FieldVec = displField(CurrentFrame).vec;
            end          
            FieldVecNorm = (FieldVec(:,1).^2+FieldVec(:,2).^2).^0.5;
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
    
    %%
    displFieldNetMaxPointInFrame = -1;
    reverseString = '';
    for CurrentFrame = FramesDoneNumbers
        ProgressMsg = sprintf('Searching Frame #%d/(%d-%d)...\n',CurrentFrame, FramesDoneNumbers(1),FramesDoneNumbers(end));
        fprintf([reverseString, ProgressMsg]);
        reverseString = repmat(sprintf('\b'), 1, length(ProgressMsg));
        
        NetdisplFieldAllPointsInFrame = vecnorm(displField(CurrentFrame).vec(:,1:2),2,2);
        [tmpMaxDisplFieldNetInFrame,tmpMaxDisplFieldInFrameIndex] =  max(NetdisplFieldAllPointsInFrame);          % maximum item in a column
        displField(CurrentFrame).vec(:,3) = vecnorm(displField(CurrentFrame).vec(:,1:2), 2,2);                
        
        if tmpMaxDisplFieldNetInFrame > displFieldNetMaxPointInFrame
            displFieldNetMaxPointInFrame(CurrentFrame) = tmpMaxDisplFieldNetInFrame;
            displFieldMaxPosFrame = displField(CurrentFrame).pos; 
            displFieldMaxVecFrame = displField(CurrentFrame).vec;        
            displFieldMaxVecFrame(:,3) = displField(CurrentFrame).vec(:,3);
            
            displFieldMaxDisplPixelsNet = tmpMaxDisplFieldNetInFrame;                        
            MaxDisplFieldIndex = tmpMaxDisplFieldInFrameIndex;
            MaxDisplPixelsXYnet =  displFieldMaxVecFrame(MaxDisplFieldIndex, :);
            MaxDisplFrameNumber = CurrentFrame;
            MaxPosPixelsXYnet = displFieldMaxPosFrame(MaxDisplFieldIndex, :);
        end 
    end
    
    MaxDisplMicronsXYnet =  MaxDisplPixelsXYnet * ScaleMicronPerPixel;
    fprintf('Maximum displacement = %0.4g pixels at ', displFieldMaxDisplPixelsNet);
    fprintf('[x,y] = [%g, %g] pixels in Frame #%d, Point Index #%d \n', MaxPosPixelsXYnet, MaxDisplFrameNumber, MaxDisplFieldIndex)
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
    displFieldMicron = struct('pos', displField(FirstFrame).pos, 'vec',  NaN(totalPoints, 3));
    displFieldMicronMax = struct('pos', displField(FirstFrame).pos(MaxDisplFieldIndex,:), 'vec',  NaN(1, 3));
    
    displMicronVecX = nan([numel(FramesDoneNumbers), totalPoints]);
    displMicronVecY = nan([numel(FramesDoneNumbers), totalPoints]);
    displMicronVecNorm = nan([numel(FramesDoneNumbers), totalPoints]);
    displMicronMaxVecX = nan([numel(FramesDoneNumbers), 1]);
    displMicronMaxVecY = nan([numel(FramesDoneNumbers), 1]);
    displMicronMaxVecNorm = nan([numel(FramesDoneNumbers), 1]);

    for CurrentFrame = FramesDoneNumbers        
        displFieldMicron(CurrentFrame).pos = displField(CurrentFrame).pos;        
        displFieldMicron(CurrentFrame).vec = displField(CurrentFrame).vec .* ScaleMicronPerPixel; 
        
        displFieldMicronMax(CurrentFrame).pos = displFieldMicron(CurrentFrame).pos(MaxDisplFieldIndex,:);
        displFieldMicronMax(CurrentFrame).vec = displFieldMicron(CurrentFrame).vec(MaxDisplFieldIndex,:);       

        displMicronVecX(CurrentFrame, :) = displFieldMicron(CurrentFrame).vec(:,1);
        displMicronVecY(CurrentFrame, :) = displFieldMicron(CurrentFrame).vec(:,2);
        displMicronVecNorm(CurrentFrame, :) = displFieldMicron(CurrentFrame).vec(:,3);
        
        displMicronMaxVecX(CurrentFrame) = displFieldMicronMax(CurrentFrame).vec(:,1);
        displMicronMaxVecY(CurrentFrame) = displFieldMicronMax(CurrentFrame).vec(:,2);
        displMicronMaxVecNorm(CurrentFrame) = displFieldMicronMax(CurrentFrame).vec(:,3);
    end
    
    %% Backward derivative for all frames
%     VelocityField = displFieldMicron(FramesDoneNumbers);
    veloFieldMicronPerSec = struct('pos', displField(FirstFrame).pos, 'vec',  NaN(totalPoints, 3));
    veloFieldMicronPerSecMax =  struct('pos', displField(FirstFrame).pos(MaxDisplFieldIndex,:), 'vec',  NaN(1, 3));
    
    accelFieldMicronPerSecSq = struct('pos', displField(FirstFrame).pos, 'vec',  NaN(totalPoints, 3));
    accelFieldMicronPerSecSqMax =  struct('pos', displField(FirstFrame).pos(MaxDisplFieldIndex,:), 'vec',  NaN(1, 3));

    veloMicronPerSecVecX = nan([numel(FramesDoneNumbers), totalPoints]);
    veloMicronPerSecVecY = nan([numel(FramesDoneNumbers), totalPoints]);
    veloMicronPerSecVecNorm = nan([numel(FramesDoneNumbers), totalPoints]);
    veloMicronPerSecMaxVecX = nan([numel(FramesDoneNumbers), 1]);
    veloMicronPerSecMaxVecY = nan([numel(FramesDoneNumbers), 1]);
    veloMicronPerSecMaxVecNorm = nan([numel(FramesDoneNumbers), 1]);    
    
    accelMicronPerSecSqVecX = nan([numel(FramesDoneNumbers), totalPoints]);
    accelMicronPerSecSqVecY = nan([numel(FramesDoneNumbers), totalPoints]);
    accelMicronPerSecSqVecNorm = nan([numel(FramesDoneNumbers), totalPoints]);
    accelMicronPerSecSqMaxVecX = nan([numel(FramesDoneNumbers), 1]);
    accelMicronPerSecSqMaxVecY = nan([numel(FramesDoneNumbers), 1]);
    accelMicronPerSecSqMaxVecNorm = nan([numel(FramesDoneNumbers), 1]);
    
    for CurrentFrame = FramesDoneNumbers
        veloFieldMicronPerSec(CurrentFrame).pos = displField(CurrentFrame).pos;
        accelFieldMicronPerSecSq(CurrentFrame).pos = displField(CurrentFrame).pos;
        
        if CurrentFrame > FramesDoneNumbers(1)
            veloFieldMicronPerSec(CurrentFrame).vec(:,1:2) = (displFieldMicron(CurrentFrame).vec(:,1:2) - displFieldMicron(CurrentFrame - 1).vec(:,1:2)) / (TimeStamps(CurrentFrame) - TimeStamps(CurrentFrame - 1));      
            if CurrentFrame > FramesDoneNumbers(2)               
                accelFieldMicronPerSecSq(CurrentFrame).vec(:,1:2) = (veloFieldMicronPerSec(CurrentFrame).vec(:,1:2) - veloFieldMicronPerSec(CurrentFrame - 1).vec(:,1:2)) / (TimeStamps(CurrentFrame) - TimeStamps(CurrentFrame - 1));
            else
                accelFieldMicronPerSecSq(CurrentFrame).vec = accelFieldMicronPerSecSq(FramesDoneNumbers(1)).vec;
            end 
        end
        
        veloFieldMicronPerSec(CurrentFrame).vec(:,3) = vecnorm(veloFieldMicronPerSec(CurrentFrame).vec(:,1:2), 2, 2);
        
        veloFieldMicronPerSecMax(CurrentFrame).pos =  displField(CurrentFrame).pos;
        veloFieldMicronPerSecMax(CurrentFrame).vec = veloFieldMicronPerSec(CurrentFrame).vec(MaxDisplFieldIndex,:);
        
        accelFieldMicronPerSecSq(CurrentFrame).vec(:,3) = vecnorm(accelFieldMicronPerSecSq(CurrentFrame).vec(:,1:2), 2, 2); 
        
        accelFieldMicronPerSecSqMax(CurrentFrame).pos =  displField(CurrentFrame).pos;
        accelFieldMicronPerSecSqMax(CurrentFrame).vec =  accelFieldMicronPerSecSq(CurrentFrame).vec(MaxDisplFieldIndex,:);

        veloMicronPerSecVecX(CurrentFrame, :) = veloFieldMicronPerSec(CurrentFrame).vec(:, 1);
        veloMicronPerSecVecY(CurrentFrame, :) = veloFieldMicronPerSec(CurrentFrame).vec(:, 2);
        veloMicronPerSecVecNorm(CurrentFrame, :) = veloFieldMicronPerSec(CurrentFrame).vec(:, 3);
        
        veloMicronPerSecMaxVecX(CurrentFrame) = veloFieldMicronPerSecMax(CurrentFrame).vec(:,1);
        veloMicronPerSecMaxVecY(CurrentFrame) = veloFieldMicronPerSecMax(CurrentFrame).vec(:,2);
        veloMicronPerSecMaxVecNorm(CurrentFrame) = veloFieldMicronPerSecMax(CurrentFrame).vec(:,3);          
        
        accelMicronPerSecSqVecX(CurrentFrame, :) = accelFieldMicronPerSecSq(CurrentFrame).vec(:,1);
        accelMicronPerSecSqVecY(CurrentFrame, :) = accelFieldMicronPerSecSq(CurrentFrame).vec(:,2);
        accelMicronPerSecSqVecNorm(CurrentFrame, :) = accelFieldMicronPerSecSq(CurrentFrame).vec(:,3);  

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
    
    [displBparamMuHatMaxNorm, displBparamCImaxNorm] = raylfit(rmmissing(displMicronMaxVecNorm'), 0.05);         % 95% CI for the B-parameter
    displMicronCImaxNorm(1) = 0;
    displMicronCImaxNorm(2) = raylinv(1 - StatAlpha, displBparamMuHatMaxNorm);   % one-tailed test    
    [displMicronMuHatMaxNorm, displMicronVarHatMaxNorm] = raylstat(displBparamMuHatMaxNorm);
    displMicronSigmaHatMaxNorm = sqrt(displMicronVarHatMaxNorm);    
    [displMicronMuCIMaxNorm, displMicronVarCIMaxNorm] = raylstat(displBparamCImaxNorm);
    displMicronSigmaCImaxNorm = sqrt(displMicronVarCIMaxNorm);

%----- all beads
    EmptyArray = nan(size(FramesDoneNumbers));
    displMicronMuHatAllX = EmptyArray';
    displMicronSigmaHatAllX = EmptyArray';
    displMicronMuCIallX = [EmptyArray', EmptyArray'];
    displMicronSigmaCIallX = [EmptyArray', EmptyArray'];
    displMicronCIallX  = [EmptyArray', EmptyArray'];
    
    EmptyArray = nan(size(FramesDoneNumbers));
    displMicronMuHatAllY = EmptyArray';
    displMicronSigmaHatAllY = EmptyArray';
    displMicronMuCIallY = [EmptyArray', EmptyArray'];
    displMicronSigmaCIallY = [EmptyArray', EmptyArray'];
    displMicronCIallY  = [EmptyArray', EmptyArray'];
    
    EmptyArray = nan(size(FramesDoneNumbers));
    displMicronBparamMuHatAllNorm =  EmptyArray';
    displMicronMuHatAllNorm = EmptyArray';
    displMicronSigmaHatAllNorm = EmptyArray';
    displMicronBparamCIAllNorm = [EmptyArray', EmptyArray'];
    displMicronVarHatAllNorm = EmptyArray;
    displMicronMuCIallNorm = [EmptyArray', EmptyArray'];
    displMicronVarCIallNorm = [EmptyArray', EmptyArray'];
    displMicronSigmaCIallNorm = [EmptyArray', EmptyArray'];
    displMicronCIallNorm  = [EmptyArray', EmptyArray'];
        
    for CurrentFrame = FramesDoneNumbers
        [displMicronMuHatAllX(CurrentFrame),displMicronSigmaHatAllX(CurrentFrame),displMicronMuCIallX(CurrentFrame, :),displMicronSigmaCIallX(CurrentFrame,:)] = normfit(rmmissing(displMicronVecX(CurrentFrame,:)), StatAlpha);
        displMicronCIallX(CurrentFrame, :) = norminv([StatAlpha/2, 1-StatAlpha/2], displMicronMuHatAllX(CurrentFrame), displMicronSigmaHatAllX(CurrentFrame));
     
        [displMicronMuHatAllY(CurrentFrame),displMicronSigmaHatAllY(CurrentFrame), displMicronMuCIallY(CurrentFrame, :), displMicronSigmaCIallY(CurrentFrame, :)] = normfit(rmmissing(displMicronVecY(CurrentFrame,:)), StatAlpha);
        displMicronCIallY(CurrentFrame, :) = norminv([StatAlpha/2, 1-StatAlpha/2], displMicronMuHatAllY(CurrentFrame), displMicronSigmaHatAllY(CurrentFrame));
    
        [displMicronBparamMuHatAllNorm(CurrentFrame), displMicronBparamCIAllNorm(CurrentFrame,:)] = raylfit(rmmissing(displMicronVecNorm(CurrentFrame,:)), 0.05);         % 95% CI for the B-parameter
        displMicronCIallNorm(CurrentFrame, 1) = 0;
        displMicronCIallNorm(CurrentFrame, 2) = raylinv(1 - StatAlpha, displMicronBparamMuHatAllNorm(CurrentFrame));   % one-tailed test    
        [displMicronMuHatAllNorm(CurrentFrame), displMicronVarHatAllNorm(CurrentFrame)] = raylstat(displMicronBparamMuHatAllNorm(CurrentFrame));
        displMicronSigmaHatAllNorm(CurrentFrame) = sqrt(displMicronVarHatAllNorm(CurrentFrame));        

        [displMicronMuCIallNorm(CurrentFrame, :), displMicronVarCIallNorm(CurrentFrame, :)] =  raylstat(displMicronBparamCIAllNorm(CurrentFrame,:));
        displMicronSigmaCIallNorm(CurrentFrame, :) = sqrt(displMicronVarCIallNorm(CurrentFrame, :));
    end
    
    displMicronMuHatAllXMean = mean(displMicronMuHatAllX, 'omitnan');
    displMicronCIallXMean = mean(displMicronCIallX, 'omitnan');
   
    displMicronMuHatAllYMean = mean(displMicronMuHatAllY, 'omitnan');
    displMicronCIallYMean = mean(displMicronCIallY, 'omitnan');
    
    displMicronMuHatAllNormMean = mean(displMicronMuHatAllNorm, 'omitnan');
    displMicronCIallNormMean = mean(displMicronCIallNorm, 'omitnan'); 
    
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
    
    [veloBparamMuHatMaxNorm, veloBparamCImaxNorm] = raylfit(rmmissing(veloMicronPerSecMaxVecNorm'), 0.05);         % 95% CI for the B-parameter
    veloMicronPerSecCImaxNorm(1) = 0;
    veloMicronPerSecCImaxNorm(2) = raylinv(1 - StatAlpha, veloBparamMuHatMaxNorm);   % one-tailed test    
    [veloMicronPerSecMuHatMaxNorm, veloMicronPerSecVarHatMaxNorm] = raylstat(veloBparamMuHatMaxNorm);
    veloMicronPerSecSigmaHatMaxNorm = sqrt(veloMicronPerSecVarHatMaxNorm);    
    [veloMicronPerSecMuCIMaxNorm, veloMicronPerSecVarCIMaxNorm] = raylstat(veloBparamCImaxNorm);
    veloMicronPerSecSigmaCImaxNorm = sqrt(veloMicronPerSecVarCIMaxNorm);
    
    [accelBparamMuHatMaxNorm, accelBparamCImaxNorm] = raylfit(rmmissing(accelMicronPerSecSqMaxVecNorm'), 0.05);         % 95% CI for the B-parameter
    accelMicronPerSecSqCImaxNorm(1) = 0;
    accelMicronPerSecSqCImaxNorm(2) = raylinv(1 - StatAlpha, accelBparamMuHatMaxNorm);   % one-tailed test    
    [accelMicronPerSecSqMuHatMaxNorm, accelMicronPerSecSqVarHatMaxNorm] = raylstat(accelBparamMuHatMaxNorm);
    accelMicronPerSecSqSigmaHatMaxNorm = sqrt(accelMicronPerSecSqVarHatMaxNorm);    
    [accelMicronPerSecSqMuCIMaxNorm, accelMicronPerSecSqVarCIMaxNorm] = raylstat(accelBparamCImaxNorm);
    accelMicronPerSecSqSigmaCImaxNorm = sqrt(accelMicronPerSecSqVarCIMaxNorm);
%----- All beads
    %_______________________  
  %----- all beads
    EmptyArray = nan(size(FramesDoneNumbers));
    veloMicronPerSecMuHatAllX = EmptyArray';
    veloMicronPerSecSigmaHatAllX = EmptyArray';
    veloMicronPerSecMuCIallX = [EmptyArray', EmptyArray'];
    veloMicronPerSecSigmaCIallX = [EmptyArray', EmptyArray'];
    veloMicronPerSecCIallX  = [EmptyArray', EmptyArray'];
    
    EmptyArray = nan(size(FramesDoneNumbers));
    veloMicronPerSecMuHatAllY = EmptyArray';
    veloMicronPerSecSigmaHatAllY = EmptyArray';
    veloMicronPerSecMuCIallY = [EmptyArray', EmptyArray'];
    veloMicronPerSecSigmaCIallY = [EmptyArray', EmptyArray'];
    veloMicronPerSecCIallY  = [EmptyArray', EmptyArray'];
    
    EmptyArray = nan(size(FramesDoneNumbers));
    veloBparamMuHatAllNorm =  EmptyArray';
    veloMicronPerSecMuHatAllNorm = EmptyArray';
    veloMicronPerSecSigmaHatAllNorm = EmptyArray';
    veloBparamVarHatAllNorm = [EmptyArray', EmptyArray'];
    veloMicronPerSecVarHatAllNorm = EmptyArray;
    veloMicronPerSecMuCIallNorm = [EmptyArray', EmptyArray'];
    veloMicronPerSecVarCIallNorm = [EmptyArray', EmptyArray'];
    veloMicronPerSecSigmaCIallNorm = [EmptyArray', EmptyArray'];
    veloMicronPerSecCIallNorm  = [EmptyArray', EmptyArray'];
        
    for CurrentFrame = FramesDoneNumbers
        [veloMicronPerSecMuHatAllX(CurrentFrame),veloMicronPerSecSigmaHatAllX(CurrentFrame),veloMicronPerSecMuCIallX(CurrentFrame, :),veloMicronPerSecSigmaCIallX(CurrentFrame,:)] = normfit(rmmissing(veloMicronPerSecVecX(CurrentFrame,:)), StatAlpha);
        veloMicronPerSecCIallX(CurrentFrame, :) = norminv([StatAlpha/2, 1-StatAlpha/2], veloMicronPerSecMuHatAllX(CurrentFrame), veloMicronPerSecSigmaHatAllX(CurrentFrame));
     
        [veloMicronPerSecMuHatAllY(CurrentFrame),veloMicronPerSecSigmaHatAllY(CurrentFrame), veloMicronPerSecMuCIallY(CurrentFrame, :), veloMicronPerSecSigmaCIallY(CurrentFrame, :)] = normfit(rmmissing(veloMicronPerSecVecY(CurrentFrame,:)), StatAlpha);
        veloMicronPerSecCIallY(CurrentFrame, :) = norminv([StatAlpha/2, 1-StatAlpha/2], veloMicronPerSecMuHatAllY(CurrentFrame), veloMicronPerSecSigmaHatAllY(CurrentFrame));
    
        [veloBparamMuHatAllNorm(CurrentFrame), veloBparamVarHatAllNorm(CurrentFrame,:)] = raylfit(rmmissing(veloMicronPerSecVecNorm(CurrentFrame,:)), 0.05);         % 95% CI for the B-parameter
        veloMicronPerSecCIallNorm(CurrentFrame, 1) = 0;
        veloMicronPerSecCIallNorm(CurrentFrame, 2) = raylinv(1 - StatAlpha, veloBparamMuHatAllNorm(CurrentFrame));   % one-tailed test    
        [veloMicronPerSecMuHatAllNorm(CurrentFrame), veloMicronPerSecVarHatAllNorm(CurrentFrame)] = raylstat(veloBparamMuHatAllNorm(CurrentFrame));
        veloMicronPerSecSigmaHatAllNorm(CurrentFrame) = sqrt(veloMicronPerSecVarHatAllNorm(CurrentFrame));        

        [veloMicronPerSecMuCIallNorm(CurrentFrame, :), veloMicronPerSecVarCIallNorm(CurrentFrame, :)] =  raylstat(veloBparamVarHatAllNorm(CurrentFrame,:));
        veloMicronPerSecSigmaCIallNorm(CurrentFrame, :) = sqrt(veloMicronPerSecVarCIallNorm(CurrentFrame, :));
    end
    
    veloMicronPerSecMuHatAllXMean = mean(veloMicronPerSecMuHatAllX, 'omitnan');
    veloMicronPerSecCIallXMean = mean(veloMicronPerSecCIallX, 'omitnan');
   
    veloMicronPerSecMuHatAllYMean = mean(veloMicronPerSecMuHatAllY, 'omitnan');
    veloMicronPerSecCIallYMean = mean(veloMicronPerSecCIallY, 'omitnan');
    
    veloMicronPerSecMuHatAllNormMean = mean(veloMicronPerSecMuHatAllNorm, 'omitnan');
    veloMicronPerSecCIallNormMean = mean(veloMicronPerSecCIallNorm, 'omitnan');
    
    %----- all beads
    EmptyArray = nan(size(FramesDoneNumbers));
    accelMicronPerSecSqMuHatAllX = EmptyArray';
    accelMicronPerSecSqSigmaHatAllX = EmptyArray';
    accelMicronPerSecSqMuCIallX = [EmptyArray', EmptyArray'];
    accelMicronPerSecSqSigmaCIallX = [EmptyArray', EmptyArray'];
    accelMicronPerSecSqCIallX  = [EmptyArray', EmptyArray'];
    
    EmptyArray = nan(size(FramesDoneNumbers));
    accelMicronPerSecSqMuHatAllY = EmptyArray';
    accelMicronPerSecSqSigmaHatAllY = EmptyArray';
    accelMicronPerSecSqMuCIallY = [EmptyArray', EmptyArray'];
    accelMicronPerSecSqSigmaCIallY = [EmptyArray', EmptyArray'];
    accelMicronPerSecSqCIallY  = [EmptyArray', EmptyArray'];
    
    EmptyArray = nan(size(FramesDoneNumbers));
    accelBparamMuHatAllNorm =  EmptyArray';
    accelMicronPerSecSqMuHatAllNorm = EmptyArray';
    accelMicronPerSecSqSigmaHatAllNorm = EmptyArray';
    accelBparamVarHatAllNorm = [EmptyArray', EmptyArray'];
    accelMicronPerSecSqVarHatAllNorm = EmptyArray;
    accelMicronPerSecSqMuCIallNorm = [EmptyArray', EmptyArray'];
    accelMicronPerSecSqVarCIallNorm = [EmptyArray', EmptyArray'];
    accelMicronPerSecSqSigmaCIallNorm = [EmptyArray', EmptyArray'];
    accelMicronPerSecSqCIallNorm  = [EmptyArray', EmptyArray'];
        
    for CurrentFrame = FramesDoneNumbers
        [accelMicronPerSecSqMuHatAllX(CurrentFrame),accelMicronPerSecSqSigmaHatAllX(CurrentFrame),accelMicronPerSecSqMuCIallX(CurrentFrame, :),accelMicronPerSecSqSigmaCIallX(CurrentFrame,:)] = normfit(rmmissing(accelMicronPerSecSqVecX(CurrentFrame,:)), StatAlpha);
        accelMicronPerSecSqCIallX(CurrentFrame, :) = norminv([StatAlpha/2, 1-StatAlpha/2], accelMicronPerSecSqMuHatAllX(CurrentFrame), accelMicronPerSecSqSigmaHatAllX(CurrentFrame));
     
        [accelMicronPerSecSqMuHatAllY(CurrentFrame),accelMicronPerSecSqSigmaHatAllY(CurrentFrame), accelMicronPerSecSqMuCIallY(CurrentFrame, :), accelMicronPerSecSqSigmaCIallY(CurrentFrame, :)] = normfit(rmmissing(accelMicronPerSecSqVecY(CurrentFrame,:)), StatAlpha);
        accelMicronPerSecSqCIallY(CurrentFrame, :) = norminv([StatAlpha/2, 1-StatAlpha/2], accelMicronPerSecSqMuHatAllY(CurrentFrame), accelMicronPerSecSqSigmaHatAllY(CurrentFrame));
    
        [accelBparamMuHatAllNorm(CurrentFrame), accelBparamVarHatAllNorm(CurrentFrame,:)] = raylfit(rmmissing(accelMicronPerSecSqVecNorm(CurrentFrame,:)), 0.05);         % 95% CI for the B-parameter
        accelMicronPerSecSqCIallNorm(CurrentFrame, 1) = 0;
        accelMicronPerSecSqCIallNorm(CurrentFrame, 2) = raylinv(1 - StatAlpha, accelBparamMuHatAllNorm(CurrentFrame));   % one-tailed test    
        [accelMicronPerSecSqMuHatAllNorm(CurrentFrame), accelMicronPerSecSqVarHatAllNorm(CurrentFrame)] = raylstat(accelBparamMuHatAllNorm(CurrentFrame));
        accelMicronPerSecSqSigmaHatAllNorm(CurrentFrame) = sqrt(accelMicronPerSecSqVarHatAllNorm(CurrentFrame));        

        [accelMicronPerSecSqMuCIallNorm(CurrentFrame, :), accelMicronPerSecSqVarCIallNorm(CurrentFrame, :)] =  raylstat(accelBparamVarHatAllNorm(CurrentFrame,:));
        accelMicronPerSecSqSigmaCIallNorm(CurrentFrame, :) = sqrt(accelMicronPerSecSqVarCIallNorm(CurrentFrame, :));
    end
    
    accelMicronPerSecSqMuHatAllXMean = mean(accelMicronPerSecSqMuHatAllX, 'omitnan');
    accelMicronPerSecSqCIallXMean = mean(accelMicronPerSecSqCIallX, 'omitnan');
   
    accelMicronPerSecSqMuHatAllYMean = mean(accelMicronPerSecSqMuHatAllY, 'omitnan');
    accelMicronPerSecSqCIallYMean = mean(accelMicronPerSecSqCIallY, 'omitnan');
    
    accelMicronPerSecSqMuHatAllNormMean = mean(accelMicronPerSecSqMuHatAllNorm, 'omitnan');
    accelMicronPerSecSqCIallNormMean = mean(accelMicronPerSecSqCIallNorm, 'omitnan');


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
    
%% Decimating the samples as needed___________________________
    decimateFactorFramesDefault = 2;
    decimateFactorBeadsDefault = 25;
    
    Str1 = sprintf('What is the decimation factor of frames? [Default N = %d & No Decimation N = 1]: ', decimateFactorFramesDefault);
    Str2 = sprintf('What is the decimation factor of Beads? [Default N = %d & No Decimation N = 1]: ', decimateFactorBeadsDefault);
    decimateFactors = inputdlg({Str1, Str2}, 'Decimate Beads?', ...
                    [1, 80], {num2str(decimateFactorFramesDefault), num2str(decimateFactorBeadsDefault)});
    if isempty(decimateFactors)
        decimateFactorFrames = decimateFactorFramesDefault;
        decimateFactorBeads = decimateFactorBeadsDefault;
    else
        if isempty( decimateFactors{1})
            decimateFactorFrames = decimateFactorFramesDefault;
        else
            decimateFactorFrames = str2double(decimateFactors{1});
        end
        if isempty( decimateFactors{2})
            decimateFactorBeads = decimateFactorBeadsDefault;
        else
            decimateFactorBeads = str2double(decimateFactors{2});
        end
    end
    
    %____ decimating by beads first
    BeadCount = size(displMicronVecNorm, 2);
    BeadCountDecimated = 1:decimateFactorBeads:BeadCount;
    if isempty(find(BeadCountDecimated == MaxDisplFieldIndex)), BeadCountDecimated = sort([BeadCountDecimated, MaxDisplFieldIndex]); end
    
    displMicronVecX_Decimated = displMicronVecX(:,BeadCountDecimated); 
    displMicronVecY_Decimated = displMicronVecY(:,BeadCountDecimated);
    displMicronVecNorm_Decimated = displMicronVecNorm(:,BeadCountDecimated);  
    
    veloMicronPerSecVecX_Decimated = veloMicronPerSecVecX(:,BeadCountDecimated); 
    veloMicronPerSecVecY_Decimated = veloMicronPerSecVecY(:,BeadCountDecimated);     
    veloMicronPerSecVecNorm_Decimated = veloMicronPerSecVecNorm(:,BeadCountDecimated);  
    
    accelMicronPerSecSqVecX_Decimated = accelMicronPerSecSqVecX(:,BeadCountDecimated); 
    accelMicronPerSecSqVecY_Decimated = accelMicronPerSecSqVecY(:,BeadCountDecimated);     
    accelMicronPerSecSqVecNorm_Decimated = accelMicronPerSecSqVecNorm(:,BeadCountDecimated); 

    %____ decimating by frames now
    FramesDecimated = FramesDoneNumbers(1):decimateFactorFrames:FramesDoneNumbers(end);
    
    displMicronVecX_Decimated = displMicronVecX_Decimated(FramesDecimated, :);    
    displMicronVecY_Decimated = displMicronVecY_Decimated(FramesDecimated, :);     
    displMicronVecNorm_Decimated = displMicronVecNorm_Decimated(FramesDecimated, :);     

    veloMicronPerSecVecX_Decimated = veloMicronPerSecVecX_Decimated(FramesDecimated, :);     
    veloMicronPerSecVecY_Decimated = veloMicronPerSecVecY_Decimated(FramesDecimated, :); 
    veloMicronPerSecVecNorm_Decimated = veloMicronPerSecVecNorm_Decimated(FramesDecimated, :); 

    accelMicronPerSecSqVecX_Decimated = accelMicronPerSecSqVecX_Decimated(FramesDecimated, :); 
    accelMicronPerSecSqVecY_Decimated = accelMicronPerSecSqVecY_Decimated(FramesDecimated, :);       
    accelMicronPerSecSqVecNorm_Decimated = accelMicronPerSecSqVecNorm_Decimated(FramesDecimated, :); 
       
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
    
%% ___ Plot all norm
    figHandleBeadDynamicsAllNorm = figure('visible',showPlot, 'color', 'w');     % added by WIM on 2019-02-07. To show, remove 'visible
    set(figHandleBeadDynamicsAllNorm, 'Position', [50, 450, 825, 775])
    pause(0.1)          % give some time so that the figure loads well
    subplot(3,1,1);
    plot(TimeStamps(FramesDecimated), displMicronVecNorm_Decimated, 'r.', 'MarkerSize', 0.5, 'HandleVisibility', 'off')
    hold on
    if strcmpi(NegativeBeadDynamicsStatsChoice, 'Yes')
        plot(TimeStamps(FramesDoneNumbers), repmat(NegativeBeadDynamics.displMicronMuHatAllNormMean, FrameCount, 1)', Style1, 'LineWidth', 1);
        plot(TimeStamps(FramesDoneNumbers), repmat(NegativeBeadDynamics.displMicronCIallNormMean(2), FrameCount, 1)', Style2, 'LineWidth', 1);
        txt = sprintf('\\mu=%0.5f, CI = [%0.5f, %0.5f] %s', NegativeBeadDynamics.displMicronMuHatAllNormMean, NegativeBeadDynamics.displMicronCIallNormMean, um);
    else
        plot(TimeStamps(FramesDoneNumbers), repmat(displMicronMuHatAllNormMean, FrameCount, 1)', Style1, 'LineWidth', 1);
        plot(TimeStamps(FramesDoneNumbers), repmat(displMicronCIallNormMean(2), FrameCount, 1)', Style2, 'LineWidth', 1);
        txt = sprintf('\\mu=%0.5f, CI = [%0.5f, %0.5f] %s', displMicronMuHatAllNormMean, displMicronCIallNormMean, um);
    end   
    text(0.05,1.1, txt, 'Units', 'normalized');
    xlim([0, TimeStamps(end)]);
    %     xlim([0, TimeStamps(LastFramePlotted)]);    
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
    ylabel(strcat('\itu\rm(\itt\rm) [', um, ']'));
    title(titleStr2)
    hold on
    if strcmpi(NegativeBeadDynamicsStatsChoice, 'Yes')
        legend('Rayleigh Fit Mean  ',strcat(titleStr1_4, ' -ve ctrl'),'Location', 'best', 'Orientation', 'horizontal')
    else
        legend('Rayleigh Fit Mean', titleStr1_4, 'Location', 'best', 'Orientation', 'horizontal')
    end

    subplot(3,1,2);
    plot(TimeStamps(FramesDecimated), veloMicronPerSecVecNorm_Decimated, 'r.', 'MarkerSize', 0.5, 'HandleVisibility','off');
    xlim([0, TimeStamps(end)]);
    hold on
    if strcmpi(NegativeBeadDynamicsStatsChoice, 'Yes')
        plot(TimeStamps(FramesDoneNumbers), repmat(NegativeBeadDynamics.veloMicronPerSecMuHatAllNormMean, FrameCount, 1)', Style1, 'LineWidth', 1);
        plot(TimeStamps(FramesDoneNumbers), repmat(NegativeBeadDynamics.veloMicronPerSecCIallNormMean(2), FrameCount, 1)', Style2, 'LineWidth', 1);
        txt = sprintf('\\mu=%0.5f, CI = [%0.5f, %0.5f] %s/s', NegativeBeadDynamics.veloMicronPerSecMuHatAllNormMean, NegativeBeadDynamics.veloMicronPerSecCIallNormMean, um);        
    else        
        plot(TimeStamps(FramesDoneNumbers), repmat(veloMicronPerSecMuHatAllNormMean, FrameCount, 1)', Style1, 'LineWidth', 1);
        plot(TimeStamps(FramesDoneNumbers), repmat(veloMicronPerSecCIallNormMean(2), FrameCount, 1)', Style2, 'LineWidth', 1);
        txt = sprintf('\\mu=%0.5f, CI = [%0.5f, %0.5f] %s/s', veloMicronPerSecMuHatAllNormMean, veloMicronPerSecCIallNormMean, um);
    end
    text(0.05,1.1, txt, 'Units', 'normalized');
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
    ylabel(strcat('{\partial\itu\rm(\itt\rm)}/{\partial\itt\rm} [', um, '/s]'), 'Interpreter', 'tex');
    
    % Flip to Cartesian Coordinates in the Plot (Negative pointing downwards). Add a negative Sign before plot.    
    subplot(3,1,3);
    plot(TimeStamps(FramesDecimated), accelMicronPerSecSqVecNorm_Decimated,'r.', 'MarkerSize', 0.5, 'HandleVisibility', 'off')
    xlim([0, TimeStamps(end)]);
    hold on
    if strcmpi(NegativeBeadDynamicsStatsChoice, 'Yes')
        plot(TimeStamps(FramesDoneNumbers), repmat(NegativeBeadDynamics.accelMicronPerSecSqMuHatAllNormMean, FrameCount, 1)', Style1, 'LineWidth', 1)   
        plot(TimeStamps(FramesDoneNumbers), repmat(NegativeBeadDynamics.accelMicronPerSecSqCIallNormMean(2), FrameCount, 1)', Style2, 'LineWidth', 1)
        txt = sprintf('\\mu=%0.5f, CI = [%0.5f, %0.5f] %s/s^2', NegativeBeadDynamics.accelMicronPerSecSqMuHatAllNormMean, NegativeBeadDynamics.accelMicronPerSecSqCIallNormMean, um);
    else
        plot(TimeStamps(FramesDoneNumbers), repmat(accelMicronPerSecSqMuHatAllNormMean, FrameCount, 1)', Style1, 'LineWidth', 1)   
        plot(TimeStamps(FramesDoneNumbers), repmat(accelMicronPerSecSqCIallNormMean(2), FrameCount, 1)', Style2, 'LineWidth', 1)
        txt = sprintf('\\mu=%0.5f, CI = [%0.5f, %0.5f] %s/s^2', accelMicronPerSecSqMuHatAllNormMean, accelMicronPerSecSqCIallNormMean, um);
    end
    text(0.05,1.1, txt, 'Units', 'normalized');
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
    ylabel(strcat('{\partial^{2}\itu\rm(\itt\rm)}/{\partial\itt\rm^{2}} [', um, '/s^2]'), 'Interpreter', 'tex');
    pause(1)
    
%% ___ Plot all X    
    figHandleBeadDynamicsAllX = figure('visible', showPlot, 'color', 'w');     % added by WIM on 2019-02-07. To show, remove 'visible
    set(figHandleBeadDynamicsAllX, 'Position', [100, 400, 825, 775])
    pause(0.1)          % give some time so that the figure loads well
    subplot(3,1,1);
    plot(TimeStamps(FramesDecimated), displMicronVecX_Decimated, 'r.', 'MarkerSize', 0.5, 'HandleVisibility', 'off')
    xlim([0, TimeStamps(end)]);
    hold on
    if strcmpi(NegativeBeadDynamicsStatsChoice, 'Yes')
        plot(TimeStamps(FramesDoneNumbers), repmat(NegativeBeadDynamics.displMicronMuHatAllXMean, FrameCount, 1)', Style1, 'LineWidth', 1);
        plot(TimeStamps(FramesDoneNumbers), repmat(NegativeBeadDynamics.displMicronCIallXMean, FrameCount, 1)', Style2, 'LineWidth', 1);   
        txt = sprintf('\\mu=%0.5f, CI = [%0.5f, %0.5f] %s', NegativeBeadDynamics.displMicronMuHatAllXMean, NegativeBeadDynamics.displMicronCIallXMean, um);
    else
        plot(TimeStamps(FramesDoneNumbers), repmat(displMicronMuHatAllXMean, FrameCount, 1)', Style1, 'LineWidth', 1);
        plot(TimeStamps(FramesDoneNumbers), repmat(displMicronCIallXMean, FrameCount, 1)', Style2, 'LineWidth', 1);
        txt = sprintf('\\mu=%0.5f, CI = [%0.5f, %0.5f] %s', displMicronMuHatAllXMean, displMicronCIallXMean, um);
    end
    text(0.05,1.1, txt, 'Units', 'normalized');
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
    ylabel(strcat('\itu_{x\rm*}(\itt\rm) [', um, ']'));
    title(titleStr1)
    hold on
    if strcmpi(NegativeBeadDynamicsStatsChoice, 'Yes')
        legend('Gaussian Fit Mean',strcat(titleStr1_3, ' -ve ctrl'),'Location', 'best', 'Orientation', 'horizontal')
    else
        legend('Gaussian Fit Mean', titleStr1_3, 'Location', 'best', 'Orientation', 'horizontal')
    end
    
    subplot(3,1,2);
    plot(TimeStamps(FramesDecimated), veloMicronPerSecVecX_Decimated, 'r.', 'MarkerSize', 0.5, 'HandleVisibility','off');
    xlim([0, TimeStamps(end)]);
    hold on
    if strcmpi(NegativeBeadDynamicsStatsChoice, 'Yes')
        plot(TimeStamps(FramesDoneNumbers), repmat(NegativeBeadDynamics.veloMicronPerSecMuHatAllXMean, FrameCount, 1)', Style1, 'LineWidth', 1);
        plot(TimeStamps(FramesDoneNumbers), repmat(NegativeBeadDynamics.veloMicronPerSecCIallXMean, FrameCount, 1)', Style2, 'LineWidth', 1);
        txt = sprintf('\\mu=%0.5f, CI = [%0.5f, %0.5f] %s/s', NegativeBeadDynamics.veloMicronPerSecMuHatAllXMean, NegativeBeadDynamics.veloMicronPerSecCIallXMean, um);
    else
        plot(TimeStamps(FramesDoneNumbers), repmat(veloMicronPerSecMuHatAllXMean, FrameCount, 1)', Style1, 'LineWidth', 1);
        plot(TimeStamps(FramesDoneNumbers), repmat(veloMicronPerSecCIallXMean, FrameCount, 1)', Style2, 'LineWidth', 1);
        txt = sprintf('\\mu=%0.5f, CI = [%0.5f, %0.5f] %s/s', veloMicronPerSecMuHatAllXMean, veloMicronPerSecCIallXMean, um);
    end
    text(0.05,1.1, txt, 'Units', 'normalized');
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
    ylabel(strcat('{\partial\itu_{x\rm*}(\itt\rm)}/{\partial\itt\rm} [', um, '/s]'), 'Interpreter', 'tex');
    
    % Flip to Cartesian Coordinates in the Plot (Negative pointing downwards). Add a negative Sign before plot.    
    subplot(3,1,3)
    plot(TimeStamps(FramesDecimated), accelMicronPerSecSqVecX_Decimated,'r.', 'MarkerSize', 0.5, 'HandleVisibility', 'off')
    xlim([0, TimeStamps(end)]);
    hold on
    if strcmpi(NegativeBeadDynamicsStatsChoice, 'Yes')
        plot(TimeStamps(FramesDoneNumbers), repmat(NegativeBeadDynamics.accelMicronPerSecSqMuHatAllXMean, FrameCount, 1)', Style1, 'LineWidth', 1)   
        plot(TimeStamps(FramesDoneNumbers), repmat(NegativeBeadDynamics.accelMicronPerSecSqCIallXMean, FrameCount, 1)', Style2, 'LineWidth', 1)  
        txt = sprintf('\\mu=%0.5f, CI = [%0.5f, %0.5f] %s/s^2', NegativeBeadDynamics.accelMicronPerSecSqMuHatAllXMean, NegativeBeadDynamics.accelMicronPerSecSqCIallXMean, um);
    else
        plot(TimeStamps(FramesDoneNumbers), repmat(accelMicronPerSecSqMuHatAllXMean, FrameCount, 1)', Style1, 'LineWidth', 1)   
        plot(TimeStamps(FramesDoneNumbers), repmat(accelMicronPerSecSqCIallXMean, FrameCount, 1)', Style2, 'LineWidth', 1)        
        txt = sprintf('\\mu=%0.5f, CI = [%0.5f, %0.5f] %s/s^2', accelMicronPerSecSqMuHatAllXMean, accelMicronPerSecSqCIallXMean, um);
    end
    text(0.05,1.1, txt, 'Units', 'normalized');
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
    ylabel(strcat('{\partial^{2}\itu_{x\rm*}(\itt\rm)}/{\partial\itt\rm^{2} [', um, '/s^2]}'), 'Interpreter', 'tex');
    pause(1)
    
%% ___ Plot all Y
    figHandleBeadDynamicsAllY = figure('visible',showPlot, 'color', 'w');     % added by WIM on 2019-02-07. To show, remove 'visible
    set(figHandleBeadDynamicsAllY, 'Position', [150, 350, 825, 775])
    pause(0.1)          % give some time so that the figure loads well
    subplot(3,1,1);
    plot(TimeStamps(FramesDecimated), displMicronVecY_Decimated, 'r.', 'MarkerSize', 0.5, 'HandleVisibility', 'off')
    xlim([0, TimeStamps(end)]);
    hold on
    if strcmpi(NegativeBeadDynamicsStatsChoice, 'Yes')
        plot(TimeStamps(FramesDoneNumbers), repmat(NegativeBeadDynamics.displMicronMuHatAllYMean, FrameCount, 1)', Style1, 'LineWidth', 1);
        plot(TimeStamps(FramesDoneNumbers), repmat(NegativeBeadDynamics.displMicronCIallYMean, FrameCount, 1)', Style2, 'LineWidth', 1); 
        txt = sprintf('\\mu=%0.5f, CI = [%0.5f, %0.5f] %s', NegativeBeadDynamics.displMicronMuHatAllYMean, NegativeBeadDynamics.displMicronCIallYMean, um);
    else
        plot(TimeStamps(FramesDoneNumbers), repmat(displMicronMuHatAllYMean, FrameCount, 1)', Style1, 'LineWidth', 1);
        plot(TimeStamps(FramesDoneNumbers), repmat(displMicronCIallYMean, FrameCount, 1)', Style2, 'LineWidth', 1);
        txt = sprintf('\\mu=%0.5f, CI = [%0.5f, %0.5f] %s', displMicronMuHatAllYMean, displMicronCIallYMean, um);
    end
    text(0.05,1.1, txt, 'Units', 'normalized');
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
    ylabel(strcat('\itu_{y\rm*}(\itt\rm) [', um, ']'));
    title(titleStr1)
    hold on
    if strcmpi(NegativeBeadDynamicsStatsChoice, 'Yes')
        legend('Gaussian Fit Mean',strcat(titleStr1_3, ' -ve ctrl'),'Location', 'best', 'Orientation', 'horizontal')
    else
        legend('Gaussian Fit Mean', titleStr1_3, 'Location', 'best', 'Orientation', 'horizontal')
    end
    
    subplot(3,1,2);
    plot(TimeStamps(FramesDecimated), veloMicronPerSecVecY_Decimated, 'r.', 'MarkerSize', 0.5, 'HandleVisibility','off');
    xlim([0, TimeStamps(end)]);
    hold on
    if strcmpi(NegativeBeadDynamicsStatsChoice, 'Yes')
        plot(TimeStamps(FramesDoneNumbers), repmat(NegativeBeadDynamics.veloMicronPerSecMuHatAllYMean, FrameCount, 1)', Style1, 'LineWidth', 1);
        plot(TimeStamps(FramesDoneNumbers), repmat(NegativeBeadDynamics.veloMicronPerSecCIallYMean, FrameCount, 1)', Style2, 'LineWidth', 1);
        txt = sprintf('\\mu=%0.5f, CI = [%0.5f, %0.5f] %s/s', NegativeBeadDynamics.veloMicronPerSecMuHatAllYMean, NegativeBeadDynamics.veloMicronPerSecCIallYMean, um);
    else
        plot(TimeStamps(FramesDoneNumbers), repmat(veloMicronPerSecMuHatAllYMean, FrameCount, 1)', Style1, 'LineWidth', 1);
        plot(TimeStamps(FramesDoneNumbers), repmat(veloMicronPerSecCIallYMean, FrameCount, 1)', Style2, 'LineWidth', 1);
        txt = sprintf('\\mu=%0.5f, CI = [%0.5f, %0.5f] %s/s', veloMicronPerSecMuHatAllYMean, veloMicronPerSecCIallYMean, um);
    end
    text(0.05,1.1, txt, 'Units', 'normalized');
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
    ylabel(strcat('{\partial\itu_{y}\rm(\itt\rm)}/{\partial\itt\rm} [', um, '/s]'), 'Interpreter', 'tex');
    
    % Flip to Cartesian Coordinates in the Plot (Negative pointing downwards). Add a negative Sign before plot.    
    subplot(3,1,3);
    plot(TimeStamps(FramesDecimated), accelMicronPerSecSqVecY_Decimated,'r.', 'MarkerSize', 0.5, 'HandleVisibility', 'off')
    xlim([0, TimeStamps(end)]);
    hold on
    if strcmpi(NegativeBeadDynamicsStatsChoice, 'Yes')
        plot(TimeStamps(FramesDoneNumbers), repmat(NegativeBeadDynamics.accelMicronPerSecSqMuHatAllYMean, FrameCount, 1)', Style1, 'LineWidth', 1)   
        plot(TimeStamps(FramesDoneNumbers), repmat(NegativeBeadDynamics.accelMicronPerSecSqCIallYMean, FrameCount, 1)', Style2, 'LineWidth', 1) 
        txt = sprintf('\\mu=%0.5f, CI = [%0.5f, %0.5f] %s/s^2', NegativeBeadDynamics.accelMicronPerSecSqMuHatAllYMean, NegativeBeadDynamics.accelMicronPerSecSqCIallYMean, um);
    else
        plot(TimeStamps(FramesDoneNumbers), repmat(accelMicronPerSecSqMuHatAllYMean, FrameCount, 1)', Style1, 'LineWidth', 1)   
        plot(TimeStamps(FramesDoneNumbers), repmat(accelMicronPerSecSqCIallYMean, FrameCount, 1)', Style2, 'LineWidth', 1)      
        txt = sprintf('\\mu=%0.5f, CI = [%0.5f, %0.5f] %s/s^2', accelMicronPerSecSqMuHatAllYMean, accelMicronPerSecSqCIallYMean, um);
    end
    text(0.05,1.1, txt, 'Units', 'normalized');
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
    ylabel(strcat('{\partial^{2}\itu_{y}\rm(\itt\rm)}/{\partial\itt\rm^{2} [', um, '/s^2]}'), 'Interpreter', 'tex');
    pause(1)
    
%% ___ Plot max norm 
    figHandleBeadDynamicsMaxNorm = figure('visible',showPlot, 'color', 'w');     % added by WIM on 2019-02-07. To show, remove 'visible
    set(figHandleBeadDynamicsMaxNorm, 'Position', [200, 300, 825, 775])
    pause(0.1)          % give some time so that the figure loads well
    subplot(3,1,1);
    plot(TimeStamps(FramesDoneNumbers), displMicronMaxVecNorm, 'r.-', 'LineWidth', 1, 'MarkerSize', 1, 'HandleVisibility', 'off')
    hold on
    if strcmpi(NegativeBeadDynamicsStatsChoice, 'Yes')
        plot(TimeStamps(FramesDoneNumbers), repmat(NegativeBeadDynamics.displMicronMuHatAllNormMean, FrameCount, 1)', Style1, 'LineWidth', 1)   
        plot(TimeStamps(FramesDoneNumbers), repmat(NegativeBeadDynamics.displMicronCIallNormMean(2), FrameCount, 1)', Style2, 'LineWidth', 1)
        txt = sprintf('\\mu=%0.5f, CI = [%0.5f, %0.5f] %s', NegativeBeadDynamics.displMicronMuHatAllNormMean, NegativeBeadDynamics.displMicronCIallNormMean, um);            
    else
        plot(TimeStamps(FramesDoneNumbers), repmat(displMicronMuHatAllNormMean, FrameCount, 1)', Style1, 'LineWidth', 1)   
        plot(TimeStamps(FramesDoneNumbers), repmat(displMicronCIallNormMean(2), FrameCount, 1)', Style2, 'LineWidth', 1)
        txt = sprintf('\\mu=%0.5f, CI = [%0.5f, %0.5f] %s', displMicronMuHatAllNormMean, displMicronCIallNormMean, um);
    end
    text(0.05,1.1, txt, 'Units', 'normalized');
    xlim([0, TimeStamps(end)]);
    %     xlim([0, TimeStamps(LastFramePlotted)]);
    title(titleStr2);
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
        legend('Rayleigh Fit Mean',strcat(titleStr1_4, ' -ve ctrl'),'Location', 'best', 'Orientation', 'horizontal')
    else
        legend('Rayleigh Fit Mean', titleStr1_4, 'Location', 'best', 'Orientation', 'horizontal')
    end

    subplot(3,1,2);
    plot(TimeStamps(FramesDoneNumbers), veloMicronPerSecMaxVecNorm', 'r.-', 'LineWidth', 1, 'MarkerSize', 2, 'HandleVisibility', 'off')
    hold on
    if strcmpi(NegativeBeadDynamicsStatsChoice, 'Yes')
        plot(TimeStamps(FramesDoneNumbers), repmat(NegativeBeadDynamics.veloMicronPerSecMuHatAllNormMean', FrameCount, 1)', Style1, 'LineWidth', 1)   
        plot(TimeStamps(FramesDoneNumbers), repmat(NegativeBeadDynamics.veloMicronPerSecCIallNormMean(2)', FrameCount, 1)', Style2, 'LineWidth', 1)
        txt = sprintf('\\mu=%0.5f, CI = [%0.5f, %0.5f] %s/s', NegativeBeadDynamics.veloMicronPerSecMuHatAllNormMean, NegativeBeadDynamics.veloMicronPerSecCIallNormMean, um);
    else
        plot(TimeStamps(FramesDoneNumbers), repmat(veloMicronPerSecMuHatAllNormMean, FrameCount, 1)', Style1, 'LineWidth', 1)   
        plot(TimeStamps(FramesDoneNumbers), repmat(veloMicronPerSecCIallNormMean(2), FrameCount, 1)', Style2, 'LineWidth', 1)        
        txt = sprintf('\\mu=%0.5f, CI = [%0.5f, %0.5f] %s/s', veloMicronPerSecMuHatAllNormMean, veloMicronPerSecCIallNormMean, um);
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
        plot(TimeStamps(FramesDoneNumbers), repmat(NegativeBeadDynamics.accelMicronPerSecSqMuHatAllNormMean, FrameCount, 1)', Style1, 'LineWidth', 1)   
        plot(TimeStamps(FramesDoneNumbers), repmat(NegativeBeadDynamics.accelMicronPerSecSqCIallNormMean(2), FrameCount, 1)', Style2, 'LineWidth', 1)
        txt = sprintf('\\mu=%0.5f, CI = [%0.5f, %0.5f] %s/s^2', NegativeBeadDynamics.accelMicronPerSecSqMuHatAllNormMean, NegativeBeadDynamics.accelMicronPerSecSqCIallNormMean, um);  
    else
        plot(TimeStamps(FramesDoneNumbers), repmat(accelMicronPerSecSqMuHatAllNormMean, FrameCount, 1)', Style1, 'LineWidth', 1)   
        plot(TimeStamps(FramesDoneNumbers), repmat(accelMicronPerSecSqCIallNormMean(2), FrameCount, 1)', Style2, 'LineWidth', 1)      
        txt = sprintf('\\mu=%0.5f, CI = [%0.5f, %0.5f] %s/s^2', accelMicronPerSecSqMuHatAllNormMean, accelMicronPerSecSqCIallNormMean, um);     
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
        plot(TimeStamps(FramesDoneNumbers), repmat(NegativeBeadDynamics.displMicronMuHatAllXMean, FrameCount, 1)', Style1, 'LineWidth', 1)   
        plot(TimeStamps(FramesDoneNumbers), repmat(NegativeBeadDynamics.displMicronCIallXMean, FrameCount, 1)', Style2, 'LineWidth', 1)
        txt = sprintf('\\mu=%0.5f, CI = [%0.5f, %0.5f] %s', NegativeBeadDynamics.displMicronMuHatAllXMean, NegativeBeadDynamics.displMicronCIallXMean, um);
    else
        plot(TimeStamps(FramesDoneNumbers), repmat(displMicronMuHatAllXMean, FrameCount, 1)', Style1, 'LineWidth', 1)   
        plot(TimeStamps(FramesDoneNumbers), repmat(displMicronCIallXMean, FrameCount, 1)', Style2, 'LineWidth', 1)
        txt = sprintf('\\mu=%0.5f, CI = [%0.5f, %0.5f] %s', displMicronMuHatAllXMean, displMicronCIallXMean, um);
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
        legend('Gaussian Fit Mean',strcat(titleStr1_3, ' -ve ctrl'),'Location', 'best', 'Orientation', 'horizontal')
    else
        legend('Gaussian Fit Mean', titleStr1_3, 'Location', 'best', 'Orientation', 'horizontal')
    end
    
    subplot(3,1,2);
    plot(TimeStamps(FramesDoneNumbers), veloMicronPerSecMaxVecX, 'r.-', 'LineWidth', 1, 'MarkerSize', 2, 'HandleVisibility', 'off')
    hold on
    if strcmpi(NegativeBeadDynamicsStatsChoice, 'Yes')
        plot(TimeStamps(FramesDoneNumbers), repmat(NegativeBeadDynamics.veloMicronPerSecMuHatAllXMean, FrameCount, 1)', Style1, 'LineWidth', 1)   
        plot(TimeStamps(FramesDoneNumbers), repmat(NegativeBeadDynamics.veloMicronPerSecCIallXMean, FrameCount, 1)', Style2, 'LineWidth', 1)
        txt = sprintf('\\mu=%0.5f, CI = [%0.5f, %0.5f] %s/s', NegativeBeadDynamics.veloMicronPerSecMuHatAllXMean, NegativeBeadDynamics.veloMicronPerSecCIallXMean, um);
    else
        plot(TimeStamps(FramesDoneNumbers), repmat(veloMicronPerSecMuHatAllXMean, FrameCount, 1)', Style1, 'LineWidth', 1)   
        plot(TimeStamps(FramesDoneNumbers), repmat(veloMicronPerSecCIallXMean, FrameCount, 1)', Style2, 'LineWidth', 1) 
        txt = sprintf('\\mu=%0.5f, CI = [%0.5f, %0.5f] %s/s', veloMicronPerSecMuHatAllXMean, veloMicronPerSecCIallXMean, um);
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
        plot(TimeStamps(FramesDoneNumbers), repmat(NegativeBeadDynamics.accelMicronPerSecSqMuHatAllXMean, FrameCount, 1)', Style1, 'LineWidth', 1)   
        plot(TimeStamps(FramesDoneNumbers), repmat(NegativeBeadDynamics.accelMicronPerSecSqCIallXMean, FrameCount, 1)', Style2, 'LineWidth', 1)
        txt = sprintf('\\mu=%0.5f, CI = [%0.5f, %0.5f] %s/s^2', NegativeBeadDynamics.accelMicronPerSecSqMuHatAllXMean, NegativeBeadDynamics.accelMicronPerSecSqCIallXMean, um);
    else
        plot(TimeStamps(FramesDoneNumbers), repmat(accelMicronPerSecSqMuHatAllXMean, FrameCount, 1)', Style1, 'LineWidth', 1)   
        plot(TimeStamps(FramesDoneNumbers), repmat(accelMicronPerSecSqCIallXMean, FrameCount, 1)', Style2, 'LineWidth', 1)
        txt = sprintf('\\mu=%0.5f, CI = [%0.5f, %0.5f] %s/s^2', accelMicronPerSecSqMuHatAllXMean, accelMicronPerSecSqCIallXMean, um);
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
        plot(TimeStamps(FramesDoneNumbers), repmat(NegativeBeadDynamics.displMicronMuHatAllYMean, FrameCount, 1)', Style1, 'LineWidth', 1)   
        plot(TimeStamps(FramesDoneNumbers), repmat(NegativeBeadDynamics.displMicronCIallYMean, FrameCount, 1)', Style2, 'LineWidth', 1)
        txt = sprintf('\\mu=%0.5f, CI = [%0.5f, %0.5f] %s', NegativeBeadDynamics.displMicronMuHatAllYMean, NegativeBeadDynamics.displMicronCIallYMean, um);        
    else
        plot(TimeStamps(FramesDoneNumbers), repmat(displMicronMuHatAllYMean, FrameCount, 1)', Style1, 'LineWidth', 1)   
        plot(TimeStamps(FramesDoneNumbers), repmat(displMicronCIallYMean, FrameCount, 1)', Style2, 'LineWidth', 1)
        txt = sprintf('\\mu=%0.5f, CI = [%0.5f, %0.5f] %s', displMicronMuHatAllYMean, displMicronCIallYMean, um);        
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
        plot(TimeStamps(FramesDoneNumbers), repmat(NegativeBeadDynamics.veloMicronPerSecMuHatAllYMean, FrameCount, 1)', Style1, 'LineWidth', 1)   
        plot(TimeStamps(FramesDoneNumbers), repmat(NegativeBeadDynamics.veloMicronPerSecCIallYMean, FrameCount, 1)', Style2, 'LineWidth', 1)
        txt = sprintf('\\mu=%0.5f, CI = [%0.5f, %0.5f] %s/s', NegativeBeadDynamics.veloMicronPerSecMuHatAllYMean, NegativeBeadDynamics.veloMicronPerSecCIallYMean, um);
    else
        plot(TimeStamps(FramesDoneNumbers), repmat(veloMicronPerSecMuHatAllYMean, FrameCount, 1)', Style1, 'LineWidth', 1)   
        plot(TimeStamps(FramesDoneNumbers), repmat(veloMicronPerSecCIallYMean, FrameCount, 1)', Style2, 'LineWidth', 1)    
        txt = sprintf('\\mu=%0.5f, CI = [%0.5f, %0.5f] %s/s', veloMicronPerSecMuHatAllYMean, veloMicronPerSecCIallYMean, um);
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
        plot(TimeStamps(FramesDoneNumbers), repmat(NegativeBeadDynamics.accelMicronPerSecSqMuHatAllYMean, FrameCount, 1)', Style1, 'LineWidth', 1)   
        plot(TimeStamps(FramesDoneNumbers), repmat(NegativeBeadDynamics.accelMicronPerSecSqCIallYMean, FrameCount, 1)', Style2, 'LineWidth', 1)
        txt = sprintf('\\mu=%0.5f, CI = [%0.5f, %0.5f] %s/s^2', NegativeBeadDynamics.accelMicronPerSecSqMuHatAllYMean, NegativeBeadDynamics.accelMicronPerSecSqCIallYMean, um);
    else
        plot(TimeStamps(FramesDoneNumbers), repmat(accelMicronPerSecSqMuHatAllYMean, FrameCount, 1)', Style1, 'LineWidth', 1)   
        plot(TimeStamps(FramesDoneNumbers), repmat(accelMicronPerSecSqCIallYMean, FrameCount, 1)', Style2, 'LineWidth', 1)
        txt = sprintf('\\mu=%0.5f, CI = [%0.5f, %0.5f] %s/s^2', accelMicronPerSecSqMuHatAllYMean, accelMicronPerSecSqCIallYMean, um);
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
                BeadDynamicsAllPNGNorm = fullfile(NetDisplacementPath, 'Bead Dynamics All Norm.png');
                fprintf('Bead Dynamics (All - Norm) *.png File Name is: \n\t %s\n', BeadDynamicsAllPNGNorm);
                BeadDynamicsMaxPNGNorm = fullfile(NetDisplacementPath, 'Bead Dynamics Max Norm.png');
                fprintf('Bead Dynamics (Max - Norm) *.png File Name is: \n\t %s\n', BeadDynamicsMaxPNGNorm);
            case 'FIG'                 
                BeadDynamicsAllFIGNorm = fullfile(NetDisplacementPath, 'Bead Dynamics All Norm.fig');
                fprintf('Bead Dynamics (All - Norm) *.fig File Name is: \n\t %s\n', BeadDynamicsAllFIGNorm);
                BeadDynamicsMaxFIGNorm = fullfile(NetDisplacementPath, 'Bead Dynamics Max Norm.fig');
                fprintf('Bead Dynamics (Max - Norm) *.fig File Name is: \n\t %s\n', BeadDynamicsMaxFIGNorm);
            case 'EPS'
                BeadDynamicsAllEPSNorm = fullfile(NetDisplacementPath, 'Bead Dynamics All Norm.eps');
                fprintf('Bead Dynamics (All - Norm) *.eps File Name is: \n\t %s\n', BeadDynamicsAllEPSNorm);
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
                BeadDynamicsAllPNGX = fullfile(NetDisplacementPath, 'Bead Dynamics All X.png');
                fprintf('Bead Dynamics (All - X) *.png File Name is: \n\t %s\n', BeadDynamicsAllPNGX);
                BeadDynamicsMaxPNGX = fullfile(NetDisplacementPath, 'Bead Dynamics Max X.png');
                fprintf('Bead Dynamics (Max - X) *.png File Name is: \n\t %s\n', BeadDynamicsMaxPNGX);
            case 'FIG'                 
                BeadDynamicsAllFIGX = fullfile(NetDisplacementPath, 'Bead Dynamics All X.fig');
                fprintf('Bead Dynamics (All - X) *.fig File Name is: \n\t %s\n', BeadDynamicsAllFIGX);
                BeadDynamicsMaxFIGX = fullfile(NetDisplacementPath, 'Bead Dynamics Max X.fig');
                fprintf('Bead Dynamics (Max - X) *.fig File Name is: \n\t %s\n', BeadDynamicsMaxFIGX);
            case 'EPS'
                BeadDynamicsAllEPSX = fullfile(NetDisplacementPath, 'Bead Dynamics All X.eps');
                fprintf('Bead Dynamics (All - X) *.eps File Name is: \n\t %s\n', BeadDynamicsAllEPSX);
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
                BeadDynamicsAllPNGY = fullfile(NetDisplacementPath, 'Bead Dynamics All Y.png');
                fprintf('Bead Dynamics (All - Y) *.png File Name is: \n\t %s\n', BeadDynamicsAllPNGY);
                BeadDynamicsMaxPNGY = fullfile(NetDisplacementPath, 'Bead Dynamics Max Y.png');
                fprintf('Bead Dynamics (Max - Y) *.png File Name is: \n\t %s\n', BeadDynamicsMaxPNGY);
            case 'FIG'                 
                BeadDynamicsAllFIGY = fullfile(NetDisplacementPath, 'Bead Dynamics All Y.fig');
                fprintf('Bead Dynamics (All - Y) *.fig File Name is: \n\t %s\n', BeadDynamicsAllFIGY);
                BeadDynamicsMaxFIGY = fullfile(NetDisplacementPath, 'Bead Dynamics Max Y.fig');
                fprintf('Bead Dynamics (Max - Y) *.fig File Name is: \n\t %s\n', BeadDynamicsMaxFIGY);
            case 'EPS'
                BeadDynamicsAllEPSY = fullfile(NetDisplacementPath, 'Bead Dynamics All Y.eps');
                fprintf('Bead Dynamics (All - Y) *.eps File Name is: \n\t %s\n', BeadDynamicsAllEPSY);
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
                    BeadDynamicsAllPNGNorm = fullfile(AnalysisPath, '08 Bead Dynamics All Norm.png');
                    fprintf('08 Bead Dynamics (All - Norm) *.png File Name is: \n\t %s\n', BeadDynamicsAllPNGNorm);
                    BeadDynamicsMaxPNGNorm = fullfile(AnalysisPath, '08 Bead Dynamics Max Norm.png');
                    fprintf('08 Bead Dynamics (Max - Norm) *.png File Name is: \n\t %s\n', BeadDynamicsMaxPNGNorm);
                case 'FIG'                 
                    BeadDynamicsAllFIGNorm = fullfile(AnalysisPath, '08 Bead Dynamics All Norm.fig');
                    fprintf('08 Bead Dynamics (All - Norm) *.fig File Name is: \n\t %s\n', BeadDynamicsAllFIGNorm);
                    BeadDynamicsMaxFIGNorm = fullfile(AnalysisPath, '08 Bead Dynamics Max Norm.fig');
                    fprintf('08 Bead Dynamics (Max - Norm) *.fig File Name is: \n\t %s\n', BeadDynamicsMaxFIGNorm);
                case 'EPS'
                    BeadDynamicsAllEPSNorm = fullfile(AnalysisPath, '08 Bead Dynamics All Norm.eps');
                    fprintf('08 Bead Dynamics (All - Norm) *.eps File Name is: \n\t %s\n', BeadDynamicsAllEPSNorm);
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
                    BeadDynamicsAllPNGX = fullfile(AnalysisPath, '08 Bead Dynamics All X.png');
                    fprintf('08 Bead Dynamics (All - X) *.png File Name is: \n\t %s\n', BeadDynamicsAllPNGX);
                    BeadDynamicsMaxPNGX = fullfile(AnalysisPath, '08 Bead Dynamics Max X.png');
                    fprintf('08 Bead Dynamics (Max - X) *.png File Name is: \n\t %s\n', BeadDynamicsMaxPNGX);
                case 'FIG'                 
                    BeadDynamicsAllFIGX = fullfile(AnalysisPath, '08 Bead Dynamics All X.fig');
                    fprintf('08 Bead Dynamics (All - X) *.fig File Name is: \n\t %s\n', BeadDynamicsAllFIGX);
                    BeadDynamicsMaxFIGX = fullfile(AnalysisPath, '08 Bead Dynamics Max X.fig');
                    fprintf('08 Bead Dynamics (Max - X) *.fig File Name is: \n\t %s\n', BeadDynamicsMaxFIGX);
                case 'EPS'
                    BeadDynamicsAllEPSX = fullfile(AnalysisPath, '08 Bead Dynamics All X.eps');
                    fprintf('08 Bead Dynamics (All - X) *.eps File Name is: \n\t %s\n', BeadDynamicsAllEPSX);
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
                    BeadDynamicsAllPNGY = fullfile(AnalysisPath, '08 Bead Dynamics All Y.png');
                    fprintf('08 Bead Dynamics (All - Y) *.png File Name is: \n\t %s\n', BeadDynamicsAllPNGY);
                    BeadDynamicsMaxPNGY = fullfile(AnalysisPath, '08 Bead Dynamics Max Y.png');
                    fprintf('08 Bead Dynamics (Max - Y) *.png File Name is: \n\t %s\n', BeadDynamicsMaxPNGY);
                case 'FIG'                 
                    BeadDynamicsAllFIGY = fullfile(AnalysisPath, '08 Bead Dynamics All Y.fig');
                    fprintf('08 Bead Dynamics (All - Y) *.fig File Name is: \n\t %s\n', BeadDynamicsAllFIGY);
                    BeadDynamicsMaxFIGY = fullfile(AnalysisPath, '08 Bead Dynamics Max Y.fig');
                    fprintf('08 Bead Dynamics (Max - Y) *.fig File Name is: \n\t %s\n', BeadDynamicsMaxFIGY);
                case 'EPS'
                    BeadDynamicsAllEPSY = fullfile(AnalysisPath, '08 Bead Dynamics All Y.eps');
                    fprintf('08 Bead Dynamics (All - Y) *.eps File Name is: \n\t %s\n', BeadDynamicsAllEPSY);
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
                saveas(figHandleBeadDynamicsAllNorm, BeadDynamicsAllPNGNorm, 'png')
                saveas(figHandleBeadDynamicsMaxNorm, BeadDynamicsMaxPNGNorm, 'png')                
                if  strcmpi(AnalysisFolderChoice , 'Yes')
                    saveas(figHandleBeadDynamicsAllNorm, BeadDynamicsAllPNGNorm, 'png')
                    saveas(figHandleBeadDynamicsMaxNorm, BeadDynamicsMaxPNGNorm, 'png')            
                end                

            case 'FIG'
                hgsave(figHandleBeadDynamicsAllNorm, BeadDynamicsAllFIGNorm,'-v7.3')
                hgsave(figHandleBeadDynamicsMaxNorm,  BeadDynamicsMaxFIGNorm,'-v7.3')                
                if  strcmpi(AnalysisFolderChoice , 'Yes')
                    hgsave(figHandleBeadDynamicsAllNorm, BeadDynamicsAllFIGNorm,'-v7.3')         
                    hgsave(figHandleBeadDynamicsMaxNorm, BeadDynamicsMaxFIGNorm,'-v7.3')                             
                end                
                
            case 'EPS'
                print(figHandleBeadDynamicsAllNorm, BeadDynamicsAllEPSNorm,'-depsc')  
                print(figHandleBeadDynamicsMaxNorm, BeadDynamicsMaxEPSNorm,'-depsc')                  
                if  strcmpi(AnalysisFolderChoice , 'Yes')
                    print(figHandleBeadDynamicsAllNorm, BeadDynamicsAllEPSNorm,'-depsc') 
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
                saveas(figHandleBeadDynamicsAllX, BeadDynamicsAllPNGX, 'png')
                saveas(figHandleBeadDynamicsMaxX, BeadDynamicsMaxPNGX, 'png')                
                if  strcmpi(AnalysisFolderChoice , 'Yes')
                    saveas(figHandleBeadDynamicsAllX, BeadDynamicsAllPNGX, 'png')
                    saveas(figHandleBeadDynamicsMaxX, BeadDynamicsMaxPNGX, 'png')            
                end                

            case 'FIG'
                hgsave(figHandleBeadDynamicsAllX, BeadDynamicsAllFIGX,'-v7.3')
                hgsave(figHandleBeadDynamicsMaxX,  BeadDynamicsMaxFIGX,'-v7.3')                
                if  strcmpi(AnalysisFolderChoice , 'Yes')
                    hgsave(figHandleBeadDynamicsAllX, BeadDynamicsAllFIGX,'-v7.3')         
                    hgsave(figHandleBeadDynamicsMaxX, BeadDynamicsMaxFIGX,'-v7.3')                             
                end                
                
            case 'EPS'
                print(figHandleBeadDynamicsAllX, BeadDynamicsAllEPSX,'-depsc')  
                print(figHandleBeadDynamicsMaxX, BeadDynamicsMaxEPSX,'-depsc')                  
                if  strcmpi(AnalysisFolderChoice , 'Yes')
                    print(figHandleBeadDynamicsAllX, BeadDynamicsAllEPSX,'-depsc') 
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
                saveas(figHandleBeadDynamicsAllY, BeadDynamicsAllPNGY, 'png')
                saveas(figHandleBeadDynamicsMaxY, BeadDynamicsMaxPNGY, 'png')                
                if  strcmpi(AnalysisFolderChoice , 'Yes')
                    saveas(figHandleBeadDynamicsAllY, BeadDynamicsAllPNGY, 'png')
                    saveas(figHandleBeadDynamicsMaxY, BeadDynamicsMaxPNGY, 'png')            
                end                

            case 'FIG'
                hgsave(figHandleBeadDynamicsAllY, BeadDynamicsAllFIGY,'-v7.3')
                hgsave(figHandleBeadDynamicsMaxY,  BeadDynamicsMaxFIGY,'-v7.3')                
                if  strcmpi(AnalysisFolderChoice , 'Yes')
                    hgsave(figHandleBeadDynamicsAllY, BeadDynamicsAllFIGY,'-v7.3')         
                    hgsave(figHandleBeadDynamicsMaxY, BeadDynamicsMaxFIGY,'-v7.3')                             
                end                
                
            case 'EPS'
                print(figHandleBeadDynamicsAllY, BeadDynamicsAllEPSY,'-depsc')  
                print(figHandleBeadDynamicsMaxY, BeadDynamicsMaxEPSY,'-depsc')                  
                if  strcmpi(AnalysisFolderChoice , 'Yes')
                    print(figHandleBeadDynamicsAllY, BeadDynamicsAllEPSY,'-depsc') 
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
    
    
    
    %% ________________ CODE DUMPSTER
    
                      

    
%     decimateChoice = questdlg('How do you want to deal with the data', 'Decimate?',...
%          'Decimate by points', 'Decimate by frame', 'Leave as is', 'Decimate by points');
%      
%     switch decimateChoice
%         case {'Decimate by points', 'Decimate by frame'}
%             decimateFactor = inputdlg(sprintf('What is the decimation factor? [Default = %d] ', decimateFactorFramesDefault), 'Decimate Beads?', ...
%                 [1, 50], {num2str(decimateFactorFramesDefault)});
%             if isempty(decimateFactor)
%                 decimateFactor = decimateFactorFramesDefault;
%             else
%                 decimateFactor = str2double(decimateFactor{:});
%             end
%         case 'Leave as is'
%              decimateFactor = 1;
%         otherwise
%             return
%     end
%     switch decimateChoice
%         case {'Decimate by points', 'Leave as is'}
%             FramesDecimated = FramesDoneNumbers;
%             BeadCount = size(displFieldMicronVecNorm, 2);
%             clear displFieldMicronVecNorm_Decimated VelocityFieldMicronVecAllNorm_Decimated AccelerationFieldMicronVecAllNorm_Decimated
%             clear displMicronVecX_Decimated VelocityFieldMicronMicronVecAllX_Decimated AccelerationFieldMicronVecAllX_Decimated
%             clear displFieldMicronVecY_Decimated veloMicronPerSecVecY_Decimated AccelerationFieldMicronVecAllY_Decimated 
% 
%             BeadCountDecimated = 1:decimateFactor:BeadCount;
%             displFieldMicronVecNorm_Decimated = displFieldMicronVecNorm(:,BeadCountDecimated); 
%             VelocityFieldMicronVecAllNorm_Decimated = VelocityFieldMicronVecAllNorm(:,BeadCountDecimated); 
%             AccelerationFieldMicronVecAllNorm_Decimated = AccelerationFieldMicronVecAllNorm(:,BeadCountDecimated); 
%             displMicronVecX_Decimated = displFieldMicronVecX(:,BeadCountDecimated); 
%             VelocityFieldMicronMicronVecAllX_Decimated = VelocityFieldMicronMicronVecAllX(:,BeadCountDecimated); 
%             AccelerationFieldMicronVecAllX_Decimated = AccelerationFieldMicronVecAllX(:,BeadCountDecimated); 
%             displFieldMicronVecY_Decimated = displFieldMicronVecY(:,BeadCountDecimated); 
%             veloMicronPerSecVecY_Decimated = VelocityFieldMicronVecAllY(:,BeadCountDecimated); 
%             AccelerationFieldMicronVecAllY_Decimated = AccelerationFieldMicronVecAllY(:,BeadCountDecimated); 
%             
%         case 'Decimate by frame' 
%             FramesDecimated = FramesDoneNumbers(1):decimateFactor:FramesDoneNumbers(end);
%             clear displFieldMicronVecNorm_Decimated VelocityFieldMicronVecAllNorm_Decimated AccelerationFieldMicronVecAllNorm_Decimated
%             clear displMicronVecX_Decimated VelocityFieldMicronMicronVecAllX_Decimated AccelerationFieldMicronVecAllX_Decimated
%             clear displFieldMicronVecY_Decimated veloMicronPerSecVecY_Decimated AccelerationFieldMicronVecAllY_Decimated
% 
%             displFieldMicronVecNorm_Decimated = displFieldMicronVecNorm(FramesDecimated, :); 
%             VelocityFieldMicronVecAllNorm_Decimated = VelocityFieldMicronVecAllNorm(FramesDecimated, :); 
%             AccelerationFieldMicronVecAllNorm_Decimated = AccelerationFieldMicronVecAllNorm(FramesDecimated, :); 
%             displMicronVecX_Decimated = displFieldMicronVecX(FramesDecimated, :); 
%             VelocityFieldMicronMicronVecAllX_Decimated = VelocityFieldMicronMicronVecAllX(FramesDecimated, :); 
%             AccelerationFieldMicronVecAllX_Decimated = AccelerationFieldMicronVecAllX(FramesDecimated, :); 
%             displFieldMicronVecY_Decimated = displFieldMicronVecY(FramesDecimated, :); 
%             veloMicronPerSecVecY_Decimated = VelocityFieldMicronVecAllY(FramesDecimated, :); 
%             AccelerationFieldMicronVecAllY_Decimated = AccelerationFieldMicronVecAllY(FramesDecimated, :);                         
%     end
    
 



      
%     save(NetDisplacementNameMAT, 'MD', 'FirstFrame', 'LastFrame', 'ScaleMicronPerPixel', 'maxDisplacementMicron', ...
%         'displField', 'displFieldMicron', 'displMicronVecX','displMicronVecNorm', 'displMicronMaxVecY','displMicronMaxVecNorm', 'displFieldMicronMax', ...
%         'displMicronMaxVecX', 'displFieldMicronMaxVecY', 'displFieldMicronMaxVecNorm', ...
%         'VelocityField', 'VelocityFieldMicronPerSec', 'VelocityFieldMax', 'VelocityFieldMicronPerSecMax', ...
%         'VelocityFieldMicronVecAllNorm', 'VelocityFieldMax', 'VelocityFieldMaxVecNorm', 'totalPoints', ...
%         'AccelerationField', 'AccelerationFieldMicronPerSecSq', 'AccelerationFieldMax', 'AccelerationFieldMicronPerSecSqMax', ...
%         'AccelerationFieldMicronVecAllNorm', 'AccelerationFieldMax', 'AccelerationFieldMaxVecNorm', 'StatAlpha', '-append');       
%     save(NetDisplacementNameMAT, 'displFieldMaxDisplPixelsNet','MaxPosPixelsXYnet', 'MaxDisplFrameNumber', 'MaxDisplFieldIndex', 'MaxDisplPixelsXYnet', ...
%        'MaxDisplMicronsXYnet', '-append')
%    
%     save(NetDisplacementNameMAT, ...
%                     'displMicronMuHatAllNorm', 'displMicronMuHatAllNormMean', 'displMicronCIallNorm', 'displMicronCIallNormMean', ...
%                     'displMicronMuHatAllX',    'displMicronMuHatAllXMean',    'displMicronCIallX', 'displMicronCIallXMean', ...
%                     'displMicronMuHatAllY',    'displMicronMuHatAllYMean',    'displMicronCIallY', 'displMicronCIallYMean', ...
%                     'displMicronMuHatMaxNorm', 'displMicronMuHatMaxX',    'displMicronMuHatMaxY',        '-append')
%     save(NetDisplacementNameMAT, 'NegativeBeadDynamicsStatsChoice', '-append')
%    
%     save(NetDisplacementNameMAT,  'VelocitymuHatMaxX', 'VelocitysigmaHatMaxX', 'veloMuCImaxX', 'VelocitySigmaCImaxX', 'VelocityCImaxX', ... 
%         'AccelerationmuHatMaxX', 'AccelerationsigmaHatMaxX', 'AccelerationMuCImaxX', 'AccelerationSigmaCImaxX', 'AccelerationCImaxX', ...
%         'VelocityFieldMaxVecX', 'AccelerationFieldMaxVecX', '-append')
%     save(NetDisplacementNameMAT,  'VelocitymuHatMaxY', 'VelocitysigmaHatMaxY', 'VelocityMuCImaxY', 'VelocitySigmaCImaxY', 'VelocityCImaxY', ... 
%         'AccelerationmuHatMaxY', 'AccelerationsigmaHatMaxY', 'AccelerationMuCImaxY', 'AccelerationSigmaCImaxY', 'AccelerationCImaxY', ...
%         'VelocityFieldMaxVecY', 'AccelerationFieldMaxVecY', '-append')    
%     save(NetDisplacementNameMAT, 'VelocitymuHatMaxNorm', 'VelocitysigmaHatMaxNorm', 'VelocityMuCImaxNorm', 'VelocitySigmaCImaxNorm', 'VelocityCImaxNorm', ... 
%         'AccelerationmuHatMaxNorm', 'AccelerationsigmaHatMaxNorm', 'AccelerationMuCImaxNorm', 'AccelerationSigmaCImaxNorm', 'AccelerationCImaxNorm',...
%         'VelocityFieldMaxVecNorm', 'AccelerationFieldMaxVecNorm', '-append')      
%     save(NetDisplacementNameMAT, 'VelocitymuHatAllX', 'VelocitysigmaHatAllX', 'VelocityMuCIallX', 'VelocitySigmaCIallX', 'VelocityCIallX', ... 
%         'AccelerationmuHatAllX', 'AccelerationsigmaHatAllX', 'AccelerationMuCIallX', 'AccelerationSigmaCIallX', 'AccelerationCIallX', ...
%         'VelocityFieldMicronMicronVecAllX', 'AccelerationFieldMicronVecAllX', '-append')
%     save(NetDisplacementNameMAT, 'VelocitymuHatAllY', 'VelocitysigmaHatAllY', 'VelocityMuCIallY', 'VelocitySigmaCIallY', 'VelocityCIallY', ... 
%         'AccelerationmuHatAllY', 'AccelerationsigmaHatAllY', 'AccelerationMuCIallY', 'AccelerationSigmaCIallY', 'AccelerationCIallY', ...
%         'VelocityFieldMicronVecAllY', 'AccelerationFieldMicronVecAllY', '-append')
%     save(NetDisplacementNameMAT, 'VelocitymuHatAllNorm', 'VelocitysigmaHatAllNorm', 'VelocityMuCIallNorm', 'VelocitySigmaCIallNorm', 'VelocityCIallNorm', ... 
%         'AccelerationmuHatAllNorm', 'AccelerationsigmaHatAllNorm', 'AccelerationMuCIallNorm', 'AccelerationSigmaCIallNorm', 'AccelerationCIallNorm', ...
%         'VelocityFieldMicronVecAllNorm', 'AccelerationCIallNorm', '-append')
%     save(NetDisplacementNameMAT, 'VelocitymuHatAllNormMean' , 'VelocityCIallNormMean' , 'AccelerationmuHatAllNormMean', 'AccelerationCIallNormMean', ...
%         'VelocitymuHatAllXMean', 'VelocityCIallXMean', 'AccelerationmuHatAllXMean', 'AccelerationCIallXMean', 'VelocitymuHatAllYMean', 'VelocityCIallYMean', ...
%         'AccelerationmuHatAllYMean', 'AccelerationCIallYMean', '-append')
    
%     try
%         save(NetDisplacementNameMAT, 'MagnificationTimes', '-append')
%     catch
%         % do nothing
%     end
%     save(NetDisplacementNameMAT, 'TimeStamps', '-append')