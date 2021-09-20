%{
Written by Waddah Moghram on 2020-08-15..22
    this script is to generate a histogram and fitted Rayleigh distribution of displacements of 
    TrackedEpiBeadsDynamics.m
    displMicronVecNorm is loaded from Bead Dynamics Results.mat
%}
%% Frame 600 of negative EPI for controlled-displacement experiment.
HistoFrame = input(sprintf('What is the frame number to be analyzed [max = %d]\n', size(displMicronVecNorm, 1)));
data = displMicronVecNorm(HistoFrame, :);
[data2, idx] = sort(rmmissing(data));           % Sort data and remove nan


Bparam_HistoFrame = displMicronBparamMuHatAllNorm(600);
BparamCI_HistoFrame = displMicronBparamCIAllNorm(600, :);      % 95% CI for B-param
BparamMean = mean(displMicronBparamMuHatAllNorm);
BparamStdDev = std(displMicronBparamMuHatAllNorm);

TotalFrames = size(displMicronVecNorm, 1);
TotalBeadsTracked = size(data2);

RaylCurve_HistoFrame = raylpdf(data, Bparam_HistoFrame);
RaylCurve_HistoFrame2 = rmmissing(RaylCurve_HistoFrame);
RaylCurve_HistoFrame2 = RaylCurve_HistoFrame2(idx);

RaylCurveMean = raylpdf(data, BparamMean);
RaylCurveMean2 = rmmissing(RaylCurveMean);
RaylCurveMean2 = RaylCurveMean2(idx);

figHistoHandle =  figure('visible',showPlot, 'color', 'w');     % added by WIM on 2019-02-07. To show, remove 'visible   
figHistoHandle.Position = [100, 100, 560, 420];
histHandle = histogram(data, 300, 'LineStyle','none', 'FaceColor', 'b');
axesHistoHandle = findobj(figHistoHandle,'type', 'axes');
set(axesHistoHandle, ...
        'FontSize',11, ...
        'FontName', 'Helvetica', ...
        'LineWidth',1, ...
        'XMinorTick', 'on', ...
        'YMinorTick', 'on', ...
        'TickDir', 'out', ...
        'TitleFontSizeMultiplier', 0.9, ...
        'TitleFontWeight', 'bold');     % Make axes bold  
axesHistoHandle.XLim(1) = 0;
axesHistoHandle.TickLength = [0.015,0.30];
xlabel(strcat('Net Displacement (|\bfu\rm|) [', um, ']'))
ylabel('Microsphere Count')

title(sprintf('Histogram for microsphere net displacements. Frame %d/%d', HistoFrame, TotalFrames))

% Rayleigh distribution fit

yyaxis right
hold on
plot(data2,RaylCurve_HistoFrame2, 'r-')
txt1 = strcat('Rayleigh PDF $(B_{', num2str(HistoFrame), '}=\sigma_{', num2str(HistoFrame),'}=', num2str(Bparam_HistoFrame), ')$');
plot(data2,RaylCurveMean2, 'm-')
ylabel('Rayleigh PDF Count')
txt2 = strcat('Rayleigh PDF $(\bar{B}=\bar{\sigma}=', num2str(BparamMean), ')$');
h = legend('Data', txt1, txt2);
h.Interpreter = 'latex';


