%{
    v.2020-07-04 by Waddah Moghram, PhD Candidate in Biomedical Engineering at the University of Iowa
        1. Initial version is based on visual inspection of the segment where the displacement moves more than the 
    displacement average in the negative controlled-displacement
%}

function [FluxON, FluxOFF, FluxTransient, MaxDisplacementDetails] = FindFluxStatusControlledDisplacement(movieData, displField, TimeStamps, FramesDoneNumbers)
    
    [MaxDisplacementDetails, figHandleBeadMaxNetDispl] = ExtractBeadMaxDisplacementEPIBeads(movieData, displField, 0, TimeStamps);

    FirstFrame = FramesDoneNumbers(1); 
    LastFrame = FramesDoneNumbers(end);
    
    disp('NOTE: if first and last frames/timestamps are the same. Then there is no ON segment. All are OFF segments')
    FirstTimeInputSecDefault = TimeStamps(FirstFrame);
    FirstTimeInputSec = input(sprintf('What is the time for the start of the ON segment (in seconds) [Default = %0.3g sec]? ', FirstTimeInputSecDefault));
    if isempty(FirstTimeInputSec), FirstTimeInputSec = FirstTimeInputSecDefault; end

    LastTimeInputSecDefault = TimeStamps(LastFrame);           % t =0 seconds
    LastTimeInputSec = input(sprintf('What is the time for the end of the ON segment (in seconds) [Default = %0.3g sec]? ', LastTimeInputSecDefault));
    if isempty(LastTimeInputSec), LastTimeInputSec = LastTimeInputSecDefault; end

    FirstONframe = find((FirstTimeInputSec - TimeStamps) <= 0, 1);               % Find the index of the first frame to be found.
    fprintf('First ON frame to be plotted is: %d.\n', FirstONframe)  

    LastONframe = find((LastTimeInputSec - TimeStamps) <= 0,1);
    fprintf('Last ON frame to be plotted is: %d.\n', LastONframe)

    close(figHandleBeadMaxNetDispl)    
    
    LastFrameOverall = min([LastFrame, numel(TimeStamps)]);

    FluxON = false(size(1:LastFrameOverall));
%     FluxOFF = false(size(1:LastFrameOverall));
    FluxTransient = false(size(1:LastFrameOverall));

    if FirstONframe ~= LastONframe
        FluxON(FirstONframe:LastONframe) = true;
    end
    FluxOFF = ~FluxON;
    % use acceleration data to find moving segments vs. stationary segments
end