function [displFieldNoFilteredGrid, displFieldFilteredGrid, forceField, energyDensityField, ForceN, TractionEnergyJ, ...
    reg_corner, forceFieldParameters, NoiseROIsCombined] = TFM_Solver_Single_Frame(displField, CurrentFrame, GridtypeChoiceStr, ...
    SpatialFilterChoiceStr, gridMagnification, gridSpacing, EdgeErode, InterpolationMethod, forceFieldParameters, PaddingChoiceStr, calculateRegParam, ...
    reg_cornerChoiceStr, reg_grid,  WienerWindowSize, ScaleMicronPerPixel, CornerPercentage, StressMask)
%TFM_Solver_Single_Frame try to parallel process to speed up evaluating frames
%   Detailed explanation goes here
    ConversionMicrontoMeters = 1e-6;
    ConversionMicronSqtoMetersSq = ConversionMicrontoMeters.^2;      


    displFieldTMP =  displField(CurrentFrame);
    displFieldTMPPos = displFieldTMP.pos;
    displFieldTMPVec = displFieldTMP.vec;

    %__ 3 Interpolating displacement field
    [pos_grid, disp_grid_NoFilter_NoPadding, ~,~] = interp_vec2grid(displFieldTMPPos, displFieldTMPVec(:,1:2),[], reg_grid, InterpolationMethod);
    disp_grid_NoFilter_NoPadding(:,:,3) = sqrt(disp_grid_NoFilter_NoPadding(:,:,1).^2 + disp_grid_NoFilter_NoPadding(:,:,2).^2);       % Third column is the net displacement in grid form

     %__ 5 Filtering the displacement field _______________________________________          
    clear disp_grid stress_grid pos_grid_stress
    switch SpatialFilterChoiceStr
        case 'No-Filter'
            disp_grid = disp_grid_NoFilter_NoPadding;
            disp_gridHan = disp_grid;
        case 'Wiener 2D'
            disp_grid = NaN(size(disp_grid_NoFilter_NoPadding));
            for ii = 1:size(disp_grid_NoFilter_NoPadding,3), disp_grid(:,:,ii) = wiener2(gather(disp_grid_NoFilter_NoPadding(:,:,ii)), gather(WienerWindowSize)); end
            switch HanWindowchoice
                case 'Yes'
                    disp_gridHan = HanWindow(disp_grid);
                    HanWindowBoolean = true;
                case 'No'
                    disp_gridHan  = disp_grid;
                    HanWindowBoolean = false;
                    % Continue
            end
            forceFieldParameters.HanWindowchoice = HanWindowchoice;
    end
    forceFieldParameters.SpatialFilterChoiceStr = SpatialFilterChoiceStr;        
    forceFieldParameters.GridtypeChoiceStr = GridtypeChoiceStr;
    forceFieldParameters.gridSpacing = gridSpacing;
    forceFieldParameters.gridMagnification = gridMagnification;
    forceFieldParameters.EdgeErode = EdgeErode;       

   %% * updated on 2020-07-06 by Waddah Moghram. To find the parameter. No Padding or Han Windowing.
    %__ 4 Padding the Array with random edge displacement readings and 0's _______________________________________ 
    if ~exist('PaddingChoiceStr', 'var'), PaddingChoiceStr = []; end
    if isempty(PaddingChoiceStr)
        dlgQuestion = ({'Pad displacement array?'});
        PaddingListStr = {'No padding', 'Padded with random & zeros', 'Padded with zeros only'};  
        PaddingChoice = listdlg('ListString', PaddingListStr, 'PromptString',dlgQuestion ,'InitialValue', 3, 'SelectionMode' ,'single');    
        if isempty(PaddingChoice), error('No Padding Method was selected'); end
        try
            PaddingChoiceStr = PaddingListStr{PaddingChoice};                 % get the names of the string.   
        catch
            error('X was selected');      
        end
    end
    switch PaddingChoiceStr
        case 'No padding'
            % do nothing
            disp_grid_padded = disp_grid;
            switch HanWindowchoice
                case 'Yes'
                    disp_grid_padded_Han = HanWindow(disp_grid);
%                         disp_grid_padded  = disp_grid_padded_Han;
            end
        case 'Padded with random & zeros'
            [disp_grid_padded, ~, disp_grid_Padded_TopLeftCorner, disp_grid_Padded_BottomRightCorner] =  PadArrayRandomAndZeros(disp_grid);
            switch HanWindowchoice
                case 'Yes'
                    disp_grid_padded_Han = HanWindow(disp_grid_padded);
%                         disp_grid_padded  = disp_grid_padded_Han;
            end
        case 'Padded with zeros only'
            [disp_grid_padded, ~, disp_grid_Padded_TopLeftCorner, disp_grid_Padded_BottomRightCorner] =  PadArrayRandomAndZeros(disp_grid, true);
            switch HanWindowchoice
                case 'Yes'
                    disp_grid_padded_Han = HanWindow(disp_grid_padded);
%                         disp_grid_padded  = disp_grid_padded_Han;
            end
        otherwise
            return
    end
    forceFieldParameters.PaddingChoiceStr = PaddingChoiceStr;

%__ 6 Calculate the regularization parameter on the fly for each frame if so chosen_______________________________________ 
    if calculateRegParam
        switch GridtypeChoiceStr
            case 'Even Grid'
                switch reg_cornerChoiceStr
                    case 'Current Value'
                        % continue
                    case 'L-Curve Optimal L2-Norm (L2)'
                        %_____ added by WIM on 2020-02-20
                        SizeX = size(disp_grid_padded_Han);
                        SizeY = size(disp_grid_padded_Han);
                        [i_max,j_max, ~] = size(disp_grid_padded_Han);

                        xVecGrid = 1:SizeX;
                        yVecGrid = 1:SizeY;
                        [Xvec, Yvec] = ndgrid(xVecGrid, yVecGrid);
                        grid_mat_padded(:,:,1) = Xvec;
                        grid_mat_padded(:,:,2) = Yvec;
    %                                 disp('Calculating regularization parameter value...in progress...');
                        forceFieldParameters.LcurveFactor = 10;  
                        forceFieldParameters.regParam = 1;              

                        [i_max, j_max, ~] = size(disp_grid_padded_Han);
                        [rho,eta, reg_cornerTMP, alphas, FigHandleRegParam] = calculateLcurveFTTC(grid_mat_padded, disp_grid_padded_Han, forceFieldParameters.YoungModulus,...
                            forceFieldParameters.PoissonRatio, gridSpacing, i_max, j_max, forceFieldParameters.regParam, forceFieldParameters.LcurveFactor, false);
                        close(FigHandleRegParam)
                                    % update on 2020-07-05 replaced disp_grid with disp_gridHan 
%                         disp('Calculating regularization parameter value...completed');
                    case 'Optimized Bayesian L2 (BL2)'      % 2020-07-07. Not Han Windowed. No Padding. Wiener2D filter only.
                        clear displFieldTMP
                        displFieldTMP.pos = reshape(pos_grid, [size(pos_grid,1)*size(pos_grid,1), size(pos_grid,3)]);               % reshape the gridded data so that it can be plotted
                        displFieldTMP.vec = reshape(disp_grid, [size(disp_grid,1)*size(disp_grid,1), size(disp_grid,3)]);               % reshape the gridded data so that it can be plotted
                        [~, ~, ~, ~, ~, ~, ~, NoiseROIsCombinedTMP] = ...
                                DisplacementDriftCorrectionIdenticalCorners(displFieldTMP, CornerPercentage, 1, gridMagnification, ...
                                EdgeErode, GridtypeChoiceStr, InterpolationMethod, false);              % just to the NoiseROIs for whatever frame is fred (drift-corrected or not).
%                             NoiseROIsCombinedTMP = NoiseROIsCombined(CurrentFrame);
                        
                        [i_max, j_max, ~] = size(disp_grid);
                        [reg_cornerTMP] = optimal_lambda_complete(displFieldTMP, NoiseROIsCombinedTMP, forceFieldParameters.YoungModulus, forceFieldParameters.PoissonRatio, ...
                            gridMagnification, EdgeErode, i_max, j_max, disp_grid(:,:,1:2), GridtypeChoiceStr, InterpolationMethod, false, ScaleMicronPerPixel, 1, 1);   
                                     % update on 2020-07-06 displacement grid fed to this one is only Wiener-filtered without padding (disp_grid_Wiener_NoPadding)
                                     % previously it was Wiener-Filtered with padding (disp_grid_padded)
%                             disp('Calculating Bayesian Optimized regularization parameter value...completed');
                    otherwise
                        return
                end
                if ShowOutput, fprintf('FTTC regularization corner (reg_corner) is %g. \n', reg_cornerTMP);end

            case 'Odd Grid'  
                error('This segments of the code is incomplete. Use Odd-grid-based code')
            otherwise
                % INCOMPLETE
        end 
        if ShowOutput
            fprintf('Regularization parameter = %7.5g\n', reg_cornerTMP);
        end
        reg_corner(CurrentFrame) = reg_cornerTMP;
    end

%     %% * updated on 2020-07-06 by Waddah Moghram. To find the parameter. No Padding or Han Windowing.
% %         PaddingChoiceStr = 'Padded with zeros only';        % updated on 2020-07-06 by WIM
% %         HanWindowchoice = 'Yes'; 
% 
%     switch PaddingChoiceStr
%         case 'No padding'
%             % do nothing
%             disp_grid_NoFilter = disp_grid_NoFilter_NoPadding;
%         case 'Padded with random & zeros'
%             [disp_grid_NoFilter, ~, disp_grid_Padded_TopLeftCorner, disp_grid_Padded_BottomRightCorner] =  PadArrayRandomAndZeros(disp_grid_NoFilter_NoPadding);
%         case 'Padded with zeros only'
%             [disp_grid_NoFilter, ~, disp_grid_Padded_TopLeftCorner, disp_grid_Padded_BottomRightCorner] =  PadArrayRandomAndZeros(disp_grid_NoFilter_NoPadding, true);
%         otherwise
%             return
%     end
% 
%  %__ 5 Filtering the displacement field _______________________________________          
%     clear disp_grid stress_grid pos_grid_stress
%     switch SpatialFilterChoiceStr
%         case 'No-Filter'
%             disp_grid = disp_grid_NoFilter;
%             disp_gridHan = disp_grid;
%         case 'Wiener 2D'
%             disp_grid = NaN(size(disp_grid_NoFilter));
%             for ii = 1:size(disp_grid_NoFilter,3), disp_grid(:,:,ii) = wiener2(gather(disp_grid_NoFilter(:,:,ii)), gather(WienerWindowSize)); end
%             switch HanWindowchoice
%                 case 'Yes'
%                     disp_gridHan = HanWindow(disp_grid);
%                     HanWindowBoolean = true;
%                 case 'No'
%                     disp_gridHan  = disp_grid;
%                     HanWindowBoolean = false;
%                     % Continue
%             end
%         case 'Low-Pass Exponential 2D' 
%             [pos_grid_stress, disp_grid, stress_grid, i_max, j_max, qMax] = Filters_LowPassExponential2D(pos_grid, disp_grid_NoFilter, gridSpacing, thickness_um, thickness_um,  YoungModulusPa, PoissonRatio, ...
%                 fracPad, min_feature_size, ExponentOrder, reg_corner, i_max, j_max);
%         case 'Low-Pass Butterworth'
%             [pos_grid_stress, disp_grid, stress_grid, i_max, j_max, qMax] = Filters_LowPassButterworth2D(pos_grid, disp_grid_NoFilter, gridSpacing, [], [],  YoungModulusPa, PoissonRatio, ...
%                 fracPad, 3, BW_order, i_max, j_max);            
%     end

    % __ 7 calculate the traction stress field "forceField" in Pa  _______________________________________    
    [i_max,j_max, ~] = size(disp_grid_padded_Han);
    reg_cornerTMP =  reg_corner(CurrentFrame);
    switch SpatialFilterChoiceStr
        case {'No-Filter', 'Wiener 2D'}
            switch TractionStressMethod
                case 'FTTC'
                    forceFieldParameters.method = 'FTTC';
                    switch GridtypeChoiceStr
                        case 'Even Grid'
                            [pos_grid_stress, stress_vec, stress_grid, stress_grid_norm] = reg_fourier_TFM(pos_grid, disp_grid_padded_Han(:,:,1:2), forceFieldParameters.YoungModulus,...
                                forceFieldParameters.PoissonRatio, ScaleMicronPerPixel, gridSpacing, i_max, j_max, reg_cornerTMP);
%                                 [pos_grid_stress, stress_vec, stress_grid, stress_grid_norm] = reg_fourier_TFM_Updated(pos_grid, disp_gridHan(:,:,1:2), YoungModulusPa,...
%                                     PoissonRatio, ScaleMicronPerPixel, 0, gridSpacing, i_max, j_max, reg_corner);         % updated on 2020-05-08
                            stress_grid(:,3) = stress_grid_norm;
                        case 'Odd Grid'
% %                             %   output is embedded in LowPassGaussian2DFilter
                            [pos_grid_stress,stress_vec, stress_grid, stress_grid_norm] = reg_fourier_TFM_odd(pos_grid, disp_grid_padded_Han(:,:,1:2), forceFieldParameters.YoungModulus,...
                                forceFieldParameters.PoissonRatio, ScaleMicronPerPixel, gridSpacing, i_max, j_max, reg_cornerTMP);
                            stress_grid(:,3) = stress_grid_norm;
                    end
            end
        otherwise
            % continue
    end

%__ 8 Reshape & Trim the displacement  integration traction force in N  _______________________________________ 
    pos_grid_size = size(pos_grid);
    disp_grid_size = size(disp_grid_padded);
    pos_grid_stress = reshape(pos_grid_stress, pos_grid_size);            
    stress_grid = reshape(stress_grid, disp_grid_size);    

    clear disp_grid_trimmed stress_grid_trimmed
    switch PaddingChoiceStr
        case { 'Padded with random & zeros', 'Padded with zeros only'}       
            clear disp_grid_trimmed disp_grid_NoFilter_trimmed stress_grid_trimmed
            for ii = 1:size(disp_grid_padded, 3)
                disp_grid_trimmed(:,:,ii) = disp_grid_padded_Han(disp_grid_Padded_TopLeftCorner(1):disp_grid_Padded_BottomRightCorner(1) , disp_grid_Padded_TopLeftCorner(2):disp_grid_Padded_BottomRightCorner(2), ii);
                disp_grid_NoFilter_trimmed(:,:,ii) = disp_grid_padded(disp_grid_Padded_TopLeftCorner(1):disp_grid_Padded_BottomRightCorner(1) , disp_grid_Padded_TopLeftCorner(2):disp_grid_Padded_BottomRightCorner(2), ii);
            end 
            for ii = 1:size(stress_grid, 3)
                stress_grid_trimmed(:,:,ii) = stress_grid(disp_grid_Padded_TopLeftCorner(1):disp_grid_Padded_BottomRightCorner(1) , disp_grid_Padded_TopLeftCorner(2):disp_grid_Padded_BottomRightCorner(2), ii);
            end
            clear disp_grid stress_grid disp_grid_NoFilter
            disp_grid = disp_grid_trimmed;
            disp_grid_NoFilter = disp_grid_NoFilter_trimmed;
            stress_grid = stress_grid_trimmed;

            disp_grid_trimmed_size = size(disp_grid_trimmed);
            stress_grid_trimmed_size = size(stress_grid_trimmed);

        case 'No padding'
            % do nothing
        otherwise
            return
    end

%__ 9 Testing 2020-01-23 Integrate only a part of the stress field. This is to test if there is any effect. Create a mask _______________________________________ 
   if StressMask
            stress_grid2 = stress_grid;
            pos_grid_stress_MaskX = (pos_grid_stress(:,:,1) > (Center(1) - Width)) & (pos_grid_stress(:,:,1) < (Center(1) + Width));
            pos_grid_stress_MaskY = (pos_grid_stress(:,:,2) > (Center(2) - Width)) & (pos_grid_stress(:,:,2) < (Center(2) + Width));
            pos_grid_stress_Mask = pos_grid_stress_MaskX & pos_grid_stress_MaskY;
%             figure, imagesc(pos_grid_stress_Mask)
%              xlabel('X [pixels]')
%             ylabel('Y [pixels]')

            for k = 1:3, stress_grid(:,:,k) = stress_grid2(:,:,k).* pos_grid_stress_Mask; end
%             figure, surf(pos_grid_stress(:,:,1), pos_grid_stress(:,:,2), stress_grid3(:,:,3))
%             zlabel('T(x,y,t) [\mum]')
%             xlabel('X [pixels]')
%             ylabel('Y [pixels]')
   end

%__ 10 Calculate the integration traction force in N _______________________________________ 
    switch ForceIntegrationMethod
        case 'Summed'
            % Integrate the traction stresses
            if numel(size(stress_grid)) == 3         % is 3-layer grids
                ForceN(CurrentFrame, :) = TractionForceSingleFrameNoMD(pos_grid_stress, stress_grid(:,:,1:2), ScaleMicronPerPixel, ForceIntegrationMethod, [], ShowOutput);
            else
                ForceN(CurrentFrame, :) = TractionForceSingleFrameNoMD(pos_grid_stress, stress_grid(:,1:2), ScaleMicronPerPixel, ForceIntegrationMethod, [], ShowOutput);
            end

    end
    if useGPU, ForceN = gather(ForceN); end
%     TractionForceX= Force(:,1);
%     TractionForceY = Force(:,2);
%     TractionForce = Force(:,3);

%__ 11 Reshsaping for the output _______________________________________ 
    displFieldNoFilteredGrid(CurrentFrame).pos = gather(reshape(pos_grid(:,:,1:2) , [pos_grid_size(1) * pos_grid_size(2), pos_grid_size(3)]));
    displFieldNoFilteredGrid(CurrentFrame).vec = gather(reshape(disp_grid_trimmed(:,:,1:2) , [pos_grid_size(1) * pos_grid_size(2), pos_grid_size(3)]));
    displFieldNoFilteredGrid(CurrentFrame).vec(:,3) = vecnorm(displFieldNoFilteredGrid(CurrentFrame).vec(:,1:2), 2, 2);             % find the norm and put it in the third column
%          
    displFieldFilteredGrid(CurrentFrame).pos = gather(reshape(pos_grid(:,:,1:2) , [pos_grid_size(1) * pos_grid_size(2), pos_grid_size(3)]));
    displFieldFilteredGrid(CurrentFrame).vec = gather(reshape(disp_grid(:,:,1:2) , [pos_grid_size(1) * pos_grid_size(2), pos_grid_size(3)]));
    displFieldFilteredGrid(CurrentFrame).vec(:,3) = vecnorm(displFieldFilteredGrid(CurrentFrame).vec(:,1:2) , 2, 2);

    forceField(CurrentFrame).pos = gather(reshape(pos_grid_stress(:,:,1:2), [pos_grid_size(1) * pos_grid_size(2), 2]));    
    forceField(CurrentFrame).vec = gather(reshape(stress_grid(:,:,1:2),  [pos_grid_size(1) * pos_grid_size(2), pos_grid_size(3)]));   
    forceField(CurrentFrame).vec(:,3) = vecnorm(forceField(CurrentFrame).vec(:,1:2), 2, 2);

%__ 12 Calculate Energy Storage _______________________________________ 
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

    totalAreaMicronSq = (Ymax-Ymin)*(Xmax-Xmin);
    totalPointsCount = meshGridSize(1) * meshGridSize(2);
    AvgAreaMicronSq = (totalAreaMicronSq)/(totalPointsCount);
    AvgAreaMetersSq =  AvgAreaMicronSq * ConversionMicronSqtoMetersSq;

    % displacement is in pixels, convert to meters. Stress is in Pa. 
    disp_grid_trimmed_meters = disp_grid_trimmed .* ScaleMicronPerPixel .* ConversionMicrontoMeters;           

    energyDensityField(CurrentFrame).pos = forceField.pos ;        
    energyDensityField_gridX = 1/2 * disp_grid_trimmed_meters(:,:,1).* stress_grid_trimmed(:,:,1);
    energyDensityField_gridY = 1/2 * disp_grid_trimmed_meters(:,:,2).* stress_grid_trimmed(:,:,2);  
    energyDensityField_grid = energyDensityField_gridX + energyDensityField_gridY;

%         energyDensityField(CurrentFrame).vec(:, 1) = gather(reshape(energyDensityField_gridX , size(forceField(CurrentFrame).vec(:,1)))) + ...
%             gather(reshape(energyDensityField_gridY , size(forceField(CurrentFrame).vec(:,2))));
% alternatively you can use. Less computation time (resizing matrices)
    energyDensityField(CurrentFrame).vec(:, 1) = gather(reshape(energyDensityField_gridX + energyDensityField_gridY , size(forceField(CurrentFrame).vec(:,1))));

    TractionEnergyJ(CurrentFrame) = sum(sum(energyDensityField_grid)) .* AvgAreaMetersSq;                  % TrDotUr;        

end

