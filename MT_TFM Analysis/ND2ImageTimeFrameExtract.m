function [TimeStamps, FrameCount] = ND2ImageTimeFrameExtract(ND2FileFullName)
    %% Written by Waddah Moghram, PhD Candidate in Biomedical Engineering at the University of Iowa, on 2/6/2018.
    % Based on examples online for Bioformats


    %% 1. Getting the ND2 filename
    if nargin ==0, ND2FileFullName = []; end
    if isempty(ND2FileFullName)
        [FileName,PathName,FilterIndex] = uigetfile('Image.nd2');
        ND2FileFullName = fullfile(PathName,FileName);
    end
    
    % Separating Extension from Path and Name
    [PathName,FileName,Extension] = fileparts(ND2FileFullName);

    %% 2. Opening/Loading the entire file with the header. Otherwise, you can use bfGetReader(); to read the image alone without the metadata
    %**** Update on 5/19/2019. It is possible to use bfGetReader() to find the file side, reader.getSizeT and so forth
    
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
        CurrentSeries_planeCount = size(CurrentSeries, 1);        % plane count for each series. Basically the number of frames for my images. 

        %% 4. Looping through each frame
        for CurrentPlaneIndex = 1:CurrentSeries_planeCount
            CurrentSeries_CurrentPlane = CurrentSeries{CurrentPlaneIndex,1};                % first index goes from frame 1 to CurrentSeries_planeCount. Plane1 is basically the image
            CurrentSeries_CurrentLabel = CurrentSeries{CurrentPlaneIndex, 2};               % first index goes from frame 1 to CurrentSeries_planeCount. Plane1 is basically the image     

          %% 5. displaying the image the most basic way with grayscale. This works if you have the image processing toolbox

            %imshow(CurrentSeries_CurrentPlane, []);\
            imtool(CurrentSeries_CurrentPlane, []);
    % 
    %         % otherwise, displaying the image using the embedded color map. [] if none embedded. 
    %         CurrentSeries_colorMaps = ImageData{1, 3};
    %         figure('Name', CurrentSeries_CurrentLabel);
    %         if (isempty(CurrentSeries_colorMaps{1}))
    %           colormap(gray);
    %         else
    %           colormap(CurrentSeries_colorMaps{1}(1,:));
    %         end
    %         imagesc(CurrentSeries_CurrentPlane);

        end 

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
        metadataKeys = MetaDataList.keySet().iterator();
        TimeStamps = zeros(CurrentSeries_planeCount,1);
        for i=1:CurrentSeries_planeCount
          NumDigits = numel(num2str(CurrentSeries_planeCount));            %counting the number of digits in the number of frames. E.g., 1000 = 4 digits, 100 is three digits, and so forth.
          FormatSpecifier = sprintf('%%0.%di', NumDigits);
          FrameNumber = sprintf(FormatSpecifier, i);
          key = strcat('timestamp #',FrameNumber);
          value = MetaDataList.get(key);
          fprintf('%s = %s\n', key, value);
          TimeStamps(i,1) = value;
        end

        %% 7. Now Writing the timestamp file

        TimeStampFileNameDAT = strcat(FileName,  ' dTime MetaData.dat');
        TimeStampFullFileNameDAT = fullfile(PathName, TimeStampFileNameDAT);
        TimeStampFileNameMAT = strcat(FileName,  ' dTime MetaData');
        TimeStampFullFileNameDAT = fullfile(PathName, TimeStampFileNameMAT);
        dlmwrite(TimeStampFullFileNameDAT,timestamps, 'precision','%.8f')
        save(TimeStampFullFileNameMAT, 'ND2FileFullName', 'TimeStamps', 'MetaDataList', '-v7.3')

    end 
    
end
