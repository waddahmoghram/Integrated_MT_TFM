%{
    v.2020-07-12 by Waddah Moghra, PhD Candidate in Biomedical Engineering at the University of Iowa.
        1. redid so that it uses the same ProcessTrackedDisplacementTFM.m function to get displacements, gridding and TFM parameters.
            This function takes care of temporal filtering and drift-correction if needed. No need to add CornerPercentage since NoiseROIsCombined is given.
    v.2020-06-29 by Waddah Moghram
        1. Updated so that it uses the master functions including for drift-correction (DisplacementDriftCorrectionIdenticalCorners.m), 
        2. optimized BL2 regularization paramter (optimal_lambda_complete.m), and 
        3. master TFM solver (TFM_MasterSolver.m)
    v.2020-06-03 by Waddah Moghram,
        1. Added the option to calculate the optimization parameter over ALL ON segments, but
        calculate the elastic modulus over the designated ON segment of a certain cycle where 
        statoelastic condtiion applies.
    v.2020-05-26 by Waddah Moghram
        1. Double-check the solution is what it is supposed to be. See how this 
    v.2020-05-14 by Waddah Moghram
        Based on "YoungModulusOptimizationFromForcesL2.m" v.2020-05-14 
        1. Calculate traction stresses using BL2 (Bayesian L2 optimization).
        2. For now, identical corners to be fed into Force_MTvTFM_RMSE_BL2_Master
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
    ConversionMicrontoMeters = 1e-6;
    ConversionMicronSqtoMetersSq = ConversionMicrontoMeters.^2; 
    
    ConversionNtoNN = 1e9;
    CornerPercentage = 0.10;                     % 10% of dimension length of tracked particles grid for each of the 4 ROIs    
    DCchoice = 'Yes';
    EdgeErode = 1;
    GelType = 'Type I Collagen';
    SpatialFilterChoiceStr = 'Wiener 2D';
    FrameDisplMeanChoice = 'No';    
    gridMagnification = 1;                                      %% (to go with the original rectangular grid size created to interpolate displField)
    GridtypeChoiceStr = 'Even Grid';
    HanWindowChoice = 'Yes';
    IdenticalCornersChoice = 'Yes';
    InterpolationMethod = 'griddata';
    PaddingChoiceStr = 'Padded with zeros only';                % Updated on 2020-03-03 by WIM
    TractionStressMethod = 'FTTC';
    ForceIntegrationMethod = 'Summed';
    WienerWindowSize = [3, 3] ;                                      % 3x3 pixel window for Wiener2D Spatial Filter
    ShowOutput = false;
    CalculateRegParamMethod = 'ON Cycles mean(log10())';
    reg_cornerChoiceStr = 'Optimized Bayesian L2 (BL2)'; 
    % Choose control mode (controlled force vs. controlled displacement).  
    controlMode = 'Controlled Force';               % for now that is the only way we can apply a known force from MT 2020-02-11
%     dlgQuestion = 'What is the control mode for this EPI/DIC experiment? ';
%     dlgTitle = 'Control Mode?';
%     controlMode = questdlg(dlgQuestion, dlgTitle, 'Controlled Force', 'Controlled Displacement', 'Controlled Force');
%     if isempty(controlMode), error('Choose a control mode'); end  
       
        
%% 1 ==================== load EPI Movie Data (MD) & load tracked displacement file (displField.mat) ==================== 
    [movieData, displField, TimeStampsEPI, ModulusPathName, ScaleMicronPerPixel, FramesDoneNumbers, controlMode, ...
        rect, DriftROIs, DriftROIsCombined, reg_grid, gridSpacing, NoiseROIs, NoiseROIsCombined, TimeFilterChoiceStr, ...
        DriftCorrectionChoiceStr, DisplacementFileFullName] = ...
            ProcessTrackedDisplacementTFM([], [], [], [], gridMagnification, EdgeErode, GridtypeChoiceStr, ...
            InterpolationMethod, ShowOutput, [], []);
     
%% 2 ==================== Ask where to save output ====================                 InterpolationMethod, ShowOutput, [], [], SaveOutput);
    if isempty(ModulusPathName)
        try 
            ModulusPathTMP = fileparts(DisplacementFileFullName);
            ModulusPathName = uigetdir(ModulusPathTMP, 'Where do you want to save the Optimized Young Modulus'); 
            if isempty(ModulusPathName), return; end
        catch
            ModulusPathName = uigetdir('Where do you want to save the Optimized Young Modulus'); 
            if isempty(ModulusPathName), return; end
        end
    end

%% 3. ==================== ask if EPI Displacement Grid Padding is needed ==================== 
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
    
%% 4. ==================== choose/load file for stress field parameters (forceFieldParameters.mat)
    forceFieldParameters = [];
    reg_corner = []; 
    FirstFrame = FramesDoneNumbers(1);
    LastFrame = FramesDoneNumbers(end);
    
    [~, ~, ~, ~, ~, ~, ~, ~, forceFieldParameters, CornerPercentage] = ...
        TFM_MasterSolver(displField, NoiseROIsCombined, forceFieldParameters, reg_corner, ...
        gridMagnification, EdgeErode, PaddingChoiceStr, SpatialFilterChoiceStr, HanWindowChoice, ...
        GridtypeChoiceStr, reg_cornerChoiceStr, InterpolationMethod, TractionStressMethod, ForceIntegrationMethod, ...
        WienerWindowSize, ScaleMicronPerPixel, false, FirstFrame, FirstFrame, []);

     if isempty(CornerPercentage)
        CornerPercentageDefault = 0.1;
        inputStr = sprintf('Choose the percentage of the images size to use for noise adjustment [Default = %0.2g%%]: ', CornerPercentageDefault * 100);
        CornerPercentage = input(inputStr);
        if isempty(CornerPercentage)
           CornerPercentage =  CornerPercentageDefault; 
        else
           CornerPercentage = CornerPercentage / 100;
        end
     end
    
    if isempty(forceFieldParameters.YoungModulus)
        YoungModulusPa = input('What was the gel''s Young Elastic modulus (in Pa)? ');  
    end
    
    if isempty(forceFieldParameters.PoissonRatio)
        PoissonRatio = input('What was the gel''s Poisson Ratio (unitless)? ');  
    end
    
    if isempty(forceFieldParameters.YoungModulus), forceFieldParameters.YoungModulus = YoungModulusPa; end
    if isempty(forceFieldParameters.PoissonRatio), forceFieldParameters.PoissonRatio = PoissonRatio; end    
    
%     fprintf('Gel''s elastic modulus (E) is %g  Pa. \n', forceFieldParameters.YoungModulus); 
%     fprintf('Gel''s Poisson Ratio (nu) is %g. \n', forceFieldParameters.PoissonRatio);
    
%% 5. ==================== load MT Force and Cycle information ====================
    [ForceFileDICname, ForceFileDICpath] = uigetfile(fullfile(movieData.outputDirectory_,'*.mat'), ...
        '''05 Force Compiled Results.mat''__under DIC tracking output');
    if ForceFileDICname == 0, return; end
    ForceFileDICFullName = fullfile(ForceFileDICpath, ForceFileDICname);
    try
        MT_Force_xy_N_struct = load(ForceFileDICFullName);  
        MT_Force_xy_N = MT_Force_xy_N_struct.Force_xy_N;
    catch
        MT_Force_xy_N_struct = load(ForceFileDICFullName);
        MT_Force_xy_N = MT_Force_xy_N_struct.CompiledDataStruct.Force_xy_N;
    end    

%% 6. =================== load timestamps ==================== 
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
            dlgQuestion = ({'Do you have DIC/EPI timestamps?'});
            dlgTitle = 'DIC/EPI Time Stamp RT file from sensor files?';
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
                    
                    if ~exist('TimeStampsEPI', 'var')
                        [TimeStampFileNameEPI, TimeStampPathEPI] = uigetfile(movieData.outputDirectory_, 'EPI TimeStampsRT Sec');
                        if isempty(TimeStampChoice), error('No File Was chosen'); end
                        TimeStampFullFileNameEPI = fullfile(TimeStampPathEPI, TimeStampFileNameEPI);
                        TimeStampsRelativeRT_SecDataEPI = load(TimeStampFullFileNameEPI);
                        TimeStampsEPI = TimeStampsRelativeRT_SecDataEPI.TimeStampsAbsoluteRT_Sec;
                        fprintf('EPI RT Timestamps file is: \n\t %s\n', TimeStampFullFileNameEPI);
                    else
                        TimeStampsRelativeRT_SecDataEPI.TimeStampsAbsoluteRT_Sec = TimeStampsEPI;
                    end
                    FrameRateEPI = 1/mean(diff(TimeStampsRelativeRT_SecDataEPI.TimeStampsAbsoluteRT_Sec));
                    
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

%% 7. =================== find first & last frame numbers based on timestamp ==================== 
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
    FramesOptimizedNumbers = FrameNumbersEPI;
           
%% 8. =================== find first & last frame numbers to calculate regularization parameters ====================
    if ~exist('CalculateRegParamMethod', 'var')
        dlgQuestion = 'How do you want to calculate regularization parameters?';
        dlgTitle = 'Regularization parameters method?';
        switch controlMode
            case 'Controlled Force'
                CalculateRegParamMethod = questdlg(dlgQuestion, dlgTitle, 'ON Cycles mean(log10())', 'Optimzied Segment mean(log10())', 'Each Frame', 'ON Cycles Average');
            case 'Controlled Displacement'
        end  
    end
    
    switch controlMode    
        case 'Controlled Force'
            % Controlled force mode will use the Magnetic Flux reading to classify ON/OFF
            [FluxON, FluxOFF, FluxTransient, ~] = FindFluxStatusControlledForce([]);
        case 'Controlled Displacement'
            % Cotnrolled Force mode will rely on the user to identify the beginning of the "ON" based on the displacement of the bead that is considered above average noise level.
            [FluxON, FluxOFF, FluxTransient, ~] = FindFluxStatusControlledDisplacement(movieData, displField, TimeStamps, FramesDoneNumbers);
    end   
    switch CalculateRegParamMethod
        case 'ON Cycles mean(log10())'
            FramesRegParamNumbers = find(FluxON)';               % non-zero elements.
        case 'Optimzied Segment mean(log10())'
            FramesRegParamNumbers = intersect(find(FluxON), FramesOptimizedNumbers)';
        case 'Each Frame'
            FramesRegParamNumbers = [];
    end
%     TransientRegParamMethod = 'ON for Transients';
    
%% 9. =================== find the optimized Young Elastic Modulus from forces ==================== 
    commandwindow;
    % ==================== Ask for Initial Guess for Young Elastic Modulus ==================== 
    dlgTitle = 'Initial Young Modulus';
    try
        YoungModulusInitialGuess = forceFieldParameters.YoungModulus;
    catch
        YoungModulusInitialGuess = 80;
    end

    prompt = sprintf('What is the Initial Young Modulus point guess, [Default = %g Pa]: ', YoungModulusInitialGuess);
    YoungModulusInitialDefault = {num2str(YoungModulusInitialGuess)};
    YoungModulusInitialGuess = inputdlg(prompt, dlgTitle, [1 80], YoungModulusInitialDefault);
    if isempty(YoungModulusInitialGuess), return; end
    YoungModulusInitialGuess = str2double(YoungModulusInitialGuess{1});                                  % Convert to a number
 
    tolerancepower = input('How many decimal places do you want the solution to be? [Default = 2]: ');         % number of significant figures beyond decimal
    if isempty(tolerancepower), tolerancepower = 2; end
    tolerance = 10^(-tolerancepower);
    
    options = optimset('Display', 'iter', 'TolX', tolerance);
    clc
    disp('______________________________________________________________________')
    fprintf('Optimzation output will be saved under:\n\t%s\n', ModulusPathName);
    disp('Evaluating Optimized Young Modulus...in progress.')
    
    PoissonRatio = forceFieldParameters.PoissonRatio;
    [YoungModulusOptimum, YoungModulusOptimumRMSE] = fminsearch(@(YoungModulusPa)Force_MTvTFM_RMSE_BL2_Master(displField, forceFieldParameters,...
        FramesOptimizedNumbers, YoungModulusPa, PoissonRatio, MT_Force_xy_N_Segment, PaddingChoiceStr, HanWindowChoice, WienerWindowSize, ScaleMicronPerPixel, ...
        gridMagnification, EdgeErode, CornerPercentage, FramesRegParamNumbers, ...
        SpatialFilterChoiceStr, GridtypeChoiceStr, InterpolationMethod, TractionStressMethod, ForceIntegrationMethod, ...
        ConversionMicrontoMeters, ConversionMicronSqtoMetersSq, ShowOutput, CalculateRegParamMethod), YoungModulusInitialGuess, options); 
    
    YoungModulusOptimumRounded = round(YoungModulusOptimum, tolerancepower, 'decimals');    
    forceFieldParameters.YoungModulus = YoungModulusOptimum;
    
    
    [RMSE_Newtons, ~ , ~, ~, ~, reg_corner] = Force_MTvTFM_RMSE_BL2_Master(displField, forceFieldParameters,...
        FramesOptimizedNumbers, YoungModulusOptimum, PoissonRatio, MT_Force_xy_N_Segment, PaddingChoiceStr, HanWindowChoice, WienerWindowSize, ScaleMicronPerPixel, ...
        gridMagnification, EdgeErode, CornerPercentage, FramesRegParamNumbers, ...
        SpatialFilterChoiceStr, GridtypeChoiceStr, InterpolationMethod, TractionStressMethod, ForceIntegrationMethod, ...
        ConversionMicrontoMeters, ConversionMicronSqtoMetersSq, ShowOutput, CalculateRegParamMethod);
    
    [RMSE_NewtonsRounded, ~ , ~, ~, ~, reg_cornerRounded] = Force_MTvTFM_RMSE_BL2_Master(displField, forceFieldParameters,...
        FramesOptimizedNumbers, YoungModulusOptimumRounded, PoissonRatio, MT_Force_xy_N_Segment, PaddingChoiceStr, HanWindowChoice, WienerWindowSize, ScaleMicronPerPixel, ...
        gridMagnification, EdgeErode, CornerPercentage, FramesRegParamNumbers, ...
        SpatialFilterChoiceStr, GridtypeChoiceStr, InterpolationMethod, TractionStressMethod, ForceIntegrationMethod, ...
        ConversionMicrontoMeters, ConversionMicronSqtoMetersSq, ShowOutput, CalculateRegParamMethod);
    disp('Evaluating Optimized Young Modulus...completed.')

%% 10 =================== saving the optimized Young Elastic Modulus & parameters ==================== 
    YoungModulusOptimizationOutput = fullfile(ModulusPathName, sprintf('Young Modulus based on forces %g Pa.mat', YoungModulusOptimum));
        
    save(YoungModulusOptimizationOutput, 'movieData', 'displField', 'forceFieldParameters', 'TimeStampsEPI', 'TimeStampsDIC', 'CalculateRegParamMethod', ...
        'FirstFrameDIC', 'FirstFrameEPI', 'LastFrameDIC', 'LastFrameEPI', 'YoungModulusInitialGuess', 'PoissonRatio', 'CornerPercentage', ... ...
        'TractionStressMethod', 'ForceIntegrationMethod', 'gridMagnification', 'MT_Force_xy_N', 'YoungModulusOptimum', 'YoungModulusOptimumRounded', 'YoungModulusOptimumRMSE', ...
        'reg_corner', 'GridtypeChoiceStr', 'PaddingChoiceStr', 'SpatialFilterChoiceStr', 'WienerWindowSize', 'FramesOptimizedNumbers', 'FramesRegParamNumbers',...
        'HanWindowChoice', 'reg_corner', 'reg_cornerRounded', 'options', 'GelType', '-v7.3');
    
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
    disp('---------------------Optimizing Young Modulus Complete!!!! ------------------');
