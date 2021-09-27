function [grid_mat,u, i_max, j_max, displHeatMap] = interp_vec2grid(pos, vec, cluster_size, grid_mat, method)
%{
     This program (regularized fourier transform traction force
    reconstruction) was produced at the University of Heidelberg, BIOMS
    group of Ulich Schwarz. It calculates traction from a gel displacement
    field.

    Benedikt Sabass 20-5-2007

    Copyright (C) 2019, Danuser Lab - UTSouthwestern 

    This file is part of TFM_Package.

    TFM_Package is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    TFM_Package is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with TFM_Package.  If not, see <http://www.gnu.org/licenses/>.

    v.2020-02-06..07 by Waddah Moghram
        1. Fixed griddata cubic so that NaNs are fitted using v4.
        2. Replaced meshgrid then transpose with ndgrid() to reduce confusion. 
            In this format: rows are increasing X coordinates, and columns are increasing Y coordinates.
        3. Increased MaskSizePerSide to 15 on each side if possible.

    v.2020-02-04 by Waddah Moghram
        1. Interpolate NaNs instead of going for V4 instead.

    v.2020-02-03 by Waddah Moghram
        1. Modifed to use cubic for most, but replace NAN with V4 values using their function. It is more robust
    v.2020-02-02 by Waddah Moghram
        1. modified to make use of the GPU if it is possible with v4 griddata
    v.2019-11-04 by Waddah Moghram
        Gives the option of which interpolation to use
    v.2019-10-08..09 Fixed by Waddah Moghram
        1. use gridded interpolant instead of griddata()
%} 
    %% parameters 
    scatteredInterpolantMethod =  'linear';
    gridatatMethod = 'cubic';                  % 'cubic';  % cubic leaves more "NaN if the corner is not inside the convex hull polygon.
%     griddedInterpolantMethod = 'cubic';
    MaskSizePerSide = min(15, round(sqrt(size(pos,1))));                        % choose 4 grid points on either side.
    
    %% -----------------------------------------------------------------------------------------------
%     commandwindow;
%     fprintf('============================== Running interp_vec2grid.m GPU-enabled ===============================================\n')

    %---------------- Added by Waddah Moghram on 4/27/2019
    if isempty(pos) || isempty(vec)
       disp('Empty input')
       return
    end
    
    if ~exist('method', 'var'), method = ''; end
    if nargin < 5 || isempty(method)
        method = 'Griddata';
    end
    %---------------
    %% Check if there is a GPU. take advantage of it if is there. Updated on 2019-06-13    
    nGPU = gpuDeviceCount;
    if nGPU > 0
        useGPU = true;
    else
        useGPU = false; 
    end
    %---------------
    if useGPU
        pos = gpuArray(pos);
        vec = gpuArray(vec);
        cluster_size = gpuArray(cluster_size);
        grid_mat = gpuArray(grid_mat);       
    end      
    %---------------
    if nargin == 3 || isempty(grid_mat)
        max_eck(1:2) = [max(pos(:,1)), max(pos(:,2))];
        min_eck(1:2) = [min(pos(:,1)), min(pos(:,2))];

        %A: I added the abs here:
        i_max = abs(floor((max_eck(1)-min_eck(1))/cluster_size));
        j_max = abs(floor((max_eck(2)-min_eck(2))/cluster_size));
        i_max = abs(i_max - mod(i_max,2));
        j_max = abs(j_max - mod(j_max,2));
        
        [X,Y] = ndgrid(min_eck(1)+(1/2:1:(i_max))*cluster_size, min_eck(2)+(1/2:1:(j_max))*cluster_size);
        if useGPU
            X = gpuArray(X);
            Y = gpuArray(Y);
        end
        grid_mat(:,:,1) = X;
        grid_mat(:,:,2) = Y;
        clear X Y;
    else
        i_max = size(grid_mat,1);
        j_max = size(grid_mat,2);
        cluster_size = abs(grid_mat(2,2,1)-grid_mat(1,1,1));
        if ~ismatrix(pos) || ~ismatrix(vec)
            temp_pos(:,1)=reshape(pos(:,:,1),[],1);
            temp_pos(:,2)=reshape(pos(:,:,2),[],1);
            temp_vec(:,1)=reshape(vec(:,:,1),[],1);
            temp_vec(:,2)=reshape(vec(:,:,2),[],1);
            pos = temp_pos;
            vec = temp_vec;
        end
    end    
    %---------------
    if useGPU
        pos = gather(pos);
        vec = gather(vec);
        grid_mat = gather(grid_mat);       
    end  
%     %---------------    Part Before
    if any(isnan(vec(:)))
%         warning('(in interp_vec2grid.m): original data contains NAN values. Removing these values!');
        pos(isnan(vec(:,1)) | isnan(vec(:,2)),:) = [];
        vec(isnan(vec(:,1)) | isnan(vec(:,2)),:) = [];
    end

    minSize = min(size(pos,1), size(vec,1));    
 
% %     %---------------
    switch upper(method)
        case 'GRIDDATA'             % works. Verified 2020-02-06 by WIM            
            u(1:i_max,1:j_max,1) = griddata(pos(1:minSize,1), pos(1:minSize,2), vec(1:minSize,1), grid_mat(:,:,1), grid_mat(:,:,2),gridatatMethod);
            if size(vec, 2) == 2
                u(1:i_max,1:j_max,2) = griddata(pos(1:minSize,1), pos(1:minSize,2), vec(1:minSize,2), grid_mat(:,:,1), grid_mat(:,:,2),gridatatMethod);
            end
            
            if useGPU
               u = gpuArray(u);
               grid_mat = gpuArray(grid_mat);
            end
            
            XI =  grid_mat(:,:,1);
            displHeatMapX = u(1:i_max,1:j_max,1);
            dispHeatMapNANindX = find(isnan(displHeatMapX(:)));
            dispHeatMapNANind = unique(dispHeatMapNANindX);          % combine poins together
            correctedValues = ~isempty(dispHeatMapNANindX);
            
            if size(vec, 2) == 2
                YI =  grid_mat(:,:,2);
                displHeatMapY = u(1:i_max,1:j_max,2);  
                dispHeatMapNANindY = find(isnan(displHeatMapY(:)));
                clear dispHeatMapNANind
                dispHeatMapNANind = unique(horzcat(dispHeatMapNANindX, dispHeatMapNANindY));          % combine poins together  
                correctedValues = ~isempty(dispHeatMapNANindX) || ~isempty(dispHeatMapNANindY);
            end
             %__________________________ CORRECTING for NaNs out of griddata(cubic) using griddata(v4)
            
            
            if correctedValues
%                 warning('NaN values where found')               

                % Method 3: Use the output from cubic grid data to interpolate using griddata(v4)            
                [dispHeatMapNANindX, dispHeatMapNANindY] = ind2sub(size(displHeatMapX), dispHeatMapNANind);

                dispHeatMapNANindXRange = [dispHeatMapNANindX - MaskSizePerSide, dispHeatMapNANindX + MaskSizePerSide];
                dispHeatMapNANindXRange(logical(dispHeatMapNANindXRange(:,1) <= 1), 1) = 1;                
                dispHeatMapNANindXRange(logical(dispHeatMapNANindXRange(:,2) >= size(displHeatMapX,1)), 2) = size(displHeatMapX,1);
                  
                if size(vec, 2) == 2
                    dispHeatMapNANindYRange = [dispHeatMapNANindY - MaskSizePerSide, dispHeatMapNANindY + MaskSizePerSide];
                    dispHeatMapNANindYRange(logical(dispHeatMapNANindYRange(:,1) <= 1), 1) = 1;  
                    dispHeatMapNANindYRange(logical(dispHeatMapNANindYRange(:,2) >= size(displHeatMapX,2)), 2) = size(displHeatMapX,2);
                end
                
                for ii = 1:numel(dispHeatMapNANind)
                    % NOTE: using the line below crashes for very large grid sizes as input;
                    XI_ii = XI(dispHeatMapNANindXRange(ii,1):dispHeatMapNANindXRange(ii,2), dispHeatMapNANindYRange(ii,1):dispHeatMapNANindYRange(ii,2));                
                    displHeatMapX_ii = displHeatMapX(dispHeatMapNANindXRange(ii,1):dispHeatMapNANindXRange(ii,2), dispHeatMapNANindYRange(ii,1):dispHeatMapNANindYRange(ii,2));
                    XI_ii_NoNaN = XI_ii(~logical(isnan(displHeatMapX_ii)));
                    displHeatMapX_ii_NoNaN = displHeatMapX_ii(~logical(isnan(displHeatMapX_ii)));
                    
                    if size(vec, 2) == 2
                        displHeatMapY_ii = displHeatMapY(dispHeatMapNANindXRange(ii,1):dispHeatMapNANindXRange(ii,2), dispHeatMapNANindYRange(ii,1):dispHeatMapNANindYRange(ii,2));
                        YI_ii = YI(dispHeatMapNANindXRange(ii,1):dispHeatMapNANindXRange(ii,2), dispHeatMapNANindYRange(ii,1):dispHeatMapNANindYRange(ii,2));                    
                        YI_ii_NoNaN = YI_ii(~logical(isnan(displHeatMapY_ii)));              
                        displHeatMapY_ii_NoNaN = displHeatMapY_ii(~logical(isnan(displHeatMapY_ii)));
                    end
                    
                    if useGPU
                        displHeatMapX(dispHeatMapNANind(ii)) =  griddata(gather(XI_ii_NoNaN), gather(YI_ii_NoNaN), gather(displHeatMapX_ii_NoNaN), ...
                            gather(XI(dispHeatMapNANind(ii))), gather(YI(dispHeatMapNANind(ii))), 'v4'); 
                        if size(vec, 2) == 2
                            displHeatMapY(dispHeatMapNANind(ii)) =  griddata(gather(XI_ii_NoNaN), gather(YI_ii_NoNaN), gather(displHeatMapY_ii_NoNaN), ...
                                gather(XI(dispHeatMapNANind(ii))), gather(YI(dispHeatMapNANind(ii))), 'v4'); 
                        end
                    else
                        displHeatMapX(dispHeatMapNANind(ii)) =  griddata(XI_ii_NoNaN, YI_ii_NoNaN, displHeatMapX_ii_NoNaN, XI(dispHeatMapNANind(ii)), YI(dispHeatMapNANind(ii)), 'v4'); 
                        if size(vec, 2) == 2
                            displHeatMapY(dispHeatMapNANind(ii)) =  griddata(XI_ii_NoNaN, YI_ii_NoNaN, displHeatMapY_ii_NoNaN, XI(dispHeatMapNANind(ii)), YI(dispHeatMapNANind(ii)), 'v4');  
                        end
                    end
                end            
            end
            %__________________________
            u(1:i_max,1:j_max,1) = displHeatMapX;
            if size(vec, 2) == 2
                u(1:i_max,1:j_max,2) = displHeatMapY;
                displHeatMap = (displHeatMapX.^2 + displHeatMapY.^2).^0.5;              % Find the norm
            else
                displHeatMap = displHeatMapX;
            end
%             u(1:i_max,1:j_max,3) = displHeatMap;
             
        case 'GRIDDATAV4'
            u(1:i_max,1:j_max,1) = griddataV4(pos(1:minSize,1), pos(1:minSize,2), vec(1:minSize,1), grid_mat(:,:,1), grid_mat(:,:,2));
            u(1:i_max,1:j_max,2) = griddataV4(pos(1:minSize,1), pos(1:minSize,2), vec(1:minSize,2), grid_mat(:,:,1), grid_mat(:,:,2));
  
        case 'GRIDDEDINTERPOLANT'
            % % %---- new part by Waddah Moghram on 2019-10-10 that uses griddedInterpolant. INCOMPLETE
%             X = pos(1:minSize,1);
%             X2 = unique(X);             % Unique values to create the grid.
%             Y = pos(1:minSize,2);
%             Y2 = unique(Y);             
%             U = vec(1:minSize,1);       % Unique values to create the grid.
%             uGridInterp(1:i_max,1:j_max,1) = griddedInterpolant(X, Y, U, griddedInterpolantMethod);

        case 'SCATTEREDINTERPOLANT'
            X = pos(1:minSize,1);
            Y = pos(1:minSize,2); 
            Vx = vec(1:minSize,1);
            Vy = vec(1:minSize, 2);
        %     Vnet = vecnorm([Vx,Vy], 2, 2);

            if useGPU
                X = gather(X);
                Y = gather(Y);
                Vx = gather(Vx);
                Vy = gather(Vy);
            end  
    
            % ---------- Scattered Interpolant by Waddah Moghram on 2019-10-10         
            Fx = scatteredInterpolant(X, Y, Vx, scatteredInterpolantMethod);
            Fy = scatteredInterpolant(X, Y, Vy, scatteredInterpolantMethod);        
            u(1:i_max,1:j_max,1) = Fx(grid_mat(:,:,1), grid_mat(:,:,2));
            u(1:i_max,1:j_max,2) = Fy(grid_mat(:,:,1), grid_mat(:,:,2));               
        otherwise
            % do nothintg
    end
    if useGPU
        grid_mat = gather(grid_mat);
        u = gather(u);
        i_max = gather(i_max);
        j_max = gather(j_max);
    end
end