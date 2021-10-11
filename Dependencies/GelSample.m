classdef GelSample
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here

    properties
        GelID_
        GelType_
        GelThickness_
        GelDiameter_mm_
        pH_
        concentration_
        EDC_
        YoungsElasticModulusPa
        RedMicrospheres                         % Class
    end

    methods
        function obj = GelSample(varargin)
            %UNTITLED2 Construct an instance of this class
            %   Detailed explanation goes here
            GelDefaultDiameter_mm = 18;                     % 18 mm-diameter gels is the default
            GelDefaultDiameGelTypeter_mm = 'Type I rat-tail collagen gel';
            GelDefault_pH = 7.4;

            ip = inputParser();
            ip.addRequired('GelID', @ischar);
            ip.addRequired('GelThickness_', @(x) validateattributes(x, {'numeric'}, {'scalar'}));
            ip.addOptional('GelType', GelDefaultDiameGelTypeter_mm , @ischar);  
            ip.addOptional('GelDiameter_mm_', GelDefaultDiameter_mm, @(x) validateattributes(x, {'numeric'}, {'scalar'}));     % 18-mm default
            ip.addOptional('pH_', GelDefaultDiameter_mm, @(x) validateattributes(x, {'numeric'}, {'scalar'}));     % 18-mm default
            ip.parse(varargin{:})

        end

        function outputArg = method1(obj,inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end
    end
end