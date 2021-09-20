%{
        v2019-09-02
            Choose all files at once, and feed them to the rest.
        v2019-08-31
        Written by Waddah Moghram on 2019-09-02|08-31|28..29|26, PhD Student in Biomedical Engineering at the University of Iowa.
        so that I can simply open them and they will compile together under a structure CompiledData
        Load "Compiled Calibration Data" and it will generate the required plots to see what is going on. 
%}
             
%% Plots Inquire for variables.
    clear CompiledAll Figures CompiledData 
    
    FluidChoiceStr = inputdlg('What is the fluid used for these calibrations?');
    if isempty(FluidChoiceStr), return; end
    
    Temperature = inputdlg(strcat('What was the average temperature in (', char(176), 'C) during those experiments?'));
    if isempty(Temperature), return; end        
    
    RelativeHumidity = inputdlg('What was the average relative humidity (%) during those experiments?');
    if isempty(RelativeHumidity), return; end
    
     CalibrationInfo = sprintf('in %s solution. RH = %d%% at %d', FluidChoiceStr{1}, str2double(RelativeHumidity{1}), str2double(Temperature{1}));    
     CalibrationInfo = strcat(CalibrationInfo, char(176),'C');        % Add a degree at the end

%%
    FluxSetpointsGs = [25, 50, 75, 100, 125, 150, 175, 185];            % gauss for flux setpoins chosen. 
    FluxSetpointsGsStr = {};   
    
    for jj = 1:numel(FluxSetpointsGs)
        FluxSetpointsGsStr{end+1} = sprintf('%d Gs', FluxSetpointsGs(jj));
    end
    [indx,tf] = listdlg('ListString',FluxSetpointsGsStr, 'PromptString','Select Flux(es) to be combined:');
    if isempty(indx), return; end        % cancel was selected 
    FluxSetpointsGsChosen = FluxSetpointsGs(indx);
    CompiledAll.CurrentFluxVarNames = {};
    CompiledAll.FluxSetpointsGsStr  = FluxSetpointsGsStr(indx);
    CompiledAll.FluxSetpointsGsChosen = FluxSetpointsGsChosen;
    CompiledAll.FluxSetpointsVarNames = {};
    
    
    %%
    DataPathMain = uigetdir([],'Choose the directory where all the calibration data is located');
    FileList = dir(fullfile(DataPathMain, '**', '*Calibration Compiled Data.mat'));
    CompiledFiles = struct();
    CompiledFiles.FullFileNames  = {};
    for CurrentFlux = FluxSetpointsGsChosen
        for kk = 1:numel(FileList)
            FileFluxGsChosenFileVarName = sprintf('Files%.0fGsChosenFiles', CurrentFlux);
            FileFluxGsAllFileVarName = sprintf('Files%.0fGsChosenFiles', CurrentFlux);
            
%             CompiledFiles.(FileFluxGsAllVarName) = {};
            CompiledFiles.(FileFluxGsChosenFileVarName) = {};
            CompiledFiles.(FileFluxGsAllFileVarName) = {};
                        
            CompiledFiles.FullFileNames{kk} = fullfile(FileList(kk).folder, FileList(kk).name);
            CompiledFiles.CurrentFlux{kk} = load(CompiledFiles.FullFileNames{kk} ,  'FluxSetPoint');
             CurrentFluxFiles(kk) = logical(abs(CompiledFiles.CurrentFlux{kk}.FluxSetPoint) == CurrentFlux);
        end
        CurrentFileList = CompiledFiles.FullFileNames(CurrentFluxFiles);
        CompiledFiles.(FileFluxGsAllFileVarName) =  CurrentFileList;
        [FilesChosenIndex, listTF] = listdlg('PromptString',sprintf('Select %0.f Gs Compiled data files:', CurrentFlux), 'ListString', CurrentFileList, 'ListSize', [700, 400]);
        if listTF == 0, return; end
        CompiledFiles.(FileFluxGsChosenFileVarName) = CurrentFileList(FilesChosenIndex);
    end
    
    %% Make merged folder
    MergedPath = fullfile(DataPathMain, '_Merged'); 
    if ~exist(MergedPath, 'dir'), mkdir(MergedPath); end
    %%
    
    Markers = {'o', '+', '*', 'x', 's', 'd', '^', 'v' , 'p', 'h'}; 
    
    %         figure(Figures.figHandleAllFluxes);
    Figures.figHandleAllFluxes = figure('color', 'w', 'visible', 'off');
    jj = 1;     
    for CurrentFlux = FluxSetpointsGsChosen
        loop = true;
        
        FileFluxGsChosenFileVarName = sprintf('Files%.0fGsChosenFiles', CurrentFlux);
        
        % Initializing
        CurrentFluxAllRunsVarNames =  strcat('Flux',num2str(CurrentFlux),'GsAllRunsVarNames');
        CompiledAll.(CurrentFluxAllRunsVarNames) = {};
        CurrentFluxGsAllRuns = strcat('Flux',num2str(CurrentFlux),'GsAllRuns');
        CurrentForceONGsAllRuns = strcat('ForceON',num2str(CurrentFlux),'GsAllRuns');
        CurrentSeparationDistONGsAllRuns = strcat('SeparationDistON',num2str(CurrentFlux),'GsAllRuns');
         
        FluxSetpointsVarNames = 'FluxSetpointsVarNames';
        CompiledAll.(FluxSetpointsVarNames){end+1} = CurrentFluxGsAllRuns;
        CompiledAll.(CurrentFluxGsAllRuns) = [];         
        CompiledAll.(CurrentForceONGsAllRuns) = [];    
        CompiledAll.(CurrentSeparationDistONGsAllRuns) = [];    
        
        CurrentMaxSepDist = 0;
        AllMaxSepDist = 0;
        RunNameStr = {};
        
        CurrentFigHandle =  strcat('CurrentFigHandle',num2str(CurrentFlux),'Gs');
        Figures.(CurrentFigHandle) = figure('color', 'w');
        ManualSelection = false;
        
        for  ii = 1:numel(CompiledFiles.(FileFluxGsChosenFileVarName))
            try 
                DataFileNameFull = CompiledFiles.(FileFluxGsChosenFileVarName){ii};
            catch
                [DataFileName, DataPathName] = uigetfile(fullfile(DataPathMain, 'Calibration Compiled Data.mat'), sprintf( 'Choose the compiled *.mat for %.0f Gs. Run %0.f', CurrentFlux, ii));
                if DataFileName == 0, return; end             % Cancel was selected
                DataFileNameFull = fullfile( DataPathName, DataFileName);
                ManualSelection = true;
            end
            load(DataFileNameFull, 'CompiledData', 'CompiledDataHeader')
            try
                FolderParts =  regexp(DataFileNameFull, filesep, 'split');
                CurrentRunName = FolderParts{(end-2)}(strfind(upper(FolderParts{(end-2)}), 'RUN'):end);                           % Assuming the structure is like this 'MainFolder\-75Gs Run 1\tracking_output\Calibration Compiled Data.mat'
                                    % find the beginning of the word Run, and select until the end of that folder part
                CurrentRunName(isspace(CurrentRunName)) = [];                       % Trim space
                RunNameStr{ii} = CurrentRunName;
                
                CurrentFluxVarName = strcat('Flux',num2str(CurrentFlux),'Gs', RunNameStr{ii});
                CompiledAll.(CurrentFluxVarName) = CompiledData;                % in case the folder name is not compatible with variables.
            catch
                RunName = inputdlg(sprintf('Enter Run* or any other comments if you want. \n File chosen is: \n(%s)', DataFileNameFull), sprintf('%0.f Gs. #%0.f', CurrentFlux, ii),  1);
                if isempty(RunName{1})
                    RunNameStr{ii} = strcat('Run',num2str(ii));
                else
                    RunNameStr{ii} = RunName{1};
                end
                CurrentFluxVarName = strcat('Flux',num2str(CurrentFlux),'Gs', RunNameStr{ii});
                CompiledAll.(CurrentFluxVarName) = CompiledData;
            end
            CompiledAll.(CurrentFluxAllRunsVarNames){end+1} = CurrentFluxVarName;
            CompiledAll.(CurrentFluxGsAllRuns) = [ CompiledAll.(CurrentFluxGsAllRuns); CompiledData];           
            
            CurrentFluxON = logical(CompiledData(:,21) == 1);                                                                % Column 21 is the flux status: 0 = false, 1 = true
            CurrentSeparationDistanceArrayMicron = CompiledData(CurrentFluxON, 8);                        % Column 8 is the separation distance in microns.
            CurrentForceArray_nN = CompiledData(CurrentFluxON, 19);            % Column 19 is the force the bead experiences in nanoNewtons (nN)
 
            figure(Figures.(CurrentFigHandle));
            plot(CurrentSeparationDistanceArrayMicron, CurrentForceArray_nN, 'LineStyle', 'none' ,'Marker', Markers{mod(ii, numel(Markers))}, 'MarkerSize', 2);
            CaptionCurrentFluxAllRuns = sprintf('Calibration Curve for %d Gs Flux ON, drift-adjusted,', CurrentFlux);     % Drift Excluded
            title({CaptionCurrentFluxAllRuns, CalibrationInfo});
            currentAxis = findobj(Figures.(CurrentFigHandle) ,'type', 'axes');
            set(currentAxis, 'FontSize',10, 'FontWeight','Bold', 'LineWidth',1, 'XMinorTick', 'on', 'YMinorTick', 'on', 'TickDir', 'out');     % Make axes bold
            box(gca, 'off')
            xlabel('Separation Distance, \delta (\mum)');
            CurrentMaxSepDist = max(max(CurrentSeparationDistanceArrayMicron), CurrentMaxSepDist);   
            xlim([0, CurrentMaxSepDist]); 
            ylabel('Force (nN)');     
            
            hold on
            pause (0.1)
            
            if ManualSelection
                AddAnotherRun = questdlg(sprintf('Do you want to add another run data %g Gs?',CurrentFlux ), sprintf('More Data for %g Gs', CurrentFlux), 'Yes', 'No', 'Yes');
                switch AddAnotherRun
                    case 'Yes'
%                         ii = ii + 1;
                        continue
                    case 'No'
                        break
                        % append data 
                    otherwise
                        return
                end
            else                                        % case of automatic selection (not manual).                
                continue
            end        
        end        
        % -------------- saving current flux value.
        legend(RunNameStr);      
        ImageHandle = getframe(Figures.(CurrentFigHandle));     
        Image_cdata = ImageHandle.cdata;
        currentFigureFileNameFIG = fullfile(MergedPath, strcat(CurrentFluxGsAllRuns, '.fig'));
        hgsave(Figures.(CurrentFigHandle), currentFigureFileNameFIG,'-v7.3')                        % save as *.fig file
        currentFigureFileNamePNG = fullfile(MergedPath, strcat(CurrentFluxGsAllRuns, '.png'));
        saveas(Figures.(CurrentFigHandle), currentFigureFileNamePNG);                                                         % save as *.png file
%         currentFigureFileNameTIF = fullfile(MergedPath, strcat(CurrentFluxGsAllRuns, '.tif'));
%         imwrite(Image_cdata, currentFigureFileNameTIF);                                          % save as *.tif format???
        % --------------        
        
       % CompiledAll.(FluxSetpointsVarNames){jj}   is equal to CurrentFluxGsAllRuns
        FluxON = logical(CompiledAll.(CurrentFluxGsAllRuns)(:,21) == 1);                                            % Column 21 is the flux status: 0 = false, 1 = true
        SeparationDistanceArrayMicron = CompiledAll.(CurrentFluxGsAllRuns)(FluxON, 8);                  % Column 8 is the separation distance in microns.
        ForceArray_nN = CompiledAll.(CurrentFluxGsAllRuns)(FluxON,19);                                               % Column 19 is the force the bead experiences in nanoNewtons (nN)
        CompiledAll.(CurrentForceONGsAllRuns) = ForceArray_nN;    
        CompiledAll.(CurrentSeparationDistONGsAllRuns) = SeparationDistanceArrayMicron;    
        
        
        AllMaxSepDist = max(SeparationDistanceArrayMicron);
        figure(Figures.figHandleAllFluxes); 
        plot(SeparationDistanceArrayMicron, ForceArray_nN, 'LineStyle', 'none' ,'Marker', Markers{mod(jj, numel(Markers))}, 'MarkerSize', 2);
        CaptionCurrentFluxAllRuns = 'Calibration Curve for a range of flux values, drift-adjusted';     % Drift Excluded
        title({CaptionCurrentFluxAllRuns, CalibrationInfo});
        hold on
        currentAxis = findobj(Figures.figHandleAllFluxes ,'type', 'axes');
        box(gca, 'off');
        set(currentAxis, 'FontSize',10, 'FontWeight','Bold', 'LineWidth',1, 'XMinorTick', 'on', 'YMinorTick', 'on', 'TickDir', 'out');     % Make axes bold
        xlabel('Separation Distance, \delta (\mum)');
    %     xlim([0, max(SeparationDistanceArrayMicron)]); 
        ylabel('Force (nN)'); 
        xlim([0, AllMaxSepDist]);
%         xAxisLabels = [cellstr(num2str(get(findobj(Figures.figHandleAllFluxes ,'type', 'axes'),'XTick')'))];
%         xAxisLabels{end+1} = num2str(MaxSepDist);
%         set(findobj(Figures.figHandleAllFluxes ,'type', 'axes'), 'XTick',str2double(xAxisLabels));
%         xtickformat(currentAxis, '%.1f');        
        jj = jj + 1;       
    end
    
    % Adding the header
    figure(Figures.figHandleAllFluxes); 
    legend(CompiledAll.FluxSetpointsGsStr);    
    ImageHandle = getframe(Figures.figHandleAllFluxes);     
    Image_cdata = ImageHandle.cdata;
    currentFigureFileNameFIG = fullfile(MergedPath, strcat('AllFluxesMerged', '.fig'));
    hgsave(Figures.figHandleAllFluxes, currentFigureFileNameFIG,'-v7.3')                        % save as *.fig file
    currentFigureFileNamePNG = fullfile(MergedPath, strcat('AllFluxesMerged', '.png'));
    saveas(Figures.figHandleAllFluxes, currentFigureFileNamePNG);                                                         % save as *.png file
%     currentFigureFileNameTIF = fullfile(MergedPath, strcat('AllFluxesMerged', '.tif'));
%     imwrite(Image_cdata, currentFigureFileNameTIF);                                          % save as *.tif format???
    
    
    
    CompiledAll.CompiledDataHeader = CompiledDataHeader; 
    
    %% Saving figures and all variables to the merged folder
    WorkspaceFileName = fullfile(MergedPath, 'CalibrationWorkspace');
    
%     %----------------    
%     % Get a list of all variables
%     allvars = whos;
%     % Identify the variables that ARE NOT graphics handles. This uses a regular
%     % expression on the class of each variable to check if it's a graphics object
%     toSave = cellfun(@isempty, regexp({allvars.class}, '^matlab\.(ui|graphics)\.'));
%     % Pass these variable names to save
%     save(WorkspaceFileName, allvars(toSave).name)
%     %-------------------
    clear currentAxis  Figures Image_cdata ImageHandle               % already saved figures
        %--------------------- to save all including figures    
    save(WorkspaceFileName)
        %---------------------    


%% ============================== CODE DUMPSTER ====== R.I.P. OLD CODE LOL!===========================================================
% 
% 
% 
% % First load 
%     load('Y:\Waddah\2019-08-15 Near-Field Calibration\-25Gs Run 1\tracking_output\Calibration Compiled Data.mat','CompiledData','CompiledDataHeader')
% % compile columns 8 (separation distance) and 18, F_net-no drift from the respective plots
%     FluxStatus25Gs = CompiledData(:,21);
%     SepDist_Force25Gs = [CompiledData(:,8), CompiledData(:,19)];
% % 
% %     Another = true;
% % 
% %     while Another   2 through 5
%         load('Y:\Waddah\2019-08-15 Near-Field Calibration\-25Gs Run 2\tracking_output\Calibration Compiled Data.mat','CompiledData','CompiledDataHeader')
%         % Open the next run 2, and run the line below
%         FluxStatus25Gs = [FluxStatus25Gs; CompiledData(:,21)];
%         SepDist_Force25Gs = [SepDist_Force25Gs; CompiledData(:,8), CompiledData(:,19)];
% 
%         %{
%          once all of the separation and force values are compiled, you can start plotting and deriving the power-law relationship, 
%         using the curve-fitting tool, as well as any other instrument
%         %}
% %     end
% 
%     FluxON25Gs = find(FluxStatus25Gs(:) == 1);
% 
%     fig25Gs = figure('color', 'w');
%     plot(SepDist_Force25Gs(FluxON25Gs,1), SepDist_Force25Gs(FluxON25Gs,2),'.');
%     xlabel('Separation Distance (\mum)')
%     ylabel('Force (nN)')
%     title('Force for 25 Gs')
% 
% %% ---------------- 50 Gs
% % First load "load('..\50Gs Run 1\tracking_output\Calibration Compiled Data.mat')
% % compile columns 8 (separation distance) and 18, F_net-no drift from the respective plots
%     FluxStatus50Gs = CompiledData(:,21);
%     SepDist_Force50Gs = [CompiledData(:,8), CompiledData(:,19)];
% 
% 
%     % Open the next run 2, and run the line below
%     FluxStatus50Gs = [FluxStatus50Gs; CompiledData(:,21)];
%     SepDist_Force50Gs = [SepDist_Force50Gs; CompiledData(:,8), CompiledData(:,19)];
% 
%     %{
%      once all of the separation and force values are compiled, you can start plotting and deriving the power-law relationship, 
%     using the curve-fitting tool, as well as any other instrument
%     %}
% 
%     FluxON50Gs = find(FluxStatus50Gs(:) == 1);
% 
%     fig50Gs = figure('color','w');
%     plot(SepDist_Force50Gs(FluxON50Gs,1), SepDist_Force50Gs(FluxON50Gs,2),'.');
%     xlabel('Separation Distance (\mum)')
%     ylabel('Force (nN)')
%     title('Force for 50 Gs')
% 
% 
% %% ---------------- 75 Gs
% % First load "load('..\50Gs Run 1\tracking_output\Calibration Compiled Data.mat')
% % compile columns 8 (separation distance) and 18, F_net-no drift from the respective plots
%     FluxStatus75Gs = CompiledData(:,21);
%     SepDist_Force75Gs = [CompiledData(:,8), CompiledData(:,19)];
% 
% 
%     % Open the next run 2, and run the line below
%     FluxStatus75Gs = [FluxStatus75Gs; CompiledData(:,21)];
%     SepDist_Force75Gs = [SepDist_Force75Gs; CompiledData(:,8), CompiledData(:,19)];
% 
% %{
%  once all of the separation and force values are compiled, you can start plotting and deriving the power-law relationship, 
% using the curve-fitting tool, as well as any other instrument
% %}
% 
%     FluxON75Gs = find(FluxStatus75Gs(:) == 1);
% 
%     fig75Gs = figure('color','w');
%     plot(SepDist_Force75Gs(FluxON75Gs,1), SepDist_Force75Gs(FluxON75Gs,2),'.');
%     xlabel('Separation Distance (\mum)')
%     ylabel('Force (nN)')
%     title('Force for 75 Gs')
% 
% %% ---------------- 100 Gs
% % First load "load('..\50Gs Run 1\tracking_output\Calibration Compiled Data.mat')
%     % compile columns 8 (separation distance) and 18, F_net-no drift from the respective plots
%     FluxStatus100Gs = CompiledData(:,21);
%     SepDist_Force100Gs = [CompiledData(:,8), CompiledData(:,19)];
% 
% 
%     % Open the next run 2, and run the line below
%     FluxStatus100Gs = [FluxStatus100Gs; CompiledData(:,21)];
%     SepDist_Force100Gs = [SepDist_Force100Gs; CompiledData(:,8), CompiledData(:,19)];
% 
%     %{
%      once all of the separation and force values are compiled, you can start plotting and deriving the power-law relationship, 
%     using the curve-fitting tool, as well as any other instrument
%     %}
% 
%     FluxON100Gs = find(FluxStatus100Gs(:) == 1);
% 
%     fig100Gs = figure('color','w');
%     plot(SepDist_Force100Gs(FluxON100Gs,1), SepDist_Force100Gs(FluxON100Gs,2),'.');
%     xlabel('Separation Distance (\mum)')
%     ylabel('Force (nN)')
%     title('Force for 100 Gs')
% 
% %% ---------------- 125 Gs
% % First load "load('..\50Gs Run 1\tracking_output\Calibration Compiled Data.mat')
% % compile columns 8 (separation distance) and 18, F_net-no drift from the respective plots
% FluxStatus125Gs = CompiledData(:,21);
% SepDist_Force125Gs = [CompiledData(:,8), CompiledData(:,19)];
% 
% 
% % Open the next run 2, and run the line below
% FluxStatus125Gs = [FluxStatus125Gs; CompiledData(:,21)];
% SepDist_Force125Gs = [SepDist_Force125Gs; CompiledData(:,8), CompiledData(:,19)];
% 
% %{
%  once all of the separation and force values are compiled, you can start plotting and deriving the power-law relationship, 
% using the curve-fitting tool, as well as any other instrument
% %}
% 
% FluxON125Gs = find(FluxStatus125Gs(:) == 1);
% 
% figure
% plot(SepDist_Force125Gs(FluxON125Gs,1), SepDist_Force125Gs(FluxON125Gs,2),'.');
% 
% %% ---------------- 150 Gs
% % First load "load('..\50Gs Run 1\tracking_output\Calibration Compiled Data.mat')
% % compile columns 8 (separation distance) and 18, F_net-no drift from the respective plots
% FluxStatus150Gs = CompiledData(:,21);
% SepDist_Force150Gs = [CompiledData(:,8), CompiledData(:,19)];
% 
% 
% % Open the next run 2, and run the line below
% FluxStatus150Gs = [FluxStatus150Gs; CompiledData(:,21)];
% SepDist_Force150Gs = [SepDist_Force150Gs; CompiledData(:,8), CompiledData(:,19)];
% 
% %{
%  once all of the separation and force values are compiled, you can start plotting and deriving the power-law relationship, 
% using the curve-fitting tool, as well as any other instrument
% %}
% 
% FluxON150Gs = find(FluxStatus150Gs(:) == 1);
% 
% figure
% plot(SepDist_Force150Gs(FluxON150Gs,1), SepDist_Force150Gs(FluxON150Gs,2),'.');
% 
% 
% %% ---------------- 175 Gs
% % First load "load('..\50Gs Run 1\tracking_output\Calibration Compiled Data.mat')
% % compile columns 8 (separation distance) and 18, F_net-no drift from the respective plots
% FluxStatus175Gs = CompiledData(:,21);
% SepDist_Force175Gs = [CompiledData(:,8), CompiledData(:,19)];
% 
% 
% % Open the next run 2, and run the line below
% FluxStatus175Gs = [FluxStatus175Gs; CompiledData(:,21)];
% SepDist_Force175Gs = [SepDist_Force175Gs; CompiledData(:,8), CompiledData(:,19)];
% 
% %{
%  once all of the separation and force values are compiled, you can start plotting and deriving the power-law relationship, 
% using the curve-fitting tool, as well as any other instrument
% %}
% 
% FluxON175Gs = find(FluxStatus175Gs(:) == 1);
% 
% figure
% plot(SepDist_Force175Gs(FluxON175Gs,1), SepDist_Force175Gs(FluxON175Gs,2),'.');

%% ---------------- 185 Gs
% First load "load('..\50Gs Run 1\tracking_output\Calibration Compiled Data.mat')
% compile columns 8 (separation distance) and 18, F_net-no drift from the respective plots
% FluxStatus185Gs = CompiledData(:,21);
% SepDist_Force185Gs = [CompiledData(:,8), CompiledData(:,19)];
% 
% 
% % Open the next run 2, and run the line below
% FluxStatus185Gs = [FluxStatus185Gs; CompiledData(:,21)];
% SepDist_Force185Gs = [SepDist_Force185Gs; CompiledData(:,8), CompiledData(:,19)];
% 
% %{
%  once all of the separation and force values are compiled, you can start plotting and deriving the power-law relationship, 
% using the curve-fitting tool, as well as any other instrument
% %}
% 
% FluxON185Gs = find(FluxStatus185Gs(:) == 1);
% 
% figure
% plot(SepDist_Force185Gs(FluxON185Gs,1), SepDist_Force185Gs(FluxON185Gs,2),'.');