%{
    v.2020-07-14 by Waddah Moghram, PhD Candidate in Biomedical Engineering at the University of Iowa
        1. Updated to work with the updated TFM_MasterSolver.m
    v.2020-06-29..30 by Waddah Moghram
        1. Updated so that it uses the master functions including for drift-correction (DisplacementDriftCorrectionIdenticalCorners.m), 
        2. optimized BL2 regularization paramter (optimal_lambda_complete.m), and 
        3. master TFM solver (TFM_MasterSolver.m)
        4. Displacement field fed can be either drift-corrected or not, but cornerpercentage variable is more for the BL2 method.
    v.2020-06-24 by Waddah Moghram
        1. Fixed glitch with usingnoise ROI. It was wrong here too.
    v.2020-05-14 by Waddah Moghram
      Based on  to "Force_MTvTFM_RMSE_L2.m" 
    v.2020-03-05 by Waddah Moghram
        1. MT_TFM_RMSE.m is renamed to Force_MTvTFM_RMSE.m 
        2. Assume only 4 identical corners, the percentage is given from outside the function.
        3. It will average the reg_corners calculated and use it to find traction stresses. 
    v.2020-03-03 by Waddah Moghram
        1. Fixed bug so that the L-Curve is calculated based on the whole zero-padded grid.
        2. 
    v.2020-02-11 by Waddah Moghram
        1. Fixed so that the MT force frames are all given. EPI frames are only given since I will need to look them up everytime.
    v.2019-12-28 by Waddah Moghram
        1. use TractionForceSingleFrameNoMD() instead of TractionForceSingleFrameNoMD()
        2. use drift-corrected line in displFieldNotFiltered(CurrentFrameFTTC).vecCorrected instead of displFieldNotFiltered(CurrentFrameFTTC).vec
        3. updated so that reg_corner is calculated every time because it is a function of elastic modulus.
        4. updated internal grid size to match those calculated outside
    v.2019-12-18 by Waddah Moghram,
        1. Add WienerWindowSize to the input variable.
    v.2019-12-16 by Waddah Moghram, PhD Student in Biomedical Engineering on 
        1. Added Wiener2() filter
        2. Added option of padding the displacement field with random values of the edge, and zeros, and trimming
        3. Added option of Han-Windowing                    
    v.2019-10-14 by Waddah Moghram
        This works with the script of YoungModulusOptimization.m

NOTE: this function uses Wiener 2D low-pass filter with an even grid interpolation for the displacement field.
%}

%% ==================================== RMSE Function below ======================
function [RMSE_Newtons, forceField , MT_Force_xy_N, grid_mat, TractionForce, reg_corner_tmp] = Force_MTvTFM_RMSE_BL2_Master(...
    displFieldNotFiltered, forceFieldParameters, FramesOptimizedNumbers, YoungModulusPa, PoissonRatio,  ...
    MT_Force_xy_N, PaddingChoiceStr, HanWindowchoice, WienerWindowSize, ScaleMicronPerPixel, gridMagnification, EdgeErode, CornerPercentage, FramesRegParamNumbers, ...
    SpatialFilterChoiceStr, GridtypeChoiceStr, InterpolationMethod, TractionStressMethod, ForceIntegrationMethod, ...
    ConversionMicrontoMeters, ConversionMicronSqtoMetersSq, ShowOutput, CalculateRegParamMethod)
     % for now just ignore the last between MT and TFM
    %% 0 ==================== Initialize variables ==================== 
    if isempty(FramesRegParamNumbers)
%         EachFrame = true;
        FramesRegParamNumbers = FramesOptimizedNumbers;
    else
%         EachFrame = false;
    end
%     intMethod = 'summed';
%     tolerance = 1e-13;
%     gridMagnification = 1;          %% (to go with the rectangular grid created to interpolate displField)
%     EdgeErode = 1;
%     cornerCount = 4;
%     ConversionMicrontoMeters = 1e-6;
% %     ConversionMicronSqtoMetersSq = ConversionMicrontoMeters.^2; 
%     SpatialFilterChoiceStr = 'Wiener 2D';
%     StressMask = false;    
%     ForceIntegrationMethod = 'Summed';
%     TractionStressMethod = 'FTTC';
%     windowSizeChoice = 3;         % 3 pixels
    grid_mat = [];
    reg_cornerChoiceStr = 'Optimized Bayesian L2 (BL2)';
    forceFieldParameters.YoungModulus = YoungModulusPa;
    forceFieldParameters.YoungModulusPa = YoungModulusPa;
    forceFieldParameters.PoissonRatio = PoissonRatio;
    TransientRegParamMethod = 'ON for Transients';          % although it does not matter since that is taken care of outside.
    
%%  Use of GPU
    nGPU = gpuDeviceCount;
    if nGPU > 0
        useGPU = true;
    else
        useGPU = false;
    end
    forceField(numel(displFieldNotFiltered)) = struct('pos','','vec','','par','');
 
    %___________________
    if ~exist('TractionForceNet', 'var') || ~exist('TractionForceX', 'var') || ~exist('TractionForceY', 'var') 
        TractionForceX = NaN(numel(FramesOptimizedNumbers),1);
        TractionForceY = NaN(numel(FramesOptimizedNumbers),1);
        TractionForceNet = NaN(numel(FramesOptimizedNumbers),1);
    end
    if useGPU
        TractionForceNet = gpuArray(TractionForceNet);
        TractionForceX = gpuArray(TractionForceX);
        TractionForceY = gpuArray(TractionForceY);
    end    
    
%% Find the raw parameters first
    disp('______________________________________________________________________')
    %finding the Drift ROI velocity
%     [~, ~, ~, NoiseROIsCombined, ~, gridSpacing] = ...
%                 DisplacementDriftCorrectionIdenticalCorners(displFieldNotFiltered, CornerPercentage, [], gridMagnification, ...
%                 EdgeErode, GridtypeChoiceStr, InterpolationMethod, false);

    CounterReg = 1;
%     reg_corner_raw = nan(1, numel(FramesRegParamNumbers));
%     reg_corner_raw_tmp = nan(1, numel(FramesRegParamNumbers)); 
%     RegParamFrames = numel(FramesRegParamNumbers);
    
    reg_corner_raw = nan(1, numel(displFieldNotFiltered));
    reg_corner_tmp = nan(1, numel(displFieldNotFiltered)); 
    TractionForceX = nan(1, numel(displFieldNotFiltered)); 
    TractionForceY = nan(1, numel(displFieldNotFiltered)); 
    TractionForceNet = nan(1, numel(displFieldNotFiltered)); 
    RegParamFrames = numel(displFieldNotFiltered);


%     disp('Calculating Bayesian Optimized regularization parameter value...in progress...');
%     reverseString = '';
    
%     for CurrentFrame = FramesRegParamNumbers
%         if ShowOutput
%             ProgressMsg = sprintf('_____Frame %d. _____ %d out of %d Frames_____\n', CurrentFrame, CounterReg, RegParamFrames);
%             fprintf([reverseString, ProgressMsg]);
% %             reverseString = repmat(sprintf('\b'), 1, length(ProgressMsg));
%         end
%         % NOTE: PaddingChoiceStr does not affect the gridsize to find reg_corner. Only if reg_corner = [] as an input
%         [~, ~, ~, ~, ~, ~, ~, reg_corner, ~, ~] = TFM_MasterSolver(displFieldNotFiltered(CurrentFrame),[], ...
%             forceFieldParameters, [], gridMagnification, EdgeErode, PaddingChoiceStr, SpatialFilterChoiceStr, HanWindowchoice, ...
%             GridtypeChoiceStr, reg_cornerChoiceStr, InterpolationMethod, TractionStressMethod, ForceIntegrationMethod, ...
%             WienerWindowSize, ScaleMicronPerPixel, false, 1, 1, CornerPercentage);       
%         reg_corner_raw(CounterReg) = reg_corner;
%         CounterReg = CounterReg + 1;
%     end
    
    starttime = tic;
    parfor CurrentFrame = FramesRegParamNumbers
        % NOTE: PaddingChoiceStr does not affect the gridsize to find reg_corner. Only if reg_corner = [] as an input
        [~, ~, ~, ~, ~, ~, ~, reg_corner, ~, ~] = TFM_MasterSolver(displFieldNotFiltered(CurrentFrame),[], ...
            forceFieldParameters, [], gridMagnification, EdgeErode, PaddingChoiceStr, SpatialFilterChoiceStr, HanWindowchoice, ...
            GridtypeChoiceStr, reg_cornerChoiceStr, InterpolationMethod, TractionStressMethod, ForceIntegrationMethod, ...
            WienerWindowSize, ScaleMicronPerPixel, false, 1, 1, CornerPercentage, true);       
        reg_corner_raw(CurrentFrame) = reg_corner;
    end 

%% Average the raw parameters
    switch CalculateRegParamMethod
        case 'ON Cycles mean(log10())'
            reg_corner_tmp(FramesRegParamNumbers) = repmat(10^(mean(log10(reg_corner_raw(FramesRegParamNumbers)), 'omitnan')), size(FramesRegParamNumbers));    
            %     disp('Calculating Bayesian Optimized regularization parameter value...completed');

        case 'Optimized Segment mean(log10())'

        case  'Each Frame'
           reg_corner_tmp = reg_corner_raw;
    end        

%% calculating Traction stress and integrated forces based on averaged raw parameters over the optimized period.
%     CounterOptimized = 1;
%     OptimizedFrames = numel(FramesOptimizedNumbers);    
% %     disp('Calculating Traction Stresses using FTTC & the Optimized regularization parameter ...in progress...');
%     reverseString = '';
    parfor CurrentFrame = FramesOptimizedNumbers
%         if ShowOutput
%             ProgressMsg = sprintf('_____Frame %d. _____%d out of %d Frames_____\n', CurrentFrame, CounterOptimized, OptimizedFrames);
%             fprintf([reverseString, ProgressMsg]);
% %             reverseString = repmat(sprintf('\b'), 1, length(ProgressMsg));
%         end         
        [~, ~, ~, ~, ~, Force, ~, ~, ~, ~] = TFM_MasterSolver(displFieldNotFiltered(CurrentFrame),[], ...
            forceFieldParameters, reg_corner_tmp(CurrentFrame), gridMagnification, EdgeErode, PaddingChoiceStr, SpatialFilterChoiceStr, HanWindowchoice, ...
            GridtypeChoiceStr, reg_cornerChoiceStr, InterpolationMethod, TractionStressMethod, ForceIntegrationMethod, ...
            WienerWindowSize, ScaleMicronPerPixel, ShowOutput, 1, 1, CornerPercentage);       

    %   Loading the respective traction file variables            
            TractionForceX(CurrentFrame) = Force(:,1);
            TractionForceY(CurrentFrame) = Force(:,2);
            TractionForceNet(CurrentFrame) = Force(:,3);
    end

%     disp('Calculating Traction Stresses using FTTC & the Optimized regularization parameter (BL2)...complete...');

%% Calculating the RMSE for the optimized period of the difference. Only  magnitudes are important.
    RMSE_Newtons  = gather(sqrt(mean(TractionForceNet(FramesOptimizedNumbers) - MT_Force_xy_N' , 'omitnan').^2));
    if useGPU
        TractionForceNet = gather(TractionForceNet);
        TractionForceX = gather(TractionForceX);
        TractionForceY = gather(TractionForceY);
    end
    TractionForce = [TractionForceX, TractionForceY, TractionForceNet];
    fprintf('\tCurrent Net Mean MT  Forces (F) = %0.16f N.\n', mean(MT_Force_xy_N, 'omitnan'))
    fprintf('\tCurrent Net Mean TFM Forces (F) = %0.16f N.\n', mean(TractionForceNet,  'omitnan'))
    fprintf('\tCurrent Young Modulus (E) = %0.16g Pa.\n', YoungModulusPa) 
    fprintf('======= Time Elapsed for one round of estimate *** %0.4f sec *** =======\n', toc(starttime))
end
      