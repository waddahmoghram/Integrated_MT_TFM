%{
    v.2020-10-25 by Waddah Moghram
        1. Update so that it return F_ON = off for setpoint = 0 Gs.
    v.2020-07-04 by Waddah Moghram, PhD Candidate in Biomedical Engineering at the University of Iowa
        1. Append Flux data to the cleaned-up sensor data. 
    v.2020-06-13 by Waddah Moghram
        1. Renamed FindFluxStatus to FindFluxStatusControlledForce.m
    v.2020-06-03, by Waddah Moghram
        1. Returns flux status FluxON, FluxOFF, FluxTransient = 1 or 0 (true or false)
        2. Returns FluxReadingsStatus = 1,0,-1 for ON/OFF/Transient;
        ** Used with controlled-force MT experiment. Modularized so that it can be used by Young Modulus 
        Optimziation code.

%}
function [FluxON, FluxOFF, FluxTransient, FluxReadingsStatus] = FindFluxStatusControlledForce(CleanedSensorDataFullFileNameMAT_EPI, FluxNoiseLevelGs)
  % Returns flux status for a controlled-force MT experiment.
    if ~exist('CleanedSensorDataFullFileNameMAT_EPI', 'var') || nargin <1, CleanedSensorDataFullFileNameMAT_EPI = []; end
    if isempty(CleanedSensorDataFullFileNameMAT_EPI) || ~isfile(CleanedSensorDataFullFileNameMAT_EPI)
        [CleanedDataFileName, CleanedDataPathName] = uigetfile(fullfile(pwd, '*.mat'), 'EPI Cleaned-up Sensor Data *.MAT file');
        CleanedSensorDataFullFileNameMAT_EPI = fullfile(CleanedDataPathName, CleanedDataFileName);
    end
% Loading cleaned-up sensor data
    load(CleanedSensorDataFullFileNameMAT_EPI, 'HeaderData', 'CleanedSensorData');
    %----------------- added by 2019-08-23. Comment lines below, and uncomment lines have sscanf()
    n = 0;
    %-------------------------%         
%             HeaderIndexStr = input('Enter two index numbers separated by whitespace that contain Flux (ON) Setpoint [Default 4 1]: ', 's');
%             [Indices, n, ErrMsg] = sscanf(HeaderIndexStr, '%u');
    if n ~= 2 || ~isempty(ErrMsg)               % Rows & Columns are required, or if an error occured
        try 
            Indices = [4; 1];                   % Default Index values latest header in v8.0 and later as of 4/24/2018
            FluxSetPointGs = HeaderData(Indices(1), Indices(2));
        catch
            disp('Error reading Flux Setpoint')
        end
    else 
        try 
            FluxSetPointGs = HeaderData(Indices(1), Indices(2));
        catch
            disp('Error reading Flux Setpoint')
        end
    end
    fprintf('The FLUX (ON) SETPOINT in the experiment is: %g Gs. \n', FluxSetPointGs);

%             NULL FLUX OBSERVED when it is OFF (in Gs). This value is set visually at the beginning of the experiment.
    disp('----------------------')
%             HeaderIndexStr = input('Enter two index numbers separated by whitespace that contain Null Flux Observed [Default 4 2]: ', 's');
%             [Indices, n, ErrMsg] = sscanf(HeaderIndexStr, '%u');
    if n ~= 2 || ~isempty(ErrMsg)               % Rows & Columns are required, or if an error occured
        try 
            Indices = [4; 2];                   % Default Index values latest header in v8.0 and later as of 4/24/2018
            NullFluxObservedGs = HeaderData(Indices(1), Indices(2));
        catch
            disp('Error reading Null Flux Observed')
        end
    else 
        try 
            NullFluxObservedGs = HeaderData(Indices(1), Indices(2));
        catch
            disp('Error reading Null Flux Observed')
        end
    end
    fprintf('The NULL FLUX OBSERVED in the experiment is: %g Gs. \n', NullFluxObservedGs);


   %NULL FLUX CORRECTION after the first cycle. This value is based on a sigmoidal fit based on bead experiments. 
    disp('----------------------')
%     HeaderIndexStr = input('Enter two index numbers separated by whitespace that contain Null Flux Correction [Default 6 1]: ', 's');
%     [Indices, n, ErrMsg] = sscanf(HeaderIndexStr, '%u');
    if n ~= 2 || ~isempty(ErrMsg)               % Rows & Columns are required, or if an error occured
        try 
            Indices = [6; 1];                   % Default Index values latest header in v8.0 and later as of 4/24/2018
            NullFluxCorrectionGs = HeaderData(Indices(1), Indices(2));
        catch
            disp('Error reading Null Flux Observed')
        end
    else 
        try 
            NullFluxCorrectionGs = HeaderData(Indices(1), Indices(2));
        catch
            disp('Error reading Null Flux Observed')
        end
    end
    fprintf('The NULL FLUX CORRECTION in the experiment is: %g Gs. \n', NullFluxCorrectionGs);

    %MAGNETIC SENSOR ZERO POINT based on previous calibration (in V). 
    disp('----------------------')
%     HeaderIndexStr = input('Enter two index numbers separated by whitespace that contain Magnetic Sensor Calibrated Zero [Default 1 1]: ', 's');
%     [Indices, n, ErrMsg] = sscanf(HeaderIndexStr, '%u');
    if n ~= 2 || ~isempty(ErrMsg)               % Rows & Columns are required, or if an error occured
        try 
            Indices = [1; 1];                   % Default Index values latest header in v8.0 and later as of 4/24/2018
            SensorZeroPointV = HeaderData(Indices(1), Indices(2));
        catch
            disp('Error reading Flux Setpoint')
        end
    else 
        try 
            SensorZeroPointV = HeaderData(Indices(1), Indices(2));
        catch
            disp('Error reading Flux Setpoint')
        end
    end
    fprintf('The MAGNETIC SENSOR CALIBRATED ZERO point for the sensor is: %g V. \n', SensorZeroPointV);

    %MAGNETIC SENSOR SENSITIVITY based on previous calibration (in V/Gs). 
    disp('----------------------')
%     HeaderIndexStr = input('Enter two index numbers separated by whitespace that contain Magnetic Sensor Sensitivity [Default 1 2]: ', 's');
%     [Indices, n, ErrMsg] = sscanf(HeaderIndexStr, '%u');
    if n ~= 2 || ~isempty(ErrMsg)               % Rows & Columns are required, or if an error occured
        try 
            Indices = [1; 2];                   % Default Index values latest header in v8.0 and later as of 4/24/2018
            SensorSensitivityVperGs = HeaderData(Indices(1), Indices(2));
        catch
            disp('Error reading Magnetic Sensor Sensitivity')
        end
    else 
        try 
            SensorSensitivityVperGs = HeaderData(Indices(1), Indices(2));
        catch
            disp('Error reading Magnetic Sensor Sensitivity')
        end
    end
    fprintf('The MAGNETIC SENSOR SENSITIVITY for the sensor is: %g V/Gs. \n', SensorSensitivityVperGs); 
       % Now asking if there is a Shift between the Flux and Camera Signals. Most likely due to DAQ problems. on 4/28/2018
    % ADDED by Waddah Moghram on 4/28/2018 to account for Flux lagging behind the camera capture. This issue is most likely due to Channel lag. 
%     % Until that problem is fixed. This will fix lag here.
%     disp('----------------------')
%     FluxSignalShiftExists = upper(input('Was there a shift between flux and camera signal? [Y/N/Flux Shift in Gs] (Default = N): ', 's'));   
%     if strcmpi(FluxSignalShiftExists,'Y')
%         prompt = 'Enter the number of frames that flux is ahead or lagging. Use Negative for lagging flux signal: ';
%         FluxSignalShift = input(prompt);
%         if isempty(FluxSignalShift)
%             % Number of Frames shifted. Use Negative if the Flux is lagging.
%             FluxSignalShift = -7;    %  Based on my inspection on Calibration Run 01 on Conducted 4/22/2018. See Electronic notes for more details. 4/28/2018 WIM.
%         end
%     elseif strcmpi(FluxSignalShiftExists,'N') || isempty(FluxSignalShiftExists)       
%         FluxSignalShift = 0;
%     elseif isnumeric(str2double(FluxSignalShiftExists))
%         FluxSignalShift = str2double(FluxSignalShiftExists);
%     else
%         disp('No flux shift is present!');
%         FluxSignalShift = 0;
%     end
    %-------------
%        FluxSignalShift = 0;         % Added on 2019-08-28 to save time. delete this part and uncomment the part above if needed.
%     %-----------
%     if FluxSignalShift > 0 
%        FluxSignalShiftPrompt = sprintf('Flux signal is ahead the camera signal by %d frames.', FluxSignalShift);
%     elseif FluxSignalShift < 0 
%        FluxSignalShiftPrompt = sprintf('Flux signal is behind the camera signal by %d frames.', FluxSignalShift);
%     else
%        FluxSignalShiftPrompt = sprintf('Flux signal is matching with the camera signal. Shift is %d frames.', FluxSignalShift);
%     end
   % Now that we have all the data compiled in one variable, we can do all sorts of manipulations
    %{
        key flux values are extracted
        Convert Flux Values from V to Gs. 
        Stick to CompiledData and not CleanedSensorData. 
        Adjusting for NullFluxObservedGs
        There are intentially more signals to ensure enough force cycles were observed.
    %}

    CompiledDataSize = size(CleanedSensorData, 1);
    % CompiledData(:,2) are the flux readings
    % FluxReadingsStatus: 1st column is the Relative Flux (in Gs), and 2nd column is the Flux Status that will be added in the next section

    FluxReadingsStatus(:,1) = ((CleanedSensorData(:,2) - SensorZeroPointV)./ SensorSensitivityVperGs) - NullFluxObservedGs;

    %Initialize 2nd column, for Flux Reading State
    FluxReadingsStatus(:,2) = 0;        
        %. Now, classifying Flux Readings to one of three states: ON (1), OFF (0), or Transient (-1)
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
%     FluxNoiseLevelGs = 2; % 2 Gs. Modified by WIM on 2019-08-28
%     FluxNoiseLevelGs = 3;
    % FluxNoiseLevelGs = 1.75;
    % Updated on 4/29/2018 to reflect the Null Flux Correction scheme.
    FirstCycleON = 0;               %Set it to false at firt
    for i = 1:CompiledDataSize                                                          % Going through all the compiled data points
        if FirstCycleON == 0                                                            
            if abs(FluxReadingsStatus(i,1) - FluxSetPointGs) < FluxNoiseLevelGs              % Flux is ON within the noise level band.              
                FluxReadingsStatus(i,2) = 1;
                FirstCycleON = 1;                                                           % First cycle is ON
            elseif abs(FluxReadingsStatus(i,1)) < FluxNoiseLevelGs                          % Flux is OFF within the noise level band. Null Flux is 0 in this case.
                FluxReadingsStatus(i,2) = 0;
            else                                                                            % Transient Value (or Sensor error).
                FluxReadingsStatus(i,2) = -1;                                               % Reverted back to -1 on 1/24/2018.    % 10/9/2017 Treat Transient as 0 and leave out
            end 
        else 
            if abs(FluxReadingsStatus(i,1) - FluxSetPointGs) < FluxNoiseLevelGs              % Flux is ON within the noise level band.              
                FluxReadingsStatus(i,2) = 1;
                FirstCycleON = 1;                                                           % First cycle is ON
            elseif abs(FluxReadingsStatus(i,1) - (NullFluxCorrectionGs - NullFluxObservedGs)) < FluxNoiseLevelGs                          % Check if it is within the noise level after the "offset from Null Flux"
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
    FluxTransient = logical(FluxReadingsStatus(:,2) == -1);
    
    if FluxSetPointGs == 0
        FluxON = ~FluxON;
        FluxOFF= ~FluxOFF;
    end
    
    if isempty(FluxON), FluxON = nan(size(FluxReadingsStatus,1)); end
    if isempty(FluxOFF), FluxOFF = nan(size(FluxReadingsStatus,1)); end
    if isempty(FluxTransient), FluxOFF = nan(size(FluxReadingsStatus,1)); end
    
    try
       save(CleanedSensorDataFullFileNameMAT_EPI, 'FluxSetPointGs', 'NullFluxObservedGs', 'NullFluxCorrectionGs', 'SensorZeroPointV', 'SensorSensitivityVperGs', '-append')
    catch
        % do nothing
    end
    disp('Cleaning up sensor data is complete!')
    disp('__________________________________________________________________________________________')
end

