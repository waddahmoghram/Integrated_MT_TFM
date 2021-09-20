%{
    v.2020-05-14 by Waddah Moghram
        1. Renamed to "Force_MTvTFM_RMSE_L2.m" to reflect that it uses iterative L2 norm (vs. BL2)
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
function [RMSE_Newtons, forceField , MT_Force_xy_N, grid_mat, TractionForce, reg_corner] = Force_MTvTFM_RMSE_L2(movieData, displFieldNotFiltered, forceFieldParameters, ...
    FramesDoneNumbers, FirstFrameEPI, LastFrameEPI, YoungModulus,  MT_Force_xy_N, PaddingChoiceStr, HanWindowchoice, WienerWindowSize, ScaleMicronPerPixel)
     % for now just ignore the last between MT and TFM
    %% 0 ==================== Initialize variables ==================== 
    if nargin < 11
        WienerWindowSize = 3;                 % chosen on 2019-12-16 based on numerical filter experiments.
    end
    intMethod = 'summed';
    tolerance = 1e-13;
    gridMagnification = 1;          %% (to go with the rectangular grid created to interpolate displField)
    EdgeErode = 1;
    
         %%  Use of GPU
    nGPU = gpuDeviceCount;
    if nGPU > 0
        useGPU = true;
    else
        useGPU = false;
    end
    forceField(numel(displFieldNotFiltered)) = struct('pos','','vec','','par','');
 
    %___________________
    if ~exist('TractionForce', 'var') || ~exist('TractionForceX', 'var') || ~exist('TractionForceY', 'var') 
        TractionForceX = NaN(numel(FramesDoneNumbers),1);
        TractionForceY = NaN(numel(FramesDoneNumbers),1);
        TractionForceNet = NaN(numel(FramesDoneNumbers),1);
    end
    if useGPU
        TractionForceNet = gpuArray(TractionForceNet);
        TractionForceX = gpuArray(TractionForceX);
        TractionForceY = gpuArray(TractionForceY);
    end    
    
    %% FTTC
    disp('______________________________________________________________________')
    %no dense mesh in any case. It causes aliasing issue!
    %Needs an even grid to solve for the solution.
%     if ~forceFieldParameters.highRes
%         % we have to lower grid spacing because there are some redundant or aggregated displ vectors when additional non-loc-max beads were used for tracking SH170311
%         [reg_grid,~,~,gridSpacing] = createRegGridFromDisplField(displFieldNotFiltered,0.9,EdgeErode); 
%     else
%          %no dense mesh in any case. It causes aliasing issue!
%         [reg_grid,~,~,gridSpacing] = createRegGridFromDisplField(displFieldNotFiltered,1,EdgeErode);
%     end
    [reg_grid,~,~,gridSpacing] = createRegGridFromDisplField(displFieldNotFiltered, gridMagnification, EdgeErode);
    [grid_mat, disp_grid_NoFilter, ~,~] = interp_vec2grid(displFieldNotFiltered(FirstFrameEPI).pos(:,1:2), displFieldNotFiltered(FirstFrameEPI).vec(:,1:2),[], reg_grid);    
    
    for CurrentFrame = FramesDoneNumbers(FirstFrameEPI:LastFrameEPI)
%         [grid_mat, disp_grid_NoFilter, ~,~] = interp_vec2grid(displFieldNotFiltered(CurrentFrame).pos(:,1:2), displFieldNotFiltered(CurrentFrame).vecCorrected(:,1:2),[], reg_grid);    
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
        if CurrentFrame == FramesDoneNumbers(FirstFrameEPI)
            SizeX = size(disp_grid);
            SizeY = size(disp_grid);
            xVecGrid = 1:SizeX;
            yVecGrid = 1:SizeY;
            [Xvec, Yvec] = ndgrid(xVecGrid, yVecGrid);
            grid_mat_padded(:,:,1) = Xvec;
            grid_mat_padded(:,:,2) = Yvec;
            disp('Calculating L-Curve values...in progress...');
            [~,eta,reg_corner,alphas] = calculateLcurveFTTC(grid_mat_padded, disp_grid, YoungModulus,...
                forceFieldParameters.PoissonRatio, gridSpacing, i_max, j_max, forceFieldParameters.regParam, forceFieldParameters.LcurveFactor);
            [reg_corner,~,~,hcurve] = regParamSelecetionLcurve(alphas',eta,alphas,reg_corner,'manualSelection',true);
            disp('Calculating L-Curve values...Finished...');
            close(hcurve)
        end
        
        [pos_grid_stress,~,stress_grid,~,~,~] = reg_fourier_TFM(grid_mat, disp_grid, YoungModulus,...
                forceFieldParameters.PoissonRatio, movieData.pixelSize_/1000, gridSpacing, i_max, j_max, reg_corner);

        switch PaddingChoiceStr
            case {'Padded with random & zeros', 'Padded with zeros only'}
                pos_grid_size = size(pos_grid_stress);
                disp_grid_size = size(disp_grid);                
                force_grid = reshape(stress_grid, disp_grid_size);
                force_grid_trimmed = NaN(size(grid_mat));
                for kk = 1:size(force_grid, 3)
                    force_grid_trimmed(:,:,kk) = force_grid(disp_grid_NoFilter_TopLeftCorner(1):disp_grid_NoFilter_BottomRightCorner(1) , disp_grid_NoFilter_TopLeftCorner(2):disp_grid_NoFilter_BottomRightCorner(2), kk);
                end
                stress_grid = reshape(force_grid_trimmed, pos_grid_size);
        end            
        forceField(CurrentFrame).pos = pos_grid_stress;
        forceField(CurrentFrame).vec = stress_grid;
%         disp('========================================================')
%         fprintf('Traction Force for Frame %d/(%d-%d)\n', CurrentFrame, FramesDoneNumbers(FirstFrameEPI), FramesDoneNumbers(LastFrameEPI));
        % Integrate the traction stresses
        if numel(size(stress_grid)) == 3         % is 3-layer grids
            Force = TractionForceSingleFrameNoMD(pos_grid_stress, stress_grid(:,:,1:2), ScaleMicronPerPixel, intMethod, tolerance, 0);
        else
            Force = TractionForceSingleFrameNoMD(pos_grid_stress, stress_grid(:,1:2), ScaleMicronPerPixel, intMethod, tolerance, 0);
        end
% %             Loading the respective traction file variables            
%         [Force] =  TractionForceSingleFrame(movieData, stress_grid(:,:,1:2), CurrentFrame, intMethod, tolerance);   % last item, integrated = 0 is summed, 1 = integrated 
        TractionForceX(CurrentFrame, 1) = Force(:,1);
        TractionForceY(CurrentFrame) = Force(:,2);
        TractionForceNet(CurrentFrame) = Force(:,3);      
        
    end

    % Calculating the RMSE of the difference. Only  magnitudes are important.
    RMSE_Newtons  = gather(sqrt((1/ numel(FramesDoneNumbers(FirstFrameEPI:LastFrameEPI)))*sum((TractionForceNet(FramesDoneNumbers(FirstFrameEPI:LastFrameEPI)) - MT_Force_xy_N).^2)));
%     RMSE_Newtons = gather(rms(TractionForceNet(FramesDoneNumbers(FirstFrameEPI:LastFrameEPI)) - MT_Force_xy_N));          % same result
    if useGPU
        TractionForceNet = gather(TractionForceNet);
        TractionForceX = gather(TractionForceX);
        TractionForceY = gather(TractionForceY);
    end
    TractionForce = [TractionForceX, TractionForceY, TractionForceNet];
%     fprintf('\t_______________________________________\n')
    fprintf('\tCurrent Net Mean MT  Forces (F) = %0.16g N.\n', mean(MT_Force_xy_N))
    fprintf('\tCurrent Net Mean TFM Forces (F) = %0.16g N.\n', mean(TractionForceNet))
    fprintf('\tCurrent Young Modulus (E) = %0.16g Pa.\n', YoungModulusPa) 
  end
      