%{
    v.2020-02-11 by Waddah Mogharm
        1. TractionForceSingleFrameNoMD(...ScaleMicronPerPixel)
    v.2019-12-13 updated by Waddah Moghram. 
        1. Fixed Exponential method and Gaussian Filtering methods.
    v.2019-11-21..24 update by Waddah Moghram
        1. Updated for low-pass filters.
        2. Add statistical test to see if drift is the same along the right and left sides.
        3. Gives the user the ability to select the rectangle that will conduct the calculations.
        4. Update filters: Wiener, ButterWorth, and Low-Pass Exponential.

    v.2019-11-20 update by Waddah Moghram
        1. Added code to pad the displacement array with random values and 0's using "PadArraRandomAndZeros.m"
        2. Adjusted code accordingly to be compatible. 
        3. Added a reshape function to the output of the FTTC from array to grid
        4. Renamed Filtering_Script_Single_Frame_Plots.m to Filters_SingleFramePlots.m

    v.2019-11-17 update by Waddah Moghram
        1. Add Bioformats path if the file read is not working
        2. updated to have the heatmap in the right orientation using imagesc( , , 'Cdata', tranpose of grid matrix). 

    v.2019-11-11 update by Waddah Moghram 
        1. Added a section to filter in the Fourier Domain based on:
            Xu, Y., et al., PNAS 107(34): 14964-14967 (2010). Code was included in supplemental information.
            Style et al., Soft Matter 10, 4047 (2014).
        2. Use Odd-grid point numbers and see if that will make any difference in FTTC calcutions
        3. Updated drift-corrections based on a small rectangular at the top-left most window, and bottom-left windows average velocities.

    v.2019-11-04..08 
        Written by Waddah Moghram on 2019-11-04..08 to speed up calculating the proces
    This code is supposed to be output the following:
        1. Drift-Corrected Displacements vs. Non-Drift-Corrected Displacements
            * Grid generation for displacement method is "ScatteredInterpolant, but you can change it to "Griddata"

        2. Filter displacement grid: 
            1. Wiener2() adaptive 2D:
                a. Vary Window Size. 
                b. Noise Level. Ignore this option
            2. 2D Low-Pass Gaussian Filter
            3. Ad-hoc Filter
            4. medfilt2()  ** maybe **

        3. Create the following Plots:
            1. Displacement grid, 3D, Unfiltered (original), Displacement-Corrected
            2. Displacement grid, 3D, Filtered, Displacement-Corrected
            3. Traction Stress grid, 3D, Unfiltered (original), Displacement-Corrected
            4. Traction Stress grid, 3D, Filtered, Displacement-Corrected
    
        4. Calculate Traction Forces, Save output to a *.mat 
        5. Plot displacement or traction magnitudes against quivers in 2D using imagesc(unique(X_ndgrid), unique(Y_ndgrid), Z_ndgrid)
%}

%% Questions: remember to clear all previous variables since this is a script and not a function
%     clear
if ~exist('InterpolationMethod', 'var')
    RepeatExperimemntChoice = 'No';
else
    RepeatExperimemntChoice = questdlg('Do you want to use the same parameters as before?', 'Repeat Experiments with Same Parameters?','Yes', 'No', 'No'); 
end

dlgQuestion = ({'Do want to create an odd- or even-numbers grid?'});
dlgTitle = 'Odd or Even Grid?';
GridtypeChoiceStr = questdlg(dlgQuestion, dlgTitle, 'Even Grid', 'Odd Grid', 'Even Grid');  

dlgQuestion = ({'Pad displacement array?'});
PaddingListStr = {'No padding', 'Padded with random & zeros', 'Padded with zeros only'};
PaddingChoice = listdlg('ListString', PaddingListStr, 'PromptString',dlgQuestion ,'InitialValue', 2, 'SelectionMode' ,'single');    
PaddingChoiceStr = PaddingListStr{PaddingChoice};                 % get the names of the string.  
    

dlgQuestion = ({'Filtering method?'});
FilterListStr = {'No-Filter', 'Wiener 2D', 'Low-Pass Gaussian 2D', 'Low-Pass Butterworth', 'Median', 'Ad-hoc'};
FilterChoice = listdlg('ListString', FilterListStr, 'PromptString',dlgQuestion ,'InitialValue', 1, 'SelectionMode' ,'single');    
FilterChoiceStr = FilterListStr{FilterChoice};                 % get the names of the string.   
switch FilterChoiceStr
    case  'Wiener 2D'
    %% 2.2 Han Windows
    HanWindowchoice = questdlg('Do you want to add a Han Window?', 'Han Window?', 'Yes', 'No', 'Yes');
    otherwise
        % continue
end

%% 0.0
switch RepeatExperimemntChoice
    case 'No'
        %% 0.1 Initial Variables 
        InterpolationMethod = 'ScatteredInterpolant';
        fprintf('Grid interpolation function is: %s. \n', InterpolationMethod);
        TractionStressMethod = 'FTTC';
        fprintf('Method used to calculate traction stress from displacement field is: %s. \n', TractionStressMethod);
        TractionForceMethod = 'Summed';
        fprintf('Method used to calculate traction force from traction stress field is: %s. \n', TractionForceMethod);

        [ScaleMicronPerPixel, ~, MagnificationTimes] = MagnificationScalesMicronPerPixel([]); 

        %% 0.2 load tracked displacement file displField.mat
        if exist('DisplacementFileFullName', 'var') && exist('displField', 'var')
            DisplacementFieldchoice = questdlg(sprintf('Do you want to use this displacement field file? \n\t %s', DisplacementFileFullName), 'Displacement Field?','Yes', 'No', 'Yes');
        else
            DisplacementFieldchoice = 'No';
        end
        switch DisplacementFieldchoice
            case 'Yes'
                % Continue Do nothing 
            case 'No'
                [displacementFileName, displacementFilePath] = uigetfile(fullfile(pwd,'TFMPackage','*.mat'), 'Open the displacement field "displField.mat" under displacementField or backups');
                DisplacementFileFullName = fullfile(displacementFilePath, displacementFileName);
                try
                    load(DisplacementFileFullName, 'displField');   
                    fprintf('Displacement Field (displField) File is successfully loaded!: \n\t %s\n', DisplacementFileFullName);
                    disp('------------------------------------------------------------------------------')
                catch
                    errordlg('Could not open the displacement field file.');
                    return
                end
            otherwise
                return
        end
        
        
        %% 0.5 Ask for Frame number
         % Frame # FrameNum
        LastFrame = numel(displField);
        FrameNum = input(sprintf('Enter the Frame Number to be analyzed (Last Frame = %d): ', LastFrame));
        
        %% 0.4 Choose an analysis folder
        if exist('AnalysisPath', 'var')
            AnalysisPathchoice = questdlg(sprintf('Do you want to use this analysis path? \n\t %s', AnalysisPath), 'Analysis Path?','Yes', 'No', 'Yes');
        else
            AnalysisPathchoice = 'No';
        end
        switch AnalysisPathchoice
            case 'Yes'
                % Continue do nothing
            case 'No'
                AnalysisPath = uigetdir(fullfile(displacementFilePath, '..'),'Choose the analysis directory where the heatmap output will be saved.');     
                if AnalysisPath == 0  % Cancel was selected
                    clear AnalysisPath;
                elseif ~exist(AnalysisPath,'dir')   % Check for a directory
                    mkdir(AnalysisPath);
                end
                fprintf('Analysis folder is: \n\t %s \n', AnalysisPath)  
            otherwise
                return
        end
        
        %% 0.3 load forceFieldParameter.mat,
        if exist('forceFieldParametersFullFileName', 'var') && exist('forceFieldParameters', 'var')
            forceFieldParametersFileChoice = questdlg(sprintf('Do you want to use this force field parameters file? \n\t %s', forceFieldParametersFullFileName), 'Force Field Parameters?','Yes', 'No', 'Yes'); 
        else
            forceFieldParametersFileChoice = 'No';
        end
        switch forceFieldParametersFileChoice
            case 'Yes'
                % do nothing
            case 'No'
                [forceFieldParametersFile, forceFieldparametersPath] = uigetfile(fullfile(fullfile(displacementFilePath, '..'), '*.mat'), ' open the forceFieldParameters.mat file');  
                forceFieldParametersFullFileName = fullfile(forceFieldparametersPath, forceFieldParametersFile);   
                forceFieldProcessStruct = load(forceFieldParametersFullFileName);
                forceFieldCalculationInfo = forceFieldProcessStruct.forceFieldProc;
                fprintf('forceField paramters successfully: \n\t %s \n', forceFieldParametersFullFileName)
                forceFieldParameters = forceFieldProcessStruct.forceFieldParameters;   
            %--- Images Color depth
                try
                    ImageBits = MD.camBitdepth_ - 2;   % Typically if 16 bits are used. Then image will be saved in 14 bits.
                catch
                    ImageBits = 14;
                end
                TxRedColorMap =  [linspace(0,1,2^ImageBits)', zeros(2^ImageBits,2)];                   % TexasRed ColorMap for Epi Images.
            otherwise
                return
        end
        try
            MD = forceFieldProcessStruct.movieDataAfter;
        catch
            MD = forceFieldProcessStruct.movieData;        
        end
        
        %% 0.4 calculate L-curve parameters for the first time
        switch GridtypeChoiceStr
            case 'Even Grid'
                [reg_grid,~,~,gridSpacing] = createRegGridFromDisplField(displField(FrameNum),2.0,1);             % Grid twice as dense as the inidividual beads
            case 'Odd Grid'  
                [reg_grid,~,~,gridSpacing] = createRegGridFromDisplFieldOdd(displField(FrameNum),2.0,1);          % Grid twice as dense as the inidividual beads
            otherwise
                % continue
        end
        % Edge Erode to make it a square grid        
        [pos_grid, disp_grid_NoFilter, i_max,j_max] = interp_vec2grid(displField(FrameNum).pos(:,1:2), displField(FrameNum).vec(:,1:2),[], reg_grid, InterpolationMethod);        
        % Initial 
        gridXmin = min(displField(FrameNum).pos(:,1));
        gridXmax = max(displField(FrameNum).pos(:,1));
        gridYmin = min(displField(FrameNum).pos(:,2));
        gridYmax = max(displField(FrameNum).pos(:,2));
        % part below is no good
%         gridXmin = min(pos_grid(:,1));
%         gridXmax = max(pos_grid(:,1));
%         gridYmin = min(pos_grid(:,2));
%         gridYmax = max(pos_grid(:,2));

        switch GridtypeChoiceStr
            case 'Even Grid'
                switch RepeatExperimemntChoice
                    case 'No'
                        UseAvailableRegCornerChoice = '';
                        if exist('reg_corner','var')
                            dlgQuestion = ({sprintf('Do you want to use the available regularization parameters: %g?', reg_corner)});
                            dlgTitle = 'Previous L-Curve??';
                            UseAvailableRegCornerChoice = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No', 'Yes');
                        end
                        switch UseAvailableRegCornerChoice
                            case 'Yes'
                                LoadPreviousLCurveChoice = 'Use Current Value';
                            otherwise
                                dlgQuestion = ({'Do want to Load a Previous L-Curve "LCurveData.mat" Value for FTTC?'});
                                dlgTitle = 'Previous L-Curve??';
                                LoadPreviousLCurveChoice = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No', 'Yes');
                        end
                        switch LoadPreviousLCurveChoice
                            case 'Yes'
                                [LCurveFile, LCurvePath] = uigetfile(fullfile(forceFieldparametersPath,'*.mat'), ' open "LCurveData.mat" file');  
                                LCurveFullFileName = fullfile(LCurvePath, LCurveFile);   
                                load(LCurveFullFileName, 'eta', 'ireg_corner', 'reg_corner', 'rho');  
                            case 'No'
                                disp('Calculating L-Curve values in progress...');
                                [rho,eta,reg_corner,alphas] = calculateLcurveFTTC(pos_grid, disp_grid_NoFilter, forceFieldParameters.YoungModulus,...
                                    forceFieldParameters.PoissonRatio, gridSpacing, i_max, j_max, forceFieldParameters.regParam,forceFieldParameters.LcurveFactor);
                                disp('Calculating L-Curve values completed!');
                                [reg_corner,ireg_corner,~,hLcurve] = regParamSelecetionLcurve(alphas',eta,alphas,reg_corner,'manualSelection',true);
                            case 'Use Current Value'
                                % Continue do nothing
                            otherwise
                                return
                        end
                end
            case 'Odd Grid'  
                warning('Grid needs to be even for the L-Curve to be calculated')
            otherwise
                % INCOMPLETE
        end


        %% 0.6 --- Load EPI image and adjust contrast
        try
            curr_Image = MD.channels_.loadImage(FrameNum);
            curr_ImageAdjust = imadjust(curr_Image, stretchlim(curr_Image,[0.05,0.999]));       
        catch
            BioformatsPath = uigetdir([], 'Select directory containing bioformats folder (e.g., TFMpackagefolder)');
            addpath(genpath(BioformatsPath));        % include subfolders
            curr_Image = MD.channels_.loadImage(FrameNum);
            curr_ImageAdjust = imadjust(curr_Image, stretchlim(curr_Image,[0.05,0.999]));       
        end        

        %% 0.7 Load position and displacement vectors for current frame (FrameNum)
        %CorrectDisplacementMeanDrift subtract the mean displacement from a window 
        %   Detailed explanation goes here
        displFieldPos = displField(FrameNum).pos;
        displFieldVecNotDriftCorrected = displField(FrameNum).vec;
        displFieldVecNotDriftCorrected(:,3) = vecnorm(displFieldVecNotDriftCorrected(:,1:2), 2, 2);

        %___________
        clear displFieldVecMean corner_noise   

        figHandle = figure('color', 'w');
        set(figHandle, 'Position', [475, 435, 825, 575])
        figAxesHandle = gca;
        colormap(TxRedColorMap);
        imagesc(figAxesHandle, 1, 1, curr_ImageAdjust);
        hold on
        quiver(figAxesHandle, displFieldPos(:,1), displFieldPos(:,2), displFieldVecNotDriftCorrected(:,1), displFieldVecNotDriftCorrected(:,2), 'y.')
        set(figAxesHandle, 'FontWeight', 'bold','LineWidth',1, 'XMinorTick', 'on', 'YMinorTick', 'on', 'TickDir', 'out', 'Box', 'on')    
        xlabel('X (pixels)'), ylabel('Y (pixels)')
        axis image

        corner_noise(1).pos = [];
        corner_noise(1).vec = [];
        corner_noise(1).mean = [];
        clear indata
        indata(1).Index = [];
        cornerCount = 4;
        clear rect rectHandle rectCorners xx yy nxx corner_noise


        dlgQuestion = ({'Do want identical four rectangular corners for noise adjustment?'});
        dlgTitle = 'Identical Four Corners??';
        IdenticalCornersChoice = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No', 'Yes');
        switch IdenticalCornersChoice
            case 'No'
                for ii = 1:cornerCount                    % four corners
        %             [xx,yy] = getline('closed');
                    titleStr1 = sprintf('Select ROI **%d/%d**', ii, cornerCount);
                    title({titleStr1, 'ROI Position: _____', 'Double-Click on Last ROI when finished with adjusting all ROIs'})
        %             rect(ii,:) = getrect(figAxesHandle);
                    rectHandle(ii) = imrect(figAxesHandle);
                    addNewPositionCallback(rectHandle(ii),@(p) title({titleStr1, strcat('ROI Position [X,Y,W,H]=', char(32), mat2str(p,3), char(32), 'pixels'), 'Double-Click on Last ROI when finished with adjusting all ROIs'})); 
                    ConstraintFunction = makeConstrainToRectFcn('imrect',get(figAxesHandle,'XLim'),get(figAxesHandle,'YLim'));
                end        
                wait(rectHandle(cornerCount));
        %         waitfor(figHandle)
                for ii = 1:cornerCount
                    fprintf('Coordinates Extracted for ROI %d/%d\n', ii, cornerCount);
                    rect(ii,:) = rectHandle(ii).getPosition;
                end
            case 'Yes'
                CornerPercentageDefault = 0.075;             % 5 percent of size
                commandwindow;
                inputStr = sprintf('Choose the percentage of the images size to use for noise adjustment [Default = %0.2g%%]: ', CornerPercentageDefault * 100);
                CornerPercentage = input(inputStr);
                if isempty(CornerPercentage)
                   CornerPercentage =  CornerPercentageDefault; 
                else
                   CornerPercentage = CornerPercentage / 100;
                end
                cornerLengthPix_X = round(CornerPercentage * (gridXmax - gridXmin));
                cornerLengthPix_Y = round(CornerPercentage * (gridYmax - gridYmin));
                % Top Left Corner: ROI 1:
                rect(1,:) = [gridXmin, gridYmin, cornerLengthPix_X, cornerLengthPix_Y];
                rect(2,:) = [gridXmin, gridYmax - cornerLengthPix_Y, cornerLengthPix_X, cornerLengthPix_Y];
                rect(3,:) = [gridXmax - cornerLengthPix_X, gridYmin, cornerLengthPix_X, cornerLengthPix_Y];
                rect(4,:) = [gridXmax - cornerLengthPix_X, gridYmax - cornerLengthPix_Y, cornerLengthPix_X, cornerLengthPix_Y];                
                for jj = 1:cornerCount
                   rectHandle(jj) = drawrectangle('Position', rect(jj, :), 'Color', 'g'); 
                end
            otherwise
                return;
        end
        for ii = 1:cornerCount
            rectCorners = [rect(ii, 1:2); rect(ii, 1:2) + [rect(ii, 3), 0]; rect(ii, 1:2) + [0, rect(ii, 4)]; rect(ii, 1:2) + rect(ii, 3:4)];
            xx(ii,:) = rectCorners(:,1)';
            yy(ii,:) = rectCorners(:,2)';
            if isempty(xx(ii,:)) || isempty(yy(ii,:))
                errordlg('The selected noise is empty.','Error');
                return;
            end
            nxx(ii, :) = size(xx(ii));
            if isempty(xx(ii)) || nxx(ii,1)==2
                errordlg('Noise does not select','Error');
                return;
            end
            indata(ii).Index = inpolygon(displFieldPos(:,1),displFieldPos(:,2),xx(ii,:),yy(ii,:));
            corner_noise(ii).pos = displFieldPos(indata(ii).Index, :);
            corner_noise(ii).vec = displFieldVecNotDriftCorrected(indata(ii).Index,:);
            corner_noise(ii).mean = mean(corner_noise(ii).vec, 'omitnan'); 
        end
        % conduct a statistical to see if there the net drift on the right side is equal to the left side
        LeftSide = [corner_noise(1).vec(:,3); corner_noise(2).vec(:,3)];
        LeftSideMean = mean(LeftSide, 'omitnan');
        RightSide = [corner_noise(3).vec(:,3); corner_noise(4).vec(:,3)];
        RightSideMean = mean(RightSide, 'omitnan');
        SidesMeanDiffPix = RightSideMean - LeftSideMean;
        SidesMeanDiffMicron = SidesMeanDiffPix * ScaleMicronPerPixel;
        SigLevel = 0.05;
        SignificantDisplacementMicron = 1;                  % 1 microns 
        SignificantDisplacementPixel = SignificantDisplacementMicron / ScaleMicronPerPixel;
        [h,p,ci,stats] = ttest2(LeftSide,RightSide,'Vartype', 'equal', 'Alpha', SigLevel, 'Tail', 'both');

        if p < SigLevel && abs(SidesMeanDiffPix) > SignificantDisplacementPixel    % statistically and practically significant difference.
           fprintf('Mean Difference between the left side and the right side are statistically & practically significant. \n\tMean Difference = %g pixels, or %g microns.\n', SidesMeanDiffPix, SidesMeanDiffMicron );
        elseif p < SigLevel && abs(SidesMeanDiffPix) < SignificantDisplacementPixel
           fprintf('Mean Difference between the left side and the right side are statistically, but not pratically, significant. \n\tMean Difference = %0.3g pixels, or %0.3g microns < %0.3g microns.\n', SidesMeanDiffPix, SidesMeanDiffMicron, SignificantDisplacementMicron);
        else
           fprintf('Mean Difference between the left side and the right side failed to be rejected as statistically significant. \n')
        end
        corner_noise_combined.pos = [];
        corner_noise_combined.vec = [];
        corner_noise_combined.mean = [];
        for mm = 1:cornerCount
            corner_noise_combined.pos = [corner_noise_combined.pos; corner_noise(mm).pos];
            corner_noise_combined.vec = [corner_noise_combined.vec; corner_noise(mm).vec];
        end
        corner_noise_combined.mean = mean(corner_noise_combined.vec, 'omitnan');
        corner_noise_combined.mean(:,3) = vecnorm(corner_noise_combined.mean(1:2), 2, 2);

        displFieldVecDriftCorrected(:,1:2) = displFieldVecNotDriftCorrected(:,1:2) - corner_noise_combined.mean(:,1:2);
        displFieldVecDriftCorrected(:,3) = vecnorm(displFieldVecDriftCorrected(:,1:2), 2, 2); 

        DCchoice = questdlg('Do you want to use drift-correct displacements?', 'Drift Correction','Yes', 'No', 'Yes');
        switch DCchoice
            case 'Yes'
                DCchoiceStr = 'Drift Corrected';
                displFieldVec = displFieldVecDriftCorrected;
            case 'No'
                DCchoiceStr = 'Drift Uncorrected';
                displFieldVec = displFieldVecNotDriftCorrected;
        end

    case 'Yes'
        % continue
    otherwise
        return
end
        
%% 1.0 Choose Drift-Correction Type (if any) & Choose filter type. Choose even or odd number of grid.          
    clear pos_grid disp_grid_NoFilter
    [pos_grid, disp_grid_NoFilter, i_max,j_max] = interp_vec2grid(displFieldPos(:,1:2), displFieldVec(:,1:2),[], reg_grid, InterpolationMethod);
    disp_grid_NoFilter(:,:,3) = sqrt(disp_grid_NoFilter(:,:,1).^2 + disp_grid_NoFilter(:,:,2).^2);       % Third column is the net displacement in grid form

%% 2.0 Padding the Array with random edge displacement readings and 0's 
    switch PaddingChoiceStr
        case 'No padding'
            % do nothing
            [i_max,j_max, ~] = size(disp_grid_NoFilter);
        case 'Padded with random & zeros'
            [disp_grid_NoFilter, ~, disp_grid_NoFilter_TopLeftCorner, disp_grid_NoFilter_BottomRightCorner] =  PadArrayRandomAndZeros(disp_grid_NoFilter);
            [i_max,j_max, ~] = size(disp_grid_NoFilter);
        case 'Padded with zeros only'
            [disp_grid_NoFilter, ~, disp_grid_NoFilter_TopLeftCorner, disp_grid_NoFilter_BottomRightCorner] =  PadArrayRandomAndZeros(disp_grid_NoFilter, true);
            [i_max,j_max, ~] = size(disp_grid_NoFilter);
        otherwise
            return
    end
   
%% 2.3 Filtering the displacement field  
    filteringMethod = [FilterChoiceStr, char(32), DCchoiceStr];
    clear pos_grid_stress
    switch FilterChoiceStr
        case 'No-Filter'
            clear disp_grid
            disp_grid = disp_grid_NoFilter;
            filteringMethod = [filteringMethod, char(32), 'Not Han-Windowed'];
            
        case 'Wiener 2D'
            clear disp_grid
            commandwindow;
            windowSizeChoice = input('What is the length size (in pixels) for the square window in Wiener Filter? ');
            windowSize = [windowSizeChoice, windowSizeChoice];
            disp('=============================================================================')
            fprintf('%s [%dx%d] pixels window.\n', filteringMethod, windowSize)
            for i = 1:3, disp_grid(:,:,i) = wiener2(disp_grid_NoFilter(:,:,i), windowSize); end 
            
            filteringMethod = [filteringMethod, char(32), num2str(windowSize(1)), 'by', num2str(windowSize(2)), ' pix',  char(32), PaddingChoiceStr];
            switch HanWindowchoice
                case 'Yes'
                    disp_grid = HanWindow(disp_grid);
                    filteringMethod = [filteringMethod, char(32), 'Han-Windowed'];
                    HanWindowBoolean = true;
                case 'No'
                    HanWindowBoolean = false;
                    % Continue
            end            
            
        case  'Low-Pass Gaussian 2D'              
            %------ parameters--------
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
            fprintf('fraction of field of view to pad displacements on either side of current fov + extrapolated to get high k contributions to Q: %g \n', fracpad);            
            
            min_feature_sizeDefault = 1;
            min_feature_size = input(sprintf('What is the minimum feature size in tracking code in pixels? [Default = %g pixels]: ', min_feature_sizeDefault));
            if isempty(min_feature_size)
                min_feature_size = min_feature_sizeDefault;
            end            
            fprintf('Minimum feature selected is: %g pixels. \n', min_feature_size);
            
            ExpOrderDefault = 2;
            ExpOrder = input(sprintf('What is the order of the Gaussian exponential filter? [Default = %g]: ', ExpOrderDefault));
            if isempty(ExpOrder)
                ExpOrder = ExpOrderDefault;
            end            
            fprintf('Gaussian Exponential Order is: %g. \n', ExpOrder);
            
            [pos_grid_stress, disp_grid, stress_grid] = Filters_LowPassExponential2D(pos_grid, disp_grid_NoFilter, gridSpacing, filmThickness, filmThickness,  forceFieldParameters.YoungModulus, forceFieldParameters.PoissonRatio, ...
                fracpad, min_feature_size, ExpOrder, reg_corner, i_max, j_max);
                   
            filteringMethod = [filteringMethod, ' Min Feature ', num2str(min_feature_size), ' Order = ', num2str(ExpOrder), ' Pix. Han-Windowed.'];
            
        case 'Low-Pass Butterworth'
            fracpadDefault = 0.5; 
            fracpad = input(sprintf('What is the fraction of view to pad on either side? [Default = %g]: ', fracpadDefault));
            if isempty(fracpad)
                fracpad = fracpadDefault;
            end
            fprintf('fraction of field of view to pad displacements on either side of current fov+extrapolated to get high k contributions to Q: %g \n', fracpad);            
            
            BW_orderDefault = 3;
                BW_order = input(sprintf('What is the order of the Butterworth filter? [Default = %g]: ', BW_orderDefault));
            if isempty(BW_order)
                BW_order = BW_orderDefault;
            end
            fprintf('Butterworth filter order is %g.\n', BW_order);
            
            [disp_grid, stress_grid] = Filters_LowPassButterworth2D(disp_grid_NoFilter, gridSpacing, [], [],  forceFieldParameters.YoungModulus, forceFieldParameters.PoissonRatio, ...
                fracpad, 3, BW_order, i_max, j_max);
            
            pos_grid_stress = pos_grid;            
            filteringMethod = [filteringMethod, ' BW order ', num2str(BW_order)];
    end
    
%% 2.3 calculate the traction stress field "forceField" in Pa and       
    %----- Unfiltered Case ----------
    if ~exist('stress_grid', 'var')
        switch TractionStressMethod
            case 'FTTC'
                switch GridtypeChoiceStr
                    case 'Even Grid'
                        [pos_grid_stress,~, stress_grid, stress_grid_norm] = reg_fourier_TFM(pos_grid, disp_grid(:,:,1:2), forceFieldParameters.YoungModulus,...
                            forceFieldParameters.PoissonRatio, MD.pixelSize_/1000, gridSpacing, i_max, j_max, reg_corner);
                        stress_grid(:,3) = stress_grid_norm;
                    case 'Odd Grid'
                        % output is embedded in LowPassGaussian2DFilter
                        [pos_grid_stress,~, stress_grid, stress_grid_norm] = reg_fourier_TFM_odd(pos_grid, disp_grid(:,:,1:2), forceFieldParameters.YoungModulus,...
                        forceFieldParameters.PoissonRatio, MD.pixelSize_/1000, gridSpacing, i_max, j_max, reg_corner);
                        stress_grid(:,3) = stress_grid_norm;
                end
        end
    end
    % reshape for grid
    pos_grid_size = size(pos_grid);
    disp_grid_size = size(disp_grid);
    try
        pos_grid_stress = reshape(pos_grid_stress, pos_grid_size);
    catch
        pos_grid_stress = pos_grid;
        % continue. Dimensions are correct already.
    end
    try
        stress_grid = reshape(stress_grid, disp_grid_size);
    catch
        % continue. Dimensions are correct already.
    end
    
%% 2.4 Trim the displacement  integration traction force in N ============     
    switch PaddingChoiceStr
        case { 'Padded with random & zeros', 'Padded with zeros only'}                       
            for ii = 1:3
                disp_grid_trimmed(:,:,ii) = disp_grid(disp_grid_NoFilter_TopLeftCorner(1):disp_grid_NoFilter_BottomRightCorner(1) , disp_grid_NoFilter_TopLeftCorner(2):disp_grid_NoFilter_BottomRightCorner(2), ii);
                stress_grid_trimmed(:,:,ii) = stress_grid(disp_grid_NoFilter_TopLeftCorner(1):disp_grid_NoFilter_BottomRightCorner(1) , disp_grid_NoFilter_TopLeftCorner(2):disp_grid_NoFilter_BottomRightCorner(2), ii);
            end
                        
            clear disp_grid stress_grid
            disp_grid = disp_grid_trimmed;
            stress_grid = stress_grid_trimmed;
        case 'No padding'
            % do nothing
        otherwise
            return
    end

%% 2.5 Calculate the integration traction force in N ============ 
    switch TractionForceMethod
        case 'Summed'
            % Integrate the traction stresses
            if numel(size(stress_grid)) == 3         % is 3-layer grids
                TractionForceN = TractionForceSingleFrameNoMD(pos_grid_stress, stress_grid(:,:,1:2), ScaleMicronPerPixel);
            else
                TractionForceN = TractionForceSingleFrameNoMD(pos_grid_stress, stress_grid(:,1:2), ScaleMicronPerPixel);                     % 
            end
    end
    traction_fileName_1 = sprintf('01 %s Traction Unfiltered workspace.mat', filteringMethod);
    traction_fullfilename_1 = fullfile(AnalysisPath, traction_fileName_1);
    save(traction_fullfilename_1, 'pos_grid','disp_grid', 'TractionForceN', 'corner_noise', 'corner_noise_combined','rect', 'rectCorners','-v7.3')    
        
%% 3.0 ======================== Plot Displacement and Traction ==================
%--- Plot net displacements in 3D ----------------------------------------------------------------
    figHandle1_1 = figure('color', 'w');
    set(figHandle1_1, 'Position', [75, 35, 825, 575])
    surf(pos_grid(:,:,1), pos_grid(:,:,2), disp_grid(:,:,3))
    view(2);% Show from above (XY view)
    xlim([0, MD.imSize_(1)]); ylim([0, MD.imSize_(2)]);    
    set(gca, 'ydir', 'reverse', 'Box', 'on')
    shading interp
    colormap(parula(2^ImageBits));                  % try winter also. parula shows more noise levels
    colorbarHandle = colorbar;
    ylabel(colorbarHandle, 'Displacement (pixels)')
    set(colorbarHandle, 'FontWeight', 'bold')
%     caxis([-0.1, 0.1])                                % standardize it for all plots
    titleStr1_1 = sprintf('Net Displacement Grid 3D - %s - %s', InterpolationMethod);
    titleStr1_2 = sprintf('%s', filteringMethod);
    title({titleStr1_1, titleStr1_2})
%     zlim([-1, 1])                                  % standardize it for all plots.
    xlabel('X (pixels)'), ylabel('Y (pixels)'), zlabel('Displacement (pixels)')                 % note, it is reversed since surf() uses meshgrid() vs. griddata use ndgrid()
    set(gca, 'FontWeight', 'bold')    
%   hold on, plot3(displFieldPos(:,1), displFieldPos(:,2), displFieldVec(:,3), 'o', 'MarkerSize', 2, 'MarkerFaceColor', 'b', 'MarkerEdgeColor', 'w')
    disp_grid_fileName1_1 = sprintf('01 %s Displacement Net Grid 3D.fig', filteringMethod);
    disp_grid_Name1_1 = fullfile(AnalysisPath, disp_grid_fileName1_1);
    hgsave(figHandle1_1, disp_grid_Name1_1,'-v7.3')   
    
%--- Plot displacement components in 2D -----------------------------------------------------------------
    figHandle1_2 = figure('color', 'w');
    set(figHandle1_2, 'Position', [175, 135, 825, 575])
    %-------
%     imagesc(curr_ImageAdjust);
%     colormap(TxRedColorMap);
%     hold on   
%     quiver(pos_grid(:,:,1), pos_grid(:,:,2), disp_grid(:,:,1), disp_grid(:,:,2), 'g')        
    imagesc(unique(pos_grid(:,:,1)), unique(pos_grid(:,:,2)), disp_grid(:,:,3)')
    xlim([0, MD.imSize_(1)]); ylim([0, MD.imSize_(2)]);
    xlabel('X (pixels)'), ylabel('Y (pixels)')
    set(gca, 'FontWeight', 'bold')    
    colormap(parula(2^ImageBits));
    colorbarHandle = colorbar;
    ylabel(colorbarHandle, 'Displacement (Pixel)')
    set(colorbarHandle, 'FontWeight', 'bold')
    hold on   
    quiver(pos_grid(:,:,1), pos_grid(:,:,2), disp_grid(:,:,1), disp_grid(:,:,2), 'w','LineWidth', 1, 'AutoScale', 'on', 'AutoScaleFactor', 1.0)
    %-------   
	% no need to reverse if image() or imagesc() is used. The ydir is reversed. 
    titleStr1_3 = sprintf('Displacement Components - %s - %s', InterpolationMethod);
    title({titleStr1_3, titleStr1_2});
    iu_mat_original_fileName1_2 = sprintf('01 %s Displacement XY Grid Quivers.fig', filteringMethod);
    iu_mat_original_Name1_2 = fullfile(AnalysisPath, iu_mat_original_fileName1_2);
    hgsave(figHandle1_2, iu_mat_original_Name1_2,'-v7.3')    
    
%-----Plot net tractions in 3D ---------------------------------------------------------------  
    figHandle1_3 = figure('color', 'w');
    set(figHandle1_3, 'Position', [275, 235, 825, 575])
    surf(pos_grid_stress(:,:,1), pos_grid_stress(:,:,2), stress_grid(:,:,3))
    view(2);% Show from above (XY view)
    xlim([0, MD.imSize_(1)]); ylim([0, MD.imSize_(2)]);    
    set(gca, 'ydir', 'reverse', 'Box', 'on')
    shading interp
    colormap(parula(2^ImageBits));
    colorbarHandle = colorbar;
    ylabel(colorbarHandle, 'Traction Stress (Pa)')
    set(colorbarHandle, 'FontWeight', 'bold')
%     caxis([-0.1, 0.1])                                % standardize it for all plots
    titleStr1_4 = sprintf('Traction Stress Grid 3D - %s - %s', InterpolationMethod);
    titleStr1_5 = sprintf('F_{x} = %0.3g, F_{y}=%0.3g, F_{net}=%0.3g N.',TractionForceN);    
    title({titleStr1_4, titleStr1_2, titleStr1_5})
%     zlim([-1, 1])                                  % standardize it for all plots.
    xlabel('X (pixels)'), ylabel('Y (pixels)'), zlabel('Traction Stress_{net} (Pa)')                 % note, it is reversed since surf() uses meshgrid() vs. griddata use ndgrid()
    set(gca, 'FontWeight', 'bold')    
%     hold on,  plot3(pos_grid_stress(:,1), pos_grid_stress(:,2), stress_grid(:,3), 'o', 'MarkerSize', 2, 'MarkerFaceColor', 'b', 'MarkerEdgeColor', 'w')
    iu_mat_original_fileName1_3 = sprintf('01 %s Traction Net Grid 3D.fig', filteringMethod);
    iu_mat_original_Name1_3 = fullfile(AnalysisPath, iu_mat_original_fileName1_3);
    hgsave(figHandle1_3, iu_mat_original_Name1_3,'-v7.3')    
    
%--- Plot tractions  components in 2D -----------------------------------------------------------------
    figHandle1_4 = figure('color', 'w');
    set(figHandle1_4, 'Position', [375, 335, 825, 575])
    %-----------------------
%     imagesc(curr_ImageAdjust);
%     colormap(TxRedColorMap);
%     hold on   
%     quiver(pos_grid_force2(:,:,1), pos_grid_force2(:,:,2), force_mat_original2(:,:,1), force_mat_original2(:,:,2), 'g')
    imagesc(unique(pos_grid_stress(:,:,1)), unique(pos_grid_stress(:,:,2)), stress_grid(:,:,3)')
    xlim([0, MD.imSize_(1)]); ylim([0, MD.imSize_(2)]);
    xlabel('X (pixels)'), ylabel('Y (pixels)')
    set(gca, 'FontWeight', 'bold')        
    colormap(parula(2^ImageBits));
    colorbarHandle = colorbar;
    ylabel(colorbarHandle, 'Traction Stress (Pa)')
    set(colorbarHandle, 'FontWeight', 'bold')
    hold on   
    quiver(pos_grid_stress(:,:,1), pos_grid_stress(:,:,2), stress_grid(:,:,1), stress_grid(:,:,2), 'w','LineWidth', 1, 'AutoScale', 'on', 'AutoScaleFactor', 1.0)
    %-----------------------        
	% no need to reverse if image() or imagesc() is used. The ydir is reversed. 
    titleStr1_6 = sprintf('Traction Components - %s - %s', InterpolationMethod);
    title({titleStr1_6, titleStr1_2, titleStr1_5});
    iu_mat_original_fileName1_4 = sprintf('01 %s Traction XY Grid Quivers.fig', filteringMethod);    
    iu_mat_original_Name1_4 = fullfile(AnalysisPath, iu_mat_original_fileName1_4);
    hgsave(figHandle1_4, iu_mat_original_Name1_4,'-v7.3')    