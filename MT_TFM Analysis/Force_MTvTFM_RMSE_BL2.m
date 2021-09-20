%{
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
function [RMSE_Newtons, forceField , MT_Force_xy_N, grid_mat, TractionForce, reg_corner_tmp2] = Force_MTvTFM_RMSE_BL2(movieData, ...
    displFieldNotFiltered, forceFieldParameters, FramesOptimizedNumbers, YoungModulusPa, PoissonRatio,  ...
    MT_Force_xy_N, PaddingChoiceStr, HanWindowchoice, WienerWindowSize, ScaleMicronPerPixel, CornerPercentage, FramesRegParamNumbers)
     % for now just ignore the last between MT and TFM
    %% 0 ==================== Initialize variables ==================== 
    if nargin < 10
        WienerWindowSize = 3;                 % chosen on 2019-12-16 based on numerical filter experiments.
    end
    if isempty(FramesRegParamNumbers)
        EachFrame = true;
        FramesRegParamNumbers = FramesOptimizedNumbers;
    else
        EachFrame = false;
    end
    intMethod = 'summed';
    tolerance = 1e-13;
    gridMagnification = 1;          %% (to go with the rectangular grid created to interpolate displField)
    EdgeErode = 1;
    cornerCount = 4;
    ShowOutput = true;
    
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
        TractionForceX = NaN(numel(FramesOptimizedNumbers),1);
        TractionForceY = NaN(numel(FramesOptimizedNumbers),1);
        TractionForceNet = NaN(numel(FramesOptimizedNumbers),1);
    end
    if useGPU
        TractionForceNet = gpuArray(TractionForceNet);
        TractionForceX = gpuArray(TractionForceX);
        TractionForceY = gpuArray(TractionForceY);
    end    
    
    %% FTTC
    disp('______________________________________________________________________')
    FirstFrameEPI = FramesOptimizedNumbers(1);
    [reg_grid,~,~,gridSpacing] = createRegGridFromDisplField(displFieldNotFiltered, gridMagnification, EdgeErode);
    [grid_mat, disp_grid_NoFilter, ~,~] = interp_vec2grid(displFieldNotFiltered(FirstFrameEPI).pos(:,1:2), displFieldNotFiltered(FirstFrameEPI).vec(:,1:2),[], reg_grid);    
    gridXmin = min(displFieldNotFiltered(FirstFrameEPI).pos(:,1));
    gridXmax = max(displFieldNotFiltered(FirstFrameEPI).pos(:,1));
    gridYmin = min(displFieldNotFiltered(FirstFrameEPI).pos(:,2));
    gridYmax = max(displFieldNotFiltered(FirstFrameEPI).pos(:,2));

    CounterReg = 1;
    RegParamFrames = numel(FramesRegParamNumbers);
%     disp('Calculating Bayesian Optimized regularization parameter value...in progress...');
    reverseString = '';
    for CurrentFrame = FramesRegParamNumbers
        if ShowOutput
            ProgressMsg = sprintf('_____Frame %d_____ %d out of %d Frames_____\n', CurrentFrame, CounterReg, RegParamFrames);
            fprintf([reverseString, ProgressMsg]);
            reverseString = repmat(sprintf('\b'), 1, length(ProgressMsg));
        end
%         [grid_mat, disp_grid_NoFilter, ~,~] = interp_vec2grid(displFieldNotFiltered(CurrentFrame).pos(:,1:2), displFieldNotFiltered(CurrentFrame).vecCorrected(:,1:2),[], reg_grid);    
        [grid_mat, disp_grid_NoFilter, ~,~] = interp_vec2grid(displFieldNotFiltered(CurrentFrame).pos(:,1:2), displFieldNotFiltered(CurrentFrame).vec(:,1:2),[], reg_grid);        
        displFieldPos = displFieldNotFiltered(CurrentFrame).pos;
        displFieldVecNotDriftCorrected = displFieldNotFiltered(CurrentFrame).vec;
        displFieldVecNotDriftCorrected(:,3) = vecnorm(displFieldVecNotDriftCorrected(:,1:2), 2, 2); 
        
        cornerLengthPix_X = round(CornerPercentage * (gridXmax - gridXmin));
        cornerLengthPix_Y = round(CornerPercentage * (gridYmax - gridYmin));
        rect(1,:) = [gridXmin, gridYmin, cornerLengthPix_X, cornerLengthPix_Y];                                             % Top-Left Corner: ROI 1:
        rect(2,:) = [gridXmin, gridYmax - cornerLengthPix_Y, cornerLengthPix_X, cornerLengthPix_Y];                         % Bottom-Left Corner: ROI 1:
        rect(3,:) = [gridXmax - cornerLengthPix_X, gridYmin, cornerLengthPix_X, cornerLengthPix_Y];                         % Top-Right Corner: ROI 1:
        rect(4,:) = [gridXmax - cornerLengthPix_X, gridYmax - cornerLengthPix_Y, cornerLengthPix_X, cornerLengthPix_Y];     % Bottom-Right Corner: ROI 1:           
        for ii = 1:cornerCount
            rectCorners = [rect(ii, 1:2); rect(ii, 1:2) + [rect(ii, 3), 0]; rect(ii, 1:2) + [0, rect(ii, 4)]; rect(ii, 1:2) + rect(ii, 3:4)];
            DriftROIxx(ii,:) = rectCorners(:,1)';
            DriftROIyy(ii,:) = rectCorners(:,2)';
            if isempty(DriftROIxx(ii,:)) || isempty(DriftROIyy(ii,:))
                errordlg('The selected noise is empty.','Error');
                return;
            end
            nDriftROIxx(ii, :) = size(DriftROIxx(ii));
            if isempty(DriftROIxx(ii)) || nDriftROIxx(ii,1)==2
                errordlg('Noise does not select','Error');
                return;
            end
            indata(ii).Index = inpolygon(displFieldPos(:,1),displFieldPos(:,2),DriftROIxx(ii,:),DriftROIyy(ii,:));
            DriftROIs(ii).pos = displFieldPos(indata(ii).Index , :);
            DriftROIs(ii).vec = displFieldVecNotDriftCorrected(indata(ii).Index ,:);
            DriftROIs(ii).mean = mean(DriftROIs(ii).vec, 'omitnan'); 
        end
        DriftROIsCombined.pos = [];
        DriftROIsCombined.vec = [];
        DriftROIsCombined.mean = [];
        for mm = 1:cornerCount
            DriftROIsCombined.pos = [DriftROIsCombined.pos; DriftROIs(mm).pos];
            DriftROIsCombined.vec = [DriftROIsCombined.vec; DriftROIs(mm).vec];
        end
        DriftROIsCombined.mean = mean(DriftROIsCombined.vec, 'omitnan');
        DriftROIsCombined.mean(:,3) = vecnorm(DriftROIsCombined.mean(1:2), 2, 2);

        displFieldVecDriftCorrected(:,1:2) = displFieldVecNotDriftCorrected(:,1:2) - DriftROIsCombined.mean(:,1:2);
        displFieldVecDriftCorrected(:,3) = vecnorm(displFieldVecDriftCorrected(:,1:2), 2, 2); 
        displFieldVec = displFieldVecDriftCorrected;

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
        
        using_noise.pos =  DriftROIsCombined.pos;           % changed from "displFieldPos;" on 2020-06-24
        using_noise.vec =  DriftROIsCombined.vec(:,1:2);    % changed from "displFieldVec(1,1:2);" on 2020-06-24

        noise_u(1:2:size(using_noise.vec,1)*2,1) = using_noise.vec(:,1);
        noise_u(2:2:size(using_noise.vec,1)*2,1) = using_noise.vec(:,2);
        beta = 1/var(noise_u);

        kx_vec = 2*pi/i_max/gridSpacing.*[0:(i_max/2-1) (-i_max/2:-1)];
        ky_vec = 2*pi/j_max/gridSpacing.*[0:(j_max/2-1) (-j_max/2:-1)];
        kx = repmat(kx_vec',1,j_max);
        ky = repmat(ky_vec,i_max,1);
        kx(1,1) = 1;
        ky(1,1) = 1;
        k = sqrt(kx.^2+ky.^2);  

        conf = 2.*(1 + PoissonRatio)./(YoungModulusPa .*k .^3);
        Ginv_xx = conf .* ((1-PoissonRatio).*k.^2+PoissonRatio.*ky.^2);
        Ginv_xy = conf .* (-PoissonRatio.*kx.*ky);
        Ginv_yy = conf .* ((1-PoissonRatio).*k.^2+PoissonRatio.*kx.^2);

        Ginv_xx(1,1) = 0;
        Ginv_yy(1,1) = 0;
        Ginv_xy(1,1) = 0;  
        Ginv_xy(i_max/2+1,:) = 0;
        Ginv_xy(:,j_max/2+1) = 0;  

        G1 = sparse(reshape(Ginv_xx,[1,i_max*j_max]));
        G2 = sparse(reshape(Ginv_yy,[1,i_max*j_max]));
        X1 = sparse(reshape([G1; G2], [], 1)');  
        G3 = sparse(reshape(Ginv_xy,[1,i_max*j_max]));
        G4 = sparse(zeros(1, i_max*j_max)); 
        X2 = sparse(reshape([G4; G3], [], 1)');
        X3 = X2(1,2:end);   
        X4 = sparse(diag(X1));
        X5 = sparse(diag(X3,1));
        X6 = sparse(diag(X3,-1));
        X = X4+X5+X6;

        clear Ftu fux1 fuy1 fuu
        Ftu(:,:,1) = fft2(disp_grid(:,:,1));
        Ftu(:,:,2) = fft2(disp_grid(:,:,2));
        fux1 = reshape(Ftu(:,:,1),i_max*j_max,1);
        fuy1 = reshape(Ftu(:,:,2),i_max*j_max,1);
        fuu(1:2:size(fux1)*2,1) = fux1;
        fuu(2:2:size(fuy1)*2,1) = fuy1;

        [reg_corner, ~, ~, ~] = optimal_lambda(beta, fuu, Ftu(:,:,1), Ftu(:,:,2),...
            YoungModulusPa, PoissonRatio, gridSpacing, i_max, j_max, X, false);
        reg_corner_tmp(CounterReg) = reg_corner;
        
        CounterReg = CounterReg + 1;
    end
    if ~EachFrame
        reg_corner_tmp2 = repmat(10^(mean(log10(reg_corner_tmp), 'omitnan')), size(FramesOptimizedNumbers));        
    end        
%     disp('Calculating Bayesian Optimized regularization parameter value...completed');

    CounterOptimized = 1;
    OptimizedFrames = numel(FramesOptimizedNumbers);    
%     disp('Calculating Traction Stresses using FTTC & the Optimized regularization parameter ...in progress...');
    reverseString = '';
    for CurrentFrame = FramesOptimizedNumbers
        if ShowOutput
            ProgressMsg = sprintf('_____Frame %d_____%d out of %d Frames_____\n', CurrentFrame, CounterOptimized, OptimizedFrames);
            fprintf([reverseString, ProgressMsg]);
            reverseString = repmat(sprintf('\b'), 1, length(ProgressMsg));
        end
        
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
        
        [pos_grid_stress,~,stress_grid,~,~,~] = reg_fourier_TFM(grid_mat, disp_grid, YoungModulusPa,...
                forceFieldParameters.PoissonRatio, movieData.pixelSize_/1000, gridSpacing, i_max, j_max, reg_corner_tmp2(CounterOptimized));

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
        forceField(CounterOptimized).pos = pos_grid_stress;
        forceField(CounterOptimized).vec = stress_grid;
        % Integrate the traction stresses
        if numel(size(CounterOptimized)) == 3         % is 3-layer grids
            Force = TractionForceSingleFrameNoMD(pos_grid_stress, stress_grid(:,:,1:2), ScaleMicronPerPixel, intMethod, tolerance, 0);
        else
            Force = TractionForceSingleFrameNoMD(pos_grid_stress, stress_grid(:,1:2), ScaleMicronPerPixel, intMethod, tolerance, 0);
        end
% %             Loading the respective traction file variables            
%         [Force] =  TractionForceSingleFrame(movieData, stress_grid(:,:,1:2), CurrentFrame, intMethod, tolerance);   % last item, integrated = 0 is summed, 1 = integrated 
        TractionForceX(CounterOptimized) = Force(:,1);
        TractionForceY(CounterOptimized) = Force(:,2);
        TractionForceNet(CounterOptimized) = Force(:,3);
        
        CounterOptimized = CounterOptimized + 1;
    end
%     disp('Calculating Traction Stresses using FTTC & the Optimized regularization parameter (BL2)...complete...');
    % Calculating the RMSE of the difference. Only  magnitudes are important.
    
    RMSE_Newtons  = gather(sqrt(mean(TractionForceNet - MT_Force_xy_N).^2));
%     RMSE_Newtons = gather(rms(TractionForceNet(FramesOptimizedNumbers(FirstFrameEPI:LastFrameEPI)) - MT_Force_xy_N));          % same result
    if useGPU
        TractionForceNet = gather(TractionForceNet);
        TractionForceX = gather(TractionForceX);
        TractionForceY = gather(TractionForceY);
    end
    TractionForce = [TractionForceX, TractionForceY, TractionForceNet];

%     fprintf('\t_______________________________________\n')
    fprintf('\tCurrent Net Mean MT  Forces (F) = %0.16g Pa.\n', mean(MT_Force_xy_N))
    fprintf('\tCurrent Net Mean TFM Forces (F) = %0.16g Pa.\n', mean(TractionForceNet))
    fprintf('\tCurrent Young Modulus (E) = %0.16g Pa.\n', YoungModulusPa) 
  end
      