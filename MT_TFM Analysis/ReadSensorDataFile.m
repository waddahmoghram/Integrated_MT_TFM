%% 
%{
    v.2021-07-29 by Waddah Moghram
        1. changed output path to "SensorData" folder one level up
        2. Updated since the first column of our data is not the Index, but rather AO output in (V)
    v.2021-06-21 by Waddah Moghram
        1. Changed to speed up analysis. Designed for AIM3 experiments
    v.2020-03-31 by Waddah Moghram
        1. Fixed glitch if the output director does not exist. Create it in that case.
    v.2020-03-18 by Waddah Moghram
        1. Plot multiple sensor files without having to re-enter parameters all the time.
    v.2020-02-16 by Waddah Moghram
        1. Gives the user the option to say what the signals are for.
        2. for some experiments, AI7 is the tip/field sensor, and not the camera exposure. 
    v.2020-02-01 by Waddah Moghram
        1. Updated plots so that they have the same style as other figures
        2. Renamed output to 00 Sensor Data ...
    v.2020-01-09 by Waddah Moghram
        1. Updated to save sensor data using the input name if given.
        2***** AnalysisPath output needs to be fixed soon.
    v.2019-10-06..07
        1. Updated input for folder instead of filename.
        2. Fixed glitch when CleanSensorData does not pass sensor file name
    v.2019-09-22
        1. Fixed bug "SensorDataFolder"
        2. Excluded *.mat files for sensor data. Those are the output of this function, but not its input. 
            input is in *.dat format. Very old versions where *.txt format.
    v2019-09-17
        1. Updated to allow for a folder pass instead of file, in which case, that folder is the starting folder in uigetpath()
    v.2019-09-09
        1. cleanup the file plots
    v.2019-08-21 to allow the file to be plotted directly without prompts excepts the file chosen and output directory.
        Use the following command: ReadSensorDataFile([], 1, [], [], 6, 0);
        replaced gcf with actual figure handle.  Error saving camera exposure.
    updates 2019-08-12 to remove camera exposure that is not usual. 
     v7.30. Updated by Waddah Moghram on 2019-06-06. Fixed saveplot on 2019-06-14;
        1. Added a *.mat file to save the data for quicker access and for quicker viewing and plots.
    % NOTE: Sensor dats is the raw 
   v7.00 updated by Waddah Moghram on 2019-05-25
        1. Fixed Extra Zero point at the end
        2. Added the possibility of plotting the data to check if everything is OK

    v6.00 Updated on 2018-04-28 to reflected updated header files.
    This file will extract the output of the latest files generated by LabVIEW Flux Experiments. 
    Based on old ReadLabVICode.m of 11/1/2017, and ReadSensorDataFile_v_1_0.m
    Fixed glitch that skipped the first datapoint by changing the starting row for dlmread(). 

    Written by Waddah Moghram, PhD Candidate in Biomedical Engineering at the University of Iowa, on 1/18/2018. Updated on 4/28/2018 to reflected updated header files.

    Intput are SensorDataFile that user-input after this program is run, and the number of header lines
    Check the outline of the header below.
    Optional filename for sensor file

    Output are the SensorData, HeaderData & HeaderTitle. (For the v8.0 and later)
    HeaderData are Rows 2,4,6,8, 10 and 12
    HeaderTitle are Rows 1,3,5,7, 9 and 11
    SensorData are Rows 11 and thereafter
    Row 12 is the header for the SensorData
    
    %% Older Versions:
    ReadSensorDataFile_v_4_0
    HeaderData are Rows 2,4,6,8 and 10
    HeaderTitle are Rows 1,3,5,7 and 9
    SensorData are Rows 11 and thereafter
    Row 10 is the header for the SensorData
    
    ReadSensorDataFile_v_1_0 This file will extract the output of the latest
    files generated by LabVIEW Flux Experiments. Based on old ReadLabVICode.m
    of 11/1/2017. SensorDataFile is user-selected after this program is run.
    Returns the SensorData, HeaderData & HeaderTitle. 
    HeaderData are Rows 2,4,6, and 8
    HeaderTitle are Rows 1,3,5, and 7
    Sensor Data are Rows 9 and thereafter
    Programmed by Waddah Moghram, PhD Candindate in Biomedical Engineering on
     10/4/2017

    %% Outline of the header and data points of the file generated by LabVIEW. Note: they are "Tab-Delimited"
    
    
    v15.00 (8 header lines or 12 rows). Example Below
        Magnetic Sensor Zero (V)	Magnetic Sensor Sensitivity (V/Gs)	Number of Cycles	Sampling Rate (Samples/Sec)
        2.467116	0.0029794	3	30000
        ON Proportional Gain (K_c)	 Integral Time (T_i, min)	Derivative Time (T_d, min)	Samples pushed to PID
        1.800000	3.500000E-6	0.000000E+0	30
        OFF Proportional Gain (K_c)	Integral Time (T_i, min)	Derivative Time (T_d, min)	Needle Used
        0.300000	3.500000E-6	0.000000E+0	1
        Flux ON Relative Setpoint (Gs)	Null Flux - Observed (Gs)	Pre-Zero Interval (s)	Post-Zero Interval (s)
        -175.000000	3.000000	2.000000	0.000000
        Temperature (�C)	Needle Inclination Angle (�)	Magnetic Beads Diameter (Micron)	Relative Humidity
        25.7	20	4.5	0.42
        Null Flux Corrected (Gs)	Magnetic Bead Z-Level (Micron)	Fluoro Beads Z-Level (Micron)	Tip Z-Level (Micron)
        12.092087	4627.00	4623.00	4637.00
        Gel Measured Thickness (Micron)	Initial Separation Distance (Micron)	Image Scale (Micron/pixel)	Fluoro Beads Diameter (Micron)
        650.00	17.00	0.21500	0.5
        Ramp Steps	Total Ramp Time (ms)	===============	===============
        7	490	0.0	0.0 
    
    --------------------------
    v11.00 (6 header lines or 12 rows)
    
    --------------------------
    v10.00 (6 header lines or 12 rows) 
    
    
    --------------------------
    v9.70 (5 header lines or 10 rows)  
    
    
    --------------------------
    v9.60 (5 header lines or 10 rows)  
    
    
    --------------------------
    v9.50 (5 header lines or 10 rows)  
    
    
    --------------------------
    v8.0 - 9.40 (5 header lines or 10 rows)
        Row 0:
           Magnetic Sensor Zero (V)	Magnetic Sensor Sensitivity (V/Gs)	Number of Cycles	Sampling Rate (Samples/Sec)
        Row 1:
          The Corresponding Values for the headers above
        Row 2: 
          ON Proportional Gain (K_c)	 Integral Time (T_i, min)	Derivative Time (T_d, min)	Samples pushed to PID
        Row 3:    
          The corresponding values for the headers above.
        Row 4: 
          OFF Proportional Gain (K_c)     Integral Time (T_i, min)	Derivative Time (T_d, min)      Needle Used
        Row 5:    
          The Corresponding values for the headers above.
        Row 6:
          Flux ON Relative Setpoint (Gs)      Flux Observed Zero (Gs)     Pre- Zero Interval (s)      Post- Zero Interval (s)
        Row 7:
          The Corresponding values for the headers above.
        Row 8:
          Temperature (�C)	Needle Inclination Angle (�)	Magnetic Beads Diameter (Micron)	Relative Humidity
        Row 9:
          The Corresponding values for the headers above.
        Row 10:
          Index       Flux Sensor (V)     Current Sensor (V or A) 	Camera Exposure TTL (V)     
        Row 11 until EOF:
        The Corresponding values for the headers above.  
    --------------------------
    v8.0 - 9.40 (5 header lines or 10 rows)
        Row 0:
           Magnetic Sensor Zero (V)	Magnetic Sensor Sensitivity (V/Gs)	Number of Cycles	Sampling Rate (Samples/Sec)
        Row 1:
          The Corresponding Values for the headers above
        Row 2: 
          ON Proportional Gain (K_c)	 Integral Time (T_i, min)	Derivative Time (T_d, min)	Samples pushed to PID
        Row 3:    
          The corresponding values for the headers above.
        Row 4: 
          OFF Proportional Gain (K_c)     Integral Time (T_i, min)	Derivative Time (T_d, min)      Needle Used
        Row 5:    
          The Corresponding values for the headers above.
        Row 6:
          Flux ON Relative Setpoint (Gs)      Flux Observed Zero (Gs)     Pre- Zero Interval (s)      Post- Zero Interval (s)
        Row 7:
          The Corresponding values for the headers above.
        Row 8:
          Temperature (�C)	Needle Inclination Angle (�)	Magnetic Beads Diameter (Micron)	Relative Humidity
        Row 9:
          The Corresponding values for the headers above.
        Row 10:
          Index       Flux Sensor (V)     Current Sensor (V or A) 	Camera Exposure TTL (V)     
        Row 11 until EOF:
        The Corresponding values for the headers above.  
    
    --------------------------
    v7.0 - 7.4 (4 header lines or 8 rows)
        Row 0:
           Magnetic Sensor Zero (V)	Magnetic Sensor Sensitivity (V/GS)      Number of Cycles        Step Duration (Samples/Sec)
        Row 1:
          The Corresponding Values for the headers above
        Row 2: 
          Proportional Gain (K_c)     Integral Time (T_i, min)        Derivative Time (T_d, min)  	Samples pushed to PID
        Row 3:    
          The corresponding values for the headers above.
        Row 4: 
          Flux ON Relative Setpoint (GS)  	Flux Observed Zero (GS)     Pre- Zero Interval (s)      Post- Zero Interval (s)
        Row 5:    
          The Corresponding values for the headers above.
        Row 6:
          Temperature (�C)        Needle Inclination Angle (�)        Magnetic Beads Diameter (Micron)        Relative Humidity
        Row 7:
          The Corresponding values for the headers above.
        Row 8:
          Index           Flux Sensor (V)         Current Sensor (V or A)             Camera Exposure TTL (V)
        Row 9 until EOF:
        The Corresponding values for the headers above.

    --------------------------
    v6.0 and v5.20     (4 header lines or 8 rows)
        Row 0:
           Magnetic Sensor Zero (V)	Magnetic Sensor Sensitivity (V/GS)  	Number of Cycles	Step Duration (Samples/Sec)
        Row 1:
          The Corresponding Values for the headers above
        Row 2: 
          Proportional Gain (K_c)	    Integral Time (T_i, min)	 Derivative Time (T_d, min)  	Samples pushed to PID
        Row 3:
          The corresponding values for the headers above.
        Row 4: 
          Flux ON Relative Setpoint (GS)	 Flux Observed Zero (GS)	Pre- Zero Interval (s)	Post- Zero Interval (s)
        Row 5:    
          The Corresponding values for the headers above.
        Row 6:
          Solution Temperature (�C)	Needle Inclination Angle (�)	Magnetic Beads Diameter (micron)	===============    
        Row 7:
          The Corresponding values for the headers above.
        Row 8:
        Index     Flux Sensor (V)     Current Sensor (V or A)     Camera Exposure TTL (V)
        Row 9 until EOF:
        The Corresponding values for the headers above.
    
    --------------------------
    v5.00  (3 header lines or 6 rows):
        Row 0:
           Magnetic Sensor Zero (V)	Magnetic Sensor Sensitivity (V/GS)  	Number of Cycles	Step Duration (Samples/Sec)
        Row 1:
          The Corresponding Values for the headers above
        Row 2: 
          Proportional Gain (K_c)	    Integral Time (T_i, min)	 Derivative Time (T_d, min)  	Samples pushed to PID
        Row 3:
          The corresponding values for the headers above.
        Row 4: 
          Flux ON Relative Setpoint (GS)	 Flux Observed Zero (GS)	Pre- Zero Interval (s)	Post- Zero Interval (s)
        Row 5:    
          The Corresponding values for the headers above.
        Row 6:
        Index     Flux Sensor (V)     Current Sensor (V or A)     Camera Exposure TTL (V)
        Row 7 until EOF:
        The Corresponding values for the headers above.
    
    -----------------------------------
    v4.00 also has the same number of headers (3 header lines or 6 rows) as in v5.00 but the ordering is shuffled.
    
    -----------------------------------
    v3.80 has only only 2 header lines (4 rows)
    
    Note: To call a HeaderTitle item, invoke it HeaderTitle{1}{1}, since it is formatted as a cell.
    %}    

function [SensorData, HeaderData, HeaderTitle, SensorDataFullFileNameMAT, SensorOutputPathName, AnalysisPath, SamplingRate, SensorDataColumns] = ...
    ReadSensorDataFile(SensorDataFullFileNameDAT, PlotSensorData, SensorOutputPathName, AnalysisPath, HeaderLinesCount, CleanCameraSensorSignal)

%% 0. Initial Variables
    RendererMode = 'painters';
    PlotsFontName =  'Helvatica-Narrow';
    PlotsTitleFontName = 'Inconsolata Condensed Medium';   
    AI7 = 'CameraExposureTTL';
    
    %%

    AnalysisPathExist = false;
    
    %% 1. Opening the *.dat Data File generated by LabVIEW if none are passed
%     disp('-------------------------- Running "ReadSensorDataFile.m" to read Sensor Data generated by LabVIEW data logger --------------------------')
%     if ~exist('SensorDataFullFileNameDAT','var'), SensorDataFullFileNameDAT = []; end              % First parameter does not exist, so default it to something
%     if exist(SensorDataFullFileNameDAT, 'dir')
%         SensorDataFolder = SensorDataFullFileNameDAT;
        FolderChosen = true;
%     else
%         FolderChosen = false;
%     end    

%     if nargin < 1 || isempty(SensorDataFullFileNameDAT) || FolderChosen == true
% %         try
% %            [SensorDataFolder, SensorDataFile, SensorDataExt] =  fileparts(SensorDataFullFileNameDAT);    
% %         catch
% %             SensorDataFolder = pwd;
% %             % Do nothing
% %         end
%         [SensorDataFileName, SensorDataPathName] = uigetfile({fullfile(SensorDataFolder,'*.txt;*.dat')},'Select the Sensors Data File', 'MultiSelect', 'on'); % in the future, you will need to update for *.mat files.
%         try 
%             if SensorDataFileName == 0, return; end
%         catch
%             % continue
%         end
%         SensorDataFullFileNameDATs = fullfile(SensorDataPathName, SensorDataFileName);
%     end   
%     SensorOutputPathName = fullfile(fullfile(SensorDataPathName, '..'), 'SensorData');

%     if iscell(SensorDataFullFileNameDATs)
%         NumFiles = numel(SensorDataFullFileNameDATs);
%     else
        NumFiles = 1;
%     end
    
    for CurrentFile = 1:NumFiles
%         if iscell(SensorDataFullFileNameDATs)
%             SensorDataFullFileNameDAT = SensorDataFullFileNameDATs{CurrentFile};
%         else
%             SensorDataFullFileNameDAT = SensorDataFullFileNameDATs;
%         end
        fprintf('Sensor Data File opened is: \n %s \n' , SensorDataFullFileNameDAT);
        disp('----------------------------------------------------------------------------')   
        [SensorDataPathName, SensorDataFileName, ~] = fileparts(SensorDataFullFileNameDAT);
        SensorDataFileNameOnly = '';

        %%
        saveSensorPlotsChoice = 'Yes';
        saveSensorPlots = true;
        switch saveSensorPlotsChoice
            case 'Yes'       
                figureFileNames{1,1} = fullfile(SensorOutputPathName, strcat(SensorDataFileNameOnly, 'CoreMagneticFluxBluntV'));
                figureFileNames{1,2} = fullfile(SensorOutputPathName, strcat(SensorDataFileNameOnly, 'Current'));
                switch AI7
                    case 'MagneticFluxTipV' 
                        figureFileNames{1,3} = fullfile(SensorOutputPathName, strcat(SensorDataFileNameOnly, 'FieldMagneticFluxTipV'));
                        figureFileNames{1,5} = fullfile(SensorOutputPathName, strcat(SensorDataFileNameOnly, 'FieldMagneticFluxTipGs'));

                    case 'CameraExposureTTL'
                        figureFileNames{1,3} = fullfile(SensorOutputPathName, strcat(SensorDataFileNameOnly, 'CameraExposureTTL_V'));
                end
                figureFileNames{1,4} = fullfile(SensorOutputPathName, strcat(SensorDataFileNameOnly, 'CoreMagneticFluxBluntGs'));
        end        
        if AnalysisPathExist
%             figureFileNames{2,1} = fullfile(AnalysisPath, strcat(strjoin({'00', SensorDataFileNameOnly}, ' '), '-CoreMagneticFluxBluntV'));
%             figureFileNames{2,2} = fullfile(AnalysisPath, strcat(strjoin({'00', SensorDataFileNameOnly}, ' '), '-Current'));
%             switch AI7
%                 case 'MagneticFluxTipV' 
%                     figureFileNames{2,3} = fullfile(AnalysisPath, strcat(strjoin({'00', SensorDataFileNameOnly}, ' '), '-FieldMagneticFluxTipV'));
%                     figureFileNames{2,5} = fullfile(AnalysisPath, strcat(strjoin({'00', SensorDataFileNameOnly}, ' '), '-FieldMagneticFluxTipGs'));
% 
%                 case 'CameraExposureTTL'
%                     figureFileNames{2,3} = fullfile(AnalysisPath, strcat(strjoin({'00', SensorDataFileNameOnly}, ' '), '-CameraExposureTTL_V'));
%             end
%             figureFileNames{2,4} = fullfile(AnalysisPath, strcat(strjoin({'00', SensorDataFileNameOnly}, ' '), '-CoreMagneticFluxBluntGs'));
        end

        %%
        disp('Sensor data loading IN PROGRESS...')
        disp('----------------------------------------------------------------------------')       % Updated on 2019-09-09 to show the top 20 lines for this file
        fid = fopen(SensorDataFullFileNameDAT,'r');
        numLines = 20;
        your_text = cell(numLines,1);
         for ii = 1:numLines
             your_text(ii) = {fgetl(fid)}; 
         end
         fclose(fid);
         fprintf('%s\n', your_text{:});                                % printing a cell array of strings
        disp('----------------------------------------------------------------------------')       
        disp('Sensor data loading IN PROGRESS...')
        SensorFileDAT_ID = fopen(SensorDataFullFileNameDAT, 'r');
        disp('Sensor data loading COMPLETE...');

        % 2. Initializing the variables for the Header File. One for the actual data array & the second for the corresponding titles as cells
        HeaderData = [];
        HeaderTitle = {};

        % 3. Choosing the number of header lines in the versions. A default value of 5 lines based on the latest version
        if ~exist('HeaderLinesCount', 'var'), HeaderLinesCount = []; end
%         if  isempty(HeaderLinesCount) % || nargin < 5
%             commandwindow;
%             prompt = ['Enter the number of lines in the header.\n    v15.00 has 8 lines,\n    v12.00-14.00 has 7 lines,\n    v10.00-11.00 has 6 lines,\n    v8.00-9.70 has 5 lines,\n    ' ...
%                 'v5.20-7.40 has 4 lines,\n    v4.00-5.00 has 3 lines,\n    v3.80 has 2 lines.\n    [Default = 8]: '];
%             HeaderLinesCount = input(prompt);
%             if isempty(HeaderLinesCount) 
%                 HeaderLinesCount = 8;
%             end
%         end
        
        % 4. Reading the Header of Data File. This code will read one line at a time with
        % Note: fgetl() reads lines one at a time in the line.
        % Reading each line and the subsequent line
        for ii=1:HeaderLinesCount      
            HeaderTitle{ii} = strsplit(fgetl(SensorFileDAT_ID),'\t');                                  % Store the Header Titles Just In Case
            HeaderData = [HeaderData ; sscanf(fgetl(SensorFileDAT_ID) , '%f\t%f\t%f\t%f\t%f\n')'];    % Appending the Header Data
        end

        HeaderTitleFlattened = [HeaderTitle{:}];
        HeaderDataFlattened = HeaderData(:);
        for i = 1:numel(HeaderTitleFlattened)
            SensorHeader{i,1} = HeaderTitleFlattened{i};
            SensorHeader{i,2} = HeaderDataFlattened(i);
        end

        % 5. Reading the Sensor Data from the 9th row until the end of file into a matrix via dlmread()
        % Modified on 1/18/2018 to allow the flexbility based on headerline count
        % 2 * HeaderLinesCount + 1; 2 rows for each header line + one data header row, but starts at index 0. Corrected on 1/24/2018 -WIM

        SensorDataColumns = strsplit(fgetl(SensorFileDAT_ID),'\t'); 

        try
            SensorData = dlmread(SensorDataFullFileNameDAT, '\t', (2 * HeaderLinesCount) + 1 , 0);
        catch
            error('Could not read input file')
        end

        %% Add a fifth column that has the DataPoint Number
        SensorDataColumns{5} = 'Datapoint Number';
        SensorData(:,5) = (1:size(SensorData,1))';

        %% 7 Plotting Figures if indicated in input
                %------------       
        %MAGNETIC SENSOR ZERO POINT based on previous calibration (in V). 
        %-----------------------------------------------------------
        Indices = [1; 1];                   % Default Index values latest header in v8.0 and later as of 4/24/2018
        SensorZeroPointCore = HeaderData(Indices(1), Indices(2));
        Indices = [1; 2];                   % Default Index values latest header in v8.0 and later as of 4/24/2018
        SensorSensitivityCore = HeaderData(Indices(1), Indices(2));
        commandwindow;

%         fprintf('The CORE MAGNETIC SENSOR CALIBRATED ZERO point for the sensor is: %g V. \n', SensorZeroPointCore);        
%         fprintf('The CORE MAGNETIC SENSOR SENSITIVITY for the sensor is: %g V/Gs. \n', SensorSensitivityCore);  
%         Indices = [5; 3];                   % Default Index values latest header in v8.0 and later as of 4/24/2018
%         SensorZeroPointField = HeaderData(Indices(1), Indices(2));
%         Indices = [5; 4];                   % Default Index values latest header in v8.0 and later as of 4/24/2018
%         SensorSensitivityField = HeaderData(Indices(1), Indices(2));
%         fprintf('The FIELD MAGNETIC SENSOR CALIBRATED ZERO point for the sensor is: %g V. \n', SensorZeroPointField);        
%         fprintf('The FIELD MAGNETIC SENSOR SENSITIVITY for the sensor is: %g V/Gs. \n', SensorSensitivityField);  

        try
            SamplingRate = HeaderData(1,4);   % 30000 samples per seconds
            fprintf('Sampling Rate found in the data header is %.d samples/sec\n', SamplingRate);
        catch
            SamplingRate = 30000;   % 30000 samples per seconds            
            fprintf('Could not extract the sampling rate from the header. It is assumed to %d samples/sec.', SamplingRate)
        end

        if PlotSensorData == 1
            % 1. Plot Magnetic Flux (V) Signal over Time               
            figFluxV = figure('color', 'w', 'Renderer', RendererMode);
            FrameCount = size(SensorData,1);
            TimeSec = (1:FrameCount) / SamplingRate;
            plot(TimeSec, SensorData(:,2), 'b.', 'MarkerSize',2 )
            hold on
            plot(TimeSec, repmat(SensorZeroPointCore, size(TimeSec)), 'r-')
%             text(gca, sprintf('Calibrated Zero = %.6f V', SensorZeroPointCore))
            xlim([0, TimeSec(end)]);               % Adjust the end limit.
            findobj(figFluxV,'type', 'axes');
            set(findobj(gcf,'type', 'axes'), ...
                'FontSize',12, ...
                'FontName', PlotsTitleFontName, ...
                'LineWidth',1, ...
                'XMinorTick', 'on', ...
                'YMinorTick', 'on', ...
                'TickDir', 'out', ...
                'TitleFontSizeMultiplier', 0.9, ...
                'TitleFontWeight', 'bold');     % Make axes bold        
            title({'Core Magnetic Flux Sensor Reading in [V] at the Blunt End over time', strcat(SensorDataFileName,'.dat or .mat')}, 'FontWeight', 'bold', 'interpreter', 'none', 'FontName', PlotsTitleFontName)
            xlabel('Time [s]', 'FontName', PlotsFontName)
            ylabel('\bf\itB\rm_{Blunt} [V]', 'FontName', PlotsFontName)

            if saveSensorPlots
                savefig(figFluxV, strcat(figureFileNames{1,1}, '.fig'), 'compact');                    %             savefig(figFluxV,figureFileNames{1,1});                     
    %             saveas(figFluxV, strcat(figureFileNames{1,1}, '.eps'), 'eps'); 
                saveas(figFluxV, strcat(figureFileNames{1,1}, '.png'), 'png');
%                 if AnalysisPathExist
%                     savefig(figFluxV, strcat(figureFileNames{2,1}, '.fig'), 'compact');
%     %                 saveas(figFluxV, strcat(figureFileNamesAnalysis{2,1}, '.eps'), 'eps'); 
%                     saveas(figFluxV, strcat(figureFileNames{2,1}, '.png'), 'png');
%                 end
            end

            % 2. Plot Current (V) Signal over Time
            figCurrent = figure('color', 'w', 'Renderer', RendererMode);
               
            hold on
            plot(TimeSec, zeros(size(TimeSec)), 'r-')
            set(findobj(gcf,'type', 'axes'), ...
                'FontSize',12, ...
                'FontName', PlotsFontName,...
                'LineWidth',1, ...
                'XMinorTick', 'on', ...
                'YMinorTick', 'on', ...
                'TickDir', 'out', ...
                'TitleFontSizeMultiplier', 0.9, ...
                'TitleFontWeight', 'bold');     % Make axes bold   
            xlim([0, TimeSec(end)]);               % Adjust the end limit.
            xlabel('Time [s]', 'FontName', PlotsFontName)
            ylabel('\bf\itI\rm_{MT} [Amp]', 'FontName', PlotsFontName)
            if strcmpi(SensorDataColumns{1},'Current AO (V)')
                plot(TimeSec, SensorData(:,1) *0.4, 'b.', 'MarkerSize',2 ) %% AO Voltage is -10 to 104 to map -4 to 4 Amp
                title({'Current to the Needle Coils based on AO voltage', strcat(SensorDataFileName, '.dat or .mat')}, 'FontWeight', 'bold', 'interpreter', 'none', 'FontName', PlotsTitleFontName)
            else
                plot(TimeSec, SensorData(:,3), 'b.', 'MarkerSize',2 )
                title({'Current to the Needle Coils through 1-Amp Resistor', strcat(SensorDataFileName, '.dat or .mat')}, 'FontWeight', 'bold', 'interpreter', 'none', 'FontName', PlotsTitleFontName)
            end

            if saveSensorPlots
                savefig(figCurrent, strcat(figureFileNames{1,2}, '.fig'), 'compact');
    %             saveas(figCurrent, strcat(figureFileNames{1,2}, '.eps'), 'eps'); 
                saveas(figCurrent, strcat(figureFileNames{1,2}, '.png'), 'png');
                if AnalysisPathExist
                    savefig(figCurrent,strcat(figureFileNames{2,2}, '.fig'), 'compact');
    %                 saveas(figCurrent, strcat(figureFileNamesAnalysis{2,2}, '.eps'), 'eps'); 
                    saveas(figCurrent, strcat(figureFileNames{2,2}, '.png'), 'png');
                end                  
            end

            figCameraExposureTTL = figure('color', 'w', 'Renderer', RendererMode);
            plot(TimeSec, SensorData(:,4), 'b-', 'MarkerSize',2 )
            hold on
            plot(TimeSec, repmat(3, size(TimeSec)), 'r-')
            xlim([0, TimeSec(end)]);               % Adjust the end limit.
            set(findobj(gcf,'type', 'axes'), ...
                'FontSize',12, ...
                'FontName', PlotsFontName,...
                'LineWidth',1, ...
                'XMinorTick', 'on', ...
                'YMinorTick', 'on', ...
                'TickDir', 'out', ...
                'TitleFontSizeMultiplier', 0.9, ...
                'TitleFontWeight', 'bold');     % Make axes bold   

            switch AI7
                case 'MagneticFluxTipV' 
                    title({'Field Magnetic Flux Sensor Reading in [V] at the Tip over time', strcat(SensorDataFileName, '.dat or .mat')}, 'interpreter', 'none', 'FontWeight', 'bold', 'FontName', PlotsTitleFontName)
                    ylabel('\bf\itB\rm_{Tip} [V]', 'FontName', PlotsFontName)
                case 'CameraExposureTTL'
                    title({'Digital TTL Exposure Signal of the camera over time', strcat(SensorDataFileName, '.dat or .mat')}, 'interpreter', 'none', 'FontWeight', 'bold', 'FontName', PlotsTitleFontName)
                    ylabel('Camera Exposure Signal [V]', 'FontName', PlotsFontName)
            end 
            
            xlabel('Time [s]', 'FontName', PlotsFontName)

            if saveSensorPlots
                savefig(figCameraExposureTTL,strcat(figureFileNames{1,3}, '.fig'), 'compact');
    %             saveas(figCameraExposureTTL,strct(figureFileNames{1,3}, .eps'), 'eps'); 
                saveas(figCameraExposureTTL, strcat(figureFileNames{1,3}, '.png'), 'png');

            end
        end

            %----------------------------------------------------------------------
    %         disp('----------------------')
    %         commandwindow;
    %         HeaderIndexStr = input('Enter two index numbers separated by whitespace that contain Core Magnetic Sensor Calibrated Zero [Default 1 1]: ', 's');
    %         [Indices, n, ErrMsg] = sscanf(HeaderIndexStr, '%u');
    %         if n ~= 2 || ~isempty(ErrMsg)               % Rows & Columns are required, or if an error occured
    %             try 
    %                 Indices = [1; 1];                   % Default Index values latest header in v8.0 and later as of 4/24/2018
    %                 SensorZeroPointCore = HeaderData(Indices(1), Indices(2));
    %             catch
    %                 disp('Error reading Core Calibrated Zero')
    %             end
    %         else 
    %             try 
    %                 SensorZeroPointCore = HeaderData(Indices(1), Indices(2));
    %             catch
    %                 disp('Error reading Core Calibrated Zero')
    %             end
    %         end
    %         fprintf('The MAGNETIC SENSOR CALIBRATED ZERO point for the sensor is: %g V. \n', SensorZeroPointCore);
    %          %MAGNETIC SENSOR SENSITIVITY based on previous calibration (in V/Gs). 
    %         disp('----------------------')
    %         HeaderIndexStr = input('Enter two index numbers separated by whitespace that contain Core Magnetic Sensor Sensitivity [Default 1 2]: ', 's');
    %         [Indices, n, ErrMsg] = sscanf(HeaderIndexStr, '%u');
    %         if n ~= 2 || ~isempty(ErrMsg)               % Rows & Columns are required, or if an error occured
    %             try 
    %                 Indices = [1; 2];                   % Default Index values latest header in v8.0 and later as of 4/24/2018
    %                 SensorSensitivityCore = HeaderData(Indices(1), Indices(2));
    %             catch
    %                 disp('Error reading Core Magnetic Sensor Sensitivity')
    %             end
    %         else 
    %             try 
    %                 SensorSensitivityCore = HeaderData(Indices(1), Indices(2));
    %             catch
    %                 disp('Error reading Core Magnetic Sensor Sensitivity')
    %             end
    %         end
    %         fprintf('The MAGNETIC SENSOR SENSITIVITY for the sensor is: %g V/Gs. \n', SensorSensitivityCore);            
            % 1. Plot Magnetic Flux (Gs) Signal over Time            
            %----------------------------------------------------------------------
    %         disp('----------------------')
    %         commandwindow;
    %         HeaderIndexStr = input('Enter two index numbers separated by whitespace that contain Field Magnetic Sensor Calibrated Zero [Default 1 1]: ', 's');
    %         [Indices, n, ErrMsg] = sscanf(HeaderIndexStr, '%u');
    %         if n ~= 2 || ~isempty(ErrMsg)               % Rows & Columns are required, or if an error occured
    %             try 
    %                 Indices = [5; 3];                   % Default Index values latest header in v8.0 and later as of 4/24/2018
    %                 SensorZeroPointField = HeaderData(Indices(1), Indices(2));
    %             catch
    %                 disp('Error reading Field Calibrated Zero')
    %             end
    %         else 
    %             try 
    %                 SensorZeroPointField = HeaderData(Indices(1), Indices(2));
    %             catch
    %                 disp('Error reading Field Calibrated Zero')
    %             end
    %         end
    %         fprintf('The MAGNETIC SENSOR CALIBRATED ZERO point for the sensor is: %g V. \n', SensorZeroPointField);
    %          %MAGNETIC SENSOR SENSITIVITY based on previous calibration (in V/Gs). 
    %         disp('----------------------')
    %         HeaderIndexStr = input('Enter two index numbers separated by whitespace that contain Field Magnetic Sensor Sensitivity [Default 1 2]: ', 's');
    %         [Indices, n, ErrMsg] = sscanf(HeaderIndexStr, '%u');
    %         if n ~= 2 || ~isempty(ErrMsg)               % Rows & Columns are required, or if an error occured
    %             try 
    %                 Indices = [5; 4];                   % Default Index values latest header in v8.0 and later as of 4/24/2018
    %                 SensorSensitivityField = HeaderData(Indices(1), Indices(2));
    %             catch
    %                 disp('Error reading Field Magnetic Sensor Sensitivity')
    %             end
    %         else 
    %             try 
    %                 SensorSensitivityField = HeaderData(Indices(1), Indices(2));
    %             catch
    %                 disp('Error reading Field Magnetic Sensor Sensitivity')
    %             end
    %         end
    %         fprintf('The MAGNETIC SENSOR SENSITIVITY for the sensor is: %g V/Gs. \n', SensorSensitivityField);            
            % 1. Plot Magnetic Flux (Gs) Signal over Time        
        if PlotSensorData == 1
            %----------------------------------------------------------------------
            figCoreFluxGs = figure('color', 'w', 'Renderer', RendererMode);
            FrameCount = size(SensorData,1);
    %         try
    %             SamplingRate = HeaderData(1,4);   % 30000 samples per seconds
    %         catch
    %             SamplingRate = 0000;   % 30000 samples per seconds            
    %         end
            TimeSec = (1:FrameCount) /SamplingRate;
            plot(TimeSec, (SensorData(:,2)-SensorZeroPointCore)/SensorSensitivityCore, 'b.', 'MarkerSize',2 )
            hold on
            plot(TimeSec, repmat(0, size(TimeSec)), 'r-')
            xlim([0, TimeSec(end)]);               % Adjust the end limit.
            set(findobj(gcf,'type', 'axes'), ...
                'FontSize',12, ...
                'FontName', PlotsFontName,...
                'LineWidth',1, ...
                'XMinorTick', 'on', ...
                'YMinorTick', 'on', ...
                'TickDir', 'out', ...
                'TitleFontSizeMultiplier', 0.9, ...
                'TitleFontWeight', 'bold', ...
                'ydir', 'reverse');     % Make axes bold   
            title({'Core Magnetic Flux Sensor Reading at the Blunt End over time', strcat(SensorDataFileName, '.dat or .mat')}, 'interpreter', 'none', 'FontWeight', 'bold', 'FontName', PlotsTitleFontName)
            xlabel('Time [s]', 'FontName', PlotsFontName)
            ylabel('\bf\itB\rm_{Blunt} [Gs]', 'FontName', PlotsFontName)

            if saveSensorPlots
                savefig(figCoreFluxGs, strcat(figureFileNames{1,4}, '.fig'), 'compact');
    %             saveas(figCoreFluxGs, strcat(figureFileNames{1,4}, '.eps'), 'eps'); 
                saveas(figCoreFluxGs, strcat(figureFileNames{1,4}, '.png'), 'png');
            end
%             switch AI7
%                 case 'MagneticFluxTipV' 
%                     figFieldFluxGs = figure('color', 'w', 'Renderer', RendererMode);
%                     FrameCount = size(SensorData,1);
%                     TimeSec = (1:FrameCount) /SamplingRate;
%                     plot(TimeSec, (SensorData(:,4)-SensorZeroPointField)/SensorSensitivityField, 'b.', 'MarkerSize',2 )
%                     xlim([0, TimeSec(end)]);               % Adjust the end limit.
%                     set(findobj(gcf,'type', 'axes'), ...
%                         'FontSize',12, ...
%                         'FontName', PlotsFontName,...
%                         'LineWidth',1, ...
%                         'XMinorTick', 'on', ...
%                         'YMinorTick', 'on', ...
%                         'TickDir', 'out', ...
%                         'TitleFontSizeMultiplier', 0.9, ...
%                         'TitleFontWeight', 'bold');     % Make axes bold  
%                     title('Field Magnetic Flux Sensor Reading in [Gs] at the Tip over time', 'FontWeight', 'bold', 'FontName', PlotsTitleFontName)
%                     xlabel('Time [s]', 'FontName', PlotsFontName)
%                     ylabel('\bf\itB\rm_{Tip} [Gs]', 'FontName', PlotsFontName)
%                     if saveSensorPlots
%                         savefig(figFieldFluxGs, strcat(figureFileNames{1,5}, '.fig'), 'compact');
%     %                     saveas(figFieldFluxGs, strcat(figureFileNames{1,5}, '.eps'), 'eps'); 
%                         saveas(figFieldFluxGs, strcat(figureFileNames{1,5}, '.png'), 'png');
%                         if AnalysisPathExist
%                             savefig(figFieldFluxGs, strcat(figureFileNames{2,5}, '.fig'), 'compact');
%     %                         saveas(figFieldFluxGs, strcat(figureFileNamesAnalysis{2,5}, '.eps'), 'eps'); 
%                             saveas(figFieldFluxGs, strcat(figureFileNames{2,5}, '.png'), 'png');
%                         end
%                     end
%             end
        end
            %-----------------
                %%
        if ~exist('CleanCameraSensorSignal','var'), CleanCameraSensorSignal = []; end              % First parameter does not exist, so default it to something
%         if isempty(CleanCameraSensorSignal) % || nargin < 6
%             dlgQuestion = 'Do you want to clean camera sensor data of TTL pulses before the actual sequence?';
%             dlgTitle = 'Clean camera sensor data at the beginning?';
%             CleanCameraSensorSignal = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No', 'No');
%         end
%         if CleanCameraSensorSignal == 1
%             CleanCameraSensorSignal = 'Yes';
%         else
%             CleanCameraSensorSignal = 'No';
%         end
        CleanCameraSensorSignal = 'No';
        switch CleanCameraSensorSignal
            case 'Yes'
                commandwindow;
                timeCleanSensorSignal = input('Enter the time before which you would like to clean the camera signal in seconds? ');
                try
                    SamplingsPerSecond = HeaderData(1,4);               % later use the file header to get that information
                catch
                    SamplingsPerSecond = 30000;
                end
                Frames = timeCleanSensorSignal * SamplingsPerSecond;
                SensorData(1:Frames,4) = 0;
            otherwise
                CleanCameraSensorSignal = 'No';
                % do nothing
        end
        if saveSensorPlots
            fprintf('{Sensor Plots are saved in: \n %s \n' , SensorOutputPathName);            
            if AnalysisPathExist    
                fprintf('Sensor Plots for Analysis are also saved in: \n %s \n' , AnalysisPath);
            end     
        end


        %% 6. Added on 2019-06-06. Save the Sensor Data as *.mat file for easy manipuation with other functions.

        SensorDataFullFileNameMAT = fullfile(SensorOutputPathName, 'SensorData.mat');  % consider saving in SensorOutputPathName
        save(SensorDataFullFileNameMAT, 'SensorData', 'SensorDataColumns', 'SensorHeader', 'HeaderData', 'HeaderTitle', 'SamplingRate', 'SensorSensitivityCore', ...
            'SensorZeroPointCore', '-v7.3')

        %% 7. Closing the File
        fclose(SensorFileDAT_ID);
        disp('Sensor data file closed.');
        disp('-------------------------- Loading sensor data points COMPLETE! --------------------------')
        
        if ~exist('AnalysisPath', 'var'), AnalysisPath = []; end
    end
    
end

