  


disp('============================== Running PlotDisplacementOverlays.m GPU-enabled ===============================================')
   
    QuiverMagnificationFactor = 2;              % Added on 2020-01-17
    QuiverLineWidth = 0.5;
    RendererMode = 'painters';                   % other option is openGL
    PlotsFontName = 'XITS';   
    reverseString = '';
    FramesAtOnce = 10;
    scalebarFontSize = 10;
        
%         %____ parameters for exportfig to *.eps
%     EPSparam = struct();
%     EPSparam.Bounds = 'tight';          % tight bounding box instead of loose.
%     EPSparam.Color = 'rgb';             % rgb good for online stuff. cmyk is better for print.
%     EPSparam.Renderer = 'Painters';     % instead of opengl, which is better for vectors
%     EPSparam.Resolution = 600;          % DPI
%     EPSparam.LockAxes = 1;              % true
%     EPSparam.FontMode = 'fixed';        % instead of scaled
%     EPSparam.FontSize = 10;             % 10 points
%     EPSparam.FontEncoding = 'latin1';   % 'latin1' is standard for Western fonts. vs 'adobe'
%     EPSparam.LineMode = 'fixed';        % fixed is better than scaled. 
%     EPSparam.LineWidth = 1;             % can be varied depending on what you want it to be    
%     
%     EPSparams = {};
%     EPSparamsFieldNames = fieldnames(EPSparam);
%     for ii = (1:numel(fieldnames(EPSparam)))
%         EPSparams{2*ii - 1} = EPSparamsFieldNames{ii};
%     end
%     for ii = (1:numel(fieldnames(EPSparam)))
%         EPSparams{2*ii} = EPSparam.(EPSparamsFieldNames{ii});
%     end
    %%
    try 
        displFieldProcess =  MD_EPI.findProcessTag('DisplacementFieldCorrectionProcess').tag_;
    catch
        try 
            displFieldProcess =  MD_EPI.findProcessTag('DisplacementFieldCalculationProcess').tag_;
        catch
            displFieldProcess = '';
            disp('No Completed Displacement Field Calculated!');
            disp('------------------------------------------------------------------------------')
        end
    end
    displacementFileFullName = MD_EPI.findProcessTag(displFieldProcess).outFilePaths_{1};
 
    %%
    FramesDoneNumbersEPI = find(FramesDoneNumbersEPI == 1);
    FramesDifferenceEPI = diff(FramesDoneNumbersEPI);
    if isempty(FramesDifferenceEPI), FramesDifferenceEPI = 0; end
    VeryLastFrameEPI = find(FramesDoneNumbersEPI, 1, 'last');
    VeryFirstFrameEPI =  find(FramesDoneNumbersEPI, 1, 'first');      

    load(displacementFileFullName, 'displField');   
    fprintf('Displacement Field (displField) File is successfully loaded!:\n\t%s', displacementFileFullName);
    disp('------------------------------------------------------------------------------')

    fprintf('Magnification scale is %.5f microns/pixel\n', ScaleMicronPerPixel_EPI)   

    %% find maximum microsphere displacement
        %% Finding maximum bead
    dmaxTMP = nan(FramesNumEPI, 1);
    dmaxTMPindex = nan(FramesNumEPI, 1);

    disp('Finding the bead with the maximum displacement...in progress')
    parfor_progress(numel(FramesDoneNumbers), displFieldPath);
    parfor CurrentFrame = FramesDoneNumbers
        dnorm_vec = vecnorm(displField(CurrentFrame).vec(:,1:2), 2,2);  
        displField(CurrentFrame).vec(:,3)  = dnorm_vec;
        dmaxTMP(CurrentFrame) = max(dnorm_vec);
        [~, IdxTMP] = max(dnorm_vec);
        dmaxTMPindex(CurrentFrame) = IdxTMP;
        parfor_progress(-1, displFieldPath);
    end
    parfor_progress(0, displFieldPath);
    disp('Finding the bead with the maximum displacement...complete')

    [~, MaxDisplFrameNumber]  = max(dmaxTMP);

    MaxDisplFieldIndex = dmaxTMPindex(MaxDisplFrameNumber);
    MaxDispl_PosXY_Pixels =  displField(MaxDisplFrameNumber).pos(MaxDisplFieldIndex,:);
    MaxDisplNetPixels = displField(MaxDisplFrameNumber).vec(MaxDisplFieldIndex,:);
    MaxDisplNetMicrons =  MaxDisplNetPixels .* ScaleMicronPerPixel_EPI;
    fprintf('Maximum displacement = %0.4g pixels at ', MaxDisplNetPixels(3));
    fprintf('[x,y] = [%g, %g] pixels in Frame #%d, Point Index #%d \n', MaxDispl_PosXY_Pixels, MaxDisplFrameNumber, MaxDisplFieldIndex)
    fprintf('Maximum displacement [disp_x, disp_y] =  [%0.4g, %0.4g] pixels==> Net displacement [disp_net] = [%0.4g] pixels. \n', MaxDisplNetPixels)
    fprintf('Maximum displacement [disp_x, disp_y] =  [%0.4g, %0.4g] microns==> Net displacement [disp_net] = [%0.4g] microns. \n', MaxDisplNetMicrons)
    % ======== Convert pixels to microns ============================================================  
    totalPointsTracked = size(displField(VeryFirstFrameEPI).pos, 1);
    displFieldMicron = struct('pos', zeros(totalPointsTracked, 1), 'vec',  zeros(totalPointsTracked, 1));
    % 2. Covnert only displacements (.vec) to microns. Keep Starting positions in pixels. Keep the same structure
    parfor CurrentFrame = FramesDoneNumbersEPI
          displFieldMicron(CurrentFrame).pos = displField(CurrentFrame).pos;             % pixels
          displFieldMicron(CurrentFrame).vec = displField(CurrentFrame).vec * ScaleMicronPerPixel_EPI;      
    end

    %% setting up the video

    ImageBits = MD_EPI.camBitdepth_ - 2;   % Typically if 16 bits are used. Then image will be saved in 14 bits.
    ImageSizePixels = MD_EPI.imSize_;     
    MarkerSize = round(ImageSizePixels(1)/ 1000, 1, 'decimals');    
    GrayLevels = 2^ImageBits;    
    
    colormapLUT = [linspace(0,1,GrayLevels)', zeros(GrayLevels,2)];    
    QuiverColor = median(imcomplement(colormapLUT));               % User Complement of the colormap for maximum visibililty of the quiver.
 
    GrayLevelsPercentile = [0.05,0.999];
    MD_EPI_ChannelCount = numel(MD_EPI.channels_);                                             % updated on 2020-04-15

%--------------
    [VideoPathName, VideoFileNameSuffix, ~] = fileparts(displacementFileFullName);
    VideoFullFileName = fullfile(VideoPathName, strcat(VideoFileNameSuffix, '_tracked'));
    VideoOverlayParamFullFile = fullfile(VideoPathName, strcat(VideoFileNameSuffix, '_tracked_params.mat'));

    VideoChoice = 'MPEG-4';
    VideoWriterObj = VideoWriter(VideoFullFileName, VideoChoice);

    VideoWriterObj.FrameRate = FrameRateRT_EPI; 
    open(VideoWriterObj)


    %%
    showQuiver = false;  
    QuiverScaleToMax = [];

        

    %%  Creating the video
%     figHandleInitial = figure('visible','on', 'color', 'w', 'Units', 'pixels', 'Renderer', RendererMode);     % added by WIM on 2019-09-14. To show, remove 'visible
%     figAxesHandle = axes;
    FluoroSphereSizeMicron = HeaderData(7,4);
    FluoroSphereSizePixel = round(FluoroSphereSizeMicron / ScaleMicronPerPixel_EPI);
    
    maxDisplFramePlottedHandle = MD_EPI.channels_(MD_EPI_ChannelCount).loadImage(MaxDisplFrameNumber);
    if useGPU
        maxDisplFramePlottedHandle = gpuArray(maxDisplFramePlottedHandle);
    end 
    % Adjust contrast so that the bottom 5% (dark faint noise is not showing and showing all intense images).
    maxDisplFrameImageAdjusted = imadjust(maxDisplFramePlottedHandle, stretchlim(maxDisplFramePlottedHandle,GrayLevelsPercentile));    
%     maxDisplFramePlottedHandle = imagesc(figAxesHandle,  1, 1, maxDisplFrameImageAdjusted);
    maxDisplFramePlottedHandle = imshow(maxDisplFrameImageAdjusted);



    videoImages = {};    
    parfor CurrentFrame = FramesDoneNumbersEPI
            videoImages{CurrentFrame} = plotDisplacementOverlaysParfor(MD_EPI,displField,CurrentFrame, MD_EPI_ChannelCount, FluoroSphereSizePixel, ...
                QuiverColor, GrayLevelsPercentile, colormapLUT, FramesNumEPI); 
    end
    


