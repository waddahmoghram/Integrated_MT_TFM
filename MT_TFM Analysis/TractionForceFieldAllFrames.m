%{
    Updated: 2019-12-17 superseded by TractionForceFieldAllFramesFiltered.m
    v.2019-10-07 updated by Waddah Moghram, PhD candidate in Biomedical Engineering at the University of Iowa
        1. Replaced CurrentFx with Force(:,1), CurrentFy with Force(:,2), CurrentF_net with Force(:,3)
        2. Updated TractionForceFieldSingleFrame.m accordingly.
        3. ****** NOW Keep output in Image coordinates (y-positive in the x-coordinates to be consistent with everything else, displField, forceField, etc.)
            (i.e., removed negative signs)****** 
    v.2019-10-14 by Waddah Moghram
        1. Update so that the plots also include the use elastic modulus, and Poisson Ratio in the stress tractions

    v.2019-10-12
        1. Fixed error with calling ND2TimeExtract to pass along the ND2 file in the record.
        2. Changed for from negative sign for net traction force to magnitude. Also, the angle Theta is given separately
        3. Separate plots for net traction force and for theta. 

    v.2019-09-27 updated by Waddah Moghram, PhD Candidate in Biomedical Engineering at the University of Iowa
        1. Fixed the summed integration part by creating a separate function. intMethod = 'Summed'

    v.2019-09-08...12 updated by Waddah Moghram, PhD Candidate in Biomedical Engineering at the University of Iowa
        1. Changed the sign of the net traction so that it is in the negative if it is in the negative x-direction. (sign(F_x))
        2. Updated saving to figures
        3. Change *.tif output to *.png for plots
        4. Added a fourth output argument TimeFrames
        5. Renamed tIntegral to TractionForce.

    v.2019-08-25 (v6.0) updated by Waddah Moghram, PhD Candidate in Biomedical Engineering at the University of Iowa
    v.2019-06-01 (v5.0) updated by Waddah Moghram, PhD Candidate in Biomedical Engineering at the University of Iowa
    1. Change function name from TractionForceFieldAllFrames_v_4_0.m to TractionForceFieldAllFrames.m
    
    %**************** Neeeds Improvement*******************%
        TractionForceFieldAllFrames.m
        v.2019-04-26 (v.4.00)

        Written by Waddah Moghram to go over all frames.
        Load Movie Data (MD) and forceField to the workspace and run this code
        Make sure that the TFM Package is added to the search directory
        Run this script to get tractions for all frames. 

        Last updated on 4/26/2019
        This version will generate a similar forceField as that used previously
        forceField.pos (x,y) coordinates in pixels
        forceField.vec (u,v) in Pascales

        Create inputFile for tMaps instead of the huge tMap file that's compiled.
    %}
%% --------   Function Begins here -------------------------------------------------------------------  
function [TractionForce, TractionForceX, TractionForceY, TimeFrames] = TractionForceFieldAllFrames(MD, forceField, ...
    FirstFrame, LastFrame, intMethod, forceFilePath,AnalysisPath, PlotChoice, StepSize, tolerance)
%% ====== Check if there is a GPU. take advantage of it if is there ============================================================ 
    nGPU = gpuDeviceCount;
    if nGPU > 0
        useGPU = true;
    else
        useGPU = false;
    end
    params = 'r-';
    disp('-------------------------- Running TractionForceFieldAllFrames.m: To evaluate traction forces from a grid --------------------------')
    
    %% Check parameters
        if nargin >  10
            error('Too many argument inputs')
        end
    
    %% --------  nargin 1, Movie Data (MD) -------------------------------------------------------------------  
    if ~exist('MD','var'), MD = []; end
    try 
        isMD = (class(MD) ~= 'MovieData');
    catch 
        MD = [];
    end   
    if nargin < 1 || isempty(MD) 
        [movieFileName, movieFilePath] = uigetfile('*.mat','Open the TFM-Package Movie Data File');
        if movieFileName == 0, return; end
        MovieFileFullName = fullfile(movieFilePath, movieFileName);
        try 
            load(MovieFileFullName, 'MD')
            fprintf('Movie Data (MD) file is: \n\t %s\n', MovieFileFullName);
            disp('------------------------------------------------------------------------------')
        catch 
            errordlg('Could not open the movie data file!')
            return
        end
    else
        movieFilePath = MD.getPath;
    end
    
    %% --------  nargin 2, force field (forceField) -------------------------------------------------------------------    
    if ~exist('forceField','var'), forceField = []; end
    % no force field is given. find the force process tag or the correction process tag
    if nargin < 2 || isempty(forceField)
        try 
            ProcessTag =  MD.findProcessTag('ForceFieldCalculationProcess').tag_;
        catch
            ProcessTag = '';
            disp('No Completed "Force" Field Calculated!');
            disp('------------------------------------------------------------------------------')
        end
        %------------------
        if exist('ProcessTag', 'var') 
            fprintf('"Force" Process Tag is: %s\n', ProcessTag);
            try
                ForceFileFullName = MD.findProcessTag(ProcessTag).outFilePaths_{1};
                if exist(ForceFileFullName, 'file')
                    dlgQuestion = sprintf('Do you want to open the "force" field referred to in the movie data file?\n\n%s\n', ...
                        ForceFileFullName);
                    dlgTitle = 'Open "force" field (forceField.mat) file?';
                    OpenForceChoice = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No', 'Yes');
                    switch OpenForceChoice
                        case 'Yes'
                            [forceFilePath, ~, ~] = fileparts(ForceFileFullName);
                        case 'No'
                            ForceFileFullName = [];
                        otherwise
                            return
                    end            
                else
                    ForceFileFullName = [];
                end
            catch
                ForceFileFullName = [];
            end
        end
        %------------------
        if isempty(ForceFileFullName) || ~exist('ProcessTag', 'var')
                TFMPackageFiles = fullfile(movieFilePath,'TFMPackage','*.mat');
                [forceFileName, forceFilePath] = uigetfile(TFMPackageFiles, 'Open the "force" field (forceField.mat) under forceField or backups');
                if forceFileName ==  0, return; end
                ForceFileFullName = fullfile(forceFilePath, forceFileName);
        end    
        %------------------       
        try
            load(ForceFileFullName, 'forceField');   
            fprintf('"Force" Field (forceField.mat) File is successfully loaded! \n\t %s\n', ForceFileFullName);
            disp('------------------------------------------------------------------------------')
        catch
            errordlg('Could not open the "force" field file.');
            return
        end
    end
    
    %%
    [forceFieldParametersFile, forceFieldparametersPath] = uigetfile(fullfile(forceFilePath, '*.mat'), ' open the forceFieldParameters.mat file');    
    if forceFieldParametersFile==0
        error('No file was selected');
    end            
    forceFieldParametersFullFileName = fullfile(forceFieldparametersPath, forceFieldParametersFile);   
    forceFieldProcessStruct = load(forceFieldParametersFullFileName, 'forceFieldProc');
    forceFieldCalculationInfo = forceFieldProcessStruct.forceFieldProc;
    fprintf('forceField paramters successfully: \n\t %s \n', forceFieldParametersFullFileName)
               
    %% --------  nargin 5, Integration Method (intMethod) 'iterative' vs. 'tiled' vs. 'summed'------------------------------
    if ~exist('intMethod','var'), intMethod = []; end
    if nargin < 5 ||  isempty(intMethod) 
        dlgQuestion = ({'Do you want to integrated or sum the force Field?'});
        dlgTitle = 'Integration?';
        intMethodStr = questdlg(dlgQuestion, dlgTitle, 'Integrated: Tiled', 'Integrated: Iterated', 'Summed', 'Integrated: Iterated');
        switch intMethodStr
            case 'Integrated: Tiled'
                intMethod = 'tiled';
            case 'Integrated: Iterated'
                intMethod = 'iterated';
            case 'Summed'
                intMethod = 'summed';                
        end   
    end
    
    %% --------  nargin 6, Plot Choice for the integrals over time (PlotChoice) ----------------------------- 
    if ~exist('PlotChoice','var'), PlotChoice = []; end
    if nargin < 6 || isempty(PlotChoice)
        dlgQuestion = ({'File Format(s) for images?'});
        listStr = {'PNG', 'FIG', 'EPS'};
        PlotChoice = listdlg('ListString', listStr, 'PromptString',dlgQuestion, 'InitialValue', [1,2], 'SelectionMode' ,'multiple');    
        PlotChoice = listStr(PlotChoice);                 % get the names of the string.   
    end
    
    %% --------  nargin 7, output folder & parameters file  -------------------------------------------------------------------
    if ~exist('forceFilePath','var'), forceFilePath = []; end
    if nargin < 7 || isempty(forceFilePath)
        if ~exist('forceOutputPath', 'var')
            try
                forceFieldCalculationInfo =  MD.findProcessTag('ForceFieldCalculationProcess');
                forceFieldFileName = forceFieldCalculationInfo.outFilePaths_{1};
                [forceFilePath, ~, ~] = fileparts(forceFieldFileName);      
            catch
                forceFilePath = uigetdir(forceFilePath, 'Directory where you want to store the traction force in');
                if forceFilePath == 0, return; end
            end
            TractionForcesFileName = sprintf('TractionForces_%s.mat', intMethod);
            TractionForcesOutputFile = fullfile(forceFilePath, TractionForcesFileName);
        end
    end
    
    %% --------  nargin 8, Analysis Output Folder (Analysispath)-------------------------------------------------------------------  
    if ~exist('AnalysisPath','var'), AnalysisPath = []; end    
    if nargin < 8 || isempty(AnalysisPath) 
        dlgQuestion = ({'Do you want to save in an Analysis output folder?'});
        dlgTitle = 'Analysis folder?';
        AnalysisPathChoice = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No', 'Yes');
        switch AnalysisPathChoice
            case 'Yes'
                if ~exist('movieFilePath','var'), movieFilePath = pwd; end
                AnalysisPath = uigetdir(movieFilePath, 'Choose the analysis directory where the tracked output will be saved.');    
                if AnalysisPath == 0, return; end
                if ~exist(AnalysisPath,'dir')   % Check for a directory
                    mkdir(AnalysisPath);
                end
                TractionForcesFileNameAnalysis = sprintf('10 TractionForces_%s.mat', intMethod);
                TractionForcesOutputFileAnalysis = fullfile(AnalysisPath, TractionForcesFileNameAnalysis);
            case 'No'
                % Continue and do nothing
        end   
    end
    
    %% --------  nargin 9, Analysis Output Folder (Analysispath)-------------------------------------------------------------------  
    if ~exist('StepSize','var'), StepSize = []; end    
    if nargin < 9 || isempty(StepSize) 
        StepSize = input('Every how many frames do you want to evaluate the traction forces? [Default, All Frame, N =1]: ');
        if isempty(StepSize), StepSize = 1; end
    end
        
    %% --------  nargin 10, Analysis Output Folder (Analysispath)-------------------------------------------------------------------  
    if ~exist('tolerance','var'), tolerance = []; end    
    if nargin < 10 || isempty(tolerance) 
        if strcmpi(intMethod, 'iterated') || strcmpi(intMethod, 'tiled')
            tolerance = input('What is the desired tolerance for integration? [Default = 1e-13]: ');
            if isempty(tolerance), tolerance = 1e-13; end
        end            
    end
        
            
    %% --------  nargin 3, FirstFrame. Check for previously tracked images -------------------------------------------------------------------     
    if ~exist('FirstFrame','var'), FirstFrame = []; end
    if nargin < 3 || isempty(FirstFrame)
        try
            ExistingTractionForcesOutputFiles1 = dir(fullfile(forceFilePath, 'TractionForces*.mat'));
            ExistingTractionForcesOutputFiles2 = dir(fullfile(forceFilePath, 'tIntegral*.mat'));
            if  ~isempty(ExistingTractionForcesOutputFiles1)
                try
                    if numel(ExistingTractionForcesOutputFiles1) == 1
                        TractionForcesOutputFileOld = fullfile(ExistingTractionForcesOutputFiles1(1).folder, ExistingTractionForcesOutputFiles1(1).name);
                        load(TractionForcesOutputFileOld)
                    else
                        [TractionForcesFileName, TractionForcesFilePath] = uigetfile(forceFilePath, 'Open the integrated traction (tIntegral.mat) or (traction force*.mat) under forceField or backups');
                        if TractionForcesFileName ~=  0                     % cancel or exit was not selected.
                            TractionForcesOutputFileOld = fullfile(TractionForcesFilePath, TractionForcesFileName);    
                            load(TractionForcesOutputFileOld)
                        end
                    end
                catch
                    % Continue
                end
            elseif ~isempty(ExistingTractionForcesOutputFiles2)
                try
                    if numel(ExistingTractionForcesOutputFiles2) == 1
                        TractionForcesOutputFileOld = fullfile(ExistingTractionForcesOutputFiles2(1).folder, ExistingTractionForcesOutputFiles2(1).name);                            
                        load(TractionForcesOutputFileOld)
                    else
                        [TractionForcesFileName, TractionForcesFilePath] = uigetfile(forceFilePath, 'Open previously integrated traction file. Otherwise click cancel to start anew. (tIntegral.mat or traction force*.mat).');
                        if TractionForcesFileName ~=  0
                            TractionForcesOutputFileOld = fullfile(TractionForcesFilePath, TractionForcesFileName);    
                            load(TractionForcesOutputFileOld)
                        end
                    end
                catch
                    % continue
                end
            else
                [TractionForcesFileName, TractionForcesFilePath] = uigetfile(TFMPackageFiles, 'Open previously integrated traction file. Otherwise click cancel to start anew. (tIntegral.mat or traction force*.mat).');
                if TractionForcesFileName ~=  0
                    TractionForcesOutputFileOld = fullfile(TractionForcesFilePath, TractionForcesFileName);    
                    load(TractionForcesOutputFileOld)
                end
            end
            FramesDoneBoolean = arrayfun(@(x) ~isempty(x.vec), TractionForce);
            FramesDoneNumbers = find(FramesDoneBoolean == 1);       
            FirstFrame = find(FramesDoneBoolean, 1, 'first');            
            try
                TractionForce = tIntegral;
                TractionForceX = tIntegralX;
                TractionForceY = tIntegralY;           
            catch
                % continue
            end 
        catch
            FirstFrame = 1;
        end
    end
    
    %% --------  nargin 4, LastFrame. Check for last known tracked images ------------------------------------------------------------------
    if ~exist('LastFrame', 'var'), LastFrame = []; end
    if nargin < 4 || isempty(LastFrame)
        LastFrame = sum(arrayfun(@(x) ~isempty(x.vec), forceField));
        if FirstFrame == LastFrame
            dlgQuestion = ({'Tractions for All frames have been previously calculated. Do you want to start from the beginning again?'});
            dlgTitle = 'Re-Calculation Traction Forces?';
            ReCalculateTractionForces = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No', 'Yes');
            %------------------
            switch ReCalculateTractionForces
                case 'Yes'
                    FirstFrame = 1;
                case 'No'
                    return;
            end
        else        
            prompt = {sprintf('Choose the first frame to integrated. [Default, frame next to last frame integrated so far = %d]', FirstFrame)};
            dlgTitle = 'First Frame To Be Tracked';
            FirstFrameStr = inputdlg(prompt, dlgTitle, [1, 100], {num2str(FirstFrame)});
            FirstFrame = str2double(FirstFrameStr{1});                                  % Convert to a number
        end
        fprintf('First Frame = %d\n', FirstFrame);
        %------------------       
        prompt = {sprintf('Choose the last frame to integrated. [Default, Last Frame = %d]', LastFrame)};
        dlgTitle = 'Last Frame To Be integrated';
        LastFrameStr = inputdlg(prompt, dlgTitle, [1, 100], {num2str(LastFrame)});
        LastFrame = str2double(LastFrameStr{1});                                  % Convert to a number
    end
    fprintf('Last Frame = %d\n', LastFrame);
    disp('------------------------------------------------------------------------------')     
    

    %% **** Fix Parallel processing later
%     poolobj = gcp('nocreate'); % If no pool, do not create new one.
%     if isempty(poolobj)
%         poolsize = str2num(getenv('NUMBER_OF_PROCESSORS')) - 1;                       % Matlab 2018b update 3 returns getenv as string 2/20/2019               
%     %                 poolsize = getenv('NUMBER_OF_PROCESSORS') - 1;                      % Modified by Waddah Moghram on 12/10/2018 and is better to get all cores.
%     %                 poolsize = feature('numCores');
%     else
%         poolsize = poolobj.NumWorkers;
%     end
%     if isempty(gcp('nocreate'))
%         try
%             parpool('local', poolsize)
%         catch
%             try 
%                 parpool
%             catch 
%                 warning('matlabpool has been removed, and parpool is not working in this instance');
%             end
%         end
%     end % we don't need this any more.

    %% -------------- Calculating the integrals of traction stresses -------------------------------------------------------------------------
%     Force(:,1) = 0;
%     Force(:,2) = 0;

    if ~exist('TractionForce', 'var') || ~exist('TractionForceX', 'var') || ~exist('TractionForceY', 'var') 
        TractionForceX = NaN(LastFrame,1);
        TractionForceY = NaN(LastFrame,1);
        TractionForce = NaN(LastFrame,1);
    end
    if useGPU
        TractionForce = gpuArray(TractionForce);
        TractionForceX = gpuArray(TractionForceX);
        TractionForceY = gpuArray(TractionForceY);
    end

    % parfor CurrentFrame = FirstFrame:LastFrame                                                                      %% ** NEEDS TO BE FIXED
    disp('-----------------------------------------------------------------------')
    disp('Calculating Traction Integrals in Process.')
    disp('-----------------------------------------------------------------------')
    
    for CurrentFrame = FirstFrame:StepSize:LastFrame
        fprintf('Starting Frame %d/%d. \n', CurrentFrame, LastFrame);
            % Loading the respective traction file variables            
        [Force] =  TractionForceSingleFrame(MD, forceField, CurrentFrame, intMethod, tolerance);                                                                          % last item, integrated = 0 is summed, 1 = integrated  
        try
%             if gpuDeviceCount > 0
            TractionForceX(CurrentFrame) = gather(Force(:,1));
            TractionForceY(CurrentFrame) = gather(Force(:,2));
            %---------------------- Not needed anymore 2019-11-07
%             Force(:,3) = gather(sign(Force(:,1)) .* vecnorm([Force(:,1), Force(:,2)],2,2));                
%             Force(:,3) = gather(vecnorm([Force(:,1), Force(:,2)],2,2));                                         % changed on 2019-10-12 by WIM
            %----------------------
        catch
            TractionForceX(CurrentFrame) = Force(:,1);
            TractionForceY(CurrentFrame) = Force(:,2);
            %---------------------- Not needed anymore 2019-11-07
%             Force(:,3) =  sign(Force(:,1)) .* vecnorm([Force(:,1), Force(:,2)],2,2);                   % corrected for the sign on 2019-09-08
%             Force(:,3) =  vecnorm([Force(:,1), Force(:,2)],2,2);                   % corrected for the sign on 2019-09-08
            %----------------------
        end
        TractionForce(CurrentFrame) = Force(:,3);
    end    
    try
        if gpuDeviceCount > 0
            TractionForce = gather(TractionForce);
            TractionForceX = gather(TractionForceX);
            TractionForceY = gather(TractionForceY);
        end
    catch
                % do nothing
    end
    disp('Evaluating Traction Forces is finished! Now generating plots');
    
    %% Saving the output to *.mat format for future reference.
    save(TractionForcesOutputFile, 'TractionForce','TractionForceX','TractionForceY', 'intMethod',  '-v7.3')

    %% ---------------------------------------------------------------------------------------
    % Plotting
    commandwindow;
    GelConcentrationMgMl = input('What was the gel concentration in mg/mL? ');  
    fprintf('Gel Concentration Chosen is %d  mg/mL. \n', GelConcentrationMgMl);
    
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
    if isempty(thickness_um)
        thickness_um = input('What was the gel thickness in microns? ');  
        fprintf('Gel thickness is %d  microns. \n', thickness_um);
    else
        fprintf('Gel thickness found is %d  microns. \n', thickness_um);
    end

    %----------------------------------------------
    try
        YoungModulusPa = forceFieldCalculationInfo.funParams_.YoungModulus;
    catch
        YoungModulusPa = [];
    end
    if isempty(YoungModulusPa)
        YoungModulusPa = input('What was the gel''s Young Elastic modulus (in Pa)? ');  
        fprintf('Gel''s elastic modulus (E) is %g  Pa. \n', YoungModulusPa);
    else
        fprintf('Gel''s elastic modulus (E) found is %g  Pa. \n', YoungModulusPa);        
    end

    %----------------------------------------------
    try
        PoissonRatio = forceFieldCalculationInfo.funParams_.PoissonRatio;
    catch
        PoissonRatio = [];
    end
    if isempty(PoissonRatio)
        PoissonRatio = input('What was the gel''s Young Elastic modulus (in Pa)? ');  
        fprintf('Gel''s Poisson Ratio (nu) is %g  Pa. \n', PoissonRatio);
    else
        fprintf('Gel''s Poisson Ratio (nu) found is %g  Pa. \n', PoissonRatio);        
    end    
    
    
    %% =====================================

    try
        try
            [TimeFrames, ~, AverageFrameRate] = ND2TimeFrameExtract(MD.channels_.channelPath_);
        catch
            [TimeFrames, ~, AverageFrameRate] = ND2TimeFrameExtract(MD.movieDataPath_);            
        end
        FrameRate = 1/AverageFrameRate;
    catch
        try 
            FrameRate = 1/MD.timeInterval_;
        catch
            FrameRate = 1/ 0.025;           % (40 frames per seconds)              
        end
    end
    
    %%
    prompt = {sprintf('Choose the Frame Rate per second for this movie. [Default, %.4f]', FrameRate)};
    dlgTitle =  'Frames Per Second';
    FrameRateStr = inputdlg(prompt, dlgTitle, [1, 90], {num2str(FrameRate)});
    if isempty(FrameRateStr), return; end
    FrameRate = str2double(FrameRateStr{1});                                  % Convert to a number                                     
    TimeFrames = (FirstFrame:LastFrame)' ./ FrameRate;
        
    %%
    save(TractionForcesOutputFile, 'FrameRate', 'TimeFrames','FirstFrame', 'LastFrame',  'GelConcentrationMgMl',  'thickness_um', ...
        'YoungModulusPa', 'PoissonRatio','-append')
    
    %%
    FramePlotted(1:LastFrame) = ~isnan(TractionForce(1:LastFrame));
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
    plot(TimeFrames(FramePlotted), TractionForce(FramePlotted), 'r.-', 'LineWidth', 1, 'MarkerSize', 2)
    title(titleStr);
    ylabel('|F_{TFM,xy}| (N)');
    set(gca, 'FontSize',9, 'FontWeight','Bold', 'LineWidth',1, 'XMinorTick', 'on', 'YMinorTick', 'on', 'TickDir', 'out')
    xlim([TimeFrames(FirstFrame), TimeFrames(LastFrame)]);
    
    hold on    
    subplot(3,1,2)
    plot(TimeFrames(FramePlotted), -TractionForceX(FramePlotted),params)
    ylabel('F_{TFM,x} (N)')
    set(gca, 'FontSize',9, 'FontWeight','Bold', 'LineWidth',1, 'XMinorTick', 'on', 'YMinorTick', 'on', 'TickDir', 'out')
    xlim([TimeFrames(FirstFrame), TimeFrames(LastFrame)]);
    
    subplot(3,1,3)
    plot(TimeFrames(FramePlotted), - TractionForceY(FramePlotted),params)       % Flip the y-coordinates to Cartesian
    xlabel('Time (s)')
    ylabel('F_{TFM,y} (N)')
    set(gca, 'FontSize',9, 'FontWeight','Bold', 'LineWidth',1, 'XMinorTick', 'on', 'YMinorTick', 'on', 'TickDir', 'out')
    xlim([TimeFrames(FirstFrame), TimeFrames(LastFrame)]);
    
    hold off    
    
    figHandleNetOnly = figure('visible',showPlot, 'color', 'w');     % added by WIM on 2019-02-07. To show, remove 'visible    
    plot(TimeFrames(FramePlotted), TractionForce(FramePlotted),params)
    title(titleStr);
    ylabel('|F_{TFM,xy}| (N)');
    set(gca, 'FontSize',9, 'FontWeight','Bold', 'LineWidth',1, 'XMinorTick', 'on', 'YMinorTick', 'on', 'TickDir', 'out')
    xlabel('Time (s)')
    xlim([TimeFrames(FirstFrame), TimeFrames(LastFrame)]);   

%     ImageHandle = getframe(figHandle);     

  %% --------- Saving the output files to the desired file format.   
    for CurrentPlotType = 1:numel(PlotChoice)
        tmpPlotChoice =  PlotChoice{CurrentPlotType};
        switch tmpPlotChoice
            case 'PNG'                  % PNG SAVE. Consider replacing TIF to PNG.  %                 saveas(figFluxV, figureFileNames{2,1}, 'png');
                fileNamePNG1 = sprintf('TractionForcesPlot_%s.png', intMethod);
                TractionForcePNG1 = fullfile(forceFilePath, fileNamePNG1);
                saveas(figHandleAll, TractionForcePNG1, 'png');
                
                fileNamePNG2 = sprintf('TractionNetForcePlot_%s.png', intMethod);
                TractionForcePNG2 = fullfile(forceFilePath, fileNamePNG2);
                saveas(figHandleNetOnly, TractionForcePNG2, 'png');                
                
                if exist(AnalysisPath,'dir') 
                    AnalysisFileNamePNG1 = sprintf('10 TractionForcesPlot_%s.png', intMethod);                    
                    AnalysisTractionForcePNG1 = fullfile(AnalysisPath, AnalysisFileNamePNG1);
                    saveas(figHandleAll, AnalysisTractionForcePNG1);
                    
                    AnalysisFileNamePNG2 = sprintf('10 TractionNetForcePlot_%s.png', intMethod);                    
                    AnalysisTractionForcePNG2 = fullfile(AnalysisPath, AnalysisFileNamePNG2);
                    saveas(figHandleNetOnly, AnalysisTractionForcePNG2);                                
                end
                
            case 'FIG'
                fileNameFIG1 = sprintf('TractionForcesPlot_%s.fig', intMethod);
                TractionForceFIG1 = fullfile(forceFilePath, fileNameFIG1);                
                hgsave(figHandleAll, TractionForceFIG1,'-v7.3')

                fileNameFIG2 = sprintf('TractionNetForcePlot_%s.fig', intMethod);
                TractionForceFIG2 = fullfile(forceFilePath, fileNameFIG2);                
                hgsave(figHandleNetOnly, TractionForceFIG2,'-v7.3')                
                
                if exist(AnalysisPath,'dir') 
                    AnalysisFileNameFIG1 = sprintf('10 TractionForcesPlot_%s.fig', intMethod);                    
                    AnalysisTractionForceFIG1 = fullfile(AnalysisPath, AnalysisFileNameFIG1);                    
                    hgsave(figHandleAll, AnalysisTractionForceFIG1,'-v7.3')    
                    
                    AnalysisFileNameFIG2 = sprintf('10 TractionNetForcePlot_%s.fig', intMethod);                    
                    AnalysisTractionForceFIG2 = fullfile(AnalysisPath, AnalysisFileNameFIG2);                    
                    hgsave(figHandleNetOnly, AnalysisTractionForceFIG2,'-v7.3')                        
                end
                
            case 'EPS'
                fileNameEPS1 = sprintf('TractionForcesPlot_%s.eps', intMethod);
                TractionForceEPS1 = fullfile(forceFilePath, fileNameEPS1);                          
                print(figHandleAll, TractionForceEPS1,'-depsc')   
                
                fileNameEPS2 = sprintf('TractionNetForcePlot_%s.eps', intMethod);
                TractionForceEPS2 = fullfile(forceFilePath, fileNameEPS2);                          
                print(figHandleNetOnly, TractionForceEPS2,'-depsc')                   
                
                if exist(AnalysisPath,'dir') 
                    AnalysisFileNameEPS1 = sprintf('10 TractionForcesPlot_%s.eps', intMethod);                    
                    AnalysisTractionForceEPS1 = fullfile(AnalysisPath, AnalysisFileNameEPS1);                                     
                    print(figHandleAll, AnalysisTractionForceEPS1,'-depsc')
                    
                    AnalysisFileNameEPS2 = sprintf('10 TractionNetForcePlot_%s.eps', intMethod);                    
                    AnalysisTractionForceEPS2 = fullfile(AnalysisPath, AnalysisFileNameEPS2);                                     
                    print(figHandleNetOnly, AnalysisTractionForceEPS2,'-depsc')                    
                end
            otherwise
                 return
        end
    end

    % ---------------------------------------------------------------------------------------
    disp('Traction Force Plots over time have been Generating! Process Complete!')

%% ========================== CODE DUMPSTER ======================================
%                 TractionForceTIF = fullfile(forceFilePath, 'TractionForcePlot.tif');
%                 imwrite(Image_cdata, TractionForceTIF

%     Image_cdata = ImageHandle.cdata;
    
%     if exist(AnalysisPath,'dir')
%         switch AnalysisPath
%             case 'Yes'
%                 hgsave(figHandle, displFieldPathFIG,'-v7.3')
%                 displFieldPathEPS = fullfile(AnalysisPath, ['displFieldNetEPS','.eps']);          
%                 print(figHandle, displFieldPathEPS,'-depsc')   
%             otherwise
%                 % continue
%         end
%     end              


%     if  ~exist('forceField','var'), forceField = []; end
%     if nargin < 2 || isempty(forceField)
%         try 
%             forceFieldCalculationInfo =  MD.findProcessTag('ForceFieldCalculationProcess');
%             forceFieldFileName = forceFieldCalculationInfo.outFilePaths_{1};
%             [forceFieldPath, ~, ~] = fileparts(forceFieldFileName);               
%         catch
%             forceFieldPath = uigetdir(fullfile(movieFilePath,'TFMPackage'), 'Choose the folder for the desired forceField');  
%             if forceFieldPath == 0, return; end
%         end      
%         forceFieldPathDefault = fullfile(forceFieldPath,'*.mat');
%         [forceFieldName, forceFieldPath] = uigetfile(forceFieldPathDefault, 'Choose the force field data file made by tfmPackageGUI.m in the TFM Package');
%         if forceFieldName == 0, return; end
%         forceFieldFullFileName = fullfile(forceFieldPath, forceFieldName);
%         load(forceFieldFullFileName, 'forceField'); 
%         fprintf('Force Field Data file selected is: \n\t %s \n' , forceFieldFullFileName)
%         disp('----------------------------------------------------------------------------')         
%     else 
%         errordlg('Incorrect force(Traction) field entered as an argument in TractionForceFieldAllFrames');
%     end

% 
%        %% ---------------------------------------------------------------------------------------
%     if ~exist('FirstFrame','var'), FirstFrame = []; end
%     if nargin < 3 || isempty(FirstFrame)
%         commandwindow;
%         FirstFrame = input('what is the first frame to be tracked [Default = 1]? ');
%         if isempty(FirstFrame)
%             FirstFrame = 1;
%         end
%     end
% 
%     fprintf('First Frame = %d \n', FirstFrame);
%     disp('-----------------------------------------------------------------------')
%     
%    %%
%     if ~exist('LastFrame','var'), LastFrame = []; end
%     if nargin < 4 || isempty(LastFrame)
%         LastFrame = input('What is the last frame to be tracked? [Default = all frames] ');    
%         if isempty(LastFrame)
%             LastFrame = sum(arrayfun(@(x) ~isempty(x.vec), forceField));
%         end
%     end
%     fprintf('Last Frame = %d \n', LastFrame);
%     disp('-----------------------------------------------------------------------')



%     %%
%     if ~exist('AnalysisPath','var'), AnalysisPath = []; end
%     if nargin < 8 || isempty(AnalysisPath) 
%         dlgQuestion = ({'Do you want to save in an Analysis output folder?'});
%         dlgTitle = 'Analysis folder?';
%         AnalysisPath = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No', 'Yes');
%         switch AnalysisPath
%             case 'Yes'
%                 if ~exist('movieFileDir','var'), movieFileDir = pwd; end
%                 AnalysisPath = uigetdir(movieFileDir,'Choose the analysis directory where the tracked output will be saved.');    
%                 if AnalysisPath == 0, return; end
%                 AnalysisPath = fullfile(AnalysisPath, 'Displ Overlays');
%                 if ~exist(AnalysisPath,'dir')   % Check for a directory
%                     mkdir(AnalysisPath);
%                 end
%             case 'No'
%                 % Continue and do nothing
%         end   
%     end
    
    