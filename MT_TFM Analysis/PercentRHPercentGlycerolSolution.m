function [ExperimentPercentGlycerol] = PercentRHPercentGlycerolSolution(ExperimentPercentRH)
    %% Written by Waddah Moghram, PhD Candidate in Biomedical Engineering at the University of Iowa
    %{
    v3.00 Updated on 2019-05-28
    v2.00 Updated on 2019-01-24
    v1.00 Written on 2018-01-19
    
    For purposes of Magnetic Tweezer Calibrations
    This has come as a result of the observation that bead movement depends not only on temperature but also on the relative humidity of air.
    Input: the experiment *PERCENT* RELATIVE HUMIDIITY (0 to 100) 
    Output: *PERCENT* *WEIGHT/MASS* OF GLYCEROL in solution
    %}
    %% 1. Loading the datapoints for the curve, PercentRHPercentGlycerolData.mat
        %{
        The data is extracted from the plot shown in:
        "Physical Properties of glycerine and its solutions" and "Glycerine - an Overview" 
        using the website: https://apps.automeris.io/wpd/ along with manual correction of data
        %}
        try 
            load('PercentRHPercentGlycerolData.mat', 'PercentRHPercentGlycerolData');           %this way it loads as a matrix and not a structure containing the matrix
        catch
            disp('Cannot find the data matrix PercentRHPercentGlycerolData.mat')
            [file, path] = uigetfile('*.mat','Open PercentRHPercentGlycerolData.mat');
            fullFileName = fullfile(path, file);
            load(fullFileName, 'PercentRHPercentGlycerolData');
        end

        PercentGlycerol = PercentRHPercentGlycerolData(:,2);
        PercentRH = PercentRHPercentGlycerolData(:,1);
        
   %% 2. Plot of Percent Glycerol by Weight vs. Percent Relative Humidity Curves
%     figure('Color','w')
%     set(gca,'FontWeight','bold')
%     plot(PercentGlycerol,PercentRH,'.'); xlabel('Percent Relative Humidity'); ylabel('Percent Glycerol by Weight');
%     title('Percent Weight of Glycerol vs. Relative Humidity');

    %% 3. Evaluating the Percent Glycerol based on the relative humidity in the data logger file
    fprintf('Experiment relative humidity is%3.0f%%\n', ExperimentPercentRH);
    % For now, first order approximation between the datapoint is a linear interpolation.
    % A better estimate would an ellipse?
    ExperimentPercentGlycerol = interp1(PercentRH, PercentGlycerol, ExperimentPercentRH);

    ExperimentGlycerolMassFraction = ExperimentPercentGlycerol / 100;
    fprintf('Experiment percent glycerol mass is %3.4f%%\n' , ExperimentPercentGlycerol);    
    fprintf('Experiment glycerol mass fraction is %3.4f\n' , ExperimentGlycerolMassFraction);
    
    %% 4. Evaluating the viscosity of glycerol based on the obtained percent weight
%     % Function Evaluating the Viscosity of Glycerol based on percent glycerol by weight and temperature (degrees C)
%     % code is obtained from http://www.met.reading.ac.uk/~sws04cdw/viscosity_calc.html on 1/18/2018
%     % It is based on a publication  Cheng (2008) Ind. Eng. Chem. Res. 47 3285-3288, with a number of adjustments, and others
%     ExperimentTemperature = 25;       %FOR NOW. UNITS are in degree celcius
%     fprintf('Experiment temperature is %gºC\n',ExperimentTemperature)
%     [GlycerolDensity,GlycerolViscosity] = densityViscosityWaterGlycerolSolution(ExperimentGlycerolMassFraction,ExperimentTemperature);
%     fprintf('Viscosity of glycerol is %5.3f (Pa.s)\n', GlycerolViscosity);
end 