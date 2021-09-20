%% v.5.00 Updated by Waddah Moghram, PhD Candidate in Biomedical Engineering at University of Iowa, on 2019-05-15>28, and 2019-06-04
%{
For future edition, think about embedding a colormap in the video along with cData. Add a direct video animation here instead of through FIJI

   Detailed explanation goes here

    forceField = displacement field structure
        .pos = position (x,y) of beads
        .vec = vector (u,v) of beads
    HeatMapPath = where the iamges are?
    FirstFrame, numeric
    LastFrame, numeric
    showQuiver = 0 or 1 (or false/true)
    ShowPlot = 'on' or 'off'
    saveVideo = 0 or 1 (or false/true)

Note: 
%     filesep = '\';   % for windows. % No need for this line. filesep is a MATLAB environment variable

%}

function [forceHeatMap, XI, YI, displFieldPathFIG, displFileNameTIF, videoFile] = PlotTractionOverlaysFromField(MD, forceField, HeatMapPath, FirstFrame, LastFrame, ...
    showQuiver, showPlot, saveVideo, maxTractionStress, bandSize,  width, height, colorMapMode)
%% 0. Check function inputs -------------------------------------
    if ~exist('MD', 'var'), MD = []; end
    if nargin < 1 || isempty(MD)
        [name,dirname] = uigetfile('*.mat', 'Open the Movie Data File');
        fullname = fullfile(dirname,name);
        fprintf('Movie Data is: \n %s', fullname);
        load(fullname)
    end
    ImageFileNames = MD.getImageFileNames{1};
    ProcessTag = '';
    outputPath = '';

    if ~exist('forceField','var'), forceField = []; end
    if nargin < 2 || isempty(forceField)
        % no force field is given
        % find the force process tag or the correction process tag       
        try 
            disp('No forceField is given. Trying to find it from the movie data process tags.')
            ProcessTag =  MD.findProcessTag('ForceFieldCalculationProcess').tag_;
        catch
            disp('No completed forceField Calculated!');
        end
        try 
            forceFileName = MD.findProcessTag(ProcessTag).outFilePaths_{1};     %forceField.mat
            load(forceFileName);   
        catch
            disp('You need to give a force field!');
            if ~exist('dirname','var')
                dirname = pwd;
            end
            AllMatFile = fullfile(dirname,'TFMPackage','*.mat');
           	[name2,forceFieldPath] = uigetfile(AllMatFile, 'Open the force field, forceField.mat file. Under forceField or backups folder');
            fullname = fullfile(forceFieldPath,name2);
            load(fullname, 'forceField')
            disp('force Field Loaded Successfully!');
        end
    end
    
    if ~exist('HeatMapPath','var'), HeatMapPath = []; end
    if nargin <3 || isempty(HeatMapPath)
        if ~exist('dirname2', 'var'), forceFieldPath = []; end
        if isempty(forceFieldPath)
            forceFieldPath = pwd;
        end
        HeatMapPath = uigetdir(forceFieldPath,'Choose the directory where you want to store the force heatmaps.');
    end
    
    %_----------
    if ~exist('FirstFrame','var'), FirstFrame = []; end
    if nargin < 4 || isempty(FirstFrame)
        FirstFrame = 1;
    end    
    fprintf('First Frame = %d\n', FirstFrame);    
    
    %_----------
    if ~exist('LastFrame', 'var'), LastFrame = []; end
    if nargin < 5 || isempty(LastFrame)
        LastFrame = sum(arrayfun(@(x) ~isempty(x.vec), forceField));
    end
    fprintf('Last Frame tracked = %d\n', LastFrame);
    
    %-------------------
    if ~exist('showQuiver','var'), showQuiver = []; end
    if nargin < 6 || isempty(showQuiver)
        dlgQuestion = 'Do you want to show displacement quivers?';
        dlgTitle = 'Show Quivers?';
        QuiverChoice = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No', 'Yes');
        switch QuiverChoice
            case 'Yes'
                showQuiver = 1;
            case 'No'
                showQuiver = 0;    % Image sequence instead of a  videos
            otherwise
                return
        end
    end 
    fprintf('showQuiver status is: %d. \n', showQuiver);
    
    %-------------------
    if ~exist('showPlot','var'), showPlot = []; end
    if nargin < 7 || isempty(showPlot)
        dlgQuestion = 'Do you want to show plots as they are made?';
        dlgTitle = 'Show Plots?';
        showPlotChoice = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No', 'Yes');
        switch showPlotChoice
            case 'Yes'
                showPlot = 1;
            case 'No'
                showPlot = 0;    % Image sequence instead of a  videos
            otherwise
                return
        end
    end 
    fprintf('showPlot status is: %d. \n', showQuiver);
    
    if ~exist('saveVideo','var'), saveVideo = []; end
    if nargin < 8 || isempty(saveVideo)
        dlgQuestion = 'Do you want to save videos?';
        dlgTitle = 'Save videos?';
        VideoChoice = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No', 'Yes');
        switch VideoChoice
            case 'Yes'
                saveVideo = 'on';
            case 'No'
                saveVideo = 'off';
            otherwise
                return
        end
    else
        if saveVideo==0
            saveVideo = 'off';    
        end
    end
    fprintf('saveVideo status is: %s. \n', saveVideo);
   
    if ~exist('maxTractionStress','var'), maxTractionStress = []; end
    if nargin < 9 || isempty(maxTractionStress)
        temp_maxTractionStress = 0;       
        ummin = 1e20;
        VeryLastFrame = sum(arrayfun(@(x) ~isempty(x.vec), forceField));
        for CurrentFrame = 1:VeryLastFrame
            maxMag = (forceField(CurrentFrame).vec(:,1).^2+forceField(CurrentFrame).vec(:,2).^2).^0.5;
            ummin = min(ummin,min(maxMag));
            if nargin < 4 || isempty(maxTractionStress)
                temp_maxTractionStress = max(temp_maxTractionStress, max(maxMag));
            end
        end 
        maxTractionStress = temp_maxTractionStress;
    end
    fprintf('Maximum traction stress is %g Pa. \n', maxTractionStress);   
    
    if ~exist('bandSize','var'), bandSize = []; end
    if nargin < 10 || isempty(bandSize)
        bandSize = 0;
    end
    fprintf('Band size is %g pixels. \n', bandSize);       
    figHandle = figure('color','w', 'visible',saveVideo);
    
    if ~exist('colorMapMode','var'), colorMapMode = []; end
    if nargin <13 || isempty(colorMapMode)
        colorMapMode = 'jet';
    end
    if strcmp(colorMapMode,'uDefinedCool')
        color1 = [0 0 0]; color2 = [1 0 0];
        color3 = [0 1 0]; color4 = [0 0 1];
        color5 = [1 1 1]; color6 = [1 1 0];
        color7 = [0 1 1]; color8 = [1 0 1];    
        uDefinedCool = usercolormap(color1,color4,color7,color5);
        colormap(uDefinedCool);
    elseif strcmp(colorMapMode,'uDefinedJet')
        color1 = [0 0 0]; color2 = [1 0 0];
        color3 = [122/255 179/255 23/255]; color4 = [0 0 1];
        color5 = [1 1 1]; color6 = [1 1 0];
        color7 = [0 1 1]; color8 = [252/255 145/255 58/255];    
        uDefinedCool = usercolormap(color1,color4,color7, color3,color6,color8,color2);
        colormap(uDefinedCool);
    elseif strcmp(colorMapMode,'uDefinedRYG')
        color1 = [0 0 0]; color2 = [1 0 0];
        color3 = [0 1 0]; color4 = [0 0 1];
        color5 = [1 1 1]; color6 = [1 1 0];
        color7 = [0 1 1]; color8 = [1 0 1];   
        color9 = [49/255 0 98/255];
        uDefinedCool = usercolormap(color9,color2,color6, color3);
        colormap(uDefinedCool);
    elseif strcmp(colorMapMode,'uDefinedYGR')
        color1 = [0 0 0]; color2 = [1 0 0];
        color3 = [0 1 0]; color4 = [0 0 1];
        color5 = [1 1 1]; color6 = [1 1 0];
        color7 = [0 1 1]; color8 = [1 0 1];    
        uDefinedCool = usercolormap(color5,color6,color3,color2);
        colormap(uDefinedCool);
    else
        colormap(colorMapMode);
    end
    fprintf('Heat Map Color Map is %s. \n', colorMapMode); 

    %
    % 2.No need to convert units here. Leave force Field as is.
    tMap = cell(1,numel(forceField));
    tMapX = cell(1,numel(forceField));
    tMapY = cell(1,numel(forceField));
    
    % account for if forceField contains more than one frame. Make sure you add the TFM Package folder that has the function below.
    [reg_grid,~,~,~] = createRegGridFromDisplField(forceField(1), 2); %2=2 times fine interpolation

    % Anonymous function to append the file number to the file type. 
    fString = ['%0' num2str(floor(log10(LastFrame))+1) '.f'];
    FrameNumSuffix = @(frame) num2str(frame,fString);
 
    %%
     if saveVideo == 1            
        outFile2 = ['displField_Tracked2'];
        videoFile = fullfile(outPath,outFile2);
        writerObj = VideoWriter(videoFile, 'Motion JPEG AVI');
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
        try
            writerObj.FrameRate = FrameRate; 
        catch
            writerObj.FrameRate = 40; 
        end                    
    end    
    figHandle =  figure('color','w','visible',showPlot);     % added by WIM on 2/7/2019. To show, remove 'visible
    
    % Check if there is a GPU. take advantage of it if is there.
    nGPU = gpuDeviceCount;
    if nGPU > 0
        useGPU = true;
    else
        useGPU = false; 
    end    

        % saving
    % Set up the output file path
    outputFilePath = fullfile(HeatMapPath, 'tractionHeatMap');
    tifPath = fullfile(outputFilePath, 'TIF');
%             figPath = fullfile(outputFilePath, 'fig');
    tMapPath = fullfile(outputFilePath, 'tMap');
%                 epsPath = fullfile(outputFilePath, 'eps');
    if ~exist(tifPath,'dir') 
        status = mkdir(tifPath);
    end
%     if ~exist(figPath,'dir')
%         status = mkdir(figPath);
%     end
%     if ~exist(epsPath,'dir')
%        status = mkdir(epsPath);
%     end
%     if ~exist(tMapPath,'dir') 
%         status = mkdir(tMapPath);
%     end

    prompt = {'Define the quiver scaling factor, [Default = 1]'};
    title = 'Quiver Scale Factor';
    QuiverScaleDefault = {'20'};
    QuiverScaleFactor = inputdlg(prompt, title, [1 40], QuiverScaleDefault);
    QuiverScaleFactor = str2double(QuiverScaleFactor{1});                                  % Convert to a number
    %quiver plot
        
    reverseString = '';
    for CurrentFrame = FirstFrame:LastFrame
        ProgressMsg = sprintf('Frame %d/%d: \n',CurrentFrame, LastFrame);
        fprintf([reverseString, ProgressMsg]);
        reverseString = repmat(sprintf('\b'), 1, length(ProgressMsg));
        
        [grid_mat, interpGridVector,~,~] = interp_vec2grid(forceField(CurrentFrame).pos(:,1:2), forceField(CurrentFrame).vec(:,1:2) ,[], reg_grid);
        grid_spacingX = grid_mat(1,2,1)- grid_mat(1,1,1);
        grid_spacingY = grid_mat(2,1,2)- grid_mat(1,1,2);
        
        imSizeX = (grid_mat(end,end,1) - grid_mat(1,1,1)) + grid_spacingX;
        imSizeY = (grid_mat(end,end,2) - grid_mat(1,1,2)) + grid_spacingY; 
        
        if ~exist('width', 'var') || ~exist('height', 'var'), width = []; height = []; end
        if nargin < 6 || isempty(width) || isempty(height)
            width = imSizeX;
            height = imSizeY;
        end

        centerX = ((grid_mat(end,end,1) + grid_mat(1,1,1))/2);
        centerY = ((grid_mat(end,end,2) + grid_mat(1,1,2))/2);
        
        % [XI,YI] = meshgrid(grid_mat(1,1,1):grid_mat(1,1,1)+imSizeX,grid_mat(1,1,2):grid_mat(1,1,2)+imSizeY);
        xmin = centerX - width/2 + bandSize;
        xmax = centerX + width/2 - bandSize;
        ymin = centerY - height/2 + bandSize;
        ymax = centerY + height/2 - bandSize;

        [XI,YI] = meshgrid(xmin:xmax,ymin:ymax);

        % Added by WIM on 2/5/2019
        umnorm = (interpGridVector(:,:,1).^2 + interpGridVector(:,:,2).^2).^0.5;
        tMap{CurrentFrame} = umnorm;
        tMapX{CurrentFrame} = interpGridVector(:,:,1);
        tMapY{CurrentFrame} = interpGridVector(:,:,2);
        
        ForceHeatMap = griddata(grid_mat(:,:,1),grid_mat(:,:,2),umnorm,XI,YI,'cubic');
        
%         if nargin >=2
%           set(figHandle, 'Position', [100 100 w*1.2 h*1.1])
            subplot('Position',[0.05 0.05 0.90 0.9])
            axis tight                                    % added by WIM on 2/12/2019 to keep it tight
            imshow(ForceHeatMap)                                 % returned to imshow() with image and colorbar instead of image
            colormap(colorMapMode);
            
            
      
            
            hold on
            forceScale = QuiverScaleFactor * maxTractionStress; 

            totalPoints = length(forceField(CurrentFrame).pos(:,1));
            inIdx = false(totalPoints,1);

            for CurrentPoint= 1:totalPoints
                if forceField(CurrentFrame).pos(CurrentPoint,1) >= xmin && forceField(CurrentFrame).pos(CurrentPoint,1)<= xmax ...
                        && forceField(CurrentFrame).pos(CurrentPoint,2)>=ymin && forceField(CurrentFrame).pos(CurrentPoint,2)<=ymax
                    inIdx(CurrentPoint) = true;
                end
            end
            
            %quiver plot
            if showQuiver
%                  quiver(Field(CurrentFrame).pos(inIdx,1)-xmin,Field(CurrentFrame).pos(inIdx,2)-ymin, Field(CurrentFrame).vec(inIdx,1)./dispScale,Field(CurrentFrame).vec(inIdx,2)./dispScale,0,'Color',[75/255 0/255 130/255],'LineWidth',0.5);
                quiver(forceField(CurrentFrame).pos(inIdx,1)-xmin, forceField(CurrentFrame).pos(inIdx,2)-ymin, forceField(CurrentFrame).vec(inIdx,1).*forceScale, ...
                    forceField(CurrentFrame).vec(inIdx,2).*forceScale, 0, 'Color',[255/255 255/255 255/255], 'LineWidth',0.5);
            end

%             subplot('Position',[0.90 0.05 0.25 0.9])
            axis tight
            caxis([ummin maxTractionStress]), axis off
            colorbarHandle = colorbar('eastoutside');
            set(colorbarHandle,'Fontsize',14,'FontWeight','bold')
            % added by WIM on 1/13/2019
            ylabel(colorbarHandle,'Traction Stress (Pa)');

            pause(0.5);                             % to give the code some time to save the image after it is generated.

            if saveVideo == 0            
                Img = getframe(figHandle);
                tractionFileNameTIF = fullfile(tifPath, ['tractionFieldNetTIF', num2str(CurrentFrame), '.tif']);
    %             tractionFieldPathFIG = fullfile(tifPath,['tractionFieldNetFIG', num2str(CurrentFrame), '.tif']);
    %             tractionFieldPathEPS = fullfile(tifPath,['tractionFieldNetEPS', num2str(CurrentFrame), '.tif']);

                imwrite(Img.cdata, tractionFileNameTIF);
    %             hgsave(figHandle, tractionFieldPathFIG,'-v7.3')
    %            print(figHandle, tractionFieldPathEPS,'-depsc')
    
           elseif saveVideo == 1                
                    % open the video writer
                    open(writerObj);
                    % convert the image to a frame
                    ImageHandle = getframe(figHandle); 
                    % Need some fixing 3/3/2019
                    writeVideo(writerObj, ImageHandle.cdata); 
            end
    end       
                   % open the video writer
%         curr_tMap = tMap{CurrentFrame};
%         curr_tMapX = tMapX{CurrentFrame};
%         curr_tMapY = tMapY{CurrentFrame};
%         
%         outFiledMap=@(framem) (fullfile(tMapPath, ['tMap', FrameNumSuffix(framem), '.mat']));
%         save(outFiledMap(CurrentFrame),'curr_tMap','curr_tMapX','curr_tMapY','-v7.3');                   % Modified by WIM on 2/5/2019           

%     end
    
    % Added by WIM on 2/5/2019
        %{
    ***** NEEDS FIXING
    outputFile = fullfile(outputFilePath,'tMaps\tractionMaps.mat');
    save(outputFile,'tMap','tMapX','tMapY');              
    ******
    %}
    
     close(figHandle);
end


% Line below is instead of:         LastFrame = sum(arrayfun(@(x) ~isempty(x.vec), forceField));
%{
%         for ii = 1:size(forceField,2)
%             if isempty(forceField(ii).pos)
%                 LastFrame = ii - 1;   % Last non-empty frame.
%                 break
%             else
%                 LastFrame = ii;        % all frames are tracked successfully in this case
%             end       % Track only to the last tracked frame
%         end
%}

