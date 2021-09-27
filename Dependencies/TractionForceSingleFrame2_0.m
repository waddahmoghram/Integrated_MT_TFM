function [Fx,Fy] = TractionForceSingleFrame1_5(forceFieldPosArrayX,forceFieldPosArrayY, ForceFieldVecGridX, ForceFieldVecGridY, MD, CurrentFrame)
    %TractionForce v2.0 will also integrate the traction over the entire area.
    % Written by Waddah Moghram on 2/16/2019. PhD Student in Biomedical Engineering at the University of Iowa
    %{
    This function will interpolate the traction force using the function griddate.
    Unlike v1.0, which uses forceField that has both '.pos' and '.vec' fields, 
    
    v2.0 will use 'tractionMap****.mat' which was generated from the forceField using 'interp_vec2grid()' function
    The added benefit to using this is that the edges are already padded with 0's, which was probably erraneous around the edges before.
    
    I will using movie data to figure out the limits of the integration
    
    The next step is pass that function to integral2 (for a double integral)
    Inputs:
        forceField, generated after calculating traction forces using TFM Package
        MD is generated the moment a movie is created. It should have the right pixel conversion. Otherwise, enter it here.
    Outputs:
        Fx = Force_X is the x-component of the evaluated traction force in Pa
        Fy = Force_Y is the y-component of the evaluated traction force in Pa
   %}

    %  (convert movie size to pixels. PixelSize is in pixel/nm). Calculate in meters
    FrameSizePix = MD.imSize_;                           % x- and y-dimensions size in pixels
    
    forceFieldPosArrayXmeters = [forceFieldPosArrayX].*(MD.pixelSize_)/1e9;
    forceFieldPosArrayYmeters = [forceFieldPosArrayY].*(MD.pixelSize_)/1e9;
    
    
    % Distances 
    Xmin = min(forceFieldPosArrayXmeters);                  % Do not use 0, because it causes a singularity in integral2(). WIM 2/16/2019
    Ymin = min(forceFieldPosArrayYmeters);                  % Do not use 0, because it causes a singularity in integral2(). WIM 2/16/2019
    Xmax = max(forceFieldPosArrayXmeters);
    Ymax = max(forceFieldPosArrayYmeters);
    
    % Interpolating using cubic method. 
    %  T_x 
    TFMfunctionX = @(x,y)interp2(forceFieldPosArrayXmeters, forceFieldPosArrayYmeters, ForceFieldVecGridX, x, y, 'cubic'); 
    %  T_y
    TFMfunctionY = @(x,y)interp2(forceFieldPosArrayXmeters, forceFieldPosArrayYmeters, ForceFieldVecGridY, x, y, 'cubic'); 

    % 1% relative tolerance for double integrals
    start = tic;
    
    % F_x
    Fx = integral2(TFMfunctionX, Xmin, Xmax, Ymin, Ymax, 'Method','auto', 'RelTol',1e-2);
    finish1 = [num2str(toc(start)), ' seconds'];
    disp(finish1)
    
    % F_y 
    Fy = integral2(TFMfunctionY, Xmin, Xmax, Ymin, Ymax, 'Method','auto', 'RelTol',1e-2);
    finish2 = [num2str(toc(start)), ' seconds'];
    disp(finish2)

end