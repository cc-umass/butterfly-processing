function [rejectedEpochs, maskedChannels] = doPeakToPeakRejection(epochedEEG)

loadRejectionConstants;

channels = {epochedEEG.chanlocs.labels};
epochCount = epochedEEG.trials;
scalpChannels = find(~ismember(upper(channels), peripheralChannels));

% First pass on every scalp channel, to find channels that flag most epochs
firstPass = runPeakToPeakTest(epochedEEG, scalpChannels);
flagFraction = mean(firstPass.reject.rejmanualE(scalpChannels, :) > 0, 2)';
isBadChannel = flagFraction > badChannelFlagFraction;
maskedChannels = channels(scalpChannels(isBadChannel));
for badIndex = find(isBadChannel)
    butterflyLog('  masked %s: ptp flags %.0f%% of epochs', channels{scalpChannels(badIndex)}, 100 * flagFraction(badIndex));
end

% Second pass without the masked channels
testedChannels = scalpChannels(~isBadChannel);
secondPass = runPeakToPeakTest(epochedEEG, testedChannels);
rejectedEpochs = secondPass.reject.rejmanual > 0;
butterflyLog('  ptp > %g uV (%d ms window, %d ms step, %d ch, %d masked): %d of %d epochs flagged (%.1f%%)', ptpThresholdUv, ptpWindowMs, ptpStepMs, numel(testedChannels), numel(maskedChannels), sum(rejectedEpochs), epochCount, 100 * sum(rejectedEpochs) / epochCount);
end

function testedEEG = runPeakToPeakTest(epochedEEG, testChannels)
loadRejectionConstants;
testedEEG = pop_artmwppth(epochedEEG, ...
    'Twindow', testWindowMs, ...
    'Threshold', ptpThresholdUv, ...
    'Windowsize', ptpWindowMs, ...
    'Windowstep', ptpStepMs, ...
    'Channel', testChannels, ...
    'Flag', 1, ...
    'Review', 'off');
end
