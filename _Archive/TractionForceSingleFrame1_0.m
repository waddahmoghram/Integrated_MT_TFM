function [Fx,Fy] = TractionForceSingleFrame1_0(forceField,MD,CurrentFrame)
    %TractionForce v1.0 will integrate the traction over the entire area. 
    % Written by Waddah Moghram on 1/23/2019. PhD Student in Biomedical Engineering at the University of Iowa
    %{
    This function will interpolate the traction force using the function griddate.
    The next step is pass that function to integral2 (for a double integral)
    Inputs:
        forceField, generated after calculating traction forces using TFM Package
        MD is generated the moment a movie is created. It should have the right pixel conversion. Otherwise, enter it here.
    Outputs:
        Fx = Force_X is the x-component of the evaluated traction force
        Fy = Force_Y is the y-component of the evaluated traction force
   %}

%     %  (convert movie size to pixels. PixelSize is in pixel/nm). Calculate in meters
    forceFieldPosition = [forceField(CurrentFrame).pos].*(MD.pixelSize_)/1e9;
    
    % Distances 
    Xmin = min(forceFieldPosition(:,1));
    Ymin = min(forceFieldPosition(:,2));
    Xmax = max(forceFieldPosition(:,1));
    Ymax = max(forceFieldPosition(:,2));
    
    forceFieldvecPa = [forceField(CurrentFrame).vec];       % Updated on 2/8/2019 to remove division by 1000. Not need to scale here. Input is in Pa.!
    
    % Interpolating using cubic method
    %  T_x 
    TFMfunctionX = @(x,y)griddata(forceFieldPosition(:,1),forceFieldPosition(:,2),forceFieldvecPa(:,1),x,y,'cubic'); 
    %  T_y
    TFMfunctionY = @(x,y)griddata(forceFieldPosition(:,1),forceFieldPosition(:,2),forceFieldvecPa(:,2),x,y,'cubic'); 

%     % F_x
%     Fx = integral2(TFMfunctionX,Xmin,Xmax, Ymin, Ymax,'Method','iterated','AbsTol',1e-2,'RelTol',1e-1);
%     % F_y 
%     Fy = integral2(TFMfunctionY,Xmin,Xmax, Ymin, Ymax,'Method','iterated','AbsTol',1e-2,'RelTol',1e-1);
%     % F_y 
    
    % 1% relative tolerance for double integrals
    start = tic;
    % F_x
    Fx = integral2(TFMfunctionX,Xmin,Xmax, Ymin, Ymax,'Method','tiled','RelTol',1e-2);
    finish1 = [num2str(toc(start)), ' seconds'];
    disp(finish1)
    % F_y 
    Fy = integral2(TFMfunctionY,Xmin,Xmax, Ymin, Ymax,'Method','tiled','RelTol',1e-2);
    finish2 = [num2str(toc(start)), ' seconds'];
    disp(finish2)
    % F_y     
end