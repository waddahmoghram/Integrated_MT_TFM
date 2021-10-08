classdef MagBead
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    % Written by Waddah Moghram, PhD Candidate in Biomedical Engineering on 2021-10-07

    properties
        Diameter_um_
        BeadID_
        BeadType_
        ConguationProtein_
        IncubationTime_hr_
        IncubationTemp_C_
        Displacement_um
        DisplacementCorrected_um                                % You can find max by searching for it in here
        PositionXY_pix
        FrameScale_umPerPix
        Force_nN
        TimeStampsRT_sec;
        TimeStampsND2_sec;
        GelSample
    end

    methods
        function obj = MagBead(varargin)
            %MagBead Construct an instance of this class
            %   (ID, Type, diametersMicrons)

            ip = inputParser();
            ip.addRequired('BeadID', @ischar);
            ip.addOptional('BeadType', 'M-450 Tosylactivated Dynabeads', @ischar);  
            ip.addOptional('Diameter_um', 4.5, @(x) validateattributes(x, {'numeric'}, {'scalar'}));   
            ip.addOptional('PositionXY_pix', [], @(x) validateattributes(x, {'numeric'}, {'scalar'}));   % from top-left corner
            ip.addOptional('FrameScale_umPerPix', [], @(x) validateattributes(x, {'numeric'}, {'scalar'}));            
            ip.addOptional('MaxDisplacement_um', [], @(x) validateattributes(x, {'numeric'}, {'scalar'})); 
            ip.addOptional('ConguationProtein', 'Human plasma fibronectin', @ischar);  
            ip.addOptional('IncubationTime_hr_', 1, @(x) validateattributes(x, {'numeric'}, {'scalar'})); 
            ip.addOptional('IncubationTemp_C_', 37,  @(x) validateattributes(x, {'numeric'}, {'scalar'})); 
            ip.addOptional('Displacement_um', [], @(x) validateattributes(x, {'numeric'}, {'scalar'})); 
            ip.addOptional('DisplacementCorrected_um', [], @(x) validateattributes(x, {'numeric'}, {'scalar'})); 
            ip.addOptional('Force_nN', [], @(x) validateattributes(x, {'numeric'}, {'scalar'}));
            ip.addOptional('TimeStampsRT_sec', [], @(x) validateattributes(x, {'numeric'}, {'scalar'}));
            ip.addOptional('TimeStampsND2_sec', [], @(x) validateattributes(x, {'numeric'}, {'scalar'}));
            ip.addOptional('GelSample', [], @(x) isa(x, 'GelSample'));

            ip.parse(varargin{:});

            obj.BeadID_ = ip.Results.BeadID;
            obj.BeadType_ = ip.Results.BeadType;
            obj.Diameter_um_ = ip.Results.Diameter_um;
            obj.PositionXY_pix = ip.Results.PositionXY_pix;             % could be for a single point of time or over time
            obj.FrameScale_umPerPix = ip.Results.FrameScale_umPerPix;


            obj.ConguationProtein_ = ip.Results.ConguationProtein;

        end

        function maxDispl_um = maxDisplacementCorrected_um(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            maxDispl_um = max(obj.DisplacementCorrected_um, 'omitnan');
        end
    end
end