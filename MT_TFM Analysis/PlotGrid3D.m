function figHandle = PlotGrid3D(XYGrid, zGrid)
    % written by Waddah Moghram on 2019-11-05
    % Plotting 3D figures
    figHandle = figure('color', 'w');
    surf(XYGrid(:,:,1), XYGrid(:,:,2), zGrid(:,:,3))
    shading interp
    colormap('jet')
    h = colorbar;
%     caxis([-0.1, 0.1])                                % standardize it for all plots
%     titleStr = sprintf('%s - Filtered %s - [%dx%d] Window', InterpolationMethod, filteringMethod, windowSize);
%     title(titleStr)
%     zlim([-1, 1])                                  % standardize it for all plots.
%     xlabel('Y (pixels)'), ylabel('X (pixels)'), zlabel('Traction Stress (Pa)')                 % note, it is reversed since surf() uses meshgrid() vs. griddata use ndgrid()
%     set(gca, 'FontWeight', 'bold')
%     
    hold on, plot3(XYGrid(:,:,1), XYGrid(:,:,2), zGrid(:,:,3), 'm.', 'MarkerSize', 2)
end
