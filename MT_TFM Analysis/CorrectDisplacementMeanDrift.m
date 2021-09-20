function [displFieldVecDriftCorrected,displFieldVecMean] = CorrectDisplacementMeanDrift(displField, FrameNum)
%CorrectDisplacementMeanDrift subtract the mean displacement from a window 
%   v.2019-11-24 Written by Waddah Moghram
        displFieldPos = displField(FrameNum).pos;
        displFieldVecNoDrift = displField(FrameNum).vec;
        displFieldVecNoDrift(:,3) = vecnorm(displFieldVecNoDrift(:,1:2), 2, 2);

        %___________
        clear displFieldVecMean
        
        DriftWindowLogical = logical(displField(1).pos(:,1) < 130) & logical(displField(1).pos(:,2) < 130);        
        for ii = 1:size(displFieldVecNoDrift, 3)
            displFieldVecMean(ii,:) = mean(displFieldVecNoDrift(DriftWindowLogical, :, ii), 'omitnan');             % pixels per second
        end
        % OR 
        displFieldVecNoDrift = mean(displFieldVecNoDrift, 3, 'omitnan');
        %_______
        displFieldVecMean = horzcat(displFieldVecMean ,vecnorm(displFieldVecMean, 2, 2));
        
        displFieldVecDriftCorrected(:,1:2) = displFieldVecNoDrift(:,1:2) - displFieldVecMean(:,1:2);
        displFieldVecDriftCorrected(:,3) = vecnorm(displFieldVecDriftCorrected(:,1:2), 2, 2);    
end

