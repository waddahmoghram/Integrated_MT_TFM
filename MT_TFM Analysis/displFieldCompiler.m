% Compiled displacement Fields
%{
    v.2020-09-14 Written by Waddah Moghram to combined multiple displacement field files that were tracked from separate movies.

%}

% 1. Load the first displField.mat file & saved it to displFieldCompiled.mat

 displFieldCompiled = displField;
 
 
 % 2. Load the next displField.mat
 
 for ii = 1:numel(displField)
    displFieldCompiled(end+1) = displField(ii);
 end
 
 % 3. save displFieldCompield as displField, clear displFieldCompiled and save displField as a workspace (.m) file
 displField = displFieldCompiled;
 clear displFieldCompiled
 clear ans
 clear ii