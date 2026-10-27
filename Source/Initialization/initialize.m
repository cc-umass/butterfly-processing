function initialize()

globals;

setupWorkspace(intermediateDir, figureDir);
setupLogging(logFile);
setupEEGlab(eeglabDir);
% Set up epoch bins
setupBDF(binDescriptorFile);
end

function setupWorkspace(intermediateDir, figureDir)
ensureDirectory(intermediateDir);
ensureDirectory(figureDir);
end

function ensureDirectory(directory)
if ~exist(directory, 'dir'), mkdir(directory); end
end

function setupLogging(logFile)
if exist(logFile, 'file'), delete(logFile); end
butterflyLog('minimal.m start %s', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
end

function setupEEGlab(eeglabDir)
loadInitializationConstants;
% If EEGLab not on path, try to add it
if exist('eeglab', 'file') ~= 2, addpath(eeglabDir); end
% Start up EEGLab
eeglab nogui;
for functionIndex = 1:numel(requiredFunctions)
    assert(exist(requiredFunctions{functionIndex}, 'file') == 2, 'missing function %s', requiredFunctions{functionIndex});
end
butterflyLog('EEGLAB ready');
end

function setupBDF(binDescriptorFile)
loadInitializationConstants;
fileId = fopen(binDescriptorFile, 'w');
assert(fileId >= 0, 'cannot open %s for writing', binDescriptorFile);
for binIndex = 1:numel(binNames)
    fprintf(fileId, 'bin %d\n\t%s\n\t.{%d}\n', binIndex, binNames{binIndex}, binCodes(binIndex));
end
fclose(fileId);
butterflyLog('bin descriptor written: %s', binDescriptorFile);
end
