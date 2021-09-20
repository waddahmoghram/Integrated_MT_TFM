%% Written by Waddah Moghram on 2020-04-22

%%

EveryNth = input('Every how many samples (Default = 2)? ');
if isempty(EveryNth), EveryNth = 2; end
%%
plotedit on
disp('**___Click the axes on the photo that you want, and to continue, type "dbcont" or press "F5", or click "Continue" under "Editor" Menu"'___**')
keyboard
ax = gca;
%%
for i = 1:numel(ax.Children)
    ax.Children(i).XData = decimate(ax.Children(i).XData, EveryNth);
    ax.Children(i).YData = decimate(ax.Children(i).YData, EveryNth);
end