% Written by Waddah Moghram on 2021-10-07 
%{
    Goes with AIM3_Analysis, but can go with anything else
%}
format compact;
AllVars = whos;
MatlabObj = nan(numel(AllVars),1);
ParallelObj = nan(numel(AllVars),1);
gpuArrayObj = nan(numel(AllVars),1);
for ii = 1:numel(AllVars)
    currentClassStr = AllVars(ii).class;
    MatlabObj(ii) =  contains(currentClassStr, 'matlab.');
    ParallelObj(ii) = contains(currentClassStr, 'parallel.');
    gpuArrayObj(ii) = contains(currentClassStr, 'gpuArray');
    if MatlabObj(ii) || ParallelObj(ii)
        eval(sprintf('clear %s', AllVars(ii).name));
    end
    if gpuArrayObj(ii)
        eval(sprintf('%s = gather(%s);',AllVars(ii).name,AllVars(ii).name));
    end
end
clear MatlabObj ParallelObj gpuArrayObj ii jj i ;
