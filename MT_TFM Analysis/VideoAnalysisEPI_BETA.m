 %{
    v.2021-08-02 by Waddah Moghram
        1. 
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
    MagX = 30;

%%

    choiceOpenND2EPI = 'Yes';
    switch choiceOpenND2EPI    
        case 'Yes'
            disp('Opening the EPI ND2 Video File to get path and filename info to be analyzed')
            [ND2fileEPI, ND2pathEPI] = uigetfile('*.nd2', 'EPI ND2 video file');    
            if ND2fileEPI==0
                error('No file was selected');
            end
            
            ND2fullFileName = fullfile(ND2pathEPI, ND2fileEPI);   
            [ND2PathName, ND2FileName, ~] = fileparts(ND2fullFileName);
            
            ND2FileNameParts = split(ND2FileName, '-');
            AnalysisSuffix = join(ND2FileNameParts(end-2:end), '-');
            AnalysisSuffix = AnalysisSuffix{:};
            AnalysisFolderStr = strcat('Analysis_', AnalysisSuffix);
            OutputPathNameEPI = fullfile(ND2pathEPI, '..', AnalysisFolderStr);
            
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

        SensorDataFileName = fullfile(ND2PathName, strcat(ND2FileName, '.dat'));
        SensorPlotsOutputPath = fullfile(OutputPathNameEPI, 'Sensor_Signals');
        try
            mkdir(SensorPlotsOutputPath)
        catch

        end

        [SensorDataEPI, HeaderDataEPI, HeaderTitleEPI, SensorDataFullFilenameEPI, SensorOutputPathNameEPI, ~, SamplingRate, SensorDataColumns]  = ReadSensorDataFile(SensorDataFileName, PlotSensorData, SensorPlotsOutputPath, AnalysisPath, 8, 'No');   
        close all
        % Cleaning the sensor data.
        [CleanSensorDataEPI , ExposurePulseCountEPI, EveryNthFrameEPI, CleanedSensorDataFullFileName_EPI, HeaderData, HeaderTitle, FirstExposurePulseIndexEPI] = CleanSensorDataFile(SensorDataEPI, 1, SensorDataFullFilenameEPI, SamplingRate, HeaderDataEPI, HeaderTitleEPI, SensorDataColumns);
        %{
            Do not forget to reduce the frames of the cleaned sensor data to match the reduce frame number in the accompanying video 
        %}

%%
    [ScaleMicronPerPixel, MagnificationTimesStr, MagnificationTimes, NumAperture] = MagnificationScalesMicronPerPixel(MagX);

%% ================= 5.0  Create timestamps from the sensor data file instead of through that in the video metadata.
    [TimeStamps] = TimestampRTfromSensorData(CleanSensorDataEPI, SamplingRate, HeaderData, HeaderTitle, CleanedSensorDataFullFileName_EPI, FirstExposurePulseIndexEPI);
    [TimeStampsND2, LastFrameND2, AverageTimeIntervalND2] = ND2TimeFrameExtract(ND2fullFileName);

%% ----------------- 4.0 create TFM output path & MOvie Data File
    TFM_OutputPath = fullfile(OutputPathNameEPI, 'TFM_Output');
    MD = bfImport(ND2fullFileName, 'outputDirectory', TFM_OutputPath, 'askUser', 1);

    MD.numAperture_ = NumAperture;
    MD.channels_.fluorophore_ = 'TexasRed';

    [Part1, Part2, ~] = fileparts(SensorDataFileName);
    SensorDataNotesFileName = fullfile(Part1, strcat(Part2, '_Notes.txt'));
    Notes = fileread(SensorDataNotesFileName);
    NotesWords = split(Notes, ' ');             % split by white space

    MD.notes_ = Notes;
    MD.magnification_ = MagnificationTimes;
    MD.timeInterval_ = AverageTimeIntervalND2;
    MD.channels_.emissionWavelength_;                   % 
    MD.channels_.excitationWavelength_ = 560;           % nm for texas red;
    MD.channels_.excitationType_ = 'Widefield';         % Widefield Fluorescence.
    MD.channels_.exposureTime_ = AverageTimeIntervalND2; % in seconds
    MD.channels_.fluorophore_ = 'TexasRed';

%     AcquisitionDateStr = split(NotesWords{6}, '/');
%     AcquisitionTimeStr = split(NotesWords{8}, ':');
%     MonthName = month(datetime(1, str2num(AcquisitionDateStr{1}),1), 'name');
%     MonthName = MonthName{1};
%     
%     AcquisitionDate = [MonthName, ' ', AcquisitionDateStr{2}, ', ' AcquisitionDateStr{3}]; 
%         
%     MD.acquisitionDate_ = NotesWords{6};
% 

    
%% Creating the reference frame from the first frame and saving it
    RefFrame = MD.channels_.loadImage(1);
    RefFramePath =  fullfile(TFM_OutputPath, 'ReferenceFirstFrame.tif');
    imwrite(RefFrame, RefFramePath, 'TIFF')
    
%% Construct the TFM package
    packageName = 'TFMPackage';
    packageConstr = str2func(packageName);
   % Add package to movie
    packageIndx = MD.getPackageIndex(packageName,1,true);
    MD.addPackage(packageConstr(MD, MD.outputDirectory_));

%% Setup epi beads reference frame, tracking parameters, and output path
   
    % Create a structure that contains that Displacement Process Tracking
    DisplacementfunParams_.referenceFramePath = RefFramePath;
    DisplacementfunParams_.alpha = 0.01;
    DisplacementfunParams_.minCorLength = 31;
    DisplacementfunParams_.maxFlowSpeed = 15;       % pixels per frame tracked
    DisplacementfunParams_.HighRes = 1;
    DisplacementfunParams_.useGrid = 0;
    DisplacementfunParams_.lastToFirst = 0;
    DisplacementfunParams_.noFlowOutwardOnBorder = 1;
    DisplacementfunParams_.addNonLocMaxBeads = 0;
    DisplacementfunParams_.trackSuccessively =  0;
    DisplacementfunParams_.mode = 'accurate';

    calculateMovieDisplacementField(MD, DisplacementfunParams_)

%% Correct displacements for spatial outliers
    CorrectionfunParams.doRogReg = 0;               % No rotational adjustments for drift
    CorrectionfunParams.outlierThreshold = 2;
    CorrectionfunParams.fillVectors = 0;

    correctMovieDisplacementField(MD, CorrectionfunParams)
