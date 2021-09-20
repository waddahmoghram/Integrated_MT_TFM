%{
    v.2020-08-22: by Waddah Moghram, PhD Candidate in Biomedical Engineering at the University of Iowa
        1. Renamed this script from TrackMagBeadImgregtformScript.m to TrackMagBeadsDIC.m
    v.2020-08-10..13 by Waddah Moghram, PhD candidate in Biomedical Engineering
        * Using imfindcircles to find the bead instead of imregtform. 
            Algorithm chosen is "TwoStage" explained in this paper: 
                [2] H.K Yuen, .J. Princen, J. Illingworth, and J. Kittler. "Comparative study of Hough transform methods for 
                    circle finding." Image and Vision Computing. Volume 8, Number 1, 1990, pp. 71–77.
                [3] E.R. Davies, Machine Vision: Theory, Algorithms, Practicalities. Chapter 10. 3rd Edition. Morgan Kauffman 
                    Publishers, 2005.
            The alternative/Default) algorithm "PhaseCode" is .
            [1] T.J Atherton, D.J. Kerbyson. "Size invariant circle detection." Image and Vision Computing. Volume 17, Number
                    11, 1999, pp. 795-803.

    v.2020-01-16..17 by Waddah Moghram
        * updated to see if I can generalize it to needle tip. Based on VideoAnalysisDIC.m
        * this code works MUCH BETTER than the Dr. Sander code.
        * Try to make the output similar to that of Dr. Sander code so that I can use the same infrastructure for my analysis.
%  v.2020-01-15 Writtten by Waddah Moghram on
    % This script is a precursor to track the magnetic bead in DIC videos directly instead of using the Sander's Code
    
%}

%%
    PlotsFontName = 'XITS';
%%
    % use GPU acceleration if that is an option.
    nGPU = gpuDeviceCount;
    if nGPU > 0
        useGPU = true;
    else
        useGPU = false;
    end    
    BeadNodeID = 1;
    
    %%
    [ND2fileDIC, ND2pathDIC] = uigetfile('*.nd2', 'Open the ND2 DIC video file');    
    if ND2fileDIC == 0
        error('No file was selected');
    end            
    ND2fullFileName = fullfile(ND2pathDIC, ND2fileDIC);    

    [ScaleMicronPerPixel, MagnificationTimesStr] = MagnificationScalesMicronPerPixel();
    
    [TimeStampsND2, LastFrameND2] = ND2TimeFrameExtract(ND2fullFileName);
    
   try
        DICcontent = bfGetReader(ND2fullFileName);
        DICcontentMetadata = DICcontent.getMetadataStore;
% % BETTER than the previous one. There are many ways to "skin a cat"!! 
% (NOTE: Whoever came up with this saying is a terrible human being. LOL!).
%           DICmovieData = bfImport(ND2fullFileName);                 
    catch
        BioformatsPath = uigetdir([], 'Select directory containing bioformats folder (e.g., TFMpackagefolder)');
        addpath(genpath(BioformatsPath));        % include subfolders   
        DICcontent = bfGetReader(ND2fullFileName);
        DICcontentMetadata = DICcontent.getMetadataStore;
    end
    FrameCount = DICcontent.getImageCount;
%     FrameCount = DICcontent.nFrames_;
    FramesDoneNumbers = 1:FrameCount;
    VeryFirstFrame = FramesDoneNumbers(1);   
    VeryLastFrame =  FramesDoneNumbers(end); 

    prompt = {sprintf('Choose the first frame to plotted. [Default, Frame # = %d]', VeryFirstFrame)};
    dlgTitle = 'First Frame';
    FirstFrameStr = inputdlg(prompt, dlgTitle, [1, 90], {num2str(VeryFirstFrame)});
    if isempty(FirstFrameStr), return; end
    FirstFrame = str2double(FirstFrameStr{1});          
    [~, FirstFrameIndex] = min(abs(FramesDoneNumbers - FirstFrame));
    FirstFrame = FramesDoneNumbers(FirstFrameIndex);

    prompt = {sprintf('Choose the last frame to plotted. [Default, Frame # = %d]', VeryLastFrame)};
    dlgTitle = 'Last Frame';
    LastFrameStr = inputdlg(prompt, dlgTitle, [1, 90], {num2str(VeryLastFrame)});
    if isempty(LastFrameStr), return; end
    LastFrame = str2double(LastFrameStr{1});          
    [~, LastFrameIndex] = min(abs(FramesDoneNumbers - LastFrame));
    LastFrame = FramesDoneNumbers(LastFrameIndex);             

    FramesDoneNumbers = FramesDoneNumbers(FirstFrameIndex:LastFrameIndex);
    try
        ImageBits = DICcontent.getBitsPerPixel - 2;   % Typically if 16 bits are used. Then image will be saved in 14 bits.
%         ImageBits = DICmovieData.camBitdepth_ - 2;
    catch
        ImageBits = 14;
    end
    GrayColorMap =  gray(2^ImageBits);             % grayscale image for DIC image.    
%
    MToutputPath = uigetdir(ND2pathDIC, 'Choose the directory you want to save the tracking output');
    if isempty(MToutputPath), MToutputPath = fullfile(ND2pathDIC,'DIC Tracking Output'); end

    %% Tracking after select the ROI
    TrackingMethodList = {'imfindcircles()', 'imgregtform()'};
    TrackingMethodListChoiceIndex = listdlg('ListString', TrackingMethodList, 'SelectionMode', 'single', 'InitialValue', 1, ...
        'PromptString', 'Choose the tracking Algorith:', 'ListSize', [200, 100]);
    if isempty(TrackingMethodListChoiceIndex), TrackingMethodListChoiceIndex = 1; end
    TrackingMethod = TrackingMethodList{TrackingMethodListChoiceIndex}; 
    
    BeadDiameterMicron = inputdlg('What is the bead''s diameter (in microns)?', 'Bead Diameter', [1, 50], {'4.5'});
    BeadDiameterMicron = str2double(BeadDiameterMicron{:});

    BeadRadius = (BeadDiameterMicron/2) / ScaleMicronPerPixel;
    BeadRadiusRange = BeadRadius *  [0.5, 1.5];
    BeadRadiusRange(1) = max(6, floor(BeadRadiusRange(1)));
    BeadRadiusRange(2) = ceil(BeadRadiusRange(2)) + 1;

    dlgQuestion = 'Was the video part of a larger ROI?';
    dlgTitle = 'Show Plots In Progress?';
    LargerROIChoice = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No', 'Yes');
    switch LargerROIChoice
        case 'Yes'
            prompt = {'Center X (pixels)', 'Center Y (pixels)', 'Width', 'Height'};
            dlgTitle = 'Larger ROI position';
            dims = [1 70];
            defInput = {'1000', '1000', '256', '256'};
            opts.Interpreter = 'tex';
            LargerROIPositionInput = inputdlg(prompt, dlgTitle, dims, defInput, opts);
            ROICenterX = str2double(LargerROIPositionInput{1,:});
            ROICenterY = str2double(LargerROIPositionInput{2,:});
            ROIWidth = str2double(LargerROIPositionInput{3,:});
            ROIHeight = str2double(LargerROIPositionInput{4,:});
            largerROIPositionPixels = [ROICenterX, ROICenterY] - ([ROIWidth, ROIHeight]/2) + [1,1];   
        case 'No'
            largerROIPositionPixels = [0,0];
        otherwise
            return
    end           
    
    switch TrackingMethod
        case 'imfindcircles()'
            commandwindow;
            RefFrameNum = input('Enter the reference frame that you want [Default = 1]: ');
            if isempty(RefFrameNum), RefFrameNum = 1; end
            RefFrameImage = bfGetPlane(DICcontent, RefFrameNum);
            if useGPU, RefFrameImage = gpuArray(RefFrameImage); end
            RefFrameImageAdjust = imadjust(RefFrameImage, stretchlim(RefFrameImage,[0, 1]));            
            
            figHandle = figure('color', 'w');
            figAxesHandle = gca;
            colormap(GrayColorMap);
            imagesc(figAxesHandle, 1, 1, RefFrameImageAdjust);
            hold on
            set(figAxesHandle, 'FontWeight', 'bold','LineWidth',1, 'XMinorTick', 'on', 'YMinorTick', 'on', 'TickDir', 'out', 'Box', 'on')    
            xlabel('X (pixels)'), ylabel('Y (pixels)')
            axis image
                                
            dlgQuestion = 'Do you want to have an ROI of the current Video?';
            dlgTitle = 'ROI of current video?';
            SmallerROIChoice = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No', 'Yes');
            switch SmallerROIChoice
                case 'Yes'
                    prompt = {'ROI Width (pixels)', 'ROI Heigh (pixels)', 'Top-Left Corner X-Coordinates (pixels)', 'Top-Left Corner Y-Coordinates (pixels)'};
                    dlgTitle = sprintf('ROI Dimensions : Total Size = [%g, %g] pixels', size(RefFrameImageAdjust, 2), size(RefFrameImageAdjust, 1));
                    dims = [1 70];
                    defInput = {'256', '256', '1', '1'};
                    opts.Interpreter = 'tex';
                    SmallerROIinitialSize = inputdlg(prompt, dlgTitle, dims, defInput, opts);
                    ROIrectdim = [str2double(SmallerROIinitialSize{3,:}), str2double(SmallerROIinitialSize{4,:}), str2double(SmallerROIinitialSize{1,:}) - 1, str2double(SmallerROIinitialSize{2,:}) - 1];   % one pixel less at end, 1:255 = 256 pixels.
                    
                    title({'Draw a rectangle to select an ROI.', 'Zoom and adjust as needed to select a tight box'})
                    BeadROIrectHandle = imrect(figAxesHandle, ROIrectdim);              % Can also be a needle tip
                    addNewPositionCallback(BeadROIrectHandle,@(p) title({strcat('ROI Position [X,Y,W,H]=', char(32), mat2str(p,3), char(32), 'pixels'), 'Double-Click on Last ROI when finished with adjusting all ROIs'})); 
                    ConstraintFunction = makeConstrainToRectFcn('imrect',get(figAxesHandle,'XLim'),get(figAxesHandle,'YLim'));
                    setPositionConstraintFcn(BeadROIrectHandle,ConstraintFunction);
                    CroppedRectangle = wait(BeadROIrectHandle);                                     % Freeze MATLAB command until the figure is double-clicked, then it is resumed. Returns whole pixels instead of fractions
                    CroppedRectangle = (round(CroppedRectangle));
                    close(figHandle)    
                    [BeadROI, BeadROIrect] = imcrop(RefFrameImageAdjust, CroppedRectangle);
                    pause(2)
                case 'No'
                    BeadROI = RefFrameImageAdjust;
                    BeadROIrect = [1,1, size(BeadROI, 2), size(BeadROI, 1)];        % width is columns, and height is rows.
            end
                    
            fig2 = imshow(BeadROI, 'InitialMagnification', 400);
            figure(fig2.Parent.Parent)
            [centers, BeadRadius, metric] = imfindcircles(BeadROI, BeadRadiusRange, 'ObjectPolarity' ,'dark', 'Method', 'TwoStage', 'EdgeThreshold', 0.7, 'Sensitivity', 0.95);   %'Sensitivity', 0.8
            hold on
            viscircles(centers, BeadRadius, 'EdgeColor','b');
            plot(centers(:,1),centers(:,2), 'b.')           % does not work when the needle is attached, or maube the lighting?
            BeadROIcenterPixels = ginput(1);
            [ClosestBeadDist, BeadNodeID] = min(vecnorm(BeadROIcenterPixels - centers, 2, 2));
            close(fig2.Parent.Parent)
            BeadROIcenterPixels = [0, 0];         % in this case, the Bead center is the center, not the corner of the ROI
            
            clear BeadPositionXYCornerPixels         
            clear BeadRadius 
            BeadRadius = nan(size(FramesDoneNumbers))';
            reverseString = ''; 
%             
            tmpFig = figure('color', 'w');
            tmpAxes = gca;
            axis image
                             
            for CurrentFrame = FramesDoneNumbers
                ProgressMsg = sprintf('\nTracking Frame %d/%d\n', CurrentFrame, FramesDoneNumbers(end));
                fprintf([reverseString, ProgressMsg]);
                reverseString = repmat(sprintf('\b'), 1, length(ProgressMsg));

                CurrentFrameImageFull = bfGetPlane(DICcontent, CurrentFrame);
                if useGPU, CurrentFrameImageFull = gpuArray(CurrentFrameImageFull); end
                CurrentFrameImageFullAdjust = imadjust(CurrentFrameImageFull, stretchlim(RefFrameImage,[0, 1]));   
                CurrentFrameImage = imcrop(CurrentFrameImageFullAdjust, BeadROIrect);
                [CurrentCenters, CurrentRadii, metric] = imfindcircles(CurrentFrameImage, BeadRadiusRange, 'ObjectPolarity' ,'dark', 'Method', 'TwoStage', 'EdgeThreshold', 0.4, 'Sensitivity', 0.8);   % lowered edge from threshold from 0.8 & sensitivity from 0.95 on 2021-06-27
                BeadRadius(CurrentFrame, :) = CurrentRadii(BeadNodeID);
                BeadPositionXYCornerPixels(CurrentFrame,1:2) = CurrentCenters(BeadNodeID, :);
                
                tmpImg = imadjust(CurrentFrameImage, stretchlim(CurrentFrameImage,[0, 1]));
                colormap(GrayColorMap);
                imagesc(tmpAxes, 1, 1, tmpImg);
                axis image
                
                hold on
                b = viscircles(CurrentCenters(BeadNodeID, :), CurrentRadii(BeadNodeID, :), 'EdgeColor','r','LineWidth', 1,    'EnhanceVisibility', false);
                plot(CurrentCenters(BeadNodeID, 1), CurrentCenters(BeadNodeID, 2), 'r.', 'MarkerSize', 2)
            end

        case 'imgregtform()'            
            TrackingModeList = {'multimodal','monomodal'};
            TrackingModeListChoiceIndex = listdlg('ListString', TrackingModeList, 'SelectionMode', 'single', 'InitialValue', 1, ...
                'PromptString', 'Choose the tracking mode:', 'ListSize', [200, 100]); 
            if isempty(TrackingModeListChoiceIndex), TrackingModeListChoiceIndex = 1; end
            TrackingMode = TrackingModeList{TrackingModeListChoiceIndex}; 
            [optimizer, metric] = imregconfig(TrackingMode);

            TransformationTypeList = {'translation', 'rigid', 'similarity', 'affine'};
            TransformationTypeListChoiceIndex = listdlg('listString', TransformationTypeList, 'SelectionMode', 'single', 'InitialValue', 1, ...
               'PromptString', 'Choose Displacement Mode:', 'ListSize', [200, 100]);
            if isempty(TransformationTypeListChoiceIndex), TransformationTypeListChoiceIndex = 1; end
            TransformationType = TransformationTypeList{TransformationTypeListChoiceIndex};

            switch TrackingMode
                case 'monomodal'
                    switch TransformationType
                        case 'translation'
                            optimizer.MinimumStepLength = 1e-7;
                            optimizer.MaximumStepLength = 3.125e-5;
                            optimizer.MaximumIterations = 10000;    
                    end
            end
            RefFrameNum = input('Enter the reference frame that you want [Default = 1]: ');
            if isempty(RefFrameNum), RefFrameNum = 1; end
            RefFrameImage = bfGetPlane(DICcontent, RefFrameNum);
        %     RefFrameImage =  DICmovieData.channels_.loadImage(1);
            if useGPU, RefFrameImage = gpuArray(RefFrameImage); end
            RefFrameImageAdjust = imadjust(RefFrameImage, stretchlim(RefFrameImage,[0, 1]));

            figHandle = figure('color', 'w');
            figAxesHandle = gca;
            colormap(GrayColorMap);
            imagesc(figAxesHandle, 1, 1, RefFrameImageAdjust);
            hold on
            set(figAxesHandle, 'FontWeight', 'bold','LineWidth',1, 'XMinorTick', 'on', 'YMinorTick', 'on', 'TickDir', 'out', 'Box', 'on')    
            xlabel('X (pixels)'), ylabel('Y (pixels)')
            title({'Draw a rectangle to select an ROI.', 'Zoom and adjust as needed to select a tight box'})
            axis image
            BeadROIrectHandle = imrect(figAxesHandle);              % Can also be a needle tip
            addNewPositionCallback(BeadROIrectHandle,@(p) title({strcat('ROI Position [X,Y,W,H]=', char(32), mat2str(p,3), char(32), 'pixels'), 'Double-Click on Last ROI when finished with adjusting all ROIs'})); 
            ConstraintFunction = makeConstrainToRectFcn('imrect',get(figAxesHandle,'XLim'),get(figAxesHandle,'YLim'));
            setPositionConstraintFcn(BeadROIrectHandle,ConstraintFunction);
            CroppedRectangle = wait(BeadROIrectHandle);                                     % Freeze MATLAB command until the figure is double-clicked, then it is resumed. Returns whole pixels instead of fractions
            close(figHandle)    
            [BeadROI, BeadROIrect] = imcrop(RefFrameImageAdjust, CroppedRectangle);

            pause(2)
            fig2 = imshow(BeadROI, 'InitialMagnification', 400);
            figure(fig2.Parent.Parent)
            BeadROIcenterPixels = ginput(1);

            close(fig2.Parent.Parent)
                    clear BeadPositionXYCornerPixels 
            refImg = imref2d(size(BeadROI));
            for CurrentFrame = FramesDoneNumbers
                fprintf('Tracking Frame %d/%d.\n', CurrentFrame, FramesDoneNumbers(end))
                CurrentFrameImage = bfGetPlane(DICcontent, CurrentFrame);
                tFormMatrix = imregtform(gather(CurrentFrameImage), gather(BeadROI),TransformationType, optimizer, metric);
        %         tFormMatrix = imregcorr(gather(CurrentFrameImage), gather(BeadROI),TransformationType);
                switch TransformationType
                    case 'translation'
                        BeadPositionXYCornerPixels(CurrentFrame,1:2) = -tFormMatrix.T(3, 1:2);
                    case 'rigid'

                end
            end
            
        otherwise
            return
    end
    
%% Adjusting for the overall coordinates
    BeadPositionXYcenter = BeadPositionXYCornerPixels + BeadROIcenterPixels + (BeadROIrect(1:2) - [1,1]) + largerROIPositionPixels; 
    % say (20,20) top-left of ROI = (1,1), Therefore, (2,2) in ROI = (20,20) + (2,2) - (1,1) = (21,21) in Bigger Position for imcrop()
%     
%     tmpFig2 = figure('color', 'w');
%     tmpAxes2 = gca;
%     axis image
%     colormap(GrayColorMap);
%     imagesc(tmpAxes2, 1, 1, CurrentFrameImageFullAdjust);
%     axis image
%     hold on
%     b = viscircles(BeadPositionXYcenter(CurrentFrame,:), CurrentRadii(BeadNodeID, :), 'EdgeColor','r','LineWidth', 1, 'EnhanceVisibility', false);
%     plot(BeadPositionXYcenter(CurrentFrame,1), BeadPositionXYcenter(CurrentFrame,2), 'r.', 'MarkerSize', 2)
%     

    MagBeadCoordinatesXYpixels = BeadPositionXYcenter .* [1, -1];           % Convert the y-coordinates to Cartesian to match previous output.    
    MagBeadCoordinatesXYNetpixels = BeadPositionXYcenter - BeadPositionXYcenter(1,:);       
%     MagBeadCoordinatesData = MagBeadCoordinatesXYNetpixels;
    % Convert to Cartesian Units from Image units to match previous code  (y-coordinates is negative pointing downwards instead)    
    MagBeadCoordinatesXYNetpixels(:,3) = vecnorm(MagBeadCoordinatesXYNetpixels, 2, 2);
    BeadPositionXYdisplMicron = MagBeadCoordinatesXYNetpixels * ScaleMicronPerPixel;    
    
    if useGPU
        BeadROI = gather(BeadROI);
        RefFrameImage = gather(RefFrameImage);
        RefFrameImageAdjust = gather(RefFrameImageAdjust);
    end
    
%% Saving
    if useGPU, BeadROI = gather(BeadROI); end
    
    MagBeadCoordiantesFullFileName = fullfile(MToutputPath, 'Mag_Bead_Coordinates.mat');
    save(MagBeadCoordiantesFullFileName, 'MagBeadCoordinatesXYpixels', 'MagBeadCoordinatesXYNetpixels', 'BeadNodeID', 'BeadROI', 'BeadROIrect', ...
        'TrackingMethod', 'BeadPositionXYcenter', 'BeadPositionXYdisplMicron', 'FramesDoneNumbers', ...
        'RefFrameNum', 'MagnificationTimesStr', 'ScaleMicronPerPixel', 'largerROIPositionPixels', '-v7.3')

    switch TrackingMethod
        case 'imfindcircles()'
            save(MagBeadCoordiantesFullFileName,'BeadRadius', '-append')
        case 'imgregtform()'
            save(MagBeadCoordiantesFullFileName, 'optimizer', 'metric', '-append');
    end

%% Plotting
    showPlot = 'on';
    figHandle = figure('visible',showPlot, 'color', 'w');     % added by WIM on 2019-02-07. To show, remove 'visible 
    plot(TimeStampsND2(FramesDoneNumbers), BeadPositionXYdisplMicron(FramesDoneNumbers,3), 'b-', 'LineWidth', 1)
    xlim([0, TimeStampsND2(LastFrame,1)]);               % Adjust the end limit.
    set(findobj(gcf,'type', 'axes'), ...
        'FontSize',12, ...
        'FontName', 'Helvetica', ...
        'LineWidth',1, ...
        'XMinorTick', 'on', ...
        'YMinorTick', 'on', ...
        'TickDir', 'out', ...
        'TitleFontSizeMultiplier', 0.9, ...
        'TitleFontWeight', 'bold', ...
        'TickLength', [0.015, 0.030]);     % Make axes bold            
    xlabelHandle = xlabel('\rmCamera time [s]');
    set(xlabelHandle, 'FontName', PlotsFontName);
    ylabelHandle = ylabel('\bf|\it\Delta\rm_{MT}\rm(\itt\rm)\bf|\rm [\mum]');
    set(ylabelHandle, 'FontName', PlotsFontName);    
    title({'Magnetic bead net displacements from starting position'}, 'FontWeight', 'bold')

    %% plot components
%     figure, plot(MagBeadCoordinatesXYNetpixels)
        
 %% ------------- added on 2020-01-18
    disp('**___to continue, type "dbcont" or press "F5", or click "Continue" under "Editor" Menu___**')
    keyboard

    MagBeadPlotFullFileNameFig = fullfile(MToutputPath, '02 Mag_Bead_Coordinates_Precise.fig');
    MagBeadPlotFullFileNamePNG = fullfile(MToutputPath, '02 Mag_Bead_Coordinates_Precise.png');    
    savefig(figHandle, MagBeadPlotFullFileNameFig, 'compact')
    saveas(figHandle, MagBeadPlotFullFileNamePNG, 'png')