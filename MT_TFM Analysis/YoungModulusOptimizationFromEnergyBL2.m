%{
    v.2020-07-14 by Waddah Moghra, PhD Candidate in Biomedical Engineering at the University of Iowa.
        1. redid so that it uses the same ProcessTrackedDisplacementTFM.m function to get displacements, gridding and TFM parameters.
            This function takes care of temporal filtering and drift-correction if needed. No need to add CornerPercentage since NoiseROIsCombined is given.
    v.2020-06-29 by by Waddah Moghram, PhD Candidate in Biomedical Engineering at the University of Iowa
        1. Updated so that it uses the master functions including for drift-correction (DisplacementDriftCorrectionIdenticalCorners.m), 
        2. optimized BL2 regularization paramter (optimal_lambda_complete.m), and 
        3. master TFM solver (TFM_MasterSolver.m)
    v.2020-06-03 by Waddah Moghram,
        1. Added the option to calculate the optimization parameter over ALL ON segments, but
        calculate the elastic modulus over the designated ON segment of a certain cycle where 
        statoelastic condtiion applies.
        2. Add choice of cycle number as an input
    v.2020-05-14 by Waddah Moghram
        based on "YoungModulusOptimizationFromEnergyL2.m" v.2020-05-14
        1. Calculate traction stresses using BL2 (Bayesian L2 optimization).
        2. For now, identical corners to be fed into Force_MTvTFM_RMSE_BL2
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
    
    CycleNumber = 2;                % choose the second cycle for optimization of elastic modulus
    
    ConversionNtoNN = 1e9;
    CornerPercentage = 0.10;                     % 10% of dimension length of tracked particles grid for each of the 4 ROIs  
    DCchoice = 'Yes';
    EdgeErode = 1;
    GelType = 'Type I Collagen';
    SpatialFilterChoiceStr = 'Wiener 2D';
    FrameDisplMeanChoice = 'No';    
    gridMagnification = 1;          %% (to go with the rectangular grid created to interpolate displField)
    GridtypeChoiceStr = 'Even Grid';
    HanWindowchoice = 'Yes';
    IdenticalCornersChoice = 'Yes';
    InterpolationMethod = 'griddata';
    PaddingChoiceStr = 'Padded with zeros only';                % Updated on 2020-03-03 by WIM
    TractionStressMethod = 'FTTC'; 
    ForceIntegrationMethod = 'Summed';
    WienerWindowSize =[3, 3] ;    % 3x3 window for Wiener2D Spatial Filter
    ShowOutput = false;
    CalculateRegParamMethod = 'ON Cycles mean(log10())';
    reg_cornerChoiceStr = 'Optimized Bayesian L2 (BL2)'; 
    % Choose control mode (controlled force vs. controlled displacement).  
    controlMode = 'Controlled Force';               % for now that is the only way we can apply a known force from MT 2020-02-11
%     dlgQuestion = 'What is the control mode for this EPI/DIC experiment? ';
%     dlgTitle = 'Control Mode?';
%     controlMode = questdlg(dlgQuestion, dlgTitle, 'Controlled Force', 'Controlled Displacement', 'Controlled Force');
%     if isempty(controlMode), error('Choose a control mode'); end  
%        
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
        gridMagnification, EdgeErode, PaddingChoiceStr, SpatialFilterChoiceStr, HanWindowchoice, ...
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
    
%% 5. ==================== load MT Energy and Cycle information ====================    
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
    fprintf('MT work in half cycle #%d = %g J.\n', CycleNumber, WorkBeadJ_Half_Cycles(CycleNumber))
    
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

%% 7 =================== find first & last frame numbers based on timestamp for optimization ==================== 
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
%     FramesOptimizedNumbers = [FirstFrameEPI, LastFrameEPI];           % does not work for first and last frame from energetics point. There is an initial jump.
    FramesOptimizedNumbers = LastFrameEPI;
    
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
              
%% 9. =================== find the optimized Young Elastic Modulus from energetics ====================      
    commandwindow;
    % ==================== ask for Initial Guess for Young Elastic Modulus  ====================
    try
        YoungModulusInitialGuess = forceFieldParameters.YoungModulus;
    catch
        YoungModulusInitialGuess = 150;
    end
    
    %** Using Initial Guess
    dlgTitle = 'Initial Young Modulus';
    prompt = 'What is the Initial Young Modulus (Pa) guessed?';    
    YoungModulusInitialDefault = {num2str(YoungModulusInitialGuess)};
    YoungModulusInitialGuess = inputdlg(prompt, dlgTitle, [1 80], YoungModulusInitialDefault);
    if isempty(YoungModulusInitialGuess), return; end
    YoungModulusInitialGuess = str2double(YoungModulusInitialGuess{1});                         % Convert to a number

    tolerancepower = input('How many decimal places do you want the solution to be? [Default = 2]: ');         % number of significant figures beyond decimal
    if isempty(tolerancepower), tolerancepower = 2; end
    tolerance = 10^(-tolerancepower);
    
    options = optimset('Display', 'iter', 'TolX', tolerance);
    clc
    disp('______________________________________________________________________')
    fprintf('Optimzation output will be saved under:\n\t%s\n', ModulusPathName);
    fprintf('\t Half Cycle Work (U) = %0.16g J. (Cycle #%d)\n', WorkBeadJ_Half_Cycle, CycleNumber)
    disp('Evaluating Optimized Young Modulus...in progress.')
    
    PoissonRatio = forceFieldParameters.PoissonRatio;
    [YoungModulusOptimum, YoungModulusOptimumRMSE] = fminsearch(@(YoungModulusPa)abs(WorkBeadJ_Half_Cycle - Net_Energy_Stored_TFM_BL2(displField, forceFieldParameters,...
        FramesOptimizedNumbers, YoungModulusPa, PoissonRatio, PaddingChoiceStr, HanWindowchoice, WienerWindowSize, ScaleMicronPerPixel, ...
        gridMagnification, EdgeErode, CornerPercentage, FramesRegParamNumbers, ...
         SpatialFilterChoiceStr, GridtypeChoiceStr, InterpolationMethod, TractionStressMethod, ForceIntegrationMethod, ...
            ShowOutput, CalculateRegParamMethod)), YoungModulusInitialGuess, options); 
    YoungModulusOptimumRounded = round(YoungModulusOptimum, tolerancepower, 'decimals');  
    
    %% 13. Re-evaluate    
    [Net_Energy_Stored, reg_corner] = Net_Energy_Stored_TFM_BL2(displField, forceFieldParameters,...
        FramesOptimizedNumbers, YoungModulusOptimum, PoissonRatio, PaddingChoiceStr, HanWindowchoice, WienerWindowSize, ScaleMicronPerPixel, ...
        gridMagnification, EdgeErode, CornerPercentage, FramesRegParamNumbers, ...
         SpatialFilterChoiceStr, GridtypeChoiceStr, InterpolationMethod, TractionStressMethod, ForceIntegrationMethod, ...
            ShowOutput, CalculateRegParamMethod);
    [Net_Energy_StoredRounded, reg_cornerRounded] = Net_Energy_Stored_TFM_BL2(displField, forceFieldParameters,...
        FramesOptimizedNumbers, YoungModulusOptimumRounded, PoissonRatio, PaddingChoiceStr, HanWindowchoice, WienerWindowSize, ScaleMicronPerPixel, ...
        gridMagnification, EdgeErode, CornerPercentage, FramesRegParamNumbers, ...
         SpatialFilterChoiceStr, GridtypeChoiceStr, InterpolationMethod, TractionStressMethod, ForceIntegrationMethod, ...
            ShowOutput, CalculateRegParamMethod);
    disp('Evaluating Optimized Young Modulus...completed.')
    
    %% 14 =================== saving the optimized Young Elastic Modulus & parameters ==================== 
    YoungModulusOptimizationOutput = fullfile(ModulusPathName, sprintf('Young Modulus based on energetics %g Pa.mat', YoungModulusOptimum));
        
    save(YoungModulusOptimizationOutput, 'movieData', 'displField', 'forceFieldParameters', 'TimeStampsEPI', 'TimeStampsDIC', 'CalculateRegParamMethod',...
        'FirstFrameDIC', 'FirstFrameEPI', 'LastFrameDIC', 'LastFrameEPI', 'YoungModulusInitialGuess', 'CornerPercentage',...
        'ForceIntegrationMethod', 'gridMagnification', 'WorkBeadJ_Half_Cycle', 'CycleNumber', 'YoungModulusOptimum', 'YoungModulusOptimumRounded', 'YoungModulusOptimumRMSE', ...
        'reg_corner', 'GridtypeChoiceStr', 'PaddingChoiceStr', 'SpatialFilterChoiceStr', 'WienerWindowSize', 'FramesOptimizedNumbers', 'FramesRegParamNumbers', ...
        'HanWindowchoice', 'reg_corner', 'reg_cornerRounded', 'options', 'GelType', '-v7.3');
    
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
