%{
    Fixed by Waddah Moghram on 2020-02-02 
        1. Based on MATLAB function griddata() for 'v4' method.
        2. Modified to make use of the GPU to speed up the calculations.
        3. Use for NaN for cubic interpolation. that are missing 
%}

function vq = griddataV4(x,y,v,xq,yq)
%GDATAV4 MATLAB 4 GRIDDATA interpolation

%   Reference:  David T. Sandwell, Biharmonic spline
%   interpolation of GEOS-3 and SEASAT altimeter
%   data, Geophysical Research Letters, 2, 139-142,
%   1987.  Describes interpolation using value or
%   gradient of value in any dimension.

    nGPU = gpuDeviceCount;
    if nGPU > 0
        useGPU = true;
    else
        useGPU = false;
    end
    if useGPU
        x = gpuArray(x);
        y = gpuArray(y); 
        v = gpuArray(v); 
        xq = gpuArray(xq);
        yq = gpuArray(yq);
    end
    [x, y, v] = mergepoints2D(x,y,v);

    xy = x(:) + 1i*y(:);

    % Determine distances between points
    d = abs(xy - xy.');
    % Determine weights for interpolation
    g = (d.^2) .* (log(d)-1);   % Green's function.
    
    g(d==0) = 0;
    
    % Fixup value of Green's function along diagonal
    g(1:size(d,1)+1:end) = 0;
    weights = g \ v(:);

    %%
    [m,n] = size(xq);
    vq = zeros(size(xq));
    if useGPU, vq = gpuArray(vq); yq = gpuArray(yq); end
    xy = xy.';    
    
    % Evaluate at requested points (xq,yq).  Loop to save memory. 
    d3 = zeros(m,numel(weights));
    g3 = zeros(m,numel(weights));
    if useGPU
        d3 = gpuArray(d3);
        g3 = gpuArray(g3);
    end
    disp('Calculating griddataV4 in progress...')
    
    
    %________
    reverseString = '';
    for ii=1:m
        ProgressMsg = sprintf('\nEvaluating Row #%d/%d...\n', ii,m);
        fprintf([reverseString, ProgressMsg]);
        reverseString = repmat(sprintf('\b'), 1, length(ProgressMsg));
        xq33 = xq(ii,:);
        yq33 = yq(ii,:);
        d33 = arrayfun(@(jj)(gather(abs((xq33(jj)+1i*yq33(jj))-xy))),1:n,'UniformOutput',false);
        d33Mat = cell2mat(d33);
        xSize = numel(x);
        d33MatReshaped = reshape(d33Mat, xSize, [])';

        g33 = arrayfun(@(jj)(gather((d33MatReshaped(jj,:).^2) .* (log(d33MatReshaped(jj,:))-1))) ,1:n,'UniformOutput',false);
        g33Mat = cell2mat(g33);
        g33MatReshaped = reshape(g33Mat, xSize, [])';
        
        if useGPU
            vq(ii,:) = gather((gpuArray(g33MatReshaped) * gpuArray(weights))');
        else
            vq(ii,:) = (g33MatReshaped * weights)';
        end
        if find(isnan(g33MatReshaped))
            for jj=1:n
                d2= abs(xq(ii,jj) + 1i*yq(ii,jj) - xy);
                g2 = (d2.^2) .* (log(d2)-1);   % Green's function.
                % Value of Green's function at zero
                g2(d2==0) = 0;
                vq(ii,jj) = gather(g2 * weights);       
            end
        end       
    end
    
    %_________
    
%     
%     for ii=1:m
%         for jj=1:n
%             d3(jj,:) = abs((xq(ii,jj) + 1i*yq(ii,jj)) - xy);
%             g3(jj,:) = ((d3(jj,:).^2) .* (log(d3(jj,:))-1));  
%     %             g3(d3(jj,:)==0) = 0;
%         end
%         vq(ii,:) = (g3 * weights)';
%         if find(isnan(gather(g3)))
%             for jj=1:n
%                 d2= abs(xq(ii,jj) + 1i*yq(ii,jj) - xy);
%                 g2 = (d2.^2) .* (log(d2)-1);   % Green's function.
%                 % Value of Green's function at zero
%                 g2(d2==0) = 0;
%                 vq(ii,jj) = gather(g2 * weights);       
%             end
%         end       
%     end
    disp('Calculating griddataV4 is complete!')
%__________________________________________ Original
%     for ii=1:m
%         for jj=1:n
%             d2= abs(xq(ii,jj) + 1i*yq(ii,jj) - xy);
%             g2 = (d2.^2) .* (log(d2)-1);   % Green's function.
%             % Value of Green's function at zero
%             g2(d2==0) = 0;
%             vq(ii,jj) = gather(g2 * weights);       
%         end
%     end
%_________________________________________________
    if useGPU, vq = gather(vq); end
end


function [x, y, v] = mergepoints2D(x,y,v)
    % Sort x and y so duplicate points can be averaged

    %Need x,y and z to be column vectors
    sz = numel(x);
    x = reshape(x,sz,1);
    y = reshape(y,sz,1);
    v = reshape(v,sz,1);
    myepsx = eps(0.5 * (max(x) - min(x)))^(1/3);
    myepsy = eps(0.5 * (max(y) - min(y)))^(1/3);

    % look for x, y points that are indentical (within a tolerance)
    % average out the values for these points
    if isreal(v)
    if strcmpi(class(x), 'gpuArray')
        xyv = builtin('_mergesimpts', gather([y, x, v]), gather([myepsy, myepsx, Inf]), 'average');
        xyv = gpuArray(xyv);
    else
        xyv = builtin('_mergesimpts', [y, x, v], [myepsy, myepsx, Inf], 'average');
    end    
    x = xyv(:,2);
    y = xyv(:,1);
    v = xyv(:,3);
    else
        % if z is imaginary split out the real and imaginary parts
        if strcmpi(class(x), 'gpuArray')
            xyv = builtin('_mergesimpts', gather([y, x, real(v), imag(v)]), ...
                gather([myepsy, myepsx, Inf, Inf]), 'average');
            xyv = gpuArray(xyv);
        else
            xyv = builtin('_mergesimpts', [y, x, real(v), imag(v)], ...
                [myepsy, myepsx, Inf, Inf], 'average');
        end
        x = xyv(:,2);
        y = xyv(:,1);
        % re-combine the real and imaginary parts
        v = xyv(:,3) + 1i*xyv(:,4);
    end
    % give a warning if some of the points were duplicates (and averaged out)
    if sz > numel(x)
        warning(message('MATLAB:griddata:DuplicateDataPoints'));
    end
end

