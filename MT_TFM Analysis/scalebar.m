function h = scalebar(varargin)
%SCALEBAR creates a scalebar on an axes
%
% SCALEBAR
% SCALEBAR OFF
% SCALEBAR(PARAMETER, VALUE, ...)
% SCALEBAR(HAXES, PARAMETER, VALUE, ...)
% H = SCALEBAR(...)
% 
% Draws a scalebar on the axes and returns handle to the scalebar. The
% DataAspectRatio property of the axes must be set to [1 1 1] and the view
% must be in 2D. All parameters are optional (note the default values
% below). SCALEBAR OFF deletes the current scalebar.
% 
% PARAMETER/VALUE pairs
%     hAxes:        handle to the axes (defaults to current axes)
%     ScaleLength:  length to show (in data units) (defaults to ~10% of the 
%                       x-axis limit range)
%     ScaleLengthRatio: ScaleLength/range(XLim)
%     Location:     location of the scalebar. Possible values are
%                       northeast (default)
%                       northwest
%                       southeast
%                       southwest
%                       [x y] data coordinates
%     color:       color of scalebar in 1x3 RGB array (default is [0 0 0])
%     Bold:         draw with bold text and linewidth=2. 
%                       True or false(default)
%     Unit:         string containing units e.g. 'mm'
%
% Note: SCALEBAR sets the XLimMode and YLimMode of the axes to manual.
%
% Created 10 November 2009 by Amanda Ng
% Modified 24 March 2013 by Amanda Ng
%  - fixed bug: bold wasn't refreshing after zoom
%  - added unit string

% modified by Waddah Moghram on 2020-02-09 to give the type of notches and thickness that I want
% Update by Waddah moghram on 2020-08-25 to adjust the line thickness ('linewidth')
%{
    Example: to plot a scalebar of 20 microns, conversion = 0.215 micron/pixel. '\mu' is mu in green letter.
    scalebar(gca,'ScaleLength', 20, 'ScaleLengthRatio', 0.215, 'color', [1,1,1], 'bold', true, 'unit', sprintf('%sm', char(181)), 'location', 'southeast') 
    Example2: to select the location of the scale (left-edge is where the selection is).
    [Location(1), Location(2)] = ginput(1);
    scalebar(gca,'ScaleLength', 20, 'ScaleLengthRatio', 0.215, 'color', [1,1,1], 'bold', true, 'unit', sprintf('%sm', char(181)), 'location', Location) 
%}

    % DELETE SCALEBAR IF ONE EXISTS
    delete(findobj(gca,'tag','scalebar'));

    % RETURN IF 'OFF' WAS REQUESTED
    if nargin>0 && strcmpi(varargin{1},'off')
        return;
    end

    % CONSTANTS
    directions = {'northwest','northeast','southeast','southwest'};
    
    % SET PARAMETERS TO DEFAULTS
    hAxes = gca;
    scalelength = 0;
    scalelengthratio = 0.1;
    location = 'northeast';
    color = [0 0 0];
    boldflag = false;
    linewidth = 0.5;
    fontweight = 'normal';
    fontsize = 10;
    fontname = 'Helvetica';
    unitstring = '';

    % PROCESS ARGUMENTS
    if nargin>0
        args = {};
        % Process if arguments given as "hAxes, ..."
        if ishandle(varargin{1}) %hAxes
            args{length(args)+1}='hAxes';
            args{length(args)+1}=varargin{1};
            varargin = varargin(2:end);
        end
        args=[args varargin];
        % Process argument pairs
        for n=1:2:length(args)
            parameter = args{n};
            if n == length(args)
                error('Parameter ''%s'' is not followed by a value in argument list', parameter);
            end
            value = args{n+1};
            switch lower(parameter)
                case 'haxes'
                    if ~ishandle(value)
                        error 'HAXES is not a valid Axes handle'
                    elseif ~strcmpi(get(value,'type'),'axes')
                        error 'HAXES is not a valid Axes handle'
                    elseif strcmpi(get(value,'tag'),'colorbar')
                        error 'HAXES is a handle to a colorbar'
                    else
                        hAxes = value;
                    end
                case 'scalelength'
                    if ~isnumeric(value)
                        error 'SCALELENGTH must be a numeric value'
                    end
                    scalelength = value;
                case 'scalelengthratio'
                    if ~isnumeric(value)
                        error 'SCALELENGTHRATIO must be a numeric value'
                    end
                    scalelengthratio = value;
                case 'location'
                    if ~(numel(value)==2 && isnumeric(value)) && ...
                       isempty(strcmpi(lower(value),directions))
                        error 'unrecognised value for LOCATION'
                    end
                    location = value;
                case 'color'
                    if numel(value)~=3 || ~isnumeric(value)
                        error 'color must be a 1x3 representation of an RGB color'
                    end
                    color = value;
                case 'bold'
                    if ischar(value) && strcmpi(value,'true') || ...
                       (islogical(value) || isnumeric(value)) && value
                            boldflag = true;
                            linewidth=2;
                            fontweight='bold';
                    end
                case 'unit'
                    if ~ischar(value) || isempty(value)
                        error('''Unit'' must be followed by a string')
                    end
                    unitstring = [' ' strtrim(value)];
                case 'fontsize'
                    if ~isnumeric(value)
                        error 'fontsize must be a numeric value'
                    end
                    fontsize = value;       
                case 'fontname'
                    if ~ischar(value) 
                        error 'fontname must be a string value'
                    end
                    fontname = value;   
                case 'linewidth'
                    if ~isnumeric(value)
                        error 'SCALELENGTH must be a numeric value'
                    end
                    linewidth = value;
                otherwise
                    error(['unrecognised parameter: ' parameter]);
            end
        end
    end

    %________ Commented out by WIM on 2020-02-09
%     % CHECK IF DATAASPECTRATIO IS [1 1 1]
%     if ~all(get(hAxes,'DataAspectRatio')==1)
%         error 'The Axes property DataAspectRatio must be set to [1 1 1]'
%     end
    
    % CHECK IF VIEW IS IN 2D
    [az el] = view(hAxes);
    if el~=90
        error 'The Axes must be in 2D view'
    end
    
    %GET IMAGE AND AXES DATA
    axeslims = [get(hAxes,'xlim')' get(hAxes,'ylim')'];
    axesdir = [1 1];
    if strcmpi(get(hAxes,'XDir'),'reverse')
        axeslims(:,1) = flipud(axeslims(:,1));
        axesdir(1) = -1;
    end
    if strcmpi(get(hAxes,'YDir'),'reverse')
        axeslims(:,2) = flipud(axeslims(:,2));
        axesdir(2) = -1;
    end

    % CALCULATE SCALELENGTH
    if scalelength==0
        sl = range(axeslims(:,1))*scalelengthratio;
        slorder = 10^floor(log10(sl));
        scalelength = round(sl/slorder)*slorder;    
    else
%         scalelengthratio = scalelength/range(axeslims(:,1));          % commented out by WIM. If a scaleLengthratio is given, do not change it.
    end
    
    %SET UP POSITIONING
    if ischar(location)
        switch location
            case 'northeast'
                anchor = [axeslims(2,1) - axesdir(1)*range(axeslims(:,1))*0.05, ...
                          axeslims(2,2) - axesdir(2)*range(axeslims(:,2))*0.05];
                direction = 'southwest';
            case 'northwest'
                anchor = [axeslims(1,1) + axesdir(1)*range(axeslims(:,1))*0.05, ...
                          axeslims(2,2) - axesdir(2)*range(axeslims(:,2))*0.05];
                direction = 'southeast';
            case 'southwest'
                anchor = [axeslims(1,1) + axesdir(1)*range(axeslims(:,1))*0.05, ...
                          axeslims(1,2) + axesdir(2)*range(axeslims(:,2))*0.05];
                direction = 'northeast';
            case 'southeast'
                anchor = [axeslims(2,1) - axesdir(1)*range(axeslims(:,1))*0.05, ...
                          axeslims(1,2) + axesdir(2)*range(axeslims(:,2))*0.05];
                direction = 'northwest';
        end    
    else
        anchor = location;
        if location
            dirToCentre = min(axeslims)+range(axeslims)/2 - location.*axesdir;
            direction = directions{ceil((-1*atan2(dirToCentre(2),dirToCentre(1))+pi)/(2*pi)*4)};
        end
    end

    linepos = [anchor; anchor];
    if contains(direction,'east')
        linepos(2,1) = linepos(2,1)+axesdir(1)*(scalelength/scalelengthratio);         % fixed by WIM on 2020-02-09 so that input is in desired units, not pixels.
    else
        linepos(1,1) = linepos(1,1)-axesdir(1)*(scalelength/scalelengthratio);         % fixed by WIM on 2020-02-09 so that input is in desired units, not pixels.
    end
    
    ends(:,:,1) = [linepos(1,:); linepos(1,:)];
    ends(:,:,2) = [linepos(2,:); linepos(2,:)];
    if contains(direction,'north')
        ends(2,2,:) = ends(2,2,:)-axesdir(2)*0.2*scalelength;
        textalignment = {'bottom', 'center'};
    else
        ends(2,2,:) = ends(2,2,:)+axesdir(2)*0.2*scalelength;
        textalignment = {'top', 'center'};
    end
            
%     % DRAW SCALEBAR          (original style)
%     set(gca,'xlimmode','manual','ylimmode','manual');
%     hg = hggroup('tag','scalebar');
%     line(linepos(:,1), linepos(:,2), 'color', color, 'linewidth', linewidth, 'parent', hg);
%     line(ends(:,1,1), ends(:,2,1), 'color', color, 'linewidth', linewidth, 'parent', hg);
%     line(ends(:,1,2), ends(:,2,2), 'color', color, 'linewidth', linewidth, 'parent', hg);
%     text(linepos(1,1),linepos(1,2),0,'0','verticalalignment',textalignment{1},'horizontalalignment',textalignment{2}, 'color', color, 'fontweight', fontweight, 'parent', hg);
%     text(linepos(2,1),linepos(2,2),0,[num2str(scalelength) unitstring],'verticalalignment',textalignment{1},'horizontalalignment',textalignment{2}, 'color', color, 'fontweight', fontweight, 'parent', hg);
    
    % DRAW SCALEBAR              (WIM style)
    set(gca,'xlimmode','manual','ylimmode','manual');
    hg = hggroup('tag','scalebar');
    line(linepos(:,1), linepos(:,2), 'color', color, 'linewidth', linewidth, 'parent', hg);
%     line(ends(:,1,1), ends(:,2,1), 'color', color, 'linewidth', linewidth, 'parent', hg);
%     line(ends(:,1,2), ends(:,2,2), 'color', color, 'linewidth', linewidth, 'parent', hg);
%     text(linepos(1,1),linepos(1,2),0,'0','verticalalignment',textalignment{1},'horizontalalignment',textalignment{2}, 'color', color, 'fontweight', fontweight, , 'FontSize', fontsize, 'parent', hg);
    text(mean(linepos(:,1)),mean(linepos(:,2) - 5),0,[num2str(scalelength) unitstring],'verticalalignment',textalignment{1},'horizontalalignment',textalignment{2}, ...
        'color', color, 'FontWeight', fontweight, 'FontName' , fontname, 'FontSize', fontsize, 'parent', hg);

    if nargout>0
        h = hg;
    end
    
    % SETUP DELETE CALLBACK
    set(hg,'DeleteFcn',@deleteScaleBar)
    
    % SETUP LISTENER TO RESET SCALEBAR ON CHANGE OF AXES LIMITS
    hL(1) = addlistener(hAxes,'YLim','PostSet',@(src,event) resetScaleBar(src,event,hg));

    % SET USERDATA
    udata = {'ScaleLengthRatio',scalelengthratio;...
             'AnchorRatio',[(anchor(1)-min(axeslims(:,1)))/range(axeslims(:,1)) (anchor(2)-min(axeslims(:,2)))/range(axeslims(:,2))];...
             'color',color;...
             'Listeners',hL;...
             'Bold',boldflag};
    set(hg,'UserData',udata);        
end

 % CALLBACK FUNCTIONS
function deleteScaleBar(src,event)
    udata = get(src,'UserData');
    delete(udata{strcmpi(udata(:,1),'Listeners'),2});
end

function resetScaleBar(src,event,SB)
    udata = get(SB,'UserData');
    hAxes = get(SB,'parent');

    delete(SB);        

    axeslims = [get(hAxes,'xlim')' get(hAxes,'ylim')'];

    scalelengthratio = udata{strcmpi(udata(:,1),'ScaleLengthRatio'),2};
    anchorratio = udata{strcmpi(udata(:,1),'AnchorRatio'),2};
    location = [anchorratio(1)*range(axeslims(:,1))+axeslims(1,1) anchorratio(2)*range(axeslims(:,2))+axeslims(1,2)];
    color = udata{strcmpi(udata(:,1),'color'),2};
    boldflag = udata{strcmpi(udata(:,1),'Bold'),2};

    scalebar(hAxes,'ScaleLengthRatio',scalelengthratio,'Location',location,'color',color, 'Bold', boldflag);
end