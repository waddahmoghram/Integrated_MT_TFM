% Written by Waddah Moghram on 2021-12-23 to sort files generated for Aim3  experiments
% It will moves files to "$BeadNumber/_Data" for the raw experimental data. Results will be in other folders.
RootPath = uigetdir();

clear DataFiles 
DataFiles = dir(RootPath);

FileFullName = cell(length(DataFiles), 1)
BeadNumber = cell(length(DataFiles), 1)
OutputPath = cell(length(DataFiles),1)
for k = 1:length(DataFiles)
    FileFullName{k} = fullfile(DataFiles(k).folder, DataFiles(k).name);
    
    patBeadNumber = "B" + digitsPattern(1) + "." + digitsPattern + "um" ;
    BeadNumber{k} = extract(DataFiles(k).name , patBeadNumber);
    try
        OutputPath{k,1} = fullfile(DataFiles(k).folder,BeadNumber{k}, "_Data")
        mkdir(OutputPath{k,1})
        movefile (FileFullName{k}, fullfile(OutputPath{k}, DataFiles(k).name))
    catch
        continue
    end
end