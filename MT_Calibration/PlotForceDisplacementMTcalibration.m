% function [CompiledData, SensorData, CleanSensorData,TipCoordinatesXY] = PlotForceDisplacementMTcalibration( )
    %{
    v.2020-03-23 by Waddah Moghram
        1. changed from a function to a script
        2. updated to work with newer versions of sensor readers and cleaners

    % v.2019-08-01 (v9.00) Updated on 2019-08-1+ by Waddah Moghram, PhD Student in Biomedical Engineering at the University of Iowa
    % Goal is to generate plots of Force vs. Separation Distance for MT based on calibrations in solutions such as glycerol and silicone oils.

    v 9.00 2019-08-22|29
            2019-08-22
        1. Save figures to output. 
        2. streamline process to make it similar to VideoAnalysisDIC
            2019-08-27
        3. Negative sign for displacements and velocities in the negative X-direction (as defined in my calibration curves).
        4. Fixed sign for "SeparationDistanceXYmicrons" by reversing the order of needle and bead coordinates
        5. Added more plots for drift velocities in all directions to compare them. 
    v 8.00 2019-08-12..14
        1. Adjusted to allow the option of using silicone oils. 
        2. Corrected Separation Distance problem!!! 
        3. Modified the code to minimize opening and reopening of the ND2 file and output folders many times. 
    v 7.00:
        1. Function Name changed from PlotForceDisplacement_V_6_0() to MTcalibrationPlotForceDisplacement()  on 2019-05-30
        2. Replaced Some variable names to make them more understandable.
    TO DO:
        ******3. Added the possibility of passing bead and tip coordinates if they are present already.
    
    Older Editions:
    v. 6.00:    **plotForceDisplacement_V_6 will have the following corrections/updates: 2018-04-28, and thereafter. V 5.0 is skipped
        1. Introduced a temporal shift between Flux and Camera Exposure signals to allow it to be custom.
            NOTE: IF flux signal is ahead of the camera signal, it will generate an error, I need to work on that part of the code later.
        2. Increased the Flux Noise ratio to 3 GS to give extra buffer for noise
        3. Updated the final Output file to include the Frame Shift to the very end.  
        4. Adjusted the Drift Velocity detection to detect "OFF Segments" since the Null Flux is forced to change on purpose!!
            Based on experiments that showed that the Null Flux shifts after the first cycle, and that the amoutn of the shift changes with time. 
            Extract that valuel from the header of the data file. V10.00 and later for LabVIEW files. Otherwise, Set that value equal to 0.

        Written by Waddah Moghram, PhD Candidate in Biomedical Engineering at the University of Iowa,
            on 4/28-29/2018, First the Null Drift issue due to cycle shift, and also due to Flux Signal lagging behind the camera's by 7-9 cycles. See detailed notes above.
            on 1/18/2018 and therafter to incorporate the viscosity of glycerol properly. See detailed notes below.
            on 11/7/2017 and thereafter to plot the magnetic bead coordinates after cleaning it up. See detailed notes below.
        Inputs: Non Externally. Internally, they are:
            Check the outline of the header below.
        Output are CompiledData, SensorData, CleanSensorData, TipXY
            CompiledData
            SensorData
            CleanSensorData
            TipXY

        Latest CompiledData Columns as of 1/25/2018 contain the following Columns :     
            1. Index, 2. Flux Reading (V), 3. Current Reading (Amp or V)   % (Dropped Camera Exposure since all frame are exposesd (i.e., > 3.0 V))
            4. Beads X- & 5. Y- Coordinates  (in Image Cooridinates, not Cartesian Coordinates, and in microns)
            6. Tip X- & 7. Y- Coordinates  (in Image Cooridinates, not Cartesian Coordinates, and in microns)
            8. Separation Distance between the bead and the needle tip (in microns)
            9. dT or time intervals between frames (in seconds)
            10. Bead X- & 11. Y- Resultant Velocities  (in Image Cooridinates, not Cartesian Coordinates, and in microns/seconds)
            12. Resultant Bead Velocity (Not Corrected for Drift, in microns/second)
            13. Resultant Force Calculated (Not Corrected for Drift, in microns/second). 
            14. Bead X- & 15. Y- Drift Velocities for OFF segments & Average drift for ON segments
            16. Bead X- & 17. Y- No Drift Velocities for OFF segments & Average drift for ON segments subtracted from original velocities
            18. Resultant Bead Velocity (Corrected for Drift, in microns/second)
            19. Resultant Force (Corrected for Drift, in nN)
            20. Magnetic Flux (in Gs) through all frames, and 21. the Flux Status (0/1/-1)

        V4.00 
                2017-11-07:
                    1. Evaluate the drift velocity in the OFF segments
                    2. Adjust for the drift velocity in bead velocities in ON segments
                    3. Invoke ExtractTipCoordinates v4.0 to track tip pole coordinates over time, if not output file is found already
                    4. Add a header to the compiled file -- or at least a file that states what the outputs are
                        5. Correct the program so that it gives the user a second chance if
                            the input is not correct instead of having to repeat the program from the
                            beginning.
                1/18/2018
                    6. Invoke functions that calculate glycerol viscosity more accurately based on temperature and relative humidity of the air
                    7. Overhaul the entire code/program to make it more readable and user-friendly
                    8. Update the file to reflect the updates in the LabView files generated by v.8.0 and later. (UPDATE Read_Sensor_Data)
                1/19/2018
                    9. Invoke the radius of the magnetic bead based on the value & other header values
                1/23/2018
                    10. Invoke First & Final Frames & Node ID in here already unless the files are found
                    11. Think about any dimensions mismatch between Beads & Tips Files.
                1/31/2018
                    12. Fixed glitch that shifted sensor data frames by one.
                    13. Added Compiled filed Info file

        V3.00:
            1. Invoke ExtractTipCoordinates v2.0 to track tip coordinates over time
            2. Includes these coordinates in the compiles files and change the
            headers accordingly.

        V2.10:
            1. clean up the transient points by excluding points where the bead is still drifting. (NOT NEEDED)
            2. Use vector notation to account for bead velocity with response to the separation distance vector. (NOT Anymore)
            3. Try to correct the program so that it gives the user a second chance if
            the input is not correct instead of having to repeat the program from the
            beginning.(INCOMPLTE)

        V2.00: invoked the following functions:
          1. ExactBeadCoordinates_v1_0.m
          2. ExactTipCoordinates_v1_0.m
            It will also open LabVIEW-generated data files and clean up the data
            points based on the following criteria:
                1. identify Camera Shutter sequences. 
                2. Match those with frames
                3. For each frame, assign the respective values of fluxes
                4. Classify Frames based on the state of flux: ON/OFF/Transient

         Older Compiled Data Format (TO BE UPDATED TO REFLECT DRIFT VELOCITIES AS WELL).
            Compiled Data Columns are: (numbers are added for clarification here only)
            1. Index	2. Flux (V)	 3. Current (Amp)	4. Bead-x (um)	5. Bead-y (um)    6. Separation distance (um)	7. Bead Velocity (um/s)	8. Force (nN)	9. Flux Status (1/0/-1)
                    NOTE 1: The bead coordinates here are in Cartesian. They have not been flipped back to image coordinates
                    NOTE 2: Output TipXY is also in Cartesian, not image coordinates
    %}
    

%% ================= 3.0 Select the DIC image file that has the tracking output to do the analysis & choose the analysis path =======================    
    commandwindow;
    clear
    disp('-------------------------- Running "PlotForcedisplacementMcalibration.m" to calibration plots --------------------------')

    dlgQuestion = 'Do you need to open the ND2 DIC Video file to extract file information?';
    dlgTitle = 'Open *.nd2 DIC Video?';
    choiceOpenND2DIC = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No', 'Yes');    
    switch choiceOpenND2DIC    
        case 'Yes'
            disp('Opening the DIC ND2 Video File to get path and filename info to be analyzed')
            [ND2fileDIC,ND2pathDIC] = uigetfile('*.nd2', 'Open the ND2 DIC video file');    
            if ND2fileDIC==0
                error('No file was selected');
            end            
            ND2fullFileName = fullfile(ND2pathDIC,ND2fileDIC);   
            [ND2PathName, ND2FileName, ~] = fileparts(ND2fullFileName);
            OutputPathName = fullfile(ND2pathDIC,'tracking_output');
            fprintf('ND2 DIC Video File to be analyzed is: \n %s \n' , ND2fullFileName);
            disp('----------------------------------------------------------------------------')            
        case 'No'
            if ~exist('OutputPathNameDIC', 'var')
                OutputPathName = pwd;
            end
            % keep going
        otherwise
            error('Could not open *.nd2 file');
    end    
    
    % Saving plots file parts
    [ND2filePath,ND2Name, ND2fileExtension] = fileparts(ND2fullFileName);
    
    %% Other parameters to extract
    trackingFileName = fullfile(ND2PathName ,'tracking_output', 'tracking_parameters.txt');
    try
        fileID = open(trackingFileName);
        fcloser(fileID);
    catch
        % do nothing!
    end
    LastFrame = input('Enter the last Frame that was properly tracked. (See the tracking_parameters.txt file): ');
    FirstFrame = input('Enter the First Frame that was properly tracked. (See the tracking_parameters.txt file): ');
    if isempty(FirstFrame) 
        FirstFrame= 1;
    end
    BeadNodeID =  input('Enter the bead node ID. Node #1 typically): ');
    if isempty(BeadNodeID)
        BeadNodeID = 1;
    end
    fprintf('Bead Node ID is %d. (Typical)\n', BeadNodeID);   
    
%% ================= 1.0 Tracking DIC Add the particle tracking folder to the path if it is not already "... Image Bead Tracking DIC Analysis" =======================
    try       
        BeadFileFullName = fullfile(ND2PathName,'tracking_output','Bead_Coordinates.dat');
        MagBeadCoordinatesXYpixels = load(BeadFileFullName);       
        prompt = sprintf('Bead Coordinates extracted successfully from:\n\t %s', BeadFileFullName);
        disp(prompt)
    catch
        TrackingReadyDIC = false;
        dlgQuestion = 'Do you need to track DIC Images for the Magnetic Bead?';
        dlgTitle = 'Magnetic Bead Track?';
        choiceTrackDIC = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No', 'No');    
        switch choiceTrackDIC 
            case 'No' 
                TrackingReadyDIC = true;
                % Ask about bead coordinates
                dlgQuestion = 'Do you have bead coordinates compiled already from tracked output?';
                dlgTitle = 'Extracting Bead Coordinates?';
                CoordinatesFilesReady = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No. Compile Them Now', 'No. Compile Them Now');    
                switch CoordinatesFilesReady
                    case 'Yes'
                        [BeadFileName, BeadPathName] = uigetfile(fullfile(ND2PathName,'Bead_Coordinates.dat'), 'Select the Bead Coordinates File');
                        BeadFileFullName = fullfile(BeadPathName,BeadFileName);
                        MagBeadCoordinatesXYpixels = load(BeadFileFullName);  
                        disp('Bead Coordinates extracted successfully!')
                    case 'No. Compile Them Now'
                         [ MagBeadCoordinatesXYpixels, BeadCoordinatesFullFileNameMAT, FirstFrame ,LastFrame, OutputPathName] = ExtractBeadCoordinatesDIC(LastFrame, BeadNodeID, FirstFrame, OutputPathName);
                    otherwise
                        disp('Invalid input!');
                        return
                end         
            case 'Yes'
                % do nothing

            otherwise
                error('Magnetic Bead tracking working directory could not be added.')
        end
    % ================= 
        if TrackingReadyDIC == false
            dlgQuestion = {'Do you need to create a mesh for tracking first, or go to tracking directly?', '***You will need to re-run VideoAnalysisDIC.m once finished with tracking***'};
            dlgTitle = 'Create a mesh for tracking?';
            choiceMesh = questdlg(dlgQuestion, dlgTitle, 'Mesh', 'Tracking', 'Mesh');        
            switch choiceMesh
                case 'Mesh'
                    % 1.1 Run particle_mesh_gui to select the particle nodes.
                    particle_mesh_gui; 
                    disp('"----------particle_mesh_gui.m" is opened');         
                    return
                case 'Tracking'
                    % 1.2 Either click 'Launch ImageTrack" in the previous window, or Run the line below to open it.                   
                    rrImageTrackGUI;
                    disp('"--------- rrImageTrackGUI.m" is opened')                
                    return
                otherwise
                  % Do nothing. Continue
            end
            errordlg('---- You will need to re-run VideoAnalysisDIC.m once finished with tracking! ----');       
        end
    end
% ================= 2.0 Add the Bead Analysis tracking folder to the path if it is not already "...MT TFM Analysis"
%     dlgQuestion = 'Do you need to add the path for "MT TFM Analysis" to the Working Directory Path?';
%     dlgTitle = 'add "MT TFM Analysis?"';
%     choiceAddPathAnalysis = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No', 'No');    
%     switch choiceAddPathAnalysis
%         case 'Yes'
%             MTTFanalysisPathName = uigetdir(ND2PathName,'Select "MT TFM Analysis" the working directory for the analysis package."');
%             addpath(genpath(MTTFanalysisPathName));        % Do not include Archive subfolder.
%             fprintf('MT TFM Analysis directory added to the search path: \n %s \n' , MTTFanalysisPathName);
%             disp('----------------------------------------------------------------------------')            
%         case 'No'
%             % do nothing 
%         otherwise
%             error('Could not add the "MT TFM Analysis" Folder to the working path');
%     end 
%     
    %% Magnification Scale pixels/microns
        % Updated on 1/23/2018 to allow the user to choose the magnification based on dynamic referencing of "struct"
    disp('Default calibration experiments is used in here: 40X to save time')
    [MagnificationScale, MagnificationScaleStr] = MagnificationScalesMicronPerPixel(40);                % Make sure it is ZoomChoice{} and not (). Uses Dynamic referencing of a structure ".()"       
    MagnificationTimes = sscanf(MagnificationScaleStr, 'X%d') ;
    
     %% Needle tip coordinates
    try
        TipFileFullName = fullfile(ND2PathName, 'tracking_output','Tip_Coordinates.dat');
        TipCoordinatesXYpixels = load(TipFileFullName);   
        disp('Needle Tip Coordinates extracted successfully!')
    catch
        dlgQuestion = 'Do you have tip coordinates extracted already?';
        dlgTitle = 'Extracting Tip Coordinates?';
        CoordinatesFilesReady = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No. Extract them', 'Yes');    
        switch CoordinatesFilesReady
            case 'Yes'
                [TipFileName,TipPathName] = uigetfile(fullfile(ND2PathName, 'Tip_Coordinates.dat'), 'Select the Tip Coordinates File');
                TipFileFullName = fullfile(TipPathName,TipFileName);
                TipCoordinatesXYpixels = load(TipFileFullName);    
                disp('Needle Tip Coordinates extracted successfully!')
            case 'No. Extract them'
                TipCoordinatesXYpixels = ExtractNeedleTipCoordinatesDIC(ND2fullFileName, OutputPathName, FirstFrame, LastFrame, MagnificationTimes);   % Updated to v6.0 on 4/29/2018
            otherwise
                % Continue. Do nothing
        end      
    end
    %% 1. Extract Bead & Tip Coordinates from the respective separate functions  
    %{
        CONSIDER Creating an If Statement if the file does not exist. 
        For now, just load the files from the current directory.
        Later, come back and invoke them along with the required arguments 
        1. ALSO, consider passing the same parametesr for folders/number of frames tracked to save time if functions are called
    %}

    % For now, Create a similar dimension as BeadXY. Added 11/7/2017
    % might want to review this one more time later 1/23/2018    % WHY??????
    % TipCoordinatesXY = repmat(TipCoordinatesXY, size(BeadCoordinatesXY,1),1);
    ArraySize = min(size(MagBeadCoordinatesXYpixels,1), size(TipCoordinatesXYpixels,1));
    
    % Reducing both arrays to the smaller of the two
    MagBeadCoordinatesXYpixels = MagBeadCoordinatesXYpixels(1:ArraySize,:);
    TipCoordinatesXYpixels = TipCoordinatesXYpixels(1:ArraySize,:);
    
    % Flip the y-coordinates from Cartesian (-y poiting downwards) to Image coordinates ( +y pointing downwards).
    MagBeadCoordinatesXYpixels(:,2) = -MagBeadCoordinatesXYpixels(:,2);
    TipCoordinatesXYpixels(:,2) = -TipCoordinatesXYpixels(:,2);   

    %% 2. Convert the coordinates of both beads and tips *to microns* based on the magnification of the objectives

    % Convert values to **microns** from pixels       
    disp('-------------Converting bead & tip coordinates to **microns** from pixels------------------')        
    TipCoordinatesXYmicrons = TipCoordinatesXYpixels .* MagnificationScale;
    MagBeadCoordinatesXYmicrons = MagBeadCoordinatesXYpixels .* MagnificationScale;
    
    % Note:
        % TipCoordinatesXY(1,1)  = x-coordinate of the needle tip
        % TipCoordinatesXY(1,2)  = y-coordinate of the needle tip
        % BeadCoordinatesXY(:,1) = x-coordinate of the bead over all frames
        % BeadCoordinatesXY(:,2) = y-coordinate of the bead over all frames

    %% 3. Evaluating the observed separation distances between the bead & needle tip now. This includes both ON & OFF segments
    % so far it is defined as Sqrt( difference between bead & tip coordinates)
    % **CONSIDER REVIEWING THIS, how the separation distance is defined
    disp('----------------------')
    disp('Calculating separation distance between needle and tip pole.')
    
    % Reversed on 2019-08-27. Needle is to the right of the bead in my experiments. Hence, needle has higher positive x value
    SeparationDistanceXYmicrons(:,1) = TipCoordinatesXYmicrons(1:ArraySize,1) - MagBeadCoordinatesXYmicrons(1:ArraySize,1);               % Separation distance in the x-direction between needle tip and bead. Adjusted on 11/7/2017 to subtract columsn
    SeparationDistanceXYmicrons(:,2) = TipCoordinatesXYmicrons(1:ArraySize,2) - MagBeadCoordinatesXYmicrons(1:ArraySize,2);               % Separation distance in the x-direction between needle tip and bead. 
    
    % Separation distance between the bead and needle tip (distances are now in microns). Updated on 2019-08-27 by WIM
    SeparationDistanceResultantMicrons = sign(SeparationDistanceXYmicrons(1:ArraySize,1)) .* (sqrt(SeparationDistanceXYmicrons(1:ArraySize,1).^2 + SeparationDistanceXYmicrons(1:ArraySize,2).^2));     % Verified by measuring distances in ImageJ. SeparationDistance in any given frame. First item is the original point, Frame 1 tracked is Index 2
 
    
	%% 4. Now calculating bead displacement between ALL frames (or maybe variation in separation distance between frames instead?)
    % Shuffle until later or wait until displacement due to drift is accounted for?
%         % Calculating differences in separation between subsequent frames.
%         % Very First element is lost when taking differences between frames
% 
%         % Formula below assumes that separation distances between frames are in line with each other which is approximately true, but not exact
% 
%         % SeparationDistanceResultantMicrons1 = SeparationDistanceResultantMicrons(1:end-1,1);
%         % SeparationDistanceResultantMicrons2 = SeparationDistanceResultantMicrons(2:end,1);
%         % dSepDistance = SeparationDistanceResultantMicrons2 - SeparationDistanceResultantMicrons1;
    disp('----------------------')
    disp('Calculating bead displacement between ALL frames.')    

    % Adjusted displacement formula based on Bead Coordinates directly between subsequent frames. 
    BeadXY1stFrameMicrons = MagBeadCoordinatesXYmicrons(1:end-1,:);                      % Frame "1"
    BeadXY2ndFrameMicrons = MagBeadCoordinatesXYmicrons(2:end,:);                        % Frame "2" (Stagger the datapoints)
    
    TipXY2ndFrameMicrons = TipCoordinatesXYmicrons(2:end,:);                                                  % Frame "2" to match Bead Ones for later Output
    
    DisplacementAllXYmicrons = BeadXY2ndFrameMicrons - BeadXY1stFrameMicrons;                        % Bead displacement between frames in x- & y-directions.         % First element is lost when taken differences between two subsequent frames.
    % Updated on 2019-08-27. To give velocities (and hence for in the negative direction as negative). 
    DisplacementAllResultantMicrons = sign(DisplacementAllXYmicrons(:,1)) .* sqrt((DisplacementAllXYmicrons(:,1)).^2 +(DisplacementAllXYmicrons(:,2).^2));       %Nothing Fancy. Just regular distance formula between two points
    % Old one below
%      DisplacementAllResultantMicrons =  sqrt((DisplacementAllXYmicrons(:,1)).^2 +(DisplacementAllXYmicrons(:,2).^2));       %Nothing Fancy. Just regular distance formula between two points
    



    %% 5.1. Opening & Loading actual timeframes. These were extracted from the MetaData of the *.nd2 files. 
        % Otherwise, we could have used the average timestamp, and generated a complete array.
        % So far, it seems that there is hardly any difference between frames
        % (~25.00 ms) with that much accuracy according to timestamps
    disp('----------------------')
    disp('Loading timestamps.')         
    TimeStampsAllFrames = ND2TimeFrameExtract(ND2fullFileName);
    
    %% 5.2. Calculating differences in Timestamps between Frames.  
        % First element is lost when taken differences between two subsequent frames.
        % ******** See if I can use the exposure pulses intead of time? 10/6/2017
        % Also see if I can ask the user to specify the metadta file and extract the exact column.
        % Otherwise, see if I can default to a certain value of the average frame rates per seconds.  
    disp('Calculating difference between timestamps.') 
    
    TimeStamps1stFrame = TimeStampsAllFrames(1:end-1,1);                       %Frame "1"
    TimeStamps2ndFrame = TimeStampsAllFrames(2:end,1);                         %Frame "2" (Stagger the timepoints)
    TimeEntireIntervals = TimeStamps2ndFrame - TimeStamps1stFrame;                 %Time difference between subsequent frames. One less timepoint. 
   
    % Only taking the stamps that correspond to the number of frames tracked 10/6/2017. Subsequent Frames are after bead collides with tip or when they move too fast to be tracked correctly (1/31/2018 - WIM).
    if size(TimeEntireIntervals,1)  > size(DisplacementAllResultantMicrons,1) 
        % Difference between subsequent time stamps
        TimeEntireIntervals = TimeEntireIntervals(1:size(DisplacementAllResultantMicrons,1));         
    else 
       disp('Timestamps are shorter than the number of images tracked');
    end 

    %% 6.1 Calculating Instantaneous OVERALL or NET or ALL Velocities between ALL (ON & OFF) frames subsequent frames in (Microns/second)
    % Shuffle this step until later?
    %  **Not corrected for drift velocity yet. as of 1/23/2018*
    disp('----------------------')
    disp('Calculating unadjusted net velocities of bead in all frames.')  
    VelocityAllXY =  DisplacementAllXYmicrons./TimeEntireIntervals;
    
    VelocityAllResultant1 = DisplacementAllResultantMicrons ./ TimeEntireIntervals;    
%     % Another way to calculate the over. It matches the expression above visually
%     % but using isequal() or taking the difference yield noise-level values close to machine epsilon 1/24/2018
% Fixed on 2019-08-27
%    VelocityAllResultant2 = sign(VelocityAllXY(:,1)) .* sqrt((VelocityAllXY(:,1)).^2 +(VelocityAllXY(:,2).^2))

    %% 7. Loading & Extracting the Sensor Data & Header, and cleaning
    % Invoke Function to Read *.txt data file generated by LabVIEW. 
    % Updated on 2019-08-23
    disp('----------------------')
    [SensorData, HeaderData, HeaderTitle, SensorDataFullFilename, OutputPathName, ~, SamplingRate]  = ReadSensorDataFile(ND2pathDIC, 0, OutputPathName);                 
    
    % 8. Clean up the Sensor Data
    disp('----------------------')
    % Clean those data points to only those that have camera exposure
    % For later, see if you can just read it directly if it exists instead of just loading it everytime. Although it is very rapid actually
    [CleanSensorData , ExposurePulseCount, EveryNthFrameDIC, CleanedSensorDataFullFileNameDAT_DIC, ~, ~, ~] = CleanSensorDataFile(SensorData, [], SensorDataFullFilename, SamplingRate);
 
    % 9. Display the Sensor Data Header & Select Magnetic Bead Diameter.
    % Asking the user for the diameter of the magnetic beads.
    % Extract diameter from the header of the file header if possible.
    % Added on 1/24/2018 by WIM.
    format compact
    disp('-----Header Title-----')
    celldisp(HeaderTitle);
    disp('----------------------')
    
    %----------------- added by 2019-08-23. Comment lines below, and uncomment lines have sscanf()
    n = 0;
    %-------------------------
    
    
   %% 10. Extract important header values    
    % 10.1 Extract Bead Diameter from the header if possible.
%     HeaderIndexStr = input('Enter two index numbers separated by whitespace that contain Magnetic Bead Diameter [Default 5 3]: ', 's');
%      [Indices, n, ErrMsg] = sscanf(HeaderIndexStr, '%u');
    if n ~= 2 || ~isempty(ErrMsg)                % Rows & Columns are required, or if an error occured
        try 
            Indices = [5; 3];                   % Default Index values latest header in v8.0 as of 1/24/2018
            disp('Default index is attempted.')
            BeadDiameter = HeaderData(Indices(1), Indices(2));
        catch
            BeadDiameter = 2.8;                 % For my experiments so far, I am using a 2.8 micron Dynabeads from invitrogen. Use this value if nothing else works
            disp('A default bead diameter is selected.')
        end
    else
        try
            BeadDiameter = HeaderData(Indices(1), Indices(2));
        catch
            BeadDiameter = 2.8;                 % For my experiments so far, I am using a 2.8 micron Dynabeads from invitrogen. Use this value if nothing else works
            disp('A default bead diameter is selected.')
        end
    end
    fprintf('The MAGNETIC BEAD DIAMETER given is: %.1f microns\n', BeadDiameter);    % disp(sprintf) is replaced with fprintf()
    Radius = BeadDiameter/2;
    

    % 10.2 Retrieve temperature if possible from the header too before evaluating viscosity    
    disp('----------------------')
%     HeaderIndexStr = input('Enter two index numbers separated by whitespace that contain Temperature [Default 5 1]: ', 's');
%     [Indices, n, ErrMsg] = sscanf(HeaderIndexStr, '%u');
    if n ~= 2 || ~isempty(ErrMsg)               % Rows & Columns are required, or if an error occured
        try 
            Indices = [5; 1];                   % Default Index values latest header in v8.0 as of 1/24/2018
            disp('Default index is attempted.')
            Temperature = HeaderData(Indices(1), Indices(2));
        catch
            Temperature = 23;                   % For my experiments so far, average room temperature in the microscope room is ~23.0 degree C
            disp('A default temperature is selected.')
        end
    else 
        try 
            Temperature = HeaderData(Indices(1), Indices(2));
        catch
            Temperature = 23;                   % For my experiments so far, average room temperature in the microscope room is ~23.0 degree C
            disp('A default temperature is selected.')
        end
    end
    fprintf('The TEMPERATURE given is: %.1f°C \n', Temperature);
    
    % 10.3. and RH if possible from the header too before evaluating viscosity
    disp('----------------------')
%     HeaderIndexStr = input('Enter two index numbers separated by whitespace that contain Relative Humidity [Default 5 4]: ', 's');
%     [Indices, n, ErrMsg] = sscanf(HeaderIndexStr, '%u');
    if n ~= 2 || ~isempty(ErrMsg)               % Rows & Columns are required, or if an error occured
        try 
            Indices = [5; 4];                   % Default Index values latest header in v8.0 and later as of 4/24/2018
            disp('Default index is attempted. BE CAUTIOUS!!')
            RelativeHumidity = HeaderData(Indices(1), Indices(2));
        catch
            RelativeHumidity = 0.30;            % This default value fluctuates a lot based on day/season and even time of the day. 
            disp('A default relative humidity is selected. BE CAUTIOUS!!')
        end
    else 
        try 
            RelativeHumidity = HeaderData(Indices(1), Indices(2));
        catch
            RelativeHumidity = 0.30;                   % For my experiments so far, average room temperature in the microscope room is ~23.0 degree C
            disp('A default relative humidity is selected. BE CAUTIOUS!!')
        end
    end
    PercentRelativeHumidity = RelativeHumidity * 100;
    fprintf('The RELATIVE HUMIDITY given is: %3.0f%%. \n', PercentRelativeHumidity);
   
    % 10.4 Other Flux Values in the header:
    %FLUX SETPOINT when it is ON (in Gs), relative to FLUX OBSERVED ZERO
    disp('----------------------')
%     HeaderIndexStr = input('Enter two index numbers separated by whitespace that contain Flux (ON) Setpoint [Default 4 1]: ', 's');
%     [Indices, n, ErrMsg] = sscanf(HeaderIndexStr, '%u');
    if n ~= 2 || ~isempty(ErrMsg)               % Rows & Columns are required, or if an error occured
        try 
            Indices = [4; 1];                   % Default Index values latest header in v8.0 and later as of 4/24/2018
            FluxSetPoint = HeaderData(Indices(1), Indices(2));
        catch
            disp('Error reading Flux Setpoint')
        end
    else 
        try 
            FluxSetPoint = HeaderData(Indices(1), Indices(2));
        catch
            disp('Error reading Flux Setpoint')
        end
    end
    fprintf('The FLUX (ON) SETPOINT in the experiment is: %g Gs. \n', FluxSetPoint);

    %NULL FLUX OBSERVED when it is OFF (in Gs). This value is set visually at the beginning of the experiment.
    disp('----------------------')
%     HeaderIndexStr = input('Enter two index numbers separated by whitespace that contain Null Flux Observed [Default 4 2]: ', 's');
%     [Indices, n, ErrMsg] = sscanf(HeaderIndexStr, '%u');
    if n ~= 2 || ~isempty(ErrMsg)               % Rows & Columns are required, or if an error occured
        try 
            Indices = [4; 2];                   % Default Index values latest header in v8.0 and later as of 4/24/2018
            NullFluxObserved = HeaderData(Indices(1), Indices(2));
        catch
            disp('Error reading Null Flux Observed')
        end
    else 
        try 
            NullFluxObserved = HeaderData(Indices(1), Indices(2));
        catch
            disp('Error reading Null Flux Observed')
        end
    end
    fprintf('The NULL FLUX OBSERVED in the experiment is: %g Gs. \n', NullFluxObserved);
    
    %NULL FLUX CORRECTION after the first cycle. This value is based on a sigmoidal fit based on bead experiments. 
    disp('----------------------')
%     HeaderIndexStr = input('Enter two index numbers separated by whitespace that contain Null Flux Correction [Default 6 1]: ', 's');
%     [Indices, n, ErrMsg] = sscanf(HeaderIndexStr, '%u');
    if n ~= 2 || ~isempty(ErrMsg)               % Rows & Columns are required, or if an error occured
        try 
            Indices = [6; 1];                   % Default Index values latest header in v8.0 and later as of 4/24/2018
            NullFluxCorrection = HeaderData(Indices(1), Indices(2));
        catch
            disp('Error reading Null Flux Observed')
        end
    else 
        try 
            NullFluxCorrection = HeaderData(Indices(1), Indices(2));
        catch
            disp('Error reading Null Flux Observed')
        end
    end
    fprintf('The NULL FLUX CORRECTION in the experiment is: %g Gs. \n', NullFluxCorrection);
    
    %MAGNETIC SENSOR ZERO POINT based on previous calibration (in V). 
    disp('----------------------')
%     HeaderIndexStr = input('Enter two index numbers separated by whitespace that contain Magnetic Sensor Calibrated Zero [Default 1 1]: ', 's');
%     [Indices, n, ErrMsg] = sscanf(HeaderIndexStr, '%u');
    if n ~= 2 || ~isempty(ErrMsg)               % Rows & Columns are required, or if an error occured
        try 
            Indices = [1; 1];                   % Default Index values latest header in v8.0 and later as of 4/24/2018
            SensorZeroPoint = HeaderData(Indices(1), Indices(2));
        catch
            disp('Error reading Flux Setpoint')
        end
    else 
        try 
            SensorZeroPoint = HeaderData(Indices(1), Indices(2));
        catch
            disp('Error reading Flux Setpoint')
        end
    end
    fprintf('The MAGNETIC SENSOR CALIBRATED ZERO point for the sensor is: %g V. \n', SensorZeroPoint);
    
    %MAGNETIC SENSOR SENSITIVITY based on previous calibration (in V/Gs). 
    disp('----------------------')
%     HeaderIndexStr = input('Enter two index numbers separated by whitespace that contain Magnetic Sensor Sensitivity [Default 1 2]: ', 's');
%     [Indices, n, ErrMsg] = sscanf(HeaderIndexStr, '%u');
    if n ~= 2 || ~isempty(ErrMsg)               % Rows & Columns are required, or if an error occured
        try 
            Indices = [1; 2];                   % Default Index values latest header in v8.0 and later as of 4/24/2018
            SensorSensitivity = HeaderData(Indices(1), Indices(2));
        catch
            disp('Error reading Magnetic Sensor Sensitivity')
        end
    else 
        try 
            SensorSensitivity = HeaderData(Indices(1), Indices(2));
        catch
            disp('Error reading Magnetic Sensor Sensitivity')
        end
    end
    fprintf('The MAGNETIC SENSOR SENSITIVITY for the sensor is: %g V/Gs. \n', SensorSensitivity);     
    
%     %Inclination Angle of the needle. Not used for calibrations. Since the needle is at the same level as the bead, but it will included. 
%     disp('----------------------')
% %     HeaderIndexStr = input('Enter two index numbers separated by whitespace that contain Needle Inclination Angle in degrees [Default 5 2]: ', 's');
%     [Indices, n, ErrMsg] = sscanf(HeaderIndexStr, '%u');
%     if n ~= 2 || ~isempty(ErrMsg)               % Rows & Columns are required, or if an error occured
%         try 
%             Indices = [5; 2];                   % Default Index values latest header in v8.0 and later as of 4/24/2018
%             InclinationAngle = HeaderData(Indices(1), Indices(2));
%         catch
%             disp('Error reading needle inclination angle')
%         end
%     else 
%         try 
%             InclinationAngle = HeaderData(Indices(1), Indices(2));
%         catch
%             disp('Error reading needle inclination angle')
%         end
%     end
%     fprintf('The NEEDLE INCLINATION ANGLE is: %g degrees. \n', InclinationAngle);     
    
    
    %% 11. Evaluate the viscosity of glycerol based on temperature and percent relative humidity 
    % Use the values embedded in the header for temperature and relative humidity and call the function that gets the viscosity 1/23/2018
    % No need for double interpolation of temperture. RH vs. Percent Weight glycerol is fairly fixed over a wide range of tempreatures.
    % First finding the glycerol mass fraction of glycerol based on the relative humidity
    disp('----------------------')
    
    dlgQuestion = 'Select the fluid used for this experiment';
    listStr = {'glycerol', '10,000 cSt silicone oil', '1,000 cSt silicone oil'};
    FluidChoice = listdlg('ListString', listStr, 'PromptString',dlgQuestion, 'InitialValue', 2, 'SelectionMode' ,'single');    
    FluidChoiceStr = listStr{FluidChoice};                 % get the names of the string.   
    
    switch FluidChoiceStr
        case 'glycerol'
            ExperimentGlycerolMassFraction = PercentRHPercentGlycerolSolution(PercentRelativeHumidity) / 100;
            % Next finding the viscosity based on glycerol mass fraction and temperature
            [Density, Viscosity] = densityViscosityWaterGlycerolSolution(ExperimentGlycerolMassFraction, Temperature);  
        case '1,000 cSt silicone oil'
            Viscosity = 0.971;                   %in Pa.s., 1,000 cSt, density of 0.971 at 25 degree C. Density and viscosity do no change significantly over time.
        case '10,000 cSt silicone oil'
            Viscosity = 9.71;                   % in Pa.s, 10,000 cSt, density of 0.971 at 25 degree C. Density and viscosity do no change significantly over time.
        otherwise
            Viscosity = input('Please enter the viscosity of the fluid in Pa.s');
    end
    
    %% 12. Calculating & Plotting the RESULTANT FORCES that beads experience based on the ***Stoke's Einstein Formula****
    %{
        All = (i.e., magnetic + drift force)
        The Units are going to be in nN
        Viscosity (in Pa.s), Velocity (in micron/second), Radius (in micron). 
        Force will be in nanonewtons (nN) in that case
        If you remove the (10^-3 or /1000) factor, force will be in picoNewtons.    
    %}
    
    ForceAllResultant = 6.* pi().* Viscosity .* VelocityAllResultant1 * Radius /1000;
   

    %% 13.1 Now asking if there is a Shift between the Flux and Camera Signals. Most likely due to DAQ problems. on 4/28/2018
    % ADDED by Waddah Moghram on 4/28/2018 to account for Flux lagging behind the camera capture. This issue is most likely due to Channel lag. 
%     % Until that problem is fixed. This will fix lag here.
    disp('----------------------')
    FluxSignalShiftExists = upper(input('Was there a shift between flux and camera signal? [Y/N/Flux Shift in Gs] (Default = N): ', 's'));   
    if strcmpi(FluxSignalShiftExists,'Y')
        prompt = 'Enter the number of frames that flux is ahead or lagging. Use Negative for lagging flux signal: ';
        FluxSignalShift = input(prompt);
        if isempty(FluxSignalShift)
            % Number of Frames shifted. Use Negative if the Flux is lagging.
            FluxSignalShift = -7;    %  Based on my inspection on Calibration Run 01 on Conducted 4/22/2018. See Electronic notes for more details. 4/28/2018 WIM.
        end
    elseif strcmpi(FluxSignalShiftExists,'N') || isempty(FluxSignalShiftExists)       
        FluxSignalShift = 0;
    elseif isnumeric(str2double(FluxSignalShiftExists))
        FluxSignalShift = str2double(FluxSignalShiftExists);
    else
        disp('No flux shift is present!');
        FluxSignalShift = 0;
    end
    %-------------
       FluxSignalShift = 0;         % Added on 2019-08-28 to save time. delete this part and uncomment the part above if needed.
    %-----------
    if FluxSignalShift > 0 
       FluxSignalShiftPrompt = sprintf('Flux signal is ahead the camera signal by %d frames.', FluxSignalShift);
    elseif FluxSignalShift < 0 
       FluxSignalShiftPrompt = sprintf('Flux signal is behind the camera signal by %d frames.', FluxSignalShift);
    else
       FluxSignalShiftPrompt = sprintf('Flux signal is matching with the camera signal. Shift is %d frames.', FluxSignalShift);
    end
    
    %% 13.2 Now Compiling First part of Data from both image tracking and sensor data into one variable.
    % Add Header to compiled data file & close it before DLM write
    CompiledDataHeader = {'Index', 'Flux Reading (V)', 'Current Reading (Amp or V)',...
        'Bead-x (um)', 'Bead-y (um)', 'Tip-x (um)', 'Tip-y (um)', 'Separation Distance (um)',...
        'Time Intervals (s)', ...
        'v-x,All (um/s)', 'v-y,All (um/s)', 'v-Net,All (um/s)', 'F-Net,All (nN)',...
        'v-x,Drift (um/s)', 'v-y,Drift (um/s)', ...
        'v-x,No Drift (um/s)', 'v-y,No Drift (um/s)', 'v-Net,No Drift (um/s)','F-Net,No Drift (nN)', ...
        'Flux (Gs)', 'Flux Status (0/1/-1)'
        };
    
    disp('----------------------')
    disp('Compiling Image Tracking Data with Sensor Output Data...in Progress'); 
    clear CompiledData
    CompiledDataSize = size(DisplacementAllResultantMicrons,1);                        % Size of the compiled datapoints won't be more than the images tracked
    if size(CleanSensorData,1) > size(DisplacementAllResultantMicrons,1)              % If More Sensor Data Points are collected than there are frames tracked, then fine
        if FluxSignalShift <=0                                                  % Flux Signal is either matching or lagging behind the camera tracking images. 
            % First Remove those extra frames from CleanSensorData. Reverse the negative sign for FluxSignalShift.    % Modified on 4/28/2018 to account for Flux Signal Shift, as a temporary fix until I figure out what is going on (most likely a DAQ issue).
            CleanSensorData = CleanSensorData(-FluxSignalShift+1:end,:);
            
            % CompiledData will contain the following Columns :
            % NOTE: The following (Index, Flux and Current Reading should match temporally 
            % 1. Index, 2. Flux Reading (V),  3. Current Reading (Amp or V)     % (Dropped Camera Exposure since all frame are exposesd (i.e., > 3.0 V)= 4th Column)
            CompiledData = CleanSensorData(2:CompiledDataSize+1,1:3);           % Corrected on 1/31/2018 to indicate that the first frame disappears in these calculations. Its data will be inclued in Info file.
                         
            % NOTE: All of the following are matched temporally with the image tracking information
            % 4. Beads X- & 5. Y- Coordinates  (in Image Cooridinates, not Cartesian Coordinates, and in microns)
            CompiledData = [CompiledData,BeadXY2ndFrameMicrons]; 
            % 6. Tip X- & 7. Y- Coordinates  (in Image Cooridinates, not Cartesian Coordinates, and in microns)
            CompiledData = [CompiledData,TipXY2ndFrameMicrons]; 
            % 8. Separation Distance between the bead and the needle tip (in microns)
            CompiledData = [CompiledData,SeparationDistanceResultantMicrons(2:end)];    
            % 9. dT or time intervals between frames (in seconds)
            CompiledData = [CompiledData, TimeEntireIntervals];  
            % 10. Bead X- & 11. Y- Resultant Velocities  (in Image Cooridinates, not Cartesian Coordinates, and in microns/seconds)
            CompiledData = [CompiledData, VelocityAllXY]; 
            % 12. Resultant Bead Velocity (Not Corrected for Drift, in microns/second)
            CompiledData = [CompiledData, VelocityAllResultant1];
            % 13. Resultant Force Calculated (Not Corrected for Drift, in microns/second). 
            CompiledData = [CompiledData, ForceAllResultant];
        else                    % IF THE FLUX SIGNAL IS AHEAD OF THE CAMERA'S. NEED TO BE ADDED. WILL TAKE CARE OF IT LATER 4/28/2018            

        end 
    else                            % Not enough data is collected with images tracked.
        fprintf('Last Frame Tracked Frame is: #%d. Last image datapoint captured Frame is: #%d and its datapoint index is: %d in the raw data file. \nNot enough data points collected! Do this experiment again! (OR use less of the frames tracked to match the number of data points collected)', size(DisplacementAllResultantMicrons,1),size(CleanSensorData,1),CleanSensorData(end,1)); 
    end                             % End of if statement
    disp('Compiling Image Tracking Data with Sensor Output Data complete!');
    disp('-------------------------------------------------------------------------------');
    
    %% 14. Now that we have all the data compiled in one variable, we can do all sorts of manipulations
    %{
        key flux values are extracted
        Convert Flux Values from V to Gs. 
        Stick to CompiledData and not CleanSensorData. 
        Adjusting for NullFluxObserved
        There are intentially more signals to ensure enough force cycles were observed.
    %}
    
    % CompiledData(:,2) are the flux readings
    % FluxReadingsStatus: 1st column is the Relative Flux (in Gs), and 2nd column is the Flux Status that will be added in the next section
    
    FluxReadingsStatus(:,1) = ((CompiledData(:,2) - SensorZeroPoint)./ SensorSensitivity) - NullFluxObserved;
    
    %Initialize 2nd column, for Flux Reading State
    FluxReadingsStatus(:,2) = 0;                 

    %% 15. Now, classifying Flux Readings to one of three states: ON (1), OFF (0), or Transient (-1)
    % These values are inserted into the 2nd column FluxReadingsStatus next to the Relative Flux Value (in Gs).
    % Assume: Magnetic Flux Sensor noise level band is ~ ± 1.5-1.75 Gs normally.
    % Increase FluxNoiseLevelGs to 2-3 Gs if you want less noise around setpoints, especially if it is close to 0 (and not DeGaussed properly, and so forth).
    
    disp('----------------------')
%     
%     FluxNoiseLevelPrompt = upper(input('Do you want to change the Flux Noise Level? [Y/N/Flux Value] (If No is chosen, default noise level = 3.0 Gs): ', 's'));   
%     if strcmpi(FluxNoiseLevelPrompt,'Y')
%         prompt = 'Enter the Flux Noise Level in Gs (Default = 3.0 Gs): ';
%         FluxNoiseLevelGs = input(prompt);
%         if isempty(FluxNoiseLevelGs)
%             FluxNoiseLevelGs = 3;           % based on trial and error 4/29/2018
%         end
%     elseif isnumeric(str2double(FluxNoiseLevelPrompt))          % Updated on 2019-08-26
%         FluxNoiseLevelGs = str2double(FluxNoiseLevelPrompt);
%     else
%         disp('Default option is chosen of 3.0 Gs!');
%         FluxNoiseLevelGs = 3;
%     end
    FluxNoiseLevelGs = 2; % 2 Gs. Modified by WIM on 2019-08-28
%     FluxNoiseLevelGs = 3;
    % FluxNoiseLevelGs = 1.75;
    
    % Updated on 4/29/2018 to reflect the Null Flux Correction scheme.
    FirstCycleON = 0;               %Set it to false at firt
    
    for i = 1:CompiledDataSize                                                          % Going through all the compiled data points
        if FirstCycleON == 0                                                            
            if abs(FluxReadingsStatus(i,1) - FluxSetPoint) < FluxNoiseLevelGs              % Flux is ON within the noise level band.              
                FluxReadingsStatus(i,2) = 1;
                FirstCycleON = 1;                                                           % First cycle is ON
            elseif abs(FluxReadingsStatus(i,1)) < FluxNoiseLevelGs                          % Flux is OFF within the noise level band. Null Flux is 0 in this case.
                FluxReadingsStatus(i,2) = 0;
            else                                                                            % Transient Value (or Sensor error).
                FluxReadingsStatus(i,2) = -1;                                               % Reverted back to -1 on 1/24/2018.    % 10/9/2017 Treat Transient as 0 and leave out
            end 
        else 
            if abs(FluxReadingsStatus(i,1) - FluxSetPoint) < FluxNoiseLevelGs              % Flux is ON within the noise level band.              
                FluxReadingsStatus(i,2) = 1;
                FirstCycleON = 1;                                                           % First cycle is ON
            elseif abs(FluxReadingsStatus(i,1) - (NullFluxCorrection - NullFluxObserved)) < FluxNoiseLevelGs                          % Check if it is within the noise level after the "offset from Null Flux"
                FluxReadingsStatus(i,2) = 0;
            else                                                                            % Transient Value (or Sensor error).
                FluxReadingsStatus(i,2) = -1;                                               % Reverted back to -1 on 1/24/2018.    % 10/9/2017 Treat Transient as 0 and leave out
            end 
        end 
    end  

    % Create Logicals for ON/OFF Status based on the values just compiled for plots.
    % Transient values will be 0 (or false) in both logicals
    FluxON = logical(FluxReadingsStatus(:,2) == 1);
    FluxOFF = logical(FluxReadingsStatus(:,2) == 0);
    
    %% 16. Now adding the drift velocity filter (averaged over the previous OFF segments, and the same if it is OFF), & append to CompiledData

    % *** INCOMPLETE *** %
    % % % Modified on 4/28/2018 to add some buffer time on either end of the OFF segment 
% %     prompt = 'Enter the number of frames to discard from each end of the OFF segment as buffer. \nEnter 0 if none wanted [Default = 4 Frames]: ';
% %     DriftVelocityBuffer = input(prompt);
% %     if isempty(DriftVelocityBuffer)
% %         DriftVelocityBuffer = 4;                %  Based on a rate of 15-25 ms, that will be 60-100 ms on either end of the OFF segment
% %     end   
% %     
    
    % Is flux on? If so, keep. 
    % If flux is off, calculate the average drift velocity (du,dv), and adjust for both from the subsequent ON segment
    % If Transient, just discard the whole thing altogether.
 
    % Array Operations are faster than for loops?
    
    % Initializing variables
    FirstFluxOFF = true;
    CurrentDriftVelocities = [];    %This will be built up until the segment is OFF, then it is averaged
    CurrentDriftVelocitiesAVG = 0;  %No drift velocity initially
    % VelocityDriftXY will have the actual value for the OFF segments, but an averaged value from the OFF segments in the ON/Transient
    % Take a look at the Excel sheet that compares the values of average vs. overall velocity based on position at beginning and end of segment
    % The average velocity will minimize any errors over time, although both values seem identical for the experiment that I conducted to the 5th decimal of a micron!!!
    % Also assuming that dT will average out eventually to the frame rate. So no need to worry about dT of the drift
    
    VelocityDriftXY =  zeros(CompiledDataSize,2);               
    
    % Loop is similar to loop in CleanSensorDataFile_v_4_0() to find drift velocity. bead velocity in OFF segments, and averaged previous off during next ON
    for i = 1:CompiledDataSize       
        if FluxOFF(i) == 1                                                                      % Flux is in OFF Status
            if FirstFluxOFF == true
                % disp (i);                                                                 % Displaying the index of the first value of OFF segment
                % Reset vx-drift and vy-drift & FirstFluxOFF datapoint indicator
                FirstFluxOFF = false;
            else 
                % This is the 2nd OFF Value
                % Append dT if using coordinates & displacements if these are used to calculate drift
            end
            % drift value is the same as regular velocity in OFF segments
            VelocityDriftXY(i,:) = CompiledData(i,10:11);                                   
            CurrentDriftVelocities = [CurrentDriftVelocities; CompiledData(i,10:11)];
            CurrentDriftVelocitiesAVG = mean(CurrentDriftVelocities);                       % Might not be the most efficient code
        else                                                                                % Flux is either ON or Transient
            CurrentDriftVelocities = []; 
            VelocityDriftXY(i,:) =  CurrentDriftVelocitiesAVG;                              % Use the value from the previous segment
            % Reset that value to allow going into the loop next time. 
            FirstFluxOFF = true;                              
        end     	% End of if statemnets      
    end             % End of for loop

    % 14. Bead X- & 15. Y- Drift Velocities for OFF segments & Average drift for ON segments
    % (in Image Cooridinates, not Cartesian Coordinates, and in microns/seconds)
    CompiledData = [CompiledData, VelocityDriftXY]; 
    
    % Evaluating the resultant Velocity of drift.
    % Updated by Waddah Moghram on 2019-08-28
    VelocityDriftResultant = sign(VelocityDriftXY(:,1)) .* sqrt((VelocityDriftXY(:,1)).^2 +(VelocityDriftXY(:,2).^2));  
    % Old one
%     VelocityDriftResultant = sqrt((VelocityDriftXY(:,1)).^2 +(VelocityDriftXY(:,2).^2));  
    %% 17. Calculating VELOCITIES WITH NO DRIFT , and their RESULTANT, and adding to compiled file
    % Velocities due to magnetic force by excluding average drift velocities in ON segments & adding to compiled file
    % Assuming all other forces are negligible including **inertial forces** of the bead in glycerol.
    VelocityNoDriftXY = VelocityAllXY - VelocityDriftXY;
    
    % 16. Bead X- & 17. Y- No Drift Velocities for OFF segments & Average drift for ON segments subtracted from original velocities
    % (in Image Cooridinates, not Cartesian Coordinates, and in microns/seconds)
    CompiledData = [CompiledData, VelocityNoDriftXY]; 

    
    % Evaluating the resultant Velocity without drift
    VelocityNoDriftResultant = sqrt((VelocityNoDriftXY(:,1)).^2 +(VelocityNoDriftXY(:,2).^2));  
    
    % 18. Resultant Bead Velocity (Corrected for Drift, in microns/second)
    CompiledData = [CompiledData, VelocityNoDriftResultant]; 

    %% 18. Calculating RESULTANT FORCES WITH DRIFT EXCLUDED that beads experience based on the Stoke's-Einstein Formula, and adding to compiled file
    % The Units are going to be in nN
    % Viscosity (in Pa.s), Velocity (in micron/second), Radius (in micron). 
    % Force will be in nanonewtons (nN) in that case
    % If you remove the (10^-3 or /1000) factor, force will be in picoNewtons.    
    
    ForceNoDriftAllResultant = 6.* pi().* Viscosity .* VelocityNoDriftResultant * Radius /1000;
    
    % 19. Resultant Force (Corrected for Drift, in nN)
    CompiledData = [CompiledData, ForceNoDriftAllResultant];  
   
     %% 20.2 Plotting Data with Drift excluded, 
     CalibrationInfo = sprintf('in %s solution. RH = %d%% at %.1f', FluidChoiceStr, RelativeHumidity * 100, Temperature);    
     CalibrationInfo = [CalibrationInfo, char(176),'C'];        % Add a degree at the end
     
%      % 20.2.1. both ON/OFF Flux
%      figure('color', 'w') 
%      plot(CompiledData(:,8),CompiledData(:,19), 'r.');
%      xlabel('Distance (micron)'); ylabel('Force (nN)');
%      Caption1 = sprintf('Calibration Curve with ALL Flux Values for %d Gs - Drift Excluded', FluxSetPoint);
%      title(Caption1);

     % 20.2.2. Try to see what happens with Flux ON
    figHandleForceNetON = figure('color', 'w');               %Open another figure
    SeparationDistanceMicronON = CompiledData(FluxON,8);
    Force_nN_ON = CompiledData(FluxON,19);
    
    plot(SeparationDistanceMicronON, Force_nN_ON, 'b.', 'MarkerSize', 6);
    xlabel('Separation Distance \delta (\mum)'); ylabel('Force (nN)');
    set(findobj(figHandleForceNetON,'type', 'axes'), 'FontSize',10, 'FontWeight','Bold', 'LineWidth',1, 'XMinorTick', 'on', 'YMinorTick', 'on', 'TickDir', 'out');     % Make axes bold
    box(gca, 'off')
    xlim([0, max(SeparationDistanceMicronON)]);   
    Caption2 = sprintf('Calibration Curve with Flux ON %d Gs, drift-adjusted,', FluxSetPoint);     % Drift Excluded
    title({Caption2, CalibrationInfo});
    figureFileName2 = fullfile(OutputPathName, 'Calibration Force');
    
    
    savefig(figHandleForceNetON, figureFileName2, 'compact');
%     saveas(figHandleForceNetON, figureFileName2, 'eps'); 
    saveas(figHandleForceNetON, figureFileName2, 'png');
    
    % Bead velocity vs. time
    figHandle3 = figure('color', 'w');               %Open another figure
    plot(SeparationDistanceMicronON,CompiledData(FluxON,18), 'b.', 'MarkerSize', 6);
    xlabel('Separation Distance \delta (\mum)'); ylabel('Bead Velocity (\mum/s)');
    set(findobj(figHandle3,'type', 'axes'), 'FontSize',10, 'FontWeight','Bold', 'LineWidth',1, 'XMinorTick', 'on', 'YMinorTick', 'on', 'TickDir', 'out');     % Make axes bold
    box(gca, 'off')
    xlim([0, max(SeparationDistanceMicronON)]);   
    Caption2 = sprintf('Calibration Curve with Flux ON %d Gs, drift-adjusted,', FluxSetPoint);     % Drift Excluded
    title({Caption2, CalibrationInfo});
    figureFileName3 = fullfile(OutputPathName, 'Calibration Bead Velocity');
       
    savefig(figHandle3, figureFileName3, 'compact');
%     saveas(figHandle3, figureFileName3, 'eps'); 
    saveas(figHandle3, figureFileName3, 'png');
      
    %% -------------- INCOMPLETE OUTLIER REMOVAL PART ---------------
%     dlgQuestion = 'Do you need to removed outliers?';
%     dlgTitle = 'Remove Outliers?';
%     choiceRemoveOutliers = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No', 'No');    
%     switch choiceRemoveOutliers
%         case 'Yes'
%             [~, OutlierIndicesVelocity] = rmoutliers(SeparationDistanceMicronON, 'mean');
%             [~, OutlierIndicesForce] = rmoutliers(SeparationDistanceMicronON, 'mean');
%             OutlierIndices = unique([find(OutlierIndicesVelocity), find(OutlierIndicesForce)]);
%             CompiledDataOutliersIncluded = CompiledData;
%             CompiledDataTmp = CompiledData(~OutlierIndices,:);
%             
%             FluxONOutliersIncluded = FluxON;
%             FluxON = FluxON(~OutlierIndices);
%             
%             
%             clear CompiledData
%             CompiledData = CompiledDataTmp;
%             
%             figure(figureHandle2); 
%             title({Caption2, strcat(CalibrationInfo, '--Outlier Included')});
%                          % 20.2.2. Try to see what happens with Flux ON
%             forceFieldParameters.thickness = figure('color', 'w');               %Open another figure
%             plot(SeparationDistanceMicronON,Force_nN_ON, 'r.', 'MarkerSize', 5);
%             xlabel('Distance (\mum)'); ylabel('Force (nN)');
%             set(findobj(forceFieldParameters.thickness,'type', 'axes'), 'FontSize',10, 'FontWeight','Bold', 'LineWidth',1);     % Make axes bold
%             box(gca, 'off')
%             xlim([0, max(SeparationDistanceMicronON)]);   
%             Caption2 = sprintf('Calibration Curve with Flux ON %d Gs', FluxSetPoint);     % Drift Excluded
%             title({Caption2, CalibrationInfo});
%             figureFileName2 = fullfile(OutputPathNameDIC, 'Calibration Force');
%             savefig(forceFieldParameters.thickness, figureFileName2, 'compact');
%         %     saveas(forceFieldParameters.thickness, figureFileName2, 'eps'); 
%             saveas(forceFieldParameters.thickness, figureFileName2, 'png');
% 
%             % Bead velocity vs. time
%             figHandle3 = figure('color', 'w');               %Open another figure
%             plot(SeparationDistanceMicronON,CompiledData(FluxON,18), 'r.', 'MarkerSize', 5);
%             xlabel('Distance (\mum)'); ylabel('Bead Velocity (\mum/s)');
%             set(findobj(figHandle3,'type', 'axes'), 'FontSize',10, 'FontWeight','Bold', 'LineWidth',1);     % Make axes bold
%             box(gca, 'off')
%             xlim([0, max(SeparationDistanceMicronON)]);   
%             Caption2 = sprintf('Calibration Curve with Flux ON %d Gs', FluxSetPoint);     % Drift Excluded
%             title({Caption2, CalibrationInfo});
%             figureFileName3 = fullfile(OutputPathNameDIC, 'Calibration Bead Velocity');
%             savefig(figHandle3, figureFileName3, 'compact');
%         %     saveas(figHandle3, figureFileName3, 'eps'); 
%             saveas(figHandle3, figureFileName3, 'png');
% 
%             
%         case 'No'
%           % Continue
%         otherwise
%             return
%     end
%% ------------------------      
%    
%          % 20.2.2. Try to see what happens with Flux OFF
%     figHandleForceNetOFF = figure('color', 'w');               %Open another figure
%     plot(CompiledData(FluxOFF,8),CompiledData(FluxOFF,19), 'r.', 'MarkerSize', 5);
%     xlabel('Distance (\mum)'); ylabel('Force (nN)');
%     set(findobj(figHandleForceNetOFF,'type', 'axes'), 'FontSize',10, 'FontWeight','Bold', 'LineWidth',1);     % Make axes bold
%     box(gca, 'off')
%     xlim([0, max(CompiledData(FluxOFF,8))]);   
%     Caption2 = sprintf('Calibration Curve with Flux OFF %d Gs', FluxSetPoint);     % Drift Excluded
%     title({Caption2, CalibrationInfo});
%     figureFileNameFluxOFF = fullfile(OutputPathNameDIC, 'Calibration Force Flux OFF');
%     savefig(figHandleForceNetOFF, figureFileNameFluxOFF, 'compact');
% %     saveas(forceFieldParameters.thickness, figureFileName2, 'eps'); 
%     saveas(figHandleForceNetOFF, figureFileNameFluxOFF, 'png');
%     
%              % 20.2.2. Try to see what happens with Flux OFF
%     figHandleVelocityNetOFF = figure('color', 'w');               %Open another figure
%     plot(CompiledData(FluxOFF,8),CompiledData(FluxOFF,18), 'r.', 'MarkerSize', 5);
%     xlabel('Distance (\mum)'); ylabel('Bead Velocity (\mum/s)');
%     set(findobj(figHandleVelocityNetOFF,'type', 'axes'), 'FontSize',10, 'FontWeight','Bold', 'LineWidth',1);     % Make axes bold
%     box(gca, 'off')
%     xlim([0, max(CompiledData(FluxOFF,8))]);   
%     Caption2 = sprintf('Calibration Curve with Flux OFF %d Gs', FluxSetPoint);     % Drift Excluded
%     title({Caption2, CalibrationInfo});
%     figureFileNameFluxOFF = fullfile(OutputPathNameDIC, 'Calibration Force Flux OFF');
%     savefig(figHandleVelocityNetOFF, figureFileNameFluxOFF, 'compact');
% %     saveas(forceFieldParameters.thickness, figureFileName2, 'eps'); 
%     saveas(figHandleVelocityNetOFF, figureFileNameFluxOFF, 'png');
%     
    

     %% 20.3 Plotting Tip movement over separation distance for all values. Just as a check
     % Added on 2019-08-23 to find the size of the image.  Make sure BIoformats for MATLAB is in the search path.
     ND2Handle = bfopen(ND2fullFileName); 
     ImageSizePixels =  size(ND2Handle{1}{1});           % from 1st frame. Assume all frames have the same size. Axes flipped. 
     ImageSizeMicrons = ImageSizePixels * MagnificationScale; 

%      
%      figHandle6 = figure('color', 'w');   
%      plot(CompiledData(:,8),CompiledData(:,6), 'r.');
%      xlabel('Distance (micron)'); ylabel('Tip x-Position (Micron)');
%     xlim([0, max(CompiledData(:,8) )]);
%     ylim([0, max(ImageSizeMicrons(2))]);
%      Caption4 = sprintf('Tip motion in X-Direction over distance for %d Gs.', FluxSetPoint);        
%      Caption5 = sprintf('Scale is %f micron/pixel', MagnificationScale);
%      set(findobj(figHandle6,'type', 'axes'), 'FontSize',10, 'FontWeight','Bold', 'LineWidth',1, );     % Make axes bold
%      title({Caption4, Caption5});
%     % %    
%      figure('color', 'w')              
%      plot(CompiledData(:,8),CompiledData(:,7), 'r.', 'MarkerSize', 1);
%      xlabel('Distance (micron)'); ylabel('Tip y-Position (Micron)');
%      xlim([0, max(CompiledData(:,8) )]);
%      ylim([0, max(ImageSizeMicrons(1))]);
%      Caption4 = sprintf('Tip motion in y-Direction over distance for %d Gs.  ', FluxSetPoint);        
%      Caption5 = sprintf('Scale is %f micron/pixel', MagnificationScale);
%      title({Caption4, Caption5});
%      
    figHandle7 = figure('color', 'w');
    plot(CompiledData(FluxON,6),CompiledData(FluxON,7), 'g*', 'MarkerSize', 1);
    xlabel('x-position (\mum)'); ylabel(' y-Position (\mum)');
    hold on
    plot(CompiledData(FluxOFF,6),CompiledData(FluxOFF,7), 'mo', 'MarkerSize', 1);
       
    plot(CompiledData(:,4),CompiledData(:,5), 'm.', 'MarkerSize', 1);  
    plot(CompiledData(FluxON,4),CompiledData(FluxON,5), 'b*', 'MarkerSize', 1);  
    plot(CompiledData(FluxOFF,4),CompiledData(FluxOFF,5), 'r.', 'MarkerSize', 1);     

    xlim([0, max(ImageSizeMicrons(2))]);
    ylim([0, max(ImageSizeMicrons(1))]);
    set(findobj(figHandle7,'type', 'axes'), 'FontSize',10, 'FontWeight','Bold', 'LineWidth',1, 'XMinorTick', 'on', 'YMinorTick', 'on', 'TickDir', 'out');     % Make axes bold
    legend('Tip, Flux ON', 'Tip Flux OFF', 'Bead Flux ON', 'Bead Flux OFF', 'location', 'best', 'fontSize', 8)
    Caption4 = sprintf('Tip motion in x- and y-directions over distance for %d Gs', FluxSetPoint);        
    Caption5 = sprintf('Scale is %f micron/pixel', MagnificationScale);
    title({Caption4, Caption5});
    figureFileName7 = fullfile(OutputPathName, 'Calibration Bead-Tip Position');
    
    savefig(figHandle7, figureFileName7, 'compact');
%     saveas(figHandle7, figureFileName7, 'eps'); 
    saveas(figHandle7, figureFileName7, 'png');
    
%% Merging bead and needle coordinates Video. Added on 2019-08-23
%----------------------
% Merging bead and needle coordinates. Added on 2019-08-23
% dlgQuestion = 'Do you want to plot a superimposed needle/bead tip coordinates over the images?';
% dlgTitle = 'Track bead and tip coordinates over videos?';
% OverimposeTrackingChoice = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No', 'No');
OverimposeTrackingChoice = 'No'
%---------------------
switch OverimposeTrackingChoice
    case 'Yes'
       % Merging bead and needle coordinates. Added on 2019-08-23
        dlgQuestion = 'Do you want to save merged bead/needle tip coordinates as videos or as image sequence?';
        dlgTitle = 'Video vs. Image Sequence?';
        plotTypeChoice = questdlg(dlgQuestion, dlgTitle, 'Videos', 'Images', 'Neither', 'Videos');

        switch plotTypeChoice
            case 'Videos'
                saveVideo = true;
                dlgQuestion = 'Select video format.';
                listStr = {'Archival', 'Motion JPEG AVI', 'Motion JPEG 2000','MPEG-4','Uncompressed AVI','Indexed AVI','Grayscale AVI'};
                DisplacementVideoChoice = listdlg('ListString', listStr, 'PromptString',dlgQuestion, 'InitialValue', 2, 'SelectionMode' ,'Single');    
                DisplacementVideoChoice = listStr{DisplacementVideoChoice};

                finalSuffix = 'Bead&Tip_Tracked';
                videoFile = fullfile(OutputPathName, finalSuffix);        
                writerObj = VideoWriter(videoFile, DisplacementVideoChoice);
                if ~isempty(TimeEntireIntervals)
                    FrameRate = 1/mean(TimeEntireIntervals);
                    writerObj.FrameRate = 1/FrameRate;
                else
                    try                    
                        timeStamps = ND2TimeFrameExtract(ND2fullFileName);
                        FrameRate = 1/mean(timeStamps(2:end)-timeStamps(1:end-1));
                        writerObj.FrameRate = FrameRate;
                    catch
                        writerObj.FrameRate = 40;           % Assume 40 frames per second
                    end 
                end
            case 'Images'
                saveVideo = false;
                dlgQuestion = 'Select image format.';
                listStr = {'TIF', 'FIG', 'EPS','MAT data'};
                ImageChoice = listdlg('ListString', listStr, 'PromptString',dlgQuestion, 'InitialValue', 2, 'SelectionMode' ,'multiple');    
                ImageChoice = listStr(ImageChoice);                 % get the names of the string.   
                if  strcmpi(plotTypeChoice, 'Images')
                    for ii = 1:numel(ImageChoice)
                        tmpImageChoice =  ImageChoice{ii};
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
                                TrackedDisplacementPathFIG = fullfile(OutputPathName, 'NeedleTip_FIG');
                                if ~exist(TrackedDisplacementPathFIG,'dir'), mkdir(TrackedDisplacementPathFIG); end
                                fprintf('Tracked Displacement  Path - FIG is: \n\t %s\n', TrackedDisplacementPathFIG);
                                try
                                    TrackedDisplacementPathFIGcount =  numel(dir(fullfile(TrackedDisplacementPathFIG, '*.fig')));
                                catch
                                    TrackedDisplacementPathFIGcount = 0;
                                end
                            case 'EPS'
                                TrackedDisplacementPathEPS = fullfile(OutputPathName, 'NeedleTip_EPS');
                                if ~exist(TrackedDisplacementPathEPS,'dir'), mkdir(TrackedDisplacementPathEPS); end
                                fprintf('Tracked Displacement  Path - EPS is: \n\t %s\n', TrackedDisplacementPathEPS);
                                try
                                    TrackedDisplacementPathEPScount =  numel(dir(fullfile(TrackedDisplacementPathEPS, '*.fig')));                            
                                catch
                                    TrackedDisplacementPathEPScount = 0;
                                end
                            case 'MAT data'
                                TrackedDisplacementPathMAT = fullfile(OutputPathName, 'NeedleTip_MAT');  
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

        figHandle = figure('color', 'w');
        for ii = 1:ArraySize
            imshow(ND2Handle{1}{ii}, []);
            hold on
            plot(CompiledData(ii,6)/MagnificationScale,CompiledData(ii,7)/MagnificationScale, 'r.', 'MarkerSize', 10);
            plot(CompiledData(ii,4)/MagnificationScale,CompiledData(ii,5)/MagnificationScale, 'b.', 'MarkerSize', 10);

            ImageHandle = getframe(figHandle);
            Image_cdata = ImageHandle.cdata;        
            if saveVideo
                % open the video writer
                open(writerObj);            
                % Need some fixing 3/3/2019
                writeVideo(writerObj, Image_cdata);
            else            % Saving images
                CurrentTipImageName = sprintf('BeadTipP%04d.tif', ii);             %  TipP****.tiff will be the subsequent frames 
                CurrentTipImageFullName = fullfile(OutputPathName,CurrentTipImageName);      

                % Anonymous function to append the file number to the file type. 
                if ~exist('CurrentImageFileName','var')
                    fString = ['%0' num2str(floor(log10(LastFrame))+1) '.f'];
                    FrameNumSuffix = @(frame) num2str(frame,fString);
                    CurrentImageFileName = strcat('BeadTipP', FrameNumSuffix(CurrentFrame));
                end
                for ii = 1:numel(ImageChoice)
                    tmpImageChoice =  ImageChoice{ii};
                    switch tmpImageChoice
                        case 'TIF'
                            TrackedDisplacementPathTIFname = fullfile(TrackedDisplacementPathTIF ,[CurrentImageFileName , '.tif']);
                            imwrite(Image_cdata, TrackedDisplacementPathTIFname);
                        case 'FIG'
                            TrackedDisplacementPathFIGname = fullfile(TrackedDisplacementPathFIG ,[CurrentImageFileName, '.fig']);
                            hgsave(figHandle, TrackedDisplacementPathFIGname,'-v7.3')
                        case 'EPS'
                            TrackedDisplacementPathEPSname = fullfile(TrackedDisplacementPathEPS ,[CurrentImageFileName, '.eps']);               
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
            end
       end
    otherwise
        % Do nothing, continue
end
     %% 20.4 Plotting Net Drift Velocity over separation distance. Just as a check
%      figure('color', 'w')               %Open a third figure
%      plot(CompiledData(:,8), VelocityDriftResultant, 'r.');
%      xlabel('Distance (micron)'); ylabel('Net Drift Velocity  (Micron/Sec)');
%      Caption4 = sprintf('Bead Net Drift Velocity for %d Gs.', FluxSetPoint);        
%      title({Caption4,' (Average for ON Segments & Same Values for OFF Segments)'});
%    
% Added by WIM on 2019-08-26
    figHandleSepDist = figure('color', 'w');
    plot(TimeStampsAllFrames(1:CompiledDataSize), CompiledData(:,8), 'k.-', 'MarkerSize', 1);
    hold on
    plot(TimeStampsAllFrames(FluxON), SeparationDistanceMicronON, 'b.', 'MarkerSize', 1);
    plot(TimeStampsAllFrames(FluxOFF), CompiledData(FluxOFF,8), 'r.', 'MarkerSize', 1);
        
    xlabel('Time (sec)'); ylabel('Separation Distance \delta (\mum)');
    xlim([0, max(TimeStampsAllFrames)]);
    ylim([0, max(CompiledData(:,8))]);
    box(gca, 'off')
    set(findobj(figHandleSepDist,'type', 'axes'), 'FontSize',10, 'FontWeight','Bold', 'LineWidth',1 , 'XMinorTick', 'on', 'YMinorTick', 'on', 'TickDir', 'out');     % Make axes bold
    Caption4 = sprintf('Bead-Tip separation distance for %d Gs', FluxSetPoint);        
    Caption5 = sprintf('Scale is %f micron/pixel', MagnificationScale);
    title({Caption4, Caption5})
    legend('All', 'Flux ON', 'Flux OFF','Location', 'best','fontSize', 8);
    figHandleSepDistFileName = fullfile(OutputPathName, 'Calibration Bead-Tip Separation');
    savefig(figHandleSepDist, figHandleSepDistFileName, 'compact');
%     saveas(figHandleSepDist, figHandleSepDistFileName, 'eps'); 
    saveas(figHandleSepDist, figHandleSepDistFileName, 'png');

    %%
% Added by WIM on 2019-08-26
    figHandleBeadVelocity = figure('color', 'w');
    figHandleBeadVelocity1 = subplot(3,1,1);
    plot(CompiledData(:,8),CompiledData(:,18), '.-', 'MarkerSize', 5);
    plot(SeparationDistanceMicronON,CompiledData(FluxON,18), 'b.', 'MarkerSize', 5);
    hold on
    plot(CompiledData(FluxOFF,8),CompiledData(FluxOFF,18), 'r.', 'MarkerSize', 5);
    legend('ON', 'OFF', 'location', 'best','fontSize', 8);
%     xlabel('Distance (\mum)'); 
    ylabel('v_{net} (\mum/sec)');
    xlim([0, max(CompiledData(:,8))]);  
    ylim([min(CompiledData(:,18)), max(CompiledData(:,18))]);
    box(gca, 'off')
    set(findobj(figHandleBeadVelocity,'type', 'axes'), 'FontSize',8, 'FontWeight','Bold', 'LineWidth',1, 'XMinorTick', 'on', 'YMinorTick', 'on', 'TickDir', 'out');     % Make axes bold
    Caption4 = sprintf('Bead velocity, v, vs. Separation Distance for %d Gs. Flux ON & OFF', FluxSetPoint);        
    Caption5 = sprintf('Drift excluded. Scale is %f micron/pixel', MagnificationScale);
    title({Caption4, Caption5});
    %----- INCOMPLETE TO ADD MAX VALUE TO AXES'
%     XTicksCurrent = get(gca, 'XTick');
%     XticksAllStr = num2str([XTicksCurrent, max(CompiledData(:,8))]);
    %-----------------

    figHandleBeadVelocity2 = subplot(3,1,2);
    plot(SeparationDistanceMicronON,CompiledData(FluxON,16), 'b.', 'MarkerSize', 5);
    hold on
    plot(CompiledData(FluxOFF,8),CompiledData(FluxOFF,16), 'r.', 'MarkerSize', 5);
    legend('ON', 'OFF', 'location', 'best','fontSize', 8);
%     xlabel('Distance (\mum)'); 
    ylabel('v_{x} (\mum/sec)');
    xlim([0, max(CompiledData(:,8))]);  
    ylim([min(CompiledData(:,16)), max(CompiledData(:,16))]);
    box(gca, 'off')
    set(findobj(figHandleBeadVelocity,'type', 'axes'), 'FontSize',8, 'FontWeight','Bold', 'LineWidth',1, 'XMinorTick', 'on', 'YMinorTick', 'on', 'TickDir', 'out');     % Make axes bold
    
    figHandleBeadVelocity3 = subplot(3,1,3);
    plot(SeparationDistanceMicronON,CompiledData(FluxON,17), 'b.', 'MarkerSize', 5);
    hold on
    plot(CompiledData(FluxOFF,8),CompiledData(FluxOFF,17), 'r.', 'MarkerSize', 5);
    legend('ON', 'OFF', 'location', 'best','fontSize', 8);
%     xlabel('Distance (\mum)'); 
    ylabel('v_{y} (\mum/sec)');
    xlim([0, max(CompiledData(:,8))]);
    ylim([min(CompiledData(:,17)), max(CompiledData(:,17))]);
    xlabel('Separation Distance, \delta (\mum)');
    XTicksCurrent = get(gca, 'XTick');
    XticksAllStr = num2str([XTicksCurrent, max(CompiledData(:,8))]);
    box(gca, 'off')
    set(findobj(figHandleBeadVelocity,'type', 'axes'), 'FontSize',8, 'FontWeight','Bold', 'LineWidth',1, 'XMinorTick', 'on', 'YMinorTick', 'on', 'TickDir', 'out');     % Make axes bold
%     NewPosition = [1, 1, 1, 2] .* figHandleBeadVelocity.Position;                           % try to double the height. 
%     set(figHandleBeadVelocity, 'Position', NewPosition); 
    
    figHandleBeadDisplFileName = fullfile(OutputPathName, 'Calibration Bead Velocities No Drift');
    ImageHandle = getframe(figHandleBeadVelocity);     
    Image_cdata = ImageHandle.cdata;
    
    hgsave(figHandleBeadVelocity, strcat(figHandleBeadDisplFileName, '.fig'),'-v7.3');
    imwrite(Image_cdata, strcat(figHandleBeadDisplFileName, '.png'));
%             print(figHandleBeadVelocity, AnalysisBigDeltaFileNameEPS,'-depsc')   

%% Drift Velocities included in overall velocity
% Added by WIM on 2019-08-26
    figHandleBeadVelocity = figure('color', 'w');
    figHandleBeadVelocity1 = subplot(3,1,1);
    plot(SeparationDistanceMicronON,CompiledData(FluxON,12), 'b.', 'MarkerSize', 5);
    hold on
    plot(CompiledData(FluxOFF,8),CompiledData(FluxOFF,12), 'r.', 'MarkerSize', 5);
    legend('ON', 'OFF', 'location', 'best','fontSize', 8);
%     xlabel('Distance (\mum)'); 
    ylabel('v_{net} (\mum/sec)');
    xlim([0, max(CompiledData(:,8))]);  
    ylim([min(CompiledData(:,12)), max(CompiledData(:,12))]);
    box(gca, 'off')
    set(findobj(figHandleBeadVelocity,'type', 'axes'), 'FontSize',8, 'FontWeight','Bold', 'LineWidth',1, 'XMinorTick', 'on', 'YMinorTick', 'on', 'TickDir', 'out');     % Make axes bold
    Caption4 = sprintf('Bead velocity, v, vs. Separation Distance for %d Gs. Flux ON & OFF', FluxSetPoint);        
    Caption5 = sprintf('Drift included. Scale is %f micron/pixel', MagnificationScale);
    title({Caption4, Caption5});
    %----- INCOMPLETE TO ADD MAX VALUE TO AXES'
%     XTicksCurrent = get(gca, 'XTick');
%     XticksAllStr = num2str([XTicksCurrent, max(CompiledData(:,8))]);
    %-----------------

    figHandleBeadVelocity2 = subplot(3,1,2);
    plot(SeparationDistanceMicronON,CompiledData(FluxON,10), 'b.', 'MarkerSize', 5);
    hold on
    plot(CompiledData(FluxOFF,8),CompiledData(FluxOFF,10), 'r.', 'MarkerSize', 5);
    plot(SeparationDistanceMicronON,CompiledData(FluxON,14), '-', 'LineWidth', 2, 'Color', [1.00,0.41,0.16]);
%     xlabel('Distance (\mum)'); 
    ylabel('v_{x} (\mum/sec)');
    xlim([0, max(CompiledData(:,8))]);  
    ylim([min(CompiledData(:,10)), max(CompiledData(:,10))]);
    box(gca, 'off')
    set(findobj(figHandleBeadVelocity,'type', 'axes'), 'FontSize',8, 'FontWeight','Bold', 'LineWidth',1, 'XMinorTick', 'on', 'YMinorTick', 'on', 'TickDir', 'out');     % Make axes bold    
    legend('Flux ON', 'Flux OFF', 'Avg. Prev. OFF', 'location', 'best','fontSize', 7);    
    
    figHandleBeadVelocity3 = subplot(3,1,3);
    plot(SeparationDistanceMicronON,CompiledData(FluxON,11), 'b.', 'MarkerSize', 5);
    hold on
    plot(CompiledData(FluxOFF,8),CompiledData(FluxOFF,11), 'r.', 'MarkerSize', 5);
    plot(SeparationDistanceMicronON,CompiledData(FluxON,15), '-', 'LineWidth', 2, 'Color', [1.00,0.41,0.16]);
%     xlabel('Distance (\mum)'); 
    ylabel('v_{y} (\mum/sec)');
    xlim([0, max(CompiledData(:,8))]);
    ylim([min(CompiledData(:,11)), max(CompiledData(:,11))]);
    xlabel('Separation Distance \delta (\mum)');
    XTicksCurrent = get(gca, 'XTick');
    XticksAllStr = num2str([XTicksCurrent, max(CompiledData(:,8))]);
    box(gca, 'off')
    set(findobj(figHandleBeadVelocity,'type', 'axes'), 'FontSize',8, 'FontWeight','Bold', 'LineWidth',1, 'XMinorTick', 'on', 'YMinorTick', 'on', 'TickDir', 'out');     % Make axes bold
    
    figHandleBeadDisplFileName = fullfile(OutputPathName, 'Calibration Bead Velocities with Drift');
    ImageHandle = getframe(figHandleBeadVelocity);     
    Image_cdata = ImageHandle.cdata;
    
    hgsave(figHandleBeadVelocity, strcat(figHandleBeadDisplFileName, '.fig'),'-v7.3');
    imwrite(Image_cdata, strcat(figHandleBeadDisplFileName, '.png'));
%             print(figHandleBeadVelocity, AnalysisBigDeltaFileNameEPS,'-depsc')   


    %%
% Added by WIM on 2019-08-26
    figHandleBeadDispl = figure('color', 'w');
    figHandleBeadDispl1 = subplot(3,1,1);
    plot(SeparationDistanceMicronON,CompiledData(FluxON,18), 'b.', 'MarkerSize', 5);
    hold on
    plot(CompiledData(FluxOFF,8),CompiledData(FluxOFF,18), 'r.', 'MarkerSize', 5);
    legend('ON', 'OFF', 'location', 'best','fontSize', 8);
%     xlabel('Distance (\mum)'); 
    ylabel('v_{net} (\mum/sec)');
    xlim([0, max(CompiledData(:,8))]);  
    ylim([min(CompiledData(:,18)), max(CompiledData(:,18))]);
    box(gca, 'off')
    set(findobj(figHandleBeadDispl,'type', 'axes'), 'FontSize',8, 'FontWeight','Bold', 'LineWidth',1, 'XMinorTick', 'on', 'YMinorTick', 'on', 'TickDir', 'out');     % Make axes bold
    Caption4 = sprintf('Bead velocity, v, vs. Separation Distance for %d Gs. Flux ON & OFF', FluxSetPoint);        
    Caption5 = sprintf('Scale is %f micron/pixel', MagnificationScale);
    title({Caption4, Caption5});
    %----- INCOMPLETE TO ADD MAX VALUE TO AXES'
%     XTicksCurrent = get(gca, 'XTick');
%     XticksAllStr = num2str([XTicksCurrent, max(CompiledData(:,8))]);
    %-----------------

    figHandleBeadDispl2 = subplot(3,1,2);
    plot(SeparationDistanceMicronON,CompiledData(FluxON,16), 'b.', 'MarkerSize', 5);
    hold on
    plot(CompiledData(FluxOFF,8),CompiledData(FluxOFF,16), 'r.', 'MarkerSize', 5);
    legend('ON', 'OFF', 'location', 'best','fontSize', 8);
%     xlabel('Distance (\mum)'); 
    ylabel('v_{x} (\mum/sec)');
    xlim([0, max(CompiledData(:,8))]);  
    ylim([min(CompiledData(:,16)), max(CompiledData(:,16))]);
    box(gca, 'off')
    set(findobj(figHandleBeadDispl,'type', 'axes'), 'FontSize',8, 'FontWeight','Bold', 'LineWidth',1, 'XMinorTick', 'on', 'YMinorTick', 'on', 'TickDir', 'out');     % Make axes bold
    
    figHandleBeadDispl3 = subplot(3,1,3);
    plot(SeparationDistanceMicronON,CompiledData(FluxON,17), 'b.', 'MarkerSize', 5);
    hold on
    plot(CompiledData(FluxOFF,8),CompiledData(FluxOFF,17), 'r.', 'MarkerSize', 5);
    legend('ON', 'OFF', 'location', 'best','fontSize', 8);
%     xlabel('Distance (\mum)'); 
    ylabel('v_{y} (\mum/sec)');
    xlim([0, max(CompiledData(:,8))]);
    ylim([min(CompiledData(:,17)), max(CompiledData(:,17))]);
    xlabel('Separation Distance \delta (\mum)');
    XTicksCurrent = get(gca, 'XTick');
    XticksAllStr = num2str([XTicksCurrent, max(CompiledData(:,8))]);
    box(gca, 'off')
    set(findobj(figHandleBeadDispl,'type', 'axes'), 'FontSize',8, 'FontWeight','Bold', 'LineWidth',1, 'XMinorTick', 'on', 'YMinorTick', 'on', 'TickDir', 'out');     % Make axes bold

    figHandleBeadDisplFileName = fullfile(OutputPathName, 'Calibration Bead Velocities No Drift');
    ImageHandle = getframe(figHandleBeadDispl);     
    Image_cdata = ImageHandle.cdata;
    
    hgsave(figHandleBeadDispl, strcat(figHandleBeadDisplFileName, '.fig'),'-v7.3');
    imwrite(Image_cdata, strcat(figHandleBeadDisplFileName, '.png'));
%             print(figHandleBeadDispl, AnalysisBigDeltaFileNameEPS,'-depsc')   

    %% 22. Adding Flux Readings & Flux Status to Compiled Data

    % 20. Magnetic Flux (in Gs) through all frames, and 21. the Flux Status (0/1/-1)
    CompiledData = [CompiledData, FluxReadingsStatus];

%% 20.5 Plotting the flux against force in the compiled file together. Added on 4/29/2018 to see how Flux & Force are meshing up
    % Updated on 2019-08-23
    figHandleFluxForceMatch = figure('color', 'w');
    % Plotting the flux
    subplot(2,1,1)
    plot(TimeStampsAllFrames(1:CompiledDataSize), CompiledData(1:CompiledDataSize,20), '.', 'MarkerSize',6)
    PlotTitle = sprintf('Flux ON setpoint is %.0f Gs', FluxSetPoint);
    title({FluxSignalShiftPrompt, PlotTitle})
    hold on
        box(gca, 'off');
    plot(TimeStampsAllFrames(FluxON), CompiledData(FluxON,20), '.', 'MarkerSize',6);
    plot(TimeStampsAllFrames(FluxOFF), CompiledData(FluxOFF,20), '.', 'MarkerSize',6);
    xlabel('Time (s)');ylabel('Flux (Gs)');
    ylim([min(CompiledData(:,20)) - 10, max(CompiledData(FluxOFF,20)) + 10]);
    set(findobj(figHandleFluxForceMatch,'type', 'axes'), 'FontSize',9, 'FontWeight','Bold', 'LineWidth',1, 'XMinorTick', 'on', 'YMinorTick', 'on', 'TickDir', 'out');     % Make axes bold
    xlim([min(TimeStampsAllFrames(1:CompiledDataSize)), max(TimeStampsAllFrames(1:CompiledDataSize))]);
    legend('Flux All', 'FluxON', 'FluxOFF', 'Location', 'east', 'fontSize', 7)
    
    
    subplot(2,1,2)
    % Plo Force
    plot(TimeStampsAllFrames(1:CompiledDataSize), CompiledData(1:CompiledDataSize,13), '.', 'MarkerSize',6); 
    hold on
    plot(TimeStampsAllFrames(FluxON), CompiledData(FluxON,13), '.', 'MarkerSize',6); 
    plot(TimeStampsAllFrames(FluxOFF), CompiledData(FluxOFF,13), '.', 'MarkerSize',6);        
    xlabel('Time (s)');ylabel('Force (nN)');
   
    xlim([min(TimeStampsAllFrames(1:CompiledDataSize)), max(TimeStampsAllFrames(1:CompiledDataSize))]);
    ylim([-2,max(max(CompiledData(1:CompiledDataSize,2)), ceil(max(CompiledData(1:CompiledDataSize,13))))]);
    FluxForceMatchFileName = fullfile(OutputPathName, 'Calibration Force & Flux');
    box(gca, 'off');
    legend( 'Force All', 'Force ON', 'Force OFF', 'location', 'best','fontSize', 7);
    set(findobj(figHandleFluxForceMatch,'type', 'axes'), 'FontSize',9, 'FontWeight','Bold', 'LineWidth',1, 'XMinorTick', 'on', 'YMinorTick', 'on', 'TickDir', 'out');     % Make axes bold
        
    figHandleBeadDisplFileName = fullfile(OutputPathName, 'Calibration Force & Flux');
    ImageHandle = getframe(figHandleFluxForceMatch);     
    Image_cdata = ImageHandle.cdata;
    
    hgsave(figHandleFluxForceMatch, strcat(figHandleBeadDisplFileName, '.fig'),'-v7.3');
    imwrite(Image_cdata, strcat(figHandleBeadDisplFileName, '.png'));
    
    savefig(figHandleFluxForceMatch, FluxForceMatchFileName, 'compact');
%     saveas(figHandleFluxForceMatch, FluxForceMatchFileName, 'eps'); 
    saveas(figHandleFluxForceMatch, FluxForceMatchFileName, 'png');
         
    %% 23. Writing to Compiled Output File with a header

    CompiledDataFullFileNameDAT = fullfile(OutputPathName, 'Calibration Compiled Data.dat');
    CalibrationDataFullFileNameMAT = fullfile(OutputPathName, 'Calibration Compiled Data.mat');
    
    fileID = fopen(CompiledDataFullFileNameDAT, 'w+');      
    fprintf(fileID,'%s\t ', CompiledDataHeader{1:end});
    fprintf(fileID,'\n');
    fclose(fileID);
    
    save(CalibrationDataFullFileNameMAT, 'CompiledDataHeader','CompiledData','CompiledDataSize', 'ND2fileDIC','FirstFrame','LastFrame','BeadNodeID','MagBeadCoordinatesXYpixels','TipCoordinatesXYpixels',...
        'MagnificationScale','MagBeadCoordinatesXYmicrons','TipCoordinatesXYmicrons','SeparationDistanceXYmicrons','SeparationDistanceResultantMicrons', 'ArraySize', 'TimeStampsAllFrames', ...
        'DisplacementAllResultantMicrons','TimeStampsAllFrames','VelocityAllResultant1', 'FluxNoiseLevelGs', 'ForceAllResultant' , 'ForceNoDriftAllResultant','FluidChoiceStr','RelativeHumidity','Temperature', 'HeaderTitle','HeaderData', ...
        'BeadDiameter','CleanSensorData','ExposurePulseCount', 'FluxSetPoint', 'SensorSensitivity', ...
        'VelocityAllXY', 'VelocityDriftXY', 'VelocityNoDriftXY', 'FluxON', 'FluxOFF', 'SeparationDistanceMicronON', 'Force_nN_ON');
%     save(CalibrationDataFullFileNameMAT)                  % takes too much memory    (237 MB)
    % Crude way of saving the output that.
    % will have a lot of trailing zeros for index and flux status, if you using %f flag. Otherwise, use %g flag to remove them.
    dlmwrite(CompiledDataFullFileNameDAT, CompiledData, 'delimiter','\t','precision','%0.8g','-append');          %Remove trailing zeros to minimize memory. Added '-append' on 1/31/2018
    
     %% 21. Accompanying file that embeds: # of frames tracked. Viscosity, Temperature, RH, Density of glycerol, Weight Fraction of glycerol
     % Also includes header of the CompiledDataFile
     % Key Equations and Assumptions? 
     %   MagnificationScale = MagnificationScale.(ZoomChoices{Magnification}); 
    
     % NOTE: A more efficient code would have been to simply printout the prompts from earlier parts of the program here.
     
    CompiledDataInfoFullFileNameDAT  = fullfile(OutputPathName, 'Calibration_Clean_Compiled_Data_Info.dat');
    fileID = fopen(CompiledDataInfoFullFileNameDAT, 'wt');   
    fprintf(fileID, 'Number of frames tracked were %u and one less frame in Clean_Compiled_Data.dat because of difference between subsequent frames. \n', ArraySize);    %NOTE: One frame less since differences are taken. So Frame #1 disappears
    fprintf(fileID, 'Skipped First Frame Data are: Index = %u, Flux Reading (V) = %0.8g, and Current Reading (Amp or V) = %0.8g\n', CleanSensorData(1,1),CleanSensorData(1,2),CleanSensorData(1,3));
    fprintf(fileID, 'Number of frames captured are: %u\n', length(TimeStampsAllFrames));
    fprintf(fileID, 'Number of camera exposure pulses = %u\n', ExposurePulseCount);
    fprintf(fileID, 'Note: Number of camera exposure pulses is more than actual frames captured, but never less.\n');
    fprintf(fileID, 'Magnification used is %s, and its scale factor = %1.7f microns/pixel. \n'  , MagnificationScaleStr , MagnificationScale);
    
    % Rest are copied & modified from previous messages. Review if changed later. 1/31/2018 WIM
    fprintf(fileID, 'The bead magnetic diameter given is: %.1f microns.\n', BeadDiameter);    % disp(sprintf) is replaced with fprintf()
    fprintf(fileID, 'The temperature given is: %.1f°C.\n', Temperature);
    fprintf(fileID, 'The relative humidity given is: %3.0f%%.\n', PercentRelativeHumidity);
    fprintf(fileID, 'The flux setpoint in the experiment is: %g Gs.\n', FluxSetPoint);
    fprintf(fileID, 'The null flux observed in the experiment is: %g Gs.\n', NullFluxObserved);
    fprintf(fileID, 'The null flux correction in the experiment is: %g Gs.\n', NullFluxCorrection);
    fprintf(fileID, 'The magnetic sensor calibrated zero point for the sensor is: %g V.\n', SensorZeroPoint);
    fprintf(fileID, 'The magnetic sensor sensitivity for the sensor is: %g V/Gs.\n', SensorSensitivity);   
    
    fprintf(fileID, 'Flux noise level chosen = %g Gs. \n', FluxNoiseLevelGs);
    
    fprintf(fileID, '%s', FluxSignalShiftPrompt);
   
    fclose(fileID);
    
    fprintf('Output Written into:\n\t %s,\n and \t %s\n', CompiledDataInfoFullFileNameDAT , CalibrationDataFullFileNameMAT')
     
% end

%% =============================================== CODE DUMPSTER ======================================
      
%     figure('color', 'w')
%     plot(SeparationDistanceResultantMicrons(2:end),ForceAllResultant,'r.'); 
%     xlabel('Separation Distance (micron)');ylabel('Force (nN)'); 
%     title({'Resultant of {\itnet} Forces on Bead vs. Separation Distance', 'Drift Not Excluded'})


% % --------------------------------    
%     figHandle = figure('color', 'w');
%     plot(SeparationDistanceResultantMicrons(2:end),ForceNoDriftAllResultant,'r.', 'MarkerSize', 4); 
%     xlabel('Separation Distance (\mum)');ylabel('Force (nN)'); title({'Resultant of {\itnet} Forces on Bead vs. Separation Distance', 'Drift NOT Excluded'});      
%     set(findobj(figHandle,'type', 'axes'), 'FontSize',10, 'FontWeight','Bold', 'LineWidth',1, 'XMinorTick', 'on', 'YMinorTick', 'on', 'TickDir', 'out');     % Make axes bold
%     xlim([0, max(SeparationDistanceResultantMicrons)]);
%     figureFileName = fullfile(OutputPathNameDIC, 'Calibration Force v Sep Distance Drift Not Excluded');
%     savefig(figHandle, figureFileName, 'compact');
% %     saveas(figHandle figureFileName, 'eps'); 
%     saveas(figHandle, figureFileName, 'png');
%     
% % 


%     % 20. More Plotting
%      % Plot Separation Distance (Col 8) and Forces (Col 13 with drift, Col 19 without Drift) If current is ON only. 
%      % 20.1 Plotting Data with Drift NOT excluded, 
%      % 20.1.1 both ON/OFF Flux
%      
%      %------------- 
%      figure('color', 'w') 
%      plot(CompiledData(:,8),CompiledData(:,13), 'r.');
%      xlabel('Distance (micron)'); ylabel('Force (nN)');
%      Caption1 = sprintf('Calibration Curve with ALL Flux Values for %d Gs - Drift NOT Excluded', FluxSetPoint);
%      title(Caption1);


%   
% 
%      % 20.1.2. Try to see what happens with Flux ON
%      figure('color', 'w')               %Open another figure
%      plot(SeparationDistanceMicronON,CompiledData(FluxON,13), 'r.');
%      xlabel('Distance (micron)'); ylabel('Force (nN)');
%      Caption2 = sprintf('Calibration Curve with Flux ON %d Gs - Drift NOT excluded',FluxSetPoint);     
%      title(Caption2);

%      
%      % 20.1.3. Try to see what happens with Flux OFF   
%      figure('color', 'w')                %Open a third figure
%      plot(CompiledData(FluxOFF,8),CompiledData(FluxOFF,13), 'r.');
%      xlabel('Distance (micron)'); ylabel('Force (nN)');
%      Caption3 = sprintf('Calibration Curve with Flux OFF %d Gs - Drift NOT Excluded', FluxSetPoint);        
%      title(Caption3);


     % 20.2 Plotting Data with Drift excluded, 
%      % 20.2.1. both ON/OFF Flux
%      figure('color', 'w') 
%      plot(CompiledData(:,8),CompiledData(:,19), 'r.');
%      xlabel('Distance (micron)'); ylabel('Force (nN)');
%      Caption1 = sprintf('Calibration Curve with ALL Flux Values for %d Gs - Drift Excluded', FluxSetPoint);
%      title(Caption1);

%      % 20.2.2. Try to see what happens with Flux ON
%      figure('color', 'w')               %Open another figure
%      plot(SeparationDistanceMicronON,Force_nN_ON, 'r.');
%      xlabel('Distance (micron)'); ylabel('Force (nN)');
%      Caption2 = sprintf('Calibration Curve with Flux ON %d Gs - Drift Excluded',FluxSetPoint);     
%      title(Caption2);
%      
%      % 20.2.2. Try to see what happens with Flux ON
%      figure('color', 'w')               %Open another figure
%      plot(SeparationDistanceMicronON,CompiledData(FluxON,18), 'r.');
%      xlabel('Distance (micron)'); ylabel('Velocity (\mum/s)');
%      Caption2 = sprintf('Calibration Curve with Flux ON %d Gs - Drift Excluded',FluxSetPoint);     
%      title(Caption2);
%      
     
%      % 20.2.3. Try to see what happens with Flux OFF   
%      figure('color', 'w')               %Open a third figure
%      plot(CompiledData(FluxOFF,8),CompiledData(FluxOFF,19), 'r.');
%      xlabel('Distance (micron)'); ylabel('Force (nN)');
%      Caption3 = sprintf('Calibration Curve with Flux OFF %d Gs - Drift Excluded', FluxSetPoint);        
%      title(Caption3);

    % 19. Plotting the RESULTANT FORCES
    
%     %  Plotting OVERALL Bead Velocity Difference as a function of Separation Distance between bead & needle tip pole.
%     figHandle = figure('color', 'w');
%     plot(SeparationDistanceResultantMicrons(2:end), VelocityAllResultant1, 'b.', 'MarkerSize', 4);          % Note: Separation distance array is one element less than the velocity array
%     xlabel('Separation Distance (\mum)'); ylabel('Bead Velocity (\mum/sec)'); title({'{\itNet} Bead Velocity vs. Separation Distance', 'Drift NOT Excluded'});
%     set(findobj(figHandle,'type', 'axes'), 'FontSize',10, 'FontWeight','Bold', 'LineWidth',1, 'XMinorTick', 'on', 'YMinorTick', 'on', 'TickDir', 'out');     % Make axes bold
%     box(gca, 'off');
%     xlim([0, max(SeparationDistanceResultantMicrons)]);
%     figureFileName = fullfile(OutputPathNameDIC, 'Calibration Bead Velocity v Sep Distance');
%     savefig(figHandle, figureFileName, 'compact');
% %     saveas(figHandle figureFileName, 'eps'); 
%     saveas(figHandle, figureFileName, 'png');
    

%      % 20.2.2. Try to see what happens with Flux ON
%     figHandle3 = figure('color', 'w');               %Open another figure
%     plot(SeparationDistanceMicronON,CompiledData(FluxON,18), 'r.', 'MarkerSize', 4);
%     xlabel('Distance (\mum)'); ylabel('Bead Velocity (\mum/s)');
%     set(findobj(figHandle3,'type', 'axes'), 'FontSize',10, 'FontWeight','Bold', 'LineWidth',1, 'XMinorTick', 'on', 'YMinorTick', 'on', 'TickDir', 'out');     % Make axes bold
%     box(gca, 'off');
%     xlim([0, max(SeparationDistanceMicronON)]);   
%     Caption3 = sprintf('Calibration Curve with Flux ON %d Gs', FluxSetPoint);     
%     title(Caption3);
%     