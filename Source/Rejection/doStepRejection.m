function rejectedEpochs = doStepRejection(epochedEEG)

loadRejectionConstants;

veogRejected = stepTestOnChannel(epochedEEG, 'VEOG', stepThresholdVeogUv);
heogRejected = stepTestOnChannel(epochedEEG, 'HEOG', stepThresholdHeogUv);
rejectedEpochs = veogRejected | heogRejected;
butterflyLog('  step function (%d ms window, %d ms step, %d..%d ms, VEOG > %g uV, HEOG > %g uV): %d of %d epochs flagged (%.1f%%)', stepWindowMs, stepStepMs, testWindowMs, stepThresholdVeogUv, stepThresholdHeogUv, sum(rejectedEpochs), epochedEEG.trials, 100 * sum(rejectedEpochs) / epochedEEG.trials);
end

function rejectedEpochs = stepTestOnChannel(epochedEEG, eogChannelName, threshold)
loadRejectionConstants;
channels = {epochedEEG.chanlocs.labels};
epochCount = epochedEEG.trials;
rejectedEpochs = false(1, epochCount);
eogChannelIndex = find(strcmpi(channels, eogChannelName), 1);
if isempty(eogChannelIndex)
    butterflyLog('  %s: not in montage, step test skipped', eogChannelName);
    return
end
usableEpochs = eogUsableEpochs(epochedEEG, eogChannelIndex, eogPtpMinUv, eogDiffMaxUv, eogChannelName);
if ~any(usableEpochs)
    butterflyLog('  step test skipped on %s', eogChannelName);
    return
end
epochedEEG = pop_artstep(epochedEEG, ...
    'Twindow', testWindowMs, ...
    'Threshold', threshold, ...
    'Windowsize', stepWindowMs, ...
    'Windowstep', stepStepMs, ...
    'Channel', eogChannelIndex, ...
    'Flag', 1, ...
    'Review', 'off');
rejectedEpochs = epochedEEG.reject.rejmanual > 0 & usableEpochs;
end

function usableEpochs = eogUsableEpochs(epochedEEG, eogChannelIndex, ptpMinUv, diffMaxUv, eogChannelName)
% Extract the data for just the channel represented by eogChannelIndex
eogChannelData = double(squeeze(epochedEEG.data(eogChannelIndex, :, :)));

% Luck 2014 (box 6.1, p. 189; pp. 192-193) leaves a bad channel to the researcher:
% check every channel before the task and judge artifact rejection by visual inspection.
% No automated rule is given. Here we attempt to automatically determine, epoch by
% epoch, if the EOG channel is bad using a peak-to-peak and a sample-to-sample
% statistic, and leave the step test result out for those epochs
epochPtp = max(eogChannelData, [], 1) - min(eogChannelData, [], 1);
epochDiff = median(abs(diff(eogChannelData, 1, 1)), 1);
usableEpochs = ptpMinUv <= epochPtp & epochDiff <= diffMaxUv;
butterflyLog('  %s: %d of %d epochs usable (median ptp %.0f uV, median |diff| %.2f uV)', eogChannelName, sum(usableEpochs), numel(usableEpochs), median(epochPtp), median(epochDiff));
end
