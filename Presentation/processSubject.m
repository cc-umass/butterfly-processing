function result = processSubject(curryFile, listMapFile)

constants;

% Processing order follows Luck, "Order of processing steps", https://erpinfo.org/order-of-steps

continuousEEG = pop_loadcurry(curryFile);
continuousEEG = keepExperimentEvents(continuousEEG);

sections = findBadChannelsBySection(continuousEEG, listMapFile);

% Luck step 1: high-pass filter the continuous data
continuousEEG = highPassFilter(continuousEEG, highPassHz, highPassOrder);

% Luck step 3: re-reference
continuousEEG = referenceToMastoids(continuousEEG);

% Luck step 4: epoch the continuous data
epochedEEG = epochAroundPictures(continuousEEG, epochWindowMs);
% Apply baseline correction
epochedEEG = pop_rmbase(epochedEEG, baselineWindowMs);

channelsBadInAnySection = find(any(sections.badChannels, 2))';
epochedEEG = removeEyeComponents(continuousEEG, epochedEEG, channelsBadInAnySection);

repairedEEG = interpolateBadChannelsBySection(epochedEEG, sections);
badChannelEpochs = autorejectChannelEpochs(repairedEEG);

epochedEEG = lowPassFilter(epochedEEG, lowPassHz, lowPassOrder);

result = struct();
result.data = epochedEEG.data;
result.sampleTimePoints = epochedEEG.times;
result.channelLabels = {epochedEEG.chanlocs.labels};
result.epochCondition = conditionOfEachEpoch(epochedEEG);
result.epochItem = sections.pictureItem;
result.epochSection = sections.pictureSection;
result.badChannelEpochs = badChannelEpochs;
result.badChannelSections = sections.badChannels;
end

function eeg = keepExperimentEvents(eeg)
experimentCodes = [1:120, 201:204, 210, 220, 230, 240];
eventCodes = [eeg.event.type];
eeg.event = eeg.event(ismember(eventCodes, experimentCodes));
eeg = eeg_checkset(eeg, 'eventconsistency');
end

function eeg = highPassFilter(eeg, cutoffHz, order)
eeg = pop_basicfilter(eeg, allChannelsExceptTrigger(eeg), ...
    'Filter', 'highpass', ...
    'Design', 'butter', ...
    'Cutoff', cutoffHz, ...
    'Order', order, ...
    'RemoveDC', 'on');
end

function eeg = lowPassFilter(eeg, cutoffHz, order)
eeg = pop_basicfilter(eeg, allChannelsExceptTrigger(eeg), ...
    'Filter', 'lowpass', ...
    'Design', 'butter', ...
    'Cutoff', cutoffHz, ...
    'Order', order, ...
    'RemoveDC', 'off');
end

function eeg = referenceToMastoids(eeg)
constants;
channels = upper({eeg.chanlocs.labels});
mastoidIndices = find(ismember(channels, mastoidChannels));
peripheralIndices = find(ismember(channels, peripheralChannels));
eeg = pop_reref(eeg, mastoidIndices, ...
    'keepref', 'on', ...
    'exclude', peripheralIndices);
end

function epochedEEG = epochAroundPictures(eeg, windowMs)
epochedEEG = pop_creabasiceventlist(eeg, 'BoundaryString', {'boundary'}, 'BoundaryNumeric', {-99});
epochedEEG = pop_binlister(epochedEEG, 'BDF', 'bins.txt');
epochedEEG = pop_epochbin(epochedEEG, windowMs, 'none');
end

function repairedEEG = interpolateBadChannelsBySection(epochedEEG, sections)
constants;
repairedEEG = epochedEEG;
for sectionIndex = 1:sectionCount
    badIndices = find(sections.badChannels(:, sectionIndex))';
    epochIndices = find(sections.pictureSection == sectionIndex);
    if isempty(badIndices) || isempty(epochIndices)
        continue
    end
    sectionEEG = pop_select(epochedEEG, 'trial', epochIndices);
    sectionEEG = eeg_interp(sectionEEG, badIndices, 'spherical');
    repairedEEG.data(badIndices, :, epochIndices) = sectionEEG.data(badIndices, :, :);
end
end

function badChannelEpochs = autorejectChannelEpochs(epochedEEG)
constants;
scalpIndices = scalpChannels(epochedEEG);
input = struct();
input.channelData = double(epochedEEG.data(scalpIndices, :, :));
input.channelLabels = {epochedEEG.chanlocs(scalpIndices).labels};
input.channelPositions = [[epochedEEG.chanlocs(scalpIndices).X]', [epochedEEG.chanlocs(scalpIndices).Y]', [epochedEEG.chanlocs(scalpIndices).Z]'];
input.sampleRate = epochedEEG.srate;
input.epochStartSeconds = epochedEEG.xmin;
save('autorejectInput.mat', '-struct', 'input', '-v7');
system(sprintf('python autorejectThresholds.py autorejectInput.mat autorejectOutput.mat %d', autorejectRandomState));
output = load('autorejectOutput.mat');
badChannelEpochs = false(epochedEEG.nbchan, epochedEEG.trials);
badChannelEpochs(scalpIndices, :) = output.badCells > 0;
end

function conditions = conditionOfEachEpoch(epochedEEG)
constants;
conditions = zeros(1, epochedEEG.trials);
for epochIndex = 1:epochedEEG.trials
    epoch = epochedEEG.epoch(epochIndex);
    lockingEvent = cell2mat(epoch.eventlatency) == 0;
    conditions(epochIndex) = find(pictureCodes == epoch.eventtype{lockingEvent});
end
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
