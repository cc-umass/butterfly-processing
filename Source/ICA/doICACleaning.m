function [epochedEEG, icaInfo] = doICACleaning(subjectEEG, epochedEEG, excludedChannels)

loadICAConstants;

icaChannels = setdiff(getScalpChannelsWithLocations(subjectEEG), excludedChannels, 'stable');
channelLabels = {subjectEEG.chanlocs.labels};

% Train the ICA on a copy of the data band-passed 1-30 Hz at 48 dB/octave (Luck, Applied Event-Related Potential
% Data Analysis, 2022, sections 9.5 and 9.9). The weights are then applied to the 0.1 Hz data.
trainingEEG = pop_basicfilter(subjectEEG, getChannelsToFilter(subjectEEG), ...
    'Filter', 'bandpass', ...
    'Design', 'butter', ...
    'Cutoff', [icaTrainingHighPassHz icaTrainingLowPassHz], ...
    'Order', icaTrainingFilterOrder, ...
    'RemoveDC', 'on', ...
    'Boundary', []);
trainingEEG = doEpoching(trainingEEG);

componentCount = numel(icaChannels) - 1;

trainingEEG = pop_runica(trainingEEG, ...
    'icatype', 'runica', ...
    'chanind', icaChannels, ...
    'options', {'extended', 1, 'pca', componentCount, 'rndreset', 'off'});

trainingEEG = pop_iclabel(trainingEEG, 'default');
eyeProbability = trainingEEG.etc.ic_classification.ICLabel.classifications(:, 3);
eyeComponents = find(eyeProbability > eyeProbabilityMin)';

epochedEEG.icaweights = trainingEEG.icaweights;
epochedEEG.icasphere = trainingEEG.icasphere;
epochedEEG.icawinv = trainingEEG.icawinv;
epochedEEG.icachansind = trainingEEG.icachansind;
epochedEEG.icaact = [];
epochedEEG = eeg_checkset(epochedEEG);

residualBefore = [];
residualAfter = [];
if ~isempty(eyeComponents) && ~isempty(excludedChannels)
    [epochedEEG, residualBefore, residualAfter] = removeEyeFromExcludedChannels(epochedEEG, epochedEEG.icachansind, excludedChannels, eyeComponents);
end
if ~isempty(eyeComponents)
    epochedEEG = pop_subcomp(epochedEEG, eyeComponents, 0);
end

if ~isstruct(epochedEEG.reject)
    epochedEEG.reject = struct('rejmanual', [], 'rejmanualE', []);
end

icaInfo = struct('icaChannelCount', numel(icaChannels), 'excludedChannels', {channelLabels(excludedChannels)}, ...
    'eyeComponents', eyeComponents, 'maxEye', max(eyeProbability), 'residualBefore', residualBefore, 'residualAfter', residualAfter);
butterflyLog('  ICA: %d components on %d channels; excluded %s; eye components removed [%s] (max Eye %.2f)', componentCount, numel(icaChannels), strjoin(icaInfo.excludedChannels, ' '), int2str(eyeComponents), max(eyeProbability));
for excludedIndex = 1:numel(residualBefore)
    butterflyLog('  eye projection on %s: max |r| with eye activity %.2f before, %.2f after', icaInfo.excludedChannels{excludedIndex}, residualBefore(excludedIndex), residualAfter(excludedIndex));
end
end

function [epochedEEG, residualBefore, residualAfter] = removeEyeFromExcludedChannels(epochedEEG, icaChannels, excludedChannels, eyeComponents)
unmixing = epochedEEG.icaweights * epochedEEG.icasphere;
icaData = reshape(double(epochedEEG.data(icaChannels, :, :)), numel(icaChannels), []);
eyeActivity = unmixing(eyeComponents, :) * icaData;
eyeProjection = epochedEEG.icawinv(:, eyeComponents) * eyeActivity;
projectionEEG = epochedEEG;
projectionEEG.data(icaChannels, :, :) = reshape(eyeProjection, numel(icaChannels), epochedEEG.pnts, epochedEEG.trials);
interpolated = interpolateChannels(projectionEEG, icaChannels, excludedChannels);
before = reshape(double(epochedEEG.data(excludedChannels, :, :)), numel(excludedChannels), []);
epochedEEG.data(excludedChannels, :, :) = epochedEEG.data(excludedChannels, :, :) - interpolated;
after = reshape(double(epochedEEG.data(excludedChannels, :, :)), numel(excludedChannels), []);
residualBefore = max(abs(corr(before', eyeActivity')), [], 2)';
residualAfter = max(abs(corr(after', eyeActivity')), [], 2)';
end
