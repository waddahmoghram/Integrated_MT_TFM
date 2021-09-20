function [FGridValue,Xquery,Yquery]  = GridPointFromXYCoordinates(Fgrid,Xgrid,Ygrid, Xquery, Yquery)
%GridPointFromXYCoordinates returns the value from X,Y coordinates
%  X and Y are mesh grids created by meshgrid() or ndgrid(). Grid is a function of X and Y
 % Written by Waddah Moghram on 2020-02-06
    Xquery = round(Xquery);
    Yquery = round(Yquery);
    NodeIndex = find(logical(Xgrid == round(Xquery)) & logical(Ygrid==Yquery));
    FGridValue =  Fgrid(NodeIndex);
%     fprintf('%0.4g @(%g,%g)\n',FGridValue, round(Xquery), round(Yquery));
end

