function [grid_mat_windowed, wnMask] = HanWindow(grid_mat)
%HanWindow Add a han window with a padded array (using PadArrayRandomAndZeros)
%{
    v.2019-12-16 update by Waddah Moghram
        Optimized to minize the conversion to and from GPU. 
        Input will be gpuArray when calling from other functions.
    v.2019-11-21 
        Written by Waddah Moghram, PhD Candidate in Biomedical Engineering at the University of Iowa
        
%}

%%
%     nGPU = gpuDeviceCount;
%     if nGPU > 0
%         useGPU = true;
%     else
%         useGPU = false;
%     end  

%     if useGPU
%         grid_mat = gpuArray(grid_mat);
%     end

%%
    % find grid size
    nr = max(size(grid_mat(:,:,1)));

% Make 1d Hann windows
    w_c = 0.5*(1-cos(2*pi*(0:nr-1)/(nr-1)));
    w_r = 0.5*(1-cos(2*pi*(0:nr-1)/(nr-1)));

% Mesh Hann windows together to form 2D Hann window
    [wnMaskX, wnMaskY] = meshgrid(w_c,w_r);
    wnMask = wnMaskX.*wnMaskY;    
    clear grid_mat_windowed
%     grid_mat_windowed = NaN(size(grid_mat));
    if numel(size(grid_mat)) == 3
        for ii = 1:size(grid_mat, 3)
            grid_mat_windowed(:,:,ii) = grid_mat(:,:,ii) .* wnMask;
        end
    end
    
%     if useGPU
%         grid_mat_windowed = gather(grid_mat_windowed);
%     end
end

