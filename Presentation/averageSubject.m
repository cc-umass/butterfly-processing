function conditionWaves = averageSubject(result, incorrectItems)

constants;

roiPositions = cellfun(@(label) find(strcmpi(result.channelLabels, label), 1), roiChannels);
epochCount = numel(result.epochCondition);
sampleCount = numel(result.sampleTimePoints);

epochIsUsable = false(1, epochCount);
roiWaveOfEpoch = nan(epochCount, sampleCount);
for epochIndex = 1:epochCount
    if ismember(result.epochItem(epochIndex), incorrectItems)
        continue
    end
    badInThisSection = result.badChannelSections(:, result.epochSection(epochIndex));
    availableROIPositions = roiPositions(~badInThisSection(roiPositions));
    if isempty(availableROIPositions)
        continue
    end
    if any(result.badChannelEpochs(availableROIPositions, epochIndex))
        continue
    end
    epochIsUsable(epochIndex) = true;
    roiWaveOfEpoch(epochIndex, :) = mean(result.data(availableROIPositions, :, epochIndex), 1);
end

conditionCount = numel(binNames);
conditionWaves = nan(conditionCount, sampleCount);
for conditionIndex = 1:conditionCount
    selected = epochIsUsable & result.epochCondition == conditionIndex;
    conditionWaves(conditionIndex, :) = mean(roiWaveOfEpoch(selected, :), 1);
end
end
