classdef GelSample
    %GelSample(GelID [str], EDAC [true/false], CO2 [true/false], concentration_mgmL [num], Thickness_micron [num], Diameter mm [num], Type [str], pH [num], YoungElasticModulusPa [num])
    %   Contains all the parameters of a given gel

    properties
        GelID
        concentration_mgmL
        Thickness_micron
        Diameter_mm
        GelType
        pH
        hasCO2
        hasEDAC
        YoungsElasticModulusPa
        Notes
        MagBeads
        FluorescentMicrospheres
    end

    methods
        function obj = GelSample(varargin)
            %GelSample Construct an instance of this class
            %   Required parameters are Gel GelID, EDAC or Not, concentration [mg/mL], thickness [microns]

            DefaultDiameter_mm = 18;                     % 18 mm-diameter gels is the default
            DefaultType = 'rat-tail type I collagen gel';
            Default_pH = 7.4;

            ip = inputParser();
            ip.addRequired('GelID', @ischar);
            ip.addRequired('hasEDAC', @(x) islogical(x));
            ip.addRequired('hasCO2', @(x) islogical(x));
            ip.addRequired('concentration_mgmL', @(x) validateattributes(x, {'numeric'}, {'scalar'}));
            ip.addRequired('Thickness_micron', @(x) validateattributes(x, {'numeric'}, {'scalar'}));
            ip.addOptional('Diameter_mm', DefaultDiameter_mm, @(x) validateattributes(x, {'numeric'}, {'scalar'}));     % 18-mm default
            ip.addOptional('YoungsElasticModulusPa', [], @(x) validateattributes(x, {'numeric'}, {'scalar'}));
            ip.addOptional('GelType', DefaultType , @ischar);  
            ip.addOptional('pH', Default_pH, @(x) validateattributes(x, {'numeric'}, {'scalar'}));     % 18-mm default
            ip.addOptional('Notes', @(x) isstring(x));
            ip.addOptional('MagBeads', @(x) isa(x,'MagBead'))
            
            ip.parse(varargin{:})
            
            obj.GelID = ip.Results.GelID;
            obj.hasEDAC = ip.Results.hasEDAC;
            obj.hasCO2 = ip.Results.hasCO2;
            obj.concentration_mgmL = ip.Results.concentration_mgmL;
            obj.Thickness_micron = ip.Results.Thickness_micron;
            obj.Diameter_mm = ip.Results.Diameter_mm;
            obj.GelType = ip.Results.GelType;
            obj.pH = ip.Results.pH;
            obj.YoungsElasticModulusPa = ip.Results.YoungsElasticModulusPa;
            obj.Notes = ip.Results.Notes;            

        end

        function outputArg = method1(obj,inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end
    end
end