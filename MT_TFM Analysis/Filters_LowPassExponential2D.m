function [pos_grid_trimmed, disp_grid_trimmed, stress_grid_trimmed, i_max_windowed, j_max_windowed, qMax] = Filters_LowPassExponential2D(pos_grid_trimmed, disp_grid_NotFiltered, gridSpacing, z, h, YoungModulus, PoissonRatio, ...
    fracPad, min_feature_size, ExpOrder, reg_corner, i_max, j_max)
%{
    v.2019-12-14 by Waddah Moghram
        1. pos_grid for input, and disp_grid_trimmed, and so forth
        2. Change the file name from "Filters_LowPassGaussian2D.m" to "Filters_LowPassExponential2D.m"
        3. Added line to trim the output so that it is the same as the input
    v.2019-12-13 by Waddah Moghram
        1. Added output of qMsk, which is dependent on the qMsk
    v.2019-11-27 by Waddah Moghram
        1. Fixed glitched that did not feed the right displacement 
        2. Future edition. Allow a choice of Han Windowing or Not. For now, i_max and j_max are not used in this function. 
            z, h are used for 3D TFM only.
    v.2019-11-18 Written by Waddah Moghram 
        % Outputs displacement field and the corresponding stresss_grid.
%}      
 %% ========  Check if there is a GPU. take advantage of it if is there. ============================================================  
    nGPU = gpuDeviceCount;
    if nGPU > 0
        useGPU = true;
    else
        useGPU = false;
    end
    
    if ~exist('fracPad', 'var'), fracPad = []; end
    if nargin < 7 || isempty(fracPad)
        fracPad = 0.5;
    end
    
    if ~exist('min_feature_size', 'var'), min_feature_size = []; end
    if nargin < 8 || isempty(min_feature_size)
        min_feature_size = 1;
    end
    
    if ~exist('ExpOrder', 'var'), ExpOrder = []; end
    if nargin < 9 || isempty(ExpOrder)
        ExpOrder = 2;
    end
    
    if useGPU
        disp_grid_NotFiltered = gpuArray(disp_grid_NotFiltered);
    end
    
            %% ---------
    [nr,nc,nz] = size(disp_grid_NotFiltered);

    if mod(nr,2)==0             % even grid
        nr2 = round((1+2*fracPad)*nr);
    else
        nr2 = 1 + round((1+2*fracPad)*nr);
    end
    
    % calculate filter for the displacement data (in Fourier space). This is effectively a low-pass exponential filter.
    % No changes should be necessary if modifying code for 3d TFM.
    qMax = nr2/(pi * min_feature_size);

    % Get distance from of a grid point from the centre of the array
    y = repmat((1:nr2)'-nr2/2,1,nr2);
    if useGPU
        y = gpuArray(y);
    end    
    x = y';
    q = sqrt(x.^2+y.^2);
    
    % Make the filter
    qmsk = exp(-(q./qMax).^ExpOrder);
    %Shifts 4 quadrants
    qmsk = ifftshift(qmsk);

     % Make 1d Hann windows
    [szr,szc,szrz] = size(disp_grid_NotFiltered);

    if useGPU
        szr = gpuArray(szr);
        szc = gpuArray(szc);
        szrz = gpuArray(szrz);
    end

    w_c = 0.5*(1-cos(2*pi*(0:szc-1)/(szc-1)));
    w_r = 0.5*(1-cos(2*pi*(0:szr-1)/(szr-1)));

    % Mesh Hann windows together to form 2d Hann window
    [wnx,wny] = meshgrid(w_c,w_r);
%     [wnx,wny]=ndgrid(w_c,w_r);
    wn = wnx.*wny;

%     % Pad the window
    padwidth = round((nr2-nr)/2);
    padheight = round((nr2-nr)/2);
    
%     [sz1,sz2] = size(wn);

    % If you have the Image Processing Toolbox, this is equivalent to
    wn = padarray(wn,[padwidth, padheight]);
%     pos_grid_stress_trimmed = padarray(pos_grid, [padwidth, padheight]);
    
    tmpDisplField(1).u = padarray(disp_grid_NotFiltered(:,:,1),[padwidth,padheight]);
    tmpDisplField(1).u = real(ifft2(qmsk.*fft2(tmpDisplField(1).u)));    
    tmpDisplField(1).u = tmpDisplField(1).u .* wn; 


    tmpDisplField(2).u = padarray(disp_grid_NotFiltered(:,:,2),[padwidth,padheight]);
    tmpDisplField(2).u = real(ifft2(qmsk.*fft2(tmpDisplField(2).u)));    
    tmpDisplField(2).u = tmpDisplField(2).u .* wn;      
%             
%             % Image Size in Pixels
%             size_cell_image = movieData.imSize_;

%     % calculate stress directly. No regularization in this case
%     % Q matrix that interpolates between displacements and stresses at the substrate surface in Fourier space.
%     Q = calcQ(z,h,YoungModulus, PoissonRatio,nr2,gridSpacing,2); 
%     tmpStressField = disp2stress(tmpDisplField,Q);

    disp_grid_Windowed = cat(3, tmpDisplField(1).u, tmpDisplField(2).u);
    disp_grid_Windowed(:,:,3) = sqrt(disp_grid_Windowed(:,:,1).^2 + disp_grid_Windowed(:,:,2).^2);
    [i_max_windowed, j_max_windowed, ~] = size(disp_grid_Windowed);
    
    if mod(nr,2)==0
        [~,~, stress_vector, stress_vector_norm] = reg_fourier_TFM([], disp_grid_Windowed(:,:,1:2), YoungModulus,...
            PoissonRatio, [], gridSpacing, i_max_windowed, j_max_windowed, reg_corner);
            stress_vector(:,3) = stress_vector_norm;    
    else
        [~,~, stress_vector, stress_vector_norm] = reg_fourier_TFM_odd([], disp_grid_Windowed(:,:,1:2), YoungModulus,...
            PoissonRatio, [], gridSpacing, i_max_windowed, j_max_windowed, reg_corner);
            stress_vector(:,3) = stress_vector_norm;                               
    end
    stress_grid(:,:,1) = reshape(stress_vector(:,1), i_max_windowed,j_max_windowed);
    stress_grid(:,:,2) = reshape(stress_vector(:,2), i_max_windowed,j_max_windowed);
    stress_grid(:,:,3) = reshape(stress_vector(:,3), i_max_windowed,j_max_windowed);
    
    tmpStressField(1).s = stress_grid(:,:,1);  
    tmpStressField(2).s = stress_grid(:,:,2);
    tmpStressField(3).s = stress_grid(:,:,3);
    
%     if useGPU
%         disp_grid_FilteredWindowed = gather(disp_grid_FilteredWindowed);
%         stress_grid = gather(stress_grid);
%     end
    
    try
        stress_grid_trimmed(:,:,1) = tmpStressField(1).s((nr2-nr)/2+1:((nr2-nr)/2+nr),(nr2-nr)/2+1:((nr2-nr)/2+nr));
        stress_grid_trimmed(:,:,2) = tmpStressField(2).s((nr2-nr)/2+1:((nr2-nr)/2+nr),(nr2-nr)/2+1:((nr2-nr)/2+nr));
        stress_grid_trimmed(:,:,3) = tmpStressField(3).s((nr2-nr)/2+1:((nr2-nr)/2+nr),(nr2-nr)/2+1:((nr2-nr)/2+nr));
    catch
        stress_grid_trimmed(:,:,1) = stress_grid(:,1);
        stress_grid_trimmed(:,:,2) = stress_grid(:,2);
        stress_grid_trimmed(:,:,3) = stress_grid(:,3);
    end
    
    ux = tmpDisplField(1).u((nr2-nr)/2+1:((nr2-nr)/2+nr),(nr2-nr)/2+1:((nr2-nr)/2+nr));
    uy = tmpDisplField(2).u((nr2-nr)/2+1:((nr2-nr)/2+nr),(nr2-nr)/2+1:((nr2-nr)/2+nr));
    unorm = sqrt(ux.^2 + uy.^2);
%     sed = 1/2*d(i).stress_x.*d(i).ux + 1/2*d(i).stress_y.*d(i).uy;               % strain energy. Mertz et al. PRL 108, 198101 (2012).


    disp_grid_trimmed(:,:,1) = ux;
    disp_grid_trimmed(:,:,2) = uy;
    disp_grid_trimmed(:,:,3) = unorm;
    
    if useGPU
        pos_grid_trimmed = gather(pos_grid_trimmed);
        stress_grid_trimmed = gather(stress_grid_trimmed);
        disp_grid_trimmed = gather(disp_grid_trimmed);
    end
end

