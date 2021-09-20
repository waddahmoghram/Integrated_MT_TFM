%% Written by Waddah Moghram 
%{
    v.2020-03-19 
        1. This code is designed to plot flux deviation for multiple plots
        2. Load the sensor 
%}
%%
% Open the *.mat sensor file
[SensorDataFileName, SensorDataPathName] = uigetfile({fullfile(pwd,'*.mat')},'Select the Sensors Data File', 'MultiSelect', 'on'); % in the future, you will need to update for *.mat files.
try 
    if SensorDataFileName == 0, return; end
catch
    % continue
end
SensorDataFullFileNameMATs = fullfile(SensorDataPathName, SensorDataFileName);

if iscell(SensorDataFullFileNameMATs)
    NumFiles = numel(SensorDataFullFileNameMATs);
else
    NumFiles = 1;
end


for CurrentFile = 1:NumFiles
    if iscell(SensorDataFullFileNameMATs)
        SensorDataFullFileNameMAT = SensorDataFullFileNameMATs{CurrentFile};
    else
        SensorDataFullFileNameMAT = SensorDataFullFileNameMATs;
    end
    fprintf('Sensor Data File opened is: \n %s \n' , SensorDataFullFileNameMAT);
    disp('----------------------------------------------------------------------------')   
    [SensorDataPathName, SensorDataFileNameOnly, ~] = fileparts(SensorDataFullFileNameMAT);
    load(SensorDataFullFileNameMAT);

    if CurrentFile == 1
       try
            SamplingRate = HeaderData(1,4);   % 30000 samples per seconds
            fprintf('Sampling Rate found in the data header is %.d samples/sec\n', SamplingRate);
        catch
            SamplingRate = 30000;   % 30000 samples per seconds            
            fprintf('Could not extract the sampling rate from the header. It is assumed to %d samples/sec.', SamplingRate)
        end

        FrameCount = size(SensorData,1);
        TimeSec = (1:FrameCount) / SamplingRate; 
    end
    
    if ~exist('CoreSensorDeviationGs', 'var')
        CoreSensorDeviationGs = struct();
        CoreSensorDeviationGs.ONSetpointGs = [];
        CoreSensorDeviationGs.OFFFluxDeviation10CycleGs = [];
        CoreSensorDeviationGs.ONFluxDeviation10CycleGs = [];    
    end

    if ~exist('FieldSensorDeviationGs', 'var')
        FieldSensorDeviationGs = struct();
        FieldSensorDeviationGs.ONSetpointGs = [];
        FieldSensorDeviationGs.OFFFluxDeviation10CycleGs = [];
        FieldSensorDeviationGs.ONFluxDeviation10CycleGs = [];    
    end

    CoreSensorGs = (SensorData(:,2) - SensorZeroPointCore) / SensorSensitivityCore;
    FieldSensorGs = (SensorData(:,4) - SensorZeroPointField) / SensorSensitivityField;
   
    figure('color', 'w')
    plot(TimeSec, FieldSensorGs)
    xlabel('Time (s)')
    ylabel('Field Flux (Gs)');

    figure('color', 'w')
    plot(TimeSec, CoreSensorGs)
    set(gca, 'YDir' , 'reverse')
    xlabel('Time (s)')
    ylabel('Core Flux (Gs)');

    
%     figure('color', 'w')
%     plot(TimeSec, SensorData(:,2))
%     figure('color', 'w')
%     plot(TimeSec, SensorData(:,4))

    CoreSensorDeviationGs.ONSetpointGs(end + 1, 1) = input('Input Flux Setpoint in Gs: ');            % in Gs
    FieldSensorDeviationGs.ONSetpointGs(end + 1, 1) = CoreSensorDeviationGs.ONSetpointGs(end, 1);

    % 1st Cycle
    TimeFirstOFF = (1 * SamplingRate):(1.5 * SamplingRate);
    TimeFirstON = (2.5* SamplingRate):(3 * SamplingRate);
    % 10th Cycle
    TimeLastOFF = (36.5 * SamplingRate):(37 * SamplingRate);
    TimeLastON = (38.5* SamplingRate):(39* SamplingRate);


    CoreFirstOFF = mean(CoreSensorGs(TimeFirstOFF));
    CoreFirstON = mean(CoreSensorGs(TimeFirstON));
    CoreLastOFF = mean(CoreSensorGs(TimeLastOFF));
    CoreLastON = mean(CoreSensorGs(TimeLastON));

    CoreOFFdiff = CoreLastOFF - CoreFirstOFF;
    CoreONdiff = CoreLastON - CoreFirstON;


    CoreSensorDeviationGs.OFFFluxDeviation10CycleGs(end + 1, 1) = CoreOFFdiff;
    CoreSensorDeviationGs.ONFluxDeviation10CycleGs(end + 1, 1) = CoreONdiff;



    FieldFirstOFF = mean(FieldSensorGs(TimeFirstOFF));
    FieldFirstON = mean(FieldSensorGs(TimeFirstON));
    FieldLastOFF = mean(FieldSensorGs(TimeLastOFF));
    FieldLastON = mean(FieldSensorGs(TimeLastON));

    FieldOFFdiff = FieldLastOFF - FieldFirstOFF;
    FieldONdiff = FieldLastON - FieldFirstON;

    FieldSensorDeviationGs.OFFFluxDeviation10CycleGs(end + 1, 1) = FieldOFFdiff;
    FieldSensorDeviationGs.ONFluxDeviation10CycleGs(end + 1, 1) = FieldONdiff;

    close all
end

%% Plotting Figures
figure('color', 'w')

subplot(2,2,1);
    plot(CoreSensorDeviationGs.ONSetpointGs, CoreSensorDeviationGs.OFFFluxDeviation10CycleGs, 'b.', 'MarkerSize', 10)
    hold on
    % xlim([0, max(CoreSensorDeviationGs.ONSetpointGs)])
    % plot([0, max(CoreSensorDeviationGs.ONSetpointGs)], [0,0], 'LineStyle', '--', 'LineWidth' , 2, 'Color', 'k')
    xlim([0,200])
    plot([0, 200], [0,0], 'LineStyle', '--', 'LineWidth' , 2, 'Color', 'k')

    xlabel('\itB\rm_{Blunt}^{\itON*\rm} [Gs]')
    ylabel('\Delta\itB\rm_{Blunt}^{\itOFF\rm} [Gs]')
    set(findobj(gcf,'type', 'axes'), ...
        'FontSize',9, ...
        'FontName', 'Helvetica', ...
        'LineWidth',1, ...
        'XMinorTick', 'on', ...
        'YMinorTick', 'on', ...
        'TickDir', 'out', ...
        'TitleFontSizeMultiplier', 0.9, ...
        'TitleFontWeight', 'bold');     % Make axes bold   
%-----------------
subplot(2,2,2);
    plot(FieldSensorDeviationGs.ONSetpointGs, FieldSensorDeviationGs.OFFFluxDeviation10CycleGs, 'b.', 'MarkerSize', 10)
    hold on
    xlim([0,200])
    
    xlabel('\itB\rm_{Blunt}^{\itON*\rm} [Gs]')
    ylabel('\Delta\itB\rm_{Tip}^{\itOFF\rm} [Gs]')
    set(findobj(gcf,'type', 'axes'), ...
        'FontSize',9, ...
        'FontName', 'Helvetica', ...
        'LineWidth',1, ...
        'XMinorTick', 'on', ...
        'YMinorTick', 'on', ...
        'TickDir', 'out', ...
        'TitleFontSizeMultiplier', 0.9, ...
        'TitleFontWeight', 'bold');     % Make axes bold 


subplot(2,2,3);
    plot(CoreSensorDeviationGs.ONSetpointGs, CoreSensorDeviationGs.ONFluxDeviation10CycleGs, 'b.', 'MarkerSize', 10)
    hold on
    xlim([0,200])
    plot([0, 200], [0,0], 'LineStyle', '--', 'LineWidth' , 2, 'Color', 'k')

    xlabel('\itB\rm_{Blunt}^{\itON*\rm} [Gs]')
    ylabel('\Delta\itB\rm_{Blunt}^{\itON\rm} [Gs]')
    set(findobj(gcf,'type', 'axes'), ...
        'FontSize',9, ...
        'FontName', 'Helvetica', ...
        'LineWidth',1, ...
        'XMinorTick', 'on', ...
        'YMinorTick', 'on', ...
        'TickDir', 'out', ...
        'TitleFontSizeMultiplier', 0.9, ...
        'TitleFontWeight', 'bold');     % Make axes bold   
    
subplot(2,2,4);
    plot(FieldSensorDeviationGs.ONSetpointGs, FieldSensorDeviationGs.ONFluxDeviation10CycleGs, 'b.', 'MarkerSize', 10)
    hold on
    xlim([0,200])
    plot([0, 200], [0,0], 'LineStyle', '--', 'LineWidth' , 2, 'Color', 'k')
    
    xlabel('\itB\rm_{Blunt}^{\itON*\rm} [Gs]')
    ylabel('\Delta\itB\rm_{Tip}^{\itON\rm} [Gs]')
    set(findobj(gcf,'type', 'axes'), ...
        'FontSize',9, ...
        'FontName', 'Helvetica', ...
        'LineWidth',1, ...
        'XMinorTick', 'on', ...
        'YMinorTick', 'on', ...
        'TickDir', 'out', ...
        'TitleFontSizeMultiplier', 0.9, ...
        'TitleFontWeight', 'bold');     % Make axes bold 
