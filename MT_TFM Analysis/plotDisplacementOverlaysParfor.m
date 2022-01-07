function [CurrentFramePlot] = plotDisplacementOverlaysParfor(MD_EPI,displField, CurrentFrame, MD_EPI_ChannelCount, FluoroSphereSizePixel, QuiverColor, ...
    GrayLevelsPercentile, colormapLUT, FramesNumEPI)
    CurrentFramePlot = gpuArray(MD_EPI.channels_(MD_EPI_ChannelCount).loadImage(CurrentFrame));
    CurrentFramePlot = imadjust(tmpCurrentFrame, stretchlim(CurrentFramePlot,GrayLevelsPercentile));

%     figHandle = figure('visible','on', 'color', 'w', 'Units', 'pixels');     % added by WIM on 2019-09-14. To show, remove 'visible
%     figAxesHandle = axes(figHandle);
% 
% 
% %     imshow(tmpCurrentFrame, 'Border', 'tight', 'Colormap', colormapLUT, 'Parent', figAxesHandle);
%       
%     axis image
%     truesize
%     hold on
% %     figAxesHandle = imgHandle.Parent;
%     set(figAxesHandle, 'Box', 'on', 'XTick',[], 'YTick', [], 'Visible', 'on', 'YDir', 'reverse');
%     set(figAxesHandle, 'Units', 'pixels');
%     figHandle = figAxesHandle.Parent;
%     figHandle.Name = sprintf('Frame %d/%d', CurrentFrame, FramesNumEPI);
% 
%     plot(figAxesHandle, displField(CurrentFrame).pos(:,1) + displField(CurrentFrame).vec(:,1), displField(CurrentFrame).pos(:,2) + displField(CurrentFrame).vec(:,2), ...
%             'MarkerSize', FluoroSphereSizePixel * 1.5, 'Marker', '.', 'MarkerEdgeColor', QuiverColor, 'LineStyle', 'none') ;
%     plottedFrame =  getframe(figAxesHandle);
%     CurrentFramePlot =  plottedFrame.cdata;
%     close(figHandle)
%     tmpCurrentFrame = [];
%     plottedFrame = [];
end