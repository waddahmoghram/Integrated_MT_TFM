%{
        +++++++++++++++++++ AIM 3: ANALYSIS CODE *******************
    v.2021-08-02 Written by Waddah Moghram on 2019-09-09
        1. Combined VideoanalysisDIC.m, VideoAnalysisEPI.m

%}    
format longg
%% _______________________________ Predetermined Variables DIC 
    % Initial Parameters. Make sure you track previously.
    choiceTrackDIC ='Yes';
    GelType = {'Corning Type I rat-tail collagen.', 'Stock concentration: ~3.0 mg/mL',  'Cat: CB40236. Stock .  LOT: ____.'};
   
    IdenticalCornersChoice = 'Yes';             % choose 4 identical corners.
    DCchoice = 'Yes';
    PlotsFontName = 'XITS';
    RendererMode = 'painters';
    TrackingReadyDIC = false;
    CornerPercentageDefault = 0.10;             % added on 2020-05-26 by WIM. Consider updating to allow the user to change it.
    MagX = 30;                        % 20X object * 1.5 eyepiece zoom 
    AnalysisPathChoice = 'No';    
    BeadNodeID = 1;
    AnalysisPath = [];
        
    TrackingMethodList = {'imfindcircles()', 'imgregtform()'};
%     TrackingMethodListChoiceIndex = listdlg('ListString', TrackingMethodList, 'SelectionMode', 'single', 'InitialValue', 1, ...
%         'PromptString', 'Choose the tracking Algorith:', 'ListSize', [200, 100]);
    TrackingMethodListChoiceIndex = 1;                      % going with imregtform() as our standard
%     if isempty(TrackingMethodListChoiceIndex), TrackingMethodListChoiceIndex = 1; end
    TrackingMethod = TrackingMethodList{TrackingMethodListChoiceIndex}; 
    controlMode =  'Controlled Force';
    choiceOpenND2DIC = 'Yes';
    SmallerROIChoice = 'Yes';    
    DIC_ROI_Microns_PerSide = 5;            % 5 microns on each side. Assuming that is the maximum DIC displacement   
    DCchoiceStr = 'Drift Corrected';
    FrameDisplMeanChoice = 'No';
 
    RendererMode = 'painters';
    
    YoungModulusOptimizedCycle = 2;     % seconds cycle
    YoungModulusOptimizedTimeSec = 0.5;  % 1/2 second near the end

% _______________________________ EPI Predetermined Variables
    EdgeErode = 1;                                      % do not change to 0. Update 2020-01-29
    gridMagnification = 1;
    ForceIntegrationMethod = 'Summed';
    TractionStressMethod = 'FTTC';   
    GridtypeChoiceStr = 'Even Grid';

    PoissonRatio = 0.4;                 % Assumed based on other papers
    
    reg_cornerChoiceStr = 'Optimized Bayesian L2 (BL2)'; 
    InterpolationMethod = 'griddata';                   % vs. InterpolationMethod = 'scatteredinterpolant';
        
    HanWindowChoice = 'Yes';
    PaddingChoiceStr= 'Padded with zeros only';
    
    ShowOutput = true;
    SpatialFilterChoiceStr = 'Wiener 2D';    
    WienerWindowSize = [3, 3];         % 3x3 pixels
    CornerPercentage = 0.1;
    AnalysisPathEPI = [];
    TransientRegParamMethod = 'ON for Transients';
    SaveOutput = true;  

%% _______________________________ Use GPU if it is present
    nGPU = gpuDeviceCount;
    if nGPU > 0
        useGPU = true;
    else
        useGPU = false;
    end
    
%% =============================== 1.0 Tracking DIC Add the particle tracking folder to the path if it is not already "... Image Bead Tracking DIC Analysis" =======================
    commandwindow;
    disp('-------------------------- Running "VideoAnalysisDIC.m" to generate analysis DIC related plots --------------------------')

%% =============================== 2.0 Get the magnification scale to convert pixels to microns.
    [ScaleMicronPerPixel, MagnificationTimesStr, MagnificationTimes, NumAperture] = MagnificationScalesMicronPerPixel(MagX);
%     ScaleMicronPerPixel = MD_DIC.pixelSize_ / 1000;           % nm to um

%% Add bioformats path programmatically
try
     BioformatsPath = '.\bioformats';    % relative path of project
     addpath(genpath(BioformatsPath));        % include subfolders
catch
    BioformatsPath = uigetdir(pwd, 'Select the Bioformats folder');
    addpath(genpath(BioformatsPath));        % include subfolders
end
%% =============================== 3.0 Select the DIC image file that has the tracking output to do the analysis & choose the analysis path =======================    
    switch choiceOpenND2DIC    
        case 'Yes'
            disp('Opening the DIC ND2 Video File to get path and filename info to be analyzed')
            [ND2fileDIC, ND2pathDIC] = uigetfile('*.nd2', 'DIC ND2 video file');    
            if ND2fileDIC==0
                error('No file was selected');
            end
            
            ND2fullFileNameDIC = fullfile(ND2pathDIC, ND2fileDIC);   
            [ND2PathNameDIC, ND2FileNameDIC, ND2FileExtensionDIC] = fileparts(ND2fullFileNameDIC);
            
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
    
    
    % -----------------  Open the EPI file 
    choiceOpenND2EPI = 'Yes';
    switch choiceOpenND2EPI    
        case 'Yes'
            disp('Opening the EPI ND2 Video File to get path and filename info to be analyzed')
            [ND2fileEPI, ND2pathEPI] = uigetfile(fullfile(ND2pathDIC, '*.nd2'), 'EPI ND2 video file');    
            if ND2fileEPI==0
                error('No file was selected');
            end
            
            ND2fullFileNameEPI = fullfile(ND2pathEPI, ND2fileEPI);   
            [ND2PathNameEPI, ND2FileNameEPI, ~] = fileparts(ND2fullFileNameEPI);
            
            ND2FileNamePartsEPI = split(ND2FileNameEPI, '-');
            AnalysisSuffixEPI = join(ND2FileNamePartsEPI(end-2:end), '-');
            AnalysisSuffixEPI = AnalysisSuffixEPI{:};
            AnalysisFolderStrEPI = strcat('Analysis_', AnalysisSuffixEPI);
            OutputPathNameEPI = fullfile(ND2pathEPI, '..', AnalysisFolderStrEPI);
            
            fprintf('EPI ND2 Video File to be analyzed is: \n %s \n', OutputPathNameEPI);
            disp('----------------------------------------------------------------------------')  
            
            try
                mkdir(OutputPathNameEPI)
            catch
                
            end
        case 'No'
            if ~exist('OutputPathNameEPI', 'var')
                OutputPathNameEPI = pwd;
            end
            % keep going
        otherwise
            error('Could not open *.nd2 file');
    end
    
%% ----------------- Read Sensor Data & Clean it up.    
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
            
    switch controlMode    
        case 'Controlled Force'            
            SensorDataDICFullFileName = fullfile(ND2PathNameDIC, strcat(ND2FileNameDIC, '.dat'));
            SensorOutputPath_DIC = fullfile(OutputPathNameDIC, 'Sensor_Signals');
            try
                mkdir(SensorOutputPath_DIC)
            catch
                
            end

            [SensorDataDIC, HeaderDataDIC, HeaderTitleDIC, SensorDataFullFilenameDIC, SensorOutputPathNameDIC, ~, SamplingRate, SensorDataColumns]  = ReadSensorDataFile(SensorDataDICFullFileName, PlotSensorData, SensorOutputPath_DIC, AnalysisPath, 8, 'No');   
            close all
            [CleanSensorDataDIC , ExposurePulseCountDIC, EveryNthFrameDIC, CleanedSensorDataFullFileName_DIC, HeaderData, HeaderTitle, FirstExposurePulseIndexDIC] = CleanSensorDataFile(SensorDataDIC, 1, SensorDataFullFilenameDIC, SamplingRate, HeaderDataDIC, HeaderTitleDIC, SensorDataColumns);
            %{
                Do not forget to reduce the frames of the cleaned sensor data to match the reduce frame number in the accompanying video 
            %}
            clear SensorDataDIC
            %---------------- EPI
            SensorDataEPIFullFileName = fullfile(ND2PathNameEPI, strcat(ND2FileNameEPI, '.dat'));
            SensorOutputPath_EPI = fullfile(OutputPathNameEPI, 'Sensor_Signals');
            try
                mkdir(SensorOutputPath_EPI)
            catch

            end

            [SensorDataEPI, HeaderDataEPI, HeaderTitleEPI, SensorDataFullFilenameEPI, SensorOutputPathNameEPI, ~, SamplingRate, SensorDataEPIColumns]  = ReadSensorDataFile(SensorDataEPIFullFileName, PlotSensorData, SensorOutputPath_EPI, AnalysisPathEPI, 8, 'No');   
            close all
            % Cleaning the sensor data.
            [CleanSensorDataEPI , ExposurePulseCountEPI, EveryNthFrameEPI, CleanedSensorDataFullFileName_EPI, HeaderDataEPI, HeaderTitleEPI, FirstExposurePulseIndexEPI] = CleanSensorDataFile(SensorDataEPI, 1, SensorDataFullFilenameEPI, SamplingRate, HeaderDataEPI, HeaderTitleEPI, SensorDataEPIColumns);
            %{
                Do not forget to reduce the frames of the cleaned sensor data to match the reduce frame number in the accompanying video 
            %}
            clear SensorDataEPI
    end  
    
%% ----------------------------- Extracting ND2 timestamps
% ----------------- 5.0  Create timestamps from the sensor data file instead of through that in the video metadata.
% ----------------- Create timestamps from the sensor data file instead of through that in the video metadata.
    
    [TimeStampsND2_DIC, LastFrameND2_DIC, AverageTimeIntervalND2_DIC] = ND2TimeFrameExtract(ND2fullFileNameDIC);
    [TimeStampsND2_EPI, LastFrameND2_EPI, AverageTimeIntervalND2_EPI] = ND2TimeFrameExtract(ND2fullFileNameEPI);   
    
    switch controlMode    
        case 'Controlled Force'     
            [TimeStampsRT_Abs_DIC] = TimestampRTfromSensorData(CleanSensorDataDIC, SamplingRate, HeaderData, HeaderTitle, CleanedSensorDataFullFileName_DIC, FirstExposurePulseIndexDIC);   
            [TimeStampsRT_Abs_EPI] = TimestampRTfromSensorData(CleanSensorDataEPI, SamplingRate, HeaderDataEPI, HeaderTitleEPI, CleanedSensorDataFullFileName_EPI, FirstExposurePulseIndexEPI);
    end
    TimeStampsRT_Rel_DIC = TimeStampsRT_Abs_DIC - TimeStampsRT_Abs_DIC(1);
    TimeStampsRT_Rel_EPI = TimeStampsRT_Abs_EPI - TimeStampsRT_Abs_EPI(1);    
    
    FrameRateRT_DIC = 1/mean(diff(TimeStampsRT_Rel_DIC));
    FrameRateRT_EPI = 1/mean(diff(TimeStampsRT_Rel_EPI));    
    FrameRateRT = mean([FrameRateRT_DIC, FrameRateRT_EPI]);
    
%% ----------------- Create a Movie Data File for DIC Image for easier access to images and metadata
    MT_OutputPath = fullfile(OutputPathNameDIC, 'MT_Output');
    MD_DIC = bfImport(ND2fullFileNameDIC, 'outputDirectory', MT_OutputPath, 'askUser', 0);

    MD_DIC.numAperture_ = NumAperture;
    [SensorDataDICPathName, SensorDataDICFileName, ~] = fileparts(SensorDataDICFullFileName);
    SensorDataDICNotesFileName = fullfile(SensorDataDICPathName, strcat(SensorDataDICFileName, '_Notes.txt'));
    NotesDIC = fileread(SensorDataDICNotesFileName);

    MD_DIC.notes_ = NotesDIC;
    MD_DIC.magnification_ = MagnificationTimes;
    MD_DIC.timeInterval_ = AverageTimeIntervalND2_DIC;

%     NotesWordsDIC = split(NotesDIC, ' ');             % split by white space
%     AcquisitionDateDICStr = split(NotesWordsDIC{6}, '/');
%     AcquisitionTimeStr = split(NotesWordsDIC{8}, ':');
%     MonthNameDIC = month(datetime(1, str2num(AcquisitionDateDICStr{1}),1), 'name');
%     MonthNameDIC = MonthNameDIC{1};
%     
%     AcquisitionDateDIC = [MonthNameDIC, ' ', AcquisitionDateDICStr{2}, ', ' AcquisitionDateDICStr{3}]; 
%     MD_DIC.acquisitionDate_ = NotesWordsDIC{6};    
    
%% =============================== 4.0 Select the subsequent EPI ND2 file. It will be analyzed with TFM later, but for now

 % ----------------- 4.0 create TFM output path & MOvie Data File
    TFM_OutputPath = fullfile(OutputPathNameEPI, 'TFM_Output');
    MD_EPI = bfImport(ND2fullFileNameEPI, 'outputDirectory', TFM_OutputPath, 'askUser', 0);

    MD_EPI.numAperture_ = NumAperture;

    [SensorDataEPIPathName, SensorDataEPIFileName, ~] = fileparts(SensorDataEPIFullFileName);
    SensorDataEPINotesFileName = fullfile(SensorDataEPIPathName, strcat(SensorDataEPIFileName, '_Notes.txt'));
    NotesEPI = fileread(SensorDataEPINotesFileName);
    NotesEPISentences = splitlines(NotesEPI);
    NotesEPI_Words = split(NotesEPI, ' ');             % split by white space

    MD_EPI.notes_ = NotesEPI;
    MD_EPI.magnification_ = MagnificationTimes;
    MD_EPI.timeInterval_ = AverageTimeIntervalND2_EPI;
    MD_EPI.channels_.emissionWavelength_;                   % 
    MD_EPI.channels_.excitationWavelength_ = 560;           % nm for texas red;
    MD_EPI.channels_.excitationType_ = 'Widefield';         % Widefield Fluorescence.
    MD_EPI.channels_.exposureTime_ = AverageTimeIntervalND2_EPI; % in seconds
    MD_EPI.channels_.fluorophore_ = 'TexasRed';
   
%     AcquisitionDateEPIStr = split(NotesWordsEPI{6}, '/');
%     AcquisitionTimeStr = split(NotesWordsEPI{8}, ':');
%     MonthNameEPI = month(datetime(1, str2num(AcquisitionDateEPIStr{1}),1), 'name');
%     MonthNameEPI = MonthNameEPI{1};
%     
%     AcquisitionDateEPI = [MonthNameEPI, ' ', AcquisitionDateEPIStr{2}, ', ' AcquisitionDateEPIStr{3}]; 
%     MD_EPI.acquisitionDate_ = NotesWordsEPI{6};      

%% =============================== 5.0 Tracking Magnetic Bead (4.5 micron Tosylactivated)
    disp('_________________ Starting tracking of the magnetic bead')
    MagBeadOutputPath = fullfile(MT_OutputPath, 'Mag_Bead_Tracking');
    try
        mkdir(MagBeadOutputPath)
    catch
        % continue
    end
    FrameCountDIC = MD_DIC.nFrames_;
    
    FramesDoneNumbersDIC = 1:FrameCountDIC;
    VeryFirstFrame = FramesDoneNumbersDIC(1);   
    VeryLastFrame =  FramesDoneNumbersDIC(end);           
    FirstFrame_DIC = VeryFirstFrame;
    LastFrame_DIC =  VeryLastFrame; 

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
    
    TrackingMethod = 'imgregtform()';
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
                    imSize = size(RefFrameDICAdjust);
                    close(figHandle)    
                    SideLengths =  [1, 1] * round((24 / ScaleMicronPerPixel));        % ±12 µm to pixels
                    BeadROI_CroppedRectangle = [round((imSize / 2) - SideLengths ./2), SideLengths];
                    [BeadROI_DIC, BeadROI_CroppedRectangle] = imcrop(RefFrameDICAdjust, BeadROI_CroppedRectangle);
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
            BeadRadius = nan(size(FramesDoneNumbersDIC))';
            BeadPositionXYCenterPixels  = nan(numel(FramesDoneNumbersDIC), 2);
            reverseString = ''; 
%             
            figMagBeadTracked = figure('color', 'w');
            figMagBeadTrackedAxes = gca;
            axis image
            
            %___ needs to be upgraded to use parallel processing and invoking 'MagBeadTrackedPosition_imtFindCircles.m'
            disp('---------------------------------------------------------------------------------')
            disp('Tracking the displacement of the magnetic bead. No Drift correction yet')
            parfor_progress(numel(FramesDoneNumbersDIC));
            parfor CurrentDIC_Frame_Numbers = FramesDoneNumbersDIC                
                [CurrentCenter, CurrentRadius] = MagBeadTrackedPosition_imFindCircles(MD_DIC, CurrentDIC_Frame_Numbers, BeadROI_CroppedRectangle, ...
                    BeadRadiusRange, 'dark', 'TwoStage', 0.4,  0.8);
                BeadRadius(CurrentDIC_Frame_Numbers, :) = CurrentRadius;
                BeadPositionXYCenterPixels(CurrentDIC_Frame_Numbers, :) = CurrentCenter;
                parfor_progress;
            end        
            parfor_progress(0);
            
            BeadPositionXYcenter = BeadROI_CroppedRectangle(1:2) + BeadPositionXYCenterPixels + largerROIPositionPixels; 
            
        case 'imgregtform()'                            %% Slower, but more accurate.
            TrackingModeList = {'multimodal','monomodal'};
%             TrackingModeListChoiceIndex = listdlg('ListString', TrackingModeList, 'SelectionMode', 'single', 'InitialValue', 1, ...
%                 'PromptString', 'Choose the tracking mode:', 'ListSize', [200, 100]); 
%             if isempty(TrackingModeListChoiceIndex), TrackingModeListChoiceIndex = 1; end
            TrackingModeListChoiceIndex = 2;                       
            TrackingMode = TrackingModeList{TrackingModeListChoiceIndex}; 

            [optimizer, metric] = imregconfig(TrackingMode);
            if isgpuarray(metric), metric = double(gather(metric));end
            
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
%             close(figHandle)    
            SideLengths =  [1, 1] * round((24 / ScaleMicronPerPixel));        % ±12 µm to pixels
            BeadROI_CroppedRectangle = [round((imSize / 2) - SideLengths ./2), SideLengths];
            [BeadROI_DIC, BeadROI_CroppedRectangle] = imcrop(RefFrameDICAdjust, BeadROI_CroppedRectangle);

%             pause(2)
%             fig2 = imshow(BeadROI_DIC, 'InitialMagnification', 400);
%             figure(fig2.Parent.Parent)
%             BeadROIcenterPixels = ginput(1);
%             close(fig2.Parent.Parent)
% 
            BeadROIcenterPixels = SideLengths / 2;

            figHandleROI = figure('color', 'w');
            figAxesHandleROI = gca;
            colormap(GrayColorMap);
            imagesc(figAxesHandleROI,imadjust(BeadROI_DIC, []))
            hold on
            set(figAxesHandleROI, 'FontWeight', 'bold','LineWidth',1, 'XMinorTick', 'on', 'YMinorTick', 'on', 'TickDir', 'out', 'Box', 'on') 
            xlabel('X (pixels)'), ylabel('Y (pixels)')
            xlabel('X (pixels)'), ylabel('Y (pixels)')
            title('4X ROI to be tracked')            
            axis image
            [centers, BeadRadius, ~] = imfindcircles(BeadROI_DIC, BeadRadiusRange, 'ObjectPolarity' ,'dark', 'Method', 'TwoStage', 'EdgeThreshold', 0.7, 'Sensitivity', 0.95);   %'Sensitivity', 0.8
                
            viscircles(centers, BeadRadius, 'EdgeColor','r');
            [ClosestBeadDist, BeadNodeID] = min(vecnorm(BeadROIcenterPixels - centers, 2, 2));
            BeadROIcenterPixels = centers(BeadNodeID, :);
            plot(BeadROIcenterPixels(:,1),BeadROIcenterPixels(:,2), 'r.', 'MarkerSize', 15)           % does not work when the needle is attached, or maube the lighting?
            LocationScale = SideLengths - [3,3];                  % bottom right corner
            ScaleLength =   round((max(SideLengths) * ScaleMicronPerPixel)/5, 1, 'significant');     
            scalebar(figAxesHandleROI,'ScaleLength', ScaleLength, 'ScaleLengthRatio', ScaleMicronPerPixel, 'color', [0,0,0]', ...
                'bold', true, 'unit', sprintf('%sm', char(181)), 'location', LocationScale);             % Modified by WIM                    
            MagBeadTrackingROIsFullFileNameFig = fullfile(MagBeadOutputPath, 'BeadTrackingROI_DIC.fig');
            MagBeadTrackingROIsFullFileNamePNG = fullfile(MagBeadOutputPath, 'BeadTrackingROI_DIC.png');    
            savefig(figHandleROI, MagBeadTrackingROIsFullFileNameFig, 'compact')
            saveas(figHandleROI, MagBeadTrackingROIsFullFileNamePNG, 'png')
            close(figHandleROI)

            clear BeadPositionXYCornerPixels 
%             refImg = imref2d(size(BeadROI_DIC));

            BeadPositionXYCornerPixels = nan(numel(FramesDoneNumbersDIC), 2);
            disp('---------------------------------------------------------------------------------')
            disp('Tracking the displacement of the magnetic bead. No Drift correction yet')
            parfor_progress(numel(FramesDoneNumbersDIC));
            parfor CurrentDIC_Frame_Numbers = FramesDoneNumbersDIC                
                switch TransformationType
                    case 'translation'
                        BeadPositionXYCornerPixels(CurrentDIC_Frame_Numbers,:) = MagBeadTrackedPosition_imtRegForm(MD_DIC, CurrentDIC_Frame_Numbers, BeadROI_DIC, BeadROI_CroppedRectangle, ...
                            TransformationType, optimizer, metric, 0);
                    case 'rigid'

                end
                parfor_progress;
            end        
            parfor_progress(0);
            disp('Tracking the displacement of the magnetic bead complete')
            BeadPositionXYcenter = BeadPositionXYCornerPixels + BeadROIcenterPixels + largerROIPositionPixels; 
        otherwise
            return
    end    
% % % % % %     
% % % % % %     MagBeadDriftROIsFullFileNameFig = fullfile(MagBeadOutputPath, 'DriftCorrectionCornerROIs_DIC.fig');
% % % % % %     MagBeadDriftROIsFullFileNamePNG = fullfile(MagBeadOutputPath, 'DriftCorrectionCornerROIs_DIC.png');    
% % % % % %     savefig(figHandle, MagBeadDriftROIsFullFileNameFig, 'compact')
% % % % % %     saveas(figHandle, MagBeadDriftROIsFullFileNamePNG, 'png')
% % % % % %     
    % Tracking  

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
    save(MagBeadTrackedDisplacementsFullFileName, 'MagBeadCoordinatesXYpixels', 'MagBeadCoordinatesXYNetpixels', 'BeadNodeID', ...
        'TrackingMethod', 'BeadPositionXYcenter', 'BeadPositionXYdisplMicron', 'FramesDoneNumbersDIC', 'TimeStampsRT_Abs_DIC',...
        'RefFrameNum', 'MagnificationTimesStr', 'ScaleMicronPerPixel', 'largerROIPositionPixels', 'BeadMaxNetDisplMicron', 'BeadMaxNetDisplFrame', '-v7.3')
% % % % %     save(MagBeadTrackedDisplacementsFullFileName, 'MagBeadCoordinatesXYpixels', 'MagBeadCoordinatesXYNetpixels', 'BeadNodeID', 'BeadROI_DIC', ...
% % % % %         'TrackingMethod', 'BeadPositionXYcenter', 'BeadPositionXYdisplMicron', 'FramesDoneNumbersDIC', 'TimeStampsRT_Abs_DIC',...
% % % % %         'RefFrameNum', 'MagnificationTimesStr', 'ScaleMicronPerPixel', 'largerROIPositionPixels', 'BeadMaxNetDisplMicron', 'BeadMaxNetDisplFrame', '-v7.3')

    switch TrackingMethod
        case 'imfindcircles()'
            save(MagBeadTrackedDisplacementsFullFileName,'BeadRadius', '-append')
        case 'imgregtform()'
            save(MagBeadTrackedDisplacementsFullFileName, 'optimizer', 'metric', '-append');
    end
    fprintf('Tracking output and plots are saved under: \n\t %s\n', MagBeadOutputPath)
    fprintf('DIC Tracking output is saved as: \n\t%s\n', MagBeadTrackedDisplacementsFullFileName);
%---------------------- Plotting
    showPlot = 'on';
    figHandle = figure('visible',showPlot, 'color', 'w');     % added by WIM on 2019-02-07. To show, remove 'visible 
    plot(TimeStampsRT_Abs_DIC(FramesDoneNumbersDIC), BeadPositionXYdisplMicron(FramesDoneNumbersDIC,3), 'b-', 'LineWidth', 1)
    xlim([0, TimeStampsRT_Abs_DIC(FramesDoneNumbersDIC(end),1)]);               % Adjust the end limit.
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
        sprintf('%s.%s\n', ND2FileNameDIC, ND2FileExtensionDIC)}, 'FontWeight', 'bold', 'interpreter', 'none')
    legend('No Drift-Correction')

    MagBeadPlotFullFileNameFig = fullfile(MagBeadOutputPath, 'MagBeadDisplacementsPlusMax.fig');
    MagBeadPlotFullFileNamePNG = fullfile(MagBeadOutputPath, 'MagBeadDisplacementsPlusMax.png');    
    savefig(figHandle, MagBeadPlotFullFileNameFig, 'compact')
    saveas(figHandle, MagBeadPlotFullFileNamePNG, 'png')
    close all
    
    fprintf('Magnetic bead displacements are saved as: \n\t %s\n\t %s\n', MagBeadPlotFullFileNameFig, MagBeadPlotFullFileNamePNG)


%% ============ Figure out the 10% of the corners based on the beads detected
% ----------------- Creating the reference frame from the first frame and
% saving it and embedding it in MD_EPI
    RefFrameEPI = MD_EPI.channels_.loadImage(1);
    RefFramePathEPI =  fullfile(TFM_OutputPath, 'ReferenceFirstFrame.tif');
    imwrite(RefFrameEPI, RefFramePathEPI, 'TIFF')
    
%_____________ Construct the TFM package
    if isempty(MD_EPI.packages_)
        packageName = 'TFMPackage';
        packageConstr = str2func(packageName);
       % Add package to movie
        packageIndx = MD_EPI.getPackageIndex(packageName,1,true);
        MD_EPI.addPackage(packageConstr(MD_EPI, MD_EPI.outputDirectory_));  
    end
%_____________ Setup epi beads reference frame, tracking parameters, and output path
    % Create a structure that contains that Displacement Process Tracking
    displacementParameters.referenceFramePath = RefFramePathEPI;
    displacementParameters.alpha = 0.01;
    displacementParameters.minCorLength = 31;
    displacementParameters.maxFlowSpeed = 15;       % pixels per frame tracked
    displacementParameters.highRes = 1;
    displacementParameters.useGrid = 0;
    displacementParameters.lastToFirst = 0;
    displacementParameters.noFlowOutwardOnBorder = 1;
    displacementParameters.addNonLocMaxBeads = 0;
    displacementParameters.trackSuccessively =  0;
    displacementParameters.mode = 'accurate';
    % these parameters will be embedded when calling on calculateMovieDisplacementField.m
        
%% =============================== 7.0 Determining the Corners COORDINATES BUT NEED TO FIND THE PSF SIGMA EXTERNALLY from the EPI file
    disp('Determining PSF value, Beads to be tracked, and the dimensions of the grid')
    try
        [~, psfSigma, psfSigmaPlot] = getGaussianSmallestPSFsigmaFromData(double(RefFrameEPI),'Display',true);       % Changed to True by Waddah Moghram on 5/27/2019
        close(psfSigmaPlot)
    catch
        psfSigma = nan;                    
    end
    if isnan(psfSigma) || psfSigma > MD_EPI.channels_.psfSigma_*3 
        if strcmp(MD_EPI.channels_.imageType_,'Widefield') || MD_EPI.pixelSize_>130
            psfSigma = MD_EPI.channels_.psfSigma_*2; %*2 scale up for widefield.                  % TERRIBLE FOR OUR EPI Experiments. Waddah Moghram on 2019-10-27
        elseif strcmp(MD_EPI.channels_.imageType_,'Confocal')
            psfSigma = MD_EPI.channels_.psfSigma_*0.79; %*4/7 scale down for  Confocal finer detection SH012913
        elseif strcmp(MD_EPI.channels_.imageType_,'TIRF')
            psfSigma = MD_EPI.channels_.psfSigma_ * 3/7; %*3/7 scale down for TIRF finer detection SH012913
        else
            error('(ERROR in calculateMovieDisplacementField.m): image type should be chosen among Widefield, confocal and TIRF!');
        end
    end              
    disp(['Determined sigma: ' num2str(psfSigma)])
    disp('Detecting beads in the reference frame...')
    %------------    
    maskArray = MD_EPI.getROIMask;
    % Use mask of first frame to filter bead detection
    firstMask = RefFrameEPI > 0; %false(size(refFrame));
    tempMask = maskArray(:,:,1);
    clear maskArray
    % firstMask(1:size(tempMask,1),1:size(tempMask,2)) = tempMask;
    tempMask2 = false(size(RefFrameEPI));     
    y_shift = find(any(firstMask,2),1);
    x_shift = find(any(firstMask,1),1);

    tempMask2(y_shift:y_shift+size(tempMask,1)-1,x_shift:x_shift+size(tempMask,2)-1) = tempMask;
    firstMask = tempMask2 & firstMask;

    pstruct = pointSourceDetection(RefFrameEPI, psfSigma, 'alpha',displacementParameters.alpha, 'Mask',firstMask, 'FitMixtures', false);            % Changed by Waddah Moghram on 2019-10-27. To go along with 
      % Get the mask
    assert(~isempty(pstruct), 'Could not detect any bead in the reference frame');
    % filtering out points in saturated image based on pstruct.c
    [N,edges] = histcounts(pstruct.c);
    % starting with median, find a edge disconnected with two consequtive zeros.
    medC = median(pstruct.c);
    idxAfterMedC= find(edges>medC);
    qq=idxAfterMedC(1);
    while N(qq)>0 || N(qq+1)>0
        qq=qq+1;
        if qq>=length(edges)-1
            break
        end
    end
    idx = pstruct.c<edges(qq);
    beads = [pstruct.x(idx)', pstruct.y(idx)'];   
%                 beads = [round(pstruct.x(idx)'), round(pstruct.y(idx)')];         % changed by WIM on 2020-08-26 so that it is not rounded
    %     beads = [ceil(pstruct.x'), ceil(pstruct.y')];
%----------------------------------
    % Subsample detected beads ensuring beads are separated by at least half of the correlation length - commented out to get more beads
    if ~displacementParameters.highRes
        disp('Subsampling detected beads (normal resolution)...')
        max_beads_distance = floor(displacementParameters.minCorLength/2);
    %----------------------------------
    else
        % To get high-resolution information, subsample detected beads ensuring  beads are separated by 0.1 um the correlation length 
        disp('Subsampling detected beads (high resolution)...')
        max_beads_distance = (100/MD_EPI.pixelSize_);
    end
%----------------------------------
    idx = KDTreeBallQuery(beads, beads, max_beads_distance);
    valid = true(numel(idx),1);
    for i = 1 : numel(idx)
        if ~valid(i), continue; end
        neighbors = idx{i}(idx{i} ~= i);
        valid(neighbors) = false;
    end
    beads = beads(valid, :);
    %{
        It doesn't critically require local maximal pixel to start
        x-correlation-based tracking. Thus, to increase spatial resolution,
        we add additional points in the mid points of pstruct
        We first randomly distribute point, and if it is not too close to
        existing points and the intensity of the point is above a half of the
        existing points, include the point into the point set
    %}
%----------------------------------
    if displacementParameters.addNonLocMaxBeads
        disp('Finding additional non-local-maximal points with high intensity ...')
        distance=zeros(length(beads),1);
        for i=1:length(beads)
            neiBeads = beads;
            neiBeads(i,:)=[];
            [~,distance(i)] = KDTreeClosestPoint(neiBeads,beads(i,:));
        end
        avg_beads_distance = quantile(distance,0.5);%mean(distance);%size(RefFrameEPI,1)*size(RefFrameEPI,2)/length(beads);
        notSaturated = true;
        xmin = min(pstruct.x);
        xmax = max(pstruct.x);
        ymin = min(pstruct.y);
        ymax = max(pstruct.y);
    %     avgAmp = mean(pstruct.A);
    %     avgBgd = mean(pstruct.c);
    %     thresInten = avgBgd+0.02*avgAmp;
%                 thresInten = quantile(pstruct.c,0.25);
        thresInten = quantile(pstruct.c,0.5); % try to pick up bright-enough spots
        maxNumNotDetected = 20; % the number of maximum trial without detecting possible point
        numNotDetected = 0;
        numPrevBeads = size(beads,1);

        % To avoid camera noise, Gaussian-filtered image will be used - SH 20171010
        refFrameFiltered = filterGauss2D(RefFrameEPI, psfSigma*0.90);                      
    %----------------------------------
        tic
        while notSaturated
            x_new = xmin + (xmax-xmin)*rand(10000,1);
            y_new = ymin + (ymax-ymin)*rand(10000,1);
            [~,distToPoints] = KDTreeClosestPoint(beads,[x_new,y_new]);
            inten_new = arrayfun(@(x,y) refFrameFiltered(round(y),round(x)),x_new,y_new);
            idWorthAdding = distToPoints>avg_beads_distance & inten_new>thresInten;
            if sum(idWorthAdding)>1
                beads = [beads; [x_new(idWorthAdding), y_new(idWorthAdding)]];
                numNotDetected = 0;
            else
                numNotDetected=numNotDetected+1;
            end
            if numNotDetected>maxNumNotDetected
                notSaturated = false; % this means now we have all points to start tracking from the image
            end
        end
        toc
    %----------------------------------
        disp([num2str(size(beads,1)-numPrevBeads) ' points were additionally detected for fine tracking. Total detected beads: ' num2str(length(beads))])
    end
    % Exclude all beads which are less  than half the correlation length 
    % away from the padded border. By default, no centered template should 
    % include any NaN's for correlation
    % Create beads mask with zero intensity points as false
    beadsMask = true(size(RefFrameEPI));
    % beadsMask(currImage==0)=false;
    % Remove false regions non-adjacent to the image border
    beadsMask = beadsMask | imclearborder(~beadsMask);
    %         % Erode the mask with half the correlation length and filter beads
    %         erosionDist=round((displacementParameters.minCorLength+1)/2);
    % Erode the mask with the correlation length + half maxFlowSpeed
    % and filter beads to minimize error
%----------------------------------
    if displacementParameters.noFlowOutwardOnBorder
        erosionDist = (displacementParameters.minCorLength+1);
    else
        erosionDist = displacementParameters.minCorLength+1+round(displacementParameters.maxFlowSpeed/4);
    end
%----------------------------------
    beadsMask = bwmorph(beadsMask,'erode',erosionDist);
    %         beadsMask=imerode(beadsMask,strel('square',erosionDist));
    indx = beadsMask(sub2ind(size(beadsMask),ceil(beads(:,2)), ceil(beads(:,1))));
    localbeads = beads(indx,:);
    
%___________ Creating a rectangular grid based on bead locations
    [reg_grid,~,~,gridSpacing] = createRegGridFromDisplField(localbeads, 2, displacementParameters.noFlowOutwardOnBorder);
    % Edge Erode to make it a square grid 
   
    gridXmin = min(unique(reg_grid(:,:,1)));
    gridXmax = max(unique(reg_grid(:,:,1)));
    gridYmin = min(unique(reg_grid(:,:,2)));
    gridYmax = max(unique(reg_grid(:,:,2)));    
    
    % At this point you can correct for displacement drift in DIC modes.
     
    fprintf('psfSigma = %0.3f, Microsphere count = %d\n', ...
        psfSigma, size(localbeads, 1))
    fprintf('Corners of square and even-numbered grid are at [%0.3g, %0.3g , %0.3g, %0.3g] pixels\n', gridXmin, gridYmin, gridXmax, gridYmax)
    
    
    
 
%% =============================== 8.0 Correct displacements for drift based on displacement in 4 corner ROIs
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
    DIC_image = imagesc(figAxesHandle, 1, 1, RefFrameDICAdjust);
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
                RefFrameDIC_RectHandle(jj) = rectangle(figAxesHandle,'Position', DriftROI_rect(jj, :), 'EdgeColor', 'm',  'FaceColor', 'none', 'LineWidth', 1, 'LineStyle', '-');   
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
    % scalebar
    LocationScale = MD_EPI.imSize_ - [3,3];                  % bottom right corner
    ScaleLength =   round((max(MD_EPI.imSize_) - max([gridXmax - gridXmin, gridYmax - gridYmin]))/4, 1, 'significant');     
    scalebar(figAxesHandle,'ScaleLength', ScaleLength, 'ScaleLengthRatio', ScaleMicronPerPixel, 'color', [0,0,0]', ...
        'bold', true, 'unit', sprintf('%sm', char(181)), 'location', LocationScale);             % Modified by WIM                    
    hold on
    BeadCentroid = plot(figAxesHandle, BeadPositionXYcenter(1,1), BeadPositionXYcenter(1,2), 'r.', 'MarkerSize', 10);
    
    MagBeadDriftROIsFullFileNameFig = fullfile(MagBeadOutputPath, 'DriftCorrectionCornerROIs_DIC.fig');
    MagBeadDriftROIsFullFileNamePNG = fullfile(MagBeadOutputPath, 'DriftCorrectionCornerROIs_DIC.png');    
    savefig(figHandle, MagBeadDriftROIsFullFileNameFig, 'compact')
    saveas(figHandle, MagBeadDriftROIsFullFileNamePNG, 'png')
    
% EPI Frame ROIs & grid & bead
    GrayLevels = 2^ImageBits;   
    colormapLUT = [linspace(0,1,GrayLevels)', zeros(GrayLevels,2)];             % Look up table 

    ComplementColor = median(imcomplement(colormapLUT));               % User Complement of the colormap for maximum visibililty of the quiver.

    cla
    GrayLevelsPercentile = [0.05, 0.999];
    RefFrameEPIadjusted = imadjust(RefFrameEPI, stretchlim(RefFrameEPI,GrayLevelsPercentile));
    EPI_image = imagesc(figAxesHandle, 1, 1, RefFrameEPIadjusted);
    hold on
    colormap(colormapLUT)   
    plot(figAxesHandle, reg_grid(:,:,1), reg_grid(:,:,2), 'Color', ComplementColor, 'Marker', '.', 'MarkerSize', 1, 'LineStyle', 'none') % plot grid
    
    % scalebar
    LocationScale = MD_EPI.imSize_ - [3,3];                  % bottom right corner
    ScaleLength =   round((max(MD_EPI.imSize_) - max([gridXmax - gridXmin, gridYmax - gridYmin]))/4, 1, 'significant'); 
    ScaleBarColor = ComplementColor;
    s = scalebar(figAxesHandle,'ScaleLength', ScaleLength, 'ScaleLengthRatio', ScaleMicronPerPixel, 'color', ScaleBarColor, ...
        'bold', true, 'unit', sprintf('%sm', char(181)), 'location', LocationScale);             % Modified by WIM                    
    hold on
    % plot detected beads                 
    Beads = plot(figAxesHandle, localbeads(:,1), localbeads(:,2), 'MarkerSize', 7, 'Marker', '.', 'MarkerFaceColor', 'b', 'MarkerEdgeColor', 'w', 'LineStyle', 'none');
    
    switch IdenticalCornersChoice
        case 'Yes'
            for jj = 1:cornerCount
                rectangle(figAxesHandle,'Position', DriftROI_rect(jj, :), 'EdgeColor', 'm',  'FaceColor', 'none', 'LineWidth', 1, 'LineStyle', '-');   
            end
            pause(0.1)              % pause to allow it to draw the rectangles.
            title(figAxesHandle, sprintf('%0.2g%% %d Corners ROIs. Tracked Beads & TFM Grid', CornerPercentageDefault * 100, cornerCount));
        otherwise
        return;
    end
    LocationBeadCount = MD_EPI.imSize_ .* [0, 1] + [3,-3];                  % bottom right corner
    BeadText = text(figAxesHandle, LocationBeadCount(1), LocationBeadCount(2), sprintf('Beads to be Tracked = %d. Beads Found = %d ', numel(localbeads(:, 1)), numel(beads(:, 1))));
    set(BeadText, 'color', s.Children(1).Color, 'FontSize', s.Children(1).FontSize, 'FontName', s.Children(1).FontName, ...
        'FontWeight', s.Children(1).FontWeight, 'VerticalAlignment', 'baseline')
    
    MagBeadDriftROIsFullFileNameFig = fullfile(MagBeadOutputPath, 'DriftCorrectionCornerROIs_EPI.fig');
    MagBeadDriftROIsFullFileNamePNG = fullfile(MagBeadOutputPath, 'DriftCorrectionCornerROIs_EPI.png');    
    savefig(figHandle, MagBeadDriftROIsFullFileNameFig, 'compact')
    saveas(figHandle, MagBeadDriftROIsFullFileNamePNG, 'png')
    
    close all
%-----------------------    
    DIC_DriftROIsMeanAllFrames = nan(numel(FramesDoneNumbersDIC), 3);
    disp('---------------------------------------------------------------------------------')
    disp('Correcting for drift displacement of the magnetic bead.')          
    fprintf('Starting drift correction step based on %d%% per side area\n', CornerPercentage * 100)
    parfor_progress(numel(FramesDoneNumbersDIC));
    
    parfor CurrentFrame = FramesDoneNumbersDIC  
           TrackingModeList = {'multimodal','monomodal'};
%             TrackingModeListChoiceIndex = listdlg('ListString', TrackingModeList, 'SelectionMode', 'single', 'InitialValue', 1, ...
%                 'PromptString', 'Choose the tracking mode:', 'ListSize', [200, 100]); 
%      
            TrackingModeListChoiceIndex = 2;                       
            TrackingMode = TrackingModeList{TrackingModeListChoiceIndex}; 

            [optimizer, metric] = imregconfig(TrackingMode);
            if isgpuarray(metric), metric = double(gather(metric));end
            
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

        DIC_DriftROIsMeanAllFrames(CurrentFrame, :) = cornerMeanDrifts(MD_DIC, CurrentFrame, DriftROI_rect, RefFrameDIC_RectImage, TransformationType, optimizer, metric);                    
%         if ShowOutput
%             fprintf('Drift Correction for Frame %d/%d: [\tD_x = %0.4g pix, \t\t D_y = %0.4g pix, \t\t D_net = %0.4g] pix.\n',  CurrentFrame, VeryLastFrame, DIC_DriftROIsMeanAllFrames(CurrentFrame, :)); 
%         end  
        parfor_progress;
    end   
    parfor_progress(0);
    disp('Drift correction step is complete')
    disp('---------------------------------------------------------------------------------')    
%% =============================== 9.0 Updating coordinates to account for drift-         
    % Converting pixels to microns, and converting from 2D to 3D
    if sign(MagBeadCoordinatesXYpixels(1,2)) == -1              % y-coordiantes are in cartesian coordinates instead of image coordinates.
        MagBeadCoordinatesXYpixels(:,2) = - MagBeadCoordinatesXYpixels(:,2);            % consider saving the values as positive in the DIC tracking code. ~WIM 2020-01-06
    end
    MagBeadCoordinatesXYpixelsCorrected = MagBeadCoordinatesXYpixels(FramesDoneNumbersDIC,1:2) - DIC_DriftROIsMeanAllFrames(FramesDoneNumbersDIC,1:2);

    % MagBeadCoordinatesMicronXY has relative positions with the bead's initial position
    MagBeadCoordinatesMicronXY = MagBeadCoordinatesXYpixels .* ScaleMicronPerPixel;  
    MagBeadCoordinatesMicronXYcorrected = MagBeadCoordinatesXYpixelsCorrected .* ScaleMicronPerPixel;

    MagBeadCoordinatesMicronXYintial = MagBeadCoordinatesMicronXY(1,:);            
    MagBeadCoordinatesMicronXYintialCorrected = MagBeadCoordinatesMicronXYcorrected(1,:);    

    MagBeadDisplacementMicronXY = MagBeadCoordinatesMicronXY - MagBeadCoordinatesMicronXYintial;
    MagBeadDisplacementMicronXYcorrected = MagBeadCoordinatesMicronXYcorrected - MagBeadCoordinatesMicronXYintialCorrected;            

    MagBeadDisplacementMicronXYBigDelta = vecnorm(MagBeadDisplacementMicronXY(FramesDoneNumbersDIC,1:2),2,2);
    MagBeadDisplacementMicronXYBigDeltaCorrected = vecnorm(MagBeadDisplacementMicronXYcorrected(FramesDoneNumbersDIC,1:2),2,2);            

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
    LastFrame_DIC = min([numel(TimeStampsRT_Abs_DIC), numel(MagBeadDisplacementMicronXYZBigDeltaCorrected), VeryLastFrame]);       
    FramesDoneNumbersDIC = FirstFrame_DIC:LastFrame_DIC;
    
%% finding max drift-corrected displacement
    [BeadMaxNetDisplMicronDriftCorrected, BeadMaxNetDisplFrameDriftCorrected]  = max(MagBeadDisplacementMicronXYZBigDeltaCorrected(FramesDoneNumbersDIC));
     titleTrackStr = sprintf('Tracking Method: %s. with Drift-Correction | Maximum Displacement = %0.3f %sm', TrackingMethod, BeadMaxNetDisplMicronDriftCorrected, char(181));

%% =============================== 
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

%     try
%         ConcentrationIdx = find(ismember(NotesEPI_Words, 'mg/mL')) - 1;
%         GelConcentrationMgMl = str2double(NotesEPI_Words(ConcentrationIdx));
%     catch
%         GelConcentrationMgMl = input('What was the final concentration of the gel (mg/mL)?     ');    
%     end
%     
    ND2FilePrefix = split(ND2FileNamePartsDIC{1}, '_');
    GelConcentrationMgMlStr = ND2FilePrefix{2};
    GelConcentrationMgMl = sscanf(GelConcentrationMgMlStr, '%f'); 
    GelConcentrationMgMlStr = sprintf('%0.3f mg/mL', GelConcentrationMgMl);
    GelPolymerizationTempC = ND2FilePrefix(3);
    GelSampleNumber = ND2FileNamePartsDIC{2};
    BeadNumber = ND2FileNamePartsDIC{3};
    RunNumber = ND2FileNamePartsDIC{6};
    EDCorNOTstr = ND2FileNamePartsDIC{4};
    switch EDCorNOTstr
        case {'NoEDC', 'NoEDAC'}
            EDCorNOT = false;
        case {'EDC' , 'EDAC'}
            EDCorNOT = true;
    end
    

    switch GelPolymerizationTempC{:}
        case '37C'
            GelPolymerizationTempC = sprintf('%d%sC', 37, char(176));
        case 'RT'
            GelPolymerizationTempC = sprintf('Room Temperature (%0.1f%sC)', round(HeaderDataDIC(5,1), 1, 'decimals'), char(176));
    end

    fprintf('%s\n', GelType{:})
    fprintf('Gel concentration chosen is %.3f mg/mL. \n', GelConcentrationMgMl);
    save(MagBeadTrackedDisplacementsFullFileName, 'GelConcentrationMgMl', 'thickness_um','GelConcentrationMgMlStr', 'GelType',...
            'GelPolymerizationTempC', 'BeadMaxNetDisplMicronDriftCorrected', 'BeadMaxNetDisplMicronDriftCorrected', 'BeadMaxNetDisplFrameDriftCorrected',...
            'EDCorNOTstr', 'EDCorNOT', 'GelSampleNumber', 'BeadNumber', 'RunNumber', '-append')
    fprintf('Output of drift correction is saved as:\n\t %s\n', MagBeadTrackedDisplacementsFullFileName)
    
% ================= 
    % Plotting Bead Displacement Micron vs. Pixel
    titleStr2 = sprintf('%.0f %sm-thick, %.1f mg/mL %s', thickness_um, char(181), GelConcentrationMgMl, GelType{1});
    titleStr = {titleStr2, titleTrackStr};            
    showPlot = 'on';            
    figHandle = figure('visible',showPlot, 'color','w');     % added by WIM on 2019-02-07. To show, remove 'visible
    plot(TimeStampsRT_Abs_DIC(FramesDoneNumbersDIC), MagBeadDisplacementMicronXYBigDelta(FramesDoneNumbersDIC), 'b-', 'LineWidth',1)
    hold on
    plot(TimeStampsRT_Abs_DIC(FramesDoneNumbersDIC), MagBeadDisplacementMicronXYBigDeltaCorrected(FramesDoneNumbersDIC), 'r-', 'LineWidth',1)
    xlim([0, TimeStampsRT_Abs_DIC(LastFrame_DIC,1)]);               % Adjust the end limit.
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

    save(MagBeadTrackedDisplacementsFullFileName, 'BeadMaxNetDisplFrameDriftCorrected', 'BeadMaxNetDisplMicronDriftCorrected', 'MagBeadCoordinatesMicronXY', 'MagBeadCoordinatesMicronXYcorrected', 'MagBeadDisplacementMicronXYBigDelta', ...
        'MagBeadCoordinatesXYpixels', 'MagBeadCoordinatesXYpixelsCorrected', 'MagBeadDisplacementMicronXYBigDeltaCorrected', ...
        'MagBeadCoordinatesMicronXYZ', 'MagBeadCoordinatesMicronXYZcorrected', 'DIC_DriftROIsMeanAllFrames', '-append');          
    save(MagBeadTrackedDisplacementsFullFileName, 'TimeStampsRT_Abs_DIC', '-append') 
    save(MagBeadTrackedDisplacementsFullFileName, 'DriftROI_rect', 'TrackingMode', 'metric', 'optimizer', '-append')


    fprintf('Net Displacement Big, Delta_{MT}(time) plots and *.mat files are stored in: \n\t %s \n' , MagBeadOutputPath);

    % Now switch the "corrected values" with regular ones so that they can be used directly in subsequent iterations.      
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

    close all

%% =============================== calculating MT forces
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
    
    % =============================== 9.0 Extract the needle tip coordinates 
    NeedleTipRelativeCoordinatesXYZmicrons = [0,0,0];   
    % ================= 10.0 The part below was taken from ForceMTvTime()
    switch controlMode
        case 'Controlled Force'
            %________ Inclination angle is not necessary anymore, but the part below is kept to prevent errors.
            commandwindow;
            try
                NeedleInclinationAngleDegrees = HeaderDataDIC(5,2);
            catch
                NeedleInclinationAngleDegrees = input('What is the needle inclination angle (in degrees)? ');
            end
            fprintf('Inclination Angle of the needle is %.0f%s. \n', NeedleInclinationAngleDegrees, char(0x00B0));
            %________
            
            %{
                Update 2020-01-22
                    3. Input:  InlincationAngleDegree is not used, but I will not mess with it for now due to a major rewrite everywhere. 
                    4. Input: TipRelativeCoordinatesMicronXYZ is also not needed. It can be calculated from the header and the initial coordinates of the bead.
            %}
            MagBeadCoordinatesMicronXYZ = MagBeadDisplacementMicronXYZ;
            NeedleTipRelativeCoordinatesXYZmicrons = [0,0,0];
            [MT_Force_xyz_N, MT_Force_xy_N, WorkBeadJ_Half_Cycle, WorkCycleFirstFrame, WorkCycleLastFrame, CompiledMT_Results] = CalculateForceMT(MagBeadCoordinatesMicronXYZ, ...
                NeedleTipRelativeCoordinatesXYZmicrons, ScaleMicronPerPixel, ...
                NeedleInclinationAngleDegrees, FirstFrame_DIC, LastFrame_DIC, TimeStampsRT_Abs_DIC, CleanSensorDataDIC, SensorDataFullFilenameDIC, ...
                MT_Force_OutputPath, MT_ForceFullFileName, ND2FileExtensionDIC, HeaderDataDIC, thickness_um, GelConcentrationMgMl, GelType);
    end
    close all

%%     save all variables to workspace so that I can continue my analysis
    save(OutputPathNameDIC, '-v7.3')
    fprintf('Workspace is saved as %s\n', strcat(OutputPathNameDIC, '.mat'))


%% %%%%%%%%%%%%%%%%%% Part 2: TFM Calculations. 1. Displacement filtering and drift corrections %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %_________________ Calculating the EPI displacement 
%     calculateMovieDisplacementField(MD_EPI, displacementParameters)
% %_________________ Correct displacements for spatial outliers
%     CorrectionfunParams.doRogReg = 0;               % No rotational adjustments for drift
%     CorrectionfunParams.outlierThreshold = 2;
%     CorrectionfunParams.fillVectors = 0;
%     correctMovieDisplacementField(MD_EPI, CorrectionfunParams)
% %_____Process displacements for drift and correcting for temporal errors.
%     try
%         displFieldProcess = MD_EPI.findProcessTag('DisplacementFieldCorrectionProcess', 'safeCall', true);        % 
%     catch
%         try
%             displFieldProcess = MD_EPI.findProcessTag('DisplacementFieldCalculationProcess', 'safeCall', true);         
%         catch
%             
%         end
%        error('No displacement field calculation found!')
%     end
%     displFieldPath = displFieldProcess.outFilePaths_{1};
%     load(displFieldPath, 'displField')
%     fprintf('Displacement Field (displField) File is successfully loaded!: \n\t %s\n', displFieldPath);
%     
%     [~, displField, TimeStampsRT_EPI, displFieldPath, ScaleMicronPerPixel, FramesDoneNumbersDIC, controlMode, ...
%         rect, DriftROIs, DriftROIsCombined, reg_grid, gridSpacing, NoiseROIs, NoiseROIsCombined, TimeFilterChoiceStr, ...
%         DriftCorrectionChoiceStr, displacementFileFullName] = ...
%             ProcessTrackedDisplacementTFM(MD_EPI, displField, TimeStampsRT_Abs_EPI, displFieldPath, gridMagnification, EdgeErode, GridtypeChoiceStr, ...
%                 InterpolationMethod, ShowOutput, FirstFrame_DIC, LastFrame_DIC, SaveOutput, controlMode, ScaleMicronPerPixel, CornerPercentage);
%     % update the last frame since 20 frames are eliminated after using LPEF
%     FirstFrameDIC = FramesDoneNumbersDIC(1);
%     LastFrameDIC = FramesDoneNumbersDIC(end);
%             
%     fprintf('Displacement Field (displField) processed: %s & %s.\n', TimeFilterChoiceStr, DriftCorrectionChoiceStr)    
%     
% %% =============================== FINDING THE OPTIMAL YOUNG'S ELASTIC MODULUS  
%     ConversionMicrontoMeters = 1e-6;
%     ConversionMicronSqtoMetersSq = ConversionMicrontoMeters.^2; 
%     
%     ConversionNtoNN = 1e9;
%     CornerPercentage = 0.10;                     % 10% of dimension length of tracked particles grid for each of the 4 ROIs    
%     DCchoice = 'Yes';
%     EdgeErode = 1;
% %     GelType = 'Type I Collagen';
%     SpatialFilterChoiceStr = 'Wiener 2D';
%     FrameDisplMeanChoice = 'No';    
%     gridMagnification = 1;                                      %% (to go with the original rectangular grid size created to interpolate displField)
%     GridtypeChoiceStr = 'Even Grid';
%     HanWindowChoice = 'Yes';
%     IdenticalCornersChoice = 'Yes';
%     InterpolationMethod = 'griddata';
%     PaddingChoiceStr = 'Padded with zeros only';                % Updated on 2020-03-03 by WIM
%     TractionStressMethod = 'FTTC';
%     ForceIntegrationMethod = 'Summed';
%     WienerWindowSize = [3, 3] ;                                      % 3x3 pixel window for Wiener2D Spatial Filter
%     ShowOutput = false;
%     CalculateRegParamMethod = 'ON Cycles mean(log10())';
%     reg_cornerChoiceStr = 'Optimized Bayesian L2 (BL2)'; 
% 
%     YoungModulusInitialGuess = 5 * GelConcentrationMgMl ^ 2.1 * 7;         % offset by 15. Local E is much stiffer than bulk one
%         %{
%         initial guess based on this paper.
%         Y. Yang, L. M. Leone, and L. J. Kaufman,
%            “Elastic Moduli of Collagen Gels Can Be Predicted from Two-Dimensional Confocal Microscopy,�? 
%             Biophys. J., vol. 97, no. 7, pp. 2051–2060, Oct. 2009.
%         %}
%     tolerancepower = 2;
%     tolerance = 10^(tolerancepower);            % number of significant figures beyond decimal to estimate Young's elastic modulus.
%          
%     
%     % Choose control mode (controlled force vs. controlled displacement).  
% %     controlMode = 'Controlled Force';               % for now that is the only way we can apply a known force from MT 2020-02-11
% %     dlgQuestion = 'What is the control mode for this EPI/DIC experiment? ';
% %     dlgTitle = 'Control Mode?';
% %     controlMode = questdlg(dlgQuestion, dlgTitle, 'Controlled Force', 'Controlled Displacement', 'Controlled Force');
% %     if isempty(controlMode), error('Choose a control mode'); end  
%          
%     reg_corner = []; 
%     
%     forceFieldParameters.YoungModulusPa = YoungModulusInitialGuess;
%     forceFieldParameters.PoissonRatio = PoissonRatio;
%     forceFieldParameters.GelType = GelType;
%     forceFieldParameters.thickness_nm = thickness_um * 1000; % in nm
%     forceFieldParameters.GelConcentrationMgMl = GelConcentrationMgMl;
%     forceFieldParameters.LcurveFactor = 10;  
%     forceFieldParameters.regParam = 1; 
%     forceFieldParameters.HanWindowChoice = HanWindowChoice;
%     forceFieldParameters.Notes = {'Elastic Modulus is in Pa', 'Thickness is in nanometers'};
%     
% %------------------------------------------------
%     CombinedAnalysisPath = fullfile(ND2pathEPI, '..', strcat('Analysis_', AnalysisSuffixDIC, '_&_', AnalysisSuffixEPI));
%     try  mkdir(CombinedAnalysisPath);  catch, end    
%     ModulusPathName = fullfile(CombinedAnalysisPath, 'Optimal_E-Modulus');
%     try mkdir(ModulusPathName); catch, end    
% 
%     %-------------- finding mutual frame numbers between both EPI and DIC
%     FramesDoneBooleanDIC = arrayfun(@(x) ~isempty(x), MT_Force_xy_N');
%     FramesDoneNumbersDIC = find(FramesDoneBooleanDIC == 1);
% 
%     FramesDoneBooleanEPI = arrayfun(@(x) ~isempty(x.vec), displField);
%     FramesDoneNumbersEPI = find(FramesDoneBooleanEPI == 1);
% 
%     FirstFrame = 1;
%     LastFrame = min(numel(FramesDoneBooleanDIC), numel(FramesDoneBooleanEPI));
%     FramesDoneBoolean = FramesDoneBooleanDIC(FirstFrame:LastFrame) & FramesDoneBooleanEPI(FirstFrame:LastFrame);
%     
%     FirstFrame = find(FramesDoneBoolean, 1);
%     LastFrame = find(FramesDoneBoolean, 1, 'last');
%     
%     FramesDoneBoolean = FirstFrame:LastFrame;
%  
% %     TimeStampsStart = max(TimeStampsRT_Abs_DIC(1), TimeStampsRT_Abs_EPI(1));
% %     TimeStampsEnd = min(TimeStampsRT_Abs_DIC(end), TimeStampsRT_Abs_EPI(end));    
% %     LastFrame = floor(TimeStampsEnd * FrameRateRT);  
% 
%     TimeStampsRT = [((FirstFrame:LastFrame) - FirstFrame) / FrameRateRT]';
%     
%      % =================== find first & last frame numbers based on timestamp ==================== 
%  
%     FluxON = CompiledMT_Results.FluxON(FirstFrame:LastFrame);
%     FluxOFF = CompiledMT_Results.FluxOFF(FirstFrame:LastFrame);
% 	FluxTransient = CompiledMT_Results.FluxTransient(FirstFrame:LastFrame);
% 
%     FluxONend = find(FluxON(2:end) - FluxON(1:end-1) == -1);            % end of cycles
%     
%     TimeEndOptimization = TimeStampsRT_Abs_DIC(FluxONend(YoungModulusOptimizedCycle));
%     TimeStartOptimization = TimeEndOptimization - YoungModulusOptimizedTimeSec;    
%     
%     switch controlMode
%         case 'Controlled Force'            
%             FirstFrameDIC = find((TimeStartOptimization - TimeStampsRT_Abs_DIC) <= 0, 1);               % Find the index of the first frame to be found.
%             fprintf('First DIC frame to be plotted is: %d.\n', FirstFrameDIC)
%             FirstFrameEPI = find((TimeStartOptimization - TimeStampsRT_Abs_EPI) <= 0, 1);               % Find the index of the first frame to be found.
%             fprintf('First EPI frame to be plotted is: %d.\n', FirstFrameEPI)            
%             LastFrameDIC = find((TimeEndOptimization - TimeStampsRT_Abs_DIC) <= 0,1);
%             fprintf('Last DIC frame to be plotted is: %d.\n', LastFrameDIC)            
%             LastFrameEPI = find((TimeEndOptimization - TimeStampsRT_Abs_EPI) <= 0,1);
%             fprintf('Last EPI frame to be plotted is: %d.\n', LastFrameEPI)
% 
%             FrameNumbersDIC = FirstFrameDIC:LastFrameDIC;
%             FrameNumbersEPI = FirstFrameEPI:LastFrameEPI;
%             %__ Trim to make sure you get the same number of samples for both
%             FramesSize = min([numel(FrameNumbersDIC), numel(FrameNumbersEPI)]);
%             FrameNumbersDIC = FrameNumbersDIC(1:FramesSize);
%             FrameNumbersEPI = FrameNumbersEPI(1:FramesSize);            
%         case 'Controlled Displacement'          % incomplete. I need to include a step to line both modes up. 
%     %             FirstFrame = find((TimeStartOptimization - TimeStampsRT) <= 0, 1);               % Find the index of the first frame to be found.
%     %             fprintf('First frame to be plotted is: %d.\n', FirstFrame); 
%     %             LastFrame = find((TimeEndOptimization - TimeStampsRT) <= 0,1);
%     %             fprintf('Last frame to be plotted is: %d.\n', LastFrame)
%     %             
%     %             LastFrameEPI = LastFrame;
%     %             LastFrameDIC = LastFrame;
%     %             FirstFrameEPI = FirstFrame;
%     %             FirstFrameDIC = FirstFrame;            
%     end
%     MT_Force_xy_N_Segment = MT_Force_xy_N(FrameNumbersDIC);
%     FramesOptimizedNumbers = FrameNumbersEPI;
%     
%     FramesRegParamNumbers = FramesOptimizedNumbers;
%     
%     options = optimset('Display', 'iter', 'TolFun', tolerance);    % 'TolX', tolerance   will do the significant figures for the Forces, not the elastic modulus
%     disp('______________________________________________________________________')
%     fprintf('Optimzation output will be saved under:\n\t%s\n', ModulusPathName);
%     disp('Evaluating Optimized Young Modulus...in progress.')
% 
%     starttime = tic;
%     
%     [YoungModulusPaOptimum, YoungModulusPaOptimumRMSE] = fminsearch(@(YoungModulusPa)Force_MTvTFM_RMSE_BL2_Master(displField, forceFieldParameters,...
%         FramesOptimizedNumbers, YoungModulusPa, PoissonRatio, MT_Force_xy_N_Segment, PaddingChoiceStr, HanWindowChoice, WienerWindowSize, ScaleMicronPerPixel, ...
%         gridMagnification, EdgeErode, CornerPercentage, FramesRegParamNumbers, ...
%         SpatialFilterChoiceStr, GridtypeChoiceStr, InterpolationMethod, TractionStressMethod, ForceIntegrationMethod, ...
%         ConversionMicrontoMeters, ConversionMicronSqtoMetersSq, ShowOutput, CalculateRegParamMethod), YoungModulusInitialGuess, options); 
%     
%     fprintf('Time elapsed: *** %0.4f sec *** to to calculate the elastic modulus to  *** %d sig. fig.***\n', toc(starttime), tolerancepower)
%     
% 
%     TractionForcePath = fullfile(displFieldPath, '..', 'forceField');
%     try
%         mkdir(TractionForcePath)
%     catch
%         % folder already found
%     end
% 
% %     NoiseROIsCombined = [];             % if it is not given, the NoiseROIs will be evaluated for each frame based on the interpolated grid.
%     [pos_grid, displFieldNoFilteredGrid, displFieldFilteredGrid, forceField, energyDensityField, ForceN, TractionEnergyJ, ...
%         reg_corner_raw, forceFieldParameters, CornerPercentage] = ...
%         TFM_MasterSolver(displField, NoiseROIsCombined, forceFieldParameters, reg_corner, ...
%         gridMagnification, EdgeErode, PaddingChoiceStr, SpatialFilterChoiceStr, HanWindowChoice, ...
%         GridtypeChoiceStr, reg_cornerChoiceStr, InterpolationMethod, TractionStressMethod, ForceIntegrationMethod, ...
%         WienerWindowSize, ScaleMicronPerPixel, ShowOutput, FirstFrame, LastFrame, CornerPercentage);
%  
% %% =============================== PLOTTING Raw regularization parameters
% %     dlgQuestion = ({'File Format(s) for images?'});
%     listStr = {'PNG', 'FIG', 'EPS'};
% %     PlotChoice = listdlg('ListString', listStr, 'PromptString',dlgQuestion, 'InitialValue', [1, 2], 'SelectionMode' ,'multiple');  
% %     if isempty(PlotChoice), error('X was selected'); end
%     PlotChoice = [1,2];
%     PlotChoice = listStr(PlotChoice);                 % get the names of the string.
% 
%     ConversionNtoNN = 1e9;  
%     ConversionJtoFemtoJ = 1e15;
%     
%     FramesPlotted(FramesDoneNumbers) = ~isnan(ForceN(FramesDoneNumbers));
%     LastFramePlotted = FramesDoneNumbers(end);
%     PlotsFontName = 'Helvatica-Narrow';
%     xLabelTime = 'Time [s]';
%     
%     try
%         titleStr1_1 = sprintf('%.0f %sm-thick, %g mg/mL %s gel', forceFieldParameters.thickness_nm/ 1000, char(181),forceFieldParameters.GelConcentrationMgMl, forceFieldParameters.GelType{:});
%         titleStr1_2 = sprintf('Young Modulus = %g Pa. Poisson Ratio = %.2g', forceFieldParameters.YoungModulusPa, forceFieldParameters.PoissonRatio);
%         titleStr1 = {titleStr1_1, titleStr1_2};
%     catch
%         titleStr1 = '';
%     end
%     titleStr1{end+1} = 'Regularization parameter (reg_corner_raw) is calculated for each frame';
%         % _________ Plot 1: Traction Forces: 
% 
%     figHandleAllTraction = figure('visible',showPlot, 'color', 'w');     % added by WIM on 2019-02-07. To show, remove 'visible    
%     set(figHandleAllTraction, 'Position', [275, 435, 825, 775])
%     pause(0.1)          % give some time so that the figure loads well    
%     subplot(3,1,1)
%     plot(TimeStampsRT_EPI(FramesPlotted), ConversionNtoNN * ForceN(FramesPlotted, 3), 'r.-', 'LineWidth', 1, 'MarkerSize', 2)
%     xlim([0, TimeStampsRT_EPI(LastFramePlotted)]);
%     title(titleStr1, 'interpreter', 'none');
%     set(findobj(gcf,'type', 'axes'), ...
%         'FontSize',11, ...
%         'FontName', 'Helvetica', ...
%         'LineWidth',1, ...
%         'XMinorTick', 'on', ...
%         'YMinorTick', 'on', ...
%         'TickDir', 'out', ...
%         'TitleFontSizeMultiplier', 0.9, ...
%         'TitleFontWeight', 'bold');     % Make axes bold
%     ylabel('\bf|\itF\rm(\itt\rm)\bf|\rm [nN]', 'FontName', PlotsFontName);    
%     hold on    
%     subplot(3,1,2)
%     plot(TimeStampsRT_EPI(FramesPlotted), ConversionNtoNN * ForceN(FramesPlotted, 1), 'r.-', 'LineWidth', 1, 'MarkerSize', 2)
%     xlim([0, TimeStampsRT_EPI(LastFramePlotted)]);
%     set(findobj(gcf,'type', 'axes'), ...
%         'FontSize',11, ...
%         'FontName', 'Helvetica', ...
%         'LineWidth',1, ...
%         'XMinorTick', 'on', ...
%         'YMinorTick', 'on', ...
%         'TickDir', 'out', ...
%         'TitleFontSizeMultiplier', 0.9, ...
%         'TitleFontWeight', 'bold');     % Make axes bold    
%     ylabel('\bf\itF_{x}\rm(\itt\rm) [nN]', 'FontName', PlotsFontName);    
%     % Flip to Cartesian Coordinates in the Plot (Negative pointing downwards). Add a negative Sign before plot. 
%     subplot(3,1,3)
%     plot(TimeStampsRT_EPI(FramesPlotted), - ConversionNtoNN * ForceN(FramesPlotted, 2), 'r.-', 'LineWidth', 1, 'MarkerSize', 2)       % Flip the y-coordinates to Cartesian
%     xlim([0, TimeStampsRT_EPI(LastFramePlotted)]);
%     set(findobj(gcf,'type', 'axes'), ...
%         'FontSize',11, ...
%         'FontName', 'Helvetica', ...
%         'LineWidth',1, ...
%         'XMinorTick', 'on', ...
%         'YMinorTick', 'on', ...
%         'TickDir', 'out', ...
%         'TitleFontSizeMultiplier', 0.9, ...
%         'TitleFontWeight', 'bold');     % Make axes bold  
%     xlabelHandle = xlabel(sprintf('\\rm %s', xLabelTime));
%     set(xlabelHandle, 'FontName', PlotsFontName)
%     ylabel('\bf\itF_{y}\rm(\itt\rm) [nN]', 'FontName', PlotsFontName);    
% % 2.__________________
%     figHandleEnergy = figure('visible',showPlot, 'color', 'w');     % added by WIM on 2019-02-07. To show, remove 'visible    
%     set(figHandleEnergy, 'Position', [275, 435, 825, 375])
%     plot(TimeStampsRT_EPI(FramesPlotted), TractionEnergyJ(FramesPlotted) * ConversionJtoFemtoJ, 'r.-', 'LineWidth', 1, 'MarkerSize', 2)
%     xlim([0, TimeStampsRT_EPI(LastFramePlotted)]);
%     title(titleStr1, 'interpreter', 'none');
%     set(findobj(gcf,'type', 'axes'), ...
%         'FontSize',11, ...
%         'FontName', 'Helvetica', ...
%         'LineWidth',1, ...
%         'XMinorTick', 'on', ...
%         'YMinorTick', 'on', ...
%         'TickDir', 'out', ...
%         'TitleFontSizeMultiplier', 0.9, ...
%         'TitleFontWeight', 'bold');     % Make axes bold  
%     xlabelHandle = xlabel(sprintf('\\rm %s', xLabelTime));
%     set(xlabelHandle, 'FontName', PlotsFontName)
%     ylabel('\itU\rm(\itt\rm) [fJ]', 'FontName', PlotsFontName);
% 
% %     disp('**___to continue, type "dbcont" or press "F5", or click "Continue" under "Editor" Menu___**')
% %     keyboard
% %       Saving the plots
%     for CurrentPlotType = 1:numel(PlotChoice)
%         tmpPlotChoice =  PlotChoice{CurrentPlotType};
%         switch tmpPlotChoice
%             case 'FIG'
%                 if exist(TractionForcePath,'dir') 
%                     AnalysisFileNameFIG1 = sprintf('E_%0.2gPa_TractionForce_Raw.fig', forceFieldParameters.YoungModulusPa);
%                     AnalysisTractionForceFIG1 = fullfile(TractionForcePath, AnalysisFileNameFIG1);                    
%                     savefig(figHandleAllTraction, AnalysisTractionForceFIG1,'compact')    
%                     
%                     AnalysisFileNameFIG3 = sprintf('E_%0.2gPa_TractionEnergy_Raw.fig', forceFieldParameters.YoungModulusPa);
%                     AnalysisTractionForceFIG3 = fullfile(TractionForcePath, AnalysisFileNameFIG3);                    
%                     savefig(figHandleEnergy, AnalysisTractionForceFIG3,'compact')            
%                       
%                 end
%                 
%             case 'PNG'                  % PNG SAVE. Consider replacing TIF to PNG.  %                 saveas(figFluxV, figureFileNames{2,1}, 'png');               
%                 if exist(TractionForcePath,'dir') 
%                     AnalysisFileNamePNG1 = sprintf('E_%0.2gPa_TractionForce_Raw.png', forceFieldParameters.YoungModulusPa);
%                     AnalysisTractionForcePNG1 = fullfile(TractionForcePath, AnalysisFileNamePNG1);
%                     saveas(figHandleAllTraction, AnalysisTractionForcePNG1, 'png');
% 
%                     AnalysisFileNamePNG3 = sprintf('E_%0.2gPa_TractionEnergy_Raw.png', forceFieldParameters.YoungModulusPa);
%                     AnalysisTractionForcePNG3 = fullfile(TractionForcePath, AnalysisFileNamePNG3);
%                     saveas(figHandleEnergy, AnalysisTractionForcePNG3, 'png');                    
%                 end
%                 
%             case 'EPS'
%                 if exist(TractionForcePath,'dir') 
%                     AnalysisFileNameEPS1 = sprintf('E_%0.2gPa_TractionForce_Raw.eps', forceFieldParameters.YoungModulusPa);
%                     AnalysisTractionForceEPS1 = fullfile(TractionForcePath, AnalysisFileNameEPS1);                                     
%                     print(figHandleAllTraction, AnalysisTractionForceEPS1,'-depsc')
% 
%                     AnalysisFileNameEPS3 = sprintf('E_%0.2gPa_TractionEnergy_Raw.eng', forceFieldParameters.YoungModulusPa);
%                     AnalysisTractionForceEPS3 = fullfile(TractionForcePath, AnalysisFileNameEPS3);                                     
%                     print(figHandleEnergy, AnalysisTractionForceEPS3,'-depsc')                                
%                 end
%             otherwise
%                  return
%         end    
%     end
%     close all
% 
% %% =============================== Step #8 Average those Regularization Parameters or Not?
% %     dlgQuestion = 'How do you want to average the raw regularization parameters by mean(log10())?';
% %     dlgTitle = 'Regularization parameters method?';
% %     CalculateRegParamMethod = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No', 'Yes'); 
% 
%     CalculateRegParamMethod = 'Yes';
%     disp('Averaging regularization parameters by mean(log10())')
%     
%     if strcmpi(CalculateRegParamMethod, 'Yes')  
%     % Bin the displacement based on flux status for controlled-force experiments, by averaging 10^(mean(log10(reg_corner(cycle ON/OFF)))
%     % based on displacement motion status for controlled-displacement experiments.
% 
%         [reg_corner_averaged, TransientRegParamMethod] = RegCornerBinAndAverage(reg_corner_raw, FluxON, FluxOFF, FluxTransient, FramesDoneNumbers, TransientRegParamMethod);
%         reg_corner_averagedON = reg_corner_averaged(FluxON(1));
%         if isempty(reg_corner_averagedON), reg_corner_averagedON = nan;end
%         
%         reg_corner_averagedOFF = reg_corner_averaged(FluxOFF(1));
%         if isempty(reg_corner_averagedOFF), reg_corner_averagedOFF = nan;end
%         
%         % Plot 3. Regularization Parameters_______________________________
%         titleStr3 = {titleStr1_1, titleStr1_2, sprintf('Regularization Method: %s', reg_cornerChoiceStr)};
%      
%         figHandleRegParams = figure('visible',showPlot, 'color', 'w');     % added by WIM on 2019-02-07. To show, remove 'visible    
%         set(figHandleRegParams, 'Position', [100, 100, 825, 600])
% 
%         sub1 = subplot(2,1,1);
%         plot(TimeStampsRT_EPI(FramesPlotted), reg_corner_averaged(FramesPlotted), 'r.-', 'LineWidth', 1, 'MarkerSize', 2)
%         hold on
%         if strcmpi(CalculateRegParamMethod, 'Yes')
%             plot(TimeStampsRT_EPI(FramesPlotted), reg_corner_raw(FramesPlotted), 'b.-', 'LineWidth', 1, 'MarkerSize', 2)
%             legend(sprintf('ON mean = %0.5f.\nOFF mean = %0.5f', reg_corner_averagedON,  reg_corner_averagedOFF), 'Raw Parameters','location', 'best')
%         end
%         xlim([0, TimeStampsRT_EPI(LastFramePlotted)]);
%         xlabel(sprintf('\\rm %s', xLabelTime));
%         ylabel('Reg. param.');  
%         title(titleStr3, 'interpreter', 'none');
%         set(findobj(gcf,'type', 'axes'), ...
%             'FontSize',11, ...
%             'FontName', 'Helvetica', ...
%             'LineWidth',1, ...
%             'XMinorTick', 'on', ...
%             'YMinorTick', 'on', ...
%             'TickDir', 'out', ...
%             'TitleFontSizeMultiplier', 0.9, ...
%             'TitleFontWeight', 'bold');     % Make axes bold       
%         hold on
%         sub2 = subplot(2,1,2);
%         plot(TimeStampsRT_EPI(FramesPlotted), log10(reg_corner_averaged(FramesPlotted)), 'r.-', 'LineWidth', 1, 'MarkerSize', 2)
%         hold on
%         if strcmpi(CalculateRegParamMethod, 'Yes')
%             plot(TimeStampsRT_EPI(FramesPlotted), log10(reg_corner_raw(FramesPlotted)), 'b.-', 'LineWidth', 1, 'MarkerSize', 2)
%             legend(sprintf('ON mean = %0.5f.\nOFF mean = %0.5f', reg_corner_averagedON,  reg_corner_averagedOFF), 'Raw Parameters', ...
%                 'location', 'best')
%         end
%         xlim([0, TimeStampsRT_EPI(LastFramePlotted)]);
%         ylabel('\itlog_{10}\rm(Reg. param.)\rm');  
%         xlabel(sprintf('\\rm %s', xLabelTime));
%             set(findobj(gcf,'type', 'axes'), ...
%             'FontSize',11, ...
%             'FontName', 'Helvetica', ...
%             'LineWidth',1, ...
%             'XMinorTick', 'on', ...
%             'YMinorTick', 'on', ...
%             'TickDir', 'out', ...
%             'TitleFontSizeMultiplier', 0.9, ...
%             'TitleFontWeight', 'bold');     % Make axes bold        
%             
%     % Saving the plots    
%         for CurrentPlotType = 1:numel(PlotChoice)
%             tmpPlotChoice =  PlotChoice{CurrentPlotType};
%             switch tmpPlotChoice
%                 case 'FIG'
%                     if exist(TractionForcePath,'dir') 
%                         AnalysisFileNameFIG7 = sprintf('E_%0.2gPa_Regularization_Parameters.fig', forceFieldParameters.YoungModulusPa);
%                         AnalysisTractionForceFIG7 = fullfile(TractionForcePath, AnalysisFileNameFIG7);                    
%                         savefig(figHandleRegParams, AnalysisTractionForceFIG7,'compact')    
%                     end
% 
%                 case 'PNG'                  % PNG SAVE. Consider replacing TIF to PNG.  %                 saveas(figFluxV, figureFileNames{2,1}, 'png');               
%                     if exist(TractionForcePath,'dir')                     
%                         AnalysisFileNamePNG7 = sprintf('E_%0.2gPa_Regularization_Parameters.png', forceFieldParameters.YoungModulusPa);
%                         AnalysisTractionForcePNG7 = fullfile(TractionForcePath, AnalysisFileNamePNG7);
%                         saveas(figHandleRegParams, AnalysisTractionForcePNG7, 'png');
%                     end
% 
%                 case 'EPS'
%                     if exist(TractionForcePath,'dir')                     
%                         AnalysisFileNameEPS7 = sprintf('E_%0.2gPa_Regularization_Parameters.eps', forceFieldParameters.YoungModulusPa);
%                         AnalysisTractionForceEPS7 = fullfile(TractionForcePath, AnalysisFileNameEPS7);                                     
%                         print(figHandleRegParams, AnalysisTractionForceEPS7,'-depsc')
%                     end
%                 otherwise
%                      return
%             end
%         end
%         close all
%         
% %% Step #9 Second round of finding all but regularization parameter using TFM_MasterSolver. 
%         [pos_grid, displFieldNoFilteredGrid, displFieldFilteredGrid, forceField, energyDensityField, ForceN, TractionEnergyJ, ~, ~, ~] = ...
%             TFM_MasterSolver(displField, NoiseROIsCombined, forceFieldParameters, reg_corner_averaged, ...
%             gridMagnification, EdgeErode, PaddingChoiceStr, SpatialFilterChoiceStr, HanWindowChoice, ...
%             GridtypeChoiceStr, reg_cornerChoiceStr, InterpolationMethod, TractionStressMethod, ForceIntegrationMethod, ...
%             WienerWindowSize, ScaleMicronPerPixel, ShowOutput, FirstFrame, LastFrame, CornerPercentage);
%         % Append Other Outputs
% %         
% %         [pos_grid, displFieldNoFilteredGrid, displFieldFilteredGrid, forceField, energyDensityField, ForceN, TractionEnergyJ, ~, ~, ~] = ...
% %             TFM_MasterSolver(displField, NoiseROIsCombined, forceFieldParameters, reg_corner_averaged, ...
% %             gridMagnification, EdgeErode, PaddingChoiceStr, SpatialFilterChoiceStr, HanWindowChoice, ...
% %             GridtypeChoiceStr, reg_cornerChoiceStr, InterpolationMethod, TractionStressMethod, ForceIntegrationMethod, ...
% %             WienerWindowSize, ScaleMicronPerPixel, ShowOutput, FirstFrame, LastFrame, CornerPercentage);
% 
%         disp('Saving TFM Analysis Output')
%         displField = displFieldNoFilteredGrid; 
%         TimeStamps = TimeStampsRT_Abs_EPI;
%         displFieldNoFilteredGridFullFileName = fullfile(displFieldPath, 'displField_GridNoSpatialFilter_Averaged.mat');
%         Notes = 'Units of "displFieldNoFilteredGrid" = pixels. Averaged displacement output. No Spatial Filter, or Han Windowing. (displFieldNoFilteredGrid)';
%         save(displFieldNoFilteredGridFullFileName, 'MD_EPI', 'displField', 'TimeStamps','Notes', 'TimeFilterChoiceStr', ...
%             'EdgeErode',  'gridMagnification', 'GridtypeChoiceStr', 'InterpolationMethod', 'DriftCorrectionChoiceStr', 'ScaleMicronPerPixel', '-v7.3')
% 
%         displField = displFieldFilteredGrid;
%         displFieldFilteredGridFullFileName = fullfile(displFieldPath, 'displField_GridWithSpatialFilter_Averaged.mat');
%         Notes = 'Units of "displFieldFilteredGrid" = pixels. Averaged displacement output. Wiener2D Spatial Filter, & Han Windowing.';
%         save(displFieldFilteredGridFullFileName, 'MD_EPI', 'displField', 'TimeStamps','Notes', 'TimeFilterChoiceStr', ...
%              'EdgeErode',  'gridMagnification', 'GridtypeChoiceStr', 'InterpolationMethod','DriftCorrectionChoiceStr', 'ScaleMicronPerPixel', ...
%              'SpatialFilterChoiceStr', 'WienerWindowSize', 'HanWindowChoice', '-v7.3')
% 
%          
%         sprintf('E_%0.2gPa_TractionEnergy_Averaged.mat', forceFieldParameters.YoungModulusPa);
% %-----------         
%         forceFieldFullFileName = fullfile(TractionForcePath, ...
%             sprintf('E_%0.2gPa_TractionField_PlusRegCorner_Averaged.mat', forceFieldParameters.YoungModulusPa));   
%         Notes = 'Units of "forceField" = Pa. Actually traction stress, or T. Regularization parameters included.';
%         save(forceFieldFullFileName, 'MD_EPI', 'forceField', 'TimeStamps', 'CornerPercentage','Notes', ...
%             'TransientRegParamMethod', 'FluxON', 'FluxOFF', 'FluxTransient', 'reg_corner_averaged', ...
%             'reg_cornerChoiceStr', 'TractionStressMethod', 'PaddingChoiceStr', 'HanWindowChoice', 'forceFieldParameters', 'CalculateRegParamMethod', '-v7.3')
% 
%         TractionForceFullFileName = fullfile(TractionForcePath, sprintf('E_%0.2gPa_TractionForce_Averaged.mat', forceFieldParameters.YoungModulusPa));   
%         Notes = 'Units of "Force, or Traction Force over the entire area, or F" = N. [x,y,norm]';
%         save(TractionForceFullFileName, 'MD_EPI', 'ForceN', 'TimeStamps','Notes', 'ForceIntegrationMethod', '-v7.3')
% 
%         Notes = 'Units of "energyField, or Storage Elastic Energy Density, or Sigma" = J/m^2. ';
%         energyDensityFullFileName = fullfile(TractionForcePath, ...
%             sprintf('E_%0.2gPa_EnergyDensity_Averaged.mat', forceFieldParameters.YoungModulusPa));
%         save(energyDensityFullFileName, 'MD_EPI', 'energyDensityField', 'TimeStamps', 'Notes','-v7.3')
% 
%         Notes = 'Units of "ElasticTractionEnergy, or or U" = J. ';
%         TractionEnergyFullFileName = fullfile(TractionForcePath, ...
%             sprintf('E_%0.2gPa_TractionEnergy_Averaged.mat', forceFieldParameters.YoungModulusPa));    
%         save(TractionEnergyFullFileName, 'MD_EPI', 'TractionEnergyJ', 'TimeStamps', 'Notes', '-v7.3')
%         disp('TFM Analysis Output saved!')
%         
%     %% Step #9 Plot the second round right here         
%         titleStr4 = {titleStr1_1, titleStr1_2, 'Regularization parameters are binned and averaged (ON vs. OFF)'};    
%         
%         ConversionNtoNN = 1e9;  
%         ConversionJtoFemtoJ = 1e15;
% 
%         FramesPlotted(FramesDoneNumbers) = ~isnan(ForceN(FramesDoneNumbers));
%         LastFramePlotted = FramesDoneNumbers(end);
%         PlotsFontName = 'Helvatica-Narrow';
%         xLabelTime = 'Time [s]';
% 
%         %_________ Plot 1: 
%         showPlot = 'on';
%         figHandleAllTraction = figure('visible',showPlot, 'color', 'w');     % added by WIM on 2019-02-07. To show, remove 'visible    
%         set(figHandleAllTraction, 'Position', [275, 435, 825, 775])
%         pause(0.1)          % give some time so that the figure loads well    
%         subplot(3,1,1)
%         plot(TimeStampsRT_EPI(FramesPlotted), ConversionNtoNN * ForceN(FramesPlotted, 3), 'r.-', 'LineWidth', 1, 'MarkerSize', 2)
%         xlim([0, TimeStampsRT_EPI(LastFramePlotted)]);
%         title(titleStr4, 'interpreter', 'none');
%         set(findobj(gcf,'type', 'axes'), ...
%             'FontSize',11, ...
%             'FontName', 'Helvetica', ...
%             'LineWidth',1, ...
%             'XMinorTick', 'on', ...
%             'YMinorTick', 'on', ...
%             'TickDir', 'out', ...
%             'TitleFontSizeMultiplier', 0.9, ...
%             'TitleFontWeight', 'bold');     % Make axes bold
%         ylabel('\bf|\itF\rm(\itt\rm)\bf|\rm [nN]', 'FontName', PlotsFontName);    
%         hold on    
%         subplot(3,1,2)
%         plot(TimeStampsRT_EPI(FramesPlotted), ConversionNtoNN * ForceN(FramesPlotted, 1), 'r.-', 'LineWidth', 1, 'MarkerSize', 2)
%         xlim([0, TimeStampsRT_EPI(LastFramePlotted)]);
%         set(findobj(gcf,'type', 'axes'), ...
%             'FontSize',11, ...
%             'FontName', 'Helvetica', ...
%             'LineWidth',1, ...
%             'XMinorTick', 'on', ...
%             'YMinorTick', 'on', ...
%             'TickDir', 'out', ...
%             'TitleFontSizeMultiplier', 0.9, ...
%             'TitleFontWeight', 'bold');     % Make axes bold    
%         ylabel('\bf\itF_{x}\rm(\itt\rm) [nN]', 'FontName', PlotsFontName);    
%         % Flip to Cartesian Coordinates in the Plot (Negative pointing downwards). Add a negative Sign before plot. 
%         subplot(3,1,3)
%         plot(TimeStampsRT_EPI(FramesPlotted), - ConversionNtoNN * ForceN(FramesPlotted, 2), 'r.-', 'LineWidth', 1, 'MarkerSize', 2)       % Flip the y-coordinates to Cartesian
%         xlim([0, TimeStampsRT_EPI(LastFramePlotted)]);
%         set(findobj(gcf,'type', 'axes'), ...
%             'FontSize',11, ...
%             'FontName', 'Helvetica', ...
%             'LineWidth',1, ...
%             'XMinorTick', 'on', ...
%             'YMinorTick', 'on', ...
%             'TickDir', 'out', ...
%             'TitleFontSizeMultiplier', 0.9, ...
%             'TitleFontWeight', 'bold');     % Make axes bold  
%         xlabelHandle = xlabel(sprintf('\\rm %s', xLabelTime));
%         set(xlabelHandle, 'FontName', PlotsFontName)
%         ylabel('\bf\itF_{y}\rm(\itt\rm) [nN]', 'FontName', PlotsFontName);    
%     % 2.__________________
%         figHandleEnergy = figure('visible',showPlot, 'color', 'w');     % added by WIM on 2019-02-07. To show, remove 'visible    
%         set(figHandleEnergy, 'Position', [275, 435, 825, 375])
%         plot(TimeStampsRT_EPI(FramesPlotted), TractionEnergyJ(FramesPlotted) * ConversionJtoFemtoJ, 'r.-', 'LineWidth', 1, 'MarkerSize', 2)
%         xlim([0, TimeStampsRT_EPI(LastFramePlotted)]);
%         title(titleStr4, 'interpreter', 'none');
%         set(findobj(gcf,'type', 'axes'), ...
%             'FontSize',11, ...
%             'FontName', 'Helvetica', ...
%             'LineWidth',1, ...
%             'XMinorTick', 'on', ...
%             'YMinorTick', 'on', ...
%             'TickDir', 'out', ...
%             'TitleFontSizeMultiplier', 0.9, ...
%             'TitleFontWeight', 'bold');     % Make axes bold  
%         xlabelHandle = xlabel(sprintf('\\rm %s', xLabelTime));
%         set(xlabelHandle, 'FontName', PlotsFontName)
%         ylabel('\itU\rm(\itt\rm) [fJ]', 'FontName', PlotsFontName);
% % 
% %         disp('**___to continue, type "dbcont" or press "F5", or click "Continue" under "Editor" Menu___**')
% %         keyboard
% 
%     % Saving the plots
%        for CurrentPlotType = 1:numel(PlotChoice)
%             tmpPlotChoice =  PlotChoice{CurrentPlotType};
%             switch tmpPlotChoice
%                 case 'FIG'
%                     if exist(TractionForcePath,'dir') 
%                         
%                         AnalysisFileNameFIG1 = sprintf('E_%0.2gPa_TractionForce_Averaged.fig', forceFieldParameters.YoungModulusPa);
%                         AnalysisTractionForceFIG1 = fullfile(TractionForcePath, AnalysisFileNameFIG1);                    
%                         savefig(figHandleAllTraction, AnalysisTractionForceFIG1,'compact')    
% 
%                         AnalysisFileNameFIG3 = sprintf('E_%0.2gPa_TractionEnergy_Averaged.fig', forceFieldParameters.YoungModulusPa);
%                         AnalysisTractionForceFIG3 = fullfile(TractionForcePath, AnalysisFileNameFIG3);                    
%                         savefig(figHandleEnergy, AnalysisTractionForceFIG3,'compact')                    
% 
%                     end
% 
%                 case 'PNG'                  % PNG SAVE. Consider replacing TIF to PNG.  %                 saveas(figFluxV, figureFileNames{2,1}, 'png');               
%                     if exist(TractionForcePath,'dir') 
%                         AnalysisFileNamePNG1 = sprintf('E_%0.2gPa_TractionForce_Averaged.png', forceFieldParameters.YoungModulusPa);
%                         AnalysisTractionForcePNG1 = fullfile(TractionForcePath, AnalysisFileNamePNG1);
%                         saveas(figHandleAllTraction, AnalysisTractionForcePNG1, 'png');
% 
%                         AnalysisFileNamePNG3 = sprintf('E_%0.2gPa_TractionEnergy_Averaged.png', forceFieldParameters.YoungModulusPa);
%                         AnalysisTractionForcePNG3 = fullfile(TractionForcePath, AnalysisFileNamePNG3);
%                         saveas(figHandleEnergy, AnalysisTractionForcePNG3, 'png');                    
%                     end
% 
%                 case 'EPS'
%                     if exist(TractionForcePath,'dir') 
%                         AnalysisFileNameEPS1 = sprintf('E_%0.2gPa_TractionForce_Averaged.eps', forceFieldParameters.YoungModulusPa);
%                         AnalysisTractionForceEPS1 = fullfile(TractionForcePath, AnalysisFileNameEPS1);                                     
%                         print(figHandleAllTraction, AnalysisTractionForceEPS1,'-depsc')
% 
%                         AnalysisFileNameEPS3 = sprintf('E_%0.2gPa_TractionEnergy_Averaged.eps', forceFieldParameters.YoungModulusPa);             
%                         AnalysisTractionForceEPS3 = fullfile(TractionForcePath, AnalysisFileNameEPS3);                                     
%                         print(figHandleEnergy, AnalysisTractionForceEPS3,'-depsc')                                
%                     end
%                 otherwise
%                      return
%             end    
%        end
%        close all
%        
%     end