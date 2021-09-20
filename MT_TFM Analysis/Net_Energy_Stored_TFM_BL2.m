%{
    v.2020-07-14 by Waddah Moghram, PhD Candidate in Biomedical Engineering at the University of Iowa
        1. Updated to work with the updated TFM_MasterSolver.m
    v.2020-06-24 by Waddah Moghram
        1. Fixed glitch with usingnoise ROI. It was wrong here too.
    v.2020-06-03..04 by Waddah Moghram,
        1. Added the option of optimizing over a different segment that the one used to evaluate the optimization parameter.
        2. Adjusted function input to accomodate that. 
        3. Fixed the optimized segments to have first and last in the input file used.
    v.2020-05-26 by WAddah Moghram
        1. Fixed this so that two reg_corner parameters based on optimal Bayesian are used for the ON and OFF values.
    v.2020-03-11 by Waddah MOghram
        1. Renamed "Net_Energy_Stored_TFM.m" to "
    v.2020-03-11 by Waddah MOghram
        1. Updated so that the energy at the beginning of the cycle is set to zero. (in effect, it is noise level due to the jump).
    v.2020-03-05 by Waddah Moghram
        1. MT_TFM_RMSE.m is renamed to Force_MTvTFM_RMSE.m 
    v.2020-03-03 by Waddah Moghram
        1. Fixed bug so that the L-Curve is calculated based on the whole zero-padded grid.
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
function [Energy_StoredJ, reg_corner] = Net_Energy_Stored_TFM_BL2(displFieldNotFiltered, forceFieldParameters, FramesOptimizedNumbers, YoungModulusPa, PoissonRatio, ...
    PaddingChoiceStr, HanWindowchoice, WienerWindowSize, ScaleMicronPerPixel,...
    gridMagnification, EdgeErode, CornerPercentage, FramesRegParamNumbers, ...
    SpatialFilterChoiceStr, GridtypeChoiceStr, InterpolationMethod, TractionStressMethod, ForceIntegrationMethod, ...
    ShowOutput, CalculateRegParamMethod)

     % for now just ignore the last between MT and TFM
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

    reg_cornerChoiceStr = 'Optimized Bayesian L2 (BL2)';
    forceFieldParameters.YoungModulus = YoungModulusPa;
    forceFieldParameters.PoissonRatio = PoissonRatio;
    TransientRegParamMethod = 'ON for Transients';          % although it does not matter since that is taken care of outside.
    
%%  Use of GPU
    nGPU = gpuDeviceCount;
    if nGPU > 0
        useGPU = true;
    else
        useGPU = false;
    end
    
%% Find the raw parameters first
    disp('______________________________________________________________________')
    %finding the Drift ROI velocity
%     [~, ~, ~, NoiseROIsCombined, ~, gridSpacing] = ...
%                 DisplacementDriftCorrectionIdenticalCorners(displFieldNotFiltered, CornerPercentage, [], gridMagnification, ...
%                 EdgeErode, GridtypeChoiceStr, InterpolationMethod, false);

    CounterReg = 1;
    reg_corner_raw = nan(size(FramesRegParamNumbers));
    RegParamFrames = numel(FramesRegParamNumbers);
%     disp('Calculating Bayesian Optimized regularization parameter value...in progress...');
    reverseString = '';
    
    for CurrentFrame = FramesRegParamNumbers
        if ShowOutput
            ProgressMsg = sprintf('_____Frame %d. _____ %d out of %d Frames_____\n', CurrentFrame, CounterReg, RegParamFrames);
            fprintf([reverseString, ProgressMsg]);
%             reverseString = repmat(sprintf('\b'), 1, length(ProgressMsg));
        end
        % NOTE: PaddingChoiceStr does not affect the gridsize to find reg_corner. Only if reg_corner = [] as an input
        [~, ~, ~, ~, ~, ~, ~, reg_corner, ~, ~] = TFM_MasterSolver(displFieldNotFiltered(CurrentFrame), [], ...
            forceFieldParameters, [], gridMagnification, EdgeErode, PaddingChoiceStr, SpatialFilterChoiceStr, HanWindowchoice, ...
            GridtypeChoiceStr, reg_cornerChoiceStr, InterpolationMethod, TractionStressMethod, ForceIntegrationMethod, ...
            WienerWindowSize, ScaleMicronPerPixel, false, 1, 1, CornerPercentage);       
        reg_corner_raw(CounterReg) = reg_corner;
        CounterReg = CounterReg + 1;
    end
    
    %% Average the raw parameters
    switch CalculateRegParamMethod
        case 'ON Cycles mean(log10())'
            reg_corner_tmp = repmat(10^(mean(log10(reg_corner_raw), 'omitnan')), size(FramesOptimizedNumbers));    
        case 'Optimzied Segment mean(log10())'
            for ii = 1:numel(FramesOptimizedNumbers)
                Idx(ii) = find(FramesRegParamNumbers == FramesOptimizedNumbers(ii));
            end
            reg_corner_tmp = repmat(10^(mean(log10(reg_corner_raw(Idx)), 'omitnan')), size(FramesOptimizedNumbers));   
        case  'Each Frame'
           reg_corner_tmp = reg_corner_raw;
    end        
%     disp('Calculating Bayesian Optimized regularization parameter value...completed');
    
%% calculating Traction stress and integrated forces based on averaged raw parameters over the optimized period.
    %no dense mesh in any case. It causes aliasing issue!
    %Needs an even grid to solve for the solution.
    FirstFrameEPI = FramesOptimizedNumbers(1);
    LastFrameEPI = FramesOptimizedNumbers(end);
    disp('______________________________________________________________________')
   
    CounterReg = 1;
%     RegParamFrames = numel(1,LastFrameEPI-FirstFrameEPI);
%     disp('Calculating Bayesian Optimized regularization parameter value...in progress');
%     reverseString = '';
    reg_corner = nan(1,FirstFrameEPI:LastFrameEPI);
    for CurrentFrame = FramesOptimizedNumbers       
        [~, ~, ~, ~, ~, ~, TractionEnergyJ, reg_corner_tmp, ~, ~] = TFM_MasterSolver(displFieldNotFiltered(CurrentFrame),[], ...
            forceFieldParameters, reg_corner_tmp, gridMagnification, EdgeErode, PaddingChoiceStr, SpatialFilterChoiceStr, HanWindowchoice, ...
            GridtypeChoiceStr, reg_cornerChoiceStr, InterpolationMethod, TractionStressMethod, ForceIntegrationMethod, ...
            WienerWindowSize, ScaleMicronPerPixel, ShowOutput, 1, 1, CornerPercentage);    

        reg_corner(CurrentFrame) = reg_corner_tmp;
        CounterReg = CounterReg + 1;
    end
%     disp('Calculating Stored Energy using FTTC & the Optimized regularization parameter (BL2) ...complete...');
    
        %% 2.3 Calculate Energy Storage.
    if numel(TractionEnergyJ) == 1
        TractionEnergyJ1 = 0;
    else
        TractionEnergyJ1 = TractionEnergyJ(1);
    end
    Energy_StoredJ = TractionEnergyJ(end) - TractionEnergyJ1;
%     fprintf('\t_________________________________________________________________\n')
    fprintf('\tCurrent Energy Stored (U) = %0.16g J.\n', Energy_StoredJ)
    fprintf('\tCurrent Young Modulus (E) = %0.16g Pa.\n', YoungModulusPa)
  end
      