 %{
    Created by Waddah Moghram on 2021-08-03
    called  by AIM3Analysis.m
 %}

    % **************************** FUNCTIONS DEFINED IN THE SCRIPT "AIM3Analysis.m"

function beadNewPosition = MagBeadTrackedPosition_imtRegForm(MD_DIC, CurrentDIC_Frame, BeadROI_DIC, ...
    TransformationType, optimizer, metric, showOutput)
    
    cornerCount = 4;
    nGPU = gpuDeviceCount;
    if nGPU > 0
        useGPU = true;
    else
        useGPU = false;
    end
 
    if showOutput
        fprintf('Tracking magnetic bead in frame %d/%d.\n', CurrentDIC_Frame, MD_DIC.nFrames_)
    end
    CurrentDIC_FrameFullImage = MD_DIC.channels_.loadImage(CurrentDIC_Frame);
    if useGPU, CurrentDIC_FrameFullImage = gpuArray(CurrentDIC_FrameFullImage); end
    
    CurrentDIC_FrameImageFullAdjust = imadjust(CurrentDIC_FrameFullImage, stretchlim(CurrentDIC_FrameFullImage, [0, 1]));
%     CurrentFrameImageROI = imcrop(CurrentDIC_FrameImageFullAdjust,
%     CroppedRectangle); 
    tFormMatrix = imregtform(gather(CurrentDIC_FrameImageFullAdjust), gather(BeadROI_DIC),TransformationType, optimizer, metric);
    beadNewPosition = -tFormMatrix.T(3, 1:2);
end