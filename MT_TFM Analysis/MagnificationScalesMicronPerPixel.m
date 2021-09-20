function [ScaleMicronPerPixel, MagnificationTimesStr, MagnificationTimes, NumAperture] = MagnificationScalesMicronPerPixel(MagnificationTimes, ShowOutput)
%MagnificationScalesMicronPerPixel Returns the scale of a given magnification in microns/pixel. 
%{
    v.2019-10-06 by Waddah Moghram
        1. Fixed error where MagnificationTimes is given as [], and not output right
    v.2019-09-22 by Waddah Moghram
        1. Changed the command window prompt with a list dialog box
        2. If no magnification is selected, then just exit, and do not continue
    v2019-09-10 by WIM
        1. Added MagnificationTimes as an output
    v2.00 on 2019-05-30
        Updated the file so that Magification can be looked up directly from a MagnificationScalesMicronPerPixelValues.mat that has the structure. Gives flexilibty to change one master switch
    v1.00 on 2019-05-28
        Created by Waddah Moghram from previous code embedded in multiple files.
    % Find out the magnification scale to convert pixels to microns for forces.
    %************* Possible to fish the scale from the data header (7,3) ********** if is entered correctly before.*******************%%

     MagnificationScalesMicronPerPixelValues = struct('X4',1.819, 'X10',0.732, 'X20',0.367, 'X30',0.2150321, 'X40',0.1645066, 'X60',0.122);       % As of 2019-05-30 in microns per pixel.
     MagnificationChoices{MagnificationIndex} vs. 
    
    on 2019-05-27
        FIXed SCALE to merge X10DIC & X10Ph. Maybe even use the header data since the scale is embedded there too, or the metadata for ND2. 
%}

    if ~exist('ShowOutput', 'var'), ShowOutput = []; end
    if  nargin < 2 ||  isempty(ShowOutput)
        ShowOutput = true;
    end

 %%   %---------------------------------
%     disp('-------------------------- Running MagnificationScalesMicronPerPixel.m: To return magnification scale in microns/pixel : --------------------------')
%     disp('Loading the mangification Scale from "MagnificationScalesMicronPerPixelValues.mat". Note: You can change the values in that file.')
%     try
    load('MagnificationScalesMicronPerPixelValues.mat', 'MagnificationScalesMicronPerPixelValues','NumApertures'); 
%     catch
%         [Magnificationdir,MagnificationFile] = uigetfile('Please choose "MagnificationScalesMicronPerPixelValues.mat"');
%         load(fullfile(Magnificationdir,MagnificationFile), 'MagnificationScalesMicronPerPixelValues')
%     end
    
    MagnificationChoices =  fieldnames(MagnificationScalesMicronPerPixelValues);
    %   NOTE 1: Units are in Micron/Pixel of Magnification scale below.
    %   NOTE 2: 30X is basically 1.5x eyepiece lens * 20X objective lens
    if ~exist('MagnificationTimes', 'var'), MagnificationTimes = []; end
    if nargin < 1 || isempty(MagnificationTimes)
       prompt = 'Select the magnification factor of the following choices: ';
       MagnificationTimesIdx = listdlg('ListString', MagnificationChoices, 'SelectionMode', 'single', 'PromptString', prompt, 'InitialValue', 4);   % Default is 30X
       if isempty(MagnificationTimesIdx), return; end
       MagnificationTimesStr = MagnificationChoices{MagnificationTimesIdx};
       MagnificationTimes = regexp(MagnificationTimesStr, '[0-9]', 'match');
       MagnificationTimes = str2double(strcat(MagnificationTimes{:}));
    else
        MagnificationTimesStr = (strcat('X', num2str(MagnificationTimes)));
    end
    if isempty(MagnificationTimesStr)
        return;            
    end    
%     disp('----------------------------------------------------------------------------')   
   
    ScaleMicronPerPixel = MagnificationScalesMicronPerPixelValues.(MagnificationTimesStr);         % Make sure it is ZoomChoice{} and not (). Uses Dynamic referencing of a structure ".()"
    NumAperture = NumApertures.(MagnificationTimesStr); 
    if ShowOutput
        fprintf('%s is chosen. Scale = %g microns/pixel. NA = %0.2f \n', MagnificationTimesStr, ScaleMicronPerPixel, NumAperture);
    %      disp('-------------------------- Extracting Magnification Scale COMPLETE --------------------------')   
    end
end

%% =================================== CODE DUMPSTER =========================================
%         MagnificationListStr = sprintf('%s, ', MagnificationChoices{:});
%         prompt = sprintf('Enter the times magnification (just number) out of the following choices: %s\b\b. [Default = X30]: ', MagnificationListStr);
%         MagnificationTimes = input(prompt);