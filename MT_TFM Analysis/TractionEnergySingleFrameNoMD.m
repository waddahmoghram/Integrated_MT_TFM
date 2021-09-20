%{
    v.2020-03-04 
        


   %}
    
function [Force, forceFieldposPixels, forceFieldvecPa, ScaleMicronPerPixel] = TractionEnergySingleFrameNoMD(forceFieldposPixels, forceFieldvecPa, ScaleMicronPerPixel, intMethod, tolerance, ShowOutput)
    %% --------  Check for extra nargin -------------------------------------------------------------------  
    if nargin > 6
        errordlg('Too many arguments in this function, or wrong argument structure!')
        return
    end
 %% Check if there is a GPU. take advantage of it if is there.
        %    nGPU = gpuDeviceCount;
        %     if nGPU > 0
        %         useGPU = true;
        %     else
        %         useGPU = false; 
        %     end    
        %     
    %% --------  nargin 1, Movie Data (MD) by TFM Package-------------------------------------------------------------------  
    if ~exist('forceFieldposPixels', 'var'), forceFieldposPixels = []; end
    if nargin < 1 || isempty(forceFieldposPixels)
        [movieFileName, movieFilePath] = uigetfile('*.mat', 'Open the TFM-Package Movie Data File');
        if movieFileName == 0, return; end
        MovieFileFullName = fullfile(movieFilePath, movieFileName);
        try 
            load(MovieFileFullName, 'MD')
            fprintf('Movie Data (MD) file is: \n\t %s\n', MovieFileFullName);
            disp('------------------------------------------------------------------------------')
        catch 
            errordlg('Could not open the movie data file!')
            return
        end
        try 
            isMD = (class(MD) ~= 'MovieData');
        catch 
            errordlg('Could not open the movie data file!')
            return
        end   
    end    
    %% --------  nargin 2, force field (forceField) -------------------------------------------------------------------    
    if ~exist('forceFieldvecPa','var')
        forceFieldvecPa = [];
        % no force field is given. find the force process tag or the correction process tag
        try 
            ProcessTag =  MD.findProcessTag('ForceFieldCalculationProcess').tag_;
        catch
            ProcessTag = '';
            disp('No Completed "Force" Field Calculated!');
            disp('------------------------------------------------------------------------------')
        end
        %------------------
        if exist('ProcessTag', 'var') 
            fprintf('"Force" Process Tag is: %s\n', ProcessTag);
            try
                ForceFileFullName = forceFieldposPixels.findProcessTag(ProcessTag).outFilePaths_{1};
                if exist(ForceFileFullName, 'file')
                    dlgQuestion = sprintf('Do you want to open the "force" field referred to in the movie data file?\n\n%s\n', ...
                        ForceFileFullName);
                    dlgTitle = 'Open "force" field (forceField.mat) file?';
                    OpenForceChoice = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No', 'Yes');
                    switch OpenForceChoice
                        case 'Yes'
                            [forceFilePath, ~, ~] = fileparts(ForceFileFullName);
                        case 'No'
                            ForceFileFullName = [];
                        otherwise
                            return
                    end            
                else
                    ForceFileFullName = [];
                end
            catch
                ForceFileFullName = [];
            end
        end
        %------------------
        if isempty(ForceFileFullName) || ~exist('ProcessTag', 'var')
                TFMPackageFiles = fullfile(movieFilePath,'TFMPackage','*.mat');
                [forceFileName, forceFilePath] = uigetfile(TFMPackageFiles, 'Open the "force" field (forceField.mat) under forceField or backups');
                if forceFileName ==  0, return; end
                ForceFileFullName = fullfile(forceFilePath, forceFileName);
        end    
        %------------------       
        try
            load(ForceFileFullName, 'forceField');   
            fprintf('"Force" Field (forceField.mat) File is successfully loaded! \n\t %s\n', ForceFileFullName);
            disp('------------------------------------------------------------------------------')
        catch
            errordlg('Could not open the "force" field file.');
            return
        end
        FirstFrame = 1;
        prompt = {sprintf('Choose the current frame whose traction stresses are to be integrated. [Default = %d]', 1)};
        dlgTitle = 'Current Frame To Be Integrated';
        CurrentFrameStr = inputdlg(prompt, dlgTitle, [1, 75], {num2str(FirstFrame)});
        CurrentFrame = str2double(CurrentFrameStr{1});
        forceFieldposPixels = forceField(CurrentFrame).pos;
        forceFieldvecPa = forceField(CurrentFrame).vec;
    end
    %% --------  nargin 6, Output Prompts (true or false) Default = true -------------------------------------------------------------------          
    if ~exist('ShowOutput', 'var'), ShowOutput = []; end
    if  nargin < 5 ||  isempty(ShowOutput)
        ShowOutput = true;
    end
    
    %% --------  nargin 3, Current Frame to be integrated (CurrentFrame) -------------------------------------------------------------------        
    if ~exist('ScaleMicronPerPixel','var'), ScaleMicronPerPixel = []; end
    if nargin < 3 || isempty(ScaleMicronPerPixel)
        ScaleMicronPerPixel = MagnificationScalesMicronPerPixel([], ShowOutput);
    end
    if ShowOutput
        fprintf('Scale (Micron/Pixel) = %d\n', ScaleMicronPerPixel);
        disp('------------------------------------------------------------------------------') 
    end

    %% --------  nargin 4, integration method (iterated vs. tiled vs. summed) (intMethod) -------------------------------------------------------------------     
    if ~exist('intMethod', 'var'), intMethod = []; end
    if  nargin < 4 ||  isempty(intMethod)
        intMethod = 'summed';
    end
    
    %% --------  nargin 5, tolerance for integration methods(tolerance) -------------------------------------------------------------------          
    if ~exist('tolerance', 'var'), tolerance = []; end
    if  nargin < 5 ||  isempty(tolerance)
        if strcmpi(intMethod, 'iterated') || strcmpi(intMethod, 'tiled')
            tolerance = 1e-13';
        end
    end
    
%% =========================================================
    forceFieldPositionMicron = forceFieldposPixels.*(ScaleMicronPerPixel) * 1e-6;
%     forceFieldPositionMicron  = forceFieldposPixels % check if the conversion has anything to do with it
    if numel(size(forceFieldPositionMicron)) == 3
        forceFieldPositionMicron2 = forceFieldPositionMicron;
        forceFieldPositionMicron = reshape(forceFieldPositionMicron2, [], size(forceFieldPositionMicron,3));
    end
%%=========================================================
    % Distances 
    Xmin = min(forceFieldPositionMicron(:,1));
    Ymin = min(forceFieldPositionMicron(:,2));
    Xmax = max(forceFieldPositionMicron(:,1));
    Ymax = max(forceFieldPositionMicron(:,2));

    X = forceFieldPositionMicron(:,1);
    Y = forceFieldPositionMicron(:,2);
%     clear forceFieldPositionMicron

    if numel(size(forceFieldvecPa)) == 3
        forceFieldvecPa2 = forceFieldvecPa;
        forceFieldvecPa = reshape(forceFieldvecPa2, [], size(forceFieldvecPa,3));
    end

    Vx = forceFieldvecPa(:,1);
    Vy = forceFieldvecPa(:,2);    
%     clear forceFieldvecPa
    
% %%=========================================================    
    Xpoints = unique(X);
    Ypoints = unique(Y);

    % Now creating a mesh grid
    [Xgrid, Ygrid] = ndgrid(Xpoints, Ypoints);
    meshGridSize = size(Xgrid);
    % for whatever reason, Xgrid is transposed in the '.pos' field
    % an easier approach is to transposed the reshaped matrix
% %%=========================================================
   start = tic;    
    if strcmpi(intMethod, 'summed')
        TFMfunctionX = sum(sum(Vx), 'native');
        TFMfunctionY = sum(sum(Vy), 'native');
%         TFMfunctionNet = sum(sum(vecnorm([Vx,Vy], 2, 2)));
        
        % Average Area: 
        totalArea = (Ymax-Ymin)*(Xmax-Xmin);
        totalPointsCount = meshGridSize(1) * meshGridSize(2);
        AvgArea = (totalArea)/(totalPointsCount);
        Force(1,1) = TFMfunctionX * AvgArea;
        
        if isnan(Force(1,1) ), Force(1,1)  = 0; end
        if ShowOutput
            fprintf('\tF_x   = %g N. ', Force(1,1));        
            fprintf('\t\tF_x downtime = %g seconds. \n', toc(start));
        end
        Force(1,2)  = TFMfunctionY * AvgArea;           
        if ShowOutput
            fprintf('\tF_y   = %g N. ', Force(1,2));         
            fprintf('\t\tF_y downtime = %g seconds. \t\t (Note: positive y = negative y in Cartesian).  \n', toc(start));  
        end        
    else                    % integrated methods: tiled or iterated
        VxGrid = reshape(Vx, meshGridSize);                 % x-values are the rows. x-values are the columns
        VyGrid = reshape(Vy, meshGridSize);                 % y-values are the rows. x-values are the columns
       %%=========================================================
        % now creating the griddedinterpolant object. Need to invert for griddedinterpolant format.
        % Cubic interpolation. No extrapolation, returned as NaN
        Fx = griddedInterpolant(Xgrid, Ygrid, VxGrid, 'cubic', 'none');
        Fy = griddedInterpolant(Xgrid, Ygrid, VyGrid, 'cubic', 'none');
        % Function below verified agaisnt the real data points as well as interpolations. 
        % extrapolations returns as NaN
        TFMfunctionX = @(x,y)Fx(x,y);
        TFMfunctionY = @(x,y)Fy(x,y);
        %--------------------------- OR ----------------------------------              
%         TFMfunctionX = @(x,y)griddata(Xgrid, Ygrid, VxGrid, x, y, 'cubic');         
%         TFMfunctionY = @(x,y)griddata(Xgrid, Ygrid, VyGrid, x, y, 'cubic');         
%        %%=========================================================

        % Now use the double integral. Revesed the limited tot he normal order Xmin, Xmas, Ymin, Ymax
        Force(1,1) = integral2(TFMfunctionX, Xmin, Xmax, Ymin, Ymax, 'Method',intMethod, 'AbsTol',tolerance);
        if isnan(Force(1,1)), Force(1,1) = 0; end
        if ShowOutput
            fprintf('\tF_x   = %g N. ', Force(1,1));        
            fprintf('\t\tF_x downtime = %g seconds. \n', toc(start));
        end
        
        Force(1,2) = integral2(TFMfunctionY, Xmin, Xmax, Ymin, Ymax, 'Method',intMethod, 'AbsTol',tolerance);      
        if isnan(Force(1,2)), Force(1,2) = 0; end
        if ShowOutput
            fprintf('\tF_y   = %g N. ', Force(1,2));         
            fprintf('\t\tF_y downtime = %g seconds. \t\t (Note: positive y = negative y in Cartesian). \n', toc(start));
        end
    end
    
    Force(1,3) = vecnorm(Force(:,1:2), 2, 2);
    if ShowOutput
        fprintf('\tF_net = %g N. \n', Force(1,3));   
    end
end

%% ========================= CODE DUMPSTER +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

%{

     forceFieldvecPa = [forceField(CurrentFrame).vec];       % Updated on 2/8/2019 to remove division by 1000. Not need to scale here. Input is in Pa.!
% ------------------------- using griddata will take more than 12 days to evaluate even without gpu acceleration     
% %     % Interpolating using cubic method
% %     %  T_x 
%     TFMfunctionX = @(x,y)griddata(forceFieldPositionMicron(:,1),forceFieldPositionMicron(:,2),forceFieldvecPa(:,1),x,y,'cubic'); 
%     %  T_y
%     TFMfunctionY = @(x,y)griddata(forceFieldPositionMicron(:,1),forceFieldPositionMicron(:,2),forceFieldvecPa(:,2),x,y,'cubic'); 
% 
 %     
% % ------------- the part below needs to have unique points. Also, some weird aspect about flipping the indices which is inexplicable
% 
%     TFMfunctionX = @(x,y)interp2(forceFieldPositionMicron(:,1),forceFieldPositionMicron(:,2), forceFieldvecPa(:,1), y, x,'cubic',0); 
%         %  T_y....negative since the y-axis not in cartesians
%     TFMfunctionY = @(x,y)interp2(forceFieldPositionMicron(:,1),forceFieldPositionMicron(:,2), -forceFieldvecPa(:,2), y, x,'cubic',0);
%          
 Force_x = integral2(TFMfunctionX, Ymin, Ymax, Xmin, Xmax, 'Method',intMethod,'AbsTol',tolerance);

    Force_y = integral2(TFMfunctionY, Xmin, Xmax, Ymin, Ymax, 'Method',intMethod, 'AbsTol',tolerance);


%         % F_x
%         Force_x = integral2(TFMfunctionX,Xmin,Xmax, Ymin, Ymax,'Method','iterated','AbsTol',1e-2,'RelTol',1e-1);
%         % F_y 
%         Force_y = integral2(TFMfunctionY,Xmin,Xmax, Ymin, Ymax,'Method','iterated','AbsTol',1e-2,'RelTol',1e-1);
%         % F_y 
%     

%}