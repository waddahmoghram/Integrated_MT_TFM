function [TimeStampsAbsoluteRT_Sec, TimeStampsRelativeRT_Sec, TimeStampFullFileNameMAT, SamplingRate, AverageTimeInterval] = TimestampRTfromSensorData(CleanSensorData, SamplingRate, HeaderTitle, HeaderData, CleanedSensorDataFullFileName, FirstExposurePulseIndex)
%{
    v.2021-08-01 by Waddah Moghram
        1. Updated for AIM 3 experiments
        2. Reflected the new SensorData format that has the index in the 5th column added after the fact
                column 1 now represents "Current AO (V)" Controlled Output signal
    v.2020-02-12 by Waddah Moghram
        1. Added AverageTimeInterval as an output for this.
    v.2020-02-10 by Waddah Moghram
        1. Create an absolute time stamps where t = 0 is when the camera signal started.
        2. Output them in here so that I do not need to open "Cleaned Sensor Data'
        3. Needs fixing so that arguments can be input
    v.2019-06-14 by Waddah Moghram. 
    v.2020-06-13 Written by Waddah Moghram, PhD Student in Biomedical Engineering
%}
    disp('----------------------Running TimestampRTfromSensorData().m to extract timestamps from the real-time computer.')
    if ~exist('CleanSensorData', 'var'), CleanSensorData = []; end
    if nargin < 1 || isempty(CleanSensorData)
        [CleanSensorData , ExposurePulseCount, EveryNthFrame, CleanedSensorDataFullFileNameDAT, HeaderData, HeaderTitle, FirstExposurePulseIndex] = CleanSensorDataFile([]);
    end
    
    %%
    if ~exist('SamplingRate', 'var'), SamplingRate = []; end
    if nargin < 2 || isempty(SamplingRate)
        if ~exist('HeaderData', 'var') || ~exist('HeaderTitle', 'var') 
            HeaderData = [];
            HeaderTitle = [];
        end
        if isempty(HeaderData) || ~iscell(HeaderTitle) 
            [HeaderData, HeaderTitle]  = ReadSensorDataFileHeaderOnly([]);   
        end
%         fprintf('Verify this information extracted from the sensor data file header: %s = %i?\n', HeaderTitle{1,1}{4}, HeaderData(1,4))
%         correctValue = input('Is the sampling rate shown above is correct? [Y/N, Default=Y]  ', 's');
        correctValue = 'Y';
        if upper(correctValue) == 'N'
            SamplingRate = input('Enter the rate (Samples/Sec)?');
        else
            SamplingRate = HeaderData(1,4);
        end
    end
        
    %%
    if ~exist('CleanedSensorDataFullFileName', 'var'), CleanedSensorDataFullFileName = []; end
    if nargin < 5 || isempty(CleanedSensorDataFullFileName)
%         dlgQuestion = 'Do you want to save the real-time timestamps?';
%         dlgTitle = 'Save Timestamps RT';
%         choiceSaveOutput = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No', 'Yes');
        choiceSaveOutput = 'Yes';
        switch choiceSaveOutput    
            case 'Yes'
                if exist(CleanedSensorDataFullFileNameDAT, 'file')
                    [CleanedSensorDataPath, CleanedSensorDataFileName, ~] = fileparts(CleanedSensorDataFullFileNameDAT);
                else
                    CleanedSensorDataPath = pwd;
                end
%                 CleanedSensorDataPathName = uigetdir(CleanedSensorDataPath, 'Select the folder where you want to save Timestamps Real-time');                
%                 if CleanedSensorDataPathName==0
%                     error('No folder was selected');
%                 end      
                CleanedSensorDataPathName = CleanedSensorDataPath;
        end
    end
    if ~exist('CleanedSensorDataPathName', 'var')
        try
            [CleanedSensorDataPathName, ~, ~]  = fileparts(CleanedSensorDataFullFileName);
            TimeStampsPathName = fullfile(CleanedSensorDataPathName, '..', 'Time_Stamps');
            try
                mkdir(TimeStampsPathName)
            catch
                %continue
            end
        catch
            TimeStampsPathName = pwd;
        end
    end
    
    %% Calculating the absolute timestamps
        % Using DataPoint index for timestamp since it is taken in Remote LabVIEW real-time computer. 
    % First Camera Signal Point = Time 0 seconds

    TimeStampsAbsoluteRT_Sec = (CleanSensorData(:,5) - 1)./SamplingRate;        % first data point has index for t = 0;    
    TimeStampsRelativeRT_Sec = (CleanSensorData(:,5) - CleanSensorData(5,1))./SamplingRate;
    
    AverageTimeInterval = mean(TimeStampsAbsoluteRT_Sec(2:end)-TimeStampsAbsoluteRT_Sec(1:end-1));
    FramesPerSecond = 1/AverageTimeInterval;
    
    %% Saving the results 
    if ~exist('CleanedSensorDataFileName','var'), CleanedSensorDataFileName = []; end
    if isempty(CleanedSensorDataFileName)
        TimeStampsFileNameDAT = 'TimeStamps_RT_sec.dat';
        TimeStampsFileName = 'TimeStamps_RT_sec.mat';
%     else
% %         TimeStampsFileNameDAT = strcat(TimeStampsPathName, 'TimeStamps_RT_sec.dat');
%         TimeStampsFileNameMAT = strcat(TimeStampsPathName, 'TimeStamps_RT_sec.mat');
%     end
    
%     try
%         TimeStampsFileNameMAT = strrep(TimeStampsPathName , 'Cleaned-up', '');
%     catch
%         % do nothing
%     end        
    
    TimeStampFullFileNameDAT = fullfile(TimeStampsPathName, TimeStampsFileNameDAT);    
    TimeStampFullFileNameMAT = fullfile(TimeStampsPathName, TimeStampsFileName);    
    
    dlmwrite(TimeStampFullFileNameDAT, TimeStampsRelativeRT_Sec, 'precision','%.6f')
    save(TimeStampFullFileNameMAT, 'TimeStampsRelativeRT_Sec', 'TimeStampsAbsoluteRT_Sec', ...
        'SamplingRate', 'FirstExposurePulseIndex', 'AverageTimeInterval', 'FramesPerSecond', '-v7.3')
    
    disp('----------------------------------------------------------------------------')   
    fprintf('Real-time timestamps is saved in: \n %s \n' , TimeStampFullFileNameDAT);
    fprintf('Real-time timestamps is saved in: \n %s \n' , TimeStampFullFileNameMAT);
    
disp('------------------------- Creating Real-time Time-stamps COMPLETE ---------------------------------------------------') 
end