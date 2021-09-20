%{
    
    v.2020-05-14 by Waddah Moghram
        1. Renamed "YoungModulusOptimizationFromEnergyL2.m" to signify the iterative L2-norm regularization previously
    v.2020-05-07 by Waddah Moghram
        1. just cleaned up the code to be more understable.
        2. Changed some variable names to make them more understable.
    v.2020-05-07 by Waddah Moghram
        1. just cleaned up the code to be more understable.
        2. Changed some variable names to make them more understable.
    v.2020-03-23 by Waddah Moghram
        1. Update to be compatible with the latest CalculateForceMT.m v.2020-03-11
    v.2020-03-05..09 by Waddah Moghram based on YoungModulusOptimizationFromForces.m v.2020-03-05
%}

    %% 0 ==================== Initialize variables ==================== 
    commandwindow;
    
    ConversionNtoNN = 1e9;
    CycleNumber = 2;                % choose the second cycle for optimization of elastic modulus
    DCchoice = 'Yes';
    EdgeErode = 1;
    FilterChoiceStr = 'Wiener 2D';
    FrameDisplMeanChoice = 'No';    
    gridMagnification = 1;          %% (to go with the rectangular grid created to interpolate displField)
    GridtypeChoiceStr = 'Even Grid';
    HanWindowchoice = 'Yes';
    IdenticalCornersChoice = 'Yes';
    InterpolationMethod = 'griddata';
    PaddingChoiceStr = 'Padded with zeros only';                % Updated on 2020-03-03 by WIM
    TractionForceMethod = 'Summed';
    WienerWindowSize = 3 ;    % 3x3 window for Wiener2D Spatial Filter

    % Choose control mode (controlled force vs. controlled displacement).  
    controlMode = 'Controlled Force';               % for now that is the only way we can apply a known force from MT 2020-02-11
%     dlgQuestion = 'What is the control mode for this EPI/DIC experiment? ';
%     dlgTitle = 'Control Mode?';
%     controlMode = questdlg(dlgQuestion, dlgTitle, 'Controlled Force', 'Controlled Displacement', 'Controlled Force');
%     if isempty(controlMode), error('Choose a control mode'); end  
%        
        
    %% 1 ==================== load EPI Movie Data (MD) ==================== 
    [movieFileName, movieFilePath] = uigetfile('*.mat','EPI TFM-Package Movie Data File');
    if movieFileName == 0, return; end
    MovieFileFullName = fullfile(movieFilePath, movieFileName);
    try 
        load(MovieFileFullName, 'MD')
        fprintf('Movie Data (MD) file is: \n\t %s\n', MovieFileFullName);
        disp('------------------------------------------------------------------------------')
    catch 
        errordlg('Could not open the EPI movie data file!')
        return
    end
    movieData = MD;
        
    %% 2 ==================== ask for & load tracked displacement file (displField.mat) ==================== 
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
    if exist('ProcessTag', 'var') 
        fprintf('Displacement Process Tag is: %s\n', ProcessTag);
        try
            DisplacementFileFullName = MD.findProcessTag(ProcessTag).outFilePaths_{1};
            if exist(DisplacementFileFullName, 'file')
                dlgQuestion = sprintf('Do you want to open the displacement field referred to in the movie data file?\n\n%s\n', ...
                    DisplacementFileFullName);
                dlgTitle = 'Open displacement field (displField.mat) file?';
                OpenDisplacementChoice = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No', 'Yes');
                switch OpenDisplacementChoice
                    case 'Yes'
                        [displacementFilePath, ~, ~] = fileparts(DisplacementFileFullName);
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
    if isempty(DisplacementFileFullName)    
        TFMPackageFiles = fullfile(movieFilePath,'TFMPackage','*.mat');
        [displacementFileName, displacementFilePath] = uigetfile(TFMPackageFiles, '**Drift-Corrected**  EPI displacement field "displField.mat"  (Filtered DC)');
        if displacementFileName == 0, return; end
        DisplacementFileFullName = fullfile(displacementFilePath, displacementFileName);
    end
    try
        load(DisplacementFileFullName, 'displField');   
        fprintf('EPI Drift-Corrected Displacement Field (displField) File is successfully loaded!: \n\t %s\n', DisplacementFileFullName);
        disp('------------------------------------------------------------------------------')
    catch
        errordlg('Could not open Drift-Corrected EPI displacement field file.');
        return
    end
    
    %% 3 ==================== ask if EPI Displacement Grid Padding is needed ==================== 
    if ~exist('PaddingChoiceStr', 'var'), PaddingChoiceStr= []; end
    PaddingListStr = {'No padding', 'Padded with random & zeros', 'Padded with zeros only'};    
    if isempty(PaddingChoiceStr)        
        dlgQuestion = ({'Pad displacement array?'});
        PaddingChoiceStr = listdlg('ListString', PaddingListStr, 'PromptString',dlgQuestion ,'InitialValue', 2, 'SelectionMode' ,'single'); 
        try
            PaddingChoiceStr = PaddingListStr{PaddingChoiceStr};                 % get the names of the string.   
        catch
            return
        end
    end
    
    %% 4 ==================== ask if EPI Displacement Grid Han-Windowing is needed ====================
    if ~exist('HanWindowchoice', 'var'), HanWindowchoice = []; end    
    if isempty(HanWindowchoice)
        HanWindowchoice = questdlg('Do you want to add a Han Window?', 'Han Window?', 'Yes', 'No', 'Yes');
    end
    switch HanWindowchoice
        case 'Yes'
            HanWindowBoolean = true;
        case 'No'
            HanWindowBoolean = false;
            % Continue
        otherwise
            return
    end

    %% 5 ==================== load EPI Traction Stress Field ("Force Field") & Parameters (forcefield.mat) ==================== 
    if exist('forceFieldParametersFullFileName', 'var') && exist('forceFieldParameters', 'var')
        forceFieldParametersFileChoice = questdlg(sprintf('Do you want to use this EPI ''force'' field parameteres file? \n\t %s', forceFieldParametersFullFileName), 'Force Field Parameters?','Yes', 'No', 'Yes'); 
    else
        forceFieldParametersFileChoice = 'No';
    end    
    switch forceFieldParametersFileChoice
        case 'Yes'
            % do nothing
        case 'No'
            [forceFieldParametersFile, forceFieldParametersPath] = uigetfile(fullfile(fullfile(displacementFilePath, '..'), '*.mat'), ' EPI traction stress ''forceFieldParameters.mat'' file');  
            if forceFieldParametersPath == 0, error('No file was selected'); end                       % Cancel was chosen
            forceFieldParametersFullFileName = fullfile(forceFieldParametersPath, forceFieldParametersFile);   
            forceFieldProcessStruct = load(forceFieldParametersFullFileName);
            try
                forceFieldCalculationInfo = forceFieldProcessStruct.forceFieldProc;
            catch
                forceFieldCalculationInfo = '[NONE IDENTIFIED]';
            end
            fprintf('forceField parameters successfully: \n\t %s \n', forceFieldParametersFullFileName)
            forceFieldParameters = forceFieldProcessStruct.forceFieldParameters;   
            try
                movieData = forceFieldProcessStruct.movieDataAfter;
            catch
                try
                    movieData = forceFieldProcessStruct.movieData;        
                catch
                    [movieFileName, movieFilePath] = uigetfile('*.mat', 'EPI TFM-Package Movie Data File');
                    if movieFileName == 0, error('No Movie data file was selected'); end
                    MovieFileFullName = fullfile(movieFilePath, movieFileName);
                    try 
                        load(MovieFileFullName, 'MD')
                        fprintf('Movie Data (MD) file is: \n\t %s\n', MovieFileFullName);
                        disp('------------------------------------------------------------------------------')
                    catch 
                        error('Could not open the movie data file!')
                    end
                    try 
                        isMD = (class(MD) ~= 'MovieData');
                    catch 
                        error('Could not open the movie data file!')
                    end 
                    movieData = MD;
                end
            end
        otherwise
            return
    end
    
    %% 6 ==================== load MT Energy and Cycle information ==================== 
    [ForceFileDICname, ForceFileDICpath] = uigetfile(fullfile(movieData.outputDirectory_,'*.mat'), ...
        '''05 Force Compiled Results.mat''__under DIC tracking output');
    if ForceFileDICname == 0, return; end
    ForceFileDICFullName = fullfile(ForceFileDICpath, ForceFileDICname);
    try
        MT_Force_xy_N_struct = load(ForceFileDICFullName);  
        MT_Force_xy_N = MT_Force_xy_N_struct.Force_xy_N;
        WorkBeadJ_Half_Cycles = MT_Force_xy_N_struct.WorkBeadJ_Half_Cycles;
        totalCycles = numel(WorkBeadJ_Half_Cycles);
        if ~exist('CycleNumber', 'var'), CycleNumber = []; end
        if isempty(CycleNumber)
           CycleNumberStr = inputdlg(sprintf('Enter the cycle number want [Number of Cycles = %d]: ', totalCycles), 'Cycle Number', 1, ...
               {num2str(round(totalCycles/2))});
           CycleNumber =  str2double(CycleNumberStr{:});
        end
        WorkCycleFirstFrames = unique(MT_Force_xy_N_struct.WorkCycleFirstFrame);
        WorkCycleFirstFrames(isnan(WorkCycleFirstFrames)) = [];
        WorkCycleFirstFrames = WorkCycleFirstFrames(1:totalCycles);
        WorkCycleLastFrames = unique(MT_Force_xy_N_struct.WorkCycleLastFrame);
        WorkCycleLastFrames(isnan(WorkCycleLastFrames)) = [];        
        WorkCycleFirstFrame = WorkCycleFirstFrames(CycleNumber);
        WorkCycleLastFrame = WorkCycleLastFrames(CycleNumber);
    catch
%         error('Could not load Bead work');
% %         MT_Force_xy_N_struct = load(ForceFileDICFullName);
% %         WorkBeadJ_Half_Cycle = MT_Force_xy_N_struct.CompiledDataStruct.Force_xy_N;
    end

    WorkBeadJ_Half_Cycle = WorkBeadJ_Half_Cycles(CycleNumber);
    
    %% 7 ==================== ask for Initial Guess for Young Elastic Modulus  ====================
    dlgTitle = 'Initial Young Modulus';
    prompt = 'What is the Initial Young Modulus (Pa) guessed?';
    try
        YoungModulusInitialGuess = forceFieldCalculationInfo.funParams_.YoungModulus;
    catch
        YoungModulusInitialGuess = 100;
    end
    YoungModulusInitialDefault = {num2str(YoungModulusInitialGuess)};
    YoungModulusInitialGuess = inputdlg(prompt, dlgTitle, [1 40], YoungModulusInitialDefault);
    if isempty(YoungModulusInitialGuess), return; end
    YoungModulusInitialGuess = str2double(YoungModulusInitialGuess{1});                         % Convert to a number
    
    %% 8 ==================== ask where to save output ==================== 
    try
       ModulusPathName = uigetdir(displacementFilePath, 'Where do you want to save Energy-Based Optimized Young Modulus');
    catch
       ModulusPathName = uigetdir('Where do you want to save the Optimized Young Modulus'); 
    end
    if isempty(ModulusPathName), ModulusPathName = pwd; end
    
    %% 9 ==================== choose the scale (microns/pixels) ==================== 
    try
        ScaleMicronPerPixel = movieData.pixelSize_/1000;           % from Nanometers/pixel to micron/pixel
    catch
        % continue
    end
    if exist('ScaleMicronPerPixel', 'var')
        dlgQuestion = sprintf('Do you want the scaling found in the movie file (%0.5g micron/pixels)?', ScaleMicronPerPixel);
        dlgTitle = 'Use Embedded Scale?';
        ScalingChoice = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No', 'Yes');
    else
        ScalingChoice = 'No';
    end
    switch ScalingChoice
        case 'No'
            [ScaleMicronPerPixel, ~, ~] = MagnificationScalesMicronPerPixel();    
        case 'Yes'
            % Continue
        otherwise 
            return
    end
    fprintf('Magnification scale is %.5f microns/pixel\n', ScaleMicronPerPixel)
        
    %% 10 =================== load timestamps ====================
    FramesDoneBooleanMT = arrayfun(@(x) ~isempty(x), MT_Force_xy_N');
    FramesDoneNumbersMT = find(FramesDoneBooleanMT == 1);

    FramesDoneBooleanEPI = arrayfun(@(x) ~isempty(x.vec), displField);
    FramesDoneNumbersEPI = find(FramesDoneBooleanEPI == 1);
    
    FirstFrame = 1;
    LastFrame = min(numel(FramesDoneBooleanMT), numel(FramesDoneBooleanEPI));
    FramesDoneBoolean = FramesDoneBooleanMT(FirstFrame:LastFrame) & FramesDoneBooleanEPI(FirstFrame:LastFrame);
    
    FirstFrame = find(FramesDoneBoolean, 1);
    LastFrame = find(FramesDoneBoolean, 1, 'last');
%  
    switch controlMode
        case 'Controlled Force'
            dlgQuestion = ({'Do you have a timestamps?'});
            dlgTitle = 'EPI/DIC Time Stamp RT file from sensor files?';
            TimeStampChoice = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No', 'Yes');
            if isempty(TimeStampChoice), error('Choose a EPI timestampsRT file'); end
            switch TimeStampChoice
                case 'Yes'
                    [TimeStampFileNameDIC, TimeStampPathDIC] = uigetfile(ForceFileDICpath, 'DIC TimeStampsRT Sec');
                    if isempty(TimeStampFileNameDIC), error('No File Was chosen'); end
                    TimeStampFullFileNameDIC = fullfile(TimeStampPathDIC, TimeStampFileNameDIC);
                    TimeStampsRelativeRT_SecDataDIC = load(TimeStampFullFileNameDIC);
                    TimeStampsDIC = TimeStampsRelativeRT_SecDataDIC.TimeStampsAbsoluteRT_Sec;
                    FrameRateDIC = 1/mean(diff(TimeStampsRelativeRT_SecDataDIC.TimeStampsRelativeRT_Sec));
                    fprintf('DIC RT Timestamps file is: \n\t %s\n', TimeStampFullFileNameDIC);
                    
                    [TimeStampFileNameEPI, TimeStampPathEPI] = uigetfile(movieData.outputDirectory_, 'EPI TimeStampsRT Sec');
                    if isempty(TimeStampFileNameEPI), error('No File Was chosen'); end
                    TimeStampFullFileNameEPI = fullfile(TimeStampPathEPI, TimeStampFileNameEPI);
                    TimeStampsRelativeRT_SecDataEPI = load(TimeStampFullFileNameEPI);
                    TimeStampsEPI = TimeStampsRelativeRT_SecDataEPI.TimeStampsAbsoluteRT_Sec;
                    FrameRateEPI = 1/mean(diff(TimeStampsRelativeRT_SecDataEPI.TimeStampsRelativeRT_Sec));
                    fprintf('EPI RT Timestamps file is: \n\t %s\n', TimeStampFullFileNameEPI);
                    
                    TimeStampsEnd = min(TimeStampsDIC(end), TimeStampsEPI(end));
                    FrameRate = mean([FrameRateDIC, FrameRateEPI]);
                    LastFrame = floor(TimeStampsEnd * FrameRate);                    
                    TimeStamps = ((FirstFrame:LastFrame) - FirstFrame) ./ FrameRate;
                case 'No'
                    try
                        [TimeStamps, ~] = TimestampRTfromSensorData();
                    catch
                        try 
                            FrameRate = 1/movieData.timeInterval_;
                        catch
                            FrameRate = 1/ 0.025;           % (40 frames per seconds)              
                        end
                        prompt = {sprintf('Choose the Frame Rate per second for this movie. [Default, %.4f]', FrameRate)};
                        dlgTitle =  'Frames Per Second';
                        FrameRateStr = inputdlg(prompt, dlgTitle, [1, 90], {num2str(FrameRate)});
                        if isempty(FrameRateStr), error('No Frame Rate was chosen'); end
                        FrameRate = str2double(FrameRateStr{1});                                  % Convert to a number                                              
                        TimeStamps = ((FirstFrame:LastFrame) - FirstFrame)./ FrameRate;
                    end
                otherwise
                    return
            end
        case 'Controlled Displacement'              % incomplete
%             try
%                 try
%                     [TimeStamps, ~, AverageFrameRate] = ND2TimeFrameExtract(movieData.channels_.channelPath_);
%                 catch
%                     [TimeStamps, ~, AverageFrameRate] = ND2TimeFrameExtract(movieData.movieDataPath_);            
%                 end
%                 FrameRate = 1/AverageFrameRate;
%             catch
%                 try 
%                     FrameRate = 1/movieData.timeInterval_;
%                 catch
%                     FrameRate = 1/ 0.025;           % (40 frames per seconds)              
%                 end
%             end
    end    

    %% 11 =================== find first & last frame numbers based on timestamp ==================== 
    FirstTimeInputSec = TimeStampsDIC(WorkCycleFirstFrame);
    LastTimeInputSec = TimeStampsDIC(WorkCycleLastFrame);

    switch controlMode
        case 'Controlled Force'            
            FirstFrameDIC = find((FirstTimeInputSec - TimeStampsDIC) <= 0, 1);               % Find the index of the first frame to be found.
            fprintf('First DIC frame to be plotted is: %d.\n', FirstFrameDIC)
            FirstFrameEPI = find((FirstTimeInputSec - TimeStampsEPI) <= 0, 1);               % Find the index of the first frame to be found.
            fprintf('First EPI frame to be plotted is: %d.\n', FirstFrameEPI)
            LastFrameDIC = find((LastTimeInputSec - TimeStampsDIC) <= 0,1);
            fprintf('Last DIC frame to be plotted is: %d.\n', LastFrameDIC)            
            LastFrameEPI = find((LastTimeInputSec - TimeStampsEPI) <= 0,1);
            fprintf('Last EPI frame to be plotted is: %d.\n', LastFrameEPI)
            
            FrameNumbersDIC = FirstFrameDIC:LastFrameDIC;
            FrameNumbersEPI = FirstFrameEPI:LastFrameEPI;            
            %__ Trim to make sure you get the same number of samples for both
            FramesSize = min([numel(FrameNumbersDIC), numel(FrameNumbersEPI)]);
            FrameNumbersDIC = FrameNumbersDIC(1:FramesSize);
            FrameNumbersEPI = FrameNumbersEPI(1:FramesSize);            
        case 'Controlled Displacement'          % incomplete. I need to include a step to line both modes up. 
%             FirstFrame = find((FirstTimeInputSec - TimeStamps) <= 0, 1);               % Find the index of the first frame to be found.
%             fprintf('First frame to be plotted is: %d.\n', FirstFrame); 
%             LastFrame = find((LastTimeInputSec - TimeStamps) <= 0,1);
%             fprintf('Last frame to be plotted is: %d.\n', LastFrame)
%             
%             LastFrameEPI = LastFrame;
%             LastFrameDIC = LastFrame;
%             FirstFrameEPI = FirstFrame;
%             FirstFrameDIC = FirstFrame;            
    end
              
    %% 12 =================== find the optimized Young Elastic Modulus from energetics ====================      
    commandwindow;
    
    tolerancepower = input('How many decimal places do you want the solution to be? [Default = 2]: ');         % number of significant figures beyond decimal
    if isempty(tolerancepower), tolerancepower = 2; end
    tolerance = 10^(-tolerancepower);
    
    options = optimset('Display', 'iter', 'TolX', tolerance);
    clc
    disp('______________________________________________________________________')
    diary fullfile(ModulusPathName, 'Young Modulus based on energetics.txt')
    diary on
    fprintf('Optimzation output will be saved under:\n\t%s\n', ModulusPathName);
    fprintf('\t Half Cycle Work (U) = %0.16g J. (Cycle #%d)\n', WorkBeadJ_Half_Cycle, CycleNumber)        
    disp('Evaluating Optimized Young Modulus...in progress.')
    [YoungModulusOptimum, YoungModulusOptimumRMSE] = fminsearch(@(YoungModulus)abs(WorkBeadJ_Half_Cycle - Net_Energy_Stored_TFM_L2(movieData, displField, forceFieldParameters,...
        FirstFrameEPI, LastFrameEPI, YoungModulus,  PaddingChoiceStr, HanWindowchoice, WienerWindowSize, ScaleMicronPerPixel)), YoungModulusInitialGuess, options); 
    
    YoungModulusOptimum = round(YoungModulusOptimum, tolerancepower, 'decimals');
    [Net_Energy_Stored, reg_corner] = Net_Energy_Stored_TFM_L2(movieData, displField, forceFieldParameters,...
        FirstFrameEPI, LastFrameEPI, YoungModulusOptimum,  PaddingChoiceStr, HanWindowchoice, WienerWindowSize, ScaleMicronPerPixel);
    disp('Evaluating Optimized Young Modulus...complete.')
    
    %% 13 =================== saving the optimized Young Elastic Modulus & parameters ==================== 
    YoungModulusOptimizationOutput = fullfile(ModulusPathName, sprintf('Young Modulus based on energetics %g Pa.mat', YoungModulusOptimum));
        
    save(YoungModulusOptimizationOutput, 'movieData', 'displField', 'forceFieldParameters', 'TimeStampsEPI', 'TimeStampsDIC', ...
        'FirstFrameDIC', 'FirstFrameEPI', 'LastFrameDIC', 'LastFrameEPI', 'YoungModulusInitialGuess', ...
        'TractionForceMethod', 'gridMagnification', 'WorkBeadJ_Half_Cycle', 'CycleNumber', 'YoungModulusOptimum', 'YoungModulusOptimumRMSE', ...
        'reg_corner', 'GridtypeChoiceStr', 'PaddingChoiceStr', 'FilterChoiceStr', 'WienerWindowSize', ...
        'HanWindowBoolean', 'reg_corner', 'options', '-v7.3');
    
    toleranceString = sprintf('%%0.%df', abs(tolerancepower));
    promptString = sprintf('The optimized Young''s Modulus is ***%s Pa***.\n', toleranceString);
    fprintf(promptString, YoungModulusOptimum);
    
    disp('---------------------Optimizing Young Modulus Complete!!!! ------------------')
    fprintf('The optimized Young''s Modulus is ***%g Pa***.\n', YoungModulusOptimum);
    fprintf('The optimized L-Curve regularization parameter (reg_corner) = %g\n', reg_corner(1));
    
    fprintf('The optimized Young''s Modulus rounded to %d decimals is ~ ***%g Pa***.\n', tolerancepower, YoungModulusOptimumRounded);
    fprintf('The optimized L-Curve regularization parameter for rounded E (reg_cornerRounded) = %g\n', reg_cornerRounded(1));
    
    fprintf('The optimized Young''s Modulus file is saved in:\n\t%s\n', YoungModulusOptimizationOutput);
    diary off
    disp('---------------------Optimizing Young Modulus Complete!!!! ------------------');
