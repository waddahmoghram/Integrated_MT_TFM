%{
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
        This works with the script of YoungModulusPaOptimization.m

NOTE: this function uses Wiener 2D low-pass filter with an even grid interpolation for the displacement field.
%}

%% ==================================== RMSE Function below ======================
function [Energy_StoredJ, reg_corner] = Net_Energy_Stored_TFM(movieData, displFieldNotFiltered, forceFieldParameters, ...
    FirstFrameEPI, LastFrameEPI, YoungModulusPa,  PaddingChoiceStr, HanWindowchoice, WienerWindowSize, ScaleMicronPerPixel)
     % for now just ignore the last between MT and TFM
    %% 0 ==================== Initialize variables ==================== 
    if nargin < 9
        WienerWindowSize = 3;                 % chosen on 2019-12-16 based on numerical filter experiments.
    end
    
    ConversionMicrontoMeters = 1e-6;  
    ConversionMicronSqtoMetersSq = ConversionMicrontoMeters.^2;      
    EdgeErode = 1;
%     FramesDoneNumbers = [FirstFrameEPI, LastFrameEPI];
    FramesDoneNumbers = LastFrameEPI;                     % modified on 2020-03-11
    gridMagnification = 1;          %% (to go with the rectangular grid created to interpolate displField)
    intMethod = 'summed';
    tolerance = 1e-13;

    %  Use of GPU
    nGPU = gpuDeviceCount;
    if nGPU > 0
        useGPU = true;
    else
        useGPU = false;
    end    
    %% FTTC
    disp('______________________________________________________________________')
    %no dense mesh in any case. It causes aliasing issue!
    %Needs an even grid to solve for the solution.

    [reg_grid,~,~,gridSpacing] = createRegGridFromDisplField(displFieldNotFiltered, gridMagnification, EdgeErode);
    [grid_mat, disp_grid_NoFilter, ~,~] = interp_vec2grid(displFieldNotFiltered(FirstFrameEPI).pos(:,1:2), displFieldNotFiltered(FirstFrameEPI).vec(:,1:2),[], reg_grid);    
    
    for CurrentFrame = FramesDoneNumbers
        [grid_mat, disp_grid_NoFilter, ~,~] = interp_vec2grid(displFieldNotFiltered(CurrentFrame).pos(:,1:2), displFieldNotFiltered(CurrentFrame).vec(:,1:2),[], reg_grid);        
        switch PaddingChoiceStr
            case 'No padding'
                % do nothing
            case 'Padded with random & zeros'
                [disp_grid_NoFilter, ~, disp_grid_NoFilter_TopLeftCorner, disp_grid_NoFilter_BottomRightCorner] =  PadArrayRandomAndZeros(disp_grid_NoFilter);
            case 'Padded with zeros only'
                [disp_grid_NoFilter, ~, disp_grid_NoFilter_TopLeftCorner, disp_grid_NoFilter_BottomRightCorner] =  PadArrayRandomAndZeros(disp_grid_NoFilter, true);
            otherwise
                return
        end
        
        % Wiener Filter
%         clear disp_grid
        disp_grid = NaN(size(disp_grid_NoFilter));
        for ii = 1:size(disp_grid_NoFilter,3), disp_grid(:,:,ii) = wiener2(disp_grid_NoFilter(:,:,ii), [WienerWindowSize, WienerWindowSize]); end   
        
        switch HanWindowchoice
            case 'Yes'
                disp_grid = HanWindow(disp_grid);
            case 'No'
                % Continue
            otherwise
                return
        end     
        
        [i_max,j_max, ~] = size(disp_grid);
        if CurrentFrame == FramesDoneNumbers(1)
            SizeX = size(disp_grid);
            SizeY = size(disp_grid);
            xVecGrid = 1:SizeX;
            yVecGrid = 1:SizeY;
            [Xvec, Yvec] = ndgrid(xVecGrid, yVecGrid);
            grid_mat_padded(:,:,1) = Xvec;
            grid_mat_padded(:,:,2) = Yvec;
            disp('Calculating L-Curve values...in progress...');
            [~,eta,reg_corner,alphas] = calculateLcurveFTTC(grid_mat_padded, disp_grid, YoungModulusPa,...
                forceFieldParameters.PoissonRatio, gridSpacing, i_max, j_max, forceFieldParameters.regParam, forceFieldParameters.LcurveFactor);
            [reg_corner,~,~,hcurve] = regParamSelecetionLcurve(alphas',eta,alphas,reg_corner,'manualSelection',true);
            disp('Calculating L-Curve values...Finished...');
            close(hcurve)
        end
        
        [pos_grid_stress,~,stress_grid,~,~,~] = reg_fourier_TFM(grid_mat, disp_grid, YoungModulusPa,...
                forceFieldParameters.PoissonRatio, movieData.pixelSize_/1000, gridSpacing, i_max, j_max, reg_corner);

        switch PaddingChoiceStr
            case {'Padded with random & zeros', 'Padded with zeros only'}
                disp_grid_size = size(disp_grid);                
                force_grid = reshape(stress_grid, disp_grid_size);
                
                stress_grid_trimmed = NaN(size(grid_mat));
                for ii = 1:size(disp_grid, numel(size(disp_grid)))
                    disp_grid_trimmed(:,:,ii) = disp_grid(disp_grid_NoFilter_TopLeftCorner(1):disp_grid_NoFilter_BottomRightCorner(1) , disp_grid_NoFilter_TopLeftCorner(2):disp_grid_NoFilter_BottomRightCorner(2), ii);      % in pixels
                end 
                
                for kk = 1:size(stress_grid, numel(size(stress_grid)))
                    stress_grid_trimmed(:,:,kk) = force_grid(disp_grid_NoFilter_TopLeftCorner(1):disp_grid_NoFilter_BottomRightCorner(1) , disp_grid_NoFilter_TopLeftCorner(2):disp_grid_NoFilter_BottomRightCorner(2), kk);   % in pascals
                end
        end
        
        forceFieldPositionMicron = pos_grid_stress.* ScaleMicronPerPixel;

        Xmin = min(forceFieldPositionMicron(:,1));
        Ymin = min(forceFieldPositionMicron(:,2));
        Xmax = max(forceFieldPositionMicron(:,1));
        Ymax = max(forceFieldPositionMicron(:,2));


        X = forceFieldPositionMicron(:,1);
        Y = forceFieldPositionMicron(:,2);

        Xpoints = unique(X);
        Ypoints = unique(Y);

        [Xgrid, Ygrid] = ndgrid(Xpoints, Ypoints);
        meshGridSize = size(Xgrid);

        totalAreaMicronsSq = (Ymax-Ymin)*(Xmax-Xmin);
        totalPointsCount = meshGridSize(1) * meshGridSize(2);
        AvgAreaMicronSq = (totalAreaMicronsSq)/(totalPointsCount);
        AvgAreaMetersSq =  AvgAreaMicronSq * ConversionMicronSqtoMetersSq;
        % displacement is in pixels, convert to meters. Stress is in Pa. 
        % Integrate over the area double-sums and 
        disp_grid_trimmed_meters = disp_grid_trimmed .* ScaleMicronPerPixel .* ConversionMicrontoMeters;
        
        
        TrDotUr = 1/2 * sum(sum(disp_grid_trimmed_meters(:,:,1).* stress_grid_trimmed(:,:,1) + disp_grid_trimmed_meters(:,:,2).* stress_grid_trimmed(:,:,2)) .* AvgAreaMetersSq) ;
        TractionEnergyJ(CurrentFrame)  = TrDotUr;
    end
    
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
      