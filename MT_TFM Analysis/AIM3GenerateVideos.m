%{
    Written by Waddah Moghram, PhD Student in Biomedical Engineering at the University of Iowa.
    Load finalworkspace.mat and run this script. Run 'startup.m' script to initiate the localcluster parpool
%}   
%%
    startup
%% Initial Setup for videos. 
    % load workspace "finalworkspace.mat"
    nGPU = gpuDeviceCount;
    if nGPU > 0
        useGPU = true;
    else
        useGPU = false;
    end    
    diaryfile = fullfile(CombinedAnalysisPath, 'GenerateVideosParforLog.txt');
    diary(diaryfile)
    diary on
    disp('============================== Running PlotDisplacementOverlays.m GPU-enabled ===============================================')
%     fig = figure();
%     imshow('coins.png')           % get rid of tutorial window for MATLAB 2021b\
%     figure(fig)
%     pause(3)
%     close(fig)

% copy fonts
    matlabFontPath = fullfile(matlabroot, '\sys\java\jre\win64\jre\lib\fonts');
    FontName1 = "Dependencies\Inconsolata-ExtraCondensedRegular.ttf";
    FontName2 = "Dependencies\xits-regular.otf";
    FontName1MATLAB = fullfile(matlabFontPath, 'Inconsolata-ExtraCondensedRegular.ttf');
    FontName2MATLAB = fullfile(matlabFontPath, 'xits-regular.otf');
%     if ~exist(FontName1MATLAB, 'file') || ~exist(FontName2MATLAB, 'file')
%         try
%             copyfile(FontName1,matlabFontPath, 'f')
%             copyfile(FontName2, matlabFontPath, 'f')
%             !matlab &
%             exit
%         catch
%            font1 = java.awt.Font.createFont(java.awt.Font.TRUETYPE_FONT, java.io.File(FontName1));
%            font2 = java.awt.Font.createFont(java.awt.Font.TRUETYPE_FONT, java.io.File(FontName2));
% %            !matlab &
% %            exit
%         end
%     else
%         % continue
%     end

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
    ImageBits = MD_EPI.camBitdepth_ - 2;   % Typically if 16 bits are used. Then image will be saveFramesDoneNumbersEPId in 14 bits.
    MarkerSize = round(MD_EPI.imSize_(1)/ 1000, 1, 'decimals');    
    GrayLevels = 2^8; %     GrayLevels = 2^ImageBits;    8 bit * 3 channel RGB is the final video output [24 bit]

    GrayLevelsPercentile = [0.05,0.999];                        % to make beads show up better
    MD_EPI_ChannelCount = numel(MD_EPI.channels_);                                             % updated on 2020-04-15

    ScaleLength_EPI =   round((max(MD_EPI.imSize_) - max([gridXmax - gridXmin, gridYmax - gridYmin]))/4, 1, 'significant'); 

    QuiverMagnificationFactor = 1;              % Added on 2020-01-17
    QuiverLineWidth = 0.5;
    bandSize = 0;
    displUnit = sprintf('%sm', char(181));      % um using micron unicode.
    tractionUnit = 'Pa';

    FramesDifferenceEPI = diff(FramesDoneNumbersEPI);
    if isempty(FramesDifferenceEPI), FramesDifferenceEPI = 0; end
    VeryLastFrameEPI = find(FramesDoneNumbersEPI, 1, 'last');
    VeryFirstFrameEPI =  find(FramesDoneNumbersEPI, 1, 'first');      

    fprintf('Magnification scale is %.5f microns/pixel\n', ScaleMicronPerPixel_EPI)     
        % ======== Convert pixels to microns ============================================================  
    TotalAreaPixel = (max(displField(RefFrameNumEPI).pos(:,1)) -  min(displField(RefFrameNumEPI).pos(:,1))) * ...
        (max(displField(RefFrameNumEPI).pos(:,2)) -  min(displField(RefFrameNumEPI).pos(:,2)));                 % x-length * y-length
    totalBeadsTracked = numel(displField(RefFrameNumEPI).pos(:,1));

    VideoType1 = 'Motion JPEG 2000';
    VideoType2 = 'Motion JPEG AVI';
    VideoType3 = 'Uncompressed AVI';
%     VideoType4 = 'Archival';
%     VideoType5 = 'MPEG-4';   

% searchpath for current project to be attached
    searchPath = split(path, ';');
    proj = currentProject;
    for ii = 1:numel(proj.ProjectPath)
        searchPathProject{ii} = proj.ProjectPath(ii).File{:};
    end
    ROIsideSizeMicron = 50;  % default 50 microns
    ROIMagnificationFactor = 3;  % default 300% or 3X 
    
    disp('----------------------------------------------------------------------------------------------------------------')
    displacementFileFullNameLPEFDC = displacementFileFullName;

    FluxON = CompiledMT_Results.FluxON;
    FluxOFF = CompiledMT_Results.FluxOFF;
    FluxTransient = CompiledMT_Results.FluxTransient;

%% Video 1: displacement field  (tracked beads)
    if isempty(gcp('nocreate')), localcluster.parpool;end
    disp('----------------------------------------------------------------------------------------------------------------')
    displFieldProcess =  MD_EPI.findProcessTag('DisplacementFieldCalculationProcess').tag_;
    displacementFileFullNameRaw = MD_EPI.findProcessTag(displFieldProcess).outFilePaths_{1};  
    [DisplPathName, displFileNamePrefix, displFieldFileNameExt] = fileparts(displacementFileFullNameRaw);   
    displacementFileFullName = fullfile(DisplPathName, strcat(displFileNamePrefix, displFieldFileNameExt));
    fprintf('1.0 Displacement Field (displField) File is successfully loaded!:\n\t%s\n', displacementFileFullName);

    load(displacementFileFullName, 'displField');                % at this point. displField.mat is the default file
    fprintf('Displacement Field (displField) File is successfully loaded!:\n\t%s\n', displacementFileFullName);
    
    FramesDoneIdx = ~arrayfun(@(x)isempty(displField(x).pos),1:numel(displField));
    FramesNumbersAll = 1:numel(FramesDoneIdx);
    FramesDoneNumbersEPI = FramesNumbersAll(FramesDoneIdx);
    FramesNumEPI = min([numel(FramesDoneNumbersEPI), numel(displField), numel(FluxON)]) ;
    FramesNumbersAll = FramesNumbersAll(1:FramesNumEPI);
    FramesDoneIdx = FramesDoneIdx(1:FramesNumEPI);
    FramesDoneNumbersEPI = FramesNumbersAll(FramesDoneIdx);
    FluxON = FluxON(1:FramesNumEPI);
    FluxOFF = FluxOFF(1:FramesNumEPI);   
    FramesDoneNumbersONTrans = FramesDoneNumbersEPI(FluxON(FramesDoneIdx) | FluxTransient(FramesDoneIdx));
    FluxStatusString = cell(FramesNumEPI, 1);
    FluxStatusString(FluxON(FramesDoneNumbersEPI)) = {'Flux ON'};
    FluxStatusString(FluxOFF(FramesDoneNumbersEPI)) = {'Flux OFF'};
    FluxStatusString(FluxTransient(FramesDoneNumbersEPI)) = {'Flux TRANS'};    

    [VideoPathName1, VideoFileNameSuffix, ~] = fileparts(displacementFileFullName);   
    VideoFileName = strcat(VideoFileNameSuffix, '_tracked');
    VideoFullFileName1 = fullfile(VideoPathName1, VideoFileName);
    VideoWriterObj1 = VideoWriter(VideoFullFileName1, VideoType1);
    VideoWriterObj1.LosslessCompression = true;
    VideoWriterObj1.FrameRate = FrameRateRT_EPI; 
    VideoFullFileName3 = fullfile(CombinedAnalysisPath, VideoFileName);
    VideoWriterObj3 = VideoWriter(VideoFullFileName3, VideoType3);
    VideoWriterObj3.FrameRate = FrameRateRT_EPI; 
    fprintf("-------- Video 1. **** %s **** ------------------\n%s", VideoWriterObj1.Filename)

    disp('1.1 Finding the bead with the maximum displacement in ON/Transient frames IN PROGRESS')
    dmaxTMP = nan(FramesNumEPI, 1);
    dmaxTMPindex = nan(FramesNumEPI, 1);
    diary off
    parfor_progress(numel(FramesDoneNumbersEPI), DisplPathName);
    parfor CurrentFrame = FramesDoneNumbersEPI
        dnorm_vec = vecnorm(displField(CurrentFrame).vec(:,1:2), 2,2);  
        if useGPU, dnorm_vec = gpuArray(dnorm_vec); end
        displField(CurrentFrame).vec(:,3)  = dnorm_vec;
        dmaxTMP(CurrentFrame) = max(dnorm_vec);
        [~, IdxTMP] = max(dnorm_vec);
        dmaxTMPindex(CurrentFrame) = IdxTMP;
        parfor_progress(-1, DisplPathName);
        dnorm_vec = [];
        IdxTMP = [];
    end
    parfor_progress(0, DisplPathName);
    clear dnorm_vec  IdxTMP IdxTMP
    diary on
    [~, MaxDisplFrameNumber]  = max(dmaxTMP);
    MaxDisplFieldIndex = dmaxTMPindex(MaxDisplFrameNumber);
    MaxDispl_PosXY_Pixels =  displField(MaxDisplFrameNumber).pos(MaxDisplFieldIndex,:);
    MaxDisplNetPixels = displField(MaxDisplFrameNumber).vec(MaxDisplFieldIndex,:);
    MaxDisplNetMicrons =  MaxDisplNetPixels .* ScaleMicronPerPixel_EPI;
    fprintf('[x,y] = [%0.3f, %0.3f] pixels in Frame #%d, Point Index #%d \n', MaxDispl_PosXY_Pixels, MaxDisplFrameNumber, MaxDisplFieldIndex)
    fprintf('Maximum displacement [disp_x, disp_y] =  [%0.3f, %0.3f] pixels  \t==> Net displacement [disp_net] = [%0.3f] pixels. \n', MaxDisplNetPixels)
    fprintf('Maximum displacement [disp_x, disp_y] =  [%0.3f, %0.3f] %s      \t==> Net displacement [disp_net] = [%0.3f] %s. \n', ...
        MaxDisplNetMicrons(1:2), displUnit, MaxDisplNetMicrons(3) , displUnit)
    disp('1.1 Finding the bead with the maximum displacement in ON/Transient frames COMPLETE')

    disp("1.2 Creating frames IN PROGRESS") 
    colormapLUT_TxRed = [linspace(0,1,GrayLevels)', zeros(GrayLevels,2)];    % Texas Red LUT
    QuiverColor = median(imcomplement(colormapLUT_TxRed));               % User Complement of the colormap for maximum visibililty of the quiver.
    NumDigits = numel(num2str(FramesNumEPI));            %counting the number of digits in the number of frames. E.g., 1000 = 4 digits, 100 is three digits, and so forth.
    FormatSpecifier = sprintf('%%%dg', NumDigits);
    FrameString = sprintf('Frame #%s', sprintf(FormatSpecifier, MaxDisplFrameNumber));
    TrackingInfoTXT = sprintf('mode=%s. highRes=%g. addNonLocMaxBeads=%d. trackSuccessively=%d. alpha=%0.3f, minCorLength=%g, maxFlowSpeed=%g. useGrid=%g. lastToFirst=%g. noFlowOutwardOnBorder=%d.', ...
        displacementParameters.mode,displacementParameters.highRes, displacementParameters.addNonLocMaxBeads,displacementParameters.trackSuccessively, displacementParameters.alpha, ...
        displacementParameters.minCorLength,displacementParameters.maxFlowSpeed, displacementParameters.useGrid, displacementParameters.lastToFirst, displacementParameters.noFlowOutwardOnBorder);
    TrackingInfoTXT = sprintf('%s\nMaxDisplNetMicrons=%0.3f %s in %s @ [%0.3f, %0.3f] pix.', TrackingInfoTXT, MaxDisplNetMicrons(3), sprintf('%sm', char(181)), FrameString, MaxDispl_PosXY_Pixels); 
    videoImages = cell(FramesNumEPI, 1);
    diary off
    parfor_progress(numel(FramesDoneNumbersEPI), DisplPathName);
    parfor CurrentFrame = FramesDoneNumbersEPI
            videoImages{CurrentFrame} = plotDisplacementOverlaysBeadsParfor(MD_EPI,displField,CurrentFrame, MD_EPI_ChannelCount, FluoroSphereSizePixel, ...
                QuiverColor, colormapLUT_TxRed, GrayLevelsPercentile, FramesNumEPI, ScaleLength_EPI, ScaleMicronPerPixel_EPI, TimeStampsRT_Abs_EPI, FluxStatusString{CurrentFrame}, ...
                TrackingInfoTXT, scalebarFontSize, useGPU, MaxDisplNetPixels); 
            parfor_progress(-1, DisplPathName);
    end
    parfor_progress(0, DisplPathName);
    diary on
    disp("1.2 Creating frames COMPLETE!") 

    disp("1.2 Writing  frames IN PROGRESS") 
    open(VideoWriterObj1)
    open(VideoWriterObj3)        
    diary off
    parfor_progress(numel(FramesDoneNumbersEPI), DisplPathName);
    for CurrentFrame = FramesDoneNumbersEPI 
        writeVideo(VideoWriterObj1,  videoImages{CurrentFrame})
        writeVideo(VideoWriterObj3,  videoImages{CurrentFrame})
        parfor_progress(-1, DisplPathName);
    end
    parfor_progress(0, DisplPathName);
    diary on
    close(VideoWriterObj1)
    close(VideoWriterObj3)
    disp("1.2 Writing  frames COMPLETE!") 
    fprintf('Saved as: \n\t%s\n', VideoFullFileName1)
%     winopen(VideoPathName1)
%     winopen(CombinedAnalysisPath)
    disp('----------------------------------------------------------------------------------------------------------------')
    clear videoImages 

%% Video 2: displacement field corrected + LPEF (tracked beads)
    disp('----------------------------------------------------------------------------------------------------------------')
    displFieldProcess =  MD_EPI.findProcessTag('DisplacementFieldCorrectionProcess').tag_;
    displacementFileFullNameRaw = MD_EPI.findProcessTag(displFieldProcess).outFilePaths_{1};  
    [DisplPathName, displFileNamePrefix, displFieldFileNameExt] = fileparts(displacementFileFullNameRaw);   
    displacementFileFullNameLPEF = fullfile(DisplPathName, strcat(displFileNamePrefix, '_LPEF', displFieldFileNameExt));
    fprintf('2.0 Displacement Field (displField) File is successfully loaded!:\n\t%s\n', displacementFileFullNameLPEF);

    load(displacementFileFullNameLPEF, 'displField');                % at this point. displField.mat is the default file
    fprintf('Corrected & Filtered Displacement Field (displField) File is successfully loaded!:\n\t%s\n', displacementFileFullNameLPEF);

    FramesNumEPI = numel(displField);
    FramesNumbersAll = 1:FramesNumEPI;
    FramesDoneIdx=~arrayfun(@(x)isempty(displField(x).pos),FramesNumbersAll);
    FramesDoneNumbersEPI = FramesNumbersAll(FramesDoneIdx);
    FramesDoneNumbersONTrans = FramesDoneNumbersEPI(FluxON(FramesDoneNumbersEPI) | FluxTransient(FramesDoneNumbersEPI));
    FramesNumEPI = numel(FramesDoneNumbersEPI);    
    FluxStatusString = cell(FramesNumEPI, 1);
    FluxStatusString(FluxON(FramesDoneNumbersEPI)) = {'Flux ON'};
    FluxStatusString(FluxOFF(FramesDoneNumbersEPI)) = {'Flux OFF'};
    FluxStatusString(FluxTransient(FramesDoneNumbersEPI)) = {'Flux TRANS'};    
    
    [VideoPathName1, VideoFileNameSuffix, ~] = fileparts(displacementFileFullNameLPEF);   
    VideoFileName = strcat(VideoFileNameSuffix, '_tracked');
    VideoFullFileName1 = fullfile(VideoPathName1, VideoFileName);
    VideoWriterObj1 = VideoWriter(VideoFullFileName1, VideoType1);
    VideoWriterObj1.LosslessCompression = true;
    VideoWriterObj1.FrameRate = FrameRateRT_EPI; 
    VideoFullFileName3 = fullfile(CombinedAnalysisPath, VideoFileName);
    VideoWriterObj3 = VideoWriter(VideoFullFileName3, VideoType3);
    VideoWriterObj3.FrameRate = FrameRateRT_EPI; 
    fprintf("-------- Video 2. **** %s **** ------------------\n%s", VideoWriterObj1.Filename)

    disp('2.1 Finding the bead with the maximum displacement in ON/Transient frames IN PROGRESS')
    dmaxTMP = nan(FramesNumEPI, 1);
    dmaxTMPindex = nan(FramesNumEPI, 1);
    diary off
    parfor_progress(numel(FramesDoneNumbersEPI), displFieldPath);
    parfor CurrentFrame = FramesDoneNumbersEPI
        dnorm_vec = vecnorm(displField(CurrentFrame).vec(:,1:2), 2,2);  
        if useGPU, dnorm_vec = gpuArray(dnorm_vec); end
        displField(CurrentFrame).vec(:,3)  = dnorm_vec;
        dmaxTMP(CurrentFrame) = max(dnorm_vec);
        [~, IdxTMP] = max(dnorm_vec);
        dmaxTMPindex(CurrentFrame) = IdxTMP;
        parfor_progress(-1, displFieldPath);
        dnorm_vec = [];
        IdxTMP = [];
    end
    parfor_progress(0, displFieldPath);
    clear dnorm_vec  IdxTMP IdxTMP
    diary on
    [~, MaxDisplFrameNumber]  = max(dmaxTMP);
    MaxDisplFieldIndex = dmaxTMPindex(MaxDisplFrameNumber);
    MaxDispl_PosXY_Pixels =  displField(MaxDisplFrameNumber).pos(MaxDisplFieldIndex,:);
    MaxDisplNetPixels = displField(MaxDisplFrameNumber).vec(MaxDisplFieldIndex,:);
    MaxDisplNetMicrons =  MaxDisplNetPixels .* ScaleMicronPerPixel_EPI;
    fprintf('[x,y] = [%0.3f, %0.3f] pixels in Frame #%d, Point Index #%d \n', MaxDispl_PosXY_Pixels, MaxDisplFrameNumber, MaxDisplFieldIndex)
    fprintf('Maximum displacement [disp_x, disp_y] =  [%0.3f, %0.3f] pixels  \t==> Net displacement [disp_net] = [%0.3f] pixels. \n', MaxDisplNetPixels)
    fprintf('Maximum displacement [disp_x, disp_y] =  [%0.3f, %0.3f] %s      \t==> Net displacement [disp_net] = [%0.3f] %s. \n', ...
        MaxDisplNetMicrons(1:2), displUnit, MaxDisplNetMicrons(3) , displUnit)
    disp('2.1 Finding the bead with the maximum displacement in ON/Transient frames COMPLETE')

    disp("2.2 Creating frames IN PROGRESS") 
    colormapLUT_TxRed = [linspace(0,1,GrayLevels)', zeros(GrayLevels,2)];    % Texas Red LUT
    QuiverColor = median(imcomplement(colormapLUT_TxRed));               % User Complement of the colormap for maximum visibililty of the quiver.
    NumDigits = numel(num2str(FramesNumEPI));            %counting the number of digits in the number of frames. E.g., 1000 = 4 digits, 100 is three digits, and so forth.
    FormatSpecifier = sprintf('%%%dg', NumDigits);
    FrameString = sprintf('Frame #%s', sprintf(FormatSpecifier, MaxDisplFrameNumber));
    TrackingInfoTXT = sprintf('mode=%s. highRes=%g. addNonLocMaxBeads=%d. trackSuccessively=%d. alpha=%0.3f, minCorLength=%g, maxFlowSpeed=%g. useGrid=%g. lastToFirst=%g. noFlowOutwardOnBorder=%d.', ...
        displacementParameters.mode,displacementParameters.highRes, displacementParameters.addNonLocMaxBeads,displacementParameters.trackSuccessively, displacementParameters.alpha, ...
        displacementParameters.minCorLength,displacementParameters.maxFlowSpeed, displacementParameters.useGrid, displacementParameters.lastToFirst, displacementParameters.noFlowOutwardOnBorder);
    TrackingInfoTXT = sprintf('%s\nMaxDisplNetMicrons=%0.3f %s in %s @ [%0.3f, %0.3f] pix. Spatially corrected: outlierThreshold = %g. Low-pass Equirriples temporal filter.', ...
        TrackingInfoTXT, MaxDisplNetMicrons(3), sprintf('%sm', char(181)), FrameString, MaxDispl_PosXY_Pixels, CorrectionfunParams.outlierThreshold); 
    videoImages = cell(FramesNumEPI, 1);
    diary off
    parfor_progress(numel(FramesDoneNumbers), displFieldPath);
    parfor CurrentFrame = FramesDoneNumbersEPI
            videoImages{CurrentFrame} = plotDisplacementOverlaysBeadsParfor(MD_EPI,displField,CurrentFrame, MD_EPI_ChannelCount, FluoroSphereSizePixel, ...
                QuiverColor, colormapLUT_TxRed, GrayLevelsPercentile, FramesNumEPI, ScaleLength_EPI, ScaleMicronPerPixel_EPI, TimeStampsRT_Abs_EPI, FluxStatusString{CurrentFrame}, ...
                TrackingInfoTXT, scalebarFontSize, useGPU, MaxDisplNetPixels); 
            parfor_progress(-1, displFieldPath);
    end
    parfor_progress(0, displFieldPath);
    diary on
    disp("2.2 Creating frames COMPLETE!") 

    disp("2.3 Writing  frames IN PROGRESS") 
    open(VideoWriterObj1)
    open(VideoWriterObj3)        
    diary off
    parfor_progress(numel(FramesDoneNumbers), displFieldPath);
    for CurrentFrame = FramesDoneNumbersEPI 
        writeVideo(VideoWriterObj1,  videoImages{CurrentFrame})
        writeVideo(VideoWriterObj3,  videoImages{CurrentFrame})
        parfor_progress(-1, displFieldPath);
    end
    parfor_progress(0, displFieldPath);
    diary on
    close(VideoWriterObj1)
    close(VideoWriterObj3)
    disp("2.3 Writing  frames COMPLETE!") 
    fprintf('Saved as: \n\t%s\n', VideoFullFileName1)
%     winopen(VideoPathName1)
%     winopen(CombinedAnalysisPath)
    disp('----------------------------------------------------------------------------------------------------------------')
    clear videoImages 

%% Video 3: displacement field corrected + LPEF + DC (vectors)
    if isempty(gcp('nocreate')), localcluster.parpool;end
    load(displacementFileFullNameLPEFDC, 'displField');                % at this point. displField_LPEF_DC.mat is the default file
    fprintf('3.0 Displacement Field (displField) File is successfully loaded!:\n\t%s\n', displacementFileFullNameLPEFDC);

    FramesDoneIdx = ~arrayfun(@(x)isempty(displField(x).pos),1:numel(displField));
    FramesNumbersAll = 1:numel(FramesDoneIdx);
    FramesDoneNumbersEPI = FramesNumbersAll(FramesDoneIdx);
    FramesNumEPI = min([numel(FramesDoneNumbersEPI), numel(displField), numel(FluxON)]) ;
    FramesNumbersAll = FramesNumbersAll(1:FramesNumEPI);
    FramesDoneIdx = FramesDoneIdx(1:FramesNumEPI);
    FramesDoneNumbersEPI = FramesNumbersAll(FramesDoneIdx);
    FluxON = FluxON(1:FramesNumEPI);
    FluxOFF = FluxOFF(1:FramesNumEPI);   
    FramesDoneNumbersONTrans = FramesDoneNumbersEPI(FluxON(FramesDoneIdx) | FluxTransient(FramesDoneIdx));
    FluxStatusString = cell(FramesNumEPI, 1);
    FluxStatusString(FluxON(FramesDoneNumbersEPI)) = {'Flux ON'};
    FluxStatusString(FluxOFF(FramesDoneNumbersEPI)) = {'Flux OFF'};
    FluxStatusString(FluxTransient(FramesDoneNumbersEPI)) = {'Flux TRANS'};    

    [VideoPathName1, VideoFileNameSuffix, ~] = fileparts(displacementFileFullNameLPEFDC);   
    VideoFileName = strcat(VideoFileNameSuffix, '_vectors');
    VideoFullFileName1 = fullfile(VideoPathName1, VideoFileName);
    VideoWriterObj1 = VideoWriter(VideoFullFileName1, VideoType1);
    VideoWriterObj1.LosslessCompression = true;
    VideoWriterObj1.FrameRate = FrameRateRT_EPI; 
    displFieldPath = VideoPathName1;
    VideoFullFileName3 = fullfile(CombinedAnalysisPath, VideoFileName);
    VideoWriterObj3 = VideoWriter(VideoFullFileName3, VideoType3);
    VideoWriterObj3.FrameRate = FrameRateRT_EPI; 
    fprintf("-------- Video 3. **** %s **** ------------------\n%s", VideoWriterObj1.Filename)

    % 2. Covnert only displacements (.vec) to microns. Keep Starting positions in pixels. Keep the same structure
    disp('3.0 Calculating displacements in microns IN PROGRESS')
    diary off
    parfor_progress(numel(FramesDoneNumbers), displFieldPath);    
    parfor CurrentFrame = FramesDoneNumbersEPI
          displFieldMicron(CurrentFrame).pos = displField(CurrentFrame).pos;             % pixels
          displFieldMicron(CurrentFrame).vec = displField(CurrentFrame).vec * ScaleMicronPerPixel_EPI;
          parfor_progress(-1, displFieldPath);
    end
    parfor_progress(0, displFieldPath);
    diary on
    disp('3.0 Calculating displacements in microns COMPLETE')
    
    disp('3.1 Finding the bead with the maximum displacement in ON/Transient frames IN PROGRESS')
    dmaxTMP = nan(FramesNumEPI, 1);
    dmaxTMPindex = nan(FramesNumEPI, 1);
    diary off
    parfor_progress(numel(FramesDoneNumbersEPI), displFieldPath);
    parfor CurrentFrame = FramesDoneNumbersEPI
        dnorm_vec = vecnorm(displField(CurrentFrame).vec(:,1:2), 2,2);  
        if useGPU, dnorm_vec = gpuArray(dnorm_vec); end
        displField(CurrentFrame).vec(:,3)  = dnorm_vec;
        dmaxTMP(CurrentFrame) = max(dnorm_vec);
        [~, IdxTMP] = max(dnorm_vec);
        dmaxTMPindex(CurrentFrame) = IdxTMP;
        parfor_progress(-1, displFieldPath);
        dnorm_vec = [];
        IdxTMP = [];
    end
    parfor_progress(0, displFieldPath);
    clear dnorm_vec  IdxTMP IdxTMP
    diary on
    [~, MaxDisplFrameNumber]  = max(dmaxTMP);
    MaxDisplFieldIndex = dmaxTMPindex(MaxDisplFrameNumber);
    MaxDispl_PosXY_Pixels =  displField(MaxDisplFrameNumber).pos(MaxDisplFieldIndex,:);
    MaxDisplNetPixels = displField(MaxDisplFrameNumber).vec(MaxDisplFieldIndex,:);
    MaxDisplNetMicrons =  MaxDisplNetPixels .* ScaleMicronPerPixel_EPI;
    fprintf('[x,y] = [%0.3f, %0.3f] pixels in Frame #%d, Point Index #%d \n', MaxDispl_PosXY_Pixels, MaxDisplFrameNumber, MaxDisplFieldIndex)
    fprintf('Maximum displacement [disp_x, disp_y] =  [%0.3f, %0.3f] pixels  \t==> Net displacement [disp_net] = [%0.3f] pixels. \n', MaxDisplNetPixels)
    fprintf('Maximum displacement [disp_x, disp_y] =  [%0.3f, %0.3f] %s      \t==> Net displacement [disp_net] = [%0.3f] %s. \n', ...
        MaxDisplNetMicrons(1:2), displUnit, MaxDisplNetMicrons(3) , displUnit)
    disp('3.1 Finding the bead with the maximum displacement in ON/Transient frames COMPLETE')

    delete(gcp('nocreate'));
    if isempty(gcp('nocreate')), localcluster.parpool;end

    AvgInterBeadDist = sqrt(TotalAreaPixel/totalBeadsTracked);        % avg inter-bead separation distance = total img area/number of tracked points
    QuiverScaleDefault = 0.95 * (AvgInterBeadDist/MaxDisplNetPixels(3)) * QuiverMagnificationFactor;    
    QuiverScaleToMax = QuiverScaleDefault * QuiverMagnificationFactor; 

    disp("3.2 Creating frames IN PROGRESS") 
    colormapLUT_TxRed = [linspace(0,1,GrayLevels)', zeros(GrayLevels,2)];    % Texas Red LUT
    QuiverColor = median(imcomplement(colormapLUT_TxRed));                   % User Complement of the colormap for maximum visibililty of the quiver.
    NumDigits = numel(num2str(FramesNumEPI));                                % counting the number of digits in the number of frames. E.g., 1000 = 4 digits, 100 is three digits, and so forth.
    FormatSpecifier = sprintf('%%%dg', NumDigits);
    FrameString = sprintf('Frame #%s', sprintf(FormatSpecifier, MaxDisplFrameNumber));
    TrackingInfoTXT = sprintf('mode=%s. highRes=%g. addNonLocMaxBeads=%d. trackSuccessively=%d. alpha=%0.3f, minCorLength=%g, maxFlowSpeed=%g. useGrid=%g. lastToFirst=%g. noFlowOutwardOnBorder=%d.', ...
        displacementParameters.mode,displacementParameters.highRes, displacementParameters.addNonLocMaxBeads,displacementParameters.trackSuccessively, displacementParameters.alpha, ...
        displacementParameters.minCorLength,displacementParameters.maxFlowSpeed, displacementParameters.useGrid, displacementParameters.lastToFirst, displacementParameters.noFlowOutwardOnBorder);
    TrackingInfoTXT = sprintf('%s\nMaxDisplNetMicrons=%0.3f %s in %s @ [%0.3f, %0.3f] pix. Spatial outlierThreshold=%g. Low-pass Equirriples temporal filter. Drift-corrected', ...
        TrackingInfoTXT, MaxDisplNetMicrons(3), sprintf('%sm', char(181)), FrameString, MaxDispl_PosXY_Pixels, CorrectionfunParams.outlierThreshold); 
   
    localcluster = gcp;
    TotalNumWorkers = localcluster.NumWorkers;
    
    videoImages = cell(FramesNumEPI, 1);
    diary off
    parfor_progress(numel(FramesDoneNumbers), displFieldPath);
    parfor CurrentFrame = FramesDoneNumbersEPI                                    % BUG: Memory leak causing parfor to crashing. Using regular for for now. 
            videoImages{CurrentFrame} = plotDisplacementOverlaysVectorsParfor(MD_EPI,displField,CurrentFrame, MD_EPI_ChannelCount, QuiverScaleToMax, ...
                QuiverColor, colormapLUT_TxRed, GrayLevelsPercentile, FramesNumEPI, ScaleLength_EPI, ScaleMicronPerPixel_EPI, TimeStampsRT_Abs_EPI, ...
                FluxStatusString{CurrentFrame}, TrackingInfoTXT, scalebarFontSize, useGPU, MaxDisplNetPixels, DriftROI_rect); 
            parfor_progress(-1, displFieldPath); 
    end
    parfor_progress(0, displFieldPath);
    diary on
    disp("3.2 Creating frames COMPLETE!") 

    disp("3.2 Writing  frames IN PROGRESS") 
    open(VideoWriterObj1)
    open(VideoWriterObj3)        
    diary off
    parfor_progress(numel(FramesDoneNumbers), displFieldPath);
    for CurrentFrame = FramesDoneNumbersEPI 
        writeVideo(VideoWriterObj1,  videoImages{CurrentFrame})
        writeVideo(VideoWriterObj3,  videoImages{CurrentFrame})
        parfor_progress(-1, displFieldPath);
    end
    parfor_progress(0, displFieldPath);
    diary on
    close(VideoWriterObj1)
    close(VideoWriterObj3)
    disp("3.3 Writing  frames COMPLETE!") 
    fprintf('Saved as: \n\t%s\n', VideoFullFileName1)
%     winopen(VideoPathName1)
%     winopen(CombinedAnalysisPath)
    disp('----------------------------------------------------------------------------------------------------------------')
    clear videoImages 
    
%% Video 4: displacement field corrected + LPEF + DC (heatmap)       
    if isempty(gcp('nocreate')), localcluster.parpool;end
    disp('----------------------------------------------------------------------------------------------------------------')
    load(displacementFileFullNameLPEFDC, 'displField');                % at this point. displField_LPEF_DC.mat is the default file
    fprintf('3.0 Displacement Field (displField) File is successfully loaded!:\n\t%s\n', displacementFileFullNameLPEFDC);

    FramesDoneIdx = ~arrayfun(@(x)isempty(displField(x).pos),1:numel(displField));
    FramesNumbersAll = 1:numel(FramesDoneIdx);
    FramesDoneNumbersEPI = FramesNumbersAll(FramesDoneIdx);
    FramesNumEPI = min([numel(FramesDoneNumbersEPI), numel(displField), numel(FluxON)]) ;
    FramesNumbersAll = FramesNumbersAll(1:FramesNumEPI);
    FramesDoneIdx = FramesDoneIdx(1:FramesNumEPI);
    FramesDoneNumbersEPI = FramesNumbersAll(FramesDoneIdx);
    FluxON = FluxON(1:FramesNumEPI);
    FluxOFF = FluxOFF(1:FramesNumEPI);   
    FramesDoneNumbersONTrans = FramesDoneNumbersEPI(FluxON(FramesDoneIdx) | FluxTransient(FramesDoneIdx));
    FluxStatusString = cell(FramesNumEPI, 1);
    FluxStatusString(FluxON(FramesDoneNumbersEPI)) = {'Flux ON'};
    FluxStatusString(FluxOFF(FramesDoneNumbersEPI)) = {'Flux OFF'};
    FluxStatusString(FluxTransient(FramesDoneNumbersEPI)) = {'Flux TRANS'};    

    [VideoPathName1, VideoFileNameSuffix, ~] = fileparts(displacementFileFullNameLPEFDC);   
    displFieldPath = VideoPathName1;
    VideoFileName = strcat(VideoFileNameSuffix, '_heatmap');
    VideoFullFileName1 = fullfile(VideoPathName1, VideoFileName);
    VideoWriterObj1 = VideoWriter(VideoFullFileName1, VideoType1);
    VideoWriterObj1.LosslessCompression = true;
    VideoWriterObj1.FrameRate = FrameRateRT_EPI; 
    VideoFullFileName3 = fullfile(CombinedAnalysisPath, VideoFileName);
    VideoWriterObj3 = VideoWriter(VideoFullFileName3, VideoType3);
    VideoWriterObj3.FrameRate = FrameRateRT_EPI; 
    fprintf("-------- Video 4. **** %s **** ------------------\n%s", VideoWriterObj1.Filename)

    [grid_mat, ~,~,~] = interp_vec2grid(displField(RefFrameNumEPI).pos(:,1:2), displField(RefFrameNumEPI).vec(:,1:2) ,[], reg_grid, InterpolationMethod);
    grid_mat = gpuArray(grid_mat);
    grid_matX = grid_mat(:,:,1);
    grid_matY = grid_mat(:,:,2);
    grid_spacingX = grid_mat(1,2,1)- grid_mat(1,1,1);
    grid_spacingY = grid_mat(2,1,2)- grid_mat(1,1,2);        
    imSizeX = (grid_mat(end,end,1) - grid_mat(1,1,1)) + grid_spacingX;
    imSizeY = (grid_mat(end,end,2) - grid_mat(1,1,2)) + grid_spacingY;    
    centerX = ((grid_mat(end,end,1) + grid_mat(1,1,1))/2);
    centerY = ((grid_mat(end,end,2) + grid_mat(1,1,2))/2);
    Xmin = centerX - imSizeX/2 + bandSize;
    Xmax = centerX + imSizeX/2 - bandSize;
    Ymin = centerY - imSizeY/2 + bandSize;
    Ymax = centerY + imSizeY/2 - bandSize;               
    [XI,YI] = ndgrid(Xmin:Xmax,Ymin:Ymax);                % Addded on 2019-10-10 to go with gridded interpolant, the line above is for griddata
%     XI = gather(XI);
%     YI = gather(YI);            
    reg_gridFull(:,:,1)  = XI; reg_gridFull(:,:,2)  = YI;

    % 2. Covnert only displacements (.vec) to microns. Keep Starting positions in pixels. Keep the same structure
    disp('4.0 Calculating displacements in microns IN PROGRESS')
    diary off
    parfor_progress(numel(FramesDoneNumbers), displFieldPath);    
    parfor CurrentFrame = FramesDoneNumbersEPI
          displFieldMicron(CurrentFrame).pos = displField(CurrentFrame).pos;             % pixels
          displFieldMicron(CurrentFrame).vec = displField(CurrentFrame).vec * ScaleMicronPerPixel_EPI;
          parfor_progress(-1, displFieldPath);
    end
    parfor_progress(0, displFieldPath);
    diary on
    disp('4.0 Calculating displacements in microns COMPLETE')

    disp('4.1 Finding the pixel with the maximum displacement in ON/Transient frames IN PROGRESS')    
    dmaxTMPgrid = nan(FramesNumEPI, 1);
    dmaxTMPindex = nan(FramesNumEPI, 1);
    diary off
    parfor_progress(numel(FramesDoneNumbers), displFieldPath);
    parfor CurrentFrame=FramesDoneNumbersEPI
        if find(FramesDoneNumbersONTrans == CurrentFrame)
            %Load the saved body heat map.
            [~, displVecGridXY,~,~] = interp_vec2grid(displField(CurrentFrame).pos(:,1:2), displField(CurrentFrame).vec(:,1:2) ,[], reg_gridFull, InterpolationMethod);         
            displVecGridXY = gpuArray(displVecGridXY);
            d_norm = (displVecGridXY(:,:,1).^2 + displVecGridXY(:,:,2).^2).^0.5;
                % Boundary cutting - I'll take care of this boundary effect later
            if band > 2
                d_norm(end-(round(band/2)+1:end),:)=[];
                d_norm(:,end-(round(band/2)+1:end))=[];
                d_norm(1:(round(band/2)-1),:)=[];
                d_norm(:,1:(round(band/2)-1))=[];
            end
            d_norm_vec = reshape(d_norm,[],1); 
    
            [dmaxTMPgrid(CurrentFrame), dmaxTMPindex(CurrentFrame)] = max(d_norm_vec);
        end
        parfor_progress(-1, displFieldPath);
    end
    parfor_progress(0, displFieldPath);
    diary on
    [dmaxPixGridFine, MaxDisplFrameNumber] = max(dmaxTMPgrid(:,1));
    dmaxMicronsFine = dmaxPixGridFine  * ScaleMicronPerPixel_EPI;
    MaxDisplFieldIndex = dmaxTMPindex(MaxDisplFrameNumber);
    [~, displVecGridXY,~,~] = interp_vec2grid(displField(MaxDisplFrameNumber).pos(:,1:2), displField(MaxDisplFrameNumber).vec(:,1:2) ,[], reg_gridFull, InterpolationMethod);         
    if useGPU, displVecGridXY = gpuArray(displVecGridXY); end
    d_norm = (displVecGridXY(:,:,1).^2 + displVecGridXY(:,:,2).^2).^0.5;
    if band > 2
            d_norm(end-(round(band/2)+1:end),:)=[];
            d_norm(:,end-(round(band/2)+1:end))=[];
            d_norm(1:(round(band/2)-1),:)=[];
            d_norm(:,1:(round(band/2)-1))=[];
            XI(end-(round(band/2)+1:end),:)=[];
            XI(:,end-(round(band/2)+1:end))=[];
            XI(1:(round(band/2)-1),:)=[];
            XI(:,1:(round(band/2)-1))=[];
            YI(end-(round(band/2)+1:end),:)=[];
            YI(:,end-(round(band/2)+1:end))=[];
            YI(1:(round(band/2)-1),:)=[];
            YI(:,1:(round(band/2)-1))=[];      
    end
    MaxDisplFieldIndexXY(1,1) = XI(MaxDisplFieldIndex);
    MaxDisplFieldIndexXY(1,2) = YI(MaxDisplFieldIndex);
    if useGPU, MaxDisplFieldIndexXY = gather(MaxDisplFieldIndexXY); end
    d_norm_vec = reshape(d_norm,[],1); 
    [MaxDispl_PosXY_Pixels(1,1), MaxDispl_PosXY_Pixels(1,2)] =  ind2sub(size(d_norm), MaxDisplFieldIndex);
    MaxDisplNetPixels = [displVecGridXY(MaxDispl_PosXY_Pixels(1),MaxDispl_PosXY_Pixels(2),1), displVecGridXY(MaxDispl_PosXY_Pixels(1),MaxDispl_PosXY_Pixels(2),2), dmaxPixGridFine];
    MaxDisplNetMicrons = MaxDisplNetPixels * ScaleMicronPerPixel_EPI;    
    fprintf('[x,y] = [%0.3f, %0.3f] pixels in Frame #%d, Point Index #%d \n', MaxDisplFieldIndexXY, MaxDisplFrameNumber, MaxDisplFieldIndex)
    fprintf('Maximum displacement [disp_x, disp_y] =  [%0.3f, %0.3f] pixels  \t==> Net displacement [disp_net] = [%0.3f] pixels. \n', MaxDisplNetPixels)
    fprintf('Maximum displacement [disp_x, disp_y] =  [%0.3f, %0.3f] %s      \t==> Net displacement [disp_net] = [%0.3f] %s. \n', ...
        MaxDisplNetMicrons(1:2), displUnit, MaxDisplNetMicrons(3) , displUnit)
    disp('4.1 Finding the pixel with the maximum displacement in ON/Transient frames COMPLETE')  

    disp("4.2 Creating frames IN PROGRESS") 
    QuiverMagnificationFactor = 1;
    colormapLUT_TxRed = [linspace(0,1,GrayLevels)', zeros(GrayLevels,2)];    % Texas Red LUT
    totaGridPoints = size(reg_grid,1)*size(reg_grid,2);
    AvgInterBeadDist = sqrt(TotalAreaPixel/totaGridPoints);        % avg inter-bead separation distance = total img area/number of tracked points
    QuiverScaleDefault = 0.95 * (AvgInterBeadDist/dmaxMicronsFine) * QuiverMagnificationFactor;    
    QuiverScaleToMax = QuiverScaleDefault * QuiverMagnificationFactor; 
    colormapLUT_parula = parula(GrayLevels);
    QuiverColor = median(imcomplement(colormapLUT_parula));      
    colorbarLimits = [0, dmaxMicronsFine];
    NumDigits = numel(num2str(FramesNumEPI));            %counting the number of digits in the number of frames. E.g., 1000 = 4 digits, 100 is three digits, and so forth.
    FormatSpecifier = sprintf('%%%dg', NumDigits);
    FrameString = sprintf('Frame #%s', sprintf(FormatSpecifier, MaxDisplFrameNumber));
    TrackingInfoTXT = sprintf('(%dx%d) grid pts (%d pix spacing). %s interp. %s', size(reg_grid,1:2) , gridSpacing, InterpolationMethod, TractionStressMethod);
    TrackingInfoTXT = sprintf('%s %s (%dx%d) pix. Han window %s. %s.', TrackingInfoTXT, SpatialFilterChoiceStr, WienerWindowSize, PaddingChoiceStr, reg_cornerChoiceStr ) ;
    TrackingInfoTXT = sprintf('%s\nMaxDisplNetMicrons=%0.3f %s in %s @ [%0.3f, %0.3f] pix.', TrackingInfoTXT, MaxDisplNetMicrons(3), sprintf('%sm', char(181)), FrameString, ...
        MaxDisplFieldIndexXY); 
    if ~isempty(TimeFilterChoiceStr), TrackingInfoTXT = sprintf('%s %s.', TrackingInfoTXT,TimeFilterChoiceStr);end
    if ~isempty(DriftCorrectionChoiceStr), TrackingInfoTXT = sprintf('%s %s.', TrackingInfoTXT,DriftCorrectionChoiceStr);end 
    parfor_progressPath = displFieldPath;
    diary off
    videoImages = cell(FramesNumEPI, 1);
    parfor_progress(numel(FramesDoneNumbers), parfor_progressPath);
    parfor CurrentFrame = FramesDoneNumbersEPI
        videoImages{CurrentFrame} = plotDisplacementHeatmapsVectorParfor(MD_EPI,displFieldMicron, CurrentFrame, QuiverScaleToMax, ...
            QuiverColor, colormapLUT_parula, TrackingInfoTXT, FramesNumEPI, ScaleLength_EPI, ScaleMicronPerPixel_EPI, TimeStampsRT_Abs_EPI, FluxStatusString{CurrentFrame}, ...
            reg_grid, InterpolationMethod, bandSize, colorbarLimits, colorbarFontSize,useGPU, MaxDisplNetPixels)
        parfor_progress(-1, parfor_progressPath);
    end
    parfor_progress(0, parfor_progressPath);
    diary on
    disp("4.2 Creating frames COMPLETE!") 
    disp("4.2 Writing  frames IN PROGRESS") 
    open(VideoWriterObj1)
    open(VideoWriterObj3)        
    diary off
    parfor_progress(numel(FramesDoneNumbers), displFieldPath);
    for CurrentFrame = FramesDoneNumbersEPI 
        writeVideo(VideoWriterObj1,  videoImages{CurrentFrame})
        writeVideo(VideoWriterObj3,  videoImages{CurrentFrame})
        parfor_progress(-1, displFieldPath);
    end
    parfor_progress(0, displFieldPath);
    diary on
    close(VideoWriterObj1)
    close(VideoWriterObj3)
    disp("4.2 Writing  frames COMPLETE!") 
    fprintf('Saved as: \n\t%s\n', VideoFullFileName1)
%     winopen(VideoPathName1)
%     winopen(CombinedAnalysisPath)
    disp('----------------------------------------------------------------------------------------------------------------')
    clear videoImages;

    delete(gcp('nocreate'));
    if isempty(gcp('nocreate')), localcluster.parpool;end

    disp("4.3 Creating ROI frames IN PROGRESS") 
    QuiverMagnificationFactor = 2;
    totaGridPoints = size(reg_grid,1)*size(reg_grid,2);
    AvgInterBeadDist = sqrt(TotalAreaPixel/totaGridPoints);        % avg inter-bead separation distance = total img area/number of tracked points    
    QuiverScaleDefault = 0.95 * (AvgInterBeadDist/dmaxMicronsFine) * QuiverMagnificationFactor;    
    QuiverScaleToMax = QuiverScaleDefault * QuiverMagnificationFactor; 
    colormapLUT_parula = parula(GrayLevels);
    QuiverColor = median(imcomplement(colormapLUT_parula));      
    colorbarLimits = [0, dmaxMicronsFine];
    NumDigits = numel(num2str(FramesNumEPI));            %counting the number of digits in the number of frames. E.g., 1000 = 4 digits, 100 is three digits, and so forth.
    FormatSpecifier = sprintf('%%%dg', NumDigits);
    FrameString = sprintf('Frame #%s', sprintf(FormatSpecifier, MaxDisplFrameNumber));
    diary off
    TrackingInfoTXT = '';
    videoImages = cell(FramesNumEPI, 1);
    parfor_progressPath = displFieldPath;
    parfor_progress(numel(FramesDoneNumbers), parfor_progressPath);
    parfor CurrentFrame = FramesDoneNumbersEPI
        videoImages{CurrentFrame} = plotDisplacementHeatmapsVectorParforROI(MD_EPI,displFieldMicron, CurrentFrame, QuiverScaleToMax, ...
            QuiverColor, colormapLUT_parula, TrackingInfoTXT, FramesNumEPI, ScaleLength_EPI, ScaleMicronPerPixel_EPI, TimeStampsRT_Abs_EPI, FluxStatusString{CurrentFrame}, ...
            reg_grid, InterpolationMethod, bandSize, colorbarLimits, colorbarFontSize,useGPU, MaxDisplNetPixels, ROIsideSizeMicron, ROIMagnificationFactor)
        parfor_progress(-1, parfor_progressPath);
    end
    parfor_progress(0, parfor_progressPath);
    diary on
    disp("4.3 Creating ROI frames COMPLETE!") 
    disp("4.3 Writing  ROI frames IN PROGRESS") 
    VideoFileName = strcat(VideoFileNameSuffix, '_ROI_heatmap');
    VideoFullFileName1 = fullfile(VideoPathName1, VideoFileName);
    VideoWriterObj1 = VideoWriter(VideoFullFileName1, VideoType1);
    VideoWriterObj1.LosslessCompression = true;
    VideoWriterObj1.FrameRate = FrameRateRT_EPI; 
    VideoFullFileName3 = fullfile(CombinedAnalysisPath, VideoFileName);
    VideoWriterObj3 = VideoWriter(VideoFullFileName3, VideoType3);
    VideoWriterObj3.FrameRate = FrameRateRT_EPI;     
    displFieldPath = VideoPathName1;
    fprintf("-------- Video 2 ROI. **** %s **** ------------------\n%s", VideoWriterObj1.Filename)
    open(VideoWriterObj1)
    open(VideoWriterObj3)        
    diary off
    parfor_progress(numel(FramesDoneNumbers), displFieldPath);
    for CurrentFrame = FramesDoneNumbersEPI 
        writeVideo(VideoWriterObj1,  videoImages{CurrentFrame})
        writeVideo(VideoWriterObj3,  videoImages{CurrentFrame})
        parfor_progress(-1, displFieldPath);
    end
    parfor_progress(0, displFieldPath);
    diary on
    close(VideoWriterObj1)
    close(VideoWriterObj3)
    disp("4.3 Writing  frames COMPLETE!") 
    fprintf('Saved as: \n\t%s\n', VideoFullFileName1)
%     winopen(VideoPathName1)
%     winopen(CombinedAnalysisPath)
    disp('----------------------------------------------------------------------------------------------------------------')
    clear videoImages;   
    delete(gcp('nocreate')) 

%% Video 5: traction stress field from grid from displ outliercorrection, LPEF, DC (heatmap) 
    delete(gcp('nocreate'));
    if isempty(gcp('nocreate')), localcluster.parpool;end
    disp('------------------------------------------------------------------------------')
    load(forceFieldFullFileName, 'forceField')
    [VideoPathName1, VideoFileNameSuffix, ~] = fileparts(forceFieldFullFileName);   
    fprintf('Traction Field (forceField) File is successfully loaded!:\n\t%s\n', forceFieldFullFileName);

    FramesDoneIdx = ~arrayfun(@(x)isempty(forceField(x).pos),1:numel(forceField));
    FramesNumbersAll = 1:numel(FramesDoneIdx);
    FramesDoneNumbersEPI = FramesNumbersAll(FramesDoneIdx);
    FramesNumEPI = min([numel(FramesDoneNumbersEPI), numel(forceField), numel(FluxON)]) ;
    FramesNumbersAll = FramesNumbersAll(1:FramesNumEPI);
    FramesDoneIdx = FramesDoneIdx(1:FramesNumEPI);
    FramesDoneNumbersEPI = FramesNumbersAll(FramesDoneIdx);
    FluxON = FluxON(1:FramesNumEPI);
    FluxOFF = FluxOFF(1:FramesNumEPI);   
    FramesDoneNumbersONTrans = FramesDoneNumbersEPI(FluxON(FramesDoneIdx) | FluxTransient(FramesDoneIdx));
    FluxStatusString = cell(FramesNumEPI, 1);
    FluxStatusString(FluxON(FramesDoneNumbersEPI)) = {'Flux ON'};
    FluxStatusString(FluxOFF(FramesDoneNumbersEPI)) = {'Flux OFF'};
    FluxStatusString(FluxTransient(FramesDoneNumbersEPI)) = {'Flux TRANS'};    


    VideoFileName = strcat(VideoFileNameSuffix, '_heatmap');
    VideoFullFileName1 = fullfile(VideoPathName1, VideoFileName);
    VideoWriterObj1 = VideoWriter(VideoFullFileName1, VideoType1);
    VideoWriterObj1.LosslessCompression = true;
    VideoWriterObj1.FrameRate = FrameRateRT_EPI; 
    VideoFullFileName3 = fullfile(CombinedAnalysisPath, VideoFileName);
    VideoWriterObj3 = VideoWriter(VideoFullFileName3, VideoType3);
    VideoWriterObj3.FrameRate = FrameRateRT_EPI;     
    forceFieldPath = VideoPathName1;
    fprintf("-------- Video 5. **** %s **** ------------------\n%s", VideoWriterObj1.Filename)

    [grid_mat, ~,~,~] = interp_vec2grid(forceField(RefFrameNumEPI).pos(:,1:2), forceField(RefFrameNumEPI).vec(:,1:2) ,[], reg_grid, InterpolationMethod);
    grid_mat = gpuArray(grid_mat);
    grid_matX = grid_mat(:,:,1);
    grid_matY = grid_mat(:,:,2);
    grid_spacingX = grid_mat(1,2,1)- grid_mat(1,1,1);
    grid_spacingY = grid_mat(2,1,2)- grid_mat(1,1,2);        
    imSizeX = (grid_mat(end,end,1) - grid_mat(1,1,1)) + grid_spacingX;
    imSizeY = (grid_mat(end,end,2) - grid_mat(1,1,2)) + grid_spacingY;    
    centerX = ((grid_mat(end,end,1) + grid_mat(1,1,1))/2);
    centerY = ((grid_mat(end,end,2) + grid_mat(1,1,2))/2);
    Xmin = centerX - imSizeX/2 + bandSize;
    Xmax = centerX + imSizeX/2 - bandSize;
    Ymin = centerY - imSizeY/2 + bandSize;
    Ymax = centerY + imSizeY/2 - bandSize;               
    [XI,YI] = ndgrid(Xmin:Xmax,Ymin:Ymax);                % Addded on 2019-10-10 to go with gridded interpolant, the line above is for griddata       
    reg_gridFull(:,:,1)  = XI; reg_gridFull(:,:,2)  = YI;

    disp('5.1 Finding the pixel with the maximum traction stress in ON/Transient frames IN PROGRESS')
    QuiverMagnificationFactor = 1;
    FramesNumEPI = numel(forceField);
    FramesDoneNumbers = 1:FramesNumEPI;
    tmaxTMPgrid = nan(FramesNumEPI, 1);
    tminTMPgrid = nan(FramesNumEPI, 1);
    diary off
    parfor_progressPath = forceFieldPath;
    parfor_progress(numel(FramesDoneNumbers), parfor_progressPath);
    parfor CurrentFrame=FramesDoneNumbersEPI
%         if find(FramesDoneNumbersONTrans == CurrentFrame) 
            [~, stressFieldGridXY,~,~] = interp_vec2grid(forceField(CurrentFrame).pos(:,1:2), forceField(CurrentFrame).vec(:,1:2) ,[], reg_gridFull, InterpolationMethod);         
            stressFieldGridXY = gpuArray(stressFieldGridXY);
            t_norm = (stressFieldGridXY(:,:,1).^2 + stressFieldGridXY(:,:,2).^2).^0.5;
            if band > 2
                t_norm(end-(round(band/2)+1:end),:)=[];
                t_norm(:,end-(round(band/2)+1:end))=[];
                t_norm(1:(round(band/2)-1),:)=[];
                t_norm(:,1:(round(band/2)-1))=[];
            end
            t_norm_vec = reshape(t_norm,[],1); 
            [tmaxTMPgrid(CurrentFrame), tmaxTMPindex(CurrentFrame)] = max(t_norm_vec);
%         end
        parfor_progress(-1, parfor_progressPath);
    end
    parfor_progress(0, parfor_progressPath);
    diary on
    [tmaxPaGridFine, MaxTractionFrameNumber] = max(tmaxTMPgrid(:,1));
    tmaxMicronsFine = tmaxPaGridFine  * ScaleMicronPerPixel_EPI;
    MaxTractionFieldIndex = tmaxTMPindex(MaxTractionFrameNumber);
    [~, stressFieldGridXY,~,~] = interp_vec2grid(forceField(MaxTractionFrameNumber).pos(:,1:2), forceField(MaxTractionFrameNumber).vec(:,1:2) ,[], reg_gridFull, InterpolationMethod);         
        stressFieldGridXY = gpuArray(stressFieldGridXY);
    t_norm = (stressFieldGridXY(:,:,1).^2 + stressFieldGridXY(:,:,2).^2).^0.5;
    if band > 2
            t_norm(end-(round(band/2)+1:end),:)=[];
            t_norm(:,end-(round(band/2)+1:end))=[];
            t_norm(1:(round(band/2)-1),:)=[];
            t_norm(:,1:(round(band/2)-1))=[];
            XI(end-(round(band/2)+1:end),:)=[];
            XI(:,end-(round(band/2)+1:end))=[];
            XI(1:(round(band/2)-1),:)=[];
            XI(:,1:(round(band/2)-1))=[];
            YI(end-(round(band/2)+1:end),:)=[];
            YI(:,end-(round(band/2)+1:end))=[];
            YI(1:(round(band/2)-1),:)=[];
            YI(:,1:(round(band/2)-1))=[];      
    end
    MaxTractionFieldIndexXY(1,1) = XI(MaxTractionFieldIndex);
    MaxTractionFieldIndexXY(1,2) = YI(MaxTractionFieldIndex);
    t_norm_vec = reshape(t_norm,[],1); 
    [MaxTraction_PosXY_Pixels(1,1), MaxTraction_PosXY_Pixels(1,2)] =  ind2sub(size(t_norm), MaxTractionFieldIndex);
    MaxTractionNetPa = [stressFieldGridXY(MaxTraction_PosXY_Pixels(1),MaxTraction_PosXY_Pixels(2),1), stressFieldGridXY(MaxTraction_PosXY_Pixels(1),MaxTraction_PosXY_Pixels(2),2), tmaxPaGridFine];
    fprintf('[x,y] = [%0.3f, %0.3f] pixels in Frame #%d, Point Index #%d \n', MaxTractionFieldIndexXY, MaxTractionFrameNumber, MaxTractionFieldIndex)
    fprintf('Maximum traction stress [stress_x, stress_y] =  [%0.3f, %0.3f] %s  ==> Net traction stress [stress_net] = [%0.3f] %s. \n', ...
        MaxTractionNetPa(1:2), tractionUnit, MaxTractionNetPa(3) , tractionUnit)
    QuiverScaleDefault = 0.95 * (gridSpacing/MaxTractionNetPa(3));
    QuiverScaleToMax = QuiverScaleDefault * QuiverMagnificationFactor;      
    disp('5.1 Finding the pixel with the maximum traction stress in ON/Transient frames COMPLETE!')
    disp("5.2 Creating frames IN PROGRESS") 
    QuiverMagnificationFactor = 1;
    totaGridPoints = size(reg_grid,1)*size(reg_grid,2);
    AvgInterBeadDist = sqrt(TotalAreaPixel/totaGridPoints);        % avg inter-bead separation distance = total img area/number of tracked points
    QuiverScaleDefault = 0.95 * (AvgInterBeadDist/tmaxPaGridFine) * QuiverMagnificationFactor;    
    QuiverScaleToMax = QuiverScaleDefault * QuiverMagnificationFactor; 
    colormapLUT_parula = parula(GrayLevels);
    QuiverColor = median(imcomplement(colormapLUT_parula));      
    colorbarLimits = [0, tmaxPaGridFine];
    NumDigits = numel(num2str(FramesNumEPI));            %counting the number of digits in the number of frames. E.g., 1000 = 4 digits, 100 is three digits, and so forth.
    FormatSpecifier = sprintf('%%%dg', NumDigits);
    FrameString = sprintf('Frame #%s', sprintf(FormatSpecifier, MaxTractionFrameNumber));
    TrackingInfoTXT = sprintf('(%dx%d) grid pts. (%d pix spacing). %s interp. %s.', size(reg_grid,1:2) , gridSpacing, InterpolationMethod, TractionStressMethod);
    TrackingInfoTXT = sprintf('%s %s (%dx%d) pix. Han window %s. %s.', TrackingInfoTXT, SpatialFilterChoiceStr, WienerWindowSize, PaddingChoiceStr, reg_cornerChoiceStr) ;
    TrackingInfoTXT = sprintf('%s\nMaxTractionNetPa=%0.3f %s in %s @ [%0.3f, %0.3f] pix.', TrackingInfoTXT, MaxTractionNetPa(3), tractionUnit,  FrameString , ...
        MaxTractionFieldIndexXY); 
    tractionInfoTxt = sprintf('\\itE\\rm=%0.3f Pa. \\nu=%0.2g.', YoungModulusPaOptimum, PoissonRatio);
    diary off
    videoImages = cell(FramesNumEPI, 1);
    parfor_progress(FramesNumEPI, parfor_progressPath);
    parfor CurrentFrame = FramesDoneNumbersEPI
            videoImages{CurrentFrame} = plotTractionHeatmapsVectorsParfor(MD_EPI,forceField, CurrentFrame, QuiverScaleToMax, QuiverColor, colormapLUT_parula, ...
                TrackingInfoTXT, FramesNumEPI, ScaleLength_EPI, ScaleMicronPerPixel_EPI, TimeStampsRT_Abs_EPI, FluxStatusString{CurrentFrame}, reg_grid, ...
                InterpolationMethod, bandSize, colorbarLimits, colorbarFontSize, reg_corner_averaged(CurrentFrame), tractionInfoTxt, useGPU, MaxTractionNetPa);
                parfor_progress(-1, parfor_progressPath);
    end
    parfor_progress(0, parfor_progressPath);
    diary on
    disp("5.2 Creating frames COMPLETE!") 
    disp("5.2 Writing  frames IN PROGRESS") 
    open(VideoWriterObj1)
    open(VideoWriterObj3)        
    diary off
    parfor_progress(numel(FramesDoneNumbers), parfor_progressPath);
    for CurrentFrame = FramesDoneNumbersEPI 
        writeVideo(VideoWriterObj1,  videoImages{CurrentFrame})
        writeVideo(VideoWriterObj3,  videoImages{CurrentFrame})
        parfor_progress(-1, parfor_progressPath);
    end
    parfor_progress(0, parfor_progressPath);
    diary on
    close(VideoWriterObj1)
    close(VideoWriterObj3)
    disp("5.2 Writing  frames COMPLETE!") 
    fprintf('Saved as: \n\t%s\n', VideoFullFileName1)
%     winopen(VideoPathName1)
%     winopen(CombinedAnalysisPath)

    delete(gcp('nocreate'));
    if isempty(gcp('nocreate')), localcluster.parpool;end 

    disp("5.3 Creating ROI frames IN PROGRESS") 
    QuiverMagnificationFactor = 2;
    totaGridPoints = size(reg_grid,1)*size(reg_grid,2);
    AvgInterBeadDist = sqrt(TotalAreaPixel/totaGridPoints);        % avg inter-bead separation distance = total img area/number of tracked points
    QuiverScaleDefault = 0.95 * (AvgInterBeadDist/tmaxPaGridFine) * QuiverMagnificationFactor;    
    QuiverScaleToMax = QuiverScaleDefault * QuiverMagnificationFactor; 
    diary off
    TrackingInfoTXT = sprintf('MaxTractionNetPa=%0.3f %s in %s @ [%0.3f, %0.3f] pix.', MaxTractionNetPa(3), tractionUnit,  FrameString ,  MaxTractionFieldIndexXY); 
    videoImages = cell(FramesNumEPI, 1);
    parfor_progress(FramesNumEPI, parfor_progressPath);
    parfor CurrentFrame = FramesDoneNumbersEPI
            videoImages{CurrentFrame} = plotTractionHeatmapsVectorsParforROI(MD_EPI,forceField, CurrentFrame, QuiverScaleToMax, QuiverColor, colormapLUT_parula, ...
                TrackingInfoTXT, FramesNumEPI, ScaleLength_EPI, ScaleMicronPerPixel_EPI, TimeStampsRT_Abs_EPI, FluxStatusString{CurrentFrame}, reg_grid, ...
                InterpolationMethod, bandSize, colorbarLimits, colorbarFontSize, reg_corner_averaged(CurrentFrame), tractionInfoTxt, useGPU, MaxTractionNetPa, ROIsideSizeMicron, ROIMagnificationFactor);
                parfor_progress(-1, parfor_progressPath);
    end
    parfor_progress(0, parfor_progressPath);
    diary on
    disp("5.3 Creating frames COMPLETE!") 
    disp("5.3 Writing  frames IN PROGRESS") 
    VideoFileName = strcat(VideoFileNameSuffix, '_ROI_heatmap');
    VideoFullFileName1 = fullfile(VideoPathName1, VideoFileName);
    VideoWriterObj1 = VideoWriter(VideoFullFileName1, VideoType1);
    VideoWriterObj1.LosslessCompression = true;
    VideoWriterObj1.FrameRate = FrameRateRT_EPI; 
    VideoFullFileName3 = fullfile(CombinedAnalysisPath, VideoFileName);
    VideoWriterObj3 = VideoWriter(VideoFullFileName3, VideoType3);
    VideoWriterObj3.FrameRate = FrameRateRT_EPI;     
    forceFieldPath = VideoPathName1;
    fprintf("-------- Video 4. ROI **** %s **** ------------------\n%s", VideoWriterObj1.Filename)
    open(VideoWriterObj1)
    open(VideoWriterObj3)        
    diary off
    parfor_progress(numel(FramesDoneNumbers), parfor_progressPath);
    for CurrentFrame = FramesDoneNumbersEPI 
        writeVideo(VideoWriterObj1,  videoImages{CurrentFrame})
        writeVideo(VideoWriterObj3,  videoImages{CurrentFrame})
        parfor_progress(-1, parfor_progressPath);
    end
    parfor_progress(0, parfor_progressPath);
    diary on
    close(VideoWriterObj1)
    close(VideoWriterObj3)
    disp("5.3 Writing  ROI frames COMPLETE!") 
    fprintf('Saved as: \n\t%s\n', VideoFullFileName1)
%     winopen(VideoPathName1)
%     winopen(CombinedAnalysisPath)
    disp('----------------------------------------------------------------------------------------------------------------')
    
    clear videoImages 
    disp('------------------------------------------------------------------------------')

%% Video 6: Magnetic bead displacement (tracked bead)
    disp('------------------------------------------------------------------------------')
    load(MagBeadTrackedDisplacementsFullFileName, 'MagBeadCoordinatesXYpixels')

    FramesDoneIdx = ~isnan(MagBeadCoordinatesXYpixels(:,1));
    FramesNumbersAll = 1:numel(FramesDoneIdx);
    FramesDoneNumbersDIC = FramesNumbersAll(FramesDoneIdx);
    FramesNumDIC = min([numel(FramesDoneNumbersDIC), numel(displField), numel(FluxON)]) ;
    FramesNumbersAll = FramesNumbersAll(1:FramesNumDIC);
    FramesDoneIdx = FramesDoneIdx(1:FramesNumDIC);
    FramesDoneNumbersDIC = FramesNumbersAll(FramesDoneIdx);
    FluxON = FluxON(1:FramesNumDIC);
    FluxOFF = FluxOFF(1:FramesNumDIC);   
    FramesDoneNumbersONTrans = FramesDoneNumbersDIC(FluxON(FramesDoneIdx) | FluxTransient(FramesDoneIdx));
    FluxStatusString = cell(FramesNumDIC, 1);
    FluxStatusString(FluxON(FramesDoneNumbersDIC)) = {'Flux ON'};
    FluxStatusString(FluxOFF(FramesDoneNumbersDIC)) = {'Flux OFF'};
    FluxStatusString(FluxTransient(FramesDoneNumbersDIC)) = {'Flux TRANS'};        

    [VideoPathName1, VideoFileNameSuffix, ~] = fileparts(MagBeadTrackedDisplacementsFullFileName);   
    VideoFileName = strcat(VideoFileNameSuffix, '_tracked');
    VideoFullFileName1 = fullfile(VideoPathName1, VideoFileName);
    VideoWriterObj1 = VideoWriter(VideoFullFileName1, VideoType1);
    VideoWriterObj1.LosslessCompression = true;
    VideoWriterObj1.FrameRate = FrameRateRT_EPI; 
    VideoFullFileName3 = fullfile(CombinedAnalysisPath, VideoFileName);
    VideoWriterObj3 = VideoWriter(VideoFullFileName3, VideoType3);
    VideoWriterObj3.FrameRate = FrameRateRT_EPI; 
    fprintf("-------- Video 6. **** %s **** ------------------\n%s", VideoWriterObj1.Filename)
    
    MD_DIC_ChannelCount = numel(MD_DIC.channels_);
    colormapLUT_GrayScale = gray(GrayLevels);
    QuiverColor = [1,0,0];  
    GrayLevelsPercentile = [0,1];                        % to make beads show up better;

    TrackingInfoTXT = sprintf('BeadTrackingMethod=%s. DriftTrackingMethod=%s. Max displ.=%0.3f%s (%0.3f%s drift-corrected). ', ...
        BeadTrackingMethod, DriftTrackingMethod,BeadMaxNetDisplMicron, displUnit, BeadMaxNetDisplMicronDriftCorrected, displUnit);

    disp("6.1 Creating frames IN PROGRESS") 
    videoImages = cell(FramesNumDIC, 1);
    diary off
    parfor_progressPath = VideoPathName1;
    parfor_progress(FramesNumDIC, parfor_progressPath);
    parfor CurrentFrame = FramesDoneNumbersDIC
            videoImages{CurrentFrame} = plotDisplacementMagBeadOverlayParfor(MD_DIC,MagBeadCoordinatesXYpixels,CurrentFrame, MD_DIC_ChannelCount, BeadRadius, ...
                QuiverColor, GrayLevelsPercentile, colormapLUT_GrayScale, FramesNumDIC, ScaleLength_EPI, ScaleMicronPerPixel_DIC, TimeStampsRT_Abs_DIC, ...
                FluxStatusString{CurrentFrame}, TrackingInfoTXT, scalebarFontSize, useGPU); 
            parfor_progress(-1, parfor_progressPath);
    end
    parfor_progress(0, parfor_progressPath);
    diary on
    disp("6.1 Creating frames COMPLETE!")

    disp("6.2 Writing  frames IN PROGRESS") 
    open(VideoWriterObj1)
    open(VideoWriterObj3)        
    diary off
    parfor_progress(numel(FramesDoneNumbers), parfor_progressPath);
    for CurrentFrame = FramesDoneNumbersDIC
        writeVideo(VideoWriterObj1,  videoImages{CurrentFrame})
        writeVideo(VideoWriterObj3,  videoImages{CurrentFrame})
        parfor_progress(-1, parfor_progressPath);
    end
    parfor_progress(0, parfor_progressPath);
    diary on
    close(VideoWriterObj1)
    close(VideoWriterObj3)
    disp("6.2 Writing  frames COMPLETE!") 
    fprintf('Saved as: \n\t%s\n', VideoFullFileName1)
%     winopen(VideoPathName1)
%     winopen(CombinedAnalysisPath)
    disp('----------------------------------------------------------------------------------------------------------------')

    clear videoImages 

%% Video 7: Magnetic bead displacement, drift-corrected (vector bead)
    disp('------------------------------------------------------------------------------')
    load(MagBeadTrackedDisplacementsFullFileNameCorrected, 'MagBeadCoordinatesXYpixels')
    [VideoPathName1, VideoFileNameSuffix, ~] = fileparts(MagBeadTrackedDisplacementsFullFileNameCorrected);   
    VideoFileName = strcat(VideoFileNameSuffix, '_vector');
    VideoFullFileName1 = fullfile(VideoPathName1, VideoFileName);
    VideoWriterObj1 = VideoWriter(VideoFullFileName1, VideoType1);
    VideoWriterObj1.LosslessCompression = true;
    VideoWriterObj1.FrameRate = FrameRateRT_EPI; 
    VideoFullFileName3 = fullfile(CombinedAnalysisPath, VideoFileName);
    VideoWriterObj3 = VideoWriter(VideoFullFileName3, VideoType3);
    VideoWriterObj3.FrameRate = FrameRateRT_EPI; 
    fprintf("-------- Video 7. **** %s **** ------------------\n%s", VideoWriterObj1.Filename)

    MagBeadCoordinatesXYNetpixels = (MagBeadCoordinatesXYpixels - MagBeadCoordinatesXYpixels(1,:));

%     FramesNumDIC = numel(FramesDoneNumbersDIC);
%     FluxStatusString = cell(FramesNumDIC, 1);
%     FluxON_DIC = CompiledMT_Results.FluxON;
%     FluxStatusString(FramesDoneNumbersDIC(CompiledMT_Results.FluxON(1:FramesNumDIC))) = {'Flux ON'};
%     FluxStatusString(FramesDoneNumbersDIC(CompiledMT_Results.FluxOFF(1:FramesNumDIC))) = {'Flux OFF'};
%     FluxStatusString(FramesDoneNumbersDIC(CompiledMT_Results.FluxTransient(1:FramesNumDIC))) = {'Flux TRANS'};    

    MD_DIC_ChannelCount = numel(MD_DIC.channels_);
    colormapLUT_GrayScale = gray(GrayLevels);
    QuiverColor = [1,0,0];  
    GrayLevelsPercentile = [0,1];                        % to make beads show up better

    TrackingInfoTXT = sprintf('BeadTrackingMethod=%s. DriftTrackingMethod=%s. Max displ.=%0.3f%s (%0.3f%s Drift-corrected). ', ...
        BeadTrackingMethod, DriftTrackingMethod,BeadMaxNetDisplMicron, displUnit, BeadMaxNetDisplMicronDriftCorrected, displUnit);

    disp("7.1 Creating frames IN PROGRESS") 
    videoImages = cell(FramesNumDIC, 1);
    diary off
    parfor_progressPath = VideoPathName1;
    parfor_progress(FramesNumDIC, parfor_progressPath);
    parfor CurrentFrame = FramesDoneNumbersDIC
        videoImages{CurrentFrame} = plotDisplacementMagBeadVectorParfor(MD_DIC, MagBeadCoordinatesXYpixels, MagBeadCoordinatesXYNetpixels, CurrentFrame, MD_DIC_ChannelCount, ...
            QuiverColor, GrayLevelsPercentile, colormapLUT_GrayScale, FramesNumDIC, ScaleLength_EPI, ScaleMicronPerPixel_DIC, TimeStampsRT_Abs_DIC, ...
            FluxStatusString{CurrentFrame}, TrackingInfoTXT, scalebarFontSize, useGPU)
            parfor_progress(-1, parfor_progressPath);
    end
    parfor_progress(0, parfor_progressPath);
    diary on
    disp("7.1 Creating frames COMPLETE!") 

    disp("7.1 Writing  frames IN PROGRESS") 
    open(VideoWriterObj1)
    open(VideoWriterObj3)        
    diary off
    parfor_progress(numel(FramesDoneNumbers), parfor_progressPath);
    for CurrentFrame = FramesDoneNumbersDIC 
        writeVideo(VideoWriterObj1,  videoImages{CurrentFrame})
        writeVideo(VideoWriterObj3,  videoImages{CurrentFrame})
        parfor_progress(-1, parfor_progressPath);
    end
    parfor_progress(0, parfor_progressPath);
    diary on
    close(VideoWriterObj1)
    close(VideoWriterObj3)
    disp("7.1 Writing  frames COMPLETE!") 
    fprintf('Saved as: \n\t%s\n', VideoFullFileName1)
%     winopen(VideoPathName1)
    winopen(CombinedAnalysisPath)
    disp('----------------------------------------------------------------------------------------------------------------')

    clear videoImages 