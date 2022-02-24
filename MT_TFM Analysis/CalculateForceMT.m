    %% Used to calculate the force of a magnetic bead placed on top of a gel or cell surface.
    %{
        v.2020-05-14 by Waddah Moghram,
            1. Updates sign of the y-coordinates of the work so that it is also negative now.
        v.2020-03-11 by Waddah Moghram
            1. Updated so that the energies for all cycles as well as Half Cycle beginnings & Ends are identified.
        v.2020-03-05..08 by Waddah Moghram
            1. Added Work calculation and cycle identification
            2. Updated Flux ON/OFF to allow accurate choice of ON/OFF.
            3. Added FluxTransient term to saved output.
            4. All output now is saved into one file (*.mat)
        v.2020-02-19 by Waddah Moghram
            1. Error Analysis of MT force added based on equation. See the notes

        v.2020-01-25 by Waddah Moghram
            1. updated code to calculate the angle precisely in 3D
            2. re-expressed expressions so that the needle tip is [0,0,0]

        v.2020-01-21 by Waddah Moghram
            1. No need for needle inlincation angle. What is really important is the Theta between the bead and the needle tip.
            2. Save theta as a function of time, and a generate a plot for that.
            3. Input:  InlincationAngleDegree is not used, but I will not mess with it for now due to a major rewrite everywhere.
            4. Input: NeedleTipRelativeCoordinatesXYZmicrons is also not needed. It can be calculated from the header and the initial coordinates of the bead.

        v.2020-01-17 by Waddah Moghram
            1. Updated legends and symbols to match the output of the paper.
            2. changed hgsave() to savefig() to save space.
        v.2019-10-09
            1. Fixed LastFrame_DIC Bug if captured sensor images are less than the LastFrame_DIC in the video.
        v.2019-10-07
            1. Added inclination angle to the output.
        v2019-09-22
            1. Fixed bug with LastFrame_DIC if CleanSensorData is not capturing all images.
        v2019-09-09, updated by Waddah Moghram
            1. Updated the accompany power law curves based on near-field experiments conducted on 2019-08-15.
             2. updated related plots axis markings.

        v2019-06-15, Updated by Waddah Moghram.
    1. Continue working on the code below.
        v2019-06-06,  Updated by Waddah Moghram
    1. any flux value < (Noise Level + Observed Null Flux) is evaluted as zero flux.
    2. correct down the force to the lower calibrated level (staircase function).
    3. Got rid of first-cycle vs. subsequent cycle classification

        v 1.50 Updated by Waddah Moghram on 2019-05-29 by Waddah Moghram
        CalculateForceMT Written by Waddah Moghram on 2019-02-03>>04
        See Notes on 2019-02-03

        NeedleTipRelativeCoordinatesXYZmicrons in microns with respect to the starting position of the bead,,,in 3D
    %}

    function [Force_xyz_N, Force_xy_N, WorkBeadJ_Half_Cycles, WorkCycleFirstFrame, WorkCycleLastFrame, CompiledMT_Results] = CalculateForceMT(MagBeadCoordinatesMicronXYZ, ...
        NeedleTipRelativeCoordinatesXYZmicrons, ScaleMicronPerPixel, ...
            NeedleInclinationAngleDegrees, FirstFrame_DIC, LastFrame_DIC, TimeStampsRT_Abs_DIC, CleanSensorDataDIC, CleanSensorDataFullFileName, ...
            OutputPathName, MT_ForceFullFileName, ND2FileExtensionDIC, HeaderData, thickness_um, GelConcentrationMgMl, GelType, FluxNoiseLevelGs)

        %%
        PlotsFontName = 'XITS'; % other fonts are cambria math
        PlotTitleFontName = 'Inconsolata Condensed';

        ConversionNtoNN = 1e9;
        ConversionMicronToMeters = 1e-6;
        ConversionJtoFemtoJ = 1e15;
        disp(' ---------------------- Running CalculateForceMT.m ----------------------')

        %% ======================= 1. Track Magnetic Bead Location.

        if ~exist('ScaleMicronPerPixel', 'var'), ScaleMicronPerPixel = []; end

        if nargin < 3 || isempty(ScaleMicronPerPixel)
            ScaleMicronPerPixel = MagnificationScalesMicronPerPixel(30); % for 30X magnification for my experiments
        else
            fprintf('Scale is %g microns/pixel.\n', ScaleMicronPerPixel);
        end

        %-----------------------------------------------------------
        if ~exist('MagBeadCoordinatesMicronXYZ', 'var'), MagBeadCoordinatesMicronXYZ = []; end

        if nargin < 1 || isempty(MagBeadCoordinatesMicronXYZ)
            MagBeadCoordinatesMicronXYZ = ExtractBeadCoordinatesDIC .* ScaleMicronPerPixel;
            % Open the file, and enter the parameters needed
        end

        %-----------------------------------------------------------
        % Updated 2020-01-22:  Input: NeedleTipRelativeCoordinatesXYZmicrons is also not needed. It can be calculated from the header and the initial coordinates of the bead.
        if ~exist('NeedleTipRelativeCoordinatesXYZmicrons', 'var'), NeedleTipRelativeCoordinatesXYZmicrons = []; end

        if nargin < 2 || isempty(NeedleTipRelativeCoordinatesXYZmicrons)
            NeedleTipRelativeCoordinatesXYZmicrons = input('Enter the relative tip coordinates (in microns) as a vector [X,Y,Z]: ');
            %************************************ Consider connecting it to another function to streamline it*******************
        end

        %-----------------------------------------------------------
        % Updated 2020-01-22: Input InlincationAngleDegree is not used, but I will not mess with it for now due to a major rewrite everywhere.
        if ~exist('NeedleInclinationAngleDegrees', 'var'), NeedleInclinationAngleDegrees = []; end

        if nargin < 4 || isempty(ScaleMicronPerPixel)

            try
                NeedleInclinationAngleDegrees = HeaderData(5, 2);
            catch
                NeedleInclinationAngleDegrees = 25; % 25 degrees for my experiments. Updated on 2019-08-12 from 20 degrees before.
            end

            fprintf('Default Inclination angle of %g degrees.\n', NeedleInclinationAngleDegrees);
        end

        %-----------------------------------------------------------
        if ~exist('FirstFrame_DIC', 'var'), FirstFrame_DIC = []; end

        if nargin < 5 || isempty(FirstFrame_DIC)
            FirstFrame_DIC = 1;
        end

        %-----------------------------------------------------------
        if ~exist('LastFrame_DIC', 'var'), LastFrame_DIC = []; end

        if nargin < 6 || isempty(LastFrame_DIC)
            LastFrame_DIC = size(MagBeadCoordinatesMicronXYZ, 1);
        end

        LastFrame_DIC = min(LastFrame_DIC, size(CleanSensorDataDIC, 1));
        AllFrames = (FirstFrame_DIC:LastFrame_DIC)';

        MagBeadCoordinatesMicronXYZ = MagBeadCoordinatesMicronXYZ(AllFrames, :);
        %-----------------------------------------------------------
        if ~exist('TimeStampsRT_Abs_DIC', 'var'), TimeStampsRT_Abs_DIC = []; end

        if nargin < 7 || isempty(TimeStampsRT_Abs_DIC)
            FrameRate = input('What was the average rate (frames per second) for the video [Default = 40 FPS]? ');

            if isempty(FrameRate)
                FrameRate = 40; % 40 fps
            end

            TimeStampsRT_Abs_DIC = AllFrames ./ FrameRate;
        else

            try
                TimeStampsRT_Abs_DIC = TimeStampsRT_Abs_DIC(AllFrames);
            catch
                TimeStampsRT_Abs_DIC = TimeStampsRT_Abs_DIC(AllFrames);
            end

        end

        TimeIntervalsRT_DIC = diff(TimeStampsRT_Abs_DIC);
        TimeIntervalsRT_DIC = vertcat(TimeIntervalsRT_DIC, TimeIntervalsRT_DIC(end));

        %-----------------------------------------------------------
        %     ND2TimeFrameExtract
        %     [TimeStampsFileName,TimeStampsPathName] = uigetfile({'*.dat;*.txt;','Data Files';'*.*','All Files'},'Select the Timestamps file' );         %modified by WIM on 2/21/2018 to expand extensions
        %     TimeStampsFullName = fullfile(TimeStampsPathName,TimeStampsFileName);
        %     TimeStamps = load(TimeStampsFullName);           %Load A textfile that has only the timestamps in one column. Nothing more or less.
        %
        %     TimeStamps1stFrame = TimeStamps(1:end-1calculateforce,1);                       %Frame "1"
        %     TimeStamps2ndFrame = TimeStamps(2:end,1);                         %Frame "2" (Stagger the timepoints)
        %     TimeStampsDT = TimeStamps2ndFrame - TimeStamps1stFrame;             % dT = Time difference between subsequent frames. One less timepoint.
        %     TimeStampsRT_Abs_DIC = cumsum(TimeStampsDT);
        %     TimeStampsIntervals = TimeStampsIntervals(1:LastFrame_DIC);
        %     TimeStampsRT_Abs_DIC = TimeStampsRT_Abs_DIC(1:LastFrame_DIC)

        %-----------------------------------------------------------
        if ~exist('CleanSensorDataDIC', 'var'), CleanSensorDataDIC = []; end

        if nargin < 8 || isempty(CleanSensorDataDIC)
            [CleanSensorDataDIC, HeaderData, HeaderTitle, ~, ~] = ReadSensorDataFile();
        end

        %-----------------------------------------------------------
        if ~exist('SensorDataFullFileName', 'var'), SensorDataFullFileName = []; end

        if nargin < 9 || isempty(CleanSensorDataDIC)
            [CleanSensorDataDIC, HeaderData, HeaderTitle, ~, ~] = ReadSensorDataFile();
        end

        CleanSensorDataDIC = CleanSensorDataDIC(AllFrames, :);
        %     %-----------------------------------------------------------
        if ~exist('HeaderData', 'var'), HeaderData = []; end

        if nargin < 13 || isempty(HeaderData)
            [HeaderData, HeaderTitle] = ReadSensorDataFileHeaderOnly(SensorDataFullFileName);
        end

        if ~exist('thickness_um', 'var'), thickness_um = []; end

        if nargin < 14 || isempty(thickness_um)
            thickness_um = [];
        end

        if ~exist('GelConcentrationMgMl', 'var'), GelConcentrationMgMl = []; end

        if nargin < 15 || isempty(GelConcentrationMgMl)
            GelConcentrationMgMl = [];
        end

        if ~exist('GelType', 'var'), GelType = []; end

        if nargin < 16 || isempty(GelType)
            GelType = [];
        end

        if ~exist('FluxNoiseLevelGs', 'var'), FluxNoiseLevelGs = []; end

        if nargin < 17 || isempty(FluxNoiseLevelGs)
            FluxNoiseLevelGs = 3; % default +- 3 Gs level noise
        end

        % %% ======================= Cleaning the sensor data
        %     [CleanSensorDataDICPoints , ExposurePulseCount, EveryNthFrame, CleanedSensorDataFullFileNameDAT, ~, HeaderTitle, FirstExposurePulseIndex]= CleanSensorDataFile(SensorData, [], SensorDataFullFileName);
        %     % Discard all data points beyond frame numbers
        %     CleanSensorDataDIC = CleanSensorDataPoints(AllFrames, :);

        %% ======================= 5. Extract other Flux Values in the header:
        %FLUX SETPOINT when it is ON (in Gs), relative to FLUX OBSERVED ZERO
        disp('----------------------')
        commandwindow
        %     HeaderIndexStr = input('Enter two index numbers separated by whitespace that contain Flux (ON) Setpoint [Default 4 1]: ', 's');
        %     [Indices, n, ErrMsg] = sscanf(HeaderIndexStr, '%u');
        %     if n ~= 2 || ~isempty(ErrMsg)               % Rows & Columns are required, or if an error occured
        try
            Indices = [4; 1]; % Default Index values latest header in v8.0 and later as of 4/24/2018
            FluxSetPoint = HeaderData(Indices(1), Indices(2));
        catch
            disp('Error reading Flux Setpoint')
        end

        %     else
        %         try
        %             FluxSetPoint = HeaderData(Indices(1), Indices(2));
        %         catch
        %             disp('Error reading Flux Setpoint')
        %         end
        %     end
        fprintf('The FLUX (ON) SETPOINT in the experiment is: %g Gs. \n', FluxSetPoint);

        % -------------------------------------------
        %NULL FLUX OBSERVED when it is OFF (in Gs). This value is set visually at the beginning of the experiment.
        %     disp('----------------------')
        %     commandwindow
        %     HeaderIndexStr = input('Enter two index numbers separated by whitespace that contain Null Flux Observed [Default 4 2]: ', 's');
        %     [Indices, n, ErrMsg] = sscanf(HeaderIndexStr, '%u');
        %     if n ~= 2 || ~isempty(ErrMsg)               % Rows & Columns are required, or if an error occured
        try
            Indices = [4; 2]; % Default Index values latest header in v8.0 and later as of 4/24/2018
            NullFluxObserved = HeaderData(Indices(1), Indices(2));
        catch
            disp('Error reading Null Flux Observed')
        end

        %     else
        %         try
        %             NullFluxObserved = HeaderData(Indices(1), Indices(2));
        %         catch
        %             disp('Error reading Null Flux Observed')
        %         end
        %     end
        fprintf('The NULL FLUX OBSERVED in the experiment is: %g Gs. \n', NullFluxObserved);

        % -------------------------------------------
        %NULL FLUX CORRECTION after the first cycle. This value is based on a sigmoidal fit based on bead experiments.
        %     disp('----------------------')
        %     commandwindow
        %     HeaderIndexStr = input('Enter two index numbers separated by whitespace that contain Null Flux Correction [Default 6 1]: ', 's');
        %     [Indices, n, ErrMsg] = sscanf(HeaderIndexStr, '%u');
        %     if n ~= 2 || ~isempty(ErrMsg)               % Rows & Columns are required, or if an error occured
        try
            Indices = [6; 1]; % Default Index values latest header in v8.0 and later as of 4/24/2018
            NullFluxCorrection = HeaderData(Indices(1), Indices(2));
        catch
            disp('Error reading Null Flux Observed')
        end

        %     else
        %         try
        %             NullFluxCorrection = HeaderData(Indices(1), Indices(2));
        %         catch
        %             disp('Error reading Null Flux Observed')
        %         end
        %     end
        fprintf('The NULL FLUX CORRECTION in the experiment is: %g Gs. \n', NullFluxCorrection);

        % -------------------------------------------
        %MAGNETIC SENSOR ZERO POINT based on previous calibration (in V).
        %     disp('----------------------')
        %     commandwindow
        %     HeaderIndexStr = input('Enter two index numbers separated by whitespace that contain Magnetic Sensor Calibrated Zero [Default 1 1]: ', 's');
        %     [Indices, n, ErrMsg] = sscanf(HeaderIndexStr, '%u');
        %     if n ~= 2 || ~isempty(ErrMsg)               % Rows & Columns are required, or if an error occured
        try
            Indices = [1; 1]; % Default Index values latest header in v8.0 and later as of 4/24/2018
            SensorZeroPoint = HeaderData(Indices(1), Indices(2));
        catch
            disp('Error reading Flux Setpoint')
        end

        %     else
        %         try
        %             SensorZeroPoint = HeaderData(Indices(1), Indices(2));
        %         catch
        %             disp('Error reading Flux Setpoint')
        %         end
        %     end
        fprintf('The MAGNETIC SENSOR CALIBRATED ZERO point for the sensor is: %g V. \n', SensorZeroPoint);

        % -------------------------------------------
        %MAGNETIC SENSOR SENSITIVITY based on previous calibration (in V/Gs).
        %     disp('----------------------')
        %     commandwindow
        %     HeaderIndexStr = input('Enter two index numbers separated by whitespace that contain Magnetic Sensor Sensitivity [Default 1 2]: ', 's');
        %     [Indices, n, ErrMsg] = sscanf(HeaderIndexStr, '%u');
        %     if n ~= 2 || ~isempty(ErrMsg)               % Rows & Columns are required, or if an error occured
        try
            Indices = [1; 2]; % Default Index values latest header in v8.0 and later as of 4/24/2018
            SensorSensitivity = HeaderData(Indices(1), Indices(2));
        catch
            disp('Error reading Magnetic Sensor Sensitivity')
        end

        %     else
        %         try
        %             SensorSensitivity = HeaderData(Indices(1), Indices(2));
        %         catch
        %             disp('Error reading Magnetic Sensor Sensitivity')
        %         end
        %     end
        fprintf('The MAGNETIC SENSOR SENSITIVITY for the sensor is: %g V/Gs. \n', SensorSensitivity);
        commandwindow;

        SepDistXmicron = HeaderData(7, 2);
        SepDistYmicron = 0; % Assumed that it is at the same level at the bead in the y-direction.

        SepDistZmicron = HeaderData(6, 4) - HeaderData(6, 2); % these values are entered that way in a default header from LabVIEW.

        %         NeedleTipRelativeCoordinatesXYZmicrons = [0,0,0];                                                                                                                                   % updated notation where the needle tip is what is fixed
        fprintf('Tip Coordinates [x,y,z] = [%g, %g, %g] microns.\n', NeedleTipRelativeCoordinatesXYZmicrons)
        fprintf('Magnetic Bead Coordinates [x,y,z] = [%g, %g, %g] microns.\n', SepDistXmicron, SepDistYmicron, SepDistZmicron)
        disp('----------------------------------------------------------------------------')

        %% ======================= Calculating Separation Distance (small Delta)
        % Flip the y-coodinates from negative cartesians to a positive image coordinates.
        MagBeadCoordinatesMicronXYZ(:, 1) =- MagBeadCoordinatesMicronXYZ(:, 1); % flip to needle coordinates (x- to the left is positive)
        MagBeadCoordinatesMicronXYZ(:, 2) =- MagBeadCoordinatesMicronXYZ(:, 2); % Latest update has the Y positive pointing upwards
        %         NeedleTipRelativeCoordinatesXYZmicrons(:,2) = - NeedleTipRelativeCoordinatesXYZmicrons(:,2);        % no needle. Needle is [0,0,0]
    %{
        Shift bead coordinates so that the needle tip is the origin (0,0,0).
                X is positive poiting away from the needle (towars the left of the image)
                y is poisitive pointing downwards (just image coordinates in MATLAB)
                z is positive pointing downwards in the z-level. Lower bead is positive.
    %}
        MagBeadCoordinatesMicronXYZ = MagBeadCoordinatesMicronXYZ + [SepDistXmicron, SepDistYmicron, SepDistZmicron];
        MagBeadCoordinatesMicronXYZintial = MagBeadCoordinatesMicronXYZ(1, :);
        TipCoordinatesMicronXYZ = NeedleTipRelativeCoordinatesXYZmicrons;

        SepDistanceMicronXYZ = MagBeadCoordinatesMicronXYZ - NeedleTipRelativeCoordinatesXYZmicrons;
        SepDistanceMicronNet = vecnorm(SepDistanceMicronXYZ, 2, 2); % small delta(t) in microns = sqrt(x^2+y^2+z^2) % this is the small delta(t)

        MagBeadDisplacementMicronXY = MagBeadCoordinatesMicronXYZ - MagBeadCoordinatesMicronXYZintial; % MagBeadCoordinatesMicronXYZ is the (x,y,z) coordinates in needle coordinates
        MagBeadDisplacementMicronBigDeltaXYZ = vecnorm(MagBeadDisplacementMicronXY, 2, 2); % big delta in microns

        %% Inlination Angle Calculation:
        InclinationAnglesDegrees = asind(SepDistZmicron ./ SepDistanceMicronNet);
        %     % alternatively , you can calculate the inclination angle as:
        %     InclinationAnglesDegrees = atand(SepDistZmicron ./  vecnorm(MagBeadCoordinatesMicronXYZ(:, 1:2), 2, 2));
        %     InclinationAnglesDegrees = acosd( vecnorm(MagBeadCoordinatesMicronXYZ(:, 1:2), 2, 2)./SepDistanceMicronNet);

        %% ======================= 6. Now Compiling First part of Data from both image tracking and sensor data into one variable.
        % Updated on 2/4/2019
        disp('----------------------')
        disp('Compiling Image Tracking Data with Sensor Output Data...in Progress');
        CompiledDataSize = LastFrame_DIC; % Size of the compiled datapoints won't be more than the images tracked
        CompiledMT_Results = struct();
        % CompiledData will contain the following Columns :
        % NOTE: The following (Index, Flux and Current Reading should match temporally
        % 1. Index, 2. Flux Reading (V),  3. Current Reading (Amp or V)     % (Dropped Camera Exposure since all frame are exposesd (i.e., > 3.0 V)= 4th Column)
        CompiledData = CleanSensorDataDIC(AllFrames, 1:3); % Corrected on 1/31/2018 to indicate that the first frame disappears in these calculations. Its data will be inclued in Info file.
        CompiledMT_Results.CleanSensorData = CleanSensorDataDIC(AllFrames, 1:3);
        % NOTE: All of the following are matched temporally with the image tracking information
        % 4. Beads X- & 5. Y- & 6. Z-Coordinates  (in Image Cooridinates, not Cartesian Coordinates, and in microns)
        CompiledData = [CompiledData, MagBeadCoordinatesMicronXYZ(AllFrames, :)];
        CompiledMT_Results.MagBeadCoordinatesMicronXYZ = MagBeadCoordinatesMicronXYZ(AllFrames, :);
        % 7. Tip X- & 8. Y- & 9.Z- Coordinates  (in Image Cooridinates, not Cartesian Coordinates, and in microns)
        % repeat same values across all rows.

        CompiledData = [CompiledData, repmat(TipCoordinatesMicronXYZ, LastFrame_DIC - FirstFrame_DIC + 1, 1)];
        CompiledMT_Results.TipCoordinatesMicronXYZ = repmat(TipCoordinatesMicronXYZ, LastFrame_DIC - FirstFrame_DIC + 1, 1);
        % 10. dT or time intervals between frames (in seconds)
        CompiledData = [CompiledData, TimeStampsRT_Abs_DIC(AllFrames, :)];
        CompiledMT_Results.TimeStampsRT_Abs_DIC = TimeStampsRT_Abs_DIC(AllFrames, :);
        % 11. Separation Distance (small Delta) between the bead and the needle tip (in microns)
        CompiledData = [CompiledData, SepDistanceMicronNet(AllFrames, :)];
        CompiledMT_Results.SepDistanceMicronNet = SepDistanceMicronNet(AllFrames, :);
        disp('Compiling Image Tracking Data with Sensor Output Data complete!');

        %% =======================
    %{
    In this case it is not just ON or OFF, but rather I should assign the nearest flux signals. I need to modify the code above
    if it is OFF or transient, then I will need to throw it out.
    Otherwise, I will invoke power-law function (or values and calculate it here directly).

    Now that we have all the data compiled in one variable, we can do all sorts of manipulations
    {
        key flux values are extracted
        Convert Flux Values from V to Gs.
        Stick to CompiledData and not CleanSensorData.
        Adjusting for NullFluxObserved
        There are intentially more signals to ensure enough force cycles were observed.
    %}
        % CompiledData(:,2) are the flux readings
        % FluxReadingsStatus: 1st column is the Relative Flux (in Gs), and 2nd column is the Flux Setpoint that will be added in the next section
        FluxReadingsStatus(:, 1) = ((CompiledData(:, 2) - SensorZeroPoint) ./ SensorSensitivity) - NullFluxObserved;
        %Initialize 2nd column, for Flux Reading State. 3rd Column for Flux Setpoint. Transients are written as nan (not a number)
        FluxReadingsStatus(:, 2:3) = 0;

        %% 15. Now, classifying Flux Readings to one of three states: ON (1), OFF (0), or Transient (NaN)
        % These values are inserted into the 2nd column FluxReadingsStatus next to the Relative Flux Value (in Gs).
        % Assume: Magnetic Flux Sensor noise level band is ~ � 1.5-5 Gs normally.
        % Uncomment if you want to throw out transient points 2/4/2019
        disp('--------------------------------------------------------------------------------------------------')
        commandwindow;
        %     FluxNoiseLevelPrompt = upper(input('Do you want to change the Flux Noise Level? [Y/N] (Default = 3.0 Gs): ', 's'));
        %     if FluxNoiseLevelPrompt == 'Y'
        %         prompt = 'Enter the Flux Noise Level in Gs: ';
        %         FluxNoiseLevelGs = input(prompt);
        %         if isempty(FluxNoiseLevelGs)
        %             FluxNoiseLevelGs = 3;                   % based on trial and error 2/4/2019. Will capture most of the ramps
        %         end
        %     elseif FluxNoiseLevelPrompt == 'N'
        %             FluxNoiseLevelGs = 3;
        %     else
        %         disp('Default Noise Level is chosen of 3.0 Gs!');
        %         FluxNoiseLevelGs = 3;
        %     end
        % =======================
        % Updated on 2019-06-16  by Waddah Moghram to use a piecewise function to sort the plots.
        % List of Flux Setpoints for my experiments. negatives for ON setpoints.
        FluxSetpoints =- [0, 25, 50, 75, 100, 125, 150, 175];

        FluxSetpointsAdjusted = FluxSetpoints + FluxNoiseLevelGs; % if it is within the noise level round up. Otherwise, round down
        FluxSetpointsAdjusted = [FluxSetpointsAdjusted(2:end), -Inf];

        firstCycle = true;
        NullFluxLowEndCutoff =- FluxNoiseLevelGs; % already offset by NullFluxObserved

        % No need to sort for transients for now.
        for ii = 1:CompiledDataSize % Going through all the compiled data points
            % Finding the nearest flux data point from nearestneighbor.m
            CurrentFluxReading = FluxReadingsStatus(ii, 1);

            GreaterFluxReadings = find((CurrentFluxReading - FluxSetpointsAdjusted) > 0);
            FluxSetpointsIdx = GreaterFluxReadings(1);
            AssignedFluxSetpoint = FluxSetpoints(FluxSetpointsIdx);

            if firstCycle == false
                NullFluxLowEndCutoff = NullFluxCorrection - NullFluxObserved - FluxNoiseLevelGs;
            end

            if CurrentFluxReading > NullFluxLowEndCutoff
                FluxOFF(ii) = true;
            else
                FluxOFF(ii) = false;
            end

            if AssignedFluxSetpoint == 0
                FluxReadingsStatus(ii, 2) = 0;
                FluxON(ii) = false;
            elseif AssignedFluxSetpoint == FluxSetpoints(end)
                firstCycle = false;
                FluxON(ii) = true;
                FluxReadingsStatus(ii, 2) = 1;
            else
                FluxON(ii) = false;
                FluxReadingsStatus(ii, 2) = -1;
            end

            FluxReadingsStatus(ii, 3) = AssignedFluxSetpoint;
        end

        FluxTransient = ~(FluxON | FluxOFF);

        % Create Logicals for ON/OFF Status based on the values just compiled for plots.
        % Transient values will be 0 (or false) in both logicals
        %     FluxON = logical(FluxReadingsStatus(:,2) == 1);
        %     FluxOFF = logical(FluxReadingsStatus(:,2) == 0);

        CompiledMT_Results.FluxReadingsStatus = FluxReadingsStatus;

        %  Append the flux values to the compiled data
        % 12. F1ux reading (Gs)  13. Flux Status: {ON (1), OFF(0), Transient (nan) if uncommented above}     14. Flux ON Setpoint (to choose the curve)
        CompiledData = [CompiledData, FluxReadingsStatus];

        %% Now. Evaluating the Force
        try
            load PowerLawFitParametersMTmerged.mat F0 p x0 % This file contains the parameters for the power-law relationship. It should be saved in the same directory as this code.
        catch
            [PowerLawFileFile, PowerLawFilePath] = uigetfile('PowerLawFitParametersMTmerged.mat', 'Load the Power-Law file "PowerLawFitParametersMT.mat"');
            PowerLawFullFileName = fullfile(PowerLawFilePath, PowerLawFileFile);
            load(PowerLawFullFileName, 'F0', 'p', 'x0')
        end

        for ii = 1:CompiledDataSize
            CurrentFluxSetpoint =- CompiledData(ii, 14); % Flip Signs
            %         Currenttime = TimeStampsRT_Abs_DIC(ii);
            CurrentSmallDeltaMicrons = CompiledData(ii, 11);
            % Choose the flux parameters (idx = index)
            switch CurrentFluxSetpoint
                case 25
                    idx = 1;
                case 50
                    idx = 2;
                case 75
                    idx = 3;
                case 100
                    idx = 4;
                case 125
                    idx = 5;
                case 150
                    idx = 6;
                case 175
                    idx = 7;
                case 0
                    idx = 0;
                otherwise
                    disp('Choose one of the following values: {0,25, 50, 75, 100, 125, 150, 175} Gs')
            end

            if idx == 0
                Force_xyz_nN(ii, 1) = 0;
            else
                Force_xyz_nN(ii, 1) = F0(idx) / ((CurrentSmallDeltaMicrons / x0(idx)) + 1)^p(idx); % answer is in Newtons (nN) in here
            end

        end

        Force_xy_nN = Force_xyz_nN .* cosd(InclinationAnglesDegrees')'; % before 2020-01-22. cosd(Array) needs to be [1xlength]. Hence, the transpose.

        % convert to N
        Force_xy_N = Force_xy_nN / 10^9;
        Force_xyz_N = Force_xyz_nN / 10^9;

        %% 15. & 16. Append Force Values calculated above
        % 15 Force_XYZ (nN)  16. Force_xy (nN)
        CompiledData = [CompiledData, Force_xyz_nN, Force_xy_nN];
        %     CompiledMT_Results.Force_xyz = Force_xyz;
        %     CompiledMT_Results.Force_xy = Force_xy;
        CompiledMT_Results.InclinationAnglesDegrees = [];
        CompiledMT_Results.InclinationAnglesDegrees = InclinationAnglesDegrees;

        CompiledDataFileName = fullfile(OutputPathName, 'MT_Force_Work_Results.mat');

        CompiledMT_Results.Force_xy_N = Force_xy_N;
        CompiledMT_Results.Force_xyz_N = Force_xyz_N;
        CompiledMT_Results.Force_xy_nN = Force_xy_nN;
        CompiledMT_Results.Force_xyz_nN = Force_xyz_nN;
        CompiledMT_Results.FirstFrame_DIC = FirstFrame_DIC;
        CompiledMT_Results.LastFrame_DIC = LastFrame_DIC;
        CompiledMT_Results.CompiledDataSize = CompiledDataSize;
        CompiledMT_Results.FluxON = FluxON;
        CompiledMT_Results.FluxOFF = FluxOFF;
        CompiledMT_Results.FluxTransient = FluxTransient;

        %% 17. Evaluate work done throught the next full cycle
        ComponentAnglesDegreesXYplane = atand(MagBeadCoordinatesMicronXYZ(:, 2) ./ MagBeadCoordinatesMicronXYZ(:, 1));
        Force_x_N = -1 * Force_xy_N .* cosd(ComponentAnglesDegreesXYplane')'; % Updated on 2020-05-14 to make both negative.
        Force_y_N = -1 * Force_xy_N .* sind(ComponentAnglesDegreesXYplane')';

        clear MagBeadCoordinatesMicronXYdiff
        dTime = [TimeIntervalsRT_DIC, TimeIntervalsRT_DIC];
        MagBeadCoordinatesMicronXYdiff = [0, 0; diff(MagBeadCoordinatesMicronXYZ(:, 1:2))] ./ dTime; % Initial diff = 0; % TimeIntervalsRT_DIC is already in dT= 0.025 sec   dX term

        clear WorkCycleFirstFrame WorkCycleLastFrame

        WorkCycleFirstFrame = nan(size(Force_xy_N));
        WorkCycleLastFrame = nan(size(Force_xy_N));

        for CurrentFrame = AllFrames'

            if CurrentFrame == 1
                WorkCycleFirstFrame(CurrentFrame, 1) = 1;
                FirstFrameValue = 1;
            else
                FirstFrameValue = find(diff(FluxOFF(CurrentFrame + 1:LastFrame_DIC)) == 1, 1) + CurrentFrame + 1; % take difference, if it is 1, that means going from ON to OFF (1 to 0)
                if isempty(FirstFrameValue), FirstFrameValue = NaN; end
                WorkCycleFirstFrame(CurrentFrame, 1) = FirstFrameValue;
            end

            if ~isnan(FirstFrameValue)
                LastFrameValue = find(diff(FluxON((WorkCycleFirstFrame(CurrentFrame, 1) + 1):LastFrame_DIC)) == -1, 1) + WorkCycleFirstFrame(CurrentFrame, 1) - 1; % take difference, if it is -1, that means going from ON to OFF (1 to 0)
                if isempty(LastFrameValue), LastFrameValue = NaN; end
                WorkCycleLastFrame(CurrentFrame, 1) = LastFrameValue;
            end

        end

        %
        %     if FirstFrame_DIC == 1
        %         WorkCycleFirstFrame = 1;
        %     else
        %         WorkCycleFirstFrame =  find(diff(FluxOFF(FirstFrame_DIC + 1:LastFrame_DIC)) == 1, 1) + FirstFrame_DIC + 1;                         % take difference, if it is 1, that means going from ON to OFF (1 to 0)
        %     end
        %     WorkCycleLastFrame = find(diff(FluxON(WorkCycleFirstFrame + 1:LastFrame_DIC)) == -1, 1) + WorkCycleFirstFrame - 1;        % take difference, if it is -1, that means going from ON to OFF (1 to 0)
        %
        CyclesStartFrames = unique(WorkCycleFirstFrame);
        CyclesStartFrames(isnan(CyclesStartFrames)) = [];

        CyclesEndFrames = unique(WorkCycleLastFrame);
        CyclesEndFrames(isnan(CyclesEndFrames)) = [];

        CyclesNum = min(numel(CyclesStartFrames), numel(CyclesEndFrames));

        CyclesStartFrames = CyclesStartFrames(1:CyclesNum);
        CyclesEndFrames = CyclesEndFrames(1:CyclesNum);

        if ~isempty(CyclesStartFrames) || ~isempty(CyclesEndFrames)
            WorkAllFramesNm = ((Force_x_N .* MagBeadCoordinatesMicronXYdiff(:, 1) + Force_y_N .* MagBeadCoordinatesMicronXYdiff(:, 2)) .* ConversionMicronToMeters .* dTime); % sum rows (or x- and y-components
        else
            warning('No Full cycle is found for bead work analysis')
            WorkBeadJ_Half_Cycles = nan;
            WorkAllFramesNm = nan;
        end

        if ~isnan(WorkAllFramesNm)
            clear WorkBeadJ_Half_CycleInstant WorkAllFramesNmSummed

            for ii = 1:CyclesNum
                WorkBeadJ_Half_Cycles(ii) = sum(WorkAllFramesNm(CyclesStartFrames(ii):CyclesEndFrames(ii)));

                for jj = CyclesStartFrames(ii):CyclesEndFrames(ii)
                    WorkAllFramesNmSummed(jj) = sum(WorkAllFramesNm(CyclesStartFrames(ii):jj));
                end

            end

            try
                WorkAllFramesNmSummed(1, end + 1:CompiledDataSize) = 0;
            catch
                % all is accounted for
            end

            CompiledMT_Results.WorkAllFramesNm = WorkAllFramesNm;
            CompiledMT_Results.WorkAllFramesNmSummed = WorkAllFramesNmSummed;
        end

        %%
        save(CompiledDataFileName, 'CompiledData', 'CleanSensorDataDIC', 'FirstFrame_DIC', 'LastFrame_DIC', 'CompiledDataSize', 'ScaleMicronPerPixel', ...
        'CleanSensorDataFullFileName', 'FluxReadingsStatus', 'InclinationAnglesDegrees', 'MagBeadDisplacementMicronBigDeltaXYZ', ...
            'FluxNoiseLevelGs', 'TimeIntervalsRT_DIC', 'Force_xy_nN', 'Force_xyz_nN', 'Force_xy_N', 'Force_xyz_N', 'Force_xy_nN', 'Force_xyz_nN', ...
            'MagBeadCoordinatesMicronXYZ', 'TipCoordinatesMicronXYZ', 'FluxNoiseLevelGs', 'SepDistanceMicronXYZ', '-v7.3')

        if ~isempty(WorkCycleFirstFrame) || ~isempty(WorkCycleLastFrame)
            save(CompiledDataFileName, 'ComponentAnglesDegreesXYplane', 'Force_x_N', 'Force_y_N', 'CyclesStartFrames', 'CyclesEndFrames', ...
                'WorkAllFramesNm', 'WorkCycleFirstFrame', 'WorkCycleLastFrame', 'WorkBeadJ_Half_Cycles', '-append')
        end

        %% Error Analysis. Added on 2020-02-19 based on Calibration Curve Force
        %     Term0_1 = SepDistanceMicronNet;                                 % sqrt(x^2 + y^2 + z^2)
        %     Term0_2 = vecnorm(SepDistanceMicronXYZ(:,1:2), 2, 2);           % sqrt(x^2 + y^2)
        %
        %     X = SepDistanceMicronXYZ(:,1);
        %     Y = SepDistanceMicronXYZ(:,2);
        %     Z = SepDistanceMicronXYZ(:,3);
        %
        %     Term1 = (Error_Calibration .* Term0_2 ./  Term0_1 ).^2;
        %     Term2 = ((Error_x .* Force_xyz_nN  .* X .* (Z.^2))./(Term0_2 .* (Term0_1.^3))).^2;
        %     Term3 = ((Error_y .* Force_xyz_nN  .* Y .* (Z.^2))./(Term0_2 .* (Term0_1.^3))).^2;
        %     Term4 = ((Error_z .* Force_xyz_nN  .* Z .* Term0_2)./((Term0_1.^3))).^2;
        %
        %     Term1_Expressions = '(Error_Calibration .* Term0_2 ./  Term0_1 ).^2';
        %  	Term2_Expressions = '((Error_x .* Force_xyz_nN  .* X .* (Z.^2))./(Term0_2 .* (Term0_1.^3))).^2';
        %     Term3_Expressions = '((Error_y .* Force_xyz_nN  .* Y .* (Z.^2))./(Term0_2 .* (Term0_1.^3))).^2';
        %     Term4_Expressions = '((Error_z .* Force_xyz_nN  .* Z .* Term0_2)./((Term0_1.^3))).^2';
        %     Error_Force_Expression = 'sqrt(Term1 + Term2 + Term3 + Term4)';
        %
        %     Error_Force = sqrt(Term1 + Term2 + Term3 + Term4);
        %     save(CompiledDataFileName, 'Error_Force', 'Error_Calibration', 'Error_x', 'Error_y', 'Error_z', ...
        %         'Term1', 'Term2', 'Term3', 'Term4', 'Term1_Expressions', 'Term2_Expressions', 'Term3_Expressions', 'Term4_Expressions', ...
        %         'Error_Force_Expression', '-append')

        % Error Analysis. Added on 2020-02-19 based on uncertainty in power-law terms
        Term0_1 = SepDistanceMicronNet; % sqrt(x^2 + y^2 + z^2)
        Term0_2 = vecnorm(SepDistanceMicronXYZ(:, 1:2), 2, 2); % sqrt(x^2 + y^2)

        Error_Calibration = 0.5; % +/- 0.5 nN        (Based on calibration curves fit in MATLAB curve-fitting tool for the 150,175,185Gs calibration curves.
        Error_F0 = 1.325;
        Error_p = 0.036;
        Error_x0 = 0.3335;
        Error_x = 1;
        Error_y = 1;
        Error_z = 1;

        F = 58.65; % nN from power-law curve 175Gs
        p = 2.331; % power from power-law curve
        x0 = 8.206; % microns from power-law curve

        X = SepDistanceMicronXYZ(:, 1);
        Y = SepDistanceMicronXYZ(:, 2);
        Z = SepDistanceMicronXYZ(:, 3);

        Term1 = (Error_F0 .* ((Term0_2 .* (Term0_1 ./ x0 + 1).^(-p)) ./ Term0_1)).^2; %  verified;
        Term2 = (Error_p .* (- (F .* Term0_2 .* (Term0_1 ./ x0 + 1).^(-p) .* log(Term0_1 ./ x0 + 1)) ./ Term0_1)).^2; %  verified;
        Term3 = (Error_x0 * ((F .* p .* Term0_2 .* (Term0_1 ./ x0 + 1).^(-p - 1)) ./ (x0.^2))).^2; %  verified;
        Term4 = (Error_x .* (- (F .* p .* X .* Term0_2 .* (Term0_1 ./ x0 + 1).^(-p - 1)) ./ (x0 .* Term0_1.^2) + ...
            (F .* X .* (Term0_1 ./ x0 + 1).^(-p)) ./ (Term0_2 .* Term0_1) - ...
            (F .* X .* Term0_2 .* (Term0_1 ./ x0 + 1).^(-p)) ./ Term0_1.^3)).^2; %  verified;
        Term5 = (Error_y .* (- (F .* p .* Y .* Term0_2 .* (Term0_1 ./ x0 + 1).^(-p - 1)) ./ (x0 .* Term0_1.^2) + ...
            (F .* Y .* (Term0_1 ./ x0 + 1).^(-p)) ./ (Term0_2 .* Term0_1) - ...
            (F .* Y .* Term0_2 .* (Term0_1 ./ x0 + 1).^(-p)) ./ Term0_1.^3)).^2; %  verified;
        Term6 = (Error_z .* (- (F .* p .* Z .* Term0_2 .* (Term0_1 ./ x0 + 1).^(-p - 1)) ./ (x0 .* Term0_1.^2) - ...
            (F .* Z .* Term0_2 .* (Term0_1 ./ x0 + 1).^(-p)) ./ Term0_1.^3)).^2; %  verified;

        Term1_Expressions = '(Error_F0 .*((Term0_2 .* (Term0_1./x0 + 1).^(-p))./Term0_1)).^2';
        Term2_Expressions = '(Error_p .*(-(F .* Term0_2 .* (Term0_1 ./x0 + 1).^(-p) .* log(Term0_1./x0 + 1))./Term0_1)).^2';
        Term3_Expressions = '(Error_x0 *((F .* p .* Term0_2 .* (Term0_1 ./x0 + 1).^(-p - 1))./(x0.^2))).^2';
        Term4_Expressions = strcat('(Error_x .*(- (F .* p .* X .* Term0_2 .* (Term0_1./x0 + 1).^(-p - 1))./(x0 .* Term0_1.^2) + ', ...
            '(F .* X .* (Term0_1 ./x0 + 1).^(-p))./(Term0_2 .* Term0_1) - ', ...
        '(F .* X .* Term0_2 .* (Term0_1./x0 + 1).^(-p))./Term0_1.^3)).^2');
        Term5_Expressions = strcat('(Error_y .*(-(F .* p .* Y .* Term0_2 .* (Term0_1./x0 + 1).^(-p - 1))./(x0 .* Term0_1.^2) +', ...
            '(F .* Y .* (Term0_1 ./x0 + 1).^(-p))./(Term0_2 .* Term0_1) -', ...
        '(F .* X .* Term0_2 .* (Term0_1./x0 + 1).^(-p))./Term0_1.^3)).^2');
        Term6_Expressions = strcat('(Error_z .*(-(F .* p .* Z .* Term0_2 .* (Term0_1./x0 + 1).^(-p - 1))./(x0 .* Term0_1.^2) -', ...
        '(F .* Z .* Term0_2 .* (Term0_1 ./x0 + 1).^(-p))./Term0_1.^3)).^2');

        Error_Force_Expression = 'sqrt(Term1 + Term2 + Term3 + Term4 + Term5 + Term 6)'; % Verified
        Error_Force = sqrt(Term1 + Term2 + Term3 + Term4 + Term5 + Term6);

        save(CompiledDataFileName, 'Error_Force', 'Error_Calibration', 'Error_x', 'Error_y', 'Error_z', ...
            'Term1', 'Term2', 'Term3', 'Term4', 'Term5', 'Term6', 'Term1_Expressions', 'Term2_Expressions', 'Term3_Expressions', 'Term4_Expressions', ...
            'Term5_Expressions', 'Term6_Expressions', 'Error_Force_Expression', '-append')

        %%
        %     CompiledDataFileNameStruct = fullfile(OutputPathName, 'MT_Force_Work_Struct.mat');
        save(CompiledDataFileName, 'CompiledMT_Results', '-append')
        dlmwrite(fullfile(OutputPathName, 'MT_Force_Work_Results.dat'), CompiledData)

        %     if ~exist('AnalysisPath', 'var'), AnalysisPath = []; end
        %     if ~isempty(AnalysisPath)
        %         AnalysisCompiledDataFileName = fullfile(AnalysisPath, '05 Force_MT Compiled Results.mat');
        %         save(AnalysisCompiledDataFileName, 'CompiledData', 'CleanSensorData' ,  'FirstFrame_DIC', 'LastFrame_DIC', 'CompiledDataSize', ...
        %             'CleanSensorDataFullFileName', 'FluxReadingsStatus', 'InclinationAnglesDegrees',...
        %             'FluxNoiseLevelGs', 'TimeIntervalsRT_DIC', 'Force_xy', 'Force_xyz', 'Force_xyz', 'Force_xy_N', 'Force_xyz_N', ...
        %             'MagBeadCoordinatesMicronXYZ', 'TipCoordinatesMicronXYZ', 'FluxNoiseLevelGs',  'CompiledMT_Results', '-v7.3' )
        %     end

        %% 17. Ask for header information.
        commandwindow;
        %     if isempty(GelType)
        %         GelType = input('What type of gel was used for the experiment? ', 's');
        %         if ~isempty(GelType)
        %            fprintf('Gel type is: "%s" \n', GelType);
        %         else
        %            disp('No gel type was given')
        %         end
        %     else
        %         GelTypeInput = input(sprintf('Do you want to use "%s" as the gel type?\n\t Press Enter to continue. Type the gel type otherwise: ',GelType), 's');
        %         if ~isempty(GelTypeInput), GelType = GelTypeInput; end
        fprintf('Gel type is: "%s" \n', GelType{:});
        %     end

        %     try
        %         thickness_um_Default =  HeaderDataDIC(7,1);
        %     catch
        %         thickness_um_Default = 700;             % 700 microns
        %     end
        %     prompt = sprintf('What was the gel thickness in microns? [Default, %d micron]: ', thickness_um_Default);
        %     thickness_um = input(prompt);
        %     if isempty(thickness_um)
        %         thickness_um = thickness_um_Default;
        %     end
        fprintf('Gel thickness is %d  microns. \n', thickness_um);
        %
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
        GelConcentrationMgMlStr = sprintf('%.3f', GelConcentrationMgMl);
        %     end
        fprintf('Gel Concentration Chosen is %s mg/mL. \n', GelConcentrationMgMlStr);

        try
            save(CompiledDataFileName, 'GelConcentrationMgMl', 'thickness_um', 'GelType', '-append'); % Modified by WIM on 2/5/2019
        catch
            % Do nothing
        end

        %-----------

        %% 18. Separation Distance (small delta) vs. time. %% ******** CONSIDER MAKING THIS ITS OWN FUNCTION******************
        %     ForceInfo = sprintf('Needle-Bead Separation Distance at inclination angle of %.0f', InclinationAnglesDegrees);
        %     ForceInfo = [ForceInfo, char(176)];        % Add a degree at the end
        titleStr2 = sprintf('%.0f %sm-thick, %.1f mg/mL %s', thickness_um, char(181), GelConcentrationMgMl, GelType{1});
        %             titleStr = {'Magnetic bead net displacements from starting position', titleStr2};
        titleStr = titleStr2;

        TimeStampsSeconds = CompiledData(:, 10);

        figHandleSepDistance = figure('color', 'w');
        plot(TimeStampsSeconds, CompiledData(:, 11), 'b.-', 'LineWidth', 1', 'MarkerSize', 2)
        %     xlim([TimeStampsSeconds(1), TimeStampsSeconds(end)]);
        xlim([0, TimeStampsSeconds(end)]);
        set(findobj(figHandleSepDistance, 'type', 'axes'), ...
            'FontSize', 12, ...
            'FontName', 'Helvetica', ...
            'LineWidth', 1, ...
            'XMinorTick', 'on', ...
            'YMinorTick', 'on', ...
            'TickDir', 'out', ...
            'TitleFontSizeMultiplier', 0.9, ...
            'TitleFontWeight', 'bold', ...
            'Box', 'off'); % Make axes bold
        xlabel('\rmtime [s]', 'FontName', PlotsFontName)
        ylabel(strcat('\bf|\it\delta\rm\it_{MT}\rm(\itt\rm)\bf|\rm [', char(181), 'm]'), 'FontName', PlotsFontName);
        title({'Separation Distance vs. Time', titleStr}, 'FontName', PlotTitleFontName);

        % 19. Plotting Force vs. Time
        %-----------
        figHandleForce = figure('color', 'w');
        plot(TimeStampsSeconds, Force_xy_N * ConversionNtoNN, 'b.-', 'LineWidth', 1', 'MarkerSize', 2)
        xlim([0, TimeStampsSeconds(end)]);
        %     xlim([TimeStampsSeconds(1), TimeStampsSeconds(end)]);
        set(findobj(figHandleForce, 'type', 'axes'), ...
        'FontSize', 12, ...
            'FontName', 'Helvetica', ...
            'LineWidth', 1, ...
            'XMinorTick', 'on', ...
            'YMinorTick', 'on', ...
            'TickDir', 'out', ...
            'TitleFontSizeMultiplier', 0.9, ...
            'TitleFontWeight', 'bold', ...
            'Box', 'off'); % Make axes bold
        xlabel('\rmtime [s]', 'FontName', PlotsFontName)
        ylabel('\bf|\itF_{MT}\rm(\itt\rm)\bf|\rm [nN]', 'FontName', PlotsFontName); % Note to self. The MT force is along the XY-plane.
        title({'Magnetic Tweezer Pulling Force vs. Time', titleStr}, 'FontName', PlotTitleFontName);
        

        % 20. Plotting Bead inclination Angles
        figHandleInclinationAngles = figure('color', 'w');
        plot(TimeStampsSeconds, InclinationAnglesDegrees, 'b.-', 'LineWidth', 1', 'MarkerSize', 2)
        xlim([0, TimeStampsSeconds(end)]);
        %     xlim([TimeStampsSeconds(1), TimeStampsSeconds(end)]);
        set(findobj(figHandleInclinationAngles, 'type', 'axes'), ...
        'FontSize', 12, ...
            'FontName', 'Helvetica', ...
            'LineWidth', 1, ...
            'XMinorTick', 'on', ...
            'YMinorTick', 'on', ...
            'TickDir', 'out', ...
            'TitleFontSizeMultiplier', 0.9, ...
            'TitleFontWeight', 'bold', ...
            'Box', 'off'); % Make axes bold
        xlabel('\rmtime [s]', 'FontName', PlotsFontName)
        ylabel('\bf|\it\theta\rm\it_{MT}\rm(\itt\rm)\bf|\rm [\circ]', 'FontName', PlotsFontName);
        title({'Inclination angle between the bead and the needle tip', titleStr}, 'FontName', PlotTitleFontName);

        % 21. Plotting Bead Component Angles
        figHandleComponentAngles = figure('color', 'w');
        plot(TimeStampsSeconds, ComponentAnglesDegreesXYplane, 'b.-', 'LineWidth', 1', 'MarkerSize', 2)
        xlim([0, TimeStampsSeconds(end)]);
        %     xlim([TimeStampsSeconds(1), TimeStampsSeconds(end)]);
        set(findobj(figHandleComponentAngles, 'type', 'axes'), ...
        'FontSize', 12, ...
            'FontName', 'Helvetica', ...
            'LineWidth', 1, ...
            'XMinorTick', 'on', ...
            'YMinorTick', 'on', ...
            'TickDir', 'out', ...
            'TitleFontSizeMultiplier', 0.9, ...
            'TitleFontWeight', 'bold', ...
            'Box', 'off'); % Make axes bold
        xlabel('\rmtime [s]', 'FontName', PlotsFontName)
        ylabel('\bf|\it\alpha\rm\it_{MT}\rm(\itt\rm)\bf|\rm [\circ]', 'FontName', PlotsFontName);
        %     title({ForceInfo, titleStr2})
        title({'Bead Displaement/Force XY-vector angle with respect to x-axis', titleStr}, 'FontName', PlotTitleFontName);

        % 22. Error Analysis
        figHandleForceError = figure('color', 'w');
        plot(TimeStampsSeconds, Error_Force, 'b.-', 'LineWidth', 1', 'MarkerSize', 2)
        xlim([0, TimeStampsSeconds(end)]);
        %     xlim([TimeStampsSeconds(1), TimeStampsSeconds(end)]);
        set(findobj(figHandleForceError, 'type', 'axes'), ...
        'FontSize', 12, ...
            'FontName', 'Helvetica', ...
            'LineWidth', 1, ...
            'XMinorTick', 'on', ...
            'YMinorTick', 'on', ...
            'TickDir', 'out', ...
            'TitleFontSizeMultiplier', 0.9, ...
            'TitleFontWeight', 'bold', ...
            'Box', 'off'); % Make axes bold
        xlabel('\rmtime [s]', 'FontName', PlotsFontName)
        ylabel('\bf|\itw_{F_{TM}}\rm(\itt\rm)\bf|\rm [nN]', 'FontName', PlotsFontName);
        title({'Magnetic Tweezer Force Error. ', strcat(sprintf('Error_{Calibration} = %0.3g nN. Error_{x,y,z} = %0.3g ', Error_Calibration, Error_x), char(181), 'm'), ...
                titleStr}, 'FontName', PlotTitleFontName);

        if ~isempty(WorkCycleFirstFrame) || ~isempty(WorkCycleLastFrame)
            % 23. Plot work over time
            figHandleWorkMT = figure('color', 'w');
            plot(TimeStampsSeconds, WorkAllFramesNm .* ConversionNtoNN ./ ConversionMicronToMeters, 'b.-', 'LineWidth', 0.75', 'MarkerSize', 2)
            %     xlim([TimeStampsSeconds(1), TimeStampsSeconds(end)]);
            xlim([0, TimeStampsSeconds(end)]);
            set(findobj(figHandleWorkMT, 'type', 'axes'), ...
                'FontSize', 12, ...
                'FontName', 'Helvetica', ...
                'LineWidth', 1, ...
                'XMinorTick', 'on', ...
                'YMinorTick', 'on', ...
                'TickDir', 'out', ...
                'TitleFontSizeMultiplier', 0.9, ...
                'TitleFontWeight', 'bold', ...
                'Box', 'off'); % Make axes bold
            xlabel('\rmtime [s]', 'FontName', PlotsFontName)
            ylabel('Instantaneous\bf\itW\rm\it_{MT}\rm(\itt\rm)\bf\rm [nN.\mum or fJ]', 'FontName', PlotsFontName);
            title({'Work vs. Time', titleStr}, 'FontName', PlotTitleFontName);
        end

        % 24. Plot work over time
        if ~isnan(WorkAllFramesNm)
            figHandleWorkMTsummed = figure('color', 'w');
            plot(TimeStampsSeconds(1:numel(WorkAllFramesNmSummed)), WorkAllFramesNmSummed .* ConversionNtoNN ./ ConversionMicronToMeters, 'b.', 'MarkerSize', 4)
            %     xlim([TimeStampsSeconds(1), TimeStampsSeconds(end)]);
            xlim([0, TimeStampsSeconds(end)]);
            set(findobj(figHandleWorkMTsummed, 'type', 'axes'), ...
                'FontSize', 12, ...
                'FontName', 'Helvetica', ...
                'LineWidth', 1, ...
                'XMinorTick', 'on', ...
                'YMinorTick', 'on', ...
                'TickDir', 'out', ...
                'TitleFontSizeMultiplier', 0.9, ...
                'TitleFontWeight', 'bold', ...
                'Box', 'off'); % Make axes bold
            xlabel('\rmtime [s]', 'FontName', PlotsFontName)
            ylabel('\bf\itW\rm\it_{MT}\rm(\itt\rm)\bf\rm [nN.\mum] or [fJ]', 'FontName', PlotsFontName);
            title({'Work vs. Time', titleStr}, 'FontName', PlotTitleFontName);
        end

        %% ___________
        %     disp('**___to continue saving, type "dbcont" or press "F5", or click "Continue" under "Editor" Menu"___**')
        %     keyboard
        %
        %% ____ Saving the images
        SeparationDistanceMTfileNameFIG = fullfile(OutputPathName, 'MT_SeparationDistance.fig');
        savefig(figHandleSepDistance, SeparationDistanceMTfileNameFIG, 'compact');
        SeparationDistanceMTfileNamePNG = fullfile(OutputPathName, 'MT_SeparationDistance.png');
        saveas(figHandleSepDistance, SeparationDistanceMTfileNamePNG, 'png');
        fprintf('Big Delta_{MT}(time) plots are stored as:\n\t%s\n\t%s \n', SeparationDistanceMTfileNameFIG, SeparationDistanceMTfileNamePNG);

        ForceMTfileNameFIG = fullfile(OutputPathName, 'MT_Force.fig');
        savefig(figHandleForce, ForceMTfileNameFIG, 'compact');
        ForceMTfileNamePNG = fullfile(OutputPathName, 'MT_Force.png');
        saveas(figHandleForce, ForceMTfileNamePNG, 'png');
        fprintf('Force_{MT}(time) plots are stored as:\n\t%s\n\t%s \n', ForceMTfileNameFIG, ForceMTfileNamePNG);

        ForceMT_ErrorfileNameFIG = fullfile(OutputPathName, 'MT_Force_Error.fig');
        savefig(figHandleForceError, ForceMT_ErrorfileNameFIG, 'compact');
        ForceMT_ErrorfileNamePNG = fullfile(OutputPathName, 'MT_Force_Error.png');
        saveas(figHandleForceError, ForceMT_ErrorfileNamePNG, 'png');
        fprintf('Force Error_{MT}(time) plots are stored as:\n\t%s\n\t%s \n', ForceMT_ErrorfileNameFIG, ForceMT_ErrorfileNamePNG);

        InclinationAnglesMTfileNameFIG = fullfile(OutputPathName, 'Needle_Inclination_Angle.fig');
        savefig(figHandleInclinationAngles, InclinationAnglesMTfileNameFIG, 'compact');
        InclinationAnglesMTfileNamePNG = fullfile(OutputPathName, 'Needle_Inclination_Angle.png');
        saveas(figHandleInclinationAngles, InclinationAnglesMTfileNamePNG, 'png');
        fprintf('Inclination Angle_{MT}(time) plots are stored as:\n\t%s\n\t%s \n', InclinationAnglesMTfileNameFIG, InclinationAnglesMTfileNamePNG);

        ComponentAnglesMTfileNameFIG = fullfile(OutputPathName, 'Needle_Inclination_Angle_Components.fig');
        savefig(figHandleComponentAngles, ComponentAnglesMTfileNameFIG, 'compact');
        ComponentAnglesMTfileNamePNG = fullfile(OutputPathName, 'Needle_Inclination_Angle_Components.PNG');
        saveas(figHandleComponentAngles, ComponentAnglesMTfileNamePNG, 'png');
        fprintf('Component Angles_{MT}(time) plots are stored as:\n\t%s\n\t%s \n', ComponentAnglesMTfileNameFIG, ComponentAnglesMTfileNamePNG);

        if ~isempty(WorkCycleFirstFrame) || ~isempty(WorkCycleLastFrame)
            WorkMTfileNameFIG = fullfile(OutputPathName, 'MT_Work_Instantaneous.fig');
            savefig(figHandleWorkMT, WorkMTfileNameFIG, 'compact');
            WorkMTfileNamePNG = fullfile(OutputPathName, 'MT_Work_Instantaneous.PNG');
            saveas(figHandleWorkMT, WorkMTfileNamePNG, 'png');
            fprintf('Work Plots_{MT}(time) plots are stored as:\n\t%s\n\t%s  \n', WorkMTfileNameFIG, WorkMTfileNamePNG);
        end

        if ~isnan(WorkAllFramesNm)

            if ~isempty(WorkCycleFirstFrame) || ~isempty(WorkCycleLastFrame)
                WorkMTfileNameFIG = fullfile(OutputPathName, 'MT_Work_Summed.fig');
                savefig(figHandleWorkMTsummed, WorkMTfileNameFIG, 'compact');
                WorkMTfileNamePNG = fullfile(OutputPathName, 'MT_Work_Summed.PNG');
                saveas(figHandleWorkMTsummed, WorkMTfileNamePNG, 'png');
                fprintf('Work Plots_{MT}(time) plots as stored in:\n\t%s\n\t%s \n', WorkMTfileNameFIG, WorkMTfileNamePNG);
            end

        end

        %% ++++++++++++++++++++++++++++++++ CODE DUMPSTER ++++++++++++++++++++++++++++++++++++++
%{
    wF = 1.325;
    wp = 0.036;
    wb = 0.3335;

    F = 58.65;      % nN from power-law curve 175Gs
    p = 2.331;      % power from power-law curve
    b = 8.206;      % microns from power-law curve

    x = SepDistanceMicronXYZ(:,1);
    y = SepDistanceMicronXYZ(:,2);
    z = SepDistanceMicronXYZ(:,3);

    wx = 1;
    wy = 1;
    wz = 1;

    Term1 = (wF.*((sqrt(x.^2 + y.^2) .* (sqrt(x.^2 + y.^2 + z.^2)./b + 1).^(-p))./sqrt(x.^2 + y.^2 + z.^2))).^2;
    Term2 = (wp.*(-(F .* sqrt(x.^2 + y.^2) .* (sqrt(x.^2 + y.^2 + z.^2)./b + 1).^(-p) .* log(sqrt(x.^2 + y.^2 + z.^2)./b + 1))./sqrt(x.^2 + y.^2 + z.^2))).^2;
    Term3 = (wb.*((F .* p .* sqrt(x.^2 + y.^2) .* (sqrt(x.^2 + y.^2 + z.^2)./b + 1).^(-p - 1))./b.^2)).^2;
    Term4 = (wx.*(-(F .* p .* x .* sqrt(x.^2 + y.^2) .* (sqrt(x.^2 + y.^2 + z.^2)./b + 1).^(-p - 1))./(b .* (x.^2 + y.^2 + z.^2)) + ...
        (F .* x .* (sqrt(x.^2 + y.^2 + z.^2)./b + 1).^(-p))./(sqrt(x.^2 + y.^2) .* sqrt(x.^2 + y.^2 + z.^2)) - ...
        (F .* x .* sqrt(x.^2 + y.^2) .* (sqrt(x.^2 + y.^2 + z.^2)./b + 1).^(-p))./(x.^2 + y.^2 + z.^2).^(3./2))).^2;
    Term5 = (wy.*(-(F .* p .* y .* sqrt(x.^2 + y.^2) .* (sqrt(x.^2 + y.^2 + z.^2)./b + 1).^(-p - 1))./(b .* (x.^2 + y.^2 + z.^2)) + ...
        (F .* y .* (sqrt(x.^2 + y.^2 + z.^2)./b + 1).^(-p))./(sqrt(x.^2 + y.^2) .* sqrt(x.^2 + y.^2 + z.^2)) - ...
        (F .* y .* sqrt(x.^2 + y.^2) .* (sqrt(x.^2 + y.^2 + z.^2)./b + 1).^(-p))./(x.^2 + y.^2 + z.^2).^(3./2))).^2;
    Term6 = (wz.*(-(F .* p .* z .* sqrt(x.^2 + y.^2) .* (sqrt(x.^2 + y.^2 + z.^2)./b + 1).^(-p - 1))./(b .* (x.^2 + y.^2 + z.^2)) - ...
        (F .* z .*sqrt(x.^2 + y.^2) .* (sqrt(x.^2 + y.^2 + z.^2)./b + 1).^(-p))./(x.^2 + y.^2 + z.^2).^(3./2))).^2;

    Error_Force = sqrt(Term1 + Term2 + Term3 + Term4 + Term5 + Term6);
%}
