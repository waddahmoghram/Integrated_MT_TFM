function ForceComparisonMTvTFM()
    %% compare Magnetic bead DIC-evaluated force vs. epi-evaluated traction force
    % Written by Waddah Moghram, PhD Student in Biomedical Engineering at the University of Iowa, on 3/1/2019

    % Load the traction integral runs (tIntegral)
    %

    %% Correct for inclination angle
    z_SepDistanceMicron = 18; % microns. Z-level separation difference between the needle tip and the magnetic bead
    xy_SepDistanceMicron = 15; % microns. 2D separation idstance between the needle tip projection on the gel and the magnetic bead
    inclinationAngle = atand(z_SepDistanceMicron/xy_SepDistanceMicron);

    %% Frames converted to time
    FirstFrame = 1;
    NumFrames = numel(tIntegral);
    FrameRate = 0.025;   % seconds per frame
    TimeFrames = (FirstFrame:NumFrames) * FrameRate;

    %% Plotting

    figure()
    hold on
    params = 'r-';

    plot(TimeFrames, (tIntegral(FirstFrame:NumFrames)*1e9), params);   % Convert to nN. 70 ms OFF
    % Shift by the amount of noise down..
    AverageNoise = mean(tIntegral(1:80)*1e9));   % first two seconds

    % plot(TimeFrames, (tIntegral(FirstFrame:NumFrames)*1e9)/cosd(inclinationAngle)-AverageNoise,params);   % Convert to nN. 70 ms OFF
    xlabel('Time(s)')
    ylabel('T, Force (N)')
    set(gca,'color',[1 1 1])
    set(gca,'FontWeight','Bold');


    % Load force separation data. Saved into  "Force_Time_DIC.mat"
    
    %% Now creating the force shift that both TFM and MT waveforms match.
    hold on
    params = 'b-';
    TimeFrameShiftTFM = 0.278;                     %  225 ms shift for DIC in that particular video.

    plot(TimeFrames- TimeFrameShift, ForceTFM(FirstFrame:NumFrames,1),params);     % Already corrected for inclination angle (separation distance is in 3D).
    ylabel('T, Force (N)')
    set(gca,'color',[1 1 1])
    set(gca,'FontWeight','Bold','XLim',[0,35]);
end