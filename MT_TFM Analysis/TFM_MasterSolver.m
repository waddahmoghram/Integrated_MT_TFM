%{
    v.2020-07-07 by Waddah Moghram, PhD candidate in biomedical engineering at the University of Iowa
        1. Need to fix forceFieldCalculationInfo based on Moviedata forceField process.
    v.2020-07-05 
        1. No user choice for Han or Padding. For the Optimal BL2 parameter, no padding or Han-windowing is required.
        2. For the second step after the regularization parameters are found, the gridded displacement field is padded with zeros, then Han-windowed.
    v.2020-06-29..07-04 by Waddah Moghram
        1. Updated so that it can solve for everything. Regularization parameter is an optional choice. If given, it will use it.
%}

function [pos_grid, displFieldNoFilteredGrid, displFieldFilteredGrid, forceField, energyDensityField, ForceN, TractionEnergyJ, ...
    reg_corner, forceFieldParameters, CornerPercentage, NoiseROIsCombined] = ...
    TFM_MasterSolver(displField, NoiseROIsCombined,forceFieldParameters, reg_corner, ...
    gridMagnification, EdgeErode, PaddingChoiceStr, SpatialFilterChoiceStr, HanWindowchoice, ...
    GridtypeChoiceStr, reg_cornerChoiceStr, InterpolationMethod, TractionStressMethod, ForceIntegrationMethod, ...
    WienerWindowSize, ScaleMicronPerPixel, ShowOutput, FirstFrame, LastFrame, CornerPercentage, IsOptimization)
     
    ConversionMicrontoMeters = 1e-6;
    ConversionMicronSqtoMetersSq = ConversionMicrontoMeters.^2;      
%     EdgeErode = 1;                                      % do not change to 0. Update 2020-01-29
%     gridMagnification = 1;
%     WienerWindowSize = 3;
%     ForceIntegrationMethod = 'Summed';
%     TractionStressMethod = 'FTTC';   
%     GridtypeChoiceStr = 'Even Grid';
%     HanWindowchoice = 'Yes';
%     reg_cornerChoiceStr = 'Optimized Bayesian L2 (BL2)'; 
%     InterpolationMethod = 'griddata';                   % vs. InterpolationMethod = 'scatteredinterpolant';
%     PaddingChoiceStr = 'Padded with zeros only';        % updated on 2020-03-03 by WIM
%     ShowOutput = true;
%     SpatialFilterChoiceStr = 'Wiener 2D';    
%     WienerWindowSize = [3, 3];         % 3x3 pixels
   
%     energyDensityFieldUnits = 'J/m^2';
%     ConversionNtoNN = 1e9;            
%     CornerPercentageDefault = 0.10;   
%     cornerCount = 4;
% %     DCchoice = 'Yes'; 
% CalculateTFM = true;

    %% 0 ------  Create if statements to give default values if none are given

    %% 1 ------ check for GPU to use if possible
    nGPU = gpuDeviceCount;
    if nGPU > 0
        useGPU = true;
    else
        useGPU = false;
    end

    StressMask  = false;
    if isempty(forceFieldParameters)
        forceFieldParameters.YoungModulusPa = [];
        forceFieldParameters.PoissonRatio = [];
        forceFieldParameters.GelType = [];
        forceFieldParameters.thickness = [];
        forceFieldParameters.GelConcentrationMgMl = [];
    end

    %% 2 ------  Open the displacement field first    
    if ~exist('displField','var'), displField = []; end
    if isempty(displField)
        [displacementFileName, displacementFilePath] = uigetfile(fullfile(pwd, '*.mat'), 'Open the displacement field "displField.mat" under displacementField or backups');
        if displacementFileName == 0, return; end
        DisplacementFileFullName = fullfile(displacementFilePath, displacementFileName);
        try
            load(DisplacementFileFullName, 'displField', 'MD');   
            fprintf('Displacement Field (displField) File is successfully loaded!: \n\t %s\n', DisplacementFileFullName);
            disp('------------------------------------------------------------------------------')
        catch
            errordlg('Could not open the displacement field file.');
            return
        end
        movieData = MD;
    else
        if ischar(displField)
            try
                load(displField, 'displField', 'MD');   
                fprintf('Displacement Field (displField) File is successfully loaded!: \n\t %s\n', displField);
                disp('------------------------------------------------------------------------------')
            catch
                errordlg('Could not open the displacement field file.');
                return
            end
            movieData = MD;
        elseif isstruct(displField)
            % continue
        else
            error('Incorrect displField variable')
        end
    end
    
    %% 3  ------ Scale for the movie 
    if ~exist('ScaleMicronPerPixel', 'var'), ScaleMicronPerPixel = []; end
    if isempty(ScaleMicronPerPixel) || nargin < 16
        % 5. choose the scale (microns/pixels) & image Bits         
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
    end
  
    %% 4  ------ find first & last frame numbers to be plotted  
    FramesDoneBoolean = arrayfun(@(x) ~isempty(x.vec), displField);
    FramesDoneNumbers = find(FramesDoneBoolean == 1);       
    VeryFirstFrame = find(FramesDoneBoolean, 1, 'first');   
    VeryLastFrame =  find(FramesDoneBoolean, 1, 'last');
    
    if ~exist('FirstFrame', 'var'), FirstFrame = []; end
    if isempty(FirstFrame) || nargin < 18
        commandwindow;
        prompt = {sprintf('Choose the first frame to plotted. [Default, Frame # = %d]', VeryFirstFrame)};
        dlgTitle = 'First Frame';
        FirstFrameStr = inputdlg(prompt, dlgTitle, [1, 100], {num2str(VeryFirstFrame)});
        if isempty(FirstFrameStr), return; end
        FirstFrame = str2double(FirstFrameStr{1});
    end
    [~, FirstFrameIndex] = min(abs(FramesDoneNumbers - FirstFrame));
    FirstFrame = FramesDoneNumbers(FirstFrameIndex);

    if ~exist('LastFrame', 'var'), LastFrame = []; end
    if isempty(LastFrame) || nargin < 19
        prompt = {sprintf('Choose the last frame to plotted. [Default, Frame # = %d]. \nNote: Might be truncated if sensor signal is less than the number of frames', VeryLastFrame)};
        dlgTitle = 'Last Frame';
        LastFrameStr = inputdlg(prompt, dlgTitle, [1, 100], {num2str(VeryLastFrame)});
        if isempty(LastFrameStr), return; end
        LastFrame = str2double(LastFrameStr{1}); 
    end
    
    [~, LastFrameIndex] = min(abs(FramesDoneNumbers - LastFrame));
    LastFrame = FramesDoneNumbers(LastFrameIndex);

%     FramesDoneBoolean = FramesDoneBoolean(FirstFrameIndex:LastFrameIndex);
    FramesDoneNumbers = FramesDoneNumbers(FirstFrameIndex:LastFrameIndex);
    
%     displField = displField(FramesDoneNumbers);
        
    if ~exist('reg_corner', 'var'), reg_corner = []; end
    if isempty(reg_corner)
        calculateRegParam = true;
    else
        calculateRegParam = false;
        if numel(reg_corner) == 1
            reg_corner = repmat(reg_corner, size(FramesDoneNumbers));
        else
            try
                reg_corner = reg_corner(FramesDoneNumbers);             % make sure they are the same number
            catch
                error('mismatched dimensions of L2 parameters')
            end
        end
    end
    
    %% 5  ------ Ask for the corner percentage if it has not been given already

    %% 6 ------  Try loading noiseROIcombined variable if present. If not. Create it here.
    if ~exist('NoiseROIsCombined','var'), NoiseROIsCombined = []; end
    if isempty(NoiseROIsCombined) || nargin < 2
        try
            load(DisplacementFileFullName, 'NoiseROIsCombined');   
            fprintf('Noise Variables where extracted successfully from: \n\t %s\n', DisplacementFileFullName);
            disp('------------------------------------------------------------------------------')

            NoiseROIsCombined = NoiseROIsCombined(FramesDoneNumbers);
            forceFieldParameters.CornerPercentage = CornerPercentage;
            try
                [~, ~, ~, ~, ~, NoiseROIsCombined] = ...
                    DisplacementDriftCorrectionIdenticalCorners(displField, CornerPercentage, FramesDoneNumbers, gridMagnification, ...
                    EdgeErode, GridtypeChoiceStr, InterpolationMethod, ShowOutput);
                NoiseROIsCombined = NoiseROIsCombined(FramesDoneNumbers);
            catch
                errordlg('Could not open the displacement field file.');
            end
        catch
            
            % do nothing
        end
    end
    commandwindow;
    if ~exist('CornerPercentage', 'var'), CornerPercentage = []; end
    if isempty(CornerPercentage) || nargin < 20
        inputStr = sprintf('Choose the percentage of the images size to use for noise adjustment [Default = %0.2g%%]: ', CornerPercentageDefault * 100);
        CornerPercentage = input(inputStr);
        if isempty(CornerPercentage)
           CornerPercentage =  CornerPercentageDefault; 
        else
           CornerPercentage = CornerPercentage / 100;
        end
    end
    if ~exist('IsOptimization', 'var'), IsOptimization = []; end
    if isempty(IsOptimization) || nargin < 21
            IsOptimization = false;
    end

    %% 7 ------ Setting up TFM variables (E, nu, etc. 
    thickness_um = [];
    YoungModulusPa = [];
    PoissonRatio = [];
%     GelType = '';
%     GelConcentrationMgMl = [];
    GelConcentrationMgMlStr = '';
    
    if ~exist('forceFieldParameters', 'var'), forceFieldParameters = []; end
    if isempty(forceFieldParameters) || nargin < 3
        %----------------------------------------------
        YoungModulusSavedChoice = questdlg('Do you have a saved Young Elastic Modulus (E) value?', 'Saved Young Modulus (E)?', 'Yes. Optimized', 'Yes. forceFieldParameters', 'No', 'Yes. Optimized');
        switch YoungModulusSavedChoice
            case 'Yes. Optimized'
                [YoungModulusFilename, YoungModulusPathName] = uigetfile(fullfile(pwd, '*.mat'), 'Young Modulus ...*.mat');
                if isempty(YoungModulusFilename), error('No File Was chosen'); end
                YoungModulusFullFileName = fullfile(YoungModulusPathName, YoungModulusFilename);
                YoungModulusFullFileNameStruct = load(YoungModulusFullFileName);
                try
                    YoungModulusPa = YoungModulusFullFileNameStruct.YoungModulusOptimum;
                catch
                    YoungModulusPa = [];
                end
            case 'Yes. forceFieldParameters'
                [YoungModulusFilename, YoungModulusPathName] = uigetfile(fullfile(pwd, '*.mat'), 'Young Modulus ...*.mat');
                if isempty(YoungModulusFilename), error('No File Was chosen'); end
                YoungModulusFullFileName = fullfile(YoungModulusPathName, YoungModulusFilename);
                YoungModulusFullFileNameStruct = load(YoungModulusFullFileName);
                forceFieldParameters = YoungModulusFullFileNameStruct.forceFieldParameters;
            case 'No'
                YoungModulusPa = [];
            otherwise
                return        
        end
        
        switch YoungModulusSavedChoice
            case 'Yes. Optimized'     
                try
                    PoissonRatio = YoungModulusFullFileNameStruct.PoissonRatio;
                catch
                    PoissonRatio = [];
                end 
%                PoissonRatio = forceFieldCalculationInfo.funParams_.PoissonRatio;
            case 'No'
                PoissonRatio = [];
        end
        %----------------------------------------------
        try
            try
                thickness_um = forceFieldCalculationInfo.funParams_.thickness_nm/1000;
            catch
                thickness_um = forceFieldCalculationInfo.funParams_.thickness/1000;
            end
        catch
            thickness_um = [];
        end
    end
        
    try YoungModulusPa = forceFieldParameters.YoungModulusPa; catch, YoungModulusPa = []; end
    try PoissonRatio = forceFieldParameters.PoissonRatio; catch, PoissonRatio = []; end
    try GelType = forceFieldParameters.GelType{1}; catch, GelType = []; end
    try thickness_um = forceFieldParameters.thickness_nm; catch, thickness_um = []; end
    try GelConcentrationMgMl = forceFieldParameters.GelConcentrationMgMl; catch, GelConcentrationMgMl = []; end
    
    commandwindow;
    if isempty(YoungModulusPa)
        YoungModulusPa = input('What was the gel''s Young Elastic modulus (in Pa)? ');  
    end
    if ShowOutput, fprintf('Gel''s elastic modulus (E) is %g  Pa. \n', YoungModulusPa); end
    
    if isempty(PoissonRatio)
        PoissonRatio = input('What was the gel''s Poisson Ratio (unitless)? ');  
    end
    if ShowOutput,fprintf('Gel''s Poisson Ratio (nu) is %g. \n', PoissonRatio); end
            
    if isempty(thickness_um)
        commandwindow;
        thickness_um = input('What was the gel thickness in microns? ');
        if ShowOutput, fprintf('Gel thickness is %d  microns. \n', thickness_um); end
    end 
        
    if isempty(GelType)
        GelType = input('What type of gel was used for the experiment? ', 's');
    end
    if ShowOutput
        if ~isempty(GelType)
           fprintf('Gel type is: "%s" \n', GelType);
        else
           disp('No gel type was given')
           GelType = '';
        end
    end    
    if isempty(GelConcentrationMgMl)
        GelConcentrationMgMl = input('What was the gel concentration in mg/mL? '); 
    end
    if ShowOutput, fprintf('Gel Concentration Chosen is %s mg/mL. \n', GelConcentrationMgMlStr); end
        
    if isempty(forceFieldParameters.thickness_nm), forceFieldParameters.thickness_nm = thickness_um * 1000; end
    if isempty(forceFieldParameters.YoungModulusPa), forceFieldParameters.YoungModulusPa = YoungModulusPa; end
    if isempty(forceFieldParameters.PoissonRatio), forceFieldParameters.PoissonRatio = PoissonRatio; end
    if isempty(forceFieldParameters.GelType), forceFieldParameters.GelType = GelType; end
    if isempty(forceFieldParameters.GelConcentrationMgMl), forceFieldParameters.GelConcentrationMgMl = GelConcentrationMgMl * 1000; end
    forceFieldParameters.thicknessUnits = 'nanomemters';
    forceFieldParameters.YoungModulusUnits = 'Pa';
    forceFieldParameters.GelConcentrationMgMl = GelConcentrationMgMl;
    
    %% 8  ------ Starting the TFM Solver Loop over all frames
    NoiseROIsCombined = struct();   NoiseROIsCombined.pos = []; NoiseROIsCombined.vec = [];  NoiseROIsCombined.mean = [];  
    
%     reverseString = '';
    if ShowOutput
        disp('_______ Using Solving TFM_MasterSolver to find all TFM results _______')
    end       
    for CurrentFrame = FramesDoneNumbers
        if ShowOutput
%             ProgressMsg = sprintf('Processing Frame #%d/(%d-%d)...\n',CurrentFrame, FramesDoneNumbers(1),FramesDoneNumbers(end));
%             fprintf([reverseString, ProgressMsg]);
%             reverseString = repmat(sprintf('\b'), 1, length(ProgressMsg));
            fprintf('______________________________Processing Frame #%d/(%d-%d)_________________________________________\n', ...
                CurrentFrame, FramesDoneNumbers(1),FramesDoneNumbers(end));
        end 

        displFieldTMP =  displField(CurrentFrame);
        displFieldTMPPos = displFieldTMP.pos;
        displFieldTMPVec = displFieldTMP.vec;
        
        switch GridtypeChoiceStr
            case 'Even Grid'
                    [reg_grid,~,~,gridSpacing] = createRegGridFromDisplField(displFieldTMPPos, gridMagnification, EdgeErode);
            case 'Odd Grid'
                    [reg_grid,~,~,gridSpacing] = createRegGridFromDisplFieldOdd(displFieldTMPPos, gridMagnification, EdgeErode);
            otherwise
                return
        end
        
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
                            [rho,eta, reg_cornerTMP, alphas, FigHandleRegParam] = calculateLcurveFTTC(grid_mat_padded, disp_grid_padded_Han, forceFieldParameters.YoungModulusPa,...
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
                            NoiseROIsCombined(CurrentFrame) = NoiseROIsCombinedTMP;
                            [i_max, j_max, ~] = size(disp_grid);
                            [reg_cornerTMP] = optimal_lambda_complete(displFieldTMP, NoiseROIsCombinedTMP, forceFieldParameters.YoungModulusPa, forceFieldParameters.PoissonRatio, ...
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
        
        if IsOptimization == false
    %         %% * updated on 2020-07-06 by Waddah Moghram. To find the parameter. No Padding or Han Windowing.
    % %         PaddingChoiceStr = 'Padded with zeros only';        % updated on 2020-07-06 by WIM
    % %         HanWindowchoice = 'Yes'; 
    %         
    %         switch PaddingChoiceStr
    %             case 'No padding'
    %                 % do nothing
    %                 disp_grid_NoFilter = disp_grid_NoFilter_NoPadding;
    %             case 'Padded with random & zeros'
    %                 [disp_grid_NoFilter, ~, disp_grid_Padded_TopLeftCorner, disp_grid_Padded_BottomRightCorner] =  PadArrayRandomAndZeros(disp_grid_NoFilter_NoPadding);
    %             case 'Padded with zeros only'
    %                 [disp_grid_NoFilter, ~, disp_grid_Padded_TopLeftCorner, disp_grid_Padded_BottomRightCorner] =  PadArrayRandomAndZeros(disp_grid_NoFilter_NoPadding, true);
    %             otherwise
    %                 return
    %         end
    % 
    %      %__ 5 Filtering the displacement field _______________________________________          
    %         clear disp_grid stress_grid pos_grid_stress
    %         switch SpatialFilterChoiceStr
    %             case 'No-Filter'
    %                 disp_grid = disp_grid_NoFilter;
    %                 disp_gridHan = disp_grid;
    %             case 'Wiener 2D'
    %                 disp_grid = NaN(size(disp_grid_NoFilter));
    %                 for ii = 1:size(disp_grid_NoFilter,3), disp_grid(:,:,ii) = wiener2(gather(disp_grid_NoFilter(:,:,ii)), gather(WienerWindowSize)); end
    %                 switch HanWindowchoice
    %                     case 'Yes'
    %                         disp_gridHan = HanWindow(disp_grid);
    %                         HanWindowBoolean = true;
    %                     case 'No'
    %                         disp_gridHan  = disp_grid;
    %                         HanWindowBoolean = false;
    %                         % Continue
    %                 end
    %             case 'Low-Pass Exponential 2D' 
    %                 [pos_grid_stress, disp_grid, stress_grid, i_max, j_max, qMax] = Filters_LowPassExponential2D(pos_grid, disp_grid_NoFilter, gridSpacing, thickness_um, thickness_um,  YoungModulusPa, PoissonRatio, ...
    %                     fracPad, min_feature_size, ExponentOrder, reg_corner, i_max, j_max);
    %             case 'Low-Pass Butterworth'
    %                 [pos_grid_stress, disp_grid, stress_grid, i_max, j_max, qMax] = Filters_LowPassButterworth2D(pos_grid, disp_grid_NoFilter, gridSpacing, [], [],  YoungModulusPa, PoissonRatio, ...
    %                     fracPad, 3, BW_order, i_max, j_max);            
    %         end

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
                                    [pos_grid_stress, stress_vec, stress_grid, stress_grid_norm] = reg_fourier_TFM(pos_grid, disp_grid_padded_Han(:,:,1:2), forceFieldParameters.YoungModulusPa,...
                                        forceFieldParameters.PoissonRatio, ScaleMicronPerPixel, gridSpacing, i_max, j_max, reg_cornerTMP);
        %                                 [pos_grid_stress, stress_vec, stress_grid, stress_grid_norm] = reg_fourier_TFM_Updated(pos_grid, disp_gridHan(:,:,1:2), YoungModulusPa,...
        %                                     PoissonRatio, ScaleMicronPerPixel, 0, gridSpacing, i_max, j_max, reg_corner);         % updated on 2020-05-08
                                    stress_grid(:,3) = stress_grid_norm;
                                case 'Odd Grid'
        % %                             %   output is embedded in LowPassGaussian2DFilter
                                    [pos_grid_stress,stress_vec, stress_grid, stress_grid_norm] = reg_fourier_TFM_odd(pos_grid, disp_grid_padded_Han(:,:,1:2), forceFieldParameters.YoungModulusPa,...
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

            TractionEnergyJ(CurrentFrame)  = sum(sum(energyDensityField_grid)) .* AvgAreaMetersSq;                  % TrDotUr;        
        else
            ForceN = [];
            displFieldNoFilteredGrid = [];
            displFieldFilteredGrid = [];
            forceField = [];
            energyDensityField = [];
            TractionEnergyJ = [];
            
            
        end
        
    end
end

