function [displField, SampleBackShift, DisplacementFileFilteredFullName, DisplacementFilterParametersFullName, LPEF_FilterParametersStruct] = FilterDisplacementLowPassEquiripples(displField, FramesDoneNumbers)
%FilterDisplacementLowPassEquiripples will filter out the high vibrations of tracked nodes
%{
    v.2020-07-29 by Waddah Moghram, PhD Student in Biomedical Engineering at the University of Iowa
        1. Updated to allow the user the option to change the filter parameters. So that it can be used for controlled-force or controlled-displacement mode.
    v.2020-06-25 by Waddah Moghram
        1. Added "DisplacementFileFilteredFullName" & "DisplacementFilterParametersFullName" as output arguments to update VideoAnalysisEPI.m
    v.2020-02-07..09 by Waddah Moghram
        1. Added a progress display to see what frame they are in.
        2. Fixed the error in frames shifted. 

    v.2020-01-12 by Waddah Moghram
        1. Updated to save in another folder in the same structure but add "Filtered" to the end.

    v.2020-01-07..08 written by Waddah Moghram
        1. This filters the displacement field to eliminate any sudden fluctuations using a low-pass equiripple filter, and shifts time back
            This will be a few frames less at the end
%} 
%% Check Inputs 
    % 1. check if there is a displacement field structure from TFM Package output
    if ~exist('displField', 'var'), displField = []; end
    if isempty(displField) || nargin < 1
        [displacementFileName, displacementFilePath] = uigetfile(fullfile(pwd,'TFMPackage','*.mat'), 'Open the displacement field "displField.mat" under displacementField or backups');
        DisplacementFileFullName = fullfile(displacementFilePath, displacementFileName);
        try
            load(DisplacementFileFullName, 'displField');
            disp('------------------------------------------------------------------------------')
            fprintf('Displacement Field (displField) File is successfully loaded!: \n\t %s\n', DisplacementFileFullName);
            disp('------------------------------------------------------------------------------')
        catch
            error('Could not open the displacement field file.');
        end
    elseif ischar(displField)
            try              % file name is given
                DisplacementFileFullName = displField;
                load(displField, 'displField');
            catch
                % continue
            end
    elseif ~isstruct(displField)
            error('displField is not a displacement field structure..');
    end
    
    % 2. Check if there is a frame number or range, otherwise, extract the range from the displField
    if ~exist('FramesDoneNumbers', 'var'), FramesDoneNumbers = []; end
    if isempty(FramesDoneNumbers) || nargin < 2
        if isstruct(displField)
            FramesDoneBoolean = arrayfun(@(x) ~isempty(x.vec), displField);
            FramesDoneNumbers = find(FramesDoneBoolean == 1);       
        else
            % if it is given as an array. Conside if the input is displField(:
        end        
    end
%     clear ux uy
    disp('Reading displacement data')
%     reverseString = '';
    parfor CurrentFrame = FramesDoneNumbers        % ux, uy rows are node displacements over time, columns are frame numbers (i.e., time).
%         ProgressMsg = sprintf('Reading displacements in Frame #%d/(%d-%d)...\n',CurrentFrame, FramesDoneNumbers(1),FramesDoneNumbers(end));
%         fprintf([reverseString, ProgressMsg]);
%         reverseString = repmat(sprintf('\b'), 1, length(ProgressMsg));       
        ux(:, CurrentFrame) = displField(CurrentFrame).vec(:,1);
        uy(:, CurrentFrame) = displField(CurrentFrame).vec(:,2);
    end
    disp('Finished reading displacement data')

    %% Design the Filter
        % Filter Parameters. Our baseline frequency is 1/11 sec (on-off sequence) or ~ 0.0909...Hz
%     prompt = {'Filter Order', 'Pass Frequency (Hz): [2 for Ctrl Force, 10 for Ctrl Displ]', 'Stop Frequency (Hz) [10 for Ctrl Force, 15 for Ctrl Displ]', 'Sample Rate (Frames/Sec)'};
%     dlgTitle = 'Low-Pass Equiripppled Filter (LPEF) parameters';
%     dims = [1 70];
%     defInput = {'41', '2', '10', '40'};
%     opts.Interpreter = 'tex';
%     GelPropertiesValuesStr = inputdlg(prompt, dlgTitle, dims, defInput, opts);
%     FilterOrder = str2double(GelPropertiesValuesStr{1,:});
%     PassFreqHz = str2double(GelPropertiesValuesStr{2,:});
%     StopFreqHz = str2double(GelPropertiesValuesStr{3,:});
%     SamplingRateHz =  str2double(GelPropertiesValuesStr{4,:});
    
    GelPropertiesValuesStr = {'41', '2', '10', '40'};
    FilterOrder = str2double(GelPropertiesValuesStr{1});
    PassFreqHz = str2double(GelPropertiesValuesStr{2});
    StopFreqHz = str2double(GelPropertiesValuesStr{3});
    SamplingRateHz =  str2double(GelPropertiesValuesStr{4});


    SampleBackShift = (FilterOrder - 1)/2;
    FilterDesign = 'Low-Pass Equiripple';
    
    LowPassFilterParams = fdesign.lowpass('N,Fp,Fst',FilterOrder,PassFreqHz,StopFreqHz,SamplingRateHz);
    EquirippleLowPassFilterParams = design(LowPassFilterParams,'equiripple');
    % fvtool(EquirippleLowPassFilterParams)
    
    %% Now filtering for each Nodes     
    disp('_________ Filtering Displacements for each node in progress... _________')
    NodesToBeFiltered = 1:size(ux,1);
%     reverseString = '';    

    %% Create Parallel Works
    %----------------------------------PARALLEL POOL
    poolobj = gcp('nocreate'); % If no pool, do not create new one.
    if isempty(poolobj)
        %                 poolsize = feature('numCores');
        poolsize = str2double(getenv('NUMBER_OF_PROCESSORS')) - 1;          % Modified by Waddah Moghram on 12/10/2018 and is better to get all cores.
    else
        poolsize = poolobj.NumWorkers;
    end
    if isempty(gcp('nocreate'))
        try
            parpool('local', poolsize);
        catch
            try 
                parpool;
            catch 
                warning('matlabpool has been removed, and parpool is not working in this instance');
            end
        end
    end
    
    parfor CurrentNode = NodesToBeFiltered  % Going from the first node to the last node across all frames, and filtering them one by one
%         ProgressMsg = sprintf('Filtering bead #%d/(%d-%d) across all frames...\n',CurrentNode, NodesToBeFiltered(1),NodesToBeFiltered(end));
%         fprintf([reverseString, ProgressMsg]);
%         reverseString = repmat(sprintf('\b'), 1, length(ProgressMsg));       
        
        uxFiltered(CurrentNode,:) = filter(EquirippleLowPassFilterParams, ux(CurrentNode,:));
        uyFiltered(CurrentNode,:) = filter(EquirippleLowPassFilterParams, uy(CurrentNode,:));
        % Note: Using low-pass time filter will shift the output back by (Filter Order - 1)/ 2
    end
    uxFilteredShifted = uxFiltered;             % Copy below first
    uyFilteredShifted = uyFiltered;
    uxFilteredShifted(:,FramesDoneNumbers(1:SampleBackShift)) = [];      % Then delete the first samples shifted back.
    uyFilteredShifted(:,FramesDoneNumbers(1:SampleBackShift)) = []; 
 
    disp('_________ Filtering and shifting displacements complete! _________')

%% Output in the proper format
    FramesDoneNumbersShifted = FramesDoneNumbers(1:end-SampleBackShift);
    parfor CurrentFrame = FramesDoneNumbersShifted        % ux, uy rows are node displacements over time, columns are frame numbers (i.e., time).
        displFieldFiltered(CurrentFrame).vec(:,1) = uxFilteredShifted(:, CurrentFrame);
        displFieldFiltered(CurrentFrame).vec(:,2) = uyFilteredShifted(:, CurrentFrame);
        displFieldFiltered(CurrentFrame).pos = displField(CurrentFrame).pos;
    end
    clear displField
    displField = displFieldFiltered;        % Replace with filtered one. 
    
    try
        [displacementFilePath, DisplFileName, DisplFileExt] = fileparts(DisplacementFileFullName);
        displacementFileNameFiltered = sprintf('%s_LPEF%s', DisplFileName, DisplFileExt); 
        displacementFileNameFilterParameters = sprintf('%s_LPEF_Parameters%s', DisplFileName, DisplFileExt); 
        DisplFieldPathsUp = strsplit(displacementFilePath, filesep);
        displacementFilePathFiltered =  fullfile( fullfile(displacementFilePath, '..'), strcat(DisplFieldPathsUp{end}, '_LPEF'));       % _Low-Pass Equiripples Filter (Equiripples)
    catch
        % continue
    end    
    
    LPEF_FilterParametersStruct.FilterOrder = FilterOrder;
    LPEF_FilterParametersStruct.PassFreqHz = PassFreqHz;
    LPEF_FilterParametersStruct.StopFreqHz = StopFreqHz;
    LPEF_FilterParametersStruct.SamplingRateHz = SamplingRateHz;
    LPEF_FilterParametersStruct.SampleBackShift = SampleBackShift;
    LPEF_FilterParametersStruct.FilterDesign = FilterDesign;
    
    DisplacementFileFilteredFullName = [];
    DisplacementFilterParametersFullName = [];
    
    if exist('displacementFilePath', 'var')
        if ~exist(displacementFilePathFiltered, 'dir'), mkdir(displacementFilePathFiltered); end            
        DisplacementFileFilteredFullName = fullfile(displacementFilePathFiltered, displacementFileNameFiltered);
        save(DisplacementFileFilteredFullName, 'displField', '-v7.3')
        DisplacementFilterParametersFullName = fullfile(displacementFilePathFiltered, displacementFileNameFilterParameters);
        save(DisplacementFilterParametersFullName, 'FilterOrder', 'PassFreqHz', 'StopFreqHz', 'SamplingRateHz', 'SampleBackShift', ...
            'FilterDesign', '-v7.3')
        fprintf('Filtered Displacement Field File is successfully saved in: \n\t %s\n', DisplacementFileFilteredFullName);
        fprintf('Filter Parameters are saved in: \n\t %s\n', DisplacementFilterParametersFullName);
        disp('------------------------------------------------------------------------------')        
    end
end