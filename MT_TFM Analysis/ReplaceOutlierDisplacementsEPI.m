%{
    v.2020-09-15..22 Written by Waddah Moghram, PhD Student in Biomedical Engineering at the University of Iowa
    * This function replaces the displacements that were discarded by Outlier Vector Detection code (detectVectorFieldOutliersTFM.m)
        Outlier vectors are saved under variables "AllOutlierIndices" found in "displFieldCorrectionAllParameters.mat"

%}

%% 1. Load the indices of outlier beads in each frame
    [OutlierFileName, OutlierPathName] = uigetfile('*.mat', 'Open "displFieldCorrectionAllParameters.mat" file');
    if OutlierFileName == 0, error('No File was selected'); end
    OutlierFullFileName = fullfile(OutlierPathName, OutlierFileName);
    load(OutlierFullFileName, 'AllOutlierIndices')
    
%     AllOutlierIndicesTMP =AllOutlierIndices
%     % Open Second file again
%     AllOutlierIndices2 = AllOutlierIndices
%     
%     % merged Multiple 
%     for ii = 1:numel(AllOutlierIndices2)
%        AllOutlierIndicesTMP{end+1} =  AllOutlierIndices2{ii};
%     end
%     AllOutlierIndices = AllOutlierIndicesTMP;

    
%% 2. Load the displacement field file 
    OutlierDisplacementFiles = fullfile(OutlierPathName,'*.mat');
    [InputFileName, outputPath] = uigetfile(OutlierDisplacementFiles, 'Open the displacement field "displField.mat" under displacementField or backups');
    if InputFileName == 0, return; end
    InputFileFullName = fullfile(outputPath, InputFileName);

    try
        load(InputFileFullName, 'displField');   
        fprintf('Displacement Field (displField) File is successfully loaded!: \n\t %s\n', InputFileFullName);
        disp('------------------------------------------------------------------------------')
    catch
        errordlg('Could not open the displacement field file.');
        return
    end
        
%% 2. Identify the position and location of those beads
 % 3. eliminate the outliers from displField to be fed to the interpolant function, then 
 % 4. Find the displacements at the locations of the outliers based on the interpolating function.
 
    gridatatMethod = 'cubic';                  % 'cubic';  % cubic leaves more "NaN if the corner is not inside the convex hull polygon.     
    displFieldInterp = displField;
    reverseString = '';
        
    for ii = 1:numel(AllOutlierIndices)
        ProgressMsg = sprintf('\nEvaluating Frame #%d/%d...\n', ii, numel(AllOutlierIndices));
        fprintf([reverseString, ProgressMsg]);
        reverseString = repmat(sprintf('\b'), 1, length(ProgressMsg));
                
        OutliersDisplPos{ii} = displField(ii).pos(AllOutlierIndices{ii},:);
        OutliersDisplVec{ii} = displField(ii).vec(AllOutlierIndices{ii},:);
        
        InterpPos = OutliersDisplPos{ii};
        
        pos = displField(ii).pos;
        pos(AllOutlierIndices{ii}, :) = [];
        
        vec = displField(ii).vec;
        vec(AllOutlierIndices{ii}, :) = [];
        
        minSize = min(size(pos,1), size(vec,1));   

        clear InterpVec
        InterpVec(:, 1) = griddata(pos(:,1), pos(:,2), vec(:,1), InterpPos(:,1), InterpPos(:,2), gridatatMethod);
        InterpVec(:, 2) = griddata(pos(:,1), pos(:,2), vec(:,2), InterpPos(:,1), InterpPos(:,2), gridatatMethod);
        
        NaNCubicInterp = unique(find(isnan(InterpVec(:,1))));
        correctedValues =  ~isempty(NaNCubicInterp);

        if correctedValues
            InterpVec(NaNCubicInterp, 1) = griddata(pos(:,1), pos(:,2), vec(:,1), InterpPos(NaNCubicInterp,1), InterpPos(NaNCubicInterp,2), 'v4');
            InterpVec(NaNCubicInterp, 2) = griddata(pos(:,1), pos(:,2), vec(:,2), InterpPos(NaNCubicInterp,1), InterpPos(NaNCubicInterp,2), 'v4');

            if find(isnan(InterpVec(NaNCubicInterp)))
                InterpVec(NaNCubicInterp, 1) = griddata(pos(:,1), pos(:,2), vec(:,1), InterpPos(NaNCubicInterp,1), InterpPos(NaNCubicInterp,2), 'linear');
                InterpVec(NaNCubicInterp, 2) = griddata(pos(:,1), pos(:,2), vec(:,2), InterpPos(NaNCubicInterp,1), InterpPos(NaNCubicInterp,2), 'linear');
            end
        end
        
        displFieldInterp(ii).vec(AllOutlierIndices{ii},:) = InterpVec;
    end

%% Save the output
    clear displField
    displField =  displFieldInterp;

    [InterpolatedFileName, InterpolatedPathName] = uiputfile('*.mat','Where to save interpolated "displField.mat" file',  fullfile(outputPath, 'displFieldInterpolated.mat'));
    if OutlierFileName == 0, error('No File was selected'); end
    InterpolatedFullFileName = fullfile(InterpolatedPathName, InterpolatedFileName);

    save(InterpolatedFullFileName, 'displField', 'AllOutlierIndices', '-v7.3')


