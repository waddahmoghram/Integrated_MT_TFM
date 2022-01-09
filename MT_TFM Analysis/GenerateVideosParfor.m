%{
    Written by Waddah Moghram, PhD Student in Biomedical Engineering at the University of Iowa.
    Load finalworkspace.mat and run this script.
%}

disp('============================== Running PlotDisplacementOverlays.m GPU-enabled ===============================================')
%     VideoChoice = 'MPEG-4';    
    VideoChoice = 'Motion JPEG 2000';                  % better than mp4. Keeps more details but compresses it. Lossy compression, but quality is the same

    ImageSize = [200, 500, 1000, 2000]';         % pixels
    FontSizeDesired = [7, 17, 19, 28]';          
    FontSizeCurveFit = fit(ImageSize,FontSizeDesired,'poly2');       % quadratic fit between 200 pixels and 2000 pixels window size.
    colorbarFontSize = round((FontSizeCurveFit.p1 * MD_EPI.imSize_(1)^2 + FontSizeCurveFit.p2 * MD_EPI.imSize_(1) + FontSizeCurveFit.p3)*2)/2;       % make in increments on 0.5 
    if colorbarFontSize < 7
        colorbarFontSize = 7;
    end   
    scalebarFontSize = round(colorbarFontSize*2/3);
    
    FluoroSphereSizeMicron = HeaderData(7,4);
    FluoroSphereSizePixel = round(FluoroSphereSizeMicron / ScaleMicronPerPixel_EPI);
    ImageBits = MD_EPI.camBitdepth_ - 2;   % Typically if 16 bits are used. Then image will be saved in 14 bits.
    MarkerSize = round(MD_EPI.imSize_(1)/ 1000, 1, 'decimals');    
    GrayLevels = 2^ImageBits;    

    GrayLevelsPercentile = [0.05,0.999];                        % to make beads show up better
    MD_EPI_ChannelCount = numel(MD_EPI.channels_);                                             % updated on 2020-04-15

    ScaleLength_EPI =   round((max(MD_EPI.imSize_) - max([gridXmax - gridXmin, gridYmax - gridYmin]))/4, 1, 'significant'); 

    FluxStatusString = cell(FramesNumEPI, 1);
    FluxStatusString(FramesDoneNumbersEPI(FluxON)) = {'Flux ON'};
    FluxStatusString(FramesDoneNumbersEPI(FluxOFF)) = {'Flux OFF'};
    FluxStatusString(FramesDoneNumbersEPI(FluxTransient)) = {'Flux TRANS'};    

    QuiverMagnificationFactor = 1;              % Added on 2020-01-17
    QuiverLineWidth = 0.5;
    bandSize = 0;

    FramesDifferenceEPI = diff(FramesDoneNumbersEPI);
    if isempty(FramesDifferenceEPI), FramesDifferenceEPI = 0; end
    VeryLastFrameEPI = find(FramesDoneNumbersEPI, 1, 'last');
    VeryFirstFrameEPI =  find(FramesDoneNumbersEPI, 1, 'first');      

    fprintf('Magnification scale is %.5f microns/pixel\n', ScaleMicronPerPixel_EPI)     
        % ======== Convert pixels to microns ============================================================  
    TotalAreaPixel = (max(displField(RefFrameNumEPI).pos(:,1)) -  min(displField(RefFrameNumEPI).pos(:,1))) * ...
        (max(displField(RefFrameNumEPI).pos(:,2)) -  min(displField(RefFrameNumEPI).pos(:,2)));                 % x-length * y-length
    totalBeadsTracked = numel(displField(RefFrameNumEPI).pos(:,1));
    
 %% 1. displacement field quivers from microspheres
    load(displacementFileFullName, 'displField');                % at this point. displField_LPEF_DC.mat is the default file
    fprintf('Displacement Field (displField) File is successfully loaded!:\n\t%s', displacementFileFullName);
    disp('------------------------------------------------------------------------------')
          % Finding maximum fluorescent microsphere
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
    [~, MaxDisplFrameNumber]  = max(dmaxTMP);

    MaxDisplFieldIndex = dmaxTMPindex(MaxDisplFrameNumber);
    MaxDispl_PosXY_Pixels =  displField(MaxDisplFrameNumber).pos(1,:);
    MaxDisplNetPixels = displField(MaxDisplFrameNumber).vec(1,:);
    MaxDisplNetMicrons =  MaxDisplNetPixels .* ScaleMicronPerPixel_EPI;
    fprintf('Maximum displacement = %0.4g pixels at ', MaxDisplNetPixels(3));
    fprintf('[x,y] = [%g, %g] pixels in Frame #%d, Point Index #%d \n', MaxDispl_PosXY_Pixels, MaxDisplFrameNumber, MaxDisplFieldIndex)
    fprintf('Maximum displacement [disp_x, disp_y] =  [%0.4g, %0.4g] pixels==> Net displacement [disp_net] = [%0.4g] pixels. \n', MaxDisplNetPixels)
    fprintf('Maximum displacement [disp_x, disp_y] =  [%0.4g, %0.4g] microns==> Net displacement [disp_net] = [%0.4g] microns. \n', MaxDisplNetMicrons)

    AvgInterBeadDist = sqrt((TotalAreaPixel)/size(displField(MaxDisplFrameNumber).pos,1));        % avg inter-bead separation distance = total img area/number of tracked points
    QuiverScaleDefault = 0.95 * (AvgInterBeadDist/MaxDisplNetPixels(3)) * QuiverMagnificationFactor;    
    QuiverScaleToMax = QuiverScaleDefault * QuiverMagnificationFactor; 

    TrackingInfoTXT = sprintf('mode=%s. highRes=%g. addNonLocMaxBeads=%d. trackSuccessively=%d. alpha=%0.4g, minCorLength=%g, maxFlowSpeed=%g. useGrid=%g. lastToFirst=%g. noFlowOutwardOnBorder=%d.', ...
        displacementParameters.mode,displacementParameters.highRes, displacementParameters.addNonLocMaxBeads,displacementParameters.trackSuccessively, displacementParameters.alpha, ...
        displacementParameters.minCorLength,displacementParameters.maxFlowSpeed, displacementParameters.useGrid, displacementParameters.lastToFirst, displacementParameters.noFlowOutwardOnBorder);
    TrackingInfoTXT = sprintf('%s\nMaxDisplNetMicrons=%0.3f%s.', TrackingInfoTXT,MaxDisplNetMicrons(3), sprintf('%sm', char(181)));
    if ~isempty(TimeFilterChoiceStr), TrackingInfoTXT = sprintf('%s %s.', TrackingInfoTXT,TimeFilterChoiceStr);end
    if ~isempty(DriftCorrectionChoiceStr), TrackingInfoTXT = sprintf('%s %s.', TrackingInfoTXT,DriftCorrectionChoiceStr);end
    
    colormapLUT_TxRed = [linspace(0,1,GrayLevels)', zeros(GrayLevels,2)];    % Texas Red LUT
    QuiverColor = median(imcomplement(colormapLUT_TxRed));               % User Complement of the colormap for maximum visibililty of the quiver.

    videoImages = cell(FramesNumEPI, 1);
    parfor CurrentFrame = FramesDoneNumbersEPI
            videoImages{CurrentFrame} = plotDisplacementOverlaysVectorsParfor(MD_EPI,displField,CurrentFrame, MD_EPI_ChannelCount, QuiverScaleToMax, ...
                QuiverColor, GrayLevelsPercentile, colormapLUT_TxRed, FramesNumEPI, ScaleLength_EPI, ScaleMicronPerPixel_EPI, TimeStampsRT_Abs_EPI, FluxStatusString(CurrentFrame), TrackingInfoTXT, scalebarFontSize); 
    end

    [VideoPathName, VideoFileNameSuffix, ~] = fileparts(displacementFileFullName);
    VideoFullFileName = fullfile(VideoPathName, strcat(VideoFileNameSuffix, '_vectors'));
    VideoWriterObj = VideoWriter(VideoFullFileName, VideoChoice);
%     VideoOverlayParamFullFile = fullfile(VideoPathName, strcat(VideoFileNameSuffix, '_vectors_params.mat'));
    VideoWriterObj.FrameRate = FrameRateRT_EPI; 
    if strcmpi(VideoChoice, 'MPEG-4'), VideoWriterObj.Quality = 100;end
%     if strcmpi(VideoChoice, 'Motion JPEG 2000'), VideoWriterObj.LosslessCompression = true;end
    open(VideoWriterObj)

    for CurrentFrame = FramesDoneNumbersEPI 
        writeVideo(VideoWriterObj,  videoImages{CurrentFrame})
    end
    close(VideoWriterObj)
    clear videoImages;

%% 2.  gridded heatmap for the displacement above
% plotting displacement heat maps
   % find maximum microsphere displacement of the gridded displacement
    disp('Identifying the limits of the interpolated displacement grid limits over all frames without generating it yet.')
    disp('Note that these values might be extreme due to noise. Rely more on outlier-cleaned/filtered/drift corrected values')

    % 2. Covnert only displacements (.vec) to microns. Keep Starting positions in pixels. Keep the same structure
    parfor CurrentFrame = FramesDoneNumbersEPI
          displFieldMicron(CurrentFrame).pos = displField(CurrentFrame).pos;             % pixels
          displFieldMicron(CurrentFrame).vec = displField(CurrentFrame).vec * ScaleMicronPerPixel_EPI;      
    end

    dmaxTMPgrid = nan(FramesNumEPI, 2);
    dminTMPgrid = nan(FramesNumEPI, 2);
    [grid_mat, ~,~,~] = interp_vec2grid(displField(RefFrameNumEPI).pos(:,1:2), displField(RefFrameNumEPI).vec(:,1:2) ,[], reg_grid, InterpolationMethod);
    grid_mat = gpuArray(grid_mat);
    grid_matX = grid_mat(:,:,1);
    grid_matY = grid_mat(:,:,2);
    %-----------------------------------------------------------------------------------------------
    grid_spacingX = grid_mat(1,2,1)- grid_mat(1,1,1);
    grid_spacingY = grid_mat(2,1,2)- grid_mat(1,1,2);        
    imSizeX = (grid_mat(end,end,1) - grid_mat(1,1,1)) + grid_spacingX;
    imSizeY = (grid_mat(end,end,2) - grid_mat(1,1,2)) + grid_spacingY;    
    %----------------------------------------------------------------------------------------------
    centerX = ((grid_mat(end,end,1) + grid_mat(1,1,1))/2);
    centerY = ((grid_mat(end,end,2) + grid_mat(1,1,2))/2);
    % [XI,YI] = meshgrid(grid_mat(1,1,1):grid_mat(1,1,1)+imSizeX,grid_mat(1,1,2):grid_mat(1,1,2)+imSizeY);
    Xmin = centerX - imSizeX/2 + bandSize;
    Xmax = centerX + imSizeX/2 - bandSize;
    Ymin = centerY - imSizeY/2 + bandSize;
    Ymax = centerY + imSizeY/2 - bandSize;               
    [XI,YI] = ndgrid(Xmin:Xmax,Ymin:Ymax);                % Addded on 2019-10-10 to go with gridded interpolant, the line above is for griddata
    XI = gather(XI);
    YI = gather(YI);            
    reg_gridFull(:,:,1)  = XI; reg_gridFull(:,:,2)  = YI;
    [grid_mat_full, ~,~,~] = interp_vec2grid(displField(RefFrameNumEPI).pos(:,1:2), displField(RefFrameNumEPI).vec(:,1:2) ,[], reg_gridFull, InterpolationMethod);
    grid_mat_full = gpuArray(grid_mat_full);

    parfor_progressPath = TractionForcePath;
    parfor_progress(FramesNumEPI, parfor_progressPath);
    parfor CurrentFrame=FramesDoneNumbersEPI
        %Load the saved body heat map.
        [~, displVecGridXY,~,~] = interp_vec2grid(displField(CurrentFrame).pos(:,1:2), displField(CurrentFrame).vec(:,1:2) ,[], reg_gridFull, InterpolationMethod);         
        displVecGridXY = gpuArray(displVecGridXY);
        d_norm = (displVecGridXY(:,:,1).^2 + displVecGridXY(:,:,2).^2).^0.5;
            % Boundary cutting - I'll take care of this boundary effect later
        d_norm(end-round(band/2):end,:)=[];
        d_norm(:,end-round(band/2):end)=[];
        d_norm(1:1+round(band/2),:)=[];
        d_norm(:,1:1+round(band/2))=[];
        d_norm_vec = reshape(d_norm,[],1); 
  
        dmaxTMPgrid(CurrentFrame, :) = max(max(d_norm_vec));
        dminTMPgrid(CurrentFrame, :) = min(min(d_norm_vec));
        
        parfor_progress(-1, parfor_progressPath);
    end
    parfor_progress(0, parfor_progressPath);
    [dmaxPixGridFine, ~] = max(dmaxTMPgrid(:,1));
    [dminPixGridFine, ~] = min(dminTMPgrid(:,1));

    dminMicronsFine = dminPixGridFine  * ScaleMicronPerPixel_EPI;                  % Convert from nanometer to microns. 2019-06-08 WIM
    dmaxMicronsFine = dmaxPixGridFine  * ScaleMicronPerPixel_EPI;                  % Convert from nanometer to microns. 2019-06-08 WIM
    fprintf('Maximum displacement = %0.4g microns. \n', dmaxMicronsFine);

    totaGridPoints = size(reg_grid,1)*size(reg_grid,2);
    AvgInterBeadDist = sqrt(TotalAreaPixel/totaGridPoints);        % avg inter-bead separation distance = total img area/number of tracked points
    QuiverScaleDefault = 0.95 * (AvgInterBeadDist/dmaxMicronsFine) * QuiverMagnificationFactor;    
    QuiverScaleToMax = QuiverScaleDefault * QuiverMagnificationFactor; 

    colormapLUT_parula = parula(GrayLevels);
    QuiverColor = median(imcomplement(colormapLUT_parula));      
    colorbarLimits = [0, dmaxMicronsFine];

    TrackingInfoTXT = sprintf('Grid size=%dx%d. Spacing=%d pix. Interp. method=%s.', size(reg_grid,1:2) , gridSpacing, 'griddata: cubic & v4.');
    TrackingInfoTXT = sprintf('% s%s. %s (%dx%d). Han window %s. %s.', TrackingInfoTXT, TractionStressMethod, SpatialFilterChoiceStr, WienerWindowSize, PaddingChoiceStr, reg_cornerChoiceStr ) ;
    TrackingInfoTXT = sprintf('%s\nMaxDisplNetMicrons=%0.3f%s.', TrackingInfoTXT,dmaxMicronsFine, sprintf('%sm', char(181)));
    if ~isempty(TimeFilterChoiceStr), TrackingInfoTXT = sprintf('%s %s.', TrackingInfoTXT,TimeFilterChoiceStr);end
    if ~isempty(DriftCorrectionChoiceStr), TrackingInfoTXT = sprintf('%s %s.', TrackingInfoTXT,DriftCorrectionChoiceStr);end
    TrackingInfoTXT = sprintf('%s Grid size = %dx%d. Spacing = %d pix. Interp. method = %s', TrackingInfoTXT, size(reg_grid,1:2) , gridSpacing, 'griddata: cubic & v4.');
    
    videoImages = cell(FramesNumEPI, 1);
    parfor CurrentFrame = FramesDoneNumbersEPI
            videoImages{CurrentFrame} = plotDisplacementHeatmapsVectorsParfor(MD_EPI,displFieldMicron, CurrentFrame, QuiverScaleToMax, ...
                QuiverColor, TrackingInfoTXT, colormapLUT_parula, FramesNumEPI, ScaleLength_EPI, ScaleMicronPerPixel_EPI, TimeStampsRT_Abs_EPI, FluxStatusString{CurrentFrame}, ...
                reg_grid, InterpolationMethod, bandSize, colorbarLimits, colorbarFontSize)
    end

    VideoFullFileName = fullfile(VideoPathName, strcat(VideoFileNameSuffix, '_heatmap'));
    VideoWriterObj = VideoWriter(VideoFullFileName, VideoChoice);
    VideoOverlayParamFullFile = fullfile(VideoPathName, strcat(VideoFileNameSuffix, '_heatmap_params.mat'));
    VideoWriterObj.FrameRate = FrameRateRT_EPI; 
    open(VideoWriterObj)
    for CurrentFrame = FramesDoneNumbersEPI 
        writeVideo(VideoWriterObj,  videoImages{CurrentFrame})
    end
    close(VideoWriterObj)
    clear videoImages;

%% 3. find maximum traction stress from grid
    tmaxTMPgrid = nan(FramesNumEPI, 2);
    tminTMPgrid = nan(FramesNumEPI, 2);

    parfor_progressPath = TractionForcePath;
    parfor_progress(FramesNumEPI, parfor_progressPath);
    parfor CurrentFrame=FramesDoneNumbersEPI
        %Load the saved body heat map.
        [~,fmat, ~, ~] = interp_vec2grid(forceField(CurrentFrame).pos(:,1:2), forceField(CurrentFrame).vec(:,1:2),[],reg_grid);            % 1:cluster size
        t_norm = (fmat(:,:,1).^2 + fmat(:,:,2).^2).^0.5;
    
        % Boundary cutting - I'll take care of this boundary effect later
        t_norm(end-round(band/2):end,:)=[];
        t_norm(:,end-round(band/2):end)=[];
        t_norm(1:1+round(band/2),:)=[];
        t_norm(:,1:1+round(band/2))=[];
        t_norm_vec = reshape(t_norm,[],1); 
  
        tmaxTMPgrid(CurrentFrame, :) = max(max(t_norm_vec));
        tminTMPgrid(CurrentFrame, :) = min(min(t_norm_vec));

        parfor_progress(-1, parfor_progressPath);
    end
    parfor_progress(0, parfor_progressPath);
    [tmaxPaGrid, dmaxIdx] = max(tmaxTMPgrid(:,1));
    [tminPaGrid, dminIdx] = min(tminTMPgrid(:,1));

    % find maximum traction stress from finer pixel by pixel
    tmaxTMPgrid = nan(FramesNumEPI, 2);
    tminTMPgrid = nan(FramesNumEPI, 2);

    [grid_mat, ~,~,~] = interp_vec2grid(forceField(dmaxIdx).pos(:,1:2), forceField(dmaxIdx).vec(:,1:2) ,[], reg_grid, InterpolationMethod);
    grid_mat = gpuArray(grid_mat);
    grid_matX = grid_mat(:,:,1);
    grid_matY = grid_mat(:,:,2);
    %-----------------------------------------------------------------------------------------------
    grid_spacingX = grid_mat(1,2,1)- grid_mat(1,1,1);
    grid_spacingY = grid_mat(2,1,2)- grid_mat(1,1,2);        
    imSizeX = (grid_mat(end,end,1) - grid_mat(1,1,1)) + grid_spacingX;
    imSizeY = (grid_mat(end,end,2) - grid_mat(1,1,2)) + grid_spacingY;    
    %----------------------------------------------------------------------------------------------
    centerX = ((grid_mat(end,end,1) + grid_mat(1,1,1))/2);
    centerY = ((grid_mat(end,end,2) + grid_mat(1,1,2))/2);
    % [XI,YI] = meshgrid(grid_mat(1,1,1):grid_mat(1,1,1)+imSizeX,grid_mat(1,1,2):grid_mat(1,1,2)+imSizeY);
    Xmin = centerX - imSizeX/2 + bandSize;
    Xmax = centerX + imSizeX/2 - bandSize;
    Ymin = centerY - imSizeY/2 + bandSize;
    Ymax = centerY + imSizeY/2 - bandSize;               
    [XI,YI] = ndgrid(Xmin:Xmax,Ymin:Ymax);                % Addded on 2019-10-10 to go with gridded interpolant, the line above is for griddata
    XI = gather(XI);
    YI = gather(YI);            
    reg_gridFull(:,:,1)  = XI; reg_gridFull(:,:,2)  = YI;
    [grid_mat_full, ~,~,~] = interp_vec2grid(forceField(CurrentFrame).pos(:,1:2), forceField(CurrentFrame).vec(:,1:2) ,[], reg_gridFull, InterpolationMethod);
    grid_mat_full = gpuArray(grid_mat_full);

    parfor_progressPath = TractionForcePath;
    parfor_progress(FramesNumEPI, parfor_progressPath);
    parfor CurrentFrame=FramesDoneNumbersEPI
        %Load the saved body heat map.
        [~, forceVecGridXY,~,~] = interp_vec2grid(forceField(dmaxIdx).pos(:,1:2), forceField(dmaxIdx).vec(:,1:2) ,[], reg_gridFull, InterpolationMethod);         
        forceVecGridXY = gpuArray(forceVecGridXY);
        t_norm = (forceVecGridXY(:,:,1).^2 + forceVecGridXY(:,:,2).^2).^0.5;
            % Boundary cutting - I'll take care of this boundary effect later
        t_norm(end-round(band/2):end,:)=[];
        t_norm(:,end-round(band/2):end)=[];
        t_norm(1:1+round(band/2),:)=[];
        t_norm(:,1:1+round(band/2))=[];
        t_norm_vec = reshape(t_norm,[],1); 
  
        tmaxTMPgrid(CurrentFrame, :) = max(max(t_norm_vec));
        tminTMPgrid(CurrentFrame, :) = min(min(t_norm_vec));
        
        parfor_progress(-1, parfor_progressPath);
    end
    parfor_progress(0, parfor_progressPath);
    [tmaxPaGridFine, dmaxIdxFine] = max(tmaxTMPgrid(:,1));
    [tminPaGridFine, dminIdxFine] = min(tminTMPgrid(:,1));

    % plot traction stress heatmap right now
    [VideoPathName, VideoFileNameSuffix, ~] = fileparts(TractionForceFullFileName);

    VideoFullFileName = fullfile(VideoPathName, strcat(VideoFileNameSuffix, '_heatmap'));
    VideoWriterObj = VideoWriter(VideoFullFileName, VideoChoice);
    VideoOverlayParamFullFile = fullfile(VideoPathName, strcat(VideoFileNameSuffix, '_heatmap_param.mat'));
    VideoWriterObj.FrameRate = FrameRateRT_EPI; 
    if strcmpi(VideoChoice, 'MPEG-4'), VideoWriterObj.Quality = 100;end
     
    open(VideoWriterObj)
    videoImages = cell(FramesNumEPI, 1);

    colormapLUT_parula = parula(GrayLevels);
    QuiverColor = median(imcomplement(colormapLUT_parula));      
    colorbarLimits = [0, tmaxPaGridFine];

    QuiverScaleDefault = 0.95 * (AvgInterBeadDist/tmaxPaGridFine) * QuiverMagnificationFactor;    
    QuiverScaleToMax = QuiverScaleDefault * QuiverMagnificationFactor; 

    TrackingInfoTXT = '';
    TrackingInfoTXT = sprintf('Grid size = %dx%d. Spacing = %d pix. Interp. method = %s.', size(reg_grid,1:2) , gridSpacing, 'griddata: cubic & v4.');
    TrackingInfoTXT = sprintf('% s%s. %s (%dx%d). Han window %s. %s.', TrackingInfoTXT, TractionStressMethod, SpatialFilterChoiceStr, WienerWindowSize, PaddingChoiceStr, reg_cornerChoiceStr ) ;
    tractionInfoTxt = sprintf('\\itE\\rm=%0.3f Pa. \\nu=%0.2g.', YoungModulusPaOptimum, PoissonRatio);

    parfor CurrentFrame = FramesDoneNumbersEPI
            videoImages{CurrentFrame} = plotTractionHeatmapsVectorsParfor(MD_EPI,forceField, CurrentFrame, QuiverScaleToMax, ...
                QuiverColor, TrackingInfoTXT, colormapLUT_parula, FramesNumEPI, ScaleLength_EPI, ScaleMicronPerPixel_EPI, TimeStampsRT_Abs_EPI, FluxStatusString{CurrentFrame}, ...
                reg_grid, InterpolationMethod, bandSize, colorbarLimits, colorbarFontSize, reg_corner_averaged(CurrentFrame), tractionInfoTxt)
    end
    for CurrentFrame = FramesDoneNumbersEPI 
        writeVideo(VideoWriterObj,  videoImages{CurrentFrame})
    end
    close(VideoWriterObj)
    clear videoImages;

%% 4. load tracked red beads first
    displFieldProcess =  MD_EPI.findProcessTag('DisplacementFieldCalculationProcess').tag_;
    displacementFileFullName = MD_EPI.findProcessTag(displFieldProcess).outFilePaths_{1};  
    load(displacementFileFullName, 'displField');                % at this point. displField_LPEF_DC.mat is the default file
    [VideoPathName, VideoFileNameSuffix, ~] = fileparts(displacementFileFullName);    
    displFieldPath = VideoPathName;
    % Finding maximum fluorescent microsphere
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

    MaxDisplFieldIndex = dmaxTMPindex(MaxDisplFrameNumber);
    MaxDispl_PosXY_Pixels =  displField(MaxDisplFrameNumber).pos(1,:);
    MaxDisplNetPixels = displField(MaxDisplFrameNumber).vec(1,:);
    MaxDisplNetMicrons =  MaxDisplNetPixels .* ScaleMicronPerPixel_EPI;
    fprintf('Maximum displacement = %0.4g pixels at ', MaxDisplNetPixels(3));
    fprintf('[x,y] = [%g, %g] pixels in Frame #%d, Point Index #%d \n', MaxDispl_PosXY_Pixels, MaxDisplFrameNumber, MaxDisplFieldIndex)
    fprintf('Maximum displacement [disp_x, disp_y] =  [%0.4g, %0.4g] pixels==> Net displacement [disp_net] = [%0.4g] pixels. \n', MaxDisplNetPixels)
    fprintf('Maximum displacement [disp_x, disp_y] =  [%0.4g, %0.4g] microns==> Net displacement [disp_net] = [%0.4g] microns. \n', MaxDisplNetMicrons)

    AvgInterBeadDist = sqrt((TotalAreaPixel)/size(displField(MaxDisplFrameNumber).pos,1));        % avg inter-bead separation distance = total img area/number of tracked points
    QuiverScaleDefault = 0.95 * (AvgInterBeadDist/MaxDisplNetPixels(3)) * QuiverMagnificationFactor;    
    QuiverScaleToMax = QuiverScaleDefault * QuiverMagnificationFactor; 

    colormapLUT_TxRed = [linspace(0,1,GrayLevels)', zeros(GrayLevels,2)];    % Texas Red LUT
    QuiverColor = median(imcomplement(colormapLUT_TxRed));               % User Complement of the colormap for maximum visibililty of the quiver.

    VideoFullFileName = fullfile(VideoPathName, strcat(VideoFileNameSuffix, '_tracked'));
    VideoWriterObj = VideoWriter(VideoFullFileName, VideoChoice);
    VideoOverlayParamFullFile = fullfile(VideoPathName, strcat(VideoFileNameSuffix, '_tracked_param.mat'));
    VideoWriterObj.FrameRate = FrameRateRT_EPI; 
    open(VideoWriterObj)
    videoImages = cell(FramesNumEPI, 1);

    TrackingInfoTXT = sprintf('mode=%s. highRes=%g. addNonLocMaxBeads=%d. trackSuccessively=%d. alpha=%0.4g, minCorLength=%g, maxFlowSpeed=%g. useGrid=%g. lastToFirst=%g. noFlowOutwardOnBorder=%d.', ...
        displacementParameters.mode,displacementParameters.highRes, displacementParameters.addNonLocMaxBeads,displacementParameters.trackSuccessively, displacementParameters.alpha, ...
        displacementParameters.minCorLength,displacementParameters.maxFlowSpeed, displacementParameters.useGrid, displacementParameters.lastToFirst, displacementParameters.noFlowOutwardOnBorder);
    TrackingInfoTXT = sprintf('%s\nMaxDisplNetMicrons=%0.3g%s.', TrackingInfoTXT,MaxDisplNetMicrons(3), sprintf('%sm', char(181)));

    parfor CurrentFrame = FramesDoneNumbersEPI
            videoImages{CurrentFrame} = plotDisplacementOverlaysBeadsParfor(MD_EPI,displField,CurrentFrame, MD_EPI_ChannelCount, FluoroSphereSizePixel, ...
                QuiverColor, GrayLevelsPercentile, colormapLUT_TxRed, FramesNumEPI, ScaleLength_EPI, ScaleMicronPerPixel_EPI, TimeStampsRT_Abs_EPI, FluxStatusString(CurrentFrame), TrackingInfoTXT); 
    end
    for CurrentFrame = FramesDoneNumbersEPI 
        writeVideo(VideoWriterObj,  videoImages{CurrentFrame})
    end
    close(VideoWriterObj)
    clear videoImages;

    %% 5. Making movie for DIC magnetic bead with all the references.
        FramesNumDIC = numel(FramesDoneNumbersDIC);
        FluxStatusString = cell(FramesNumDIC, 1);
        FluxON_DIC = CompiledMT_Results.FluxON;
        FluxStatusString(FramesDoneNumbersDIC(CompiledMT_Results.FluxON(1:FramesNumDIC))) = {'Flux ON'};
        FluxStatusString(FramesDoneNumbersDIC(CompiledMT_Results.FluxOFF(1:FramesNumDIC))) = {'Flux OFF'};
        FluxStatusString(FramesDoneNumbersDIC(CompiledMT_Results.FluxTransient(1:FramesNumDIC))) = {'Flux TRANS'};    
    
        [VideoPathName, VideoFileNameSuffix, ~] = fileparts(MagBeadTrackedDisplacementsFullFileName);
        VideoFullFileName = fullfile(VideoPathName, strcat(VideoFileNameSuffix, '_bead'));
        VideoWriterObj = VideoWriter(VideoFullFileName, VideoChoice);
        VideoOverlayParamFullFile = fullfile(VideoPathName, strcat(VideoFileNameSuffix, '_beads_param.mat'));
        VideoWriterObj.FrameRate = FrameRateRT_EPI; 
        open(VideoWriterObj)
        videoImages = cell(FramesNumDIC, 1);
        
        MD_DIC_ChannelCount = numel(MD_DIC.channels_);
        colormapLUT_GrayScale = gray(GrayLevels);
        QuiverColor = [1,0,0];               % red 
        GrayLevelsPercentile  = [0, 1];
    
        TrackingInfoTXT = sprintf('BeadTrackingMethod=%s. DriftTrackingMethod=%s', BeadTrackingMethod, DriftTrackingMethod);
    
        parfor CurrentFrame = FramesDoneNumbersDIC
                videoImages{CurrentFrame} = plotDisplacementMagBeadOverlayParfor(MD_DIC,MagBeadCoordinatesXYpixels,CurrentFrame, MD_DIC_ChannelCount, BeadRadius, ...
                    QuiverColor, GrayLevelsPercentile, colormapLUT_GrayScale, FramesNumDIC, ScaleLength_EPI, ScaleMicronPerPixel_DIC, TimeStampsRT_Abs_DIC, FluxStatusString(CurrentFrame), ...
                    TrackingInfoTXT, scalebarFontSize); 
        end
        for CurrentFrame = FramesDoneNumbersDIC
            writeVideo(VideoWriterObj,  videoImages{CurrentFrame})
        end
        close(VideoWriterObj)
        clear videoImages;