classdef MagBead
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    % Written by Waddah Moghram, PhD Candidate in Biomedical Engineering on 2021-10-07

    properties
        Diameter_micron_
        BeadID_
        BeadType_
        BeadChemistry_
        AttachedProtein_
        IncubationTime_hr_
        IncubationTemp_C_
        PositionXY_pix_
        FrameScale_micronPerPix_
        Displacement_micron_
        DisplacementCorrected_micron_                                % You can find max by searching for it in here
        ForceMT_N_
        WorkMT_J_
        TimeStampsRT_sec
        TimeStampsND2_sec
        GelSample
        Notes_
    end

    methods
        function obj = MagBead(varargin)
            %MagBead Construct an instance of this class
            %   (ID, Type, diametersMicrons)

            ip = inputParser();
            ip.addRequired('BeadID', @ischar);
            ip.addOptional('BeadType', 'M-450 4.5 micron Tosylactivated Dynabeads', @ischar);
            ip.addOptional('BeadChemistry_', 'Tosyl group', @ischar);
            ip.addOptional('AttachedProtein_', 'Human plasma fibronectin', @ischar);  
            ip.addOptional('IncubationTime_hr_', 1, @(x) validateattributes(x, {'numeric'}, {'scalar'})); 
            ip.addOptional('IncubationTemp_C_', 37,  @(x) validateattributes(x, {'numeric'}, {'scalar'})); 
            ip.addOptional('PositionXY_pix', [], @(x) validateattributes(x, {'numeric'}, {'scalar'}));   % from top-left corner
            ip.addOptional('FrameScale_micronPerPix', [], @(x) validateattributes(x, {'numeric'}, {'scalar'}));            
            ip.addOptional('Diameter_micron', 4.5, @(x) validateattributes(x, {'numeric'}, {'scalar'}));   
            % ip.addOptional('MaxDisplacement_micron', [], @(x) validateattributes(x, {'numeric'}, {'scalar'})); 
            ip.addOptional('Displacement_micron', [], @(x) validateattributes(x, {'numeric'}, {'scalar'})); 
            ip.addOptional('DisplacementCorrected_micron', [], @(x) validateattributes(x, {'numeric'}, {'scalar'})); 
            ip.addOptional('ForceMT_nN', [], @(x) validateattributes(x, {'numeric'}, {'scalar'}));
            ip.addOptional('WorkMT_J_', [], @(x) validateattributes(x, {'numeric'}, {'scalar'}));
            ip.addOptional('TimeStampsRT_sec', [], @(x) validateattributes(x, {'numeric'}, {'scalar'}));
            ip.addOptional('TimeStampsND2_sec', [], @(x) validateattributes(x, {'numeric'}, {'scalar'}));
            ip.addOptional('GelSample', [], @(x) isa(x, 'GelSample'));
            ip.addOptional('Notes', 'Human plasma fibronectin', @ischar);  

            ip.parse(varargin{:});

            obj.BeadID_ = ip.Results.BeadID;
            obj.BeadType_ = ip.Results.BeadType;
            obj.BeadChemistry_ = ip.Results.BeadChemistry;
            obj.AttachedProtein_ = ip.Results.AttachedProtein;
            obj.PositionXY_pix_ = ip.Results.PositionXY_pix;             % could be for a single point of time or over time
            obj.FrameScale_micronPerPix_ = ip.Results.FrameScale_micronPerPix;
            obj.Diameter_micron_ = ip.Results.Diameter_micron;
            obj.MaxDisplacement_micron = ip.Results.MaxDisplacement_micron;
            obj.FrameScale_micronPerPix_ = ip.Results.FrameScale_micronPerPix;
            obj.FrameScale_micronPerPix_ = ip.Results.FrameScale_micronPerPix;
            obj.FrameScale_micronPerPix_ = ip.Results.FrameScale_micronPerPix;
            obj.FrameScale_micronPerPix_ = ip.Results.FrameScale_micronPerPix;
            obj.FrameScale_micronPerPix_ = ip.Results.FrameScale_micronPerPix;
            obj.FrameScale_micronPerPix_ = ip.Results.FrameScale_micronPerPix;


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