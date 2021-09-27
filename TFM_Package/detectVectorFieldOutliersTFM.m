function [outlierIndex, sparseIndex, normResid, neighborhood_distance] = detectVectorFieldOutliersTFM(data,varargin)
% detectVectorFieldOutliersTFM detect and return the outliers in a vector field
%{
    Synopsis:        outlierIdx = detectVectorFieldOutliersTFM(data)
                     [outlierIdx,r] = detectVectorFieldOutliersTFM(data,2)

    This function detects outliers within a vectorial field using an extended
    version of the 'median test' of Westerweel et al. 1994, adapted for PTV.
    After finding neighbors within an average bead distance using KDTree,
    the algorithm calculates the directional fluctuation and norm of vector fluctuation
    with respect to the neighborhood median residual for each vertex. 
    A threshold is then applied to this quantity to extract
    the outliers. Directional fluctuation weights more than vector norm
    fluctuation in usual TFM experiment.

    Input:
         data - a vector field, i.e. a matrix of size nx4 where the two first
         columns give the positions and the two last the displacement

         threshold (optional) - a threshold for the detection criterion.
         Usually values are between 2-4 depending on the stringency.

         weighted (optional) - a boolean. If true, neighbors influence is
         weighted using their relative distance to the central point.

    Output
         outlierIndx - the index of the outlier along the first dimension of
         data

         r - the values of the normalized fluctuation for each element of the
         vector field

    For more information, see:
    J. Westerweel & F. Scarano, Exp. Fluids, 39 1096-1100, 2005.
    J. Duncan et al., Meas. Sci. Technol., 21 057002, 2010.

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


    v.2020-08-31 by Waddah Moghram. Fixed the random seed so that used in fitgmdist() is the same between runs.
    Sebastien Besson, Aug 2011
    Sangyoon Han, Mar 2015
    
    %_____% Updated by Waddah Moghram & John C. Selby on 2020-09-08..10
    % 1. Using iterative/adaptive epsilon instead of a fixed default value of 0
    % 2. Using magnitudes of vectors instead of absolute value.
    % 3. use a more realistic neighborhood of 8 beads, which is what the original paper uses. 

%}

    % Input check
    ip=inputParser;
    ip.addRequired('data',@(x) size(x,2)==4);
    ip.addOptional('threshold', 2, @isscalar);
    ip.addOptional('weighted', 1, @isscalar);
    ip.addParameter('epsilon', 0.1, @isscalar);
    ip.parse(data,varargin{:})
    threshold = ip.Results.threshold;
    weighted = ip.Results.weighted;
    epsilon = ip.Results.epsilon;

    % Filter out NaN from the initial data (but keep the index for the outliers)
    ind = find(~isnan(data(:,3)));
    dataNoNan = data(ind,:);

    % Take out duplicate points (Sangyoon)
    [dataU,idata,~] = unique(dataNoNan,'rows'); %data2 = data(idata,:),data = data2(iudata,:)

    %------------------------ Fixed by Waddah Moghram on 2019-06-01
    % calculate maximum closest distance
%     distance = zeros(length(dataU),1);
    distance = NaN(length(dataU),1);
    %-----------------------------------------------------------------------------------------------------------
    neiBeadsWhole = dataU(:,1:2);

%------------------------Fixed by Waddah Moghram on 2019-06-01
% knnsearch is more efficient than using for loops. Better to get all 20 points right away.
% Also, knnsearch is better than KDTreeBallQuery
    scanDist = 9;               % changed down to 9 from 20; 2020-09-10
    [idxDistance, distance] = knnsearch(neiBeadsWhole,dataU(:,1:2), 'K' , scanDist);
    
    N = idxDistance;
    d = distance;
    dataFiltered = dataU;
    
    % Measure weighted local and neighborhood velocities
    options = {1:size(dataFiltered,1),'Unif',false};

%_____% Updated by Waddah Moghram & John C. Selby on 2020-09-08
    % 1. Using iterative/adaptive epsilon instead of a fixed default value of 0
    options2 =  {1:size(dataFiltered,1),'Unif',true};
    medianAllBeads = arrayfun(@(x)(median(d(x,2:end))), options2{:})';
    for ii = 1:numel(medianAllBeads)
        epsilonA(ii, :) = roots([1, medianAllBeads(ii), -0.1]);
    end
    epsilon = epsilonA(epsilonA > 0);                   % local epsilon updated on 2020-09-08
    localVel = arrayfun(@(x)dataFiltered(x,3:4)/(median(d(x,2:end)) + epsilon(x)), options{:})';          % Velocity (or displacement) vector of individual points normalized by median distance to the points.
    neighVel = arrayfun(@(x)dataFiltered(N(x,2:end),3:4)./ repmat(d(x,2:end)' + epsilon(x), 1,2), options{:})';   	% Velocities (or displacements) of all the neighboring vectors

    % Get median weighted neighborhood velocity
    medianVel = cellfun(@median, neighVel, 'Unif',false)';

    % Calculate normalized fluctuation using neighborhood residuals
    medianRes = arrayfun(@(x) median(vecnorm(neighVel{x} - repmat(medianVel{x}, size(neighVel{x},1) ,1), 2, 2)), options2{:})';
    normResid = arrayfun(@(x) vecnorm(localVel{x}- medianVel{x},2, 2)./(medianRes(x) + epsilon(x)),options2{:})';

    outlierIndex = ind(idata(N(logical(normResid > threshold))));
    sparseIndex = outlierIndex;
    neighborhood_distance = max(distance(2,:));  
%__________________________________________________________________