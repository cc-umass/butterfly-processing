function epochedEEG = removeEyeComponents(continuousEEG, epochedEEG, excludedChannels)

constants;

icaChannels = setdiff(scalpChannels(continuousEEG), excludedChannels, 'stable');

% Train the ICA on a copy of the data band-passed 1-30 Hz at 48 dB/octave (Luck, Applied Event-Related Potential
% Data Analysis, 2022, sections 9.5 and 9.9). The weights are then applied to the 0.1 Hz data.
trainingEEG = pop_basicfilter(continuousEEG, allChannelsExceptTrigger(continuousEEG), ...
    'Filter', 'bandpass', ...
    'Design', 'butter', ...
    'Cutoff', icaTrainingBandHz, ...
    'Order', icaTrainingFilterOrder, ...
    'RemoveDC', 'on');
trainingEEG = pop_creabasiceventlist(trainingEEG, 'BoundaryString', {'boundary'}, 'BoundaryNumeric', {-99});
trainingEEG = pop_binlister(trainingEEG, 'BDF', 'bins.txt');
trainingEEG = pop_epochbin(trainingEEG, epochWindowMs, 'none');

trainingEEG = pop_runica(trainingEEG, ...
    'icatype', 'runica', ...
    'chanind', icaChannels, ...
    'options', {'extended', 1, 'pca', numel(icaChannels) - 1, 'rndreset', 'off'});

trainingEEG = pop_iclabel(trainingEEG, 'default');
eyeProbability = trainingEEG.etc.ic_classification.ICLabel.classifications(:, 3);
eyeComponents = find(eyeProbability > eyeProbabilityMin)';

epochedEEG.icaweights = trainingEEG.icaweights;
epochedEEG.icasphere = trainingEEG.icasphere;
epochedEEG.icawinv = trainingEEG.icawinv;
epochedEEG.icachansind = trainingEEG.icachansind;
epochedEEG = eeg_checkset(epochedEEG);

if isempty(eyeComponents)
    return
end
if ~isempty(excludedChannels)
    epochedEEG = subtractEyeActivityFromExcludedChannels(epochedEEG, excludedChannels, eyeComponents);
end
epochedEEG = pop_subcomp(epochedEEG, eyeComponents, 0);
end

function epochedEEG = subtractEyeActivityFromExcludedChannels(epochedEEG, excludedChannels, eyeComponents)
icaChannels = epochedEEG.icachansind;
unmixing = epochedEEG.icaweights * epochedEEG.icasphere;
icaData = reshape(double(epochedEEG.data(icaChannels, :, :)), numel(icaChannels), []);
eyeActivity = unmixing(eyeComponents, :) * icaData;
eyeAtICAChannels = epochedEEG.icawinv(:, eyeComponents) * eyeActivity;

eyeOnlyEEG = epochedEEG;
eyeOnlyEEG.data(icaChannels, :, :) = reshape(eyeAtICAChannels, numel(icaChannels), epochedEEG.pnts, epochedEEG.trials);
eyeOnlyEEG = eeg_interp(eyeOnlyEEG, excludedChannels, 'spherical');
eyeAtExcludedChannels = eyeOnlyEEG.data(excludedChannels, :, :);

epochedEEG.data(excludedChannels, :, :) = epochedEEG.data(excludedChannels, :, :) - eyeAtExcludedChannels;
end

function indices = allChannelsExceptTrigger(eeg)
indices = find(~strcmpi({eeg.chanlocs.labels}, 'TRIGGER'));
end

function indices = scalpChannels(eeg)
constants;
hasLocation = ~cellfun(@isempty, {eeg.chanlocs.X});
isPeripheral = ismember(upper({eeg.chanlocs.labels}), peripheralChannels);
indices = find(hasLocation & ~isPeripheral);
end
