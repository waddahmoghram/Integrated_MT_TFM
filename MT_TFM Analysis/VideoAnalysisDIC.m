%{
    v.2021-08-01 by Waddah Moghram
        1. Code modified for AIM 3 analysis 
    v.2020-08-22 by Waddah Moghram
        1. Pass to DC file all the other properties from the non-DC file
    v.2020-05-26 by Waddah Moghram
        1. Fixed glitch with CornerPercentageDefault
    v.2020-03-04 by Waddah Moghram
        1. Added a section to calculate work applied by the MT over a whole frame
    v.2020-02-10 by Waddah Moghram
        1. updated to use RT time stamps for controlled-force experiments.
            * Verified with controlled force and controlled displacement
    v.2020-02-01 by Waddah Moghram
        1. Updated screen shot to fit the image by the same exact size (true size)
    v.2020-01-22 by Waddah Moghram
        1. Needle initial relative position is brought into CalculateForceMT(). Inlination angle is not needed anymore.
    v.2020-01-16..19 by Waddah Moghram
        1. Updated to allow flexbility to choose the first and last frame for this.
    *** Includes Drift Correction for DIC
    v.2020-01-08 by Waddah Moghram
        1. Fixed calling the dimensions of the grid. Added an option to go directly to displField instead of previously tracked traction file.
    v.2020-01-06 by Waddah Moghram
        1. Made corrections to drift corrections based on pixels first before converting to microns.
    v.2020-01-01 by Waddah Moghrma
        1. Added a step for drift correction for DIC mode step
    v.2019-10-12 by Waddah Moghram
        1. Fixed OutputPathNameDIC for extract bead coordinates already compiled?
    v.2019-10-06 by Waddah Moghram
        1. Moved displacement mode to the for front.
        2. Do not read sensor data if this is not controlled force.
    v.2019-09-21...22
        1. Changed the timestamps for Big Delta to time stamps from the ND2file instead of the time stamps from the sensor data.
        2. If SensorData time stamps are no working, use ND2 timestamps embedded in the metadata.
    v.2019-09-17 by Waddah Moghram
        1. ...
    v.2019-09-09
        Written by Waddah Moghram on 2019-09-09
        1. Streamline this software code 
    Comprehensive Code to Analyze the results for DIC
        v1.0
        Written by Waddah Moghram on 2019-05-15>29
%}

%% TO DO Maybe
% **** Check out how OutputPathName under 'tracking_output" can change if the directory structure is changed after running file_cleanup.m

%************** TO DO ******* 2.2 Make sure to convert the video to *.avi (compressed JPEG 2000) so that I can show it.
    %{
        You can do it FIJI
    %}
    % use GPU acceleration if that is an option.
    nGPU = gpuDeviceCount;
    if nGPU > 0
        useGPU = true;
    else
        useGPU = false;
    end  

    % Initial Parameters. Make sure you track previously.
    choiceTrackDIC ='Yes';
    GelType = 'Type I Collagen';
    IdenticalCornersChoice = 'Yes';             % choose 4 identical corners.
    DCchoice = 'Yes';
    PlotsFontName = 'XITS';
    RendererMode = 'painters';
    TrackingReadyDIC = false;
    CornerPercentageDefault = 0.10;             % added on 2020-05-26 by WIM. Consider updating to allow the user to change it.
    MagX = 30;
    AnalysisPathChoice = 'No';    
    BeadNodeID = 1;
    AnalysisPath = [];
        
    TrackingMethodList = {'imfindcircles()', 'imgregtform()'};
%     TrackingMethodListChoiceIndex = listdlg('ListString', TrackingMethodList, 'SelectionMode', 'single', 'InitialValue', 1, ...
%         'PromptString', 'Choose the tracking Algorith:', 'ListSize', [200, 100]);
    TrackingMethodListChoiceIndex = 2;                      % going with imregtform() as our standard
%     if isempty(TrackingMethodListChoiceIndex), TrackingMethodListChoiceIndex = 1; end
    TrackingMethod = TrackingMethodList{TrackingMethodListChoiceIndex}; 
    controlMode =  'Controlled Force';
    choiceOpenND2DIC = 'Yes';
    SmallerROIChoice = 'Yes';    
    DIC_ROI_Microns_PerSide = 5;            % 5 microns on each side. Assuming that is the maximum DIC displacement   
    DCchoiceStr = 'Drift Corrected';
    FrameDisplMeanChoice = 'No';
    RendererMode = 'painters';
    
    
%% ================= 1.0 Tracking DIC Add the particle tracking folder to the path if it is not already "... Image Bead Tracking DIC Analysis" =======================
    commandwindow;
    disp('-------------------------- Running "VideoAnalysisDIC.m" to generate analysis DIC related plots --------------------------')

%% ================= 3.0 Select the DIC image file that has the tracking output to do the analysis & choose the analysis path =======================    

    switch choiceOpenND2DIC    
        case 'Yes'
            disp('Opening the DIC ND2 Video File to get path and filename info to be analyzed')
            [ND2fileDIC, ND2pathDIC] = uigetfile('*.nd2', 'DIC ND2 video file');    
            if ND2fileDIC==0
                error('No file was selected');
            end
            
            ND2fullFileNameDIC = fullfile(ND2pathDIC, ND2fileDIC);   
            [ND2PathNameDIC, ND2FileNameDIC, ~] = fileparts(ND2fullFileNameDIC);
            
            ND2FileNamePartsDIC = split(ND2FileNameDIC, '-');
            AnalysisSuffixDIC = join(ND2FileNamePartsDIC(end-2:end), '-');
            AnalysisSuffixDIC = AnalysisSuffixDIC{:};
            AnalysisFolderStrDIC = strcat('Analysis_', AnalysisSuffixDIC);
            OutputPathNameDIC = fullfile(ND2pathDIC, '..', AnalysisFolderStrDIC);
            
            fprintf('DIC ND2 Video File to be analyzed is: \n %s \n', OutputPathNameDIC);
            disp('----------------------------------------------------------------------------')  
            
            try
                mkdir(OutputPathNameDIC)
            catch
                
            end
        case 'No'
            if ~exist('OutputPathNameDIC', 'var')
                OutputPathNameDIC = pwd;
            end
            % keep going
        otherwise
            error('Could not open *.nd2 file');
    end
 
%% ================= 4.0 Read Sensor Data & Clean it up.    
    switch controlMode    
        case 'Controlled Force'
              PlotSensorDataChoiceStr = 'Yes';
            
            if isempty(PlotSensorDataChoiceStr), return; end
            switch PlotSensorDataChoiceStr
                case 'Yes'
                    PlotSensorData = 1;
                case 'No'
                    PlotSensorData = 0;
                otherwise
                    PlotSensorData = 0;
            end
            
            SensorDataDICFileName = fullfile(ND2PathNameDIC, strcat(ND2FileNameDIC, '.dat'));
            SensorOutputPath_DIC = fullfile(OutputPathNameDIC, 'Sensor_Signals');
            try
                mkdir(SensorOutputPath_DIC)
            catch
                
            end
            [SensorDataDIC, HeaderDataDIC, HeaderTitleDIC, SensorDataFullFilenameDIC, SensorOutputPathNameDIC, ~, SamplingRate, SensorDataColumns]  = ReadSensorDataFile(SensorDataDICFileName, PlotSensorData, SensorOutputPath_DIC, AnalysisPath, 8, 'No');   
            close all
            [CleanSensorDataDIC , ExposurePulseCountDIC, EveryNthFrameDIC, CleanedSensorDataFullFileName_DIC, HeaderData, HeaderTitle, FirstExposurePulseIndexDIC] = CleanSensorDataFile(SensorDataDIC, 1, SensorDataFullFilenameDIC, SamplingRate, HeaderDataDIC, HeaderTitleDIC, SensorDataColumns);
            %{
                Do not forget to reduce the frames of the cleaned sensor data to match the reduce frame number in the accompanying video 
            %}
    end
%%

%% Create a Movie Data File for DIC Image for easier access to images and metadata
    MT_OutputPath = fullfile(OutputPathNameDIC, 'MT_Output');
    MD_DIC = bfImport(ND2fullFileNameDIC, 'outputDirectory', MT_OutputPath, 'askUser', 0);

    MD_DIC.numAperture_ = NumAperture;
    [SensorDataDICPathName, SensorDataDICFileName, ~] = fileparts(SensorDataDICFileName);
    SensorDataDICNotesFileName = fullfile(SensorDataDICPathName, strcat(SensorDataDICFileName, '_Notes.txt'));
    NotesDIC = fileread(SensorDataDICNotesFileName);
    NotesWordsDIC = split(NotesDIC, ' ');             % split by white space

    MD_DIC.notes_ = NotesDIC;
    MD_DIC.magnification_ = MagnificationTimes;
    MD_DIC.timeInterval_ = AverageTimeIntervalND2;
    MD_DIC.channels_.emissionWavelength_;                   % 
    MD_DIC.channels_.excitationWavelength_ = 560;           % nm for texas red;
    MD_DIC.channels_.excitationType_ = 'Widefield';         % Widefield Fluorescence.
    MD_DIC.channels_.exposureTime_ = AverageTimeIntervalND2; % in seconds
    MD_DIC.channels_.fluorophore_ = 'TexasRed';

%     AcquisitionDateDICStr = split(NotesWordsDIC{6}, '/');
%     AcquisitionTimeStr = split(NotesWordsDIC{8}, ':');
%     MonthNameDIC = month(datetime(1, str2num(AcquisitionDateDICStr{1}),1), 'name');
%     MonthNameDIC = MonthNameDIC{1};
%     
%     AcquisitionDateDIC = [MonthNameDIC, ' ', AcquisitionDateDICStr{2}, ', ' AcquisitionDateDICStr{3}]; 
%     MD_DIC.acquisitionDate_ = NotesWordsDIC{6};

%% ================= 5.0  Create timestamps from the sensor data file instead of through that in the video metadata.
    [TimeStampsRT_Abs_DIC] = TimestampRTfromSensorData(CleanSensorDataDIC, SamplingRate, HeaderData, HeaderTitle, CleanedSensorDataFullFileName_DIC, FirstExposurePulseIndexDIC);
    [TimeStampsND2_DIC, LastFrameND2_DIC] = ND2TimeFrameExtract(ND2fullFileNameDIC);

%% ================= 6.0 Get the magnification scale to convert pixels to microns.
    [ScaleMicronPerPixel, MagnificationTimesStr, MagnificationTimes, NumAperture] = MagnificationScalesMicronPerPixel(MagX);
%     ScaleMicronPerPixel = MD_DIC.pixelSize_ / 1000;           % nm to um
    
%% ================= 7.0 Track the magnetic bead
    MagBeadOutputPath = fullfile(MT_OutputPath, 'Mag_Bead_Tracking');
    try
        mkdir(MagBeadOutputPath)
    catch
        % continue
    end
    FrameCount = MD_DIC.nFrames_;
    FramesDoneNumbers = 1:FrameCount;
    VeryFirstFrame = FramesDoneNumbers(1);   
    VeryLastFrame =  FramesDoneNumbers(end);           
    FirstFrame = VeryFirstFrame;
    LastFrame =  VeryLastFrame; 

	ImageBits = MD_DIC.camBitdepth_ - 2;   
    GrayColorMap =  gray(2^ImageBits);             % grayscale image for DIC image.    

    BeadDiameterMicron = HeaderDataDIC(5,3);
    BeadRadius = (BeadDiameterMicron/2) / ScaleMicronPerPixel;
    BeadRadiusRange = BeadRadius *  [0.5, 1.5];
    BeadRadiusRange(1) = max(6, floor(BeadRadiusRange(1)));
    BeadRadiusRange(2) = ceil(BeadRadiusRange(2)) + 1;
      
    largerROIPositionPixels = [0,0];
    
    RefFrameNum = 1;
    RefFrameDIC = MD_DIC.channels_.loadImage(RefFrameNum);
    
    if useGPU, RefFrameDIC = gpuArray(RefFrameDIC); end
    RefFrameDICAdjust = imadjust(RefFrameDIC, stretchlim(RefFrameDIC,[0, 1]));  
    
    switch TrackingMethod
        case 'imfindcircles()'                 %% Quicker, but noisier.
            commandwindow;
            figHandle = figure('color', 'w');
            figAxesHandle = gca;
            colormap(GrayColorMap);
            imagesc(figAxesHandle, 1, 1, RefFrameDICAdjust);
            hold on
            set(figAxesHandle, 'FontWeight', 'bold','LineWidth',1, 'XMinorTick', 'on', 'YMinorTick', 'on', 'TickDir', 'out', 'Box', 'on')    
            xlabel('X (pixels)'), ylabel('Y (pixels)')
            axis image

            switch SmallerROIChoice
                case 'Yes'
%                     prompt = {'ROI Width (pixels)', 'ROI Heigh (pixels)', 'Top-Left Corner X-Coordinates (pixels)', 'Top-Left Corner Y-Coordinates (pixels)'};
%                     dlgTitle = sprintf('ROI Dimensions : Total Size = [%g, %g] pixels', size(RefFrameDICAdjust, 2), size(RefFrameDICAdjust, 1));
%                     dims = [1 70];
%                     defInput = {'256', '256', '1', '1'};
%                     opts.Interpreter = 'tex';
%                     SmallerROIinitialSize = inputdlg(prompt, dlgTitle, dims, defInput, opts);
%                     DIC_ROI_Rect_Dim = [str2double(SmallerROIinitialSize{3,:}), str2double(SmallerROIinitialSize{4,:}), str2double(SmallerROIinitialSize{1,:}) - 1, str2double(SmallerROIinitialSize{2,:}) - 1];   % one pixel less at end, 1:255 = 256 pixels.
                    imSize = size(RefFrameDICAdjust);
%                     close(figHandle)  
%                     title({'Draw a rectangle to select an ROI.', 'Zoom and adjust as needed to select a tight box'})
%                     BeadROIrectHandle = imrect(figAxesHandle, DIC_ROI_Rect_Dim);              % Can also be a needle tip
%                     addNewPositionCallback(BeadROIrectHandle,@(p) title({strcat('ROI Position [X,Y,W,H]=', char(32), mat2str(p,3), char(32), 'pixels'), 'Double-Click on Last ROI when finished with adjusting all ROIs'})); 
%                     ConstraintFunction = makeConstrainToRectFcn('imrect',get(figAxesHandle,'XLim'),get(figAxesHandle,'YLim'));
%                     setPositionConstraintFcn(BeadROIrectHandle,ConstraintFunction);
%                     CroppedRectangle = wait(BeadROIrectHandle);                                     % Freeze MATLAB command until the figure is double-clicked, then it is resumed. Returns whole pixels instead of fractions
%                     CroppedRectangle = (round(CroppedRectangle));
%                     close(figHandle)    
%                     [BeadROI_DIC, BeadROI_rect] = imcrop(RefFrameImageAdjust, CroppedRectangle);
%                     pause(2)
                    SideLengths =  2 * [1, 1] * round((DIC_ROI_Microns_PerSide / ScaleMicronPerPixel));
                    CroppedRectangle = [(imSize / 2) - round((DIC_ROI_Microns_PerSide / ScaleMicronPerPixel)), SideLengths];
                    close(figHandle)
                    [BeadROI_DIC, BeadROI_rect] = imcrop(RefFrameDICAdjust, CroppedRectangle);
                    
%                 case 'No'
%                     BeadROI = RefFrameImageAdjust;
%                     BeadROIrect = [1,1, size(BeadROI, 2), size(BeadROI, 1)];        % width is columns, and height is rows.
            end
                     
            figMagBeadROI = imshow(BeadROI_DIC, 'InitialMagnification', 400);
            figure(figMagBeadROI.Parent.Parent)
            [centers, BeadRadius, metric] = imfindcircles(BeadROI_DIC, BeadRadiusRange, 'ObjectPolarity' ,'dark', 'Method', 'TwoStage', 'EdgeThreshold', 0.7, 'Sensitivity', 0.95);   %'Sensitivity', 0.8
            hold on
            viscircles(centers, BeadRadius, 'EdgeColor','b');
            plot(centers(:,1),centers(:,2), 'b.')           % does not work when the needle is attached, or maube the lighting?
%             BeadROIcenterPixels = ginput(1);
            BeadROIcenterPixels = centers;
            [ClosestBeadDist, BeadNodeID] = min(vecnorm(BeadROIcenterPixels - centers, 2, 2));
            close(figMagBeadROI.Parent.Parent)
%             BeadROIcenterPixels = [0, 0];         % in this case, the Bead center is the center, not the corner of the ROI
%             
            clear BeadPositionXYCornerPixels         
            clear BeadRadius 
            BeadRadius = nan(size(FramesDoneNumbers))';
            BeadPositionXYCornerPixels  = nan(numel(FramesDoneNumbers), 2);
            reverseString = ''; 
%             
            figMagBeadTracked = figure('color', 'w');
            figMagBeadTrackedAxes = gca;
            axis image
            
            for CurrentDIC_Frame = FramesDoneNumbers
                ProgressMsg = sprintf('\nTracking Frame %d/%d\n', CurrentDIC_Frame, FramesDoneNumbers(end));
                fprintf([reverseString, ProgressMsg]);
                reverseString = repmat(sprintf('\b'), 1, length(ProgressMsg));
                CurrentDIC_FrameFullImage = MD_DIC.channels_.loadImage(CurrentDIC_Frame);
                
                if useGPU, CurrentDIC_FrameFullImage = gpuArray(CurrentDIC_FrameFullImage); end
                CurrentDIC_FrameImageFullAdjust = imadjust(CurrentDIC_FrameFullImage, stretchlim(RefFrameDIC,[0, 1]));   
                CurrentDIC_FrameImage = imcrop(CurrentDIC_FrameImageFullAdjust, BeadROI_rect);
                [CurrentCenters, CurrentRadii, metric] = imfindcircles(CurrentDIC_FrameImage, BeadRadiusRange, 'ObjectPolarity' ,'dark', 'Method', 'TwoStage', 'EdgeThreshold', 0.4, 'Sensitivity', 0.8);   % lowered edge from threshold from 0.8 & sensitivity from 0.95 on 2021-06-27
                BeadRadius(CurrentDIC_Frame, :) = CurrentRadii(BeadNodeID);
                BeadPositionXYCornerPixels(CurrentDIC_Frame,1:2) = CurrentCenters(BeadNodeID, :);
                
                CurrentDIC_FrameImageAdj = imadjust(CurrentDIC_FrameImage, stretchlim(CurrentDIC_FrameImage,[0, 1]));
                colormap(GrayColorMap);
                imagesc(figMagBeadTrackedAxes, 1, 1, CurrentDIC_FrameImageAdj);
                axis image
                
                hold on
                b = viscircles(CurrentCenters(BeadNodeID, :), CurrentRadii(BeadNodeID, :), 'EdgeColor','r','LineWidth', 1,    'EnhanceVisibility', false);
                plot(CurrentCenters(BeadNodeID, 1), CurrentCenters(BeadNodeID, 2), 'r.', 'MarkerSize', 4)
            end
            close all

        case 'imgregtform()'                            %% Slower, but more accurate.
            TrackingModeList = {'multimodal','monomodal'};
%             TrackingModeListChoiceIndex = listdlg('ListString', TrackingModeList, 'SelectionMode', 'single', 'InitialValue', 1, ...
%                 'PromptString', 'Choose the tracking mode:', 'ListSize', [200, 100]); 
%             if isempty(TrackingModeListChoiceIndex), TrackingModeListChoiceIndex = 1; end
            TrackingModeListChoiceIndex = 2;                       
            TrackingMode = TrackingModeList{TrackingModeListChoiceIndex}; 

            [optimizer, metric] = imregconfig(TrackingMode);

            TransformationTypeList = {'translation', 'rigid', 'similarity', 'affine'};
%             TransformationTypeListChoiceIndex = listdlg('listString', TransformationTypeList, 'SelectionMode', 'single', 'InitialValue', 1, ...
%                'PromptString', 'Choose Displacement Mode:', 'ListSize', [200, 100]);
%             if isempty(TransformationTypeListChoiceIndex), TransformationTypeListChoiceIndex = 1; end
            TrackingModeListChoiceIndex = 1;
            TransformationType = TransformationTypeList{TrackingModeListChoiceIndex};

            switch TrackingMode
                case 'monomodal'
                    switch TransformationType
                        case 'translation'
                            optimizer.MinimumStepLength = 1e-7;
                            optimizer.MaximumStepLength = 3.125e-5;
                            optimizer.MaximumIterations = 10000;    
                    end
            end

            RefFrameNum = 1;
%             RefFrameDIC = bfGetPlane(DICcontent, RefFrameNum);
        %     RefFrameImage =  DICmovieData.channels_.loadImage(1);
            RefFrameDIC = MD_DIC.channels_.loadImage(RefFrameNum);
            if useGPU, RefFrameDIC = gpuArray(RefFrameDIC); end
            RefFrameDICAdjust = imadjust(RefFrameDIC, stretchlim(RefFrameDIC,[0, 1]));

            figHandle = figure('color', 'w');
            figAxesHandle = gca;
            colormap(GrayColorMap);
            imagesc(figAxesHandle, 1, 1, RefFrameDICAdjust);
            hold on
            set(figAxesHandle, 'FontWeight', 'bold','LineWidth',1, 'XMinorTick', 'on', 'YMinorTick', 'on', 'TickDir', 'out', 'Box', 'on')    
            xlabel('X (pixels)'), ylabel('Y (pixels)')
            axis image
%             title({'Draw a rectangle to select an ROI.', 'Zoom and adjust as needed to select a tight box'})
%             BeadROIrectHandle = imrect(figAxesHandle);              % Can also be a needle tip
%             addNewPositionCallback(BeadROIrectHandle,@(p) title({strcat('ROI Position [X,Y,W,H]=', char(32), mat2str(p,3), char(32), 'pixels'), 'Double-Click on Last ROI when finished with adjusting all ROIs'})); 
%             ConstraintFunction = makeConstrainToRectFcn('imrect',get(figAxesHandle,'XLim'),get(figAxesHandle,'YLim'));
%             setPositionConstraintFcn(BeadROIrectHandle,ConstraintFunction);
%             CroppedRectangle = wait(BeadROIrectHandle);                                     % Freeze MATLAB command until the figure is double-clicked, then it is resumed. Returns whole pixels instead of fractions
            imSize = size(RefFrameDICAdjust);
            close(figHandle)    
            SideLengths =  2 * [1, 1] * round((5 / ScaleMicronPerPixel));
            CroppedRectangle = [(imSize / 2) - round((5 / ScaleMicronPerPixel)), SideLengths];
            [BeadROI_DIC, BeadROI_rect] = imcrop(RefFrameDICAdjust, CroppedRectangle);

%             pause(2)
%             fig2 = imshow(BeadROI, 'InitialMagnification', 400);
%             figure(fig2.Parent.Parent)
%             BeadROIcenterPixels = ginput(1);
%             close(fig2.Parent.Parent)
            BeadROIcenterPixels = SideLengths / 2;

            clear BeadPositionXYCornerPixels 
%             refImg = imref2d(size(BeadROI_DIC));

            BeadPositionXYCornerPixels = nan(numel(FramesDoneNumbers), 2);

            for CurrentDIC_Frame = FramesDoneNumbers
                fprintf('Tracking Frame %d/%d.\n', CurrentDIC_Frame, FramesDoneNumbers(end))
                CurrentDIC_FrameFullImage = MD_EPI.channels_.loadImage(CurrentDIC_Frame);
                CurrentDIC_FrameImageFullAdjust = imadjust(CurrentDIC_FrameFullImage, stretchlim(CurrentDIC_FrameFullImage, [0, 1]));
                CurrentFrameImageROI = imcrop(CurrentDIC_FrameImageFullAdjust, CroppedRectangle);
                tFormMatrix = imregtform(gather(CurrentDIC_FrameImageFullAdjust), gather(BeadROI_DIC),TransformationType, optimizer, metric);
        %         tFormMatrix = imregcorr(gather(CurrentFrameImageROI), gather(BeadROI),TransformationType);
                BeadTrackedPosition(CurrentDIC_Frame, :) = 
                switch TransformationType
                    case 'translation'
                        BeadPositionXYCornerPixels(CurrentDIC_Frame,1:2) =;
                    case 'rigid'

                end
            end            
        otherwise
            return
    end    
    % Tracking  
    BeadPositionXYcenter = BeadPositionXYCornerPixels + BeadROIcenterPixels + (BeadROI_rect(1:2) - [1,1]) + largerROIPositionPixels; 
    % say (20,20) top-left of ROI = (1,1), Therefore, (2,2) in ROI = (20,20) + (2,2) - (1,1) = (21,21) in Bigger Position for imcrop()    
    MagBeadCoordinatesXYpixels = BeadPositionXYcenter .* [1, -1];           % Convert the y-coordinates to Cartesian to match previous output.    
    MagBeadCoordinatesXYNetpixels = BeadPositionXYcenter - BeadPositionXYcenter(1,:);       

    % Convert to Cartesian Units from Image units to match previous code  (y-coordinates is negative pointing downwards instead)    
    MagBeadCoordinatesXYNetpixels(:,3) = vecnorm(MagBeadCoordinatesXYNetpixels, 2, 2);
    BeadPositionXYdisplMicron = MagBeadCoordinatesXYNetpixels * ScaleMicronPerPixel;    
    
    if useGPU
        BeadROI_DIC = gather(BeadROI_DIC);
        RefFrameDIC = gather(RefFrameDIC);
        RefFrameDICAdjust = gather(RefFrameDICAdjust);
    end

    if useGPU, BeadROI_DIC = gather(BeadROI_DIC); end

    [BeadMaxNetDisplMicron, BeadMaxNetDisplFrame]  = max(BeadPositionXYdisplMicron(:,3));

    MagBeadTrackedDisplacementsFullFileName = fullfile(MagBeadOutputPath, 'MagBeadTrackedDisplacements.mat');
    save(MagBeadTrackedDisplacementsFullFileName, 'MagBeadCoordinatesXYpixels', 'MagBeadCoordinatesXYNetpixels', 'BeadNodeID', 'BeadROI', 'BeadROIrect', ...
        'TrackingMethod', 'BeadPositionXYcenter', 'BeadPositionXYdisplMicron', 'FramesDoneNumbers', 'TimeStampsRT_Abs_DIC',...
        'RefFrameNum', 'MagnificationTimesStr', 'ScaleMicronPerPixel', 'largerROIPositionPixels', '-v7.3')

    switch TrackingMethod
        case 'imfindcircles()'
            save(MagBeadTrackedDisplacementsFullFileName,'BeadRadius', '-append')
        case 'imgregtform()'
            save(MagBeadTrackedDisplacementsFullFileName, 'optimizer', 'metric', '-append');
    end

    % Plotting
    showPlot = 'on';
    figHandle = figure('visible',showPlot, 'color', 'w');     % added by WIM on 2019-02-07. To show, remove 'visible 
    plot(TimeStampsRT_Abs_DIC(FramesDoneNumbers), BeadPositionXYdisplMicron(FramesDoneNumbers,3), 'b-', 'LineWidth', 1)
    xlim([0, TimeStampsRT_Abs_DIC(LastFrame,1)]);               % Adjust the end limit.
    set(findobj(gcf,'type', 'axes'), ...
        'FontSize',12, ...
        'FontName', 'Helvetica', ...
        'LineWidth',1, ...
        'XMinorTick', 'on', ...
        'YMinorTick', 'on', ...
        'TickDir', 'out', ...
        'TitleFontSizeMultiplier', 0.9, ...
        'TitleFontWeight', 'bold', ...
        'TickLength', [0.015, 0.030]);     % Make axes bold            
    xlabelHandle = xlabel('\rmReal Time [s]');
    set(xlabelHandle, 'FontName', PlotsFontName);
    ylabelHandle = ylabel('\bf|\it\Delta\rm_{MT}\rm(\itt\rm)\bf|\rm [\mum]');
    set(ylabelHandle, 'FontName', PlotsFontName);    
    titleTrackStr = sprintf('Tracking Method: %s | Maximum Displacement = %0.3f %sm', TrackingMethod, BeadMaxNetDisplMicron, char(181));
    title({titleTrackStr, ...
        'Magnetic bead net displacements from starting position'}, 'FontWeight', 'bold')

    MagBeadPlotFullFileNameFig = fullfile(MagBeadOutputPath, 'MagBeadDisplacementsPlusMax.fig');
    MagBeadPlotFullFileNamePNG = fullfile(MagBeadOutputPath, 'MagBeadDisplacementsPlusMax.png');    
    savefig(figHandle, MagBeadPlotFullFileNameFig, 'compact')
    saveas(figHandle, MagBeadPlotFullFileNamePNG, 'png')

    close all
    
    
%% =======================================================================================================================================+    
    
    
    
    
    
    
    
    
    
    
    
    
    

%% ================= 7.0 Correct displacements 
%_____________  Tracking the Drift Velocity in the DIC Video       
    DIC_DriftROIs(1).pos = [];
    DIC_DriftROIs(1).posMean = [];
    DIC_DriftROIs(1).vec = [];
    DIC_DriftROIs(1).vecMean = [];
    clear indata
    indata(1).Index = [];
    cornerCount = 4;
    clear DriftROI_rect rectHandle rectCorners xx yy nxx corner_noise CurrentFramePosGrid
    if useGPU, RefFrameDICAdjust = gpuArray(RefFrameDICAdjust); end    
    
    figHandle = figure('color', 'w', 'Renderer', RendererMode, 'Units', 'pixels');
    figAxesHandle = gca;
    colormap(GrayColorMap);
    imagesc(figAxesHandle, 1, 1, RefFrameDICAdjust);
    hold on
    set(figAxesHandle, 'Box', 'on', 'XTick', [], 'YTick', [])
%                         set(figAxesHandle, 'FontWeight', 'bold','LineWidth',1, 'XMinorTick', 'on', 'YMinorTick', 'on', 'TickDir', 'out', 'Box', 'on')    
%                         xlabel('X [pixels]'), ylabel('Y [pixels]')
    axis image
    truesize(figHandle)

    switch IdenticalCornersChoice
        case 'Yes'
            cornerLengthPix_X = round(CornerPercentage * (gridXmax - gridXmin));
            cornerLengthPix_Y = round(CornerPercentage * (gridYmax - gridYmin));
            % Top Left Corner: ROI 1:
            DriftROI_rect(1,:) = [gridXmin, gridYmin, cornerLengthPix_X, cornerLengthPix_Y];
            DriftROI_rect(2,:) = [gridXmin, gridYmax - cornerLengthPix_Y, cornerLengthPix_X, cornerLengthPix_Y];
            DriftROI_rect(3,:) = [gridXmax - cornerLengthPix_X, gridYmin, cornerLengthPix_X, cornerLengthPix_Y];
            DriftROI_rect(4,:) = [gridXmax - cornerLengthPix_X, gridYmax - cornerLengthPix_Y, cornerLengthPix_X, cornerLengthPix_Y];
            for jj = 1:cornerCount
                RefFrameDIC_RectHandle(jj) = drawrectangle(figAxesHandle,'Position', DriftROI_rect(jj, :), 'Color', 'g',  'FaceAlpha', 0);   
                RefFrameDIC_RectImage{jj} = imcrop(RefFrameDICAdjust,  DriftROI_rect(jj, :));
                X{jj} = RefFrameDIC_RectHandle(jj).Position(1) + (0:RefFrameDIC_RectHandle(jj).Position(3));
                Y{jj} = RefFrameDIC_RectHandle(jj).Position(2) + (0:RefFrameDIC_RectHandle(jj).Position(4));
                [CurrentFramePosGrid{jj}(:,:,1),CurrentFramePosGrid{jj}(:,:,2)] = meshgrid(X{jj},  Y{jj});                  % Intrinsic image coordinates
                DIC_DriftROIs(jj).pos = CurrentFramePosGrid{jj};
                DIC_DriftROIs(jj).posMean = DriftROI_rect(jj, 1:2) + DriftROI_rect(jj,3:4)./2;                % find the centers of the ROIs to match the position to. Might not be necessary
            end
            pause(0.1)              % pause to allow it to draw the rectangles.
            title(figAxesHandle, sprintf('%0.2g%% %d Corners ROIs', CornerPercentageDefault * 100, cornerCount));
        otherwise
        return;
    end
    MagBeadDriftROIsFullFileNameFig = fullfile(MagBeadOutputPath, 'DriftCorrectionCornerROIs.fig');
    MagBeadDriftROIsFullFileNamePNG = fullfile(MagBeadOutputPath, 'DriftCorrectionCornerROIs.png');    
    savefig(figHandle, MagBeadDriftROIsFullFileNameFig, 'compact')
    saveas(figHandle, MagBeadDriftROIsFullFileNamePNG, 'png')
    close all
    
    for CurrentFrame = FramesDoneNumbers
        if ShowOutput
            disp('=================================================================');
            fprintf('Drift Correct Frame %d/%d. \n', CurrentFrame, VeryLastFrame);
        end                   
        CurrentFrameImage = MD_DIC.channels_.loadImage(CurrentFrame);
        if useGPU, CurrentFrameImage = gpuArray(CurrentFrameImage); end
        CurrentFrameImageAdjust = imadjust(CurrentFrameImage, stretchlim(CurrentFrameImage,[0, 1]));

        for jj = 1:cornerCount
            CurrentFrameRectImage{jj} = imcrop(CurrentFrameImageAdjust,  DriftROI_rect(jj, :)); 
            tFormMatrix = imregtform(gather(RefFrameDIC_RectImage{jj}), gather(CurrentFrameRectImage{jj}), TransformationType, optimizer, metric);  
            meanDIC_DriftROIs(jj,1:2) = tFormMatrix.T(3, 1:2);
            meanDIC_DriftROIs(jj,3) = vecnorm(meanDIC_DriftROIs(jj,1:2), 2, 2);        % displacement             
        end
        meanDriftFrame = mean(meanDIC_DriftROIs);
        meanDriftFrame(1,3) = vecnorm(meanDriftFrame, 2, 2);
        if useGPU, meanDriftFrame = gather(meanDriftFrame); end
        fprintf('\tD_x = %g pix, \t\t D_y = %g pix, \t\t D_net = %g pix.\n', meanDriftFrame); 
        DIC_DriftROIsMeanAllFrames(CurrentFrame, :) = meanDriftFrame;                    
    end    

    
%% ===================== Updating coordinates to account for drift-         
    % Converting pixels to microns, and converting from 2D to 3D
    if sign(MagBeadCoordinatesXYpixels(1,2)) == -1              % y-coordiantes are in cartesian coordinates instead of image coordinates.
        MagBeadCoordinatesXYpixels(:,2) = - MagBeadCoordinatesXYpixels(:,2);            % consider saving the values as positive in the DIC tracking code. ~WIM 2020-01-06
    end
    MagBeadCoordinatesXYpixelsCorrected = MagBeadCoordinatesXYpixels(FramesDoneNumbers,1:2) - DIC_DriftROIsMeanAllFrames(FramesDoneNumbers,1:2);

    % MagBeadCoordinatesMicronXY has relative positions with the bead's initial position
    MagBeadCoordinatesMicronXY = MagBeadCoordinatesXYpixels .* ScaleMicronPerPixel;  
    MagBeadCoordinatesMicronXYcorrected = MagBeadCoordinatesXYpixelsCorrected .* ScaleMicronPerPixel;

    MagBeadCoordinatesMicronXYintial = MagBeadCoordinatesMicronXY(1,:);            
    MagBeadCoordinatesMicronXYintialCorrected = MagBeadCoordinatesMicronXYcorrected(1,:);    

    MagBeadDisplacementMicronXY = MagBeadCoordinatesMicronXY - MagBeadCoordinatesMicronXYintial;
    MagBeadDisplacementMicronXYcorrected = MagBeadCoordinatesMicronXYcorrected - MagBeadCoordinatesMicronXYintialCorrected;            

    MagBeadDisplacementMicronXYBigDelta = vecnorm(MagBeadDisplacementMicronXY(FramesDoneNumbers,1:2),2,2);
    MagBeadDisplacementMicronXYBigDeltaCorrected = vecnorm(MagBeadDisplacementMicronXYcorrected(FramesDoneNumbers,1:2),2,2);            

    % CONVERTING Into 3D for later
    MagBeadCoordinatesMicronXYZ = horzcat(MagBeadCoordinatesMicronXY, zeros(size(MagBeadCoordinatesMicronXY,1),1));
    MagBeadCoordinatesMicronXYZcorrected = horzcat(MagBeadCoordinatesMicronXYcorrected, zeros(size(MagBeadCoordinatesMicronXYcorrected,1),1));

    MagBeadCoordinatesMicronXYZintial = MagBeadCoordinatesMicronXYZ(1,:);
    MagBeadCoordinatesMicronXYZintialCorrected = MagBeadCoordinatesMicronXYZcorrected(1,:);

    MagBeadDisplacementMicronXYZ = MagBeadCoordinatesMicronXYZ - MagBeadCoordinatesMicronXYZintial;
    MagBeadDisplacementMicronXYZcorrected = MagBeadCoordinatesMicronXYZcorrected - MagBeadCoordinatesMicronXYZintialCorrected;

    MagBeadDisplacementMicronXYZBigDelta = vecnorm(MagBeadDisplacementMicronXYZ,2,2);
    MagBeadDisplacementMicronXYZBigDeltaCorrected = vecnorm(MagBeadDisplacementMicronXYZcorrected,2,2);            

% ================= 
    % Finding out what the last frame count is 
    LastFrame = min([numel(TimeStampsRT_Abs_DIC), numel(MagBeadDisplacementMicronXYZBigDeltaCorrected), VeryLastFrame]);       


    %% ================= 
    try
        thickness_um_Default =  HeaderDataDIC(7,1); 
    catch
        thickness_um_Default = 700;             % 700 microns
    end

    thickness_um = thickness_um_Default;
    fprintf('Gel thickness is %d microns. \n', thickness_um);    
            
%     GelConcentrationMgMl_Default = 1;           % 1 mg/mL
%     prompt = sprintf('What is the gel concentration of the gel in (mg/mL)? [Default = %d mg/mL]: ', GelConcentrationMgMl_Default); 
%     GelConcentrationMgMl = input(prompt);
%     if isempty(GelConcentrationMgMl)
%         GelConcentrationMgMl = GelConcentrationMgMl_Default;
%     end
%     if isempty(GelConcentrationMgMl)
%         GelConcentrationMgMlStr = 'N/A';
%         GelConcentrationMgMl = NaN;
%     else
%         GelConcentrationMgMlStr = sprintf('%.1f', GelConcentrationMgMl);
%     end
    ND2FilePrefix = split(ND2FileNamePartsDIC{1}, '_');
    GelConcentrationMgMlStr = ND2FilePrefix{2};
    GelConcentrationMgMl = str2num(GelConcentrationMgMlStr(1));
    fprintf('%s gel concentration chosen is %.1f mg/mL. \n', GelType, GelConcentrationMgMl);
    try
        save(MagBeadTrackedDisplacementsFullFileName, 'GelConcentrationMgMl', 'thickness_um','GelType', '-append')
    catch
        % continue
    end
    
    %%
    MT_Force_OutputPath = fullfile(MT_OutputPath, 'MT_Force_Work');
    try
        mkdir(MT_Force_OutputPath)
    catch
        % continue
    end   
    MT_ForceFullFileName = fullfile(MT_Force_OutputPath, 'MT_Force_Work.mat');
    try 
        save(MT_ForceFullFileName, 'GelConcentrationMgMl', 'thickness_um','GelType', '-v7.3');         
    catch
        % Do nothing
    end 
    
    %% ================= 
            % Plotting Bead Displacement Micron vs. Pixel
            titleStr2 = sprintf('%.0f %sm-thick, %.1f mg/mL %s', thickness_um, char(181), GelConcentrationMgMl, GelType);
            titleStr = {titleStr2, titleTrackStr};            
            showPlot = 'on';            
            figHandle = figure('visible',showPlot, 'color','w');     % added by WIM on 2019-02-07. To show, remove 'visible
            plot(TimeStampsRT_Abs_DIC(FirstFrame:LastFrame), MagBeadDisplacementMicronXYBigDelta(FirstFrame:LastFrame), 'b-', 'LineWidth',1)
            hold on
            plot(TimeStampsRT_Abs_DIC(FirstFrame:LastFrame), MagBeadDisplacementMicronXYBigDeltaCorrected(FirstFrame:LastFrame), 'r-', 'LineWidth',1)
            xlim([0, TimeStampsRT_Abs_DIC(LastFrame,1)]);               % Adjust the end limit.
            set(findobj(gcf,'type', 'axes'), ...
                'FontSize',12, ...
                'FontName', 'Helvetica', ...
                'LineWidth',1, ...
                'XMinorTick', 'on', ...
                'YMinorTick', 'on', ...
                'TickDir', 'out', ...
                'TitleFontSizeMultiplier', 0.9, ...
                'TitleFontWeight', 'bold', ...
                'Box', 'off');     % Make axes bold
            title(titleStr)
            xlabel('\rmtime [s]', 'FontName', PlotsFontName)
            ylabel('\bf\it\Delta\rm_{MT}(\itt\rm)\bf\rm [\mum]', 'FontName', PlotsFontName);
            legend('Drift not corrected', 'Drift corrected')
            set(findobj(gcf,'type', 'legend'), ...
                'FontSize', 8, ...
                'FontName', 'Helvetica', ...
                'FontWeight', 'normal', ...
                'Location', 'Best')           
            ImageHandle1 = getframe(figHandle);
            Image_cdata1 = ImageHandle1.cdata;

            BigDeltaFileName = 'MagBeadNetDisplacements';
       
            BigDeltaFileNameFIG = fullfile(MagBeadOutputPath, sprintf('%s.fig', BigDeltaFileName));
            BigDeltaFileNamePNG = fullfile(MagBeadOutputPath, sprintf('%s.png', BigDeltaFileName));
%             BigDeltaFileNameMAT = fullfile(MagBeadOutputPath, sprintf('%s.mat', BigDeltaFileName));
            
            savefig(figHandle, BigDeltaFileNameFIG, 'compact')
            saveas(figHandle, BigDeltaFileNamePNG, 'png')
        
            save(MagBeadTrackedDisplacementsFullFileName, 'MagBeadCoordinatesMicronXY', 'MagBeadCoordinatesMicronXYcorrected', 'MagBeadDisplacementMicronXYBigDelta', ...
                'MagBeadCoordinatesXYpixels', 'MagBeadCoordinatesXYpixelsCorrected', 'MagBeadDisplacementMicronXYBigDeltaCorrected', ...
                'MagBeadCoordinatesMicronXYZ', 'MagBeadCoordinatesMicronXYZcorrected', 'DIC_DriftROIsMeanAllFrames', '-append');          
            save(MagBeadTrackedDisplacementsFullFileName, 'TimeStampsRT_Abs_DIC', '-append') 
            save(MagBeadTrackedDisplacementsFullFileName, 'DriftROI_rect', 'TrackingMode', 'metric', 'optimizer', '-append')
    
            
            fprintf('Net Displacement Big, Delta_{MT}(time) plots and *.mat files are stored in: \n\t %s \n' , MagBeadOutputPath);

    %% Now switch the "corrected values" with regular ones so that they can be used directly in subsequent iterations.      
    % ---- Save Drift-Corrected DIC Displacement in the same format as the input to be used for further analysis
    %--------- chose a name to save the Mag Bead Name
    MagBeadCoordinatesXYpixels = MagBeadCoordinatesXYpixelsCorrected;
    MagBeadDisplacementMicronXYBigDelta = MagBeadDisplacementMicronXYZBigDeltaCorrected;
    MagBeadCoordinatesMicronXY = MagBeadCoordinatesMicronXYcorrected .* [1, -1]; % Flip Cartesian Coordinates            
    if exist('MagBeadTrackedDisplacementsFullFileName', 'var')
        [FileP,FileN,~] = fileparts(MagBeadTrackedDisplacementsFullFileName); 
        MagBeadTrackedDisplacementsFullFileNameCorrected = fullfile(FileP, strcat(FileN, '_DC.mat'));
    else
        MagBeadTrackedDisplacementsFullFileNameCorrected = fullfile(MagBeadOutputPath, 'Mag_Bead_Coordinates_DC.mat');
    end
    save(MagBeadTrackedDisplacementsFullFileNameCorrected , 'MagBeadDisplacementMicronXYBigDelta', 'MagBeadCoordinatesMicronXY', 'MagBeadCoordinatesXYpixels', '-v7.3')
    

%% ================= 9.0 Extract the needle tip coordinates 
    NeedleTipRelativeCoordinatesXYZmicrons = [0,0,0]; 
   
%% ================= 10.0 The part below was taken from ForceMTvTime()
    switch controlMode
        case 'Controlled Force'
            %________ Inclination angle is not necessary anymore, but the part below is kept to prevent errors.
            commandwindow;
            try
                InclinationAngleDegrees = HeaderDataDIC(5,2);
            catch
                InclinationAngleDegrees = input('What is the needle inclination angle (in degrees)? ');
            end
            fprintf('Inclination Angle of the needle is %.0f%s. \n', InclinationAngleDegrees, char(0x00B0));
            %________
            
            %{
                Update 2020-01-22
                    3. Input:  InlincationAngleDegree is not used, but I will not mess with it for now due to a major rewrite everywhere. 
                    4. Input: TipRelativeCoordinatesMicronXYZ is also not needed. It can be calculated from the header and the initial coordinates of the bead.
            %}
            MagBeadCoordinatesMicronXYZ = MagBeadDisplacementMicronXYZ;
            NeedleTipRelativeCoordinatesXYZmicrons = [0,0,0];
            [Force_xyz, Force_xy, WorkBeadJ_Half_Cycle, WorkCycleFirstFrame, WorkCycleLastFrame] = CalculateForceMT(MagBeadCoordinatesMicronXYZ, NeedleTipRelativeCoordinatesXYZmicrons, ScaleMicronPerPixel, ...
                InclinationAngleDegrees, FirstFrame, LastFrame, TimeStampsRT_Abs_DIC, CleanSensorDataDIC, SensorDataFullFilenameDIC, ...
                MT_Force_OutputPath, AnalysisPath, ND2FileNameDIC, HeaderDataDIC, thickness_um, GelConcentrationMgMl, GelType);
    end
    
    cloes all
    
    