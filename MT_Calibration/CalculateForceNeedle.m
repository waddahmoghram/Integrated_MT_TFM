    %CalculateForceNeedle evaluates the force for my MT needle based on calibration experiments
    %{   
        v2019-09-16
            1. Updated to all plotting all values, or certain values internally.
        v.2019-09-10 
            1. Based on latest near-field calibrations on 2019-08-15.
                .. Flux values are 
            2. Added a sample plot option to generate all the curves.
            3. Separation Distance can be inserted as a range for plot, or a single value to get the function value
        v.2019-08-12 (v2.00) Written by Waddah Moghram 
            Updated the CalculateForceNeedle Curves
        v.2019-02-03 (v1.00) Written by Waddah Moghram 
            This based on a power-law fit of the following equation:
            F = F0/((x/x0)+1)^p
                where:  - ***x is the separation distance, or smallDelta (in microns)***
                            *** (F0, x0, p) are fitted parameters ***
                                *** F = Magnetic force as fitted from calibration fitted (in nN) ***
            Input:  - x, or Sep Distance: The Euclidean separation distance between the needle tip and the center of the magnetic bead
                        - B: Flux ON Setpoint at the Blunt End (or core), One of many the following values : {25, 50, 75, 100, 125, 150, 175} Gs.
                                Update 2019-09-10., Flux values are  {25, 50, 75, 100, 125, 150, 175, 185} Gs.
                            Flip signs to negative later 2019-02-04
                        % Fields are the Flux ON Core Setpoint, paired with their respective parameters, in the order listed above
                        % Outlier points that residuals more than 2 were excluded

                        % values are stored in CalculateForceNeedle.mat        
            Output: The Magnetic Force the bead experiences in the near-field
    
    %}

function [Force_nN, SepDistance_micron, CurrentMagneticFluxAtCore_Gs] = CalculateForceNeedle(SepDistance_micron, MagneticFluxAtCore_Gs, ShowPlot)    
    try
        load PowerLawFitParametersMTmerged;        
    catch
        [filename, pathname] = uigetfile(pwd, 'Find PowerLawFitParametersMTmerged***.mat');
        if filename == 0, return; end
        fullfilename = fullfile(pathname, filename);
        load fullfilename
    end

    if ~exist('SepDistance_micron', 'var'), SepDistance_micron = []; end
    if isempty(SepDistance_micron) || nargin < 1       
        SepDistance_micron = input('Please input the bead-tip separation distance range (in microns, a vector of two items [Smallest Distance, Largest Distance]. [Default = [2.5, 40] microns]: ');
        if isempty(SepDistance_micron), SepDistance_micron = [2.5, 40]; end
    end
    if SepDistance_micron(1) == 0
        SepDistance_micron(1) = 0.0001;                % power law cannot be calculated at 0 microns. Technically, you should not plot for anything less than radius of the bead.
    end
    
    if ~exist('MagneticFluxAtCore_Gs', 'var'), MagneticFluxAtCore_Gs = []; end
    if isempty(MagneticFluxAtCore_Gs) || nargin < 2      
            dlgQuestion = 'Choose the Flux Values (Gs) that you want to calculate (or plot)';
            listStr = sprintfc('%d', Flux);                 % convert flux values to a cell of strings
            MagneticFluxAtCore_GsIndx = listdlg('ListString', listStr, 'PromptString',dlgQuestion, 'InitialValue', 1, 'SelectionMode' , 'multiple');    
            MagneticFluxAtCore_Gs = cellfun(@str2num, listStr(MagneticFluxAtCore_GsIndx)) ;
    end
    if strcmpi(MagneticFluxAtCore_Gs, 'All')
        MagneticFluxAtCore_Gs = Flux;               % load up all flux values
    end
    
    if ~exist('SamplePlot', 'var'), ShowPlot = []; end
    if isempty(ShowPlot) || nargin < 3  
        ShowPlot = questdlg('Do you want to show plot of the power law curves for Force vs. Separation Distance based on the calibration curves?',...
            'Power Law Curves?', 'Yes', 'No', 'Yes');
        switch ShowPlot
            case 'Yes'
                ShowPlot  = 1;
            case 'No'
                ShowPlot = 0;
            otherwise
                return
        end
    else
        if strcmpi(ShowPlot, 'y'), ShowPlot  = 1; end
        if strcmpi(ShowPlot, 'n'), ShowPlot  = 0; end        
    end
    
    
    %%
    if ShowPlot, figHandle = figure('color', 'w'); end
    ii = 1;
    RunNameStr = {};
        
    for CurrentMagneticFluxAtCore_Gs = MagneticFluxAtCore_Gs
        % Choose the flux parameters (idx = index)
        switch CurrentMagneticFluxAtCore_Gs
            case 25
                idx = 1;
            case 50
                idx = 2;
            case 75
                idx = 3;
            case 100
                idx = 4;
            case 125
                idx = 5;
            case 150
                idx = 6;
            case 175
                idx = 7;
            case 185
                idx = 7;
            otherwise
                disp('Choose one of the following values: {25, 50, 75, 100, 125, 150, 175} Gs')
        end
        if ShowPlot
            RunNameStr{ii} = sprintf('%d Gs', CurrentMagneticFluxAtCore_Gs);
            ii = ii + 1;
            SepDistance = linspace(SepDistance_micron(1),SepDistance_micron(2),1000);
            Force_nN = F0(idx)./((SepDistance/x0(idx))+1).^p(idx);                
            plot(SepDistance, Force_nN, '.-',  'MarkerSize', 2);
            hold on
            set(findobj(gcf,'type', 'axes'), 'FontSize',10, 'FontWeight','Bold', 'LineWidth',1, 'XMinorTick', 'on', 'YMinorTick', 'on', 'TickDir', 'out');     % Make axes bold         
        else
            Force_nN = F0(idx)./((SepDistance_micron/x0(idx))+1).^p(idx);
        end
    end
    
    if ShowPlot
        title('Power Law Curve Plot')
        xlabel('Separation Distance, \delta (\mum)');
        xlim([0, SepDistance(end)]);
        ylabel('Force, F (nN)');
        legend(RunNameStr)

        ImageHandle = getframe(figHandle);
        Image_cdata = ImageHandle.cdata;

        OutputPathName = uigetdir('Where do you want to save the plot?');
        MTforceCalculatedFIG = fullfile(OutputPathName, 'MT Force Calculated.fig');
        if MTforceCalculatedFIG ~= 0, hgsave(figHandle,MTforceCalculatedFIG, '-v7.3'); end
        MTforceCalculatedPNG = fullfile(OutputPathName, 'MT Force Calculated.PNG');
        saveas(figHandle, MTforceCalculatedPNG, 'png');    
    %     MTforceCalculatedTIF = fullfile(OutputPathName, 'MT Force Calculated.tif');
    %     imwrite(Image_cdata, MTforceCalculatedTIF);
    %     MTforceCalculatedEPS = fullfile(OutputPathName, 'MT Force Calculated.eps');
    %     print(figHandle, MTforceCalculatedEPS,'-depsc2')   
    end
    
    % output values for a wide range of values were validated and they match the curves on 2/3/2019
end

