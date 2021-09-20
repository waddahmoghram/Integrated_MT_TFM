%{
    v.2019-10-14 by WAddah Moghram
        1. Added x- and y-components of Delta_TFM to see how it matches the traction forces.
    v.2019-10-13 by Waddah Moghram 
        1. Use only back-ward difference derivatives. That means the first frame will have a NaN value, or 0
        2. Changed griddata() to griddeddata() which speeds up the process a lot more.
    v.2019-10-08..09 by Waddah Moghram
        1. Renamed "PlotBeadNetDisplacementEpiMax.m" to "08PlotBeadEpiMaxDisplacementVelocity.m"
        2. Adding the change of Big Delta over time as another plot. Improve NaN plots, and added step Size so that not all frames are calculated.
    v.2019-09-26 by Waddah Moghram
        1. Fixed Average Frame rate not being correct
        2. Improved the plot
        3. Added a *.mat file to save the outputs of this file.
    v.2019-09-22..23 by Waddah Moghram
        1. Updated Epi Max to use Stamps from the ND2 file (tracked displacement time stamps) instead of that for the sensors.
        2. Do not assume default magnification is 30X.
    v.2019-06-13 Written Waddah Moghram
        Based on ExtractBeadCoordinatesEpiMax v. 2019-05-27 & PlotDisplacementHeatmapField  v.2019-06-11 Update 
        1. Renamed "ExtractBeadCoordinatesEpiMax" to "PlotBeadNetDisplacementEpiMax"
        2. Variable renamed: {DisplacementHeatMapPath -> NetDisplacementPath}
        3. Variables removed: {ShowQuiver, 
    ** This version will load all the heatmap to the memory. It will need a lot of RAM ** 
    Other version should save the heat map to the drive.
        
%}

function [BeadNetDisplacementMicronEPImax_EachFrame, MD, displField, FirstFrame, LastFrame, movieFilePath, displacementFilePath, AnalysisPath, NetDisplacementPath, BeadNetDisplacementMicronEPImax_Absolute] = PlotEpiAllBeadsVelocity2(MD, displField, ...
    FirstFrame, LastFrame, NetDisplacementPath, ...
    MagnificationTimes, showPlot, AnalysisPath, MaxDisplacement, bandSize, width, height, TimeStampsND2)

    %% Check if there is a GPU. take advantage of it if is there.
    nGPU = gpuDeviceCount;
%     if nGPU > 0
%         dlgQuestion = 'Do you want to use GPU-Acceleration?';
%         dlgTitle = 'Use GPU?';
%         useGPUchoice = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No', 'Yes');
%         switch useGPUchoice
%             case 'Yes'
%                 useGPU = true;
%             case 'No'
%                 useGPU = false;
%             otherwise
%                 return;
%         end        
%     else
%         useGPU = false; 
%     end
    if nGPU > 0
        useGPU = true;
    else
        useGPU = false;
    end

   %% 
    StepSize = 1;
    
    %% -----------------------------------------------------------------------------------------------
    commandwindow;
    disp('============================== Running PlotBeadCoordinatesEpiMax.m GPU-enabled ===============================================')
    
    %% -----------------------------------------------------------------------------------------------
    if ~exist('MD', 'var'), MD = []; end
    if nargin < 1 || isempty(MD)
        [movieFileName, movieFilePath] = uigetfile('*.mat', 'Open the TFM-Package Movie Data File');
        MovieFileFullName = fullfile(movieFilePath, movieFileName);
        try 
            load(MovieFileFullName, 'MD')
            fprintf('Movie Data (MD) file is: \n\t %s\n', MovieFileFullName);
            disp('------------------------------------------------------------------------------')
        catch 
            errordlg('Could not open the movie data file!')
            return
        end
    end
    
    %% -----------------------------------------------------------------------------------------------
    ProcessTag = '';
    displacementFilePath = '';
    if ~exist('movieFilePath', 'var')
        movieFilePath = pwd;
    end
    if ~exist('displField','var'), displField = []; end
    % no displacement field is given
    % find the displacement process tag or the correction process tag
    if nargin < 2 || isempty(displField)
        try 
            ProcessTag =  MD.findProcessTag('DisplacementFieldCorrectionProcess').tag_;
        catch
            try 
                ProcessTag =  MD.findProcessTag('DisplacementFieldCalculationProcess').tag_;
            catch
                disp('No Completed Displacement Field Calculated!');
                disp('------------------------------------------------------------------------------')
            end
        end
        if exist('ProcessTag', 'var') 
            fprintf('Displacement Process Tag is: %s\n', ProcessTag);
            try
                DisplacementFileFullName = MD.findProcessTag(ProcessTag).outFilePaths_{1};
                if exist(DisplacementFileFullName, 'file')
                    dlgQuestion = sprintf('Do you want to open the displacement field referred to in the movie data file?\n%s\n', ...
                        DisplacementFileFullName);
                    dlgTitle = 'Open displacement field?';
                    OpenDisplacementChoice = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No', 'Yes');
                    switch OpenDisplacementChoice
                        case 'Yes'
                            [displacementFilePath, ~, ~] = fileparts(DisplacementFileFullName);
                            try
                                load(DisplacementFileFullName, 'displField');   
                                fprintf('Displacement Field (displField) File is: \n\t %s\n', DisplacementFileFullName);
                                disp('Original displacement field loaded!!')
                                disp('------------------------------------------------------------------------------')
                            catch
                                errordlg('Could not open the displacement field file.');
                                return
                            end
                        case 'No'
                            DisplacementFileFullName = [];
                        otherwise
                            return
                    end            
                else
                    DisplacementFileFullName = [];
                end
            catch
                DisplacementFileFullName = [];
            end
            if isempty(DisplacementFileFullName)             
                    TFMPackageFiles = fullfile(movieFilePath,'TFMPackage','*.mat');
                    [displacementFileName, displacementFilePath] = uigetfile(TFMPackageFiles, 'Open the displacement field "displField.mat" under displacementField or backups');
                    DisplacementFileFullName = fullfile(displacementFilePath, displacementFileName);
                    try
                        load(DisplacementFileFullName, 'displField')
                        fprintf('Displacement Field (displField) File is: \n\t %s\n', DisplacementFileFullName);
                        disp('Displacement field loaded.');
                        disp('------------------------------------------------------------------------------')
                    catch
                        errordlg('Could not open the displacement field file.');
                        return
                    end
            end                     
        end
    end
    
    %% -----------------------------------------------------------------------------------------------
    if ~exist('FirstFrame','var'), FirstFrame = []; end
    if nargin < 3 || isempty(FirstFrame)
        FirstFrame = 1;
        prompt = {sprintf('Choose the first frame to plotted, [Default, = %d]', FirstFrame)};
        dlgTitle = 'First Frame';
        FirstFrameStr = inputdlg(prompt, dlgTitle, [1 40], {num2str(FirstFrame)});
        FirstFrame = str2double(FirstFrameStr{1});                                  % Convert to a number
    end
    fprintf('First Frame = %d\n', FirstFrame);
    
    %% -----------------------------------------------------------------------------------------------
    if ~exist('LastFrame', 'var'), LastFrame = []; end
    if nargin < 4 || isempty(LastFrame)
        LastFrame = sum(arrayfun(@(x) ~isempty(x.vec), displField));
        prompt = {sprintf('Choose the last frame to plotted, [Default = %d]', LastFrame)};
        dlgTitle = 'Last Frame';
        LastFrameStr = inputdlg(prompt, dlgTitle, [1 40], {num2str(LastFrame)});
        LastFrame = str2double(LastFrameStr{1});                                  % Convert to a number
    end
    fprintf('Last Frame tracked = %d\n', LastFrame);
    disp('------------------------------------------------------------------------------') 
    
    %% -----------------------------------------------------------------------------------------------
    if ~exist('NetDisplacementPath','var'), NetDisplacementPath = []; end
    if nargin < 5 || isempty(NetDisplacementPath)
        if ~exist('displacementFilePath', 'var'), displacementFilePath = []; end
        if isempty(displacementFilePath)
            try
                displacementFilePath = movieFilePath;
            catch
                displacementFilePath = pwd;
            end
        end
        NetDisplacementPath = uigetdir(displacementFilePath,'Choose the directory where you want to store the max net displacement Epi.');
        if NetDisplacementPath == 0  % Cancel was selected
            clear NetDisplacementPath;
        elseif ~exist(NetDisplacementPath,'dir')
            mkdir(NetDisplacementPath);
        end
        
        fprintf('NetDisplacementEPI Path is: \n\t %s\n', NetDisplacementPath);
        disp('------------------------------------------------------------------------------')
    end    
    
    %% -----------------------------------------------------------------------------------------------
    if ~exist('MagnificationTimes', 'var'), MagnificationTimes = []; end
    if nargin < 6 || isempty(MagnificationTimes)
        MagnificationTimes = [];                % Updated on 2019-09-23. 
    end
    [ScaleMicronPerPixel, ~, MagnificationTimes] = MagnificationScalesMicronPerPixel(MagnificationTimes);    
    
    %% -----------------------------------------------------------------------------------------------
    if ~exist('showPlot','var'), showPlot = []; end
    if nargin < 7 || isempty(showPlot)
        dlgQuestion = 'Do you want to show the plot of max net displacement EPI vs. time?';
        dlgTitle = 'Show Net Displacement EPI Max?';
        showPlotChoice = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No', 'Yes');
    elseif showPlot == 0 || strcmpi(showPlot, 'N') || strcmpi(showPlot, 'No') || strcmpi(showPlot, 'Off')
        showPlotChoice = 'No';
    elseif showPlot == 1 || strcmpi(showPlot, 'Y') || strcmpi(showPlot, 'Yes') || strcmpi(showPlot, 'On')
        showPlotChoice = 'Yes';
    end    
    switch showPlotChoice
        case 'Yes'
            showPlot = 'on';
        case 'No'
            showPlot = 'off';
        otherwise
            return
    end
    
    %% -----------------------------------------------------------------------------------------------
    
    dlgQuestion = 'Select image format.';
    listStr = {'PNG', 'FIG', 'EPS'};
    ImageChoice = listdlg('ListString', listStr, 'PromptString',dlgQuestion, 'InitialValue', [1,2], 'SelectionMode' ,'multiple');    
    ImageChoice = listStr(ImageChoice);                 % get the names of the string.   

    NetDisplacementNameMAT = fullfile(NetDisplacementPath, 'Displacement Max Net EPI Bead.mat');
    fprintf('Net Displacement MAT file name is: \n\t %s\n', NetDisplacementNameMAT);
    
    NetVelocityNameMAT = fullfile(NetDisplacementPath, 'Velocity Max Net EPI Bead.mat');
    fprintf('Net Velocity MAT file name is: \n\t %s\n', NetVelocityNameMAT);
    
    disp('------------------------------------------------------------------------------')
    
    %% -----------------------------------------------------------------------------------------------
    if ~exist('AnalysisPath','var'), AnalysisPath = []; end    
    if nargin < 8 || isempty(AnalysisPath)        
        dlgQuestion = ({'Do you want to save in an Analysis output folder?'});
        dlgTitle = 'Analysis folder?';
        AnalysisFolderChoice = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No', 'Yes');
        switch AnalysisFolderChoice
            case 'Yes'
                if ~exist('movieFilePath','var'), movieFilePath = pwd; end
                AnalysisPath = uigetdir(movieFilePath,'Choose the analysis directory where the max net displacement Epi will be saved.');     
                if AnalysisPath == 0  % Cancel was selected
                    clear AnalysisPath;
                    return
                elseif ~exist(AnalysisPath,'dir')   % Check for a directory
                    mkdir(AnalysisPath);
                end
                                    
            case 'No'
                % continue. Do nothing
            otherwise
                return
        end               
    end
    
    %% -----------------------------------------------------------------------------------------------
    if ~exist('maxDisplacement','var'), MaxDisplacement = []; end              % this is necessary if you know what the max is ahread of it
    if nargin < 9 || isempty(MaxDisplacement)
        temp_maxDisplacement = 0;
        temp_minDisplacement = Inf;
        VeryLastFrame = sum(arrayfun(@(x) ~isempty(x.vec), displField));
        for CurrentFrame = 1:VeryLastFrame
            if useGPU
                displFieldVec = gpuArray(displField(CurrentFrame).vec);
            else
                displFieldVec = displField(CurrentFrame).vec;
            end          
            maxMag = (displFieldVec(:,1).^2+displFieldVec(:,2).^2).^0.5;
            temp_minDisplacement = min(temp_minDisplacement,min(maxMag));
            if nargin < 4 || isempty(MaxDisplacement)
                temp_maxDisplacement = max(temp_maxDisplacement, max(maxMag));
            end
        end 
%         minDisplacement = temp_minDisplacement;
        MaxDisplacement = temp_maxDisplacement;        
    else
        msgbox('Make sure the entered Maximum Displacement is in microns.')
    end
    fprintf('Maximum displacement is around %g pixels. \n', MaxDisplacement);
    MaxDisplacementMicron = MaxDisplacement * ScaleMicronPerPixel; 
    fprintf('Maximum displacement is around %g microns, based on tracked points. \n', MaxDisplacementMicron);
    disp('------------------------------------------------------------------------------')

    
    %% -----------------------------------------------------------------------------------------------
    if ~exist('bandSize','var'), bandSize = []; end
    if nargin < 10 || isempty(bandSize)
        bandSize = 0;
    end
    fprintf('Band size is %g pixels, or %g microns. \n', bandSize, bandSize * ScaleMicronPerPixel);
    
    %% -----------------------------------------------------------------------------------------------    
    if ~exist('TimeStampsND2','var'), TimeStampsND2 = []; end
    if nargin < 11 || isempty(TimeStampsND2)        
        dlgQuestion = ({'Do you have a timestamp file compiled already?'});
        dlgTitle = 'Time Stamp file?';
        TimeStampChoice = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No', 'Yes');
        switch TimeStampChoice
            case 'Yes'
                [TimeStampFileName, TimeStampPath] = uigetfile(movieFilePath, 'Load TimeStampsND2 File');
                if TimeStampFileName == 0, return; end
                TimeStampFullFileName = fullfile(TimeStampPath, TimeStampFileName);
                load(TimeStampFullFileName, 'TimeStampsND2');
            case 'No'
                try 
                    [TimeStampsND2, ~] = ND2TimeFrameExtract(ND2fullFileName); 
                catch
                    try 
                        FrameRate = 1/MD.timeInterval_;
                    catch
                        FrameRate = 1/ 0.025;           % (40 frames per seconds)              
                    end
                    prompt = {sprintf('Choose the Frame Rate per second for this movie. [Default, %.4f]', FrameRate)};
                    dlgTitle =  'Frames Per Second';
                    FrameRateStr = inputdlg(prompt, dlgTitle, [1, 90], {num2str(FrameRate)});
                    if isempty(FrameRateStr), return; end
                    FrameRate = str2double(FrameRateStr{1});                                  % Convert to a number                            
                    TimeStampsND2 = (FirstFrame:LastFrame) ./ FrameRate;
                end
            otherwise     
               return
        end
    end
    
    %% ---------------------------------------------------------------------------------------------- 
    if nargin > 12
        errordlg('Too many arguments in this function, or wrong argument structure!')
        return
    end      
    
    %% ==================================================================================  
    % 2. Covnert only displacements (.vec) to microns. Keep Starting positions in pixels. Keep the same structure
    totalPoints = size(displField(FirstFrame).pos, 1);
    displFieldMicron = struct('pos', NaN(totalPoints, 1), 'vec',  NaN(totalPoints, 1));
    for CurrentFrame = 1:VeryLastFrame
        tmpField = displField(CurrentFrame).vec;
        displFieldMicron(CurrentFrame).pos = displField(CurrentFrame).pos;             % pixels
        displFieldMicron(CurrentFrame).vec = tmpField * ScaleMicronPerPixel;
        displFieldMicron(CurrentFrame).posShifted = displFieldMicron(CurrentFrame).pos + displFieldMicron(CurrentFrame).vec;
    end

    %% Calculate the bead instantaneous velocity: Foward derivative for first frame. Backward derivative for last frame. Central for anything in between (best method).
    velocityField = displField;
    velocityFieldMicronPerSec = displFieldMicron;
    %-- foward difference for the first frame
    velocityField(1).vec = [0, 0];                  % No velocity for the first frame
    %-- back difference for the last frame
    for CurrentFrame = 2:VeryLastFrame - 1
        velocityField(CurrentFrame).vec = (displField(CurrentFrame).vec - displField(CurrentFrame - 1).vec) / (TimeStampsND2(CurrentFrame) - TimeStampsND2(CurrentFrame - 1));
        velocityFieldMicronPerSec(CurrentFrame).vec = (displFieldMicron(CurrentFrame).vec - displFieldMicron(CurrentFrame - 1).vec) / (TimeStampsND2(CurrentFrame) - TimeStampsND2(CurrentFrame - 1));    
    end           
    
    %% ----------------------------------------------------------------------------------------------
   disp('------------------------- Starting generating the tracked image sequence. ---------------------------------------------------')   
   
    %% ==================================================================================
    reverseString = '';
    % account for if displFieldMicron contains more than one frame. Make sure you add "createRegGridFromDisplField.m" in the search path.
    [reg_grid,~,~,~] = createRegGridFromDisplField(displField(1), 2); %2=2 times fine interpolation

    % tmpDisplHeatMapMax = [x-coord max, y-coord max, max value] for each frame.
    if useGPU
        tmpDisplHeatMapMax = NaN(VeryLastFrame, 3, 'gpuArray');
%         displFieldMicronNetDispl = NaN(VeryLastFrame, 1, 'gpuArray');
        displHeatMapMaxIndex = NaN(VeryLastFrame, 1, 'gpuArray');
    else
        tmpDisplHeatMapMax = NaN(VeryLastFrame, 3);
%         displFieldMicronNetDispl = NaN(FrameCount, 1);      
        displHeatMapMaxIndex = NaN(VeryLastFrame, 1);        
    end
    
    %% First Finding the coordinates of the maximum points in each frame 
    displHeatMapMicronAll = cell(VeryLastFrame, 1);
    displHeatMapXMicronAll = cell(VeryLastFrame, 1);
    displHeatMapYMicronAll = cell(VeryLastFrame, 1);
    velocityHeatMapMicronPerSecAll = cell(VeryLastFrame, 1);
    
    for CurrentFrame = FirstFrame:StepSize:LastFrame
%         if ~mod(CurrentFrame, 20)  || CurrentFrame == 1       % Output every 20 frames so that it works faster.
        ProgressMsg = sprintf('\nCreating Frame #%d/%d...\n',CurrentFrame, LastFrame);
        fprintf([reverseString, ProgressMsg]);
        reverseString = repmat(sprintf('\b'), 1, length(ProgressMsg));
%         end    
        % -----------------------------------------------------------------------------------------------
        [grid_mat, interpGridVector_Displ,~,~] = interp_vec2grid(displFieldMicron(CurrentFrame).pos(:,1:2), displFieldMicron(CurrentFrame).vec(:,1:2) ,[], reg_grid);
        [~, interpGridVector_Velocity,~,~] = interp_vec2grid(velocityFieldMicronPerSec(CurrentFrame).pos(:,1:2), velocityFieldMicronPerSec(CurrentFrame).vec(:,1:2) ,[], reg_grid);        
        %-----------------------------------------------------------------------------------------------
        grid_spacingX = grid_mat(1,2,1) - grid_mat(1,1,1);
        grid_spacingY = grid_mat(2,1,2) - grid_mat(1,1,2);        
        imSizeX = (grid_mat(end,end,1) - grid_mat(1,1,1)) + grid_spacingX;
        imSizeY = (grid_mat(end,end,2) - grid_mat(1,1,2)) + grid_spacingY; 
        %----------------------------------------------------------------------------------------------
        if ~exist('width', 'var') || ~exist('height', 'var'), width = []; height = []; end
        if nargin < 11 || isempty(width) || isempty(height)
            width = imSizeX;
            height = imSizeY;
        end
        %----------------------------------------------------------------------------------------------
        centerX = ((grid_mat(end,end,1) + grid_mat(1,1,1))/2);
        centerY = ((grid_mat(end,end,2) + grid_mat(1,1,2))/2);
        % [XI,YI] = meshgrid(grid_mat(1,1,1):grid_mat(1,1,1)+imSizeX,grid_mat(1,1,2):grid_mat(1,1,2)+imSizeY);
        Xmin = centerX - width/2 + bandSize;
        Xmax = centerX + width/2 - bandSize;
        Ymin = centerY - height/2 + bandSize;
        Ymax = centerY + height/2 - bandSize;
%         [XI,YI] = meshgrid(Xmin:Xmax,Ymin:Ymax);       
        [XI,YI] = ndgrid(Xmin:Xmax,Ymin:Ymax);                % Addded on 2019-10-10 to go with gridded interpolant, the line above is for griddata
        %-----------------------------------------------------------------------------------------------            
        % Added by WIM on 2019-02-05
        dMapNet = cell(1,numel(displFieldMicron));
        dMapX = cell(1,numel(displFieldMicron));
        dMapY = cell(1,numel(displFieldMicron));
        interpGridVector_Displ_norm = (interpGridVector_Displ(:,:,1).^2 + interpGridVector_Displ(:,:,2).^2).^0.5;
        % Added by WIM on 2019-10-09
        vMapNet = cell(1,numel(velocityFieldMicronPerSec));
        vMapX = cell(1,numel(velocityFieldMicronPerSec));
        vMapY = cell(1,numel(velocityFieldMicronPerSec));
        interpGridVector_Velocity_norm = (interpGridVector_Velocity(:,:,1).^2 + interpGridVector_Velocity(:,:,2).^2).^0.5;                
        %-----------------------------------------------------------------------------------------------             
        dMapNet{CurrentFrame} = interpGridVector_Displ_norm;
        dMapX{CurrentFrame} = interpGridVector_Displ(:,:,1);
        dMapY{CurrentFrame} = interpGridVector_Displ(:,:,2);
         % Added by WIM on 2019-10-09       
        vMapNet{CurrentFrame} = interpGridVector_Velocity_norm;
        vMapX{CurrentFrame} = interpGridVector_Velocity(:,:,1);
        vMapY{CurrentFrame} = interpGridVector_Velocity(:,:,2);        
        % -----------------------------------------------------------------------------------------------            
         %% Replaced to a griddded interpolant by Waddah Moghram on 2019-10-10 to match interp_vec2grid updated version, to avoid NaNs
        ImageSizePixels = MD.imSize_;     
                
%             displHeatMapInterpNDgridCoor = griddata(grid_mat(:,:,1), grid_mat(:,:,2), interpGridVector_Displ_norm ,XI, YI, 'cubic');              % check the possibility of interp2() to use GPU                    
            displHeatMapInterpNDgridCoor = griddedInterpolant(grid_mat(:,:,1), grid_mat(:,:,2), dMapNet{CurrentFrame} , 'cubic');              % No need to Flip back X-grid to go to ndgrid() format. Already in that format
            displHeatMap = displHeatMapInterpNDgridCoor(XI, YI);                               % transpose from NDgrid() coordinates to ImageCoordinates. Equivalent to 90 degree rotation counterclockwise
            displHeatMapPaddedMicron = zeros(ImageSizePixels);                    % Added on 2019-10-13
            displHeatMapPaddedMicron(Xmin:Xmax,Ymin:Ymax) = displHeatMap;

            %
            displHeatMapXGridded = griddedInterpolant(grid_mat(:,:,1), grid_mat(:,:,2), dMapX{CurrentFrame}  , 'cubic');              % No need to Flip back X-grid to go to ndgrid() format. Already in that format
            displHeatMapXMicronUnpadded = displHeatMapXGridded(XI, YI);                               % transpose from NDgrid() coordinates to ImageCoordinates. Equivalent to 90 degree rotation counterclockwise
            displHeatMapXPaddedMicron = zeros(ImageSizePixels);                    % Added on 2019-10-13
            displHeatMapXPaddedMicron(Xmin:Xmax,Ymin:Ymax) = displHeatMapXMicronUnpadded;
            
            %
            displHeatMapYGridded = griddedInterpolant(grid_mat(:,:,1), grid_mat(:,:,2), dMapY{CurrentFrame} , 'cubic');              % No need to Flip back X-grid to go to ndgrid() format. Already in that format
            displHeatMapYMicronUnpadded = displHeatMapYGridded(XI, YI);                               % transpose from NDgrid() coordinates to ImageCoordinates. Equivalent to 90 degree rotation counterclockwise
            displHeatMapYPaddedMicron = zeros(ImageSizePixels);                    % Added on 2019-10-13
            displHeatMapYPaddedMicron(Xmin:Xmax,Ymin:Ymax) = displHeatMapYMicronUnpadded;
            
            
%             velocityHeatMapMicronPerSecond = griddata(grid_mat(:,:,1), grid_mat(:,:,2), interpGridVector_Velocity_norm ,XI, YI, 'cubic');              % check the possibility of interp2() to use GPU
            velocityHeatMapGridded = griddedInterpolant(grid_mat(:,:,1), grid_mat(:,:,2), vMapNet{CurrentFrame} , 'cubic');              % No need to Flip back X-grid to go to ndgrid() format. Already in that format
            velocityHeatMapMicronPerSecondUnpadded = velocityHeatMapGridded(XI, YI);                               % transpose from NDgrid() coordinates to ImageCoordinates. Equivalent to 90 degree rotation counterclockwise
            velocityHeatMapMicronPerSecond = zeros(ImageSizePixels);                    % Added on 2019-10-13
            velocityHeatMapMicronPerSecond(Xmin:Xmax,Ymin:Ymax) = velocityHeatMapMicronPerSecondUnpadded;
        

       % -----------------------------------------------------------------------------------------------        
        if useGPU
            displHeatMapPaddedMicron = gpuArray(displHeatMapPaddedMicron); 
            displHeatMapXPaddedMicron = gpuArray(displHeatMapXPaddedMicron); 
            displHeatMapYPaddedMicron = gpuArray(displHeatMapYPaddedMicron);             
            
            velocityHeatMapMicronPerSecond = gpuArray(velocityHeatMapMicronPerSecond);
        end
        % -----------------------------------------------------------------------------------------------                
        % use displacement to the find the maximum interpolated particle, and save the velocity of that particular interpolated node
        % tmpDisplHeatMapMax = [X (pixel), Y (pixel), Max Value]
        [tmpDisplHeatMapMax(CurrentFrame, 3), displHeatMapMaxIndex(CurrentFrame)] = max(displHeatMapPaddedMicron(:));
        displHeatMapSize = size(displHeatMapPaddedMicron);
        [tmpDisplHeatMapMax(CurrentFrame, 1), tmpDisplHeatMapMax(CurrentFrame, 2)] = ind2sub(displHeatMapSize, displHeatMapMaxIndex(CurrentFrame));
        
        if useGPU
            displHeatMapPaddedMicron = gather(displHeatMapPaddedMicron);
            displHeatMapXPaddedMicron = gather(displHeatMapXPaddedMicron);
            displHeatMapYPaddedMicron = gather(displHeatMapYPaddedMicron);
            
            
            velocityHeatMapMicronPerSecond = gather(velocityHeatMapMicronPerSecond);
        end
        displHeatMapMicronAll{CurrentFrame} = displHeatMapPaddedMicron;
        displHeatMapXMicronAll{CurrentFrame} = displHeatMapXPaddedMicron;        
        displHeatMapYMicronAll{CurrentFrame} = displHeatMapYPaddedMicron;        
        
        velocityHeatMapMicronPerSecAll{CurrentFrame}  = velocityHeatMapMicronPerSecond;
    end
    
    %% Finding the maximum displacement absolutely and for each frame.
    [~, MaxDisplacementFrameNum] = max(tmpDisplHeatMapMax(:,3));

    MaxDisplacementPosMicronXY  = tmpDisplHeatMapMax(MaxDisplacementFrameNum, 1:2);
    MaxDisplacementIndex =  displHeatMapMaxIndex(MaxDisplacementFrameNum);
    fprintf('The displacement of the absolute maximum displacement is at (x,y) = (%g, %g) pixels at Frame #%d. \n\tNode ID# %d. Absolute maximum Displacement is %g microns.\n', ...
        MaxDisplacementPosMicronXY, MaxDisplacementFrameNum, MaxDisplacementIndex , MaxDisplacementMicron )
       
    BeadNetDisplacementMicronEPImax_Absolute = NaN(VeryLastFrame, 1);    
    BeadNetDisplacementXMicronEPImax_Absolute = NaN(VeryLastFrame, 1);        
    BeadNetDisplacementYMicronEPImax_Absolute = NaN(VeryLastFrame, 1);    
    
    BeadNetDisplacementMicronEPImax_EachFrame = NaN(VeryLastFrame, 1);
    BeadNetDisplacementXMicronEPImax_EachFrame = NaN(VeryLastFrame, 1);    
    BeadNetDisplacementYMicronEPImax_EachFrame = NaN(VeryLastFrame, 1);  
    
    BeadNetVelocityMicronPerSecEPImax_EachFrame = NaN(VeryLastFrame, 1);
    BeadNetVelocityMicronPerSecEPImax_Absolute = NaN(VeryLastFrame, 1);    
    
     
    for CurrentFrame = FirstFrame:StepSize:LastFrame
        CurrentDisplHeatMapMicron = displHeatMapMicronAll{CurrentFrame}; 
        CurrentDisplHeatMapXMicron = displHeatMapXMicronAll{CurrentFrame}; 
        CurrentDisplHeatMapYMicron = displHeatMapYMicronAll{CurrentFrame}; 
                
        
        CurrentVelocityHeatMap = velocityHeatMapMicronPerSecAll{CurrentFrame};         
        
        if ~isempty(CurrentDisplHeatMapMicron)
            BeadNetDisplacementMicronEPImax_Absolute(CurrentFrame) =  CurrentDisplHeatMapMicron(MaxDisplacementIndex);
            BeadNetDisplacementXMicronEPImax_Absolute(CurrentFrame) =  CurrentDisplHeatMapXMicron(MaxDisplacementIndex);            
            BeadNetDisplacementYMicronEPImax_Absolute(CurrentFrame) =  CurrentDisplHeatMapYMicron(MaxDisplacementIndex);            
            BeadNetVelocityMicronPerSecEPImax_Absolute(CurrentFrame) = CurrentVelocityHeatMap(MaxDisplacementIndex);   
            
            BeadNetDisplacementMicronEPImax_EachFrame(CurrentFrame) =  CurrentDisplHeatMapMicron(displHeatMapMaxIndex(CurrentFrame));
            BeadNetDisplacementXMicronEPImax_EachFrame(CurrentFrame) =  CurrentDisplHeatMapXMicron(displHeatMapMaxIndex(CurrentFrame));
            BeadNetDisplacementYMicronEPImax_EachFrame(CurrentFrame) =  CurrentDisplHeatMapYMicron(displHeatMapMaxIndex(CurrentFrame));
            BeadNetVelocityMicronPerSecEPImax_EachFrame(CurrentFrame) = CurrentVelocityHeatMap(displHeatMapMaxIndex(CurrentFrame));
        end
    end

    BeadNetDisplacementMicronEPImax_Absolute = BeadNetDisplacementMicronEPImax_Absolute';
    BeadNetDisplacementXMicronEPImax_Absolute = BeadNetDisplacementXMicronEPImax_Absolute';    
    BeadNetDisplacementYMicronEPImax_Absolute = BeadNetDisplacementYMicronEPImax_Absolute';
    BeadNetVelocityMicronPerSecEPImax_Absolute = BeadNetVelocityMicronPerSecEPImax_Absolute';
        
    BeadNetDisplacementMicronEPImax_EachFrame =  BeadNetDisplacementMicronEPImax_EachFrame';
    BeadNetDisplacementXMicronEPImax_EachFrame =  BeadNetDisplacementXMicronEPImax_EachFrame';    
    BeadNetDisplacementYMicronEPImax_EachFrame =  BeadNetDisplacementYMicronEPImax_EachFrame';    
    BeadNetVelocityMicronPerSecEPImax_EachFrame =  BeadNetVelocityMicronPerSecEPImax_EachFrame';

    %% -----------------------------------------------------------------------------------------------           .
    % Finding out what the last frame count is 
    LastPlotFrame = min(numel(TimeStampsND2), numel(BeadNetDisplacementMicronEPImax_EachFrame));
    
    if ~exist('TimeStampsND2', 'var') 
        if ~exist('LastFrame','var')
            % Generate time stamp?
            LastPlotFrame = input('What is the Last Frame tracked under DIC?');
            FrameSeq = linspace(1,LastPlotFrame,LastPlotFrame);
            FrameRate = input('What is the frame rate per second');
            TimeStampsND2 = FrameSeq ./ FrameRate;   
        end
    end
    
    if useGPU
        MaxDisplacement = gather(MaxDisplacement);
        MaxDisplacementMicron = gather(MaxDisplacementMicron);               
        MaxDisplacementFrameNum = gather(MaxDisplacementFrameNum);
        MaxDisplacementIndex = gather(MaxDisplacementIndex);
        MaxDisplacementPosMicronXY = gather(MaxDisplacementPosMicronXY);
    end
    
    %% save parameters so far.    
    save(NetDisplacementNameMAT, 'MD', 'displField', 'displFieldMicron', 'velocityField', 'velocityFieldMicronPerSec','FirstFrame', 'LastFrame', 'LastPlotFrame', 'MaxDisplacementFrameNum', ...
        'MaxDisplacementPosMicronXY', 'MaxDisplacementIndex', 'MagnificationTimes', 'MaxDisplacement', 'MaxDisplacementMicron', ...
        'bandSize', 'width', 'height', 'BeadNetDisplacementMicronEPImax_EachFrame', 'BeadNetDisplacementXMicronEPImax_EachFrame', 'BeadNetDisplacementYMicronEPImax_EachFrame' , ...
          'BeadNetDisplacementMicronEPImax_Absolute', 'BeadNetDisplacementXMicronEPImax_Absolute', 'BeadNetDisplacementYMicronEPImax_Absolute', ...
          'BeadNetVelocityMicronPerSecEPImax_EachFrame', 'BeadNetVelocityMicronPerSecEPImax_Absolute', '-v7.3');          % Modified by WIM on 2/5/2019
%     if  strcmpi(AnalysisFolderChoice , 'Yes')
%         save(AnalysisNetDisplacementNameMAT,'MD', 'displField', 'displFieldMicron', 'velocityField', 'velocityFieldMicronPerSec','FirstFrame', 'LastFrame', 'LastPlotFrame', 'MaxDisplacementFrameNum', ...
%         'MaxDisplacementPosMicronXY', 'MaxDisplacementIndex', 'MagnificationTimes', 'MaxDisplacement', 'MaxDisplacementMicron', ...
%         'bandSize', 'width', 'height', 'BeadNetDisplacementMicronEPImax_EachFrame', 'BeadNetDisplacementXMicronEPImax_EachFrame', 'BeadNetDisplacementYMicronEPImax_EachFrame' , ...
%           'BeadNetDisplacementMicronEPImax_Absolute', 'BeadNetDisplacementXMicronEPImax_Absolute', 'BeadNetDisplacementYMicronEPImax_Absolute', ...
%           'BeadNetVelocityMicronPerSecEPImax_EachFrame', 'BeadNetVelocityMicronPerSecEPImax_Absolute', '-v7.3');          % Modified by WIM on 2/5/2019
%     end
%    

%%

    try 
        ProcessTag =  MD.findProcessTag('ForceFieldCalculationProcess').tag_;
    catch
        ProcessTag = '';
        disp('No Completed "Force" Field Calculated!');
        disp('------------------------------------------------------------------------------')
    end
    %------------------
    if exist('ProcessTag', 'var') 
        fprintf('"Force" Process Tag is: %s\n', ProcessTag);
        try
            ForceFileFullName = MD.findProcessTag(ProcessTag).outFilePaths_{1};
            if exist(ForceFileFullName, 'file')
                dlgQuestion = sprintf('Do you want to open the "force" field referred to in the movie data file?\n\n%s\n', ...
                    ForceFileFullName);
                dlgTitle = 'Open "force" field (forceField.mat) file?';
                OpenForceChoice = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No', 'Yes');
                switch OpenForceChoice
                    case 'Yes'
                        [forceFilePath, ~, ~] = fileparts(ForceFileFullName);
                    case 'No'
                        ForceFileFullName = [];
                    otherwise
                        return
                end            
            else
                ForceFileFullName = [];
            end
        catch
            ForceFileFullName = [];
        end
    end
    %------------------
    if isempty(ForceFileFullName) || ~exist('ProcessTag', 'var')
            TFMPackageFiles = fullfile(movieFilePath,'TFMPackage','*.mat');
            [forceFileName, forceFilePath] = uigetfile(TFMPackageFiles, 'Open the "force" field (forceField.mat) under forceField or backups');
            ForceFileFullName = fullfile(forceFilePath, forceFileName);
    end    
    %------------------       
    try
        load(ForceFileFullName, 'forceField');   
        fprintf('"Force" Field (forceField.mat) File is successfully loaded! \n\t %s\n', ForceFileFullName);
        disp('------------------------------------------------------------------------------')
    catch
        disp('Could not open the "force" field file.');
        return
    end
    
    forceFieldCalculationInfo =  MD.findProcessTag('ForceFieldCalculationProcess');

    %% Plotting the overall maximum overtime
         % -----------------------------------------------------------------------------------------------           .
    commandwindow;
    showPlot = 'on';
    GelConcentrationMgMl = input('What was the gel concentration in mg/mL? ');          
    
       %----------------------------------------------
    try
        try
            thickness_um = forceFieldCalculationInfo.funParams_.thickness_nm/1000;
        catch
            thickness_um = forceFieldCalculationInfo.funParams_.thickness/1000;
        end
    catch
        thickness_um = [];
    end
    if isempty(thickness_um)
        thickness_um = input('What was the gel thickness in microns? ');  
        fprintf('Gel thickness is %d  microns. \n', thickness_um);
    else
        fprintf('Gel thickness found is %d  microns. \n', thickness_um);
    end
    
    %----------------------------------------------
    try
        YoungModulusPa = forceFieldCalculationInfo.funParams_.YoungModulus;
    catch
        YoungModulusPa = [];
    end
    if isempty(YoungModulusPa)
        YoungModulusPa = input('What was the gel''s Young Elastic modulus (in Pa)? ');  
        fprintf('Gel''s elastic modulus (E) is %g  Pa. \n', YoungModulusPa);
    else
        fprintf('Gel''s elastic modulus (E) found is %g  Pa. \n', YoungModulusPa);        
    end

    %----------------------------------------------
    try
        PoissonRatio = forceFieldCalculationInfo.funParams_.PoissonRatio;
    catch
        PoissonRatio = [];
    end
    if isempty(PoissonRatio)
        PoissonRatio = input('What was the gel''s Young Elastic modulus (in Pa)? ');  
        fprintf('Gel''s Poisson Ratio (nu) is %g  Pa. \n', PoissonRatio);
    else
        fprintf('Gel''s Poisson Ratio (nu) found is %g  Pa. \n', PoissonRatio);        
    end    
   
    
    %%
       
    try 
        save(NetDisplacementNameMAT, 'GelConcentrationMgMl', 'thickness_um', '-append');          % Modified by WIM on 2/5/2019
    %     if  strcmpi(AnalysisFolderChoice , 'Yes')
    %         save(AnalysisNetDisplacementNameMAT, 'GelConcentrationMgMl', 'thickness_um', '-append');                   % Modified by WIM on 2/5/2019
    %     end
    catch
        % Do nothing
    end    
    
    %%
    FramePlotted(1:LastPlotFrame) = ~isnan(BeadNetDisplacementMicronEPImax_EachFrame(1:LastPlotFrame));
    TimeStampsPlotted = TimeStampsND2(FramePlotted);
    
    titleStr2 = sprintf('%.0f', thickness_um);
    titleStr2 = strcat(titleStr2, '-\mum,');
    titleStr2 = strcat(titleStr2, sprintf('%.1f mg/mL collagen type-I gel', GelConcentrationMgMl));
    titleStr3 = sprintf('Young Moudulus = %.1f Pa. Poisson Ratio = %.2f', YoungModulusPa, PoissonRatio);        
    
    
    %% Plotting the frames
   showPlot = 'on';
    
    titleStr1displAbsolute = 'Maximum Epi beads net displacement (of All Frames) for';
    titleStr1velocityAbsolute = 'Rate of Maximum Epi beads net displacement (of All Frames) for';   
    
    figHandleDisplacement_Absolute = figure('visible',showPlot, 'color', 'w');     % added by WIM on 2019-02-07. To show, remove 'visible
    plot(TimeStampsND2(FramePlotted), BeadNetDisplacementMicronEPImax_Absolute(FramePlotted), 'r.', 'MarkerSize', 5); 
    title({titleStr1displAbsolute, titleStr2, titleStr3}, 'FontWeight', 'bold')
    xlabel('Time (s)', 'FontWeight', 'bold')
    ylabel('Displacement,\Delta_{TFM}(t) (\mum)', 'FontWeight', 'bold')
    xlim([TimeStampsND2(FirstFrame),TimeStampsND2(LastFrame)]);               % Adjust the end limit.
    set(findobj(gcf,'type', 'axes'), 'FontSize',10, 'FontWeight','Bold', 'LineWidth',1,'XMinorTick', 'on', 'YMinorTick', 'on', 'TickDir', 'out');     % Make axes bold    
     
    %--------------
    titleStr1 = 'Maximum Epi beads net displacement (of All Frames) for';
    figHandleDisplacementAll_Absolute = figure('visible',showPlot, 'color', 'w');     % added by WIM on 2019-02-07. To show, remove 'visible    
    subplot(3,1,1)
    plot(TimeStampsND2(FramePlotted), BeadNetDisplacementMicronEPImax_Absolute(FramePlotted), 'r.', 'MarkerSize', 5); 
    title({titleStr1, titleStr2, titleStr3}, 'FontWeight', 'bold')
    ylabel('\Delta_{TFM}(t) (\mum)');
    set(gca, 'FontSize',9, 'FontWeight','Bold', 'LineWidth',1, 'XMinorTick', 'on', 'YMinorTick', 'on', 'TickDir', 'out')
    xlim([ TimeStampsPlotted(1),  TimeStampsPlotted(end)]);    
    hold on
    subplot(3,1,2)
    plot(TimeStampsND2(FramePlotted), BeadNetDisplacementXMicronEPImax_Absolute(FramePlotted), 'r.', 'MarkerSize', 5); 
    ylabel('\Delta_{TFM, x}(t) (\mum)');
    set(gca, 'FontSize',9, 'FontWeight','Bold', 'LineWidth',1, 'XMinorTick', 'on', 'YMinorTick', 'on', 'TickDir', 'out')
    xlim([ TimeStampsPlotted(1),  TimeStampsPlotted(end)]);    
    hold on
    subplot(3,1,3)
    plot(TimeStampsND2(FramePlotted), BeadNetDisplacementYMicronEPImax_Absolute(FramePlotted), 'r.', 'MarkerSize', 5); 
    ylabel('\Delta_{TFM, y}(t) (\mum)');
    set(gca, 'FontSize',9, 'FontWeight','Bold', 'LineWidth',1, 'XMinorTick', 'on', 'YMinorTick', 'on', 'TickDir', 'out')
    xlim([ TimeStampsPlotted(1),  TimeStampsPlotted(end)]);    
    xlabel('Time (s)', 'FontWeight', 'bold');
    hold off    
    %--------------
    figHandleVelocity_Absolute = figure('visible',showPlot, 'color', 'w');     % added by WIM on 2019-02-07. To show, remove 'visible
    plot(TimeStampsND2(FramePlotted), BeadNetVelocityMicronPerSecEPImax_Absolute(FramePlotted), 'r.', 'MarkerSize', 5); 
    title({titleStr1velocityAbsolute, titleStr2, titleStr3}, 'FontWeight', 'bold')
    xlabel('Time (s)', 'FontWeight', 'bold')
    ylabel('Velocity,\delta(\Delta)/\delta(t)_{TFM} (\mum/s)', 'FontWeight', 'bold')
    xlim([TimeStampsND2(FirstFrame),TimeStampsND2(LastFrame)]);               % Adjust the end limit.
    set(findobj(gcf,'type', 'axes'), 'FontSize',10, 'FontWeight','Bold', 'LineWidth',1,'XMinorTick', 'on', 'YMinorTick', 'on', 'TickDir', 'out');     % Make axes bold    
    
    %% --------------
    for ii = 1:numel(ImageChoice)
        tmpImageChoice =  ImageChoice{ii};
        switch tmpImageChoice
            case 'PNG'
                NetDisplacementNamePNG_Absolute = fullfile(NetDisplacementPath, 'Displacement Max Net EPI Bead_Absolute.png');
                fprintf('Net Displacement PNG file name_Absolute is: \n\t %s\n', NetDisplacementNamePNG_Absolute);
                NetDisplacementAllNamePNG_Absolute = fullfile(NetDisplacementPath, 'Displacement Max All EPI Bead_Absolute.png');
                fprintf('All Displacements PNG file name_Absolute is: \n\t %s\n', NetDisplacementAllNamePNG_Absolute);              
                NetVelocityNamePNG_Absolute = fullfile(NetDisplacementPath, 'Velocity Max Net EPI Bead_Absolute.png');
                fprintf('Net Velocity PNG file name_Absolute is: \n\t %s\n', NetVelocityNamePNG_Absolute);
                
                
                NetDisplacementNamePNG_EachFrame = fullfile(NetDisplacementPath, 'Displacement Max Net EPI Bead_EachFrame.png');
                fprintf('Net Displacement PNG file name_EachFrame is: \n\t %s\n', NetDisplacementNamePNG_EachFrame);         
                NetDisplacementAllNamePNG_EachFrame = fullfile(NetDisplacementPath, 'Displacement Max All EPI Bead_EachFrame.png');
                fprintf('All Displacements PNG file name_EachFrame is: \n\t %s\n', NetDisplacementAllNamePNG_EachFrame);                         
                NetVelocityNamePNG_EachFrame = fullfile(NetDisplacementPath, 'Velocity Max Net EPI Bead_EachFrame.png');
                fprintf('Net Velocity PNG file name_EachFrame is: \n\t %s\n', NetVelocityNamePNG_EachFrame);
            case 'FIG' 
                
                NetDisplacementNameFIG_Absolute = fullfile(NetDisplacementPath, 'Displacement Max Net EPI Bead_Absolute.fig');
                fprintf('Net Displacement FIG file name _Absolute is: \n\t %s\n', NetDisplacementNameFIG_Absolute);
                NetDisplacementAllNameFIG_Absolute = fullfile(NetDisplacementPath, 'Displacement Max All EPI Bead_Absolute.fig');
                fprintf('All Displacements FIG file name _Absolute is: \n\t %s\n', NetDisplacementAllNameFIG_Absolute);                                
                 NetVelocityNameFIG_Absolute = fullfile(NetDisplacementPath, 'Velocity Max Net EPI Bead_Absolute.fig');
                fprintf('Net Velocity FIG file name _Absolute is: \n\t %s\n', NetVelocityNameFIG_Absolute);                
 

                NetDisplacementNameFIG_EachFrame = fullfile(NetDisplacementPath, 'Displacement Max Net EPI Bead_EachFrame.fig');
                fprintf('Net Displacement FIG file name _EachFrame is: \n\t %s\n', NetDisplacementNameFIG_EachFrame);
                NetDisplacementAllNameFIG_EachFrame = fullfile(NetDisplacementPath, 'Displacement Max All EPI Bead_EachFrame.fig');
                fprintf('All Displacements FIG file name _EachFrame is: \n\t %s\n', NetDisplacementAllNameFIG_EachFrame);  
                NetVelocityNameFIG_EachFrame = fullfile(NetDisplacementPath, 'Velocity Max Net EPI Bead_EachFrame.fig');
                fprintf('Net Velocity FIG file name _EachFrame is: \n\t %s\n', NetVelocityNameFIG_EachFrame);                
            case 'EPS'
                NetDisplacementNameEPS_Absolute = fullfile(NetDisplacementPath, 'Displacement Max Net EPI Bead_Absolute.eps');
                fprintf('Net Displacement EPS file name_Absolute is: \n\t %s\n', NetDisplacementNameEPS_Absolute);
                NetDisplacementAllNameEPS_Absolute = fullfile(NetDisplacementPath, 'Displacement Max All EPI Bead_Absolute.eps');
                fprintf('All Displacements EPS file name_Absolute is: \n\t %s\n', NetDisplacementAllNameEPS_Absolute);
                NetVelocityNameEPS_Absolute = fullfile(NetVelocityPath, 'Velocity Max Net EPI Bead_Absolute.eps');
                fprintf('Net Velocity EPS file name_Absolute is: \n\t %s\n', NetVelocityNameEPS_Absolute);                                
                
                NetDisplacementNameEPS_EachFrame = fullfile(NetDisplacementPath, 'Displacement Max Net EPI Bead_EachFrame.eps');
                fprintf('Net Displacement EPS file name_EachFrame is: \n\t %s\n', NetDisplacementNameEPS_EachFrame);
                AllDisplacementNameEPS_EachFrame = fullfile(NetDisplacementPath, 'Displacement Max All EPI Bead_EachFrame.eps');
                fprintf('All Displacements EPS file name_EachFrame is: \n\t %s\n', AllDisplacementNameEPS_EachFrame);                
                NetVelocityNameEPS_EachFrame = fullfile(NetDisplacementPath, 'Velocity Max Net EPI Bead_EachFrame.eps');
                fprintf('Net Velocity EPS file name_EachFrame is: \n\t %s\n', NetVelocityNameEPS_EachFrame);

        otherwise
            return
        end
    end
    

    for ii = 1:numel(ImageChoice)
        tmpImageChoice =  ImageChoice{ii};
        switch tmpImageChoice
            case 'PNG'
                AnalysisNetDisplacementNamePNG_Absolute = fullfile(AnalysisPath, '08 Displacement Max Net EPI Bead_Absolute.png');
                fprintf('Net Displacement PNG file name_Absolute is: \n\t %s\n', AnalysisNetDisplacementNamePNG_Absolute);
                AnalysisNetDisplacementAllNamePNG_Absolute = fullfile(AnalysisPath, '08 Displacement Max All EPI Bead_Absolute.png');
                fprintf('All Displacements PNG file name_Absolute is: \n\t %s\n', AnalysisNetDisplacementAllNamePNG_Absolute);                
                AnalysisNetVelocityNamePNG_Absolute = fullfile(AnalysisPath, '08 Velocity Max Net EPI Bead_Absolute.png');
                fprintf('Net Velocity PNG file name_Absolute is: \n\t %s\n', AnalysisNetVelocityNamePNG_Absolute);

                
                AnalysisNetDisplacementNamePNG_EachFrame = fullfile(AnalysisPath, '08 Displacement Max Net EPI Bead_EachFrame.png');
                fprintf('Net Displacement PNG file name_EachFrame is: \n\t %s\n', AnalysisNetDisplacementNamePNG_EachFrame);
                AnalysisNetDisplacementAllNamePNG_EachFrame = fullfile(AnalysisPath, '08 Displacement Max All EPI Bead_EachFrame.png');
                fprintf('All Displacements PNG file name_EachFrame is: \n\t %s\n', AnalysisNetDisplacementAllNamePNG_EachFrame);                
                AnalysisNetVelocityNamePNG_EachFrame = fullfile(AnalysisPath, '08 Velocity Max Net EPI Bead_EachFrame.png');
                fprintf('Net Velocity PNG file name_EachFrame is: \n\t %s\n', AnalysisNetVelocityNamePNG_EachFrame);
            case 'FIG'
                AnalysisNetDisplacementNameFIG_Absolute = fullfile(AnalysisPath, '08 Displacement Max Net EPI Bead_Absolute.fig');
                fprintf('Net Displacement FIG file name_Absolute is: \n\t %s\n', AnalysisNetDisplacementNameFIG_Absolute);
                AnalysisNetDisplacementAllNameFIG_Absolute = fullfile(AnalysisPath, '08 Displacement Max All EPI Bead_Absolute.fig');
                fprintf('All Displacements FIG file name_Absolute is: \n\t %s\n', AnalysisNetDisplacementAllNameFIG_Absolute);                
                AnalysisNetVelocityNameFIG_Absolute = fullfile(AnalysisPath, '08 Velocity Max Net EPI Bead_Absolute.fig');
                fprintf('Net Velocity FIG file name_Absolute is: \n\t %s\n', AnalysisNetVelocityNameFIG_Absolute);

                
                AnalysisNetDisplacementNameFIG_EachFrame = fullfile(AnalysisPath, '08 Displacement Max Net EPI Bead_EachFrame.fig');
                fprintf('Net Displacement FIG file name_EachFrame is: \n\t %s\n', AnalysisNetDisplacementNameFIG_EachFrame);
                AnalysisNetDisplacementAllNameFIG_EachFrame = fullfile(AnalysisPath, '08 Displacement Max All EPI Bead_EachFrame.fig');
                fprintf('All Displacements FIG file name_EachFrame is: \n\t %s\n', AnalysisNetDisplacementAllNameFIG_EachFrame);       
                AnalysisNetVelocityNameFIG_EachFrame = fullfile(AnalysisPath, '08 Velocity Max Net EPI Bead_EachFrame.fig');
                fprintf('Net Velocity FIG file name_EachFrame is: \n\t %s\n', AnalysisNetVelocityNameFIG_EachFrame);
                
            case 'EPS'
                AnalysisNetDisplacementEPS_EachFrame = fullfile(AnalysisPath, '08 Displacement Max Net EPI Bead_EachFrame.eps');
                fprintf('Net Displacement EPS file name_EachFrame is: \n\t %s\n', AnalysisNetDisplacementEPS_EachFrame);
                AnalysisNetDisplacementAllEPS_EachFrame = fullfile(AnalysisPath, '08 Displacement Max All EPI Bead_EachFrame.eps');
                fprintf('All Displacements EPS file name_EachFrame is: \n\t %s\n', AnalysisNetDisplacementAllEPS_EachFrame);                
                AnalysisNetDisplacementEPS_Absolute = fullfile(AnalysisPath, '08 Displacement Max Net EPI Bead_Absolute.eps');
                fprintf('Net Displacement EPS file name_Absolute is: \n\t %s\n', AnalysisNetDisplacementEPS_Absolute);

                AnalysisNetVelocityEPS_EachFrame = fullfile(AnalysisPath, '08 Velocity Max Net EPI Bead_EachFrame.eps');
                fprintf('Net Velocity EPS file name_EachFrame is: \n\t %s\n', AnalysisNetVelocityEPS_EachFrame);
                AnalysisNetVelocityEPS_Absolute = fullfile(AnalysisPath, '08 Velocity Max Net EPI Bead_Absolute.eps');
                fprintf('Net Velocity EPS file name_Absolute is: \n\t %s\n', AnalysisNetVelocityEPS_Absolute);                            
            otherwise
                return
        end
    end
%                 
%                 AnalysisNetDisplacementNameMAT = fullfile(AnalysisPath, '08 Displacement Max Net EPI Bead.mat');
%                 fprintf('Net Displacement MAT file name is: \n\t %s\n', AnalysisNetDisplacementNameMAT);

%                 
%                 AnalysisNetVelocityNameMAT = fullfile(AnalysisPath, '08 Velocity Max Net EPI Bead.mat');
%                 fprintf('Net Velocity MAT file name is: \n\t %s\n', AnalysisNetVelocityNameMAT);

    
    %% Saving the output files to the desired file format.       
    for ii = 1:numel(ImageChoice)
        tmpImageChoice =  ImageChoice{ii};
        switch tmpImageChoice                
            case 'PNG'
                saveas(figHandleDisplacement_Absolute, NetDisplacementNamePNG_Absolute, 'png')
                saveas(figHandleDisplacementAll_Absolute, NetDisplacementAllNamePNG_Absolute, 'png')                
                saveas(figHandleVelocity_Absolute, NetVelocityNamePNG_Absolute, 'png')
                if  strcmpi(AnalysisFolderChoice , 'Yes')
                    saveas(figHandleDisplacement_Absolute, AnalysisNetDisplacementNamePNG_Absolute, 'png')
                    saveas(figHandleDisplacementAll_Absolute, AnalysisNetDisplacementAllNamePNG_Absolute, 'png')                    
                    saveas(figHandleVelocity_Absolute, AnalysisNetVelocityNamePNG_Absolute, 'png')
                end                

            case 'FIG'
                hgsave(figHandleDisplacement_Absolute, AnalysisNetDisplacementNameFIG_Absolute,'-v7.3')
                hgsave(figHandleDisplacementAll_Absolute,  AnalysisNetDisplacementAllNameFIG_Absolute,'-v7.3')                
                hgsave(figHandleVelocity_Absolute, NetVelocityNameFIG_Absolute,'-v7.3')              
                
                if  strcmpi(AnalysisFolderChoice , 'Yes')
                    hgsave(figHandleDisplacement_Absolute, AnalysisNetDisplacementNameFIG_Absolute,'-v7.3')         
                    hgsave(figHandleDisplacementAll_Absolute, AnalysisNetDisplacementAllNameFIG_Absolute,'-v7.3')                             
                    hgsave(figHandleVelocity_Absolute, AnalysisNetVelocityNameFIG_Absolute,'-v7.3')         
                end                
                
            case 'EPS'
                print(figHandleDisplacement_Absolute, NetDisplacementNameEPS_Absolute,'-depsc')  
                print(figHandleDisplacementAll_Absolute, NetDisplacementAllNameEPS_Absolute,'-depsc')                  
                print(figHandleVelocity_Absolute, NetVelocityNameEPS_Absolute,'-depsc')                   
                if  strcmpi(AnalysisFolderChoice , 'Yes')
                    print(figHandleDisplacement_Absolute, AnalysisNetDisplacementNameEPS_Absolute,'-depsc') 
                    print(figHandleDisplacementAll_Absolute, AnalysisNetDisplacementAllNameEPS_Absolute,'-depsc')                     
                    print(figHandleVelocity_Absolute, AnalysisNetVelocityNameEPS_Absolute,'-depsc')                     
                end
            otherwise
                 return
        end       
    end
   
    %
    
    
    titleStr1displEach = 'Maximum Epi beads net displacement (of Each Frame) for';
    titleStr1velocityEach = 'Rate of Maximum Epi beads net displacement (of Each Frame) for';
    
    
    figHandleDisplacement_EachFrame = figure('visible',showPlot, 'color', 'w');     % added by WIM on 2019-02-07. To show, remove 'visible
    plot(TimeStampsND2(FramePlotted), BeadNetDisplacementMicronEPImax_EachFrame(FramePlotted), 'r.', 'MarkerSize', 5); 
    title({titleStr1displEach, titleStr2, titleStr3}, 'FontWeight', 'bold')
    xlabel('Time (s)', 'FontWeight', 'bold')
    ylabel('Displacement,\Delta_{TFM}(t) (\mum)', 'FontWeight', 'bold')
    xlim([TimeStampsND2(FirstFrame),TimeStampsND2(LastFrame)]);               % Adjust the end limit.
    set(findobj(gcf,'type', 'axes'), 'FontSize',10, 'FontWeight','Bold', 'LineWidth',1,'XMinorTick', 'on', 'YMinorTick', 'on', 'TickDir', 'out');     % Make axes bold    
 
   
    figHandleVelocity_EachFrame = figure('visible',showPlot, 'color', 'w');     % added by WIM on 2019-02-07. To show, remove 'visible
    plot(TimeStampsND2(FramePlotted), BeadNetVelocityMicronPerSecEPImax_EachFrame(FramePlotted), 'r.', 'MarkerSize', 5); 
    title({titleStr1velocityEach, titleStr2, titleStr3}, 'FontWeight', 'bold')
    xlabel('Time (s)', 'FontWeight', 'bold')
    ylabel('Velocity,\delta(\Delta)/\delta(t)_{TFM} (\mum/s)', 'FontWeight', 'bold')
    xlim([TimeStampsND2(FirstFrame),TimeStampsND2(LastFrame)]);               % Adjust the end limit.
    set(findobj(gcf,'type', 'axes'), 'FontSize',10, 'FontWeight','Bold', 'LineWidth',1,'XMinorTick', 'on', 'YMinorTick', 'on', 'TickDir', 'out');     % Make axes bold    
 
    
    for ii = 1:numel(ImageChoice)
        tmpImageChoice =  ImageChoice{ii};
        switch tmpImageChoice
            case 'FIG'
                hgsave(figHandleDisplacement_EachFrame, NetDisplacementNameFIG_EachFrame,'-v7.3')
                hgsave(figHandleVelocity_EachFrame, NetVelocityNameFIG_EachFrame,'-v7.3')
                
                if  strcmpi(AnalysisFolderChoice , 'Yes')
                    hgsave(figHandleDisplacement_EachFrame, AnalysisNetDisplacementNameFIG_EachFrame,'-v7.3')         
                    hgsave(figHandleVelocity_EachFrame, AnalysisNetVelocityNameFIG_EachFrame,'-v7.3')         
                end
                
            case 'PNG'
                saveas(figHandleDisplacement_EachFrame, NetDisplacementNamePNG_EachFrame, 'png')
                saveas(figHandleVelocity_EachFrame, NetVelocityNamePNG_EachFrame, 'png')
                if  strcmpi(AnalysisFolderChoice , 'Yes')
                    saveas(figHandleDisplacement_EachFrame, AnalysisNetDisplacementNamePNG_EachFrame, 'png')
                    saveas(figHandleVelocity_EachFrame, AnalysisNetVelocityNamePNG_EachFrame, 'png')
                end                
                
            case 'EPS'
                print(figHandleDisplacement_EachFrame, NetDisplacementNameEPS_EachFrame,'-depsc') 
                print(figHandleVelocity_EachFrame, NetVelocityNameEPS_EachFrame,'-depsc')
                if  strcmpi(AnalysisFolderChoice , 'Yes')
                    print(figHandleDisplacement_EachFrame, AnalysisNetDisplacementNameEPS_EachFrame,'-depsc')
                    print(figHandleVelocity_EachFrame, AnalysisNetVelocityNameEPS_EachFrame,'-depsc')
                end
            otherwise
                 return
        end       
    end
    % ---------------------------------------------------------------------------------------
    disp('Maximum EPI Displacement & Velocity Plots over time have been Generating! Process Complete!')