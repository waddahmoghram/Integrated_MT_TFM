function [grid_mat_padded, grid_mat_padded_trimmed, grid_mat_trimming_TopLeftCorner, grid_mat_trimming_BottomRightCorner] = ...
    PadArrayRandomAndZeros(grid_mat, ZerosOnly)
%PadArrayRandomAndZeros Summary of this function goes here
%{
    v.2020-02-19 by Waddah Moghram
        1. Added a specific random stream to keep results consistent. Before it would give different results every time you run it.
            RandStream.list. Chose this at random: mlfg6331_64
    v.2019-12-18 updated by Waddah Moghram
        1. fixed glitch when padding a 2D-array with no frames.
    v.2019-12-16..17 updated by Waddah Moghram
        1. Fixed glitch in line 34, changed to grid_mat_Size(3)
        2. commented out GPU lines since this function will be spitting in and out gpuArray from other functions.
        3. Updated zero pad to 1X instead of 2X on either side. Line 47
    v.2019-11-20..21 
  Written by Waddah Moghram on to pad the array with random values from the edge of the grid 
    (about half of the size on either side), and twice the size afterwards with 0's.
    grid_mat_padded_trimmed should be the same as grid_mat
%}
  %%
    stream = RandStream('mlfg6331_64');   % keep default seed 0
  
%     nGPU = gpuDeviceCount;
%     if nGPU > 0
%         useGPU = true;
%     else
%         useGPU = false;
%     end  
% 
%     if useGPU
%         grid_mat = gpuArray(grid_mat);
%     end

    %%
    clear grid_mat_EdgeValues randomArray grid_mat_padded_trimmed
    
    if ~exist('ZerosOnly', 'var'), ZerosOnly = []; end
    if nargin < 2 || isempty(ZerosOnly), ZerosOnly = false; end

    grid_mat_Size = size(grid_mat);
    grid_mat_elements = cumprod(grid_mat_Size);   

    if numel(grid_mat_Size) == 3
        for ii = 1:grid_mat_Size(3)
            grid_mat_EdgeValues(:,ii) = [grid_mat(:,1,ii); grid_mat(:,end, ii); grid_mat(1,:, ii)'; grid_mat(end,:, ii)'];
            RandomPadWidth = round(grid_mat_Size .* [0.5, 0.5, 1]);
            ZeroPadWidth = grid_mat_Size .* [2, 2, 2];
        end
    elseif numel(grid_mat_Size) == 2
        grid_mat_EdgeValues(:,1) = [grid_mat(:,1); grid_mat(:,end); grid_mat(1,:)'; grid_mat(end,:)'];
        RandomPadWidth = round(grid_mat_Size .* [0.5, 0.5]);
        ZeroPadWidth = grid_mat_Size .* [2, 2];
    else
        error('grid_mat needs to be a rectangular grid or 2, or 3 dimensions')
    end
    
    grid_mat_PlusPad = padarray(grid_mat,RandomPadWidth(1:2), 1);
    grid_mat_PlusPadSize = size(grid_mat_PlusPad);    
    grid_mat_PlusPadelements = grid_mat_PlusPadSize(1) * grid_mat_PlusPadSize(2);       
    
    mask1 = padarray(zeros(size(grid_mat)), RandomPadWidth(1:2), 1);
    
    
    for ii = 1:size(grid_mat_EdgeValues,2)
        if ~ZerosOnly
            randomArray(:,:,ii) = reshape(datasample(stream, grid_mat_EdgeValues(:,ii), grid_mat_PlusPadelements), grid_mat_PlusPadSize(1:2));    
        else
            randomArray(:,:,ii) = zeros(grid_mat_PlusPadSize(1:2));
        end
    end
    
    randomArrayWithHole = randomArray .* mask1;
    grid_matPlus0Pad = padarray(grid_mat, RandomPadWidth(1:2), 0);
    grid_matPlusRandomPad  = randomArrayWithHole + grid_matPlus0Pad;
    
    grid_mat_padded = padarray(grid_matPlusRandomPad, ZeroPadWidth(1:2), 0);
    
    grid_mat_trimming_TopLeftCorner = [RandomPadWidth(1:2) + ZeroPadWidth(1:2)] + [1,1];
    grid_mat_trimming_BottomRightCorner = grid_mat_trimming_TopLeftCorner(1:2) + grid_mat_Size(1:2) - [1,1];
    
    for ii = 1:size(grid_mat_EdgeValues,2)
        grid_mat_padded_trimmed(:,:,ii) = grid_mat_padded(grid_mat_trimming_TopLeftCorner(1):grid_mat_trimming_BottomRightCorner(1), grid_mat_trimming_TopLeftCorner(2):grid_mat_trimming_BottomRightCorner(2), ii);
    end
    
    if numel(size(grid_mat)) == 2
        grid_mat_padded = grid_mat_padded(:,:,1);    
        grid_mat_padded_trimmed = grid_mat_padded_trimmed(:,:,1);
    end
    
%     if useGPU
%         grid_mat_padded = gather(grid_mat_padded);
%         grid_mat_padded_trimmed = gather(grid_mat_padded_trimmed);
%     end
end

