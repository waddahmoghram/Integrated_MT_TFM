%{
 Run it after ImageTracking v7_0 
Written by Waddah Moghram on 1/17/2019. See Brief Meeting note on Tuesday 1/17/2019
Updated on 2/6/2019
%% Needs to updated so that the two frames are aligned.
%}
    ExtractBeadCoordinates_v6_0
%     1400
%     1
    MagBead = ans;
    
    % or you can load bead_coordiantes.txt if this code has been run already.
    load('Bead_Coordinates.dat')
    MagBead = Bead_Coordinates;
    
    FrameNum = size(MagBead,1);
    
    FrameSeq = linspace(1,FrameNum,FrameNum);
    MagBeadMicron = MagBead * 0.215;            % Magnification for 30X (20X and 1.5X eye piece)
    MagBeadInitialPosition = MagBeadMicron(1,:);
    MagBeadDisplacement = vecnorm(MagBeadMicron - MagBeadInitialPosition,2,2);

    TimeFrame = FrameSeq * 0.025;               % 40 FPS video

    plot(TimeFrame,MagBeadDisplacement,'b.-')

    xlabel('Time (s)'), ylabel('Displacement,\Delta(t) (\mum)'), title('Bead displacements from starting position')

%=========================================================================================================

% Load the displacement File