    %{
    compiled DIC data
     Written by Waddah Moghram, PhD candidate in Biomedical Engineering

    1. Select the folder for the gel and it will compiled all the bead data for
    DIC
    %}

    GelPath = uigetdir(pwd, 'Select the folder where the bead data are collected');


    %%
    Analysis_DIC_Displ_Files = dir(fullfile(GelPath, '**', 'MagBeadTrackedDisplacements.mat'));
    FileCount = numel(Analysis_DIC_Displ_Files);

    GelPathParts  = strsplit(GelPath, filesep);
    SameGelAnalysisPath = fullfile(GelPath, strcat('Analysis_', GelPathParts{end}));

    try
        mkdir(SameGelAnalysisPath);
    catch
        % folder already exists;
    end

    clear Analysis_DIC_MT_Files
    for ii = 1:FileCount
        Analysis_DIC_MT_Files(ii) = dir(fullfile(Analysis_DIC_Displ_Files(ii).folder, '..', '**', 'MT_Force_Work_Results.mat'));
        disp(Analysis_DIC_MT_Files(ii))
        try
            FileNameForce{ii} = fullfile(Analysis_DIC_MT_Files(ii).folder, Analysis_DIC_MT_Files(ii).name);
            DataForce(ii) = load(FileNameForce{ii});
            SameGelAnalysis{ii}.FileNameForce = FileNameForce{ii};
        catch
            FileNameForce{ii} = [];
            DataForce(ii) = [];
            SameGelAnalysis{ii}.FileNameForce = [];
        end
    end

    patBeadNumber = "B" + digitsPattern(1);
    patRunNumber = "R" + digitsPattern(1);

    patEDCorNOT_ = ("-"|"_") + ("EDC"|"EDAC"|"NoEDC"|"NoEDAC");
    patEDCorNOT = ("EDC"|"EDAC"|"NoEDC"|"NoEDAC");
    
    clear MagBeadCompiledAnalysis

    for ii = 1:FileCount
        FileNameDispl{ii} = fullfile(Analysis_DIC_Displ_Files(ii).folder, Analysis_DIC_Displ_Files(ii).name);
        DataDispl{ii} = load(FileNameDispl{ii});
        SameGelAnalysis{ii}.FileNameDispl = FileNameDispl{ii};
        
       

        SameGelAnalysis{ii}.MagBeadDisplacementMicronXYBigDeltaCorrected = DataDispl{ii}.MagBeadDisplacementMicronXYBigDeltaCorrected;
        SameGelAnalysis{ii}.MagBeadDisplacementMicronXYBigDelta = DataDispl{ii}.MagBeadDisplacementMicronXYBigDelta;    

        try
            SameGelAnalysis{ii}.BeadMaxNetDisplMicronDriftCorrected = DataDispl{ii}.BeadMaxNetDisplMicronDriftCorrected;
            SameGelAnalysis{ii}.BeadMaxNetDisplFrameDriftCorrected = DataDispl{ii}.BeadMaxNetDisplFrameDriftCorrected;
            SameGelAnalysis{ii}.BeadMaxNetDisplMicron = DataDispl{ii}.BeadMaxNetDisplMicron;
            SameGelAnalysis{ii}.BeadMaxNetDisplFrame = DataDispl{ii}.BeadMaxNetDisplFrame;
        catch
            [SameGelAnalysis{ii}.BeadMaxNetDisplMicronDriftCorrected, SameGelAnalysis{ii}.BeadMaxNetDisplFrameDriftCorrected ] = ...
                max(SameGelAnalysis{ii}.MagBeadDisplacementMicronXYBigDeltaCorrected);
            [SameGelAnalysis{ii}.BeadMaxNetDisplMicron, SameGelAnalysis{ii}.BeadMaxNetDisplFrame] = ...
                max( SameGelAnalysis{ii}.MagBeadDisplacementMicronXYBigDelta);        
        end 

        try
            SameGelAnalysis{ii}.BeadNumber =  DataDispl{ii}.BeadNumber;
        catch
            SameGelAnalysis{ii}.BeadNumber = extract(FileNameDispl{ii} , patBeadNumber);
        end
        try
            SameGelAnalysis{ii}.RunNumber =  DataDispl{ii}.RunNumber;
        catch
            RunNumberStr = extract(FileNameDispl{ii} , patRunNumber);
            SameGelAnalysis{ii}.RunNumber = RunNumberStr{:};
        end

        try
            SameGelAnalysis{ii}.EDCorNOT = DataDispl{ii}.EDCorNOT;
            SameGelAnalysis{ii}.EDCorNOTstr = DataDispl{ii}.EDCorNOTstr;
        catch
            EDCorNotStr_ = extract(FileNameDispl{ii} , patEDCorNOT_);
            EDCorNotStr = extract(EDCorNotStr_, patEDCorNOT);
            SameGelAnalysis{ii}.EDCorNOTstr = EDCorNotStr{:};
            switch SameGelAnalysis{ii}.EDCorNOTstr
                case {"EDC", "EDAC"}
                    SameGelAnalysis{ii}.EDCorNOT = true;
                otherwise
                    SameGelAnalysis{ii}.EDCorNOT = false;
            end
        end
        EDCorNot(ii) = SameGelAnalysis{ii}.EDCorNOT;
        BeadNumber{ii} = SameGelAnalysis{ii}.BeadNumber;
        SameGelAnalysis{ii}.thickness_um = DataDispl{ii}.thickness_um;
        SameGelAnalysis{ii}.GelConcentrationMgMl = DataDispl{ii}.GelConcentrationMgMl;
        SameGelAnalysis{ii}.GelConcentrationMgMlStr = DataDispl{ii}.GelConcentrationMgMlStr;
        SameGelAnalysis{ii}.GelPolymerizationTempC = DataDispl{ii}.GelPolymerizationTempC;
        SameGelAnalysis{ii}.GelSampleNumber = DataDispl{ii}.GelSampleNumber;
        SameGelAnalysis{ii}.TimeStampsRT_Abs_DIC = DataDispl{ii}.TimeStampsRT_Abs_DIC;
        SameGelAnalysis{ii}.ScaleMicronPerPixel = DataDispl{ii}.ScaleMicronPerPixel;
        SameGelAnalysis{ii}.TrackingMethod = DataDispl{ii}.TrackingMethod;
        SameGelAnalysis{ii}.TrackingMode = DataDispl{ii}.TrackingMode;
        SameGelAnalysis{ii}.MagnificationTimesStr = DataDispl{ii}.MagnificationTimesStr;
        SameGelAnalysis{ii}.GelType = DataDispl{ii}.GelType;
        SameGelAnalysis{ii}.NumFramesTracked = min(numel(DataDispl{ii}.TimeStampsRT_Abs_DIC), numel(DataDispl{ii}.MagBeadDisplacementMicronXYBigDeltaCorrected)); 

        try
            FileNameMT{ii} = fullfile(Analysis_DIC_MT_Files{ii}.folder, Analysis_DIC_MT_Files{ii}.name);
            DataMT{ii} = load(FileNameMT{ii});
            fname = fieldnames(DataMT{ii}.CompiledMT_Results);
            for jj = 1:numel(DataMT)
                SameGelAnalysis{ii}.(fname{jj}) = DataMT{ii}.CompiledMT_Results.(fname{jj});
            end
        catch
            % continue
        end
    end   

    SameGelAnalysisFile = fullfile(SameGelAnalysisPath, 'SameGel_Compiled_Results.mat');
    save(SameGelAnalysisFile, 'SameGelAnalysis', '-v7.3')
    fprintf('Gel-wide data analysis is saved as:\n\t%s\n', SameGelAnalysisFile);

    %% Generating plots now and average
    figDisplacementsEDC = figure('color', 'white', 'Visible', 'off');        
    figDisplacementsNoEDC = figure('color', 'white', 'Visible', 'off');    
    figForceEDC = figure('color', 'white', 'Visible', 'off');
    figForceNoEDC = figure('color', 'white', 'Visible', 'off');

    for ii = 1:FileCount
        if SameGelAnalysis{ii}.EDCorNOT
            figure(figDisplacementsEDC);
            tmpStr = strcat(SameGelAnalysis{ii}.BeadNumber, '_', SameGelAnalysis{ii}.RunNumber);
            try
                CurrentLineLegend = tmpStr{:};
            catch
                CurrentLineLegend = tmpStr;
            end
            plot(SameGelAnalysis{ii}.TimeStampsRT_Abs_DIC(1:SameGelAnalysis{ii}.NumFramesTracked), ...
                SameGelAnalysis{ii}.MagBeadDisplacementMicronXYBigDeltaCorrected(1:SameGelAnalysis{ii}.NumFramesTracked), ...
                'DisplayName', CurrentLineLegend)
            xlim([SameGelAnalysis{ii}.TimeStampsRT_Abs_DIC(1), SameGelAnalysis{ii}.TimeStampsRT_Abs_DIC(end)])
            hold on
            legend('interpreter','none', 'Location', 'eastoutside')

            try
                figure(figForceEDC);
                plot(SameGelAnalysis{ii}.TimeStampsRT_Abs_DIC(1:SameGelAnalysis{ii}.NumFramesTracked), ...
                    SameGelAnalysis{ii}.Force_xy_nN(1:SameGelAnalysis{ii}.NumFramesTracked), ...
                    'DisplayName', CurrentLineLegend)
                xlim([SameGelAnalysis{ii}.TimeStampsRT_Abs_DIC(1), SameGelAnalysis{ii}.TimeStampsRT_Abs_DIC(end)])
                hold on
                legend('interpreter','none', 'Location', 'eastoutside')
            catch
                % continue
            end
        else
            figure(figDisplacementsNoEDC);
            tmpStr = strcat(SameGelAnalysis{ii}.BeadNumber, '_', SameGelAnalysis{ii}.RunNumber);
            try
                CurrentLineLegend = tmpStr{:};
            catch
                CurrentLineLegend = tmpStr;
            end
            LastFrame = min(numel(SameGelAnalysis{ii}.TimeStampsRT_Abs_DIC), numel(SameGelAnalysis{ii}.MagBeadDisplacementMicronXYBigDeltaCorrected));
            plot(SameGelAnalysis{ii}.TimeStampsRT_Abs_DIC(1:LastFrame), ...
                SameGelAnalysis{ii}.MagBeadDisplacementMicronXYBigDeltaCorrected(1:LastFrame), ...
                'DisplayName', CurrentLineLegend)
            xlim([SameGelAnalysis{ii}.TimeStampsRT_Abs_DIC(1), SameGelAnalysis{ii}.TimeStampsRT_Abs_DIC(end)])
            hold on
            legend('interpreter','none', 'Location', 'eastoutside')

            try             % TFM package was not run
                figure(figForceNoEDC);
                plot(SameGelAnalysis{ii}.TimeStampsRT_Abs_DIC(1:SameGelAnalysis{ii}.NumFramesTracked), ...
                    SameGelAnalysis{ii}.Force_xy_nN(1:SameGelAnalysis{ii}.NumFramesTracked), ...
                    'DisplayName', CurrentLineLegend)
                xlim([SameGelAnalysis{ii}.TimeStampsRT_Abs_DIC(1), SameGelAnalysis{ii}.TimeStampsRT_Abs_DIC(end)])
                hold on
                legend('interpreter','none', 'Location', 'eastoutside')
            catch
                % continue
            end
        end
    end

    figure(figDisplacementsEDC)
    title({sprintf('Displacement EDC Treatment. %s @ %s', SameGelAnalysis{1}.GelConcentrationMgMlStr, SameGelAnalysis{1}.GelPolymerizationTempC), ...
        sprintf('Gel Sample ID: %s', GelPathParts{end})}, 'interpreter', 'none')
    xlabel('Time, [s]')
    ylabel(sprintf('Displacement_{net} (%sm)', char(181)))
    set(findobj(figDisplacementsEDC,'type', 'axes'), ...
        'FontSize',12, ...
        'FontName', 'Helvetica', ...
        'LineWidth',1, ...
        'XMinorTick', 'on', ...
        'YMinorTick', 'on', ...
        'TickDir', 'out', ...
        'TitleFontSizeMultiplier', 0.9, ...
        'TitleFontWeight', 'bold', ...
        'Box', 'off');     % Make axes bold           

    figure(figDisplacementsNoEDC);
    title({sprintf('Displacement NO EDC Treatment. %s @ %s', SameGelAnalysis{1}.GelConcentrationMgMlStr, SameGelAnalysis{1}.GelPolymerizationTempC), ...
        sprintf('Gel Sample ID: %s', GelPathParts{end})}, 'interpreter', 'none')
    xlabel('Time, [s]')
    ylabel(sprintf('Displacement_{net} (%sm)', char(181)))
    set(findobj(figDisplacementsNoEDC,'type', 'axes'), ...
        'FontSize',12, ...
        'FontName', 'Helvetica', ...
        'LineWidth',1, ...
        'XMinorTick', 'on', ...
        'YMinorTick', 'on', ...
        'TickDir', 'out', ...
        'TitleFontSizeMultiplier', 0.9, ...
        'TitleFontWeight', 'bold', ...
        'Box', 'off');     % Make axes bold    

    figure(figForceEDC)
    title({sprintf('Traction Force EDC Treatment. %s @ %s', SameGelAnalysis{1}.GelConcentrationMgMlStr, SameGelAnalysis{1}.GelPolymerizationTempC), ...
        sprintf('Gel Sample ID: %s', GelPathParts{end})}, 'interpreter', 'none')
    xlabel('Time, [s]')
    ylabel('F_{net} (nN)')
    set(findobj(figForceEDC,'type', 'axes'), ...
        'FontSize',12, ...
        'FontName', 'Helvetica', ...
        'LineWidth',1, ...
        'XMinorTick', 'on', ...
        'YMinorTick', 'on', ...
        'TickDir', 'out', ...
        'TitleFontSizeMultiplier', 0.9, ...
        'TitleFontWeight', 'bold', ...
        'Box', 'off');     % Make axes bold    

    figure(figForceNoEDC)
    title({sprintf('Traction Force NO EDC Treatment. %s @ %s', SameGelAnalysis{1}.GelConcentrationMgMlStr, SameGelAnalysis{1}.GelPolymerizationTempC), ...
        sprintf('Gel Sample ID: %s', GelPathParts{end})}, 'interpreter', 'none')
    xlabel('Time, [s]')
    ylabel('F_{net} (nN)')
    set(findobj(figForceNoEDC,'type', 'axes'), ...
        'FontSize',12, ...
        'FontName', 'Helvetica', ...
        'LineWidth',1, ...
        'XMinorTick', 'on', ...
        'YMinorTick', 'on', ...
        'TickDir', 'out', ...
        'TitleFontSizeMultiplier', 0.9, ...
        'TitleFontWeight', 'bold', ...
        'Box', 'off');     % Make axes bold    

% Saving plots so far
    figDisplacementsEDC_fig = fullfile(SameGelAnalysisPath, 'SameGel_MagBeadsDispl_EDC.fig');
    savefig(figDisplacementsEDC, figDisplacementsEDC_fig, 'compact')    
    figForceEDC_fig = fullfile(SameGelAnalysisPath, 'SameGel_MagBeadsForce_EDC.fig');
    savefig(figForceEDC, figForceEDC_fig, 'compact')    
    figDisplacementsNoEDC_fig = fullfile(SameGelAnalysisPath, 'SameGel_MagBeadsDispl_NoEDC.fig');
    savefig(figDisplacementsNoEDC, figDisplacementsNoEDC_fig, 'compact')
    figForceNoEDC_fig = fullfile(SameGelAnalysisPath, 'SameGel_MagBeadsForce_NoEDC.fig');
    savefig(figForceNoEDC, figForceNoEDC_fig, 'compact')


    figDisplacementsEDC_png = fullfile(SameGelAnalysisPath, 'SameGel_MagBeadsDispl_EDC.png');
    saveas(figForceEDC, figDisplacementsEDC_png, 'png')    
    figForceEDC_png = fullfile(SameGelAnalysisPath, 'SameGel_MagBeadsForce_EDC.png');
    saveas(figDisplacementsEDC, figForceEDC_png, 'png')    
    figDisplacementsNoEDC_png = fullfile(SameGelAnalysisPath, 'SameGel_MagBeadsDispl_NoEDC.png');
    saveas(figDisplacementsNoEDC, figDisplacementsNoEDC_png, 'png')
    figForceNoEDC_png = fullfile(SameGelAnalysisPath, 'SameGel_MagBeadsForce_NoEDC.png');
    saveas(figForceNoEDC, figForceNoEDC_png, 'png')

    fprintf('Same gel plots are saved under:\n\t%s\n', SameGelAnalysisPath);
    close all

    %% Now by bead
    [UniqueBeadNumbers, UniqueBeadIndex] = unique(BeadNumber, 'stable');
    clear AllBeadNumbersIndexed
    for ii = 1:numel(UniqueBeadNumbers)
        for jj = 1:numel(BeadNumber)
            AllBeadNumbersIndexed(jj, ii) = strcmpi(UniqueBeadNumbers{ii},BeadNumber{jj});
        end
    end
    UniqueBeadNumbersCount = sum(AllBeadNumbersIndexed);

    for ii = 1:numel(UniqueBeadNumbers)
       figDisplacementsBead{ii} = figure('color', 'white', 'Visible', 'on', 'Name', UniqueBeadNumbers{ii}); 
       figDisplacementsBeadHandle(ii) = axes(figDisplacementsBead{ii});       
    end
    for ii = 1:numel(UniqueBeadNumbers) 
        figure(figDisplacementsBead{ii})
        for jj = find(AllBeadNumbersIndexed(:, ii))'
            CurrentBeadStruct = SameGelAnalysis{jj};
            try
                tmpStr = strcat(CurrentBeadStruct.EDCorNOTstr, '_', CurrentBeadStruct.RunNumber);
            catch
                tmpStr = strcat(CurrentBeadStruct.EDCorNOTstr, '_', CurrentBeadStruct.RunNumber{:});
            end
            if iscell(tmpStr), tmpStr = tmpStr{:}; end
            if CurrentBeadStruct.EDCorNOT
                PlotColor = 'b'; 
                PlotLineStyle = '--';
            else
                PlotColor = 'r'; 
                PlotLineStyle = '-';                
            end
            LastFrame = min(numel(CurrentBeadStruct.TimeStampsRT_Abs_DIC), numel(CurrentBeadStruct.MagBeadDisplacementMicronXYBigDeltaCorrected));
            plot(figDisplacementsBeadHandle(ii), CurrentBeadStruct.TimeStampsRT_Abs_DIC(1:LastFrame), ...
                    CurrentBeadStruct.MagBeadDisplacementMicronXYBigDeltaCorrected(1:LastFrame), 'DisplayName', tmpStr, ...
                    'Color', PlotColor, 'LineStyle', PlotLineStyle)
            xlim([SameGelAnalysis{ii}.TimeStampsRT_Abs_DIC(1), SameGelAnalysis{ii}.TimeStampsRT_Abs_DIC(LastFrame)])
            hold on
            legend('interpreter','none', 'location', 'eastoutside')
        end
    end
    for ii = 1:numel(UniqueBeadNumbers) 
        figure(figDisplacementsBead{ii})
        CurrentGelStruct = SameGelAnalysis{ii};        
        titleStr1 = sprintf('%.0f %sm-thick, %.1f mg/mL %s', SameGelAnalysis{ii}.thickness_um, char(181), ...
            SameGelAnalysis{ii}.GelConcentrationMgMl, SameGelAnalysis{ii}.GelType{1});
        titleStr2 = sprintf('Magnetic Bead #%d (%s)', sscanf(UniqueBeadNumbers{ii}, 'B%d'), UniqueBeadNumbers{ii});
        titleStr = {titleStr1, titleStr2};          
        xlabel('Time, [s]')
        ylabel(sprintf('Displacement_{net} (%sm)', char(181)))
        title(titleStr)
        set(figDisplacementsBeadHandle(ii), ...
            'FontSize',12, ...
            'FontName', 'Helvetica', ...
            'LineWidth',1, ...
            'XMinorTick', 'on', ...
            'YMinorTick', 'on', ...
            'TickDir', 'out', ...
            'TitleFontSizeMultiplier', 0.9, ...
            'TitleFontWeight', 'bold', ...
            'Box', 'off');     % Make axes bold           
        pause(0.5)
%         
        figDisplacementsBead_fig = fullfile(SameGelAnalysisPath, sprintf('SameMagBead_%s_Displ.fig',UniqueBeadNumbers{ii}));
        savefig(figDisplacementsBead{ii}, figDisplacementsBead_fig, 'compact')
        figDisplacementsBead_png = fullfile(SameGelAnalysisPath, sprintf('SameMagBead_%s_Displ.png',UniqueBeadNumbers{ii}));
        saveas(figDisplacementsBead{ii}, figDisplacementsBead_png, 'png')
        
        fprintf('Plots are saved as:\n\t%s\n\t%s\n', figDisplacementsBead_fig,figDisplacementsBead_png)
    end
    close all
%________________________________________________________________________________________________________________
    for ii = 1:numel(UniqueBeadNumbers)
        figForceBead{ii} = figure('color', 'white', 'Visible', 'on', 'Name', UniqueBeadNumbers{ii}); 
        figForceBeadHandle(ii) = axes(figForceBead{ii});
    end
    for ii = 1:numel(UniqueBeadNumbers) 
        figure(figForceBead{ii})
        for jj = find(AllBeadNumbersIndexed(:, ii))'
            CurrentBeadStruct = SameGelAnalysis{jj};
            try
                tmpStr = strcat(CurrentBeadStruct.EDCorNOTstr, '_', CurrentBeadStruct.RunNumber);
            catch
                tmpStr = strcat(CurrentBeadStruct.EDCorNOTstr, '_', CurrentBeadStruct.RunNumber{:});
            end
            if iscell(tmpStr), tmpStr = tmpStr{:}; end
            if CurrentBeadStruct.EDCorNOT
                PlotColor = 'b'; 
                PlotLineStyle = '--';
            else
                PlotColor = 'r'; 
                PlotLineStyle = '-';                
            end
            plot(figForceBeadHandle(ii), CurrentBeadStruct.TimeStampsRT_Abs_DIC, ...
                    CurrentBeadStruct.Force_xy_nN, 'DisplayName', tmpStr, ...
                    'Color', PlotColor, 'LineStyle', PlotLineStyle)
            xlim([SameGelAnalysis{ii}.TimeStampsRT_Abs_DIC(1), SameGelAnalysis{ii}.TimeStampsRT_Abs_DIC(end)])
            hold on
            legend('interpreter','none', 'location', 'eastoutside')
        end
    end
    for ii = 1:numel(UniqueBeadNumbers) 
        figure(figForceBead{ii})
        CurrentGelStruct = SameGelAnalysis{ii};        
        titleStr1 = sprintf('%.0f %sm-thick, %.1f mg/mL %s', SameGelAnalysis{ii}.thickness_um, char(181), ...
            SameGelAnalysis{ii}.GelConcentrationMgMl, SameGelAnalysis{ii}.GelType{1});
        titleStr2 = sprintf('Magnetic Bead #%d (%s)', sscanf(UniqueBeadNumbers{ii}, 'B%d'), UniqueBeadNumbers{ii});
        titleStr = {titleStr1, titleStr2};          
        xlabel('Time, [s]')
        ylabel('Force_{net} (nN)')
        title(titleStr)
        set(figForceBeadHandle(ii), ...
            'FontSize',12, ...
            'FontName', 'Helvetica', ...
            'LineWidth',1, ...
            'XMinorTick', 'on', ...
            'YMinorTick', 'on', ...
            'TickDir', 'out', ...
            'TitleFontSizeMultiplier', 0.9, ...
            'TitleFontWeight', 'bold', ...
            'Box', 'off');     % Make axes bold           
        pause(0.5)
%         
        figForcesBead_fig = fullfile(SameGelAnalysisPath, sprintf('SameMagBead_%s_Force.fig',UniqueBeadNumbers{ii}));
        savefig(figForceBead{ii}, figForcesBead_fig, 'compact')
        figForcesBead_png = fullfile(SameGelAnalysisPath, sprintf('SameMagBead_%s_Force.png',UniqueBeadNumbers{ii}));
        saveas(figForceBead{ii}, figForcesBead_png, 'png')
        
        fprintf('Plots are saved as:\n\t%s\n\t%s\n', figForcesBead_fig,figForcesBead_png);
    end
    close all
    
    %% Saving files
