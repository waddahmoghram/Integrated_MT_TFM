function [displField, SampleBackShift] = FilterDisplacementWienerHan(displField, FramesDoneNumbers, HanWindow, PaddingChoiceStr)
%FilterDisplacementLowPassEquiripples will filter out the high vibrations of tracked nodes
%{
    v. 2020-01-14 by Waddah Moghram 
        based on FilterDisplacementLowPassEquiripples v.2020-01-14
      PaddingChoiceStr choices are:  'No padding' or 0,  'Padded with random & zeros' or 1 (Default), 'Padded with zeros only' or 2
    
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
    
    %3. Check if HanWindow Option was given. D
    if ~exist('HanWindow', 'var'), HanWindow = []; end
    if isempty(HanWindow) || nargin < 3
        HanWindow = true;               % Default option is with Han Windowing because that is the proper approach   
    end
    
    if ~exist('PaddingChoiceStr', 'var'), PaddingChoiceStr = []; end
    if isempty(PaddingChoiceStr) || nargin < 4
        PaddingChoiceStr = 'Padded with random & zeros';               % Default option is with Han Windowing because that is the proper approach  
    else
        if PaddingChoiceStr == 0
           PaddingChoiceStr = '
    end
    
    
    
%     clear ux uy
    for ii = FramesDoneNumbers        % ux, uy rows are node displacements over time, columns are frame numbers (i.e., time).
        ux(:, ii) = displField(ii).vec(:,1);
        uy(:, ii) = displField(ii).vec(:,2);
    end
    
    %% Now filtering for each Nodes 
    disp('_________ Filtering Displacements for each node in progress... _________')
    for ii = 1:size(ux,1)  % Going from the first node to the last node across all frames, and filtering them one by one
        uxFiltered(ii,:) = filter(EquirippleLowPassFilterParams, ux(ii,:));
        uyFiltered(ii,:) = filter(EquirippleLowPassFilterParams, uy(ii,:));
        % Note: Using low-pass time filter will shift the output back by (Filter Order - 1)/ 2
    end
    disp('_________ Filtering and shifting displacements complete! _________')

%% Output in the proper format
    for ii = FramesDoneNumbers(1:(end-SampleBackShift))        % ux, uy rows are node displacements over time, columns are frame numbers (i.e., time).
        displFieldFiltered(ii).vec(:,1) = uxFiltered(:, ii);
        displFieldFiltered(ii).vec(:,2) = uxFiltered(:, ii);
        displFieldFiltered(ii).pos = displField(ii).pos;
    end
    clear displField
    displField = displFieldFiltered;        % Replace with filtered one. 
    
    try
        [DisplFilePath, DisplFileName, DisplFileExt] = fileparts(DisplacementFileFullName);
        displacementFileNameFiltered = sprintf('%sLowPassFiltered%s', DisplFileName, DisplFileExt); 
        displacementFileNameFilterParameters = sprintf('%sLowPassFilterParameters%s', DisplFileName, DisplFileExt); 
        DisplFieldPathsUp = strsplit(DisplFilePath, filesep);
        displacementFilePathFiltered =  fullfile( fullfile(DisplFilePath, '..'), strcat(DisplFieldPathsUp{end}, 'Filtered'));
    catch
        % continue
    end    
    
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