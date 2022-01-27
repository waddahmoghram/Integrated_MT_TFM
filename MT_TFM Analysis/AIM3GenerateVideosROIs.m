MaxTractionNetPa = gather(MaxTractionNetPa);




%% Surf
[XIM, YIM] = meshgrid(displHeatMapPaddedCroppedPixel(1):displHeatMapPaddedCroppedPixel(3),displHeatMapPaddedCroppedPixel(2):displHeatMapPaddedCroppedPixel(4));
XIMum = XIM .* ScaleMicronPerPixel_EPI;
YIMum = YIM .* ScaleMicronPerPixel_EPI;
XIMum = gpuArray(XIMum); YIMum = gpuArray(YIMum);
surfHandleROI = surf(figAxesHandleROI, XIMum, YIMum, displHeatMapPaddedMicronROI   , 'linestyle', 'none', 'FaceColor', 'interp' );
hold on
XLIM = gather([min(XIMum(1,:)),max(XIMum(end,:))]);
YLIM = gather([min(YIMum(:,1)),max(YIMum(:,end))]);
Corner_BR = [XLIM(2), YLIM(2)];

figAxesHandleROI.TickDir = 'out';
figAxesHandleROI.XLim = XLIM;
figAxesHandleROI.YLim = YLIM;
figAxesHandleROI.XLabel.String = 'X [\mum]';
figAxesHandleROI.YLabel.String = 'Y [\mum]';
figAxesHandleROI.YDir = 'reverse';

colorbarHandle = colorbar('eastoutside');
caxis(colorbarLimits);
colorbarTicks = unique(sort([colorbarLimits, colorbarHandle.Ticks])); 
colorbarTicksExpDefault = colorbarHandle.Ruler.Exponent;   
colorbarUnits = 'Pa';   
colorbarTickLabels = {};
colorbarTickLabels{1} = num2str(colorbarTicks(1));
colorbarTicks(1) = str2double(colorbarTickLabels{1});
colorbarTicksFormats = sprintf('%%0.%dg', DecimalsColorbar);
colorbarHandle.Ruler.TickLabelFormat = colorbarTicksFormats;
colorbarTickLabels = colorbarHandle.Ruler.TickLabels;
commandLine = sprintf('sprintf(''%s'', colorbarTicks(ii));', sprintf('%s', colorbarTicksFormats));    
for ii = 2:(numel(colorbarTicks)-1)
    CurrentTick = eval(commandLine);
    colorbarTickLabels{ii} = CurrentTick;
    colorbarTicks(ii) = str2double(CurrentTick);
end
colorbarTickLabels{numel(colorbarTicks)} =  sprintf(sprintf('%%0.%df', DecimalsColorbar), colorbarTicks(numel(colorbarTicks)));
colorbarTicks(numel(colorbarTicks)) = str2double( colorbarTickLabels{numel(colorbarTicks)});
colorbarTickLabels = colorbarTickLabels';             % transpose it
delete(colorbarHandle);
caxis(colorbarLimits); 
colorbarHandle = colorbar('eastoutside'); 
colorbarHandle.Limits = colorbarLimits;   
colorbarTicksDiff = diff(colorbarTicks);
colorbarTickNoDiffIdx = find(~colorbarTicksDiff);  % find ticks where there is no difference between
if colorbarTickNoDiffIdx
    colorbarTickLabels(colorbarTickNoDiffIdx) = [];       
    colorbarTicks(colorbarTickNoDiffIdx) = [];      
    colorbarTicksDiff(colorbarTickNoDiffIdx) = [];     
end
if colorbarTicksDiff(end)/colorbarTicksDiff(end-1) < 0.2, colorbarTickLabels{end - 1} = ''; end
set(colorbarHandle, 'Limits', [colorbarTicks(1), colorbarTicks(end)], 'Ticks',colorbarTicks,  'TickLabels', colorbarTickLabels, 'TickDirection', 'out', 'color', 'k',...
        'FontWeight', 'bold', 'FontName', FontName1, 'LineWidth', QuiverLineWidth, 'Units', 'Pixels', 'FontSize', colorbarFontSize)     % font size, 1/100 of height in pixels     
colorbarLabelString =  sprintf('\\bf\\itT\\rm(\\itx\\fontsize{%d}*\\fontsize{%d}, y\\fontsize{%d}*\\fontsize{%d}, t\\rm) [%s]', ...
        repmat([ylabelFontSize * 0.75, ylabelFontSize] , 1, 2), colorbarUnits);
ylabelHandle = ylabel(colorbarHandle, colorbarLabelString);    % 'Displacement (\mum)'; % in Tex format
ylabelHandle.FontSize = ylabelFontSize;
ylabelHandle.FontName = FontName2;
ylabelHandle.Units = 'pixels';

NumDigits = numel(num2str(FramesNumEPI));            %counting the number of digits in the number of frames. E.g., 1000 = 4 digits, 100 is three digits, and so forth.
FormatSpecifier = sprintf('%%%dg', NumDigits);   
FrameString = sprintf('Frame %s/%s', sprintf(FormatSpecifier, CurrentFrame), sprintf(FormatSpecifier, FramesNumEPI));
FrameString = sprintf('%s. \\itt\\rm = %6.3fs. %s.', FrameString, TimeStampsRT_Abs_EPI(CurrentFrame), FluxStatusString);
title(strcat(FrameString, ' ', tractionInfoTxt));

figAxesHandleROI.Position(1) = figAxesHandleROI.Position(1) - colorbarHandle.Position(3);
hold off

%% Now, creating contours.
MaxTractionNetPa = gather(MaxTractionNetPa);

contourCutoffPercentages = [0, .25, .50, .75, 1] ;         % cutoffs 0%, %25, 50%, 75%, 100%
contourCutoffs =  MaxTractionNetPa(3) .* contourCutoffPercentages;
[ContourData, contourHandleROI] = contourf(figAxesHandleROI, XIMum, YIMum, displHeatMapPaddedMicronROI, contourCutoffs, 'ShowText', 'off', 'LineWidth', 2);
figAxesHandleROI.YDir = 'reverse';
hold on

colorbarHandle = colorbar('eastoutside');
caxis(colorbarLimits);
colorbarTicks = contourCutoffs;
colorbarHandle.Ticks = colorbarTicks;
colorbarTicksExpDefault = colorbarHandle.Ruler.Exponent;   
colorbarUnits = 'Pa';   
colorbarTickLabels = {};
colorbarTickLabels{1} = num2str(colorbarTicks(1));
colorbarTicks(1) = str2double(colorbarTickLabels{1});
colorbarTicksFormats = sprintf('%%0.%df', DecimalsColorbar);
colorbarHandle.Ruler.TickLabelFormat = colorbarTicksFormats;
colorbarTickLabels = colorbarHandle.Ruler.TickLabels;
commandLine = sprintf('sprintf(''%s'', colorbarTicks(ii));', sprintf('%s', colorbarTicksFormats));    
for ii = 2:(numel(colorbarTicks)-1)
    CurrentTick = eval(commandLine);
    colorbarTickLabels{ii} = CurrentTick;
    colorbarTicks(ii) = str2double(CurrentTick);
end
colorbarTickLabels{numel(colorbarTicks)} =  sprintf(sprintf('%%0.%df', DecimalsColorbar), colorbarTicks(numel(colorbarTicks)));
colorbarTicks(numel(colorbarTicks)) = str2double( colorbarTickLabels{numel(colorbarTicks)});
colorbarTickLabels = colorbarTickLabels';             % transpose it
delete(colorbarHandle);
caxis(colorbarLimits); 
colorbarHandle = colorbar('eastoutside'); 
colorbarHandle.Limits = colorbarLimits;   
colorbarTicksDiff = diff(colorbarTicks);
colorbarTickNoDiffIdx = find(~colorbarTicksDiff);  % find ticks where there is no difference between
if colorbarTickNoDiffIdx
    colorbarTickLabels(colorbarTickNoDiffIdx) = [];       
    colorbarTicks(colorbarTickNoDiffIdx) = [];      
    colorbarTicksDiff(colorbarTickNoDiffIdx) = [];     
end
if colorbarTicksDiff(end)/colorbarTicksDiff(end-1) < 0.2, colorbarTickLabels{end - 1} = ''; end
set(colorbarHandle, 'Limits', [colorbarTicks(1), colorbarTicks(end)], 'Ticks',colorbarTicks,  'TickLabels', colorbarTickLabels, 'TickDirection', 'out', 'color', 'k',...
        'FontWeight', 'bold', 'FontName', FontName1, 'LineWidth', QuiverLineWidth, 'Units', 'Pixels', 'FontSize', colorbarFontSize)     % font size, 1/100 of height in pixels     
colorbarLabelString =  sprintf('\\bf\\itT\\rm(\\itx\\fontsize{%d}*\\fontsize{%d}, y\\fontsize{%d}*\\fontsize{%d}, t\\rm) [%s]', ...
        repmat([ylabelFontSize * 0.75, ylabelFontSize] , 1, 2), colorbarUnits);
ylabelHandle = ylabel(colorbarHandle, colorbarLabelString);    % 'Displacement (\mum)'; % in Tex format
ylabelHandle.FontSize = ylabelFontSize;
ylabelHandle.FontName = FontName2;
ylabelHandle.Units = 'pixels';

clabel(ContourData, 'Color', 'r','FontSmoothing','on', 'FontName', FontName1, 'FontWeight', 'bold', FontSize = colorbarFontSize);
title(sprintf('Cutoffs: 25%%=%0.3f %s, 50%%=%0.3f %s, 75%%=%0.3f %s, 100%%(max)=%0.3f%s', contourCutoffs(1), colorbarUnits, contourCutoffs(2), colorbarUnits,contourCutoffs(3), colorbarUnits, ...
     MaxTractionNetPa(3), colorbarUnits))
imgSizeMicron = imgSizePix * ScaleMicronPerPixel_EPI;       
Location = Corner_BR - [3,3];             
sBar = scalebar(figAxesHandleROI,'ScaleLength', round(ScaleLength_EPI/4), 'ScaleLengthRatio', 1, 'color', colormapLUT_parula(end,:), 'bold', true, ...
    'unit', sprintf('%sm', char(181)), 'location', Location, 'fontname',  FontName1, 'fontsize', round(colorbarFontSize/3)*2 );

hold on
title()

plot(figAxesHandleROI, 110, 107, 'rx', 'LineWidth', 1)