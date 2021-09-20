%
%{
    ********************* NEEDS TO BE UPDATED to allow video recording option on 2019-06-03
    Change the output to *.mat file
    Change the output so that it can be saved during the process instead of at the very end.
%}


% 
%{
    v.2019-10-14. 
        1. Fixed errors with nargin, and given the user a choice of the frame.
        
    v9.0 2019-09-02
        1. updated so that all variables in the workspace for this function.
    v8.0 updated from 2019-08-20
        1. Added video movie capability.
        2. output the coordinates as as a *.mat file.

    v7.0:
    ExtractTipCoordinates v7.0 will returns x-, and y-coordinates of the "Needle Pole".
    1. Changed function from ExtractTipCoordinates_v6_0 to ExtractNeedleTipCoordinatesDIC
  It does the same as v4.0 except that it read directly from the ND2 file to save space and time.
    Input and Output are in pixel and in Cartesian Coordiantes  
    NOTE: Needle pole coordinates will be whole pixel units. Compare to Bead coordinates that come from image tracking, that has "subpixel displacements".
    
    Updated on 5/15/2019 to give an option to pass the FullImageFileName and output directory name
    % Written by Waddah Moghram, PhD Candidate in Biomedical Engineering at the University of Iowa on 2/7/2018 and later

% Older Editions
    v4.0
    Updates to this editions include:
    1. Optional input arguments: FinalFrameNumber, FirstFrame, ChosenPoleDistance, Magnification
        Magnification choices are: 4, 10, 20, 30, 40 and 60.
        Include user-prompted input if needed with default values. 
        Use "exist" & "isempty" arguments. Another way is to use "parse" and "inputPraser" for functions
    2. Outputs Bead Node Coordinates and also into a file "Tip_Coordinates.dat"
    3. to flip or not to flip coordinates? Coordinates are not flipped, but remain as cartesian.****
    
    %%TO DO 
    4. Added a part where I can also plot the bead coordinates if they have been extracted already
    5. Added a fixed size rectangle to standardize amongst frames. %2/1/2018
    
    6. Added a save feature to see how images track between frames. 2/1/2018

    v3.0 
    Needle Pole is defined to be initially 5 microns behind the left-most needle tip along the bisector line.
            1/18/2018.
            However, it seems to be equivalent to the radius of curvature of
            the needle tip. Needle #1 has a radius of 7 microns; Needle #2 has
            a radius of 10 microns?? **DOUBLE CHECK VALUES**
        Bisector line bisects the angle subtended by the needle tip and two poins on the needle edge.
        Unlike previous versions, This does no rely on Cross-cross relation, which has proven not to be effective,
        and can halt prematurely 
        Based on TrialScriptOutline5.m

        It will open up p****.tif and zoom in at 30% (since it is a huge image),
        and that way I can control it). Future versions can obtain the value of the resolution
        
    Created by Waddah Moghram, PhD Candindate in Biomedical Engineering at the Unviersity of Iowa, on 12/01/2017.
%}

function [NeedlePoleCoordinatesXYpixels] = ExtractNeedleTipCoordinatesDIC(ND2fullFileName, OutputPathName, FirstFrameNumber, FinalFrameNumber, MagnificationTimes,...
    showPlot, saveVideo, ChosenPoleDistanceMicron)
    commandwindow;
    disp('-------------------------- Running "ExtractNeedleTipCoordinatesDIC.m" to To track tip pole coordinates --------------------------')
%% Hash out the input variables
    %%
    if nargin > 8 
        error('Too many arguments')
    end

    %% 1. Getting the ND2 filename and reading it
    if ~exist('ND2fullFileName','var'), ND2fullFileName = []; end
    if isempty(ND2fullFileName)
        [ND2FileName,ND2PathName,~] = uigetfile('*.nd2','Select the *.ND2 DIC Video');
        ND2fullFileName = fullfile(ND2PathName,ND2FileName);
    end
    % 2. Opening/Loading the entire file with the header. 
    try 
        reader = bfGetReader(ND2fullFileName);
%         reader = bfopen(ND2fullFileName);               % faster than bfGetReader. Updated on 2019-08-23
    catch
        BioformatsPath = uigetdir([], 'Select directory containing bioformats folder (e.g., TFMpackagefolder)');
        addpath(genpath(BioformatsPath));        % include subfolders
        try 
            reader = bfGetReader(ND2fullFileName);
%             reader = bfopen(ND2fullFileName);               % faster than bfGetReader. Updated on 2019-08-23
        catch
            error('Cannot open the file');
        end
    end
    disp('DIC video loaded successfully!');
    disp('----------------------------------------------------------------------------')
    %{
        Otherwise, you can use bfGetReader(); to read the image alone without the metadata
        Faster way to open the image instead of loading the entire file with bfopen()
    %}
    %%
    if ~exist('OutputPathName', 'var'), OutputPathName = []; end
    if nargin < 2 || isempty(OutputPathName)
        tmpOutputPathName = fullfile(ND2PathName, 'tracking_output');
        if ~exist(tmpOutputPathName, 'dir'), mkdir(tmpOutputPathName); end
        OutputPathName = uigetdir(tmpOutputPathName,'Select the data directory where you want to save output. Default is Present Working Directory'); 
        if ~exist('OutputPathName', 'dir'), mkdir OutputPathName; end 
    end   
        
        %% Other parameters to extract
        try
            trackingFileName = fullfile(ND2PathName ,'tracking_output', 'tracking_parameters.txt');
            open(trackingFileName);
        catch
            % Do nothing
        end

    %%
    %Define the first and last frames to be tracked, the chosen offset of the pole from the needle tip. Prompt for how many frames to be tracked
    if ~exist('FirstFrameNumber','var'), FirstFrameNumber = []; end
    if nargin < 3 || isempty(FirstFrameNumber)
        FirstFrameNumber = 1;                                     % Default value for first frame = 1
    end
    %%
    if ~exist('FinalFrameNumber','var'), FinalFrameNumber = []; end
    if nargin < 4 || isempty(FinalFrameNumber)
        FinalFrameNumber = reader.getSizeT;
        prompt = sprintf('Enter the final frame number that you would like to track the tip at: (Last Frame is %d): ', FinalFrameNumber);
        FinalFrameNumber = input(prompt);
%             if isempty(FinalFrameNumber)
%                 error('***No Final Frame Number was entered. Run this function again.***')
%             end
%         end
    end
    %%
    if ~exist('MagnificationTimes', 'var'), MagnificationTimes = []; end
    if nargin < 5 || isempty(MagnificationTimes)   
        % Find out the magnification scale to convert pixels to microns for displacements.
        %************* Possible to fish the scale from the data header (7,3) ********** if is entered correctly before.*******************%%
        MagnificationTimes = [];
    end
    [ScaleMicronPerPixel, MagnificationTimesStr] = MagnificationScalesMicronPerPixel(MagnificationTimes);
    commandwindow;
    fprintf('First Frame to be tracked is #%d.\n', FirstFrameNumber);    
    fprintf('Final Frame to be tracked is #%d.\n', FinalFrameNumber);
    disp('----------------------------------------------------------------------------')
    
    %% -----------------------------------------------------------------------------------------------
    if ~exist('showPlot','var'), showPlot = []; end
    if nargin < 6 || isempty(showPlot)
        dlgQuestion = 'Do you want to show needle displacement in frames as they are made?';
        dlgTitle = 'Show Plots In Progress?';
        showPlotChoice = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No', 'Yes');
    elseif showPlot == 0 || strcmpi(showPlot, 'N') || strcmpi(showPlot, 'No') || strcmpi(showPlot, 'Off')
        showPlotChoice = 'No';
    elseif showPlot == 1 || strcmpi(showPlot, 'Y') || strcmpi(showPlot, 'Yes') || strcmpi(showPlot, 'On')
        showPlotChoice = 'Yes';
    end    
    switch showPlotChoice
        case 'Yes'
            showPlot = 'on';
        case 'No'
            showPlot = 'off';
        otherwise
            return
    end
    
    %% ----------------------------------------------------------------------------------------
    if ~exist('saveVideo','var'), saveVideo = []; end
    if nargin < 7 || isempty(saveVideo)
        TrackedDisplacementPathTIFcount = 0;
        TrackedDisplacementPathFIGcount = 0; 
        TrackedDisplacementPathEPScount = 0;
        TrackedDisplacementPathMATcount = 0;
        
        dlgQuestion = 'Do you want to save as videos or as image sequence?';
        dlgTitle = 'Video vs. Image Sequence?';
        plotTypeChoice = questdlg(dlgQuestion, dlgTitle, 'Videos', 'Images', 'Neither', 'Videos');
    elseif saveVideo == 0 || upper(saveVideo) == 'N'
        plotTypeChoice = 'Images';
    elseif saveVideo == 1 || upper(saveVideo) == 'Y'
        plotTypeChoice = 'Videos';        
    else 
        errordlg('Invalid Plot Type Choice')
        return
    end
    
    switch plotTypeChoice
        case 'Videos'
            saveVideo = true;
            dlgQuestion = 'Select video format.';
            listStr = {'Archival', 'Motion JPEG AVI', 'Motion JPEG 2000','MPEG-4','Uncompressed AVI','Indexed AVI','Grayscale AVI'};
            DisplacementVideoChoice = listdlg('ListString', listStr, 'PromptString',dlgQuestion, 'InitialValue', 2, 'SelectionMode' ,'Single');    
            DisplacementVideoChoice = listStr{DisplacementVideoChoice};
            
            finalSuffix = 'Tip_Tracked';
            videoFile = fullfile(OutputPathName, finalSuffix);        
            writerObj = VideoWriter(videoFile, DisplacementVideoChoice);
            try
                timeStamps = ND2TimeFrameExtract(ND2fullFileName);
                FrameRate = 1/mean(timeStamps(2:end)-timeStamps(1:end-1));
                writerObj.FrameRate = FrameRate;
            catch
                prompt = {sprintf('Choose the Frame Rate per second for this movie. [Default, %.4f]', FrameRate)};
                dlgTitle =  'Frames Per Second';
                FrameRateStr = inputdlg(prompt, dlgTitle, [1, 90], {num2str(FrameRate)});
                if isempty(FrameRateStr), return; end
                FrameRate = str2double(FrameRateStr{1});                                  % Convert to a number      
                writerObj.FrameRate = FrameRate;           % Assume 40 frames per second
            end                     
        case 'Images'
            saveVideo = false;
            dlgQuestion = 'Select image format.';
            listStr = {'TIF', 'FIG', 'EPS','MAT data'};
            ImageChoice = listdlg('ListString', listStr, 'PromptString',dlgQuestion, 'InitialValue', 2, 'SelectionMode' ,'multiple');    
            ImageChoice = listStr(ImageChoice);                 % get the names of the string.   
            if  strcmpi(plotTypeChoice, 'Images')
                for CurrentFrame = 1:numel(ImageChoice)
                    tmpImageChoice =  ImageChoice{CurrentFrame};
                    switch tmpImageChoice
                        case 'TIF'
                            TrackedDisplacementPathTIF = fullfile(OutputPathName, 'NeedleTip_TIF');
                            if ~exist(TrackedDisplacementPathTIF,'dir'), mkdir(TrackedDisplacementPathTIF); end
                            fprintf('Tracked Displacement  Path - TIF is: \n\t %s\n', TrackedDisplacementPathTIF);
                            try
                                TrackedDisplacementPathTIFcount =  numel(dir(fullfile(TrackedDisplacementPathTIF, '*.eps')));
                            catch
                                TrackedDisplacementPathTIFcount = 0;
                            end
                        case 'FIG'
                            TrackedDisplacementPathFIG = fullfile(DisplacementHeatMapPath, 'NeedleTip_FIG');
                            if ~exist(TrackedDisplacementPathFIG,'dir'), mkdir(TrackedDisplacementPathFIG); end
                            fprintf('Tracked Displacement  Path - FIG is: \n\t %s\n', TrackedDisplacementPathFIG);
                            try
                                TrackedDisplacementPathFIGcount =  numel(dir(fullfile(TrackedDisplacementPathFIG, '*.fig')));
                            catch
                                TrackedDisplacementPathFIGcount = 0;
                            end
                        case 'EPS'
                            TrackedDisplacementPathEPS = fullfile(DisplacementHeatMapPath, 'NeedleTip_EPS');
                            if ~exist(TrackedDisplacementPathEPS,'dir'), mkdir(TrackedDisplacementPathEPS); end
                            fprintf('Tracked Displacement  Path - EPS is: \n\t %s\n', TrackedDisplacementPathEPS);
                            try
                                TrackedDisplacementPathEPScount =  numel(dir(fullfile(TrackedDisplacementPathEPS, '*.fig')));                            
                            catch
                                TrackedDisplacementPathEPScount = 0;
                            end
                        case 'MAT data'
                            TrackedDisplacementPathMAT = fullfile(DisplacementHeatMapPath, 'NeedleTip_MAT');  
                            if ~exist(TrackedDisplacementPathMAT,'dir'), mkdir(TrackedDisplacementPathMAT); end
                            fprintf('Tracked Displacement  Path - MAT is: \n\t %s\n', TrackedDisplacementPathMAT);
                            try
                                TrackedDisplacementPathMATcount =  numel(dir(fullfile(TrackedDisplacementPathMAT, '*.mat')));
                            catch
                                TrackedDisplacementPathMATcount = 0;
                            end
                    otherwise
                        return
                    end
                end
            end          
        case 'Neither'
            saveVideo = [];
        otherwise
            return
    end
    
    %%
    %1/18/2018 by WIM to allow choice of Needles #1 and #2 tips
    if ~exist('ChosenPoleDistanceMicron','var'), ChosenPoleDistanceMicron = []; end          % Third parameter does not exist, so ask for prompt or default it
    if isempty(ChosenPoleDistanceMicron)
        prompt = '3. Enter the Pole Distance from the tip in microns \n (~7 microns for HyMu80#1 Needle, and ~ 10 microns for HyMu80#2 Needle). [Default = 0 microns]: ';
        commandwindow;
        ChosenPoleDistanceMicron = input(prompt);
        if isempty(ChosenPoleDistanceMicron)
            ChosenPoleDistanceMicron = 0;                % Distance in microns between tip and pole along with the AD line. Modified to 0 microns on 2/21/2018                
        end
    end
    fprintf('Pole Distance from the tip of the needle is %g microns.\n', ChosenPoleDistanceMicron);
    disp('----------------------------------------------------------------------------')    
    
    %% Load the last image (from current directory) into memory
    FinalFrameImageHandle = bfGetPlane(reader, FinalFrameNumber);            


    
%% Part below is repurposed and modified from TrialScriptOutline5.m
%{ 
    Variable names changed on 1/23/2018 to make the code more readable. and corrected some wrong commentary.
    Previous version Written by Waddah Moghram, PhD Candidate in Biomedical Engineering on Friday 12/1/2017. Update on 1/23/2018
        Identifies boundaries by selecting a box to "crop" the image
        Identify the left-most point, and the needle point around the right-most edge.
        Bisect the angle: theta=arccos((a^2+b^2?c^2)/2ab)...Not needed after all
        See OneNote for equations on how the Needle Pole is located
%}

%% 3. Show & Crop Final Image of the tracked Images
    showPlot = 'on';
    figHandle = figure('visible',showPlot, 'color', 'w', 'Units', 'pixels', 'Resize', 'on');    % added by WIM on 2019-09-14. To show, remove     
    axis image
    figAxesHandle = findobj(figHandle, 'type',  'Axes');    
    WindowAPI_used = false;
    try
        ImageBits = reader.getBitsPerPixel - 2;   % Typically if 16 bits are used. Then image will be saved in 14 bits.
    catch
        ImageBits = 14;
    end
    GrayColorMap =  gray(2^ImageBits);                   % TexasRed ColorMap for Epi Images.       
%     ImageSizePixels =[reader.getSizeX, reader.getSizeY];     
       ImageSizePixels = size(FinalFrameImageHandle);
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

    curr_Image = FinalFrameImageHandle; 
    
    imagesc(figAxesHandle, 1, 1, curr_Image);
    colormap(GrayColorMap);
    set(figAxesHandle, 'Units', 'pixels', 'Position', [1, 1,  ImageSizePixels(1), ImageSizePixels(2)], 'Box', 'off', 'TickLength', [0, 0], 'Visible', 'off');
    hold(figAxesHandle, 'on')
    axis image
 
    % A cropping box to select the edges to identify the boundaries
    % Select 30-40 micron-wide square preferably to encompass all possible needle tip motion.
    disp('5. Now select an area where the needle tip will stay within through all tracked images, and double-click on it to proceed with imcrop.')            % old code with imcrop. 
%     disp('5. Now select an area where the needle tip will stay within through all tracked images, right-click and select on it to proceed with imcrop.')    %New code with imrect. See below 2/1/2018

    % Imported from imrect examples and modified by WIM on 2/1/2018
    rectHandle = imrect(gca, [0, 0, 250, 400]);                             % gca    is get current axis or latest chart. Initial dimensions so far. Changed height from 450 to 400 pixels on 2/21/2018
%     setResizable(RectHandle, false)                                           % Look the dimensions of the rectangle is already known. Otherwise, Allow a custom-entered dimension ahead of time
    addNewPositionCallback(rectHandle,@(p) title(strcat(mat2str(p*ScaleMicronPerPixel,5),' Microns')));                                 % Update position as it goes in a function with p as in put. *ScaleMicronPerPixel to show distance in microns
    ConstraintFunction = makeConstrainToRectFcn('imrect',get(gca,'XLim'),get(gca,'YLim'));                      % Limit to frame size
    setPositionConstraintFcn(rectHandle,ConstraintFunction);                                            % Match the function to the handle

    CroppedRectangle = wait(rectHandle);                                     % Freeze MATLAB command until the figure is double-clicked, then it is resumed. Returns whole pixels instead of fractions

%         CroppedRectangle = getPosition(RectHandle)                        % Returns the position of the rectangle after double-clicking (Alternative Way)
%   % or ...
%     [CroppedImage, CroppedRectangle] = imcrop(FinalFrameImageHandle,RectPosition);                      % RectPosition added on 2/1/2018. Replaced figure(1) with FinalFrameImageHandle. Probably not needed
%     imshow(CroppedImage,[])       
    close(gcf);                                         % Close the figure after double clicking 
    
%% 4. Extracting the coordinates of the cropped rectangle selected
    CroppedRectangle1x = CroppedRectangle(1,1);
    CroppedRectangle1y = CroppedRectangle(1,2);
    CroppedRectangle2x = CroppedRectangle(1,1) + CroppedRectangle(1,3);
    CroppedRectangle2y = CroppedRectangle(1,2) + CroppedRectangle(1,4);    

%% 5. Initialize matrix for Needle Pole Coordiantes to speed up the loops
    NeedlePoleCoordinatesXYpixels = zeros(FinalFrameNumber,2);          
    
%% 6. Thresholding the boundaries of the needle and extracting the coordinates of the boundaries. Looping through all frames
    disp('Tracking Needle Poles through all images...in progress');

    FirstFrame = 0;
    FirstFrameNow = true;
    % NOTE: This works so far, but it takes a very long time since it is in "For Loop Format"
    % Consider upgrading it to a vector array to speed up the process.            
    for CurrentFrame = FirstFrameNumber:FinalFrameNumber
        % Load current image frame
        CurrentImageGray = bfGetPlane(reader, CurrentFrame);     
        
        if mod(CurrentFrame, 30) == 0 || FirstFrameNow == true                  % close figHandle every 30 samples to prevent memory overflow.
            try
                close(figHandle)
            catch
               % No figure Exists, continue 
            end
        
            FirstFrameNow = false;  
            figHandle = figure('visible',showPlot, 'color', 'w', 'Toolbar','none', 'Menubar','none', 'Units', 'pixels', 'Resize', 'off');    % added by WIM on 2019-09-14. To show, remove     
            reverseString = '';   
            axis image
            figAxesHandle = findobj(figHandle, 'type',  'Axes');    

            ImageSizePixels  = size(CurrentImageGray);
            try
                ImageBits = handles.reader.getBitsPerPixel - 2;   % Typically if 16 bits are used. Then image will be saved in 14 bits.
            catch
                ImageBits = 14;
            end
            GrayColorMap =  gray(2^ImageBits);                   % TexasRed ColorMap for Epi Images.       
            try
                %---------Matlab 2014 and higher
                ScreenSize = get(0, 'Screensize');          
                WindowAPI(figHandle, 'Position', [50, (ScreenSize(4) - ImageSizePixels(2) - 50), ImageSizePixels(1), ImageSizePixels(2)])           % Downloaded from MATLAB Website
            catch
                fprintf('Using MATLAB internal functions. Might not work to plot full resolution images with overlays. Check resolution of final output.\n');
                ScreenWorkArea = images.internal.getWorkArea;       
                set(figHandle, 'Position',  [50, -(ImageSizePixels(2) - ScreenWorkArea.top) ,ImageSizePixels(1), ImageSizePixels(2)]);
                matlab.ui.internal.PositionUtils.setDevicePixelPosition(figHandle,  [50, -(ImageSizePixels(2) - ScreenWorkArea.top) ,ImageSizePixels(1), ImageSizePixels(2)]);
    %             matlab.ui.internal.PositionUtils.setDevicePixelPosition(gca, [1, -1, ImageSizePixels(1), ImageSizePixels(2)]);
            end
        end
            
        imagesc(figAxesHandle, 1, 1, CurrentImageGray);
        colormap(GrayColorMap);
        set(figAxesHandle, 'Units', 'pixels', 'Position', [1, 1,  ImageSizePixels(1), ImageSizePixels(2)], 'Box', 'off', 'TickLength', [0, 0], 'Visible', 'off');
        hold(figAxesHandle, 'on')
               
            
        % Threshold current image to a binary image (black and white)
        %Igray = rgb2gray(Irgb);                                %will not work if the image is already in grayscale
        ImageBlackWhite = imbinarize(CurrentImageGray,'global');       %replaced im2bw(Igray,graythresh(Igray)). Better code in newer Matlab editions
        
        % Fill all the beads "holes" which are the magnetic beads in this case. 
        % The tip is not a hole inside the image, and will not be filled as a result
        ImageFilled = imfill(ImageBlackWhite,'holes');                            
        
        % 7. Trace the region boundaries of the binary image
        [BoundaryInfo,~] = bwboundaries(ImageFilled);

        % 8. Extract Coordinates of boundary points as (y,x)
        BoundaryCoordinatesPixel = BoundaryInfo{1};                                       
        BoundaryCoordinatesPixelX = BoundaryCoordinatesPixel(:,2);
        BoundaryCoordinatesPixelY = BoundaryCoordinatesPixel(:,1);

        % Indices of the x- and y-coordinates of the needle tip boundary found within the cropped box
        OutsideCoordinates = logical((BoundaryCoordinatesPixelX < CroppedRectangle1x )| ( BoundaryCoordinatesPixelY < CroppedRectangle1y ) | (BoundaryCoordinatesPixelX > CroppedRectangle2x) |  (BoundaryCoordinatesPixelY > CroppedRectangle2y ));
        InsideCoordinates = ~OutsideCoordinates;

        % Flipping row to display it
        BoundaryCoordinatesPixelFlipped = fliplr(BoundaryCoordinatesPixel);
        BoundaryCoordinatesPixelFlippedInside = BoundaryCoordinatesPixelFlipped(InsideCoordinates,:);
   
        %hold on;
        %plot(BoundaryCoordaintesFlippedInside(:,1), BoundaryCoordaintesFlippedInside(:,2),'g', 'LineWidth', 2);
        
        % 9. Finding the left-most point; minimum x-coordinates, or Point A.
        % Typical experimental setup is with the needle protroding from the right of the screen
        [~,IndexMinX] = min(BoundaryCoordinatesPixelFlippedInside(:,1));
        TipPointPixel = BoundaryCoordinatesPixelFlippedInside(IndexMinX,:);

        % 10. Finding the top-most point along needle edge; maximum Y-coordinates, or Point B
        [~,IndexMaxY] = max(BoundaryCoordinatesPixelFlippedInside(:,2));
        EdgeTopPointPixel = BoundaryCoordinatesPixelFlippedInside(IndexMaxY,:);

        % 11. Finding the bottom-most point along needle edge. maximum Y-coordinates, Point C
        [~,IndexMinY] = min(BoundaryCoordinatesPixelFlippedInside(:,2));
        EdgeBottomPointPixel = BoundaryCoordinatesPixelFlippedInside(IndexMinY,:);

        %====================================
        % 12. Evaluating the midpoint between points B & C, or Point D
        MidPointPixel = (1/2) * (EdgeTopPointPixel + EdgeBottomPointPixel);
        %     plot(MidPoint(1), MidPoint(2), 'ro','LineWidth', 3) 
    
        % 13. Evaluating the slope of line AD
        diffPixel = MidPointPixel - TipPointPixel;
        Slope = (diffPixel(2) / diffPixel(1));

        % 14. Offset of the 'needle pole' behind the tip along the bisector line
        
        % ScaleMicronPerPixel in micron/pixel. Take the reciprocal for Chosen Pole Distance given in micron.                    
        PoleDistancePixel = ChosenPoleDistanceMicron * 1/ScaleMicronPerPixel;    
        
        NeedlePoleXPixel = TipPointPixel(1) + sqrt(PoleDistancePixel^2 /(Slope^2 + 1));
        NeedlePoleYPixel = TipPointPixel(2) + Slope * sqrt(PoleDistancePixel^2 /(Slope^2 + 1));
        
        %Append the coordinates of the NeedlePole 
        NeedlePoleCoordinatesXYpixels(CurrentFrame,1) = NeedlePoleXPixel;
        NeedlePoleCoordinatesXYpixels(CurrentFrame,2) = NeedlePoleYPixel;

        % 15. Plot the necessary points/lines if needed.
        
            % Save to present working directly for now

        
            % 15.a Plotting the image with Poins A, B & C (Tip Point, Top Edge Point, and Bottom Edge Point)
        if ~exist('figHandle', 'var')
            figHandle = figure('visible',showPlot, 'color', 'w', 'Toolbar','none', 'Menubar','none', 'Units', 'pixels', 'Resize', 'off');    % added by WIM on 2019-09-14. To show, remove     
            reverseString = '';   
            axis image
            figAxesHandle = findobj(figHandle, 'type',  'Axes');    
        end   
            
        imagesc(figAxesHandle, 1, 1, CurrentImageGray);
        colormap(GrayColorMap);
        set(figAxesHandle, 'Units', 'pixels', 'Position', [1, 1,  ImageSizePixels(1), ImageSizePixels(2)], 'Box', 'off', 'TickLength', [0, 0], 'Visible', 'off');
        hold(figAxesHandle, 'on')
                
%         CurrentImageGray = imshow(bfGetPlane(reader, CurrentFrame),[]);                      %Added 2/7/2018
        hold on

        %Plotting the points on the needle that are of interest
            plot(TipPointPixel(1), TipPointPixel(2), 'ro','LineWidth', 1, 'MarkerSize', 3)                 %right-most point of needle tip.

            if ChosenPoleDistanceMicron > 0 
                plot(EdgeTopPointPixel(1), EdgeTopPointPixel(2), 'r.','LineWidth', 2, 'MarkerSize', 12)         %right-most point of needle tip.
                plot(EdgeBottomPointPixel(1), EdgeBottomPointPixel(2), 'r.','LineWidth', 1, 'MarkerSize',  12)   %right-most point of needle tip.
            %====================================
            %Plotting two line edges of the triangle.
                plot([EdgeTopPointPixel(1), TipPointPixel(1)] , [EdgeTopPointPixel(2), TipPointPixel(2)], 'r-', 'LineWidth', 1);     %plot a line between these two points.
                plot([EdgeBottomPointPixel(1), TipPointPixel(1)] , [EdgeBottomPointPixel(2), TipPointPixel(2)], 'r-', 'LineWidth', 1);     %plot a line between these two points.

%         ====================================
%                     %NOTE: **** Alternative method is by bisecting the angle ****
%                     %Evaluating the angle extended by the needle sides.
%                     %using Norm of the Difference to calculate the distance
%                     %this is just calculated as a check later to see the varibility in angle
%                     AB = norm(TipPoint - EdgeTopPoint);
%                     AC = norm(TipPoint - EdgeBottomPoint);
%                     BC = norm(EdgeTopPoint - EdgeBottomPoint);
%                     thetaRad = acos((AB^2 + AC^2 - BC^2) / (2* AB * AC));            %Angle in radians
%                     thetaDeg = radtodeg(thetaRad);
                % 15.b Plotting the bisector
                %plot a line between these two points.
                plot([MidPointPixel(1), TipPointPixel(1)] , [MidPointPixel(2), TipPointPixel(2)], 'r-', 'LineWidth', 1);     
                %Plotting the "Needle Pole"
                plot(NeedlePoleXPixel, NeedlePoleYPixel, 'o','LineWidth', 1) 
            end
            hold off
            %pause        %Pause to see how it will repeat between loops
            %pause(0.01)
            
        % 15.c Saving the current frame to see that it is correct. Added on 2/1/2018
            ImageHandle = getframe(figHandle);
            Image_cdata = ImageHandle.cdata;        
            if saveVideo
                % open the video writer
                open(writerObj);            
                % Need some fixing 3/3/2019
                writeVideo(writerObj, Image_cdata);
            else            % Saving images
                CurrentTipImageName = sprintf('TipP%04d.tif', CurrentFrame);             %  TipP****.tiff will be the subsequent frames 
                CurrentTipImageFullName = fullfile(OutputPathName,CurrentTipImageName);      
                
                % Anonymous function to append the file number to the file type. 
                if ~exist('CurrentImageFileName','var')
                    fString = ['%0' num2str(floor(log10(FinalFrameNumber))+1) '.f'];
                    FrameNumSuffix = @(frame) num2str(frame,fString);
                    CurrentImageFileName = strcat('TipP', FrameNumSuffix(CurrentFrame));
                end
                for CurrentFrame = 1:numel(ImageChoice)
                    tmpImageChoice =  ImageChoice{CurrentFrame};
                    switch tmpImageChoice
                        case 'TIF'
                            TrackedDisplacementPathTIFname = fullfile(TrackedDisplacementPathTIF, [CurrentImageFileName , '.tif']);
                            imwrite(Image_cdata, TrackedDisplacementPathTIFname);
                        case 'FIG'
                            TrackedDisplacementPathFIGname = fullfile(TrackedDisplacementPathFIG,[CurrentImageFileName, '.fig']);
                            hgsave(figHandle, TrackedDisplacementPathFIGname,'-v7.3')
                        case 'EPS'
                            TrackedDisplacementPathEPSname = fullfile(TrackedDisplacementPathEPS,[CurrentImageFileName, '.eps']);               
                            print(figHandle, TrackedDisplacementPathEPSname,'-depsc')   
                        case 'MAT data'
                            TrackedDisplacementPathMATname = fullfile(TrackedDisplacementPathMAT ,[CurrentImageFileName, '.mat']);   
                            curr_dMap = dMap{CurrentFrame};
                            curr_dMapX = dMapX{CurrentFrame};
                            curr_dMapY = dMapY{CurrentFrame};         
                            save(TrackedDisplacementPathMATname,'curr_dMap','curr_dMapX','curr_dMapY','-v7.3');                   % Modified by WIM on 2/5/2019                        
                        otherwise
                             return   
                    end
                end                
%                 imwrite(CurrentTipImageData, CurrentTipImageFullName, 'tif');           % Writign the output image
            end
                               
    end     % End of for loop

    disp('Tracking Needle Poles through all images COMPLETE!');
    
    %% 13. Flipping the y-coordinates into Cartesian Coordinates from Image coordinates to be consistent with all the other output files.
    NeedlePoleCoordinatesXYpixels(:,2) = - NeedlePoleCoordinatesXYpixels(:,2);
    
    %Added on 2/4/2018 by WIM to remove all zeros if First Elements is not Frame Number 1
    NeedlePoleCoordinatesXYpixels(1:FirstFrameNumber-1,:) = [];
    
    %% 14. Writing to 'Tip_Coordinates.dat' and to the accompnaying file 'Tip_Coordinates_Info.dat
    
    TipCoordinatesFullFileName = fullfile(OutputPathName, 'Tip_Coordinates.dat');
    dlmwrite(TipCoordinatesFullFileName,NeedlePoleCoordinatesXYpixels,'delimiter','\t','precision','%7.3f');
    
    TipCoordinatesFullFileName = fullfile(OutputPathName, 'Tip_Coordinates.mat');
%     save(TipCoordinatesFullFileName,'NeedlePoleCoordinatesXYpixels' , 'FirstFrameNumber', 'FinalFrameNumber', 'MagnificationTimesStr','ScaleMicronPerPixel'   ,'-v7.3');
    save(TipCoordinatesFullFileName);

    TipInfoFullFileName  = fullfile(OutputPathName, 'Tip_Coordinates_Info.txt');
    fid = fopen(TipInfoFullFileName, 'wt');
    fprintf(fid, 'Frames tracked were from #%u to #%u \n', FirstFrameNumber, FinalFrameNumber);  
    fprintf(fid, '%s\t%s\t -coordinates are the 1st and 2nd columns, respectively (pixels)\n', 'x','y');  
    fprintf(fid, 'The needle pole offset from the tip is %5.3f microns \n', ChosenPoleDistanceMicron);
    fprintf(fid, 'The magnification used was %s and its scale factor is %8.7f micron/pixel \n', MagnificationTimesStr, ScaleMicronPerPixel);
    fprintf(fid, '(%7.3f,%7.3f) and (%7.3f,%7.3f) pixels are the coordinates of the top-left and bottom-right corners of the cropped box \n', CroppedRectangle1x, CroppedRectangle1y, CroppedRectangle2x, CroppedRectangle2y) ;  % Accompany file
    fclose(fid);
    try
        close(writerObj)
    catch
       % Do nothing 
    end
    
    fprintf('Tip Coordinates File is saved in: \n %s \n' , TipCoordinatesFullFileName);
    fprintf('Tip Coordinates Info File is saved in: \n %s \n' , TipInfoFullFileName);    
    disp('-------------------------- Extracting Tip Coordinates COMPLETE --------------------------')