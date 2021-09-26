 %{

 %}

    % **************************** FUNCTIONS DEFINED IN THE SCRIPT "AIM3Analysis.m"

function beadNewPosition = MagBeadTrackedPosition_imRegtform(MD_DIC, CurrentDIC_FrameNumber, BeadROI_DIC, BeadROI_CroppedRectangle, ...
    TransformationType, optimizer, metric, showOutput)

    nGPU = gpuDeviceCount;
    if nGPU > 0
        useGPU = true;
    else
        useGPU = false;
    end
 
    if showOutput
        fprintf('Tracking magnetic bead in frame %d/%d.\n', CurrentDIC_FrameNumber, MD_DIC.nFrames_)
    end
    
    CurrentDIC_FrameFullImage = MD_DIC.channels_.loadImage(CurrentDIC_FrameNumber);
    if useGPU, CurrentDIC_FrameFullImage = gpuArray(CurrentDIC_FrameFullImage); end
    
    [CurrentDIC_CurrentFrameImageCropped, ~] = imcrop(CurrentDIC_FrameFullImage, round(BeadROI_CroppedRectangle));
    CurrentDIC_CurrentFrameImageCroppedAdjust = imadjust(CurrentDIC_CurrentFrameImageCropped, stretchlim(CurrentDIC_CurrentFrameImageCropped, [0, 1]));

    if useGPU
        CurrentDIC_CurrentFrameImageCroppedAdjust = gather(CurrentDIC_CurrentFrameImageCroppedAdjust);
        BeadROI_DIC = gather(BeadROI_DIC);
        CurrentDIC_FrameFullImage = gather(CurrentDIC_FrameFullImage);
    end
    
%     tFormMatrix = imregtform(CurrentDIC_CurrentFrameImageCroppedAdjust, BeadROI_DIC,TransformationType, optimizer, metric);
    tFormMatrix = imregtform(CurrentDIC_FrameFullImage, BeadROI_DIC, TransformationType, optimizer, metric);
    beadNewPosition = BeadROI_CroppedRectangle(1,2) -tFormMatrix.T(3, 1:2);
    
    % Reset Large Array to clear memory
    clear CurrentDIC_FrameFullImage BeadROI_DIC CurrentDIC_CurrentFrameImageCroppedAdjust CurrentDIC_CurrentFrameImageCropped
end