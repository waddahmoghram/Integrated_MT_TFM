%{
    v.2020-06-29 by Waddah Moghram, PhD Student in Biomedical Engineering at the University of Iowa
        NoiseROIsCombined is the noise ROI displacements (or driftROIcombined). 
        1. Put the regularization parameter based on Optimized Bayesian L2-norm ('Optimized Bayesian L2 (BL2)')
            See the following paper and related source code: 
                ** Huang, Y. et al. Traction force microscopy with optimized regularization and automated Bayesian parameter selection 
                        for comparing cells. Sci. Rep. 9, 539 (2019).
%}

function [reg_corner] = optimal_lambda_complete(displField, NoiseROIsCombined, YoungModulusPa, PoissonRatio, ...
    gridMagnification, EdgeErode, i_max, j_max, disp_grid, GridtypeChoiceStr, InterpolationMethod, ShowOutput, ...
    ScaleMicronPerPixel, FirstFrame, LastFrame, CornerPercentage)

   %% Open the displacement field first    
    if ~exist('displField','var'), displField = []; end
    if isempty(displField) || nargin < 1
        [displacementFileName, displacementFilePath] = uigetfile(fullfile(pwd, '*.mat'), 'Open the displacement field "displField.mat" under displacementField or backups');
        if displacementFileName == 0, return; end
        DisplacementFileFullName = fullfile(displacementFilePath, displacementFileName);
        
        try
            load(DisplacementFileFullName, 'displField', 'MD');   
            fprintf('Displacement Field (displField) File is successfully loaded!: \n\t %s\n', DisplacementFileFullName);
            disp('------------------------------------------------------------------------------')
                
            movieData = MD;
        catch
            errordlg('Could not open the displacement field file.');
            return
        end
    end
    
    %% ------------------
    if ~exist('ScaleMicronPerPixel', 'var'), ScaleMicronPerPixel = []; end
    if isempty(ScaleMicronPerPixel) || nargin < 13
        % 5. choose the scale (microns/pixels) & image Bits        
        try
            ScaleMicronPerPixel = movieData.pixelSize_/1000;           % from Nanometers/pixel to micron/pixel
        catch
            % continue
        end            
        if exist('ScaleMicronPerPixel', 'var')
            dlgQuestion = sprintf('Do you want the scaling found in the movie file (%0.5g micron/pixels)?', ScaleMicronPerPixel);
            dlgTitle = 'Use Embedded Scale?';
            ScalingChoice = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No', 'Yes');
        else
            ScalingChoice = 'No';
        end            
        switch ScalingChoice
            case 'No'
                [ScaleMicronPerPixel, ~, ~] = MagnificationScalesMicronPerPixel();    
            case 'Yes'
                % Continue
            otherwise 
                return
        end
            % 5. choose the scale (microns/pixels) & image Bits         
        try
            ScaleMicronPerPixel = movieData.pixelSize_/1000;           % from Nanometers/pixel to micron/pixel
        catch
            % continue
        end            
        if exist('ScaleMicronPerPixel', 'var')
            dlgQuestion = sprintf('Do you want the scaling found in the movie file (%0.5g micron/pixels)?', ScaleMicronPerPixel);
            dlgTitle = 'Use Embedded Scale?';
            ScalingChoice = questdlg(dlgQuestion, dlgTitle, 'Yes', 'No', 'Yes');
        else
            ScalingChoice = 'No';
        end            
        switch ScalingChoice
            case 'No'
                [ScaleMicronPerPixel, ~, ~] = MagnificationScalesMicronPerPixel();    
            case 'Yes'
                % Continue
            otherwise 
                return
        end
        
        fprintf('Magnification scale is %.5f microns/pixel\n', ScaleMicronPerPixel)    
    end  
  
    %% 5 ==================== find first & last frame numbers to be plotted ==================== 
    FramesDoneBoolean = arrayfun(@(x) ~isempty(x.vec), displField);
    FramesDoneNumbers = find(FramesDoneBoolean == 1);       
    VeryFirstFrame = find(FramesDoneBoolean, 1, 'first');   
    VeryLastFrame =  find(FramesDoneBoolean, 1, 'last');
    
    if ~exist('FirstFrame', 'var'), FirstFrame = []; end
    if isempty(FirstFrame) || nargin < 14
        commandwindow;
        prompt = {sprintf('Choose the first frame to plotted. [Default, Frame # = %d]', VeryFirstFrame)};
        dlgTitle = 'First Frame';
        FirstFrameStr = inputdlg(prompt, dlgTitle, [1, 100], {num2str(VeryFirstFrame)});
        if isempty(FirstFrameStr), return; end
        FirstFrame = str2double(FirstFrameStr{1});
    end
    [~, FirstFrameIndex] = min(abs(FramesDoneNumbers - FirstFrame));
    FirstFrame = FramesDoneNumbers(FirstFrameIndex);

    if ~exist('LastFrame', 'var'), LastFrame = []; end
    if isempty(LastFrame) || nargin < 15
        prompt = {sprintf('Choose the last frame to plotted. [Default, Frame # = %d]. \nNote: Might be truncated if sensor signal is less than the number of frames', VeryLastFrame)};
        dlgTitle = 'Last Frame';
        LastFrameStr = inputdlg(prompt, dlgTitle, [1, 100], {num2str(VeryLastFrame)});
        if isempty(LastFrameStr), return; end
        LastFrame = str2double(LastFrameStr{1}); 
    end
    LastFrame = min(LastFrame, VeryLastFrame);
    [~, LastFrameIndex] = min(abs(FramesDoneNumbers - LastFrame));
    LastFrame = FramesDoneNumbers(LastFrameIndex);
    
    FramesDoneBoolean = FramesDoneBoolean(FirstFrameIndex:LastFrameIndex);
    FramesDoneNumbers = FramesDoneNumbers(FirstFrameIndex:LastFrameIndex);
   
    
        
    if ~exist('NoiseROIsCombined', 'var'), NoiseROIsCombined = []; end
    if isempty(NoiseROIsCombined) || nargin < 2
        displField = displField(FramesDoneNumbers);
    
        try
            if ~exist('CornerPercentage','var'), CornerPercentage = []; end
            if isempty(CornerPercentage) || nargin < 16
                
            end
                
            [~, ~, ~, ~, ~, ~, ~, NoiseROIsCombined] = ...
                DisplacementDriftCorrectionIdenticalCorners(displField, CornerPercentage, FramesDoneNumbers, gridMagnification, ...
                EdgeErode, GridtypeChoiceStr, InterpolationMethod, ShowOutput);
            NoiseROIsCombined = NoiseROIsCombined(FramesDoneNumbers);
        catch
            errordlg('Could not extract NoiseROIsCombined');
        end
    end  
%%   
    
    if ~exist('gridMagnification', 'var'), gridMagnification = []; end
    if isempty(gridMagnification) || nargin < 5
        gridMagnification = 1;
    end
    
    if ~exist('EdgeErode', 'var'), EdgeErode = []; end
    if isempty(EdgeErode) || nargin < 6
        EdgeErode = 1;
    end
    
    if ~exist('GridtypeChoiceStr', 'var'), GridtypeChoiceStr = []; end
    if isempty(GridtypeChoiceStr) || nargin < 10
        GridtypeChoiceStr = 'Even Grid';
    end
    
    if ~exist('InterpolationMethod', 'var'), InterpolationMethod = []; end
    if isempty(InterpolationMethod) || nargin < 11
        InterpolationMethod = 'griddata';
    end
    
    if ~exist('ShowOutput', 'var'), ShowOutput = []; end
    if isempty(ShowOutput) || nargin < 12
    end
    
    switch GridtypeChoiceStr
        case 'Even Grid'
                [reg_grid,~,~,gridSpacing] = createRegGridFromDisplField(displField, gridMagnification, EdgeErode);
        case 'Odd Grid'
                [reg_grid,~,~,gridSpacing] = createRegGridFromDisplFieldOdd(displField, gridMagnification, EdgeErode);
        otherwise
            return
    end       
    if ~exist('i_max', 'var'), i_max = []; end
    if ~exist('j_max', 'var'), j_max = []; end    
    
    if isempty(i_max) || isempty(j_max) || nargin < 7 || nargin < 8
       [~, disp_grid_tmp, i_max,j_max] = interp_vec2grid(NoiseROIsCombined(FirstFrame).pos(:,1:2), ...
           NoiseROIsCombined(FirstFrame).vec(:,1:2),[], reg_grid, InterpolationMethod);
    end
    
    if ~exist('disp_grid', 'var'), disp_grid = []; end
    if isempty(disp_grid) || nargin < 9
       if exist('disp_grid_tmp', 'var')
           disp_grid = disp_grid_tmp;
       else       
            [~, disp_grid, ~,~] = interp_vec2grid(NoiseROIsCombined(FirstFrame).pos(:,1:2), ...
                NoiseROIsCombined(FirstFrame).vec(:,1:2),[], reg_grid, InterpolationMethod);            
       end
    end

    reverseString = '';
    if ShowOutput
        disp('_______ Finding optimal Bayesian (BL2) regularization parameter _______')
    end
    for CurrentFrame = FramesDoneNumbers
        if ShowOutput
            ProgressMsg = sprintf('Finding BL2 parameter for Frame #%d/(%d-%d)...\n',CurrentFrame, FramesDoneNumbers(1),FramesDoneNumbers(end));
            fprintf([reverseString, ProgressMsg]);
            reverseString = repmat(sprintf('\b'), 1, length(ProgressMsg));
        end 
        
        using_noise.pos =  NoiseROIsCombined(CurrentFrame).pos;           % changed from "displFieldPos;" on 2020-06-24
        using_noise.vec =  NoiseROIsCombined(CurrentFrame).vec(:,1:2);    % changed from "displFieldVec(1,1:2);" on 2020-06-24

        noise_u(1:2:size(using_noise.vec,1)*2,1) = using_noise.vec(:,1);
        noise_u(2:2:size(using_noise.vec,1)*2,1) = using_noise.vec(:,2);
        beta = 1/var(noise_u, 'omitnan');

        kx_vec = 2*pi/i_max/gridSpacing.*[0:(i_max/2-1) (-i_max/2:-1)];
        ky_vec = 2*pi/j_max/gridSpacing.*[0:(j_max/2-1) (-j_max/2:-1)];
        kx = repmat(kx_vec',1,j_max);
        ky = repmat(ky_vec,i_max,1);
        kx(1,1) = 1;
        ky(1,1) = 1;
        k = sqrt(kx.^2+ky.^2);  

        conf = 2.*(1+PoissonRatio)./(YoungModulusPa.*k.^3);
        Ginv_xx = conf .* ((1-PoissonRatio).*k.^2+PoissonRatio.*ky.^2);
        Ginv_xy = conf .* (-PoissonRatio.*kx.*ky);
        Ginv_yy = conf .* ((1-PoissonRatio).*k.^2+PoissonRatio.*kx.^2);

        Ginv_xx(1,1) = 0;
        Ginv_yy(1,1) = 0;
        Ginv_xy(1,1) = 0;  
        Ginv_xy(i_max/2+1,:) = 0;
        Ginv_xy(:,j_max/2+1) = 0;  

        G1 = sparse(reshape(Ginv_xx,[1,i_max*j_max]));
        G2 = sparse(reshape(Ginv_yy,[1,i_max*j_max]));
        X1 = sparse(reshape([G1; G2], [], 1)');  
        G3 = sparse(reshape(Ginv_xy,[1,i_max*j_max]));
        G4 = sparse(zeros(1, i_max*j_max)); 
        X2 = sparse(reshape([G4; G3], [], 1)');
        X3 = X2(1,2:end);   
        X4 = sparse(diag(X1));
        X5 = sparse(diag(X3,1));
        X6 = sparse(diag(X3,-1));
        X = X4+X5+X6;

        clear Ftu fux1 fuy1 fuu
        Ftu(:,:,1) = fft2(disp_grid(:,:,1));
        Ftu(:,:,2) = fft2(disp_grid(:,:,2));
        fux1 = reshape(Ftu(:,:,1),i_max*j_max,1);
        fuy1 = reshape(Ftu(:,:,2),i_max*j_max,1);
        fuu(1:2:size(fux1)*2,1) = fux1;
        fuu(2:2:size(fuy1)*2,1) = fuy1;

    %                                         disp('Calculating Bayesian Optimized regularization parameter value...in progress...');
        [reg_corner_tmp, ~, ~, ~] = optimal_lambda(beta, fuu, Ftu(:,:,1), Ftu(:,:,2),...
            YoungModulusPa, PoissonRatio, gridSpacing, i_max, j_max, X, false);
    %                                         disp('Calculating Bayesian Optimized regularization parameter value...completed');
        reg_corner(CurrentFrame) = reg_corner_tmp;
    end
    
    if numel(FramesDoneNumbers) == 1
        reg_corner = reg_corner(FramesDoneNumbers);
    end
end

