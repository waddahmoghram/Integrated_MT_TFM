% function [MaxDisplacementDetails, outputPlotFileNameFig] = ExtractBeadMaxDisplacementEPIGrid(MD, displField, AnalysisFolderAsWell,FrameNumberMaxDisplacementGuess, CutoffPercentage)
%%
%{
    v.2020-02-24 by Waddah Moghram
        1. Find the percentage for each frame instead of a global one.
    v.2020-02-21..22 by Waddah Moghram
        1. Generates a plot for the contact radius based on a certain level of maximum displacement over all frames.

    v.2020-02-05 by Waddah Moghram
        1. Updated interpolation from griddata to use V4 based on the cubic interpolation to ensure a C2 continuous function.
        2. Renamed from ExtractBeadCoordinatesEpiMaxInterp.m to ExtractBeadMaxDisplacementEPIGrid.m
    v.2020-02-04 by Waddah Moghram
        1. supersedes FluoroBeadDisplacementMaxInterp.m (v.2019-02-07) and
        is based on ExtractBeadCoordinatesEpiMax.m (v.2020-01-29).

  % **********************TO DO: Re-do by using interpolated value instead of the coordniates of an individual value *********************
    v.2020-01-29 by Waddah Moghram
        1. updated so that t=0 for the first frame.
    v.2020-01-17 by Waddah Moghram
        1. Save max displacement in *.mat to be used by VideoAnalysisCombined.mat
    v.2020-01-16 by Waddah Moghram
        Fixed the time frame so that they are in seconds.

    Written by Waddah Moghram, PhD Student in Biomedical Engineering at the University of Iowa... Updated on 2019-05-27
    % update
  %}
%%
PlotsFontName = 'XITS';
PlotTitleFontName = 'Inconsolata Condensed Medium';

EdgeErode = 1;
gridMagnification = 1;
bandSize = 0;
%______________
% Check if this device has a GPU device. Take advantage of it.
nGPU = gpuDeviceCount;

if nGPU > 0
    useGPU = true;
else
    useGPU = false;
end

%% --------  nargin 1, Movie Data (MD) by TFM Package -------------------------------------------------------------------
if ~exist('MD', 'var'), MD = []; end

try
    isMD = (class(MD) ~= 'MovieData');
catch
    MD = [];
end

%     if nargin < 1 || isempty(MD)
if isempty(MD)
    [movieFileName, movieFilePath] = uigetfile('*.mat', 'Open the TFM-Package Movie Data File');
    if movieFileName == 0, return; end
    MovieFileFullName = fullfile(movieFilePath, movieFileName);

    try
        load(MovieFileFullName, 'MD')
        fprintf('Movie Data (MD) file is: \n\t %s\n', MovieFileFullName);
        disp('------------------------------------------------------------------------------')
    catch
        errordlg('Could not open the movie data file!')
        return
    end

    try
        isMD = (class(MD) ~= 'MovieData');
    catch
        errordlg('Could not open the movie data file!')
        return
    end

else
    movieFilePath = MD.getPath;
end

try
    ScaleMicronPerPixel = MD.pixelSize_ / 1000;
catch
    [ScaleMicronPerPixel, ~, ~] = MagnificationScalesMicronPerPixel([]);
end

%% --------  nargin 2, displacement field (displField) -------------------------------------------------------------------
if ~exist('displField', 'var'), displField = []; end
%     if nargin < 2 || isempty(displField)
if isempty(displField)

    try
        ProcessTag = MD.findProcessTag('DisplacementFieldCorrectionProcess').tag_;
    catch

        try
            ProcessTag = MD.findProcessTag('DisplacementFieldCalculationProcess').tag_;
        catch
            ProcessTag = '';
            disp('No Completed Displacement Field Calculated!');
            disp('------------------------------------------------------------------------------')
        end

    end

    %------------------
    if exist('ProcessTag', 'var')
        fprintf('Displacement Process Tag is: %s\n', ProcessTag);

        try
            InputFileFullName = MD.findProcessTag(ProcessTag).outFilePaths_{1};

            if exist(InputFileFullName, 'file')
                dlgQuestion = sprintf('Do you want to open the displacement field referred to in the movie data file?\n\n%s\n', ...
                    InputFileFullName);
                dlgTitle = 'Open displacement field (displField.mat) file?';
                OpenDisplacementChoice = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No', 'Yes');

                switch OpenDisplacementChoice
                    case 'Yes'
                        [displacementOutputPath, ~, ~] = fileparts(InputFileFullName);
                    case 'No'
                        InputFileFullName = [];
                    otherwise
                        return
                end

            else
                InputFileFullName = [];
            end

        catch
            InputFileFullName = [];
        end

    end

end

%------------------
if isempty(InputFileFullName) || ~exist('ProcessTag', 'var')
    TFMPackageFiles = fullfile(movieFilePath, 'TFMPackage', '*.mat');
    [displacementFileName, displacementOutputPath] = uigetfile(TFMPackageFiles, 'Open the displacement field "displField.mat" under displacementField or backups');
    if displacementFileName == 0, return; end
    InputFileFullName = fullfile(displacementOutputPath, displacementFileName);
end

%------------------
try
    load(InputFileFullName, 'displField');
    fprintf('Displacement Field (displField) File is successfully loaded!: \n\t %s\n', InputFileFullName);
    disp('------------------------------------------------------------------------------')
catch
    errordlg('Could not open the displacement field file.');
    return
end

FramesDoneBoolean = arrayfun(@(x) ~isempty(x.vec), displField);
FramesDoneNumbers = find(FramesDoneBoolean == 1);
FramesDifference = diff(FramesDoneNumbers);
VeryLastFrame = find(FramesDoneBoolean, 1, 'last');
VeryFirstFrame = find(FramesDoneBoolean, 1, 'first');

%% -----------------------------------------------------------------------------------------------------------------------
if ~exist('AnalysisFolderAsWell', 'var'), AnalysisFolderAsWell = []; end
%     if nargin < 3 || isempty(AnalysisFolderAsWell) || AnalysisFolderAsWell ==0 || upper(AnalysisFolderAsWell) == 'N'
if isempty(AnalysisFolderAsWell) || AnalysisFolderAsWell == 0 || upper(AnalysisFolderAsWell) == 'N'

    if exist('displacementOutputPath', 'var')
        dlgQuestion = ({'Do you want to save the output to this folder?', displacementOutputPath});
        dlgTitle = 'Output folder?';
        outputFolderChoice = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No', 'Yes');

        switch outputFolderChoice
            case 'Yes'
                FramesOutputPath = displacementOutputPath;

                if ~exist(FramesOutputPath, 'dir') % Check for a directory
                    mkdir(FramesOutputPath);
                end

            case 'No'
                FramesOutputPath = uigetdir(movieFilePath, 'Choose the directory where the tracked output will be saved.');
            otherwise
                return;
        end

    end

    dlgQuestion = ({'Do you want to save in an Analysis output folder?'});
    dlgTitle = 'Analysis folder?';
    AnalysisFolderAsWell = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No', 'No');

    switch AnalysisFolderAsWell
        case 'Yes'
            AnalysisFolderAsWell = 1;
        case 'No'
            AnalysisFolderAsWell = 0;
    end

end

if AnalysisFolderAsWell == 1 || upper(AnalysisFolderAsWell) == 'Y'
    if ~exist('movieFileDir', 'var'), movieFilePath = pwd; end
    AnalysisOutputPath = uigetdir(movieFilePath, 'Choose the directory where the tracked output will be saved.');
end

if ~exist('AnalysisOutputPath', 'var'), AnalysisOutputPath = []; end

%% ______________________________________________________________________________
NumFrames = numel(displField);
MaxDisplFrameNumber = 0;
MaxDisplFieldIndex = 0;

FramesDoneBoolean = arrayfun(@(x) ~isempty(x.vec), displField);
FramesDoneNumbers = find(FramesDoneBoolean == 1);
FramesDifference = diff(FramesDoneNumbers);
VeryLastFrame = find(FramesDoneBoolean, 1, 'last');
VeryFirstFrame = find(FramesDoneBoolean, 1, 'first');

prompt = {sprintf('Choose the first frame to plotted. [Default, Frame = %d]', VeryFirstFrame)};
dlgTitle = 'First Frame Plotted';
FirstFrameStr = inputdlg(prompt, dlgTitle, [1, 90], {num2str(VeryFirstFrame)});
if isempty(FirstFrameStr), return; end
FirstFrame = str2double(FirstFrameStr{1});
[~, FirstFrameIndex] = min(abs(FramesDoneNumbers - FirstFrame));
FirstFrame = FramesDoneNumbers(FirstFrameIndex);

prompt = {sprintf('Choose the last frame to plotted. [Default, Frame = %d]', VeryLastFrame)};
dlgTitle = 'Last Frame Plotted';
LastFrameStr = inputdlg(prompt, dlgTitle, [1, 90], {num2str(VeryLastFrame)});
if isempty(LastFrameStr), return; end
LastFrame = str2double(LastFrameStr{1});
[~, LastFrameIndex] = min(abs(FramesDoneNumbers - LastFrame));
LastFrame = FramesDoneNumbers(LastFrameIndex);

FramesDoneNumbers = FramesDoneNumbers(FirstFrameIndex:LastFrameIndex);

dlgQuestion = ({'Which timestamps do you want to use)?'});
dlgTitle = 'Real-Time vs. Camera-Time vs. from FPS rate?';
TimeStampChoice = questdlg(dlgQuestion, dlgTitle, 'Real-Time', 'Camera-Time', 'From FPS rate', 'Camera-Time');
if isempty(TimeStampChoice), error('No Choice was made'); end

switch TimeStampChoice
    case 'Real-Time'

        try
            [TimeStampFileNameEPI, TimeStampPathEPI] = uigetfile(movieFilePath, 'EPI TimeStamps RT Sec');
            if isempty(TimeStampFileNameEPI), error('No File Was chosen'); end
            TimeStampFullFileNameEPI = fullfile(TimeStampPathEPI, TimeStampFileNameEPI);
            TimeStampsRT_SecData = load(TimeStampFullFileNameEPI);
            TimeStamps = TimeStampsRT_SecData.TimeStampsAbsoluteRT_Sec;
            FrameRate = 1 / mean(diff(TimeStampsRT_SecData.TimeStampsAbsoluteRT_Sec));
        catch
            [TimeStamps, ~, ~, ~, AverageFrameRate] = TimestampRTfromSensorData();
            FrameRate = 1 / AverageFrameRate;
        end

        xLabelTime = 'Real Time [s]';

    case 'Camera-Time'

        try
            [TimeStampFileNameEPI, TimeStampPathEPI] = uigetfile(movieFilePath, 'EPI TimeStamps ND2 Sec');
            if isempty(TimeStampFileNameEPI), error('No File Was chosen'); end
            TimeStampFullFileNameEPI = fullfile(TimeStampPathEPI, TimeStampFileNameEPI);
            TimeStampsND2_SecData = load(TimeStampFullFileNameEPI);
            TimeStamps = TimeStampsND2_SecData.TimeStampsND2;
            FrameRate = 1 / TimeStampsND2_SecData.AverageTimeInterval;
        catch

            try
                [TimeStamps, ~, AverageTimeInterval] = ND2TimeFrameExtract(movieData.channels_.channelPath_);
            catch
                [TimeStamps, ~, AverageTimeInterval] = ND2TimeFrameExtract();
            end

            FrameRate = 1 / AverageTimeInterval;
        end

        xLabelTime = 'Camera Time [s]';

    case 'From FPS rate'

        try
            FrameRateDefault = 1 / MD.timeInterval_;
        catch
            FrameRateDefault = 1/0.025; % (40 frames per seconds)
        end

        prompt = {sprintf('Choose the Frame Rate per second for this movie. [Default, %.4g]', FrameRateDefault)};
        dlgTitle = 'Frames Per Second';
        FrameRateStr = inputdlg(prompt, dlgTitle, [1, 90], {num2str(FrameRateDefault)});
        if isempty(FrameRateStr), error('No Frame Rate was chosen'); end
        FrameRate = str2double(FrameRateStr{1});

        TimeStamps = FramesDoneNumbers ./ FrameRate;
        xLabelTime = 'Time based on frame rate [s]';
end

LastFrameOverall = min([LastFrame, numel(TimeStamps)]);
FramesDoneNumbers = FramesDoneNumbers(1:find(FramesDoneNumbers == LastFrameOverall));
TimeStampsSec = TimeStamps(FramesDoneNumbers);
%     TimeStampsSec = TimeStampsSec - TimeStampsSec(1);               % MAKE SURE TIME IS REFERENCE TO T = 0 FOR THE FIRST FRAME

%% Check if there is a given frame or frame range where you know the maximum displacement is there
if ~exist('FrameNumberMaxDisplacementGuess', 'var'), FrameNumberMaxDisplacementGuess = []; end
%     if nargin < 4 || isempty(FrameNumberMaxDisplacementGuess)
if isempty(FrameNumberMaxDisplacementGuess)
    dlgQuestion = 'Do you want to search for the frame of maximum displacement in a certain range?';
    dlgTitle = 'Search for max frame?';
    MaxFrameSearchChoice = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No', 'Yes');
end

switch MaxFrameSearchChoice
    case 'Yes'
        prompt = {sprintf('Choose the first frame to searched. [Default, Frame = %d]', FirstFrame)};
        dlgTitle = 'First Frame Searched';
        FirstFrameStr = inputdlg(prompt, dlgTitle, [1, 60], {num2str(FirstFrame)});
        if isempty(FirstFrameStr), return; end
        FirstFrameSearch = str2double(FirstFrameStr{1});
        [~, FirstFrameIndexSearch] = min(abs(FramesDoneNumbers - FirstFrameSearch));
        %             FirstFrameSearch = FramesDoneNumbers(FirstFrameIndex);

        prompt = {sprintf('Choose the last frame to searched. [Default, Frame = %d]', LastFrame)};
        dlgTitle = 'Last Frame Searched';
        LastFrameStr = inputdlg(prompt, dlgTitle, [1, 90], {num2str(LastFrame)});
        if isempty(LastFrameStr), return; end
        LastFrameSearch = str2double(LastFrameStr{1});
        [~, LastFrameIndexSearch] = min(abs(FramesDoneNumbers - LastFrameSearch));
        %             LastFrameSearch = FramesDoneNumbers(LastFrameIndex);

        FramesDoneNumbersSearch = FramesDoneNumbers(FirstFrameIndexSearch:LastFrameIndexSearch);

    case 'No'
        FramesDoneNumbersSearch = FramesDoneNumbers;
        % Continue
    otherwise
        return
end

%% Finding maximum bead
dMap = cell(1, numel(displField));
dMapX = cell(1, numel(displField));
dMapY = cell(1, numel(displField));
displFieldMaxDisplPixelsNet = -1;
[reg_grid, ~, ~, GridSpacing] = createRegGridFromDisplField(displField(FramesDoneNumbers(1)).pos, gridMagnification, EdgeErode); % 2=2 times fine interpolation

if useGPU
    reg_grid = gpuArray(reg_grid);
end

reverseString = '';

for CurrentFrame = FramesDoneNumbersSearch
    ProgressMsg = sprintf('Searching Frame #%d/(%d-%d)...\n', CurrentFrame, FramesDoneNumbersSearch(1), FramesDoneNumbersSearch(end));
    fprintf([reverseString, ProgressMsg]);
    reverseString = repmat(sprintf('\b'), 1, length(ProgressMsg));
    %
    [grid_mat, displVecGridXY, ~, ~] = interp_vec2grid(displField(CurrentFrame).pos(:, 1:2), displField(CurrentFrame).vec(:, 1:2), [], reg_grid);

    grid_spacingX = grid_mat(1, 2, 1) - grid_mat(1, 1, 1);
    grid_spacingY = grid_mat(2, 1, 2) - grid_mat(1, 1, 2);
    imSizeX = (grid_mat(end, end, 1) - grid_mat(1, 1, 1)) + grid_spacingX;
    imSizeY = (grid_mat(end, end, 2) - grid_mat(1, 1, 2)) + grid_spacingY;
    width = imSizeX;
    height = imSizeY;
    centerX = ((grid_mat(end, end, 1) + grid_mat(1, 1, 1)) / 2);
    centerY = ((grid_mat(end, end, 2) + grid_mat(1, 1, 2)) / 2);
    % [XI,YI] = meshgrid(grid_mat(1,1,1):grid_mat(1,1,1)+imSizeX,grid_mat(1,1,2):grid_mat(1,1,2)+imSizeY);
    Xmin = centerX - width / 2 + bandSize;
    Xmax = centerX + width / 2 - bandSize;
    Ymin = centerY - height / 2 + bandSize;
    Ymax = centerY + height / 2 - bandSize;
    %         [XI, YI] = meshgrid(Xmin:Xmax,Ymin:Ymax);

    [XI, YI] = ndgrid(Xmin:Xmax, Ymin:Ymax);
    reg_gridFull(:, :, 1) = XI; reg_gridFull(:, :, 2) = YI;

    [grid_mat_full, displVecGridFullXY, ~, ~] = interp_vec2grid(displField(CurrentFrame).pos(:, 1:2), displField(CurrentFrame).vec(:, 1:2), [], reg_gridFull, 'griddata');
    displHeatMapFullX = displVecGridFullXY(:, :, 1);
    displHeatMapFullY = displVecGridFullXY(:, :, 2);
    displHeatMapFullNorm = (displVecGridFullXY(:, :, 1).^2 + displVecGridFullXY(:, :, 2).^2).^0.5;

    [tmpMaxDisplFieldNetInFrame, tmpMaxDisplFieldInFrameIndex] = max(displHeatMapFullNorm(:)); % maximum item in a column

    if tmpMaxDisplFieldNetInFrame > displFieldMaxDisplPixelsNet
        %             displFieldMaxPosFrameX = XI;
        %             displFieldMaxPosFrameY = YI;
        %
        %             displFieldMaxVecFrameX = displHeatMapX;
        %             displFieldMaxVecFrameY = displHeatMapY;
        %             displFieldMaxVecFrameNet = displHeatMap;
        displFieldMaxDisplPixelsNet = tmpMaxDisplFieldNetInFrame;
        MaxDisplFieldIndex = tmpMaxDisplFieldInFrameIndex;
        MaxDisplFrameNumber = CurrentFrame;
        MaxDisplPixelsXYnet = [displHeatMapFullX(MaxDisplFieldIndex), displHeatMapFullY(MaxDisplFieldIndex), displHeatMapFullNorm(MaxDisplFieldIndex)];
        MaxPosXYnet = [XI(MaxDisplFieldIndex), YI(MaxDisplFieldIndex)];
    end

end

MaxDisplMicronsXYnetContact = MaxDisplPixelsXYnet * ScaleMicronPerPixel;
fprintf('Maximum displacement = %0.4g pixels at ', displFieldMaxDisplPixelsNet);
fprintf('[x,y] = [%g, %g] pixels in Frame #%d, Point Index #%d \n', MaxPosXYnet, MaxDisplFrameNumber, MaxDisplFieldIndex)
fprintf('Maximum displacement [disp_x, disp_y] =  [%0.4g, %0.4g] pixels==> Net displacement [disp_net] = [%0.4g] pixels. \n', MaxDisplPixelsXYnet)
fprintf('Maximum displacement [disp_x, disp_y] =  [%0.4g, %0.4g] microns==> Net displacement [disp_net] = [%0.4g] microns. \n', MaxDisplMicronsXYnetContact)

%% Nargin 5
prompt = {sprintf('Choose the maximum displacement in microns. [Default, = %0.4g microns]', MaxDisplMicronsXYnetContact(3))};
dlgTitle = 'Maximum Displacement';
MaximumDisplacementMicronStr = inputdlg(prompt, dlgTitle, [1, 90], {num2str(str2double(sprintf('%0.4g', MaxDisplMicronsXYnetContact(3))))});
if isempty(MaximumDisplacementMicronStr), return; end
MaximumDisplacementMicron = str2double(MaximumDisplacementMicronStr{1});

if ~exist('CutoffPercentage', 'var'), CutoffPercentage = []; end
%     if nargin < 5 || isempty(CutoffPercentage)
if isempty(CutoffPercentage)
    CutoffPercentage = 95;
end

prompt = {sprintf('Choose the cutoff percentage of maximum displacement chosen. [Default, = %0.3g%%]', CutoffPercentage)};
dlgTitle = 'Cutoff Percentage';
CutoffPercentageStr = inputdlg(prompt, dlgTitle, [1, 90], {num2str(str2double(sprintf('%0.3g', CutoffPercentage)))});
if isempty(CutoffPercentageStr), return; end
CutoffPercentage = str2double(CutoffPercentageStr{1});
CutoffPercentage = CutoffPercentage / 100;
CutoffLevelMicrons = CutoffPercentage .* MaximumDisplacementMicron;

%%  Track the max over all Frames.
reverseString = '';

for CurrentFrame = FramesDoneNumbers
    ProgressMsg = sprintf('Tracking Maximum Node at Frame #%d/(%d-%d)...\n', CurrentFrame, FramesDoneNumbers(1), FramesDoneNumbers(end));
    fprintf([reverseString, ProgressMsg]);
    reverseString = repmat(sprintf('\b'), 1, length(ProgressMsg));

    [grid_mat, displVecGridXY, ~, ~] = interp_vec2grid(displField(CurrentFrame).pos(:, 1:2), displField(CurrentFrame).vec(:, 1:2), [], reg_grid, 'griddata');
    grid_spacingX = grid_mat(1, 2, 1) - grid_mat(1, 1, 1);
    grid_spacingY = grid_mat(2, 1, 2) - grid_mat(1, 1, 2);
    imSizeX = (grid_mat(end, end, 1) - grid_mat(1, 1, 1)) + grid_spacingX;
    imSizeY = (grid_mat(end, end, 2) - grid_mat(1, 1, 2)) + grid_spacingY;

    width = imSizeX;
    height = imSizeY;
    centerX = ((grid_mat(end, end, 1) + grid_mat(1, 1, 1)) / 2);
    centerY = ((grid_mat(end, end, 2) + grid_mat(1, 1, 2)) / 2);
    % [XI,YI] = meshgrid(grid_mat(1,1,1):grid_mat(1,1,1)+imSizeX,grid_mat(1,1,2):grid_mat(1,1,2)+imSizeY);
    Xmin = centerX - width / 2 + bandSize;
    Xmax = centerX + width / 2 - bandSize;
    Ymin = centerY - height / 2 + bandSize;
    Ymax = centerY + height / 2 - bandSize;
    %         [XI, YI] = meshgrid(Xmin:Xmax,Ymin:Ymax);
    [XI, YI] = ndgrid(Xmin:Xmax, Ymin:Ymax);

    reg_gridFull(:, :, 1) = XI; reg_gridFull(:, :, 2) = YI;
    [grid_mat_full, displVecGridFullXY, ~, ~] = interp_vec2grid(displField(CurrentFrame).pos(:, 1:2), displField(CurrentFrame).vec(:, 1:2), [], reg_gridFull, 'griddata');
    displHeatMapFullX = displVecGridFullXY(:, :, 1);
    displHeatMapFullY = displVecGridFullXY(:, :, 2);
    displHeatMapFullNorm = (displVecGridFullXY(:, :, 1).^2 + displVecGridFullXY(:, :, 2).^2).^0.5;
    %-----------------------------------------------------------------------------------------------
    % Added by WIM on 2/5/2019
    %         displVecGridNorm = (displVecGridXY(:,:,1).^2 + displVecGridXY(:,:,2).^2).^0.5;
    %
    %         dMap{CurrentFrame} = displVecGridNorm;
    %         dMapX{CurrentFrame} = displVecGridXY(:,:,1);
    %         dMapY{CurrentFrame} = displVecGridXY(:,:,2);
    %         if useGPU
    %             grid_mat = gather(grid_mat);
    %             displVecGridNorm = gather(displVecGridNorm);
    %             XI = gather(XI);
    %             YI = gather(YI);
    %         end
    %
    %         grid_matX = grid_mat(:,:,1);
    %         grid_matY = grid_mat(:,:,2);
    %         [displHeatMap,displHeatMapX, displHeatMapY]  = interp_gridNoNaNs(displField(CurrentFrame).pos(:,1), displField(CurrentFrame).pos(:,2), dMapX,dMapY, XI, YI, CurrentFrame, MaskSizePerSide);
    %
    TxRedBeadMaxNetPositionPixels(CurrentFrame, :) = [XI(MaxDisplFieldIndex), YI(MaxDisplFieldIndex)];
    TxRedBeadMaxNetDisplacementPixels(CurrentFrame, 1:3) = [displHeatMapFullX(MaxDisplFieldIndex), displHeatMapFullY(MaxDisplFieldIndex), displHeatMapFullNorm(MaxDisplFieldIndex)];

    %______________ Calculate Contact Area
    TotalAreaMicronSq(CurrentFrame) = prod(MD.imSize_ * ScaleMicronPerPixel);
    %         ContactAreaPercentage(CurrentFrame) = sum((displHeatMapFullNorm * ScaleMicronPerPixel) >= CutoffLevelMicrons, 'all') ./ numel(displHeatMapFullNorm);      % 2020-02-22
    ContactAreaPercentage(CurrentFrame) = sum((displHeatMapFullNorm * ScaleMicronPerPixel) >= (CutoffPercentage .* max(displHeatMapFullNorm(:))), 'all') ./ numel(displHeatMapFullNorm); % 2020-02-24
    ContactAreaMicronSq(CurrentFrame) = TotalAreaMicronSq(CurrentFrame) .* ContactAreaPercentage(CurrentFrame);
end

TxRedBeadMaxNetDisplacementMicrons = TxRedBeadMaxNetDisplacementPixels * ScaleMicronPerPixel; % convert from micron to nm

%% ---------------- PLOTS
% From field vectors are not cumulative.
%     TxRedBeadMaxNetDisplacementPixels(:,3) = vecnorm(TxRedBeadMaxNetDisplacementPixels(:,1:2),2,2);
%     TxRedBeadMaxNetDisplacementMicrons(:,3) = vecnorm(TxRedBeadMaxNetDisplacementMicrons(:,1:2),2,2);

figHandleBeadMaxNetDispl = figure('color', 'w', 'Renderer', 'painters');
plot(TimeStampsSec, TxRedBeadMaxNetDisplacementMicrons(FramesDoneNumbers, 3), 'r.-', 'LineWidth', 1', 'MarkerSize', 2)
xlim([0, TimeStampsSec(end)]);
set(findobj(gcf, 'type', 'axes'), ...
    'FontSize', 12, ...
    'FontName', 'Helvetica', ...
    'LineWidth', 1, ...
    'XMinorTick', 'on', ...
    'YMinorTick', 'on', ...
    'TickDir', 'out', ...
    'TitleFontSizeMultiplier', 0.9, ...
    'TitleFontWeight', 'bold'); % Make axes bold
xlabelHandle = xlabel(sprintf('\\rm %s', xLabelTime));
set(xlabelHandle, 'FontName', PlotsFontName)
ylabel('\bf|\it\Delta\rm_{TxRed}(\itt\rm)\bf|\rm [\mum]', 'FontName', PlotsFontName);

MaxDisplMicronsXYnetContact = MaxDisplPixelsXYnet * ScaleMicronPerPixel;

title({'Maximum Net EPI Bead Displacement (Interpolated)', sprintf('Max at (X,Y) = (%d,%d) pix in Frame %d/%d = %0.3f sec', ...
        XI(MaxDisplFieldIndex), YI(MaxDisplFieldIndex), ...
        MaxDisplFrameNumber, LastFrame, TimeStamps(MaxDisplFrameNumber)), ...
        sprintf('Max displacement = %0.4f pix = %0.4f \\mum', MaxDisplPixelsXYnet(3), MaxDisplMicronsXYnetContact(3))}, ...
    'FontName', PlotTitleFontName)

MaxDisplacementDetails.TimeFrameSeconds = TimeStampsSec;
MaxDisplacementDetails.TxRedBeadMaxNetPositionPixels = TxRedBeadMaxNetPositionPixels;
MaxDisplacementDetails.TxRedBeadMaxNetDisplacementPixels = TxRedBeadMaxNetDisplacementPixels;
MaxDisplacementDetails.TxRedBeadMaxNetDisplacementMicrons = TxRedBeadMaxNetDisplacementMicrons;
MaxDisplacementDetails.MaxDisplFrameNumber = MaxDisplFrameNumber;
MaxDisplacementDetails.MaxDisplMicronsXYnetContact = MaxDisplMicronsXYnetContact;
MaxDisplacementDetails.MaxDisplPixelsXYnet = MaxDisplPixelsXYnet;
MaxDisplacementDetails.MaxPosXYnet = MaxPosXYnet;

%%
disp('**___to continue saving, type "dbcont" or press "F5", or click "Continue" under "Editor" Menu"___**')
keyboard

%%
outputPlotFileNameFig = fullfile(FramesOutputPath, sprintf('Net Displacement_TxRed_max_interp_%s.fig', TimeStampChoice));
%     outputPlotFileNameTIF = fullfile(FramesOutputPath,  sprintf('Net Displacement_TxRed_max_interp_%s.tif', TimeStampChoice));
outputPlotFileNamePNG = fullfile(FramesOutputPath, sprintf('Net Displacement_TxRed_max_interp_%s.png', TimeStampChoice));
outputPlotFileNameMAT = fullfile(FramesOutputPath, sprintf('Net Displacement_TxRed_max_interp_%s.mat', TimeStampChoice));

savefig(figHandleBeadMaxNetDispl, outputPlotFileNameFig, 'compact');
%     FrameImage = getframe(figHandleBeadMaxNetDispl);
%     imwrite(FrameImage.cdata, outputPlotFileNameTIF);
saveas(figHandleBeadMaxNetDispl, outputPlotFileNamePNG, 'png')
save(outputPlotFileNameMAT, 'TimeStampsSec', 'TxRedBeadMaxNetPositionPixels', 'TxRedBeadMaxNetDisplacementPixels', ...
    'MaxDisplFieldIndex', 'TxRedBeadMaxNetDisplacementMicrons', 'MaxDisplFrameNumber', 'MaxDisplPixelsXYnet', 'FrameRate', '-v7.3')

%%
if AnalysisFolderAsWell
    outputPlotFileNameFigAnalysis = fullfile(AnalysisOutputPath, sprintf('07 Net Displacement_TxRed_max_interp_%s.fig', TimeStampChoice));
    %     outputPlotFileNameTIFAnalysis = fullfile(AnalysisOutputPath, sprintf('07 Net Displacement_TxRed_max_interp_%s.tif', TimeStampChoice));
    outputPlotFileNamePNGAnalysis = fullfile(AnalysisOutputPath, sprintf('07 Net Displacement_TxRed_max_interp_%s.png', TimeStampChoice));
    outputPlotFileNameMATAnalysis = fullfile(AnalysisOutputPath, sprintf('07 Net Displacement_TxRed_max_interp_%s.mat', TimeStampChoice));

    savefig(figHandleBeadMaxNetDispl, outputPlotFileNameFigAnalysis, 'compact');
    %         FrameImage = getframe(figHandleBeadMaxNetDispl);
    %         imwrite(FrameImage.cdata, outputPlotFileNameTIFAnalysis);
    saveas(figHandleBeadMaxNetDispl, outputPlotFileNamePNGAnalysis, 'png')
    save(outputPlotFileNameMATAnalysis, 'TimeStampsSec', 'TxRedBeadMaxNetPositionPixels', 'TxRedBeadMaxNetDisplacementPixels', 'MaxDisplMicronsXYnetContact', ...
        'MaxDisplFieldIndex', 'TxRedBeadMaxNetDisplacementMicrons', 'MaxDisplFrameNumber', 'MaxDisplPixelsXYnet', 'FrameRate', '-v7.3')
end

%______________________ added on 2020-02-22

figContactArea = figure('color', 'w');
plot(TimeStampsSec, ContactAreaMicronSq(FramesDoneNumbers), 'r.-', 'LineWidth', 1, 'MarkerSize', 1);
set(findobj(figContactArea, 'type', 'axes'), ...
    'FontSize', 11, ...
    'FontName', 'Helvetica', ...
    'LineWidth', 1, ...
    'XMinorTick', 'on', ...
    'YMinorTick', 'on', ...
    'TickDir', 'out', ...
    'TitleFontSizeMultiplier', 0.9, ...
    'TitleFontWeight', 'bold'); % Make axes bold
xlim([TimeStampsSec(1), TimeStampsSec(end)]);
xlabel('\rmtime [\its\rm]', 'FontName', PlotsFontName)
ylabel(sprintf('%d%% of \\it\\bfu\\rm(\\itx,y,t\\rm)_{max} contact area [\\mum^{2}]', CutoffPercentage * 100), ...
    'FontName', PlotsFontName)
title({sprintf('%d%% of \\it\\bfu\\rm(\\itx,y,t\\rm)_{max} \\bf= %0.4g \\mum contact area [\\mum^{2}]', CutoffPercentage * 100, MaxDisplMicronsXYnetContact(3))})

FileNameFIG1 = 'Net Displacement Effective Contact Area.fig';
ContactAreaFIG1 = fullfile(FramesOutputPath, FileNameFIG1);
savefig(figContactArea, ContactAreaFIG1, 'compact')

if AnalysisFolderAsWell
    AnalysisContactAreaFIG = fullfile(AnalysisOutputPath, strjoin('07', FileNameFIG1, ' '));
    savefig(figContactArea, AnalysisContactAreaFIG, 'compact')
end

FileNamePNG1 = 'Net Displacement Effective Contact Area.png';
ContactAreaPNG1 = fullfile(FramesOutputPath, FileNamePNG1);
saveas(figContactArea, ContactAreaPNG1, 'png')

if AnalysisFolderAsWell
    AnalysisContactAreaPNG = fullfile(AnalysisOutputPath, strjoin('07', FileNamePNG1, ' '));
    savas(figContactArea, AnalysisContactAreaPNG, 'png')
end

FileNameEPS1 = 'Net Displacement Effective Contact Area.eps';
ContactAreaEPS1 = fullfile(FramesOutputPath, FileNameEPS1);
print(figContactArea, ContactAreaEPS1, '-depsc')

if AnalysisFolderAsWell
    AnalysisContactAreaEPS = fullfile(AnalysisOutputPath, strjoin('07', FileNameEPS1, ' '));
    savas(figContactArea, AnalysisContactAreaEPS, '-depsc')
end

% end
%++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
