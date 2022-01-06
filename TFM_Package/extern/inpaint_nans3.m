function B=inpaint_nans3(A,method)
% INPAINT_NANS3: in-paints over nans in a 3-D array
% usage: B=INPAINT_NANS3(A)          % default method (0)
% usage: B=INPAINT_NANS3(A,method)   % specify method used
%
% Solves approximation to a boundary value problem to
% interpolate and extrapolate holes in a 3-D array.
% 
% Note that if the array is large, and there are many NaNs
% to be filled in, this may take a long time, or run into
% memory problems.
%
% arguments (input):
%   A - n1 x n2 x n3 array with some NaNs to be filled in
%
%   method - (OPTIONAL) scalar numeric flag - specifies
%       which approach (or physical metaphor to use
%       for the interpolation.) All methods are capable
%       of extrapolation, some are better than others.
%       There are also speed differences, as well as
%       accuracy differences for smooth surfaces.
%
%       method 0 uses a simple plate metaphor.
%       method 1 uses a spring metaphor.
%
%       method == 0 --> (DEFAULT) Solves the Laplacian
%         equation over the set of nan elements in the
%         array.
%         Extrapolation behavior is roughly linear.
%         
%       method == 1 --+ Uses a spring metaphor. Assumes
%         springs (with a nominal length of zero)
%         connect each node with every neighbor
%         (horizontally, vertically and diagonally)
%         Since each node tries to be like its neighbors,
%         extrapolation is roughly a constant function where
%         this is consistent with the neighboring nodes.
%
%       There are only two different methods in this code,
%       chosen as the most useful ones (IMHO) from my
%       original inpaint_nans code.
%
%
% arguments (output):
%   B - n1xn2xn3 array with NaNs replaced
%
%
% Example:
% % A linear function of 3 independent variables,
% % used to test whether inpainting will interpolate
% % the missing elements correctly.
%  [x,y,z] = ndgrid(-10:10,-10:10,-10:10);
%  W = x + y + z;
%
% % Pick a set of distinct random elements to NaN out.
%  ind = unique(ceil(rand(3000,1)*numel(W)));
%  Wnan = W;
%  Wnan(ind) = NaN;
%
% % Do inpainting
%  Winp = inpaint_nans3(Wnan,0);
%
% % Show that the inpainted values are essentially
% % within eps of the originals.
%  std(Winp(ind) - W(ind))
% ans =
%   4.3806e-15
%
%
% See also: griddatan, inpaint_nans
%
% Author: John D'Errico
% e-mail address: woodchips@rochester.rr.com
% Release: 1
% Release date: 8/21/08

% Need to know which elements are NaN, and
% what size is the array. Unroll A for the
% inpainting, although inpainting will be done
% fully in 3-d.
NA = size(A);
A = A(:);
nt = prod(NA);
k = isnan(A(:));

% list the nodes which are known, and which will
% be interpolated
nan_list=find(k);
known_list=find(~k);

% how many nans overall
nan_count=length(nan_list);

% convert NaN indices to (r,c) form
% nan_list==find(k) are the unrolled (linear) indices
% (row,column) form
[n1,n2,n3]=ind2sub(NA,nan_list);

% both forms of index for all the nan elements in one array:
% column 1 == unrolled index
% column 2 == index 1
% column 3 == index 2
% column 4 == index 3
nan_list=[nan_list,n1,n2,n3];

% supply default method
if (nargin<2) || isempty(method)
  method = 0;
elseif ~ismember(method,[0 1])
  error 'If supplied, method must be one of: {0,1}.'
end

% alternative methods
switch method
 case 0
  % The same as method == 1, except only work on those
  % elements which are NaN, or at least touch a NaN.
  
  % horizontal and vertical neighbors only
  talks_to = [-1 0 0;1 0 0;0 -1 0;0 1 0;0 0 -1;0 0 1];
  neighbors_list=identify_neighbors(NA,nan_list,talks_to);
  
  % list of all nodes we have identified
  all_list=[nan_list;neighbors_list];
  
  % generate sparse array with second partials on row
  % variable for each element in either list, but only
  % for those nodes which have a row index > 1 or < n
  L = find((all_list(:,2) > 1) & (all_list(:,2) < NA(1))); 
  nL=length(L);
  if nL>0
    fda=sparse(repmat(all_list(L,1),1,3), ...
      repmat(all_list(L,1),1,3)+repmat([-1 0 1],nL,1), ...
      repmat([1 -2 1],nL,1),nt,nt);
  else
    fda=spalloc(nt,nt,size(all_list,1)*7);
  end
  
  % 2nd partials on column index
  L = find((all_list(:,3) > 1) & (all_list(:,3) < NA(2))); 
  nL=length(L);
  if nL>0
    fda=fda+sparse(repmat(all_list(L,1),1,3), ...
      repmat(all_list(L,1),1,3)+repmat([-NA(1) 0 NA(1)],nL,1), ...
      repmat([1 -2 1],nL,1),nt,nt);
  end

  % 2nd partials on third index
  L = find((all_list(:,4) > 1) & (all_list(:,4) < NA(3))); 
  nL=length(L);
  if nL>0
    ntimesm = NA(1)*NA(2);
    fda=fda+sparse(repmat(all_list(L,1),1,3), ...
      repmat(all_list(L,1),1,3)+repmat([-ntimesm 0 ntimesm],nL,1), ...
      repmat([1 -2 1],nL,1),nt,nt);
  end
  
  % eliminate knowns
  rhs=-fda(:,known_list)*A(known_list);
  k=find(any(fda(:,nan_list(:,1)),2));
  
  % and solve...
  B=A;
  B(nan_list(:,1))=fda(k,nan_list(:,1))\rhs(k);
  
 case 1
  % Spring analogy
  % interpolating operator.
  
  % list of all springs between a node and a horizontal
  % or vertical neighbor
  hv_list=[-1 -1 0 0;1 1 0 0;-NA(1) 0 -1 0;NA(1) 0 1 0; ...
      -NA(1)*NA(2) 0 0 -1;NA(1)*NA(2) 0 0 1];
  hv_springs=[];
  for i=1:size(hv_list,1)
    hvs=nan_list+repmat(hv_list(i,:),nan_count,1);
    k=(hvs(:,2)>=1) & (hvs(:,2)<=NA(1)) & ...
      (hvs(:,3)>=1) & (hvs(:,3)<=NA(2)) & ...
      (hvs(:,4)>=1) & (hvs(:,4)<=NA(3));
    hv_springs=[hv_springs;[nan_list(k,1),hvs(k,1)]];
  end
  
  % delete replicate springs
  hv_springs=unique(sort(hv_springs,2),'rows');
  
  % build sparse matrix of connections
  nhv=size(hv_springs,1);
  springs=sparse(repmat((1:nhv)',1,2),hv_springs, ...
     repmat([1 -1],nhv,1),nhv,prod(NA));
  
  % eliminate knowns
  rhs=-springs(:,known_list)*A(known_list);
  
  % and solve...
  B=A;
  B(nan_list(:,1))=springs(:,nan_list(:,1))\rhs;
  
end

% all done, make sure that B is the same shape as
% A was when we came in.
B=reshape(B,NA);


% ====================================================
%      end of main function
% ====================================================
% ====================================================
%      begin subfunctions
% ====================================================
function neighbors_list=identify_neighbors(NA,nan_list,talks_to)
% identify_neighbors: identifies all the neighbors of
%   those nodes in nan_list, not including the nans
%   themselves
%
% arguments (input):
%  NA - 1x3 vector = size(A), where A is the
%      array to be interpolated
%  nan_list - array - list of every nan element in A
%      nan_list(i,1) == linear index of i'th nan element
%      nan_list(i,2) == row index of i'th nan element
%      nan_list(i,3) == column index of i'th nan element
%      nan_list(i,4) == third index of i'th nan element
%  talks_to - px2 array - defines which nodes communicate
%      with each other, i.e., which nodes are neighbors.
%
%      talks_to(i,1) - defines the offset in the row
%                      dimension of a neighbor
%      talks_to(i,2) - defines the offset in the column
%                      dimension of a neighbor
%      
%      For example, talks_to = [-1 0;0 -1;1 0;0 1]
%      means that each node talks only to its immediate
%      neighbors horizontally and vertically.
% 
% arguments(output):
%  neighbors_list - array - list of all neighbors of
%      all the nodes in nan_list

if ~isempty(nan_list)
  % use the definition of a neighbor in talks_to
  nan_count=size(nan_list,1);
  talk_count=size(talks_to,1);
  
  nn=zeros(nan_count*talk_count,3);
  j=[1,nan_count];
  for i=1:talk_count
    nn(j(1):j(2),:)=nan_list(:,2:4) + ...
        repmat(talks_to(i,:),nan_count,1);
    j=j+nan_count;
  end
  
  % drop those nodes which fall outside the bounds of the
  % original array
  L = (nn(:,1)<1) | (nn(:,1)>NA(1)) | ...
      (nn(:,2)<1) | (nn(:,2)>NA(2)) | ... 
      (nn(:,3)<1) | (nn(:,3)>NA(3));
  nn(L,:)=[];
  
  % form the same format 4 column array as nan_list
  neighbors_list=[sub2ind(NA,nn(:,1),nn(:,2),nn(:,3)),nn];
  
  % delete replicates in the neighbors list
  neighbors_list=unique(neighbors_list,'rows');
  
  % and delete those which are also in the list of NaNs.
  neighbors_list=setdiff(neighbors_list,nan_list,'rows');
  
else
  neighbors_list=[];
end




%
% Copyright (C) 2019, Danuser Lab - UTSouthwestern 
%
% This file is part of TFM_Package.
% 
% TFM_Package is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% TFM_Package is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with TFM_Package.  If not, see <http://www.gnu.org/licenses/>.
% 
% 

