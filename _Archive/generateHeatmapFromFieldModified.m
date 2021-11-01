function [umMap, tmax, tmin, cropInfo,tMapX,tMapY,reg_grid1] = generateHeatmapFromFieldModified(forceField,displField,band)
    % Modified by Waddah Moghram on 12/5/2018 to match Shifted function
    %{
        [tMap, tmax, tmin, cropInfo] = generateHeatmapShifted(forceField,displField,band)
    %
    generates an image of traction in the place of deformed position defined by displField. 

    input: 
              forceField: traction field with pos and vec
              displField: displacement field with pos and vec
              band: pixel band that you want to exclude from the map from the edge

    output:
              tMap: image of traction magnitude contained in cell array
              tmax: max value of traction magnitude
              tmin: min value of traction magnitude
              cropInfo: pos min and max that is used in creating tMap [xmin,ymin,xmax,ymax]
    Sangyoon Han, Nov, 2014
    
    Copyright (C) 2017, Danuser Lab - UTSouthwestern 
    
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

    %% tmax and tmin determination
    tmax = -1;
    tmin = 1e10;
    reg_grid1 = createRegGridFromDisplField(forceField,1,0); %2=2 times fine interpolation
    
    if nargin <3
        band = 0;
    end
    
    for ii = 1:numel(forceField)
        %Load the saved body force map.
        [~,fmat, ~, ~] = interp_vec2grid(forceField(ii).pos, forceField(ii).vec,[], reg_grid1); %1:cluster size
        fnorm = (fmat(:,:,1).^2 + fmat(:,:,2).^2).^0.5;

        % Boundary cutting - I'll take care of this boundary effect later
        fnorm(end-round(band/2):end,:)=[];
        fnorm(:,end-round(band/2):end)=[];
        fnorm(1:1+round(band/2),:)=[];
        fnorm(:,1:1+round(band/2))=[];
        fnorm_vec = reshape(fnorm,[],1); 

        tmax = max(tmax,max(fnorm_vec));
        tmin = min(tmin,min(fnorm_vec));
    end
    
    %%
    ummin = eps;
    temp_ummax = 0;
    
    numNonEmpty = sum(arrayfun(@(x) ~isempty(x.vec),displField));
    
    for k = 1:numNonEmpty
        maxMag = (displField(k).vec(:,1).^2 + displField(k).vec(:,2).^2).^0.5;
        ummin = min(ummin,min(maxMag));
        if nargin < 4 || isempty(ummax)
            ummax = max(temp_ummax, max(maxMag));
        end
    end
    msg = sprintf('Maximum diplacement is %f pixels.\n.',ummax);
    disp(msg)