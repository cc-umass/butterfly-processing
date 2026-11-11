function section_stub(entryName)

addpath(genpath(fullfile(fileparts(mfilename('fullpath')), 'Source')));
feval(entryName);
end
