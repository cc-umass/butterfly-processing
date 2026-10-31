function badCells = getAutorejectMask(epochedEEG, subjectId)

loadRejectionConstants;

% Prepare the data that we want to test with Autoreject, which we will write to a .mat file
channels = {epochedEEG.chanlocs.labels};
indicesToTest = getScalpChannelsWithLocations(epochedEEG);
autorejectInput = struct();
autorejectInput.channelData = double(epochedEEG.data(indicesToTest, :, :));
autorejectInput.channelLabels = channels(indicesToTest);
autorejectInput.channelPositions = [[epochedEEG.chanlocs(indicesToTest).X]', [epochedEEG.chanlocs(indicesToTest).Y]', [epochedEEG.chanlocs(indicesToTest).Z]'];
autorejectInput.sampleRate = epochedEEG.srate;
autorejectInput.epochStartSeconds = epochedEEG.xmin;
inputFile = fullfile(intermediateDir, [subjectId '_autoreject_in.mat']);
outputFile = fullfile(intermediateDir, [subjectId '_autoreject_out.mat']);
save(inputFile, '-struct', 'autorejectInput', '-v7');

% Run autorejectMask.py which writes a channel x epoch matrix and marks cells that should be dropped
script = fullfile(rootDir, 'Source', 'Rejection', 'autorejectMask.py');
command = sprintf('"%s" -I "%s" "%s" "%s" %d', pythonExecutable, script, inputFile, outputFile, autorejectRandomState);
[~, output] = system(command);
butterflyLog('  %s', strtrim(output));

% A cell is bad when Autoreject marked that channel in that epoch
result = load(outputFile);
badCells = false(epochedEEG.nbchan, epochedEEG.trials);
badCells(indicesToTest, :) = result.badCells > 0;
end
