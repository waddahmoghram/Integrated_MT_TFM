%{
    v.2020-03-04 by Waddah Moghram
        1. Added strain energy calculation to the output for all outputs
        2. Renamed from TractionForceFieldAllFramesFilteredScript.m to VideoAnalysisEPI
    v.2020-02-25 by Waddah Moghram
        1. Fixed glitch that asks you to save DRIFTROI figure even if the choice is no
    v.2020-02-20 by Waddah Moghram
        1. Change the default padding method to 'pad with zero's only' as this will be our method moving forward.. 
            padding with randoms + zeros results in traction force variability by about +/-5%.+
        2. shifted the code so that the re-calculated regularization parameter is based on the padded matrix size that will be used
          to find the L-Curve value for the regularized parameter of the FTTC Solution., and not the trimmed matrix.
    v.2020-02-18 by Waddah Moghram
        1. commented out RepeatExperimemntChoice to always 'NO'
    v.2020-02-09 by Waddah Moghram
        1. Insert Scalebar into matlab figures. 
    v.2020-02-05 by Waddah Moghram
        1. Update so that we save displacement field after Wiener 2D Filter (W2DF) and before Han Windowing if that is an option.
            Input to FTTC is dispGridHan instead of dispGrid
    v.2020-02-01 by Waddah Moghram
        1. Updated so that saved ROI has trueSize
    v.2020-01-28..29 by Waddah Moghram
        1. Updated grid choice so that it is EdgeErode = 1, gridMagnification = 1 (although = 2 make no difference here).
        2. make the first frame identically t = 0 
    v.2020-01-18 by Waddah Moghram
        1. Modified the legends so that they match those in the manuscript.
    v.2020-01-15 by Waddah Moghram.
        1. Only output displField filtered if that is filtered besides the unfiltered one to avoid a duplicate and confusion
    v.2020-01-14 by Waddah Moghram
        1. convert displacement field grid to a vector.
    v.2020-01-09 by Waddah MoghramExtractBeadCoordinatesEpiMaxInterp
        1. Updated to give shorter file names
        2. Added choice to ask if the displacement was filtered in time. If so, the variables are also saved here.
    v.2020-01-07 by Waddah Moghram
        1. Output stress field (forceField.mat) to the same structure format to be used for continuous analysis
    v.2020-01-04 by Waddah Moghram
        1. Updated errors with empty dialog boxes when run a second time
    v.2019-12-18 by Waddah Moghram
        1. Renamed to TractionForceFieldAllFramesFilteredScript.m from TractionForceFieldAllFramesFiltered.m
        2. Fixed code to allow to enter reg_corner manually, or load it, or recalculate it on the spot.
    v.2019-12-17 by Waddah Moghram
        1. updated movieData = forceFieldProcessStruct.movieDataAfter if the movie data is not embedded in that structure.
    v.2019-12-14 by Waddah Moghram
        1. Updated input arguments for Filters_LowPassExponential2D() and Filters_LowPassButterworth2D()
        2. Replaced 'Low-Pass Gaussian 2D' to 'Low-Pass Exponential 2D'
        3. Updated windowing and filtering option choices based on the filter choice.
    v.2019-12-13 Updated by Waddah Moghram
        1. Added the capabilty to plot surfaces for comparison. based on Filters_SingleFramePlot.m v.2019-11-21..24
            *Added to the very end. Section 6.0
        2. Change the output saved to only "AnalysisPath" and not "tractionFieldPath"
    v.2019-11-26..12-12 Written by Waddah Moghram, PhD Student in Biomedical Engineering at the University of Iowa
        based on Filters_SingleFramePlots.m
        1. Updated filters
        2. Updated ROI selection to 4 frames.
        3. Added displacement mean plots option (for negative control experiments).
        4. Updated otherwise structure for switch-case
        5. Added mean(displacement) for negative-control mode.
    v.2019-11-20:
        based on FilteringSingleFramePlots.m v.2019-11-20 
%}

%% Default Options that we decided on to save time moving down the road 2020-01-18
%     DCchoice = 'Yes';
% 
    ConversionNtoNN = 1e9;            
    ConversionMicronPerM = 1e6;        
    ConversionJtoPicoJ = 1e-12;
        
    FrameDisplMeanChoice = 'No';
    SpatialFilterChoiceStr = 'Wiener 2D';
    windowSizeChoice = 3;         % 3 pixels
    HanWindowchoice = 'Yes';
    RepeatExperimemntChoice = 'No';
    GridtypeChoiceStr = 'Even Grid';
    PaddingChoiceStr = 'Padded with zeros only';                   % updated on 2020-03-03 by WIM
    IdenticalCornersChoice = 'Yes';
    CentralROIChoice = 'No';
    RepeatExperimemntChoice = 'No';
    
    InterpolationMethod = 'griddata';               % vs. InterpolationMethod = 'scatteredinterpolant';
    TractionStressMethod = 'FTTC';
    intMethodStr = 'Summed';
    TractionForceMethod = 'Summed';

    QuiverColor = [1,1,0];

    SignificantDisplacementMicron = 0.5;                  % 0.5 microns Based on negative control experiments.
    SigLevel = 0.05;                                    % Statistical Significance:    
    CornerPercentageDefault = 0.10;             % 10% of dimension length of tracked particles grid for each of the 4 ROIs    
    MaskCenter = [535, 500];                % In pixels
    MaskWidth = 250;                              % In pixels
    StressMask = false;    
    gridMagnification = 1;
    EdgeErode = 1;                          % do not change to 0. Update 2020-01-29    
    bandSize = 0;   
    PlotsFontName = 'XITS';                     % replaced 'Cambria Math' with XITS, which is open source math font.
    
    %____ parameters for exportfig to *.eps
    EPSparam = struct();
    EPSparam.Bounds = 'tight';          % tight bounding box instead of loose.
    EPSparam.Color = 'rgb';             % rgb good for online stuff. cmyk is better for print.
    EPSparam.Renderer = 'Painters';     % instead of opengl, which is better for vectors
    EPSparam.Resolution = 600;          % DPI
    EPSparam.LockAxes = 1;              % true
    EPSparam.FontMode = 'fixed';        % instead of scaled
    EPSparam.FontSize = 10;             % 10 points
    EPSparam.FontEncoding = 'latin1';    % 'latin1' is standard for Western fonts. vs 'adobe'
    EPSparam.LineMode = 'fixed';        % fixed is better than scaled. 
    EPSparam.LineWidth = 1;           % can be varied depending on what you want it to be.

    EPSparams = {};
    EPSparamsFieldNames = fieldnames(EPSparam);
    for ii = (1:numel(fieldnames(EPSparam)))
        EPSparams{2*ii - 1} = EPSparamsFieldNames{ii};
    end
    for ii = (1:numel(fieldnames(EPSparam)))
        EPSparams{2*ii} = EPSparam.(EPSparamsFieldNames{ii});
    end
    
%% remember to clear all previous variables since this is a script and not a function
%     clear
    ShowOutput = true;
    nGPU = gpuDeviceCount;
    if nGPU > 0
        useGPU = true;
    else
        useGPU = false;
    end
    
    %% ================= 0 Select the experiment mode: Controlled Force vs. Controlled Displacement
    dlgQuestion = 'What is the control mode for EPI experiment? ';
    dlgTitle = 'Control Mode?';
    controlMode = questdlg(dlgQuestion, dlgTitle, 'Controlled Force', 'Controlled Displacement', 'Controlled Force');
    if isempty(controlMode), return; end

%% 0 Questions:    
    if ~exist('DCchoice', 'var'), DCchoice = []; end
    if isempty(DCchoice)
        DCchoice = questdlg('Do you want to drift-correct displacements?', 'Drift Correction','Yes', 'No', 'Yes');
        switch DCchoice
            case 'Yes'
                DCchoiceStr = 'Drift-Corrected';
            case 'No'
                DCchoiceStr = 'Drift-Uncorrected';
            otherwise
                error('X was selected');      
        end
    end
    
    if ~exist('FrameDisplMeanChoice', 'var'), FrameDisplMeanChoice = []; end
    if isempty(FrameDisplMeanChoice)
        dlgQuestion = {'Do you want to plot mean displacements over all frames?', 'Note: This is useful only for negative control experiments'};
        FrameDisplMeanChoice = questdlg(dlgQuestion, 'Displacements Over Time?','Yes', 'No', 'No');
        switch FrameDisplMeanChoice
            case {'Yes', 'No'}
                % continue
            otherwise
                error('X was selected');                
        end
    end
    
    if ~exist('SpatialFilterChoiceStr', 'var'), SpatialFilterChoiceStr = []; end
    if isempty(SpatialFilterChoiceStr)
        dlgQuestion = ({'Filtering method?'});
        FilterListStr = {'No-Filter', 'Wiener 2D', 'Low-Pass Exponential 2D', 'Low-Pass Butterworth'};         % , 'Median', 'Ad-hoc'
        FilterChoice = listdlg('ListString', FilterListStr, 'PromptString',dlgQuestion ,'InitialValue', 2, 'SelectionMode' ,'single');
        if isempty(FrameDisplMeanChoice), error('No method was selected'); end
        try
            SpatialFilterChoiceStr = FilterListStr{FilterChoice};                 % get the names of the string.   
        catch
            error('X was selected');           
        end      
        PaddingListStr = {'No padding', 'Padded with random & zeros', 'Padded with zeros only'};    
        dlgQuestion = ({'Pad displacement array?'});
        PaddingChoice = listdlg('ListString', PaddingListStr, 'PromptString',dlgQuestion ,'InitialValue', 3, 'SelectionMode' ,'single');    
        if isempty(PaddingChoice), error('No Padding Method was selected'); end
        try
            PaddingChoiceStr = PaddingListStr{PaddingChoice};                 % get the names of the string.   
        catch
            error('X was selected');      
        end
    end
    
    % Questions: remember to clear all previous variables since this is a script and not a function
%     clear
    if ~exist('InterpolationMethod', 'var'), InterpolationMethod = []; end
    if isempty(InterpolationMethod)
        RepeatExperimemntChoice = 'No';
    else
        if ~exist('RepeatExperimemntChoice', 'var'), RepeatExperimemntChoice = []; end
        if isempty(RepeatExperimemntChoice)
            RepeatExperimemntChoice = questdlg('Do you want to use the same parameters as before?', 'Repeat Experiments with Same Parameters?','Yes', 'No', 'No'); 
        end
    end
    switch RepeatExperimemntChoice
        case {'Yes', 'No'}
            % continue
        otherwise
            error('X was selected');      
    end

    if ~exist('GridtypeChoiceStr', 'var'), GridtypeChoiceStr = []; end
    if isempty(GridtypeChoiceStr)
        dlgQuestion = ({'Do want to create an odd- or even-numbers grid?'});
        dlgTitle = 'Odd or Even Grid?';
        GridtypeChoiceStr = questdlg(dlgQuestion, dlgTitle, 'Even Grid', 'Odd Grid', 'Even Grid');      
        switch GridtypeChoiceStr
            case {'Even Grid', 'Odd Grid'}
                % continue
            otherwise
                error('X was selected');      
        end
    end
    
%     switch RepeatExperimemntChoice
%         case 'No'            
            % 0.2 load tracked displacement file displField.mat
            if ~exist('displField', 'var'), displField = []; end
            if isempty(displField), DisplacementFieldchoice = 'No'; end
            if exist('DisplacementFileFullName', 'var')
                DisplacementFieldchoice = questdlg(sprintf('Do you want to use this displacement field file? \n\t %s', DisplacementFileFullName), 'Displacement Field?','Yes', 'No', 'Yes');
                if isempty(DisplacementFieldchoice), error('Could not open the displacement field file'); end                
            else
                DisplacementFieldchoice = 'No';
            end
            
            switch DisplacementFieldchoice
                case 'Yes'
                    if isempty(displField)
                        try
                            load(DisplacementFileFullName, 'displField');
                            disp('------------------------------------------------------------------------------')
                            fprintf('Displacement Field (displField) File is successfully loaded!: \n\t %s\n', DisplacementFileFullName);
                            disp('------------------------------------------------------------------------------')
                        catch
                            error('Could not open the displacement field file.');
                        end
                    end
                    % Continue Do nothing 
                case 'No'                    
                    [displacementFileName, displacementFilePath] = uigetfile(fullfile(pwd,'TFMPackage','*.mat'), 'Open the displacement field "displField.mat" under displacementField or backups');
                    DisplacementFileFullName = fullfile(displacementFilePath, displacementFileName);
                    try
                        load(DisplacementFileFullName, 'displField');
                        disp('------------------------------------------------------------------------------')
                        fprintf('Displacement Field (displField) File is successfully loaded!: \n\t %s\n', DisplacementFileFullName);
                        disp('------------------------------------------------------------------------------')
                    catch
                        error('Could not open the displacement field file.');
                    end
                otherwise
                    error('X was selected'); 
            end
            %____________________________
            FramesDoneBoolean = arrayfun(@(x) ~isempty(x.vec), displField);
            FramesDoneNumbers = find(FramesDoneBoolean == 1);       
            VeryFirstFrame = find(FramesDoneBoolean, 1, 'first');   
            VeryLastFrame =  find(FramesDoneBoolean, 1, 'last');
            commandwindow;
            prompt = {sprintf('Choose the first frame to plotted. [Default, Frame # = %d]', VeryFirstFrame)};
            dlgTitle = 'First Frame';
            FirstFrameStr = inputdlg(prompt, dlgTitle, [1, 90], {num2str(VeryFirstFrame)});
            if isempty(FirstFrameStr), return; end
            FirstFrame = str2double(FirstFrameStr{1});
            [~, FirstFrameIndex] = min(abs(FramesDoneNumbers - FirstFrame));
            FirstFrame = FramesDoneNumbers(FirstFrameIndex);
            
            prompt = {sprintf('Choose the last frame to plotted. [Default, Frame # = %d]. Note: Might be truncated if sensor signal is less', VeryLastFrame)};
            dlgTitle = 'Last Frame';
            LastFrameStr = inputdlg(prompt, dlgTitle, [1, 90], {num2str(VeryLastFrame)});
            if isempty(LastFrameStr), return; end
            LastFrame = str2double(LastFrameStr{1});
            [~, LastFrameIndex] = min(abs(FramesDoneNumbers - LastFrame));
            LastFrame = FramesDoneNumbers(LastFrameIndex);            
            FramesDoneNumbers = FramesDoneNumbers(FirstFrameIndex:LastFrameIndex);

            %___________ Ask if this displacement field was time-filtered to be output
            if ~isempty(DisplacementFileFullName)
                if ~exist('TimeFilterChoiceStr', 'var'), TimeFilterChoiceStr = []; end
                if isempty(TimeFilterChoiceStr)
                    dlgPrompt = sprintf('Were the displacements in this file filtered with low-pass equiripples filter?\n\t %s',DisplacementFileFullName); 
                    TimeFilterChoiceStr = questdlg(dlgPrompt, 'Low-Pass Filter?','Yes', 'No', 'Yes');
                    if isempty(TimeFilterChoiceStr), error('No choice was given'); end
                    switch TimeFilterChoiceStr
                        case 'Yes'
                            % Open the parameters file, that will save a lot of time.
                            [TimeFilterFile, TimeFilterPath] = uigetfile(fullfile(displacementFilePath,'*.mat'), ' open "displFieldLowPassFilterParameters.mat" file');  
                            TimeFilterFullFileName = fullfile(TimeFilterPath, TimeFilterFile);   
                            TimeFilterParameters = load(TimeFilterFullFileName);
                            TimeFilterChoiceStrName = 'Low-Pass Equipripples';
                        case 'No'
                            TimeFilterChoiceStrName = 'No Time Filter';
                        otherwise
                            error('X was selected');      
                    end
                end
            end
            
            %____________________ 0.3
            if ~exist('TractionForce', 'var') || ~exist('TractionForceX', 'var') || ~exist('TractionForceY', 'var') 
                TractionForceX = NaN(VeryLastFrame,1);
                TractionForceY = NaN(VeryLastFrame,1);
                TractionForce = NaN(VeryLastFrame,1);
            end

            if useGPU
                TractionForce = gpuArray(TractionForce);
                TractionForceX = gpuArray(TractionForceX);
                TractionForceY = gpuArray(TractionForceY);
            end
            
            if ~exist('intMethodStr', 'var'), intMethodStr = []; end
            if isempty(intMethodStr)
                dlgQuestion = ({'Do you want to integrated or sum the force Field?'});
                dlgTitle = 'Integration?';
                intMethodStr = questdlg(dlgQuestion, dlgTitle, 'Integrated: Tiled', 'Integrated: Iterated', 'Summed', 'Summed');
                switch intMethodStr
                    case 'Integrated: Tiled'
                        intMethod = 'tiled';
                    case 'Integrated: Iterated'
                        intMethod = 'iterated';
                    case 'Summed'
                        intMethod = 'summed';             
                    otherwise
                        error('X was selected'); 
                end
            end

            dlgQuestion = ({'File Format(s) for images?'});
            listStr = {'PNG', 'FIG', 'EPS'};
            PlotChoice = listdlg('ListString', listStr, 'PromptString',dlgQuestion, 'InitialValue', [1, 2], 'SelectionMode' ,'multiple');  
            if isempty(PlotChoice), error('X was selected'); end
            PlotChoice = listStr(PlotChoice);                 % get the names of the string. 
            
            %_________________ 0.4 Choose an analysis folder
            if ~exist('AnalysisPath', 'var'), AnalysisPath = []; end
            if ~exist('AnalysisPath', 'dir') || isempty(AnalysisPath)
                fprintf('Analysis folder does not exist or not selected: \n\t%s \n\tChoose an analysis path!\n ', AnalysisPath);
                AnalysisPath = uigetdir(displacementFilePath, 'Choosing Analysis Path for traction force/analysis output');
                if AnalysisPath == 0, error('No path was selected'); end                       % Cancel was chosen
            else
               tractionForcePathChoice = questdlg(sprintf('Do you want to use this path to store traction force/analysis output? \n\t %s', AnalysisPath), 'Traction Force Path?','Yes', 'No', 'Yes'); 
               switch tractionForcePathChoice
                   case 'Yes'
                       % continue. Do nothing here
                   case 'No'
                       AnalysisPath = uigetdir(displacementFilePath, 'Choosing path for traction force/analysis output');
                       if AnalysisPath == 0, error('No analysis path was chosen'); end                       % Cancel was chosen
                   otherwise
                       error('No analysis path was selected'); 
               end                   
            end

            %_________________ 0.3 load forceFieldParameter.mat,
            if exist('forceFieldParametersFullFileName', 'var') && exist('forceFieldParameters', 'var')
                forceFieldParametersFileChoice = questdlg(sprintf('Do you want to use this force field parameteres file? \n\t %s', forceFieldParametersFullFileName), 'Force Field Parameters?','Yes', 'No', 'Yes'); 
            else
                forceFieldParametersFileChoice = 'No';
            end
            switch forceFieldParametersFileChoice
                case 'Yes'
                    % do nothing
                case 'No'
                    [forceFieldParametersFile, forceFieldParametersPath] = uigetfile(fullfile(fullfile(displacementFilePath, '..'), '*.mat'), ' open the forceFieldParameters.mat file');  
                    if forceFieldParametersPath == 0, error('No file was selected'); end                       % Cancel was chosen
                    forceFieldParametersFullFileName = fullfile(forceFieldParametersPath, forceFieldParametersFile);   
                    forceFieldProcessStruct = load(forceFieldParametersFullFileName);
                    try
                        forceFieldCalculationInfo = forceFieldProcessStruct.forceFieldProc;
                    catch
                        forceFieldCalculationInfo = '[NONE IDENTIFIED]';
                    end
                    fprintf('forceField paramters successfully: \n\t %s \n', forceFieldParametersFullFileName)
                    forceFieldParameters = forceFieldProcessStruct.forceFieldParameters;   
                    try
                        movieData = forceFieldProcessStruct.movieDataAfter;
                    catch
                        try
                            movieData = forceFieldProcessStruct.movieData;        
                        catch
                            [movieFileName, movieDir] = uigetfile('*.mat', 'Open the TFM-Package Movie Data File');
                            if movieFileName == 0, error('No Movie data file was selected'); end
                            MovieFileFullName = fullfile(movieDir, movieFileName);
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
            
             %--- Images Color depth
            try
                ImageBits = movieData.camBitdepth_ - 2;   % Typically if 16 bits are used. Then image will be saved in 14 bits.
            catch
                ImageBits = 14;
            end
            TxRedColorMap =  [linspace(0,1,2^ImageBits)', zeros(2^ImageBits,2)];                   % TexasRed ColorMap for Epi Images.
            
            ImageSizePixels = movieData.imSize_;
            
            %__________ choose the scale (microns/pixels)            
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
            %___________________
            
            %% 0.4 calculate edge values (Grid sizes is the same throughout the video).
            switch GridtypeChoiceStr
                case 'Even Grid'
                        [reg_grid,~,~,gridSpacing] = createRegGridFromDisplField(displField, gridMagnification, EdgeErode);
%                     end
                case 'Odd Grid'
                        [reg_grid,~,~,gridSpacing] = createRegGridFromDisplFieldOdd(displField, gridMagnification, EdgeErode);
%                     end     
                otherwise
                    return
            end
            % Edge Erode to make it a square grid        
            [pos_grid, disp_grid_NoFilter, i_max, j_max] = interp_vec2grid(displField(VeryFirstFrame).pos(:,1:2), displField(VeryFirstFrame).vec(:,1:2),[], reg_grid, InterpolationMethod);        
            % Initial 
            gridXmin = min(displField(VeryFirstFrame).pos(:,1));
            gridXmax = max(displField(VeryFirstFrame).pos(:,1));
            gridYmin = min(displField(VeryFirstFrame).pos(:,2));
            gridYmax = max(displField(VeryFirstFrame).pos(:,2));
            
            %%_________________ 3.1 Setting up plot variables -------------------------------------------------------------------------
            commandwindow;
            
            GelConcentrationMgMl = input('What was the gel concentration in mg/mL? '); 
            if isempty(GelConcentrationMgMl)
                GelConcentrationMgMlStr = 'N/A';
                GelConcentrationMgMl = NaN;
            else
                GelConcentrationMgMlStr = sprintf('%.1f', GelConcentrationMgMl);
            end
            fprintf('Gel Concentration Chosen is %s mg/mL. \n', GelConcentrationMgMlStr);
            
            try
                try
                    thickness_um = forceFieldCalculationInfo.funParams_.thickness_nm/1000;
                catch
                    thickness_um = forceFieldCalculationInfo.funParams_.thickness/1000;
                end
            catch
                thickness_um = [];
            end
            commandwindow;
            if isempty(thickness_um)
                commandwindow;
                thickness_um = input('What was the gel thickness in microns? ');
                fprintf('Gel thickness is %d  microns. \n', thickness_um);
            else
                thickness_um_input = input(sprintf('Do you want to use %g microns as the gel thickness?\n\t Press Enter to continue. Enter the value and enter otherwise: ',thickness_um));  
                if ~isempty(thickness_um_input), thickness_um = thickness_um_input; end
                fprintf('Gel thickness is %d  microns. \n', thickness_um);
            end
            %----------------------------------------------
            try
                YoungModulusPa = forceFieldCalculationInfo.funParams_.YoungModulus;
            catch
                YoungModulusPa = [];
            end
            commandwindow;
            if isempty(YoungModulusPa)
                YoungModulusPa = input('What was the gel''s Young Elastic modulus (in Pa)? ');  
                fprintf('Gel''s elastic modulus (E) is %g  Pa. \n', YoungModulusPa);
            else        
                YoungModulusPa_input = input(sprintf('Do you want to use %g Pa as the gel''s elastic modulus?\n\t Press Enter to continue. Enter the value and enter otherwise: ',YoungModulusPa));  
                if ~isempty(YoungModulusPa_input), YoungModulusPa = YoungModulusPa_input; end
                fprintf('Gel''s elastic modulus (E) is %d Pa. \n', YoungModulusPa);   
            end
        %----------------------------------------------
            try
                PoissonRatio = forceFieldCalculationInfo.funParams_.PoissonRatio;
            catch
                PoissonRatio = [];
            end
            commandwindow;
            if isempty(PoissonRatio)
                PoissonRatio = input('What was the gel''s Poisson Ratio (unitless)? ');  
                fprintf('Gel''s Poisson Ratio (nu) is %g. \n', PoissonRatio);
            else
                PoissonRatio_input = input(sprintf('Do you want to use %g as the gel''s Poisson Ratio (unitless)?\n\t Press Enter to continue. Enter the value and enter otherwise: ',PoissonRatio));  
                if ~isempty(PoissonRatio_input), PoissonRatio = PoissonRatio_input; end
                fprintf('Gel''s Poisson Ratio (nu) is %g. \n', PoissonRatio);       
            end

            %% 0.35 Set up default values for filters
            switch SpatialFilterChoiceStr
                case 'No-Filter'
                    filteringMethod = strjoin({SpatialFilterChoiceStr, 'Not Han-Windowed'}, ', ');    
                    HanWindowchoice = 'No';
                case  'Wiener 2D'
                    commandwindow;
                    if ~exist('windowSizeChoice', 'var'), windowSizeChoice = []; end
                    if isempty(windowSizeChoice)
                        windowSizeChoice = input('What is the length size (in pixels) for the square window in Wiener Filter [Default Size = 3 pix]? ');
                        if isempty(windowSizeChoice), windowSizeChoice = 3; end
                    end
                    windowSize = [windowSizeChoice, windowSizeChoice];
                    disp('=============================================================================')
                    fprintf('%s [%dx%d] pixels window.\n', SpatialFilterChoiceStr, windowSize)
                    filteringMethod = strjoin({SpatialFilterChoiceStr, strcat(num2str(windowSize(1)), 'by', num2str(windowSize(2)), ' pix')}, ', ');
                    % 2.2 Han Windows
                    if ~exist('HanWindowchoice', 'var'), HanWindowchoice = []; end
                    if isempty(HanWindowchoice)
                        HanWindowchoice = questdlg('Do you want to add a Han Window?', 'Han Window?', 'Yes', 'No', 'Yes');
                    end
                    switch HanWindowchoice
                        case 'Yes'
                            filteringMethod = strjoin({filteringMethod,'Han-Windowed'}, ', ');
                            HanWindowBoolean = true;
                        case 'No'
                            filteringMethod = strjoin({filteringMethod, 'Not Han-Windowed'}, ', ');                    
                            HanWindowBoolean = false;
                            % Continue
                        otherwise
                            return
                    end     

                case 'Low-Pass Exponential 2D' 
                    HanWindowchoice = 'Yes';
                    commandwindow;
                    fracPadDefault = 0.5; 
                    fracPad = input(sprintf('What is the fraction of view to pad on either side? [Default = %g]: ', fracPadDefault));
                    if isempty(fracPad)
                        fracPad = fracPadDefault;
                    end
                    fprintf('fraction of field of view to pad displacements on either side of current fov + extrapolated to get high k contributions to Q: %g \n', fracPad);            

                    min_feature_sizeDefault = 1;
                    min_feature_size = input(sprintf('What is the minimum feature size in tracking code in pixels? [Default = %g pixels]: ', min_feature_sizeDefault));
                    if isempty(min_feature_size)
                        min_feature_size = min_feature_sizeDefault;
                    end            
                    fprintf('Minimum feature selected is: %g pixels. \n', min_feature_size);

                    ExponentOrderDefault = 2;
                    ExponentOrder = input(sprintf('What is the order of the Gaussian exponential filter? [Default = %g]: ', ExponentOrderDefault));
                    if isempty(ExponentOrder)
                        ExponentOrder = ExponentOrderDefault;
                    end            
                    fprintf('Gaussian Exponential Order is: %g. \n', ExponentOrder);
                
                case 'Low-Pass Butterworth'
                    HanWindowchoice = 'Yes';
                    fracPadDefault = 0.5; 
                    fracPad = input(sprintf('What is the fraction of view to pad on either side? [Default = %g]: ', fracPadDefault));
                    if isempty(fracPad)
                        fracPad = fracPadDefault;
                    end
                    fprintf('fraction of field of view to pad displacements on either side of current fov+extrapolated to get high k contributions to Q: %g \n', fracPad);            

                    BW_orderDefault = 3;
                        BW_order = input(sprintf('What is the order of the Butterworth filter? [Default = %g]: ', BW_orderDefault));
                    if isempty(BW_order)
                        BW_order = BW_orderDefault;
                    end
                    fprintf('Butterworth filter order is %g.\n', BW_order);
                otherwise
                    return
            end    
            
            %% 0.7 Load position and displacement vectors for current frame (FrameNum)
            %CorrectDisplacementMeanDrift subtract the mean displacement from a window 
            %   Detailed explanation goes here
            displFieldNetMaxPointInFrame = zeros(numel(FramesDoneNumbers),1);
            for CurrentFrame = FramesDoneNumbers
                NetdisplFieldAllPointsInFrame = vecnorm(displField(CurrentFrame).vec,2,2);
                [tmpMaxDisplFieldNetInFrame,tmpMaxDisplFieldInFrameIndex] =  max(NetdisplFieldAllPointsInFrame);          % maximum item in a column

                if tmpMaxDisplFieldNetInFrame > displFieldNetMaxPointInFrame
                    displFieldNetMaxPointInFrame(CurrentFrame) = tmpMaxDisplFieldNetInFrame;
                    displFieldMaxPosFrame = displField(CurrentFrame).pos; 
                    displFieldMaxVecFrame = displField(CurrentFrame).vec;
                    MaxDisplFieldIndex = tmpMaxDisplFieldInFrameIndex;
                    FrameNumberMaxDisplacement = CurrentFrame;
                end 
            end            
            displFieldPos = displField(FrameNumberMaxDisplacement).pos;
            displFieldVecNotDriftCorrected = displField(FrameNumberMaxDisplacement).vec;
            displFieldVecNotDriftCorrected(:,3) = vecnorm(displFieldVecNotDriftCorrected(:,1:2), 2, 2);            

            clear displFieldVecMean corner_noise displFieldVecDriftCorrected
            
        %% 0.6 --- Load EPI image and adjust contrast
            try
                curr_Image = movieData.channels_.loadImage(FrameNumberMaxDisplacement);
                if useGPU, curr_Image = gpuArray(curr_Image); end
                curr_ImageAdjust = imadjust(curr_Image, stretchlim(curr_Image,[0.05,0.999]));       % Make beads contrast more
            catch
                BioformatsPath = uigetdir([], 'Select directory containing bioformats folder (e.g., TFMpackagefolder)');
                addpath(genpath(BioformatsPath));        % include subfolders
                curr_Image = movieData.channels_.loadImage(FrameNumberMaxDisplacement);
                curr_ImageAdjust = imadjust(curr_Image, stretchlim(curr_Image,[0.05,0.999]));       % make beads contrast more.
            end 

            %% Select the windows for the noise.
            figHandle = figure('color', 'w', 'Renderer', 'Painters');
            axes
            figAxesHandle = findobj(figHandle, 'type', 'Axes');
            colormap(TxRedColorMap);
            imagesc(figAxesHandle, 1, 1, curr_ImageAdjust);
            truesize(figHandle);
            hold on
            quiver(figAxesHandle, displFieldPos(:,1), displFieldPos(:,2), displFieldVecNotDriftCorrected(:,1), displFieldVecNotDriftCorrected(:,2), 'y.', 'ShowArrowHead', 'on', ...
                'LineWidth',  0.5)
            set(figAxesHandle,'LineWidth',1, 'XTick', [], 'YTick', [], 'Box', 'off')    
%             xlabel('\itX \rm[pixels]'), ylabel('\itY \rm[pixels]')
            axis image

            switch DCchoice
                case 'Yes'
                    figHandle.Visible = 'on';
                    %**** CONSIDER SAVING THE IMAGE **** %
                    DriftROIs(1).pos = [];
                    DriftROIs(1).vec = [];
                    DriftROIs(1).mean = [];
                    clear indata
                    indata(1).Index = [];

                    cornerCount = 4;
                    clear rect rectHandle rectCorners xx yy nxx corner_noise

                    if ~exist('IdenticalCornersChoice', 'var'), IdenticalCornersChoice = []; end
                    if isempty(IdenticalCornersChoice)
                        dlgQuestion = ({'Do want identical four rectangular corners for noise adjustment?'});
                        dlgTitle = 'Identical Four Corners??';
                        IdenticalCornersChoice = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No', 'Yes');
                    end

                    switch IdenticalCornersChoice
                        case 'No'
                            for ii = 1:cornerCount                    % four corners
                    %             [xx,yy] = getline('closed');
                                titleStr1 = sprintf('Select ROI **%d/%d**', ii, cornerCount);
                                title({titleStr1, 'ROI Position: _____', 'Double-Click on Last ROI when finished with adjusting all ROIs'})
                    %             rect(ii,:) = getrect(figAxesHandle);
                                rectHandle(ii) = imrect(figAxesHandle);
                                addNewPositionCallback(rectHandle(ii),@(p) title({titleStr1, strcat('ROI Position [X,Y,W,H]=', char(32), mat2str(p,3), char(32), 'pixels'), 'Double-Click on Last ROI when finished with adjusting all ROIs'})); 
                                ConstraintFunction = makeConstrainToRectFcn('imrect',get(figAxesHandle,'XLim'),get(figAxesHandle,'YLim'));
                            end        
                            wait(rectHandle(cornerCount));
                    %         waitfor(figHandle)
                            for ii = 1:cornerCount
                                fprintf('Coordinates Extracted for ROI %d/%d\n', ii, cornerCount);
                                rect(ii,:) = rectHandle(ii).getPosition;
                            end
                        case 'Yes'                    
                            commandwindow;
                            if ~exist('CornerPercentage', 'var'), CornerPercentage = []; end
                            if isempty(CornerPercentage)
                                inputStr = sprintf('Choose the percentage of the images size to use for noise adjustment [Default = %0.2g%%]: ', CornerPercentageDefault * 100);
                                CornerPercentage = input(inputStr);
                                if isempty(CornerPercentage)
                                   CornerPercentage =  CornerPercentageDefault; 
                                else
                                   CornerPercentage = CornerPercentage / 100;
                                end
                            end
                            cornerLengthPix_X = round(CornerPercentage * (gridXmax - gridXmin));
                            cornerLengthPix_Y = round(CornerPercentage * (gridYmax - gridYmin));

                            rect(1,:) = [gridXmin, gridYmin, cornerLengthPix_X, cornerLengthPix_Y];                                             % Top-Left Corner: ROI 1:
                            rect(2,:) = [gridXmin, gridYmax - cornerLengthPix_Y, cornerLengthPix_X, cornerLengthPix_Y];                         % Bottom-Left Corner: ROI 1:
                            rect(3,:) = [gridXmax - cornerLengthPix_X, gridYmin, cornerLengthPix_X, cornerLengthPix_Y];                         % Top-Right Corner: ROI 1:
                            rect(4,:) = [gridXmax - cornerLengthPix_X, gridYmax - cornerLengthPix_Y, cornerLengthPix_X, cornerLengthPix_Y];     % Bottom-Right Corner: ROI 1:           
                            for jj = 1:cornerCount
                               rectHandle(jj) = drawrectangle(figAxesHandle,'Position', rect(jj, :), 'Color', 'g', 'FaceAlpha', 0);             % make it fully transparent
                            end
                            pause(0.1)              % pause to allow it to draw the rectangles.
                            title(figAxesHandle, 'ROIs to adjust for noise');
                        otherwise
                            return;
                    end            
                    for ii = 1:cornerCount
                        rectCorners = [rect(ii, 1:2); rect(ii, 1:2) + [rect(ii, 3), 0]; rect(ii, 1:2) + [0, rect(ii, 4)]; rect(ii, 1:2) + rect(ii, 3:4)];
                        xx(ii,:) = rectCorners(:,1)';
                        yy(ii,:) = rectCorners(:,2)';
                        if isempty(xx(ii,:)) || isempty(yy(ii,:))
                            errordlg('The selected noise is empty.','Error');
                            return;
                        end
                        nxx(ii, :) = size(xx(ii));
                        if isempty(xx(ii)) || nxx(ii,1)==2
                            errordlg('Noise does not select','Error');
                            return;
                        end
                        indata(ii).Index = inpolygon(displFieldPos(:,1),displFieldPos(:,2),xx(ii,:),yy(ii,:));
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
                    fprintf('There are %d tracked points: [TL, BL, TR, BR] = [%d,%d,%d, %d] points each in Frame %d/%d. \n', size(DriftROIsCombined.pos, 1), ...
                        size(DriftROIs(1).pos, 1), size(DriftROIs(2).pos, 1), size(DriftROIs(3).pos, 1), size(DriftROIs(4).pos, 1), FrameNumberMaxDisplacement,FramesDoneNumbers(end));

                    DriftROIsCombined.mean = mean(DriftROIsCombined.vec, 'omitnan');
                    DriftROIsCombined.mean(:,3) = vecnorm(DriftROIsCombined.mean(1:2), 2, 2);

                    displFieldVecDriftCorrected(:,1:2) = displFieldVecNotDriftCorrected(:,1:2) - DriftROIsCombined.mean(:,1:2);
                    displFieldVecDriftCorrected(:,3) = vecnorm(displFieldVecDriftCorrected(:,1:2), 2, 2); 

                    displFieldVec = displFieldVecDriftCorrected;
                    title(figAxesHandle, sprintf('%0.2g%% %d Corners ROIs. Frame %d/%d.', CornerPercentageDefault * 100, cornerCount, ...
                FrameNumberMaxDisplacement,FramesDoneNumbers(end)));   
                case 'No'
                    figHandle.Visible = 'off';
                    CornerPercentage = 0.10;
                    displFieldVec = displFieldVecNotDriftCorrected;
                    title(figAxesHandle, sprintf('Frame %d/%d.', FrameNumberMaxDisplacement,FramesDoneNumbers(end))); 
            end
%         case 'Yes'
%             % continue
%         otherwise
%             return
%     end    
%    
    
    %_______ This line masks the displacement field at the center before feeding it to the FTTC code.
    if ~exist('CentralROIChoice', 'var'), CentralROIChoice = []; end
    if isempty(CentralROIChoice)
        dlgQuestion = ({'Do want choose a central ROI?'});
        dlgTitle = 'Center ROI??';
        CentralROIChoice = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No', 'No');
        if isempty(CentralROIChoice), return; end
    else
        % Continue
    end
    
    switch CentralROIChoice
        case 'Yes'
            try figHandle.Visible = 'on'; catch, end
            if ~exist('figHandle', 'var')
                try
                    curr_Image = movieData.channels_.loadImage(FrameNumberMaxDisplacement);
                    if useGPU, curr_Image = gpuArray(curr_Image); end
                    curr_ImageAdjust = imadjust(curr_Image, stretchlim(curr_Image,[0.05,0.999]));       % Make beads contrast more
                catch
                    BioformatsPath = uigetdir([], 'Select directory containing bioformats folder (e.g., TFMpackagefolder)');
                    addpath(genpath(BioformatsPath));        % include subfolders
                    curr_Image = movieData.channels_.loadImage(FrameNumberMaxDisplacement);
                    curr_ImageAdjust = imadjust(curr_Image, stretchlim(curr_Image,[0.05,0.999]));       % make beads contrast more.
                end
                % Select the windows for the noise.
                figHandle = figure('color', 'w', 'Renderer', 'painters');
                figAxesHandle = gca;
                colormap(TxRedColorMap);
                imagesc(figAxesHandle, 1, 1, curr_ImageAdjust);
                truesize(figHandle);
                hold on
                quiver(figAxesHandle, displFieldPos(:,1), displFieldPos(:,2), displFieldVecNotDriftCorrected(:,1), displFieldVecNotDriftCorrected(:,2), 'y.', 'ShowArrowHead', 'on', ...
                    'LineWidth',  0.5)
                set(figAxesHandle, 'FontWeight', 'bold','LineWidth',1, 'XMinorTick', 'off', 'YMinorTick', 'off', 'TickDir', 'out', 'Box', 'on')    
                xlabel('\itX \rm[pixels]'), ylabel('\itY \rm[pixels]')
                axis image
            end

            clear rectHandle
            titleStr1 = sprintf('Select Center ROI');
            title({titleStr1, 'ROI Position: _____', 'Double-Click on Last ROI when finished with adjusting all ROIs'})
            RectCenterHandle = imrect(figAxesHandle);
            addNewPositionCallback(RectCenterHandle,@(p) title({titleStr1, strcat('ROI Position [X,Y,W,H]=', char(32), mat2str(p,3), char(32), 'pixels'), 'Double-Click when finished with adjusting'})); 
            ConstraintFunction = makeConstrainToRectFcn('imrect',get(figAxesHandle,'XLim'),get(figAxesHandle,'YLim'));
            wait(RectCenterHandle)
            rectCenter = RectCenterHandle.getPosition;
            fprintf('Coordinates Extracted for Center ROI is [X,Y,W,H] = [%.0f,%.0f,%.0f,%.0f] \n', rectCenter );

            rectCenterCorners = [rectCenter( 1:2); rectCenter( 1:2) + [rectCenter( 3), 0]; rectCenter( 1:2) + [0, rectCenter( 4)]; rectCenter( 1:2) + rectCenter( 3:4)];
            xxCenter = rectCenterCorners(:,1)';
            yyCenter = rectCenterCorners(:,2)';
            if isempty(xxCenter) || isempty(yyCenter)
                errordlg('The selected noise is empty.','Error');
                return;
            end
            nxxCenter = size(xxCenter);
            if isempty(nxxCenter) || xxCenter ==2
                errordlg('Noise does not select','Error');
                return;
            end
            indataCenter.Index = inpolygon(displFieldPos(:,1),displFieldPos(:,2),xxCenter,yyCenter);
            DriftROIsCenter.pos = displFieldPos(indataCenter.Index , :);
            DriftROIsCenter.vec = displFieldVecNotDriftCorrected(indataCenter.Index ,:);
            % DriftROIsCenter.mean = mean(DriftROIsCenter.vec, 'omitnan'); 
            % DriftROIsCenter.mean(:,3) = vecnorm(DriftROIsCenter.mean );
            displFieldVecNotDriftCorrectedCenter = displFieldVecNotDriftCorrected(indataCenter.Index, :);
            displFieldVecDriftCorrectedCenter = displFieldVecNotDriftCorrectedCenter(:,1:2) - DriftROIsCombined.mean(:,1:2);
            displFieldPosCenter = displFieldPos(indataCenter.Index, :);
        case 'No'
            % continue
        otherwise
            % continue
    end
    
    %______________ Insert a scale bar ________________________
    figure(figHandle)
    ScaleBarChoice = questdlg({'Do you want to insert a scalebar?','If yes, choose the right-edge position'}, 'ScaleBar Position?', 'Yes', 'No', 'Yes');
    if strcmpi(ScaleBarChoice, 'Yes')
        ScaleBarNotOK = true;
        while ScaleBarNotOK
            ScaleBarUnits = sprintf('%sm', char(181));         % in Microns
            figure(figHandle)
            [Location(1), Location(2)] = ginputc(1, 'Color', QuiverColor);
            prompt = sprintf('Scale Bar Length [%s]:', ScaleBarUnits);
            dlgTitle = 'Scale Bar Length?';
            dims = [1 40];
            defInput = {num2str(round((round((gridXmax*ScaleMicronPerPixel* CornerPercentage)/10) * 10)))};          % ideal scale length. CornerPercentage is 10%    
            opts.Interpreter = 'tex';
            ScaleLengthStr = inputdlg(prompt, dlgTitle, dims, defInput, opts);
            ScaleLength = str2double(ScaleLengthStr{:});
            ScaleBarColor = uisetcolor(QuiverColor, 'Select the ScaleBar Color');   % [1,1,0] is the RGB for yellow        
            scalebar(figAxesHandle,'ScaleLength', ScaleLength, 'ScaleLengthRatio', ScaleMicronPerPixel, 'color', ScaleBarColor, ...
                'bold', true, 'unit', sprintf('%sm', char(181)), 'location', Location)                 % Modified by WIM
            IsScaleBarOK = questdlg('Is the scale bar length & color looking OK?', 'Scalebar Length/Color OK?', 'Yes', 'No', 'Yes');
            switch IsScaleBarOK
                case 'Yes'
                    ScaleBarNotOK = false;
                case 'No'
                    disp('**___to continue, type "dbcont" or press "F5", or click "Continue" under "Editor" Menu___**')
                    keyboard
            end
        end
    end
    %__________________________________________________________
        
        %% Saving Plots
    disp('**___to continue, type "dbcont" or press "F5", or click "Continue" under "Editor" Menu___**')
    keyboard
    
    %%
    if strcmp(DCchoice, 'Yes') || strcmpi(CentralROIChoice', 'Yes')
        try
            [DisplFilePath, DisplFileName, DisplFileExt] = fileparts(DisplacementFileFullName);
            displacementFileNameFiltered = sprintf('%s_DC%s', DisplFileName, DisplFileExt); 
            DisplFieldPathsUp = strsplit(DisplFilePath, filesep);
            displacementFilePathFiltered =  fullfile( fullfile(DisplFilePath, '..'), strcat(DisplFieldPathsUp{end}, '_DC'));       % _Low-Pass Equiripples Filter (Equiripples) Drift-Corrected
        catch
            displacementFilePathFiltered = uigetdir('Select Path for DC-corrected displacement fields');
            % continue
        end
        if exist('displacementFilePathFiltered', 'var')
            if ~exist(displacementFilePathFiltered, 'dir'), mkdir(displacementFilePathFiltered); end            
            displFieldBeadsUnfiltered = displField;
        end
        
        for CurrentPlotType = 1:numel(PlotChoice)
            tmpPlotChoice =  PlotChoice{CurrentPlotType};
            switch tmpPlotChoice
                case 'FIG'
                    savefig(figHandle, fullfile(AnalysisPath, 'Displacement Drift ROIs EPI.fig'), 'compact')     
                case 'PNG'
                    saveas(figHandle, fullfile(AnalysisPath, 'Displacement Drift ROIs EPI.png'), 'png')       
                case 'EPS'
    %                 print(figHandle, fullfile(AnalysisPath, 'Displacement Drift ROIs EPI.eps'),'-depsc')
                    exportfig(figHandle,  fullfile(AnalysisPath, 'Displacement Drift ROIs EPI.eps'), EPSparams)
            end
        end            
    end
    close(figHandle)

%% 1. Beginning of the for loop
    clear displFieldVecMean  displFieldVecDriftCorrected
    clear pos_grid disp_grid_NoFilter corner_noise_combined
    displField(1).vecCorrected = [];
    switch FrameDisplMeanChoice
        case 'Yes'
            displField(1).vecCorrectedMean = [];
        case 'No'
            % continue
        otherwise
            return
    end

%% 2 Ask for Frame number
    switch controlMode
        case 'Controlled Force'
            dlgQuestion = ({'Which timestamps do you want to use)?'});
            dlgTitle = 'Real-Time vs. Camera-Time vs. from FPS rate?';
            TimeStampChoice = questdlg(dlgQuestion, dlgTitle, 'Real-Time', 'Camera-Time', 'From FPS rate', 'Real-Time');
            if isempty(TimeStampChoice), error('No Choice was made'); end
        case 'Controlled Displacement'
            TimeStampChoice =  'Camera-Time';
    end
    try
        movieDir = movieData.outputDirectory_;
    catch
        movieDir = pwd;
    end
                
    switch TimeStampChoice
        case 'Real-Time'
            try 
                [TimeStampFileNameEPI, TimeStampPathEPI] = uigetfile(movieDir, 'EPI TimeStamps RT Sec');
                if isempty(TimeStampFileNameEPI), error('No File Was chosen'); end
                TimeStampFullFileNameEPI = fullfile(TimeStampPathEPI, TimeStampFileNameEPI);
                TimeStampsRT_SecData = load(TimeStampFullFileNameEPI);
                TimeStamps = TimeStampsRT_SecData.TimeStampsAbsoluteRT_Sec;
                FrameRate = 1/mean(diff(TimeStampsRT_SecData.TimeStampsRelativeRT_Sec));
            catch                        
                [TimeStamps, ~, ~, ~, AverageFrameRate] = TimestampRTfromSensorData();
                FrameRate = 1/AverageFrameRate;
            end
            xLabelTime = 'Real Time [s]';
                    
        case 'Camera-Time'
            try 
                [TimeStampFileNameEPI, TimeStampPathEPI] = uigetfile(movieDir, 'EPI TimeStamps ND2 Sec');
                if isempty(TimeStampFileNameEPI), error('No File Was chosen'); end
                TimeStampFullFileNameEPI = fullfile(TimeStampPathEPI, TimeStampFileNameEPI);
                TimeStampsND2_SecData = load(TimeStampFullFileNameEPI);
                TimeStamps = TimeStampsND2_SecData.TimeStampsND2;
                FrameRate = 1/TimeStampsND2_SecData.AverageTimeInterval;
            catch          
                try
                    [TimeStamps, ~, AverageTimeInterval] = ND2TimeFrameExtract(movieData.channels_.channelPath_);
                catch
                    [TimeStamps, ~, AverageTimeInterval] = ND2TimeFrameExtract();            
                end
                FrameRate = 1/AverageTimeInterval;
            end
            xLabelTime = 'Camera Time [s]';
                
        case 'From FPS rate'
            try 
                FrameRateDefault = 1/MD.timeInterval_;
            catch
                FrameRateDefault = 1/ 0.025;           % (40 frames per seconds)              
            end

            prompt = {sprintf('Choose the Frame Rate per second for this movie. [Default, %.4g]', FrameRateDefault)};
            dlgTitle =  'Frames Per Second';
            FrameRateStr = inputdlg(prompt, dlgTitle, [1, 90], {num2str(FrameRateDefault)});
            if isempty(FrameRateStr), error('No Frame Rate was chosen'); end
            FrameRate = str2double(FrameRateStr{1});      
            
            TimeStamps = FramesDoneNumbers ./ FrameRate;
            xLabelTime = 'Time based on frame rate [s]';
    end

    if ~exist('TimeStamps', 'var')
        TimeStamps = (VeryFirstFrame:VeryLastFrame)' ./ FrameRate;
        TimeStamps = TimeStamps - TimeStamps(1);                                    % MAKE THE FIRST FRAME IDENTICALLY ZERO 2020-01-28
    end
        
    % =====================================
    prompt = {sprintf('Choose the Frame Rate per second for this movie. [Default, %.4f]', FrameRate)};
    dlgTitle =  'Frames Per Second';
    FrameRateStr = inputdlg(prompt, dlgTitle, [1, 90], {num2str(FrameRate)});
    if isempty(FrameRateStr), return; end
    FrameRate = str2double(FrameRateStr{1});                                  % Convert to a number                                     
    
    LastFrame = FramesDoneNumbers(end);
    FrameNumInput = input(sprintf('Enter the Frame Number to be analyzed (Frame Rate = %0.2g fps).\n\t The nearest tracked frame will be chosen (Last Frame = %d): ',FrameRate, LastFrame));
    if ~isempty(FrameNumInput)
        [~,FrameNumIndex] = (min(abs(FramesDoneNumbers - FrameNumInput)));
        FrameNumToBePlotted = FramesDoneNumbers(FrameNumIndex);
        fprintf('Frame to be plotted is: %d/%d.\n', FrameNumToBePlotted, LastFrame)
    else
        FrameNumToBePlotted = [];
    end   
    TractionForceMean = [];
    indata = [];
    
    switch DCchoice
        case 'Yes'
            DriftROIs = [];
            pValTtest = [];
            pValANOVA = [];
    
            % for combinations difference. out of the loop so that it would not be evaluated all the time
            DriftROIsMeanDiffCombinations = nchoosek(1:cornerCount,2);           % choose two out of all the corners at a time. Do not replace.
            DriftROIsMeanDiffCount = size(DriftROIsMeanDiffCombinations, 1);
            clear DriftROIsMeanDispAllCorners
    end
    
%% Starting the loop to adjust displacement (drift-correction, spatial filtering), calculate stress field, and traction force (summation).
    clear pos_gridLcurve disp_grid_NoFilter disp_gridHan
    for CurrentFrame = FramesDoneNumbers
        if ShowOutput
            disp('=================================================================');
            fprintf('Starting Frame %d/%d. \n', CurrentFrame, VeryLastFrame);
        end    

        %% 1.0 Load position and displacement vectors for current frame (CurrentFrame)    
        displFieldPos = displField(CurrentFrame).pos;
        displFieldVecNotDriftCorrected = displField(CurrentFrame).vec;
        displFieldVecNotDriftCorrected(:,3) = vecnorm(displFieldVecNotDriftCorrected(:,1:2), 2, 2); 
        
        switch DCchoice
            case 'Yes'        
                for ii = 1:cornerCount
                    indata(CurrentFrame, ii).Index = inpolygon(displFieldPos(:,1),displFieldPos(:,2),xx(ii,:),yy(ii,:));
                    DriftROIs(CurrentFrame, ii).pos = displFieldPos(indata(CurrentFrame, ii).Index , :);
                    DriftROIs(CurrentFrame, ii).vec = displFieldVecNotDriftCorrected(indata(CurrentFrame, ii).Index ,:);
                    DriftROIs(CurrentFrame, ii).mean = mean(DriftROIs(CurrentFrame, ii).vec, 'omitnan'); 
                    DriftROIs(CurrentFrame, ii).vec(:,3) = vecnorm(DriftROIs(CurrentFrame, ii).vec, 2, 2);
                    DriftROIsMeanDispAllCorners(CurrentFrame, ii) = DriftROIs(CurrentFrame, ii).mean(:,3);
                end
        %         _________________________________________________________________________________________________________________________
                SignificantDisplacementPixel = SignificantDisplacementMicron / ScaleMicronPerPixel;

                % conduct a statistical to see if there the net drift on the right side is equal to the left side
                LeftSide = [];
                LeftSide(CurrentFrame, :) = [DriftROIs(CurrentFrame,1).vec(:,3); DriftROIs(CurrentFrame,2).vec(:,3)];
                LeftSideMean(CurrentFrame, :) = mean(LeftSide(CurrentFrame, :), 'omitnan');
                RightSide = [];
                RightSide(CurrentFrame, :) = [DriftROIs(CurrentFrame,3).vec(:,3); DriftROIs(CurrentFrame,4).vec(:,3)];
                RightSideMean(CurrentFrame, :) = mean(RightSide(CurrentFrame,:), 'omitnan');
                SidesMeanDiffPix = [];
                SidesMeanDiffPix = RightSideMean(CurrentFrame) - LeftSideMean(CurrentFrame);
                SidesMeanDiffMicron(CurrentFrame, :)  = SidesMeanDiffPix * ScaleMicronPerPixel;

                [~, pValTtest(CurrentFrame), ci, ~] = ttest2(LeftSide(CurrentFrame, :), RightSide(CurrentFrame, :),'Vartype', 'unequal', 'Alpha', SigLevel, 'Tail', 'both');       % T-test for right vs. left mean
%                 if pValTtest(CurrentFrame) < SigLevel && abs(SidesMeanDiffPix) > SignificantDisplacementPixel    % statistically and practically significant difference.
%                    fprintf('Difference is REJECTED, BUT > %0.3g microns!!! \n\t(Mean Difference Left = %0.3g pixels) - (Right Side Drift %0.3g microns) is statistically significant.\n\t(p-value = %0.3g).\n', ...
%                        SignificantDisplacementMicron, SidesMeanDiffPix, SidesMeanDiffMicron, pValTtest(CurrentFrame));
%                 elseif pValTtest(CurrentFrame) < SigLevel && abs(SidesMeanDiffPix) < SignificantDisplacementPixel
%                    fprintf('Difference is REJECTED, BUT < %0.3g microns!!! \n\t(Mean Difference Left = %0.3g pixels) - (Right Side Drift %0.3g microns) is statistically significant.\n\t (p-value = %0.3g).\n', ...
%                        SignificantDisplacementMicron, SidesMeanDiffPix, SidesMeanDiffMicron, pValTtest(CurrentFrame));
%                 else
%                    fprintf('Difference is POSSIBLE and > %0.3g microns!!! \n\t(Mean Difference Left = %0.3g pixels) - (Right Side Drift %0.3g microns) is statistically significant.\n\t (p-value = %0.3g).\n', ...
%                        SignificantDisplacementMicron, SidesMeanDiffPix, SidesMeanDiffMicron, pValTtest(CurrentFrame));
%                 end
                TL = repmat('1', size(DriftROIs(CurrentFrame,1).vec(:,3)));                 % Top-Low (TL)
                BL= repmat('2', size(DriftROIs(CurrentFrame,2).vec(:,3)));                  % Below-Low (BL)
                TR= repmat('3', size(DriftROIs(CurrentFrame,3).vec(:,3)));                     % Top-Right (TR)
                BR= repmat('4', size(DriftROIs(CurrentFrame,4).vec(:,3)));                  % Bottom-Right (BR)

                DriftROIsGroupsLetters = TL;
                for ii = 1:numel(BL), DriftROIsGroupsLetters(end+1) = BL(ii); end
                for ii = 1:numel(TR), DriftROIsGroupsLetters(end+1) = TR(ii); end
                for ii = 1:numel(BR), DriftROIsGroupsLetters(end+1) = BR(ii); end

                DriftROIsNetVec = [DriftROIs(CurrentFrame,1).vec(:,3); DriftROIs(CurrentFrame,2).vec(:,3); DriftROIs(CurrentFrame,3).vec(:,3); DriftROIs(CurrentFrame,4).vec(:,3)];
                [pValANOVA(CurrentFrame), tbl, stats] = anova1(DriftROIsNetVec, DriftROIsGroupsLetters, 'off');        
%                 [c, m, h, gnames] = multcompare(stats, 'Alpha', SigLevel, 'Display', 'off');
%                 _________________________________________________________________________________________________________________________
% 
%                         % Mean Differences between ROIs Group Numbers: 1  = TL - BL (or 1 - 2), 2 = TL - TR (or 1 -3), 3 = TL - BR (or 1 - 4), 4 = BL - TR (or 2 - 3), 5 = BL - BR (or 2 - 4), 6 = BR - TR (or 3 - 4)
%                 % Easier method is to let matlab do it it
%                 clear DriftROIsDiff
%                 for jj = 1:DriftROIsMeanDiffCount
%                     DriftROIsDiff{CurrentFrame, jj} = DriftROIs(CurrentFrame,DriftROIs(1).vec(:,3) - DriftROIsMeanDiffCombinations(2)).vec(:,3);
%                 end        

            %% 1.1 Drift Correct the displacement based on the window chosen previously.
                DriftROIsCombined.pos = [];
                DriftROIsCombined.vec = [];
                DriftROIsCombined.mean = [];
                displFieldVecCorrectedMean = [];
% 
%                 for jj = 1:cornerCount
%                     DriftROIs(CurrentFrame,jj).pos = displFieldPos(indata(jj).Index, :);
%                     DriftROIs(CurrentFrame,jj).vec = displFieldVecNotDriftCorrected(indata(jj).Index,:);
%                     DriftROIs(CurrentFrame,jj).mean = mean(DriftROIs(CurrentFrame,jj).vec, 'omitnan'); 
%                 end
                for jj = 1:cornerCount
                    DriftROIsCombined.pos = [DriftROIsCombined.pos; DriftROIs(CurrentFrame,jj).pos];
                    DriftROIsCombined.vec = [DriftROIsCombined.vec; DriftROIs(CurrentFrame,jj).vec];
                end

                DriftROIsCombined.mean = mean(DriftROIsCombined.vec, 'omitnan');
                DriftROIsCombined.mean(:,3) = vecnorm(DriftROIsCombined.mean(1:2), 2, 2);

                displFieldVecDriftCorrected = [];
                displFieldVecDriftCorrected(:,1:2) = displFieldVecNotDriftCorrected(:,1:2) - DriftROIsCombined.mean(:,1:2);
                displFieldVecDriftCorrected(:,3) = vecnorm(displFieldVecDriftCorrected(:,1:2), 2, 2); 

                DCchoiceStr = 'Drift-Corrected';
                displFieldVec = displFieldVecDriftCorrected;
            case 'No'
                DCchoiceStr = 'Drift-Uncorrected';
                displFieldVec = displFieldVecNotDriftCorrected;
        end
        displFieldBeadsDriftCorrected(CurrentFrame).pos = displFieldPos;
        displFieldBeadsDriftCorrected(CurrentFrame).vec = displFieldVec;
        
        switch FrameDisplMeanChoice
            case 'Yes'
                displFieldVecMean = mean(displFieldVec, 'omitnan');
                displFieldVecMean(:,3) = vecnorm(displFieldVecMean(:,1:2), 2, 2);
                displFieldBeadsDriftCorrected(CurrentFrame).vecCorrectedMean = displFieldVecMean;
        end

        %% 1.2 Choose Drift-Correction Type (if any) & Choose filter type. Choose even or odd number of grid.        
        [pos_grid, disp_grid_NoFilter, i_max,j_max] = interp_vec2grid(displFieldBeadsDriftCorrected(CurrentFrame).pos(:,1:2), displFieldBeadsDriftCorrected(CurrentFrame).vec(:,1:2),[], reg_grid, InterpolationMethod);
        disp_grid_NoFilter(:,:,3) = sqrt(disp_grid_NoFilter(:,:,1).^2 + disp_grid_NoFilter(:,:,2).^2);       % Third column is the net displacement in grid form

        %% 1.3 Padding the Array with random edge displacement readings and 0's    
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
        [i_max,j_max, ~] = size(disp_grid_NoFilter);
               
      %% 1.5 Filtering the displacement field  
        clear disp_grid stress_grid pos_grid_stress
        filteringMethod = strjoin({DCchoiceStr, TimeFilterChoiceStrName}, ', ');
        switch SpatialFilterChoiceStr
            case 'No-Filter'
                disp_grid = disp_grid_NoFilter;
                filteringMethod = strjoin({filteringMethod , SpatialFilterChoiceStr, 'Not Han-Windowed'} , ', ');
                disp_gridHan = disp_grid;
            case 'Wiener 2D'
                disp_grid = NaN(size(disp_grid_NoFilter));
                for ii = 1:size(disp_grid_NoFilter,3), disp_grid(:,:,ii) = wiener2(gather(disp_grid_NoFilter(:,:,ii)), gather(windowSize)); end
                filteringMethod1  = filteringMethod;
                filteringMethod = strjoin({filteringMethod, strcat(SpatialFilterChoiceStr, '(', num2str(windowSize(1)), 'x', num2str(windowSize(2)), 'pix', ')'),  PaddingChoiceStr}, ', ');                
                switch HanWindowchoice
                    case 'Yes'
                        disp_gridHan = HanWindow(disp_grid);
                        filteringMethod = strjoin({filteringMethod, 'Han-Windowed'}, ', ');
                        HanWindowBoolean = true;
                    case 'No'
                        disp_gridHan  = disp_grid;
                        HanWindowBoolean = false;
                        % Continue
                end

            case 'Low-Pass Exponential 2D' 
                [pos_grid_stress, disp_grid, stress_grid, i_max, j_max, qMax] = Filters_LowPassExponential2D(pos_grid, disp_grid_NoFilter, gridSpacing, thickness_um, thickness_um,  YoungModulusPa, PoissonRatio, ...
                    fracPad, min_feature_size, ExponentOrder, reg_corner, i_max, j_max);

            case 'Low-Pass Butterworth'
                [pos_grid_stress, disp_grid, stress_grid, i_max, j_max, qMax] = Filters_LowPassButterworth2D(pos_grid, disp_grid_NoFilter, gridSpacing, [], [],  YoungModulusPa, PoissonRatio, ...
                    fracPad, 3, BW_order, i_max, j_max);            
        end
        
        
        %% 1.5 ----------------------------------------------
        if CurrentFrame == FramesDoneNumbers(1)
            switch GridtypeChoiceStr
                case 'Even Grid'
                    switch RepeatExperimemntChoice
                        case 'No'
                            if exist('reg_corner','var')                                        
                                dlgQuestion = ({sprintf('(reg_corner) = %g?', reg_corner)});
                                reg_cornerChoices = {'Use Current Value', 'Recalculate', 'Load from File', 'Enter Manually'};
                                reg_cornerChoiceIndex = listdlg('ListString', reg_cornerChoices, 'PromptString', dlgQuestion,  'SelectionMode', 'single', 'InitialValue', 2);
                                if isempty(reg_cornerChoiceIndex), return; end
                                reg_cornerChoiceStr = reg_cornerChoices{reg_cornerChoiceIndex};
                            else
                                dlgQuestion = ('reg_corner?');
                                reg_cornerChoices = {  'Recalculate', 'Load from File', 'Enter Manually'};
                                reg_cornerChoiceIndex = listdlg('ListString', reg_cornerChoices, 'PromptString', dlgQuestion,  'SelectionMode', 'single', 'InitialValue',1);
                                if isempty(reg_cornerChoiceIndex), return; end
                                reg_cornerChoiceStr = reg_cornerChoices{reg_cornerChoiceIndex};
                            end
                            switch reg_cornerChoiceStr
                                case 'Use Current Value'
                                    % continue
                                case 'Recalculate'
                                    disp('Calculating L-Curve values...in progress...');      
                                    %_____ added by WIM on 2020-02-20
                                    SizeX = size(disp_grid);
                                    SizeY = size(disp_grid);
                                    xVecGrid = 1:SizeX;
                                    yVecGrid = 1:SizeY;
                                    [Xvec, Yvec] = ndgrid(xVecGrid, yVecGrid);
                                    grid_mat_padded(:,:,1) = Xvec;
                                    grid_mat_padded(:,:,2) = Yvec;
                                    disp('Calculating L-Curve values in progress...');
                                    [rho,eta,reg_corner,alphas] = calculateLcurveFTTC(grid_mat_padded, disp_grid, YoungModulusPa,...
                                        PoissonRatio, gridSpacing, i_max, j_max, forceFieldParameters.regParam,forceFieldParameters.LcurveFactor);                                    
                                    %______________________________________
%                                     disp('Calculating L-Curve values in progress...');
%                                     [rho,eta,reg_corner,alphas] = calculateLcurveFTTC(pos_grid, disp_grid_NoFilter, YoungModulusPa,...
%                                         PoissonRatio, gridSpacing, i_max, j_max, forceFieldParameters.regParam,forceFieldParameters.LcurveFactor);
                                    disp('Calculating L-Curve values completed!');
                                    [reg_corner,ireg_corner,~,hLcurve] = regParamSelecetionLcurve(alphas',eta,alphas,reg_corner,'manualSelection',true);
                                case 'Load from File'
                                    if ~exist('forceFieldParametersPath', 'var'), forceFieldParametersPath = []; end
                                    [LCurveFile, LCurvePath] = uigetfile(fullfile(forceFieldParametersPath,'*.mat'), ' open "LCurveData.mat" file');  
                                    if isempty(forceFieldParametersPath), forceFieldParametersPath = LCurvePath; end
                                    LCurveFullFileName = fullfile(LCurvePath, LCurveFile);   
                                    load(LCurveFullFileName, 'eta', 'ireg_corner', 'reg_corner', 'rho');
                                case 'Enter Manually'
                                    if ~exist('reg_corner', 'var'), reg_corner =  0.0056; end       % default value
                                    reg_corner_input = input(sprintf('Do you want to use %g as the FTTC regularization corner (reg_corner)\n\t Press Enter to continue. Enter the value and enter otherwise: ',reg_corner));  
                                    if ~isempty(reg_corner_input)
                                        reg_corner = reg_corner_input;
                                        reg_cornerChoiceStr = 'Yes';
                                    else
                                        reg_cornerChoiceStr = 'No';                                            
                                    end                                            
                                otherwise
                                    return
                            end
                            fprintf('FTTC regularization corner (reg_corner) is %g. \n', reg_corner);
                    end
                case 'Odd Grid'  
                    error('This segments of the code is incomplete. Use Odd-grid-based code')
                otherwise
                    % INCOMPLETE
            end 
        end
 

        %% 2.0 calculate the traction stress field "forceField" in Pa and       
        %----- Unfiltered Case ----------
        switch SpatialFilterChoiceStr
            case {'No-Filter', 'Wiener 2D'}
                switch TractionStressMethod
                    case 'FTTC'
                        switch GridtypeChoiceStr
                            case 'Even Grid'
                                [pos_grid_stress, stress_vec, stress_grid, stress_grid_norm] = reg_fourier_TFM(pos_grid, disp_gridHan(:,:,1:2), YoungModulusPa,...
                                    PoissonRatio, movieData.pixelSize_/1000, gridSpacing, i_max, j_max, reg_corner);
                                stress_grid(:,3) = stress_grid_norm;
                            case 'Odd Grid'
% %                             %   output is embedded in LowPassGaussian2DFilter
                                [pos_grid_stress,stress_vec, stress_grid, stress_grid_norm] = reg_fourier_TFM_odd(pos_grid, disp_gridHan(:,:,1:2), YoungModulusPa,...
                                PoissonRatio, movieData.pixelSize_/1000, gridSpacing, i_max, j_max, reg_corner);
                                stress_grid(:,3) = stress_grid_norm;
                        end
                end
            otherwise
                % continue
        end

        %% 2.1 Reshape & Trim the displacement  integration traction force in N ============     
        % reshape for grid
        pos_grid_size = size(pos_grid);
        disp_grid_size = size(disp_grid);
        pos_grid_stress = reshape(pos_grid_stress, pos_grid_size);            
        stress_grid = reshape(stress_grid, disp_grid_size);    

        clear disp_grid_trimmed stress_grid_trimmed
        switch PaddingChoiceStr
            case { 'Padded with random & zeros', 'Padded with zeros only'}       
                clear disp_grid_trimmed disp_grid_NoFilter_trimmed stress_grid_trimmed
                for ii = 1:size(disp_grid, 3)
                    disp_grid_trimmed(:,:,ii) = disp_grid(disp_grid_NoFilter_TopLeftCorner(1):disp_grid_NoFilter_BottomRightCorner(1) , disp_grid_NoFilter_TopLeftCorner(2):disp_grid_NoFilter_BottomRightCorner(2), ii);
                    disp_grid_NoFilter_trimmed(:,:,ii) = disp_grid_NoFilter(disp_grid_NoFilter_TopLeftCorner(1):disp_grid_NoFilter_BottomRightCorner(1) , disp_grid_NoFilter_TopLeftCorner(2):disp_grid_NoFilter_BottomRightCorner(2), ii);
                end 
                for ii = 1:size(stress_grid, 3)
                    stress_grid_trimmed(:,:,ii) = stress_grid(disp_grid_NoFilter_TopLeftCorner(1):disp_grid_NoFilter_BottomRightCorner(1) , disp_grid_NoFilter_TopLeftCorner(2):disp_grid_NoFilter_BottomRightCorner(2), ii);
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

       %%  Testing 2020-01-23 Integrate only a part of the stress field. This is to test if there is any effect. Create a mask. 
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
        
        %% 2.2 Calculate the integration traction force in N ============ 
        switch TractionForceMethod
            case 'Summed'
                % Integrate the traction stresses
                if numel(size(stress_grid)) == 3         % is 3-layer grids
                    Force = TractionForceSingleFrameNoMD(pos_grid_stress, stress_grid(:,:,1:2), ScaleMicronPerPixel, TractionForceMethod, [], ShowOutput);
                else
                    Force = TractionForceSingleFrameNoMD(pos_grid_stress, stress_grid(:,1:2), ScaleMicronPerPixel, TractionForceMethod, [], ShowOutput);
                end
        end
        if useGPU, Force = gather(Force); end
        TractionForceX(CurrentFrame) = Force(:,1);
        TractionForceY(CurrentFrame) = Force(:,2);
        TractionForce(CurrentFrame) = Force(:,3);

        switch FrameDisplMeanChoice
            case 'Yes'
                TractionForceMean(CurrentFrame, 1) = mean([TractionForceX(CurrentFrame),TractionForceY(CurrentFrame), TractionForce(CurrentFrame)]);
            case 'No'
                % continue and do nothing
        end
        
        %% 2.3 Calculate Energy Storage.
        TrDotUr = (disp_grid_trimmed(:,:,1:2).*(ScaleMicronPerPixel * ConversionMicronPerM).^2) .*stress_grid_trimmed(:,:,1:2);      % convert to microns from pixels. stress in Pa.
        TractionEnergyJ(CurrentFrame)  = 1/2*sum(sum(sum(TrDotUr)));

        if CurrentFrame == FrameNumToBePlotted
            disp_grid_plotted = disp_grid;
            stress_grid_plotted = stress_grid;
            pos_grid_plotted = pos_grid_stress;
%             pos_grid_stress_plotted = pos_grid_stress;
        end
        
        displFieldNoFilteredGrid(CurrentFrame).pos = gather(reshape(pos_grid(:,:,1:2) , [pos_grid_size(1) * pos_grid_size(2), pos_grid_size(3)]));
        displFieldNoFilteredGrid(CurrentFrame).vec = gather(reshape(disp_grid_NoFilter(:,:,1:2) , [pos_grid_size(1) * pos_grid_size(2), pos_grid_size(3)]));
        
        displFieldFilteredGrid(CurrentFrame).pos = gather(reshape(pos_grid(:,:,1:2) , [pos_grid_size(1) * pos_grid_size(2), pos_grid_size(3)]));
        displFieldFilteredGrid(CurrentFrame).vec = gather(reshape(disp_grid(:,:,1:2) , [pos_grid_size(1) * pos_grid_size(2), pos_grid_size(3)]));
        
        forceField(CurrentFrame).pos = gather(reshape(pos_grid_stress(:,:,1:2), [pos_grid_size(1) * pos_grid_size(2), 2]));    
        forceField(CurrentFrame).vec = gather(reshape(stress_grid(:,:,1:2),  [pos_grid_size(1) * pos_grid_size(2), pos_grid_size(3)]));       
    end
    
    %%
    switch DCchoice
        case 'Yes'
            try
                [DisplFilePath, DisplFileName, DisplFileExt] = fileparts(DisplacementFileFullName);
                displacementFileNameFiltered = sprintf('%s_DC%s', DisplFileName, DisplFileExt); 
                DisplFieldPathsUp = strsplit(DisplFilePath, filesep);
                displacementFilePathFiltered =  fullfile( fullfile(DisplFilePath, '..'), strcat(DisplFieldPathsUp{end}, '_DC'));       % _Low-Pass Equiripples Filter (Equiripples) Drift-Corrected
            catch
                displacementFilePathFiltered = uigetdir('Select Path for DC-corrected displacement fields');
                % continue
            end
            if exist('displacementFilePathFiltered', 'var')
                if ~exist(displacementFilePathFiltered, 'dir'), mkdir(displacementFilePathFiltered); end            
                displFieldBeadsUnfiltered = displField;

                displField = displFieldBeadsDriftCorrected;            
                displFieldDCBeadsfileName = fullfile(displacementFilePathFiltered, sprintf('displField_%s_%s_beads.mat', TimeFilterChoiceStrName, DCchoiceStr));
                save(displFieldDCBeadsfileName, 'displField', '-v7.3')
            
                displField = displFieldNoFilteredGrid;            
                displFieldDCGridfileName = fullfile(displacementFilePathFiltered, sprintf('displField_%s_%s_interp.mat', TimeFilterChoiceStrName, DCchoiceStr));
                save(displFieldDCGridfileName, 'displField', '-v7.3')
            end
    end  
    
    if ~strcmpi(SpatialFilterChoiceStr, 'No-Filter')                % skip this if no filter is used. Otherwise, output that displField.
        % Now, save the Spatial filtered grid after it had been reshaped to a vector.
        displField = displFieldFilteredGrid;
        displFieldDCfileName = fullfile(AnalysisPath, sprintf('displField_%s_%s_%s_interp.mat', TimeFilterChoiceStrName, DCchoiceStr, SpatialFilterChoiceStr));
        save(displFieldDCfileName, 'displField')    
    end
    
    forceFieldDCfileName = fullfile(AnalysisPath, sprintf('forceField_%s_%s_%s.mat', TimeFilterChoiceStrName, DCchoiceStr, SpatialFilterChoiceStr));
    save(forceFieldDCfileName, 'forceField')          
    %%
    if exist('qMax', 'var'), fprintf('Qmax = %0.1f\n', qMax); end
    
    if useGPU
        TractionForceX = gather(TractionForceX);
        TractionForceY = gather(TractionForceY);
        TractionForce = gather(TractionForce);
        try
            TractionForceMean = gather(TractionForceMean);
        catch
            % continue
        end
    end    
    tractionForceDCfileName = fullfile(AnalysisPath, sprintf('tractionForce_%s_%s_%s.mat', TimeFilterChoiceStrName, DCchoiceStr, SpatialFilterChoiceStr));
    save(tractionForceDCfileName, 'TractionForceX', 'TractionForceY', 'TractionForce')

%% 2.0 ADD MORE PARAMETERS TO BE SAVED TO THE OUTPUT
    tractionForceFieldFileName =   sprintf('Traction Force_%s_%s_%s_Workspace.mat', TimeFilterChoiceStrName, DCchoiceStr, SpatialFilterChoiceStr); %Traction Force_Workspace';
    tractionForceFieldFullFileName = fullfile(AnalysisPath, tractionForceFieldFileName);
%     switch SpatialFilterChoiceStr
%         case {'Low-Pass Exponential 2D', 'Low-Pass Butterworth'}
%             PaddingListStr = 'Padded with random & zeros';
%     end    
    save(tractionForceFieldFullFileName, 'SpatialFilterChoiceStr','HanWindowchoice', 'PaddingChoiceStr', 'GridtypeChoiceStr', 'IdenticalCornersChoice', ...
        'TractionStressMethod','forceFieldParameters', 'displField', 'gridSpacing', 'reg_grid', ...
        'gridMagnification', 'EdgeErode', 'controlMode', 'CentralROIChoice', 'DCchoiceStr', ...       
        'TractionForceX','TractionForceY', 'TractionForce', 'TractionEnergyJ', 'intMethodStr', 'YoungModulusPa', 'PoissonRatio', 'thickness_um', '-v7.3')
    try save(tractionForceFieldFullFileName, 'reg_corner', '-append'); catch ;end
    switch DCchoice
        case 'Yes'
            save(tractionForceFieldFullFileName, 'DriftROIs', 'DriftROIsCombined', 'rect', 'gridXmin', 'gridXmax', 'gridYmin',...
                'gridYmax', 'CornerPercentage', 'pValTtest', 'pValANOVA','-append')
    end    
    switch CentralROIChoice
        case 'Yes'
            save(tractionForceFieldFullFileName, 'rectCenter', '-append')
    end    
    switch FrameDisplMeanChoice
        case 'Yes'
            save(tractionForceFieldFullFileName, 'TractionForceMean', '-append')
    end
    switch IdenticalCornersChoice
        case 'Yes' 
           save(tractionForceFieldFullFileName,'CornerPercentage' , '-append')
    end
    switch TimeFilterChoiceStr
        case 'Yes'
            save(tractionForceFieldFullFileName, 'TimeFilterParameters', '-append')
    end
    switch SpatialFilterChoiceStr
        case 'No-Filter'
            % nothing else to append
        case  'Wiener 2D'     
            save(tractionForceFieldFullFileName, 'windowSize', '-append')   
        case 'Low-Pass Exponential 2D'
            save(tractionForceFieldFullFileName, 'thickness_um', 'fracPad', 'min_feature_size', 'ExponentOrder','qMax','-append')
            filteringMethod = [filteringMethod, char(32), 'qMax',char(32), num2str(qMax, '%0.1f')];
            switch HanWindowchoice
                case 'Yes'
                    filteringMethod = [filteringMethod, char(32), 'Han-Windowed'];
                    HanWindowBoolean = true;
                case 'No'
                    filteringMethod = [filteringMethod, char(32), 'Not Han-Windowed'];                    
                    HanWindowBoolean = false;
                    % Continue
                otherwise
                    return
            end     
        case 'Low-Pass Butterworth'
            save(tractionForceFieldFullFileName, 'fracPad', 'BW_order', 'qMax', '-append')
            filteringMethod = [filteringMethod, char(32), 'qMax',char(32), num2str(qMax, '%0.0f')];
            switch HanWindowchoice
                case 'Yes'
                    filteringMethod = [filteringMethod, char(32), 'Han-Windowed'];
                    HanWindowBoolean = true;
                case 'No'
                    filteringMethod = [filteringMethod, char(32), 'Not Han-Windowed'];                    
                    HanWindowBoolean = false;
                    % Continue
                otherwise
                    return
            end                 
    end
    
    LastFramePlotted = min([numel(TimeStamps), VeryLastFrame, LastFrame]);
    
%% 3.1 Saving variables to *.mat files.
    save(tractionForceFieldFullFileName, 'FrameRate', 'TimeStamps','VeryFirstFrame', 'VeryLastFrame', 'LastFramePlotted', ...
        'GelConcentrationMgMl',  'thickness_um', 'YoungModulusPa', 'PoissonRatio', '-append')
    fprintf('Workspace key varuiables saved as: \n\t%s\n,' ,tractionForceFieldFullFileName)   
    
    try
        save(displFieldDCBeadsfileName,  'TimeStamps', '-append')
    catch
        % continue
    end
    try
        save(displacementFilePathFiltered, 'TimeStamps', '-append')
    catch
        % continue
    end       
    save(forceFieldDCfileName, 'TimeStamps', '-append')
    save(tractionForceDCfileName, 'TimeStamps', '-append')
    
%% 3.2 Plotting Traction Force over all Frames
    fprintf('Plots saved under: \n\t%s\n,' ,AnalysisPath)    
    clear titleStr titleStr0 titleStr1 titleStr2 titleStr3 titleStr4 titleStr5
    clear FramesPlotted
    
    FramesPlotted(1:LastFramePlotted) = ~isnan(TractionForce(1:LastFramePlotted));
    params = 'r-';
    save(tractionForceFieldFullFileName, 'ConversionNtoNN', 'FramesPlotted', '-append')
    
    %%
%     titleStr0 = 'Traction force, F,';
%     titleStr1 = sprintf('%s for %.0f', titleStr0, thickness_um);
%     titleStr2 = strcat(titleStr1, ' \mum-thick,');
%     titleStr2 = strcat(titleStr2, sprintf('%.1f mg/mL type I collagen gel', GelConcentrationMgMl));
%     titleStr3 = sprintf('Young Moudulus = %.0f Pa. Poisson Ratio = %.2f', YoungModulusPa, PoissonRatio);
%     titleStr4 = sprintf('Traction stresses %s ', lower(TractionForceMethod));
%     titleStr5 = sprintf('%s', filteringMethod);
%     titleStr = {titleStr2, titleStr3, titleStr4, titleStr5};
    titleStr0 = sprintf('%.0f \\mum-thick, %.1f mg/mL type I collagen gel', thickness_um, GelConcentrationMgMl);
    titleStr1 = sprintf('Young Modulus = %.0f Pa. Poisson Ratio = %.2f', YoungModulusPa, PoissonRatio);
    titleStr = {titleStr0, titleStr1};

    showPlot = 'on';
    figHandleAllTraction = figure('visible',showPlot, 'color', 'w');     % added by WIM on 2019-02-07. To show, remove 'visible    
    set(figHandleAllTraction, 'Position', [275, 435, 825, 775])
    pause(0.1)          % give some time so that the figure loads well
    
    subplot(3,1,1)
    plot(TimeStamps(FramesPlotted), ConversionNtoNN * TractionForce(FramesPlotted), 'r.-', 'LineWidth', 1, 'MarkerSize', 2)
    xlim([0, TimeStamps(LastFramePlotted)]);
    title(titleStr);
    set(findobj(gcf,'type', 'axes'), ...
        'FontSize',11, ...
        'FontName', 'Helvetica', ...
        'LineWidth',1, ...
        'XMinorTick', 'on', ...
        'YMinorTick', 'on', ...
        'TickDir', 'out', ...
        'TitleFontSizeMultiplier', 0.9, ...
        'TitleFontWeight', 'bold');     % Make axes bold
    ylabel('\bf|\itF\rm(\itt\rm)\bf|\rm [nN]', 'FontName', PlotsFontName);
    
    hold on    
    subplot(3,1,2)
    plot(TimeStamps(FramesPlotted), ConversionNtoNN * TractionForceX(FramesPlotted), 'r.-', 'LineWidth', 1, 'MarkerSize', 2)
    xlim([0, TimeStamps(LastFramePlotted)]);
    set(findobj(gcf,'type', 'axes'), ...
        'FontSize',11, ...
        'FontName', 'Helvetica', ...
        'LineWidth',1, ...
        'XMinorTick', 'on', ...
        'YMinorTick', 'on', ...
        'TickDir', 'out', ...
        'TitleFontSizeMultiplier', 0.9, ...
        'TitleFontWeight', 'bold');     % Make axes bold    
    ylabel('\bf\itF_{x}\rm(\itt\rm) [nN]', 'FontName', PlotsFontName);
    
    % Flip to Cartesian Coordinates in the Plot (Negative pointing downwards). Add a negative Sign before plot. 
    subplot(3,1,3)
    plot(TimeStamps(FramesPlotted), - ConversionNtoNN * TractionForceY(FramesPlotted), 'r.-', 'LineWidth', 1, 'MarkerSize', 2)       % Flip the y-coordinates to Cartesian
    xlim([0, TimeStamps(LastFramePlotted)]);
    set(findobj(gcf,'type', 'axes'), ...
        'FontSize',11, ...
        'FontName', 'Helvetica', ...
        'LineWidth',1, ...
        'XMinorTick', 'on', ...
        'YMinorTick', 'on', ...
        'TickDir', 'out', ...
        'TitleFontSizeMultiplier', 0.9, ...
        'TitleFontWeight', 'bold');     % Make axes bold  
    xlabelHandle = xlabel(sprintf('\\rm %s', xLabelTime));
    set(xlabelHandle, 'FontName', PlotsFontName)
    ylabel('\bf\itF_{y}\rm(\itt\rm) [nN]', 'FontName', PlotsFontName);    
%__________________
    figHandleNetOnlyTraction = figure('visible',showPlot, 'color', 'w');     % added by WIM on 2019-02-07. To show, remove 'visible    
    set(figHandleNetOnlyTraction, 'Position', [275, 435, 825, 375])
    plot(TimeStamps(FramesPlotted), ConversionNtoNN * TractionForce(FramesPlotted), 'r.-', 'LineWidth', 1, 'MarkerSize', 2)
    xlim([0, TimeStamps(LastFramePlotted)]);
    title(titleStr);
    set(findobj(gcf,'type', 'axes'), ...
        'FontSize',11, ...
        'FontName', 'Helvetica', ...
        'LineWidth',1, ...
        'XMinorTick', 'on', ...
        'YMinorTick', 'on', ...
        'TickDir', 'out', ...
        'TitleFontSizeMultiplier', 0.9, ...
        'TitleFontWeight', 'bold');     % Make axes bold  
    xlabelHandle = xlabel(sprintf('\\rm %s', xLabelTime));
    set(xlabelHandle, 'FontName', PlotsFontName)
    ylabel('\bf|\itF\rm\it(t)\rm\bf|\rm [nN]', 'FontName', PlotsFontName);
    
    if strcmpi(DCchoice, 'Yes')
        figANOVA_tTest  =   figure('Visible', showPlot,  'color', 'w');
        set(figANOVA_tTest, 'Position', [475, 435, 825, 200])
        plot(TimeStamps(FramesPlotted), pValANOVA(FramesPlotted), 'b.-', 'LineWidth', 1, 'MarkerSize', 2)
        hold on 
        plot(TimeStamps(FramesPlotted), pValTtest(FramesPlotted), 'r.-', 'LineWidth', 1, 'MarkerSize', 2)
        xlim([0, TimeStamps(LastFramePlotted)]);     
        title(titleStr);
            title(titleStr);
        set(findobj(gcf,'type', 'axes'), ...
            'FontSize',11, ...
            'FontName', 'Helvetica', ...
            'LineWidth',1, ...
            'XMinorTick', 'on', ...
            'YMinorTick', 'on', ...
            'TickDir', 'out', ...
            'TitleFontSizeMultiplier', 0.9, ...
            'TitleFontWeight', 'bold');     % Make axes bold  
        xlabelHandle = xlabel(sprintf('\\rm %s', xLabelTime));
        set(xlabelHandle, 'FontName', PlotsFontName)
        ylabel('\bf\it\rmp-value(\itt\rm)\bf\rm', 'FontName', PlotsFontName);
        legendHandle =  legend('ANOVA1: 4 Corner ROIs', 'T-test: Right vs. Left');
        legendHandle.FontSize = 8;

       %___________________
        for kk = FramesDoneNumbers
            for ii = 1:size(DriftROIs, 2)
                    DriftROIsMeans(kk, ii) = DriftROIs(kk, ii).mean(:,3);
            end    
        end
        figROIsDrift  =   figure('Visible', showPlot,  'color', 'w');
        set(figROIsDrift, 'Position', [475, 435, 1000, 400])
        for ii = 1:4
            plot(TimeStamps(FramesPlotted), DriftROIsMeanDispAllCorners(FramesPlotted, ii) .* ScaleMicronPerPixel, 'LineWidth', 0.5, 'MarkerSize', 2)
            hold on
        end
        xlim([0, TimeStamps(LastFramePlotted)]);
        set(findobj(gcf,'type', 'axes'), ...
            'FontSize',11, ...
            'FontName', 'Helvetica', ...
            'LineWidth',1, ...
            'XMinorTick', 'on', ...
            'YMinorTick', 'on', ...
            'TickDir', 'out', ...
            'TitleFontSizeMultiplier', 0.9, ...
            'TitleFontWeight', 'bold');     % Make axes bold    
        title(titleStr);
        xlabelHandle = xlabel(sprintf('\\rm %s', xLabelTime));
        set(xlabelHandle, 'FontName', PlotsFontName)
        ylabel('\bf|\it\Delta\rm(\itt\rm)\bf|\rm [\mum]', 'FontName', PlotsFontName);
        legendHandle = legend('ROI Top-Left', 'ROI Bottom-Left', 'ROI Top-Right', 'ROI Bottom-Right');
        legendHandle.FontSize = 8;  
    end
 
    
%% Strain Energy
    figHandleEnergy = figure('visible',showPlot, 'color', 'w');     % added by WIM on 2019-02-07. To show, remove 'visible    
    set(figHandleEnergy, 'Position', [275, 435, 825, 375])
    plot(TimeStamps(FramesPlotted), TractionEnergyJ(FramesPlotted) * ConversionJtoPicoJ, 'r.-', 'LineWidth', 1, 'MarkerSize', 2)
    xlim([0, TimeStamps(LastFramePlotted)]);
    title(titleStr);
    set(findobj(gcf,'type', 'axes'), ...
        'FontSize',11, ...
        'FontName', 'Helvetica', ...
        'LineWidth',1, ...
        'XMinorTick', 'on', ...
        'YMinorTick', 'on', ...
        'TickDir', 'out', ...
        'TitleFontSizeMultiplier', 0.9, ...
        'TitleFontWeight', 'bold');     % Make axes bold  
    xlabelHandle = xlabel(sprintf('\\rm %s', xLabelTime));
    set(xlabelHandle, 'FontName', PlotsFontName)
    ylabel('\itU\rm\it(t)\rm [pJ]', 'FontName', PlotsFontName);
    
    
%% 4.0 Plot Displacement Mean if requested
    switch FrameDisplMeanChoice
        case 'Yes'
%             titleStr0 = 'Displacement from starting point, \Delta_{TFM},';
%             titleStr1 = sprintf('%s for %.0f', titleStr0, thickness_um);
%             titleStr2 = strcat(titleStr1, '-\mum,');
%             titleStr2 = strcat(titleStr2, sprintf('%.1f mg/mL collagen type-I gel', GelConcentrationMgMl));
%             titleStr3 = sprintf('Young Moudulus = %.1f Pa. Poisson Ratio = %.2f', YoungModulusPa, PoissonRatio);
%             titleStr4 = sprintf('Traction stresses %s ', lower(TractionForceMethod));
%             titleStr5 = sprintf('%s', filteringMethod);
%             titleStr = {titleStr2, titleStr3, titleStr4, titleStr5};
           
            vecCorrectedMean = nan(numel(FramesDoneNumbers), 3);
            for ii = FramesDoneNumbers
                vecCorrectedMean(ii, :) = displField(ii).vecCorrectedMean;
            end

            figHandleAllDisplacement = figure('visible',showPlot, 'color', 'w');     % added by WIM on 2019-02-07. To show, remove 'visible    
            set(figHandleAllDisplacement, 'Position', [275, 435, 825, 775])
            pause(0.1)          % give some time so that the figure loads well

            subplot(3,1,1)
            plot(TimeStamps(FramesPlotted), vecCorrectedMean(FramesPlotted,3), 'r.-', 'LineWidth', 1, 'MarkerSize', 2)
            xlim([0, TimeStamps(LastFramePlotted)]);
            title(titleStr);
            set(findobj(gcf,'type', 'axes'), ...
                'FontSize',11, ...
                'FontName', 'Helvetica', ...
                'LineWidth',1, ...
                'XMinorTick', 'on', ...
                'YMinorTick', 'on', ...
                'TickDir', 'out', ...
                'TitleFontSizeMultiplier', 0.9, ...
                'TitleFontWeight', 'bold');     % Make axes bold
            ylabel('\bf|\it\Delta\rm(\itt\rm)\bf|\rm [\mum]', 'FontName', PlotsFontName);

            hold on    
            subplot(3,1,2)
            plot(TimeStamps(FramesPlotted), vecCorrectedMean(FramesPlotted,1), 'r.-', 'LineWidth', 1, 'MarkerSize', 2)
            xlim([0, TimeStamps(LastFramePlotted)]);
            set(findobj(gcf,'type', 'axes'), ...
                'FontSize',11, ...
                'FontName', 'Helvetica', ...
                'LineWidth',1, ...
                'XMinorTick', 'on', ...
                'YMinorTick', 'on', ...
                'TickDir', 'out', ...
                'TitleFontSizeMultiplier', 0.9, ...
                'TitleFontWeight', 'bold');     % Make axes bold    
            ylabel('\bf\it\Delta_{x}\rm(\itt\rm) [\mum]', 'FontName', PlotsFontName);

            % Flip to Cartesian Coordinates in the Plot (Negative pointing downwards). Add a negative Sign before plot. 
            subplot(3,1,3)
            plot(TimeStamps(FramesPlotted), - vecCorrectedMean(FramesPlotted,2), 'r.-', 'LineWidth', 1, 'MarkerSize', 2)       % Flip the y-coordinates to Cartesian
            xlim([0, TimeStamps(LastFramePlotted)]);
            set(findobj(gcf,'type', 'axes'), ...
                'FontSize',11, ...
                'FontName', 'Helvetica', ...
                'LineWidth',1, ...
                'XMinorTick', 'on', ...
                'YMinorTick', 'on', ...
                'TickDir', 'out', ...
                'TitleFontSizeMultiplier', 0.9, ...
                'TitleFontWeight', 'bold');     % Make axes bold  
            xlabelHandle = xlabel(sprintf('\\rm %s', xLabelTime));
            set(xlabelHandle, 'FontName', PlotsFontName)
            ylabel('\bf\it\Delta_{y}\rm(\itt\rm) [\mum]', 'FontName', PlotsFontName);

            %__________________

            figHandleNetOnlyDisplacement = figure('visible',showPlot, 'color', 'w');     % added by WIM on 2019-02-07. To show, remove 'visible    
            set(figHandleNetOnlyDisplacement, 'Position', [275, 435, 825, 375])
            plot(TimeStamps(FramesPlotted), TractionForce(FramesPlotted), 'r.-', 'LineWidth', 1, 'MarkerSize', 2)
            xlim([0, TimeStamps(LastFramePlotted)]);
            title(titleStr);
            set(findobj(gcf,'type', 'axes'), ...
                'FontSize',11, ...
                'FontName', 'Helvetica', ...
                'LineWidth',1, ...
                'XMinorTick', 'on', ...
                'YMinorTick', 'on', ...
                'TickDir', 'out', ...
                'TitleFontSizeMultiplier', 0.9, ...
                'TitleFontWeight', 'bold');     % Make axes bold  
            xlabelHandle = xlabel(sprintf('\\rm %s', xLabelTime));
            set(xlabelHandle, 'FontName', PlotsFontName)
            ylabel('\bf|\it\Delta\rm(\itt\rm)\bf|\rm [\mum]', 'FontName', PlotsFontName);
    end  
    
% 6.0 ======================== Plot Displacement and Traction ==================
    if ~isempty(FrameNumToBePlotted)
        %--- Plot net displacement in 3D -----------------------------------------------------------------
        clear XI YI reg_gridFull displVecGridXY displVecGridFullXY
        displFieldPos = displFieldBeadsDriftCorrected(FrameNumToBePlotted).pos;
        displFieldVec = displFieldBeadsDriftCorrected(FrameNumToBePlotted).vec;
        displFieldVec(:,3) = vecnorm(displFieldVec(:,1:2), 2, 2);           % find the norm;
        [reg_grid, ~, ~, GridSpacing] = createRegGridFromDisplField(displFieldPos, gridMagnification, EdgeErode);              
        [grid_mat, displVecGridXY,~,~] = interp_vec2grid(displFieldPos(:,1:2), displFieldVec(:,1:2) ,[], reg_grid);
        grid_matX = grid_mat(:,:,1);
        grid_matY = grid_mat(:,:,2);        
        grid_spacingX = grid_mat(1,2,1)- grid_mat(1,1,1);
        grid_spacingY = grid_mat(2,1,2)- grid_mat(1,1,2);        
        imSizeX = (grid_mat(end,end,1) - grid_mat(1,1,1)) + grid_spacingX;
        imSizeY = (grid_mat(end,end,2) - grid_mat(1,1,2)) + grid_spacingY; 
        width = imSizeX;
        height = imSizeY;
        centerX = ((grid_mat(end,end,1) + grid_mat(1,1,1))/2);
        centerY = ((grid_mat(end,end,2) + grid_mat(1,1,2))/2);
        Xmin = centerX - width/2 + bandSize;
        Xmax = centerX + width/2 - bandSize;
        Ymin = centerY - height/2 + bandSize;
        Ymax = centerY + height/2 - bandSize;
        [XI, YI] = ndgrid(Xmin:Xmax,Ymin:Ymax);       
        displVecGridNorm = (displVecGridXY(:,:,1).^2 + displVecGridXY(:,:,2).^2).^0.5;
        dMap{FrameNumToBePlotted} = displVecGridNorm;
        dMapX{FrameNumToBePlotted} = displVecGridXY(:,:,1);
        dMapY{FrameNumToBePlotted} = displVecGridXY(:,:,2);
        if useGPU
            grid_mat = gather(grid_mat);
            displVecGridNorm = gather(displVecGridNorm);
            XI = gather(XI);
            YI = gather(YI);
        end        
        reg_gridFull(:,:,1)  = XI; reg_gridFull(:,:,2)  = YI;     
        [grid_mat_full, displVecGridFullXY,~,~] = interp_vec2grid(displFieldPos(:,1:2),displFieldVec(:,1:2) ,[], reg_gridFull, InterpolationMethod);
        displHeatMapX = displVecGridFullXY(:,:,1);
        displHeatMapY = displVecGridFullXY(:,:,2);
        displHeatMap = (displHeatMapX.^2 + displHeatMapY.^2).^0.5;              % Find the norm        
%         % Padding Step with 0s 
%         displHeatMapPadded = zeros(ImageSizePixels);                    % Added on 2019-10-13
%         displHeatMapXPadded = zeros(ImageSizePixels);                    % Added on 2019-10-13
%         displHeatMapYPadded = zeros(ImageSizePixels);                    % Added on 2019-10-13
%         displHeatMapPadded(Xmin:Xmax,Ymin:Ymax) = displHeatMap;                   
%         displHeatMapXPadded(Xmin:Xmax,Ymin:Ymax) = displHeatMapX;                    
%         displHeatMapYPadded(Xmin:Xmax,Ymin:Ymax) = displHeatMapY;        
%         [XIPadded, YIPadded] = ndgrid(1:ImageSizePixels(1), 1:ImageSizePixels(2));

%_______________________________________________
        figHandle1_1_1 = figure('color', 'w');
        set(figHandle1_1_1, 'Position', [75, 35, 825, 575])
%         surf(pos_grid_plotted(:,:,1), pos_grid_plotted(:,:,2), disp_grid_plotted(:,:,3) * ScaleMicronPerPixel)
        surf(XI, YI, displHeatMap * ScaleMicronPerPixel)
        axis square
%         view(2);% Show from above (XY view)
        xlim([0, movieData.imSize_(1)]); ylim([0, movieData.imSize_(2)]);        
        set(gca, 'ydir', 'reverse', 'Box', 'on')
        shading interp
        colormap(fake_parula(2^ImageBits));                  % try winter also. parula shows more noise levels
        colorbarHandle = colorbar;
        colorbarLimits = get(colorbarHandle, 'Limits');
        colorbarTicks = unique(sort([colorbarLimits, colorbarHandle.Ticks]));               % updated on 2019-10-23 to make sure points are unique
        set(colorbarHandle, 'Ticks', colorbarTicks, 'TickDirection', 'out', ...
            'FontWeight', 'bold', 'FontName', 'Helvetica', 'LineWidth', 1);     % font size, 1/100 of height in pixels
        ylabel(colorbarHandle, 'Displacement_{Net} [\mum]')
    %     caxis([-0.1, 0.1])                                % standardize it for all plots
        titleStr1_1 = sprintf('Frame %d/%d. Full Size. Net Displacement Grid 3D - %s - %s', FrameNumToBePlotted, LastFrame, InterpolationMethod);
        titleStr1_2 = sprintf('%s', filteringMethod1);
        title({titleStr1_1, titleStr1_2})
    %     zlim([-1, 1])                                  % standardize it for all plots.
        xlabel('X [pixels]'), ylabel('Y [pixels]'), zlabel('Displacement_{Net} [\mum]')                 % note, it is reversed since surf() uses meshgrid() vs. griddata use ndgrid()
        set(gca, 'FontWeight', 'bold')    
        hold on, plot3(displFieldPos(:,1), displFieldPos(:,2), displFieldVec(:,3) * ScaleMicronPerPixel, 'o', 'MarkerSize', 2, 'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'r')

        %--- Plot net displacement in 3D -----------------------------------------------------------------
        clear XI YI reg_gridFull displVecGridXY displVecGridFullXY
        displFieldPos = displFieldFilteredGrid(FrameNumToBePlotted).pos;
        displFieldVec = displFieldFilteredGrid(FrameNumToBePlotted).vec;
        displFieldVec(:,3) = vecnorm(displFieldVec(:,1:2), 2, 2);           % find the norm;
        [reg_grid, ~, ~, GridSpacing] = createRegGridFromDisplField(displFieldPos, gridMagnification, EdgeErode);              
        [grid_mat, displVecGridXY,~,~] = interp_vec2grid(displFieldPos(:,1:2), displFieldVec(:,1:2) ,[], reg_grid);
        grid_matX = grid_mat(:,:,1);
        grid_matY = grid_mat(:,:,2);        
        grid_spacingX = grid_mat(1,2,1)- grid_mat(1,1,1);
        grid_spacingY = grid_mat(2,1,2)- grid_mat(1,1,2);        
        imSizeX = (grid_mat(end,end,1) - grid_mat(1,1,1)) + grid_spacingX;
        imSizeY = (grid_mat(end,end,2) - grid_mat(1,1,2)) + grid_spacingY; 
        width = imSizeX;
        height = imSizeY;
        centerX = ((grid_mat(end,end,1) + grid_mat(1,1,1))/2);
        centerY = ((grid_mat(end,end,2) + grid_mat(1,1,2))/2);
        Xmin = centerX - width/2 + bandSize;
        Xmax = centerX + width/2 - bandSize;
        Ymin = centerY - height/2 + bandSize;
        Ymax = centerY + height/2 - bandSize;
        [XI, YI] = ndgrid(Xmin:Xmax,Ymin:Ymax);       
        displVecGridNorm = (displVecGridXY(:,:,1).^2 + displVecGridXY(:,:,2).^2).^0.5;
        dMap{FrameNumToBePlotted} = displVecGridNorm;
        dMapX{FrameNumToBePlotted} = displVecGridXY(:,:,1);
        dMapY{FrameNumToBePlotted} = displVecGridXY(:,:,2);
        if useGPU
            grid_mat = gather(grid_mat);
            displVecGridNorm = gather(displVecGridNorm);
            XI = gather(XI);
            YI = gather(YI);
        end        
        reg_gridFull(:,:,1)  = XI; reg_gridFull(:,:,2)  = YI;     
        [grid_mat_full, displVecGridFullXY,~,~] = interp_vec2grid(displFieldPos(:,1:2),displFieldVec(:,1:2) ,[], reg_gridFull, InterpolationMethod);
        displHeatMapX = displVecGridFullXY(:,:,1);
        displHeatMapY = displVecGridFullXY(:,:,2);
        displHeatMap = (displHeatMapX.^2 + displHeatMapY.^2).^0.5;              % Find the norm        
%         % Padding Step with 0s 
%         displHeatMapPadded = zeros(ImageSizePixels);                    % Added on 2019-10-13
%         displHeatMapXPadded = zeros(ImageSizePixels);                    % Added on 2019-10-13
%         displHeatMapYPadded = zeros(ImageSizePixels);                    % Added on 2019-10-13
%         displHeatMapPadded(Xmin:Xmax,Ymin:Ymax) = displHeatMap;                   
%         displHeatMapXPadded(Xmin:Xmax,Ymin:Ymax) = displHeatMapX;                    
%         displHeatMapYPadded(Xmin:Xmax,Ymin:Ymax) = displHeatMapY;        
%         [XIPadded, YIPadded] = ndgrid(1:ImageSizePixels(1), 1:ImageSizePixels(2));
        figHandle1_1_2 = figure('color', 'w');
        set(figHandle1_1_2, 'Position', [75, 35, 825, 575])
%         surf(pos_grid_plotted(:,:,1), pos_grid_plotted(:,:,2), disp_grid_plotted(:,:,3) * ScaleMicronPerPixel)
        surf(XI, YI, displHeatMap * ScaleMicronPerPixel)
        axis square
%         view(2);% Show from above (XY view)
        xlim([0, movieData.imSize_(1)]); ylim([0, movieData.imSize_(2)]);        
        set(gca, 'ydir', 'reverse', 'Box', 'on')
        shading interp
        colormap(fake_parula(2^ImageBits));                  % try winter also. parula shows more noise levels
        colorbarHandle = colorbar;
        colorbarLimits = get(colorbarHandle, 'Limits');
        colorbarTicks = unique(sort([colorbarLimits, colorbarHandle.Ticks]));               % updated on 2019-10-23 to make sure points are unique
        set(colorbarHandle, 'Ticks', colorbarTicks, 'TickDirection', 'out', ...
            'FontWeight', 'bold', 'FontName', 'Helvetica', 'LineWidth', 1);     % font size, 1/100 of height in pixels
        ylabel(colorbarHandle, 'Displacement_{Net} [\mum]')
    %     caxis([-0.1, 0.1])                                % standardize it for all plots
        titleStr1_1 = sprintf('Frame %d/%d. Full Size. Net Displacement Grid 3D - %s - %s', FrameNumToBePlotted, LastFrame, InterpolationMethod);
        titleStr1_2 = sprintf('%s', filteringMethod);
        title({titleStr1_1, titleStr1_2})
    %     zlim([-1, 1])                                  % standardize it for all plots.
        xlabel('X [pixels]'), ylabel('Y [pixels]'), zlabel('Displacement_{Net} [\mum]')                 % note, it is reversed since surf() uses meshgrid() vs. griddata use ndgrid()
        set(gca, 'FontWeight', 'bold')    
        hold on, plot3(displFieldPos(:,1), displFieldPos(:,2), displFieldVec(:,3) * ScaleMicronPerPixel, 'o', 'MarkerSize', 2, 'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'r')
        
    %--- Plot displacement components in 2D -----------------------------------------------------------------
        figHandle1_2_1 = figure('color', 'w');
        set(figHandle1_2_1, 'Position', [175, 135, 825, 575])
        imagesc(unique(pos_grid_plotted(:,:,1)), unique(pos_grid_plotted(:,:,2)), disp_grid_plotted(:,:,3)' * ScaleMicronPerPixel)  % tranpose convert ndgrid >> meshgrid for image.
        axis square
        xlim([0, movieData.imSize_(1)]); ylim([0, movieData.imSize_(2)]);
        xlabel('X [pixels]'), ylabel('Y [pixels]')
        set(gca, 'FontWeight', 'bold')    
        colormap(fake_parula(2^ImageBits));
        colorbarHandle = colorbar;
        colorbarLimits = get(colorbarHandle, 'Limits');
        colorbarTicks = unique(sort([colorbarLimits, colorbarHandle.Ticks]));               % updated on 2019-10-23 to make sure points are unique
        set(colorbarHandle, 'Ticks', colorbarTicks, 'TickDirection', 'out', ...
            'FontWeight', 'bold', 'FontName', 'Helvetica', 'LineWidth', 1);     % font size, 1/100 of height in pixels        
        ylabel(colorbarHandle, 'Displacement_{Net} [\mum]')
        set(colorbarHandle, 'FontWeight', 'bold')
        hold on   
        quiver(pos_grid_plotted(:,:,1), pos_grid_plotted(:,:,2), disp_grid_plotted(:,:,1) * ScaleMicronPerPixel, disp_grid_plotted(:,:,2) * ScaleMicronPerPixel,...
            'w','LineWidth',  0.5, 'AutoScale', 'on', 'AutoScaleFactor', 0.9)  
        % no need to reverse if image() or imagesc() is used. The ydir is reversed. 
        titleStr1_3 = sprintf('Frame %d/%d. Original. Displacement Components - %s - %s', FrameNumToBePlotted, LastFrame, InterpolationMethod);
        title({titleStr1_3, titleStr1_2});

        %-----Plot net tractions in 3D ---------------------------------------------------------------  
        forceFieldPos = forceField(FrameNumToBePlotted).pos;
        forceFieldVec = forceField(FrameNumToBePlotted).vec;
        forceFieldVec(:,3) = vecnorm(forceFieldVec(:,1:2), 2, 2);
        [reg_grid, ~, ~, GridSpacing] = createRegGridFromDisplField(forceFieldPos, gridMagnification, EdgeErode);              
        [grid_mat, forceVecGridXY,~,~] = interp_vec2grid(forceFieldPos(:,1:2), forceFieldVec(:,1:2) ,[], reg_grid);
        grid_matX = grid_mat(:,:,1);
        grid_matY = grid_mat(:,:,2);

        grid_spacingX = grid_mat(1,2,1)- grid_mat(1,1,1);
        grid_spacingY = grid_mat(2,1,2)- grid_mat(1,1,2);        
        imSizeX = (grid_mat(end,end,1) - grid_mat(1,1,1)) + grid_spacingX;
        imSizeY = (grid_mat(end,end,2) - grid_mat(1,1,2)) + grid_spacingY; 
        width = imSizeX;
        height = imSizeY;
        centerX = ((grid_mat(end,end,1) + grid_mat(1,1,1))/2);
        centerY = ((grid_mat(end,end,2) + grid_mat(1,1,2))/2);
        Xmin = centerX - width/2 + bandSize;
        Xmax = centerX + width/2 - bandSize;
        Ymin = centerY - height/2 + bandSize;
        Ymax = centerY + height/2 - bandSize;
        [XI, YI] = ndgrid(Xmin:Xmax,Ymin:Ymax);       
        forceVecGridNorm = (forceVecGridXY(:,:,1).^2 + forceVecGridXY(:,:,2).^2).^0.5;
        tMap{FrameNumToBePlotted} = forceVecGridNorm;
        tMapX{FrameNumToBePlotted} = forceVecGridXY(:,:,1);
        tMapY{FrameNumToBePlotted} = forceVecGridXY(:,:,2);
        if useGPU
            grid_mat = gather(grid_mat);
            forceVecGridNorm = gather(forceVecGridNorm);
            XI = gather(XI);
            YI = gather(YI);
        end
        reg_gridFull(:,:,1)  = XI; reg_gridFull(:,:,2)  = YI;     
        [grid_mat_full, forceVecGridFullXY,~,~] = interp_vec2grid(forceFieldPos(:,1:2),forceFieldVec(:,1:2) ,[], reg_gridFull, InterpolationMethod);
        forceHeatMapX = forceVecGridFullXY(:,:,1);
        forceHeatMapY = forceVecGridFullXY(:,:,2);
        forceHeatMap = (forceHeatMapX.^2 + forceHeatMapY.^2).^0.5;              % Find the norm
%         Padding Step with 0s 
%         forceHeatMapPadded = zeros(ImageSizePixels);                    % Added on 2019-10-13
%         forceHeatMapXPadded = zeros(ImageSizePixels);                    % Added on 2019-10-13
%         forceHeatMapYPadded = zeros(ImageSizePixels);                    % Added on 2019-10-13
%         forceHeatMapPadded(Xmin:Xmax,Ymin:Ymax) = forceHeatMap;      
        figHandle1_3 = figure('color', 'w');
        set(figHandle1_3, 'Position', [275, 235, 825, 575])
%         surf(pos_grid_plotted(:,:,1), pos_grid_plotted(:,:,2), stress_grid_plotted(:,:,3))
        surf(XI, YI, forceHeatMap)
        axis square
%         view(2);% Show from above (XY view)
        xlim([0, movieData.imSize_(1)]); ylim([0, movieData.imSize_(2)]);    
        set(gca, 'ydir', 'reverse', 'Box', 'on')
        shading interp
        colormap(fake_parula(2^ImageBits));
        colorbarHandle = colorbar;
        colorbarLimits = get(colorbarHandle, 'Limits');
        colorbarTicks = unique(sort([colorbarLimits, colorbarHandle.Ticks]));               % updated on 2019-10-23 to make sure points are unique
        set(colorbarHandle, 'Ticks', colorbarTicks, 'TickDirection', 'out', ...
            'FontWeight', 'bold', 'FontName', 'Helvetica', 'LineWidth', 1);     % font size, 1/100 of height in pixels        
        ylabel(colorbarHandle, 'Traction Stress_{Net} [Pa]')
        set(colorbarHandle, 'FontWeight', 'bold')
    %     caxis([-0.1, 0.1])                                % standardize it for all plots
        titleStr1_4 = sprintf('Frame %d/%d. Full Size. Traction Stress Grid 3D - %s - %s', FrameNumToBePlotted, LastFrame, InterpolationMethod);
        titleStr1_5 = sprintf('F_{x} = %0.3g, F_{y}=%0.3g, F_{net}=%0.3g N.',TractionForceX(FrameNumToBePlotted),TractionForceY(FrameNumToBePlotted),TractionForce(FrameNumToBePlotted));
        title({titleStr1_4, titleStr1_2, titleStr1_5})
    %     zlim([-1, 1])                                  % standardize it for all plots.
        xlabel('X [pixels]'), ylabel('Y [pixels]'), zlabel('Traction Stress_{net} [Pa]')                 % note, it is reversed since surf() uses meshgrid() vs. griddata use ndgrid()
        set(gca, 'FontWeight', 'bold')    
        hold on,  plot3(forceFieldPos(:,1), forceFieldPos(:,2), forceFieldVec(:,3), 'o', 'MarkerSize', 2, 'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'r')

    %--- Plot tractions  components in 2D -----------------------------------------------------------------
        figHandle1_4 = figure('color', 'w');
        set(figHandle1_4, 'Position', [375, 335, 825, 575])
        %-----------------------
    %     imagesc(curr_ImageAdjust);
    %     colormap(TxRedColorMap);
    %     hold on   
    %     quiver(pos_grid_plotted(:,:,1), pos_grid_plotted(:,:,2), stress_grid_plotted(:,:,1), stress_grid_plotted(:,:,2), 'g')
        imagesc(unique(pos_grid_plotted(:,:,1)), unique(pos_grid_plotted(:,:,2)), stress_grid_plotted(:,:,3)')
        axis square
        xlim([0, movieData.imSize_(1)]); ylim([0, movieData.imSize_(2)]);
        xlabel('X [pixels]'), ylabel('Y [pixels]')
        set(gca, 'FontWeight', 'bold')        
        colormap(fake_parula(2^ImageBits));
        colorbarHandle = colorbar;
        ylabel(colorbarHandle, 'Traction Stress_{Net} [Pa]')
        set(colorbarHandle, 'FontWeight', 'bold')
        hold on   
        quiver(pos_grid_plotted(:,:,1), pos_grid_plotted(:,:,2), stress_grid_plotted(:,:,1), stress_grid_plotted(:,:,2), 'w','LineWidth', 0.5, 'AutoScale', 'on', 'AutoScaleFactor', 1.0)    
        % no need to reverse if image() or imagesc() is used. The ydir is reversed. 
        titleStr1_6 = sprintf('Frame %d/%d. Traction Components - %s - %s', FrameNumToBePlotted, LastFrame, InterpolationMethod);
        title({titleStr1_6, titleStr1_2, titleStr1_5});
    end
    
    %% Saving Plots
    disp('**___to continue, type "dbcont" or press "F5", or click "Continue" under "Editor" Menu___**')
    keyboard
    
    % --------- Saving the output files to the desired file format.   
    for CurrentPlotType = 1:numel(PlotChoice)
        tmpPlotChoice =  PlotChoice{CurrentPlotType};
        switch tmpPlotChoice
            case 'FIG'
                if exist(AnalysisPath,'dir') 
                    AnalysisFileNameFIG1 = 'Traction Force_All Components.fig';
                    AnalysisTractionForceFIG1 = fullfile(AnalysisPath, AnalysisFileNameFIG1);                    
                    savefig(figHandleAllTraction, AnalysisTractionForceFIG1,'compact')    
                    
                    AnalysisFileNameFIG2 = 'Traction Force_Net Only.fig';               
                    AnalysisTractionForceFIG2 = fullfile(AnalysisPath, AnalysisFileNameFIG2);                    
                    savefig(figHandleNetOnlyTraction, AnalysisTractionForceFIG2,'compact')

                    AnalysisFileNameFIG3 = 'Traction Energy Stored.fig';               
                    AnalysisTractionForceFIG3 = fullfile(AnalysisPath, AnalysisFileNameFIG3);                    
                    savefig(figHandleEnergy, AnalysisTractionForceFIG3,'compact')                    
                    
                    if strcmpi(DCchoice, 'Yes')
                        AnalysisFileNameFIG = 'P-Value ANOVA T-Test.fig';               
                        AnalysisP_ValFIG = fullfile(AnalysisPath, AnalysisFileNameFIG);                    
                        savefig(figANOVA_tTest, AnalysisP_ValFIG,'compact')                  

                        AnalysisFileNameFIG = 'Displacements of Corner ROIs.fig';               
                        ROIsDisplacementFIG = fullfile(AnalysisPath, AnalysisFileNameFIG);                    
                        savefig(figROIsDrift, ROIsDisplacementFIG,'compact') 
                    end
                end
                
            case 'PNG'                  % PNG SAVE. Consider replacing TIF to PNG.  %                 saveas(figFluxV, figureFileNames{2,1}, 'png');               
                if exist(AnalysisPath,'dir') 
                    AnalysisFileNamePNG1 = 'Traction Force All Components.png';
                    AnalysisTractionForcePNG1 = fullfile(AnalysisPath, AnalysisFileNamePNG1);
                    saveas(figHandleAllTraction, AnalysisTractionForcePNG1, 'png');
                    
                    AnalysisFileNamePNG2 = 'Traction Force_Net Only.png';
                    AnalysisTractionForcePNG2 = fullfile(AnalysisPath, AnalysisFileNamePNG2);
                    saveas(figHandleNetOnlyTraction, AnalysisTractionForcePNG2, 'png');
                    
                    AnalysisFileNamePNG3 = 'Traction Energy Stored.png';
                    AnalysisTractionForcePNG3 = fullfile(AnalysisPath, AnalysisFileNamePNG3);
                    saveas(figHandleEnergy, AnalysisTractionForcePNG3, 'png');                    
                    
                    if strcmpi(DCchoice, 'Yes')
                        AnalysisFileNamePNG = 'P-Value ANOVA T-Test.png';
                        AnalysisP_ValPNG = fullfile(AnalysisPath, AnalysisFileNamePNG);
                        saveas(figANOVA_tTest, AnalysisP_ValPNG, 'png');

                        AnalysisFileNamePNG = 'Displacements of Corner ROIs.png';     
                        ROIsDisplacementPNG = fullfile(AnalysisPath, AnalysisFileNamePNG);
                        saveas(figROIsDrift, ROIsDisplacementPNG, 'png');
                    end
                end                
            case 'EPS'
                if exist(AnalysisPath,'dir') 
                    AnalysisFileNameEPS1 = 'Traction Force All Components.eps';                
                    AnalysisTractionForceEPS1 = fullfile(AnalysisPath, AnalysisFileNameEPS1);                                     
                    print(figHandleAllTraction, AnalysisTractionForceEPS1,'-depsc')
%                     exportfig(figHandleAllTraction, AnalysisTractionForceEPS1, 'Bounds', EPSparam.Bounds, 'Color', EPSparam.Color, ...
%                         'Renderer', EPSparam.Renderer, 'Resolution', EPSparam.Resolution, 'LockAxes', EPSparam.LockAxes, 'FontMode', EPSparam.FontMode, ...
%                         'FontSize', EPSparam.FontSize, 'FontEncoding', EPSparam.FontEncoding, 'LineMode', EPSparam.LineMode, 'LineWidth', EPSparam.LineWidth)
                    
                    AnalysisFileNameEPS2 = 'Traction Force_Net Only.eps';             
                    AnalysisTractionForceEPS2 = fullfile(AnalysisPath, AnalysisFileNameEPS2);                                     
                    print(figHandleNetOnlyTraction, AnalysisTractionForceEPS2,'-depsc')

                    AnalysisFileNameEPS3 = 'Traction Energy Stored.eps';             
                    AnalysisTractionForceEPS3 = fullfile(AnalysisPath, AnalysisFileNameEPS3);                                     
                    print(figHandleEnergy, AnalysisTractionForceEPS3,'-depsc')                    
                    
                    if strcmpi(DCchoice, 'Yes')
                        AnalysisFileNameEPS = 'P-Value ANOVA T-Test.eps';             
                        AnalysisP_ValEPS = fullfile(AnalysisPath, AnalysisFileNameEPS);                                     
                        print(figANOVA_tTest, AnalysisP_ValEPS,'-depsc')

                        AnalysisFileNameEPS = 'Displacements of Corner ROIs.eps';      
                        ROIsDisplacementEPS = fullfile(AnalysisPath, AnalysisFileNameEPS);                                     
                        print(figROIsDrift, ROIsDisplacementEPS,'-depsc')
                    end
                end
            otherwise
                 return
        end
    end
    
    switch FrameDisplMeanChoice
        case 'Yes'  
            for CurrentPlotType = 1:numel(PlotChoice)
                tmpPlotChoice =  PlotChoice{CurrentPlotType};
                switch tmpPlotChoice
                    case 'PNG'                  % PNG SAVE. Consider replacing TIF to PNG.  %                 saveas(figFluxV, figureFileNames{2,1}, 'png');
                        if exist(AnalysisPath,'dir') 
                            AnalysisFileNamePNG1 = '11 Displacement All.png';                    
                            AnalysisDisplacementForcePNG1 = fullfile(AnalysisPath, AnalysisFileNamePNG1);
                            saveas(figHandleAllDisplacement, AnalysisDisplacementForcePNG1);

                            AnalysisFileNamePNG2 = '11 Displacement Net.png';                    
                            AnalysisDisplacementForcePNG2 = fullfile(AnalysisPath, AnalysisFileNamePNG2);
                            saveas(figHandleNetOnlyDisplacement, AnalysisDisplacementForcePNG2);                                
                        end

                    case 'FIG'
                        if exist(AnalysisPath,'dir') 
                            AnalysisFileNameFIG1 = '11 Displacement All.fig';                    
                            AnalysisDisplacementForceFIG1 = fullfile(AnalysisPath, AnalysisFileNameFIG1);                    
                            savefig(figHandleAllDisplacement, AnalysisDisplacementForceFIG1,'compact')    

                            AnalysisFileNameFIG2 = '11 Displacement Net.fig';                  
                            AnalysisDisplacementForceFIG2 = fullfile(AnalysisPath, AnalysisFileNameFIG2);                    
                            savefig(figHandleNetOnlyDisplacement, AnalysisDisplacementForceFIG2,'compact')                        
                        end

                    case 'EPS'
                        if exist(AnalysisPath,'dir') 
                            AnalysisFileNameEPS1 = '11 Displacement All.eps';                    
                            AnalysisDisplacementForceEPS1 = fullfile(AnalysisPath, AnalysisFileNameEPS1);                                     
                            print(figHandleAllDisplacement, AnalysisDisplacementForceEPS1,'-depsc')

                            AnalysisFileNameEPS2 = '11 Displacement Net.eps';                    
                            AnalysisDisplacementForceEPS2 = fullfile(AnalysisPath, AnalysisFileNameEPS2);                                     
                            print(figHandleNetOnlyDisplacement, AnalysisDisplacementForceEPS2,'-depsc')                    
                        end
                    otherwise
                         return
                end
            end
    end
    
    if ~isempty(FrameNumToBePlotted)
        for CurrentPlotType = 1:numel(PlotChoice)
            tmpPlotChoice =  PlotChoice{CurrentPlotType};
            switch tmpPlotChoice
                case 'PNG'                  % PNG SAVE. Consider replacing TIF to PNG.  %                 saveas(figFluxV, figureFileNames{2,1}, 'png');
                  if exist(AnalysisPath,'dir') 
                    %__________ Saving individual frame heatmaps
                    disp_grid_plotted_fileName1_1_1 = 'Displacement Net Grid 3D Not Filtered.png';
                    saveas(figHandle1_1_1,  fullfile(AnalysisPath,disp_grid_plotted_fileName1_1_1),'png')   

                    iu_mat_original_fileName1_2_1 = 'Displacement XY Grid Quivers Filtered Original.png';
                    saveas(figHandle1_2_1, fullfile(AnalysisPath,iu_mat_original_fileName1_2_1),'png')    
                    
                    disp_grid_plotted_fileName1_1_2 = 'Displacement Net Grid 3D Filtered.png';
                    saveas(figHandle1_1_2,  fullfile(AnalysisPath,disp_grid_plotted_fileName1_1_2),'png')
                   
                    iu_mat_original_fileName1_3 = 'Traction Net Grid 3D.png';
                    saveas(figHandle1_3, fullfile(AnalysisPath, iu_mat_original_fileName1_3),'png')    

                    iu_mat_original_fileName1_4 = 'Traction XY Grid Quivers.png';
                    saveas(figHandle1_4, fullfile(AnalysisPath, iu_mat_original_fileName1_4),'png')
                  end

                case 'FIG'     
                  if exist(AnalysisPath,'dir') 
                    %__________ Saving individual frame heatmaps
                    disp_grid_plotted_fileName1_1_1 = 'Displacement Net Grid 3D Not Filtered.fig';
                    savefig(figHandle1_1_1,  fullfile(AnalysisPath,disp_grid_plotted_fileName1_1_1),'compact')   

                    iu_mat_original_fileName1_2_1 = 'Displacement XY Grid Quivers Filtered Original.fig';
                    savefig(figHandle1_2_1, fullfile(AnalysisPath,iu_mat_original_fileName1_2_1),'compact')
                    
                    disp_grid_plotted_fileName1_1_2 = 'Displacement Net Grid 3D Filtered.fig';
                    savefig(figHandle1_1_2,  fullfile(AnalysisPath,disp_grid_plotted_fileName1_1_2),'compact')   

                    iu_mat_original_fileName1_3 = 'Traction Net Grid 3D.fig';
                    savefig(figHandle1_3, fullfile(AnalysisPath, iu_mat_original_fileName1_3),'compact')    

                    iu_mat_original_fileName1_4 = 'Traction XY Grid Quivers.fig';
                    savefig(figHandle1_4, fullfile(AnalysisPath, iu_mat_original_fileName1_4),'compact')
                  end
                case 'EPS'
                  if exist(AnalysisPath,'dir') 
                    %__________ Saving individual frame heatmaps
                    disp_grid_plotted_fileName1_1_1 = 'Displacement Net Grid 3D Not Filtered.eps';
                    print(figHandle1_1_1,  fullfile(AnalysisPath,disp_grid_plotted_fileName1_1_1),'-depsc')   

                    
                    
                    iu_mat_original_fileName1_2_1 = 'Displacement XY Grid Quivers Filtered Original.eps';
                    print(figHandle1_2_1, fullfile(AnalysisPath,iu_mat_original_fileName1_2_1),'-depsc')    

                    
                    
                    disp_grid_plotted_fileName1_1_2 = 'Displacement Net Grid 3D Filtered.eps';
                    print(figHandle1_1_2,  fullfile(AnalysisPath,disp_grid_plotted_fileName1_1_2),'-depsc')   

                    
                    
                    iu_mat_original_fileName1_3 = 'Traction Net Grid 3D.eps';
                    print(figHandle1_3, fullfile(AnalysisPath, iu_mat_original_fileName1_3),'-depsc')    

                    
                    
                    iu_mat_original_fileName1_4 = 'Traction XY Grid Quivers.eps';
                    print(figHandle1_4, fullfile(AnalysisPath, iu_mat_original_fileName1_4),'-depsc')
                  end
                otherwise
                    return
            end
        end
    end
    
    
        % ---------------------------------------------------------------------------------------
    disp('Traction Force Plots over time have been Generating! Process Complete!')