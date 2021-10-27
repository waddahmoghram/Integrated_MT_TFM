classdef MagBead
    %MagBead(BeadID)Summary of this class goes here
    %   Other options properties are: 
    % Written by Waddah Moghram, PhD Candidate in Biomedical Engineering on 2021-10-07

    properties
        BeadID
        GelSample
        Diameter_micron
        BeadType
        BeadChemistry
        AttachedProtein
        IncubationTime_hr
        IncubationTemp_C
        PositionXY_pix
        FrameScale_micronPerPix
        % MaxDisplacement_micron
        Displacement_micron
        DisplacementCorrected_micron                                % You can find max by searching for it in here
        ForceMT_N
        WorkMT_J
        TimeStampsRT_sec
        TimeStampsND2_sec
        Notes
    end

    methods
        function obj = MagBead(varargin)
            %MagBead Construct an instance of this class
            %   (ID, Type, diametersMicrons, ...). All default values are based on latest round of experiments on 2021-10-24

            ip = inputParser();
            ip.addRequired('BeadID', @ischar);
            ip.addOptional('GelSample', [], @(x) isa(x, 'GelSample'));
            ip.addOptional('Diameter_micron', 4.5, @(x) validateattributes(x, {'numeric'}, {'scalar'}));   
            ip.addOptional('BeadType', 'Dynabeads M-450 Tosylactivated superparamagnetic beads', @ischar);
            ip.addOptional('BeadChemistry', 'Tosyl group', @ischar);
            ip.addOptional('AttachedProtein', 'Human plasma fibronectin purified protein. (Millipore Sigma, REF: FC010)', @ischar);  
            ip.addOptional('IncubationTime_hr', duration(4,0,0), @(x) isa('duration'));     % duration type is duration(hh:mm:ss), unless other format is specified. 4 hours initially
            ip.addOptional('IncubationTemp_C', 37,  @(x) validateattributes(x, {'numeric'}, {'scalar'})); 
            ip.addOptional('PositionXY_pix', [], @(x) validateattributes(x, {'numeric'}, {'scalar'}));   % from top-left corner
            ip.addOptional('FrameScale_micronPerPix', [], @(x) validateattributes(x, {'numeric'}, {'scalar'}));            
            % ip.addOptional('MaxDisplacement_micron', [], @(x) validateattributes(x, {'numeric'}, {'scalar'})); 
            ip.addOptional('Displacement_micron', [], @(x) validateattributes(x, {'numeric'}, {'scalar'})); 
            ip.addOptional('DisplacementCorrected_micron', [], @(x) validateattributes(x, {'numeric'}, {'scalar'})); 
            ip.addOptional('ForceMT_N', [], @(x) validateattributes(x, {'numeric'}, {'scalar'}));
            ip.addOptional('WorkMT_J', [], @(x) validateattributes(x, {'numeric'}, {'scalar'}));
            ip.addOptional('TimeStampsRT_sec', [], @(x) validateattributes(x, {'numeric'}, {'scalar'}));
            ip.addOptional('TimeStampsND2_sec', [], @(x) validateattributes(x, {'numeric'}, {'scalar'}));
            ip.addOptional('Notes', '', @ischar);  

            ip.parse(varargin{:});
            
            obj.Diameter_micron = ip.Results.Diameter_micron;
            obj.BeadID = ip.Results.BeadID;
            obj.BeadType = ip.Results.BeadType;
            obj.BeadChemistry = ip.Results.BeadChemistry;
            obj.AttachedProtein = ip.Results.AttachedProtein;
            obj.IncubationTemp_C = ip.Results.IncubationTemp_C;
            obj.IncubationTime_hr = ip.Results.IncubationTime_hr;
            obj.PositionXY_pix = ip.Results.PositionXY_pix;             % could be for a single point of time or over time
            obj.FrameScale_micronPerPix = ip.Results.FrameScale_micronPerPix;
            % obj.MaxDisplacement_micron = ip.Results.MaxDisplacement_micron;
            obj.Displacement_micron = ip.Results.Displacement_micron;
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