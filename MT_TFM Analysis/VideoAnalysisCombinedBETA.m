%{
    v.2020-09-27 by Waddah Moghram
        1. Updated to reflecct the latest updates in file structures
        2. ForceFieldParameters is not output since we do not run the 3rd step in the TFM Package code.
    v.2020-04-05 by Waddah Moghram
        1. Fixed errro that plots energy in Displacement mode.
    v.2020-03-11..12 by Waddah Moghram
        1. Added combined plot of energy (in units of FemtoNewtons)
    v.2020-02-25 by Waddah moghram
        1. Allowed to plot Controlled-Displacement Force
    v.2020-02-10 by Waddah Moghram
        1. Did away with reading cleaned sensor data. Need to re-run TimestampRTfromSensorData.m
        2. Now plots can be mapped directly for the sensor signals for a controlled-force experiment.
    v.2020-01-26 by Waddah Moghram
        1. Removed 'InclinationAngleDegrees' from input and output.
    v.2020-01-20 by Waddah Moghram
        1. Allow for controlled displacement mode as well. Only align displacements.
        2. Fixed to save also the control mode to the output
        3. Renamed output file to be "MT vs TFM Combined Data.mat"
    v.2020-01-17 by Waddah Moghram
        1. Fixed plots, changed units to nN instead of N.
    v.2019-10-14 by Waddah Moghram
        1. Updated the plot to include other details about the gel in the final output
        2. Bypassed MD file, and instead load the forcefield parameters directly from the output file.
    v.2019-10-07 by Waddah Moghram
        Run this code after you have run VideoAnalysisEPI.m and VideoAnalysisDIC.m 
        this code will read both output files, sensor files and merge both plots into a single plot.
%}

%% =============================== Part 3: Combined MT-TFM ANALYSIS =================================
    PlotsFontName = 'XITS';
    ConversionNtoNN = 1e9;
    ConversionJtoFemtoJ = 1e15;
    
%% ================= 0 Select the experiment mode: Controlled Force vs. Controlled Displacement
    dlgQuestion = 'What is the control mode for DIC experiment? ';
    dlgTitle = 'Control Mode?';
    controlMode = questdlg(dlgQuestion, dlgTitle, 'Controlled Force', 'Controlled Displacement', 'Controlled Force');
    if isempty(controlMode), error('Choose a control mode'); end
       
    dlgQuestion = 'Select lots Format';
    listStr = {'PNG', 'FIG', 'EPS'};
    PlotChoiceIndex = listdlg('ListString', listStr, 'PromptString',dlgQuestion, 'InitialValue', [1,2], 'SelectionMode' ,'multiple');    
    PlotChoice = listStr(PlotChoiceIndex);                 % get the names of the string.   
    
    switch controlMode
        case 'Controlled Displacement'
            dlgQuestion = 'Was DIC control sequence ahead of the EPI control sequence? ';
            dlgTitle = 'DIC first?';
            DIC_firstSeq = questdlg(dlgQuestion, dlgTitle, 'DIC First', 'EPI First', 'DIC First');
            if isempty(DIC_firstSeq), error('Need to indicate which one is first');  end
            switch DIC_firstSeq
                case 'DICFirst'
                    DIC_first = 1;
                case 'EPI First'
                    DIC_first = 0;
            end
            TimeLagInSecondsStr = inputdlg('What was the time lag (in seconds) between the sequences?');
            TimeLagInSeconds = str2double(TimeLagInSecondsStr{1});
            
            [DisplFileDICname, DisplFileDICpath] = uigetfile('*.mat', 'Open the DIC ''03 NetDisplacement_DIC_Time.mat'' file. Under DIC Tracking Output');
            if DisplFileDICname == 0, return; end
            DisplFileDICFullName = fullfile(DisplFileDICpath, DisplFileDICname);
            try 
                DisplDICvariables = load(DisplFileDICFullName);
                fprintf('DIC Magnetic Tweezer Net Displacement File is file is: \n\t %s\n', DisplFileDICFullName);
                disp('------------------------------------------------------------------------------')
            catch 
                errordlg('Could not open the MT Bead Net Displacement file!')
                return
            end
            
            [CleanedupTimeStampsFileDICname, CleanedupTimeStampsFileDICpath] = uigetfile(fullfile(fullfile(DisplFileDICpath, '..'),'*.mat'), 'Open the DIC Cleaned-up Timestamps ND2 *.mat file');
            if CleanedupTimeStampsFileDICname == 0, return; end
            CleanedupTimeStampsFileDIC = fullfile(CleanedupTimeStampsFileDICpath, CleanedupTimeStampsFileDICname);
            try 
                CleanedUpTimeStampsDICvariables= load(CleanedupTimeStampsFileDIC);
                fprintf('Cleaned-up Sensor Data File is file is: \n\t %s\n', CleanedupTimeStampsFileDIC);
                disp('------------------------------------------------------------------------------')
            catch 
                errordlg('Could not open the clean-up timestamps data file!')
                return
            end    
            
            [DisplFileEPIname, DisplFileEPIpath] = uigetfile(fullfile(fullfile(DisplFileDICpath, '..'),'*.mat'), 'Open the '' Net Displacement_TxRed_max''  file. Under TFM Package Corrected Displacement Folder');
            if DisplFileEPIname == 0, return; end
            DisplFileEPIFullName = fullfile(DisplFileEPIpath, DisplFileEPIname);
            try 
                DisplEPIvariables = load(DisplFileEPIFullName);
                fprintf('EPI TFM Traction MAX Net Displacement File is file is: \n\t %s\n', DisplFileEPIFullName);
                disp('------------------------------------------------------------------------------')
            catch 
                errordlg('Could not open the max net displacement file!')
                return
            end
            
            [CleanedupTimeStampsFileEPIname, CleanedupTimeStampsFileEPIpath] = uigetfile(fullfile(CleanedupTimeStampsFileDICpath,'*.mat'), 'Open the EPI Cleaned-up Timestamps ND2 *.mat file');
            if CleanedupTimeStampsFileEPIname == 0, return; end
            CleanedupTimeStampsFileEPI = fullfile(CleanedupTimeStampsFileEPIpath, CleanedupTimeStampsFileEPIname);
            try 
                CleanedUpTimeStampsEPIvariables = load(CleanedupTimeStampsFileEPI);
                fprintf('Cleaned-up Sensor Data File is file is: \n\t %s\n', CleanedupTimeStampsFileEPI);
                disp('------------------------------------------------------------------------------')
            catch 
                errordlg('Could not open the clean-up timestamps data file!')
                return
            end          
            
        case  'Controlled Force'
            %____________ DIC RT Timestamps
            [CleanedupTimeStampsFileDICname, CleanedupTimeStampsFileDICpath] = uigetfile(pwd, 'DIC Timestamps RT *.mat');
            if CleanedupTimeStampsFileDICname == 0, return; end
            CleanedupTimeStampsFileDIC = fullfile(CleanedupTimeStampsFileDICpath, CleanedupTimeStampsFileDICname);
            try 
                CleanedUpTimeStampsDICvariables = load(CleanedupTimeStampsFileDIC);
                fprintf('DIC RT Timestamps file is: \n\t %s\n', CleanedupTimeStampsFileDIC);
                disp('------------------------------------------------------------------------------')
            catch 
                errordlg('Could not open the clean-up timestamps data file!')
                return
            end
            %____________ DIC Displacement (MAG BEAD)
            [DisplFileDICname, DisplFileDICpath] = uigetfile(fullfile(CleanedupTimeStampsFileDICpath,'*.mat'), '''03 NetDisplacement_DIC***.mat'' file__Under DIC Tracking Output');
            if DisplFileDICname == 0, return; end
            DisplFileDICFullName = fullfile(DisplFileDICpath, DisplFileDICname);
            try 
                DisplDICvariables = load(DisplFileDICFullName);
                fprintf('DIC Magnetic Tweezer Net Displacement File is file is: \n\t %s\n', DisplFileDICFullName);
                disp('------------------------------------------------------------------------------')
            catch 
                errordlg('Could not open the MT Bead Net Displacement file!')
                return
            end
            %____________ MT FORCE
            [ForceFileDICname, ForceFileDICpath] = uigetfile(fullfile(DisplFileDICpath,'*.mat'), '''05 Force Compiled Results.mat''__under DIC tracking output');
            if ForceFileDICname == 0, return; end
            ForceFileDICFullName = fullfile(ForceFileDICpath, ForceFileDICname);
            try 
                ForceDICvariables = load(ForceFileDICFullName);
                fprintf('DIC Magnetic Tweezer Force File is file is: \n\t %s\n', ForceFileDICFullName);
                disp('------------------------------------------------------------------------------')
            catch 
                errordlg('Could not open the MT force file!')
                return
            end
            
            %____________ EPI RT Timestamps
            [CleanedupTimeStampsFileEPIname, CleanedupTimeStampsFileEPIpath] = uigetfile(fullfile(CleanedupTimeStampsFileDICpath,'*.mat'), 'EPI Timestamps RT *.mat');
            if CleanedupTimeStampsFileEPIname == 0, return; end
            CleanedupTimeStampsFileEPI = fullfile(CleanedupTimeStampsFileEPIpath, CleanedupTimeStampsFileEPIname);
            try 
                CleanedUpTimeStampsEPIvariables = load(CleanedupTimeStampsFileEPI);
                fprintf('EPI RT Timestamps file is: \n\t %s\n', CleanedupTimeStampsFileEPI);
                disp('------------------------------------------------------------------------------')
            catch 
                errordlg('Could not open the clean-up timestamps data file!')
                return
            end
            
            %____________ EPI Displacement (MAX RED BEAD)
            [DisplFileEPIname, DisplFileEPIpath] = uigetfile(fullfile(CleanedupTimeStampsFileEPIpath,'*.mat'), ''' Net Displacement_TxRed_max''__Under TFM Package Output');
            if DisplFileEPIname == 0, return; end
            DisplFileEPIFullName = fullfile(DisplFileEPIpath, DisplFileEPIname);
            try 
                DisplEPIvariables = load(DisplFileEPIFullName);
                fprintf('EPI TFM Traction MAX Net Displacement File is file is: \n\t %s\n', DisplFileEPIFullName);
                disp('------------------------------------------------------------------------------')
            catch 
                errordlg('Could not open the max net displacement file!')
                return
            end
    end
    % ____________ Traction FORCE
    [ForceFileEPIname, ForceFileEPIpath] = uigetfile(fullfile(DisplFileEPIpath,'*.mat'), '''Traction Force Averaged.mat''__Under TFM Package\ForceField');
    if ForceFileEPIname == 0, return; end
    ForceFileEPI = fullfile(ForceFileEPIpath, ForceFileEPIname);
    try 
        ForceEPIvariables = load(ForceFileEPI);
        fprintf('EPI TFM Traction Forces File is file is: \n\t %s\n', ForceFileEPI);
        disp('------------------------------------------------------------------------------')
    catch 
        errordlg('Could not open the traction forces file!')
        return
    end

     %% For EPI Parameters
%     [forceFieldParametersFile, forceFieldparametersPath] = uigetfile(fullfile(fullfile(ForceFileEPIpath, '..'),'*.mat'), ' open the forceFieldParameters.mat file');    
%     if forceFieldParametersFile==0
%         error('No file was selected');
%     end            
%     forceFieldParametersFullFileName = fullfile(forceFieldparametersPath, forceFieldParametersFile);   
%     forceFieldProcessStruct = load(forceFieldParametersFullFileName, 'forceFieldProc');
%     forceFieldCalculationInfo = forceFieldProcessStruct.forceFieldProc;
%     fprintf('forceField paramters successfully: \n\t %s \n', forceFieldParametersFullFileName)            
    
    DisplDIC_xy_Micron = DisplDICvariables.MagBeadDisplacementMicronXYBigDelta;
    DisplEPI_xy_Micron = DisplEPIvariables.TxRedBeadMaxNetDisplacementMicrons;
    
    %% Extract EPI Cleaned-up Sensors, Sampling Rate, First Exposure Pulse, and RT Timeframes
    switch controlMode
        case 'Controlled Displacement'
            if DIC_first == 1
                CleanedUpTimeStampsDICvariables.TimeStampsAbsoluteRT_Sec = CleanedUpTimeStampsDICvariables.TimeStampsND2  + TimeLagInSeconds;
                CleanedUpTimeStampsEPIvariables.TimeStampsAbsoluteRT_Sec =  CleanedUpTimeStampsDICvariables.TimeStampsND2;
            elseif DIC_first ==0
                CleanedUpTimeStampsEPIvariables.TimeStampsAbsoluteRT_Sec = CleanedUpTimeStampsEPIvariables.TimeStampsND2 + TimeLagInSeconds;
                CleanedUpTimeStampsDICvariables.TimeStampsAbsoluteRT_Sec = CleanedUpTimeStampsDICvariables.TimeStampsND2;
            else
                error('You need to specify if DIC or EPI mode is first')
            end
        case 'Controlled Force'
            [minExposurePulseIndex, DIC_first] = min([CleanedUpTimeStampsDICvariables.FirstExposurePulseIndex, CleanedUpTimeStampsEPIvariables.FirstExposurePulseIndex]);
            if DIC_first == 1
                disp('DIC video was captured earlier than the EPI video.')
                TimeLagInSeconds = (CleanedUpTimeStampsEPIvariables.FirstExposurePulseIndex - CleanedUpTimeStampsDICvariables.FirstExposurePulseIndex)/CleanedUpTimeStampsEPIvariables.SamplingRate;
%                 CleanedUpTimeStampsDICvariables.TimeStampsAbsoluteRT_Sec = CleanedUpTimeStampsDICvariables.TimeStampsRelativeRT_Sec;
%                 CleanedUpTimeStampsEPIvariables.TimeStampsAbsoluteRT_Sec = CleanedUpTimeStampsEPIvariables.TimeStampsRelativeRT_Sec + TimeLagInSeconds;
            elseif DIC_first ==0
                disp('EPI video was captured earlier than the DIC video.')
                TimeLagInSeconds = (CleanedUpTimeStampsDICvariables.FirstExposurePulseIndex - CleanedUpTimeStampsEPIvariables.FirstExposurePulseIndex)/CleanedUpTimeStampsDICvariables.SamplingRate;
%                 CleanedUpTimeStampsEPIvariables.TimeStampsAbsoluteRT_Sec = CleanedUpTimeStampsEPIvariables.TimeStampsRelativeRT_Sec;
%                 CleanedUpTimeStampsDICvariables.TimeStampsAbsoluteRT_Sec = CleanedUpTimeStampsDICvariables.TimeStampsRelativeRT_Sec  + TimeLagInSeconds;
            else
                error('Incorrect FirstExposurePulseIndex for either DIC or EPI mode')
            end
%         CleanedUpTimeStampsEPIvariables.TimeStampsAbsoluteRT_Sec =  CleanedUpTimeStampsDICvariables.TimeStampsRelativeRT_Sec +  
    end
    
    %% Compiling the forces in N
    switch controlMode
        case 'Controlled Displacement'
            LastFramePlotted = min([size(CleanedUpTimeStampsEPIvariables.TimeStampsAbsoluteRT_Sec, 1), size(CleanedUpTimeStampsDICvariables.TimeStampsAbsoluteRT_Sec, 1), ...
                size(DisplDIC_xy_Micron, 1),size(DisplEPI_xy_Micron, 1) ]);
            TimeXlimSec = max(CleanedUpTimeStampsDICvariables.TimeStampsAbsoluteRT_Sec(LastFramePlotted), CleanedUpTimeStampsEPIvariables.TimeStampsAbsoluteRT_Sec(LastFramePlotted));
            ForceEPI_xy_N = ForceEPIvariables.ForceN;               % already in N
            FramesPlottedNumbers = 1:LastFramePlotted;
            FramesPlottedBooleans = ~isnan(ForceEPI_xy_N(1:LastFramePlotted));
      
        case 'Controlled Force'
            % Calibrated forces in MT are in nN while those generated through traction forces are in N.
            try
                ForceDIC_xy_N = ForceDICvariables.CompiledDataStruct.Force_xy / ConversionNtoNN;
            catch
                ForceDIC_xy_N = ForceDICvariables.Force_xy / ConversionNtoNN;
            end
%             ForceEPI_xy_N = ForceEPIvariables.TractionForce;               % already in nN    
            ForceEPI_xy_N = ForceEPIvariables.ForceN;               % already in N
            LastFramePlotted = min([size(CleanedUpTimeStampsEPIvariables.TimeStampsAbsoluteRT_Sec, 1), size(CleanedUpTimeStampsDICvariables.TimeStampsAbsoluteRT_Sec, 1), size(ForceEPI_xy_N, 1), size(ForceDIC_xy_N,1)]);
            TimeXlimSec = max(CleanedUpTimeStampsDICvariables.TimeStampsAbsoluteRT_Sec(LastFramePlotted), CleanedUpTimeStampsEPIvariables.TimeStampsAbsoluteRT_Sec(LastFramePlotted));
            FramesPlottedNumbers = 1:LastFramePlotted;
            FramesPlottedBooleans = ~isnan(ForceEPI_xy_N(1:LastFramePlotted));
    end

    %% ================= 2.0 open the movie details and try to get all other parametes for further process.
%  %% ------------------------------------------------------------------------------------------
%     dlgQuestion = 'Do you want open the TFM package movie *.mat file?';
%     dlgTitle = 'Movie Data *.mat file?';
%     choiceMovieData = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No', 'Yes');
%     switch choiceMovieData    
%         case 'Yes'
% %             disp('Opening the Epi ND2 Video File to get path and filename info to be analyzed')
%             [MDfile, MDpath] = uigetfile(fullfile(CleanedUpFileEPIpath, '*.mat'), 'Open the *.mat movie data file');    
%             if MDfile==0
%                 error('No file was selected');
%             end            
%             MDfullFileName = fullfile(MDpath, MDfile);   
%             load(MDfullFileName, 'MD')
%             fprintf('Movie data loaded successfully: \n\t %s \n', MDfullFileName)
%             disp('----------------------------------------------------------------------------')            
%         case 'No'
%             % keep going
%         otherwise
%             error('Could not open *.nd2 file');
%     end
%     
%     try 
%         ProcessTag =  MD.findProcessTag('ForceFieldCalculationProcess').tag_;
%     catch
%         ProcessTag = '';
%         disp('No Completed "Force" Field Calculated!');
%         disp('------------------------------------------------------------------------------')
%     end
%     %------------------
%     if exist('ProcessTag', 'var') 
%         fprintf('"Force" Process Tag is: %s\n', ProcessTag);
%         try
%             ForceFileFullName = MD.findProcessTag(ProcessTag).outFilePaths_{1};
%             if exist(ForceFileFullName, 'file')
%                 dlgQuestion = sprintf('Do you want to open the "force" field referred to in the movie data file?\n\n%s\n', ...
%                     ForceFileFullName);
%                 dlgTitle = 'Open "force" field (forceField.mat) file?';
%                 OpenForceChoice = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No', 'Yes');
%                 switch OpenForceChoice
%                     case 'Yes'
%                         [forceFilePath, ~, ~] = fileparts(ForceFileFullName);
%                     case 'No'
%                         ForceFileFullName = [];
%                     otherwise
%                         return
%                 end            
%             else
%                 ForceFileFullName = [];
%             end
%         catch
%             ForceFileFullName = [];
%         end
%     end
%     %------------------
%     if isempty(ForceFileFullName) || ~exist('ProcessTag', 'var')
%             TFMPackageFiles = fullfile(ForceFileEPIpath,'TFMPackage','*.mat');
%             [forceFileName, forceFilePath] = uigetfile(TFMPackageFiles, 'Open the "force" field (forceField.mat) under forceField or backups');
%             if forceFileName ==  0, return; end
%             ForceFileFullName = fullfile(forceFilePath, forceFileName);
%     end    
%     %------------------       
%     try
%         load(ForceFileFullName, 'forceField');   
%         fprintf('"Force" Field (forceField.mat) File is successfully loaded! \n\t %s\n', ForceFileFullName);
%         disp('------------------------------------------------------------------------------')
%     catch
%         errordlg('Could not open the "force" field file.');
%         return
%     end
%     
   
    %%
    if ~exist('CleanedupTimeStampsFileDICpath','var'), CleanedupTimeStampsFileDICpath = pwd; end
    CombinedAnalysisPath = uigetdir(CleanedupTimeStampsFileDICpath, 'Choose the analysis directory where the combined MT-TFM analysis is saved.');    
    if CombinedAnalysisPath == 0, return; end
    if ~exist(CombinedAnalysisPath,'dir')   % Check for a directory
        mkdir(CombinedAnalysisPath);
    end
    CombinedAnalysisFileName = sprintf('11 MT vs TFM Combined data.mat');
    CombinedAnalysisFullFileName = fullfile(CombinedAnalysisPath, CombinedAnalysisFileName);
    save(CombinedAnalysisFullFileName, 'CleanedUpTimeStampsDICvariables', 'CleanedUpTimeStampsEPIvariables', 'CleanedUpTimeStampsDICvariables', ...
       'CleanedUpTimeStampsEPIvariables',  'DIC_first',  'TimeLagInSeconds', 'controlMode',  '-v7.3')
    switch controlMode
       case 'Controlled Force'
           save( CombinedAnalysisFullFileName, 'ForceDIC_xy_N', 'ForceEPI_xy_N', 'LastFramePlotted', 'TimeXlimSec', '-append')    % 'forceFieldProcessStruct'
    end
    
    %%
    GelConcentrationMgMl = input('What was the gel concentration in mg/mL? ');              
    %---------------------------------------------
%     try
%         thickness_um = forceFieldCalculationInfo.funParams_.thickness_nm/1000;
%     catch
%         thickness_um = forceFieldCalculationInfo.funParams_.thickness/1000;
%     end
    thickness_um = 760;
    if isempty(thickness_um)
        thickness_um = input('What was the gel thickness in microns? ');  
        fprintf('Gel thickness is %d  microns. \n', thickness_um);
    else
        prompt = sprintf('Gel''s thickness in microns found is %g Pa. Use it? \n', thickness_um); 
        dlgTitle = 'Elastic Modulus Used';
        thickness_umDefault = {num2str(thickness_um)};
        thickness_umStr = inputdlg(prompt, dlgTitle, [1, 60], thickness_umDefault);
        if isempty(thickness_umStr), return; end
        thickness_um = str2double(thickness_umStr{:});
    end
    %----------------------------------------------
%     try
%         YoungModulusPa = forceFieldCalculationInfo.funParams_.YoungModulus;
%     catch
%         YoungModulusPa = [];
%     end
    YoungModulusPa = 100;
    if isempty(YoungModulusPa)
        YoungModulusPa = input('What was the gel''s Young Elastic modulus (in Pa)? ');  
        fprintf('Gel''s elastic modulus (E) is %g  Pa. \n', YoungModulusPa);
    else
        prompt = sprintf('Gel''s elastic modulus (E) found is %g  Pa. Use it? \n', YoungModulusPa); 
        dlgTitle = 'Elastic Modulus Used';
        YoungModulusPaDefault = {num2str(YoungModulusPa)};
        YoungModulusPaStr = inputdlg(prompt, dlgTitle, [1, 60], YoungModulusPaDefault);
        if isempty(YoungModulusPaStr), return; end
        YoungModulusPa = str2double(YoungModulusPaStr{:});
    end
    %----------------------------------------------
%     try
%         PoissonRatio = forceFieldCalculationInfo.funParams_.PoissonRatio;
%     catch
%         PoissonRatio = [];
%     end
    PoissonRatio = 0.4;
    if isempty(PoissonRatio)
        PoissonRatio = input('What was the gel''s Poisson Ratio? ');  
        fprintf('Gel''s Poisson Ratio (nu) is %g. \n', PoissonRatio);
    else
        prompt = sprintf('Gel''s poisson ratio (nu) is %g. Use it? \n', PoissonRatio); 
        dlgTitle = 'Poisson Ratio Used';
        PoissonRatioDefault = {num2str(PoissonRatio)};
        PoissonRatioStr = inputdlg(prompt, dlgTitle, [1, 60], PoissonRatioDefault);
        if isempty(PoissonRatioStr), return; end
        PoissonRatio = str2double(PoissonRatioStr{:});  
    end
    %----------------------------------------------
    try 
        save(CombinedAnalysisFullFileName, 'GelConcentrationMgMl', 'thickness_um', 'YoungModulusPa', 'PoissonRatio',  '-append');          % Modified by WIM on 2/5/2019
    catch
        % Do nothing
    end
    
    %% ----------------------------------------------
%     titleStr1 = strcat(sprintf('Traction Force_{TFM} vs. Force_{MT}. Needle Inclination angle = %g', InclinationAngleDegrees), char(176));   
%     titleStr2 = sprintf('for %.0f', thickness_um);
%     titleStr2 = strcat(titleStr2, '\mum-thick,');
%     titleStr2 = strcat(titleStr2, sprintf('%.1f mg/mL type I collagen gel', GelConcentrationMgMl));
%     titleStr3 = sprintf('Young Moudulus = %.1f Pa. Poisson Ratio = %.2f', YoungModulusPa, PoissonRatio);
%     titleStr   = {titleStr1, titleStr2, titleStr3};        
    titleStr = sprintf('%.0f \\mum-thick, %.1f mg/mL type I collagen gel. \\itE \\rm\\bf= %g Pa', thickness_um, GelConcentrationMgMl, YoungModulusPa);
    %% ---Plot MT Force (Controlled-force case) vs. TFM Force against either other
    showPlot = 'on';
    ConversionNNtoN = 1e9;               % from N to n
    save(CombinedAnalysisFullFileName,'ConversionNNtoN', '-append')

% 1. ___________ Plot Displacements
    figHandleForce = figure('visible',showPlot, 'color', 'w');     % added by WIM on 2019-02-07. To show, remove 'visible
    switch controlMode
        case 'Controlled Force'
            plot(CleanedUpTimeStampsDICvariables.TimeStampsAbsoluteRT_Sec(FramesPlottedBooleans), ConversionNNtoN* ForceDIC_xy_N(FramesPlottedBooleans), ...
        'b.-',  'LineWidth', 1, 'MarkerSize', 2)
    end
    hold on 
%             plot(CleanedUpTimeStampsEPIvariables.TimeStampsAbsoluteRT_Sec(FramesPlotted), ConversionNNtoN .* ForceEPI_xy_N(FramesPlotted), ...
%                 'r.-',  'LineWidth', 1, 'MarkerSize', 2)
    plot(CleanedUpTimeStampsEPIvariables.TimeStampsAbsoluteRT_Sec(FramesPlottedNumbers), ConversionNNtoN .* ForceEPI_xy_N(FramesPlottedNumbers), ...
        'r.-',  'LineWidth', 1, 'MarkerSize', 2)    
    xlim([0, TimeXlimSec]);
    set(findobj(gcf,'type', 'axes'), ...
        'FontSize',11, ...
        'FontName', 'Helvetica', ...
        'LineWidth',1, ...
        'XMinorTick', 'on', ...
        'YMinorTick', 'on', ...
        'TickDir', 'out', ...
        'TitleFontSizeMultiplier', 0.9, ...
        'TitleFontWeight', 'bold',...
        'box', 'off');     % Make axes bold  
    xlabel('\rmtime [s]', 'FontName', PlotsFontName)  
    ylabel('\bf|\itF\rm(\itt\rm)\bf|\rm or \bf|\itF_{\rmMT}(\itt\rm)\bf| [nN]', 'FontName', PlotsFontName);
    title(titleStr);    
    legendHandle = legend('|\bfF_{MT}|', '|\bfF|');
    legendHandle.FontSize = 8;
%     ImageHandleForce = getframe(figHandleForce);
%     ImageForce_cdata = ImageHandleForce.cdata;
        
% 2. ___________ Plot Works
        %     titleStr1 = strcat(sprintf('Substrate Displacement \\Delta_{TFM} vs. MT Displacement_{MT}. Needle Inclination angle = %g', InclinationAngleDegrees), char(176));   
        %     titleStr   = {titleStr1, titleStr2, titleStr3};       
    figHandleDispl = figure('visible',showPlot, 'color', 'w');     % added by WIM on 2019-02-07. To show, remove 'visible
%     set(figHandleDispl, 'defaultAxesColorOrder',[[0,0,1]; [1,0,0]]);              % blue for left, and red for right    
    plot(CleanedUpTimeStampsDICvariables.TimeStampsAbsoluteRT_Sec(FramesPlottedNumbers), DisplDIC_xy_Micron(FramesPlottedNumbers), ...
        'b.-', 'LineWidth', 1,  'MarkerSize',2)
    xlim([0, TimeXlimSec]);
    title(titleStr);
    set(findobj(gcf,'type', 'axes'), ...
        'FontSize',11, ...
        'FontName', 'Helvetica', ...
        'LineWidth',1, ...
        'XMinorTick', 'on', ...
        'YMinorTick', 'on', ...
        'TickDir', 'out', ...
        'TitleFontSizeMultiplier', 0.9, ...
        'TitleFontWeight', 'bold', ...
        'box', 'off');     % Make axes bold  
    xlabel('\rmtime [s]', 'FontName', PlotsFontName)
    ylabel('\bf|\it\Delta_{\rmTxRed}(\itt\rm)\bf|\rm or \bf|\it\Delta_{\rmMT}(\itt\rm)\bf| [\mum]', 'FontName', PlotsFontName);        
    hold on 
    plot(CleanedUpTimeStampsEPIvariables.TimeStampsAbsoluteRT_Sec(FramesPlottedNumbers), DisplEPI_xy_Micron(FramesPlottedNumbers, 3), ...
        'r.-',  'LineWidth', 1, 'MarkerSize', 2)
    legendHandle = legend('|\bf\Delta_{MT}|', '|\bf\Delta_{TxRed}|');
    legendHandle.FontSize = 8;
        
  % Saving the plot
%     ImageHandleDispl = getframe(figHandleForce);
%     ImageDispl_cdata = ImageHandleDispl.cdata;
   switch controlMode
        case 'Controlled Force' 
        figHandleEnergy = figure('visible',showPlot, 'color', 'w');     % added by WIM on 2019-02-07. To show, remove 'visible
    %     set(figHandleDispl, 'defaultAxesColorOrder',[[0,0,1]; [1,0,0]]);              % blue for left, and red for right    
        try
            WorkMTJ = ForceDICvariables.CompiledDataStruct.WorkAllFramesNmSummed;
            plot(CleanedUpTimeStampsDICvariables.TimeStampsAbsoluteRT_Sec(1:numel(WorkMTJ)), WorkMTJ(1:numel(WorkMTJ)) * ConversionJtoFemtoJ , ...
                'b.', 'MarkerSize',4)
        catch
            % no work. negative control probably
        end
        xlim([0, TimeXlimSec]);
        title(titleStr);
        set(findobj(gcf,'type', 'axes'), ...
            'FontSize',11, ...
            'FontName', 'Helvetica', ...
            'LineWidth',1, ...
            'XMinorTick', 'on', ...
            'YMinorTick', 'on', ...
            'TickDir', 'out', ...
            'TitleFontSizeMultiplier', 0.9, ...
            'TitleFontWeight', 'bold', ...
            'box', 'off');     % Make axes bold  
        xlabel('\rmtime [s]', 'FontName', PlotsFontName)
        ylabel('\bf\itU\rm(\itt\rm) or \bfW\rm_{MT}(\itt\rm) [Nm.\mum] or [fJ]', 'FontName', PlotsFontName);        
        hold on 
        EnergyTFMJ = ForceEPIvariables.TractionEnergyJ(FramesPlottedNumbers) ;
        plot(CleanedUpTimeStampsEPIvariables.TimeStampsAbsoluteRT_Sec(FramesPlottedNumbers), EnergyTFMJ * ConversionJtoFemtoJ,  ...
            'r.', 'MarkerSize', 4)
        legendHandle = legend('\bfW\rm_{MT}(\itt\rm)', '\bf\itU\rm(\itt\rm)');
        legendHandle.FontSize = 8;   
   end
   %%
    disp('**___to continue, type "dbcont" or press "F5", or click "Continue" under "Editor" Menu___**')
    keyboard
    

        %% Saving the output files to the desired file format.       
    AnalysisCombinedForcePNG = '';
    AnalysisCombinedForceFIG = '';
    AnalysisCombinedForceEPS = '';
    AnalysisCombinedDisplPNG = '';
    AnalysisCombinedDisplFIG = '';
    AnalysisCombinedDisplEPS = '';
    AnalysisCombinedEnergyWorkPNG  = '';
    AnalysisCombinedEnergyWorkFIG  = '';
    AnalysisCombinedEnergyWorkEPS  = '';
    
    for ii = 1:numel(PlotChoice)
        tmpPlotChoice =  PlotChoice{ii};
        switch tmpPlotChoice
            case 'PNG'
                AnalysisCombinedForcePNG = fullfile(CombinedAnalysisPath, '11 Forces TFM vs. MT Plot.png');                    
                saveas(figHandleForce, AnalysisCombinedForcePNG,'png') 
            case 'FIG'
                AnalysisCombinedForceFIG = fullfile(CombinedAnalysisPath, '11 Forces TFM vs. MT Plot.fig');
                savefig(figHandleForce, AnalysisCombinedForceFIG, 'compact')
            case 'EPS'
                AnalysisCombinedForceEPS = fullfile(CombinedAnalysisPath, '11 Forces TFM vs. MT Plot.eps');
                print(figHandleForce, AnalysisCombinedForceEPS,'-depsc')                
        otherwise
            return
        end
    end
      
    for ii = 1:numel(PlotChoice)
        tmpPlotChoice =  PlotChoice{ii};
        switch tmpPlotChoice
            case 'PNG'
                AnalysisCombinedDisplPNG = fullfile(CombinedAnalysisPath, '11 Net Displacements TFM vs. MT Plot.png');                    
                saveas(figHandleDispl, AnalysisCombinedDisplPNG,'png') 
            case 'FIG'
                AnalysisCombinedDisplFIG = fullfile(CombinedAnalysisPath, '11 Net Displacements TFM vs. MT Plot.fig');
                savefig(figHandleDispl, AnalysisCombinedDisplFIG, 'compact')              
            case 'EPS'
                AnalysisCombinedDisplEPS = fullfile(CombinedAnalysisPath, '11 Net Displacements TFM vs. MT Plot.eps');
                print(figHandleDispl, AnalysisCombinedDisplEPS, '-depsc')                         
        otherwise
            return
        end
    end
    fprintf('Force Plots are: \n\t%s \n\t%s \n\t%s \n', AnalysisCombinedForcePNG, AnalysisCombinedForceFIG, AnalysisCombinedForceEPS)
    fprintf('Displacement Plots are: \n\t%s \n\t%s \n\t%s \n', AnalysisCombinedDisplPNG, AnalysisCombinedDisplFIG, AnalysisCombinedDisplEPS)
    
    switch controlMode
        case 'Controlled Force' 
            for ii = 1:numel(PlotChoice)
                tmpPlotChoice =  PlotChoice{ii};
                switch tmpPlotChoice
                    case 'PNG'
                        AnalysisCombinedEnergyWorkPNG = fullfile(CombinedAnalysisPath, '11 Energy TFM vs. MT Work Plot.png');                    
                        saveas(figHandleEnergy, AnalysisCombinedEnergyWorkPNG,'png') 
                    case 'FIG'
                        AnalysisCombinedEnergyWorkFIG = fullfile(CombinedAnalysisPath, '11 Energy TFM vs. MT Work Plot.fig');
                        savefig(figHandleEnergy, AnalysisCombinedEnergyWorkFIG, 'compact')              
                    case 'EPS'
                        AnalysisCombinedEnergyWorkEPS = fullfile(CombinedAnalysisPath, '11 Energy TFM vs. MT Work Plot.eps');
                        print(figHandleEnergy, AnalysisCombinedEnergyWorkEPS, '-depsc')                         
                otherwise
                    return
                end
            end
            fprintf('Work/Energy Plots are: \n\t%s \n\t%s \n\t%s \n', AnalysisCombinedEnergyWorkPNG, AnalysisCombinedEnergyWorkFIG, AnalysisCombinedEnergyWorkEPS)
    end   

    fprintf('The Combined Analysis file is: \n\t %s\n', CombinedAnalysisFullFileName)

    % ---------------------------------------------------------------------------------------
    disp('Maximum EPI Displacement Plots over time have been Generating! Process Complete!')
