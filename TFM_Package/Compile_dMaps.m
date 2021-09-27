%% Compiled individual grid to a big traction map
numNonEmpty = FrameNum;
dataPath = pwd;
    filesep = '\';   % for windows
    fString = ['%0' num2str(floor(log10(numNonEmpty))+1) '.f'];
    numStr = @(frame) num2str(frame,fString);
    
    outFiledMap=@(frame) [dataPath, filesep, 'dMaps',filesep, 'dMap' numStr(frame) '.mat'];
for i = 1:numNonEmpty
    name = outFiledMap(i);
    load(name)
    disp{i} = curr_dMap;    
end
