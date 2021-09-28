 %{
    Created by Waddah Moghram on 2021-08-03
    called  by AIM3Analysis.m
 %}


% **************************** FUNCTIONS DEFINED IN THE SCRIPT "AIM3Analysis.m"

function [CurrentBeadCenter, CurrentBeadRadius] = MagBeadTrackedPosition_imFindCircles(MD_DIC, CurrentDIC_FrameNumber, BeadROI_CroppedRectangle, ...
    BeadRadiusRange, ObjectPolarity, Method, EdgeThreshold, Sensitivity)

%     nGPU = gpuDeviceCount;
%     if nGPU > 0
%         useGPU = true;
%     else
        useGPU = false;
%     end
 
    CurrentDIC_FrameFullImage = MD_DIC.channels_.loadImage(CurrentDIC_FrameNumber);
    if useGPU, CurrentDIC_FrameFullImage = gpuArray(CurrentDIC_FrameFullImage); end

%     fprintf('Tracking magnetic bead in frame %d/%d.\n', CurrentDIC_Frame, MD_DIC.nFrames_)
    
    if useGPU, CurrentDIC_FrameFullImage = gpuArray(CurrentDIC_FrameFullImage); end
    CurrentDIC_FrameFullImage = imadjust(CurrentDIC_FrameFullImage, stretchlim(CurrentDIC_FrameFullImage,[0, 1]));   
    CurrentDIC_FrameImage = imcrop(CurrentDIC_FrameFullImage, BeadROI_CroppedRectangle);
    [CurrentBeadCenter, CurrentBeadRadius, ~] = imfindcircles(CurrentDIC_FrameImage, BeadRadiusRange, 'ObjectPolarity' ,ObjectPolarity, 'Method', Method, 'EdgeThreshold', EdgeThreshold, 'Sensitivity', Sensitivity);   % lowered edge from threshold from 0.8 & sensitivity from 0.95 on 2021-06-27
%     clear CurrentDIC_FrameImage CurrentDIC_FrameFullImage
end
%     
%     ROI_cropped_Extra = BeadROI_CroppedRectangle(3:4) / 2;    
%     ROI_cropped_corner = BeadROI_CroppedRectangle(1:2) -  ROI_cropped_Extra;
%     BeadROI_CroppedRectangle = [ROI_cropped_corner, ROI_cropped_Extra * 4];
%     
%     
%     [CurrentDIC_CurrentFrameImageCropped, ~] = imcrop(CurrentDIC_FrameFullImage, round(BeadROI_CroppedRectangle));
%     CurrentDIC_CurrentFrameImageCroppedAdjust = imadjust(CurrentDIC_CurrentFrameImageCropped, stretchlim(CurrentDIC_CurrentFrameImageCropped, [0, 1]));

%     if useGPU
%         CurrentDIC_CurrentFrameImageCroppedAdjust = gather(CurrentDIC_CurrentFrameImageCroppedAdjust);
% %         BeadROI_DIC = gather(BeadROI_DIC);
% %         CurrentDIC_FrameFullImage = gather(CurrentDIC_FrameFullImage);
%     end
%        
%     [CurrentCenters, CurrentRadii, ~] = imfindcircles(CurrentDIC_CurrentFrameImageCroppedAdjust, BeadRadiusRange, 'ObjectPolarity' , ObjectPolarity, 'Method', Method, 'EdgeThreshold', EdgeThreshold, 'Sensitivity', Sensitivity);   % lowered edge from threshold from 0.8 & sensitivity from 0.95 on 2021-06-27
%     CurrentBeadCenter = max(BeadROI_CroppedRectangle(3:4)) / 2;
%     [~, BeadNodeID] = min(vecnorm(CurrentBeadCenter - CurrentCenters, 2, 2));
%     CurrentBeadCenter = CurrentCenters(BeadNodeID, :) - ROI_cropped_Extra;
%     CurrentBeadRadius = CurrentRadii(BeadNodeID, :);