function scale_quivers(qh, scale)
% SCALE_QUIVERS(QH, SCALE) takes an array of quiver handles QH to scale the
% arrows. The arrows are first scaled with reference to the longest vector,
% and then they are scaled by the user-defined SCALE (default 1, i.e. no
% further scaling).

if ~all(isgraphics(qh,'quiver'))
    error('First input must be an array of handles to quiver plots');
end
if nargin == 1
    scale = 1;
end

qh = qh(:); % recast to column
set(qh, 'autoscale', 'off'); % just in case user forgot

% get data and determine if in 2D/3D
U = get(qh,'UData');
V = get(qh,'VData');
W = get(qh,'WData');
if any( cellfun(@numel, W) == 0) % W is empty and hence quiver is in 2D
    twoD = 1;
    W = cellfun(@(x) 0*x, U, 'uniformoutput',0);
else
    twoD = 0;
end

% get max vector length 
L = cellfun(@(x,y,z) max(max(max(sqrt(x.^2 + y.^2 + z.^2)))), U, V, W); % local max of each quiver
L = max(L) / scale^(inv(3-twoD)); % global max

% Scale vectors
U = cellfun(@(x) x/L, U, 'uniformoutput',0);
V = cellfun(@(x) x/L, V, 'uniformoutput',0);
if twoD
    W = cell(size(qh)); % empty cell for W in 2D quivers
else
    W = cellfun(@(x) x/L, W, 'uniformoutput',0);
end

% Apply changes
arrayfun(@(q,D) set(q, 'UData', D{1}), qh, U);
arrayfun(@(q,D) set(q, 'VData', D{1}), qh, V);
arrayfun(@(q,D) set(q, 'WData', D{1}), qh, W);

end