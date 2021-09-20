 %{
    Created by Waddah Moghram on 2021-08-03
    called  by AIM3Analysis.m
 %}

    % **************************** FUNCTIONS DEFINED IN THE SCRIPT "AIM3Analysis.m"

function [CurrentCenters, CurrentRadii, metric] = MagBeadTrackedPosition_imtFindCircles(MD_DIC, CurrentDIC_Frame, BeadROI_DIC, ...
    TransformationType, optimizer, metric)
    
    cornerCount = 4;
    nGPU = gpuDeviceCount;
    if nGPU > 0
        useGPU = true;
    else
        useGPU = false;
    end

    CurrentDIC_FrameFullImage = MD_DIC.channels_.loadImage(CurrentDIC_Frame);
    if useGPU, CurrentFrameImage = gpuArray(CurrentFrameImage); end
    CurrentFrameImageAdjust = imadjust(CurrentFrameImage, stretchlim(CurrentFrameImage,[0, 1]));
    fprintf('Tracking magnetic bead in frame %d/%d.\n', CurrentDIC_Frame, MD_DIC.nFrames_)
    
    if useGPU, CurrentDIC_FrameFullImage = gpuArray(CurrentDIC_FrameFullImage); end
        CurrentDIC_FrameImageFullAdjust = imadjust(CurrentDIC_FrameFullImage, stretchlim(RefFrameDIC,[0, 1]));   
        CurrentDIC_FrameImage = imcrop(CurrentDIC_FrameImageFullAdjust, BeadROI_rect);
        [CurrentCenters, CurrentRadii, metric] = imfindcircles(CurrentDIC_FrameImage, BeadRadiusRange, 'ObjectPolarity' ,'dark', 'Method', 'TwoStage', 'EdgeThreshold', 0.4, 'Sensitivity', 0.8);   % lowered edge from threshold from 0.8 & sensitivity from 0.95 on 2021-06-27
    end