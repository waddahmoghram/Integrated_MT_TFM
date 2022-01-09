function [CurrentFramePlot] = plotDisplacementOverlaysBeadsParfor(MD_EPI,displField, CurrentFrame, MD_EPI_ChannelCount, FluoroSphereSizePixel, QuiverColor, ...
    GrayLevelsPercentile, colormapLUT, FramesNumEPI, ScaleLength_EPI, ScaleMicronPerPixel_EPI, TimeStampsRT_Abs_EPI,FluxStatusString, TrackingInfoTXT)
    trackedBeads = numel(find(~isnan(displField(CurrentFrame).vec(:,1)==1)));
    
    try
        CurrentFramePlot = gpuArray(MD_EPI.channels_(MD_EPI_ChannelCount).loadImage(CurrentFrame));
    catch
        CurrentFramePlot = MD_EPI.channels_(MD_EPI_ChannelCount).loadImage(CurrentFrame);
    end
    CurrentFramePlot = imadjust(CurrentFramePlot, stretchlim(CurrentFramePlot,GrayLevelsPercentile));

    NumDigits = numel(num2str(FramesNumEPI));            %counting the number of digits in the number of frames. E.g., 1000 = 4 digits, 100 is three digits, and so forth.
    FormatSpecifier = sprintf('%%0.%di', NumDigits);

    imgHandle = imshow(CurrentFramePlot, 'Border', 'tight', 'Colormap', colormapLUT);    
    axis image
    truesize
    hold on
    figAxesHandle = imgHandle.Parent;
    set(figAxesHandle, 'Box', 'on', 'XTick',[], 'YTick', [], 'Visible', 'on', 'YDir', 'reverse');
    set(figAxesHandle, 'Units', 'pixels');
    figHandle = figAxesHandle.Parent;
    FrameString = sprintf('Frame %s/%s', sprintf(FormatSpecifier, CurrentFrame), sprintf(FormatSpecifier, FramesNumEPI));
    figHandle.Name = FrameString;

    plot(figAxesHandle, displField(CurrentFrame).pos(:,1) + displField(CurrentFrame).vec(:,1), displField(CurrentFrame).pos(:,2) + displField(CurrentFrame).vec(:,2), ...
            'MarkerSize', FluoroSphereSizePixel * 1.5, 'Marker', '.', 'MarkerEdgeColor', QuiverColor, 'LineStyle', 'none') ;

    Location = MD_EPI.imSize_ - [3,3];       
    sBar = scalebar(figAxesHandle,'ScaleLength', ScaleLength_EPI, 'ScaleLengthRatio', ScaleMicronPerPixel_EPI, 'color', QuiverColor, 'bold', true, 'unit', sprintf('%sm', char(181)), 'location', Location);


    Location = MD_EPI.imSize_ .* [0, 1] + [3,-3];                  % bottom right corner
    FrameString = sprintf('#Beads=%d. %s. \\itt\\rm = %0.3fs. %s', trackedBeads, FrameString, TimeStampsRT_Abs_EPI(CurrentFrame), FluxStatusString{:});
    text(figAxesHandle, Location(1), Location(2), FrameString , 'FontSize', sBar.Children(1).FontSize, 'VerticalAlignment', 'bottom', ...
                    'HorizontalAlignment', 'left', 'Color', QuiverColor);
    Location = [3,3];
    text(figAxesHandle, Location(1), Location(2), TrackingInfoTXT , 'FontSize', sBar.Children(1).FontSize - 3, 'VerticalAlignment', 'top', ...
                    'HorizontalAlignment', 'left', 'Color', QuiverColor, 'FontWeight','bold');

    plottedFrame =  getframe(figAxesHandle);
    CurrentFramePlot =  plottedFrame.cdata;
    delete(figAxesHandle)
    close(figHandle)
end