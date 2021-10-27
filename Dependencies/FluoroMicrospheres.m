classdef FluoroMicrospheres
    %FluoroMicrospheres(microsphereID)Summary of this class goes here
    %   Other options properties are: 
    % Written by Waddah Moghram, PhD Candidate in Biomedical Engineering on 2021-10-24
    
    properties
        microsphereID
        GelSample
        Diameter_micron
        BeadType
        BeadChemistry
        AttachedProtein
        IncubationTime_min
        IncubationTemp_C
        FrameScale_micronPerPix
        PositionXY_pix
        % MaxDisplacement_micron
        displField
        DisplacementCorrected_micron                                % You can find max by searching for it in here
        ForceMT_N
        WorkMT_J
        TimeStampsRT_sec
        TimeStampsND2_sec
        MovieData
        Notes
    end

    methods
        function obj = FluoroMicrospheres(varargin)
            %FluoroMicrospheres Construct an instance of this class
            %   (ID, Type, diametersMicrons)

            ip = inputParser();
            ip.addRequired('microsphereID', @ischar);
            ip.addRequired('GelSample', [], @(x) isa(x, 'GelSample'));
            ip.addOptional('Diameter_micron', 0.5, @(x) validateattributes(x, {'numeric'}, {'scalar'}));   
            ip.addOptional('BeadType', 'FluoSpheres™ carboxylate-modified polystyrene red fluorescent microspheres', @ischar);
            ip.addOptional('BeadChemistry', 'carboxylate group', @ischar);
            ip.addOptional('AttachedProtein', 'human plasma fibronectin purified protein (Catalog No. FC010; MilliporeSigma, St. Louis, MO', @ischar);  
            ip.addOptional('IncubationTime_min', 0.5, @(x) validateattributes(x, {'numeric'}, {'scalar'})); 
            ip.addOptional('IncubationTemp_C', 37,  @(x) validateattributes(x, {'numeric'}, {'scalar'})); 
            ip.addOptional('PositionXY_pix', [], @(x) validateattributes(x, {'numeric'}, {'scalar'}));   % from top-left corner
            ip.addOptional('FrameScale_micronPerPix', [], @(x) validateattributes(x, {'numeric'}, {'scalar'}));            
            % ip.addOptional('MaxDisplacement_micron', [], @(x) validateattributes(x, {'numeric'}, {'scalar'})); 
            ip.addOptional('displField', [], @(x) validateattributes(x, {'numeric'}, {'scalar'})); 
            ip.addOptional('DisplacementCorrected_micron', [], @(x) validateattributes(x, {'numeric'}, {'scalar'})); 
            ip.addOptional('ForceMT_N', [], @(x) validateattributes(x, {'numeric'}, {'scalar'}));
            ip.addOptional('WorkMT_J', [], @(x) validateattributes(x, {'numeric'}, {'scalar'}));
            ip.addOptional('TimeStampsRT_sec', [], @(x) validateattributes(x, {'numeric'}, {'scalar'}));
            ip.addOptional('TimeStampsND2_sec', [], @(x) validateattributes(x, {'numeric'}, {'scalar'}));
            ip.addOptional('MovieData', '', @(x) isa(x, 'MovieData'));  
            ip.addOptional('Notes', 'Human plasma fibronectin', @ischar);  

            ip.parse(varargin{:});
            
            obj.Diameter_micron = ip.Results.Diameter_micron;
            obj.microsphereID = ip.Results.microsphereID;
            obj.BeadType = ip.Results.BeadType;
            obj.BeadChemistry = ip.Results.BeadChemistry;
            obj.AttachedProtein = ip.Results.AttachedProtein;
            obj.IncubationTemp_C = ip.Results.IncubationTemp_C;
            obj.IncubationTime_min = ip.Results.IncubationTime_min;
            obj.PositionXY_pix = ip.Results.PositionXY_pix;             % could be for a single point of time or over time
            obj.FrameScale_micronPerPix = ip.Results.FrameScale_micronPerPix;
            % obj.MaxDisplacement_micron = ip.Results.MaxDisplacement_micron;
            obj.displField = ip.Results.displField;
            obj.DisplacementCorrected_micron = ip.Results.DisplacementCorrected_micron;
            obj.ForceMT_N = ip.Results.ForceMT_N;
            obj.WorkMT_J = ip.Results.WorkMT_J;
            obj.TimeStampsRT_sec = ip.Results.TimeStampsRT_sec;
            obj.TimeStampsND2_sec = ip.Results.TimeStampsND2_sec;
            obj.GelSample = ip.Results.GelSample;
            obj.Notes = ip.Results.Notes;

        end

        function [maxDispl_micron, MaxFrameNumber] = maxDisplacementCorrected_micron(obj, corrected)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            if corrected
                [maxDispl_micron, MaxFrameNumber] = max(obj.DisplacementCorrected_micron_, 'omitnan');
            else
                [maxDispl_micron, MaxFrameNumber] = max(obj.Displacement_micron_, 'omitnan');
            end
        end
        
    end
end