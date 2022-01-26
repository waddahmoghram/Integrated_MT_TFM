MaxTractionNetPa = gather(MaxTractionNetPa);

%% ROI Heatmap
figHandleROI = figure('color','w', 'Units','pixels', 'visible', 'on');
figAxesHandleROI = axes(figHandleROI);
set(figAxesHandleROI, 'Box', 'on', 'XTick',[], 'YTick', [], 'Visible', 'on', 'YDir', 'reverse', 'Units', 'pixels', 'Colormap', colormapLUT_parula);
  
DistanceCenterToEdgePixel = round((50 / ScaleMicronPerPixel_EPI)/2);     % +/- 50 micron ROI from the center
displHeatMapPaddedCenter = round(size(displHeatMapPadded))/2;
displHeatMapPaddedCroppedPixel = [displHeatMapPaddedCenter - DistanceCenterToEdgePixel, displHeatMapPaddedCenter + DistanceCenterToEdgePixel];

displHeatMapPaddedMicronROI = displHeatMapPadded(displHeatMapPaddedCroppedPixel(1):displHeatMapPaddedCroppedPixel(3),displHeatMapPaddedCroppedPixel(2):displHeatMapPaddedCroppedPixel(4))';
figAxesHandleROI_XYWH = [displHeatMapPaddedCroppedPixel(1), displHeatMapPaddedCroppedPixel(2), (displHeatMapPaddedCroppedPixel(3)-displHeatMapPaddedCroppedPixel(1)+1),(displHeatMapPaddedCroppedPixel(4) - displHeatMapPaddedCroppedPixel(2)+1)];

imgHandleROI = imagesc(figAxesHandleROI, 'CData', displHeatMapPaddedMicronROI) ;               % transpose to convert ndgrid to meshgrid for imagesc Cdata
imgHandleROI.Interpolation = 'bilinear';
axis image
truesize
sideSize = figAxesHandleROI.Position(3:4) ;
imgSizePix = sideSize;

percentmag = 3;  % 300%
figAxesHandleROI.InnerPosition(3:4) = sideSize * percentmag;
figHandleROI.Position(1:2) = sideSize * (percentmag - 1);
figHandleROI.InnerPosition(3:4) = figHandleROI.Position(3:4) + sideSize * (percentmag - 1);

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

figAxesHandleROI.Position(1) = figAxesHandleROI.Position(1) - colorbarHandle.Position(3);

Location = imgSizePix - [3,3];             
sBar = scalebar(figAxesHandleROI,'ScaleLength', round(ScaleLength_EPI/4), 'ScaleLengthRatio', ScaleMicronPerPixel_EPI, 'color', imcomplement(colormapLUT_parula(1, :)), 'bold', true, ...
    'unit', sprintf('%sm', char(181)), 'location', Location, 'fontname',  FontName1, 'fontsize', round(colorbarFontSize/3)*2 );

Location = imgSizePix.* [0, 1] + [3,-3];                  % bottom right corner
NumDigits = numel(num2str(FramesNumEPI));            %counting the number of digits in the number of frames. E.g., 1000 = 4 digits, 100 is three digits, and so forth.
FormatSpecifier = sprintf('%%%dg', NumDigits);   
FrameString = sprintf('Frame %s/%s', sprintf(FormatSpecifier, CurrentFrame), sprintf(FormatSpecifier, FramesNumEPI));
FrameString = sprintf('%s. \\itt\\rm = %6.3fs. %s', FrameString, TimeStampsRT_Abs_EPI(CurrentFrame), FluxStatusString);
text(figAxesHandleROI, Location(1), Location(2), FrameString , 'FontSize', sBar.Children(1).FontSize, 'VerticalAlignment', 'bottom', ...
                'HorizontalAlignment', 'left', 'Color',  imcomplement(colormapLUT_parula(1, :)), 'FontName',FontName1, 'interpreter', 'tex');    
Location = [3,3];
ROI_InfoTxt = sprintf('ROI [X,Y,W,H]=[%d,%d,%d,%d] pix.', figAxesHandleROI_XYWH);
text(figAxesHandleROI, Location(1), Location(2), ROI_InfoTxt , 'FontSize', sBar.Children(1).FontSize - 2, 'VerticalAlignment', 'top', ...
                'HorizontalAlignment', 'Left', 'Color',  imcomplement(colormapLUT_parula(1, :)),'FontName',FontName1, 'Interpreter','tex');

Location = imgSizePix.* [1, 0] + [-3,3];                  % top right corner
tractionInfoTxt = sprintf('%s \\lambda_{2}=%0.5g', tractionInfoTxt, reg_corner_averaged);
text(figAxesHandleROI, Location(1), Location(2), tractionInfoTxt , 'FontSize', sBar.Children(1).FontSize - 2, 'VerticalAlignment', 'top', ...
                'HorizontalAlignment', 'Right', 'Color',  imcomplement(colormapLUT_parula(1, :)),'FontName',FontName1, 'Interpreter','tex');

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
colorbarHandle.Ticks = contourCutoffs;
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

figAxesHandleROI.Position(1) = figAxesHandleROI.Position(1) + colorbarHandle.Position(3);
hold off

%% Now, creating contours.
contourCutoffPercentages = [0, .25, .50, .75, 1];         % cutoffs 0%, %25, 50%, 75%, 100%
contourCutoffs =  MaxTractionNetPa(3) .* contourCutoffPercentages;
figAxesHandleROI.YDir = 'reverse';
[ContourData, contourHandleROI] = contourf(figAxesHandleROI, XIMum, YIMum, displHeatMapPaddedMicronROI, contourCutoffs, 'ShowText', 'off', 'LineWidth', 2);
hold on

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



clabel(ContourData, 'Color', 'r','FontSmoothing','on', 'FontName', FontName1, 'FontWeight', 'bold', FontSize = colorbarFontSize);
title(sprintf('Cutoffs: 25%%=%0.3f %s, 50%%=%0.3f %s, 75%%=%0.3f %s, 100%%(max)=%0.3f%s', contourCutoffs(1), colorbarUnits, contourCutoffs(2), colorbarUnits,contourCutoffs(3), colorbarUnits, ...
     MaxTractionNetPa(3), colorbarUnits))
imgSizeMicron = imgSizePix * ScaleMicronPer;       
Location = Corner_BR - [3,3];             
sBar = scalebar(figAxesHandleROI,'ScaleLength', round(ScaleLength_EPI/4), 'ScaleLengthRatio', 1, 'color', [0,0,0], 'bold', true, ...
    'unit', sprintf('%sm', char(181)), 'location', Location, 'fontname',  FontName1, 'fontsize', round(colorbarFontSize/3)*2 );

hold on
title()

plot(figAxesHandleROI, 110, 107, 'rx', 'LineWidth', 1)