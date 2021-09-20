function [ MagBeadCoordinatesXYpixels, BeadCoordinatesFullFileNameMAT, FirstFrame ,LastFrame, MToutputPathName] = ExtractBeadCoordinatesDIC(LastFrame,  BeadNodeID,  FirstFrame,  MToutputPathName)
%{ 
    v2019-09-02 
        save all workspace variables to the output file.
    v.2019-07-01
        Fixed error where no tmpNodes* are found, and allows the user to select another folder that has the tracked output.
    v.2019-06-26.
        Output of firstFrame and LastFrame.

 v7.30  2019-06-13 by Waddah Moghram
    ** need to update to allow an analysis output folder. 
    ** Update to generate the plot internally and to accept TimeStampsCumulativeAbsoluteSec in here.

 v7.20  2019-06-02 by Waddah Moghram
    Based on v7.10 and 7.00
     
v 7.00 Updates. 
Created by Waddah Moghram, PhD Candidate in Biomedical Engineering at the University of Iowa on 2018-01-22 and later.
        Updated on 2019-05-30 

        0. Changed the function name from "ExtractBeadCoordinates_v6_0()"  to "ExtractBeadCoordinatesDIC()"
        1. Added 'commandwindow'
        2. Updated LastFrame mismatch if it is provided on the outside.
        3. Added a try/catch if no more tmp files are available, and adjusts the final frame count
        4. Fixed extra 
   Older Verion        
   v.6.00 Updates to this editions include:
        1. Optional input arguments: FinalFrameNumber, BeadNodeID, FirstFrameNumber. 
            Include user-prompted input if needed with default values. 
            Use "exist" & "isempty" arguments. Another way is to use "parse" and "inputPraser" for functions
        2. Outputs Bead Node Coordinates and also into a file "Bead_Coordinates.dat"
        3. to flip or not to flip coordinates? Coordinates are not flipped, but remain as cartesian.****

        NOTE: Needle pole coordinates will be whole pixel units. Compare to Bead coordinates that come from image tracking, that has "subpixel displacements".

        Next versions will extract the first and last frames and the node I from NodeInfo.dat??
        I might want to add a code that plots that point and gives the user the option to review the choice of node 2017-10-06

        Input and Output are in pixel and in Cartesian Coordiantes
    v1.0
        Extract Bead Coordinates: will sift through tmpXXXX.dat files from rrImageTrackGUI.m, and outputs a matrix of x-Coordinates and y-Coordinates over frames, for the same given node.
            Created by Waddah Moghram, PhD Candindate in Biomedical Engineering at the Unviersity of Iowa, on 2017-10-03
              This function works by
            Selecting the first temporary nodes file "tmpNodesXXXX.dat" (XXXX = four digits) from rrImageTrackGUI.m
            Outputs are x- & y-coordinates in pixels going node by node, but we
            will only extract the node of interest.
            y-coordinates are in the negative        
%}
%%
    commandwindow;
    disp('-------------------------- Running ExtractBeadCoordinatesDIC.m: To compile bead coordinates: --------------------------')
    %% -------------------------------------------------
    if ~exist('MToutputPathName', 'var'), MToutputPathName = []; end
    if isempty(MToutputPathName) || nargin < 4
        if ispc     % opening file explorer externally to see those individual files
%                 winopen(pwd)
            elseif isunix
                disp('INCOMPLETE CODE in UNIX')
            elseif ismac
                disp('INCOMPLETE CODE in Mac')
            else
                disp('Platform not supported')
        end
        MToutputPathName = uigetdir(pwd, 'Select the folder containing the temporary nodes data files, tmpNodes****.dat'); 
        if isempty(MToutputPathName), return; end
    end 
    
        %% Other parameters to extract
    try
        trackingFileName = fullfile(MToutputPathName ,'tracking_output', 'tracking_parameters.txt');
        open(trackingFileName);
    catch
        % Do nothing
    end
        
    %% -------------------------------------------------
    % 1. Define the first and last frames to be tracked, and the Node ID for the bead.
            % Prompt for how many frames to be tracked -- if missing
    if ~exist('LastFrame','var'), LastFrame = []; end         % First parameter does not exist, so default it to something
    if nargin < 1 || isempty(LastFrame)    
        prompt = '* Enter the Final Frame number that was image-tracked properly [Default = Last Frame]: ';
        LastFrame = input(prompt);
        FinalTmpFrameNumber = LastFrame - 1;                         % Modified on 10/6/2017 by Waddah Moghram. tmpNodes****.dat are one point less than the images tracked.   
    end
%         if ~exist('FinalTmpFrameNumber', 'var'), FinalTmpFrameNumber = []; end
%         if isempty(FinalTmpFrameNumber) || FinalTmpFrameNumber ==0
            filesList = dir(fullfile(MToutputPathName, 'tmpNodes*'));
            filenames = {filesList.name};
            if isempty(filenames)
                disp('***No "tmpNodes** files were found. Select another folder.***')
                MToutputPathName = uigetdir('Select the folder containing "tmpNodes** files');
            end
            filesList = dir(fullfile(MToutputPathName, 'tmpNodes*'));
            filenames = {filesList.name};
            FinalTmpFrameNumber = sum(contains(filenames, 'tmpNodes'));
            LastFrame = FinalTmpFrameNumber + 1;                        % Guide node file on top of tmp nodes need to be accounted for.
%         end
%     
    %% -------------------------------------------------
    % 2. Prompt for the bead/node to be tracked (only one at a time this far, but you can call back the same function) -- if missing
    if ~exist('BeadNodeID','var'), BeadNodeID = []; end
    if isempty(BeadNodeID) || nargin < 2                   % Second parameter does not exist, so ask for a prompt or default it
        prompt = '* Enter the Bead Node ID whose coordinates you want to compile [Default = 1]: ';
        BeadNodeID = input(prompt);   
        if isempty(BeadNodeID) 
            BeadNodeID = 1;                                         % Default value of 1 if left empty
        end
    end
    
    %% -------------------------------------------------
    % 3. Prompt for the first frame number to be tracked -- if missing
    if ~exist('FirstFrame','var'), FirstFrame = []; end
    if isempty(FirstFrame) || nargin < 3           % Third parameter does not exist, so ask for prompt or default it
        prompt = '* Enter the First Frame number that was image-tracked [Default = 1]: ';
        FirstFrame = input(prompt);
        if isempty(FirstFrame)
            FirstFrame = 1;                                % Default value of 1 if left empty
        end 
    end    
    %-------------------------------------------------

    fprintf('First Frame to be tracked is #%d.\n', FirstFrame);    
    fprintf('Final Frame to be tracked is #%d.\n', LastFrame);
    fprintf('Bead #%d will be tracked.\n', BeadNodeID);    
    disp('----------------------------------------------------------------------------')
    
    %% 3. Initialize the matrix that will hold bead coordinates over time. This speeds up the process
    MagBeadCoordinatesXYpixels = zeros(LastFrame,2);             
    
    %% 4. Now the actual loop between frames to load individual bead coordinates from files
    disp('Loading bead coordinates IN PROGRESS')
    for ii = FirstFrame:(LastFrame - 1) 
        CurrentFrameFileName = filenames{ii};                            %       Updated on 2019-06-06 by Waddah Moghram
%         CurrentFrameFileName = sprintf('tmpNodes%04d.dat', ii);
        tmpNodeFullFileName = fullfile(MToutputPathName, CurrentFrameFileName) ; 
            %NOTE: "fullfile" is the better way to create the FileName because it will be compatible with the OS running MATLAB
        try 
            tmpNodesXY = load(tmpNodeFullFileName);                 %Loading the current node file
            MagBeadCoordinatesXYpixels(ii,:) = tmpNodesXY(BeadNodeID,:);            %Append to the matrix
             %NOTE: The y-coordinates are kept in the negative Cartesian Coordinates
        catch 
            LastFrame = ii;
            if isempty(LastFrame)
                fprintf('No tracking data was found in this directory: \n %s \n,', MToutputPathName);
                return;
            else
                break;
            end
        end
    end 
    %-------------------------------------------------
    fprintf('Final Frame tracked is #%d.\n', LastFrame);
    %Added on 2/4/2018 by WIM to remove all zeros if First Elements is not Frame Number 1, but rather Frame 2. The first element is called GUInodes.dat (or reference frame)
    MagBeadCoordinatesXYpixels(1:FirstFrame-1,:) = [];    
    
    %% 5. Lastly Including the coordinates of Frame 0, that is saved as 'GUInodes.dat'
    ZerothFrameFileName = 'GUInodes.dat';
    ZerothFrameFullFileName = fullfile(MToutputPathName, ZerothFrameFileName) ;
    ZerothFrameNodes = load(ZerothFrameFullFileName);
     
    %-------------------------------------------------
    %%%%%%% Append to the beginning of the matrix, and removing last Frame since it will be on extra point. WIM 2019-05-31.
    MagBeadCoordinatesXYpixels = [ZerothFrameNodes(BeadNodeID,:);MagBeadCoordinatesXYpixels(1:end-1,:)];         
    
    %-------------------------------------------------
    disp('Loading bead coordinates COMPLETE!')
    disp('----------------------------------------------------------------------------')
    
    %% 6. Writting the beads coordinates into "Beads_Coordinates.dat" file, into the same folder as the other nodes
    BeadCoordinatesFullFileNameDAT = fullfile(MToutputPathName, '02 Mag_Bead_Coordinates_Imprecise.dat');    
    BeadCoordinatesFullFileNameMAT = fullfile(MToutputPathName, '02 Mag_Bead_Coordinates_Imprecise.mat');    
     
%     save(BeadCoordinatesFullFileNameMAT, 'MagBeadCoordinatesXYpixels','BeadNodeID', 'FirstFrame', 'LastFrame')
    save(BeadCoordinatesFullFileNameMAT);                  % save all variables.
    dlmwrite(BeadCoordinatesFullFileNameDAT, MagBeadCoordinatesXYpixels, 'delimiter','\t', 'precision','%7.3f');

    BeadInfoFullFileName  = fullfile(MToutputPathName, '02 Mag_Bead_Coordinates_Imprecise_Info.txt');
    %-------------------------------------------------
    fileID = fopen(BeadInfoFullFileName, 'wt');       
    %-------------------------------------------------
    fprintf(fileID, 'Frames tracked were from #%u to #%u \n', FirstFrame, LastFrame);  % Added "+1" since it was subtracted before
    fprintf(fileID, '%s\t%s\t -coordinates are the 1st and 2nd columns, respectively (pixels)\n', 'x','y');  
    fprintf(fileID, 'The bead node ID was #%u', BeadNodeID); 
    fclose(fileID);
    %-------------------------------------------------
    fprintf('Bead Coordinates File is saved in: \n %s \n %s \n' , BeadCoordinatesFullFileNameDAT, BeadCoordinatesFullFileNameMAT);
    fprintf('Bead Coordinates Info File is saved in: \n %s \n' , BeadInfoFullFileName);    
    disp('-------------------------- Extracting Bead Coordinates COMPLETE --------------------------')
end
