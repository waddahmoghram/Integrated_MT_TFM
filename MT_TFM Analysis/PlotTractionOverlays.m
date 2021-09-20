%{
    v.2020-02-07 by Waddah Moghram
        1. Renamed from PlotForceOverlays.m to PlotTractionOverlays.m
    v.2020-02-03 by Waddah Moghram
        1. Added a step ask the user if the quiver size is OK or not. 
        2. change the heatmap max to match that of the maximum displacement frame, and not of the raw displacements. 
    v.2020-01-28 by Waddah Moghram
        1. Updated quiver scale to use multiples of suggested one instead of entering exact number?
    v.2020-01-17 by Waddah Moghram
        1. Added a QuiverMagnificationFactor to go by a whole number. Needs to be tweaked internally. So far. it is 2X
    v.2019-12-18 by Waddah Moghram
        1. Fixed FirstFrame error if starting from the middle
    v.2019-12-02 by Waddah Moghram
            1. Fixed the Plot() error if no quivers are used.
    v.2019-11-22 by Waddah Moghram
        1. Made this program compatible with tracking multiple frames at at time.
        2. Change variable names to make DisplacementOverlays, DisplacementHeatmaps, ForceOverlays, ForceHeatmaps the same
            to make changes more efficient in the future.
    v.2019-10-23 by Waddah Moghram
        1. Plot without figure stealing focus. Use clf(figHandle, 'reset'), and ...
    v.2019-10-13 by Waddah Moghram
        1. Added set(figHandleAxes, 'YDir', 'reverese') to make sure that the top-left corner is the origin for images.
    v.2019-10-03..07 by WIM
        1. Fixed the problem of the quiver rescaling the image. Set the Camera View to Manual after the plot.
        2. Figure out an autoscale based on average bead separation distance (90% of that)
        3. Moved up nargin 11 (max displacement) filter ahead of quiver 
        4. Fixed Analysis Output
    v.2019-09-21|24
        1. changed getframe(figHandle) to getframe(figAxesHandle)
        2. Added the part where it closes the figure and creates a new one every 30 frames to reduce RAM and GPU Memory usage.
        3. elminated using "undecorate.m"
    v.2019-09-12
        1. Allow the option to not resize the image to retain the full resoultion for the image overlay.
    v.2019-09-09 
        1. improve the output to be more consistent.
        2. Added a *.mat file to save key parameters.
    v.2019-06-17 based on PlotDisplacementOverlays()
    v.2019-06-14 Update. Written by Waddah Moghram
        1. Update glitch with forceField argument input parsing
    v.2.00
    generatedTrackedDisplacement use dot to track the tracked beads. Quivers are also possible.
    for now, just run by giving no arguments, or up to the first 4 arguments.
    Needs to be fixed for certain input arguments, as they generate error messages.        
    v.2019-05-19..06-12
        Written by Waddah Moghram, PhD Student in Biomedical Engineering. Updated on 2019-05-19, 2019-06-12
        2019-06-04 Renamed "generatedTrackedDisplacement.m" --->  "PlotDisplacementOverlays.m"
        For future edition, think about embedding a colormap in the video along with cData.         
            MD = movie data object
            forceField = displacement field structure
                .pos = position (x,y) of beads
                .vec = vector (u,v) of beads
            FirstFrame
            LastFrame
            ShowPlot = 'on' or 'off'
            saveVideo = 0 or 1 (or false/true)
            showQuiver = 0 or 1 (or false/true)
%}

%% --------   Function Begins here -------------------------------------------------------------------  
function [MD, forceField, FirstFrame, LastFrame, movieFilePath, inputPath, analysisOutputPath] = PlotTractionOverlays(MD, forceField, FirstFrame, LastFrame, ...
    inputPath, showQuiver, showPlot, saveVideo, analysisOutputPath, maxInput, FullResolution)
    
    QuiverMagnificationFactor = 2;              % Added on 2020-01-17
    QuiverLineWidth = 0.5;
       
    %% --------  Check for extra nargin -------------------------------------------------------------------  
    if nargin > 11
        errordlg('Too many arguments in this function, or wrong argument structure!')
        return
    end
    
    %% ====== Check if there is a GPU. take advantage of it if is there ============================================================ 
    nGPU = gpuDeviceCount;
    if nGPU > 0
        useGPU = true;
    else
        useGPU = false;
    end
    
    disp('============================== Running PlotTractionOverlays.m GPU-enabled ===============================================')
    disp('========== WARNING: All reference to "force" in this code and in its output are actually traction stresses (in Pascals)============================')
    
    %% --------  nargin 1, Movie Data (MD) by TFM Package-------------------------------------------------------------------  
    if ~exist('MD', 'var'), MD = []; end
    try 
        isMD = (class(MD) ~= 'MovieData');
    catch 
        MD = [];
    end   
    if nargin < 1 || isempty(MD)
        [movieFileName, movieFilePath] = uigetfile('*.mat', 'Open the TFM-Package Movie Data File');
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
        try 
            isMD = (class(MD) ~= 'MovieData');
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
            InputFileFullName = MD.findProcessTag(ProcessTag).outFilePaths_{1};
            if exist(InputFileFullName, 'file')
                dlgQuestion = sprintf('Do you want to open the "force" field referred to in the movie data file?\n\n%s\n', ...
                    InputFileFullName);
                dlgTitle = 'Open "force" field (forceField.mat) file?';
                OpenForceChoice = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No', 'Yes');
                switch OpenForceChoice
                    case 'Yes'
                        [inputPath, ~, ~] = fileparts(InputFileFullName);
                    case 'No'
                        InputFileFullName = [];
                    otherwise
                        return
                end            
            else
                InputFileFullName = [];
            end
        catch
            InputFileFullName = [];
        end
    end
    %------------------
    if isempty(InputFileFullName) || ~exist('ProcessTag', 'var')
            TFMPackageFiles = fullfile(movieFilePath,'TFMPackage','*.mat');
            [forceFileName, inputPath] = uigetfile(TFMPackageFiles, 'Open the "force" field (forceField.mat) under forceField or backups');
            if forceFileName ==  0, return; end
            InputFileFullName = fullfile(inputPath, forceFileName);
    end    
    %------------------       
    try
        load(InputFileFullName, 'forceField');   
        fprintf('"Force" Field (forceField.mat) File is successfully loaded! \n\t %s\n', InputFileFullName);
        disp('------------------------------------------------------------------------------')
    catch
        errordlg('Could not open the "force" field file.');
        return
    end
    FramesDoneBoolean = arrayfun(@(x) ~isempty(x.vec), forceField);
    FramesDoneNumbers = find(FramesDoneBoolean == 1); 
    FramesDifference = diff(FramesDoneNumbers);
    VeryLastFrame = find(FramesDoneBoolean, 1, 'last');
    VeryFirstFrame =  find(FramesDoneBoolean, 1, 'first');   

    %% --------  nargin 5, Input folder & parameters file  -------------------------------------------------------------------
    if ~exist('inputPath','var'), inputPath = []; end
    if nargin < 5 || isempty(inputPath)
    if ~exist('inputPath', 'var'), inputPath = []; end
        if isempty(inputPath)
            try
                inputPath = movieFilePath;
            catch
                inputPath = pwd;
            end
        end
        inputPath = uigetdir(inputPath,'Choose the directory where you want to store the calculation "Force Field" Overlays.');
        if inputPath == 0  % Cancel was selected
            clear InputPath;
        elseif ~exist(inputPath,'dir')
            mkdir(inputPath);
        end        
        try
            fprintf('Calculated Force Field Overlays Path is: \n\t %s\n', inputPath);
            disp('------------------------------------------------------------------------------')
        catch
            % No Analysis path was selected. ContinueInputPath
        end
    end    
    %------------------       
    InputParamFile =  fullfile(inputPath, 'Force Overlays Parameters.mat');

%% --------  nargin 10, Maximum Traction Stress, Pa (maxInput) -------------------------------------------------------------------  
    if ~exist('maxInput','var'), maxInput = []; end              % this is necessary if you know what the max is ahread of it
    maxInput = -1;
    maxFrame = -1;
    minInput = Inf;
    
    if nargin < 10 || isempty(maxInput)     
%         try
%             minInput  = MD.findProcessTag(ProcessTag).tMapLimits_(1);
%             maxInput = MD.findProcessTag(ProcessTag).tMapLimits_(2);       
%         catch
            disp('Evaluating the maximum and minimum traction stress value in progress....')
            reverseString = ''; 
            for CurrentFrame = FramesDoneNumbers
                ProgressMsg = sprintf('\nEvaluating Frame #%d/%d...\n', CurrentFrame, FramesDoneNumbers(end));
                fprintf([reverseString, ProgressMsg]);
                reverseString = repmat(sprintf('\b'), 1, length(ProgressMsg));                
                if useGPU
                    FieldVec = gpuArray(forceField(CurrentFrame).vec);
                else
                    FieldVec = forceField(CurrentFrame).vec;
                end          
                FieldVecNorm = (FieldVec(:,1).^2+FieldVec(:,2).^2).^0.5;
                if nargin < 4 || isempty(maxInput)
                    [maxInput, maxInputIndex] = max([maxInput, max(FieldVecNorm)]);
                    if maxInputIndex == 2, maxFrame = CurrentFrame; end
                    minInput = min([minInput,min(FieldVecNorm)]);
                end
            end

%         end
%     else
%         msgbox('Make sure the entered Maximum Force is in Pa (Pascals.)')
    end
    fprintf('Maximum traction stress is %g Pa (pascals). \n', maxInput);
    disp('------------------------------------------------------------------------------')
   
    
    %% --------  nargin 7, ShowPlot (Yes/Y/1/On vs. No/N/0/Off)-------------------------------------------------------------------  
    if ~exist('showPlot','var'), showPlot = []; end
    if nargin < 7 || isempty(showPlot)
        %------------------
        dlgQuestion = 'Do you want to show tractions tracking in frames as they are made?';
        dlgTitle = 'Show Plots In Progress?';
        showPlotChoice = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No', 'Yes');
        %------------------
    elseif showPlot == 0 || strcmpi(showPlot, 'N') || strcmpi(showPlot, 'No') || strcmpi(showPlot, 'Off')
        showPlotChoice = 'No';
    elseif showPlot == 1 || strcmpi(showPlot, 'Y') || strcmpi(showPlot, 'Yes') || strcmpi(showPlot, 'On')
        showPlotChoice = 'Yes';
    end
    %------------------ 
    switch showPlotChoice
        case 'Yes'
            showPlot = 'on';
        case 'No'
            showPlot = 'off';
        otherwise
            return
    end
    
    %% --------  nargin 8, ShowVideo (vs. Images) (Yes/Y/1/Images/I vs. No/N/0/Video/V)-------------------------------------------------------------------  
    if ~exist('saveVideo','var'), saveVideo = []; end
    if nargin < 8 || isempty(saveVideo)
        TrackedTIFcount = 0; 
        TrackedJPEGcount = 0;
        TrackedFIGcount = 0;
        TrackedEPScount = 0;       
        %------------------
        dlgQuestion = 'Do you want to save as videos or as image sequence?';
        dlgTitle = 'Video vs. Image Sequence?';
        plotTypeChoice = questdlg(dlgQuestion, dlgTitle, 'Video', 'Images', 'Video');
        %------------------
    elseif saveVideo == 0 || strcmpi(saveVideo, 'N') ||  strcmpi(saveVideo, 'No')  ||  strcmpi(saveVideo, 'Images') 
        plotTypeChoice = 'Images';
    elseif saveVideo == 1 || strcmpi(saveVideo, 'Y')  ||  strcmpi(saveVideo, 'Yes')  ||  strcmpi(saveVideo, 'Video') ||  strcmpi(saveVideo, 'V') 
        plotTypeChoice = 'Video';
    else 
        errordlg('Invalid Plot Type Choice')
        return
    end
    %------------------
    switch plotTypeChoice
        case 'Video'
            saveVideo = true;
            %------------------
            dlgQuestion = 'Select video format.';
            listStr = {'Archival', 'Motion JPEG AVI', 'Motion JPEG 2000','MPEG-4','Uncompressed AVI','Indexed AVI','Grayscale AVI'};
            [VideoChoice, TF1] = listdlg('ListString', listStr, 'PromptString',dlgQuestion, 'InitialValue', 4, 'SelectionMode' ,'Single');   
            if TF1 == 0, return; end
            VideoChoice = listStr{VideoChoice};
        case 'Images'
            saveVideo = false;
            %------------------
            dlgQuestion = 'Select image format.';
            listStr = {'TIF', 'JPEG', 'FIG', 'EPS'};
            [ImageChoice, TF2] = listdlg('ListString', listStr, 'PromptString',dlgQuestion, 'InitialValue', 1, 'SelectionMode' ,'multiple');    
            if TF2 == 0, return; end
            ImageChoice = listStr(ImageChoice);                 % get the names of the string.   
            if  strcmp(plotTypeChoice, 'Images')
                for ii = 1:numel(ImageChoice)
                    tmpImageChoice =  ImageChoice{ii};
                    switch tmpImageChoice
                        case 'TIF'
                            TrackedPathTIF = fullfile(inputPath, 'Force Overlays TIF');
                            if ~exist(TrackedPathTIF,'dir'), mkdir(TrackedPathTIF); end
                            fprintf('Tracked Force Overlays Path - TIF is: \n\t %s\n', TrackedPathTIF);
                            try
                                clear TrackedFilesNum
                                TrackedFilesTIF =  dir(fullfile(TrackedPathTIF, '*.tif'));
                                for jj = 1:numel(TrackedFilesTIF) 
                                    NumberBlocks = regexp(TrackedFilesTIF(jj).name,'\d+');
                                    NumbersFromFileIndex = regexp(TrackedFilesTIF(jj).name,'\d');
                                    NumbersFromFileStartIndex = find(NumbersFromFileIndex == NumberBlocks(end));
                                    NumbersOfFile = NumbersFromFileIndex(NumbersFromFileStartIndex:end);
                                    TrackedFilesNum(jj) = str2double(TrackedFilesTIF(jj).name(NumbersOfFile));
                                end
                                TrackedTIFcount = max(TrackedFilesNum);
                            catch
                                TrackedTIFcount = 0;
                            end
                        case 'JPEG'
                            TrackedForceJPEG = fullfile(inputPath, 'Force Overlays JPEG');
                            if ~exist(TrackedForceJPEG,'dir'), mkdir(TrackedForceJPEG); end
                            fprintf('Tracked Force Overlays Path - JPEG is: \n\t %s\n', TrackedForceJPEG);
                            try
                                TrackedDisplacementPathJPEG =  dir(fullfile(TrackedDisplacementPathJPEG, '*.jpeg'));
                                for jj = 1:numel(TrackedDisplacementPathJPEG) 
                                    NumberBlocks = regexp(TrackedDisplacementPathJPEG(jj).name,'\d+');
                                    NumbersFromFileIndex = regexp(TrackedDisplacementPathJPEG(jj).name,'\d');
%                                     NumbersFromFileAll = regexp(TrackedDisplacementPathJPEG(jj).name,'[0-9]','match');
                                    NumbersFromFileStartIndex = find(NumbersFromFileIndex == NumberBlocks(end));
                                    NumbersOfFile = NumbersFromFileIndex(NumbersFromFileStartIndex:end);
                                    TrackedFilesNum(jj) = str2double(TrackedDisplacementPathJPEG(jj).name(NumbersOfFile));
                                end
                                TrackedJPEGcount = max(TrackedFilesNum);
                            catch
                                TrackedJPEGcount = 0;
                            end
                        case 'FIG'
                            TrackedPathFIG = fullfile(inputPath, 'Force Overlays FIG');
                            if ~exist(TrackedPathFIG,'dir'), mkdir(TrackedPathFIG); end
                            fprintf('Plotted Force Overlays Path - FIG is: \n\t %s\n', TrackedPathFIG);
                            try
                                TrackedFilesFIG =  dir(fullfile(TrackedPathFIG, '*.fig'));
                                clear TrackedFilesNum
                                for jj = 1:numel(TrackedFilesFIG) 
                                    NumberBlocks = regexp(TrackedFilesFIG(jj).name,'\d+');
                                    NumbersFromFileIndex = regexp(TrackedFilesFIG(jj).name,'\d');
                                    NumbersFromFileStartIndex = find(NumbersFromFileIndex == NumberBlocks(end));
                                    NumbersOfFile = NumbersFromFileIndex(NumbersFromFileStartIndex:end);
                                    TrackedFilesNum(jj) = str2double(TrackedFilesFIG(jj).name(NumbersOfFile));
                                end
                                TrackedFIGcount = max(TrackedFilesNum);
                            catch
                                TrackedFIGcount = 0;
                            end
                        case 'EPS'
                            TrackedPathEPS = fullfile(inputPath, 'Force Overlays EPS');
                            if ~exist(TrackedPathEPS,'dir'), mkdir(TrackedPathEPS); end
                            fprintf('Plotted Force Overlays Path - EPS is: \n\t %s\n', TrackedPathEPS);
                            try 
                                TrackedFilesEPS =  dir(fullfile(TrackedPathEPS, '*.eps'));
                                clear TrackedFilesNum
                                for jj = 1:numel(TrackedFilesEPS) 
                                    NumberBlocks = regexp(TrackedFilesEPS(jj).name,'\d+');
                                    NumbersFromFileIndex = regexp(TrackedFilesEPS(jj).name,'\d');
                                    NumbersFromFileStartIndex = find(NumbersFromFileIndex == NumberBlocks(end));
                                    NumbersOfFile = NumbersFromFileIndex(NumbersFromFileStartIndex:end);
                                    TrackedFilesNum(jj) = str2double(TrackedFilesEPS(jj).name(NumbersOfFile));
                                end
                                TrackedEPScount = max(TrackedFilesNum);
                            catch
                                TrackedEPScount = 0;
                            end
                    otherwise
                        return
                    end
                end
            end          
        otherwise
            return
    end
    disp('------------------------------------------------------------------------------')
    
    %% --------  nargin 9, Analysis Output Folder (AnalysisOutputPath)-------------------------------------------------------------------  
    if ~exist('AnalysisOutputPath','var'), analysisOutputPath = []; end    
    if nargin < 9 || isempty(analysisOutputPath)
        AnalysisTIFcount = 0;
        AnalysisJPEGcount = 0;
        AnalysisFIGcount = 0; 
        AnalysisEPScount = 0;
        %------------------
        dlgQuestion = ({'Do you want to save in an Analysis output folder?'});
        dlgTitle = 'Analysis folder?';
        AnalysisFolderChoice = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No', 'No');
        %------------------
        switch AnalysisFolderChoice
            case 'Yes'
                if ~exist('movieFilePath','var'), movieFilePath = pwd; end
                analysisOutputPath = uigetdir(movieFilePath,'Choose the analysis directory where the tracked output will be saved.');     
                if analysisOutputPath == 0  % Cancel was selected
                    clear AnalysisOutputPath;
                elseif ~exist(analysisOutputPath,'dir')   % Check for a directory
                    mkdir(analysisOutputPath);              
                end    
                if strcmp(plotTypeChoice, 'Images') && exist('AnalysisOutputPath', 'var')       
                    for ii = 1:numel(ImageChoice)
                        tmpImageChoice =  ImageChoice{ii};
                        switch tmpImageChoice
                            case 'TIF'
                                AnalysisPathTIF = fullfile(analysisOutputPath, '09 Force Overlays TIF');
                                if ~exist(AnalysisPathTIF,'dir'), mkdir(AnalysisPathTIF); end
                                fprintf('Analysis Tracked Force Overlays Path - TIF is: \n\t %s\n', AnalysisPathTIF);
                                try
                                    AnalysisFilesTIF =  dir(fullfile(AnalysisPathTIF, '*.tif'));
                                    clear TrackedFilesNum
                                    for jj = 1:numel(AnalysisFilesTIF) 
                                        NumberBlocks = regexp(AnalysisFilesTIF(jj).name,'\d+');
                                        NumbersFromFileIndex = regexp(AnalysisFilesTIF(jj).name,'\d');
                                        NumbersFromFileStartIndex = find(NumbersFromFileIndex == NumberBlocks(end));
                                        NumbersOfFile = NumbersFromFileIndex(NumbersFromFileStartIndex:end);
                                        TrackedFilesNum(jj) = str2double(AnalysisFilesTIF(jj).name(NumbersOfFile));
                                    end
                                    AnalysisTIFcount = max(TrackedFilesNum);
                                catch
                                    AnalysisTIFcount = 0;
                                end
                            case 'JPEG'
                                clear TrackedFilesNum
                                AnalysisJPEG = fullfile(analysisOutputPath, '09 Force Overlays JPEG');
                                if ~exist(AnalysisJPEG,'dir'), mkdir(AnalysisJPEG); end
                                fprintf('Analysis Tracked Force Overlays  Path - JPEG is: \n\t %s\n', AnalysisJPEG);
                                try
                                    AnalysisFilesJPEG =  dir(fullfile(AnalysisJPEG, '*.jpeg'));
                                    for jj = 1:numel(AnalysisFilesJPEG) 
                                        NumberBlocks = regexp(AnalysisFilesJPEG(jj).name,'\d+');
                                        NumbersFromFileIndex = regexp(AnalysisFilesJPEG(jj).name,'\d');
                                        NumbersFromFileStartIndex = find(NumbersFromFileIndex == NumberBlocks(end));
                                        NumbersOfFile = NumbersFromFileIndex(NumbersFromFileStartIndex:end);
                                        TrackedFilesNum(jj) = str2double(AnalysisFilesJPEG(jj).name(NumbersOfFile));
                                    end
                                    AnalysisJPEGcount = max(TrackedFilesNum);
                                catch
                                    AnalysisJPEGcount = 0;
                                end
                            case 'FIG'
                                AnalysisPathFIG = fullfile(analysisOutputPath, '09 Force Overlays FIG');
                                if ~exist(AnalysisPathFIG,'dir'), mkdir(AnalysisPathFIG); end
                                fprintf('Analysis Tracked Force Overlays Path - FIG is: \n\t %s\n', AnalysisPathFIG);
                                try
                                    AnalysisFilesFIG =  dir(fullfile(AnalysisPathFIG, '*.fig'));
                                    clear TrackedFilesNum
                                    for jj = 1:numel(AnalysisFilesFIG) 
                                        NumberBlocks = regexp(AnalysisFilesFIG(jj).name,'\d+');
                                        NumbersFromFileIndex = regexp(AnalysisFilesFIG(jj).name,'\d');
                                        NumbersFromFileStartIndex = find(NumbersFromFileIndex == NumberBlocks(end));
                                        NumbersOfFile = NumbersFromFileIndex(NumbersFromFileStartIndex:end);
                                        TrackedFilesNum(jj) = str2double(AnalysisFilesFIG(jj).name(NumbersOfFile));
                                    end
                                    AnalysisFIGcount = max(TrackedFilesNum);
                                catch
                                    AnalysisFIGcount = 0;
                                end
                            case 'EPS'
                                AnalysisPathEPS = fullfile(analysisOutputPath, '09 Force Overlays EPS');
                                if ~exist(AnalysisPathEPS,'dir'), mkdir(AnalysisPathEPS); end
                                fprintf('Analysis Tracked Force Overlays Path - EPS is: \n\t %s\n', AnalysisPathEPS);
                                try
                                    AnalysisFilesEPS =  dir(fullfile(AnalysisPathEPS, '*.eps'));
                                    for jj = 1:numel(AnalysisFilesEPS) 
                                        NumberBlocks = regexp(AnalysisFilesEPS(jj).name,'\d+');
                                        NumbersFromFileIndex = regexp(AnalysisFilesEPS(jj).name,'\d');
                                        NumbersFromFileStartIndex = find(NumbersFromFileIndex == NumberBlocks(end));
                                        NumbersOfFile = NumbersFromFileIndex(NumbersFromFileStartIndex:end);
                                        TrackedFilesNum(jj) = str2double(AnalysisFilesEPS(jj).name(NumbersOfFile));
                                    end
                                    AnalysisEPScount = max(TrackedFilesNum);
                                catch
                                    AnalysisEPScount = 0;
                                end
                            otherwise
                                return
                        end
                    end
                end
            %------------------
            case 'No'
                % continue. Do nothing
            otherwise
                return
        end               
    end
    
     %% -------- nargin 11, Full Resolution (Yes/Y/1 vs. No/N/0)-------------------------------------------------------------------  
    if ~exist('FullResolution','var'), FullResolution = []; end
    if nargin < 12 || isempty(FullResolution)
        dlgQuestion = 'Do you want to retain the full resolution of the images, or let MATLAB scale it to fit the screen?';
        dlgTitle = 'Retain Full Resolution?';
        FullResolutionChoice = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No', 'Yes');
        switch FullResolutionChoice
            case 'Yes'
                FullResolution = 1;
                showPlot = 1;          
                warning('Full Resolution works only if ShowPlot is ''on''!');                
            case 'No'
                FullResolution = 0;
            otherwise
                return
        end        
        %------------------
    elseif FullResolution == 0 || strcmpi(FullResolution, 'N') ||  strcmpi(FullResolution, 'No')  
        FullResolution = 0;
    elseif FullResolution == 1 || strcmpi(FullResolution, 'Y')  ||  strcmpi(FullResolution, 'Yes')
        FullResolution = 1;
    else 
        errordlg('Invalid Choice')
        return
    end
    FullResolution = logical(FullResolution);               % convert to logical. Just to speed up process   
    
    %% --------  nargin 3, FirstFrame. Check for previously plotted images -------------------------------------------------------------------  
    if ~exist('FirstFrame','var'), FirstFrame = []; end
    if nargin < 3 || isempty(FirstFrame)
        switch plotTypeChoice
            case 'Images'
                FramesTrackedCountMax = max([TrackedTIFcount, TrackedJPEGcount, TrackedFIGcount, TrackedEPScount, ...
                    AnalysisTIFcount, AnalysisJPEGcount, AnalysisFIGcount, AnalysisEPScount]);
                try
                    FramesTrackedMax = FramesDoneNumbers(FramesTrackedCountMax);
                catch
                    FramesTrackedMax = 0;
                end
                %------------------
                if FramesTrackedMax == 0
                    FirstFrame =  VeryFirstFrame;
                elseif FramesTrackedMax == VeryLastFrame
                    %------------------
                    dlgQuestion = ({'All frames have been previously plotted. Do you want to start from the beginning again?'});
                    dlgTitle = 'Re-plot Frames?';
                    RePlotFramesChoice = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No', 'Yes');
                    %------------------
                    switch RePlotFramesChoice
                        case 'Yes'
                            FirstFrame =  VeryFirstFrame;
                        case 'No'
                            return;
                    end
                else
                    FirstFrame = FramesTrackedMax + FramesDifference(end);              % Frame next to last frame plotted
                    if FirstFrame > VeryLastFrame
                        FirstFrame = VeryLastFrame;
                    end
                end
            %------------------
            case 'Video'
                FirstFrame =  VeryFirstFrame;
            otherwise
                return
        end
        %------------------     
        prompt = {sprintf('Choose the first plotted frame. [Default, frame next to last frame plotted so far = %d]', FirstFrame)};
        dlgTitle = 'First Frame Calculated Traction Overlays To Be Plotted';
        FirstFrameStr = inputdlg(prompt, dlgTitle, [1, 90], {num2str(FirstFrame)});
        if isempty(FirstFrameStr), return; end
        FirstFrame = str2double(FirstFrameStr{1});                                  % Convert to a number
        %------------------
        [~, FirstFrameIndex] = min(abs(FramesDoneNumbers - FirstFrame));
        FirstFrame = FramesDoneNumbers(FirstFrameIndex);        
    end
    fprintf('First Frame To be Plotted = %d/%d\n', FirstFrame, VeryLastFrame);
    
    %% --------  nargin 4, LastFrame. Check for last known plotted images ------------------------------------------------------------------
    if ~exist('LastFrame', 'var'), LastFrame = []; end
    if nargin < 4 || isempty(LastFrame)
        LastFrame = VeryLastFrame;
        prompt = {sprintf('Choose the last frame to plotted. [Default = %d]', LastFrame)};
        dlgTitle = 'Last Frame To Be Plotted';
        LastFrameStr = inputdlg(prompt, dlgTitle, [1, 50], {num2str(LastFrame)});
        if isempty(LastFrameStr), return; end
        LastFrame = str2double(LastFrameStr{1});                                  % Convert to a number
        [~, LastFrameIndex] = min(abs(FramesDoneNumbers - LastFrame));            % choose a non-empty frame
        LastFrame = FramesDoneNumbers(LastFrameIndex);
    end
    fprintf('Last Frame To Be Tracked = %d/%d\n', LastFrame, VeryLastFrame);
    disp('------------------------------------------------------------------------------') 
    
    FramesToBePloted = FramesDoneNumbers(FirstFrameIndex:LastFrameIndex);
    
    %% ======  total points interpolated ============================================================      
    totalPointsInterpolated = size(forceField(VeryFirstFrame).pos, 1);
        
    %% ======  Set up video writer object ============================================================
    try 
        FrameRateOriginal = 1/MD.timeInterval_;
    catch
        FrameRateOriginal = 1/ 0.025;           % (40 frames per seconds)              
    end
    prompt = {sprintf('Choose the Frame Rate per second for this movie. [Default, %.4f]', FrameRateOriginal)};
    dlgTitle =  'Frames Per Second';
    FrameRateStr = inputdlg(prompt, dlgTitle, [1, 90], {num2str(FrameRateOriginal)});
    if isempty(FrameRateStr), return; end
    FrameRateOriginal = str2double(FrameRateStr{1});                                  % Convert to a number                            
    FramesTimestampsSec = FramesDoneNumbers / FrameRateOriginal;
    FramesTimestampsSec = FramesTimestampsSec - FramesTimestampsSec(1);
    FrameRateActual = 1/mean(FramesTimestampsSec(2:end) - FramesTimestampsSec(1:end-1));

    if saveVideo == 1
        finalSuffix = 'Force Overlays';
        videoFile = fullfile(inputPath, finalSuffix);        
        writerObj = VideoWriter(videoFile, VideoChoice);        
        try
            writerObj.FrameRate = FrameRateActual; 
        catch
            writerObj.FrameRate = 40; 
        end                    
        %-----------------------------------------------------------------------------------------------
        try
            if exist(analysisOutputPath, 'dir')
                finalSuffixAnalysis = '09 Force Overlays';                       % Need to double check this one.
                videoFileAnalysis = fullfile(analysisOutputPath, finalSuffixAnalysis);                     
                writerObjAnalysis = VideoWriter(videoFileAnalysis, VideoChoice);
               try
                    writerObjAnalysis.FrameRate = FrameRateActual; 
                catch
                    writerObjAnalysis.FrameRate = 40; 
               end    
            end
        catch
            % do nothing
        end
    end 
    
    %% ======  Check for GPU & Save parameters so far ============================================================  
   disp('------------------------- Starting generating the plotted image sequence. ---------------------------------------------------')   
    if useGPU
        maxInput = gather(maxInput);
        minInput = gather(minInput);
    end
    InputUnits = 'Pa';
    save(InputParamFile, 'FirstFrame', 'LastFrame', 'maxInput', 'minInput', 'InputUnits', ...
       'totalPointsInterpolated', '-v7.3')
    try 
        save(InputParamFile,'VeryLastFrame', '-append')
    catch
       % Do not add if it is not visible.
    end
            
    %% --------  nargin 6, ShowQuiver (Yes/Y/1 vs. No/N/0)-------------------------------------------------------------------   
    if ~exist('showQuiver','var'), showQuiver = []; end
    if nargin < 6 || isempty(showQuiver)
        %------------------
        dlgQuestion = 'Do you want to show traction stress quivers?';
        dlgTitle = 'Show Quivers?';
        QuiverChoice = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No', 'No');
        %------------------
    elseif showQuiver == 0 || strcmpi(showQuiver, 'N') || strcmpi(showQuiver, 'No')
        QuiverChoice = 'No';
    elseif showQuiver == 1 || strcmpi(showQuiver, 'Y') || strcmpi(showQuiver, 'Yes')
        QuiverChoice = 'Yes';
    end
    %------------------       
    QuiverScaleToMax = [];
    %------------------           
    switch QuiverChoice
        case 'Yes'
            showQuiver = true;
            TotalAreaPixel = (max(forceField(VeryFirstFrame).pos(:,1)) -  min(forceField(VeryFirstFrame).pos(:,1))) * ...
                (max(forceField(VeryFirstFrame).pos(:,2)) -  min(forceField(VeryFirstFrame).pos(:,2)));                 % x-length * y-length
            AvgInterBeadDist = sqrt(4*(TotalAreaPixel)/size(forceField(VeryFirstFrame).pos,1));        % avg inter-bead separation distance = total img area/number of tracked points
            QuiverScaleDefault = 0.95 * (AvgInterBeadDist/maxInput) * QuiverMagnificationFactor;
            prompt = {sprintf('Define the quiver scaling factor, [Currently 1X = %g ]', QuiverScaleDefault)};
            dlgTitle = 'Quiver Scale Factor';
            QuiverMagnificationFactorDefault = {num2str(QuiverMagnificationFactor)};
            QuiverMagnificationFactor = inputdlg(prompt, dlgTitle, [1, 70],  QuiverMagnificationFactorDefault);        % Modified on 2020-01-17            
            if isempty(QuiverMagnificationFactor), return; end
            QuiverMagnificationFactor = str2double(QuiverMagnificationFactor{1});                                  % Convert to a number                
            QuiverScaleFactor = QuiverScaleDefault * QuiverMagnificationFactor;                                 %quiver plot maximum and scale
            QuiverScaleToMax = QuiverScaleFactor;
        case 'No'
            showQuiver = false;  
        otherwise
            return
    end
    %%
    try
        ImageBits = MD.camBitdepth_ - 2;   % Typically if 16 bits are used. Then image will be saved in 14 bits.
    catch
        ImageBits = 14;
    end
    TxRedColorMap =  [linspace(0,1,2^ImageBits)', zeros(2^ImageBits,2)];                   % TexasRed ColorMap for Epi Images.    
    ImageSizePixels = MD.imSize_;     
    MarkerSize = round(ImageSizePixels(1)/ 1000, 1, 'decimals');
            
    switch QuiverChoice
        case 'Yes'
            X = forceField(maxFrame).pos(:,1);
            Y = forceField(maxFrame).pos(:,2);
            U = forceField(maxFrame).vec(:,1);
            V = forceField(maxFrame).vec(:,2);

            FigRenderer = 'painters';

            figHandle = figure('visible',showPlot, 'color', 'w', 'MenuBar','none', 'Toolbar','none', 'Units', 'pixels', 'Resize', 'off', 'Renderer', FigRenderer);     % added by WIM on 2019-09-14. To show, remove 'visible
            figAxesHandle = axes;
            set(figAxesHandle, 'Box', 'on', 'XTick',[], 'YTick', [], 'Visible', 'on', 'YDir', 'reverse');
            set(figAxesHandle, 'Units', 'pixels');

            try
                curr_Image = MD.channels_.loadImage(maxFrame);
            catch
                BioformatsPath = uigetdir([], 'Select directory containing bioformats folder (e.g., TFMpackagefolder)');
                addpath(genpath(BioformatsPath));        % include subfolders
                curr_Image = MD.channels_.loadImage(maxFrame);
            end
            if useGPU
                curr_Image = gpuArray(curr_Image);
            end 

            % Adjust contrast so that the bottom 5% (dark faint noise is not showing and showing all intense images).
            curr_ImageAdjust = imadjust(curr_Image, stretchlim(curr_Image,[0.05,0.999]));    
            % display the adjusted image       

            imagesc(figAxesHandle,  1, 1, curr_ImageAdjust)
            axis image
            truesize
            hold on

            colormap(TxRedColorMap)

            quiverNotOK = true;

            while quiverNotOK
                qHandle = quiver(figAxesHandle, X, Y, U .*QuiverScaleToMax, V .*QuiverScaleToMax, 0, ...
                   'MarkerSize',MarkerSize, 'markerfacecolor','y', 'ShowArrowHead','on', 'MaxHeadSize', 3, ...
                  'color','y', 'AutoScale','off', 'LineWidth', QuiverLineWidth , 'AlignVertexCenters', 'on');
                IsQuiverOK = questdlg('Are the plot quivers looking OK?', 'Quiver OK?', 'Yes', 'No', 'Yes');
                switch IsQuiverOK
                    case 'Yes'
                        close(figHandle);
                        quiverNotOK = false;
                    case 'No'
                        disp('**___to continue, type "dbcont" or press "F5", or click "Continue" under "Editor" Menu___**')
                        keyboard
                        
                        prompt = {sprintf('Enter the quiver magnification factor that you want. [Currently = %g]', QuiverMagnificationFactor)};
                        dlgTitle = 'QuiverScale';
                        QuiverMagnificationFactorStr = {num2str(QuiverMagnificationFactor)};
                        QuiverMagnificationFactorStr = inputdlg(prompt, dlgTitle, [1 40], QuiverMagnificationFactorStr);
                        QuiverMagnificationFactor = str2double(QuiverMagnificationFactorStr{:}); 
                        QuiverScaleToMax = QuiverScaleDefault * QuiverMagnificationFactor;                                 %quiver plot maximum and scale
                        delete(qHandle)
                    otherwise 
                        return
                end
            end    
            if useGPU, QuiverScaleToMax = gather(QuiverScaleToMax); end
            save(InputParamFile,  'QuiverScaleToMax', '-append')
    end
    
    %% ======  Plotting Overlays Now ============================================================  
    disp('------------------------- Starting generating the plotted image sequence. ---------------------------------------------------');
    FirstFrameNow = true; 
    for CurrentFrame = FramesToBePloted   
        if mod(CurrentFrame, 10 * FramesDifference(1)) == 0 || FirstFrameNow == true                  % close figHandle every 30 samples to prevent memory overflow.
            try
                clf(figHandle, 'reset')
                set(figHandle, 'visible',showPlot, 'color', 'w', 'Toolbar','none', 'Menubar','none', 'Units', 'pixels', 'Resize', 'off');    % added by WIM on 2019-09-14. To show, remove                  
            catch
               % No figure Exists, continue 
            end
            FirstFrameNow = false;  
            if ~exist('figHandle', 'var')            
                figHandle = figure('visible',showPlot, 'color', 'w', 'Toolbar','none', 'Menubar','none', 'Units', 'pixels', 'Resize', 'off');     % added by WIM on 2019-09-14. To show, remove 'visible
            end
            reverseString = '';
            axis image
            figAxesHandle = findobj(figHandle, 'type',  'Axes');    
            WindowAPI_used = false;       

            
            if FullResolution

                try
%                     fprintf('Using WindowAPI.m to resize the window to plot full resolution images with overlays.\n');
                    %---------Matlab 2014 and higher
                    ScreenSize = get(0, 'Screensize');          

                    WindowAPI(figHandle, 'Position', [50, (ScreenSize(4) - ImageSizePixels(2) - 50), ImageSizePixels(1), ImageSizePixels(2)])           % Downloaded from MATLAB Website
                    WindowAPI_used = true;
                catch
                    fprintf('Using MATLAB internal functions. Might not work to plot full resolution images with overlays. Check resolution of final output.\n');
                    ScreenWorkArea = images.internal.getWorkArea;       
                    set(figHandle, 'Position',  [50, -(ImageSizePixels(2) - ScreenWorkArea.top) ,ImageSizePixels(1), ImageSizePixels(2)]);
                    matlab.ui.internal.PositionUtils.setDevicePixelPosition(figHandle,  [50, -(ImageSizePixels(2) - ScreenWorkArea.top) ,ImageSizePixels(1), ImageSizePixels(2)]);
        %             matlab.ui.internal.PositionUtils.setDevicePixelPosition(gca, [1,1, ImageSizePixels(1), ImageSizePixels(2)]);
                end
                set(figAxesHandle, 'Units', 'pixels', 'Position', [1, 1,  ImageSizePixels(1), ImageSizePixels(2)], 'Box', 'off', 'TickLength', [0, 0], 'Visible', 'off');
             end  
        end
        ProgressMsg = sprintf('\nCreating Frame #%d/%d...\n', CurrentFrame, LastFrame);
        fprintf([reverseString, ProgressMsg]);
        reverseString = repmat(sprintf('\b'), 1, length(ProgressMsg));
    %-----------------------------------------------------------------------------------------------       
        try
            curr_Image = MD.channels_.loadImage(CurrentFrame);
        catch
            BioformatsPath = uigetdir([], 'Select directory containing bioformats folder (e.g., TFMpackagefolder)');
            addpath(genpath(BioformatsPath));        % include subfolders
            curr_Image = MD.channels_.loadImage(CurrentFrame);
        end
        if useGPU
            curr_Image = gpuArray(curr_Image);
        end
    
        % Adjust contrast so that the bottom 5% (dark faint noise is not showing and showing all intense images).
        curr_ImageAdjust = imadjust(curr_Image, stretchlim(curr_Image,[0.05,0.999]));    
        % display the adjusted image

        if FullResolution
            if WindowAPI_used 
                imagesc(figAxesHandle, 1, 1, curr_ImageAdjust);
%             image(figAxesHandle, 1, 1, curr_ImageAdjust, 'cDataMapping', 'scaled')                     % Scale to the right size
            else
                figHandle = imshow(curr_ImageAdjust, 'Initialmagnification', 'fit');
            end
        else
            figHandle = imshow(curr_ImageAdjust);  
%         figHandle = imshow(curr_Image, []);          % display all images autocontrasted for whole range. Use Texas Red Imaging
        end
        set(figAxesHandle, 'Box', 'off', 'TickLength', [0, 0], 'Visible', 'off');       
        colormap(TxRedColorMap);
        hold on        
        %-----------------------------------------------------------------------------------------------        
        if useGPU
            forceFieldPos = gpuArray(forceField(CurrentFrame).pos);
            FieldVec = gpuArray(forceField(CurrentFrame).vec);
        else
            forceFieldPos = forceField(CurrentFrame).pos;
            FieldVec = forceField(CurrentFrame).vec;
        end        
        %-----------------------------------------------------------------------------------------------        
        if ~isempty(forceField(CurrentFrame).vec)
            if showQuiver
                pause(0.1)
                set(figAxesHandle, 'CameraPositionMode', 'manual', 'CameraTargetMode', 'manual', 'CameraUpVectorMode', 'manual', 'CameraViewAngleMode', 'auto')       % Added by WIM on 2019-10-02
                quiver(figAxesHandle, forceFieldPos(:,1),forceFieldPos(:,2), FieldVec(:,1) * QuiverScaleToMax, FieldVec(:,2) * QuiverScaleToMax, 'MarkerSize',1, 'MarkerFaceColor','w', 'ShowArrowHead','on', 'MaxHeadSize', 3 , 'LineWidth', 1 ,  'color','y', 'AutoScale','off');                 
            else
                plot(figAxesHandle, forceField(CurrentFrame).pos(:,1) + forceField(CurrentFrame).vec(:,1), forceField(CurrentFrame).pos(:,2) + forceField(CurrentFrame).vec(:,2), 'wo', 'MarkerSize',1);  
            end
        else    % no tracked force anymore
            break
        end
        %-----------------------------------------------------------------------------------------------   
        try
            ImageFileNames = MD.getImageFileNames;
            chanelIndex = 1;          % for now. For later code with mulitiple channels, this will need to be updated. WIM 2019-05-31.
            CurrentImageFullname = fullfile(analysisOutputPath, ImageFileNames{chanelIndex}{CurrentFrame}); 
            [~, CurrentImageFileName, ~] =  fileparts(CurrentImageFullname);
        catch
            errordlg('Image File Names for Frames not found. Update code to include calling bfreader() of bioformats.')
            return
        end        
        %-----------------------------------------------------------------------------------------------           .
        % convert the image to a frame\
        if ~exist('figHandle', 'var')
            figHandle = figure('visible',showPlot, 'color', 'w', 'Units', 'pixels','Toolbar','none', 'Menubar','none');     % added by WIM on 2019-02-07. To show, remove 'visible
            figAxesHandle = findobj(figHandle, 'type',  'Axes');    
            axis image
            set(figAxesHandle, 'Units', 'pixels', 'Position', [1, 1,  ImageSizePixels(1), ImageSizePixels(2)], 'Box', 'off', 'TickLength', [0, 0], 'Visible', 'off');
        end
        ImageHandle = getframe(figHandle);     
        Image_cdata = ImageHandle.cdata;
        if  saveVideo
            % open the video writer
            open(writerObj);            

            % Need some fixing 3/3/2019
            writeVideo(writerObj, Image_cdata);
            if exist('AnalysisOutputPath', 'var')
                if exist(analysisOutputPath,'dir')
                    open(writerObjAnalysis);                          
                    writeVideo(writerObjAnalysis, Image_cdata);
                end
            end
        %-----------------------------------------------------------------------------------------------    
        else
                % ==================================================================================
    % Anonymous function to append the file number to the file type. 
            if ~exist('CurrentImageFileName','var')
                fString = ['%0' num2str(floor(log10(LastFrame))+1) '.f'];
                FrameNumSuffix = @(frame) num2str(frame,fString);
                CurrentImageFileName = strcat('TrackedForceOverlay', FrameNumSuffix(CurrentFrame));
            end

            for ii = 1:numel(ImageChoice)
                tmpImageChoice =  ImageChoice{ii};
                switch tmpImageChoice
                    case 'TIF'
                        TrackedForcePathTIFname = fullfile(TrackedPathTIF, [CurrentImageFileName , '.tif']);
                        imwrite(Image_cdata, TrackedForcePathTIFname);
                        if exist('AnalysisOutputPath', 'var')
                            if exist(analysisOutputPath,'dir')
                                AnalysisForcePathTIFname = fullfile(AnalysisPathTIF,[CurrentImageFileName, '.tif']);
                                imwrite(Image_cdata, AnalysisForcePathTIFname); 
                            end               
                        end
                     case 'JPEG'
                        TrackedForcePathJPEGname = fullfile(TrackedForcePathJPEG, [CurrentImageFileName , '.jpeg']);
                        imwrite(Image_cdata, TrackedForcePathJPEGname);
                        if exist('AnalysisOutputPath', 'var')
                            if exist(analysisOutputPath,'dir')
                                AnalysisForcePathJPEGname = fullfile(AnalysisJPEG, [CurrentImageFileName, '.jpeg']);
                                imwrite(Image_cdata, AnalysisForcePathJPEGname); 
                            end               
                        end         
                    case 'FIG'
                        TrackedForcePathFIGname = fullfile(TrackedPathFIG,[CurrentImageFileName, '.fig']);
                        savefig(figHandle, TrackedForcePathFIGname,'compact')
                        if exist('AnalysisOutputPath', 'var')
                            if exist(analysisOutputPath,'dir')
                                AnalysisForcePathTIFname = fullfile(AnalysisPathFIG,[CurrentImageFileName, '.fig']);
                                savefig(figHandle, AnalysisForcePathTIFname,'compact')
                            end 
                        end
                    case 'EPS'
                        TrackedForcePathEPSname = fullfile(TrackedPathEPS,[CurrentImageFileName, '.eps']);               
                        print(figHandle, TrackedForcePathEPSname,'-depsc')   
                        if exist('AnalysisOutputPath', 'var')
                            if exist(analysisOutputPath,'dir')
                                AnalysisForcePathEPSname = fullfile(AnalysisPathEPS,[CurrentImageFileName, '.eps']);               
                                print(figHandle, AnalysisForcePathEPSname,'-depsc')   
                            end              
                        end
                     otherwise
                         return   
                end
            end
        end
    end
    %% ======  Close video writer objects & ImageHandle =======================================================
    try
        close(writerObj)
        close(writerObjAnalysis)
    catch
       % Do nothing 
    end
    try 
        close(ImageHandle);
    catch 
        % do nothing
    end
          
%% ==================================================================================
%     if ispc     % opening file explorer externally to see those individual files
%         if exist('AnalysisOutputPath', 'var') 
%             try 
%                 winopen(AnalysisOutputPath);
%             catch
%                 warning('could not open the analysis folder directory')
%             end
%         end
% 
%     elseif isunix
%         disp('INCOMPLETE CODE in UNIX')
%     elseif ismac
%         disp('INCOMPLETE CODE in Mac')
%     else
%         disp('Platform not supported')
%     end    
%     disp('-------------------------- Finished generated tracked tractions --------------------------')
    
end


%% ======================================= CODE DUMPSTER ============================
%     if nGPU > 0
%         dlgQuestion = 'Do you want to use GPU-Acceleration?';
%         dlgTitle = 'Use GPU?';
%         useGPUchoice = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No', 'Yes');
%         switch useGPUchoice
%             case 'Yes'
%                 useGPU = true;
%             case 'No'
%                 useGPU = false;
%             otherwise
%                 return;
%         end        
%     else
%         useGPU = false; 
%     end

%---------------------------------------------------------