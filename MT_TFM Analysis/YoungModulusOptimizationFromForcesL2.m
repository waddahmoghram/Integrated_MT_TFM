%{
    v.2020-05-14 by Waddah Moghram
        1. Renamed "YoungModulusOptimizationFromForcesL2.m" to signify the iterative L2-norm regularization previously
    v.2020-05-07 by Waddah Moghram
        1. just cleaned up the code to be more understable.
        2. Changed some variable names to make them more understable.
    v.2020-03-23 by Waddah Moghram
        1. Update to be compatible with the latest CalculateForceMT.m v.2020-03-11
    v.2020-03-05 by Waddah Moghram
        1. Renamed YoungModulusOptimization.m to  YoungModulusOptimizationFromForces.m
    v.2020-03-03..04 by Waddah Moghram
        1. padded with zeros only.
        2. L-curve for padded, filtered and windowed curve.
    v.2020-02-11 by Waddah Moghram
        1. Make sure to normalize the results with respect to frame number for controlled force.
        2. Updated optimization parameters to match those in TractionForceFieldAllFramesScripts.
        3. Temporarily commented out drift-correction for EPI mode, since DIC needs to be corrected as well. 
            * Simply feed drift-corrected MT force and drift-corrected TFM force
    v.2020-01-28 by Waddah Moghram
        1. Updated grid choice to 0.9 for high resolution, 1 for low-resolution
        2. Updated grid magnification down from 2.0 to 1.0
        3. output reg_corner. reg_corner is no longer an input and is evaluated every time to arrive at a more accurate solution
    v.2020-01-19 by Waddah Moghram
        1. Gives the user the option of choosen a drift-corrected displacement field.
    v.2020-01-04 Updated by Waddah Moghram, PhD Student in Biomedical Engineering at the University of Iowa.
        1. The final YoungModulusOptimum is rounded to the tolerance level of 1e-1
    v.2019-12-28 Updated by Waddah Moghram
        1. Fixed Drift correction to find it in every frame.
    v.2019-12-18 Updated by Waddah Moghram, PhD Student in Biomedical Engineering at the University of Iowa.
        1. corrected drift displacements before feeding it into the RMSE optimization part.
    v.2019-12-16 Updatd by Waddah Moghram:
        1. Add option for Han-Windowing, and Padding with Randoms and Zeros.
            based heavily on TractionForceFieldAllFramesFiltered.m v.2019-12-14

    v.2019-10-14 Written by Waddah Moghram:
        This will find the elastic modulus that will miminze the error between the TFM and MT force
        This Script will invoke MT_TFM_RMSE() function repeatedly using fminsearch until the solution is found.
%}

    %% 0 ==================== Initialize variables ==================== 
    commandwindow;

    ConversionNtoNN = 1e9;            
    DCchoice = 'Yes';
    EdgeErode = 1;
    SpatialFilterChoiceStr = 'Wiener 2D';
    FrameDisplMeanChoice = 'No';    
    gridMagnification = 1;                                      %% (to go with the original rectangular grid size created to interpolate displField)
    GridtypeChoiceStr = 'Even Grid';
    HanWindowchoice = 'Yes';
    IdenticalCornersChoice = 'Yes';
    InterpolationMethod = 'griddata';
    PaddingChoiceStr = 'Padded with zeros only';                % Updated on 2020-03-03 by WIM
    TractionForceMethod = 'Summed';
    WienerWindowSize = 3 ;                                      % 3x3 pixel window for Wiener2D Spatial Filter

    
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
        [displacementFileName, displacementFilePath] = uigetfile(TFMPackageFiles, 'Drift-Corrected  EPI displacement field "displField.mat"  (Filtered DC)');
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
    
    %% 3 ==================== ask if Displacement Grid Padding is needed ==================== 
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

    %% 4 ==================== ask if Han-Windowing is needed ==================== 
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
    
    %% 6 ==================== load MT Force ====================
    [ForceFileDICname, ForceFileDICpath] = uigetfile(fullfile(movieData.outputDirectory_,'*.mat'), ...
        '''05 Force Compiled Results Struct.mat''__under DIC tracking output');
    if ForceFileDICname == 0, return; end
    ForceFileDICFullName = fullfile(ForceFileDICpath, ForceFileDICname);
    try
        MT_Force_xy_N_struct = load(ForceFileDICFullName);  
        MT_Force_xy_N = MT_Force_xy_N_struct.Force_xy_N;
    catch
        MT_Force_xy_N_struct = load(ForceFileDICFullName);
        MT_Force_xy_N = MT_Force_xy_N_struct.CompiledDataStruct.Force_xy_N;
    end    
    
    %% 7 ==================== Ask for Initial Guess for Young Elastic Modulus ==================== 
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
    YoungModulusInitialGuess = str2double(YoungModulusInitialGuess{1});                                  % Convert to a number
    
    %% 8 ==================== Ask where to save output ==================== 
    try
        ModulusPathName = uigetdir(displacementFilePath, 'Where do you want to save Force-Based Optimized Young Modulus');
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
                    if isempty(TimeStampChoice), error('No File Was chosen'); end
                    TimeStampFullFileNameDIC = fullfile(TimeStampPathDIC, TimeStampFileNameDIC);
                    TimeStampsRelativeRT_SecDataDIC = load(TimeStampFullFileNameDIC);
                    TimeStampsDIC = TimeStampsRelativeRT_SecDataDIC.TimeStampsAbsoluteRT_Sec;
                    FrameRateDIC = 1/mean(diff(TimeStampsRelativeRT_SecDataDIC.TimeStampsRelativeRT_Sec));
                    fprintf('DIC RT Timestamps file is: \n\t %s\n', TimeStampFullFileNameDIC);
                    
                    [TimeStampFileNameEPI, TimeStampPathEPI] = uigetfile(movieData.outputDirectory_, 'EPI TimeStampsRT Sec');
                    if isempty(TimeStampChoice), error('No File Was chosen'); end
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
    commandwindow;
    
    FirstTimeInputSecDefault = TimeStamps(FirstFrame);
    FirstTimeInputSec = input(sprintf('What is the time for the start of the period to be optimized (in seconds) [Default = %0.3g sec]? ', FirstTimeInputSecDefault));
    if isempty(FirstTimeInputSec), FirstTimeInputSec = FirstTimeInputSecDefault; end
    
    LastTimeInputSecDefault = TimeStamps(LastFrame);           % t =0 seconds
    LastTimeInputSec = input(sprintf('What is the time for the end of the period to be optimized (in seconds) [Default = %0.3g sec]? ', LastTimeInputSecDefault));
    if isempty(LastTimeInputSec), LastTimeInputSec = LastTimeInputSecDefault; end

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
    
    MT_Force_xy_N_Segment = MT_Force_xy_N(FrameNumbersDIC);
                    
 %% 13 =================== find the optimized Young Elastic Modulus from forces ==================== 
    commandwindow;
    % ==================== Ask for Initial Guess for Young Elastic Modulus ==================== 
    dlgTitle = 'Initial Young Modulus';
    try
        YoungModulusInitialGuess = forceFieldCalculationInfo.funParams_.YoungModulus;
    catch
        YoungModulusInitialGuess = 100;
    end

    prompt = sprintf('What is the Initial Young Modulus point guess, [Default = %g Pa]: ', YoungModulusInitialGuess);
    YoungModulusInitialDefault = {num2str(YoungModulusInitialGuess)};
    YoungModulusInitialGuess = inputdlg(prompt, dlgTitle, [1 40], YoungModulusInitialDefault);
    if isempty(YoungModulusInitialGuess), return; end
    YoungModulusInitialGuess = str2double(YoungModulusInitialGuess{1});                                  % Convert to a number
 
%     prompt = sprintf('Specify range to solve for the Young Elastic Modulus as [min,max], [Default = %g Pa]: ', ...
%         YoungModulusInitialGuess);
%     YoungModulusInitialChoice = input(prompt);
%     if ~isempty(YoungModulusInitialChoice), YoungModulusInitialGuess = YoungModulusInitialChoice; end

    tolerancepower = input('How many decimal places do you want the solution to be? [Default = 2]: ');         % number of significant figures beyond decimal
    if isempty(tolerancepower), tolerancepower = 2; end
    tolerance = 10^(-tolerancepower);
    
    options = optimset('Display', 'iter', 'TolX', tolerance);
    clc
    disp('______________________________________________________________________')
    diary fullfile(ModulusPathName, 'Young Modulus based on energetics.txt')
    diary on
    fprintf('Optimzation output will be saved under:\n\t%s\n', ModulusPathName);
    disp('Evaluating Optimized Young Modulus...in progress.')
    [YoungModulusOptimum, YoungModulusOptimumRMSE] = fminsearch(@(YoungModulus)Force_MTvTFM_RMSE_L2(movieData, displField, forceFieldParameters,...
        FramesDoneNumbersEPI, FirstFrameEPI, LastFrameEPI, YoungModulus, MT_Force_xy_N_Segment, PaddingChoiceStr, HanWindowchoice, WienerWindowSize, ...
        ScaleMicronPerPixel), YoungModulusInitialGuess, options); 
    
    YoungModulusOptimum = round(YoungModulusOptimum, tolerancepower, 'decimals');
    [RMSE_Newtons, ~ , ~, ~, ~, reg_corner] = Force_MTvTFM_RMSE_L2(movieData, displField, forceFieldParameters,...
        FramesDoneNumbersEPI, FirstFrameEPI, LastFrameEPI, YoungModulusOptimum, MT_Force_xy_N_Segment, PaddingChoiceStr, ...
        HanWindowchoice, WienerWindowSize, ScaleMicronPerPixel);
    disp('Evaluating Optimized Young Modulus...complete.')

    %% 13 =================== saving the optimized Young Elastic Modulus & parameters ==================== 
    YoungModulusOptimizationOutput = fullfile(ModulusPathName, sprintf('Young Modulus based on forces %g Pa.mat', YoungModulusOptimum));
        
    save(YoungModulusOptimizationOutput, 'movieData', 'displField', 'forceFieldParameters', 'TimeStampsEPI', 'TimeStampsDIC', ...
        'FirstFrameDIC', 'FirstFrameEPI', 'LastFrameDIC', 'LastFrameEPI', 'YoungModulusInitialGuess', ...
        'TractionForceMethod', 'gridMagnification', 'MT_Force_xy_N', 'YoungModulusOptimum', 'YoungModulusOptimumRMSE', ...
        'reg_corner', 'GridtypeChoiceStr', 'PaddingChoiceStr', 'SpatialFilterChoiceStr', 'WienerWindowSize', ...
        'HanWindowBoolean', 'reg_corner', 'options', '-v7.3');
    
    toleranceString = sprintf('%%0.%df', abs(tolerancepower));
    promptString = sprintf('The optimized Young''s Modulus is ***%s Pa***.\n', toleranceString);
    fprintf(promptString, YoungModulusOptimum);
    
    disp('---------------------Optimizing Young Modulus Complete!!!! ------------------')
    fprintf('The optimized Young''s Modulus is ***%g Pa***.\n', YoungModulusOptimum);
    fprintf('The optimized L-Curve regularization parameter (reg_corner) = %0.8f\n', reg_corner(1));
    
    fprintf('The optimized Young''s Modulus rounded to %d decimals is ~ ***%g Pa***.\n', tolerancepower, YoungModulusOptimumRounded);
    fprintf('The optimized L-Curve regularization parameter for rounded E (reg_cornerRounded) = %g\n', reg_cornerRounded(1));
    
    fprintf('The optimized Young''s Modulus file is saved in:\n\t%s\n', YoungModulusOptimizationOutput);
    diary off
%     
%     %% Re-calculate traction force for all frames    
%     TractionForceFieldAllFramesFilteredScript
%     
%     %% Plot the MT vs. TFM force   
%     VideoAnalysisCombined