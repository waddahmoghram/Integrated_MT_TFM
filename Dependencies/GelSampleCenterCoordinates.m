% Written by Waddah Moghram, PhD Candidate in Biomedical Engineering at the University of Iowa on 2021-10-18
% Capture the coordinates of three points on the periphery of the gel mold.
xmlFile = 'Y:\_Sandbox\multipoints.xml';
%%
xmlParsed = parseXML(xmlFile);
% finding the beads from the saved Nikon Elements under "ND Multipoint Set Aquisition"
BeadCount = size(xmlParsed.Children.Children, 2) - 2;
% loop between end - 2 to end for that size
% for 3 points: <x1,y1>, <x2,y2>, <x3,y3>
clear x y z
z = zeros(BeadCount, 1); 
for ii = 1:BeadCount
   x(ii, 1) = str2num(xmlParsed.Children.Children(2+ii).Children(3).Attributes(2).Value);
   y(ii, 1) = str2num(xmlParsed.Children.Children(2+ii).Children(4).Attributes(2).Value);  
end
A = horzcat(x.^2+y.^2, x, y, ones(BeadCount,1));
M11 = A(:,2:4);
M12 = A(:,[1,2,4]);
M13 = A(:,[1,3,4]);

x_c = 1/2 * det(M13)/det(M11);
y_c = 1/2 * det(M12)/det(M11);

fprintf('Gel center is at [%0.2f, %0.2f] pixel. Move to that location using XYZ Navigation in Nikon Elements.\n', x_c, y_c)