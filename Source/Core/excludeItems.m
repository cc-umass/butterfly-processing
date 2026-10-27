function subjectEEG = excludeItems(subjectEEG, itemsToExclude)

globals;

eventCodes = [subjectEEG.event.type];

% Increment every picture event code (which is what our epochs are time locked to) that is followed by an excluded item
% with 9000, which will cause them to not be collected in the bins we will use for our analysis
isPicture = ismember(eventCodes, pictureCodes);
followedByExcluded = [ismember(eventCodes(2:end), itemsToExclude), false];
toIncrement = isPicture & followedByExcluded;
eventCodes(toIncrement) = eventCodes(toIncrement) + 9000;
butterflyLog('  exclusion: %d items listed, %d trials renamed', numel(itemsToExclude), sum(toIncrement));
for eventIndex = 1:numel(eventCodes)
    subjectEEG.event(eventIndex).type = eventCodes(eventIndex);
end
subjectEEG = eeg_checkset(subjectEEG, 'eventconsistency');

end
