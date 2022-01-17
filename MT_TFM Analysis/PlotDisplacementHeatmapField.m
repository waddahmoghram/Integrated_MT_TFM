%{
    v.2020-10-24..27 by Waddah Moghram, PhD Student in Biomedical Engineering at the University of Iowa.
        1. Add Flux Status to output video
    v,2020-07-22 by Waddah Moghram, PhD Student in Biomedical Engineering at the University of Iowa.
        1. Fixed glitch with FramesDifference being empty if one frame is fed
    v.2020-06-17..21 by Waddah Moghram
        1. Updated so the label contains the x*,y*,z. 
        2. Modified Units so that only the unit is adde at the front. 
        3. Choose the lesser of Timestamps vs. Tracked displcements if a timestamps file is chosen.
    v.2020-06-04 by Waddah Moghram
        1. Allow user to insert the timestamps into a user-chosen location
    v.2020-03-02 by Waddah Moghram
        1. Reverted back to print eps instead of exportfig. For full-resolution, it messes things up.
    v.2020-02-28 by Waddah Moghram
        1. Give the user the choice to adjust the width of the colorbar and
        quiver line width.
    v.2020-02-26 by Waddah Moghram
        1. Fixed colorbar limits for more than 2 decimal significant digits
    v.2020-02-13 by Waddah Moghram
        1. Gives the user more flexbility with scale bar and color bar fonts and the right edge buffer.
    v.2020-02-12 by Waddah Moghram
        1. Tried solving the memory leak problem with the RAM by deleting objects in the 
        figure to no avail. Just close MATLAB after a single run.
    v.2020-02-09..10 by Waddah Moghram
        1. Added a scale bar to be included with the heatmap
        2. updated the export option to *.eps that can be customized using 
            exportfig.m
        3. Adjust the decimals of the colorbar labels (ticks).
    v.2020-02-07 by Waddah Moghram
        1. Changed quivercolor based on the complement of the heatmap for maximum visibility.
    v.2020-02-06 by Waddah Moghram
        1. updated so that heatmap is interpolated directly from the original datapoints.
    v.2020-02-05 by Waddah Moghram
        1. Calculating the norm of the interpolated components instead of the interpolation of the norm of the smaller grid
        2. Updated interpolation from griddata to use V4 based on the cubic interpolation to ensure a C2 continuous function.
    v.2020-02-03 by Waddah Moghram
        1. Added a step ask the user if the quiver size is OK or not. 
        2. change the heatmap max to match that of the maximum displacement frame, and not of the raw displacements. 
    v.2020-01-30 by Waddah Moghram
        1. Fixed grid size so that: ErodeEdge = 1, gridMagnification = 1
        2. switch back to griddata() and use 'cubic' unless you can use gridded data, and then griddedinterpolant
                C2 continue. 
    v.2020-01-28 by Waddah Moghram
        1. Updated quiver scale to use multiples of suggested one instead of entering exact number?
        2. Fixed every Nth datapoint to work correctly.
    v.2020-01-20 by Waddah Moghram
        1. Plot every other (or every nth point in the grid to show more and zero out every other one 
        2. Added possibility to change the colormap 
    v.2020-01-16..17 by Waddah Moghram
        1. Add an option to remove the second to top label (Remove2ndToTopLabel) if it is
        overlapping with the top one. Default option is to ask what to do, but keep it.
        2. Rename the displacement so that it matches the output for the
        paper
        3. Added a QuiverMagnificationFactor to go by a whole number. Needs to be tweaked internally. So far. it is 2X
    v.2019-12-18 by Waddah Moghram
        1. Fixed FirstFrame error if starting from the middle
    v.2019-11-22 by Waddah Moghram
        1. Made this program compatible with tracking multiple frames at at time.
        2. Change variable names to make DisplacementOverlays, DisplacementHeatmaps, ForceOverlays, ForceHeatmaps the same
            to make changes more efficient in the future.
    v.2019-11-20 by Waddah Moghram
        1. Fixed transpose problem with heatmaps         imagesc(figAxesHandle, 'CData', displHeatMapPadded')
    v.2019-10-23 by Waddah moghram
        1. Fixed "maxDisplacement" input to "colorbarLimits"
        2. Plot without figure stealing focus. Use clf(figHandle, 'reset'), and ...
    v.2019-10-22 by Waddah Moghram
        1. Fixed the location of the transpose for displHeatMap after padding with 0s. 
    v.2019-10-13 by Waddah Moghram
        1. Added the padding to the heatmap to fix the original size of the image. Got rid of the offset -xmin and -ymin for the quivers
        2. Added set(figHandleAxes, 'YDir', 'reverese') to make sure that the top-left corner is the origin for images.
    v.2019-10-02 by WIM
        1. Fixed the problem of the quiver rescaling the image. Set the Camera View to Manual after the plot.
        2. Figure out an autoscale based on average bead separation distance (90% of that)
        3. Moved up nargin 11 (max displacement) filter ahead of quiver 
        4. Extract traction limits from the process directly instead of manually first.
    v.2019-09-24 by WIM
        1. Added an if statement to close figHandle every 30 frames to prevent image flow using mod(CurrentFrame, 30)
    v.2019-09-06..15
        1. the heat map size is the same as that of the image. 
        2. improve the shape and ticks of the label (outside. among other improvements.
    v.2019-06-13..4 Update v3.10 
        1. FIxed some errors 
        2. Removed "DisplacementUnitStr' from input. Only microns 
        3. Update glitch with displField argument input parsing
    v.2019-06-11 Update v.3.00 PlotDisplacementHeatmapField.
        1. Change the ouput and input variables format and counts.
                HeatMapPath (TrackedDisplacementPath) -> DisplacementHeatMapPath - > TrackedFilesNum
                TrackedDisplacementVideoChoice -> DisplacementHeatMapVideoChoice
                "Displacement Overlays" -> "Displacement Heatmaps"
        2. Made the program run more smoothly under various scenarios. This program can be independtly run without any function inputs.

    v2.00 generatedTrackedDisplacement use dot to track the tracked beads. Quivers are also possible.
    for now, just run by giving no arguments, or up to the first 4 arguments.
    Needs to be fixed for certain input arguments, as they generate error messages.
    
    Written by Waddah Moghram, PhD Student in Biomedical Engineering. Updated on 2019-09-06
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
function [MD, displField, FirstFrame, LastFrame, movieFilePath, outputPath, analysisOutputPath] = PlotDisplacementHeatmapField(MD, displField, ...
    FirstFrame, LastFrame, outputPath, MagnificationTimes, showQuiver, showPlot, saveVideo, ...
     analysisOutputPath, colorbarLimits, bandSize, width, height, colorMapMode, Remove2ndToTopLabel,QuiverPlotEveryNth, QuiverPlotEveryNthShift)
 
    colorbarUnits = sprintf('%sm', char(181));              % colorbarUnits = '\mum';  % Unicode 181 = greek small case mu
    colorbarUnits2 = 'microns';
    showPlot = 1;   

    ErodeEdge = 1;
    gridMagnification = 1;
    QuiverMagnificationFactor = 4;              % Added on 2020-01-17
    QuiverPlotEveryNthDefault = 1;
    QuiverPlotEveryNthShiftDefault = 0;
    QuiverLineWidth = 1;
    InterpolationMethod = 'griddata';
    FigRenderer = 'painters';                   % other option is openGL
    PlotsFontName = 'Times New Roman';   
    bandSize = 0;      % pixels
    offSetWindow = 50;
    reverseString = '';
    FramesAtOnce = 10;
    scalebarFontSize = 10;
    ylabelFontSize = 10;
    
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
    EPSparam.LineWidth = 1;           % can be varied depending on what you want it to be    
    EPSparam.Width = 4;         % In inches
    EPSparam.Width = 3.26;   
    
    EPSparams = {};
    EPSparamsFieldNames = fieldnames(EPSparam);
    for ii = (1:numel(fieldnames(EPSparam)))
        EPSparams{2*ii - 1} = EPSparamsFieldNames{ii};
    end
    for ii = (1:numel(fieldnames(EPSparam)))
        EPSparams{2*ii} = EPSparam.(EPSparamsFieldNames{ii});
    end
    
    %% ========  Check for extra nargin ============================================================  
    if nargin > 18
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
    
    disp('============================== Running PlotDisplacementHeatmapField.m GPU-enabled ===============================================')
    
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
    
    %% --------- Initial Variableds
    ImageSizePixels = MD.imSize_;
    MarkerSize = round(ImageSizePixels(1)/ 1000, 1, 'decimals');
            
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
        [displacementFileName, outputPath] = uigetfile(TFMPackageFiles, 'Open the displacement field "displField.mat" under displacementField or backups');
        if displacementFileName == 0, return; end
        InputFileFullName = fullfile(outputPath, displacementFileName);
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
        outputPath = uigetdir(outputPath,'Choose the directory where you want to store the tracked Displacement Field Heatmaps.');
        if outputPath == 0  % Cancel was selected
            clear outputPath;
        elseif ~exist(outputPath,'dir')
            mkdir(outputPath);
        end
        
        fprintf('Tracked Displacement Field Heatmaps Path is: \n\t %s\n', outputPath);
        disp('------------------------------------------------------------------------------')
    end    
        
    InputParamFile = fullfile(outputPath, 'Displacement Heatmaps Parameters.mat');
    
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
    
    
       %% --------  nargin 10, Analysis Output Folder (Analysispath)-------------------------------------------------------------------  
    if ~exist('analysisOutputPath','var'), analysisOutputPath = []; end    
    if nargin < 10 || isempty(analysisOutputPath)
        AnalysisTIFcount = 0;
        AnalysisJPEGcount = 0;        
        AnalysisFIGcount = 0; 
        AnalysisEPScount = 0;
        AnalysisMATcount = 0;
                
        dlgQuestion = ({'Do you want to save in an Analysis output folder?'});
        dlgTitle = 'Analysis folder?';
        AnalysisFolderChoice = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No', 'No');
        switch AnalysisFolderChoice
            case 'Yes'
                if ~exist('movieFilePath','var'), movieFilePath = pwd; end
                analysisOutputPath = uigetdir(movieFilePath,'Choose the analysis directory where the heatmap output will be saved.');     
                if analysisOutputPath == 0  % Cancel was selected
                    clear AnalysisPath;
                elseif ~exist(analysisOutputPath,'dir')   % Check for a directory
                    mkdir(analysisOutputPath);
                end    
                if strcmp(plotTypeChoice, 'Images') && exist('AnalysisPath', 'var')
                    for ii = 1:numel(ImageChoice)
                        tmpImageChoice =  ImageChoice{ii};
                        switch tmpImageChoice
                            case 'TIF'
                                AnalysisPathTIF = fullfile(analysisOutputPath, '03 Displacement Heatmaps TIF');
                                if ~exist(AnalysisPathTIF,'dir'), mkdir(AnalysisPathTIF); end
                                fprintf('Analysis Tracked Displacement Heatmaps Path - TIF is: \n\t %s\n', AnalysisPathTIF);
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
                                AnalysisPathJPEG = fullfile(analysisOutputPath, '06 Displacement Heatmaps JPEG');
                                if ~exist(AnalysisPathJPEG,'dir'), mkdir(AnalysisPathJPEG); end
                                fprintf('Analysis Tracked Displacement Heatmaps Path - JPEG is: \n\t %s\n', AnalysisPathJPEG);
                                try
                                    AnalysisFilesJPEG =  dir(fullfile(AnalysisPathJPEG, '*.jpeg'));
                                    clear TrackedFilesNum
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
                                AnalysisPathFIG = fullfile(analysisOutputPath, '06 Displacement Heatmaps FIG');
                                if ~exist(AnalysisPathFIG,'dir'), mkdir(AnalysisPathFIG); end
                                fprintf('Analysis Tracked Displacement Heatmaps Path - FIG is: \n\t %s\n', AnalysisPathFIG);
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
                                AnalysisPathEPS = fullfile(analysisOutputPath, '06 Displacement Heatmaps EPS');
                                if ~exist(AnalysisPathEPS,'dir'), mkdir(AnalysisPathEPS); end
                                fprintf('Analysis Tracked Displacement Heatmaps Path - EPS is: \n\t %s\n', AnalysisPathEPS);
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
                            case 'MAT data'
                                AnalysisPathMAT = fullfile(analysisOutputPath, '06 Displacement Heatmaps MAT');  
                                if ~exist(AnalysisPathMAT,'dir'), mkdir(AnalysisPathMAT); end
                                fprintf('Analysis Tracked Displacement Heatmaps Path - MAT is: \n\t %s\n', AnalysisPathMAT);
                                try
                                    AnalysisFilesMAT =  dir(fullfile(AnalysisPathMAT, '*.mat'));
                                    clear TrackedFilesNum
                                    for jj = 1:numel(AnalysisFilesMAT) 
                                        NumberBlocks = regexp(AnalysisFilesMAT(jj).name,'\d+');
                                        NumbersFromFileIndex = regexp(AnalysisFilesMAT(jj).name,'\d');
                                        NumbersFromFileStartIndex = find(NumbersFromFileIndex == NumberBlocks(end));
                                        NumbersOfFile = NumbersFromFileIndex(NumbersFromFileStartIndex:end);
                                        TrackedFilesNum(jj) = str2double(AnalysisFilesMAT(jj).name(NumbersOfFile));
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
            case 'No'
                % continue. Do nothing
            otherwise
                return
        end               
    end
    
   %% --------  nargin 12, Blank Band Size around plot (bandSize) in pixels-------------------------------------------------------------------  
    if ~exist('bandSize','var'), bandSize = []; end
    if nargin < 12 || isempty(bandSize)
        bandSize = 0;
    end
    fprintf('Band size is %g pixels, or %g microns. \n', bandSize, bandSize * ScaleMicronPerPixel);
    disp('------------------------------------------------------------------------------');
    
   %% --------  nargin 15, Heatmap color map plot-------------------------------------------------------------------  
    if ~exist('colorMapMode','var'), colorMapMode = []; end
    try
        ImageBits = MD.camBitdepth_ - 2;   % Typically if 16 bits are used. Then image will be saved in 14 bits.
    catch
        ImageBits = 14; 
    end
        
    if nargin < 15 || isempty(colorMapMode)        
        colorMapList = {'copper', 'fake_parula', 'inferno', 'jet', 'magma', 'parula', 'viridis', 'plasma'};
        colorMapChoice = listdlg('ListString' , colorMapList, 'SelectionMode', 'single', 'InitialValue', 2 , 'PromptString' , 'Choose a Colormap:');
        if isempty(colorMapChoice); return; end
        colorMapMode =colorMapList{ colorMapChoice};
    end
           
    warning('Full Resolution works only if ShowPlot is ''on''!');
    
   %% --------  nargin 9, ShowVideo (vs. Images) (Yes/Y/1/Images/I vs. No/N/0/Video/V)-------------------------------------------------------------------  
    if ~exist('saveVideo','var'), saveVideo = []; end
    if nargin < 9 || isempty(saveVideo)
        TrackedTIFcount = 0;
        TrackedJPEGcount = 0;
        TrackedFIGcount = 0; 
        TrackedEPScount = 0;
        TrackedMATcount = 0;
        
        dlgQuestion = 'Do you want to save as videos or as image sequence?';
        dlgTitle = 'Video vs. Image Sequence?';        
        plotTypeChoice = questdlg(dlgQuestion, dlgTitle, 'Video', 'Images', 'Video');
        
    elseif saveVideo == 0 || upper(saveVideo) == 'N'
        plotTypeChoice = 'Images';
    elseif saveVideo == 1 || upper(saveVideo) == 'Y'
        plotTypeChoice = 'Video';
    else 
        errordlg('Invalid Plot Type Choice')
        return
    end
    
    switch plotTypeChoice
        case 'Video'
            saveVideo = true;
            dlgQuestion = 'Select video format.';
            listStr = {'Archival', 'Motion JPEG AVI', 'Motion JPEG 2000','MPEG-4','Uncompressed AVI','Indexed AVI','Grayscale AVI'};
            [DisplacementHeatMapVideoChoice, TF1] = listdlg('ListString', listStr, 'PromptString',dlgQuestion, 'InitialValue', 2, 'SelectionMode' ,'Single');    
            if TF1 == 0, return; end            
            DisplacementHeatMapVideoChoice = listStr{DisplacementHeatMapVideoChoice};
        case 'Images'
            saveVideo = false;
            dlgQuestion = 'Select image format.';
            listStr = {'TIF', 'JPEG', 'FIG', 'EPS', 'MAT data'};
            [ImageChoice, TF2] = listdlg('ListString', listStr, 'PromptString',dlgQuestion, 'InitialValue', 1, 'SelectionMode' ,'multiple');    
            if TF2 == 0, return; end
            ImageChoice = listStr(ImageChoice);                 % get the names of the string.   
            if  strcmp(plotTypeChoice, 'Images')
                for ii = 1:numel(ImageChoice)
                    tmpImageChoice =  ImageChoice{ii};
                    switch tmpImageChoice
                        case 'TIF'
                            TrackedPathTIF = fullfile(outputPath, 'Displacement Heatmaps TIF');
                            if ~exist(TrackedPathTIF,'dir'), mkdir(TrackedPathTIF); end
                            fprintf('Tracked Displacement Heatmaps Path - TIF is: \n\t %s\n', TrackedPathTIF);
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
                            TrackedPathJPEG = fullfile(outputPath, 'Displacement Heatmaps JPEG');
                            if ~exist(TrackedPathJPEG,'dir'), mkdir(TrackedPathJPEG); end
                            fprintf('Tracked Displacement Heatmaps Path - JPEG is: \n\t %s\n', TrackedPathJPEG);
                            try
                                TrackedFilesJPEG =  dir(fullfile(TrackedPathJPEG, '*.jpeg'));
                                clear TrackedFilesNum
                                for jj = 1:numel(TrackedFilesJPEG) 
                                    NumberBlocks = regexp(TrackedFilesJPEG(jj).name,'\d+');
                                    NumbersFromFileIndex = regexp(TrackedFilesJPEG(jj).name,'\d');
                                    NumbersFromFileAll = regexp(TrackedFilesJPEG(jj).name,'[0-9]','match');
                                    NumbersFromFileStartIndex = find(NumbersFromFileIndex == NumberBlocks(end));
                                    NumbersOfFile = NumbersFromFileIndex(NumbersFromFileStartIndex:end);
                                    TrackedFilesNum(jj) = str2double(TrackedFilesJPEG(jj).name(NumbersOfFile));
                                end
                                TrackedJPEGcount = max(TrackedFilesNum);
                            catch
                                TrackedJPEGcount = 0;
                            end                            
                        case 'FIG'
                            TrackedPathFIG = fullfile(outputPath, 'Displacement Heatmaps FIG');
                            if ~exist(TrackedPathFIG,'dir'), mkdir(TrackedPathFIG); end
                            fprintf('Tracked Displacement Heatmaps Path - FIG is: \n\t %s\n', TrackedPathFIG);
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
                            TrackedPathEPS = fullfile(outputPath, 'Displacement Heatmaps EPS');
                            if ~exist(TrackedPathEPS,'dir'), mkdir(TrackedPathEPS); end
                            fprintf('Tracked Displacement Heatmaps Path - EPS is: \n\t %s\n', TrackedPathEPS);
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
                        case 'MAT data'
                            TrackedPathMAT = fullfile(outputPath, 'Displacement Heatmaps MAT');  
                            if ~exist(TrackedPathMAT,'dir'), mkdir(TrackedPathMAT); end
                            fprintf('Tracked Displacement Heatmaps Path - MAT is: \n\t %s\n', TrackedPathMAT);
                            try
                                TrackedFilesMAT =  dir(fullfile(TrackedPathMAT, '*.mat'));
                                clear TrackedFilesNum
                                for jj = 1:numel(TrackedFilesMAT) 
                                    NumberBlocks = regexp(TrackedFilesMAT(jj).name,'\d+');
                                    NumbersFromFileIndex = regexp(TrackedFilesMAT(jj).name,'\d');
                                    NumbersFromFileAll = regexp(TrackedFilesMAT(jj).name,'[0-9]','match');
                                    NumbersFromFileStartIndex = find(NumbersFromFileIndex == NumberBlocks(end));
                                    NumbersOfFile = NumbersFromFileIndex(NumbersFromFileStartIndex:end);
                                    TrackedFilesNum(jj) = str2double(TrackedFilesMAT(jj).name(NumbersOfFile));
                                end
                                TrackedMATcount = max(TrackedFilesNum);
                            catch
                                TrackedMATcount = 0;
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
    
    
    %% --------  nargin 3, FirstFrame. Check for previously plotted images -------------------------------------------------------------------  
    if ~exist('FirstFrame','var'), FirstFrame = []; end
    if nargin < 3 || isempty(FirstFrame)
        switch plotTypeChoice
            case 'Images'
                FramesTrackedCountMax = max([TrackedTIFcount, TrackedJPEGcount, TrackedFIGcount, TrackedEPScount, TrackedMATcount ...
                    AnalysisTIFcount, AnalysisJPEGcount, AnalysisFIGcount, AnalysisEPScount, AnalysisMATcount]);
                try
                    FramesTrackedMax = FramesDoneNumbers(FramesTrackedCountMax);
                catch
                    FramesTrackedMax = 0;
                end
                if FramesTrackedMax == 0
                    FirstFrame =  VeryFirstFrame;
                elseif FramesTrackedMax == VeryLastFrame
                    dlgQuestion = ({'All frames have been previously tracked.  Do you want to start from the beginning again?'});
                    dlgTitle = 'Retrack Frames?';
                    ReTrackFramesChoice = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No', 'Yes');
                    switch ReTrackFramesChoice
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
            case 'Video'
                FirstFrame =  VeryFirstFrame;            
            otherwise
                return
        end
        %------------------
        prompt = {sprintf('Choose the first frame to plotted. [Default, max last frame tracked so far = %d]', FirstFrame)};
        dlgTitle = 'First Frame';
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
        dlgTitle = 'Last Frame';
        LastFrameStr = inputdlg(prompt, dlgTitle, [1, 70], {num2str(LastFrame)});
        if isempty(LastFrameStr), return; end
        LastFrame = str2double(LastFrameStr{1});                                  % Convert to a number
        [~, LastFrameIndex] = min(abs(FramesDoneNumbers - LastFrame));              % choose a non-empty frame
        LastFrame = FramesDoneNumbers(LastFrameIndex);
    end
    fprintf('Last Frame tracked = %d\n', LastFrame);
    disp('------------------------------------------------------------------------------') 
    
    FramesToBePloted = FramesDoneNumbers(FirstFrameIndex:LastFrameIndex);
    FramesDoneNumbers = FramesToBePloted;
    
    %% --------  nargin 11, Maximum Displacement, microns (maxInput) -------------------------------------------------------------------  
    if ~exist('colorbarLimits','var'), colorbarLimits = []; end              % this is necessary if you know what the max is ahread of it
    maxInput = -1;
    maxFrame = -1;
    minInput = Inf;

    [reg_grid, ~, ~, GridSpacing] = createRegGridFromDisplField(displField(FramesDoneNumbers(1)).pos, gridMagnification,ErodeEdge);                                                % 2=2 times fine interpolation

    if nargin < 11 || isempty(colorbarLimits)    
%         try
%             minInput = MD.findProcessTag(ProcessTag).tMapLimits_(1);
%             maxInput = MD.findProcessTag(ProcessTag).tMapLimits_(2);            
%         catch
            disp('Evaluating the maximum and minimum displacement value in progress....')
            reverseString = '';   
            for CurrentFrame = FramesDoneNumbers                
                ProgressMsg = sprintf('\nEvaluating Frame #%d/%d...\n', CurrentFrame, FramesDoneNumbers(end));
                fprintf([reverseString, ProgressMsg]);
                reverseString = repmat(sprintf('\b'), 1, length(ProgressMsg));
        
%                 if useGPU
%                     FieldVec = gpuArray(displField(CurrentFrame).vec(:,1:2));
%                 else
%                     FieldVec = displField(CurrentFrame).vec(:,1:2);
%                 end          
%                 FieldVecNorm = (FieldVec(:,1).^2+FieldVec(:,2).^2).^0.5;
%                 if nargin < 4 || isempty(maxInput)
%                     [maxInput, maxInputIndex] = max([maxInput, max(FieldVecNorm)]);
%                     if maxInputIndex == 2, maxFrame = CurrentFrame; end
%                     minInput = min([minInput,min(FieldVecNorm)]);
%                 end
%             end 
            
            
          % This is the most rigorous way, but it is very time consuming. 
                [~,d_mat, ~, ~] = interp_vec2grid(displField(CurrentFrame).pos(:,1:2), displField(CurrentFrame).vec(:,1:2),[],reg_grid1, 'griddata');            % 1:cluster size
                d_norm = (d_mat(:,:,1).^2 + d_mat(:,:,2).^2).^0.5;
                     % Boundary cutting - I'll take care of this boundary effect later
                if band > 2
                    d_norm(end-(round(band/2)+1:end),:)=[];
                    d_norm(:,end-(round(band/2)+1:end))=[];
                    d_norm(1:(round(band/2)-1),:)=[];
                    d_norm(:,1:(round(band/2)-1))=[];
                end
                d_norm_vec = reshape(d_norm,[],1); 
                [maxInput, maxInputIndex] = max([maxInput,max(d_norm_vec)]);
                if maxInputIndex == 2, maxFrame = CurrentFrame; end
                minInput = min([minInput,min(d_norm_vec)]);
            end
%     else
%         msgbox('Make sure the Maximum Displacement entered is in microns.')
    end
%     
%     maxInputMicron = maxInput * ScaleMicronPerPixel;            % 2020-02-03. This will be superseded by the value found on the max frame.
%     minInputMicron = minInput * ScaleMicronPerPixel;
    
    %% --------  nargin 8, ShowPlot (Yes/Y/1/On vs. No/N/0/Off)-------------------------------------------------------------------  
%     if ~exist('showPlot','var'), showPlot = []; end
%     if nargin < 8 || isempty(showPlot)
%         dlgQuestion = 'Do you want to show displacement heatmap in frames as they are made?';
%         dlgTitle = 'Show Plots In Progress?';
%         showPlotChoice = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No', 'Yes');
%     elseif showPlot == 0 || strcmpi(showPlot, 'N') || strcmpi(showPlot, 'No') || strcmpi(showPlot, 'Off')
%         showPlotChoice = 'No';
%     elseif showPlot == 1 || strcmpi(showPlot, 'Y') || strcmpi(showPlot, 'Yes') || strcmpi(showPlot, 'On')
%         showPlotChoice = 'Yes';
%     end    
%     switch showPlotChoice
%         case 'Yes'
%             showPlot = 'on';
%         case 'No'
%             showPlot = 'off';
%         otherwise
%             return
%     end
    
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
    %% Added on 2019-10-07 for now until full resolution is fixed for this function when plot is hidden
    
    %% --------  nargin 16,QuiverPlotEveryNth ------------------------------------------------------------------
    if ~exist('QuiverPlotEveryNth', 'var'), QuiverPlotEveryNth = []; end
    if nargin < 16 || isempty(QuiverPlotEveryNth)
        prompt = {sprintf('Plot Every Nth Grid Point? [Default N = %g]', QuiverPlotEveryNthDefault)};
        dlgTitle = 'Reduce Grid Points?';
        
        QuiverPlotEveryNthStr = {num2str(QuiverPlotEveryNthDefault)};
        QuiverPlotEveryNthChoice = inputdlg(prompt, dlgTitle, [1, 50], QuiverPlotEveryNthStr);
        QuiverPlotEveryNth = str2double(QuiverPlotEveryNthChoice{:});
    end
      
    if ~exist('QuiverPlotEveryNthShift', 'var'), QuiverPlotEveryNthShift = []; end
    if nargin < 17 || isempty(QuiverPlotEveryNthShift)
        prompt = {sprintf('Shift to the right/bottom by how many points? [Default N = %g]', QuiverPlotEveryNthShiftDefault)};
        dlgTitle = 'Shift Grid to Right/Bottom?';
        
        QuiverPlotEveryNthShiftStr = {num2str(QuiverPlotEveryNthShiftDefault)};
        QuiverPlotEveryNthShiftChoice = inputdlg(prompt, dlgTitle, [1, 50], QuiverPlotEveryNthShiftStr);
        QuiverPlotEveryNthShift = str2double(QuiverPlotEveryNthShiftChoice{:});
    end
    
    
    %% ======== Convert pixels to microns ============================================================  
    % 2. Covnert only displacements (.vec) to microns. Keep Starting positions in pixels. Keep the same structure
    totalPointsTracked = size(displField(VeryFirstFrame).pos, 1);
    displFieldMicron = struct('pos', zeros(totalPointsTracked, 1), 'vec',  zeros(totalPointsTracked, 1));
    for CurrentFrame = FramesDoneNumbers
          tmpField = displField(CurrentFrame).vec;
          displFieldMicron(CurrentFrame).pos = displField(CurrentFrame).pos;             % pixels
          displFieldMicron(CurrentFrame).vec = tmpField * ScaleMicronPerPixel; 
    end
    maxInputMicron = maxInput * ScaleMicronPerPixel; 
    fprintf('Maximum displacement is %g microns, based on tracked points. \n', maxInputMicron);  
    disp('------------------------------------------------------------------------------') 
    
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
        finalSuffix = 'Displacement Heatmaps';
        videoFile = fullfile(outputPath, finalSuffix);        
        writerObj = VideoWriter(videoFile, DisplacementHeatMapVideoChoice);
        try
            writerObj.FrameRate = FrameRateActual; 
        catch
            writerObj.FrameRate = 40; 
        end          
        try
            if exist(analysisOutputPath, 'dir')
                finalSuffixAnalysis = '07 Displacement Heatmaps';
                videoFileAnalysis = fullfile(analysisOutputPath, finalSuffixAnalysis);               
                writerObjAnalysis = VideoWriter(videoFileAnalysis, DisplacementHeatMapVideoChoice);
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
    disp('------------------------- Starting generating the plotted image sequence. ---------------------------------------------------')   
   %% --------  nargin 7, ShowQuiver (Yes/Y/1 vs. No/N/0)-------------------------------------------------------------------    
    QuiverScaleToMax = [];
    
    [reg_grid, ~, ~, gridSpacing] = createRegGridFromDisplField(displFieldMicron(maxFrame), gridMagnification, ErodeEdge);
    [grid_mat, displVecGridXY,~,~] = interp_vec2grid(displFieldMicron(maxFrame).pos(:,1:2), displFieldMicron(maxFrame).vec(:,1:2) ,[], reg_grid, InterpolationMethod);
    grid_matX = grid_mat(:,:,1);
    grid_matY = grid_mat(:,:,2);

    grid_spacingX = grid_mat(1,2,1)- grid_mat(1,1,1);
    grid_spacingY = grid_mat(2,1,2)- grid_mat(1,1,2);        
    imSizeX = (grid_mat(end,end,1) - grid_mat(1,1,1)) + grid_spacingX;
    imSizeY = (grid_mat(end,end,2) - grid_mat(1,1,2)) + grid_spacingY;

    if ~exist('width', 'var') || ~exist('height', 'var'), width = []; height = []; end
    if nargin < 14 || isempty(width) || isempty(height)
        width = imSizeX;
        height = imSizeY;
    end
    %----------------------------------------------------------------------------------------------
    centerX = ((grid_mat(end,end,1) + grid_mat(1,1,1))/2);
    centerY = ((grid_mat(end,end,2) + grid_mat(1,1,2))/2);
    % [XI,YI] = meshgrid(grid_mat(1,1,1):grid_mat(1,1,1)+imSizeX,grid_mat(1,1,2):grid_mat(1,1,2)+imSizeY);
    Xmin = centerX - width/2 + bandSize;
    Xmax = centerX + width/2 - bandSize;
    Ymin = centerY - height/2 + bandSize;
    Ymax = centerY + height/2 - bandSize;
    %         [XI,YI] = meshgrid(Xmin:Xmax,Ymin:Ymax);       
    [XI,YI] = ndgrid(Xmin:Xmax,Ymin:Ymax);                % Addded on 2019-10-10 to go with gridded interpolant, the line above is for griddata
    %-----------------------------------------------------------------------------------------------            
    % Added by WIM on 2/5/2019
    % All values moving forward are in microns for displacement
    dMap = cell(1,numel(displFieldMicron));
    dMapX = cell(1,numel(displFieldMicron));
    dMapY = cell(1,numel(displFieldMicron));
    displVecGridNorm = (displVecGridXY(:,:,1).^2 + displVecGridXY(:,:,2).^2).^0.5;
    %-----------------------------------------------------------------------------------------------             
    dMap = displVecGridNorm;
    dMapX = displVecGridXY(:,:,1);
    dMapY = displVecGridXY(:,:,2);
    if useGPU
        grid_mat = gather(grid_mat);
        displVecGridNorm = gather(displVecGridNorm);
        XI = gather(XI);
        YI = gather(YI);
    end

    reg_gridFull(:,:,1)  = XI; reg_gridFull(:,:,2)  = YI;
    [grid_mat_full, displVecGridFullXY,~,~] = interp_vec2grid(displFieldMicron(maxFrame).pos(:,1:2), displFieldMicron(maxFrame).vec(:,1:2) ,[], reg_gridFull, InterpolationMethod);
    displHeatMapX = displVecGridFullXY(:,:,1);
    displHeatMapY = displVecGridFullXY(:,:,2);
    displHeatMap = (displHeatMapX.^2 + displHeatMapY.^2).^0.5;              % Find the norm   

    displHeatMapPadded = zeros(ImageSizePixels);                                % Added on 2019-10-13
    displHeatMapPadded(Xmin:Xmax,Ymin:Ymax) = gather(displHeatMap);                    % Reverse back to MeshGrid format for the heatmap. Verified 2020-02-19

    if useGPU
        displFieldMicronPos = gpuArray(displFieldMicron(CurrentFrame).pos);
        displFieldMicronVec = gpuArray(displFieldMicron(CurrentFrame).vec);
    else
        displFieldMicronPos = displFieldMicron(CurrentFrame).pos;
        displFieldMicronVec = displFieldMicron(CurrentFrame).vec;
    end
%% -----------------------------------------------------------------------------------------------   
    figHandleInitial = figure('visible','on', 'color', 'w', 'MenuBar','none', 'Toolbar','none', 'Units', 'pixels', 'Resize', 'off', 'Renderer', FigRenderer);     % added by WIM on 2019-09-14. To show, remove 'visible
    figAxesHandle = axes;
    set(figAxesHandle, 'Box', 'on', 'XTick',[], 'YTick', [], 'Visible', 'on', 'YDir', 'reverse');
    set(figAxesHandle, 'Units', 'pixels');
    imagesc(figAxesHandle, 'CData', displHeatMapPadded')
    axis image
    truesize
    hold on
    
    colorMapCommand = sprintf('colormapLUT = colormap(%s(2^%d));', colorMapMode, ImageBits);
    eval(colorMapCommand)
    fprintf('Heatmap colormap is %s. \n', colorMapMode);
    QuiverColor = median(imcomplement(colormapLUT));               % User Complement of the colormap for maximum visibililty of the quiver.
    fprintf('Quiver Color RGB = [%0.4f, %0.4f, %0.4f]\n', QuiverColor)
    
    colorbarHandle = colorbar('eastoutside');        
    colorbarLimits = get(colorbarHandle, 'Limits');
    colorbarTicks = unique(sort([colorbarLimits, colorbarHandle.Ticks]));               % updated on 2019-10-23 to make sure points are unique
    set(colorbarHandle, 'Limits', [colorbarTicks(1), colorbarTicks(end)], 'Ticks', colorbarTicks, 'TickDirection', 'out','color', 'k', ...
            'FontWeight', 'bold', 'FontName', 'Helvetica-Narrow', 'LineWidth', QuiverLineWidth, 'Units', 'Pixels');     % font size, 1/100 of height in pixels
    
    colorbarLabelString =  sprintf('\\bf\\itu\\rm(\\itx\\fontsize{%d}*\\fontsize{%d},y\\fontsize{%d}*\\fontsize{%d},t\\rm) [%s]', ...
        repmat([ylabelFontSize * 0.75, ylabelFontSize] , 1, 2), colorbarUnits);
    ylabelHandle = ylabel(colorbarHandle, colorbarLabelString, 'FontSize', ylabelFontSize);        % 'Traction Stress (Pa)'; % in Tex Format
    
    minInputMicron = colorbarLimits(1);
%     maxInputMicron = colorbarLimits(2);
    
    % Seting up the limits for the colormap    
    prompt = {sprintf('Do you want the colorbar min to be , [Default = %g microns]', minInputMicron)};
    dlgTitle = 'Color Map Minimum (microns)';
    minInputMicronDefault = {num2str(minInputMicron)};
    colorbarLimitsStrMin = inputdlg(prompt, dlgTitle, [1, 70], minInputMicronDefault);
    colorbarLimits(1) = str2double(colorbarLimitsStrMin{:});
    
    prompt = {sprintf('Do you want the colorbar maximum to be , [Default = %g microns]', maxInputMicron)};
    dlgTitle = 'Color Map Maximum (microns)';
    maxInputMicronDefault = {num2str(maxInputMicron)};
    colorbarLimitsStrMax = inputdlg(prompt, dlgTitle, [1, 70], maxInputMicronDefault);
    colorbarLimits(2) = str2double(colorbarLimitsStrMax{:});               
    maxInput = maxInputMicron / ScaleMicronPerPixel;
    minInput = minInputMicron / ScaleMicronPerPixel;
    
    colorbarTicksExpDefault = colorbarHandle.Ruler.Exponent;
    prompt = {sprintf('Do you want to use this exponent for colorbar: 10^x, [x = %g]', colorbarTicksExpDefault)};
    dlgTitle = 'Colorbar 10^x exponent';
    colorbarTicksExpDefaultStr = {num2str(colorbarTicksExpDefault)};
    colorbarTicksExpStr = inputdlg(prompt, dlgTitle, [1 70], colorbarTicksExpDefaultStr);
    colorbarTicksExp = str2double(colorbarTicksExpStr{:});
    
    % Starting Fresh
    delete(colorbarHandle);
    caxis(colorbarLimits);
    colorbarHandle = colorbar('eastoutside'); 
    colorbarHandle.Limits = colorbarLimits;
    colorbarHandle.Ruler.TickLabelsMode = 'auto';    
    
    colorbarLimits = get(colorbarHandle, 'Limits');
    colorbarTicks = unique(sort([colorbarLimits, colorbarHandle.Ticks]));               % updated on 2019-10-23 to make sure points are unique
    set(colorbarHandle, 'Limits', [colorbarTicks(1), colorbarTicks(end)], 'Ticks', colorbarTicks, 'TickDirection', 'out', 'color', 'k',...
            'FontWeight', 'bold', 'FontName', 'Helvetica-Narrow', 'LineWidth', QuiverLineWidth, 'Units', 'Pixels');     % font size, 1/100 of height in pixels
    colorbarLabelString =  sprintf('\\bf\\itu\\rm(\\itx\\fontsize{%d}*\\fontsize{%d}, y\\fontsize{%d}*\\fontsize{%d}, t\\rm) [%s]', ...
        repmat([ylabelFontSize * 0.75, ylabelFontSize] , 1, 2), colorbarUnits);
    ylabelHandle = ylabel(colorbarHandle, colorbarLabelString, 'FontSize', ylabelFontSize);        % 'Traction Stress (Pa)'; % in Tex Format
    
    colorbarHandle.Ruler.Exponent = colorbarTicksExp;
    
    %_______________ Preserve ticks 2020-02-10 by WIM
    colorbarTickLabels = {};
    colorbarTickLabels{1} = num2str(colorbarTicks(1));
    colorbarTicks(1) = str2double(colorbarTickLabels{1});
    DecimalsColorbar = inputdlg('How many decimals to you want for 2nd to 2nd-to-last ticks [Default = 1]: ', ...
        'Decimals?', [1 70], {num2str(1)});
    DecimalsColorbar = str2double(DecimalsColorbar{:});
    if isempty(DecimalsColorbar) || ~isnumeric(DecimalsColorbar), DecimalsColorbar = 1; end
    colorbarTicksFormats = sprintf('%%0.%dg', DecimalsColorbar);
    
    colorbarHandle.Ruler.TickLabelFormat = colorbarTicksFormats;
    colorbarTickLabels = colorbarHandle.Ruler.TickLabels;
    commandLine = sprintf('sprintf(''%s'', colorbarTicks(ii));', sprintf('%s', colorbarTicksFormats));    
    for ii = 2:(numel(colorbarTicks)-1)
        CurrentTick = eval(commandLine);
        colorbarTickLabels{ii} = CurrentTick;
        colorbarTicks(ii) = str2double(CurrentTick);
    end
%     colorbarTickLabels{numel(colorbarTicks)} =  sprintf(sprintf('%%0.%df', DecimalsColorbar + 1), colorbarTicks(numel(colorbarTicks)));
    colorbarTickLabels{numel(colorbarTicks)} =  sprintf(sprintf('%%0.%df', DecimalsColorbar), colorbarTicks(numel(colorbarTicks)));
    colorbarTicks(numel(colorbarTicks)) = str2double( colorbarTickLabels{numel(colorbarTicks)});
    colorbarTickLabels = colorbarTickLabels';             % transpose it
    delete(colorbarHandle);
    caxis(colorbarLimits); 
    colorbarHandle = colorbar('eastoutside'); 
    colorbarHandle.Limits = colorbarLimits;   
    set(colorbarHandle, 'Limits', [colorbarTicks(1), colorbarTicks(end)], 'Ticks',colorbarTicks,  'TickLabels', colorbarTickLabels, 'TickDirection', 'out', 'color', 'k',...
            'FontWeight', 'bold', 'FontName', 'Helvetica-Narrow', 'LineWidth', QuiverLineWidth, 'Units', 'Pixels');     % font size, 1/100 of height in pixels     
    ylabelHandle = ylabel(colorbarHandle, colorbarUnits);        % 'Traction Stress (Pa)'; % in Tex Format
    minInputMicron = colorbarLimits(1);
    maxInputMicron = colorbarLimits(2);
    
    disp('------------------------------------------------------------------------------')
    disp('Evaluating the maximum and minimum heatmap displacement complete!')
    fprintf('Maximum displacement is %g pixels, or %g %s at frame %d/%d. \n', maxInput, maxInputMicron, colorbarUnits2, maxFrame, FramesDoneNumbers(end));
    fprintf('Minimum displacement is %g pixels, or %g %s. \n', minInput, minInputMicron, colorbarUnits2);
    fprintf('Color bar limits for net displacement is [%g, %g] %s). \n', colorbarLimits, colorbarUnits2);    
    disp('------------------------------------------------------------------------------')         
    
    % --------  nargin 6, ShowQuiver (Yes/Y/1 vs. No/N/0)-------------------------------------------------------------------
    if ~exist('showQuiver','var'), showQuiver = []; end
    if nargin < 7 || isempty(showQuiver)
        dlgQuestion = 'Do you want to show displacement quivers?';
        dlgTitle = 'Show Quivers?';
        QuiverChoice = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No', 'Yes');
    elseif showQuiver == 0 || strcmpi(showQuiver, 'N') || strcmpi(showQuiver, 'No')
        QuiverChoice = 'No';
    elseif showQuiver == 1 || strcmpi(showQuiver, 'Y') || strcmpi(showQuiver, 'Yes')
        QuiverChoice = 'Yes';
    end
    
    switch QuiverChoice
        case 'Yes'
            set(figHandleInitial, 'visible', 'on')
            showQuiver = true;
%             TotalAreaPixel = (max(displField(VeryFirstFrame).pos(:,1)) -  min(displField(VeryFirstFrame).pos(:,1))) * ...
%                 (max(displField(VeryFirstFrame).pos(:,2)) -  min(displField(VeryFirstFrame).pos(:,2)));                 % x-length * y-length
%             AvgInterBeadDist = sqrt((TotalAreaPixel)/size(displField(VeryFirstFrame).pos,1));        % avg inter-bead separation distance = total img area/number of tracked points
%             QuiverScaleDefault = 0.95 * (AvgInterBeadDist/ maxInput);
            QuiverScaleDefault = 0.95 * (GridSpacing/maxInput);
            prompt = {sprintf('Define the quiver scaling factor recommended, [Currently 1X = %0.16g]', QuiverScaleDefault)};
            dlgTitle = 'Quiver Scale Factor';
            QuiverMagnificationFactorDefault = {num2str(QuiverMagnificationFactor)};
            QuiverMagnificationFactor = inputdlg(prompt, dlgTitle, [1, 90],  QuiverMagnificationFactorDefault);        % Modified on 2020-01-17            
            if isempty(QuiverMagnificationFactor), return; end
            QuiverMagnificationFactor = str2double(QuiverMagnificationFactor{1});                                  % Convert to a number                
            QuiverScaleToMax = QuiverScaleDefault * QuiverMagnificationFactor;                                 %quiver plot maximum and scale
            if useGPU, QuiverScaleToMax = gather(QuiverScaleToMax); end
            
            prompt = {sprintf('Enter the quiver line width [Currently = %g points]', QuiverLineWidth)};
            dlgTitle = 'Quiver Line Width';
            QuiverLineWidthStr = {num2str(QuiverLineWidth)};
            QuiverLineWidthStr = inputdlg(prompt, dlgTitle, [1 60], QuiverLineWidthStr);
            if isempty(QuiverLineWidthStr), return; end             
            QuiverLineWidth = str2double(QuiverLineWidthStr{:});

            %% ================== Check if the quiver size is OK      %% ================== Check if the quiver size is OK                        
            try
                clear IsWithinGrid IsWithinGridSpliced
                IsWithinGridSpliced = zeros(size(grid_mat));
                for ii = 1:size(IsWithinGridSpliced,3)
                    IsWithinGridSpliced(1+QuiverPlotEveryNthShift:QuiverPlotEveryNth:end, 1+QuiverPlotEveryNthShift:QuiverPlotEveryNth:end, ii)  = 1;    
                end
            catch
                IsWithinGridSpliced = ones(size(grid_mat));            
                % continue normally
            end
            IsWithin = IsWithinGridSpliced(:,:,1) & IsWithinGridSpliced(:,:,2);

        %     TotalAreaPixel = (max(displField(VeryFirstFrame).pos(:,1)) -  min(displField(VeryFirstFrame).pos(:,1))) * ...
        %     (max(displField(VeryFirstFrame).pos(:,2)) -  min(displField(VeryFirstFrame).pos(:,2)));                 % x-length * y-length
        %                 AvgInterBeadDist = sqrt(1*(TotalAreaPixel)/size(displField(VeryFirstFrame).pos,1));        % avg inter-bead separation distance = total img area/number of tracked points
        %                 QuiverScaleDefault = 0.95 * (AvgInterBeadDist/ maxInput)*QuiverMagnificationFactor;
            QuiverScaleDefault = 0.95 * (GridSpacing/maxInput);

            X = reshape(grid_matX(IsWithin),1,[]);
            Y = reshape(grid_matY(IsWithin),1,[]);
            U = reshape(gather(dMapX(IsWithin)),1,[]);
            V = reshape(gather(dMapY(IsWithin)),1,[]);

            quiverNotOK = true;
            while quiverNotOK
                figure(figHandleInitial)    
                qHandle = quiver(figAxesHandle, X, Y,U .*QuiverScaleToMax,V .*QuiverScaleToMax, 0, ...
                   'MarkerSize',MarkerSize, 'markerfacecolor',QuiverColor, 'ShowArrowHead','on', 'MaxHeadSize', 3, ...
                  'color', QuiverColor, 'AutoScale','off', 'LineWidth', QuiverLineWidth , 'AlignVertexCenters', 'on');
                IsQuiverOK = questdlg('Are the plot quivers length and width looking OK?', 'Quiver Length/Width OK?', 'Yes', 'No', 'Yes');
                if isempty(IsQuiverOK), return; end
                switch IsQuiverOK
                    case 'Yes'
                        quiverNotOK = false;
                    case 'No'
                        disp('**___to continue, type "dbcont" or press "F5"___, or click "Continue" under "Editor" Menu"**')
                        keyboard

                        prompt = {sprintf('Enter the quiver magnification factor that you want. [Currently = %g]', QuiverMagnificationFactor)};
                        dlgTitle = 'QuiverScale';
                        QuiverMagnificationFactorStr = {num2str(QuiverMagnificationFactor)};
                        QuiverMagnificationFactorStr = inputdlg(prompt, dlgTitle, [1 60], QuiverMagnificationFactorStr);
                        if isempty(QuiverMagnificationFactorStr), return; end
                        QuiverMagnificationFactor = str2double(QuiverMagnificationFactorStr{:}); 
                        QuiverScaleToMax = QuiverScaleDefault * QuiverMagnificationFactor;                                 %quiver plot maximum and scale
                        
                        prompt = {sprintf('Enter the quiver line width [Currently = %g points]', QuiverLineWidth)};
                        dlgTitle = 'Quiver Line Width';
                        QuiverLineWidthStr = {num2str(QuiverLineWidth)};
                        QuiverLineWidthStr = inputdlg(prompt, dlgTitle, [1 60], QuiverLineWidthStr);
                        if isempty(QuiverLineWidthStr), return; end             
                        QuiverLineWidth = str2double(QuiverLineWidthStr{:});
                        
                        delete(qHandle)
                    otherwise 
                        return
                end
            end
            quiverColorNotOK = true;
            while quiverColorNotOK
                figure(figHandleInitial)
                QuiverColor = uisetcolor(QuiverColor); 
                if (logical(QuiverColor == 0) & logical(numel(QuiverColor)==1)), return; end
                set(qHandle, 'markerfacecolor',QuiverColor,  'color', QuiverColor)       
                IsQuiverColorOK = questdlg('Is the quiver color looking OK?', 'Quiver Color OK?', 'Yes', 'No', 'Yes');
                if isempty(IsQuiverColorOK), return; end
                switch IsQuiverColorOK
                    case 'Yes'
                        quiverColorNotOK = false;
                    case 'No'
                        disp('**___to continue, type "dbcont" or press "F5", or click "Continue" under "Editor" Menu"___**')
                        keyboard
                end
            end    
        case 'No'
            showQuiver = false;  
        otherwise
            return
    end
    %____________________
    ScaleBarChoice = questdlg({'Do you want to insert a scalebar?','If yes, choose the right-edge position'},'ScaleBar Position?', 'Yes', 'No', 'Yes');
    if isempty(ScaleBarChoice), return; end
    if strcmpi(ScaleBarChoice, 'Yes')
        set(figHandleInitial, 'visible', 'on')
        ScaleBarNotOK = true;
        ScaleBarColor = QuiverColor;
        while ScaleBarNotOK
            figure(figHandleInitial)
            [ScaleBarLocation(1), ScaleBarLocation(2)] = ginputc(1, 'Color', QuiverColor);
            
            ScaleBarUnits = sprintf('%sm', char(181));         % '\mum';                                    % in Microns 150 is Unicode for small mu
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
    
    % Added by WIM on 2020-06-04
    TimeStampsChoice = questdlg({'Do you want to insert timestamps?','If yes, choose the Left-edge position'},'Time Stamps?', 'Yes', 'No', 'Yes');
    if strcmpi(TimeStampsChoice, 'Yes')
        TimeStampsNotOK = true;
        TimeStampsFontSize = 12;
        TimeStamps = [];
        
        if isempty(TimeStamps)
            [TimeStampsFileName, TimeStampsPathName] = uigetfile(fullfile(movieFilePath, '*.*'), 'Choose EPI timestamps file (RT or ND2)');
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
%         FramesToBePloted = FramesToBePloted(FirstFrame:LastFrame);
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

    
        %% ======  Check for GPU & Save parameters so far ============================================================  
    if useGPU
        maxInput = gather(maxInput);
        minInput = gather(minInput);
        maxInputMicron = gather(maxInputMicron);
        minInputMicron = gather(minInputMicron);
    end
    
    InputUnits = 'Pixels';   
    save(InputParamFile, 'FirstFrame', 'LastFrame', 'maxInput', 'maxInputMicron', 'InputUnits', ...
       'minInput', 'minInputMicron', 'totalPointsTracked', 'colorbarLimits', '-v7.3')   
   
    switch QuiverChoice
        case 'Yes'
            if useGPU, QuiverScaleToMax = gather(QuiverScaleToMax); end
            save(InputParamFile, 'QuiverScaleToMax','QuiverMagnificationFactor','QuiverPlotEveryNth', 'QuiverColor', ...
            'QuiverLineWidth', 'QuiverPlotEveryNthShift', '-append')
    end
    
    try
        save(InputParamFile,'VeryLastFrame', '-append')
        if useGPU
            QuiverScaleToMax = gather(QuiverScaleToMax);
        end 
    catch
       % Continue
    end
    
    %% --------  nargin 15, Remove2ndToTopLabel color map plot -------------------------------------------------------------------  
    if ~exist('Remove2ndToTopLabel','var'), Remove2ndToTopLabel = []; end
    if nargin < 16 || isempty(Remove2ndToTopLabel)    
        dlgQuestion = ({'Do you want to remove the second-to-top label in the colormap bar to prevent overlap?'});
        dlgTitle = 'Remove second-to-top colormap bar label?';
        Remove2ndToTopLabelChoice = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No', 'No');
        switch Remove2ndToTopLabelChoice    
            case 'Yes'
                Remove2ndToTopLabel = true;
            case 'No'
                Remove2ndToTopLabel = false;
            otherwise
                Remove2ndToTopLabel = false;
        end
    end
    
    if  Remove2ndToTopLabel == 1 || strcmpi(Remove2ndToTopLabel, 'Y') || strcmpi(Remove2ndToTopLabel, 'Yes')
         Remove2ndToTopLabel = true;
    else
         Remove2ndToTopLabel = false;
    end
    save(InputParamFile, 'Remove2ndToTopLabel', '-append')
    try
        close(figHandleInitial);
    catch
        % continue
    end
    
   %% Final Check
    FontNotOK = true;
    ImageSize = [200, 500, 1000, 2000]';         % pixels
    FontSizeDesired = [7, 15, 18, 25]';          
    FontSizeCurveFit = fit(ImageSize,FontSizeDesired,'poly2');       % quadratic fit between 200 pixels and 2000 pixels window size.
    colorbarFontSize = round((FontSizeCurveFit.p1 * MD_EPI.imSize_(1)^2 + FontSizeCurveFit.p2 * MD_EPI.imSize_(1) + FontSizeCurveFit.p3)*2)/2;       % make in increments on 0.5 
    if colorbarFontSize < 7
        colorbarFontSize = 7;
    end   

    ylabelFontSize = colorbarFontSize + 2;
%     scalebarFontSize = 10;
    RightSideBuffer = 20;
    ScreenSize = get(0, 'Screensize');                       %---------Matlab 2014 and higher
    [reg_grid,~,~,~] = createRegGridFromDisplField(displField(VeryFirstFrame), gridMagnification, ErodeEdge); %2=2 times fine interpolation

    while FontNotOK
        figHandlePreview = figure('visible',showPlot, 'color', 'w', 'Toolbar','none', 'Menubar','none', 'Units', 'pixels', 'Resize', 'off', 'Renderer', FigRenderer);     % added by WIM on 2019-09-14. To show, remove 'visible
        WindowAPI(figHandlePreview, 'Position', [offSetWindow, (ScreenSize(4) - MD_EPI.imSize_(2) - (offSetWindow + (2* bandSize))), ...
                MD_EPI.imSize_(1) + 300, MD_EPI.imSize_(2) + (2 * bandSize)])          
        figAxesHandle = axes;
        set(figAxesHandle, 'Box', 'on', 'XTick',[], 'YTick', [], 'Visible', 'on', 'YDir', 'reverse');
        set(figAxesHandle, 'Units', 'pixels');        
        %-----------------------------------------------------------------------------------------
        hold on        
        eval(colorMapCommand);                  % consider eliminating this line. It might be what is causing the memory leak
        caxis(colorbarLimits);
        colorbarHandle = colorbar('eastoutside');
        
        if Remove2ndToTopLabel
            colorbarTickLabels{end - 1} = '';
        end   
        set(colorbarHandle, 'Limits', [colorbarTicks(1), colorbarTicks(end)], 'Ticks', colorbarTicks,'TickLabels', colorbarTickLabels, 'TickDirection', 'out', 'color', 'k',...
                'Fontsize', colorbarFontSize , 'FontWeight', 'bold', 'FontName', 'Helvetica-Narrow', 'LineWidth', QuiverLineWidth, 'Units', 'Pixels');     % font size, 1/100 of height in pixels
        colorbarLabelString =  sprintf('\\bf\\itu\\rm(\\itx\\fontsize{%d}*\\fontsize{%d}, y\\fontsize{%d}*\\fontsize{%d}, t\\rm) [%s]', ...
            repmat([ylabelFontSize * 0.75, ylabelFontSize] , 1, 2), colorbarUnits);
        %-----------------------------------------------------------------------------------------        
        ylabelHandle = ylabel(colorbarHandle, colorbarLabelString);    % 'Displacement (\mum)'; % in Tex format
        ylabelHandle.FontSize = ylabelFontSize;
        ylabelHandle.FontName = PlotsFontName;
        %-----------------------------------------------------------------------------------------                
        figAxesHandle.Position = [bandSize, bandSize, ImageSizePixels(1), ImageSizePixels(2)];
        axis equal
        axis off
        ylabelHandle.Units = 'pixels';
        colorbarHandle.Units = 'pixels';
        
        if ~exist('colorbarWidthPixels', 'var'), colorbarWidthPixels = colorbarHandle.Position(3);end        
        if ~exist('colorbarPositionInitial', 'var'), colorbarPositionInitial = colorbarHandle.Position;end
        
        if colorbarTicksExp == 0 
            offset = 2.5;
        else
            offset = 3.5;
        end
        
        set(colorbarHandle , 'Position', colorbarPositionInitial + [0, round(1* colorbarFontSize), 0, - offset * round(1* colorbarFontSize)]);
        ColorbarCurrentPosition = colorbarHandle.Position;
        ColorbarCurrentPosition(3) = colorbarWidthPixels;
        set(colorbarHandle , 'Position', ColorbarCurrentPosition);
        WindowAPI(figHandlePreview, 'Position', [offSetWindow, (ScreenSize(4) - ImageSizePixels(2) - (offSetWindow + (2* bandSize))), ...
            (ColorbarCurrentPosition(1) +  ColorbarCurrentPosition(3) + ylabelHandle.Position(1) + bandSize + RightSideBuffer) , ...
            ImageSizePixels(2) + (2 * bandSize)])          
        
        [grid_mat, displVecGridXY,~,~] = interp_vec2grid(displFieldMicron(maxFrame).pos(:,1:2), displFieldMicron(maxFrame).vec(:,1:2) ,[], reg_grid, InterpolationMethod);
            % NOTE: grid_mat and interp2GridVector are the tranposes of the output of meshgrid() generated from createRegGridFromDisplField()
            % They are however, appropriate ndgrid() grids.
        grid_matX = grid_mat(:,:,1);
        grid_matY = grid_mat(:,:,2);

        if useGPU
            grid_mat = gpuArray(grid_mat);
            displVecGridXY = gpuArray(displVecGridXY);
        end
        %-----------------------------------------------------------------------------------------------
        grid_spacingX = grid_mat(1,2,1)- grid_mat(1,1,1);
        grid_spacingY = grid_mat(2,1,2)- grid_mat(1,1,2);        
        imSizeX = (grid_mat(end,end,1) - grid_mat(1,1,1)) + grid_spacingX;
        imSizeY = (grid_mat(end,end,2) - grid_mat(1,1,2)) + grid_spacingY; 
        %----------------------------------------------------------------------------------------------
        if ~exist('width', 'var') || ~exist('height', 'var'), width = []; height = []; end
        if nargin < 14 || isempty(width) || isempty(height)
            width = imSizeX;
            height = imSizeY;
        end
        
        %----------------------------------------------------------------------------------------------
        centerX = ((grid_mat(end,end,1) + grid_mat(1,1,1))/2);
        centerY = ((grid_mat(end,end,2) + grid_mat(1,1,2))/2);
        % [XI,YI] = meshgrid(grid_mat(1,1,1):grid_mat(1,1,1)+imSizeX,grid_mat(1,1,2):grid_mat(1,1,2)+imSizeY);
        Xmin = centerX - width/2 + bandSize;
        Xmax = centerX + width/2 - bandSize;
        Ymin = centerY - height/2 + bandSize;
        Ymax = centerY + height/2 - bandSize;        
    %         [XI,YI] = meshgrid(Xmin:Xmax,Ymin:Ymax);       
        [XI,YI] = ndgrid(Xmin:Xmax,Ymin:Ymax);                % Addded on 2019-10-10 to go with gridded interpolant, the line above is for griddata
        
        %-----------------------------------------------------------------------------------------------            
        % Added by WIM on 2/5/2019
        % All values moving forward are in microns for displacement
        dMap = cell(1,numel(displFieldMicron));
        dMapX = cell(1,numel(displFieldMicron));
        dMapY = cell(1,numel(displFieldMicron));
        displVecGridNorm = (displVecGridXY(:,:,1).^2 + displVecGridXY(:,:,2).^2).^0.5;
        %-----------------------------------------------------------------------------------------------             
        dMap = displVecGridNorm;
        dMapX = displVecGridXY(:,:,1);
        dMapY = displVecGridXY(:,:,2);       
        % -----------------------------------------------------------------------------------------------  
        if useGPU
            grid_mat = gather(grid_mat);
            displVecGridNorm = gather(displVecGridNorm);
            XI = gather(XI);
            YI = gather(YI);
        end
        
        %% Replaced to a griddded interpolant by Waddah Moghram on 2019-10-10 to match interp_vec2grid updated version, to avoid NaNs
        % Replaced to griddata on 2020-01 by WIM to make it C2-continuous
        reg_gridFull(:,:,1)  = XI; reg_gridFull(:,:,2)  = YI;
        [grid_mat_full, displVecGridFullXY,~,~] = interp_vec2grid(displFieldMicron(maxFrame).pos(:,1:2), displFieldMicron(maxFrame).vec(:,1:2) ,[], reg_gridFull, InterpolationMethod);
        displHeatMapX = displVecGridFullXY(:,:,1);
        displHeatMapY = displVecGridFullXY(:,:,2);
        displHeatMap = (displHeatMapX.^2 + displHeatMapY.^2).^0.5;              % Find the norm   

        displHeatMapPadded = zeros(ImageSizePixels);                    % Added on 2019-10-13
        displHeatMapPadded(Xmin:Xmax,Ymin:Ymax) = displHeatMap;                    % Reverse back to MeshGrid format for the heatmap

        %% -----------------------------------------------------------------------------------------------        
        if useGPU
            displFieldMicronPos = gpuArray(displFieldMicron(maxFrame).pos);
            displFieldMicronVec = gpuArray(displFieldMicron(maxFrame).vec);
        else
            displFieldMicronPos = displFieldMicron(maxFrame).pos;
            displFieldMicronVec = displFieldMicron(maxFrame).vec;
        end
        %-----------------------------------------------------------------------------------------------            
        try
            clear IsWithinGrid IsWithinGridSpliced
            IsWithinGridSpliced = zeros(size(grid_mat));
            for ii = 1:size(IsWithinGridSpliced,3)
                IsWithinGridSpliced(1+QuiverPlotEveryNthShift:QuiverPlotEveryNth:end, 1+QuiverPlotEveryNthShift:QuiverPlotEveryNth:end, ii)  = 1;    
            end
        catch
            IsWithinGridSpliced = ones(size(grid_mat));            
            % continue normally
        end
        IsWithin = IsWithinGridSpliced(:,:,1) & IsWithinGridSpliced(:,:,2);

    % -----------------------------------
        figImageHandle = imagesc(figAxesHandle, 'CData', displHeatMapPadded');                % transpose to convert ndgrid to meshgrid for imagesc Cdata
        if strcmpi(ScaleBarChoice, 'Yes')
            scalebarHandle = scalebar(figAxesHandle,'ScaleLength', ScaleLength, 'ScaleLengthRatio', ScaleMicronPerPixel, 'color', ScaleBarColor, ...
                'fontsize', scalebarFontSize, 'unit', ScaleBarUnits, 'location', ScaleBarLocation, 'FontName', 'Helvetica-Narrow', 'linewidth', ScaleWidth);                 % 181 is Unicode for small mu. 
        end
        try
            if strcmpi(TimeStampsChoice, 'Yes')
                CurrentTimeStampsStr = sprintf('\\itt\\rm = %0.3f %s' , TimeStamps(maxFrame), TimeStampsStr);
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
        hold on
        eval(colorMapCommand)
        %-----------------------------------------------------------------------------------------------        
        if ~isempty(displFieldMicron(maxFrame).vec)
            if showQuiver        
                pause(0.1)
                X = reshape(grid_matX(IsWithin),1,[]);
                Y = reshape(grid_matY(IsWithin),1,[]);
                U = reshape(gather(dMapX(IsWithin)),1,[]);
                V = reshape(gather(dMapY(IsWithin)),1,[]);
                set(figAxesHandle, 'CameraPositionMode', 'manual', 'CameraTargetMode', 'manual', 'CameraUpVectorMode', 'manual', 'CameraViewAngleMode','auto')       % Added by WIM on 2019-10-02
                   % autoscale is off to keep arrow lengths have the same scale.
                plotHandle = quiver(figAxesHandle, X,Y,U.*QuiverScaleToMax,V.*QuiverScaleToMax, 0, ...
                       'MarkerSize',MarkerSize, 'markerfacecolor', QuiverColor, 'ShowArrowHead','on', 'MaxHeadSize', 4, ...
                      'color', QuiverColor, 'AutoScale','off', 'LineWidth', QuiverLineWidth , 'AlignVertexCenters', 'on');              
            else
                plotHandle = plot(figAxesHandle, displFieldMicronPos(:,1) + displFieldMicronVec(:,1), displFieldMicronPos(:,2) + displFieldMicronVec(:,2), 'wo', 'MarkerSize',1);  
            end
        else    % no tracked displacement anymore
            return
        end

        ImageHandle = getframe(figHandlePreview);
        Image_cdata = ImageHandle.cdata;
        ColorbarCurrentPosition = colorbarHandle.Position;
        ylabelCurrentPosition = ylabelHandle.Position;      
        
        close(figHandlePreview)
        imshow(Image_cdata)
        figPreview = gcf;

        IsFontOK = questdlg('Are scale bar font size, color bar font sizes & right-side buffer width looking OK?', 'OK?', 'Yes', 'No', 'Yes');
        switch IsFontOK
            case 'Yes'            
                close(figPreview)
                break
            case 'No'
                disp('**___to continue, type "dbcont" or press "F5", or click "Continue" under "Editor" Menu"___**')
                keyboard
        end
        
        prompt = {sprintf('Color bar ticks font size [Currently = %g points]:', colorbarFontSize)};
        dlgTitle = 'color bar ticks font size?';
        colorbarFontSizeStr = {num2str(colorbarFontSize)};
        colorbarFontSizeStr = inputdlg(prompt, dlgTitle, [1 50], colorbarFontSizeStr);
        if isempty(colorbarFontSizeStr), return; end
        colorbarFontSize = str2double(colorbarFontSizeStr{:}); 

        prompt = {sprintf('Color bar label font size [Currently = %g points]:', ylabelFontSize)};
        dlgTitle = 'color bar label font size?';
        ylabelFontSizeStr = {num2str(ylabelFontSize)};
        ylabelFontSizeStr = inputdlg(prompt, dlgTitle, [1 50], ylabelFontSizeStr);
        if isempty(ylabelFontSizeStr), return; end
        ylabelFontSize = str2double(ylabelFontSizeStr{:}); 
        
        prompt = {sprintf('Colorbar width in in pixels [Currently = %g pixels]:', colorbarWidthPixels)};
        dlgTitle = 'color bar width?';
        colorbarWidthPixelsStr = {num2str(colorbarWidthPixels)};
        colorbarWidthPixelsStr = inputdlg(prompt, dlgTitle, [1 60], colorbarWidthPixelsStr);
        if isempty(colorbarWidthPixelsStr), return; end
        colorbarWidthPixels = str2double(colorbarWidthPixelsStr{:}); 
        
        prompt = {sprintf('Right-side buffer width in in pixels [Currently = %g pixels]:', RightSideBuffer)};
        dlgTitle = 'right-side buffer size?';
        RightSideBufferStr = {num2str(RightSideBuffer)};
        RightSideBufferStr = inputdlg(prompt, dlgTitle, [1 60], RightSideBufferStr);
        if isempty(RightSideBufferStr), return; end
        RightSideBuffer = str2double(RightSideBufferStr{:}); 

        close(figPreview)
    end

    if strcmpi(ScaleBarChoice, 'Yes')
        save(InputParamFile, 'scalebarFontSize', '-append')
    end
    try
       save(InputParamFile, 'ylabelFontSize', 'colorbarFontSize', 'RightSideBuffer', 'colorbarWidthPixels', '-append')       
    catch
        % Continue
    end
    if useGPU, Xmin = gather(Xmin); Xmax = gather(Xmax); Ymin = gather(Ymin); Ymax = gather(Ymax); end
    save(InputParamFile, 'ScaleMicronPerPixel', 'Xmin','Xmax','Ymin','Ymax', 'ImageSizePixels', '-append')
    
    %% ======== Plotting Heatmaps Now ============================================================  
    disp('------------------------- Starting generating the plotted image sequence. ---------------------------------------------------')   
    FirstFrameNow = true;
    ScreenSize = get(0, 'Screensize');                       %---------Matlab 2014 and higher
    %-----------------------------------------------------------------------------------------                        
    % account for if displFieldMicron contains more than one frame. Make sure you add "createRegGridFromDisplField.m" in the search path.
    [reg_grid, ~, ~, gridSpacing] = createRegGridFromDisplField(displFieldMicron(maxFrame), gridMagnification, ErodeEdge); %2=2 times fine interpolation

    if isempty(FramesDifference), FramesDifference = 0; end
    
    for CurrentFrame = FramesToBePloted
        if mod(CurrentFrame, FramesAtOnce * FramesDifference(1)) == 0 || FirstFrameNow == true                  % close figHandle every ... samples to prevent memory leak
            try
                clf(figHandle, 'reset')              
                set(figHandle, 'visible',showPlot, ...
                    'color', 'w',...
                    'Toolbar','none', ...
                    'Menubar','none', ...
                    'Units', 'pixels', ...
                    'Resize', 'off',...
                    'Renderer', FigRenderer);    % added by WIM on 2019-09-14. To show, remove                  
            catch
                clear figHandle
               % No figure Exists, continue 
            end
            reverseString = '';
            FirstFrameNow = false;
            if ~exist('figHandle', 'var')            
                figHandle = figure('visible',showPlot, 'color', 'w', 'Toolbar','none', 'Menubar','none', 'Units', 'pixels', 'Resize', 'off', 'Renderer', FigRenderer);     % added by WIM on 2019-09-14. To show, remove 'visible
            end
    %             fprintf('Using WindowAPI.m to resize the window to plot full resolution images with overlays.\n');
    %*** WARNING: THIS CODE IS NOT FUNCTIONAL IF THERE IS A SCALING FACTOR FOR HIGHER DPI plots yet. 
    %**** Make sure that the magnification factor is 100% *** This works only on WINDOWS Operating System.
                    % Downloaded from MATLAB Website. (WindowAPI). Add extra area around the edge, and more extra room for the colorbar. Initial Size
            WindowAPI(figHandle, 'Position', [offSetWindow, (ScreenSize(4) - ImageSizePixels(2) - (offSetWindow + (2* bandSize))), ...
                (colorbarPositionInitial(1) +  ColorbarCurrentPosition(3) + ylabelCurrentPosition(1) + bandSize + RightSideBuffer) , ...
                ImageSizePixels(2) + (2 * bandSize)])   
            figAxesHandle = axes;
            set(figAxesHandle, 'Box', 'on', 'XTick',[], 'YTick', [], 'Visible', 'on', 'YDir', 'reverse');
            set(figAxesHandle, 'Units', 'pixels');
            %-----------------------------------------------------------------------------------------
            hold on        
            eval(colorMapCommand);                  % consider eliminating this line. It might be what is causing the memory leak
            caxis(colorbarLimits);
            colorbarHandle = colorbar('eastoutside');        
            if Remove2ndToTopLabel
                colorbarTickLabels{end - 1} = '';
            end   
            set(colorbarHandle, 'Limits', [colorbarTicks(1), colorbarTicks(end)], 'Ticks', colorbarTicks,'TickLabels', colorbarTickLabels, 'TickDirection', 'out', 'color', 'k',...
                'Fontsize', colorbarFontSize , 'FontWeight', 'bold', 'FontName', 'Helvetica-Narrow', 'LineWidth', QuiverLineWidth, 'Units', 'Pixels');     % font size, 1/100 of height in pixels
           %-----------------------------------------------------------------------------------------        

%             colorbarHandle.FontName = PlotsFontName;
%             colorbarHandle.Label.FontName = PlotsFontName;  
            ylabelHandle = ylabel(colorbarHandle, colorbarLabelString, 'FontSize', ylabelFontSize);        % 'Traction Stress (Pa)'; % in Tex Format
            ylabelHandle.FontSize = ylabelFontSize;
            ylabelHandle.FontName = PlotsFontName;            
            %----------------------------------------------------------------------------------------            
            figAxesHandle.Position = [bandSize, bandSize, ImageSizePixels(1), ImageSizePixels(2)];
            axis equal
            axis off
            ylabelHandle.Units = 'pixels';
            colorbarHandle.Units = 'pixels';
            
            set(colorbarHandle , 'Position', colorbarPositionInitial + [0, round(1* colorbarFontSize), 0, - offset * round(1* colorbarFontSize)]);
            ColorbarCurrentPosition = colorbarHandle.Position;
            ColorbarCurrentPosition(3) = colorbarWidthPixels;
            set(colorbarHandle , 'Position', ColorbarCurrentPosition);
            WindowAPI(figHandle, 'Position', [offSetWindow, (ScreenSize(4) - ImageSizePixels(2) - (offSetWindow + (2* bandSize))), ...
                (ColorbarCurrentPosition(1) +  ColorbarCurrentPosition(3) + ylabelCurrentPosition(1) + bandSize + RightSideBuffer) , ...
                ImageSizePixels(2) + (2 * bandSize)])       
            

            if CurrentFrame == FramesToBePloted(1)
                save(InputParamFile, 'colorbarLimits', 'reg_grid', '-append')
            end
        end
        ProgressMsg = sprintf('\nCreating Frame #%d/%d...\n',CurrentFrame, LastFrame);
        fprintf([reverseString, ProgressMsg]);
        reverseString = repmat(sprintf('\b'), 1, length(ProgressMsg));

        %% -----------------------------------------------------------------------------------------------
        [grid_mat, displVecGridXY,~,~] = interp_vec2grid(displFieldMicron(CurrentFrame).pos(:,1:2), displFieldMicron(CurrentFrame).vec(:,1:2) ,[], reg_grid, InterpolationMethod);
            % NOTE: grid_mat and interp2GridVector are the tranposes of the output of meshgrid() generated from createRegGridFromDisplField()
            % They are however, appropriate ndgrid() grids.
            
        if useGPU
            grid_mat = gpuArray(grid_mat);
            displVecGridXY = gpuArray(displVecGridXY);
        end
        grid_matX = grid_mat(:,:,1);
        grid_matY = grid_mat(:,:,2);

        %-----------------------------------------------------------------------------------------------
        grid_spacingX = grid_mat(1,2,1)- grid_mat(1,1,1);
        grid_spacingY = grid_mat(2,1,2)- grid_mat(1,1,2);        
        imSizeX = (grid_mat(end,end,1) - grid_mat(1,1,1)) + grid_spacingX;
        imSizeY = (grid_mat(end,end,2) - grid_mat(1,1,2)) + grid_spacingY; 
        %----------------------------------------------------------------------------------------------
        if ~exist('width', 'var') || ~exist('height', 'var'), width = []; height = []; end
        if nargin < 14 || isempty(width) || isempty(height)
            width = imSizeX;
            height = imSizeY;
        end
        %----------------------------------------------------------------------------------------------
        centerX = ((grid_mat(end,end,1) + grid_mat(1,1,1))/2);
        centerY = ((grid_mat(end,end,2) + grid_mat(1,1,2))/2);
        % [XI,YI] = meshgrid(grid_mat(1,1,1):grid_mat(1,1,1)+imSizeX,grid_mat(1,1,2):grid_mat(1,1,2)+imSizeY);
        Xmin = centerX - width/2 + bandSize;
        Xmax = centerX + width/2 - bandSize;
        Ymin = centerY - height/2 + bandSize;
        Ymax = centerY + height/2 - bandSize;        
%         [XI,YI] = meshgrid(Xmin:Xmax,Ymin:Ymax);       
        [XI,YI] = ndgrid(Xmin:Xmax,Ymin:Ymax);                % Addded on 2019-10-10 to go with gridded interpolant, the line above is for griddata
        %-----------------------------------------------------------------------------------------------            
        % Added by WIM on 2/5/2019
        % All values moving forward are in microns for displacement
%         dMap = cell(1,numel(displFieldMicron));
%         dMapX = cell(1,numel(displFieldMicron));
%         dMapY = cell(1,numel(displFieldMicron));
        displVecGridNorm = (displVecGridXY(:,:,1).^2 + displVecGridXY(:,:,2).^2).^0.5;
        %-----------------------------------------------------------------------------------------------             
        dMap = displVecGridNorm;
        dMapX = displVecGridXY(:,:,1);
        dMapY = displVecGridXY(:,:,2);       
        % -----------------------------------------------------------------------------------------------  
        if useGPU
            grid_mat = gather(grid_mat);
            displVecGridNorm = gather(displVecGridNorm);
            XI = gather(XI);
            YI = gather(YI);
        end
        
        %% Replaced to a griddded interpolant by Waddah Moghram on 2019-10-10 to match interp_vec2grid updated version, to avoid NaNs
        reg_gridFull(:,:,1)  = XI; reg_gridFull(:,:,2)  = YI;
        [grid_mat_full, displVecGridFullXY,~,~] = interp_vec2grid(displFieldMicron(CurrentFrame).pos(:,1:2), displFieldMicron(CurrentFrame).vec(:,1:2) ,[], reg_gridFull, InterpolationMethod);
        if useGPU
            grid_mat_full = gpuArray(grid_mat_full);
            displVecGridFullXY = gpuArray(displVecGridFullXY);
        end
        displHeatMapX = displVecGridFullXY(:,:,1);
        displHeatMapY = displVecGridFullXY(:,:,2);
        displHeatMap = (displHeatMapX.^2 + displHeatMapY.^2).^0.5;              % Find the norm   
    
        displHeatMapPadded = zeros(ImageSizePixels);                    % Added on 2019-10-13
        if useGPU, displHeatMapPadded = gpuArray(displHeatMapPadded); end
        displHeatMapPadded(Xmin:Xmax,Ymin:Ymax) = displHeatMap;                    % Reverse back to MeshGrid format for the heatmap
        
        %% -----------------------------------------------------------------------------------------------        
        if useGPU
            displFieldMicronPos = gpuArray(displFieldMicron(CurrentFrame).pos);
            displFieldMicronVec = gpuArray(displFieldMicron(CurrentFrame).vec);
        else
            displFieldMicronPos = displFieldMicron(CurrentFrame).pos;
            displFieldMicronVec = displFieldMicron(CurrentFrame).vec;
        end
        %-----------------------------------------------------------------------------------------------            
        try
            clear IsWithinGrid IsWithinGridSpliced
            IsWithinGridSpliced = zeros(size(grid_mat));
            for ii = 1:size(IsWithinGridSpliced,3)
                IsWithinGridSpliced(1+QuiverPlotEveryNthShift:QuiverPlotEveryNth:end, 1+QuiverPlotEveryNthShift:QuiverPlotEveryNth:end, ii)  = 1;    
            end
        catch
            IsWithinGridSpliced = ones(size(grid_mat));            
            % continue normally
        end
        IsWithin = IsWithinGridSpliced(:,:,1) & IsWithinGridSpliced(:,:,2);

    %% -----------------------------------
        figImageHandle = imagesc(figAxesHandle, 'CData', displHeatMapPadded');                % transpose to convert ndgrid to meshgrid
        if strcmpi(ScaleBarChoice, 'Yes')
            scalebarHandle = scalebar(figAxesHandle,'ScaleLength', ScaleLength, 'ScaleLengthRatio', ScaleMicronPerPixel, 'color', ScaleBarColor, ...
                'fontsize', scalebarFontSize, 'unit', ScaleBarUnits, 'location', ScaleBarLocation, 'FontName', 'Helvetica-Narrow', 'linewidth', ScaleWidth);               % in Microns 181 is Unicode for small mu     
        end
        if strcmpi(TimeStampsChoice, 'Yes')
            CurrentTimeStampsStr = sprintf('\\itt\\rm = %0.3f %s' , TimeStamps(CurrentFrame), TimeStampsStr);
            textHandle = text(TimeStampsLocation(1), TimeStampsLocation(2), CurrentTimeStampsStr , 'FontSize', TimeStampsFontSize, 'VerticalAlignment', 'bottom', ...
                'HorizontalAlignment', 'left', 'Color', TimeStampscolor, 'FontName', 'Helvetica-Narrow');
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
        hold on
        hold on
        eval(colorMapCommand)
        %-----------------------------------------------------------------------------------------------        
        if ~isempty(displFieldMicron(CurrentFrame).vec)
            if showQuiver        
                pause(0.1)
                X = reshape(grid_matX(IsWithin),1,[]);
                Y = reshape(grid_matY(IsWithin),1,[]);
                U = reshape(gather(dMapX(IsWithin)),1,[]);
                V = reshape(gather(dMapY(IsWithin)),1,[]);
                set(figAxesHandle, 'CameraPositionMode', 'manual', 'CameraTargetMode', 'manual', 'CameraUpVectorMode', 'manual', 'CameraViewAngleMode','auto')       % Added by WIM on 2019-10-02
                   % autoscale is off to keep arrow lengths have the same scale.
                plotHandle = quiver(figAxesHandle, X,Y,U.*QuiverScaleToMax,V.*QuiverScaleToMax, 0, ...
                       'MarkerSize',MarkerSize, 'markerfacecolor', QuiverColor, 'ShowArrowHead','on', 'MaxHeadSize', 4, ...
                      'color', QuiverColor, 'AutoScale','off', 'LineWidth', QuiverLineWidth , 'AlignVertexCenters', 'on');              
            else
                plotHandle = plot(figAxesHandle, displFieldMicronPos(:,1) + displFieldMicronVec(:,1), displFieldMicronPos(:,2) + displFieldMicronVec(:,2), 'wo', 'MarkerSize',1);  
            end
        else    % no tracked displacement anymore
            return
        end
        pause(0.1);         % pause 0.1 second for the image to be created. If it loops so fast. the heatmap won't be scaled correctly.        
        % -----------------------------------------------------------------------------------------------
        
        try
            ImageFileNames = MD.getImageFileNames;
            channelIndex = 1;          % for now. For later code with mulitiple channels, this will need to be updated. WIM 2019-05-31.
            CurrentImageFullname = fullfile(analysisOutputPath, ImageFileNames{channelIndex}{CurrentFrame}); 
            [~, CurrentImageFileName, ~] =  fileparts(CurrentImageFullname);
        catch
            errordlg('Image File Names for Frames not found. Update code to include calling bfreader() of bioformats.')
            return
        end
        % -----------------------------------------------------------------------------------------------           .
        % convert the image to a frame\
        if ~exist('figHandle', 'var')
            figHandle = figure('visible',showPlot, 'color', 'w', 'Toolbar','none', 'Menubar','none', 'Units', 'pixels', 'Renderer', FigRenderer);     % added by WIM on 2019-02-07. To show, remove 'visible
        end
        ImageHandle = getframe(figHandle);
        Image_cdata = ImageHandle.cdata;
        
        %% -----------------------------------------------------------------------------------------------
        if saveVideo
            % open the video writer
            open(writerObj);            
            % Need some fixing 3/3/2019
            writeVideo(writerObj, Image_cdata);
            if exist(analysisOutputPath,'dir')
                open(writerObjAnalysis);                          
                writeVideo(writerObjAnalysis, Image_cdata);
            end            
        end
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
                CurrentImageFileName = strcat('Displacement Heatmaps_#', FrameNumSuffix(CurrentFrame));
%             end
            for ii = 1:numel(ImageChoice)
                tmpImageChoice =  ImageChoice{ii};
                switch tmpImageChoice
                    case 'TIF'
                        TrackedDisplacementPathTIFname = fullfile(TrackedPathTIF, [CurrentImageFileName , '.tif']);
                        imwrite(Image_cdata, TrackedDisplacementPathTIFname);
                        if exist('AnalysisPath', 'var')
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
                        if exist('AnalysisPath', 'var')
                            if exist(analysisOutputPath,'dir')
                                AnalysisDisplacementPathTIFname = fullfile(AnalysisPathFIG,[CurrentImageFileName, '.fig']);
                                savefig(figHandle, AnalysisDisplacementPathTIFname,'compact')
                            end 
                        end
                        
                    case 'EPS'
                        TrackedDisplacementPathEPSname = fullfile(TrackedPathEPS,[CurrentImageFileName, '.eps']);               
                        print(figHandle, TrackedDisplacementPathEPSname,'-depsc')
%                         exportfig(figHandle, TrackedDisplacementPathEPSname, EPSparams)                
                        if exist('AnalysisPath', 'var')
                            if exist(analysisOutputPath,'dir')
                                AnalysisDisplacementPathEPSname = fullfile(AnalysisPathEPS,[CurrentImageFileName, '.eps']);               
                                print(figHandle, AnalysisDisplacementPathEPSname,'-depsc')   
%                                 exportfig(figHandle, AnalysisDisplacementPathEPSname, EPSparams)
                            end              
                        end
                        
                    case 'MAT data'
                        TrackedDisplacementPathMATname = fullfile(TrackedPathMAT ,[CurrentImageFileName, '.mat']);   
                        curr_dMap = dMap;
                        curr_dMapX = dMapX;
                        curr_dMapY = dMapY;         
                        save(TrackedDisplacementPathMATname,'curr_dMap','curr_dMapX','curr_dMapY','-v7.3');                   % Modified by WIM on 2/5/2019                  
                        if exist('AnalysisPath', 'var')
                            if exist(analysisOutputPath,'dir')
                                AnalysisDisplacementPathMATname = fullfile(AnalysisPathMAT,[CurrentImageFileName, '.mat']);     
                                curr_dMap = dMap;
                                curr_dMapX = dMapX;
                                curr_dMapY = dMapY;         
                                save(AnalysisDisplacementPathMATname,'curr_dMap','curr_dMapX','curr_dMapY','-v7.3');                   % Modified by WIM on 2/5/2019
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
        fprintf('Image(s) are saved as: \n\t%s\n', outputPath)
        if exist(analysisOutputPath, 'dir')
            fprintf('Image(s) are saved as: \n\t%s\n', analysisOutputPath)
        end
    end
    
    
    %% ==================================================================================
%     if ispc     % opening file explorer externally to see those individual files
%         if exist('AnalysisPath', 'var') 
%             try 
%                 winopen(AnalysisPath);
%             catch
%                 warn('could not open the analysis folder directory')
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

    disp('-------------------------- Finished generating plotted tracked displacements heatmaps --------------------------')
end
