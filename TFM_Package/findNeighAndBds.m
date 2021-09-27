function [neigh, bounds, bdPtsID]=findNeighAndBds(p, t)
% generate neighbors, bounding box for each basis function and the convex hull of the mesh.
%{
    This function has been tested for square and hexagonal lattices.

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

%}
    p = gather(p);
    t = gather(t);

    numPts=size(p,1);
    neigh(numPts).cand=[];
    bounds(numPts).x=[];
    bounds(numPts).y=[];

    for idx=1:length(p(:,1))
        %% Modified by WIM on 2/22/2019 't,idx' instead of 't=idex
        [row,~] = find(t,idx);
        %%
        cand = setdiff(unique(t(row,:)),idx);
        %%
%         neigh(idx).cand = gather(round(cand(:)'));
%         neigh(idx).pos = gather(p(neigh(idx).cand,:));
%         bounds(idx).x  = gather([min(neigh(idx).pos(:,1)) max(neigh(idx).pos(:,1))]);
%         bounds(idx).y  = gather([min(neigh(idx).pos(:,2)) max(neigh(idx).pos(:,2))]);
        neigh(idx).cand = round(cand(:)');
        neigh(idx).pos = p(neigh(idx).cand,:);
        bounds(idx).x  = [min(neigh(idx).pos(:,1)) max(neigh(idx).pos(:,1))];
        bounds(idx).y  = [min(neigh(idx).pos(:,2)) max(neigh(idx).pos(:,2))];   
    end
    clear t
    
    % Added by WIM on 2/22/2019
    p = gather(p);
    bdPtsID = convhull(p(:,1),p(:,2));