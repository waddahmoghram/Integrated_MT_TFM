%{
    v.2019-12-14 by Waddah Moghram
        1. pos_grid for input, and pos_grid_stress for padded output
        2. Change the file name from "Filters_LowPassGaussian2D.m" to "Filters_LowPassExponential2D.m"
    v.2019-12->> by Waddah Moghram
        1. Temporary code to conduct 2D Exponential Filters and then conduct FTTC using the convolution with Q-matrix directly.

%}
FirstFrame =1 ;
LastFrame = numel(displField);
MD = movieData;

dlgQuestion = ({'Do you want to integrated or sum the force Field?'});
dlgTitle = 'Integration?';
intMethodStr = questdlg(dlgQuestion, dlgTitle, 'Integrated: Tiled', 'Integrated: Iterated', 'Summed', 'Integrated: Iterated');
switch intMethodStr
    case 'Integrated: Tiled'
        intMethod = 'tiled';
    case 'Integrated: Iterated'
        intMethod = 'iterated';
    case 'Summed'
        intMethod = 'summed';                
end   

commandwindow;
filmThicknessDefault = forceFieldParameters.thickness / 1000;           % convert from nm to microns.
filmThickness = input(sprintf('What is the film thickness in microns [Default = %g microns]: ', filmThicknessDefault));
if isempty(filmThickness)
    filmThickness = filmThicknessDefault;
end
fprintf('Film thickness assumed %d microns. \n', filmThickness);

fracpadDefault = 0.5; 
fracpad = input(sprintf('What is the fraction of view to pad on either side? [Default = %g]: ', fracpadDefault));
if isempty(fracpad)
    fracpad = fracpadDefault;
end
fprintf('fraction of field of view to pad displacements on either side of current fov+extrapolated to get high k contributions to Q: %g \n', fracpad);            

min_feature_sizeDefault = 1;
min_feature_size = input(sprintf('What is the minimum feature size in tracking code in pixels? [Default = %g pixels]: ', min_feature_sizeDefault));
if isempty(min_feature_size)
    min_feature_size = min_feature_sizeDefault;
end            
fprintf('Minimum feature selected is %g pixels. \n', min_feature_size);

[disp_grid, stress_grid] = Filters_LowPassGaussian2D(disp_grid_NoFilter, gridSpacing, [], [], forceFieldParameters.YoungModulusPa,...
    forceFieldParameters.PoissonRatio, fracpad, min_feature_size, 2, [],[],[]);

pos_grid_stress = pos_grid;            

filteringMethod = [filteringMethod, ' Min Feature ', num2str(min_feature_size), ' Pix'];

dlgQuestion = ({'File Format(s) for images?'});
listStr = {'PNG', 'FIG', 'EPS'};
PlotChoice = listdlg('ListString', listStr, 'PromptString',dlgQuestion, 'InitialValue', [1,2], 'SelectionMode' ,'multiple');    
PlotChoice = listStr(PlotChoice);                 % get the names of the string.   

try
    forceFieldCalculationInfo =  MD.findProcessTag('ForceFieldCalculationProcess');
    forceFieldFileName = forceFieldCalculationInfo.outFilePaths_{1};
    [forceFieldPath, ~, ~] = fileparts(forceFieldFileName);      
catch
    forceFilePath = uigetdir(forceFilePath, 'Directory where you want to store the traction force in');
    if forceFilePath == 0, return; end
end
TractionForcesFileName = sprintf('TractionForces_%s.mat', intMethod);
TractionForcesOutputFile = fullfile(forceFieldPath, TractionForcesFileName);

clear displFieldCorrected  displFieldPos displFieldVecNoDrift displFieldVecMean displFieldVecCorrected displFieldCorrected

displFieldCorrected(LastFrame).pos = [];
displFieldCorrected(LastFrame).vec = [];
displFieldCorrected(LastFrame).drift = [];
displFieldCorrected(LastFrame).vecCorrected = [];

displFieldFiltered(LastFrame).pos = [];
displFieldFiltered(LastFrame).vec = [];

stressFieldFiltered(LastFrame).pos = [];
stressFieldFiltered(LastFrame).vec = [];

% odd for LowPassGaussian
[reg_grid,~,~,gridSpacing] = createRegGridFromDisplFieldOdd(displField,2.0, 1);


for FrameNum = 1:LastFrame
    displFieldPos(:, :, FrameNum)  = displField(FrameNum).pos;
    displFieldVecNoDrift(:,:, FrameNum)  = displField(FrameNum).vec;  
end


displFieldVecMean = mean(displFieldVecNoDrift, 'omitnan');             % pixels per second
displFieldVecCorrected = displFieldVecNoDrift(:,1:2,:) - displFieldVecMean(:,1:2, :);

for FrameNum = 1:LastFrame
    displFieldCorrected(FrameNum).pos = displFieldPos(:,:, FrameNum);
    displFieldCorrected(FrameNum).vec = displFieldVecCorrected(:,:,FrameNum);
    displFieldCorrected(FrameNum).vecdrift = displFieldVecMean(:,:, FrameNum);    
end

for FrameNum = 1:LastFrame    
    [pos_grid, disp_grid_NoFilter, i_max,j_max] = interp_vec2grid(displFieldPos(:,:,FrameNum), displFieldVecNoDrift(:,:, FrameNum),[], reg_grid, InterpolationMethod);
    
    disp_grid_NoFilter(:,:,3) = sqrt(disp_grid_NoFilter(:,:,1).^2 + disp_grid_NoFilter(:,:,2).^2);       % Third column is the net displacement in grid form
    
    [disp_grid, stress_grid] = Filters_LowPassExponential2D(pos_grid,disp_grid_NoFilter(:,:,1:2), 0.5, gridSpacing, min_feature_size, ...
                filmThickness, filmThickness, forceFieldParameters.YoungModulus, forceFieldParameters.YoungModulusPa);
 
    displFieldFiltered(FrameNum).pos = displFieldPos(:,:, FrameNum);
    displFieldFiltered(FrameNum).vec = disp_grid;
    
    stressFieldFiltered(FrameNum).pos = displFieldPos(:,:, FrameNum);
    stressFieldFiltered(FrameNum).vec = stress_grid;
end

clear TractionForceFilteredX TractionForceFilteredY TractionForceFiltered
intMethod = 'Summed';
tolerance = 1e-13;          % not needed really

for FrameNum = 1:LastFrame  
    fprintf('Starting Frame %d/%d. \n', FrameNum, LastFrame);
            % Loading the respective traction file variables            
    [Force] =  TractionForceSingleFrame(MD, stressFieldFiltered, FrameNum, intMethod, tolerance);     
    try
        TractionForceFilteredX(FrameNum) = gather(Force(:,1));
        TractionForceFilteredY(FrameNum) = gather(Force(:,2));
    catch
        TractionForceFilteredX(FrameNum) = Force(:,1);
        TractionForceFiltereY(FrameNum) = Force(:,2);
    end
    TractionForceFiltered(FrameNum) = Force(:,3);
end


TractionForceX = TractionForceFilteredX;
TractionForceY = TractionForceFilteredY;
TractionForce = TractionForceFiltered;

try
    forceFieldCalculationInfo =  MD.findProcessTag('ForceFieldCalculationProcess');
    forceFieldFileName = forceFieldCalculationInfo.outFilePaths_{1};
    [forceFieldPath, ~, ~] = fileparts(forceFieldFileName);      
catch
    forceFilePath = uigetdir(forceFilePath, 'Directory where you want to store the traction force in');
    if forceFilePath == 0, return; end
end
TractionForcesFileName = sprintf('TractionForces_%s.mat', intMethod);
TractionForcesOutputFile = fullfile(forceFieldPath, TractionForcesFileName);


 %%
    commandwindow;
    GelConcentrationMgMl = input('What was the gel concentration in mg/mL? ');  
    fprintf('Gel Concentration Chosen is %d  mg/mL. \n', GelConcentrationMgMl);
    
    %----------------------------------------------
    try
        try
            thickness_um = forceFieldCalculationInfo.funParams_.thickness_nm/1000;
        catch
            thickness_um = forceFieldCalculationInfo.funParams_.thickness/1000;
        end
    catch
        thickness_um = [];
    end
    if isempty(thickness_um)
        thickness_um = input('What was the gel thickness in microns? ');  
        fprintf('Gel thickness is %d  microns. \n', thickness_um);
    else
        fprintf('Gel thickness found is %d microns. \n', thickness_um);
    end

    %----------------------------------------------
    try
        YoungModulusPa = forceFieldCalculationInfo.funParams_.YoungModulusPa;
    catch
        YoungModulusPa = [];
    end
    if isempty(YoungModulusPa)
        YoungModulusPa = input('What was the gel''s Young Elastic modulus (in Pa)? ');  
        fprintf('Gel''s elastic modulus (E) is %g Pa. \n', YoungModulusPa);
    else
        fprintf('Gel''s elastic modulus (E) found is %g Pa. \n', YoungModulusPa);        
    end

    %----------------------------------------------
    try
        PoissonRatio = forceFieldCalculationInfo.funParams_.PoissonRatio;
    catch
        PoissonRatio = [];
    end
    if isempty(PoissonRatio)
        PoissonRatio = input('What was the gel''s Young Elastic modulus (in Pa)? ');  
        fprintf('Gel''s Poisson Ratio (nu) is %g. \n', PoissonRatio);
    else
        fprintf('Gel''s Poisson Ratio (nu) found is %g. \n', PoissonRatio);        
    end    
    
    try
        try
            [TimeFrames, ~, AverageFrameRate] = ND2TimeFrameExtract(MD.channels_.channelPath_);
        catch
            [TimeFrames, ~, AverageFrameRate] = ND2TimeFrameExtract(MD.movieDataPath_);            
        end
        FrameRate = 1/AverageFrameRate;
    catch
        try 
            FrameRate = 1/MD.timeInterval_;
        catch
            FrameRate = 1/ 0.025;           % (40 frames per seconds)              
        end
    end
    
%% PLOT
    FramePlotted(1:LastFrame) = ~isnan(TractionForce(1:LastFrame));
    hold on
    params = 'r-';     
    titleStr1 = sprintf('Traction force, F, for %.0f', thickness_um);
    titleStr1 = strcat(titleStr1, '-\mum,');
    titleStr1 = strcat(titleStr1, sprintf('%.1f mg/mL collagen type-I gel', GelConcentrationMgMl));
    titleStr2 = sprintf('Young Moudulus = %.1f Pa. Poisson Ratio = %.2f', YoungModulusPa, PoissonRatio);
    titleStr3 = sprintf('Traction stresses %s ', lower(intMethodStr));
    titleStr = {titleStr1, titleStr2, titleStr3};
    
    showPlot = 'on';
    figHandleAll = figure('visible',showPlot, 'color', 'w');     % added by WIM on 2019-02-07. To show, remove 'visible    
    
    subplot(3,1,1)
    plot(TimeFrames(FramePlotted), TractionForce(FramePlotted),params)
    title(titleStr);
    ylabel('|F_{TFM,xy}| (N)');
    set(gca, 'FontSize',9, 'FontWeight','Bold', 'LineWidth',1, 'XMinorTick', 'on', 'YMinorTick', 'on', 'TickDir', 'out')
    xlim([TimeFrames(FirstFrame), TimeFrames(LastFrame)]);
    
    hold on    
    subplot(3,1,2)
    plot(TimeFrames(FramePlotted), TractionForceX(FramePlotted),params)
    ylabel('F_{TFM,x} (N)')
    set(gca, 'FontSize',9, 'FontWeight','Bold', 'LineWidth',1, 'XMinorTick', 'on', 'YMinorTick', 'on', 'TickDir', 'out')
    xlim([TimeFrames(FirstFrame), TimeFrames(LastFrame)]);
    
    subplot(3,1,3)
    plot(TimeFrames(FramePlotted), - TractionForceY(FramePlotted),params)       % Flip the y-coordinates to Cartesian
    xlabel('Time (s)')
    ylabel('F_{TFM,y} (N)')
    set(gca, 'FontSize',9, 'FontWeight','Bold', 'LineWidth',1, 'XMinorTick', 'on', 'YMinorTick', 'on', 'TickDir', 'out')
    xlim([TimeFrames(FirstFrame), TimeFrames(LastFrame)]);
    
    hold off    
    
    figHandleNetOnly = figure('visible',showPlot, 'color', 'w');     % added by WIM on 2019-02-07. To show, remove 'visible    
    plot(TimeFrames(FramePlotted), TractionForce(FramePlotted),params)
    title(titleStr);
    ylabel('|F_{TFM,xy}| (N)');
    set(gca, 'FontSize',9, 'FontWeight','Bold', 'LineWidth',1, 'XMinorTick', 'on', 'YMinorTick', 'on', 'TickDir', 'out')
    xlabel('Time (s)')
    xlim([TimeFrames(FirstFrame), TimeFrames(LastFrame)]);   
    
    %% Plots


 for CurrentFrame = 1:numel(PlotChoice)
    tmpPlotChoice =  PlotChoice{CurrentFrame};
    switch tmpPlotChoice
        case 'PNG'                  % PNG SAVE. Consider replacing TIF to PNG.  %                 saveas(figFluxV, figureFileNames{2,1}, 'png');
            fileNamePNG1 = sprintf('TractionForcesPlot_%s.png', intMethod);
            TractionForcePNG1 = fullfile(forceFilePath, fileNamePNG1);
            saveas(figHandleAll, TractionForcePNG1, 'png');

            fileNamePNG2 = sprintf('TractionNetForcePlot_%s.png', intMethod);
            TractionForcePNG2 = fullfile(forceFilePath, fileNamePNG2);
            saveas(figHandleNetOnly, TractionForcePNG2, 'png');                

            if exist(AnalysisPath,'dir') 
                AnalysisFileNamePNG1 = sprintf('10 TractionForcesPlot_%s.png', intMethod);                    
                AnalysisTractionForcePNG1 = fullfile(AnalysisPath, AnalysisFileNamePNG1);
                saveas(figHandleAll, AnalysisTractionForcePNG1);

                AnalysisFileNamePNG2 = sprintf('10 TractionNetForcePlot_%s.png', intMethod);                    
                AnalysisTractionForcePNG2 = fullfile(AnalysisPath, AnalysisFileNamePNG2);
                saveas(figHandleNetOnly, AnalysisTractionForcePNG2);                                
            end

        case 'FIG'
            fileNameFIG1 = sprintf('TractionForcesPlot_%s.fig', intMethod);
            TractionForceFIG1 = fullfile(forceFilePath, fileNameFIG1);                
            hgsave(figHandleAll, TractionForceFIG1,'-v7.3')

            fileNameFIG2 = sprintf('TractionNetForcePlot_%s.fig', intMethod);
            TractionForceFIG2 = fullfile(forceFilePath, fileNameFIG2);                
            hgsave(figHandleNetOnly, TractionForceFIG2,'-v7.3')                

            if exist(AnalysisPath,'dir') 
                AnalysisFileNameFIG1 = sprintf('10 TractionForcesPlot_%s.fig', intMethod);                    
                AnalysisTractionForceFIG1 = fullfile(AnalysisPath, AnalysisFileNameFIG1);                    
                hgsave(figHandleAll, AnalysisTractionForceFIG1,'-v7.3')    

                AnalysisFileNameFIG2 = sprintf('10 TractionNetForcePlot_%s.fig', intMethod);                    
                AnalysisTractionForceFIG2 = fullfile(AnalysisPath, AnalysisFileNameFIG2);                    
                hgsave(figHandleNetOnly, AnalysisTractionForceFIG2,'-v7.3')                        
            end

        case 'EPS'
            fileNameEPS1 = sprintf('TractionForcesPlot_%s.eps', intMethod);
            TractionForceEPS1 = fullfile(forceFilePath, fileNameEPS1);                          
            print(figHandleAll, TractionForceEPS1,'-depsc')   

            fileNameEPS2 = sprintf('TractionNetForcePlot_%s.eps', intMethod);
            TractionForceEPS2 = fullfile(forceFilePath, fileNameEPS2);                          
            print(figHandleNetOnly, TractionForceEPS2,'-depsc')                   

            if exist(AnalysisPath,'dir') 
                AnalysisFileNameEPS1 = sprintf('10 TractionForcesPlot_%s.eps', intMethod);                    
                AnalysisTractionForceEPS1 = fullfile(AnalysisPath, AnalysisFileNameEPS1);                                     
                print(figHandleAll, AnalysisTractionForceEPS1,'-depsc')

                AnalysisFileNameEPS2 = sprintf('10 TractionNetForcePlot_%s.eps', intMethod);                    
                AnalysisTractionForceEPS2 = fullfile(AnalysisPath, AnalysisFileNameEPS2);                                     
                print(figHandleNetOnly, AnalysisTractionForceEPS2,'-depsc')                    
            end
        otherwise
             return
    end
end

    % ---------------------------------------------------------------------------------------
    disp('Traction Force Plots over time have been Generating! Process Complete!')