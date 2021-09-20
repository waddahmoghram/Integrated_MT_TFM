function [] = ND2Convert(ND2FileFullName, saveVideo)
% Written by Waddah Moghram, PhD Candidate in Biomedical Engineering at the University of Iowa, on 2/6/2018.
    % Based on examples online for Bioformats
    % Only display and load all frames alone. Not timestamps involved. This code will be used in Image Tracking
%%   Detailed explanation goes here
    
    %% 1. Getting the ND2 filename
    if ~exist('ND2FileFullName', 'var'), ND2FileFullName = []; end
    if nargin < 1 || isempty(ND2FileFullName)
        disp('Opening the DIC ND2 Video File to get path and filename info to be analyzed')
        try
            [ND2FileName, ND2FilePath] = uigetfile('*.nd2', 'Open the ND2 DIC video file to be converted');    
            ND2FileFullName = fullfile(ND2FilePath,ND2FileName);   
            [ND2Path, ND2Name, ~] = fileparts(ND2FileFullName);
            ND2ConvertedName = fullfile(ND2Path,ND2Name);
            fprintf('ND2 DIC Video File to be analyzed is: \n %s \n' , ND2ConvertedName);
            disp('----------------------------------------------------------------------------')            
        catch
            error('No file was selected or file cannot be opened.');               
        end
    end
    [Path, Name, Extension] = fileparts(ND2FileFullName);    
    %--------------------------------------------------------------------
    if ~exist('saveVideo','var'), saveVideo = []; end
    if nargin < 2 || isempty(saveVideo) || saveVideo == 0 || upper(saveVide) == 'Y'
        dlgQuestion = 'Do you want to save as videos or as image sequence?';
        dlgTitle = 'Video vs. Image Sequence?';
        plotTypeChoice = questdlg(dlgQuestion, dlgTitle, 'Video', 'Images', 'Images');
        switch plotTypeChoice
            case 'Video'
                saveVideo = true;
                dlgQuestion = 'Select video format.';
                listStr = {'Archival', 'Motion JPEG AVI', 'Motion JPEG 2000','MPEG-4','Uncompressed AVI','Indexed AVI','Grayscale AVI'};
                videoChoice = listdlg('ListString', listStr, 'PromptString',dlgQuestion, 'InitialValue', 2, 'SelectionMode' ,'Single');    
                videoChoice = listStr{videoChoice};              
            case 'Images'
                saveVideo = false;
                dlgQuestion = 'Select image format.';
                listStr = {'TIF', 'FIG', 'EPS','MAT data'};
                ImageChoice = listdlg('ListString', listStr, 'PromptString',dlgQuestion, 'InitialValue', 2, 'SelectionMode' ,'multiple');    
                ImageChoice = listStr(ImageChoice);                 % get the names of the string.   
                displacementOutputPath = fullfile(ND2ConvertedName, 'Converted Movie Overlays');
            otherwise
                return
        end
    end
        
    %% 2. Opening/Loading the entire file with the header. Otherwise, you can use bfGetReader(); to read the image alone without the metadata
    ImageData = bfopen(ND2FileFullName);       
    
    %% 3. Looping through each series/stack
    SeriesCount = size(ImageData, 1);            % Basically if there are multiple z- t- or c- stacks
    

end

