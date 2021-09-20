%% Written by Waddah Moghram, PhD Student in Biomedical Engineering on 10/7/2016
% Modified from similar codes online.
% Used to compiled the figures saved into one plots for the calibration
% curves
% Open the figures in the order they are to be added.
% Close all figures first.

% 1. Looping through all figures to get their handles
% a= randn(1,100) ; b = randn(1,150) ;
% h(1) = figure(i); plot(a); h(2) = figure; plot(b);
n = input('Number of figures: ')';
for i = 1:n
    h(i) = figure(i);
end

handleLine = findobj(h,'type','line');

% 2. Looping through all figure handles and adding them to the new plot
figure()            %Create a new plot to transfer the old plots
hold on ;
for i = 1 : length(handleLine)
    plot(get(handleLine(i),'XData'), get(handleLine(i),'YData'),'.','MarkerSize',5) ;    %Dots
end

xlabel('Separation Distance (micron)'); ylabel('Force (nN)'); title('Calibration Curves for Magnetic Tweezer at different fluxes');

%legend('25 Gs','50 Gs', '75 Gs', '100 Gs', '125 Gs', '150 Gs', '175 Gs')
%legend('Run1' , 'Run2')
    