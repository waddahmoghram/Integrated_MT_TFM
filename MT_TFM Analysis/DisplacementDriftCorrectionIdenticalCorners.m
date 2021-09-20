%{
    v.2020-06-28..29 by Waddah Moghram, PhD Student in Biomedical Engineering at the University of Iowa
        1. this is just an extract part of the code that correct for drift using 
        2. Added a nosieROI, which is the displacements of the corners/ROis after drift has been subtracted

%}

function [displFieldBeadsDriftCorrected, rect, DriftROIs, DriftROIsCombined, reg_grid, gridSpacing, NoiseROIs, NoiseROIsCombined, CornerPercentage] = ...
    DisplacementDriftCorrectionIdenticalCorners(displField, CornerPercentage, FramesDoneNumbers, gridMagnification, ...
    EdgeErode, GridtypeChoiceStr, InterpolationMethod, ShowOutput)


%_____________________ default values
    cornerCount = 4;
    CornerPercentageDefault = 0.10;

    if ~exist('CornerPercentage', 'var'), CornerPercentage = []; end
    if isempty(CornerPercentage) || nargin < 2
        inputStr = sprintf('Choose the percentage of the images size to use for noise adjustment [Default = %g%%]: ', CornerPercentageDefault * 100);
        CornerPercentage = input(inputStr);
        if isempty(CornerPercentage)
           CornerPercentage =  CornerPercentageDefault; 
        else
           CornerPercentage = CornerPercentage / 100;
        end
    end   
    
    if ~exist('FramesDoneNumbers', 'var'), FramesDoneNumbers = []; end
    if isempty(FramesDoneNumbers) || nargin < 2
        FramesDoneBoolean = arrayfun(@(x) ~isempty(x.vec), displField);
        FramesDoneNumbers = find(FramesDoneBoolean == 1);     
    else
        FramesDoneNumbers = FramesDoneNumbers;      % 10 percent.
    end
    FirstFrame = FramesDoneNumbers(1);
    LastFrame = FramesDoneNumbers(end);
    
    if ~exist('gridMagnification', 'var'), gridMagnification = []; end
    if isempty(gridMagnification) || nargin < 4
        gridMagnification = 1;
    end
    
    if ~exist('EdgeErode', 'var'), EdgeErode = []; end
    if isempty(EdgeErode) || nargin < 5
        EdgeErode = 1;
    end
    
    if ~exist('GridtypeChoiceStr', 'var'), GridtypeChoiceStr = []; end
    if isempty(GridtypeChoiceStr) || nargin < 6
        GridtypeChoiceStr = 'Even Grid';
    end
    
    if ~exist('InterpolationMethod', 'var'), InterpolationMethod = []; end
    if isempty(InterpolationMethod) || nargin < 7
        InterpolationMethod = 'griddata';
    end
    
    if ~exist('ShowOutput', 'var'), ShowOutput = []; end
    if isempty(ShowOutput) || nargin < 8
        ShowOutput = true;
    end
%_____________________ 
    switch GridtypeChoiceStr
        case 'Even Grid'
                [reg_grid,~,~,gridSpacing] = createRegGridFromDisplField(displField, gridMagnification, EdgeErode);
        case 'Odd Grid'
                [reg_grid,~,~,gridSpacing] = createRegGridFromDisplFieldOdd(displField, gridMagnification, EdgeErode);
        otherwise
            return
    end       
    
    displFieldPosNotDriftCorrected = displField(FirstFrame).pos;
    displFieldVecNotDriftCorrected = displField(FirstFrame).vec;
    displFieldVecNotDriftCorrected(:,3) = vecnorm(displFieldVecNotDriftCorrected(:,1:2), 2, 2);
    [pos_grid, disp_grid_NoFilter, i_max, j_max] = interp_vec2grid(displFieldPosNotDriftCorrected(:,1:2), displFieldVecNotDriftCorrected(:,1:2),[], reg_grid, InterpolationMethod);        

    gridXmin = min(displField(FirstFrame).pos(:,1));
    gridXmax = max(displField(FirstFrame).pos(:,1));
    gridYmin = min(displField(FirstFrame).pos(:,2));
    gridYmax = max(displField(FirstFrame).pos(:,2));

    cornerLengthPix_X = round(CornerPercentage * (gridXmax - gridXmin));
    cornerLengthPix_Y = round(CornerPercentage * (gridYmax - gridYmin));
    rect(1,:) = [gridXmin, gridYmin, cornerLengthPix_X, cornerLengthPix_Y];                                             % Top-Left Corner: ROI 1:
    rect(2,:) = [gridXmin, gridYmax - cornerLengthPix_Y, cornerLengthPix_X, cornerLengthPix_Y];                         % Bottom-Left Corner: ROI 1:
    rect(3,:) = [gridXmax - cornerLengthPix_X, gridYmin, cornerLengthPix_X, cornerLengthPix_Y];                         % Top-Right Corner: ROI 1:
    rect(4,:) = [gridXmax - cornerLengthPix_X, gridYmax - cornerLengthPix_Y, cornerLengthPix_X, cornerLengthPix_Y];     % Bottom-Right Corner: ROI 1: 

    for ii = 1:cornerCount
        rectCorners = [rect(ii, 1:2); rect(ii, 1:2) + [rect(ii, 3), 0]; rect(ii, 1:2) + [0, rect(ii, 4)]; rect(ii, 1:2) + rect(ii, 3:4)];
        DriftROIxx(ii,:) = rectCorners(:,1)';
        DriftROIyy(ii,:) = rectCorners(:,2)';
        if isempty(DriftROIxx(ii,:)) || isempty(DriftROIyy(ii,:))
            errordlg('The selected noise is empty.','Error');
            return;
        end
        nDriftROIxx(ii, :) = size(DriftROIxx(ii));
        if isempty(DriftROIxx(ii)) || nDriftROIxx(ii,1)==2
            errordlg('Noise does not select','Error');
            return;
        end
    end
    
    clear DriftROIs DriftROIsCombined NoiseROIs NoiseROIsCombined

    reverseString = '';
    if ShowOutput,disp('_______Drift-correcting _______'); end
    
    for CurrentFrame = FramesDoneNumbers
        if ShowOutput
            ProgressMsg = sprintf('Drift Correcting Frame #%d/(%d-%d)...\n',CurrentFrame, FramesDoneNumbers(1),FramesDoneNumbers(end));
            fprintf([reverseString, ProgressMsg]);
            reverseString = repmat(sprintf('\b'), 1, length(ProgressMsg));
        end 
        % Edge Erode to make it a square grid 
        displFieldPos = displField(CurrentFrame).pos;
        displFieldVecNotDriftCorrected = displField(CurrentFrame).vec;
        displFieldVecNotDriftCorrected(:,3) = vecnorm(displFieldVecNotDriftCorrected(:,1:2), 2, 2);

        for ii = 1:cornerCount
            indata(CurrentFrame, ii).Index = inpolygon(displFieldPos(:,1),displFieldPos(:,2), DriftROIxx(ii,:),DriftROIyy(ii,:));
            DriftROIs(CurrentFrame, ii).pos = displFieldPos(indata(CurrentFrame, ii).Index , :);
            DriftROIs(CurrentFrame, ii).vec = displFieldVecNotDriftCorrected(indata(CurrentFrame, ii).Index ,:);
            DriftROIs(CurrentFrame, ii).mean = mean(DriftROIs(CurrentFrame, ii).vec, 'omitnan'); 
            DriftROIs(CurrentFrame, ii).vec(:,3) = vecnorm(DriftROIs(CurrentFrame, ii).vec(:,1:2), 2, 2);
            DriftROIsMeanDispAllCorners(CurrentFrame, ii) = DriftROIs(CurrentFrame, ii).mean(:,3);
        end
        DriftROIsCombinedPos = [];
        DriftROIsCombinedVec = [];        
        for jj = 1:cornerCount
            DriftROIsCombinedPos = [DriftROIsCombinedPos; DriftROIs(CurrentFrame,jj).pos];
            DriftROIsCombinedVec = [DriftROIsCombinedVec; DriftROIs(CurrentFrame,jj).vec];
        end
        DriftROIsCombined(CurrentFrame).pos = DriftROIsCombinedPos;
        DriftROIsCombined(CurrentFrame).vec = DriftROIsCombinedVec;
        DriftROIsCombined(CurrentFrame).mean = mean(DriftROIsCombined(CurrentFrame).vec, 'omitnan');
        DriftROIsCombined(CurrentFrame).mean(:,3) = vecnorm(DriftROIsCombined(CurrentFrame).mean(1:2), 2, 2);

        displFieldVecDriftCorrected = [];
        displFieldVecDriftCorrected(:,1:2) = displFieldVecNotDriftCorrected(:,1:2) - DriftROIsCombined(CurrentFrame).mean(:,1:2);
        displFieldVecDriftCorrected(:,3) = vecnorm(displFieldVecDriftCorrected(:,1:2), 2, 2);
        displFieldVec = displFieldVecDriftCorrected;

        displFieldBeadsDriftCorrected(CurrentFrame).pos = displFieldPos;
        displFieldBeadsDriftCorrected(CurrentFrame).vec = displFieldVec;       
    end
    
%     NoiseROIs = DriftROIs;
%     NoiseROIsCombined = DriftROIsCombined;
    
    clear NoiseROIs NoiseROIsCombinedVec 
    for CurrentFrame = FramesDoneNumbers
        
        % Edge Erode to make it a square grid 
        displFieldPos = displFieldBeadsDriftCorrected(CurrentFrame).pos;
        displFieldVecDriftCorrected = displFieldBeadsDriftCorrected(CurrentFrame).vec;
        displFieldVecDriftCorrected(:,3) = vecnorm(displFieldVecDriftCorrected(:,1:2), 2, 2);
        
         for ii = 1:cornerCount
            NoiseROIs(CurrentFrame, ii).pos = displFieldPos(indata(CurrentFrame, ii).Index , :);
            NoiseROIs(CurrentFrame, ii).vec = displFieldVecDriftCorrected(indata(CurrentFrame, ii).Index ,:);
            NoiseROIs(CurrentFrame, ii).vec(:,3) = vecnorm(NoiseROIs(CurrentFrame, ii).vec(:,1:2), 2, 2);
        end
        NoiseROIsCombinedPos = [];
        NoiseROIsCombinedVec = [];        
        for jj = 1:cornerCount
            NoiseROIsCombinedPos = [NoiseROIsCombinedPos; NoiseROIs(CurrentFrame,jj).pos];
            NoiseROIsCombinedVec = [NoiseROIsCombinedVec; NoiseROIs(CurrentFrame,jj).vec];
        end
        NoiseROIsCombined(CurrentFrame).pos = NoiseROIsCombinedPos;
        NoiseROIsCombined(CurrentFrame).vec = NoiseROIsCombinedVec;
        NoiseROIsCombined(CurrentFrame).mean = mean(NoiseROIsCombined(CurrentFrame).vec, 'omitnan');
        NoiseROIsCombined(CurrentFrame).mean(:,3) = vecnorm(NoiseROIsCombined(CurrentFrame).mean(1:2), 2, 2);
    end
    if ShowOutput
        fprintf('There are %d tracked points: [TL, BL, TR, BR] = [%d,%d,%d, %d] points each in Frame #%d/(%d-%d). \n', size(DriftROIsCombined(CurrentFrame).pos, 1), ...
            size(DriftROIs(CurrentFrame,1).pos, 1), size(DriftROIs(CurrentFrame,2).pos, 1), size(DriftROIs(CurrentFrame,3).pos, 1), size(DriftROIs(CurrentFrame,4).pos, 1), ...
            CurrentFrame,FramesDoneNumbers(1), FramesDoneNumbers(end));
    end
end