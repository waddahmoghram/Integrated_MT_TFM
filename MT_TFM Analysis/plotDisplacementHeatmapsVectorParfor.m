function [CurrentFramePlot] = plotDisplacementHeatmapsVectorParfor(MD_EPI,displFieldMicron,CurrentFrame, QuiverScaleToMax, QuiverColor, colormapLUT_parula, ...
        TrackingInfoTXT, FramesNumEPI, ScaleLength_EPI, ScaleMicronPerPixel_EPI, TimeStampsRT_Abs_EPI, FluxStatusString,  reg_grid, ...
        InterpolationMethod, bandSize, colorbarLimits, colorbarFontSize, useGPU, MaxDisplNetPixels)
    
    QuiverLineWidth = 0.5;
    MarkerSize = 1;
    ylabelFontSize = round((colorbarFontSize + 2)*2)/2;     % increments of 0.5
    scalebarFontSize = round(colorbarFontSize*2/3);
    DecimalsColorbar = 2;
    FontName1 = 'Inconsolata ExtraCondensed';
    FontName2 = 'XITS';

    [grid_mat, displVecGridXY,~,~] = interp_vec2grid(displFieldMicron(CurrentFrame).pos(:,1:2), displFieldMicron(CurrentFrame).vec(:,1:2) ,[], reg_grid, InterpolationMethod);
    if useGPU, displVecGridXY = gpuArray(displVecGridXY); grid_mat = gpuArray(grid_mat); end    
    grid_matX = grid_mat(:,:,1);
    grid_matY = grid_mat(:,:,2);
    grid_spacingX = grid_mat(1,2,1)- grid_mat(1,1,1);
    grid_spacingY = grid_mat(2,1,2)- grid_mat(1,1,2);        
    imSizeX = (grid_mat(end,end,1) - grid_mat(1,1,1)) + grid_spacingX;
    imSizeY = (grid_mat(end,end,2) - grid_mat(1,1,2)) + grid_spacingY; 
    width = imSizeX;
    height = imSizeY;
    centerX = ((grid_mat(end,end,1) + grid_mat(1,1,1))/2);
    centerY = ((grid_mat(end,end,2) + grid_mat(1,1,2))/2);
    % [XI,YI] = meshgrid(grid_mat(1,1,1):grid_mat(1,1,1)+imSizeX,grid_mat(1,1,2):grid_mat(1,1,2)+imSizeY);
    Xmin = centerX - width/2 + bandSize;
    Xmax = centerX + width/2 - bandSize;
    Ymin = centerY - height/2 + bandSize;
    Ymax = centerY + height/2 - bandSize;               
    [XI,YI] = ndgrid(Xmin:Xmax,Ymin:Ymax);                % Addded on 2019-10-10 to go with gridded interpolant, the line above is for griddata
    displVecGridNorm = (displVecGridXY(:,:,1).^2 + displVecGridXY(:,:,2).^2).^0.5;
    dMap = displVecGridNorm;
    dMapX = displVecGridXY(:,:,1);
    dMapY = displVecGridXY(:,:,2);       
%     if useGPU, grid_mat = gather(grid_mat);displVecGridNorm = gather(displVecGridNorm); end
    reg_gridFull(:,:,1)  = XI; reg_gridFull(:,:,2)  = YI;
    [grid_mat_full, displVecGridFullXY,~,~] = interp_vec2grid(displFieldMicron(CurrentFrame).pos(:,1:2), displFieldMicron(CurrentFrame).vec(:,1:2) ,[], reg_gridFull, InterpolationMethod);
    if useGPU, grid_mat_full = gpuArray(grid_mat_full); displVecGridFullXY = gpuArray(displVecGridFullXY); end
    displHeatMapX = displVecGridFullXY(:,:,1);
    displHeatMapY = displVecGridFullXY(:,:,2);
    displHeatMap = (displHeatMapX.^2 + displHeatMapY.^2).^0.5;           
    MaxDisplNetPixelsCurrentFrame = max(displHeatMap(:));
    if MaxDisplNetPixelsCurrentFrame > MaxDisplNetPixels(3), error('Maximum displacement in an OFF frame. Check for max displacement in ALL FRAMES'); end
    if useGPU, displHeatMapPadded = zeros(MD_EPI.imSize_, 'gpuArray');end       
    displHeatMapPadded(Xmin:Xmax,Ymin:Ymax) = displHeatMap;
    displFieldMicronPos = gpuArray(displFieldMicron(CurrentFrame).pos);
    displFieldMicronVec = gpuArray(displFieldMicron(CurrentFrame).vec);
    X = reshape(grid_matX,1,[]);
    Y = reshape(grid_matY,1,[]);
    U = reshape(gather(dMapX),1,[]);
    V = reshape(gather(dMapY),1,[]);

    IsWithinGridSpliced = ones(size(grid_mat));         
    IsWithin = IsWithinGridSpliced(:,:,1) & IsWithinGridSpliced(:,:,2);

    figHandle = figure('visible','on', 'color', 'w', 'Units', 'pixels', 'Toolbar', 'none', 'Menubar', 'none', 'Resize', 'off', 'Colormap',colormapLUT_parula);
    figAxesHandle = axes(figHandle);
    set(figAxesHandle, 'Box', 'on', 'XTick',[], 'YTick', [], 'Visible', 'on', 'YDir', 'reverse', 'Units', 'pixels', 'Colormap', colormap('parula'));  
    imgHandle  = imagesc(figAxesHandle, 'CData', displHeatMapPadded');                % transpose to convert ndgrid to meshgrid for imagesc Cdata
    imgHandle.Interpolation = 'bilinear';
    axis image
    truesize
    hold on        
    colorbarHandle = colorbar('eastoutside');
    caxis(colorbarLimits);
    colorbarTicks = unique(sort([colorbarLimits, colorbarHandle.Ticks])); 
    colorbarTicksExpDefault = colorbarHandle.Ruler.Exponent;   
    colorbarUnits = sprintf('%sm', char(181));   
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
            'FontWeight', 'bold', 'FontName', 'Inconsolata ExtraCondensed', 'LineWidth', QuiverLineWidth, 'Units', 'Pixels', 'FontSize', colorbarFontSize)     % font size, 1/100 of height in pixels     
    colorbarLabelString =  sprintf('\\bf\\itu\\rm(\\itx\\fontsize{%d}*\\fontsize{%d}, y\\fontsize{%d}*\\fontsize{%d}, t\\rm) [%s]', ...
            repmat([ylabelFontSize * 0.75, ylabelFontSize] , 1, 2), colorbarUnits);
    ylabelHandle = ylabel(colorbarHandle, colorbarLabelString);    % 'Displacement (\mum)'; % in Tex format
    ylabelHandle.FontSize = ylabelFontSize;
    ylabelHandle.FontName = FontName2;
    ylabelHandle.Units = 'pixels';

    Location = MD_EPI.imSize_ - [3,3];       
    sBar = scalebar(figAxesHandle,'ScaleLength',ScaleLength_EPI, 'ScaleLengthRatio',ScaleMicronPerPixel_EPI, 'color', colormapLUT_parula(end,:), ...
        'bold',true, 'unit',colorbarUnits, 'location',Location, 'fontname', FontName1, 'fontsize',  scalebarFontSize);
    Location = MD_EPI.imSize_ .* [0, 1] + [3,-3];                  % bottom right corner
    NumDigits = numel(num2str(FramesNumEPI));            %counting the number of digits in the number of frames. E.g., 1000 = 4 digits, 100 is three digits, and so forth.
    FormatSpecifier = sprintf('%%%dg', NumDigits);
    FrameString = sprintf('Frame %s/%s', sprintf(FormatSpecifier, CurrentFrame), sprintf(FormatSpecifier, FramesNumEPI));
    FrameString = sprintf('%s. \\itt\\rm = %6.3fs. %s', FrameString, TimeStampsRT_Abs_EPI(CurrentFrame), FluxStatusString);
    text(figAxesHandle, Location(1), Location(2), FrameString , 'FontSize', sBar.Children(1).FontSize, 'VerticalAlignment', 'bottom', ...
                    'HorizontalAlignment', 'left', 'Color',  colormapLUT_parula(end,:), 'FontName',FontName1, 'Interpreter','tex');    
    Location = [3,3];
    text(figAxesHandle, Location(1), Location(2), TrackingInfoTXT , 'FontSize', sBar.Children(1).FontSize - 3, 'VerticalAlignment', 'top', ...
                    'HorizontalAlignment', 'left', 'Color', colormapLUT_parula(end,:),'FontName',FontName1, 'Interpreter','none');
    quiver(figAxesHandle, X, Y,U .*QuiverScaleToMax,V .*QuiverScaleToMax, 0, ...
                   'MarkerSize',MarkerSize, 'markerfacecolor',QuiverColor, 'ShowArrowHead','on', 'MaxHeadSize', 3, ...
                  'color', QuiverColor, 'AutoScale','on', 'LineWidth', QuiverLineWidth , 'AlignVertexCenters', 'on');
    
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