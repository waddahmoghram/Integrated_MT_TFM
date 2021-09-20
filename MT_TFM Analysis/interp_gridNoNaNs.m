%% Written by Waddah Moghram on 2020-02-06 to work with ExtractBeadMaxDisplacementEPIGrid.m
% This piece can be expanded to work with heatmaps. 

function [displHeatMap, displHeatMapX, displHeatMapY] = interp_gridNoNaNs(grid_matX, grid_matY, dMapX,dMapY, XI, YI, CurrentFrame, MaskSizePerSide)       
        
        displHeatMapX =  griddata(grid_matX, grid_matY, dMapX{CurrentFrame} ,XI, YI, 'cubic'); 
        displHeatMapY = griddata(grid_matX, grid_matY, dMapY{CurrentFrame} ,XI, YI, 'cubic');   

        %__________________________ CORRECTING for NaNs out of griddata(cubic) using griddata(v4)
        dispHeatMapNANindX = find(isnan(displHeatMapX(:)));
        dispHeatMapNANindY = find(isnan(displHeatMapY(:)));
        dispHeatMapNANind = unique(horzcat(dispHeatMapNANindX, dispHeatMapNANindY));          % combine poins together            
        if ~isempty(dispHeatMapNANindX) || ~isempty(dispHeatMapNANindY)
%             Method 1. Using inpaint_nan3 to fill the NaN, which solves some PDEs to interpolate (or extrapolate the data).
%             warning('NaN values where found in X-component')  
%             displHeatMapX = inpaint_nans3(displHeatMapX);
%             displHeatMapY = inpaint_nans3(displHeatMapY);
% 
%             Method 2: Re-use griddata to interpolate using '-V4" only for the points that are missing
%             displHeatMapX =  griddata(grid_matX, grid_matY, dMapX{CurrentFrame} ,XI, YI, 'v4'); 
%             displHeatMapY = griddata(grid_matX, grid_matY, dMapY{CurrentFrame} ,XI, YI, 'v4'); 
% 
%             Method 3: Use the output from cubic grid data to interpolate using griddata(v4)            
             [dispHeatMapNANindX, dispHeatMapNANindY] = ind2sub(size(displHeatMapX), dispHeatMapNANind);

             dispHeatMapNANindXRange = [dispHeatMapNANindX - MaskSizePerSide, dispHeatMapNANindX + MaskSizePerSide];
             dispHeatMapNANindYRange = [dispHeatMapNANindY - MaskSizePerSide, dispHeatMapNANindY + MaskSizePerSide];

             % If negative range, choose the first grid point. displHeatMapX should have the same size.
             dispHeatMapNANindXRange(logical(dispHeatMapNANindXRange(:,1) < 1), 1) = 1;
             dispHeatMapNANindYRange(logical(dispHeatMapNANindYRange(:,1) < 1), 1) = 1;  

             dispHeatMapNANindXRange(logical(dispHeatMapNANindXRange(:,2) > size(displHeatMapX,1)), 2) = size(displHeatMapX,1);
             dispHeatMapNANindYRange(logical(dispHeatMapNANindYRange(:,2) > size(displHeatMapX,2)), 2) = size(displHeatMapX,2);  


             for ii = 1:numel(dispHeatMapNANind)
                % NOTE: using the line below crashes for very large grid sizes as input;
                XI_ii = XI(dispHeatMapNANindXRange(ii,1):dispHeatMapNANindXRange(ii,2), dispHeatMapNANindYRange(ii,1):dispHeatMapNANindYRange(ii,2));
                YI_ii = YI(dispHeatMapNANindXRange(ii,1):dispHeatMapNANindXRange(ii,2), dispHeatMapNANindYRange(ii,1):dispHeatMapNANindYRange(ii,2));
                displHeatMapX_ii = displHeatMapX(dispHeatMapNANindXRange(ii,1):dispHeatMapNANindXRange(ii,2), dispHeatMapNANindYRange(ii,1):dispHeatMapNANindYRange(ii,2));
                displHeatMapY_ii = displHeatMapY(dispHeatMapNANindXRange(ii,1):dispHeatMapNANindXRange(ii,2), dispHeatMapNANindYRange(ii,1):dispHeatMapNANindYRange(ii,2));


                XI_ii_NoNaN = XI_ii(~logical(isnan(displHeatMapX_ii)));
                YI_ii_NoNaN = YI_ii(~logical(isnan(displHeatMapY_ii)));                 
                displHeatMapX_ii_NoNaN = displHeatMapX_ii(~logical(isnan(displHeatMapX_ii)));
                displHeatMapY_ii_NoNaN = displHeatMapY_ii(~logical(isnan(displHeatMapY_ii)));

                displHeatMapX(dispHeatMapNANind(ii)) =  griddata(XI_ii_NoNaN, YI_ii_NoNaN, displHeatMapX_ii_NoNaN, XI(dispHeatMapNANind(ii)), YI(dispHeatMapNANind(ii)), 'v4'); 
                displHeatMapY(dispHeatMapNANind(ii)) =  griddata(XI_ii_NoNaN, YI_ii_NoNaN, displHeatMapY_ii_NoNaN, XI(dispHeatMapNANind(ii)), YI(dispHeatMapNANind(ii)), 'v4');  
             end            
        end
        %__________________________
        displHeatMap = (displHeatMapX.^2 + displHeatMapY.^2).^0.5;              % Find the norm           
    end
    