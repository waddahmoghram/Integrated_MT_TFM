function [umMap,XI,YI] = generateHeatmapFromFieldModifiedForce1_0(Field,dataPath,band,ummax,cmapmode,w,h,plotQuiver)

%     Added by WIM on 1/13/2019. Convert pixels to microns
%     F = fieldnames(Field);
%     for i = 1:size(Field,2)
%           tmpField = Field(i).vec;
%           Field(i).pos = Field.pos;             % microns/pixel
%           Field(i).vec = tmpField * 0.215;      % microns/pixel
%     end
%     -------------------
    
    if nargin <5 || isempty(cmapmode)
        cmapmode = 'jet';
    end
    if nargin <8
        plotQuiver = true;
    end
    ummin = 1e20;
    if nargin <4 || isempty(ummax)
        temp_ummax = 0;
    end
    if nargin <3
        band = 0;
    end
    numNonEmpty = sum(arrayfun(@(x) ~isempty(x.vec),Field));

    for FrameNum=1:numNonEmpty
        maxMag = (Field(FrameNum).vec(:,1).^2+Field(FrameNum).vec(:,2).^2).^0.5;
        
        ummin = min(ummin,min(maxMag));
        if nargin < 4 || isempty(ummax)
            temp_ummax = max(temp_ummax, max(maxMag));
        end
    end 
    
    if nargin < 4 || isempty(ummax)
        ummax = temp_ummax;
    end
    
    tMap = cell(1,numel(Field));
    tMapX = cell(1,numel(Field));
    tMapY = cell(1,numel(Field));

%     plotQuiver = false                        % added by Waddah Moghram, since I could not get to insert only the last argument as false.

    % account for if displField contains more than one frame
    [reg_grid,~,~,~] = createRegGridFromDisplField(Field(1),2); %2=2 times fine interpolation

    filesep = '\';   % for windows
    fString = ['%0' num2str(floor(log10(numNonEmpty))+1) '.f'];
    numStr = @(frame) num2str(frame,fString);
    outFiledMap = @(frame) [pwd, filesep, 'tMaps',filesep, 'tMap' numStr(frame) '.mat'];
    
    for FrameNum=1:numNonEmpty
        msg = ['Frame #',num2str(FrameNum)];
        disp(msg)

        [grid_mat,iu_mat,~,~] = interp_vec2grid(Field(FrameNum).pos, Field(FrameNum).vec,[],reg_grid);
        grid_spacingX = grid_mat(1,2,1)- grid_mat(1,1,1);
        grid_spacingY = grid_mat(2,1,2)- grid_mat(1,1,2);
        
        imSizeX = grid_mat(end,end,1)- grid_mat(1,1,1) + grid_spacingX;
        imSizeY = grid_mat(end,end,2)- grid_mat(1,1,2) + grid_spacingY; 
        
        if nargin<6 || isempty(w) || isempty(h)
            w = imSizeX;
            h = imSizeY;
        end

        centerX = ((grid_mat(end,end,1)+grid_mat(1,1,1))/2);
        centerY = ((grid_mat(end,end,2)+grid_mat(1,1,2))/2);
        
        % [XI,YI] = meshgrid(grid_mat(1,1,1):grid_mat(1,1,1)+imSizeX,grid_mat(1,1,2):grid_mat(1,1,2)+imSizeY);
        xmin = centerX-w/2+band;
        xmax = centerX+w/2-band;
        ymin = centerY-h/2+band;
        ymax = centerY+h/2-band;

        [XI,YI] = meshgrid(xmin:xmax,ymin:ymax);

        % Added by WIM on 2/5/2019
        umnorm = (iu_mat(:,:,1).^2 + iu_mat(:,:,2).^2).^0.5;
        tMap{FrameNum} = umnorm;
        tMapX{FrameNum} = iu_mat(:,:,1);
        tMapY{FrameNum} = iu_mat(:,:,2);
        
        umMap = griddata(grid_mat(:,:,1),grid_mat(:,:,2),umnorm,XI,YI,'cubic');
        
        if nargin >=2
            h3 = figure('color','w','visible','off');             % change off to ON if you want to see the figure every time it is plotted
%             set(h3, 'Position', [100 100 w*1.05 h])
%             subplot('Position',[0.05 0.05 0.85 0.9])
            imshow(umMap,[ummin ummax])

            if strcmp(cmapmode,'uDefinedCool')
                color1 = [0 0 0]; color2 = [1 0 0];
                color3 = [0 1 0]; color4 = [0 0 1];
                color5 = [1 1 1]; color6 = [1 1 0];
                color7 = [0 1 1]; color8 = [1 0 1];    
                uDefinedCool = usercolormap(color1,color4,color7,color5);
                colormap(uDefinedCool);
            elseif strcmp(cmapmode,'uDefinedJet')
                color1 = [0 0 0]; color2 = [1 0 0];
                color3 = [122/255 179/255 23/255]; color4 = [0 0 1];
                color5 = [1 1 1]; color6 = [1 1 0];
                color7 = [0 1 1]; color8 = [252/255 145/255 58/255];    
                uDefinedCool = usercolormap(color1,color4,color7, color3,color6,color8,color2);
                colormap(uDefinedCool);
            elseif strcmp(cmapmode,'uDefinedRYG')
                color1 = [0 0 0]; color2 = [1 0 0];
                color3 = [0 1 0]; color4 = [0 0 1];
                color5 = [1 1 1]; color6 = [1 1 0];
                color7 = [0 1 1]; color8 = [1 0 1];   
                color9 = [49/255 0 98/255];
                uDefinedCool = usercolormap(color9,color2,color6, color3);
                colormap(uDefinedCool);
            elseif strcmp(cmapmode,'uDefinedYGR')
                color1 = [0 0 0]; color2 = [1 0 0];
                color3 = [0 1 0]; color4 = [0 0 1];
                color5 = [1 1 1]; color6 = [1 1 0];
                color7 = [0 1 1]; color8 = [1 0 1];    
                uDefinedCool = usercolormap(color5,color6,color3,color2);
                colormap(uDefinedCool);
            else
                colormap(cmapmode);
            end
            %quiver plot
            hold on
            dispScale = 0.05*ummax; %max(sqrt(displField.vec(:,1).^2+displField.vec(:,2).^2));

            Npoints = length(Field(FrameNum).pos(:,1));
            inIdx = false(Npoints,1);

            for CurrentPoint=1:Npoints
                if Field(FrameNum).pos(CurrentPoint,1) >= xmin && Field(FrameNum).pos(CurrentPoint,1)<= xmax ...
                        && Field(FrameNum).pos(CurrentPoint,2)>=ymin && Field(FrameNum).pos(CurrentPoint,2)<=ymax
                    inIdx(CurrentPoint) = true;
                end
            end

            if plotQuiver
%                  quiver(Field(FrameNum).pos(inIdx,1)-xmin,Field(FrameNum).pos(inIdx,2)-ymin, Field(FrameNum).vec(inIdx,1)./dispScale,Field(FrameNum).vec(inIdx,2)./dispScale,0,'Color',[75/255 0/255 130/255],'LineWidth',0.5);
                quiver(Field(FrameNum).pos(inIdx,1)-xmin,Field(FrameNum).pos(inIdx,2)-ymin, Field(FrameNum).vec(inIdx,1)./dispScale,Field(FrameNum).vec(inIdx,2)./dispScale,0,'Color',[255/255 255/255 255/255],'LineWidth',0.5);
            end

            subplot('Position',[0.90 0.05 0.25 0.9])
            axis tight
            caxis([ummin ummax]), axis off
            hc = colorbar('West');
            set(hc,'Fontsize',12)

            % added by WIM on 1/13/2019
            ylabel(hc,'Traction (Pa)')

            % saving
            % Set up the output file path
            if ~isempty(dataPath)
                outputFilePath = [dataPath filesep 'HeatMapTraction'];
                tifPath = [outputFilePath filesep 'TIF'];
                figPath = [outputFilePath filesep 'FIG'];
%                 epsPath = [outputFilePath filesep 'EPS'];
                if ~exist(tifPath,'dir') %|| ~exist(epsPath,'dir')
                    mkdir(tifPath);
                    mkdir(figPath);
%                     mkdir(epsPath);
                end

                % give it some time so that the colormap will show
                pause(2)
                
                I = getframe(h3);
                imwrite(I.cdata, strcat(tifPath,'\tractionFieldMagTIF',num2str(FrameNum),'.tif'));
                hgsave(h3,strcat(figPath,'\tractionFieldMagFIG',num2str(FrameNum)),'-v7.3')
%                 print(h3,strcat(epsPath,'\tractionFieldMagEPS',num2str(FrameNum),'.eps'),'-depsc')
                close(h3)
            end
        end
%          curr_dMap = tMap{FrameNum};
%          curr_dMapX = tMapX{FrameNum};
%          curr_dMapY = tMapY{FrameNum};
%          
%          save(outFiledMap(FrameNum),'curr_dMap','curr_dMapX','curr_dMapY','-v7.3');                   % Modified by WIM on 2/5/2019
%     
    end
    
    % Added by WIM on 2/5/2019

%     outputFile = [pwd, filesep, 'dispMaps.mat'];
%     save(outputFile,'dMap','dMapX','dMapY','-v7.3');              
    
end


