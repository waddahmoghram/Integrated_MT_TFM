%{
    v.2020-10-24 by Waddah Moghram, PhD Student in Biomedical Engineering at the University of Iowa.
        1. Add Flux Status to output video
    v.2020-08-25 by Waddah Moghram, 
        1. Give user the option to control the line width of the scalebar

    v,2020-07-22 by Waddah Moghram, PhD Student in Biomedical Engineering at the University of Iowa.
        1. Fixed glitch with FramesDifference being empty if one frame is fed

    v.2020-06-04 by Waddah Moghram
        1. Allow user to insert the timestamps into a user-chosen location

    v.2020-04-15 by Waddah Moghram
        1. Added support for multiple channels and to choose the channel of interest for the fluorescent beads
        2. Added support to adjust the histogram percentiles

    v.2020-02-12 by Waddah Moghram
        1. Tried solving the memory leak problem with the RAM by deleting objects in the 
        figure to no avail. Just close MATLAB after a single run.
    v.2020-02-09 by Waddah Moghram
        1. Added a scale bar to be included with the heatmap
        2. updated the export option to *.eps that can be customized using 
            exportfig.m

    v.2020-02-03 by Waddah Moghram
        1. Added a step ask the user if the quiver size is OK or not. 
        2. change the heatmap max to match that of the maximum displacement frame, and not of the raw displacements. 

    v.2020-01-28 by Waddah Moghram
        1. Updated quiver scale to use multiples of suggested one instead of entering exact number?

    v.2020-01-17 by Waddah Moghram
        1. QuiverMagnificationFactor = 2;              % Added on 2020-01-17

    v.2019-12-18 by Waddah Moghram
        1. Fixed FirstFrame error if starting from the middle

    v.2019-12-02 by Waddah Moghram
        1. Fixed the Plot() error if no quivers are used.

    v.2019-10-23 by Waddah Moghram
        1. Plot without figure stealing focus. Use clf(figHandle, 'reset'), and ...

    v.2019-10-13 by Waddah Moghram
        1. Added set(figHandleAxes, 'YDir', 'reverese') to make sure that the top-left corner is the origin for images.

    v.2019-10-02...07 by WIM
        1. Fixed the problem of the quiver rescaling the image. Set the Camera View to Manual after the plot.
        2. Figure out an autoscale based on average bead separation distance (90% of that)
        3. Moved up nargin 11 (max displacement) filter ahead of quiver 
        4. Fixed Analysis Output

    v.2019-09-21|24
        1. changed getframe(figHandle) to getframe(figAxesHandle)
        2. Added the part where it closes the figure and creates a new one every 30 frames to reduce RAM and GPU Memory usage.
        3. elminated using "undecorate.m"
    v.2019-09-12..14
        1. Allow the option to not resize the image to retain the full resoultion for the image overlay.
        2. Use "undecorate.m" to remove title bar, and all stuff. To re-show them, user "redecorate.m"
    v.2019-09-09 
        1. improve the output to be more consistent.
        2. Added a *.mat file to save key parameters.

    v2019-06-26 Update. Written by Waddah Moghram
        1. Fixed big with AnalysisOutput files, and names.

    v2019-06-14 Update. Written by Waddah Moghram
        1. Update glitch with displField argument input parsing

    v2.00
    generatedTrackedDisplacement use dot to track the tracked beads. Quivers are also possible.
    for now, just run by giving no arguments, or up to the first 4 arguments.
    Needs to be fixed for certain input arguments, as they generate error messages.

    Written by Waddah Moghram, PhD Student in Biomedical Engineering. Updated on 2019-05-19, 2019-06-12
        2019-06-04 Renamed "generatedTrackedDisplacement.m" --->  "PlotDisplacementOverlays.m"
        For future edition, think about embedding a colormap in the video along with cData.         
            MD = movie data object
            displField = displacement field structure
                .pos = position (x,y) of beads
                .vec = vector (u,v) of beads
            FirstFrame
            LastFrame
            ShowPlot = 'on' or 'off'
            saveVideo = 0 or 1 (or false/true)
            showQuiver = 0 or 1 (or false/true)
    %}

%% --------   Function Begins here -------------------------------------------------------------------  
function [MD, displField, FirstFrame, LastFrame, movieFilePath, outputPath, analysisOutputPath, MagnificationTimes] = PlotDisplacementOverlays(MD, displField, FirstFrame, LastFrame, ...
    outputPath, MagnificationTimes, showQuiver, showPlot, saveVideo, analysisOutputPath, maxInput, FullResolution)

    QuiverMagnificationFactor = 2;              % Added on 2020-01-17
    QuiverLineWidth = 0.5;
    FigRenderer = 'painters';                   % other option is openGL
    PlotsFontName = 'XITS';   
    reverseString = '';
    FramesAtOnce = 10;
    scalebarFontSize = 10;
        
        %____ parameters for exportfig to *.eps
    EPSparam = struct();
    EPSparam.Bounds = 'tight';          % tight bounding box instead of loose.
    EPSparam.Color = 'rgb';             % rgb good for online stuff. cmyk is better for print.
    EPSparam.Renderer = 'Painters';     % instead of opengl, which is better for vectors
    EPSparam.Resolution = 600;          % DPI
    EPSparam.LockAxes = 1;              % true
    EPSparam.FontMode = 'fixed';        % instead of scaled
    EPSparam.FontSize = 10;             % 10 points
    EPSparam.FontEncoding = 'latin1';   % 'latin1' is standard for Western fonts. vs 'adobe'
    EPSparam.LineMode = 'fixed';        % fixed is better than scaled. 
    EPSparam.LineWidth = 1;             % can be varied depending on what you want it to be    
    
    EPSparams = {};
    EPSparamsFieldNames = fieldnames(EPSparam);
    for ii = (1:numel(fieldnames(EPSparam)))
        EPSparams{2*ii - 1} = EPSparamsFieldNames{ii};
    end
    for ii = (1:numel(fieldnames(EPSparam)))
        EPSparams{2*ii} = EPSparam.(EPSparamsFieldNames{ii});
    end
    
    %% ========  Check for extra nargin ============================================================  
    if nargin > 12
        errordlg('Too many arguments in this function, or wrong argument structure!')
        return
    end 
    
    %% ========  Check if there is a GPU. take advantage of it if is there. ============================================================  
    nGPU = gpuDeviceCount;
    if nGPU > 0
        useGPU = true;
    else
        useGPU = false;
    end
    
    disp('============================== Running PlotDisplacementOverlays.m GPU-enabled ===============================================')
    
    %% --------  nargin 1, Movie Data (MD) by TFM Package -------------------------------------------------------------------  
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
    
    %% --------  nargin 2, displacement field (displField) -------------------------------------------------------------------    
    if ~exist('displField','var'), displField = []; end
    if nargin < 2 || isempty(displField)
        try 
            ProcessTag =  MD.findProcessTag('DisplacementFieldCorrectionProcess').tag_;
        catch
            try 
                ProcessTag =  MD.findProcessTag('DisplacementFieldCalculationProcess').tag_;
            catch
                ProcessTag = '';
                disp('No Completed Displacement Field Calculated!');
                disp('------------------------------------------------------------------------------')
            end
        end
        %------------------
        if exist('ProcessTag', 'var') 
            fprintf('Displacement Process Tag is: %s\n', ProcessTag);
            try
                InputFileFullName = MD.findProcessTag(ProcessTag).outFilePaths_{1};
                if exist(InputFileFullName, 'file')
                    dlgQuestion = sprintf('Do you want to open the displacement field referred to in the movie data file?\n\n%s\n', ...
                        InputFileFullName);
                    dlgTitle = 'Open displacement field (displField.mat) file?';
                    OpenDisplacementChoice = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No', 'Yes');
                    switch OpenDisplacementChoice
                        case 'Yes'
                            [outputPath, ~, ~] = fileparts(InputFileFullName);
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
    end    
    %------------------
    if isempty(InputFileFullName) || ~exist('ProcessTag', 'var')
        TFMPackageFiles = fullfile(movieFilePath,'TFMPackage','*.mat');
        [InputFileName, outputPath] = uigetfile(TFMPackageFiles, 'Open the displacement field "displField.mat" under displacementField or backups');
        if InputFileName == 0, return; end
        InputFileFullName = fullfile(outputPath, InputFileName);
    end 
    %------------------
    try
        load(InputFileFullName, 'displField');   
        fprintf('Displacement Field (displField) File is successfully loaded!: \n\t %s\n', InputFileFullName);
        disp('------------------------------------------------------------------------------')
    catch
        errordlg('Could not open the displacement field file.');
        return
    end
    FramesDoneBoolean = arrayfun(@(x) ~isempty(x.vec), displField);
    FramesDoneNumbers = find(FramesDoneBoolean == 1);
    FramesDifference = diff(FramesDoneNumbers);
    if isempty(FramesDifference), FramesDifference = 0; end
    VeryLastFrame = find(FramesDoneBoolean, 1, 'last');
    VeryFirstFrame =  find(FramesDoneBoolean, 1, 'first');        

    %% --------  nargin 5, Output folder & parameters file  -------------------------------------------------------------------
    if ~exist('outputPath','var'), outputPath = []; end
    if nargin < 5 || isempty(outputPath)
        if ~exist('outputPath', 'var'), outputPath = []; end
        if isempty(outputPath)
            try
                outputPath = movieFilePath;
            catch
                outputPath = pwd;
            end
        end
        outputPath = uigetdir(outputPath,'Choose the directory where you want to store the tracked Displacement Field Overlays.');
        if outputPath == 0  % Cancel was selected
            clear outputPath;
        elseif ~exist(outputPath,'dir')
            mkdir(outputPath);
        end        
        fprintf('Tracked Displacement Field Overlays Path is: \n\t %s\n', outputPath);
        disp('------------------------------------------------------------------------------')
    end
	%------------------       
    InputParamFile = fullfile(outputPath, 'Displacement Overlays Parameters.mat');
    
    %% --------  nargin 6, Magnification Scale  ------------------------------------------------------------------- 
    if ~exist('MagnificationTimes', 'var'), MagnificationTimes = []; end
    if nargin < 6 || isempty(MagnificationTimes)
        MagnificationTimes = [];
    end
    try
        ScaleMicronPerPixel = MD.pixelSize_/1000;           % from Nanometers/pixel to micron/pixel
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
            [ScaleMicronPerPixel, ~, ~] = MagnificationScalesMicronPerPixel(MagnificationTimes);    
        case 'Yes'
            % Continue
        otherwise 
            return
    end
    fprintf('Magnification scale is %.5f microns/pixel\n', ScaleMicronPerPixel)   
    
    %% --------  nargin 11, Maximum Displacement, microns (maxInput) -------------------------------------------------------------------  
    if ~exist('maxInput','var'), maxInput = []; end              % this is necessary if you know what the max is ahread of it
    maxInput = -1;
    maxFrame = -1;
    minInput = Inf;
    
    if nargin < 11 || isempty(maxInput)
%         try 
%             minInput  = MD.findProcessTag(ProcessTag).tMapLimits_(1);
%             maxInput = MD.findProcessTag(ProcessTag).tMapLimits_(2);            
%         catch
            disp('Evaluating the maximum and minimum displacement value in progress....')
            reverseString = ''; 
            for CurrentFrame = FramesDoneNumbers
                ProgressMsg = sprintf('\nEvaluating Frame #%d/%d...\n', CurrentFrame, FramesDoneNumbers(end));
                fprintf([reverseString, ProgressMsg]);
                reverseString = repmat(sprintf('\b'), 1, length(ProgressMsg));
                if useGPU
                    FieldVec = gpuArray(displField(CurrentFrame).vec);
                else
                    FieldVec = displField(CurrentFrame).vec;
                end          
                FieldVecNorm = (FieldVec(:,1).^2+FieldVec(:,2).^2).^0.5;
                if nargin < 4 || isempty(maxInput)
                    [maxInput, maxInputIndex] = max([maxInput, max(FieldVecNorm)]);
                    if maxInputIndex == 2, maxFrame = CurrentFrame; end
                    minInput = min([minInput,min(FieldVecNorm)]);
                end
            end      
%     else
%         msgbox('Make sure the entered Maximum Displacement is in microns.')
    end
        
    maxInputMicron = maxInput * ScaleMicronPerPixel;   
    minInputMicron = minInput * ScaleMicronPerPixel;
   
    fprintf('Maximum displacement is %g pixels. \n', maxInput);
    fprintf('Maximum displacement is %g microns, based on tracked points. \n', maxInputMicron);  
    disp('------------------------------------------------------------------------------')
    
    %% --------  nargin 8, ShowPlot (Yes/Y/1/On vs. No/N/0/Off)-------------------------------------------------------------------  
    if ~exist('showPlot','var'), showPlot = []; end
    if nargin < 8 || isempty(showPlot)
        dlgQuestion = 'Do you want to show displacement tracking in frames as they are made?';
        dlgTitle = 'Show Plots In Progress?';
        showPlotChoice = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No', 'Yes');
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
%%
    prompt = {sprintf('Enter the Frame Number to be analyzed.\n\t The nearest tracked frame will be chosen (Last Frame = %d): ', VeryLastFrame)};
    dlgTitle = 'Chosen Frame to be Plotted';
    FrameNumInputStr = inputdlg(prompt, dlgTitle, [1, 90], {num2str(VeryLastFrame)});
    if isempty(FrameNumInputStr), return; end
    FrameNumInput = str2double(FrameNumInputStr{1});                                  % Convert to a number
    if ~isempty(FrameNumInput)
        [~,FrameNumIndex] = (min(abs(FramesDoneNumbers - FrameNumInput)));
        FrameNumToBePlotted = FramesDoneNumbers(FrameNumIndex);
        fprintf('Frame to be plotted is: %d/%d.\n', FrameNumToBePlotted, VeryLastFrame)
    else
        FrameNumToBePlotted = [];
    end   
    
  %% --------  nargin 9, ShowVideo (vs. Images) (Yes/Y/1/Images/I vs. No/N/0/Video/V)-------------------------------------------------------------------  
    if ~exist('saveVideo','var'), saveVideo = []; end
    if nargin < 9 || isempty(saveVideo)
        TrackedTIFcount = 0; 
        TrackedJPEGcount = 0; 
        TrackedFIGcount = 0;
        TrackedEPScount = 0;       
        %------------------
        dlgQuestion = 'Do you want to save as videos or as image sequence?';
        dlgTitle = 'Video vs. Image Sequence?';
        plotTypeChoice = questdlg(dlgQuestion, dlgTitle, 'Video', 'Images', 'Video');
        %------------------
    elseif saveVideo == 0 || strcmpi(saveVideo, 'N') ||  strcmpi(saveVideo, 'No')  ||  strcmpi(saveVideo, 'Images') ||  strcmpi(saveVideo, 'I') 
        plotTypeChoice = 'Images';
    elseif saveVideo == 1 || strcmpi(saveVideo, 'Y')  ||  strcmpi(saveVideo, 'Yes')  ||  strcmpi(saveVideo, 'Video') ||  strcmpi(saveVideo, 'V') 
        plotTypeChoice = 'Video';
    else 
        errordlg('Invalid Plot Type Choice')
        return
    end    
    switch plotTypeChoice
        case 'Video'
            saveVideo = true;
            %------------------
            dlgQuestion = 'Select video format.';
            listStr = {'Archival', 'Motion JPEG AVI', 'Motion JPEG 2000','MPEG-4','Uncompressed AVI','Indexed AVI','Grayscale AVI'};
            [VideoChoice, TF1] = listdlg('ListString', listStr, 'PromptString',dlgQuestion, 'InitialValue', 2, 'SelectionMode' ,'Single');    
            if TF1 == 0, return; end
            %------------------
            VideoChoice = listStr{VideoChoice};
        case 'Images'
            saveVideo = false;
            %------------------
            dlgQuestion = 'Select image format.';
            listStr = {'TIF', 'JPEG', 'FIG', 'EPS'};
            [ImageChoice, TF2] = listdlg('ListString', listStr, 'PromptString',dlgQuestion, 'InitialValue', 1, 'SelectionMode' ,'multiple');    
            if TF2 == 0, return; end            
            %------------------
            ImageChoice = listStr(ImageChoice);                 % get the names of the string.   
            if  strcmp(plotTypeChoice, 'Images')
                for ii = 1:numel(ImageChoice)
                    tmpImageChoice =  ImageChoice{ii};
                    switch tmpImageChoice
                        case 'TIF'
                            TrackedPathTIF = fullfile(outputPath, 'Displacement Overlays TIF');
                            if ~exist(TrackedPathTIF,'dir'), mkdir(TrackedPathTIF); end
                            fprintf('Tracked Displacement Overlays Path - TIF is: \n\t %s\n', TrackedPathTIF);
                            try
                                TrackedFilesTIF =  dir(fullfile(TrackedPathTIF, '*.tif'));
                                clear TrackedFilesNum
                                for jj = 1:numel(TrackedFilesTIF) 
                                    NumberBlocks = regexp(TrackedFilesTIF(jj).name,'\d+');
                                    NumbersFromFileIndex = regexp(TrackedFilesTIF(jj).name,'\d');
                                    NumbersFromFileAll = regexp(TrackedFilesTIF(jj).name,'[0-9]','match');
                                    NumbersFromFileStartIndex = find(NumbersFromFileIndex == NumberBlocks(end));
                                    NumbersOfFile = NumbersFromFileIndex(NumbersFromFileStartIndex:end);
                                    TrackedFilesNum(jj) = str2double(TrackedFilesTIF(jj).name(NumbersOfFile));
                                end
                                TrackedTIFcount = max(TrackedFilesNum);
                            catch
                                TrackedTIFcount = 0;
                            end
                        case 'JPEG'
                            TrackedPathJPEG = fullfile(outputPath, 'Displacement Overlays JPEG');
                            if ~exist(TrackedPathJPEG,'dir'), mkdir(TrackedPathJPEG); end
                            fprintf('Tracked Displacement Overlays Path - JPEG is: \n\t %s\n', TrackedPathJPEG);
                            try                                                                   
                                TrackedFilesJPEG =  dir(fullfile(TrackedPathJPEG, '*.jpeg'));
                                clear TrackedFilesNum
                                for jj = 1:numel(TrackedFilesJPEG) 
                                    NumberBlocks = regexp(TrackedFilesJPEG(jj).name,'\d+');
                                    NumbersFromFileIndex = regexp(TrackedFilesJPEG(jj).name,'\d');
                                    NumbersFromFileStartIndex = find(NumbersFromFileIndex == NumberBlocks(end));
                                    NumbersOfFile = NumbersFromFileIndex(NumbersFromFileStartIndex:end);
                                    TrackedFilesNum(jj) = str2double(TrackedFilesJPEG(jj).name(NumbersOfFile));
                                end
                                TrackedJPEGcount = max(TrackedFilesNum);
                            catch
                                TrackedJPEGcount = 0;
                            end
                        case 'FIG'
                            TrackedPathFIG = fullfile(outputPath, 'Displacement Overlays FIG');
                            if ~exist(TrackedPathFIG,'dir'), mkdir(TrackedPathFIG); end
                            fprintf('Plotted Displacement Overlays Path - FIG is: \n\t %s\n', TrackedPathFIG);
                            try
                                TrackedFilesFIG =  dir(fullfile(TrackedPathFIG, '*.fig'));
                                clear TrackedFilesNum
                                for jj = 1:numel(TrackedFilesFIG) 
                                    NumberBlocks = regexp(TrackedFilesFIG(jj).name,'\d+');
                                    NumbersFromFileIndex = regexp(TrackedFilesFIG(jj).name,'\d');
                                    NumbersFromFileAll = regexp(TrackedFilesFIG(jj).name,'[0-9]','match');
                                    NumbersFromFileStartIndex = find(NumbersFromFileIndex == NumberBlocks(end));
                                    NumbersOfFile = NumbersFromFileIndex(NumbersFromFileStartIndex:end);
                                    TrackedFilesNum(jj) = str2double(TrackedFilesFIG(jj).name(NumbersOfFile));
                                end
                                TrackedFIGcount = max(TrackedFilesNum);
                            catch
                                TrackedFIGcount = 0;
                            end
                        case 'EPS'
                            TrackedPathEPS = fullfile(outputPath, 'Displacement Overlays EPS');
                            if ~exist(TrackedPathEPS,'dir'), mkdir(TrackedPathEPS); end
                            fprintf('Plotted Displacement Overlays Path - EPS is: \n\t %s\n', TrackedPathEPS);
                            try
                                TrackedFilesEPS =  dir(fullfile(TrackedPathEPS, '*.eps'));
                                clear TrackedFilesNum
                                for jj = 1:numel(TrackedFilesEPS) 
                                    NumberBlocks = regexp(TrackedFilesEPS(jj).name,'\d+');
                                    NumbersFromFileIndex = regexp(TrackedFilesEPS(jj).name,'\d');
                                    NumbersFromFileAll = regexp(TrackedFilesEPS(jj).name,'[0-9]','match');
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
    %% --------  nargin 10, Analysis Output Folder (Analysispath)-------------------------------------------------------------------  
    if ~exist('analysisOutputPath','var'), analysisOutputPath = []; end    
    if nargin < 10 || isempty(analysisOutputPath)
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
                if strcmp(plotTypeChoice, 'Images') && exist('AnalysisPath', 'var')                         
                    for ii = 1:numel(ImageChoice)
                        tmpImageChoice =  ImageChoice{ii};
                        switch tmpImageChoice
                            case 'TIF'
                                AnalysisPathTIF = fullfile(analysisOutputPath, '05 Displacement Overlays TIF');
                                if ~exist(AnalysisPathTIF,'dir'), mkdir(AnalysisPathTIF); end
                                fprintf('Analysis Plotted Displacement Overlays Path - TIF is: \n\t %s\n', AnalysisPathTIF);
                                try
                                    TrackedFilesTIF =  dir(fullfile(TrackedPathEPS, '*.tif'));
                                    clear TrackedFilesNum
                                    for jj = 1:numel(TrackedFilesTIF) 
                                        NumberBlocks = regexp(TrackedFilesTIF(jj).name,'\d+');
                                        NumbersFromFileIndex = regexp(TrackedFilesTIF(jj).name,'\d');
                                        NumbersFromFileStartIndex = find(NumbersFromFileIndex == NumberBlocks(end));
                                        NumbersOfFile = NumbersFromFileIndex(NumbersFromFileStartIndex:end);
                                        TrackedFilesNum(jj) = str2double(TrackedFilesTIF(jj).name(NumbersOfFile));
                                    end
                                    AnalysisTIFcount = max(TrackedFilesNum);
                                catch
                                    AnalysisTIFcount = 0;
                                end
                            case 'JPEG'
                                AnalysisPathJPEG = fullfile(analysisOutputPath, '06 Displacement Overlays JPEG');
                                if ~exist(AnalysisPathJPEG,'dir'), mkdir(AnalysisPathJPEG); end
                                fprintf('Analysis Plotted Displacement Overlays Path - JPEG is: \n\t %s\n', AnalysisPathJPEG);
                                try
                                    TrackedFilesJPEG =  dir(fullfile(TrackedPathEPS, '*.eps'));
                                    clear TrackedFilesNum
                                    for jj = 1:numel(TrackedFilesJPEG) 
                                        NumberBlocks = regexp(TrackedFilesJPEG(jj).name,'\d+');
                                        NumbersFromFileIndex = regexp(TrackedFilesJPEG(jj).name,'\d');
                                        NumbersFromFileStartIndex = find(NumbersFromFileIndex == NumberBlocks(end));
                                        NumbersOfFile = NumbersFromFileIndex(NumbersFromFileStartIndex:end);
                                        TrackedFilesNum(jj) = str2double(TrackedFilesJPEG(jj).name(NumbersOfFile));
                                    end
                                    AnalysisTIFcount = max(TrackedFilesNum);
                                catch
                                    AnalysisJPEGcount = 0;
                                end
                            case 'FIG'
                                AnalysisPathFIG = fullfile(analysisOutputPath, '05 Displacement Overlays FIG');
                                if ~exist(AnalysisPathFIG,'dir'), mkdir(AnalysisPathFIG); end
                                fprintf('Analysis Plotted Displacement Overlays Path - FIG is: \n\t %s\n', AnalysisPathFIG);
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
                                AnalysisPathEPS = fullfile(analysisOutputPath, '05 Displacement Overlays EPS');
                                if ~exist(AnalysisPathEPS,'dir'), mkdir(AnalysisPathEPS); end
                                fprintf('Analysis Plotted Displacement Overlays Path - EPS is: \n\t %s\n', AnalysisPathEPS);
                                try
                                    AnalysisFilesEPS =  dir(fullfile(AnalysisPathEPS, '*.eps'));
                                    clear TrackedFilesNum
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
    
    %% --------  nargin 12, Full Resolution (Yes/Y/1 vs. No/N/0)-------------------------------------------------------------------  
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
    elseif FullResolution == 1 ||  strcmpi(FullResolution, 'Y')  ||  strcmpi(FullResolution, 'Yes')
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
                FramesTrackedCountMax = max([TrackedTIFcount, TrackedJPEGcount, TrackedFIGcount, TrackedEPScount, AnalysisTIFcount, ...
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
                    dlgTitle = 'Re-Plot Frames?';
                    ReTrackFramesChoice = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No', 'Yes');
                    %------------------
                    switch ReTrackFramesChoice
                        case 'Yes'
                            FirstFrame =  find(FramesDoneBoolean, 1, 'first');
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
                FirstFrame =  find(FramesDoneBoolean, 1, 'first');
            otherwise
                return
        end
        %--------------------
        prompt = {sprintf('Choose the first plotted frame to be plotted. [Default, frame next to last frame plotted so far = %d]', FirstFrame)};
        dlgTitle =  'First Frame Displacement Overlays To Be Plotted';
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
        prompt = {sprintf('Choose the last frame to be plotted. [Default = %d]', LastFrame)};
        dlgTitle = 'Last Frame To Be Plotted';
        LastFrameStr = inputdlg(prompt, dlgTitle, [1, 50], {num2str(LastFrame)});
        if isempty(LastFrameStr), return; end
        LastFrame = str2double(LastFrameStr{1});                                  % Convert to a number
        %------------------        
        [~, LastFrameIndex] = min(abs(FramesDoneNumbers - LastFrame));          % choose a non-empty frame
        LastFrame = FramesDoneNumbers(LastFrameIndex);
    end
    fprintf('Last Frame To Be Plotted = %d\n', LastFrame);
    disp('------------------------------------------------------------------------------') 
    
    FramesToBePloted = FramesDoneNumbers(FirstFrameIndex:LastFrameIndex);
        
    %% ======== Convert pixels to microns ============================================================  
    totalPointsTracked = size(displField(VeryFirstFrame).pos, 1);
    displFieldMicron = struct('pos', zeros(totalPointsTracked, 1), 'vec',  zeros(totalPointsTracked, 1));
    % 2. Covnert only displacements (.vec) to microns. Keep Starting positions in pixels. Keep the same structure
    for CurrentFrame = FramesDoneNumbers
          tmpField = displField(CurrentFrame).vec;
          displFieldMicron(CurrentFrame).pos = displField(CurrentFrame).pos;             % pixels
          displFieldMicron(CurrentFrame).vec = tmpField * ScaleMicronPerPixel;      
    end
        
    %% ======== Set up video writer object ============================================================
    if saveVideo == 1
        finalSuffix = 'Displacement Overlays';
        videoFile = fullfile(outputPath, finalSuffix);        
        writerObj = VideoWriter(videoFile, VideoChoice);
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
     
        try
            writerObj.FrameRate = FrameRateActual; 
        catch
            writerObj.FrameRate = 40; 
        end          
        %-----------------------
        try
            if exist(analysisOutputPath, 'dir')
                finalSuffixAnalysis = '07 Displacement Overlays';
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
    
    %% ======== Check for GPU & Save parameters so far ============================================================  
    disp('------------------------- Starting generating the plotted image sequence. ---------------------------------------------------')   
    if useGPU
        maxInput = gather(maxInput);
        minInput = gather(minInput);
        maxInputMicron = gather(maxInputMicron);
        minInputMicron = gather(minInputMicron);
    end
    InputUnits = 'Pixels';
    save(InputParamFile, 'FirstFrame', 'LastFrame', 'maxInput', 'maxInputMicron', 'InputUnits',...
       'minInput', 'minInputMicron', 'totalPointsTracked', '-v7.3')   
    try
        save(InputParamFile,'VeryLastFrame', '-append')
    catch
       % Continue
    end
    
     %% --------  nargin 7, ShowQuiver (Yes/Y/1 vs. No/N/0)-------------------------------------------------------------------   
    if ~exist('showQuiver','var'), showQuiver = []; end
    if nargin < 7 || isempty(showQuiver)
        %------------------
        dlgQuestion = 'Do you want to show displacement quivers?';
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
            TotalAreaPixel = (max(displField(VeryFirstFrame).pos(:,1)) -  min(displField(VeryFirstFrame).pos(:,1))) * ...
                (max(displField(VeryFirstFrame).pos(:,2)) -  min(displField(VeryFirstFrame).pos(:,2)));                 % x-length * y-length
            AvgInterBeadDist = sqrt(4*(TotalAreaPixel)/size(displField(VeryFirstFrame).pos,1));        % avg inter-bead separation distance = total img area/number of tracked points
            QuiverScaleDefault = 0.95 * (AvgInterBeadDist/maxInput) * QuiverMagnificationFactor;
%             QuiverScaleDefault = 0.95 * (GridSpacing/maxInput);
            prompt = {sprintf('Define the quiver scaling factor recommended, [Currently 1X = %0.16g]', QuiverScaleDefault)};
            
            dlgTitle = 'Quiver Scale Factor';            
            QuiverMagnificationFactorDefault = {num2str(QuiverMagnificationFactor)};
            QuiverMagnificationFactor = inputdlg(prompt, dlgTitle, [1, 90],  QuiverMagnificationFactorDefault);        % Modified on 2020-01-17            
            if isempty(QuiverMagnificationFactor), return; end
            QuiverMagnificationFactor = str2double(QuiverMagnificationFactor{1});                                  % Convert to a number                
            QuiverScaleToMax = QuiverScaleDefault * QuiverMagnificationFactor;                                 %quiver plot maximum and scale
            if useGPU, QuiverScaleToMax = gather(QuiverScaleToMax); end
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
    
    %% Choose color: updated on 2020-04-15
    dlgQuestion = 'Select Colormap Look Up Table (LUT):';
    listStr = {'Red', 'Green', 'Blue', 'Other'};
    [colormapLUTchoice, TF1] = listdlg('ListString', listStr, 'PromptString',dlgQuestion, 'InitialValue', 1, 'SelectionMode' ,'Single', ...
        'ListSize', [200, 70]);    
    if TF1 == 0, return; end
    colormapLUTchoice = listStr{colormapLUTchoice};    
    GrayLevels = 2^ImageBits;    
    
    switch colormapLUTchoice             % represented as RGB = [Red, Green, Blue]
        case 'Red'
            colormapLUT = [linspace(0,1,GrayLevels)', zeros(GrayLevels,2)];                           
        case 'Green'
            colormapLUT = [zeros(GrayLevels,1), linspace(0,1,GrayLevels)', zeros(GrayLevels,1)];    
        case 'Blue'
            colormapLUT = [zeros(GrayLevels,2), linspace(0,1,GrayLevels)'];    
        otherwise
            GrayLevelsStr = num2str(GrayLevels);
            GrayLevelRangeStr = strcat('[0,', GrayLevelsStr, ']');
            ColormapListStr = {'Red Channel Gray Level [min, max]:' , 'Blue Channel Gray Level [min, max]:', 'Green Channel Gray Level [min, max]:'};
            ColormapDefaults = cell(1,3); 
            ColormapDefaults(:) = {GrayLevelRangeStr};
            colormapLUTstr = inputdlg(ColormapListStr, 'Enter RGB LUTs', [1, 50; 1,50; 1,50], ColormapDefaults);
            
            colormapRangeRed = str2num(colormapLUTstr{1});
            colormapRangeGreen = str2num(colormapLUTstr{2});
            colormapRangeBlue = str2num(colormapLUTstr{3});
            
            colormapRangeRedScaled = colormapRangeRed ./ GrayLevels;
            colormapRangeGreenScaled = colormapRangeGreen ./ GrayLevels;
            colormapRangeBlueScaled = colormapRangeBlue ./ GrayLevels;
            
            colormapLUT = [colormapRangeRedScaled', colormapRangeGreenScaled', colormapRangeBlueScaled']; 
    end
    QuiverColor = median(imcomplement(colormapLUT));               % User Complement of the colormap for maximum visibililty of the quiver.
 
    GrayLevelsPercentile = [0.05,0.999];
    GrayLevelsPercentileStr = {strcat('[', num2str(GrayLevelsPercentile(1)), ',', num2str(GrayLevelsPercentile(2)), ']')};
    prompt = {sprintf('Enter Histogram Percentile Adjustment (Default: [%0.3f, %0.3f]): ', GrayLevelsPercentile(1), GrayLevelsPercentile(2))};
    GrayLevelsPercentileStr = inputdlg(prompt, 'Enter Percentile Adjustment', [1, 70], GrayLevelsPercentileStr);
    GrayLevelsPercentile = str2num(GrayLevelsPercentileStr{:});
    
    save(InputParamFile, 'GrayLevels','colormapLUT', 'GrayLevelsPercentile', '-append')
    
%%
    ImageSizePixels = MD.imSize_;     
    MarkerSize = round(ImageSizePixels(1)/ 1000, 1, 'decimals');    
    
%%          
    figHandleInitial = figure('visible','off', 'color', 'w', 'Units', 'pixels', 'Renderer', FigRenderer);     % added by WIM on 2019-09-14. To show, remove 'visible
    figAxesHandle = axes;
    
    ChannelCount = numel(MD.channels_);                                             % updated on 2020-04-15
    ChannelNum = ChannelCount;
    if ChannelCount ~= 1
        prompt = {sprintf('Choose the channel to be plotted. [Channel Count = %i]', ChannelCount)};
        dlgTitle = 'Channel To Be Plotted';
        ChannelNumStr = inputdlg(prompt, dlgTitle, [1, 70], {num2str(ChannelNum)});
        if isempty(ChannelNumStr), return; end
        ChannelNum = str2double(ChannelNumStr{1});                                  % Convert to a number
    end
    
    try
        curr_Image = MD.channels_(ChannelNum).loadImage(maxFrame);
    catch
        BioformatsPath = uigetdir([], 'Select directory containing bioformats folder (e.g., TFMpackagefolder)');
        addpath(genpath(BioformatsPath));        % include subfolders
        curr_Image = MD.channels_(ChannelNum).loadImage(maxFrame);
    end
    if useGPU
        curr_Image = gpuArray(curr_Image);
    end 

    % Adjust contrast so that the bottom 5% (dark faint noise is not showing and showing all intense images).
    curr_ImageAdjust = imadjust(curr_Image, stretchlim(curr_Image,GrayLevelsPercentile));    
    % display the adjusted image
            
    imagesc(figAxesHandle,  1, 1, curr_ImageAdjust)
    axis image
    truesize
    hold on
    colormap(colormapLUT)
    set(figAxesHandle, 'Box', 'on', 'XTick',[], 'YTick', [], 'Visible', 'on', 'YDir', 'reverse');
    set(figAxesHandle, 'Units', 'pixels');
    
    switch QuiverChoice
        case 'Yes'
            set(figHandleInitial, 'visible', 'on')
            
            X = displFieldMicron(maxFrame).pos(:,1);
            Y = displFieldMicron(maxFrame).pos(:,2);
            U = displFieldMicron(maxFrame).vec(:,1);
            V = displFieldMicron(maxFrame).vec(:,2);
            
            quiverNotOK = true;
            while quiverNotOK
                figure(figHandleInitial)
                qHandle = quiver(figAxesHandle, X, Y, U .*QuiverScaleToMax, V .*QuiverScaleToMax, 0, ...
                   'MarkerSize',MarkerSize, 'markerfacecolor',QuiverColor, 'ShowArrowHead','on', 'MaxHeadSize', 3, ...
                   'color',QuiverColor, 'AutoScale','off', 'LineWidth', QuiverLineWidth , 'AlignVertexCenters', 'on');
                IsQuiverOK = questdlg('Are the plot quivers looking OK?', 'Quiver OK?', 'Yes', 'No', 'Yes');
                if isempty(IsQuiverOK), return; end
                switch IsQuiverOK
                    case 'Yes'
                        quiverNotOK = false;
                    case 'No'
                        disp('**___to continue, type "dbcont" or press "F5", or click "Continue" under "Editor" Menu"___**')
                        keyboard
                        
                        prompt = {sprintf('Enter the quiver magnification factor that you want. [Currently = %g]', QuiverMagnificationFactor)};
                        dlgTitle = 'QuiverScale';
                        QuiverMagnificationFactorStr = {num2str(QuiverMagnificationFactor)};
                        QuiverMagnificationFactorStr = inputdlg(prompt, dlgTitle, [1 40], QuiverMagnificationFactorStr);
                        if isempty(QuiverMagnificationFactorStr), return; end
                        QuiverMagnificationFactor = str2double(QuiverMagnificationFactorStr{:}); 
                        QuiverScaleToMax = QuiverScaleDefault * QuiverMagnificationFactor;                                 %quiver plot maximum and scale
                        delete(qHandle)
                    otherwise 
                        return
                end
            end
            quiverColorNotOK = true;
            while quiverColorNotOK
                figure(figHandleInitial)
                QuiverColor = uisetcolor(QuiverColor); 
                set(qHandle, 'markerfacecolor',QuiverColor,  'color', QuiverColor)       
                IsQuiverColorOK = questdlg('Is the quiver color looking OK?', 'Quiver OK?', 'Yes', 'No', 'Yes');
                if isempty(IsQuiverColorOK), return; end
                switch IsQuiverColorOK
                    case 'Yes'
                        quiverColorNotOK = false;
                    case 'No'
                        disp('**___to continue, type "dbcont" or press "F5", or click "Continue" under "Editor" Menu"___**')
                        keyboard
                end
            end   
    end
    
    ScaleBarChoice = questdlg({'Do you want to insert a scalebar?','If yes, choose the right-edge position'},'ScaleBar?', 'Yes', 'No', 'Yes');
    if isempty(ScaleBarChoice), return; end
    if strcmpi(ScaleBarChoice, 'Yes')
        set(figHandleInitial, 'visible', 'on')
        ScaleBarNotOK = true;
        ScaleBarColor = QuiverColor;
        while ScaleBarNotOK
            figure(figHandleInitial)
            [ScaleBarLocation(1), ScaleBarLocation(2)] = ginputc(1, 'Color', QuiverColor);
            
            ScaleBarUnits = sprintf('%sm', char(181));         % '\mum';                                    % in Microns 181 is Unicode for small mu
            prompt = sprintf('Scale Bar Length [%s]:', ScaleBarUnits);
            dlgTitle = 'Scale Bar Length';
            dims = [1 40];
            defInput = {num2str(round((round((ImageSizePixels(1)*ScaleMicronPerPixel* 0.10)/10) * 10)))};          % ideal scale length. CornerPercentage is 10%
            opts.Interpreter = 'tex';
            ScaleLengthStr = inputdlg(prompt, dlgTitle, dims, defInput, opts);
            if isempty(ScaleLengthStr), return; end
            ScaleLength = str2double(ScaleLengthStr{:});
            
            prompt = sprintf('Scale Bar Width [%s]:', ScaleBarUnits);
            dlgTitle = 'Scale Bar Width';
            dims = [1 40];
            defInput = {num2str(round((round((ImageSizePixels(1)*ScaleMicronPerPixel* 0.10)/20))))};          % ideal scale Width. CornerPercentage is 10%
            opts.Interpreter = 'tex';
            ScaleWidthStr = inputdlg(prompt, dlgTitle, dims, defInput, opts);
            if isempty(ScaleWidthStr), return; end
            ScaleWidth = str2double(ScaleWidthStr{:});            
            
            prompt = {sprintf('Enter the scale bar font size that you want. [Currently = %g]', scalebarFontSize)};
            dlgTitle = 'scale bar font size';
            scalebarFontSizeStr = {num2str(scalebarFontSize)};
            scalebarFontSizeStr = inputdlg(prompt, dlgTitle, [1 40], scalebarFontSizeStr);
            if isempty(scalebarFontSizeStr), return; end
            scalebarFontSize = str2double(scalebarFontSizeStr{:}); 
            
            ScaleBarColor = uisetcolor(ScaleBarColor, 'Select the ScaleBar Color');   % [1,1,0] is the RGB for yellow
            if ScaleBarColor == 0, return; end
            
            scalebar(figAxesHandle,'ScaleLength', ScaleLength, 'ScaleLengthRatio', ScaleMicronPerPixel, 'color', ScaleBarColor, ...
                'FontName', 'Helvetica-Narrow', 'fontsize', scalebarFontSize, 'unit', ScaleBarUnits, 'location', ScaleBarLocation, 'linewidth', ScaleWidth)                 % Modified by WIM
            IsScaleBarOK = questdlg('Is the scale bar looking OK?', 'Quiver OK?', 'Yes', 'No', 'Yes');
            if isempty(IsScaleBarOK), return; end
            switch IsScaleBarOK
                case 'Yes'
                    ScaleBarNotOK = false;
                case 'No'
                    disp('**___to continue, type "dbcont" or press "F5", or click "Continue" under "Editor" Menu"___**')
                    keyboard
            end
        end
    end
    
    try
        save(InputParamFile, 'QuiverScaleToMax','QuiverMagnificationFactor', 'QuiverColor', '-append')
    catch

    end
    
    % Added by WIM on 2020-06-04
    TimeStampsChoice = questdlg({'Do you want to insert timestamps?','If yes, choose the Left-edge position'},'Time Stamps?', 'Yes', 'No', 'Yes');
    if strcmpi(TimeStampsChoice, 'Yes')
        TimeStampsNotOK = true;
        TimeStampsFontSize = 12;
        TimeStamps = [];
        
        if isempty(TimeStamps)
            [TimeStampsFileName, TimeStampsPathName] = uigetfile(fullfile(movieFilePath, '*.*'), 'Choose the timestamps file (RT or ND2)');
            TimeStampsFileNameFull = fullfile(TimeStampsPathName, TimeStampsFileName);
            TimeStampsStruct = load(TimeStampsFileNameFull);
            try
                TimeStamps = TimeStampsStruct.TimeStampsAbsoluteRT_Sec;
            catch
                try
                    TimeStamps = TimeStampsStruct.TimeStampsND2;
                catch
                    TimeStamps = TimeStampsStruct.TimeStamps;
                end
            end
        end
            
        while TimeStampsNotOK
            TimeStampsUnits = 's';         % in seconds
            figure(figHandleInitial)
            [TimeStampsLocation(1), TimeStampsLocation(2)] = ginputc(1, 'Color', QuiverColor);
            prompt = sprintf('time stamps unit [%s]:', TimeStampsUnits);
            dlgTitle = 'Time Stamps Unit';
            dims = [1 40];
            defInput = {TimeStampsUnits};
            opts.Interpreter = 'tex';
            TimeStampsStr = inputdlg(prompt, dlgTitle, dims, defInput, opts);
            TimeStampsStr = TimeStampsStr{:};
            CurrentTimeStampsStr = sprintf('\\itt\\rm = %0.3f %s' , 0, TimeStampsStr);
            
            prompt = {sprintf('Enter the time stamps font size that you want. [Currently = %g]', TimeStampsFontSize)};
            dlgTitle = 'time stamps font size';
            TimeStampsFontSizeStr = {num2str(TimeStampsFontSize)};
            TimeStampsFontSizeStr = inputdlg(prompt, dlgTitle, [1 40], TimeStampsFontSizeStr);
            if isempty(TimeStampsFontSizeStr), return; end
            TimeStampsFontSize = str2double(TimeStampsFontSizeStr{:}); 
            
            TimeStampscolor = uisetcolor(QuiverColor, 'Select the Timestamps Color');   % [1,1,0] is the RGB for yellow       
            
            textHandle = text(TimeStampsLocation(1), TimeStampsLocation(2), CurrentTimeStampsStr, 'FontSize', TimeStampsFontSize, 'VerticalAlignment', 'bottom', ...
                'HorizontalAlignment', 'left', 'Color', TimeStampscolor, 'FontName', 'Helvetica-Narrow');
            
            IsTimeStampsOK = questdlg('Is the time stamp looking OK?', 'Quiver OK?', 'Yes', 'No', 'Yes');
            switch IsTimeStampsOK
                case 'Yes'
                    TimeStampsNotOK = false;
                case 'No'
                    delete(textHandle)
                    disp('**___to continue, type "dbcont" or press "F5", or click "Continue" under "Editor" Menu"___**')
                    keyboard
            end
        end
%         FramesToBePloted = FramesToBePloted(1:LastFrame);
    end
    
    FluxStatusChoice = questdlg({'Do you want to insert flux status?','If yes, choose the Left-edge position'},'Time Stamps?', 'Yes', 'No', 'Yes');
    if strcmpi(FluxStatusChoice, 'Yes')
         FluxStatusString = {'ON','OFF','Transient'};         % in seconds
%          
%         FigRenderer = 'painters';
%         figHandleInitial = figure('visible','on', 'color', 'w', 'MenuBar','none', 'Toolbar','none', 'Units', 'pixels', 'Resize', 'off', 'Renderer', FigRenderer);     % added by WIM on 2019-09-14. To show, remove 'visible
%         figAxesHandleInitial = axes;
%         set(figAxesHandleInitial, 'Box', 'on', 'XTick',[], 'YTick', [], 'Visible', 'on', 'YDir', 'reverse');
%         set(figAxesHandleInitial, 'Units', 'pixels');
%         CurrentImageInitial = bfGetPlane(handles.reader, 1);                                % Added by WIM on 2/7/2018
%         [CurrentImageInitial, BeadROIrect] = imcrop(CurrentImageInitial, BeadROIrect);
%         ImageSizePixels  = size(CurrentImageInitial);
% 
%         imagesc(figAxesHandleInitial, 1, 1, CurrentImageInitial);
%         colormap(GrayColorMap);
%         axis image
%         
%         if strcmpi(ScaleBarChoice, 'Yes')
%             scalebar(figAxesHandleInitial,'ScaleLength', ScaleLength, 'ScaleLengthRatio', ScaleMicronPerPixel, 'color', ScaleBarColor, ...
%                 'FontName', 'Helvetica-Narrow', 'fontsize', scalebarFontSize, 'unit', ScaleBarUnits, 'location', ScaleBarLocation, 'linewidth', ScaleWidth)                 % Modified by WIM           
%         end
%         
%         if strcmpi(TimeStampsChoice, 'Yes')
%             textHandle = text(TimeStampsLocation(1), TimeStampsLocation(2), CurrentTimeStampsStr, 'FontSize', TimeStampsFontSize, 'VerticalAlignment', 'bottom', ...
%                 'HorizontalAlignment', 'left', 'Color', TimeStampscolor, 'FontName', 'Helvetica-Narrow');
%         end
%         
%         FluxStatusNotOK = true;
%         FluxStatusFontSize = 12;
        FluxStatus = [];
        
        if isempty(FluxStatus)
%             [FluxStatusFileName, FluxStatusPathName] = uigetfile(fullfile(handles.outputPath, '*.*'), 'Choose Flux Status *RegularizationParam.mat file');
%             FluxStatusFileNameFull = fullfile(FluxStatusPathName, FluxStatusFileName);
%             FluxStatusStruct = load(FluxStatusFileNameFull);
%             try
%                 FluxON = FluxStatusStruct.FluxON;
%                 FluxOFF = FluxStatusStruct.FluxOFF;
%             catch
                dlgQuestion = 'What is the control mode for EPI experiment? ';
                dlgTitle = 'Control Mode?';
                controlMode = questdlg(dlgQuestion, dlgTitle, 'Controlled Force', 'Controlled Displacement', 'Controlled Force');
                if isempty(controlMode), return; end   

                switch controlMode    
                    case 'Controlled Force'                        
                        % Controlled force mode will use the Magnetic Flux reading to classify ON/OFF
                        [FluxON, FluxOFF, FluxTransient, ~] = FindFluxStatusControlledForce();
                        TransientIdx2 = find(diff(FluxTransient));
                        TransientIdx = TransientIdx2 + repmat([1;0;0;0], numel(TransientIdx2) / 4, 1);
                        
                        FluxONCombined = FluxON;
%                         counter = 1;
                        for ii = 1:4:numel(TransientIdx)                            
                            FluxONCombined(TransientIdx(ii):TransientIdx(ii+1)) = 1;
%                            FluxTransientOFF(counter, :) = TransientIdx(ii+2:ii+3);
                            FluxONCombined(TransientIdx(ii+2):TransientIdx(ii+3)) = 0;
%                            counter = counter + 1;
                        end

                    case 'Controlled Displacement'
                        % Cotnrolled Force mode will rely on the user to identify the beginning of the "ON" based on the displacement of the bead that is considered above average noise level.
%                         [FluxON, FluxOFF, FluxTransient, ~] = FindFluxStatusControlledDisplacement(movieData, displField, TimeStamps, FramesDoneNumbers);
%                         FluxONCombined = FluxON | FluxTransient;
%                       FluxONCombined(FluxONCombined == 0) = 2;
                        OnFrame = input('What is the needle turned ON? ');
                        FluxONCombined = zeros(1, numel(FramesDoneNumbers));
                        OFFFrame = input('What is the needle turned OFF? ');
                        if numel(OnFrame:OFFFrame-1) > 1
                            FluxONCombined(OnFrame:OFFFrame-1) = 1;
                        end
                end    
%             end
        end
            
    %         while FluxStatusNotOK
%               figure(figHandleInitial)
%             [FluxStatusLocation(1), FluxStatusLocation(2)] = ginputc(1, 'Color', QuiverColor);
% 
%             CurrentFluxStatusStr =  sprintf('\\itF\\rm_{MT} %s', FluxStatusString{1});
%             
%             prompt = {sprintf('Enter the flux status font size that you want. [Currently = %g]', FluxStatusFontSize)};
%             dlgTitle = 'Flux status font size';
%             FluxStatusFontSizeStr = {num2str(FluxStatusFontSize)};
%             FluxStatusFontSizeStr = inputdlg(prompt, dlgTitle, [1 70], FluxStatusFontSizeStr);
%             if isempty(FluxStatusFontSizeStr), return; end
%             FluxStatusFontSize = str2double(FluxStatusFontSizeStr{:}); 
%             
% %             for ii = 1:3
%             for ii = 1:1            % sticking to one color right now.
%                 FluxStatusColors(ii,:) = uisetcolor(QuiverColor, sprintf('Flux %s color', FluxStatusString{ii}));   % [1,1,0] is the RGB for yellow       
%             end
%             
%             CurrentFluxStatusColor = FluxStatusColors(1,:);
%             FluxStatusTextHandle = text(FluxStatusLocation(1), FluxStatusLocation(2), CurrentFluxStatusStr, 'FontSize', FluxStatusFontSize, 'VerticalAlignment', 'bottom', ...
%                 'HorizontalAlignment', 'left', 'Color', CurrentFluxStatusColor, 'FontName', 'Helvetica-Narrow');
%             
%             IsTimeStampsOK = questdlg('Is the time stamp looking OK?', 'Quiver OK?', 'Yes', 'No', 'Yes');
%             switch IsTimeStampsOK
%                 case 'Yes'
%                     FluxStatusNotOK = false;
%                 case 'No'
%                     delete(FluxStatusTextHandle)
%                     disp('**___to continue, type "dbcont" or press "F5", or click "Continue" under "Editor" Menu"___**')
%                     keyboard
%             end
%         end
% 
%         close(figHandleInitial)
% 
    end
    
    close(figHandleInitial)
    
    if strcmpi(ScaleBarChoice, 'Yes')
        save(InputParamFile, 'scalebarFontSize', '-append')
    end
    save(InputParamFile, 'ScaleMicronPerPixel', 'ImageSizePixels', '-append')
    
    %% ======== Plotting Overlays Now ============================================================    
    disp('------------------------- Starting generating the plotted image sequence. ---------------------------------------------------');   
    FirstFrameNow = true;
    
    if isempty(FramesDifference), FramesDifference = 0; end      
    
    for CurrentFrame = FramesToBePloted    
        if mod(CurrentFrame, FramesAtOnce * FramesDifference(1)) == 0 || FirstFrameNow == true                   % close figHandle every ... samples to prevent memory leak
            try
                clf(figHandle, 'reset')
                set(figHandle, 'visible',showPlot, 'color', 'w', 'Toolbar','none', 'Menubar','none', 'Units', 'pixels', 'Resize', 'off');    % added by WIM on 2019-09-14. To show, remove                  
            catch
                clear figHandle
               % No figure Exists, continue 
            end
            FirstFrameNow = false;  
            if ~exist('figHandle', 'var')
                figHandle = figure('visible',showPlot, 'color', 'w', 'Toolbar','none', 'Menubar','none', 'Units', 'pixels', 'Resize', 'off');    % added by WIM on 2019-09-14. To show, remove     
            end
            reverseString = '';
            axis image
            figAxesHandle = findobj(figHandle, 'type',  'Axes');
            if isempty(figAxesHandle), figAxesHandle = gca; end
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
        %             matlab.ui.internal.PositionUtils.setDevicePixelPosition(gca, [1, -1, ImageSizePixels(1), ImageSizePixels(2)]);
                end
                set(figAxesHandle, 'Units', 'pixels', 'Position', [1, 1,  ImageSizePixels(1), ImageSizePixels(2)], 'Box', 'off', 'TickLength', [0, 0], 'Visible', 'off', 'YDIR', 'reverse' );       % origin is top left corner
            end
        end
        %------------------------
        ProgressMsg = sprintf('\nCreating Frame #%d/%d...\n', CurrentFrame, LastFrame);
        fprintf([reverseString, ProgressMsg]);
        reverseString = repmat(sprintf('\b'), 1, length(ProgressMsg));
        %------------------------
        try
            curr_Image = MD.channels_(ChannelNum).loadImage(CurrentFrame);
        catch
            BioformatsPath = uigetdir([], 'Select directory containing bioformats folder (e.g., TFMpackagefolder)');
            addpath(genpath(BioformatsPath));        % include subfolders
            curr_Image = MD.channels_(ChannelNum).loadImage(CurrentFrame);
        end
        if useGPU
            curr_Image = gpuArray(curr_Image);
        end         
        
        % Adjust contrast so that the bottom 5% (dark faint noise is not showing and showing all intense images).
        curr_ImageAdjust = imadjust(curr_Image, stretchlim(curr_Image,GrayLevelsPercentile));    
        % display the adjusted image       

        if FullResolution
            if WindowAPI_used 
                figImageHandle = imagesc(figAxesHandle, 1, 1, curr_ImageAdjust);
            else
                figHandle = imshow(curr_ImageAdjust, 'Initialmagnification', 'fit');
            end
        else
            figHandle = imshow(curr_ImageAdjust);  
%        figHandle =  imshow(curr_Image, []);          % display all images autocontrasted for whole range. Use Texas Red Imaging
        end
        set(figAxesHandle, 'Units', 'pixels', 'Position', [1, 1,  ImageSizePixels(1), ImageSizePixels(2)], 'Box', 'off', 'TickLength', [0, 0], 'Visible', 'off');
        colormap(colormapLUT); 
        hold on
        if strcmpi(ScaleBarChoice, 'Yes')
            scalebarHandle = scalebar(figAxesHandle,'ScaleLength', ScaleLength, 'ScaleLengthRatio', ScaleMicronPerPixel, 'color', ScaleBarColor, ...
               'fontsize', scalebarFontSize, 'unit', ScaleBarUnits, 'location', ScaleBarLocation, 'FontName', 'Helvetica-Narrow', 'linewidth', ScaleWidth);                 % Modified by WIM
        end
        try
            if strcmpi(TimeStampsChoice, 'Yes')
                CurrentTimeStampsStr = sprintf('\\itt\\rm = %0.3f s' , TimeStamps(CurrentFrame));
                textHandle = text(TimeStampsLocation(1), TimeStampsLocation(2), CurrentTimeStampsStr , 'FontSize', TimeStampsFontSize, 'VerticalAlignment', 'bottom', ...
                    'HorizontalAlignment', 'left', 'Color', TimeStampscolor, 'FontName', 'Helvetica-Narrow');
            end
        catch
            break
        end
        if strcmpi(FluxStatusChoice, 'Yes')
            if FluxONCombined(CurrentFrame) == 1
                FluxStatus = 1;
            else
                FluxStatus = 2;
            end
            CurrentFluxStatusStr =  sprintf('\\itF\\rm_{MT} %s', FluxStatusString{FluxStatus});
            
            textHandle.String = sprintf('%s    %s', CurrentTimeStampsStr, CurrentFluxStatusStr);
%             FluxStatusTextHandle = text(FluxStatusLocation(1), FluxStatusLocation(2), CurrentFluxStatusStr , 'FontSize', FluxStatusFontSize, 'VerticalAlignment', 'bottom', ...
%                 'HorizontalAlignment', 'left', 'Color', CurrentFluxStatusColor, 'FontName', 'Helvetica-Narrow');
        end
        %-----------------------------------------------------------------------------------------------        
        if useGPU
            displFieldMicronPos = gpuArray(displFieldMicron(CurrentFrame).pos);
            displFieldMicronVec = gpuArray(displFieldMicron(CurrentFrame).vec);
        else
            displFieldMicronPos = displFieldMicron(CurrentFrame).pos;
            displFieldMicronVec = displFieldMicron(CurrentFrame).vec;
        end        
        %-----------------------------------------------------------------------------------------------        
        if ~isempty(displFieldMicron(CurrentFrame).vec)
            if showQuiver
                pause(0.1)
                set(figAxesHandle, 'CameraPositionMode', 'manual', 'CameraTargetMode', 'manual', 'CameraUpVectorMode', 'manual', 'CameraViewAngleMode', 'auto')       % Added by WIM on 2019-10-02
                   % autoscale is off to keep arrow lengths have the same scale.
%                 if ~isempty(qHandle2), delete(qHandle2); end
                plotHandle = quiver(figAxesHandle, displFieldMicronPos(:,1),displFieldMicronPos(:,2), displFieldMicronVec(:,1) * QuiverScaleToMax, displFieldMicronVec(:,2) * QuiverScaleToMax, ...
                   'MarkerSize',1, 'MarkerFaceColor',QuiverColor, 'ShowArrowHead','on', 'MaxHeadSize', 3 , 'LineWidth', 1 ,  'color',QuiverColor, 'AutoScale','off');                 
            else
               plotHandle = plot(figAxesHandle, displField(CurrentFrame).pos(:,1) + displField(CurrentFrame).vec(:,1), displField(CurrentFrame).pos(:,2) + displField(CurrentFrame).vec(:,2), 'wo', 'MarkerSize',1);  
            end
        else    % no tracked displacement anymore
            return
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
        
        ImageHandle = getframe(figAxesHandle);     
        Image_cdata = ImageHandle.cdata;
        
        %% Saving Frame Now
        if saveVideo
            % open the video writer
            open(writerObj);            
        
            % Need some fixing 3/3/2019
            writeVideo(writerObj, Image_cdata);
            if exist('AnalysisPath', 'var')
                if exist(analysisOutputPath,'dir')
                    open(writerObjAnalysis);                          
                    writeVideo(writerObjAnalysis, Image_cdata);
                end
            end
        end
        %-----------------------------------------------------------------------------------------------    
        if ~saveVideo || (~isempty(FrameNumToBePlotted) && FrameNumToBePlotted == CurrentFrame)
            if ~exist('ImageChoice', 'var')
                ImageChoice = {'TIF',    'FIG',    'EPS'};
                TrackedPathTIF = outputPath;
                TrackedPathFIG = outputPath;
                TrackedPathEPS = outputPath;
                if exist('AnalysisPath', 'var')
                    AnalysisPathTIF = outputPath;
                    AnalysisPathFIG = outputPath;
                    AnalysisPathEPS = outputPath;
                end
            end
            % Anonymous function to append the file number to the file type. 
%             if ~exist('CurrentImageFileName','var')
                fString = ['%0' num2str(floor(log10(LastFrame))+1) '.f'];
                FrameNumSuffix = @(frame) num2str(frame,fString);
                CurrentImageFileName = strcat('Displacement Overlays_#', FrameNumSuffix(CurrentFrame));
%             end

            for ii = 1:numel(ImageChoice)
                tmpImageChoice =  ImageChoice{ii};
                switch tmpImageChoice
                    case 'TIF'
                        TrackedDisplacementPathTIFname = fullfile(TrackedPathTIF, [CurrentImageFileName , '.tif']);
                        imwrite(Image_cdata, TrackedDisplacementPathTIFname);
                        if exist('AnalysisOutputPath', 'var')
                            if exist(analysisOutputPath,'dir')
                                AnalysisDisplacementPathTIFname = fullfile(AnalysisPathTIF,[CurrentImageFileName, '.tif']);
                                imwrite(Image_cdata, AnalysisDisplacementPathTIFname); 
                            end               
                        end
                     case 'JPEG'
                        TrackedDisplacementPathJPEGname = fullfile(TrackedPathJPEG, [CurrentImageFileName , '.jpeg']);
                        imwrite(Image_cdata, TrackedDisplacementPathJPEGname);
                        if exist('AnalysisPath', 'var')
                            if exist(analysisOutputPath,'dir')
                                AnalysisDisplacementPathJPEGname = fullfile(AnalysisPathJPEG, [CurrentImageFileName, '.jpeg']);
                                imwrite(Image_cdata, AnalysisDisplacementPathJPEGname); 
                            end               
                        end         
                    case 'FIG'
                        TrackedDisplacementPathFIGname = fullfile(TrackedPathFIG,[CurrentImageFileName, '.fig']);
                        savefig(figHandle, TrackedDisplacementPathFIGname,'compact')
                        if exist('AnalysisOutputPath', 'var')
                            if exist(analysisOutputPath,'dir')
                                AnalysisDisplacementPathTIFname = fullfile(AnalysisPathFIG,[CurrentImageFileName, '.fig']);
                                savefig(figHandle, AnalysisDisplacementPathTIFname,'compact')
                            end 
                        end
                    case 'EPS'
                        TrackedDisplacementPathEPSname = fullfile(TrackedPathEPS,[CurrentImageFileName, '.eps']);               
%                         print(figHandle, TrackedDisplacementPathEPSname,'-depsc')
                        exportfig(figHandle, TrackedDisplacementPathEPSname, EPSparams)  
                        if exist('AnalysisOutputPath', 'var')
                            if exist(analysisOutputPath,'dir')
                                AnalysisDisplacementPathEPSname = fullfile(AnalysisPathEPS,[CurrentImageFileName, '.eps']);               
%                                 print(figHandle, AnalysisDisplacementPathEPSname,'-depsc')
                                exportfig(figHandle, AnalysisDisplacementPathEPSname, EPSparams)  
                            end              
                        end
                     otherwise
                         return   
                end
            end
        end
        
        % added on 2020-02-12 by WIM to save memory
        try delete(figImageHandle); catch; end
        if strcmpi(ScaleBarChoice, 'Yes')
            try delete(scalebarHandle); catch; end
        end
        if strcmpi(TimeStampsChoice, 'Yes')
            try delete(textHandle); catch; end
        end
        if strcmpi(FluxStatusChoice, 'Yes')
            try delete(FluxStatusTextHandle); catch; end
        end
        try delete(plotHandle); catch; end
        try delete(ImageHandle); catch; end
        try delete(Image_cdata); catch; end
        clear figImageHandle scalebarHandle plotHandle ImageHandle Image_cdata
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
    close(figHandle)
    
    if saveVideo
        fprintf('Video saved as: \n\t%s\n', videoFile)        
         if exist(analysisOutputPath, 'dir')
             fprintf('Video saved as: \n\t%s', videoFileAnalysis)        
         end
    else
        fprintf('Image(s) are saved under: \n\t%s\n', outputPath)
        if exist(analysisOutputPath, 'dir')
            fprintf('Image(s) are saved under: \n\t%s\n', analysisOutputPath)
        end
    end
    
    %% ==================================================================================
%     if ispc     % opening file explorer externally to see those individual files
%         if exist('AnalysisPath', 'var') 
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

    disp('-------------------------- Finished generating plotted tracked displacements overlays--------------------------')   
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

%  In Plot Overlays, the code below will NOT extend the full height. MATLAB will resize

