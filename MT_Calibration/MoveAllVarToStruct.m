% Written by Waddah Moghram on 2019-12-15, PhD Candidate in Biomedical Engineering at the Universit of Iowa
%{
    Moves all workspace variables into a structure    
%}
    z=[who,who].'; myStruct=struct(z{:});
    clear z
    fnames=fieldnames(myStruct);
    RemovedIndex = strcmp('ans',fnames);                % not count variable 'ans'
    if ~isempty(find(RemovedIndex, 1))
        fnames{RemovedIndex} = [];                          % make it empty
        fnames = fnames(~cellfun('isempty',fnames));        % remove empty cells
    end
    RemovedIndex = strcmp('myStruct',fnames);
    if ~isempty(find(RemovedIndex, 1))
        fnames{RemovedIndex} = [];                          % make it empty
        fnames = fnames(~cellfun('isempty',fnames));        % remove empty cells
    end
    for ii = 1:numel(fnames)
%         myStruct.(fnames{ii}) = eval(fnames{ii});
%         eval(myStruct(ii,:));
    end
    structName = input('What is the structure name that has all the variables?\n No need for ("") around variable name:  ', 's');
    eval(sprintf('%s = struct(); %s = myStruct', structName, structName))
    
    for ii = 1:numel(fnames)
        try
            clear (fnames{ii})
        catch
            % move on to next variable
        end
    end
    
    clear ii fnames myStruct RemovedIndex structName ans

    %% ---------- Alternatively
    %%     You need to download structvar.m from MATLAB code depository
    % myStruct2 = structvars(myStruct,0);
    % for ii = 1:numel(fnames)
    %     myStruct.(fnames{ii}) = eval(fnames{ii});
    % end