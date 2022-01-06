
    %% Written by Waddah Moghram, PhD Candidate in Biomedical Engineering at the University of Iowa, on 2/6/2018.
    %{
    v.2020-02-12 by Waddah Moghram
        1. Replaced the file naming from "...ND2 dTime Sec" to " TimeStamps ND2 sec.dat"
    v.2019-10-05
        1. Added the ability to give the function a folder name, which will be used to option a file in that directory for starters.
    v.2019-09-25
        1. Fixed AverageFrameRate() for loaded documents.
    v.2019-09-22
        1. Updated output to "timestamp loaded successfully."
        2. Return if not uigetfile() is chosen
    v.2019-05-15
        Based on examples online for Bioformats
        Only Extracting and Writing out the time stamps here 
        Modified to a function on 5/15/2019
    %}
    
function [TimeStampsND2, FrameCount, AverageTimeInterval] = ND2TimeFrameExtract(ND2FileFullName)
    %% 1. Getting the ND2 filename
    if ~exist('ND2FileFullName', 'var'), ND2FileFullName = []; end
    if nargin < 1 || isempty(ND2FileFullName)
        [FileName,PathName, ~] = uigetfile('*.nd2');
        if FileName == 0, return; end
        ND2FileFullName = fullfile(PathName,FileName);
        % Separating Extension from Path and Name
    elseif exist(ND2FileFullName, 'dir')
        [FileName,PathName, ~] = uigetfile(fullfile(ND2FileFullName,'*.nd2'), 'Open the ND2 file to extract time frames from metadata');          % A directory in this case.
        if FileName == 0, return; end
        ND2FileFullName = fullfile(PathName,FileName);
    end

    [ND2PathName, ND2FileName] = fileparts(ND2FileFullName);

    ND2FileNameParts = split(ND2FileName, '-');
    AnalysisSuffix = join(ND2FileNameParts(end-2:end), '-');
    AnalysisSuffix = AnalysisSuffix{:};
    AnalysisFolderStr = strcat('Analysis_', AnalysisSuffix);
    dTimePathName = fullfile(ND2PathName, '..', AnalysisFolderStr, 'Time_Stamps');
    try
        mkdir(dTimePathName)
    catch

    end


    FrameCount = [];
    AverageTimeInterval = [];
    
    %%
    % changed extension from .txt to .dat from this point onward 2/6/2018. 
    TimeStampFileNameDAT =  'TimeStamps_ND2_sec.dat';
    TimeStampFileNameMAT =  'TimeStamps_ND2_sec';
%         PathName = uigetdir(pwd,'Select the folder where you want to save the time stamp file');        %Added by WIM on 2/21/2018. 
% %     dTimePathName = fullfile(ND2PathName,'tracking_output');
%     dTimePathName = fullfile(ND2PathName, '..', 'Time_Stamps');
   
    TimeStampFullFileNameDAT = fullfile(dTimePathName, TimeStampFileNameDAT);
    TimeStampFullFileNameMAT = fullfile(dTimePathName, TimeStampFileNameMAT);
    
%     if exist(TimeStampFullFileNameDAT, 'file')
% %         dlgQuestion = 'Time stamp file found already. Do you want to re-extract it from ND2 file?';
% %         dlgTitle = 'Re-Extract time stamps from ND2 video?';
% %         choiceExtractTimestamps = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No. Just Load it', 'No', 'No. Just Load it');
%         choiceExtractTimestamps = 'No'
%         switch choiceExtractTimestamps    
%             case 'Yes'
%                 % Continue
%             case 'No. Just Load it'
%                 TimeStampsND2 = load(TimeStampFullFileNameDAT);
%                 FrameCount = numel(TimeStampsND2);
%                 AverageTimeInterval = mean(TimeStampsND2(2:end)-TimeStampsND2(1:end-1));
%                 fprintf('Previous timestamp loaded successfully from: \n\t%s\n', TimeStampFullFileNameDAT);
%                 return
%             case 'No'
%                 % Continue
%             otherwise
%                 return
%         end 
%     end
%     
    %% 2. Opening/Loading the entire file with the header. Otherwise, you can use bfGetReader(); to read the image alone without the metadata
    ImageData = bfopen(ND2FileFullName);

    % This function returns an n-by-4 cell array, where n is the number of series in the dataset. If s is the series index between 1 and n:
    % 
    % The ImageData{s, 1} element is an m-by-2 cell array, where m is the number of planes in the s-th series. If t is the plane index between 1 and m:
    % The ImageData{s, 1}{t, 1} element contains the pixel data for the t-th plane in the s-th series.
    % The ImageData{s, 1}{t, 2} element contains the label for the t-th plane in the s-th series.
    % The ImageData{s, 2} element contains original metadata key/value pairs that apply to the s-th series.
    % The ImageData{s, 3} element contains color lookup tables for each plane in the s-th series.
    % The ImageData{s, 4} element contains a standardized OME metadata structure, which is the same regardless of the input file format, and contains common metadata values such as physical pixel sizes - see OME metadata below for examples.


    %% 3. Looping through each series/stack
    SeriesCount = size(ImageData, 1);            % Basically if there are multiple z- t- or c- stacks
    
    for CurrentSeriesIndex = 1:SeriesCount
        MetaDataList = ImageData{CurrentSeriesIndex, 2};               % first index is from 1 to SeriesCount A hashtable type containing the OME metadata. 2nd index = 2 means metadata
        % and so on
        CurrentSeries = ImageData{CurrentSeriesIndex, 1};              % first index is from 1 to SeriesCount. A cell containing the image and title of that frame. 2nd index = 1 means image & frame
        

    %     % Query some metadata fields (keys are format-dependent)
    %     
    %     MetaDataList = data{1, 2};
    %     subject = MetaDataList.get('Subject');
    %     title = MetaDataList.get('Title');
    % 
    %     % To printout all the metdata key/value pairs for the first series
    %     metadataKeys = MetaDataList.keySet().iterator();
    %     for i=1:MetaDataList.size()
    %       key = metadataKeys.nextElement();
    %       value = MetaDataList.get(key);
    %       fprintf('%s = %s\n', key, value)
    %     end

        %% 6. To extract timestamps for an ND2 file:
%         metadataKeys = MetaDataList.keySet().iterator();
        
        try
            CurrentSeries_planeCount = size(CurrentSeries{1}, 1);        % plane count for each series. Basically the number of frames for my images. 
            TimeStampsND2 = zeros(CurrentSeries_planeCount,1);
            for i=1:CurrentSeries_planeCount
                NumDigits = numel(num2str(CurrentSeries_planeCount));            %counting the number of digits in the number of frames. E.g., 1000 = 4 digits, 100 is three digits, and so forth.
                FormatSpecifier = sprintf('%%0.%di', NumDigits);
                FrameNumber = sprintf(FormatSpecifier, i);
                key = strcat('timestamp #',FrameNumber);
                value = MetaDataList.get(key);
                fprintf('%s = %s\n', key, value);
                TimeStampsND2(i,1) = value;
            end
        catch
            CurrentSeries_planeCount = size(ImageData{1},1);
            TimeStampsND2 = zeros(CurrentSeries_planeCount,1);
            for i=1:CurrentSeries_planeCount
                % the one below replaces the line above. Some problems with some of the series
                NumDigits = numel(num2str(CurrentSeries_planeCount));
                FormatSpecifier = sprintf('%%0.%di', NumDigits);
                FrameNumber = sprintf(FormatSpecifier, i);
                key = strcat('timestamp #',FrameNumber);
                value = MetaDataList.get(key);
                fprintf('%s = %s\n', key, value);
                TimeStampsND2(i,1) = value;
            end
        end
        
        FrameCount = numel(TimeStampsND2);
        AverageTimeInterval = mean(TimeStampsND2(2:end)-TimeStampsND2(1:end-1));
        FramesPerSecond = 1/AverageTimeInterval;
        
        %% 7. Now Writing the timestamp file
        disp('Time tamps loaded successfully')
        dlmwrite(TimeStampFullFileNameDAT,TimeStampsND2, 'precision','%.6f')
        save(TimeStampFullFileNameMAT, 'ND2FileFullName', 'TimeStampsND2', 'FrameCount', 'FramesPerSecond', ...
            'AverageTimeInterval', '-v7.3')
        
    end 
end

