    %{
        v.2020-09-22 by Waddah Moghram
            1. Fixed FluxON/FluxOFF Logicals problem
        v.2020-07-05 Written by Waddah Moghram, PhD Candidate in Biomedical Engineering at the Unviversity of Iowa.
            1. This code takes as input Raw regularization parameters for all frames, FluxON/OFF/Transients, and TransientRegParamMethod is optional
            2. This code is part of VideoAnalysisEPI.m v.2020-07-05 
            refer to VideoAnalysisEPI.m v.2020-06-29 for more details. 
    %}

 function [reg_corner_averaged, TransientRegParamMethod] = RegCornerBinAndAverage(reg_corner_raw, FluxON, FluxOFF, FluxTransient, FramesDoneNumbers, TransientRegParamMethod)
%% 0. FramesDoneNumbers setup
    if ~exist('FramesDoneNumbers', 'var'), FramesDoneNumbers = []; end
    if isempty(FramesDoneNumbers) || nargin < 5
        FramesDoneBoolean = arrayfun(@(x) ~isempty(x), reg_corner_raw);
        FramesDoneNumbers = find(FramesDoneBoolean == 1); 
    end
  
    FluxON = logical(FluxON);
    FluxOFF = logical(FluxOFF);           
 %% 1. Average ON/OFF regularization parameters for now.=
    reg_corner_rawON = reg_corner_raw(FluxON(FramesDoneNumbers));
    reg_corner_rawOFF = reg_corner_raw(FluxOFF(FramesDoneNumbers));

    reg_cornerMeanON = 10^(mean(log10(reg_corner_rawON), 'omitnan'));
    reg_cornerMeanOFF = 10^(mean(log10(reg_corner_rawOFF), 'omitnan'));   
    
    reg_corner_tmp(FluxON) = reg_cornerMeanON;
    reg_corner_tmp(FluxOFF) = reg_cornerMeanOFF;   
    
%% 2. Ask what do you want to do with transients.
    if ~exist('TransientRegParamMethod', 'var'), TransientRegParamMethod = []; end
    if isempty(TransientRegParamMethod) || nargin < 6
        dlgQuestion = 'What do you want to use for regularization parameters?';
        TransientRegParamMethodStr = {'ON for Transients','1st ON, 2nd OFF, ...', 'Averaged Transients','Average of ON/OFF', 'Leave Transients as are'};         % , 'Median', 'Ad-hoc'
        TransientRegParamMethod = listdlg('ListString', TransientRegParamMethodStr, 'PromptString',dlgQuestion ,'InitialValue', 1, 'SelectionMode' ,'single', ...
            'ListSize', [300, 80]);
        if isempty(TransientRegParamMethod), error('No method was selected'); end
        try
            TransientRegParamMethod = TransientRegParamMethodStr{TransientRegParamMethod};                 % get the names of the string.   
        catch
            error('X was selected');           
        end 
        if isempty(TransientRegParamMethod), return; end 
    end
    
% 3. Classify transients now
    switch TransientRegParamMethod
        case 'ON for Transients'
            reg_corner_tmp(FluxTransient) = reg_cornerMeanON; 

        case '1st ON, 2nd OFF, ...'
            FluxStatusTmp = zeros(size(FluxON));
            FluxStatusTmp(FluxOFF) = -1;
            FluxStatusTmp(FluxTransient) = 0;
            FluxStatusTmp(FluxON) = 1;

            FluxStatusTmpDiff = zeros(size(FluxON));
            FluxStatusTmpDiff(2:end) = FluxStatusTmp(2:end) - FluxStatusTmp(1:end-1);

            FluxTransientsToONstart = find(FluxStatusTmp == 0 & FluxStatusTmpDiff == 1);
            FluxTransientsToONend = find(FluxStatusTmp == 1 & FluxStatusTmpDiff == 1) - 1;
            FluxTransientsToONfunc = @(x) (FluxTransientsToONstart(x):FluxTransientsToONend(x));
            FluxTransientsToON = cell2mat(arrayfun(FluxTransientsToONfunc, 1:numel(FluxTransientsToONstart), 'UniformOutput', false));
            reg_corner_tmp(FluxTransientsToON) = reg_cornerMeanON;

            FluxTransientsToOFFstart = find(FluxStatusTmp == 0 & FluxStatusTmpDiff == -1);
            FluxTransientsToOFFend = find(FluxStatusTmp == -1 & FluxStatusTmpDiff == -1) - 1;
            FluxTransientsToOFFfunc = @(x) (FluxTransientsToOFFstart(x):FluxTransientsToOFFend(x));
            FluxTransientsToOFF = cell2mat(arrayfun(FluxTransientsToOFFfunc, 1:numel(FluxTransientsToOFFstart), 'UniformOutput', false)); 
            reg_corner_tmp(FluxTransientsToOFF) = reg_cornerMeanOFF;

        case 'Average of ON/OFF'
            reg_cornerTransient = reg_corner_tmp(FluxTransient(FramesDoneNumbers));
            reg_cornerMeanTransient = 10^(mean([log10(reg_cornerMeanON),log10(reg_cornerMeanOFF)] , 'omitnan'));
            reg_corner_tmp(FluxTransient) = reg_cornerMeanTransient;

        case 'Averaged Transients' 
            reg_cornerTransient = reg_corner_tmp(FluxTransient(FramesDoneNumbers));
            reg_cornerMeanTransient = 10^(mean(log10(reg_cornerTransient), 'omitnan'));                   
            reg_corner_tmp(FluxTransient) = reg_cornerMeanTransient;   

        case 'Leave Transients as are'
            reg_corner_tmp(FluxTransient) = reg_corner_tmp(FluxTransient(FramesDoneNumbers));
    end            

%     reg_cornerON = reg_corner_raw(FluxON(FramesDoneNumbers));
%     reg_cornerOFF = reg_corner_raw(FluxOFF(FramesDoneNumbers));
% 
%     reg_cornerMeanON = 10^(mean(log10(reg_cornerON), 'omitnan'));
%     reg_cornerMeanOFF = 10^(mean(log10(reg_cornerOFF), 'omitnan'));            
    
    if isempty(reg_cornerMeanON), reg_cornerMeanON= nan; end
    if isempty(reg_cornerMeanOFF), reg_cornerMeanOFF= nan; end
    
    reg_corner_tmp(FluxON) = reg_cornerMeanON;
    reg_corner_tmp(FluxOFF) = reg_cornerMeanOFF;     

    reg_corner_averaged = reg_corner_tmp;
    
end