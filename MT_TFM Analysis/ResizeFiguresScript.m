% by Waddah Moghram on 2020-03-30..updated 2020-09-29...2020-10-06
% Open the *.fig file 

ax = gca;
ax.Units = 'inches';
pos = ax.Position(3:4);
SizeLength = 3.5;             % 4 inches or whatever you want.
Ratio = SizeLength./ pos(1);                
ax.Position = [0.1,0.1, Ratio .* ax.Position(3:4)];

plotedit on
% readjust figure

fig = gcf;
fig.MenuBar = 'figure';
fig.Resize = 'on';
fig.Units = 'inches';

%%
% save as *.eps to open in illustrator
% choose the colorbar
cb = gco;   
cb.LineWidth = 0.5;
cb.Units = 'inches';
cb.Position = [0.12 + ax.Position(3), 0.1, 0.1, ax.Position(4)];
cb.FontSize = 11;
cb.FontName = 'Arial Narrow';
 
%%
% select the scale bar
sb = gco;
sb.Children(1).FontSize = 7;
sb.Children(2).LineWidth = 2;

%%
% select the timestamps text
ts = gco;
ts.FontSize  = 7;
%%
% select the Quivers if there are any
qvr = gco;
qvr.LineWidth = 0.75;

%% For zoomedin Figure
xaxlim = [390, 615];
yaxlim = [390, 615];

%
qvr = gco;
qvr.AutoScale = 'on';
% qvr.AutoScaleFactor = 2;
qvr.LineWidth = 2;
qvr.ShowArrowHead = 'off';

inbound = (qvr.XData > xaxlim(1)) &  (qvr.XData < xaxlim(2)) &  (qvr.YData > yaxlim(1)) &  (qvr.YData < yaxlim(2));

qvr.XData(~inbound) = [];
qvr.YData(~inbound) = [];
qvr.UData(~inbound) = [];
qvr.VData(~inbound) = [];

xlim(xaxlim)
ylim(yaxlim)


ax = gca;
ax.CameraPositionMode = 'auto';



%% Move Scale bar 
 sb = ax.Children(3);
 sb.Children(2).YData = [420, 420];
 sb.Children(2).XData = [470, 470 + (964 - 871.306873562934)];