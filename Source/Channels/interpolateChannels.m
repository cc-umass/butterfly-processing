function result = interpolateChannels(eeg, sourceIndices, targetIndices)

eeg.icaweights = [];
eeg.icasphere = [];
eeg.icawinv = [];
eeg.icachansind = [];
eeg.icaact = [];
eeg = pop_select(eeg, 'channel', [sourceIndices(:)' targetIndices(:)']);
targetPositions = numel(sourceIndices) + (1:numel(targetIndices));
eeg = eeg_interp(eeg, targetPositions, 'spherical');
result = eeg.data(targetPositions, :, :);
end
