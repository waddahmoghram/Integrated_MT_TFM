 %{
    Created by Waddah Moghram on 2021-08-03
    called  by AIM3Analysis.m
 %}

    % **************************** FUNCTIONS DEFINED IN THE SCRIPT "AIM3Analysis.m"
    function meanDriftFrame = cornerMeanDrifts(MD_DIC, CurrentFrame, DriftROI_rect, RefFrameDIC_RectImage, ...
        TransformationType, optimizer, metric)
        cornerCount = 4;
        nGPU = gpuDeviceCount;
        if nGPU > 0
            useGPU = true;
        else
            useGPU = false;
        end
    
        CurrentFrameImage = MD_DIC.channels_.loadImage(CurrentFrame);
        if useGPU, CurrentFrameImage = gpuArray(CurrentFrameImage); end
        CurrentFrameImageAdjust = imadjust(CurrentFrameImage, stretchlim(CurrentFrameImage,[0, 1]));

        for jj = 1:cornerCount
            CurrentFrameRectImage{jj} = imcrop(CurrentFrameImageAdjust,  DriftROI_rect(jj, :)); 
            tFormMatrix = imregtform(gather(RefFrameDIC_RectImage{jj}), gather(CurrentFrameRectImage{jj}), TransformationType, optimizer, metric);  
            meanDIC_DriftROIs(jj,1:2) = tFormMatrix.T(3, 1:2);
            meanDIC_DriftROIs(jj,3) = vecnorm(meanDIC_DriftROIs(jj,1:2), 2, 2);        % displacement             
        end
        meanDriftFrame = mean(meanDIC_DriftROIs);
        meanDriftFrame(1,3) = vecnorm(meanDriftFrame, 2, 2);
        if useGPU, meanDriftFrame = gather(meanDriftFrame); end    
    end
     % ********************************** 