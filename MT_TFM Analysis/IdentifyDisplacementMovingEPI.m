%{
    v.2020-08-23 by Waddah Moghram, PhD Candidate in Biomedical Engineering at teh University of Iowa.
        1. Use the maximum displacement in negative control as our cut-off for Moving vs. Not-Moving instead of 6-sigma statsitics of 
            Rayleigh distribution since the distribution of the net displacement is not a Rayleigh distribution.
        2. A choice is given to the user

    v.2020-08-19 by Waddah Moghram, PhD Student in Biomedical Engineering
        Based on IdentifyAccelerationTransients.m (v.2020-08-04)
    
%}

    ShowPlots = true;
    FrameRate = 40;                                 % ~40 frames per second    
    maxCutOffTimes = 15 * 1/FrameRate;            	% 15 Frames
    minCutOFFFrames = 5;                     
    
%% 0 Load EPI Stamps for positive experiment
    [TimeStampsFileName, TimeStampsPathName] = uigetfile(fullfile(pwd, '*.*'), 'Choose Positive EPI timestamps file (RT or ND2)');
    TimeStampsFileNameFull = fullfile(TimeStampsPathName, TimeStampsFileName);
    TimeStampsStruct = load(TimeStampsFileNameFull);
    try
        TimeStamps = TimeStampsStruct.TimeStampsAbsoluteRT_Sec;
    catch
        try
            TimeStamps = TimeStampsStruct.TimeStampsND2;
        catch
            TimeStamps = TimeStampsStruct.TimeStamps;
        end
    end
    
%% 1. Load the needed variables
    CutOffMethodList = {'Bead Displacement Dynamics - X & Y', 'Bead Displacement Dynamics - Norm'};
    CutOffMethodListChoiceIndex = listdlg('ListString', CutOffMethodList, 'SelectionMode', 'single', 'InitialValue', 1, ...
        'PromptString', 'Choose the criterion for cutoff limits:', 'ListSize', [250, 100]);
    if isempty(CutOffMethodListChoiceIndex), CutOffMethodListChoiceIndex = 1; end
    CutOffMethod = CutOffMethodList{CutOffMethodListChoiceIndex}; 
    
    switch CutOffMethod
        case 'Bead Displacement Dynamics - Norm'
            [PositiveBeadDynamicsFileName, PositiveBeadDynamicsFilePath] = uigetfile('*.mat', ...
                'Open POSITIVE EPI "Bead Dynamics Results.m" file');
            PositiveBeadDynamicsFileFullName = fullfile(PositiveBeadDynamicsFilePath, PositiveBeadDynamicsFileName);
            try 
                PositiveBeadDynamics = load(PositiveBeadDynamicsFileFullName, 'displMicronMaxVecNorm');
                fprintf('POSITIVE EPI Bead Dynamics file is: \n\t %s\n', PositiveBeadDynamicsFileFullName)
                disp('------------------------------------------------------------------------------')
            catch 
                errordlg('Could not open the movie data file!')
                return
            end

            dlgQuestion = 'Are the negative control-experiments acceleration confidence intervals saved in the same POSITIVE EPI Experiment file (Bead Dynamics Results.m)?';
            dlgTitle = 'Negative CIs too?';
            NegativeInPositiveFile = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No', 'Yes');
            switch NegativeInPositiveFile
                case 'Yes'
                     load(PositiveBeadDynamicsFileFullName, 'NegativeBeadDynamics');
                case 'No'
                    [NegativeBeadDynamicsFileName, NegativeBeadDynamicsFilePath] = uigetfile(fullfile(PositiveBeadDynamicsFilePath, '*.mat'), ...
                        'Open NEGATIVE EPI "Bead Dynamics Results.m" file');
                    NegativeBeadDynamicsFileFullName = fullfile(NegativeBeadDynamicsFilePath, NegativeBeadDynamicsFileName);
                    NegativeBeadDynamics = load(NegativeBeadDynamicsFileFullName, 'displMicronCIallXMean', 'displMicronCIallNormMean');
                otherwise
                    return;
            end
     
            % Save the output
            try
               save(PositiveBeadDynamicsFileFullName, 'TransientFramesLimitsAll', 'TransientFramesAll_TF', 'TransientFramesLimitsX', ...
                    'TransientFramesX_TF', 'TransientFramesLimitsY', 'TransientFramesY_TF', '-append')
            catch
               % Controlled Displacement Analysis. No Transient Analysis 
            end
            
        case 'Bead Displacement Dynamics - X & Y'
            [PositiveBeadDynamicsFileName, PositiveBeadDynamicsFilePath] = uigetfile('*.mat', ...
                'Open positive "Bead Dynamics Results.m" file');
            PositiveBeadDynamicsFileFullName = fullfile(PositiveBeadDynamicsFilePath, PositiveBeadDynamicsFileName);
            try 
                PositiveBeadDynamics = load(PositiveBeadDynamicsFileFullName, 'displMicronMaxVecX', 'displMicronMaxVecY');
                fprintf('Positive Bead Dynamics file is: \n\t %s\n', PositiveBeadDynamicsFileFullName)
                disp('------------------------------------------------------------------------------')
            catch 
                errordlg('Could not open the movie data file!')
                return
            end

            dlgQuestion = 'Are the negative control-experiments acceleration confidence intervals saved in the same positive experimernt file (Bead Dynamics Results.m)?';
            dlgTitle = 'Negative CIs too?';
            NegativeInPositiveFile = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No', 'Yes');
            switch NegativeInPositiveFile
                case 'Yes'
                     load(PositiveBeadDynamicsFileFullName, 'NegativeBeadDynamics');
                case 'No'
                    [NegativeBeadDynamicsFileName, NegativeBeadDynamicsFilePath] = uigetfile(fullfile(PositiveBeadDynamicsFilePath, '*.mat'), ...
                        'Open negative "Bead Dynamics Results.m" file');
                    NegativeBeadDynamicsFileFullName = fullfile(NegativeBeadDynamicsFilePath, NegativeBeadDynamicsFileName);
                    NegativeBeadDynamics = load(NegativeBeadDynamicsFileFullName, 'displMicronCIallXMean', 'displMicronCIallYMean');
                otherwise
                    return;
            end

        %% 2. Eliminate outliers less than or greater than CI extreme values in either X-direction
           % FIRST in the X-direction
            NegDisplacementAllXCIs = NegativeBeadDynamics.displMicronCIallXMean;
            PosDisplacementMaxX = PositiveBeadDynamics.displMicronMaxVecX;

            clear ValidFramesX
            ValidFramesX = ~logical((PosDisplacementMaxX > NegDisplacementAllXCIs(2)) | ...
             (PosDisplacementMaxX < NegDisplacementAllXCIs(1)));
            % Artifically make the last frame a 0, or invalid to catch the end
            ValidFramesX(end) = false;
            ValidFramesXDiff = [nan; diff(ValidFramesX)];
            ValidFramesXIdx = find(ValidFramesX);
            ValidFramesX(end) = true;    
            ValidFramesXIdxDiff = [nan; diff(ValidFramesXIdx)]; 
            ValidFramesXTransitionsIdx = find(ValidFramesXDiff);
            clear ValidFramesXTransitionsLengths
            ValidFramesXTransitionsLengths = diff([0;ValidFramesXTransitionsIdx]);

            NumFramesX = numel(PosDisplacementMaxX);

        %     %____ Algorithm 1
        %     CutOffFrames = ceil(maxCutOffTimes * FrameRate);
        %     ValidFramesXEndPointTF = (ValidFramesXTransitionsLengths > CutOffFrames);
        %     ValidFramesXEndPointIdx = ValidFramesXTransitionsIdx(ValidFramesXEndPointTF);
        %     ValidFramesXEndPointLength = ValidFramesXTransitionsLengths(ValidFramesXEndPointTF);
        %     TransientFramesX_TF = true(1,NumFramesX);
        %     for ii = 1:numel(ValidFramesXEndPointIdx)
        %         TransientFramesX_TF((ValidFramesXEndPointIdx(ii)-ValidFramesXEndPointLength(ii)):ValidFramesXEndPointIdx(ii) -1) = false;
        %     end
        %     TransientFramesX_TF(ValidFramesXEndPointIdx(end):NumFramesX) = false;
        %     % restore last frame to true;

            %____ Algorithm 2
            clear ValidFramesXTransitionsLengths2
            for ii = 1:(numel(ValidFramesXTransitionsIdx) - 1)
                ValidFramesXTransitionsLengths2(ValidFramesXTransitionsIdx(ii):(ValidFramesXTransitionsIdx(ii+1)-1)) = ...
                    ValidFramesXTransitionsLengths(ii +1);
            end
            ValidFramesXTransitionsLengths2(NumFramesX) = ValidFramesXTransitionsLengths(end);
            ValidFramesXTransitionsLengths2 = ValidFramesXTransitionsLengths2';

            clear TransientFramesX_TF

            TransientFramesX_TF( ValidFramesX & (ValidFramesXTransitionsLengths2 > minCutOFFFrames)) = false;
            TransientFramesX_TF(~ValidFramesX | (ValidFramesXTransitionsLengths2 <= minCutOFFFrames)) = true;
            %_________________________________

            TransientFramesLimitsXstart = find(diff(TransientFramesX_TF) == 1) + 1;            % a difference of 1 is a spike from regular to transient
            TransientFramesLimitsXend = find(diff(TransientFramesX_TF) == -1) ;            % a difference of 1 is a spike from regular to transient
            TransientFramesLimitsX = sort([TransientFramesLimitsXstart, TransientFramesLimitsXend]);

            % Plot Transitions
            if ShowPlots
                figure('color', 'w')
                plot(PosDisplacementMaxX)
                xlabel('Frame #'), ylabel('Acceleration [\mum^2/s]')
                xlim([0, NumFramesX])
                hold on
                b = plot(repmat(NegDisplacementAllXCIs, NumFramesX, 1), 'g-', 'MarkerSize', 2, 'LineWidth',0.5);
                b(2).HandleVisibility = 'off';
                yyaxis right
                yticks([-1, 0, 1]); ylim([-1.1, 1.1]);
                ylabel('Frame Validity (0/1) or Transitions (-1/0/1)')
                plot(ValidFramesX, 'r.', 'MarkerSize', 2)
                plot(ValidFramesXDiff, 'm-')
                legend('Acceleration Max', 'Acceleration Neg CI', 'Valid/Invalid Frames based on accelerations (ValidFrameX)', ...
                    'Valid/Invalid Frames Diff (Transition)')
                title('Acceleration x-direction')

                figure('color', 'w')
                plot(ValidFramesXIdx, ValidFramesXIdxDiff, 'bx-', 'MarkerSize', 2)
                xlim([0, NumFramesX])
                xlabel('Frame #')
                ylim([-1, max(ValidFramesXIdxDiff) + 1])
                yl = ylabel('Anything > 1 is invalid frames gap');
                set(yl, 'color', 'b')
                yyaxis right
                hold on
                plot(ValidFramesXDiff, 'ro', 'MarkerSize', 5)
                ylim([-1.2,1.2])
                rl = ylabel('Anything \neq 0 is transition between Valid/Invalid');
                set(rl, 'color', 'r')    
                title('Acceleration x-direction')

                figure('color', 'w')
                plot(ValidFramesXTransitionsIdx, ValidFramesXTransitionsLengths, 'k+', 'MarkerSize', 6)
                xlim([0, NumFramesX])
                xlabel('Frame #')
                ylabel('# of Valid Frames Before that')
                yyaxis right
                plot(ValidFramesX, 'r.', 'MarkerSize', 2)
                plot(ValidFramesXDiff, 'm-')
                yticks([-1, 0, 1]); ylim([-1.1, 1.1]);
                ylabel('Frame Validity (0/1) or Transitions (-1/0/1)')
                legend('Length of Segments', 'Transition (-1/1) or Valid(0)')
                title('Acceleration x-direction')

                figure('color', 'w')
                plot(TransientFramesX_TF, 'ro', 'MarkerSize', 6)
                xlim([1, NumFramesX])
                ylim([-0.2,1.2])
                xlabel('Frame #')
                ylabel('Transient = 1. Not Transient = 0')
                hold on
                plot(~ValidFramesX, 'bx', 'MarkerSize', 4)
                yyaxis right
                plot(PosDisplacementMaxX)
                b = plot(repmat(NegDisplacementAllXCIs, NumFramesX, 1), 'g-', 'MarkerSize', 2, 'LineWidth',0.5);
                ylabel('Acceleration [\mum^2/s]')
                b(2).HandleVisibility = 'off';

                VerticalLine = [min(PosDisplacementMaxX),max(PosDisplacementMaxX)];
                for ii = 1:numel(TransientFramesLimitsX)
                   c = plot([TransientFramesLimitsX(ii),TransientFramesLimitsX(ii)], VerticalLine, 'k--');
        %            c = plot(TimeStamps([TransientFramesLimitsX(ii),TransientFramesLimitsX(ii)]), VerticalLine, 'k--');
                   if ii~=1, c.HandleVisibility = 'Off'; end
                   hold on
                end

                legend('Valid/Invalid Frames based on gap lengths (TransientFramesTF)', 'Valid/Invalid Frames based on Acceleration (~ValidFramesX)', ...
                    'Acceleration Max', 'Acceleration Neg CI', 'Transient Segment Limits')
                title('Acceleration x-direction')
            end

        %% 3. Eliminate outliers less than or greater than CI extreme values in either Y-direction    
            NegDisplacementAllYCIs = NegativeBeadDynamics.displMicronCIallYMean;
            PosDisplacementMaxY = PositiveBeadDynamics.displMicronMaxVecY;

            ValidFramesY = ~logical((PosDisplacementMaxY > NegDisplacementAllYCIs(2)) | ...
             (PosDisplacementMaxY < NegDisplacementAllYCIs(1)));
            % Artifically make the last frame a 0, or invalid to catch the end
            ValidFramesY(end) = false;
            ValidFramesYDiff = [nan; diff(ValidFramesY)];
            ValidFramesYIdx = find(ValidFramesY);
            ValidFramesY(end) = true;  
            ValidFramesYIdxDiff = [nan; diff(ValidFramesYIdx)]; 
            ValidFramesYTransitionsIdx = find(ValidFramesYDiff);
            clear ValidFramesYTransitionsLengths
            ValidFramesYTransitionsLengths = diff([0;ValidFramesYTransitionsIdx]);

            NumFramesY = numel(PosDisplacementMaxY);

        %     %____ Algorithm 1
        %     CutOffFrames = ceil(maxCutOffTimes * FrameRate);
        %     ValidFramesYEndPointTF = (ValidFramesYTransitionsLengths > CutOffFrames);
        %     ValidFramesYEndPointIdx = ValidFramesYTransitionsIdx(ValidFramesYEndPointTF);
        %     ValidFramesYEndPointLength = ValidFramesYTransitionsLengths(ValidFramesYEndPointTF);
        %     TransientFramesY_TF = true(1,NumFramesY);
        %     for ii = 1:numel(ValidFramesYEndPointIdx)
        %         TransientFramesY_TF((ValidFramesYEndPointIdx(ii)-ValidFramesYEndPointLength(ii)):ValidFramesYEndPointIdx(ii) -1) = false;
        %     end
        %     TransientFramesY_TF(ValidFramesYEndPointIdx(end):NumFramesY) = false;
        %     % restore last frame to true;

            %____ Algorithm 2
            clear ValidFramesYTransitionsLengths2
            for ii = 1:(numel(ValidFramesYTransitionsIdx) - 1)
                ValidFramesYTransitionsLengths2(ValidFramesYTransitionsIdx(ii):(ValidFramesYTransitionsIdx(ii+1)-1)) = ...
                    ValidFramesYTransitionsLengths(ii +1);
            end
            ValidFramesYTransitionsLengths2(NumFramesY) = ValidFramesYTransitionsLengths(end);
            ValidFramesYTransitionsLengths2 = ValidFramesYTransitionsLengths2';

            clear TransientFramesY_TF

            TransientFramesY_TF( ValidFramesY & (ValidFramesYTransitionsLengths2 > minCutOFFFrames)) = false;
            TransientFramesY_TF(~ValidFramesY | (ValidFramesYTransitionsLengths2 <= minCutOFFFrames)) = true;
            %_________________________________

                % Plot Transitions
            TransientFramesLimitsYstart = find(diff(TransientFramesY_TF) == 1) + 1;            % a difference of 1 is a spike from regular to transient
            TransientFramesLimitsYend = find(diff(TransientFramesY_TF) == -1) ;            % a difference of 1 is a spike from regular to transient
            TransientFramesLimitsY = sort([TransientFramesLimitsYstart, TransientFramesLimitsYend]);

            if ShowPlots
                figure('color', 'w')
                plot(PosDisplacementMaxY)
                xlabel('Frame #'), ylabel('Acceleration [\mum^2/s]')
                xlim([0, NumFramesY])
                hold on
                b = plot(repmat(NegDisplacementAllYCIs, NumFramesY, 1), 'g-', 'MarkerSize', 2, 'LineWidth',0.5);
                b(2).HandleVisibility = 'off';
                yyaxis right
                yticks([-1, 0, 1]); ylim([-1.1, 1.1]);
                ylabel('Frame Validity (0/1) or Transitions (-1/0/1)')
                plot(ValidFramesY, 'r.', 'MarkerSize', 2)
                plot(ValidFramesYDiff, 'm-')
                legend('Acceleration Max', 'Acceleration Neg CI', 'Valid/Invalid Frames based on accelerations (ValidFrameX)', ...
                    'Valid/Invalid Frames Diff (Transition)')
                title('Acceleration y-direction')

                figure('color', 'w')
                plot(ValidFramesYIdx, ValidFramesYIdxDiff, 'bx-', 'MarkerSize', 2)
                xlim([0, NumFramesY])
                xlabel('Frame #')
                ylim([-1, max(ValidFramesYIdxDiff) + 1])
                yl = ylabel('Anything > 1 is invalid frames gap');
                set(yl, 'color', 'b')
                yyaxis right
                hold on
                plot(ValidFramesYDiff, 'ro', 'MarkerSize', 5)
                ylim([-1.2,1.2])
                rl = ylabel('Anything \neq 0 is transition between Valid/Invalid');
                set(rl, 'color', 'r')    
                title('Acceleration y-direction')

                figure('color', 'w')
                plot(ValidFramesYTransitionsIdx, ValidFramesYTransitionsLengths, 'k+', 'MarkerSize', 6)
                xlim([0, NumFramesY])
                xlabel('Frame #')
                ylabel('# of Valid Frames Before that')
                yyaxis right
                plot(ValidFramesY, 'r.', 'MarkerSize', 2)
                plot(ValidFramesYDiff, 'm-')
                yticks([-1, 0, 1]); ylim([-1.1, 1.1]);
                ylabel('Frame Validity (0/1) or Transitions (-1/0/1)')
                legend('Length of Segments', 'Transition (-1/1) or Valid(0)')
                title('Acceleration y-direction')

                figure('color', 'w')
                plot(TransientFramesY_TF, 'ro', 'MarkerSize', 6)
                xlim([1, NumFramesY])
                ylim([-0.2,1.2])
                xlabel('Frame #')
                ylabel('Transient = 1. Not Transient = 0')
                hold on
                plot(~ValidFramesY, 'bx', 'MarkerSize', 4)
                yyaxis right
                plot(PosDisplacementMaxY)
                b = plot(repmat(NegDisplacementAllYCIs, NumFramesY, 1), 'g-', 'MarkerSize', 2, 'LineWidth',0.5);
                ylabel('Acceleration [\mum^2/s]')
                b(2).HandleVisibility = 'off';

                VerticalLine = [min(PosDisplacementMaxY),max(PosDisplacementMaxY)];
                for ii = 1:numel(TransientFramesLimitsY)
                   c = plot([TransientFramesLimitsY(ii),TransientFramesLimitsY(ii)], VerticalLine, 'k--');
        %            c = plot(TimeStamps([TransientFramesLimitsY(ii),TransientFramesLimitsY(ii)]), VerticalLine, 'k--');
                   if ii~=1, c.HandleVisibility = 'Off'; end
                   hold on
                end

                legend('Valid/Invalid Frames based on gap lengths (TransientFramesTF)', 'Valid/Invalid Frames based on Acceleration (~ValidFramesX)', ...
                    'Acceleration Max', 'Acceleration Neg CI', 'Transient Segment Limits')
                title('Acceleration y-direction')
            end

        %% 4. Now Finding the Frames that are transient either in X- or Y-directions
            TransientFramesAll_TF = TransientFramesX_TF | TransientFramesY_TF;
            TransientFramesLimitsAllstart = find(diff(TransientFramesAll_TF) == 1) + 1;            % a difference of 1 is a spike from regular to transient
            TransientFramesLimitsAllend = find(diff(TransientFramesAll_TF) == -1) ;            % a difference of 1 is a spike from regular to transient
            TransientFramesLimitsAll = sort([TransientFramesLimitsAllstart, TransientFramesLimitsAllend]);

            % Plot on the forces plot.
            if ShowPlots
                maxForceN = 38;
                VerticalLine = [0,maxForceN];
                for ii = 1:numel(TransientFramesLimitsAll)
            %        c = plot([TransientFramesLimitsAll(ii),TransientFramesLimitsAll(ii)], VerticalLine, 'k--');
                   c =  plot(TimeStamps([TransientFramesLimitsAll(ii),TransientFramesLimitsAll(ii)]), VerticalLine, 'k--');
                   if ii~=1, c.HandleVisibility = 'Off'; end
                   hold on
                end
            end

        %% Save the output
        try
            save(PositiveBeadDynamicsFileFullName, 'TransientFramesLimitsAll', 'TransientFramesAll_TF', 'TransientFramesLimitsX', ...
                'TransientFramesX_TF', 'TransientFramesLimitsY', 'TransientFramesY_TF', '-append')
        catch
            
        end
    end