function [CurrentFramePlot] = plotDisplacementOverlaysBeadsParfor(MD_EPI,displField, CurrentFrame, MD_DIC_ChannelCount, FluoroSphereSizePixel, QuiverColor, colormapLUT_TxRed,...
        GrayLevelsPercentile, FramesNumEPI, ScaleLength_EPI, ScaleMicronPerPixel_EPI, TimeStampsRT_Abs_EPI,FluxStatusString, TrackingInfoTXT, scalebarFontSize, useGPU, MaxDisplNetPixels, DriftROI_rect)
  %%    
    if nargin > 18
        errordlg('Too many arguments in this function, or wrong argument structure!')
        return
    end 
    
    if ~exist('DriftROI_rect','var'), DriftROI_rect = []; end
    if nargin < 18 || isempty(DriftROI_rect); DriftROI_rect = []; end


  %%
    MaxDisplNetPixelsCurrentFrame = max(vecnorm(displField(CurrentFrame).vec(:,1:2), 2,2));
    if MaxDisplNetPixelsCurrentFrame > MaxDisplNetPixels(3), error(sprintf('Maximum displacement in Frame #%d is more than max found. Check for max displacement in ALL FRAMES', CurrentFrame)); end
  %%
    FontName1 = 'Inconsolata ExtraCondensed';

    trackedBeads = numel(find(~isnan(displField(CurrentFrame).vec(:,1)==1)));
    try
        CurrentFramePlot = MD_EPI.channels_(MD_DIC_ChannelCount).loadImage(CurrentFrame);
    catch
        CurrentFramePlot = MD_EPI.channels_.loadImage(CurrentFrame);
    end
    if useGPU, CurrentFramePlot = gpuArray(CurrentFramePlot); end
    CurrentFramePlot = imadjust(CurrentFramePlot, stretchlim(CurrentFramePlot,GrayLevelsPercentile));
    figHandle = figure('visible','off', 'color', 'w', 'Units', 'pixels', 'Toolbar', 'none', 'Menubar', 'none', 'Resize', 'off', 'Colormap',colormapLUT_TxRed);
    imgHandle = imshow(CurrentFramePlot, []);
    figAxesHandle = figHandle.findobj('type', 'axes');
    
    %% 
    set(figAxesHandle, 'Visible', 'off', 'YDir', 'reverse', 'Units', 'pixels', 'Colormap', colormapLUT_TxRed);    
%      imgHandle = imagesc(figAxesHandle, CurrentFramePlot)
    hold on

    NumDigits = numel(num2str(FramesNumEPI));            %counting the number of digits in the number of frames. E.g., 1000 = 4 digits, 100 is three digits, and so forth.
    FormatSpecifier = sprintf('%%%dg', NumDigits);
    FrameString = sprintf('Frame %s/%s', sprintf(FormatSpecifier, CurrentFrame), sprintf(FormatSpecifier, FramesNumEPI));

    plot(figAxesHandle, displField(CurrentFrame).pos(:,1) + displField(CurrentFrame).vec(:,1), displField(CurrentFrame).pos(:,2) + displField(CurrentFrame).vec(:,2), ...
            'MarkerSize', FluoroSphereSizePixel * 1.5, 'Marker', '.', 'MarkerEdgeColor', QuiverColor, 'LineStyle', 'none') ;

    Location = MD_EPI.imSize_ - [3,3];       
    sBar = scalebar(figAxesHandle,'ScaleLength', ScaleLength_EPI, 'ScaleLengthRatio', ScaleMicronPerPixel_EPI, 'color', QuiverColor,...
        'fontname',FontName1, 'FontSize', scalebarFontSize, 'bold', true, 'unit', sprintf('%sm', char(181)), 'location', Location);

    Location = MD_EPI.imSize_ .* [0, 1] + [3,-3];                  % bottom right corner
    FrameString = sprintf('%d microspheres. %s. \\itt\\rm = %6.3f s. %s', trackedBeads, FrameString, TimeStampsRT_Abs_EPI(CurrentFrame), FluxStatusString);
    text(figAxesHandle, Location(1), Location(2), FrameString , 'FontSize', sBar.Children(1).FontSize, 'FontName',FontName1, 'VerticalAlignment', 'bottom', ...
                    'HorizontalAlignment', 'left', 'Color', QuiverColor);
    Location = [3,3];
    text(figAxesHandle, Location(1), Location(2), TrackingInfoTXT , 'FontSize', sBar.Children(1).FontSize - 3, 'FontName',FontName1, 'VerticalAlignment', 'top', ...
                    'HorizontalAlignment', 'left', 'Color', QuiverColor, 'FontWeight','normal');

    if ~isempty(DriftROI_rect)
        for jj = 1:4
            RefFrameDIC_RectHandle(jj) = rectangle(figAxesHandle,'Position', DriftROI_rect(jj, :), 'EdgeColor', 'm',  'FaceColor', 'none', 'LineWidth', 0.5, 'LineStyle', ':');   
        end
    end

    plottedFrame =  getframe(figAxesHandle);
    CurrentFramePlot =  plottedFrame.cdata;
    CurrentFramePlot(end,:,:) = [];  CurrentFramePlot(:,1,:) = [];   % get rid of weight margin on edges that "getframe" creates. on the left/bottom

    delete(figAxesHandle)
    close(figHandle)

    AllVars = whos;
    for ii = 1:numel(AllVars)
        if contains(AllVars(ii).class, 'gpuArray')
            eval(sprintf('%s = gather(%s);',AllVars(ii).name,AllVars(ii).name));
        end
        if ~any(strcmp(AllVars(ii).name, {'CurrentFramePlot', 'AllVars'})) 
            eval(sprintf('%s = []; clear %s;',AllVars(ii).name,AllVars(ii).name));
        end
    end
    clear AllVars ii 
end