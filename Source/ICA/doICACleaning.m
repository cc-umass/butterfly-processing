function epochedEEG = doICACleaning(subjectEEG, epochedEEG)

loadICAConstants;

icaChannels = getScalpChannelsWithLocations(subjectEEG);

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

if ~isempty(eyeComponents)
    epochedEEG = pop_subcomp(epochedEEG, eyeComponents, 0);
end

if ~isstruct(epochedEEG.reject)
    epochedEEG.reject = struct('rejmanual', [], 'rejmanualE', []);
end

butterflyLog('  ICA: %d components on %d channels; eye components removed [%s] (max Eye %.2f)', componentCount, numel(icaChannels), int2str(eyeComponents), max(eyeProbability));
end
