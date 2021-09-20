%{
    v.2020-07-17 by Waddah Moghram, PhD candidate in biomedical engineering at the University of Iowa
        1. Added segments to save the following figures: Traction Forces, Traction Handles
    v.2020-07-11 by Waddah Moghram
        1. By passing the whole filtering process?
    v.2020-07-04...05 by Waddah Moghram
    . This is script is a reduced version of VideoAnalysisEPI.m 
%}

%% Step #0 initial variables.
    EdgeErode = 1;                                      % do not change to 0. Update 2020-01-29
    gridMagnification = 1;
    ForceIntegrationMethod = 'Summed';
    TractionStressMethod = 'FTTC';   
    GridtypeChoiceStr = 'Even Grid';

    reg_cornerChoiceStr = 'Optimized Bayesian L2 (BL2)'; 
    InterpolationMethod = 'griddata';                   % vs. InterpolationMethod = 'scatteredinterpolant';
    
    ShowOutput = true;
    SpatialFilterChoiceStr = 'Wiener 2D';    
    WienerWindowSize = [3, 3];         % 3x3 pixels
    CornerPercentage = 0.1;
    AnalysisPathEPI = [];
    MagX = 30;                          % 20X object * 1.5 eyepiece zoom

%% Step #1 Open the EPI file
    choiceOpenND2EPI = 'Yes';
    switch choiceOpenND2EPI    
        case 'Yes'
            disp('Opening the EPI ND2 Video File to get path and filename info to be analyzed')
            [ND2fileEPI, ND2pathEPI] = uigetfile('*.nd2', 'EPI ND2 video file');    
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

    PlotSensorDataEPIChoiceStr = 'Yes';

    if isempty(PlotSensorDataEPIChoiceStr), return; end
    switch PlotSensorDataEPIChoiceStr
        case 'Yes'
            PlotSensorEPIData = 1;
        case 'No'
            PlotSensorEPIData = 0;
        otherwise
            PlotSensorEPIData = 0;
    end

    SensorDataEPIFullFileName = fullfile(ND2PathNameEPI, strcat(ND2FileNameEPI, '.dat'));
    SensorOutputPath_EPI = fullfile(OutputPathNameEPI, 'Sensor_Signals');
    try
        mkdir(SensorOutputPath_EPI)
    catch

    end
    % ----------------- reading sensor data 
    [SensorDataEPI, HeaderDataEPI, HeaderTitleEPI, SensorDataFullFilenameEPI, SensorOutputPathNameEPI, ~, SamplingRate, SensorDataEPIColumns]  = ReadSensorDataFile(SensorDataEPIFullFileName, PlotSensorEPIData, SensorOutputPath_EPI, AnalysisPathEPI, 8, 'No');   
    close all
    % Cleaning the sensor data.
    [CleanSensorDataEPI , ExposurePulseCountEPI, EveryNthFrameEPI, CleanedSensorDataFullFileName_EPI, HeaderDataEPI, HeaderTitleEPI, FirstExposurePulseIndexEPI] = CleanSensorDataFile(SensorDataEPI, 1, SensorDataFullFilenameEPI, SamplingRate, HeaderDataEPI, HeaderTitleEPI, SensorDataEPIColumns);
    %{
        Do not forget to reduce the frames of the cleaned sensor data to match the reduce frame number in the accompanying video 
    %}

%%
    [ScaleMicronPerPixel, MagnificationTimesStr, MagnificationTimes, NumAperture] = MagnificationScalesMicronPerPixel(MagX);

%% ================= 5.0  Create timestamps from the sensor data file instead of through that in the video metadata.
    [TimeStampsRT_Abs_EPI] = TimestampRTfromSensorData(CleanSensorDataEPI, SamplingRate, HeaderDataEPI, HeaderTitleEPI, CleanedSensorDataFullFileName_EPI, FirstExposurePulseIndexEPI);
    [TimeStampsND2_EPI, LastFrameND2, AverageTimeIntervalND2] = ND2TimeFrameExtract(ND2fullFileNameEPI);

%% ----------------- 4.0 create TFM output path & MOvie Data File
    TFM_OutputPath = fullfile(OutputPathNameEPI, 'TFM_Output');
    MD_EPI = bfImport(ND2fullFileNameEPI, 'outputDirectory', TFM_OutputPath, 'askUser', 0);

    MD_EPI.numAperture_ = NumAperture;

    [SensorDataEPIPathName, SensorDataEPIFileName, ~] = fileparts(SensorDataEPIFullFileName);
    SensorDataEPINotesFileName = fullfile(SensorDataEPIPathName, strcat(SensorDataEPIFileName, '_Notes.txt'));
    NotesEPI = fileread(SensorDataEPINotesFileName);
    NotesWordsEPI = split(NotesEPI, ' ');             % split by white space

    MD_EPI.notes_ = NotesEPI;
    MD_EPI.magnification_ = MagnificationTimes;
    MD_EPI.timeInterval_ = AverageTimeIntervalND2;
    MD_EPI.channels_.emissionWavelength_;                   % 
    MD_EPI.channels_.excitationWavelength_ = 560;           % nm for texas red;
    MD_EPI.channels_.excitationType_ = 'Widefield';         % Widefield Fluorescence.
    MD_EPI.channels_.exposureTime_ = AverageTimeIntervalND2; % in seconds
    MD_EPI.channels_.fluorophore_ = 'TexasRed';

%     AcquisitionDateEPIStr = split(NotesWordsEPI{6}, '/');
%     AcquisitionTimeStr = split(NotesWordsEPI{8}, ':');
%     MonthNameEPI = month(datetime(1, str2num(AcquisitionDateEPIStr{1}),1), 'name');
%     MonthNameEPI = MonthNameEPI{1};
%     
%     AcquisitionDateEPI = [MonthNameEPI, ' ', AcquisitionDateEPIStr{2}, ', ' AcquisitionDateEPIStr{3}]; 
%     MD_EPI.acquisitionDate_ = NotesWordsEPI{6};
%     
%% Creating the reference frame from the first frame and saving it
    RefFrameEPI = MD_EPI.channels_.loadImage(1);
    RefFramePathEPI =  fullfile(TFM_OutputPath, 'ReferenceFirstFrame.tif');
    imwrite(RefFrameEPI, RefFramePathEPI, 'TIFF')
    
%% Construct the TFM package
    packageName = 'TFMPackage';
    packageConstr = str2func(packageName);
   % Add package to movie
    packageIndx = MD_EPI.getPackageIndex(packageName,1,true);
    MD_EPI.addPackage(packageConstr(MD_EPI, MD_EPI.outputDirectory_));  
    
%% Setup epi beads reference frame, tracking parameters, and output path
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
    
    %% Determining the Corners COORDINATES BUT NEED TO FIND THE PSF SIGMA EXTERNALLY
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
    
%% Creating a rectangular grid based on bead locations
    [reg_grid,~,~,gridSpacing] = createRegGridFromDisplField(localbeads, 2, displacementParameters.noFlowOutwardOnBorder);
    % Edge Erode to make it a square grid 
    gridXmin = min(unique(reg_grid(:,:,1)));
    gridXmax = max(unique(reg_grid(:,:,1)));
    gridYmin = min(unique(reg_grid(:,:,2)));
    gridYmax = max(unique(reg_grid(:,:,2)));    
    
    % At this point you can correct for displacement drift in DIC modes.
 
%% Calculating the EPI displacement
    calculateMovieDisplacementField(MD_EPI, displacementParameters)

%% Correct displacements for spatial outliers
    CorrectionfunParams.doRogReg = 0;               % No rotational adjustments for drift
    CorrectionfunParams.outlierThreshold = 2;
    CorrectionfunParams.fillVectors = 0;

    correctMovieDisplacementField(MD_EPI, CorrectionfunParams)

%% Step #2 Process the displacements as required. Ask if you want to process the displacements. Yes/No. Othewrise, just load it.
    % Do you want to process them? Case Yes?    
    [movieData, displField, TimeStampsRT_EPI, AnalysisPathEPI, ScaleMicronPerPixel, FramesDoneNumbers, controlMode, ...
        rect, DriftROIs, DriftROIsCombined, reg_grid, gridSpacing, NoiseROIs, NoiseROIsCombined, TimeFilterChoiceStr, ...
        DriftCorrectionChoiceStr, displacementFileFullName] = ...
            ProcessTrackedDisplacementTFM([], [], [], [], gridMagnification, EdgeErode, GridtypeChoiceStr, ...
                InterpolationMethod, ShowOutput, [], []);

% % Doubled Checked by running the code again. The maximum difference in  NoiseROIsCombined was:
% %         [-3.33066907387547e-16, 0, 3.40005801291454e-16]
%     [~, ~, ~, ~, ~, ~, ~, NoiseROIsCombined] = ...
%         DisplacementDriftCorrectionIdenticalCorners(displField, CornerPercentage, FramesDoneNumbers, gridMagnification, ...
%         EdgeErode, GridtypeChoiceStr, InterpolationMethod, ShowOutput);       
    % Caes No. 
        % Call the same function, but without any processing. Just to return timestamps and all the other information.         
    
%% Step #3 Read Sensor Data & Clean it up    
    switch controlMode 
        case 'Controlled Force'
            dlgQuestion = 'Do you want to clean the LabVIEW Sensor Data for the controlled-force experiment? ';
            dlgTitle = 'Clean up LabVIEW Data?';
            CleanUpLabVIEWDataChoice = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No', 'Yes');
            if isempty(CleanUpLabVIEWDataChoice), error('Need to answer this question');  end
            switch CleanUpLabVIEWDataChoice
                case 'Yes'
                    % Loading ther sensor data for controlled force mode.
                    dlgQuestion = ({'In addition to reading sensor data. Do you want to plot the sensor data'});
                    dlgTitle = 'Plot sensor data (i.e., Magnetic Flux, Current and Camera Exposure?';
                    PlotSensorDataEPIChoiceStr = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No', 'No');
                    if isempty(PlotSensorDataEPIChoiceStr), return; end
                    switch PlotSensorDataEPIChoiceStr
                        case 'Yes'
                            PlotSensorEPIData = 1;
                        case 'No'
                            PlotSensorEPIData = 0;
                        otherwise
                            PlotSensorEPIData = 0;
                    end
                    [SensorDataEPI, HeaderDataEPI, HeaderTitleEPI, SensorDataFullFilenameEPI, OutputPathNameEPI, ~, SamplingRate]  = ReadSensorDataFile(movieData.getPath, PlotSensorEPIData, AnalysisPathEPI);   
                    % Cleaning the sensor data.
                    [CleanSensorDataEPI , ExposurePulseCountEPI, EveryNthFrameEPI, CleanedSensorDataFullFileNameMAT_EPI, ~, ~, FirstExposurePulseIndexEPI] = CleanSensorDataFile(SensorDataEPI, [], SensorDataFullFilenameEPI, SamplingRate);
                    %{
                        Do not forget to reduce the frames of the cleaned sensor data to match the reduce frame number in the accompanying video 
                    %}
                    % Added 2019-10-06. Renamed 00 to the 03 EPI.
                    SensorPlots = dir(fullfile(OutputPathNameEPI, '00 Sensor*'));
                    for ii = 1:size(SensorPlots)
                        iiName = SensorPlots(ii).name;
                        iiNameNew = replace(iiName, '00', '01 EPI');
                        movefile(fullfile(SensorPlots(ii).folder,  SensorPlots(ii).name), fullfile(SensorPlots(ii).folder,iiNameNew))
                    end
                case 'No'
                    CleanedSensorDataFullFileNameMAT_EPI = [];
                otherwise
                    return
            end               
    end
    
%% Step #4 First round of finding the individual regularization parameters for all frames. (reg_corner_raw)
    forceFieldParameters = [];
    reg_corner_raw = [];
    reg_corner = []; 
    FirstFrame = FramesDoneNumbers(1);
    LastFrame = FramesDoneNumbers(end);    
    NoiseROIsCombined = [];             % if it is not given, the NoiseROIs will be evaluated for each frame based on the interpolated grid.
    
    HanWindowchoice = 'Yes';
    PaddingChoiceStr= 'Padded with zeros only';
    [pos_grid, displFieldNoFilteredGrid, displFieldFilteredGrid, forceField, energyDensityField, ForceN, TractionEnergyJ, ...
        reg_corner_raw, forceFieldParameters, CornerPercentage] = ...
        TFM_MasterSolver(displField, NoiseROIsCombined, forceFieldParameters, reg_corner, ...
        gridMagnification, EdgeErode, PaddingChoiceStr, SpatialFilterChoiceStr, HanWindowchoice, ...
        GridtypeChoiceStr, reg_cornerChoiceStr, InterpolationMethod, TractionStressMethod, ForceIntegrationMethod, ...
        WienerWindowSize, ScaleMicronPerPixel, ShowOutput, FirstFrame, LastFrame, []);
    
%% Step #6 Ask if you want to plot any things so far
    dlgQuestion = ({'File Format(s) for images?'});
    listStr = {'PNG', 'FIG', 'EPS'};
    PlotChoice = listdlg('ListString', listStr, 'PromptString',dlgQuestion, 'InitialValue', [1, 2], 'SelectionMode' ,'multiple');  
    if isempty(PlotChoice), error('X was selected'); end
    PlotChoice = listStr(PlotChoice);                 % get the names of the string.

    ConversionNtoNN = 1e9;  
    ConversionJtoFemtoJ = 1e15;
    
    FramesPlotted(FramesDoneNumbers) = ~isnan(ForceN(FramesDoneNumbers));
    LastFramePlotted = FramesDoneNumbers(end);
    PlotsFontName = 'Helvatica-Narrow';
    xLabelTime = 'Time [s]';
    
    try
        titleStr1_1 = sprintf('%.0f \\mum-thick, %g mg/mL %s gel', forceFieldParameters.thickness/ 1000, forceFieldParameters.GelConcentrationMgMl, forceFieldParameters.GelType);
        titleStr1_2 = sprintf('Young Modulus = %g Pa. Poisson Ratio = %.2g', forceFieldParameters.YoungModulus, forceFieldParameters.PoissonRatio);
        titleStr1 = {titleStr1_1, titleStr1_2};
    catch
        titleStr1 = '';
    end
    titleStr1{end+1} = 'Reg. param. is calculated for each frame';

%_________ Plot 1: Traction Forces: 
    showPlot = 'on';
    figHandleAllTraction = figure('visible',showPlot, 'color', 'w');     % added by WIM on 2019-02-07. To show, remove 'visible    
    set(figHandleAllTraction, 'Position', [275, 435, 825, 775])
    pause(0.1)          % give some time so that the figure loads well    
    subplot(3,1,1)
    plot(TimeStampsRT_EPI(FramesPlotted), ConversionNtoNN * ForceN(FramesPlotted, 3), 'r.-', 'LineWidth', 1, 'MarkerSize', 2)
    xlim([0, TimeStampsRT_EPI(LastFramePlotted)]);
    title(titleStr1);
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
    plot(TimeStampsRT_EPI(FramesPlotted), ConversionNtoNN * ForceN(FramesPlotted, 1), 'r.-', 'LineWidth', 1, 'MarkerSize', 2)
    xlim([0, TimeStampsRT_EPI(LastFramePlotted)]);
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
    plot(TimeStampsRT_EPI(FramesPlotted), - ConversionNtoNN * ForceN(FramesPlotted, 2), 'r.-', 'LineWidth', 1, 'MarkerSize', 2)       % Flip the y-coordinates to Cartesian
    xlim([0, TimeStampsRT_EPI(LastFramePlotted)]);
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
% 2.__________________
    figHandleEnergy = figure('visible',showPlot, 'color', 'w');     % added by WIM on 2019-02-07. To show, remove 'visible    
    set(figHandleEnergy, 'Position', [275, 435, 825, 375])
    plot(TimeStampsRT_EPI(FramesPlotted), TractionEnergyJ(FramesPlotted) * ConversionJtoFemtoJ, 'r.-', 'LineWidth', 1, 'MarkerSize', 2)
    xlim([0, TimeStampsRT_EPI(LastFramePlotted)]);
    title(titleStr1);
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
    ylabel('\itU\rm(\itt\rm) [fJ]', 'FontName', PlotsFontName);

    disp('**___to continue, type "dbcont" or press "F5", or click "Continue" under "Editor" Menu___**')
    keyboard
% Saving the plots
    for CurrentPlotType = 1:numel(PlotChoice)
        tmpPlotChoice =  PlotChoice{CurrentPlotType};
        switch tmpPlotChoice
            case 'FIG'
                if exist(AnalysisPathEPI,'dir') 
                    AnalysisFileNameFIG1 = 'TractionForce_Raw.fig';
                    AnalysisTractionForceFIG1 = fullfile(AnalysisPathEPI, AnalysisFileNameFIG1);                    
                    savefig(figHandleAllTraction, AnalysisTractionForceFIG1,'compact')    
                    
                    AnalysisFileNameFIG3 = 'TractionEnergy_Raw.fig';               
                    AnalysisTractionForceFIG3 = fullfile(AnalysisPathEPI, AnalysisFileNameFIG3);                    
                    savefig(figHandleEnergy, AnalysisTractionForceFIG3,'compact')                    
                      
                end
                
            case 'PNG'                  % PNG SAVE. Consider replacing TIF to PNG.  %                 saveas(figFluxV, figureFileNames{2,1}, 'png');               
                if exist(AnalysisPathEPI,'dir') 
                    AnalysisFileNamePNG1 = 'TractionForce_Raw.png';
                    AnalysisTractionForcePNG1 = fullfile(AnalysisPathEPI, AnalysisFileNamePNG1);
                    saveas(figHandleAllTraction, AnalysisTractionForcePNG1, 'png');

                    AnalysisFileNamePNG3 = 'TractionEnergy_Raw.png';
                    AnalysisTractionForcePNG3 = fullfile(AnalysisPathEPI, AnalysisFileNamePNG3);
                    saveas(figHandleEnergy, AnalysisTractionForcePNG3, 'png');                    
                end
                
            case 'EPS'
                if exist(AnalysisPathEPI,'dir') 
                    AnalysisFileNameEPS1 = 'TractionForce_Raw.eps';                
                    AnalysisTractionForceEPS1 = fullfile(AnalysisPathEPI, AnalysisFileNameEPS1);                                     
                    print(figHandleAllTraction, AnalysisTractionForceEPS1,'-depsc')

                    AnalysisFileNameEPS3 = 'TractionEnergy_Raw.eps';             
                    AnalysisTractionForceEPS3 = fullfile(AnalysisPathEPI, AnalysisFileNameEPS3);                                     
                    print(figHandleEnergy, AnalysisTractionForceEPS3,'-depsc')                                
                end
            otherwise
                 return
        end    
    end

%% Step #8 Average those Regularization Parameters or Not?
    dlgQuestion = 'How do you want to average the raw regularization parameters by mean(log10())?';
    dlgTitle = 'Regularization parameters method?';
    CalculateRegParamMethod = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No', 'Yes');
    
    if strcmpi(CalculateRegParamMethod, 'Yes')  
    % Bin the displacement based on flux status for controlled-force experiments, by averaging 10^(mean(log10(reg_corner(cycle ON/OFF)))
    % based on displacement motion status for controlled-displacement experiments.
        switch controlMode    
            case 'Controlled Force'
                % Controlled force mode will use the Magnetic Flux reading to classify ON/OFF
                [FluxON, FluxOFF, FluxTransient, ~] = FindFluxStatusControlledForce(CleanedSensorDataFullFileNameMAT_EPI);
            case 'Controlled Displacement'
                % Cotnrolled Force mode will rely on the user to identify the beginning of the "ON" based on the displacement of the bead that is considered above average noise level.
                [FluxON, FluxOFF, FluxTransient, ~] = FindFluxStatusControlledDisplacement(movieData, displField, TimeStampsRT_EPI, FramesDoneNumbers);
        end   
        [reg_corner_averaged, TransientRegParamMethod] = RegCornerBinAndAverage(reg_corner_raw, FluxON, FluxOFF, FluxTransient, FramesDoneNumbers, []);
 
        %% Plot 3. Regularization Parameters_______________________________
        titleStr3 = {titleStr1_1, titleStr1_2, reg_cornerChoiceStr};    

        figHandleRegParams = figure('visible',showPlot, 'color', 'w');     % added by WIM on 2019-02-07. To show, remove 'visible    
        set(figHandleRegParams, 'Position', [100, 100, 825, 600])

        sub1 = subplot(2,1,1);
        plot(TimeStampsRT_EPI(FramesPlotted), reg_corner_averaged(FramesPlotted), 'r.-', 'LineWidth', 1, 'MarkerSize', 2)
        hold on
        if strcmpi(CalculateRegParamMethod, 'Yes')
            plot(TimeStampsRT_EPI(FramesPlotted), reg_corner_raw(FramesPlotted), 'b.-', 'LineWidth', 1, 'MarkerSize', 2)
            legend(sprintf('ON mean = %0.5f.\n Off mean = %0.5f', reg_corner_averaged(FluxON(1)),  reg_corner_averaged(FluxOFF(1))), 'Raw Parameters')
        end
        xlim([0, TimeStampsRT_EPI(LastFramePlotted)]);
        xlabel(sprintf('\\rm %s', xLabelTime));
        ylabel('Reg. param.');  
        title(titleStr3);
        set(findobj(gcf,'type', 'axes'), ...
            'FontSize',11, ...
            'FontName', 'Helvetica', ...
            'LineWidth',1, ...
            'XMinorTick', 'on', ...
            'YMinorTick', 'on', ...
            'TickDir', 'out', ...
            'TitleFontSizeMultiplier', 0.9, ...
            'TitleFontWeight', 'bold');     % Make axes bold       
        hold on
        sub2 = subplot(2,1,2);
        plot(TimeStampsRT_EPI(FramesPlotted), log10(reg_corner_averaged(FramesPlotted)), 'r.-', 'LineWidth', 1, 'MarkerSize', 2)
        hold on
        if strcmpi(CalculateRegParamMethod, 'Yes')
            plot(TimeStampsRT_EPI(FramesPlotted), log10(reg_corner_raw(FramesPlotted)), 'b.-', 'LineWidth', 1, 'MarkerSize', 2)
            legend(sprintf('ON mean = %0.5f.\n Off mean = %0.5f', reg_corner_averaged(FluxON(1)),  reg_corner_averaged(FluxOFF(1))), 'Raw Parameters')
        end
        xlim([0, TimeStampsRT_EPI(LastFramePlotted)]);
        ylabel('\itlog_{10}\rm(Reg. param.)\rm');  
        xlabel(sprintf('\\rm %s', xLabelTime));
            set(findobj(gcf,'type', 'axes'), ...
            'FontSize',11, ...
            'FontName', 'Helvetica', ...
            'LineWidth',1, ...
            'XMinorTick', 'on', ...
            'YMinorTick', 'on', ...
            'TickDir', 'out', ...
            'TitleFontSizeMultiplier', 0.9, ...
            'TitleFontWeight', 'bold');     % Make axes bold        
            
        disp('**___to continue, type "dbcont" or press "F5", or click "Continue" under "Editor" Menu___**')
        keyboard

    % Saving the plots    
        for CurrentPlotType = 1:numel(PlotChoice)
            tmpPlotChoice =  PlotChoice{CurrentPlotType};
            switch tmpPlotChoice
                case 'FIG'
                    if exist(AnalysisPathEPI,'dir') 
                        AnalysisFileNameFIG7 = 'Regularization Parameters Raw vs Averaged.fig';
                        AnalysisTractionForceFIG7 = fullfile(AnalysisPathEPI, AnalysisFileNameFIG7);                    
                        savefig(figHandleRegParams, AnalysisTractionForceFIG7,'compact')    
                    end

                case 'PNG'                  % PNG SAVE. Consider replacing TIF to PNG.  %                 saveas(figFluxV, figureFileNames{2,1}, 'png');               
                    if exist(AnalysisPathEPI,'dir')                     
                        AnalysisFileNamePNG7 = 'Regularization Parameters Raw vs Averaged.png';
                        AnalysisTractionForcePNG7 = fullfile(AnalysisPathEPI, AnalysisFileNamePNG7);
                        saveas(figHandleRegParams, AnalysisTractionForcePNG7, 'png');
                    end

                case 'EPS'
                    if exist(AnalysisPathEPI,'dir')                     
                        AnalysisFileNameEPS7 = 'Regularization Parameters Raw vs Averaged.eps';                
                        AnalysisTractionForceEPS7 = fullfile(AnalysisPathEPI, AnalysisFileNameEPS7);                                     
                        print(figHandleRegParams, AnalysisTractionForceEPS7,'-depsc')
                    end
                otherwise
                     return
            end
        end
        
%% Step #9 Second round of finding all but regularization parameter using TFM_MasterSolver. 
        [pos_grid, displFieldNoFilteredGrid, displFieldFilteredGrid, forceField, energyDensityField, ForceN, TractionEnergyJ, ~, ~, ~] = ...
            TFM_MasterSolver(displField, NoiseROIsCombined, forceFieldParameters, reg_corner_averaged, ...
            gridMagnification, EdgeErode, PaddingChoiceStr, SpatialFilterChoiceStr, HanWindowchoice, ...
            GridtypeChoiceStr, reg_cornerChoiceStr, InterpolationMethod, TractionStressMethod, ForceIntegrationMethod, ...
            WienerWindowSize, ScaleMicronPerPixel, ShowOutput, FirstFrame, LastFrame, CornerPercentage);
        % Append Other Outputs
%         
%         [pos_grid, displFieldNoFilteredGrid, displFieldFilteredGrid, forceField, energyDensityField, ForceN, TractionEnergyJ, ~, ~, ~] = ...
%             TFM_MasterSolver(displField, NoiseROIsCombined, forceFieldParameters, reg_corner_averaged, ...
%             gridMagnification, EdgeErode, PaddingChoiceStr, SpatialFilterChoiceStr, HanWindowchoice, ...
%             GridtypeChoiceStr, reg_cornerChoiceStr, InterpolationMethod, TractionStressMethod, ForceIntegrationMethod, ...
%             WienerWindowSize, ScaleMicronPerPixel, ShowOutput, FirstFrame, LastFrame, CornerPercentage);

     % Plot or not?
        displField = displFieldNoFilteredGrid; 
        displFieldNoFilteredGridFullFileName = fullfile(AnalysisPathEPI, 'displField_GridNoSpatialFilterAveraged.mat');
        Note = 'Units of "displFieldNoFilteredGrid" = pixels. Averaged displacement output. No Spatial Filter, or Han Windowing. (displFieldNoFilteredGrid)';
        save(displFieldNoFilteredGridFullFileName, 'movieData', 'displField', 'TimeStamps','Note', 'TimeFilterChoiceStr', ...
            'EdgeErode',  'gridMagnification', 'GridtypeChoiceStr', 'InterpolationMethod', 'DriftCorrectionChoiceStr', 'ScaleMicronPerPixel', '-v7.3')

        displField = displFieldFilteredGrid;
        displFieldFilteredGridFullFileName = fullfile(AnalysisPathEPI, 'displField_GridWithSpatialFilterAveraged.mat');
        Note = 'Units of "displFieldFilteredGrid" = pixels. Averaged displacement output. Wiener2D Spatial Filter, & Han Windowing.';
        save(displFieldFilteredGridFullFileName, 'movieData', 'displField', 'TimeStamps','Note', 'TimeFilterChoiceStr', ...
             'EdgeErode',  'gridMagnification', 'GridtypeChoiceStr', 'InterpolationMethod','DriftCorrectionChoiceStr', 'ScaleMicronPerPixel', ...
             'SpatialFilterChoiceStr', 'WienerWindowSize', 'HanWindowchoice', '-v7.3')

        forceFieldFullFileName = fullfile(AnalysisPathEPI, 'forceField_PlusRegCornerAveraged.mat');   
        Note = 'Units of "forceField" = Pa. Actually traction stress, or T. Regularization parameters included.';
        save(forceFieldFullFileName, 'movieData', 'forceField', 'TimeStamps', 'CornerPercentage','Note', ...
            'TransientRegParamMethod', 'FluxON', 'FluxOFF', 'FluxTransient', 'reg_corner_averaged', ...
            'reg_cornerChoiceStr', 'TractionStressMethod', 'PaddingChoiceStr', 'HanWindowchoice', 'forceFieldParameters', 'CalculateRegParamMethod', '-v7.3')

        TractionForceFullFileName = fullfile(AnalysisPathEPI, 'TractionForce_Averaged.mat');   
        Note = 'Units of "Force, or Traction Force over the entire area, or F" = N. [x,y,norm]';
        save(TractionForceFullFileName, 'movieData', 'ForceN', 'TimeStamps','Note', 'ForceIntegrationMethod', '-v7.3')

        Note = 'Units of "energyField, or Storage Elastic Energy Density, or Sigma" = J/m^2. ';
        energyDensityFullFileName = fullfile(AnalysisPathEPI, 'EnergyDensity_Averaged.mat');
        save(energyDensityFullFileName, 'movieData', 'energyDensityField', 'TimeStamps', 'Note','-v7.3')

        Note = 'Units of "ElasticTractionEnergy, or or U" = J. ';
        TractionEnergyFullFileName = fullfile(AnalysisPathEPI, 'TractionEnergy_Averaged.mat');    
        save(TractionEnergyFullFileName, 'movieData', 'TractionEnergyJ', 'TimeStamps', 'Note', '-v7.3')


    %% Step #9 Plot the second round right here    
        try
            titleStr1_1 = sprintf('%.0f \\mum-thick, %g mg/mL %s gel', forceFieldParameters.thickness/ 100, forceFieldParameters.GelConcentrationMgMl, forceFieldParameters.GelType);
            titleStr1_2 = sprintf('Young Modulus = %g Pa. Poisson Ratio = %.2g', forceFieldParameters.YoungModulus, forceFieldParameters.PoissonRatio);
            titleStr1 = {titleStr1_1, titleStr1_2};
        catch
            titleStr1 = '';
        end
        titleStr1{end+1} = 'Reg. param. is averaged for (ONs & Transients) vs. (OFFs) Segments';

    %% Step #10 dlgQuestion = ({'File Format(s) for images?'});
        ConversionNtoNN = 1e9;  
        ConversionJtoFemtoJ = 1e15;

        FramesPlotted(FramesDoneNumbers) = ~isnan(ForceN(FramesDoneNumbers));
        LastFramePlotted = FramesDoneNumbers(end);
        PlotsFontName = 'Helvatica-Narrow';
        xLabelTime = 'Time [s]';

        try
            titleStr1_1 = sprintf('%.0f \\mum-thick, %g mg/mL %s gel', forceFieldParameters.thickness/ 1000, forceFieldParameters.GelConcentrationMgMl, forceFieldParameters.GelType);
            titleStr1_2 = sprintf('Young Modulus = %g Pa. Poisson Ratio = %.2g', forceFieldParameters.YoungModulus, forceFieldParameters.PoissonRatio);
            titleStr1 = {titleStr1_1, titleStr1_2};
        catch
            titleStr1 = '';
        end
        titleStr1{end+1} = 'Reg. param. is binned';

      %_________ Plot 1: 
        showPlot = 'on';
        figHandleAllTraction = figure('visible',showPlot, 'color', 'w');     % added by WIM on 2019-02-07. To show, remove 'visible    
        set(figHandleAllTraction, 'Position', [275, 435, 825, 775])
        pause(0.1)          % give some time so that the figure loads well    
        subplot(3,1,1)
        plot(TimeStampsRT_EPI(FramesPlotted), ConversionNtoNN * ForceN(FramesPlotted, 3), 'r.-', 'LineWidth', 1, 'MarkerSize', 2)
        xlim([0, TimeStampsRT_EPI(LastFramePlotted)]);
        title(titleStr1);
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
        plot(TimeStampsRT_EPI(FramesPlotted), ConversionNtoNN * ForceN(FramesPlotted, 1), 'r.-', 'LineWidth', 1, 'MarkerSize', 2)
        xlim([0, TimeStampsRT_EPI(LastFramePlotted)]);
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
        plot(TimeStampsRT_EPI(FramesPlotted), - ConversionNtoNN * ForceN(FramesPlotted, 2), 'r.-', 'LineWidth', 1, 'MarkerSize', 2)       % Flip the y-coordinates to Cartesian
        xlim([0, TimeStampsRT_EPI(LastFramePlotted)]);
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
    % 2.__________________
        figHandleEnergy = figure('visible',showPlot, 'color', 'w');     % added by WIM on 2019-02-07. To show, remove 'visible    
        set(figHandleEnergy, 'Position', [275, 435, 825, 375])
        plot(TimeStampsRT_EPI(FramesPlotted), TractionEnergyJ(FramesPlotted) * ConversionJtoFemtoJ, 'r.-', 'LineWidth', 1, 'MarkerSize', 2)
        xlim([0, TimeStampsRT_EPI(LastFramePlotted)]);
        title(titleStr1);
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
        ylabel('\itU\rm(\itt\rm) [fJ]', 'FontName', PlotsFontName);

        disp('**___to continue, type "dbcont" or press "F5", or click "Continue" under "Editor" Menu___**')
        keyboard

    % Saving the plots
       for CurrentPlotType = 1:numel(PlotChoice)
            tmpPlotChoice =  PlotChoice{CurrentPlotType};
            switch tmpPlotChoice
                case 'FIG'
                    if exist(AnalysisPathEPI,'dir') 
                        AnalysisFileNameFIG1 = 'TractionForce_Averaged.fig';
                        AnalysisTractionForceFIG1 = fullfile(AnalysisPathEPI, AnalysisFileNameFIG1);                    
                        savefig(figHandleAllTraction, AnalysisTractionForceFIG1,'compact')    

                        AnalysisFileNameFIG3 = 'TractionEnergy_Averaged.fig';               
                        AnalysisTractionForceFIG3 = fullfile(AnalysisPathEPI, AnalysisFileNameFIG3);                    
                        savefig(figHandleEnergy, AnalysisTractionForceFIG3,'compact')                    

                    end

                case 'PNG'                  % PNG SAVE. Consider replacing TIF to PNG.  %                 saveas(figFluxV, figureFileNames{2,1}, 'png');               
                    if exist(AnalysisPathEPI,'dir') 
                        AnalysisFileNamePNG1 = 'TractionForce_Averaged.png';
                        AnalysisTractionForcePNG1 = fullfile(AnalysisPathEPI, AnalysisFileNamePNG1);
                        saveas(figHandleAllTraction, AnalysisTractionForcePNG1, 'png');

                        AnalysisFileNamePNG3 = 'TractionEnergy_Averaged.png';
                        AnalysisTractionForcePNG3 = fullfile(AnalysisPathEPI, AnalysisFileNamePNG3);
                        saveas(figHandleEnergy, AnalysisTractionForcePNG3, 'png');                    
                    end

                case 'EPS'
                    if exist(AnalysisPathEPI,'dir') 
                        AnalysisFileNameEPS1 = 'TractionForce_Averaged.eps';                
                        AnalysisTractionForceEPS1 = fullfile(AnalysisPathEPI, AnalysisFileNameEPS1);                                     
                        print(figHandleAllTraction, AnalysisTractionForceEPS1,'-depsc')

                        AnalysisFileNameEPS3 = 'TractionEnergy_Averaged.eps';             
                        AnalysisTractionForceEPS3 = fullfile(AnalysisPathEPI, AnalysisFileNameEPS3);                                     
                        print(figHandleEnergy, AnalysisTractionForceEPS3,'-depsc')                                
                    end
                otherwise
                     return
            end    
       end
    end
    
      %% Step #5 Save outputs so far  
        displField = displFieldNoFilteredGrid;
        displFieldNoFilteredGridFullFileName = fullfile(AnalysisPathEPI, 'displField_GridNoSpatialFilterRaw.mat');
        Note = 'Units of "displFieldNoFilteredGrid" = pixels. Raw displacement output. No Spatial Filter, or Han Windowing. (displFieldNoFilteredGrid)';
        save(displFieldNoFilteredGridFullFileName, 'movieData', 'displField', 'TimeStamps','Note', 'TimeFilterChoiceStr', ...
            'EdgeErode',  'gridMagnification', 'GridtypeChoiceStr', 'InterpolationMethod', 'DriftCorrectionChoiceStr', 'ScaleMicronPerPixel', '-v7.3')

        displField = displFieldFilteredGrid;
        displFieldFilteredGridFullFileName = fullfile(AnalysisPathEPI, 'displField_GridWithSpatialFilterRaw.mat');
        Note = 'Units of "displFieldFilteredGrid" = pixels. Raw displacement output. Wiener2D Spatial Filter, & Han Windowing. (displFieldFilteredGrid)';
        save(displFieldFilteredGridFullFileName, 'movieData', 'displField', 'TimeStamps','Note', 'TimeFilterChoiceStr', ...
             'EdgeErode',  'gridMagnification', 'GridtypeChoiceStr', 'InterpolationMethod','DriftCorrectionChoiceStr', 'ScaleMicronPerPixel', ...
             'SpatialFilterChoiceStr', 'WienerWindowSize', 'HanWindowchoice', '-v7.3')   

        forceFieldFullFileName = fullfile(AnalysisPathEPI, 'forceField_PlusRegCornerRaw.mat');   
        Note = 'Units of "forceField" = Pa. Actually traction stress, or T. Regularization parameters included.';
        save( forceFieldFullFileName, 'movieData', 'forceField', 'CornerPercentage','Note', 'forceFieldParameters', ...
            'TimeStamps', 'reg_corner_raw','reg_cornerChoiceStr', 'TractionStressMethod', 'PaddingChoiceStr' , 'HanWindowchoice', '-v7.3')

        TractionForceFullFileName = fullfile(AnalysisPathEPI, 'TractionForce_Raw.mat');   
        Note = 'Units of "Force, or Traction Force over the entire area, or F" = N. [x,y,norm]';
        save(TractionForceFullFileName, 'movieData', 'ForceN', 'TimeStamps','Note', 'ForceIntegrationMethod', '-v7.3')

        Note = 'Units of "energyField, or Storage Elastic Energy Density, or Sigma" = J/m^2. ';
        energyDensityFullFileName = fullfile(AnalysisPathEPI, 'EnergyDensity_Raw.mat');
        save(energyDensityFullFileName, 'movieData', 'energyDensityField', 'TimeStamps', 'Note','-v7.3')

        Note = 'Units of "ElasticTractionEnergy, or or U" = J. ';
        TractionEnergyFullFileName = fullfile(AnalysisPathEPI, 'TractionEnergy_Raw.mat');    
        save(TractionEnergyFullFileName, 'movieData', 'TractionEnergyJ', 'TimeStamps', 'Note', '-v7.3')