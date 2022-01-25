function [CurrentFramePlot] = plotDisplacementMagBeadVectorParfor(MD_DIC,MagBeadCoordinatesXYpixels, MagBeadCoordinatesXYNetpixels, CurrentFrame, MD_DIC_ChannelCount, ...
    QuiverColor, GrayLevelsPercentile, colormapLUT_GrayScale, FramesNumDIC, ScaleLength_EPI, ScaleMicronPerPixel_DIC, TimeStampsRT_Abs_DIC, FluxStatusString, ...
    TrackingInfoTXT, scalebarFontSize, useGPU)
 %%   
    FontName1 = 'Inconsolata ExtraCondensed';
    try
        CurrentFramePlot = MD_DIC.channels_(MD_DIC_ChannelCount).loadImage(CurrentFrame);
    catch
        CurrentFramePlot = MD_DIC.channels_.loadImage(CurrentFrame);
    end
    if useGPU, CurrentFramePlot = gpuArray(CurrentFramePlot); end
    CurrentFramePlot = imadjust(CurrentFramePlot, stretchlim(CurrentFramePlot,GrayLevelsPercentile));
    figHandle = figure('visible','off', 'color', 'w', 'Units', 'pixels', 'Toolbar', 'none', 'Menubar', 'none', 'Resize', 'off', 'Colormap',colormapLUT_GrayScale);
    imgHandle = imshow(CurrentFramePlot, []);
    figAxesHandle = figHandle.findobj('type', 'axes');
    
%% 
    set(figAxesHandle, 'Box', 'on', 'XTick',[], 'YTick', [], 'Visible', 'on', 'YDir', 'reverse', 'Units', 'pixels');
    figHandle = figAxesHandle.Parent;
    hold on

    NumDigits = numel(num2str(FramesNumDIC));            %counting the number of digits in the number of frames. E.g., 1000 = 4 digits, 100 is three digits, and so forth.
    FormatSpecifier = sprintf('%%%dg', NumDigits);
    FrameString = sprintf('Frame %s/%s', sprintf(FormatSpecifier, CurrentFrame), sprintf(FormatSpecifier, FramesNumDIC));

    imgHandle = imshow(CurrentFramePlot, 'Border', 'tight', 'Colormap', colormapLUT_GrayScale);    
    axis image
    truesize
    hold on
    figAxesHandle = imgHandle.Parent;

    quiver(figAxesHandle, MagBeadCoordinatesXYpixels(1,1), MagBeadCoordinatesXYpixels(1,2), ...
        MagBeadCoordinatesXYNetpixels(CurrentFrame,1), MagBeadCoordinatesXYNetpixels(CurrentFrame,2), ...
                   'MarkerSize',1, 'MarkerFaceColor',QuiverColor, 'ShowArrowHead','on', 'MaxHeadSize', 3 , 'LineWidth', 0.75 ,  'color', QuiverColor, 'AutoScale','off');

    Location = MD_DIC.imSize_ - [3,3];       
    sBar = scalebar(figAxesHandle,'ScaleLength', ScaleLength_EPI, 'ScaleLengthRatio', ScaleMicronPerPixel_DIC, 'color', QuiverColor, 'bold', true, ...
        'unit', sprintf('%sm', char(181)), 'location', Location, 'fontname', FontName1, 'fontsize',  scalebarFontSize);

    Location = MD_DIC.imSize_ .* [0, 1] + [3,-3];                  % bottom right corner
    FrameString = sprintf('%s. \\itt\\rm = %6.3fs. %s', FrameString, TimeStampsRT_Abs_DIC(CurrentFrame), FluxStatusString);
    text(figAxesHandle, Location(1), Location(2), FrameString , 'FontSize', sBar.Children(1).FontSize, 'VerticalAlignment', 'bottom', ...
                    'HorizontalAlignment', 'left', 'Color', QuiverColor, 'FontName', FontName1, 'interpreter', 'tex');
    Location = [3,3];
    text(figAxesHandle, Location(1), Location(2), TrackingInfoTXT , 'FontSize', sBar.Children(1).FontSize - 2, 'VerticalAlignment', 'top', ...
                    'HorizontalAlignment', 'left', 'Color', QuiverColor, 'FontName', FontName1);

    plottedFrame =  getframe(figHandle);    
    CurrentFramePlot =  plottedFrame.cdata;
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
    clear Allvars ii   
end