function subjectEEG = doMastoidReferencing(subjectEEG)

globals;

channels = {subjectEEG.chanlocs.labels};
mastoidIndex = find(ismember(upper(channels), mastoidChannels));
peripheralIndex = find(ismember(upper(channels), peripheralChannels));
subjectEEG = pop_reref(subjectEEG, mastoidIndex, ...
    'keepref', 'on', ...
    'exclude', peripheralIndex);
subjectEEG = eeg_checkset(subjectEEG);
butterflyLog('  re-referenced to mean(M1,M2)');
end
