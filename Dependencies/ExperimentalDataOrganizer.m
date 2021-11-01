%{
    Distribute experimental files towards their _Data folders for each given bead
    Written by Waddah Moghram: PhD Candidate in Biomedical Engineering at the University of Iowa
    Code written on 2021-10-28
%}

    DataPath = uigetdir(pwd, 'Select the folder where experimental data are saved');
    DataFiles = dir(fullfile(DataPath, 'S*B*'));        % Sample Gels "SYYYYMMDD.#_***mgmL_37CorRTP" and the Bead ID "B#" r
    FileCount = numel(DataFiles);

    patBeadNumber = "B" + digitsPattern(1);
    patRunNumber = "R" + digitsPattern(1);

    patEDCorNOT_ = ("-"|"_") + ("EDC"|"EDAC"|"NoEDC"|"NoEDAC");
    patEDCorNOT = ("EDC"|"EDAC"|"NoEDC"|"NoEDAC");
    

    for CurrentFile = 1:FileCount
        DataFiles(CurrentFile).BeadID = cell2mat(extract(DataFiles(CurrentFile).name , patBeadNumber));
        DataFiles(CurrentFile).EDCorNOT = cell2mat(extract(DataFiles(CurrentFile).name , patEDCorNOT));      
        DataFiles(CurrentFile).SampleID = cell2mat(extract(DataFiles(CurrentFile).name , patEDCorNOT));      
        DataFiles(CurrentFile).GelNameParts = strsplit(DataPath, filesep);
        DataFiles(CurrentFile).GelSampleID = DataFiles(CurrentFile).GelNameParts{end};
    end
    DataFilesTbl = struct2table(DataFiles);

    DataFilesCell = struct2cell(DataFiles);
    DataFilesMAT = cell2mat(DataFilesCell);